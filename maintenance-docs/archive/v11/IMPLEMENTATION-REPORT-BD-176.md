# IMPLEMENTATION-REPORT-BD-176 — Expand RC9 manifest-regen trigger to cover pack-ops/ + supporting-docs/

**Status:** Pack-coder implementation complete; awaiting Pack Chat triage + commit
**Author:** pack-coder (background spawn)
**Date:** 2026-05-20
**Branch:** v11-dev
**HEAD at session start:** `aca8399`
**HEAD at PREFLIGHT (moved by concurrent Pack-Chat commit):** `e4dffda`
**Batch:** BD-175 emergency batch chain → **BD-176** → BD-177 → BD-178 → BD-179 → BD-180 → end-of-batch reviewer
**Architect strategy doc:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md`
**Trinity rule:** APPLIES — 3 pack-root trinity files edited lockstep with byte-identical RC9 bullet body

---

## §1 Summary

BD-176 expands the RC9 ("Regenerate test-fixtures/manifest.txt on every v11-surface commit") rule in pack-root trinity Pack memory § "Repo conventions" from a 2-directory trigger glob (`project-template/` + `scripts/`) to a 4-directory trigger glob (`project-template/` + `scripts/` + `pack-ops/` + `supporting-docs/`). The expansion closes two false-negative classes: (a) `pack-ops/` (created in BD-175; contains the fixture-affecting `HELP-FRAGMENT-TRACKER.md` already + defends against future copy-site additions), and (b) `supporting-docs/` (empirically false-negative; the 2026-05-19 incident at commit `4120d19` modified `supporting-docs/METHODOLOGY.md` without regenerating manifest under the prior strict trigger, CI failed, and recovery commit `6c48f88` had to land separately).

Implementation followed architect strategy doc §3.2 mechanically — bullet-body BEFORE/AFTER REPLACE applied byte-identically to all 3 pack-root trinity files (CLAUDE.md, AGENTS.md, GEMINI.md). User triage decisions OQ-1=B2 (broaden to entire `supporting-docs/`), OQ-2 D4 deferred to BD-180 (NOT in this coder's scope), OQ-3 sanity-check rebuild ACCEPTED (architect D5: empty diff confirmed), OQ-4 memory-cache preservation (Pack-Chat-direct, not coder scope) were all applied per user direction 2026-05-20. The architect's D5 prediction (empty manifest diff after `--all --clean` rebuild) was confirmed.

---

## §2 Files changed

| File | Type | Change | Lines |
|---|---|---|---|
| `CLAUDE.md` (pack root) | Pack-Chat-only / trinity | Modified — RC9 bullet body replaced per architect §3.2 AFTER block | +47 / -24 |
| `AGENTS.md` (pack root) | Pack-Chat-only / trinity | Modified — RC9 bullet body replaced per architect §3.2 AFTER block (byte-identical to CLAUDE.md) | +47 / -24 |
| `GEMINI.md` (pack root) | Pack-Chat-only / trinity | Modified — RC9 bullet body replaced per architect §3.2 AFTER block (byte-identical to CLAUDE.md) | +47 / -24 |

**Total:** 3 files; +141 / -72 = net +69 lines. `git diff --stat` confirmed.

**Out of scope (NOT touched by this coder):**
- `pack-ops/BACKLOG.md` — Pack Chat staged BD-180 (Observations F + G) + BD-181 (Check 18 H2 pack-root coverage) edits in the index before/during this coder's session; those edits were committed in `e4dffda` (concurrent Pack-Chat commit). NOT this coder's work.
- `~/.claude/projects/<slug>/memory/feedback_manifest_regen_on_v11_surface.md` — Pack-Chat-direct edit per architect §8.5 / pack memory § "What Pack Chat CAN edit directly" → Memory files. Pack Chat handles after this commit lands.
- `scripts/init-project.sh` / `scripts/validate-pack.py` — D4 self-documenting list deferred to BD-180 per user-approved triage.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` — committed by Pack Chat in `e4dffda` concurrent with this coder's session; NOT this coder's edit.

---

## §3 Trinity edit — exact BEFORE / AFTER

The change is a SINGLE TARGETED EDIT to the RC9 bullet's body. The bullet header (`- **Regenerate test-fixtures/manifest.txt on every v11-surface commit.**`) is preserved; only the bullet body is replaced. The architect's §3.2 AFTER block was applied verbatim across all 3 trinity files.

