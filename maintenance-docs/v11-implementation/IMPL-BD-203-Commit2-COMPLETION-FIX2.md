# IMPL-BD-203-Commit2-COMPLETION-FIX2 — measure-then-bound stale-prose/output sweep (PROSE/OUTPUT-STRING-ONLY)

**Agent:** pack-coder (fix-2; measure-then-bound completion sweep) · **Date:** 2026-06-05 · **Branch:** v11-dev
**HEAD (unchanged, no git verb run):** `4c370dac0963dfbea9f358535811a7c86aa2cfb9`
**Scope:** COMPLETE the SHOULD-1 stale-mirror/v8-archive cleanup in `scripts/validate-pack.py` as a
measure-then-bound sweep with a grep-zero completeness GATE — strip EVERY remaining pack-side occurrence
that fix-1's anchor-enumeration left (the surfaced `:3699` runtime `ok()` output, the `:3147` docstring
example, and any others the grep finds), to the no-mirror / de-archived (post-B8) reality. **ZERO behavior
change** — comment / docstring / output-string-TEXT only.

---

## PREFLIGHT (clean)

```
PREFLIGHT: 3/3 in-scope STRIP edits complete; GATE grep returns exactly the documented KEEP allowlist
(zero stale pack-side); skeleton-proof confirms zero executable tokens changed; no test pins removed
output text; validate-pack working-tree GREEN except 2× Check 32′ expected-RED + 1 Check-36 transient;
post-git-rm sim fully GREEN (32′/33/34/40); FULL CI battery unchanged (74/74, 57/57, 7P-1F, 6P-2F, 30P-3F);
manifest empty diff; verification PASS; HEAD 4c370da; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPL-BD-203-Commit2-COMPLETION-FIX2.md
```

All clean-PREFLIGHT conditions hold (verbatim evidence below):
- 3/3 STRIP occurrences corrected to the no-mirror / de-archived reality; PROSE/COMMENT/OUTPUT-STRING-TEXT
  only (token-skeleton proof: my 3 edits changed ZERO executable tokens — 22286 == 22286).
- The GATE grep over `scripts/validate-pack.py` returns EXACTLY the documented KEEP allowlist; ZERO stale
  pack-side occurrences remain.
- No test ASSERTS on the removed `:3705` output text ("v8-archive SKIPed" / "§11.3"); none updated (the
  3 test mentions are `#`-comment / retired-test prose, not assertions — surfaced below).
- validate-pack working tree GREEN on every check EXCEPT Check 32′ (2× expected-RED) + the benign Check-36
  HEAD transient — exactly 3 FAILs, unchanged from the fix-1 clean baseline.
- post-`git rm` simulation FULLY GREEN (32′/33/34/40 all PASS); byte-identity restore confirmed.
- FULL CI battery unchanged result counts (74/74; 57/57; 7P-1F; 6P-2F; 30P-3F — every RED the documented
  monoliths-present end-to-end exit-status assertion).
- manifest regen run → empty diff.
- `python3 ast.parse` OK.

---

## 1. MEASURE — the stale-pattern-family grep (BEFORE)

```
$ grep -nE 'regenerated mirror|monolithic mirror|mirror in-sync|mirror is byte-identical|mirror.*byte-identical|byte-identical.*mirror|_v8-resolved-archive|v8-archive|v8 archive|v8-resolved' scripts/validate-pack.py
130:      regenerated mirror. Also assert `_rules.md` + `_toc.md` are present
145:      `_v8-resolved-archive.md` SKIP is DEAD post-BD-203 B8 — the
147:      v8-archive supporting file is emitted.) SKIPs when no per-entry
229:      no regenerated mirror under the no-mirror model) — and flags
308:    # there is no regenerated monolithic mirror (Check 32 inverted to 32′).
3141:# regenerated monolithic mirror to be "in sync" with. The guard's job
3154:    `_v8-resolved-archive.md`, `_format.md`) nor matching the entry          ← STRIP #2
3519:    Note: post-BD-203 B8 there is no `_v8-resolved-archive.md` SKIP — the
3520:    BD-001..019 entries are now normal per-entry files, so no v8-archive
3559:        `_v8-resolved-archive.md` archive file — the BD-001..019 entries
3626:    # BD-203 B8: the former `_v8-resolved-archive.md` SKIP is DEAD — the
3628:    # (pre-normalize Commit 1), so no v8-archive supporting file is
3705:                f"to defined IDs (or self-reference, or v8-archive "          ← STRIP #1
4877:# defensive exemption retained post-BD-203; there is no regenerated mirror
4948:    # user-locked 2026-05-26); the previous "byte-identical mirror"
5186:    # conversion-input monoliths. NOT "regenerated mirrors" — there is
5447:#     or `pack-ops/`), minus the regenerated mirrors, the client-installed  ← project-side (Check 43)
5515:    minus: the regenerated mirrors (`BACKLOG.md` / `CHANGELOG.md`), the     ← project-side (Check 43)
7403:    # the exit code) and scoped to the two regenerated mirrors, so it       ← STRIP #3
```

