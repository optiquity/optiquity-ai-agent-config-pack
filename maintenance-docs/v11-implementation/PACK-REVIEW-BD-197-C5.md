# PACK-REVIEW — BD-197 C5: pack OPTIONAL-FEATURES + Guard-A (Check 53) + Guard-C (Check 56)

**Reviewer:** fresh pack-reviewer (RO). **Repo:** optiquity-ai-agent-config-pack-v11-dev.
**Branch:** `v11-dev`. **HEAD (read-only; agents never commit; unchanged pre/post):**
`9b7c74c75f8e67b9f7f3b909f2af5ba98f734c59`. **Date:** 2026-06-14.
**Scope under review:** the C5 working-tree changes (uncommitted) — `pack-ops/OPTIONAL-FEATURES.md`,
`scripts/validate-pack.py`, `.github/workflows/validate-pack.yml`, plus the two new
`scripts/tests/test-validate-pack-check-{53,56}.sh`. C5 is `pack-only`.
**Method:** independent re-verification — re-ran every matcher / check / test myself; did
NOT trust the IMPL-REPORT's numbers (cross-checked them).

---

## VERDICT: APPROVE-WITH-FIXES

C5 is correct, complete, and faithful to the spec on every load-bearing axis: the corrected
two-mechanism OPTIONAL-FEATURES model is right (3-token PREFLIGHT 10/6/4; no 9-cell / no
bgIsolation-as-trigger residue), Guard-A (Check 53) is measure-then-bound with a verified-empty
STRIP set and a genuinely narrow self-exception (independently reproduced 8/8), Guard-C (Check 56)
is a well-reasoned standalone with a substring-safe word-boundary matcher (independently reproduced
5/5), the Check-40 allowlist entry is justified + load-bearing + correctly sized, scope is clean
(no Guard-A′, no project surface, manifest empty), and the full CI battery reproduces green. The
ONLY defect is a **stale doc count (NIT)**: a code comment claims "all 20 representative §5.1 verbs"
while the canonical tuple holds **19**. One SHOULD-level observation (verb-set completeness rationale)
and two notes round it out. None blocks the commit; fix the NIT, optionally address the SHOULD.

---

## Explicit verdicts on the three asked-for judgments

### (a) Guard-A measure-then-bound + narrow self-exception — SOUND (APPROVE)
- **Measure-then-bound verified live.** I re-ran the matcher
  `rg -l --hidden --no-ignore 'no worktree isolation|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures'`
  at HEAD `9b7c74c` (2026-06-14) → **28 files**. Every single non-self hit is under
  `maintenance-docs/archive/` or `maintenance-docs/v11-implementation/`. After excluding the two
  allowlist dirs + the validator + the check-53 test: **ZERO active offenders**. STRIP set is
  empty exactly as claimed. (The coder's report said 27; my count is 28 because
  `IMPL-REPORT-BD-197-C5.md` itself now matches — it landed after the coder's measurement and is
  absorbed by the `v11-implementation/` prefix, which is precisely the re-measure-stability the
  design mandates. This +1 is expected, not a discrepancy.)
- **Directory-prefix vs per-file KEEP set — defensible, in fact MORE faithful.** The plan §B C5(iii)
  and design §13.1 describe the KEEP allowlist as a "per-file" measured set, while the coder used two
  directory prefixes (`maintenance-docs/archive/`, `maintenance-docs/v11-implementation/`). I verified
  this is NOT over-broad: (i) every matcher hit falls inside those two dirs (directory-prefix ==
  measured KEEP set exactly, no gap); (ii) both dirs are provably process/history surfaces — they are
  never shipped to clients (not in any install map) and never runtime-loaded as rules (the only
  `scripts/` references to them are code-comment provenance pointers). A static per-file list would be
  stale the moment this very review doc lands; the prefix bound honors the design's explicit
  "re-measure at commit-time / do NOT trust the static enumeration" mandate (plan §F EE-2). Decision 1
  delegates the KEEP-set representation to the coder. SOUND.
- **Narrow self-exception verified.** Validator self-skip is by name (`entry.name == "validate-pack.py"`,
  the Check-51 precedent); the test allowlist is `frozenset({"scripts/tests/test-validate-pack-check-53.sh"})`
  — the single file, NOT the whole `scripts/tests/` dir. I independently reproduced all 8 synthetic
  cases in `/tmp` (real tree never mutated): A/A2 catch injection (failures=1), B/B2 allowlisted dirs
  pass (0), C validator self-skip works (0), D check-53 test allowlisted (0), **E a DIFFERENT
  `scripts/tests/` file FAILS (failures=1) — proving the exception stays narrow**, F `baseRef`/`bgIsolation`
  keys do not trip the matcher (0). The matcher keys on the prohibition SIGNATURE only, never the
  setting-key names (G-1/G-2 satisfied).

### (b) Guard-C standalone decision — SOUND (APPROVE)
The coder's rationale ("no existing parity check fits 3 heterogeneous surface families without
over-complication") is correct on inspection:
- Checks 16/18/19 enforce BYTE parity within a single trinity location (whole-H2-block equality) —
  they neither span the non-trinity surfaces (commit-discipline ×3, pack-coder ×3, PACK-MEMORY-RATIONALE)
  nor model verb-SET membership.
- Check 45 operates over `[rationale:]` slugs; Check 46 is an anti-restate substring scan (opposite
  teeth). Neither fits a shared-vocabulary assertion.
- The 10 surfaces use three structurally different phrasings (trinity prose; the skill's bulleted
  `- \`git <verb>\`` list; pack-coder per-CLI prose incl. the Codex `.toml` mid-sentence block).
The plan (§E line 253, §J3) explicitly sanctions a standalone Check 56 "ONLY if folding
over-complicates" and makes it a coder's call (decision 8). The choice is justified, recorded, and
green-on-arrival: I ran Check 56 on the real tree → all 19 canonical §5.1 verbs + the catch-all
phrase present in all 10 surfaces (verb set consistent post-C4). The word-boundary matcher is
substring-safe (verified: "pullback"/"merged"/"cleanup"/"resetting" do NOT false-match; standalone
tokens do). Measure-then-bound + single-pass (10 single-file reads, no subprocess) + runtime-guarded
(10.6 ms). I independently reproduced all 5 synthetic cases (T1 pass; T2 dropped-verb FAIL with verb
named; T3 dropped-phrase FAIL; T4 absent-surface FAIL; T5 word-boundary decoys pass).
- **Note on C7b (surfaced, not a defect):** the coder scoped Check 56 to PACK-side surfaces only
  (verified: no `project-template` surface in `_CHECK_56_VERB_PARITY_SURFACES`), correct for a
  `pack-only` commit. Plan §B C7b (line 147) says a STANDALONE Guard-C should "extend it here [C7b] to
  cover the project verb-enumeration surfaces." The coder correctly defers this project extension to a
  C7-time call (decision 8 / J3 permit it). This is consistent with C5's scope; flagged so the C7
  coder/Pack Chat carry the open project-extension decision (Check 56 does NOT yet cover project
  surfaces — C7b is NOT made redundant).

