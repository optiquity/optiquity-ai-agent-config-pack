# PACK REVIEW — Batch 19b-2-RC9 — Trinity manifest-regen rule (RC9)

**Reviewer:** pack-reviewer (19b-2-RC9 review)
**Date:** 2026-05-17
**Branch:** v11-dev
**Base HEAD:** `ef9e5c7fe6adadc6d9deb27f3d2b73bf6a759c2a`
**Architect doc:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md`
**Coder IMPL-REPORT:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2-RC9.md`

---

## §1 — Summary and verdict

**Verdict: APPROVE.**

The pack-coder produced a clean, mechanical trinity edit that matches the
architect spec verbatim. All ten audit dimensions defined by the calling
prompt pass independent verification:

1. Per-bullet text fidelity vs architect §4.1: PASS — byte-identical (42
   lines, ten content-paragraphs, full four-commit lineage preserved).
2. Trinity parity (UNIVERSAL classification): PASS — `### Repo conventions`
   sub-section is byte-identical across `/CLAUDE.md`, `/AGENTS.md`,
   `/GEMINI.md` post-edit (and was pre-edit, so no GEMINI prose-form
   latitude was needed).
3. Placement: PASS — RC9 inserted at end of `### Repo conventions` after
   RC8, before `### Project goals (v11)`.
4. No out-of-scope edits: PASS — only the three trinity files were
   modified by this coder; `/PACK-CHAT.md` carries pre-existing
   modifications from a prior 19b-2 coder session and was not touched by
   this coder; no `project-template/`, `scripts/`, `supporting-docs/`,
   `test-fixtures/`, or pack-ops file edits.
5. Trigger-text correctness (Form C fuzzy directory, not Form A glob
   list): PASS — bullet uses "files under `project-template/` or
   `scripts/`"; no `scripts/lib/...` or `init-project.sh` enumeration
   appears anywhere in any trinity file.
6. Authority-shift clause: PASS — "The manifest diff after rebuild is
   the canonical authority — the trigger globs are a screen for WHEN to
   run the rebuild." present in all three files.
7. RC4 cross-reference: PASS — "the 'Test infra is self-provisioned'
   bullet above governs *test provisioning*; this bullet governs
   *manifest maintenance*..." present in all three files.
8. `### Repo conventions` integrity (RC1-RC8 unchanged): PASS — diff is
   purely additive (126 insertions, 0 deletions across the trinity).
9. Validator + baseline tests: PASS — `validate-pack.py` all 35 checks
   PASS; independent baseline `tracker-config-test.sh` 32/32 PASS;
   independent baseline `test-validate-pack-checks-32-33-34.sh` 65/65
   PASS.
10. DoD recursive-base-case verification: PASS — no v11-surface
    (`project-template/` or `scripts/`) files touched; manifest regen
    correctly not required for this commit.

No MUST findings, no SHOULD findings, no NIT findings. The implementation
matches the architect doc with zero plan deviations and the coder
IMPL-REPORT's self-claims are independently confirmed.

---

## §2 — Findings table

| Severity | File:Line | Finding | Remediation |
|---|---|---|---|
| (none) | — | No findings. Implementation is clean against all ten audit dimensions in §1. | — |

For the record: the architect doc itself acknowledged in §4.2 that this
bullet is the longest in `### Repo conventions` at ~42 source lines
(~2.2x the prior longest, RC5 at ~19 lines). That sizing was a settled
architect decision (§4.2 "Architect recommendation: keep the full bullet
— the manifest-diff-as-authority sentence is the load-bearing addition
that distinguishes the fuzzy trigger from Form A...") and is therefore
not a reviewer finding. The bullet's information density (four-commit
lineage, two file:section anchors, one file:symbol:line range, one CI
gate citation, RC4 cross-reference) is proportional to its standing-rule
weight.

---

## §3 — Per-bullet text fidelity audit

### §3.1 — Extraction methodology

Extracted the architect's §4.1 spec text from the
`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md`
code fence into `/tmp/spec_bullet.txt` via Python regex match on the
fenced block following the `### 4.1 Exact text` heading. Length: 42
lines.

Extracted the corresponding final bullet text from each trinity file via
`sed -n '<start>,<end>p' <file>` into three temp files:
- `/tmp/claude_bullet.txt` — lines 449-490 from `/CLAUDE.md`
- `/tmp/agents_bullet.txt` — lines 402-443 from `/AGENTS.md`
- `/tmp/gemini_bullet.txt` — lines 377-418 from `/GEMINI.md`

