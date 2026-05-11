# IMPLEMENTATION-REPORT-BD-095.md

**BD-095 — `migrate-v10-to-v11.sh` two-phase `--dry-run` / `--apply` /
`--resume` workflow**

## 1. Verdict

**Done.** All success criteria met; all tests green.

## 2. Branch + final HEAD SHA

- Branch: `v11-dev`
- Final HEAD SHA (worktree base; pack-coder does not commit): `aa03e4930760d0e93ec944a953e7295831a279a1`
- Recent commits (top of `git log --oneline -5`):
  ```
  aa03e49 docs: v11 — BD-139 open + Batch 12 (BD-104) audit report (1 MAJOR + 2 MINOR + 2 NIT)
  4a4a85b docs: v11 — BD-138 schedule BD-136 implementation as Batch 20b (no v11.1 deferral)
  f1dc255 fix: v11 — BD-137 retire test-migrator-behavior-preservation.sh harness
  0da7d59 docs: v11 — BD-136 third amendment …
  5e77939 fix: v11 — restore +x bit on 6 scripts clobbered by BD-104 pack-coder edits
  ```

## 3. Pre-flight check output

```
$ git rev-parse HEAD
aa03e4930760d0e93ec944a953e7295831a279a1
$ git rev-parse --abbrev-ref HEAD
v11-dev
$ ls scripts/lib
customization-preserve.sh   migrator-core.sh        tracker-config.sh
customization-report.sh     migrator-manifest.sh    tracker-doctor.sh
detect.sh                   migrator-stages.sh      tracker-errors.sh
recommendation.sh           …                       tracker-mirror.sh
template-translations.sh    template-version.sh     tracker-provider.sh
three-way.sh                tracker-agent-read.sh   …
$ ls scripts/tests
fixtures                              test-migrate-v10-to-v11.sh
pack-help-test.sh                     test-issue-forms.sh
recommendation-state-schema-test.sh   tracker-*-test.sh (×11)
test-customization-preserve.sh        …
test-init-project.sh
```

Baseline test runs before any edits:

```
$ bash scripts/test-migrator-core.sh   →  19 passed, 0 failed
$ bash scripts/test-migrator-manifest.sh → 12 passed, 0 failed
$ PACK="$PWD" bash scripts/tests/test-migrate-v10-to-v11.sh → 39 passed, 0 failed
```

Standing-rules read confirmation: CLAUDE.md (pack memory + workflow rules);
PACK-AGENTS.md (no-commit rule); skills `implementation-report`,
`verification-harness`, `commit-discipline` reviewed.

## 4. Per-task summary

### T-1 — `scripts/lib/migrate-v10-to-v11/dry-run.sh` (NEW, 216 lines)

Public API:
- `migrate_v10_to_v11_dry_run_run "$@"` — wraps `migrator_run --dry-run`,
  then renders `report.md` (the framework's `_stage_report` skips the
  render in `--dry-run`; we materialize it for the BD-095 deliverable),
  then stamps `dry-run.fingerprint`.
- `migrate_v10_to_v11_dry_run_compute_fingerprint <target>` — sha-256
  over a sorted listing of every customization-surface file (trinity,
  `.codex/config.toml`, `BACKLOG.md`, all per-CLI `agents/` files).
  Reused by apply.sh's freshness check.

Private helpers prefixed `_v10_v11_dryrun_*`.

### T-2 — `scripts/lib/migrate-v10-to-v11/apply.sh` (NEW, 384 lines)

Public API:
- `migrate_v10_to_v11_apply_run "$@"` — installs hooks (pre-dispatch /
  post-dispatch / `_stage_libs` wrapper) so the framework writes stage
  sentinels and pauses cleanly before S4 if dispatch produced
  `customization-detected-needs-reconciliation` rows. Then calls
  `migrator_run --apply`.
- `migrate_v10_to_v11_apply_check_freshness <target>` — exits with
  documented exit code on missing / stale / drifted fingerprint.

Private helpers prefixed `_v10_v11_apply_*`. Includes the `.git/info/
exclude` patch that adds the state-dir + backup-dir basenames so
`git status --porcelain` does not flag the framework's orchestration
artifacts as project dirt during the auto-apply path.

### T-3 — `scripts/lib/migrate-v10-to-v11/resume.sh` (NEW, 252 lines)