### (c) Check-40 allowlist entry — JUSTIFIED + SIZED + NOT guard-defeating (APPROVE)
- **What Check 40 enforces:** it scans `pack-ops/*.md` for backtick-bare filename refs lacking a
  directory qualifier (`check_bare_pack_ops_refs`, line 5426); refs to pack-repo files must be
  path-qualified.
- **Why the prose tripped it:** four files named `settings.json` exist in the repo
  (`project-template/.gemini`, `project-template/.claude`, `xcode-companion-templates/...`,
  `vscode-companion-templates/.vscode`), so a bare `` `settings.json` `` ref has multiple candidates →
  Check 40's "qualify to one of: ..." failure. I proved it load-bearing: removing the
  `settings.json` allowlist entry makes Check 40 FAIL on exactly the **6** OPTIONAL-FEATURES bare refs
  (lines 116/146/151/161/192/253); restoring it → 0 failures.
- **Justified + sized + not guard-defeating:** the prose deliberately means "user OR project scope
  `settings.json`" (`~/.claude/settings.json` OR `.claude/settings.json`) — neither of which is even
  among the 4 repo candidates (those are shipped templates/companion configs, not the user's actual
  config). Qualifying to any one repo path would MISREPRESENT the documented scope choice AND point at
  the wrong file. The entry is the correct minimal fix, same external-to-pack class as the
  already-allowlisted `MEMORY.md`, with a clear inline rationale citing ARCHITECTURE-BD-179.md §6.5.
  It does NOT defer to a real issue or paper over contamination. (Note: the basename allowlist is
  repo-wide for `pack-ops/*.md`, so a future bare `settings.json` ref in any pack-ops doc would be
  exempted; acceptable — Check 40 scans only the small curated `pack-ops/` set, `settings.json` is a
  genuine external-config noun, and this matches MEMORY.md handling. Not a defect.)

---

## Findings by severity

### BLOCKER — none.

### MUST — none.

### SHOULD

- **S-1 — Guard-C verb set is a 19-verb representative SUBSET of §5.1, not the full denylist; rationale
  not recorded for the omissions.** `_CHECK_56_CANONICAL_VERBS` asserts 19 verbs. I measured that
  nine other §5.1 verbs (`add`, `rm`, `mv`, `config`, `remote`, `gc`, `tag`, `notes`, `am`) ALSO appear
  word-bounded in all 10 surfaces but are NOT asserted. The design §5.4/§13.3 says "size the assertion
  to the measured surface set" — a representative subset + the asserted catch-all phrase is a defensible
  measure-then-bound reading (a surface dropping the whole verb block still fails; the catch-all covers
  unlisted verbs). But `am` is the ONLY omission with a recorded reason (substring-unsafe); the other
  eight (`add`/`rm`/`mv`/`config`/`remote`/`gc`/`tag`/`notes`) are measured-present-and-safe yet
  silently excluded, so the guard would NOT catch a surface that drops exactly `add`/`rm`/`mv` while
  keeping the 19. **Concrete fix (optional, low-risk):** either (a) add the safe measured-present verbs
  to the canonical set (they pass the word-boundary safety test — verified), or (b) add one comment line
  stating the canonical set is a deliberate representative subset and why those eight are omitted. Not a
  blocker: parity-drift of the whole block is caught, and the catch-all is asserted.

### NIT

- **N-1 — Stale verb count in the Check 56 comment (`scripts/validate-pack.py:8595`).** The comment reads
  "all 20 representative §5.1 verbs + the catch-all principle phrase were measured present" but the
  `_CHECK_56_CANONICAL_VERBS` tuple holds **19** (I counted: commit, push, stash, reset, restore,
  checkout, clean, merge, rebase, cherry-pick, revert, apply, switch, worktree, update-ref, update-index,
  pull, filter-branch, replace). The later comment says "`am` is EXCLUDED" which implies 20−1, but the
  prose "all 20 ... measured present in ALL 10 surfaces" is internally inconsistent with a 19-entry
  asserted set (am is never measured/asserted). The runtime `ok()` message correctly uses
  `len(_CHECK_56_CANONICAL_VERBS)` = 19, so behavior is fine. **Fix:** change "all 20 representative" to
  "the 19 representative" (or "20 measured, 19 asserted (am excluded)") at line 8595.

### NOTES (no action required)

- **Note A — `IMPL-REPORT-BD-197-C5.md` correctly self-absorbs into Guard-A's allowlist** (under
  `maintenance-docs/v11-implementation/`), so the report doc does not become an active offender. This is
  the directory-prefix design working as intended.
- **Note B — `am` exclusion is correct** (substring-unsafe even with `\b`-style boundaries:
  e.g. it would word-match a standalone "am" but the comment's concern about "stream"/"command" is moot
  under the word-boundary regex — `am` as a token is still risky in natural English, so excluding it is
  the right call regardless).

---

## Independent re-verification log (command + verbatim result + HEAD + date)

All at HEAD `9b7c74c`, 2026-06-14, working tree (C5 uncommitted).

1. **OPTIONAL-FEATURES 3-token PREFLIGHT** — `grep -c '<token>' pack-ops/OPTIONAL-FEATURES.md`:
   `baseRef`=**10**, `bgIsolation`=**6**, `permissions.deny`=**4**. Matches IMPL-REPORT (10/6/4).
   Anti-check `grep -inE '9-cell|9 cell|bgIsolation.*trigger|trigger.*bgIsolation'` → **CLEAN** (no
   residue). BD-218 pointer present (line 182), BD-217 trinity-exempt note present (line 259),
   `isolation` param documented as ONLY valid value (line 142), `permissions.deny` recipe is
   VERB-PRECISE (denies `Bash(git apply:*)`, never `Bash(git diff:*)`; the `> file` redirect noted
   shell-level). Corrected model present; no 9-cell matrix.
2. **Guard-A live matcher** → 28 files, all under the two allowlist dirs + validator + check-53 test;
   **ZERO active offenders**; check-56 test does NOT match (0). Real-tree `check_worktree_isolation_prohibition_flip_block()`
   → `OK` (0 failures). 8/8 synthetic cases reproduced in `/tmp` (A/A2/E fail-on-injection; B/B2/C/D/F pass).
3. **Guard-C** real-tree `check_destructive_git_verb_parity()` → `OK`, 19 verbs + phrase across 10
   PACK surfaces. 5/5 synthetic cases reproduced. Word-boundary substring-safety verified for all 19.
   `_CHECK_56_VERB_PARITY_SURFACES` contains no `project-template` surface (correct for `pack-only`).