Each temp file: 42 lines.

### §3.2 — Diff results

```
$ diff /tmp/spec_bullet.txt /tmp/claude_bullet.txt
(empty output)
CLAUDE-VS-SPEC EXIT=0

$ diff /tmp/spec_bullet.txt /tmp/agents_bullet.txt
(empty output)
AGENTS-VS-SPEC EXIT=0

$ diff /tmp/spec_bullet.txt /tmp/gemini_bullet.txt
(empty output)
GEMINI-VS-SPEC EXIT=0
```

All three trinity-file RC9 bullets are byte-identical to the architect's
§4.1 spec. Zero drift.

### §3.3 — Required-content checklist

Each clause flagged by the calling prompt as load-bearing was
independently confirmed present in all three trinity files:

| Required content | Verified present in CLAUDE.md / AGENTS.md / GEMINI.md? |
|---|---|
| Rule statement: "Regenerate test-fixtures/manifest.txt on every v11-surface commit." | Yes (line 449 / 402 / 377) |
| Fuzzy directory trigger: "files under `project-template/` or `scripts/`" | Yes (single match per file) |
| Intentionally-inclusive caveat (false positives ~30-90s; false negatives impossible) | Yes |
| Drift mechanism citation: `test-fixtures/README.md` § Determinism + `_update_manifest` at `test-fixtures/build.sh:903-912` | Yes |
| CI gate naming: `fixture manifest verify` step (BD-115, RELEASE-GATE item 5) | Yes (two mentions per file — opening clause + closing cross-reference) |
| **Why:** clause with full four-commit lineage (`cf67a96`, `62f9eec`, `479fef5`, `667d2dd`, `ef9e5c7`, `a57dd04`) | Yes — all five required SHAs preserved per architect §4.2 D-4 (CLAUDE.md lines 464, 467, 469, 470, 471; AGENTS.md lines 417, 420, 422, 423, 424; GEMINI.md lines 392, 395, 397, 398, 399) |
| **How to apply:** clause with `bash test-fixtures/build.sh --all --clean` canonical default | Yes |
| Manifest-diff-as-authority instruction ("if non-empty, `git add test-fixtures/manifest.txt`...if empty, your edit wasn't v11-surface...The manifest diff after rebuild is the canonical authority...") | Yes |
| `--name <fixture> --clean` fast-path alternative + `--verify` | Yes |
| RC4 cross-reference ("Test infra is self-provisioned" bullet above governs *test provisioning*; this bullet governs *manifest maintenance*) | Yes |

Zero silently-dropped clauses. Zero content drift.

### §3.4 — Trigger-form verification (Form C, not Form A)

The architect's D-2 resolution mandated Form C (fuzzy directory) and
explicitly rejected Form A (glob list with `project-template/**`,
`scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh`,
`scripts/lib/**`, `scripts/validate-pack.py`). Confirmation that the
bullet uses Form C:

```
$ grep -c 'scripts/lib' CLAUDE.md AGENTS.md GEMINI.md
CLAUDE.md:0
AGENTS.md:0
GEMINI.md:0

$ grep -c 'init-project.sh' CLAUDE.md AGENTS.md GEMINI.md
CLAUDE.md:0
AGENTS.md:0
GEMINI.md:0
```

Neither Form A enumeration artifact (`scripts/lib`, `init-project.sh`)
appears in any trinity file. The bullet uses the fuzzy two-directory
form per architect §2.1 / §8.3.

---

## §4 — Trinity parity audit

### §4.1 — Methodology

Diffed the `### Repo conventions` sub-section across each trinity pair
using process substitution against sed-extracted ranges:

```
$ diff <(sed -n '/^### Repo conventions/,/^### /p' CLAUDE.md) \
       <(sed -n '/^### Repo conventions/,/^### /p' AGENTS.md)
(empty output)
EXIT=0

$ diff <(sed -n '/^### Repo conventions/,/^### /p' CLAUDE.md) \
       <(sed -n '/^### Repo conventions/,/^### /p' GEMINI.md)
(empty output)
EXIT=0

$ diff <(sed -n '/^### Repo conventions/,/^### /p' AGENTS.md) \
       <(sed -n '/^### Repo conventions/,/^### /p' GEMINI.md)
(empty output)
EXIT=0
```

All three trinity `### Repo conventions` sub-sections are byte-identical
post-edit.

### §4.2 — Trinity bullet cross-check

