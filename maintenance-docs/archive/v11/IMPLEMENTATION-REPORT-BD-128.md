# IMPLEMENTATION-REPORT-BD-128.md

**BD:** BD-128 — CI tests-job red on v11-dev: blast_radius_sweep tripping on v10.1 PM-CHAT.md content; v10-tag fixture build cascading into migrator-behavior-preservation suite
**Branch:** v11-dev
**Pre-flight HEAD:** ffecfefc44b7e7829059dc0994b6518efb63ea16
**Final HEAD (worktree dirty):** ffecfefc44b7e7829059dc0994b6518efb63ea16 (unchanged — no commits per agent rules)

---

## Summary

CI was red on the `tests` job because `init-project.sh`'s
`blast_radius_sweep` did not exclude `PM-CHAT.md` from its
PROMPT-TEMPLATES match, but v10.1 added documentary references to
PROMPT-TEMPLATES.md inside `PM-CHAT.md` (orphan-files RAG table). Every
fresh install — current pack OR v10-tag — exited 31 (EXIT_SWEEP) at
end-of-S6. This took out three suites: `test-init-project.sh`
Group 3 directly; `test-fixtures/build.sh --all --clean` on the
`v10-minimal` and `v10-realistic-ot` fixtures; and
`test-migrator-behavior-preservation.sh` collaterally (it depends on
the v10 fixtures).

A second, BD-135-induced failure surfaced once the v10 fixture builds
were unblocked: the migrator-behavior-preservation suite's pre-refactor
BASELINE migrator (snapshotted at SHA `d7b3f07`) hard-codes the OLD
`project-template/tracker.toml.example` source path that BD-135
renamed out from under it (commit `ffecfef`), so the BASELINE silently
no-ops the tracker install while the ADAPTER correctly installs from
the renamed source. This is a baseline-stale-path artifact; the
ADAPTER's behavior is the contract the BD-119 framework is designed to
preserve.

All three blocking suites now pass. Validator clean. No regressions in
adjacent suites I sanity-tested.

---

## Per-failure-mode root cause + fix

### Failure mode 1 — `test-init-project.sh` Group 3 (current pack)

**Root cause.** `scripts/init-project.sh` `blast_radius_sweep()`
(formerly around line 950) ran a recursive grep for `PROMPT-TEMPLATES`
under `docs/pack/`, `scripts/`, etc., excluding only `METHODOLOGY.md`
and `INSTALL-PROCEDURES.md`. v10.1 commits `ac6fb0c` (RAG ingestion
manifest) and `f70d798` (Permission profiles section) added an
orphan-files table to `project-template/docs/pack/PM-CHAT.md` lines
147–148 that legitimately names PROMPT-TEMPLATES.md so users can purge
stale RAG entries. The sweep was not updated. Additionally,
`scripts/lib/detect.sh` (lines 316, 373) uses `PROMPT-TEMPLATES.md` as
a v10-shape negative marker for pack-version detection — this is
functional library code, not stale narrative, but the sweep would
catch it under `scripts/`.

**Fix.** Add `PM-CHAT.md` and `detect.sh` to the sweep's
`grep -rn --exclude=...` list, with comment explaining each
file's legitimate need to name the retired token. Single-line change
in `blast_radius_sweep()`; rationale block above expanded to record
each file's role.

**Why this surface (vs. relocating PM-CHAT content).** The sweep
already had precedent for excluding documentation files that
legitimately reference retired tokens (METHODOLOGY.md,
INSTALL-PROCEDURES.md). PM-CHAT.md fits the same pattern — a
docs/pack/ file that names a retired pack-version artifact in service
of a real user task (RAG-index hygiene). Moving the orphan-files table
to one of the already-excluded files would lose the table's home in
the canonical PM workflow doc and force readers to chase cross-links.
Making the sweep markdown-table-aware is over-engineering for a
fixed-cardinality exclusion list. detect.sh is library code with a
different rationale (functional negative-marker use), but the same
remedy (exclude) applies.

### Failure mode 2 — `test-fixtures/build.sh --all --clean` (v10 tag)