4. **Check 40 allowlist** — WITH entry → 0 failures; WITHOUT entry → **6** failures, all on
   `OPTIONAL-FEATURES.md` (lines 116/146/151/161/192/253). 4 `settings.json` candidate files in repo
   confirm the multi-candidate trip. Load-bearing + minimal.
5. **Tests + wiring** — both test files executable (`-rwxr-xr-x`); wired in `validate-pack.yml` lines
   220/223 (`tests` job, after Check-52 step); `bash test-validate-pack-check-53.sh` → exit 0 (3 PASS/0
   FAIL); `...check-56.sh` → exit 0 (3 PASS/0 FAIL); Check 42 (wiring gate) → `20 per-check test
   file(s) on disk; 20 workflow invocation(s); zero unwired tests`.
6. **Full CI (independent)** — `python3 scripts/validate-pack.py` → exit 0 "PASSED — all checks clean";
   `PACK_VALIDATE_DEEP=1 ...` → exit 0; NO RUNTIME-BUDGET warnings; total validate-pack wall **1.17 s**
   (<< 10 s total budget). Per-check wall (best of 3): Check 53 = **115.5 ms**, Check 56 = **10.6 ms**
   (matches IMPL-REPORT 116.1 / 10.5). Representative sample all exit 0: `test-v11-realistic-ot.sh`
   (33/33 — the BD-203/214 banner-pin trap; new banners did not break pins), `test-per-entry.sh`,
   `test-validate-pack-check-{40,42,43,45,52}.sh`, `template-translations-test.sh`,
   `template-version-test.sh`, `test-issue-forms.sh`, `test-persona-contracts.sh`,
   `build.sh --verify` (exit 0). I could NOT reproduce a 62/62 count line-by-line for all 60 tests-job
   scripts, but every script I sampled (incl. the integration banner-pin trap) was green and validate
   was clean — no non-reproduction observed.
7. **Scope/manifest** — `git status --short` = exactly the 5 C5 files + the IMPL-REPORT; no
   `project-template/` change; no Check 54 / Guard-A′ token in `validate-pack.py`. Manifest:
   `cp` backup → `build.sh --all --clean` (exit 0) → `git diff --quiet test-fixtures/manifest.txt` →
   **EMPTY** (correctly not staged) → restored via `cp`; clean. `git diff --numstat` = **pure additive**
   (158/0, 346/0, 6/0 — zero deletions; edit-in-place confirmed). OPTIONAL-FEATURES section map intact
   (new section between Agent-Teams @19 and Codex @269). HEAD unchanged pre/post (no state-changing git
   verb run by me).

---

## Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **ci-guard-design-measure-then-bound** [verify] | Guard-A: live matcher = 28 files, all under the 2 allowlist dirs + self-exception; STRIP=∅ (zero active offenders); directory-prefix bound proven == measured KEEP set (no active surface admitted; dirs never shipped/never runtime-loaded). Guard-C: 19 verbs + catch-all measured present in all 10 surfaces; `am` excluded (substring-unsafe). Check-40 entry: load-bearing (WITHOUT → 6 fails on OPTIONAL-FEATURES; WITH → 0), sized to the legitimate external-config refs, not guard-defeating. (One SHOULD: 8 safe §5.1 verbs omitted from Guard-C without recorded reason.) | COMPLIANT |
| **ci-check-runtime-compounding** [verify] | Check 53 single in-process `rglob` whole-tree walk, no subprocess/per-entry; Check 56 = 10 single-file reads, no subprocess. Wall (best of 3): 53 = 115.5 ms, 56 = 10.6 ms — both << 2000 ms WARN budget. Total validate-pack 1.17 s << 10 s. No RUNTIME-BUDGET warning in general or DEEP. | COMPLIANT |
| **enumerate-encoding-surfaces** [verify] | OPTIONAL-FEATURES + Guard-A (Check 53) + Guard-C (Check 56) + the 2 new tests + the 2 yml steps all present and in lockstep in the one C5 changeset; Check 42 confirms no unwired test (20/20). | COMPLIANT |
| **verify-full-ci-suite** [universal] | Re-ran validate-pack general + DEEP (exit 0), both new tests (3/0 each), and a representative sample incl. the `test-v11-realistic-ot.sh` integration banner-pin trap (33/33) — all green; no non-reproduction. | COMPLIANT |
| **edit-in-place-not-full-rewrite** [verify] | `git diff --numstat` = pure additive (0 deletions in all 3 modified files); OPTIONAL-FEATURES section map intact (new H2 inserted between Agent-Teams and Codex); validate-pack.py = additive check blocks + 2 `run_check` registrations + 1 allowlist entry. | COMPLIANT |
| **regenerate-manifest-v11-surface** [verify] | `build.sh --all --clean` (exit 0) → manifest diff EMPTY → correctly not staged; restored via `cp` (not git-checkout); `build.sh --verify` exit 0; manifest status clean. No denied-verb residue. | COMPLIANT |
| **empirical-evidence-blocks** [reviewer] | Every claim above carries the command + verbatim output + HEAD `9b7c74c` + date 2026-06-14 (see re-verification log §1–§7). | COMPLIANT |
| **scope-deliverables-to-the-ask** [universal] | C5 is `pack-only`: no `project-template/` change, no Guard-A′ (Check 54) token, no project surface in Guard-C. Surfaced the real findings (N-1 stale count, S-1 verb-subset, C7b open project-extension) without inventing nits or softening. | COMPLIANT |
| **agents-never-commit** [universal] | Only read-only git (`git rev-parse`, `git status`, `git diff --numstat/--quiet`); used `cp` for manifest backup/restore, no `git checkout`/`add`/`commit`. HEAD unchanged `9b7c74c`. The single file I wrote is this report. | COMPLIANT |
| **rules-applied-verification-block** [universal] | This block. | COMPLIANT |

---

## Recommendation to Pack Chat

APPROVE-WITH-FIXES. Triage:
- **N-1 (NIT, fix):** correct "all 20 representative" → "the 19" at `scripts/validate-pack.py:8595`.
- **S-1 (SHOULD, fix-or-record):** either add the safe measured-present §5.1 verbs to
  `_CHECK_56_CANONICAL_VERBS` or add one comment line declaring the canonical set a deliberate
  representative subset and why `add/rm/mv/config/remote/gc/tag/notes` are omitted.
- **C7b note:** carry forward that Check 56 covers PACK surfaces only; the project verb-parity
  extension remains an open C7-time decision (Guard-C standalone did NOT make C7b redundant).
Both fixes are one-line edits; route to fix-coder per the bounded cycle (Pack Chat does no fixes).
The 19-verb subset + catch-all phrase already protect against whole-block parity drift, so neither
finding blocks the commit if the user elects to defer S-1 as tracked tech debt.

---

## Review-2 (S-1/N-1 fix verification)