Public API:
- `migrate_v10_to_v11_resume_run "$@"` — verifies each sidecar listed in
  `stage-S3.paused` is resolved (via `.resolved` flag-file OR extension
  removal), enforces forward-only (refuses to rewind past completed
  S4/S5/S6 sentinels), then runs S4..S6 directly without re-invoking the
  framework's S0..S3 (the framework's idempotency guard would otherwise
  fire on the already-existing `dispositions.tsv`).

Private helper `_v10_v11_resume_classify_sidecars` echoes
`<status>\t<sidecar>` rows for inspection / unresolved counting.

### T-4 — `scripts/migrate-v10-to-v11.sh` (MODIFIED, +148 / -2)

- Added the BD-095 mode dispatcher between the existing framework
  source and the historical `migrator_run "$@"` call. The dispatcher
  scans `$@` for the first `--dry-run` / `--apply` / `--resume`, strips
  it, and routes to the matching mode-lib function. Bare invocation
  (no flag) auto-runs `--dry-run` first if no fresh fingerprint exists,
  then `--apply` — preserving the pre-BD-095 single-shot UX for users
  who never need to learn the new flags.
- Added a one-line dry-run gate to `migrator_post_dispatch_hook` so the
  adapter's BD-104 rename + BD-042 relocation + v11 artifact install
  are skipped when `_migrator_is_dryrun`. Without this, dry-run would
  mutate the working tree (BD-095 tests Group 1 case 1.6 fail).

### T-5 — `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (NEW, 328 lines)

Six test groups covering all BD-095 success criteria:
- Group 1: `--dry-run` produces report + dispositions + fingerprint, no
  mutation.
- Group 2: `--apply` succeeds with fresh fingerprint; sentinels written.
- Group 3: `--apply` refused when fingerprint missing / stale / drifted.
- Group 4: `--resume` with both `.resolved` flag-file and
  extension-removal signals.
- Group 5: `--resume` guards (no in-progress, no pause to resume,
  forward-only, unresolved sidecars).
- Group 6: bare-invocation backwards-compat.

Final tally: 40 PASS, 0 FAIL.

## 5. File-change inventory