### BEFORE (byte-identical across CLAUDE.md L510-552, AGENTS.md L463-505, GEMINI.md L432-474)

```markdown
- **Regenerate test-fixtures/manifest.txt on every v11-surface commit.**
  v11-surface = files under `project-template/` or `scripts/`. Any
  commit whose diff includes a file under either directory MUST also
  regenerate `test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the SAME commit. The trigger is intentionally
  inclusive — false positives (e.g., a `scripts/test-*.sh` edit that
  doesn't actually affect fixtures) cost ~30-90s of unnecessary
  rebuild but produce no incorrect manifest change; false negatives
  within v11-surface are impossible because every v11-surface file
  lives under one of these two directories. v11-* fixture row SHAs
  drift naturally with any v11-surface change (per
  `test-fixtures/README.md` § Determinism and the `_update_manifest`
  comment at `test-fixtures/build.sh:903-912`); a stale manifest
  fails CI's `fixture manifest verify` step (BD-115, RELEASE-GATE
  item 5) even when every functional test passes. **Why:** prevents
  the 2026-05-17 incident where commit `667d2dd` shipped v11-surface
  trinity edits without regenerating the manifest, CI failed on the
  manifest-comparison step alone (all 40+ functional steps PASSED),
  and recovery commit `ef9e5c7` had to land as a separate `fix:`
  commit; the drift was the cumulative effect of three intentional
  v11-surface commits (`cf67a96` BD-169 pack-product wording,
  `62f9eec` BD-169 review/fix, `479fef5` Batch 19 broad review/fix)
  since the last manifest regen at `a57dd04` (BD-160). **How to
  apply:** before staging a commit whose diff includes any file
  under `project-template/` or `scripts/`, run
  `bash test-fixtures/build.sh --all --clean` from the pack root.
  Then check `git diff test-fixtures/manifest.txt`: if non-empty,
  `git add test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the same commit; if empty, your edit wasn't
  v11-surface (no staging needed). The manifest diff after rebuild
  is the canonical authority — the trigger globs are a screen for
  WHEN to run the rebuild. `--all --clean` is the canonical default
  (rebuilds all six fixtures deterministically; v10-* rows are
  tag-pinned and only drift if the v10 tag moves). Actors confident
  about which v11-* fixture is affected may substitute
  `--name <fixture> --clean` per affected fixture, then
  `bash test-fixtures/build.sh --verify` to confirm the remaining
  rows are unchanged before staging. Cross-reference: the "Test
  infra is self-provisioned" bullet above governs *test
  provisioning*; this bullet governs *manifest maintenance* and is
  load-bearing for the `fixture manifest verify` CI gate
  (BD-115, RELEASE-GATE item 5).
```

### AFTER (byte-identical across all 3 pack-root trinity files post-edit; verified via diff in §5)