**VERDICT: APPROVE-WITH-FIXES** — the S-1 widening (19 → 27) and N-1 comment fix
are both correct, load-bearing, and CI-green; the one residual is that the `am`
kept-omission's RECORDED RATIONALE states a false mechanism (a NIT, N-2 below) —
the omission outcome is safe but the rationale, which the S-1 instruction
explicitly required, is unsound and should be corrected or `am` simply added.

**Reviewer:** FRESH pack-reviewer (RO), review-2, independent re-run (did NOT
trust the coder's report). **HEAD (read-only; agents never commit; unchanged
pre/post):** `9b7c74c75f8e67b9f7f3b909f2af5ba98f734c59`. **Date:** 2026-06-14.

### Read attestation (up front)
Read IN FULL before verifying, directly (not derived):
- `scripts/validate-pack.py` Check 56 region (lines 8569–8718: the
  MEASURE-THEN-BOUND comment block, `_CHECK_56_VERB_PARITY_SURFACES`,
  `_CHECK_56_CANONICAL_VERBS`, `_check_56_verb_present`,
  `check_destructive_git_verb_parity`) + the working-tree `git diff` of that file.
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C5.md`
  `## Fix pass (S-1 ... + N-1 ...)` section (lines 637–962) IN FULL, plus the
  base IMPL-REPORT for context.
- `scripts/tests/test-validate-pack-check-56.sh` (the dynamic-tuple read at
  line 92; Group 0/1/2 structure).
- One surface denylist verbatim
  (`.claude/skills/commit-discipline/SKILL.md` denylist region, via the actual
  matcher contexts) to confirm verb-consistency.
- `CLAUDE.md` `## Pack memory` (the rules-in-force set) in full.

Every claim below carries command + verbatim output + HEAD-SHA + date.

### 1. Verb set widened correctly (27; 8 added; `am` is the one exception)

**EB-R2-1 — tuple is 27 with all 8 additions; `am` absent.**
Command (module import):
```
len: 27
verbs: ('commit', 'push', 'stash', 'reset', 'restore', 'checkout', 'clean',
'merge', 'rebase', 'cherry-pick', 'revert', 'apply', 'switch', 'worktree',
'update-ref', 'update-index', 'pull', 'filter-branch', 'replace', 'add', 'rm',
'mv', 'config', 'remote', 'gc', 'tag', 'notes')
am present? False
all 8 added present? True
```
Conclusion: **SUPPORTED** — 19 → 27, the 8 (`add`/`rm`/`mv`/`config`/`remote`/
`gc`/`tag`/`notes`) are all present, `am` is the lone exclusion.

**EB-R2-2 — all 27 present-and-consistent across all 10 surfaces (no false-pos).**
Ran the ACTUAL `_check_56_verb_present` matcher for each of the 27 verbs against
each of the 10 `_CHECK_56_VERB_PARITY_SURFACES`. Verbatim: every one of the 27
rows = `ALL` (Y in all 10 columns); `ALL 27 VERBS PRESENT IN ALL 10 SURFACES:
True`. Independently reproduces the coder's EB-2 (the 8 added) and extends it to
the full 27. Conclusion: **SUPPORTED** — the asserted set is sized exactly to
the measured-consistent set; no surface false-positives.

**`am`-exception soundness — N-2 (NIT, NEW): the recorded rationale is FALSE.**
The S-1 instruction required any kept-omitted verb be omitted *because it can't
assert cleanly*, WITH a recorded rationale. The recorded rationale (code comment
lines 8601–8603 and 8624–8626; IMPL-REPORT fix-pass table) states:
`am` is "substring-unsafe — `\b am \b` false-matches inside 'stream'/'command'".
**Both halves of that mechanism are wrong:**
- (a) The matcher is NOT `\b am \b`; it is `(?<![\w-])am(?![\w-])`
  (`_check_56_verb_present`, line 8656).
- (b) That matcher does NOT false-match `stream`/`command`. Verbatim test of the
  actual matcher: `'stream' -> False`, `'command' -> False`, `'commands' ->
  False`, `'streaming' -> False`, `'diagram' -> False`, `'ambient' -> False`.
  The only positive hits are bare-token `am` contexts (`'I am here' -> True`,
  `'git am' -> True`).

The genuine risk for `am` is the standalone English auxiliary "am" (e.g. "I am"),
NOT the substring case the comment names. I then measured whether that risk is
real on the 10 surfaces: the bounded-`am` matcher fires **exactly once per
surface in all 10**, and in EVERY case the single hit is the legitimate git-verb
token (`` `am` `` in the trinity/RATIONALE prose; `` `git am` `` in the
skill/pack-coder surfaces) — never a stray English "am". Decisive proof: adding
`am` to the canonical set and re-running the check against faithful synthetic
copies of all 10 surfaces yields `failures=0` (`OK: ... all 28 canonical §5.1
verbs ... present in each`). So **`am` WOULD assert cleanly** — it does not meet
the "can't assert cleanly" bar the omission rationale claims.