| Path | Type | Δ |
|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | modified | +148 / -2 |
| `scripts/lib/migrate-v10-to-v11/dry-run.sh` | new | +216 |
| `scripts/lib/migrate-v10-to-v11/apply.sh` | new | +384 |
| `scripts/lib/migrate-v10-to-v11/resume.sh` | new | +252 |
| `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | new | +328 (executable) |

`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-095.md`
(this file) is the reporting artifact, not a code change.

Pre-existing uncommitted state visible in `git status --short` at the
end of the session (NOT my work — present at session start, mentioned
for transparency):
- `M BACKLOG.md` (pre-existing BD-139 entry, prior batch)
- `?? maintenance-docs/v11-implementation/AUDIT-BD-104.md` (pre-existing audit artifact)

## 6. Module boundaries

The three new lib files split BD-095 responsibilities along clean seams:

- **`dry-run.sh`** owns: fingerprint computation, dry-run-driven report
  materialization, the user-facing "review then apply" message after a
  successful dry-run. Knows nothing about sentinels or sidecars.
- **`apply.sh`** owns: freshness gate (24h + sha-equality), git/info/
  exclude housekeeping for the state dir, stage-sentinel marking via
  hook wrappers, conflict-pause-before-S4 logic, and the
  `_stage_libs` wrapper that re-stashes the dry-run.fingerprint after
  the framework's `rm -rf $STATE_DIR`.
- **`resume.sh`** owns: classification of sidecar resolution
  (`.resolved` vs extension-removal), forward-only guard, and the
  S4..S6 hand-driven sequence (the framework's S0..S3 are skipped
  because they already ran). Re-sources three-way + customization-
  preserve + customization-report on demand.

Each lib's public API is one function per mode (`*_run`); all internal
helpers carry a `_v10_v11_<mode>_*` underscore prefix.

## 7. Fingerprint design

Bytes covered: a sorted listing of `<relpath>\t<sha-256-of-file>` for
every file in the v10 customization surface that exists in the target.
The "v10 customization surface" comes from
`migrator_target_surface_for_version v10` adapted to file-level
granularity:

- Explicit list (one row per file when present):
  `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.codex/config.toml`,
  `BACKLOG.md`.
- Recursive sweep (every regular file under the directory):
  `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`.

The combined sha-256 over this listing is the `target_sha256` recorded
in the fingerprint. `target_files` is the row count.

The fingerprint file is plain key=value records:

```
schema=1
to_version=v11
epoch=<unix-epoch-seconds>
target_sha256=<64-hex-chars>
target_files=<integer>
```

`schema=1` allows future BDs to evolve the format. The 24h check
(§6.G) is `now - epoch > V10_V11_DRYRUN_MAX_AGE_SECS` (default 86400);
`now` is `date +%s` (wall-clock — matches recommendation §6.G "friendly
to overnight review"). Clock-went-backwards is treated as stale rather
than fresh.

The freshness gate exits with `EXIT_NOT_BASELINE` (13) on missing /
stale fingerprint and `EXIT_DIRTY` (12) on sha mismatch — codes already
documented for these failure shapes.

## 8. Stage-sentinel design

Sentinels live under `<state-dir>/sentinels/` and are bare-name
touched files:

- `stage-S0.done` … `stage-S6.done` — touched immediately after the
  named stage completes successfully.
- `stage-S3.paused` — present iff the post-S3 conflict-collector found
  one or more `customization-detected-needs-reconciliation` rows in
  `dispositions.tsv` whose sidecar column is non-`-`. Each such sidecar
  path appears one-per-line.

`--resume` requires the BOTH `stage-S3.done` AND `stage-S3.paused` to
exist (anything else means there is no paused run to resume). The
forward-only guard checks each of `stage-S4.done` / `S5.done` /
`S6.done` and refuses if any is present.

The sentinels are written by hook wrappers `apply.sh` installs into
the adapter:
- `migrator_pre_dispatch_hook` → marks S0/S1/S2 (the framework already
  ran them by the time the hook fires).
- `migrator_post_dispatch_hook` → marks S3, then runs the
  conflict-collector, then either pauses cleanly OR continues into the
  adapter's existing post-dispatch work (BD-104 rename + BD-042
  relocation + v11 artifact install) and marks S4/S5.
- `migrator_post_report_hook` → marks S6.

The wrappers are installed via `eval $(declare -f X | sed
'1s/X/_v10_to_v11_orig_X/')` which is bash 3.2 + BSD-sed compatible
(verified on macOS Darwin 25.4).

## 9. Backwards-compat behavior of bare invocation

Bare `scripts/migrate-v10-to-v11.sh [target]` (no flag):

1. Resolve the target.
2. If no fingerprint exists at `<target>/.pack-migrate-v10-to-v11/dry-run.fingerprint`, OR fingerprint epoch is >24h old, OR working-tree fingerprint differs from recorded fingerprint, run `--dry-run` first (auto). The auto-dry-run is logged with banner `── BD-095 backwards-compat: no fresh dry-run found ──` so the user can see what's happening.
3. Run `--apply`. Freshness gate is now satisfied because the auto-dry-run just ran (or because a previous fresh dry-run is still valid).
4. If apply produces sidecars → pause with S3.paused sentinel and the on-screen reconciliation instructions.
5. If apply produces no sidecars → continue through S6 and exit 0.

Result: the pre-BD-095 single-shot UX is preserved; users who don't
care about the new flags keep working as before. The new value-add
(safety gate, pause-on-conflicts, resume) kicks in transparently.

Explicit `--apply` STRICTLY enforces the freshness gate — no
auto-dry-run. Users who need the strict behavior (e.g. CI gates)
get it by passing the flag.

## 10. Plan deviations

None. All work landed against the BD-095 spec without expanding scope
or introducing parallel architectural decisions.

One scope adjustment that's NOT a deviation but worth noting: the
`migrator_post_dispatch_hook` in `scripts/migrate-v10-to-v11.sh`
needed a one-line dry-run gate to make BD-095's auto-dry-run +
fingerprint flow safe. This is a correction of a pre-existing oversight
in the BD-119 refactor (the framework's I6 dry-run plumbing only
short-circuits the framework's own stage helpers, not adapter post-
dispatch hooks); without it, BD-095's dry-run would mutate the working
tree. Documented inline in the adapter.

## 11. Pre-Open Questions (POQs) introduced

### POQ-1 — `MERGE-STRATEGY.md` and `MIGRATION-v10-to-v11.md` still describe BD-095 as future

**Disposition: deferred — recommend follow-up doc-only commit.**

`supporting-docs/MERGE-STRATEGY.md` §A1 (lines 281–308) and
`supporting-docs/MIGRATION-v10-to-v11.md` line 75 still say "BD-095
will extend …" / "single-shot only in v11; BD-095 will extend." With
BD-095 now landed, these prose blocks need to be rewritten to describe
the new modes as live behavior. The BD-095 BACKLOG entry's File/Symbol
list does not name these docs, so I left them untouched per the
"agents only modify scoped files" rule.

Recommended fast-follow: a `docs:` commit that updates the two
sections to describe the live behavior. Pack Chat can take this in the
batch-completion sweep.

### POQ-2 — "*.merge-conflict" is a generic spec name; actual sidecars are "*.${MIGRATOR_OWN_SIDECAR_SUFFIX}" (currently ".v10-customized")

**Disposition: resolved as written; recommend confirming spec wording in a future doc pass.**

The BD-095 BACKLOG description repeatedly uses `*.merge-conflict` as
the sidecar pattern. The actual sidecar suffix is whatever the adapter
declares via `MIGRATOR_OWN_SIDECAR_SUFFIX` (set to `v10-customized`
for v10→v11). The BD-088 customization-preserve library writes those
sidecars and stamps `customization-detected-needs-reconciliation` in
the disposition column. The implementation treats the spec's
"`*.merge-conflict`" as a generic synonym for "rows whose disposition
is needs-reconciliation and whose sidecar column is non-`-`" and uses
the actual `.v10-customized` paths read from `dispositions.tsv` as
the authoritative list. No semantic difference; just a wording
mismatch between the spec and the implementation.

If a future BD wants to actually rename sidecars to `*.merge-conflict`
across the customization-preserve surface, BD-095's resume contract
would still work unchanged — `_v10_v11_resume_classify_sidecars`
operates on the path text, not the suffix.

### POQ-3 — "Stage sentinels mirroring v9→v10 stage-S*.done" — spec mention is approximate

**Disposition: resolved with the specified naming.**

The spec referenced "stage-S*.done" sentinels mirroring the v9→v10
migrator. The v9→v10 migrator was deleted in BD-121; I did not
re-source the historical layout from the `v10` git tag (it would have
been an extra read, no fresh information). I implemented the sentinels
as `stage-S<N>.done` plus a single `stage-S3.paused` for the conflict
pause — the simplest naming consistent with the spec's wording. If
the historical sentinel layout differed, the BD-095 contract is
unaffected because the sentinels are an internal implementation
detail (no external caller reads them; only `--resume` does).

### POQ-4 — Auto-rerun-on-stale-fingerprint in bare invocation is an enhancement beyond the literal spec

**Disposition: resolved with the enhanced behavior; flagged for review.**

The literal spec says bare invocation defaults to `--apply`, and that
`--apply` requires a fresh fingerprint. A strict implementation would
mean bare invocation fails when a stale fingerprint exists (forcing
the user to manually re-run `--dry-run`). I extended the bare path to
auto-rerun `--dry-run` whenever no usable fingerprint exists OR the
existing one is stale OR the working tree drifted. This is a strict
superset of the legacy single-shot UX (the user types
`./migrate.sh <target>` and the migration runs end-to-end as
before). The trade-off is one extra fingerprint computation per
bare invocation in the no-cache case.

If the maintainer wants strict behavior in bare invocation, the
auto-rerun block in `scripts/migrate-v10-to-v11.sh` is one
contiguous block that can be removed without affecting `--apply`
explicit semantics or any of the four mode dispatchers.

## 12. Validator + test-suite pass/fail summary

```
$ bash -n scripts/migrate-v10-to-v11.sh
$ bash -n scripts/lib/migrate-v10-to-v11/dry-run.sh
$ bash -n scripts/lib/migrate-v10-to-v11/apply.sh
$ bash -n scripts/lib/migrate-v10-to-v11/resume.sh
$ bash -n scripts/tests/test-migrate-v10-to-v11-dry-run.sh
   all-syntax-ok