**Root cause.** Same bug as failure mode 1, but in v10.1's
`init-project.sh` (the `v10` floating tag points to v10.1 commit
`ec7aef1`). v10.1 PM-CHAT.md has the same two orphan-table lines
(verified: `grep -c "PROMPT-TEMPLATES" /tmp/v10-check/project-template/docs/pack/PM-CHAT.md` → 2). v10.0 PM-CHAT.md has zero such references — the bug was introduced in v10.1.
`_build_v10_minimal` and `_build_v10_realistic_ot` both call
`_run_v10_init` which invokes `bash $v10_src/scripts/init-project.sh`,
exiting 31 every time. v10's init-project.sh source cannot be
modified (the tag is frozen historical state).

**Fix.** Surgical post-clone patch in `_setup_v10_pack_src()` that
adds `--exclude='PM-CHAT.md'` to the cloned v10 init-project.sh's
sweep `grep -rn` line via a single `sed -i.bak` edit. Pre-conditions
on the patch: file present AND already has the
`exclude='INSTALL-PROCEDURES.md'` marker AND does not already have a
PM-CHAT.md exclude. This makes the patch idempotent and surface-stable
across any future v10-tag refresh. The patch does NOT relax sweep
semantics for any other file — every other PROMPT-TEMPLATES match
will still trip the sweep.

**Why this work-around (vs. alternatives the prompt named).**
- *Pin to v10.0 instead of `v10`*: rejected. v10.0 doesn't have the
  PM-CHAT.md orphan-table content, so a v10.0-pinned fixture would
  silently mask the v10.1 bug AND would no longer represent the
  released v10 line. Real v10 users live on v10.1; so should the
  fixture.
- *Make build.sh tolerate exit 31*: rejected. Masks real failures,
  exactly the anti-pattern the prompt warned against.
- *Pre-edit v10's PM-CHAT.md to remove the offending lines*: rejected.
  Drifts the fixture's `docs/pack/PM-CHAT.md` content from what real
  v10 clients have, weakening the v10 → v11 migrator's behavior
  preservation tests against the realistic shape.

The chosen patch is the smallest surgical edit that fixes the
single-file-and-single-grep-flag bug exactly as it would be fixed in
the current pack, with a clear comment block recording why we cannot
fix it in-tag.

### Failure mode 3 — `test-migrator-behavior-preservation.sh` (BD-135 source-path drift)

**Root cause.** BD-135 (commit `ffecfef`) renamed
`project-template/tracker.toml.example` to
`project-template/tracker.toml.project-example`, keeping the install
destination basename at `tracker.toml.example`. The current ADAPTER
(`scripts/migrate-v10-to-v11.sh`) sources from the new path and
correctly installs the file. The BASELINE migrator (recovered via
`git show d7b3f07:scripts/migrate-v10-to-v11.sh`, since no on-disk
gitignored snapshot exists) hard-codes the OLD source path; its
`[[ -f "$PACK/project-template/tracker.toml.example" ]]` precondition
silently evaluates false at HEAD, so no copy happens. A1
(file-list equality) flagged the divergence — `tracker.toml.example`
present in adapter tree, absent in baseline tree — for both the
v10-minimal and v10-realistic-ot fixtures.

This is a behavior-preservation false negative caused by a baseline
stale source-path. The ADAPTER's behavior is the post-BD-135 contract.

**Fix.** Add a baseline-patch step in
`test-migrator-behavior-preservation.sh` immediately after the
BASELINE is materialized (either from the gitignored snapshot or via
`git show`). Use `sed -i.bak` to retarget every occurrence of
`PACK/project-template/tracker.toml.example` to
`PACK/project-template/tracker.toml.project-example` in the BASELINE
file. Guard the patch with `grep -q` so it's a no-op on already-current
or otherwise-shaped baselines.

**Why this work-around (vs. alternatives).**
- *Update BD-135 to refresh the baseline snapshot*: would fold into
  BD-135's resolved commit history retroactively; cleanest long-term
  but requires a separate BD and is outside this BD's scope (the
  prompt scopes me to making CI green, not re-architecting BD-135).
- *Refresh the gitignored on-disk snapshot only*: brittle — the file
  is gitignored and not authoritative; CI would still fall through
  to the `git show`-from-SHA path on a fresh checkout.
- *Add the snapshot file with the patch baked in*: same brittleness as
  the prior option, plus pollutes the gitignored slot with content
  that has to be re-baked every time the BASELINE SHA changes.

The chosen patch lives at the harness level where the recovery logic
already branches by source (snapshot file vs git-show), so it
intercepts both paths uniformly.