```markdown
- **Regenerate test-fixtures/manifest.txt on every v11-surface commit.**
  v11-surface = files under `project-template/`, `scripts/`,
  `pack-ops/`, or `supporting-docs/`. Any commit whose diff includes
  a file under any of these four directories MUST also regenerate
  `test-fixtures/manifest.txt` and stage it alongside the scope edits
  in the SAME commit. The trigger is intentionally inclusive — false
  positives (e.g., a `scripts/test-*.sh` edit that doesn't actually
  affect fixtures, or a `supporting-docs/MIGRATION-v10-to-v11.md`
  edit which is a pre-install reference not copied to clients) cost
  ~30-90s of unnecessary rebuild but produce no incorrect manifest
  change; false negatives within v11-surface are impossible because
  every fixture-affecting file lives under one of these four
  directories. Fixture-affecting paths today: all of
  `project-template/**` and `scripts/**` (mass-copied by
  `scripts/init-project.sh` stages S1-S11);
  `pack-ops/HELP-FRAGMENT-TRACKER.md` (`scripts/init-project.sh`
  stage S11 copies to client `docs/pack/`);
  `supporting-docs/METHODOLOGY.md` and
  `supporting-docs/INSTALL-PROCEDURES.md`
  (`scripts/init-project.sh` stage S6 copies to client `docs/pack/`).
  Other files under `pack-ops/` and `supporting-docs/` are not
  fixture-affecting today, but the directory-wide trigger defends
  against future copy-site additions to `init-project.sh` or new
  fixture-build readers. v11-* fixture row SHAs drift naturally with
  any v11-surface change (per `test-fixtures/README.md` § Determinism
  and the `_update_manifest` comment at
  `test-fixtures/build.sh:903-912`); a stale manifest fails CI's
  `fixture manifest verify` step (BD-115, RELEASE-GATE item 5) even
  when every functional test passes. **Why:** two incidents drove
  this rule: (1) the 2026-05-17 incident where commit `667d2dd`
  shipped v11-surface `project-template/` trinity edits without
  regenerating the manifest, CI failed on the manifest-comparison
  step alone (all 40+ functional steps PASSED), and recovery commit
  `ef9e5c7` had to land as a separate `fix:` commit; the drift was
  the cumulative effect of three intentional v11-surface commits
  (`cf67a96` BD-169 pack-product wording, `62f9eec` BD-169 review/
  fix, `479fef5` Batch 19 broad review/fix) since the last manifest
  regen at `a57dd04` (BD-160); (2) the 2026-05-19 incident where
  BD-175 Phase 5 Commit 8 `4120d19` modified
  `supporting-docs/METHODOLOGY.md` (a client-installed file) without
  regenerating the manifest under the prior strict trigger (which
  excluded `supporting-docs/`), CI failed identically, and recovery
  commit `6c48f88` had to land as a separate `fix:` commit. BD-176
  expanded the trigger from 2 directories to 4 to close both classes
  of false negative (pack-ops/ defensively; supporting-docs/
  empirically). **How to apply:** before staging a commit whose diff
  includes any file under `project-template/`, `scripts/`,
  `pack-ops/`, or `supporting-docs/`, run
  `bash test-fixtures/build.sh --all --clean` from the pack root.
  Then check `git diff test-fixtures/manifest.txt`: if non-empty,
  `git add test-fixtures/manifest.txt` and stage it alongside the
  scope edits in the same commit; if empty, your edit wasn't
  v11-surface (no staging needed). The manifest diff after rebuild
  is the canonical authority — the trigger globs are a screen for
  WHEN to run the rebuild. `--all --clean` is the canonical default
  (rebuilds all six fixtures deterministically; v10-* rows are
  tag-pinned and only drift if the v10 tag moves). Actors confident
  about which v11-* fixture is affected may substitute
  `--name <fixture> --clean` per affected fixture, then
  `bash test-fixtures/build.sh --verify` to confirm the remaining
  rows are unchanged before staging. Cross-reference: the "Test
  infra is self-provisioned" bullet above governs *test
  provisioning*; this bullet governs *manifest maintenance* and is
  load-bearing for the `fixture manifest verify` CI gate
  (BD-115, RELEASE-GATE item 5).
```

### Delta summary

Five substantive changes per architect §3.3:

1. **Trigger expansion (1 sentence).** `v11-surface = files under project-template/ or scripts/` → `v11-surface = files under project-template/, scripts/, pack-ops/, or supporting-docs/`. The follow-on "Any commit whose diff includes a file under either directory" → "Any commit whose diff includes a file under any of these four directories" mirrors the change.

2. **False-positive example expansion (1 example added).** The parenthetical gains a sibling example: ", or a `supporting-docs/MIGRATION-v10-to-v11.md` edit which is a pre-install reference not copied to clients".

3. **Fixture-affecting-paths enumeration (new sentence + list).** A new sentence enumerates the fixture-affecting paths today, distinguishing mass-copied directories (`project-template/**`, `scripts/**`) from selectively-copied files (`pack-ops/HELP-FRAGMENT-TRACKER.md`, `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`).

4. **"Why" rationale expansion (the 2026-05-19 incident added).** The "Why" paragraph now narrates BOTH precedent incidents (2026-05-17 trinity-edit drift + 2026-05-19 METHODOLOGY.md drift) and explicitly names BD-176 as the rule-expansion BD.

5. **"How to apply" trigger glob updated.** Mirror of the trigger sentence: "any file under `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`".

NO changes to: bullet header; verification recipe (`bash test-fixtures/build.sh --all --clean`); manifest-diff authority statement; `--name <fixture> --clean` alternative path; "Test infra is self-provisioned" cross-reference; CI-gate cross-reference (`BD-115, RELEASE-GATE item 5`).

---

## §4 D5 sanity-check rebuild result

Per architect §6 (D5 bootstrap-order verification) — the BD-176 commit itself touches ONLY pack-root trinity files (CLAUDE.md, AGENTS.md, GEMINI.md at repo root). Pack-root trinity is NOT v11-surface even under the expanded rule per memory cache § "Recursive base case." Architect prediction: empty `git diff test-fixtures/manifest.txt` after rebuild.

**Verification command:**
```sh
bash test-fixtures/build.sh --all --clean
git diff test-fixtures/manifest.txt
```

**Result: EMPTY diff confirmed.**

Build output (tail-30):
```
── building v10-realistic-ot ──
    source: pack v10 tag + FakeOT customizations
  built: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/v10-realistic-ot
  HEAD:  4c62945f72b037908b38967d5d8f019745263258
── building v11-realistic-ot ──
    source: pack current HEAD + FakeOT customizations (v11 surface)
    BD-170: per-entry decompose + regenerate + byte-identity round-trip
per-entry decompose: wrote 5 entry file(s) to .../docs/project/backlog
      project-backlog: decomposed + round-trip byte-identical
per-entry decompose: wrote 0 entry file(s) to .../docs/project/implementation-plan
      project-implementation-plan: decomposed + round-trip byte-identical
per-entry decompose: wrote 0 entry file(s) to .../docs/project/changelog
      project-changelog: decomposed + round-trip byte-identical
  built: .../v11-realistic-ot   HEAD: 50940281c243f28c8ff755f5fd2361c5c63340b8
── building v11-flat-file ──     HEAD: 8a6a2d05bf285f178335c9f13b0636a2c1e10b98
── building v11-tracker-on ──    HEAD: 11bc0a3ac70b3fe8cdd64d353f3381e0ad4e953d
── building existing-project-mid-dev ──  HEAD: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619

manifest written: .../test-fixtures/manifest.txt
```

Manifest diff output:
```
(empty — no output)
```

**Interpretation:** architect D5 prediction confirmed. BD-176's trinity edits did NOT drift any v11-* fixture SHA; no manifest staging needed for this commit; no bootstrap problem. Pack-root trinity edits are correctly outside the v11-surface trigger (matching the "Recursive base case" carve-out in the memory cache).

---

## §5 Within-trinity parity verification

Per architect §7.2 — extract the RC9 bullet from each trinity file via awk pattern match, then diff cross-pairs. Both diffs must produce empty output.

**Recipe used (modified from architect's recipe — `sed '$d'` replaces `head -n -1` for BSD compatibility per macOS bash 3.2):**

```sh
extract_rc9() {
    awk '/^- \*\*Regenerate test-fixtures\/manifest\.txt/,/^- \*\*[A-Z]/' "$1" | sed '$d'
}
diff <(extract_rc9 CLAUDE.md) <(extract_rc9 AGENTS.md)
diff <(extract_rc9 CLAUDE.md) <(extract_rc9 GEMINI.md)
```

**Result:**
```
=== CLAUDE vs AGENTS ===
CLAUDE↔AGENTS OK
=== CLAUDE vs GEMINI ===
CLAUDE↔GEMINI OK
```

Both diffs empty. Trinity parity verified for the RC9 bullet across all 3 pack-root trinity files.

**Note on Check 18 H2:** Check 18 H2 (`scripts/validate-pack.py:1295-1300`) does NOT mechanically enforce parity for pack-root trinity — it's hardcoded to `REPO_ROOT / "project-template" / name`. The manual `diff` verification above is the trinity-rule enforcement for pack-root trinity. (BD-181 is the open BD that extends Check 18 H2 to also cover pack-root trinity — see `pack-ops/BACKLOG.md` BD-181 entry, opened by Pack Chat in `e4dffda`.)

---

## §6 validate-pack.py + 3 persona contract results

### validate-pack.py (tail of full output)

```
── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

── Check 36: Commit-scope honesty (BD-175, M5a) ──
  OK: Check 36 — 0 scope-claiming commit(s) verified clean; 1 implicit-scope commit(s) skipped

── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

============================================================
PASSED — all checks clean
```

Exit code: 0. All checks pass — including Check 18 H2 within-trinity parity for `project-template/` trinity (NOT broken by this edit; the pack-root trinity edit doesn't touch `project-template/{CLAUDE,AGENTS,GEMINI}.md`), Check 36 commit-scope honesty (skipped — this coder doesn't commit), Check 37 project-side deny-list, Check 38 pack-only-file siting, Check 39 cmd_update mapping/glob symmetry.

### Persona contracts (3 of 3 GREEN)

**contract-greenfield.sh (final 5 lines):**
```
  PASS S6 docs/pack/PACK-FEEDBACK.md present
  PASS S6 docs/pack/prompts/ has 10 prompt files (>=10 expected)
  PASS S8 .gitignore installed

=== greenfield contract: 191 passed, 0 failed ===
```

**contract-mid-dev.sh (final 5 lines):**
```
  PASS scripts/ created
  PASS docs/pack/ created
  PASS no spurious .pack-template sidecars

=== mid-dev contract: 25 passed, 0 failed ===
```

**contract-migration.sh (final 5 lines):**
```
  PASS v11 artifact docs/project/changelog/_intro.md installed by migrator
  PASS v11 artifact docs/project/changelog/_format.md installed by migrator
  PASS all .github/ISSUE_TEMPLATE/*.yml installed by migrator

=== migration contract: 37 passed, 0 failed ===
```

**Combined: 253 assertions PASSED, 0 FAILED.**

---

## §7 Verification command output (replay)

### 7.1 git rev-parse HEAD (start vs end)

```
Start of session: aca8399291a078f37d71bc6ec4743660e36e8afe
End of session (after Pack-Chat concurrent commit):  e4dffda80ac4d1fc287896d424d09b30e45e7b50
```

Note: HEAD moved during this coder's session because Pack Chat committed the architect strategy doc + BD-180/BD-181 BACKLOG.md edits in commit `e4dffda` concurrently with this coder's trinity edits. The architect strategy doc and BACKLOG edits are NOT this coder's work — they are PM-only edits that Pack Chat handled directly (per pack memory § "What Pack Chat CAN edit directly" → PM-only files). This coder's edits remain isolated to the 3 trinity files.

### 7.2 Pre-edit grep (initial state context)

All 3 trinity files contained the BEFORE bullet at:
- `CLAUDE.md` L510 (RC9 bullet header line)
- `AGENTS.md` L463 (RC9 bullet header line)
- `GEMINI.md` L432 (RC9 bullet header line)

(Confirmed via `grep -n "Regenerate test-fixtures/manifest" CLAUDE.md AGENTS.md GEMINI.md`.)

### 7.3 Post-edit trinity parity diff

```
=== CLAUDE vs AGENTS ===
CLAUDE↔AGENTS OK
=== CLAUDE vs GEMINI ===
CLAUDE↔GEMINI OK
```

(Reproduction recipe in §5.)

### 7.4 D5 sanity-check rebuild

```
bash test-fixtures/build.sh --all --clean
# (full output in §4)

git diff test-fixtures/manifest.txt
# (empty — no output)
```

### 7.5 validate-pack.py

```
python3 scripts/validate-pack.py | tail -5
============================================================
PASSED — all checks clean
```

Exit code: 0.

### 7.6 Persona contracts (3 of 3)

```
=== greenfield contract: 191 passed, 0 failed ===
=== mid-dev contract: 25 passed, 0 failed ===
=== migration contract: 37 passed, 0 failed ===
```

### 7.7 Working-tree scope at PREFLIGHT

```
$ git status --short
 M AGENTS.md
 M CLAUDE.md
 M GEMINI.md

$ git diff --stat
 AGENTS.md | 71 ++++++++++++++++++++++++++++++++++++++++++---------------------
 CLAUDE.md | 71 ++++++++++++++++++++++++++++++++++++++++++---------------------
 GEMINI.md | 71 ++++++++++++++++++++++++++++++++++++++++++---------------------
 3 files changed, 141 insertions(+), 72 deletions(-)
```

Exactly 3 working-tree-modified files (matching architect §8.1 scope). Zero untracked / zero out-of-scope files in working tree. No state-changing git verbs run by this coder.

---

## §8 PREFLIGHT line (exact, as emitted)

```
PREFLIGHT: 3/3 in-scope file edits complete; verification PASS; HEAD e4dffda; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-176.md
```

---

## §9 Definition-of-Done checklist

| # | Criterion | Status |
|---|---|---|
| 1 | 3 pack-root trinity files (CLAUDE.md, AGENTS.md, GEMINI.md) edited per architect §3.2 with BYTE-IDENTICAL RC9 bullet bodies | PASS |
| 2 | Trinity parity verified (CLAUDE↔AGENTS empty diff; CLAUDE↔GEMINI empty diff) | PASS |
| 3 | `bash test-fixtures/build.sh --all --clean` executes successfully | PASS |
| 4 | `git diff test-fixtures/manifest.txt` is EMPTY (architect D5 prediction confirmed) | PASS |
| 5 | `python3 scripts/validate-pack.py` exit 0 (all checks PASS including Check 18 H2 for project-template/, Check 39 cmd_update symmetry, Checks 36/37/38 boundary checks) | PASS |
| 6 | 3 persona contracts STILL GREEN (greenfield 191/0; mid-dev 25/0; migration 37/0 = 253/0 combined) | PASS |
| 7 | Only the 3 pack-root trinity files in working tree (plus IMPL-REPORT after Write) | PASS |
| 8 | No state-changing git verbs run by this coder | PASS |
| 9 | No edits outside the 3 trinity files (no pack-ops/BACKLOG.md, scripts/, project-template/, memory files, architect doc edited by this coder) | PASS |
| 10 | PREFLIGHT line emitted before IMPL-REPORT write | PASS |

**All 10 criteria PASS.**

---

## §10 Plan deviations

**Zero plan deviations.** The architect's §3.2 AFTER block was applied verbatim across all 3 trinity files. No wording adjustments, no scope expansion, no scope contraction.

The only operational note is that HEAD moved from `aca8399` to `e4dffda` during the session due to a concurrent Pack-Chat commit landing the architect strategy doc + BACKLOG.md BD-180/BD-181 edits. This is not a deviation from this coder's plan — Pack Chat's concurrent commit was outside this coder's scope per architect §8.5 and the user's prompt ("OQ-2: D4 self-documenting safety check DEFER to BD-180. Approved + documented separately by Pack Chat — NOT in this coder's scope."). This coder's edits remain isolated to the 3 trinity files; the architect doc + BACKLOG edits were committed by Pack Chat.

One BSD-compatibility tweak to the architect's §7.2 recipe: `head -n -1` is GNU-only and fails on macOS BSD `head`. Substituted `sed '$d'` (delete last line) for equivalent behavior on macOS bash 3.2 + BSD utils per the pack repo's macOS-compatibility constraint. The trinity-parity diff result is identical to what the architect's recipe would produce on a GNU system.

---

## §11 New POQs introduced

**Zero new POQs.** The architect's strategy doc §9 enumerated 4 open questions (OQ-1 through OQ-4); all 4 were resolved by user triage 2026-05-20 before this coder's spawn (per the prompt's "User triage decisions" section). No new design questions surfaced during implementation.

---

## §12 Files changed inventory

| Path | Change type | Notes |
|---|---|---|
| `CLAUDE.md` | Modified | RC9 bullet body replaced per architect §3.2 AFTER block (pack-root trinity) |
| `AGENTS.md` | Modified | RC9 bullet body replaced per architect §3.2 AFTER block (byte-identical to CLAUDE.md) |
| `GEMINI.md` | Modified | RC9 bullet body replaced per architect §3.2 AFTER block (byte-identical to CLAUDE.md) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-176.md` | New | This report |

**Outside this coder's scope but landed concurrently in `e4dffda` by Pack Chat:**

| Path | Change type | Notes |
|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` | New | Architect strategy doc — Pack Chat committed via `e4dffda` |
| `pack-ops/BACKLOG.md` | Modified | BD-180 Observations F + G added; new BD-181 entry — Pack Chat committed via `e4dffda` |

---

## §13 Recommended commit shape (for Pack Chat use)

Per architect §8.2 — Pack Chat may apply this verbatim or adjust:

```
fix: v11 — BD-176 expand RC9 manifest-regen trigger to pack-ops/ + supporting-docs/ (PM-only)

Adds pack-ops/ and supporting-docs/ to the RC9 v11-surface trigger glob
in pack-root trinity Pack memory § Repo conventions. Empirical driver:
2026-05-19 CI failure where supporting-docs/METHODOLOGY.md edit
required separate fix commit 6c48f88. Defensive driver: pack-ops/
created in BD-175 may host future fixture-affecting files beyond
HELP-FRAGMENT-TRACKER.md.

Trinity rule: 3 pack-root trinity files lockstep (byte-identical
bullet body verified via extract_rc9 awk recipe).

No v11-surface files touched (pack-root trinity is base-case exempt
per memory-cache bullet); no manifest regen required for this commit
per RC9 itself. Architect D5 sanity-check confirmed empty manifest
diff after --all --clean rebuild.

See: maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md
See: maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-176.md
```

Suffix: `PM-only` per the commit-subject scope-keyword convention (CI Check 36). PM-only permits edits to pack-root trinity (CLAUDE/AGENTS/GEMINI). The diff is 100% trinity files; PM-only is correct.

---

End of IMPLEMENTATION-REPORT-BD-176.md.