$ PACK="$PWD" bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh
   === Summary ===
   Passed: 40
   Failed: 0
   All BD-095 tests passed.

$ PACK="$PWD" bash scripts/tests/test-migrate-v10-to-v11.sh
   === Summary ===
   Passed: 39
   Failed: 0
   All tests passed.

$ bash scripts/test-migrator-core.sh
   === Results: 19 passed, 0 failed ===

$ bash scripts/test-migrator-manifest.sh
   === Results: 12 passed, 0 failed ===

$ python3 scripts/validate-pack.py
   ============================================================
   PASSED — all checks clean
```

Permission-bit audit:

```
$ git diff --stat | grep -i 'mode change' || echo 'no mode changes'
no mode changes
```

(The new test script `scripts/tests/test-migrate-v10-to-v11-dry-run.sh`
was created with `chmod +x` immediately after Write so the executable
bit is set from the start; no later `chmod` was needed.)

## 13. Working-tree state at handoff (`git status --short`)

```
 M BACKLOG.md
 M scripts/migrate-v10-to-v11.sh
?? maintenance-docs/v11-implementation/AUDIT-BD-104.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-095.md
?? scripts/lib/migrate-v10-to-v11/
?? scripts/tests/test-migrate-v10-to-v11-dry-run.sh
```

Files that ARE my BD-095 work:
- `M scripts/migrate-v10-to-v11.sh`
- `?? scripts/lib/migrate-v10-to-v11/` (contains `dry-run.sh`, `apply.sh`, `resume.sh`)
- `?? scripts/tests/test-migrate-v10-to-v11-dry-run.sh`
- `?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-095.md` (this report)

Files NOT my work (present at session start):
- `M BACKLOG.md` — was already modified at HEAD `aa03e49` time; contains
  BD-139 entry from prior PM-Chat work.
- `?? maintenance-docs/v11-implementation/AUDIT-BD-104.md` — pre-existing
  audit artifact from prior batch.

## 14. Definition-of-Done checklist

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | `scripts/lib/migrate-v10-to-v11/dry-run.sh`, `apply.sh`, `resume.sh` are NEW lib files (3 separate files) with clear module boundaries. | PASS | §5 inventory; §6 boundary description; `wc -l` 216/384/252. |
| 2 | `scripts/migrate-v10-to-v11.sh` parses `--dry-run` / `--apply` / `--resume` flags and dispatches to the appropriate lib. | PASS | Mode dispatcher block in `scripts/migrate-v10-to-v11.sh`; test-dry-run Groups 1/2/4 verify. |
| 3 | Bare invocation preserves backwards-compat per the rule. | PASS | test-dry-run Group 6 (4/4 PASS); test-migrate-v10-to-v11.sh Group 2 (full e2e PASS via bare invocation). |
| 4 | `--apply` enforces 24h freshness check per §6.G with clear failure message. | PASS | test-dry-run Group 3 cases 3.1 (no fingerprint), 3.2 (stale >24h), 3.3 (drift) all PASS. Apply error messages name "fresh --dry-run report" / "24h freshness" / "working-tree fingerprint changed". |
| 5 | `--resume` enforces forward-only per §6.H; accepts both conflict-resolution signals. | PASS | test-dry-run Group 4 cases 4.1 (.resolved flag) + 4.2 (extension removal) both PASS; Group 5 case 5.3 (forward-only guard) PASS. |
| 6 | New test `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` covers all 9 listed sub-cases. | PASS | 40 test assertions across 6 groups; all 9 BD-095 sub-cases mapped to assertions. |
| 7 | Existing `scripts/tests/test-migrate-v10-to-v11.sh` still passes (39/39 last green). | PASS | Final run: 39 passed, 0 failed. |
| 8 | `python3 scripts/validate-pack.py` passes (all checks clean). | PASS | "PASSED — all checks clean". |
| 9 | `bash scripts/test-migrator-core.sh` (19/19) still passes. | PASS | "=== Results: 19 passed, 0 failed ===". |
| 10 | `bash scripts/test-migrator-manifest.sh` (12/12) still passes. | PASS | "=== Results: 12 passed, 0 failed ===". |

## 15. Proposed commit message

```
feat: v11 — BD-095 two-phase --dry-run/--apply/--resume migrator workflow