Net: the OUTCOME (omitting `am`) is harmless and conservative — Check 56 stays
green, `am` is still covered by the catch-all phrase — but the RECORDED RATIONALE
is unsound (describes a non-existent failure mode of a regex that isn't the one
in use). Since S-1 demanded a *sound* recorded rationale for any omission, this
is a real-but-minor gap. Cleanest fixes (either): (i) add `am` to the tuple
(proven clean, makes it the full 28-of-28 §5.1 set); or (ii) keep it omitted but
rewrite the rationale to the correct mechanism ("`am` is the standalone-English-
word risk; matched bounded it currently hits only the real verb token, but it is
held out conservatively to avoid a future English-`am` false-positive on these
prose surfaces"). Option (i) is the more faithful reading of "widen to the FULL
§5.1 set."

### 2. Guard-C GREEN + load-bearing (independent mutation-catch)

**EB-R2-3 — validate-pack exit 0 (general + DEEP); Check 56 reports 27.**
```
=== validate-pack general ===  EXIT=0
  OK: Check 56 (Guard-C) — ... all 27 canonical §5.1 verbs + the catch-all
  principle phrase present in each.
PASSED — all checks clean
=== validate-pack DEEP ===     EXIT=0   (same Check-56 line; PASSED)
```
Conclusion: **SUPPORTED.**

**EB-R2-4 — each new verb is LOAD-BEARING (synthetic /tmp mutation; NO real-tree
mutation, NO git checkout).** Built faithful synthetic copies of all 10 surfaces
under `tempfile.mkdtemp`, pointed `mod.REPO_ROOT` there, and dropped each new
verb (one at a time) from `CLAUDE.md`, then ran
`check_destructive_git_verb_parity`. Baseline (no drop) = `failures=0` (green).
Verbatim per-verb:
```
drop add      -> NEW failures=1  CAUGHT=True
drop rm       -> NEW failures=1  CAUGHT=True
drop mv       -> NEW failures=1  CAUGHT=True
drop config   -> NEW failures=1  CAUGHT=True
drop remote   -> NEW failures=1  CAUGHT=True
drop gc       -> NEW failures=1  CAUGHT=True
drop tag      -> NEW failures=1  CAUGHT=True
drop notes    -> NEW failures=1  CAUGHT=True
```
Each failure named the dropped verb + the surface (e.g. "CLAUDE.md is MISSING
destructive git verb(s) from the §5.1 denylist: add"). The synthetic tree was
torn down; the real tree was never touched. Conclusion: **SUPPORTED** — the
widening is genuinely load-bearing on all 8 added verbs, not a no-op. This
independently reproduces the coder's EB-6 (8/8 `CAUGHT=True`).

### 3. Comment correct + auto-tracking runtime message

**EB-R2-5 — no stale count; history note intact; `len(...)` interpolation.**
```
grep "all 20|all 19" scripts/validate-pack.py  -> NONE FOUND
grep "len(_CHECK_56_CANONICAL_VERBS)"           -> 8715: f"all {len(...)} canonical §5.1 verbs ..."
8595: # ... all 27 verbs of the FULL §5.1 set asserted
8598: # widened the asserted tuple from the 19-verb representative subset to the
```
The comment says "all 27 verbs of the FULL §5.1 set"; the only "19" is the
intentional history note ("from the 19-verb representative subset"); the runtime
`ok()` message interpolates `len(_CHECK_56_CANONICAL_VERBS)` so the count
auto-tracks the tuple. Conclusion: **SUPPORTED** — N-1 fully resolved.
(Caveat: the comment's `am` clause carries the unsound rationale flagged as N-2.)

### 4. Test consistency (dynamic, no hardcoded count)

**EB-R2-6 — check-56 test reads the tuple dynamically and passes.**
```
bash scripts/tests/test-validate-pack-check-56.sh   EXIT=0   (PASS:3 / FAIL:0)
line 92: VERBS = list(mod._CHECK_56_CANONICAL_VERBS)
```
No hardcoded `19`/`20`/`27` count in the test; it lists the tuple from the module
so the 27-verb set flows through T1–T5 (incl. T5 word-boundary safety on
`command`/`stream`/`pullback`). No test edit was required by the widening.
Conclusion: **SUPPORTED.**

### 5. Full CI (independent; no non-reproduction)

**EB-R2-7 — validate-pack (general + DEEP) + representative sample all green.**
```
validate-pack general                  EXIT=0   PASSED — all checks clean
validate-pack DEEP (PACK_VALIDATE_DEEP) EXIT=0   PASSED — all checks clean
test-validate-pack-check-56.sh          EXIT=0   (3/0)
test-validate-pack-check-53.sh          EXIT=0   (bundle sibling)
test-validate-pack-check-52.sh          EXIT=0   (most-recent prior guard)
test-validate-pack-check-42.sh          EXIT=0   (CI-wiring gate)
test-validate-pack-check-51-flip-block.sh EXIT=0
test-validate-pack-check-16/18/19.sh    EXIT=0   (trinity parity)
test-v11-realistic-ot.sh                EXIT=0   (INTEGRATION banner-pin trap)
```
No RUNTIME-BUDGET warning fired. The banner-pin trap test (the BD-203/BD-214
historic CI-RED) PASSED — the "all 27" success-message change did not break any
pinned-output assertion. I did not re-run all 64 scripts the coder reported, but
every directly-affected check + the historically-fragile integration test + a
trinity/wiring/flip-block sample all reproduce green; no non-reproduction of the
coder's 64/64 in the sampled set. Conclusion: **SUPPORTED.**

### 6. No collateral / no denied-verb residue

**EB-R2-8 — `git status --short` = exactly the C5 bundle; manifest clean; HEAD
unchanged; no denied-verb residue.**
```
 M .github/workflows/validate-pack.yml
 M pack-ops/OPTIONAL-FEATURES.md
 M scripts/validate-pack.py
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C5.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-C5.md
?? scripts/tests/test-validate-pack-check-53.sh
?? scripts/tests/test-validate-pack-check-56.sh

git status --short test-fixtures/manifest.txt   -> (empty — clean)
shasum test-fixtures/manifest.txt               -> 8337c164449d51bd46fc3224f22bbe56b179d3d3
git rev-parse HEAD                              -> 9b7c74c75f8e67b9f7f3b909f2af5ba98f734c59
git reflog -n1                                  -> 9b7c74c ... (no fix-era commit/checkout/stash)
```
The S-1/N-1 fix touched `scripts/validate-pack.py` (Check 56 region only — diff
confirms `_CHECK_56_CANONICAL_VERBS` +8 verbs + the comment edits) plus the
IMPL-REPORT `## Fix pass` append; the rest of the bundle is the prior C5 state.
The whole C5 is uncommitted as one working-tree state (no committed prior-C5
checkpoint to diff against), so the "fix touched only validate-pack.py +
IMPL-REPORT" claim is verified by the diff hunks, not a commit-to-commit diff —
the bundle is exactly the 7 expected paths, no stray file. Manifest matches the
report's `8337c16…`, status clean, HEAD unchanged, no denied-verb residue from
the cp-restore. Conclusion: **SUPPORTED.**

### Triage recommendation to Pack Chat (review-2)

- **N-1 (NIT) — RESOLVED.** No fix needed.
- **S-1 (SHOULD) — RESOLVED in substance.** The widening is correct, complete to
  27, load-bearing, and CI-green. No fix needed for the widening itself.
- **N-2 (NIT, NEW) — fix-or-record.** The `am` kept-omission rationale states a
  false mechanism. Default per `feedback-fix-all-review-findings`: FIX. Smallest
  faithful fix = add `am` to `_CHECK_56_CANONICAL_VERBS` (proven to assert
  cleanly, → full 28/28 §5.1 set) and update the count wording; alternatively
  keep it omitted but rewrite the rationale to the correct standalone-English-
  word mechanism. This is a comment-accuracy / instruction-faithfulness NIT, not
  a correctness blocker — Check 56 is green and `am` is covered by the catch-all
  either way. Route to fix-coder per the bounded cycle (Pack Chat does no fixes).

The fix is a one-symbol + one-comment edit; it does not block the commit if the
user elects to defer N-2 as tracked tech debt.

### Rules-Applied Verification Block (review-2)

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **ci-guard-design-measure-then-bound** [verify] | Independently re-measured all 27 verbs present-and-consistent across all 10 surfaces with the ACTUAL matcher (EB-R2-2, every row `ALL`); asserted set sized exactly to that measured set; load-bearing proven by synthetic `/tmp` mutation — dropping each of the 8 new verbs → `failures=1 CAUGHT=True` (EB-R2-4); baseline green. The one §5.1 exception (`am`) IS recorded — but the recorded rationale is FALSE (the matcher is `(?<![\w-])am(?![\w-])` not `\b am \b`; it does NOT false-match `stream`/`command`; `am` adds cleanly → `all 28`, failures=0). Omission is safe but the rationale is unsound (N-2). | COMPLIANT (with N-2 NIT on the `am` rationale soundness) |
| **verify-full-ci-suite** [universal] | Re-ran validate-pack general + DEEP (both exit 0, Check 56 = "all 27"); check-56 test (3/0); + representative sample check-53/52/42/51/16/18/19 + the `test-v11-realistic-ot.sh` integration banner-pin trap — all EXIT=0 (EB-R2-3, EB-R2-7). No RUNTIME-BUDGET warning. No non-reproduction in the sampled set. | COMPLIANT |
| **enumerate-encoding-surfaces** [verify] | The check (`_CHECK_56_CANONICAL_VERBS`=27), its MEASURE-THEN-BOUND comment ("all 27 FULL §5.1 set"), the constant comment, the runtime `ok()` message (`len(...)`=27 auto-tracks), and the test (dynamic `list(mod._CHECK_56_CANONICAL_VERBS)`, no hardcoded count) are all consistent at 27 (EB-R2-1, EB-R2-5, EB-R2-6). No asymmetry. | COMPLIANT |
| **empirical-evidence-blocks** [reviewer] | Every claim carries command + verbatim output + HEAD `9b7c74c` + date 2026-06-14 (EB-R2-1..EB-R2-8). | COMPLIANT |
| **agents-never-commit** [universal] | Only read-only git verbs (`git rev-parse`, `git status`, `git diff`, `git reflog`); mutation proof used in-process synthetic `/tmp` trees (no real-tree mutation, no `git checkout`/`add`/`commit`/`stash`). HEAD unchanged `9b7c74c` (EB-R2-8). The only file I wrote is this review doc. | COMPLIANT |
| **rules-applied-verification-block** [universal] | This block. | COMPLIANT |

---

## Review-3 (final, N-2 fix verification + C5 readiness)

**VERDICT: APPROVE** — the N-2 fix landed correctly (`am` added → Guard-C asserts
the FULL 28-verb §5.1 set with NO exceptions, the false `am`-omission rationale
replaced by a historical-correction note, the count comment now 28); the guard
is load-bearing and false-positive-free on `am`, the full CI battery is green,
the bundle is exactly the 7 expected C5 paths with no collateral or denied-verb
residue, and nothing previously approved (OPTIONAL-FEATURES, Guard-A/Check 53,
the Check-40 allowlist entry) regressed — C5 is sound for commit.

**Reviewer:** FRESH pack-reviewer (RO), review-3 (final pass), INDEPENDENT
re-run — did NOT trust the coder's report. **HEAD (read-only; agents never
commit; unchanged pre/post):** `9b7c74c75f8e67b9f7f3b909f2af5ba98f734c59`.
**Date:** 2026-06-14. **Bounded-cycle position:** this is the cycle's final
reviewer pass (review-1 → S-1/N-1 fix → review-2 → N-2 fix → THIS review-3);
no fix pass follows a clean final reviewer pass.

### Read attestation (up front)
Read IN FULL before verifying, directly (not derived):
- `scripts/validate-pack.py` Check 56 region (lines 8569–8722: the
  MEASURE-THEN-BOUND comment block, `_CHECK_56_VERB_PARITY_SURFACES`,
  `_CHECK_56_CANONICAL_VERBS`, the constant header comment, `_check_56_verb_present`,
  `check_destructive_git_verb_parity`, the `ok()` success message) + the
  `_CHECK_40_ALLOWLIST` region (lines 5181–5206).
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C5.md` IN FULL,
  including the `## Fix pass 2 (N-2: add am → Guard-C 28/28)` section
  (lines 966–1315) and the base report + the S-1/N-1 fix pass.
- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-C5.md` review-1
  (APPROVE-WITH-FIXES; raised S-1/N-1) + review-2 (APPROVE-WITH-FIXES; S-1/N-1
  resolved, raised N-2 on the false `am` rationale) — my predecessor passes,
  for continuity of what was already APPROVED.
- `scripts/tests/test-validate-pack-check-56.sh` (the dynamic-tuple read at
  line 92).
- `CLAUDE.md` `## Pack memory` (the rules-in-force set) in full.

Every claim below carries command + verbatim output + HEAD-SHA + date.

### 1. 28/28 + no live omission rationale + count comment 28 (the N-2 fix landed)

**EB-R3-1 — tuple holds 28 unique verbs including `am` (module import).**
Command: `python3 -c` importing `validate-pack.py`, printing the tuple.
Verbatim output (HEAD `9b7c74c`, 2026-06-14):
```
count: 28
am present: True
apply present: True
unique: True
verbs: ['commit', 'push', 'stash', 'reset', 'restore', 'checkout', 'clean',
'merge', 'rebase', 'cherry-pick', 'revert', 'apply', 'switch', 'worktree',
'update-ref', 'update-index', 'pull', 'filter-branch', 'replace', 'add', 'rm',
'mv', 'config', 'remote', 'gc', 'tag', 'notes', 'am']
```
Conclusion: **SUPPORTED** — the canonical set is the FULL 28-verb §5.1 set,
`am` present, `apply` included, no duplicates.

**EB-R3-2 — NO live `am`-omission rationale remains (only historical-correction).**
Command: `grep -n "kept-omitted|EXCLUDED here|kept-omission|risks a parity
false-positive|ONLY §5.1 denied verb" scripts/validate-pack.py`.
Verbatim output: `NONE (no live omission rationale)`.
Command: `grep -n "substring-unsafe" scripts/validate-pack.py`.
Verbatim output:
```
8604:# "command" / "spam" / "amend" (review-2 proved the old "substring-unsafe"
8636:# "substring-unsafe" rationale). Sized to the measured-consistent set, which
```
Interpretation: the only two surviving `substring-unsafe` strings are framed as
the FALSE prior rationale being CORRECTED ("review-2 proved the old … false" /
"review-2 disproved the prior 'substring-unsafe' rationale") — historical-
correction notes, NOT a live omission rationale (which the prompt explicitly
permits). Conclusion: **SUPPORTED** — N-2's rationale-removal is complete.

**EB-R3-3 — count comment says 28; no stale 27.**
Command: `grep -n "all 28 verbs|28-verb set|28 verbs, no exceptions|NO
exceptions" scripts/validate-pack.py` and `grep -n "all 27|27 verbs"
scripts/validate-pack.py`.
Verbatim output:
```
8595:# fix (HEAD 9b7c74c, 2026-06-14): all 28 verbs of the FULL §5.1 set asserted
8601:# FULL §5.1 set with NO exceptions, sized to the measured-consistent set.
8626:# the complete 28-verb set with NO exceptions, measured present in ALL 10
8645:    # N-2 addition (completes the full §5.1 set — 28 verbs, no exceptions):
("all 27|27 verbs" -> NONE FOUND)
```
The only "27" tokens are the intentional history notes ("S-1 widened to 27";
"S-1 widened the asserted tuple from the 19-verb representative subset"). The
runtime `ok()` message interpolates `len(_CHECK_56_CANONICAL_VERBS)` so it
auto-tracks. Conclusion: **SUPPORTED** — comment/count fully corrected to 28.

### 2. Green + load-bearing + no false-positive (the 28/28 proof)

**EB-R3-4 — validate-pack general + DEEP both exit 0; Check 56 reports 28.**
Command: `python3 scripts/validate-pack.py` and
`PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py`.
Verbatim output:
```
GENERAL EXIT=0
  OK: Check 56 (Guard-C) — destructive-git-verb enumeration parity holds across 10 surface(s) (trinity ×3, PACK-MEMORY-RATIONALE, commit-discipline ×3, pack-coder ×3): all 28 canonical §5.1 verbs + the catch-all principle phrase present in each.
PASSED — all checks clean
DEEP EXIT=0   (identical Check-56 line; PASSED — all checks clean)
```
No RUNTIME-BUDGET warning fired. (The only WARNs in either run are the
pre-existing Check-48 soft-advisory removed-doc citations — 14 across 2 tree
dirs, "advisory only, exit code unaffected" — unrelated to C5, present on both
runs, not a C5 regression.) Conclusion: **SUPPORTED.**

**EB-R3-5 — `am` present-and-consistent on all 10 surfaces under the REAL matcher;
no false-match of stream/command/amend.**
Command: ran `(?<![\w-])am(?![\w-])` against each of the 10
`_CHECK_56_VERB_PARITY_SURFACES`, plus a false-positive probe.
Verbatim output:
```
PRESENT count=1 CLAUDE.md
PRESENT count=1 AGENTS.md
PRESENT count=1 GEMINI.md
PRESENT count=1 pack-ops/PACK-MEMORY-RATIONALE.md
PRESENT count=1 .claude/skills/commit-discipline/SKILL.md
PRESENT count=1 .codex/skills/commit-discipline/SKILL.md
PRESENT count=1 .gemini/skills/commit-discipline/SKILL.md
PRESENT count=1 .claude/agents/pack-coder.md
PRESENT count=1 .codex/agents/pack-coder.toml
PRESENT count=1 .gemini/agents/pack-coder.md
ALL 10 PRESENT: True
---
'stream'   match=False   'command'  match=False   'commands' match=False
'amend'    match=False   'spam'     match=False   'diagram'  match=False
'git am'   match=True     'bare am'  match=True
```
Interpretation: `am` appears exactly once per surface (the real git-verb token),
and the matcher does NOT false-match `stream`/`command`/`amend`/`spam`/`diagram`
— independently DISPROVES the old "substring-unsafe" rationale. Conclusion:
**SUPPORTED.**

**EB-R3-6 — dropping `am` from a surface FAILS Check 56, and ONLY `am` flags
(load-bearing + no false-positive). In-memory mutation; NO real-tree mutation,
NO git checkout.**
Command: read `.claude/skills/commit-discipline/SKILL.md` in-memory, `re.sub`'d
out the `am` token via `(?<![\w-])am(?![\w-])`, ran the module's own
`_check_56_verb_present` for every canonical verb against the mutated string.
Verbatim output:
```
real has am: True
mutated has am: False
missing on mutated: ['am']
ONLY am flagged (no false-positive on other 27): True
```
Interpretation: `am` is genuinely load-bearing (drop ⇒ FAIL) and its addition
introduces NO false-positive on the other 27 verbs. The real tree was never
touched. Conclusion: **SUPPORTED** — Guard-C = full 28-verb set, no exception,
load-bearing, no false-positive (ci-guard-design-measure-then-bound satisfied).

### 3. Test reads tuple dynamically + passes

**EB-R3-7 — check-56 test tracks the tuple, no hardcoded count, passes.**
Command: `bash scripts/tests/test-validate-pack-check-56.sh` +
`grep -n "VERBS = list(mod._CHECK_56_CANONICAL_VERBS)" <test>`.
Verbatim output:
```
EXIT=0   All tests passed.
92: VERBS = list(mod._CHECK_56_CANONICAL_VERBS)
(grep for any hardcoded 2X count in the test -> NONE)
```
Interpretation: the test reads the 28-verb tuple from the module (line 92), so
the new verb flows through T1–T5 (incl. T5 word-boundary safety) automatically;
no hardcoded count → no test edit required by N-2. Conclusion: **SUPPORTED.**

### 4. Full CI (independent; no non-reproduction of the coder's 62/62)

**EB-R3-8 — validate ×2 + check-56 + representative sample (incl. the
integration banner-pin trap) all green.**
Command + verbatim EXIT per script:
```
python3 scripts/validate-pack.py                         EXIT=0  (PASSED)
PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py    EXIT=0  (PASSED)
test-validate-pack-check-56.sh                           EXIT=0  (All tests passed)
test-validate-pack-check-53.sh   (bundle sibling)        EXIT=0
test-validate-pack-check-52.sh   (most-recent prior guard) EXIT=0
test-validate-pack-check-42.sh   (CI-wiring gate)        EXIT=0
test-validate-pack-check-51-flip-block.sh                EXIT=0
test-validate-pack-check-16.sh   (trinity parity)        EXIT=0
test-validate-pack-check-40.sh   (the Check-40 allowlist gate) EXIT=0
test-v11-realistic-ot.sh         (INTEGRATION banner-pin trap) EXIT=0  (33/33)
```
The historically-fragile integration banner-pin trap (`test-v11-realistic-ot.sh`,
the BD-203/BD-214 CI-RED) PASSED — the "all 28" success-message change did NOT
break any pinned-output assertion. I did not re-run all 62 the coder reported,
but every directly-affected check + the Check-40 gate + the integration trap +
a trinity/wiring/flip-block sample all reproduce GREEN; no non-reproduction in
the sampled set (the coder's 62/62 is consistent with the sample). Conclusion:
**SUPPORTED.**

### 5. No collateral / C5 bundle intact / no denied-verb residue

**EB-R3-9 — `git status --short` = exactly the 7-file C5 bundle; manifest clean;
HEAD unchanged; reflog shows no fix-era state change.**
Verbatim output:
```
 M .github/workflows/validate-pack.yml
 M pack-ops/OPTIONAL-FEATURES.md
 M scripts/validate-pack.py
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C5.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-C5.md
?? scripts/tests/test-validate-pack-check-53.sh
?? scripts/tests/test-validate-pack-check-56.sh

git status --short test-fixtures/manifest.txt  -> (empty — clean)
shasum test-fixtures/manifest.txt              -> 8337c164449d51bd46fc3224f22bbe56b179d3d3
git rev-parse HEAD                             -> 9b7c74c75f8e67b9f7f3b909f2af5ba98f734c59
git reflog -n1                                 -> 9b7c74c HEAD@{0}: commit: feat: v11 — BD-197 P3 ... (pack-only)
```
The bundle is exactly the 7 expected paths (OPTIONAL-FEATURES, validate-pack.py,
the yml, the 2 check tests, the IMPL-REPORT, this PACK-REVIEW) — no stray file.
The whole C5 is one uncommitted working-tree state (no committed prior-C5
checkpoint), so the "N-2 touched only validate-pack.py + IMPL-REPORT" claim is
verified by the N-2 IMPL-REPORT diff hunks (tuple +`am`, 2 comment blocks
rewritten, count 27→28) + the file-set, not a commit-to-commit diff. Manifest
matches the report's `8337c16…`, HEAD unchanged, reflog shows no fix-era
commit/checkout/stash. Conclusion: **SUPPORTED** — no collateral, no denied-verb
residue.

**EB-R3-10 — independent manifest regen → empty diff (restored via `cp`).**
Command: `cp` backup → `bash test-fixtures/build.sh --all --clean` (exit 0) →
`git diff --quiet test-fixtures/manifest.txt` → `cp`-restore.
Verbatim output: `build EXIT=0` / `MANIFEST DIFF: EMPTY` / `restored via cp` /
`git status --short test-fixtures/manifest.txt` empty. NO `git checkout` used.
Conclusion: **SUPPORTED** — pack-side commit, manifest correctly not staged.

### 6. Overall C5 readiness (nothing previously approved regressed)

**EB-R3-11 — OPTIONAL-FEATURES 3 tokens present + anti-checks clean.**
Command: `grep -c <token>` for `baseRef`/`bgIsolation`/`permissions.deny` +
the removed-model anti-check.
Verbatim output:
```
baseRef = 10   bgIsolation = 6   permissions.deny = 4
(9-cell / bgIsolation-as-trigger anti-check) -> NONE (clean)
```
Conclusion: **SUPPORTED** — the pack-side OPTIONAL-FEATURES half (review-1
APPROVED) is intact; no removed-model residue.

**EB-R3-12 — Check-40 `settings.json` allowlist entry intact.**
Command: `grep -n "settings.json.*scope-agnostic" scripts/validate-pack.py`.
Verbatim output:
```
5206: "settings.json": "Claude-Code user/project config (external to pack repo; scope-agnostic per BD-197 OPTIONAL-FEATURES)",
```
Plus `test-validate-pack-check-40.sh` EXIT=0 (EB-R3-8). Conclusion: **SUPPORTED**
— the Check-40 allowlist entry (review-1 APPROVED) is present and the Check-40
gate is green.

**Overall C5-readiness statement.** All three asked-for review-1/review-2
APPROVED items remain sound and unregressed: the pack OPTIONAL-FEATURES isolation
section (3 tokens present, no removed-model residue), Guard-A = Check 53 (its
dedicated test green; allowlist + narrow self-exception untouched), and the
Check-40 `settings.json` allowlist entry (present + gate green). Guard-C = Check
56 is now the FULL 28-verb §5.1 set with NO exceptions, load-bearing on `am`,
false-positive-free, comment/count/runtime-message all consistent at 28, and its
dynamic-tuple test passes. The full CI sample (incl. the historically-fragile
integration banner-pin trap) is green. The bundle is exactly the 7 expected
paths with a clean manifest and an unchanged HEAD. **C5 is sound for commit.**
The single residual finding from review-2 (N-2, the false `am` rationale) is
RESOLVED. No new findings (no BLOCKER / MUST / SHOULD / NIT) surfaced in this
final pass.

### Rules-Applied Verification Block (review-3)

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **ci-guard-design-measure-then-bound** [verify] | Guard-C is the FULL 28-verb §5.1 set, NO exception (EB-R3-1: `count: 28`, `am present: True`, `unique: True`; EB-R3-3: comment "complete 28-verb set with NO exceptions"). LOAD-BEARING + NO false-positive proven independently: EB-R3-6 `missing on mutated: ['am']`, `ONLY am flagged: True` (drop `am` ⇒ FAIL, and only `am` flags); EB-R3-5 all 10 surfaces `PRESENT count=1` under the real matcher, which does NOT false-match `stream`/`command`/`amend`/`spam`/`diagram`; EB-R3-4 runtime `all 28 canonical §5.1 verbs … present in each`, exit 0. The false `am`-omission rationale is GONE (EB-R3-2: no `kept-omitted`/`EXCLUDED here`/`risks a parity false-positive`; surviving `substring-unsafe` strings are historical-correction prose). Sized to the measured-consistent set = full §5.1 set, no broader. | COMPLIANT |
| **verify-full-ci-suite** [universal] | Independently re-ran validate-pack general + DEEP (both EXIT=0, Check 56 = "all 28"; no RUNTIME-BUDGET warning) + check-56 test (passed, dynamic tuple) + a representative sample check-53/52/42/51/16/40 + the `test-v11-realistic-ot.sh` INTEGRATION banner-pin trap (EXIT=0, 33/33) — all green (EB-R3-4, EB-R3-7, EB-R3-8). No non-reproduction of the coder's 62/62 in the sampled set; the banner-pin trap (BD-203/BD-214 historic CI-RED) PASSED with the "all 28" message change. | COMPLIANT |
| **empirical-evidence-blocks** [reviewer] | Every claim carries command + verbatim output + HEAD-SHA (`9b7c74c`) + date (2026-06-14): EB-R3-1 (tuple 28/unique/am), EB-R3-2 (no live omission rationale), EB-R3-3 (count 28, no stale 27), EB-R3-4 (validate ×2 green), EB-R3-5 (10/10 present + no false-match), EB-R3-6 (mutation-catch + only-am), EB-R3-7 (test dynamic + pass), EB-R3-8 (CI sample), EB-R3-9 (bundle/manifest/HEAD/reflog), EB-R3-10 (manifest regen empty), EB-R3-11 (OPTIONAL-FEATURES tokens), EB-R3-12 (Check-40 entry). | COMPLIANT |
| **agents-never-commit** [universal] | Ran ONLY read-only git verbs (`git rev-parse`, `git status`, `git diff`, `git reflog`); the mutation proof (EB-R3-6) used an in-memory string copy (no real-tree mutation, no `git checkout`); the manifest regen (EB-R3-10) used `cp` backup/restore (no `git checkout`). NO `git add`/`commit`/`stash`/`checkout` run. HEAD unchanged `9b7c74c` pre+post (EB-R3-9). The only file I wrote is this review doc. | COMPLIANT |
| **rules-applied-verification-block** [universal] | This block. | COMPLIANT |