---

## Files modified

| Path | Change | Lines (Δ) |
|---|---|---|
| `scripts/init-project.sh` | `blast_radius_sweep()` exclude list extended (+ rationale comment) | +14 / -7 |
| `test-fixtures/build.sh` | `_setup_v10_pack_src()` adds idempotent post-clone v10-init sweep patch | +21 / -2 |
| `scripts/test-migrator-behavior-preservation.sh` | Adds BASELINE source-path patch retargeting BD-135 rename | +32 / 0 |
| `test-fixtures/manifest.txt` | Auto-regenerated: new SHAs reflect successful v10 fixture builds (previously failing) | +4 / -4 |

No new files. No deletions. No changes to PM-only files
(BACKLOG.md / CHANGELOG.md / README.md / PACK-CHAT.md / PACK-AGENTS.md
/ root or template trinity files). No test-script edits beyond the
behavior-preservation harness fix (which is a test infrastructure file
within scope).

---

## Verification

### `bash scripts/tests/test-init-project.sh`

```
=== Group 3: stage S11 v11 artifacts (fresh install) ===
  PASS 3.1 fresh install rc=0
  PASS 3.1 S11 stage ran
  ...
  PASS 3.4 pack-help.sh emits client-side header

=== Summary ===
Passed: 34
Failed: 0
All tests passed.
```

### `bash test-fixtures/build.sh --all --clean`

```
── building v10-minimal ──
  HEAD:  19558cbac58ed3e47642a6bbe64418a38c60bc16
── building v10-realistic-ot ──
  HEAD:  4c62945f72b037908b38967d5d8f019745263258
── building v11-flat-file ──
  HEAD:  39e8978d120d55e0d70123e867292ec19d5f6139
── building v11-tracker-on ──
  HEAD:  e4317694550f18516ea47dc1f92e7f5cc0342cf3
── building existing-project-mid-dev ──
  HEAD:  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
manifest written
```

Determinism verified: rebuilt all five fixtures a second time;
`build.sh --verify` reports OK against the manifest written by the
first build:

```
v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
v11-flat-file OK: 39e8978d120d55e0d70123e867292ec19d5f6139
v11-tracker-on OK: e4317694550f18516ea47dc1f92e7f5cc0342cf3
existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

### `bash scripts/test-migrator-behavior-preservation.sh`

```
== [v10-minimal] A4 — stdout equality (post-redaction) ==
  pass: [v10-minimal] A4 stdout byte-identical post-redaction
##  negative-leg tests (5 — exit-code parity)
  pass: [neg] N1 EXIT_PACK_INVALID (PACK unset) baseline=adapter=10
  pass: [neg] N2 EXIT_NOT_GIT baseline=adapter=11
  pass: [neg] N3 EXIT_DIRTY baseline=adapter=12
  pass: [neg] N4 EXIT_NOT_BASELINE baseline=adapter=13
  pass: [neg] N5 EXIT_BASELINE_MISSING baseline=adapter=14

=== Results: 15 passed, 0 failed ===
```

### `python3 scripts/validate-pack.py`

```
── Check 28: PM-startup per-CLI parity (v10.1, BD-126) ──
  OK: claude:  ... Step 4 + Step 6 RAG line match canonical
  OK: codex:   ... Step 4 + Step 6 RAG line match canonical
  OK: gemini:  ... Step 4 + Step 6 RAG line match canonical