Also independently diffed the extracted bullet temp files:

```
$ diff /tmp/claude_bullet.txt /tmp/agents_bullet.txt
(empty output)

$ diff /tmp/claude_bullet.txt /tmp/gemini_bullet.txt
(empty output)
```

EXIT=0 on both diffs. The RC9 bullet itself is byte-identical across all
three trinity files.

### §4.3 — Classification confirmation (UNIVERSAL)

Per architect §6, RC9 is UNIVERSAL (byte-identical, no CLI-specific
behavior, no Trinity-exemption note). The post-edit state honors this:
all three trinity files contain the same 42-line bullet with no prose-
form variation. The coder's pre-edit parity check (IMPL-REPORT §2.1,
§2.2) established that GEMINI.md was already byte-identical to
CLAUDE.md/AGENTS.md for this sub-section, so the contingent "produce a
tighter-wording GEMINI variant" path in architect §10.1 / coder prompt
Goal #3 did NOT need to fire. Byte-identical was the correct path,
which the coder took. Confirmed independently — see §4.1 above.

---

## §5 — Placement audit

### §5.1 — Line ranges where RC9 lands

| File | RC8 closing line | RC9 opening line | RC9 closing line | Blank line | `### Project goals (v11)` |
|---|---|---|---|---|---|
| `/CLAUDE.md` | 448 ("...existed in an architect doc.") | 449 | 490 | 491 | 492 |
| `/AGENTS.md` | 401 ("...existed in an architect doc.") | 402 | 443 | 444 | 445 |
| `/GEMINI.md` | 376 ("...existed in an architect doc.") | 377 | 418 | 419 | 420 |

### §5.2 — RC sequence verification (top-level bullets in `### Repo conventions`)

CLAUDE.md (lines 369-492):

```
371: RC1 — Per-entry trees vs mirrors
387: RC2 — BACKLOG.md has no Resolved section
390: RC3 — Separate pack ops from pack product
394: RC4 — Test infra is self-provisioned
398: RC5 — Skill and agent maintenance is mechanical by default
416: RC6 — Pack-repo code-comment deferrals
427: RC7 — Filename uniqueness heuristic
438: RC8 — Architect-doc-vs-reality reconciliation
449: RC9 — Regenerate test-fixtures/manifest.txt on every v11-surface commit
```

AGENTS.md (lines 322-445):

```
324: RC1
340: RC2
343: RC3
347: RC4
351: RC5
369: RC6
380: RC7
391: RC8
402: RC9
```

GEMINI.md (lines 297-420):

```
299: RC1
315: RC2
318: RC3
322: RC4
326: RC5
344: RC6
355: RC7
366: RC8
377: RC9
```