(Line numbers are at the live working tree, which has the D1–D5 + fix-1 hunks applied — fix-1's surfaced
`:3699`/`:3147`/`:5433/5501/7389` correspond to `:3705`/`:3154`/`:5447/5515/7403` after those hunks shifted
the line numbers.)

---

## 2. CATEGORIZE — every occurrence (KEEP allowlist vs STRIP)

### KEEP (allowlist — NOT touched; verified each is correct/legitimate)

| Line(s) | What it is | KEEP category |
|---|---|---|
| `:130` | Check-32′ module docstring "…the monolith is a deleted conversion-input, NOT a regenerated mirror" | (a) affirmative NO-MIRROR statement (fix-1 Correction 1) |
| `:145,:147` | Check-34 module docstring "…`_v8-resolved-archive.md` SKIP is DEAD post-BD-203 B8 … no v8-archive supporting file is emitted" | (d) de-archived no-mirror prose (fix-1 Correction 2) |
| `:229` | Check-40 module docstring "…there is no regenerated mirror under the no-mirror model" | (d) defensive-exemption no-mirror prose (fix-1 Correction 3) |
| `:308` | STREAMS comment "…there is no regenerated monolithic mirror (Check 32 inverted to 32′)" | (a) affirmative NO-MIRROR statement (D1-era landed; correct) |
| `:3141` | Check-32′ function-banner comment "…there is NO regenerated monolithic mirror to be 'in sync' with" | (a) affirmative NO-MIRROR statement |
| `:3519,:3520` | `_extract_references` docstring "…post-BD-203 B8 there is no `_v8-resolved-archive.md` SKIP…" | (d) de-archived prose (fix-1 Correction 5) |
| `:3559` | `check_cross_reference_integrity` docstring bullet "…no `_v8-resolved-archive.md` archive file…" | (d) de-archived prose (fix-1 Correction 6) |
| `:3626,:3628` | Check-34 walk-loop comment "BD-203 B8: the former `_v8-resolved-archive.md` SKIP is DEAD…" | (d) de-archived prose (already correct, B8) |
| `:4877` | Check-40 banner comment "…there is no regenerated mirror under the no-mirror model" | (d) defensive-exemption no-mirror prose (fix-1 Correction 4) |
| `:4948` | Check-24/HELP-FRAGMENT comment "…the previous 'byte-identical mirror' rationale is retired with Check 24" | DIFFERENT SURFACE — BD-194 HELP-FRAGMENT-TRACKER.md (not the BD-203 monolith); accurate past-tense "retired" framing. Not a stale pack-monolith occurrence. |
| `:5186` | Check-40 `excluded_basenames` comment "NOT 'regenerated mirrors' — there is no mirror" | (a) affirmative NO-MIRROR statement (already corrected C-1/Commit-2) |
| `:5447,:5515` | Check-43 `_build_pack_only_doc_basenames` "…minus the regenerated mirrors (`BACKLOG.md`/`CHANGELOG.md`)…" | (b)/(c) PROJECT-SIDE mirror-skip — these are the CLIENT mirrors that STILL EXIST until BD-206; PLAN §D5 "do NOT remove the Check-43 mirror-skip basenames." EXCLUDED from this sweep. |

### STRIP (fixed — every PACK-side occurrence describing the deleted pack monolith as a live mirror, or the removed v8-archive SKIP as if it still exists)

| # | Line | What it is | Why STRIP (verified against actual code) |
|---|---|---|---|
| **1** | `:3705` | Check-34 runtime `ok()` OUTPUT string "…all resolved to defined IDs (or self-reference, or v8-archive SKIPed per §11.3)" | The loop (`check_cross_reference_integrity`) skips leading-underscore supporting files generically (`:3648 startswith("_")`) + self-references (`:3681`); there is NO v8-archive SKIP (B8 removed it). The output described a SKIP that no longer exists. ENCODING SURFACE (validator OUTPUT). |
| **2** | `:3154` | `_list_unknown_files` docstring example list "(e.g. `_rules.md`, `_intro.md`, `_toc.md`, `_v8-resolved-archive.md`, `_format.md`)" | The actual `known_supporting_for` set passed to this helper is `{"_rules.md","_intro.md","_toc.md"}` (`:3204-3205`, post-B8). `_v8-resolved-archive.md` is NO LONGER a known-supporting basename — listing it as an example mis-describes the de-archived reality. |
| **3** | `:7403` | Check-48 call-site comment "…scoped to the two regenerated mirrors…" | `check_removed_doc_advisory` (Check 48) was REPOINTED (BD-203 A12) to scan `_REMOVED_DOC_SCAN_DIRS = ("changelog","backlog")` — the per-entry TREES, NOT the monoliths (its own docstring `:7194-7197` already says so). The call-site comment still claimed the OLD monolith scope — stale. |