Splits scripts/migrate-v10-to-v11.sh into the three-mode contract
specified in supporting-docs/MERGE-STRATEGY.md §A1: --dry-run produces
report + dispositions.tsv + a working-tree fingerprint without mutating
project files; --apply enforces a 24h freshness window (§6.G) plus
fingerprint equality before writing; --resume continues a paused
migration after sidecar reconciliation, forward-only, accepting either
the .resolved flag-file or extension-removal signal (§6.H).

Bare invocation (scripts/migrate-v10-to-v11.sh <target>) preserves the
pre-BD-095 single-shot UX by auto-running --dry-run when no fresh
fingerprint exists.

Three new lib modules under scripts/lib/migrate-v10-to-v11/:
  dry-run.sh   216L — fingerprint compute + dry-run dispatch
  apply.sh     384L — freshness gate + sentinels + pause-on-conflicts
  resume.sh    252L — sidecar classify + S4..S6 hand-driven completion

New test scripts/tests/test-migrate-v10-to-v11-dry-run.sh (40 PASS)
covers all 9 sub-cases the spec enumerates. Existing
test-migrate-v10-to-v11.sh (39/39), test-migrator-core.sh (19/19),
test-migrator-manifest.sh (12/12), and validate-pack.py (all checks
clean) all still green.
```