All three trinity files have nine top-level bullets in `### Repo
conventions` post-edit, with RC9 in the ninth position immediately after
RC8 and immediately before the section terminator. Placement matches
architect §5 ("append as new bullet at end of `### Repo conventions`,
after RC8 (Architect-doc-vs-reality reconciliation)") in all three
files.

---

## §6 — Out-of-scope check

### §6.1 — `git status --short`

```
 M AGENTS.md
 M CLAUDE.md
 M GEMINI.md
 M PACK-CHAT.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B.md
?? maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-1.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2-RC9.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-1.md
?? maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md
?? maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md
```

### §6.2 — Per-file scope verdict

| File | Status | Verdict |
|---|---|---|
| `AGENTS.md` | `M` (42 insertions, 0 deletions) | IN SCOPE (RC9 trinity edit) |
| `CLAUDE.md` | `M` (42 insertions, 0 deletions) | IN SCOPE (RC9 trinity edit) |
| `GEMINI.md` | `M` (42 insertions, 0 deletions) | IN SCOPE (RC9 trinity edit) |
| `PACK-CHAT.md` | `M` (80 insertions, 0 deletions) | OUT OF SCOPE for this commit; UNTOUCHED BY THIS CODER (see §6.3) |
| `maintenance-docs/v11-implementation/*.md` (10 files) | `??` (untracked) | Pre-existing workflow artifacts; not in coder scope; reviewer's own report adds the eleventh `??` after the Write |

### §6.3 — PACK-CHAT.md verification (not touched by this coder)

The calling prompt asked for confirmation that `PACK-CHAT.md`'s
modification is pre-existing from a prior 19b-2 coder session, NOT a new
edit by the 19b-2-RC9 coder.

Verified via two independent checks:

1. **Diff content check.** The current `PACK-CHAT.md` working-tree diff
   begins:

   ```
   diff --git a/PACK-CHAT.md b/PACK-CHAT.md
   index 3ab9a9e..7fc435d 100644
   --- a/PACK-CHAT.md
   +++ b/PACK-CHAT.md
   @@ -62,0 +63,70 @@ These rules are non-negotiable and always apply:
   +- **Stop after every reviewer pass for triage discussion.** After every
   +  pack-reviewer run, Pack Chat STOPS, surfaces the findings (severity-
   +  grouped) to the user, and waits for triage approval — even if the
   +  reviewer verdict is fully clean. No auto-commit on clean verdicts.
   +  This is distinct from the implicit-BD-status-flip rule (which fires
   ...
   ```

   The diff adds 80 lines (`80 ++++++` in `git diff --stat`) of triage-
   discussion rules in the `## Operating rules` section. Content has zero
   topical relationship to the RC9 manifest-regen rule.

2. **Last-commit check.** `git log -1 --format="%H %s" -- PACK-CHAT.md`
   returned `27374b48782d77ca67bfe67f45000f57fc47553a docs: v11 — BD-169b
   PACK-CHAT.md row + README.md Repository Layout per-entry tree
   entries` — i.e., the file's last committed state is from a BD-169b
   commit; the current `M` working-tree state reflects a prior 19b-2
   coder's uncommitted additions that have not yet been staged or
   committed.

   The 19b-2-RC9 coder's IMPL-REPORT §1 explicitly enumerates PACK-CHAT.md
   as pre-existing-and-untouched. The diff content's complete topical
   disconnect from RC9 (no mention of `test-fixtures/`, `manifest.txt`,
   `build.sh`, or any v11-surface concept anywhere in the 80-line addition)
   independently corroborates that claim.

Verdict: `PACK-CHAT.md` is OUT OF SCOPE for this commit and was NOT
modified by the 19b-2-RC9 coder. Pack Chat must NOT stage `PACK-CHAT.md`
as part of this RC9 commit; the PACK-CHAT.md changes are a separate
pending commit from a different 19b-2 coder session.

---

## §7 — Validator + baseline test independent verification

### §7.1 — `validate-pack.py`

Run by reviewer: `python3 scripts/validate-pack.py` (full run, all 35
checks). Output tail:

```
── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

PASS — 35/35 checks clean. No regressions from the trinity edits.

### §7.2 — Independent baseline test 1: `tracker-config-test.sh`

Reviewer-selected (distinct from coder's spot-checks of `test-per-entry.sh`
and `test-init-project.sh`). Output tail:

```
=== Group 3: schema_version + dispatcher integration ===
  PASS 3.1 schema_version_check pass on schema_version=1
  PASS 3.2 schema_version_check on schema_version=99 → validation
  PASS 3.2 schema_version_check error names actual version
  PASS 3.3 schema_version_check missing key → validation
  PASS 3.4a no env var → github (default)
  PASS 3.4b _TRACKER_PROVIDER_CONFIG_PATH set → backend.name=stub
  PASS 3.4c override wins absolutely
  PASS 3.5 missing config file → github fallback

=== Summary ===
Passed: 32
Failed: 0
All tests passed.
```

PASS — 32/32. Independent confirmation that tracker-config invariants
unaffected by trinity edits.

### §7.3 — Independent baseline test 2: `test-validate-pack-checks-32-33-34.sh`

Output tail:

```
=== Group G: M2 snap-leftover regression (no snap files in stream_dir) ===
  PASS G1.1 Check 33 PASS path → rc=0
  PASS G1.2 Check 33 PASS path → no .per-entry-toc-snap.* leftover in stream_dir
  PASS G2.1 Check 33 FAIL path → rc=1
  PASS G2.2 Check 33 FAIL path → no .per-entry-toc-snap.* leftover in stream_dir

=== Summary ===
PASS: 65
FAIL: 0

All BD-168 validate-pack Check 32/33/34 tests PASSED (65/65).
```

PASS — 65/65. Independent confirmation that per-entry mirror sync /
TOC sync / cross-reference integrity (BD-168) unaffected by trinity
edits.

### §7.4 — Verification verdict

All three independent verifications PASS. Combined with the coder's
spot-checks (`test-per-entry.sh` 57/57, `test-init-project.sh` 67/67
per IMPL-REPORT §5.2 / §5.3), the trinity edits introduce zero
regressions across the validator and at least four distinct baseline
test suites.

---

## §8 — DoD verification (recursive base case)

### §8.1 — Claim under audit

The coder IMPL-REPORT §5.5 and §1 ("Manifest regen for this commit: NOT
NEEDED") claim that the trinity files at pack-root are NOT v11-surface
per the RC9 rule itself, so this commit does not need
`test-fixtures/manifest.txt` regeneration. This is the "recursive base
case" — the rule that requires manifest regen for v11-surface edits is
itself a non-v11-surface edit.

### §8.2 — Verification

```
$ git diff --name-only | grep -E '^(project-template/|scripts/)' || echo "NONE — no v11-surface files touched"
NONE — no v11-surface files touched
```

The full working-tree diff filtered to paths under either trigger
directory returns NONE. The four `M`-state files are:

| Path | Under `project-template/`? | Under `scripts/`? | v11-surface per RC9? |
|---|---|---|---|
| `/CLAUDE.md` | No (pack-root) | No | NO |
| `/AGENTS.md` | No (pack-root) | No | NO |
| `/GEMINI.md` | No (pack-root) | No | NO |
| `/PACK-CHAT.md` | No (pack-root, and out-of-scope per §6.3) | No | NO |

None of the modified files satisfy the RC9 trigger condition. Per the
RC9 rule itself ("v11-surface = files under `project-template/` or
`scripts/`"), no manifest regeneration is required for this commit.

### §8.3 — Independent confirmation that manifest is untouched

```
$ git diff --name-only -- test-fixtures/manifest.txt
(empty output)
```

`test-fixtures/manifest.txt` is unmodified in the working tree —
consistent with no regen having been (correctly) attempted.

### §8.4 — Structural correctness verdict

The recursive base case holds. The coder's DoD claim is structurally
correct. Pack Chat does NOT need to run `bash test-fixtures/build.sh
--all --clean` before staging this commit. Running the build script
would, per the RC9 rule's own authority-shift clause, produce an empty
`git diff test-fixtures/manifest.txt` (the canonical proof that the
edit was non-v11-surface) — so the only effect would be ~30-90s of
wasted compute. Skip the rebuild for this commit.

---

## §9 — Reviewer recommendation

**APPROVE for commit.** No fixes required. No blocking findings. No
SHOULD findings. No NIT findings.

The 19b-2-RC9 coder produced a textbook-clean mechanical trinity edit:
the bullet text is byte-identical to architect §4.1 across all three
trinity files, placement is exactly where architect §5 specified, the
UNIVERSAL classification per architect §6 is honored (byte-identical,
no GEMINI prose-form latitude needed because pre-edit parity already
existed), no out-of-scope edits leaked, validator and three independent
baseline tests confirm zero regressions, and the recursive base case
for manifest regen is structurally correct.

### §9.1 — Pack Chat next-step recommendations (informational)

These are NOT review findings — they are commit-step notes consistent
with the coder IMPL-REPORT §7.1:

1. Stage exactly three files: `/CLAUDE.md`, `/AGENTS.md`, `/GEMINI.md`.
   Do NOT stage `/PACK-CHAT.md` (out of scope per §6.3 — that file's
   `M` state is from a different 19b-2 coder session and should be a
   separate commit).
2. Do NOT run `bash test-fixtures/build.sh --all --clean` before
   staging — the recursive base case (§8) confirms manifest regen is
   not required for this commit.
3. Suggested commit message per architect §10.4:
   `feat: v11 — Batch 19b-2 trinity manifest-regen rule (RC9)`. Note
   this is a `feat:` commit (adds a standing rule), NOT a `fix:`
   commit (no BD anchor).
4. Per architect §10.3, the Pack-Chat-direct memory cache pointer file
   (`feedback_manifest_regen_on_v11_surface.md` in
   `~/.claude/projects/<slug>/memory/`) lands AFTER the trinity commit
   per the standard Tier 1.5 pointer pattern. That is a Pack-Chat
   direct edit per the Pack-Chat-direct list and is NOT pack-coder
   scope.

### §9.2 — Architect doc D-5 reminder (informational)

Architect §10.5 / §12 noted the `test-fixtures/README.md` reverse-link
to the RC9 trinity bullet as a deferred follow-up (one-line addendum
to § Determinism). Per the project's `feedback_deferral_is_scope_creep`
memory rule, that follow-up should land in v11.0 — Pack Chat may want
to surface that decision to the user when scheduling the next batch
(out of scope for this review).

End of report.