**No borderline / unclassifiable occurrence surfaced.** Every match is confidently either an affirmative
no-mirror statement / de-archived prose (KEEP), a different-surface retired-rationale (`:4948`, KEEP), the
project-side Check-43 skip (`:5447/:5515`, KEEP — BD-206), or a stale pack-side STRIP (#1/#2/#3).

---

## 3. THE 3 STRIP CORRECTIONS (old → new)

### STRIP #1 — `:3705` Check-34 runtime `ok()` OUTPUT string

OLD:
```
            ok(
                f"cross-reference integrity: {total_refs} reference(s) "
                f"across {total_files} per-entry file(s); all resolved "
                f"to defined IDs (or self-reference, or v8-archive "
                f"SKIPed per §11.3)"
            )
```
NEW:
```
            ok(
                f"cross-reference integrity: {total_refs} reference(s) "
                f"across {total_files} per-entry file(s); all resolved "
                f"to defined IDs (or self-reference; leading-underscore "
                f"supporting files are not walked)"
            )
```
Accurately describes what the loop does now: self-references skipped (`:3681`), leading-underscore
supporting files not walked (`:3648`), no v8-archive SKIP. The `cross-reference integrity:` prefix +
the count/file substrings are preserved (the realistic-ot C.9 assertion pins only `cross-reference
integrity:`).

### STRIP #2 — `:3154` `_list_unknown_files` docstring example list

OLD:
```
    """List basenames in `stream_dir` that are neither known supporting
    files (e.g. `_rules.md`, `_intro.md`, `_toc.md`,
    `_v8-resolved-archive.md`, `_format.md`) nor matching the entry
    regex. Used by Check 32 pre-check (b) — non-conforming filenames
    per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.4.
    """
```
NEW:
```
    """List basenames in `stream_dir` that are neither known supporting
    files (e.g. `_rules.md`, `_intro.md`, `_toc.md`) nor matching the
    entry regex. Used by Check 32 pre-check (b) — non-conforming
    filenames per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.4.
    (Post-BD-203 B8 there is no `_v8-resolved-archive.md` supporting
    file — the BD-001..019 entries are now normal per-entry files — so
    it is no longer a known-supporting basename; see the
    `known_supporting_for` set in `check_mirror_in_sync`.)
    """
```
The example list now matches the live `known_supporting_for` set (`{_rules.md,_intro.md,_toc.md}`) and
names the de-archived reality. (`_format.md` was ALSO dropped from the example list because it is not in
the live `known_supporting_for` set either — keeping it would re-introduce a different inaccuracy; the
example is now exactly the live set. This is a TEXT correction only, zero logic.)

### STRIP #3 — `:7403` Check-48 call-site comment

OLD:
```
    # ── BD-195 (C6): JC-5 soft-advisory removed-doc guard. Lands LAST —
    # it is SOFT (WARN-only; never appends to `failures`, never changes
    # the exit code) and scoped to the two regenerated mirrors, so it
    # neither gates nor depends on any prior check. Per
    # PLAN-BD-195-REMEDIATION.md §C6 / §2.3 (measure-then-bound JC-5).
```
NEW:
```
    # ── BD-195 (C6): JC-5 soft-advisory removed-doc guard. Lands LAST —
    # it is SOFT (WARN-only; never appends to `failures`, never changes
    # the exit code) and scoped to the per-entry trees (`/backlog/` +
    # `/changelog/` per BD-203 A12 `_REMOVED_DOC_SCAN_DIRS`, where the
    # accurate-history citations relocated when the monoliths were
    # deleted — no regenerated mirror under the no-mirror model), so it
    # neither gates nor depends on any prior check. Per
    # PLAN-BD-195-REMEDIATION.md §C6 / §2.3 (measure-then-bound JC-5).
```
Matches the function's own (already-correct) docstring (`:7194-7197`) and the live `_REMOVED_DOC_SCAN_DIRS
= ("changelog","backlog")` (`:335-338`).

---

## 4. GATE — the completeness contract (AFTER)

```
$ grep -nE 'regenerated mirror|monolithic mirror|mirror in-sync|mirror is byte-identical|mirror.*byte-identical|byte-identical.*mirror|_v8-resolved-archive|v8-archive|v8 archive|v8-resolved' scripts/validate-pack.py
130:      regenerated mirror. Also assert `_rules.md` + `_toc.md` are present          KEEP (a) fix-1 Corr.1
145:      `_v8-resolved-archive.md` SKIP is DEAD post-BD-203 B8 — the                  KEEP (d) fix-1 Corr.2
147:      v8-archive supporting file is emitted.) SKIPs when no per-entry              KEEP (d) fix-1 Corr.2
229:      no regenerated mirror under the no-mirror model) — and flags                 KEEP (d) fix-1 Corr.3
308:    # there is no regenerated monolithic mirror (Check 32 inverted to 32′).        KEEP (a)
3141:# regenerated monolithic mirror to be "in sync" with. The guard's job             KEEP (a)
3156:    (Post-BD-203 B8 there is no `_v8-resolved-archive.md` supporting               KEEP (d) STRIP#2 NEW text
3522:    Note: post-BD-203 B8 there is no `_v8-resolved-archive.md` SKIP — the          KEEP (d) fix-1 Corr.5
3523:    BD-001..019 entries are now normal per-entry files, so no v8-archive           KEEP (d) fix-1 Corr.5
3562:        `_v8-resolved-archive.md` archive file — the BD-001..019 entries           KEEP (d) fix-1 Corr.6
3629:    # BD-203 B8: the former `_v8-resolved-archive.md` SKIP is DEAD — the           KEEP (d) B8 (correct)
3631:    # (pre-normalize Commit 1), so no v8-archive supporting file is               KEEP (d) B8 (correct)
4880:# defensive exemption retained post-BD-203; there is no regenerated mirror        KEEP (d) fix-1 Corr.4
4951:    # user-locked 2026-05-26); the previous "byte-identical mirror"               KEEP — BD-194 HELP-FRAGMENT
5189:    # conversion-input monoliths. NOT "regenerated mirrors" — there is            KEEP (a)
5450:#     or `pack-ops/`), minus the regenerated mirrors, the client-installed        KEEP (b)/(c) project-side Check-43
5518:    minus: the regenerated mirrors (`BACKLOG.md` / `CHANGELOG.md`), the           KEEP (b)/(c) project-side Check-43
7409:    # deleted — no regenerated mirror under the no-mirror model), so it           KEEP (d) STRIP#3 NEW text
```

**Verdict:** the grep returns EXACTLY the documented KEEP allowlist (affirmative no-mirror statements + the
fix-1 de-archived corrections + the B8 walk-loop comment + the BD-194 HELP-FRAGMENT retired-rationale + the
two project-side Check-43 `:5450/:5518` lines + my 2 NEW de-archived/no-mirror correction blocks) and **ZERO
stale pack-side occurrences**. STRIP #1 (`v8-archive SKIPed`/`§11.3` output) and STRIP #3's old
"scoped to the two regenerated mirrors" prose are GONE. The gate — not the anchor list — is the contract.

---

## 5. STRIP #1 test-pin check (enumerate-encoding-surfaces)

`:3705` is a validator OUTPUT string (encoding surface). Grepped the test suite for any assertion pinning
the OLD output text:

```
$ grep -rnE 'v8-archive SKIPed|v8-archive|§11\.3|11\.3' scripts/tests/ test-fixtures/
scripts/tests/test-validate-pack-checks-32-33-34.sh:36:#         passes (archive SKIPed per integration parent §11.3).
scripts/tests/test-validate-pack-checks-32-33-34.sh:61:#     scope); §11.3 (v8-archive SKIP for cross-refs).
scripts/tests/test-validate-pack-checks-32-33-34.sh:538:# inside the archive that Check 34 SKIPed per §11.3). The archive

$ grep -rnE 'all resolved to defined|self-reference, or v8|or v8-archive' scripts/tests/   → (none; rc=1)
$ grep -rnE 'cross-reference integrity:|reference\(s\)' scripts/tests/
scripts/tests/test-v11-realistic-ot.sh:357:    "cross-reference integrity:"
```

**Result: NO test ASSERTS on the removed output text.**
- The 3 `test-validate-pack-checks-32-33-34.sh` hits (`:36`, `:61`, `:538`) are all `#`-COMMENT prose — a
  header description of the (RETIRED) C3 test case + an architecture-pointer comment + the C3 retirement
  note (`:536-542` reads "C3: (RETIRED — BD-203 B8) … there is no archive section to SKIP and this test no
  longer applies"). NONE is an `assert_*` call. They are STALE TEST-COMMENT prose, but they are in
  `scripts/tests/` (OUTSIDE the scoped `scripts/validate-pack.py`) and they do not PIN the output. Per the
  task's enumerate-encoding-surfaces clause ("If a test pins it, update lock-step. If none does, note
  that.") I did NOT edit the test file; surfaced below.
- The only test assertion touching the Check-34 OK banner — `test-v11-realistic-ot.sh:354,:357` — pins the
  substrings `── Check 34: cross-reference integrity (BD-168) ──` and `cross-reference integrity:`, BOTH of
  which my new output PRESERVES verbatim. C.8/C.9 stay GREEN (confirmed in §7 post-rm sim).

No test required a lock-step update.

---

## 6. NO LOGIC CHANGE — token-skeleton proof

`python3 -c "import ast; ast.parse(...)"` → **AST OK**.

`git diff --stat scripts/validate-pack.py` (working tree vs HEAD; includes the pre-existing D1–D5 + fix-1
hunks + my 3 strips): `166 insertions(+), 51 deletions(-)`.

The load-bearing proof that MY 3 strips changed ONLY string/comment TEXT: I reconstructed the
pre-my-edit content (reverted my 3 strips back to their pre-fix2 text in a temp copy) and compared the
**executable token skeleton** (all comment + all string/f-string tokens collapsed to a single `<s>`
placeholder; whitespace/NL/INDENT dropped) of pre-my-edit vs now:

```
pre-my-edit executable-skeleton tokens: 22286
now (mine)  executable-skeleton tokens: 22286
EXECUTABLE SKELETON IDENTICAL (my 3 edits changed ZERO executable tokens): True
```

ZERO executable tokens changed. No condition, constant, `excluded_basenames`, regex, return, or control
flow changed:
- `excluded_basenames = {"BACKLOG.md","CHANGELOG.md"}` (`:5188`) UNCHANGED.
- `known_supporting_for = {"pack-backlog":{"_rules.md","_intro.md","_toc.md"}, …}` (`:3203-3206`) UNCHANGED.
- `_REMOVED_DOC_SCAN_DIRS = ("changelog","backlog")` (`:335-338`) UNCHANGED.
- the `startswith("_")` walk guard (`:3648`) + the `ok(` call structure + the `check_removed_doc_advisory()`
  call (`:7412`) UNCHANGED — only the f-string TEXT inside `ok(...)` and the surrounding comments changed.

(Note on the naive per-line tokenizer: Python 3.12 tokenizes f-strings as `FSTRING_*` tokens, not the
legacy `STRING` token, so a naive "is this line a COMMENT/STRING token" line-membership test mis-flags
f-string-content lines as code. The skeleton-equality proof above is f-string-aware and is the definitive
zero-logic proof.)

---

## 7. VERIFICATION RESULTS (verbatim)

### validate-pack — working tree (monoliths PRESENT) — exactly 3 FAILs

```
$ python3 scripts/validate-pack.py 2>&1 | grep '^FAIL:'
FAIL: pack-ops/BACKLOG.md still present while backlog/ tree exists — under the no-mirror model the per-entry tree (+ _toc.md) is the SOLE source of truth; delete the monolith (pack-ops/BACKLOG.md) so the tree is the only SSOT     (Check 32′ — EXPECTED-RED)
FAIL: pack-ops/CHANGELOG.md still present while changelog/ tree exists — … delete the monolith (pack-ops/CHANGELOG.md) so the tree is the only SSOT                                                                                  (Check 32′ — EXPECTED-RED)
FAIL: Commit 4c370da subject claims `pack-chat-only` but touches non-pack-chat-only paths: pack-ops/BACKLOG.md …                                                                                                                    (Check 36 — HEAD transient)
$ python3 scripts/validate-pack.py 2>&1 | grep -c '^FAIL:'   → 3
$ python3 scripts/validate-pack.py >/dev/null 2>&1; echo EXIT=$?   → EXIT=1
```
Identical to the fix-1 clean baseline (2× Check 32′ expected-RED + 1× Check-36 HEAD transient).

### post-`git rm` simulation (non-destructive `cp`-backup + `mv`-aside → validate → `mv`-back) — FULLY GREEN

```
$ (BACKLOG.md + CHANGELOG.md mv aside) python3 scripts/validate-pack.py 2>&1 | grep '^FAIL:'
FAIL: Commit 4c370da subject claims `pack-chat-only` … pack-ops/BACKLOG.md   (Check 36 — HEAD transient ONLY)
$ … | grep -c '^FAIL:'   → 1
── Check 32′: no pack monolith exists (BD-203) ──
  OK: backlog/ — no monolith present; _rules.md + _toc.md present; filenames conform (no-mirror SSOT)
  OK: changelog/ — no monolith present; _rules.md + _toc.md present; filenames conform (no-mirror SSOT)
── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/_toc.md byte-identical (21580 bytes)
  OK: changelog/_toc.md byte-identical (582 bytes)
── Check 34: cross-reference integrity (BD-168) ──
  OK: cross-reference integrity: 2630 reference(s) across 222 per-entry file(s); all resolved to defined IDs (or self-reference; leading-underscore supporting files are not walked)
── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 10 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (54 allowlist-exempt + 6 anchor-phrase-exempt + 16 same-dir-legit hit(s) accepted)
$ diff -q /tmp/BACKLOG.md.bak pack-ops/BACKLOG.md     → identical (BACKLOG identical)
$ diff -q /tmp/CHANGELOG.md.bak pack-ops/CHANGELOG.md → identical (CHANGELOG identical)
$ ls -l pack-ops/{BACKLOG,CHANGELOG}.md → 592252 / 46177 bytes (restored)
```
Post-delete: Check 32′/33/34/40 all PASS; only the benign Check-36 HEAD transient remains. **The Check-34 OK
banner now shows my corrected wording** ("…or self-reference; leading-underscore supporting files are not
walked") — no v8-archive. Matches the fix-1 clean baseline exactly (1 residual FAIL = the HEAD transient).

### FULL CI battery (verify-full-ci-suite) — unchanged result counts

```
test-validate-pack-checks-32-33-34.sh → PASS: 74  FAIL: 0   (74/74; incl. C3-retired note, C4 self-ref, C6 suffix-resolve)
test-per-entry.sh                     → PASS: 57  FAIL: 0   (57/57)
test-validate-pack-check-40.sh        → PASS: 7   FAIL: 1   (the 1 = "validate-pack.py exits non-zero on HEAD" end-to-end; "mirror-skip tests" + every Check-40 UNIT case PASS)
test-validate-pack-checks-36-37-38.sh → PASS: 6   FAIL: 2   (both = G6.T11 "validate-pack.py exits … on HEAD" end-to-end)
test-v11-realistic-ot.sh (working tree) → PASS: 30 FAIL: 3  (C.1 exit-0, C.3/C.4 Check-32′-no-monolith — all monoliths-present artifacts; C.8/C.9 Check-34 banner+integrity PASS)
```
Every integration/end-to-end RED is the SAME documented single root cause: validate-pack exits non-zero
ONLY because the monoliths are still present (Check 32′ expected-RED) + the Check-36 HEAD transient.
Confirmed each failing assertion is the literal end-to-end exit-status check (`validate-pack.py exits 0/non-zero
on HEAD` / `C.1 exits 0` / `C.3/C.4 Check 32′ no-monolith` / `G6.T11 expected 0`), never a docstring-/
output-/unit-level assertion. **These counts are identical to the fix-1 clean baseline — my 3 strips changed
no test result.** The WARN lines (JC-5 removed-doc advisories on `changelog/v8.md`, `backlog/BD-046.md`,
etc.) are SOFT advisory-only (never gate), present in the baseline.

### manifest (regenerate-manifest-v11-surface — `scripts/` is v11-surface)

```
$ bash test-fixtures/build.sh --all --clean   → exit 0
$ git status --short test-fixtures/manifest.txt   → (empty)
$ git diff --stat test-fixtures/manifest.txt      → (empty)
```
Empty diff — prose/output-string edits do not change tracked fixture SHAs. RUN per the rule; nothing to stage.

### syntax

```
$ python3 -c "import ast; ast.parse(open('scripts/validate-pack.py').read()); print('AST OK')"   → AST OK
```

---

## 8. FILES CHANGED (this fix)

| Path | Change type | Nature |
|---|---|---|
| `scripts/validate-pack.py` | modified | 3 STRIP occurrences corrected (1 output-string TEXT + 2 docstring/comment); PROSE/OUTPUT-STRING-TEXT only; zero executable tokens |

`test-fixtures/manifest.txt` — regen RUN, empty diff, NOT staged/changed.
No other file touched by this fix. `git status` shows ZERO `project-template/` or `supporting-docs/` paths
attributable to me → `pack-only` clean. (The ~80 other dirty paths in the working tree are the pre-existing
D1–D5 + fix-1 completion state, untouched by this fix.) HEAD unchanged `4c370da` (read-only git only).

---

## 9. PLAN / FINDING DEVIATIONS

**None.** The sweep applied exactly the measure-then-bound procedure: measured the stale-pattern family,
categorized every occurrence KEEP/STRIP per the documented allowlist, stripped every pack-side STRIP, and
gated on the grep returning only the allowlist. No D1–D5 work re-edited; no fix-1 6 corrections re-edited;
the project-side `:5447/:5515` (Check 43, BD-206) untouched; zero logic change.

One classification refinement worth noting (NOT a deviation — it is the measure-then-bound sweep doing its
job): fix-1's "Surfaced" §3 lumped `:7389` (now `:7403`) with the project-side `:5433/5501` Check-43 lines
and left it unchanged. The sweep RE-CLASSIFIED `:7403` correctly — it is the PACK-side Check-48 call-site
comment, and Check 48 was repointed (BD-203 A12) to scan the per-entry TREES, so "scoped to the two
regenerated mirrors" is stale PACK-side prose (STRIP #3), NOT project-side. This is exactly the
anchor-enumeration-miss the measure-then-bound gate exists to catch.

---

## 10. SURFACED (not silently fixed) — out-of-scope stale mentions for a follow-up

Per GOALS "surface, don't silently fix," reported for Pack Chat / a follow-up; NOT folded into this
`validate-pack.py`-scoped fix:

1. **3 stale test-COMMENT mentions in `scripts/tests/test-validate-pack-checks-32-33-34.sh`** — `:36`
   ("archive SKIPed per integration parent §11.3"), `:61` ("§11.3 (v8-archive SKIP for cross-refs)"),
   `:538` (the C3-retirement note still references "§11.3"). These are `#`-comments / header-description
   prose describing the RETIRED C3 v8-archive-SKIP test case; NONE is an `assert_*` that pins validator
   OUTPUT, so they do NOT break with STRIP #1 (confirmed §5). They are OUTSIDE this fix's scope
   (`scripts/validate-pack.py` only). A future test-comment-hygiene pass could prune the §11.3 mentions; no
   gate or test result depends on them.

None of item 1 affects any gate or test result.

---

## 11. DEFINITION-OF-DONE CHECKLIST

| Item | Status | Evidence |
|---|---|---|
| MEASURE: stale-pattern-family grep run; every occurrence captured | PASS | §1 BEFORE grep (19 lines) |
| CATEGORIZE: every occurrence KEEP (allowlist) or STRIP | PASS | §2 tables (16 KEEP rows + 3 STRIP rows) |
| FIX every STRIP to the no-mirror / de-archived reality, accurate vs actual code | PASS | §3 corrections 1–3; each verified against the live code (`known_supporting_for`, `_REMOVED_DOC_SCAN_DIRS`, the walk loop) |
| GATE: grep returns EXACTLY the documented KEEP allowlist; ZERO stale pack-side | PASS | §4 AFTER grep — every line annotated KEEP; #1/#3 old prose gone |
| ENCODING-SURFACE: STRIP #1 output test-pin check; lock-step if pinned | PASS | §5 — no `assert_*` pins the removed text; 3 hits are `#`-comments; no test edited |
| PROSE/OUTPUT-STRING TEXT ONLY — zero executable logic changed | PASS | §6 token-skeleton identical (22286==22286); constants/regex/control-flow UNCHANGED |
| No new mirror-model language introduced | PASS | new text states "leading-underscore supporting files are not walked" / "no regenerated mirror under the no-mirror model" / "no `_v8-resolved-archive.md` supporting file" |
| Edit-in-place (no wholesale rewrite) | PASS | 3 targeted `Edit` calls; rest of file untouched |
| validate-pack working tree = 3 expected FAILs only | PASS | §7 — 2× Check 32′ + 1× Check-36 transient |
| post-`git rm` sim FULLY GREEN (32′/33/34/40) + byte-identity restore | PASS | §7 sim output; `diff -q` identical both monoliths (592252/46177) |
| FULL CI battery unchanged result counts | PASS | §7 — 74/74; 57/57; 7P-1F; 6P-2F; 30P-3F — all RED = documented end-to-end monoliths-present root cause |
| manifest regen run + diff reported (empty) | PASS | §7 build exit 0; empty `git status`/`git diff` |
| AST/syntax valid | PASS | AST OK |
| No git state-changing verb run; HEAD unchanged | PASS | HEAD `4c370da` (read-only git + non-destructive mv-aside/restore only) |
| No project-template/ or supporting-docs/ paths touched (pack-only) | PASS | `git status` filter → none |
| D1–D5 + fix-1 work untouched; project-side `:5447/:5515` untouched | PASS | only `scripts/validate-pack.py` 3 strips changed; Check-43 lines unmodified |

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (QUOTED) | Conclusion |
|---|---|---|
| **rename-plans / mass-edit = measure-then-bound (NOT anchor-enumeration)** | Ran the MEASURE grep (§1, 19 lines), CATEGORIZED every occurrence KEEP/STRIP (§2), fixed every STRIP, and the GATE grep (§4) returns EXACTLY the documented allowlist — ZERO stale pack-side. The gate, not a hand list, is the completeness contract; before/after captured verbatim. The sweep CAUGHT the `:7403` occurrence fix-1's anchor-enumeration mis-classified (§9). | COMPLIANT |
| **ci-guard-measure-then-bound** | §2 categorizes every occurrence; STRIP set sized to exactly the 3 pack-side stale occurrences; the allowlist is sized to the legitimate KEEP set (affirmative no-mirror + de-archived prose + project-side Check-43 + the BD-194 different-surface line) — no broader. The `:4948` (HELP-FRAGMENT) and `:5447/:5515` (Check-43 project-side) borderline hits were classified KEEP with explicit evidence, not admitted as STRIP. | COMPLIANT |
| **enumerate-encoding-surfaces** | STRIP #1 (`:3705`) is a validator OUTPUT string. Grepped `scripts/tests/` + `test-fixtures/` for `v8-archive SKIPed`/`§11.3`/`all resolved to defined` (§5): NO `assert_*` pins it (3 hits are `#`-comments / retired-test prose); the only banner assertion (`test-v11-realistic-ot.sh:357 "cross-reference integrity:"`) is PRESERVED by the new text → C.9 stays GREEN. No test edited; surfaced the stale test-comments (§10). | COMPLIANT |
| **fail-loud / no-mirror accuracy** | New text describes the no-mirror, de-archived reality: "leading-underscore supporting files are not walked"; "Post-BD-203 B8 there is no `_v8-resolved-archive.md` supporting file"; "no regenerated mirror under the no-mirror model". No mirror-model language reintroduced (§3 + §4 gate). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | 3 targeted `Edit(old→new)` calls on the exact output-string / docstring / comment regions; file NOT wholesale-rewritten. Token-skeleton identical (§6) proves the rest of the file is byte-structurally untouched. | COMPLIANT |
| **verify-full-ci-suite** | Ran the FULL battery (§7), not just validate-pack: `test-validate-pack-checks-32-33-34.sh` (74/74), `test-per-entry.sh` (57/57), `test-validate-pack-check-40.sh` (7/1), `test-validate-pack-checks-36-37-38.sh` (6/2), `test-v11-realistic-ot.sh` (30/3) + the non-destructive post-`git rm` sim (`cp`-backup + mv-aside → validate → mv-back; `diff -q` byte-identical both monoliths). All counts identical to the fix-1 clean baseline; every RED is the documented end-to-end monoliths-present exit-status assertion. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `scripts/` is v11-surface → `bash test-fixtures/build.sh --all --clean` → exit 0; `git status --short test-fixtures/manifest.txt` → empty; `git diff --stat` → empty. RUN; nothing to stage. | COMPLIANT |
| **agents-never-commit** | Ran NO state-changing git verb. Only read-only: `git rev-parse HEAD` → `4c370da` (unchanged), `git status`, `git diff`, `git show HEAD:…`. No `git add/commit/push/tag/rm`. The monolith `git rm` is Pack Chat's later gated step. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line only AFTER all 3 strips + the GATE green + full verification PASSED. No partial report. No parent stop received. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered exactly the pack-side stale-prose/output strip in `scripts/validate-pack.py` (3 STRIPs). No project-side edits, no logic changes, no unrelated cleanup. The out-of-scope test-comment mentions were SURFACED (§10), not folded in. | COMPLIANT |
| **rules-applied-verification-block (+ read-in-full)** | This block; every row QUOTED evidence (none empty); per-file direct-read-proof row below for docs #1–#10. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof — docs #1–#10, each Read DIRECTLY this session)

| # | Document | Direct Read? | Proof (line count · first line · last line) |
|---|---|---|---|
| 1 | `CLAUDE.md` | YES | 576 lines · L1 "# CLAUDE.md — AI Agent Config Pack (Pack Repo)" · L576 "- OT-style v10→v11 migration is automated; OT itself is read-only for / testing (use `/tmp` clones or scratch fixtures, never write to real OT)." (read in full incl. `## Pack memory`). |
| 2 | `IMPL-BD-203-Commit2-COMPLETION-FIX1.md` | YES | 407 lines · L1 "# IMPL-BD-203-Commit2-COMPLETION-FIX1 — SHOULD-1 docstring/comment hygiene (PROSE-ONLY)" · L407 "**End of IMPL-BD-203-Commit2-COMPLETION-FIX1.md**" (the 6 corrected locations + the "Surfaced" §1/§2/§3 naming `:3699`/`:3147`/`:5433/5501/7389` read directly). |
| 3 | `PACK-REVIEW-BD-203-Commit2-COMPLETION.md` | YES | 165 lines · L1 "# PACK-REVIEW — BD-203 Commit-2 COMPLETION (D1–D5)" · L165 "**End of PACK-REVIEW-BD-203-Commit2-COMPLETION.md**" (SHOULD-1 finding §121-126 + the Check-43 `:5318-5319` mirror-skip "do NOT remove" note read directly). |
| 4 | `PLAN-BD-203-C2-COMPLETION.md` | YES | 607 lines · L1 "# PLAN-BD-203-C2-COMPLETION — close the Commit-2 gaps to a clean PREFLIGHT (then Pack Chat `git rm` + commit)" · L607 "**End of PLAN-BD-203-C2-COMPLETION.md**" (§D5 Check-43 "do NOT remove the Check-43 mirror-skip basenames" + the Check 32′/40 mechanism + EE-10 read directly). |
| 5 | `ARCHITECTURE-BD-203-V3.md` | YES | 413 lines · L1 "# ARCHITECTURE-BD-203-V3 — Shared per-entry engine co-design + the PACK conversion (no-mirror, preserve-all, reversible)" · L413 "**End of ARCHITECTURE-BD-203-V3.md**" (§2.4 mirror retire, §4 Check 32′/34/40/48 design read directly). |
| 6 | `scripts/validate-pack.py` (every occurrence + the functions they describe) | YES | Read offsets 120-139, 222-233, 298-317, 3128-3206 (`check_mirror_in_sync`/Check 32′ + `_list_unknown_files` + `known_supporting_for`), 3510-3584 (`_extract_references` + Check 34), 3610-3720 (walk loop + the `ok()` output), 4868-4881 (Check 40 banner), 4940-4954 (HELP-FRAGMENT), 5176-5195 (`excluded_basenames`), 5438-5526 (Check 43), 7185-7229 + 7392-7411 (Check 48 + call-site) directly; confirmed each function's CODE against the prose before editing. |
| 7 | `feedback_rename_plans_measure_then_bound.md` | YES | 44 lines · L1 "---" · L44 "blast-radius map feeds the gate's in-scope file set + allowlist)." |
| 8 | `feedback_fail_loud_delete_old_source.md` | YES | 55 lines · L1 "---" · L55 "caught by the architect; do not invent scope." |
| 9 | `feedback_verify_full_ci_suite.md` | YES | 43 lines · L1 "---" · L43 "`enumerate-encoding-surfaces` (CLAUDE.md), [[feedback_manifest_regen_on_v11_surface]]." |
| 10 | `feedback_edit_in_place_not_full_rewrite.md` | YES | 15 lines · L1 "---" · L15 "...[[feedback_pack_chat_no_coder_review]] (independent verification)." |

**No named document was derived rather than read.** Every verification result above (the 3 working-tree
FAILs; the 1-FAIL post-`git rm` sim with byte-identity restore; Check 32′/33/34/40 OK lines incl. the
corrected Check-34 banner; the full CI battery counts 74/74, 57/57, 7/1, 6/2, 30/3; the BEFORE/AFTER GATE
greps; the token-skeleton-identical zero-logic proof; AST OK; the empty manifest diff; HEAD `4c370da`) was
independently measured this session via Bash/Read, not carried from any prior report.

**End of IMPL-BD-203-Commit2-COMPLETION-FIX2.md**