============================================================
PASSED — all checks clean
```

### Adjacent regression sanity (sampled)

| Suite | Result |
|---|---|
| `scripts/test-detect.sh` | 40 passed, 0 failed |
| `scripts/test-migrator-core.sh` | 19 passed, 0 failed |
| `scripts/test-migrator-manifest.sh` | 12 passed, 0 failed |
| `scripts/test-restore-from-backup.sh` | 36 passed, 0 failed |
| `scripts/tests/test-customization-preserve.sh` | 72 passed, 0 failed |
| `scripts/tests/test-issue-forms.sh` | 78 passed, 0 failed |

No regressions in adjacent suites.

---

## Plan deviations

None. The prompt explicitly named the fix-shape as a design call;
chosen approach (named-file excludes for current pack; surgical
post-clone patch for v10 tag) is documented above. The third surface
(`test-migrator-behavior-preservation.sh`) was a previously-undiagnosed
collateral bug surfaced once the v10 fixture builds were unblocked —
it is a BD-135 baseline-drift artifact, not a new design call. Same
surgical-patch pattern applied at the harness level for symmetry.

---

## New POQs introduced

None requiring a new BD. The BD-135 baseline-drift could in principle
be addressed by refreshing the BD-119 BASELINE snapshot file, but
that is appropriately a future hygiene task rather than a blocker;
the harness patch is sufficient and resilient to repeating BD-135-style
renames in the future (the patch is a no-op when source path is already
current).

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| `bash scripts/tests/test-init-project.sh` passes (all groups, including Group 3) | PASS — 34 passed, 0 failed |
| `bash test-fixtures/build.sh --all --clean` succeeds (v10-minimal, v10-realistic-ot, v11-flat-file, v11-tracker-on, existing-project-mid-dev) | PASS — 5/5 fixtures built; manifest deterministic across two rebuilds |
| `bash scripts/test-migrator-behavior-preservation.sh` passes | PASS — 15 passed, 0 failed |
| `python3 scripts/validate-pack.py` PASSES (all 28 checks clean) | PASS — `PASSED — all checks clean` |
| Adjacent suites still green (no regressions) | PASS — 6 sampled suites all green (257 passing assertions across them) |
| Trinity rule respected (no asymmetric edit to project-template trinity files) | PASS — no trinity files touched |
| PM-only files untouched | PASS — no edits to BACKLOG.md / CHANGELOG.md / README.md / PACK-CHAT.md / PACK-AGENTS.md / CLAUDE.md / AGENTS.md / GEMINI.md (root or project-template/) |
| BD-128 left at `Status: Open` in BACKLOG.md (Pack Chat flips, not me) | PASS — BACKLOG.md untouched |
| No state-changing git operations | PASS — only `git status`, `git diff`, `git log`, `git rev-parse`, `git show`, `git show-ref` used |
| macOS bash 3.2 + BSD compatibility (sed -i.bak with backup, no GNU-only flags) | PASS — every sed call uses `sed -i.bak` then `rm -f *.bak` for BSD parity |

---

## Files-changed inventory

```
M scripts/init-project.sh
M scripts/test-migrator-behavior-preservation.sh
M test-fixtures/build.sh
M test-fixtures/manifest.txt    (auto-regenerated by build.sh; expected delta)
```

`git diff --stat`:
```
 scripts/init-project.sh                        | 21 ++++++++++++-----
 scripts/test-migrator-behavior-preservation.sh | 32 ++++++++++++++++++++++++++
 test-fixtures/build.sh                         | 23 ++++++++++++++++++
 test-fixtures/manifest.txt                     |  8 +++----
 4 files changed, 74 insertions(+), 10 deletions(-)
```

---

## Working-tree state at report time

```
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.

Changes not staged for commit:
  modified:   scripts/init-project.sh
  modified:   scripts/test-migrator-behavior-preservation.sh
  modified:   test-fixtures/build.sh
  modified:   test-fixtures/manifest.txt
```

No staged changes. No untracked files. HEAD unchanged at `ffecfef`.
Pack Chat owns the commit; suggested message:

```
fix: v11 — BD-128 unblock CI tests-job (sweep + v10-fixture + behavior-preservation)
```

---

## Deferred items

None require new BDs. Two pieces of follow-up hygiene that the user
may optionally fold into a future BD:

1. **Refresh the BD-119 BASELINE snapshot file**
   (`scripts/.bd119-pre-refactor-monolith.sh.snapshot`, gitignored) so
   the migrator-behavior-preservation harness no longer relies on the
   inline source-path patch. Low priority — the patch is idempotent
   and self-documenting, and any new path-rename in
   `migrate-v10-to-v11.sh` source will need a parallel patch line
   regardless of which baseline materialization path is chosen.

2. **Document the sweep exclude policy** somewhere durable (likely
   `supporting-docs/MIGRATION-v9-to-v10.md` or
   `INSTALL-PROCEDURES.md` Procedure 5-C.1) so future contributors
   don't re-introduce the bug by adding new files in `docs/pack/` or
   `scripts/lib/` that legitimately reference retired pack-version
   artifact names. Out of scope for this BD — this is a process
   hardening, not a CI fix.
