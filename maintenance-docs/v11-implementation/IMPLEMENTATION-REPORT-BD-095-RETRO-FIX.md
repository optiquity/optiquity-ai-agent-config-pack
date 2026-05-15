# IMPLEMENTATION-REPORT-BD-095-RETRO-FIX

Retroactive per-BD review-fix for BD-095 ("`migrate-v10-to-v11.sh`
two-phase `--dry-run` / `--apply` / `--resume` workflow"), part of Batch
21c per the 2026-05-15 review/fix cycle. Addresses all 12 findings
(1 MUST, 4 SHOULD, 7 NIT) raised in
`maintenance-docs/v11-implementation/PACK-REVIEW-BD-095-RETRO.md`.

## Branch + HEAD

- **Branch:** `v11-dev`
- **HEAD SHA at session start:** `304078f3d88aa48d763dd8e5c4b3d41917076640`
- **HEAD SHA at session end:** `07e9c1aaee2e08148af598ff7aea39ff94dc4557`
  (Pack Chat committed two unrelated retro-fix batches — BD-129, BD-131
  — between the pre-flight and the report write; my edits are
  unaffected because they target disjoint files.)

The BACKLOG `Resolved:` dangling-link finding from the original review
is closed by commit `614e67e` (Pattern B bulk-fix); no other Batch 21c
cross-cuts apply here. None of the concurrent BD-129 / BD-131 retro
files overlap mine.

## Findings disposition

| Finding | Severity | Disposition | Files |
|---|---|---|---|
| F1 — Dry-run fingerprint covers a *subset* of the customization surface | MUST | FIXED | `dry-run.sh` (+/-167) |
| F2 — Framework `--help` and idempotency error message are stale post-BD-095 | SHOULD | FIXED | `migrator-core.sh` (lines 244-245), `migrator-stages.sh` (line 133) |
| F3 — Bare invocation does not detect a paused state | SHOULD | FIXED | `migrate-v10-to-v11.sh` (bare branch) |
| F4 — `--apply` after pause produces no recovery guidance | SHOULD | FIXED | `apply.sh` (`migrate_v10_to_v11_apply_run` head) |
| F5 — Duplicate mode flag silently mis-routed | SHOULD | FIXED | `migrate-v10-to-v11.sh` (mode dispatcher) |
| F6 — `customization_report` failure during dry-run silently swallowed | NIT | FIXED | `dry-run.sh` (renderer call site) |
| F7 — Stale `*.merge-conflict` aliasing comment in apply.sh | NIT | FIXED | `apply.sh` (line 47 banner-comment) |
| F8 — `_stage_libs` wrapper writes fingerprint on early framework failure | NIT | DOCUMENTED + WORKAROUND | `apply.sh` (commentary) |
| F9 — Fingerprint stash mktemp leaks on early framework failure | NIT | FIXED | `apply.sh` (`_stage_libs` wrapper drops the stash; belt-and-braces post-call cleanup) |
| F10 — `--resume` re-runs `_stage_relocations` / `_stage_artifact_installs` despite empty adapter | NIT | FIXED (commentary; v11→v12 audit prompt) | `resume.sh` |
| F11 — `_v10_v11_resume_classify_sidecars` runtime is unused | NIT | FIXED | `resume.sh` (dedupe error-block listing) |
| F12 — `--apply` recovery emits `${PACK:-/path/to/pack}` instead of resolved PACK | NIT | FIXED | `apply.sh` (4 call sites), `resume.sh` (1 site) |

12 / 12 findings addressed. F8 is documented-as-known plus partially
mitigated by F9's stash cleanup; the underlying fix belongs in BD-119's
framework (preserve-list in `_stage_libs`) per the reviewer's explicit
framing in PACK-REVIEW-BD-095-RETRO.md F8.

## Per-finding detail

### F1 — Fingerprint surface coverage (MUST)

**Problem.** `dry-run.sh` lines 85-96 hardcoded a *subset* of the
v10→v11 customization surface:

```sh
local explicit=( "CLAUDE.md" "AGENTS.md" "GEMINI.md" \
    ".codex/config.toml" "BACKLOG.md" )
local sweep_dirs=( ".claude/agents" ".codex/agents" ".gemini/agents" )
```

The `migrator_manifest` declares 14 `transform`-class rows; only 5 of
those (the trinity + `.codex/config.toml`) appeared in the hardcoded
list. A user mutating `.claude/settings.json`, `.mcp.json.example`,
`.codex/config.toml.example`, `.codex/requirements.toml`, `.gemini/.env`,
`.gemini/settings.json`, `docs/pack/PM-CHAT.md`, etc. between
`--dry-run` review and `--apply` would silently bypass the freshness
gate.

**Fix.** Replace the hardcoded arrays with a dynamic union of:

1. `migrator_target_surface_for_version "$MIGRATOR_FROM_VERSION"` — the
   framework helper at `scripts/lib/migrator-core.sh:471` whose v10
   entry contributes the trinity files, `.codex/config.toml`,
   `BACKLOG.md`, plus the three per-CLI `agents/` directories. Files
   are hashed individually; directories are swept recursively (via
   `find -type f`).
2. `migrator_manifest` — every row whose action column is `transform`
   (project-relpath in column 2). Comment lines / blanks ignored, same
   lenience as `_manifest_parse`.

Duplicates between (1) and (2) are unioned via `sort -u`; the union is
then hashed once. Implementation chooses two intermediate temp files
(`files_listing` + `dirs_listing`) plus a pre-final `sort -o` over the
combined `<relpath>\t<sha>` listing so the final fingerprint is
deterministic and union-stable regardless of source-list ordering.

The fix consumes the framework's existing helper per ARCHITECTURE-BD-119
§9.2 ("avoid duplicating surface knowledge") rather than expanding the
helper itself, because the helper lives at `migrator-core.sh:471` (out
of my edit scope; BD-101 owns the rest of `migrator-core.sh`). The
helper-plus-manifest union is structurally equivalent to expanding the
helper because the manifest is the authoritative table of `transform`
sites — the dry-run is now driven by the same data the apply path uses.

**`unknown` sentinel.** When the helper returns its `unknown` sentinel
(e.g. for an unsupported `MIGRATOR_FROM_VERSION`), the fix emits a
`warn` and falls back to the manifest-only path. Future v11→v12
adapters that wire the helper for `v11` get the union behavior for
free.

**Manifest-row file existence.** Manifest rows whose target path does
not exist on disk are silently skipped (unchanged from pre-fix
behavior). A v10 client with no `docs/pack/PROMPT-TEMPLATES.md` (a
v11-additive file) will still produce a fingerprint that drifts
correctly when, say, `.claude/settings.json` is later edited.

**Stale message text.** The freshness-FAIL error block in `apply.sh`
also listed only the pre-fix subset ("CLAUDE.md / AGENTS.md / GEMINI.md /
.codex/config.toml / BACKLOG.md / per-CLI agents/"). Updated to point
at the helper + manifest as the authoritative source so the user can
self-audit which file drifted.

### F2 — Stale `--help` / idempotency strings (SHOULD)

**Problem.** Two stale-string sites:
- `migrator-core.sh:244-245` — `_migrator_usage` says `--apply`/`--resume`
  are "reserved for BD-095 (errors today)".
- `migrator-stages.sh:133` — S0 idempotency `die` says `--resume is
  reserved for BD-095 and not yet implemented`. A user who re-runs the
  migration on an already-migrated tree is told to restore from backup
  when `--resume` is in fact the right path for paused dispatches.

**Fix.** Both sites updated with accurate post-ship descriptions
(verbatim per the reviewer's suggested wording in
PACK-REVIEW-BD-095-RETRO.md F2). `--help` now describes the freshness
gate + pause semantics; the idempotency `die` now points the user at
`--help` for `--resume` semantics.

**Verification.** `grep -c 'reserved for BD-095'` returns 0 across
every `scripts/lib/*.sh` and `scripts/lib/migrate-v10-to-v11/*.sh`
file (verified post-fix).

### F3 — Bare invocation after pause (SHOULD)

**Problem.** Sequence: bare invocation → `--apply` paused at S3 with
sidecars → user reconciles sidecars but bare-reinvokes (forgets
`--resume`) → bare flow sees fresh fingerprint (still <24h, sha
unchanged because user only touched sidecars not in the surface) →
calls `migrate_v10_to_v11_apply_run` → wipes `dispositions.tsv` →
calls `migrator_run --apply` → S0 passes (no dispositions.tsv) → S1
fails on backup-dir-already-exists. Error tells user to remove backup;
correct answer is `--resume`.

**Fix.** Insert a paused-state guard at the top of the bare branch in
`scripts/migrate-v10-to-v11.sh` (right after target resolution, before
the fingerprint freshness check). When `stage-S3.paused` is present,
emit a typed-error block naming the sentinel + the `--resume`
recovery line + the alternative ("restore from backup and start
over"); exit `EXIT_INTERNAL` (99).

The PACK fallback at this site is preserved (`${PACK:-/path/to/pack}`)
because the bare-invocation path runs *before* any framework-level
PACK validation — F12's "drop the fallback" rationale doesn't apply
here.

### F4 — `--apply` after pause (SHOULD)

**Problem.** Same UX trap as F3 but via the explicit `--apply` flag.
The freshness check passes (sidecars aren't in the surface), the
post-S3-conflict-pause sentinel sits in the state dir, and the apply
falls through to S1 backup-dir-already-exists.

**Fix.** Insert the paired paused-state guard at the head of
`migrate_v10_to_v11_apply_run` (immediately after target resolution,
before the freshness check). Same typed-error block; exit
`EXIT_INTERNAL`. PACK fallback dropped here (F12 logic — by the time
this guard fires, PACK has been validated upstream by the dispatcher
flow).

The bare-branch path (F3) bypasses `apply.sh`'s guard because it
calls `migrate_v10_to_v11_apply_run` only after its own paused-check
fires; the F3 + F4 guards are line-disjoint and both required.

### F5 — Duplicate mode flag fail-loud (SHOULD)

**Problem.** The dispatcher in `migrate-v10-to-v11.sh` captured the
*first* `--<mode>` flag and pushed any subsequent ones to `_passthru`.
The reviewer's example: `--dry-run --apply` ran with `_MIGRATOR_DRY_RUN=1`
and `_MIGRATOR_MODE="apply"` — contradictory state the framework's
parser doesn't validate. `--dry-run --resume` produced the framework's
"call path was not intercepted by the adapter" diagnostic — confusing
to the user.

**Fix.** The `_passthru+=("$_a")` branch on duplicate is replaced with
an immediate fail-loud:

```sh
printf 'error: multiple mode flags: %s and %s (only one of --dry-run / --apply / --resume permitted)\n' \
    "$_mode" "$_a" >&2
exit "${EXIT_INTERNAL:-99}"
```

Exit code 99 (`EXIT_INTERNAL`) — verified end-to-end with all six
pairwise combinations (`--dry-run --apply`, `--dry-run --resume`,
`--apply --dry-run`, `--apply --resume`, `--resume --dry-run`,
`--resume --apply`).

### F6 — Swallowed `customization_report` failure (NIT)

**Problem.** `dry-run.sh` lines 183-190 (pre-fix) called
`customization_report ... >/dev/null 2>&1 || true`. A renderer failure
(malformed dispositions.tsv row, awk error, missing helper) silently
produced no `report.md`; downstream Gate 1 would emit `[FAIL] report.md
not rendered` with no diagnostic.

**Fix.** Capture stderr to `$state_dir/customization_report.stderr`
on failure; emit `warn`s that name the first 5 lines + the full-file
path; leave the stderr file in place for Gate 1 to reference. On
success the stderr file is deleted (no clutter).

### F7 — Stale `*.merge-conflict` comment (NIT)

**Problem.** `apply.sh:47` referenced `*.merge-conflict (a.k.a.
*.${MIGRATOR_OWN_SIDECAR_SUFFIX})` — a documentation artifact from the
spec era. POQ-2 closure (per the BD-095 implementation report §11)
already dropped bare `*.merge-conflict` from user-facing surfaces; the
code comment was the last residue.

**Fix.** Replace with `*.${MIGRATOR_OWN_SIDECAR_SUFFIX} sidecars
(currently *.v10-customized for the v10→v11 adapter)` — one path
pattern, no aliasing.

### F8 — Fingerprint restore on framework failure (NIT, DOCUMENTED)

**Problem.** The `_stage_libs` wrapper in `apply.sh` restores the
stashed fingerprint after the framework's `_stage_libs` runs. If S3
dispatch fails, the fingerprint is restored to a half-mutated state
dir; harmless (no `--apply` against the same tree will succeed) but
pointless.

**Disposition.** The reviewer explicitly framed the underlying fix
(preserve-list in `_stage_libs`) as BD-119 framework cleanup,
out of scope for BD-095 retro. Inline commentary added to apply.sh
documenting (a) the workaround, (b) the framework gap, and (c) the
F9 stash cleanup that subsumes the practical leak concern. No new BD
opened — the reviewer's framing already names the future work.

### F9 — Fingerprint stash mktemp leak (NIT)

**Problem.** `fp_stash=$(mktemp)` at apply.sh:344 was followed by a
single `rm -f "$fp_stash"` only after `migrator_run --apply` returned.
Any framework `die` / `fail_stage` between trap-set and the rm leaked
a temp file under `$TMPDIR`.

**Fix.** Two-layer cleanup:
1. The `_stage_libs` wrapper (which restores the stash to the state
   dir) drops the stash file as soon as the restore lands and zeroes
   `$fp_stash` — covers the common case where `_stage_libs` runs.
2. Belt-and-braces: the post-`migrator_run` cleanup runs only when
   `$fp_stash` is non-empty. If the `_stage_libs` wrapper never ran
   (early-failure path), the post-call line still removes the stash.

Bash 3.2 compatible. The reviewer's `EXIT` trap suggestion was
considered but rejected because `migrator_run` (called from the same
function) sets its own `_migrator_exit_trap EXIT` and traps don't
compose without `unset`/restore plumbing — the two-layer cleanup is
simpler and equally leak-free.

### F10 — `--resume` re-runs no-op stages (NIT)

**Problem.** `resume.sh` lines 235-236 call `_stage_relocations` and
`_stage_artifact_installs`. The v10→v11 adapter declares both
`migrator_relocations` and `migrator_artifact_installs` empty (the
post-dispatch hook does the equivalent work), so the framework calls
correctly no-op. Future v11→v12 adapter authors who copy this resume.sh
verbatim might inherit unsafe semantics if their adapter declares
non-empty rows.

**Fix.** Inline commentary added describing (a) why the calls are
no-ops here, (b) why we keep them (byte-equivalent to
`_migrator_run_stages`'s tail, exercises the framework's no-op
contract), and (c) the audit prompt for v11→v12 reuse. No code change
because the calls are correct today.

### F11 — Duplicate classification work (NIT)

**Problem.** `resume.sh` invoked `_v10_v11_resume_classify_sidecars`
once to count, then re-awk'd the same `$classification` string inside
the error block to render the `Unresolved sidecars:` listing. Minor
duplication.

**Fix.** Build the `unresolved_list` text in the same awk pass that
counts:

```sh
unresolved_list=$(printf '%s\n' "$classification" \
    | awk -F'\t' '$1 == "unresolved" {print "  " $2}')
unresolved=$(printf '%s\n' "$unresolved_list" | grep -c '^  ' || true)
resolved=$(printf '%s\n' "$classification" \
    | awk -F'\t' '$1 != "unresolved" && $1 != "" {c++} END {print c+0}')
```

The error block reuses `$unresolved_list` directly. Same observable
behavior; one fewer awk invocation per resume call.

### F12 — `${PACK:-/path/to/pack}` fallback (NIT)

**Problem.** Five sites in `apply.sh` + `resume.sh` (per the
reviewer's enumeration) emit `"${PACK:-/path/to/pack}"` in recovery
guidance. By the time these recovery lines fire, PACK has already
been validated upstream — the fallback is unreachable and renders as
a real-path-looking footgun.

**Fix.** Drop the fallback at all four reviewer-named sites in
`apply.sh` (the freshness-fingerprint-missing error, the freshness-
window-stale error, the working-tree-drift error, the post-S3-pause
guidance) + the `resume.sh` unresolved-sidecars error. My new F4
paused-guard site (added in this fix) also drops the fallback for
consistency — the F4 guard fires inside `migrate_v10_to_v11_apply_run`
where PACK is upstream-validated by the dispatcher flow.

The bare-branch F3 paused-guard in `migrate-v10-to-v11.sh`
intentionally KEEPS the fallback because it fires before any
framework-level validation — at that point PACK genuinely could be
unset and an empty string in the recovery line would be more
confusing than `/path/to/pack`.

## Files changed

| Path | Change | Net lines |
|---|---|---|
| `scripts/lib/migrate-v10-to-v11/dry-run.sh` | modified | +120/-31 (F1, F6) |
| `scripts/lib/migrate-v10-to-v11/apply.sh` | modified | +56/-12 (F4, F7, F8, F9, F12) |
| `scripts/lib/migrate-v10-to-v11/resume.sh` | modified | +35/-10 (F10, F11, F12) |
| `scripts/lib/migrator-core.sh` | modified (lines 244-245 only) | +5/-2 (F2) |
| `scripts/lib/migrator-stages.sh` | modified (line 133 only) | +1/-1 (F2) |
| `scripts/migrate-v10-to-v11.sh` | modified | +33/-7 (F3, F5) |
| `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | modified | +92 (Group 7 added) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-095-RETRO-FIX.md` | NEW | this file |

Total: 7 modified, 1 new. No deletions.

## Plan deviations

None. All 12 findings were addressed using the reviewer's suggested
fixes verbatim or near-verbatim. F8 is the only finding NOT closed by
a code change — and the reviewer's text explicitly framed F8 as
"framework cleanup; BD-095 currently works around with a stash";
inline commentary was added documenting this.

The F1 fix uses a helper-plus-manifest union rather than expanding the
helper itself (because `migrator-core.sh:471` is out of my edit scope
per the prompt's BD-101 carve-out). Reviewer's rationale was "consume
the framework helper"; I do that AND read the manifest, which is
structurally equivalent because the manifest is the authoritative
`transform`-site table.

## New POQs

None. The reviewer's text mentions "framework cleanup" for F8 but
explicitly assigns it to BD-119 (already shipped + closed); no new BD
needed.

## Verification

### Per-finding verification

- **F1 (MUST):** Manual harness on `/tmp/migrate10-bd095-f1-test`
  fixture with all 14 v10 transform-class manifest rows seeded.
  Dry-run report:

  ```
  Dry-run fingerprint stamped: .../dry-run.fingerprint
    target_sha256: ed3b1521519f4988327b02154da82f9f8d579010dac56a76822335778dcec93a
    target_files:  13
  ```

  `target_files: 13` matches the expected 13 manifest paths (the 14th
  manifest row, `docs/pack/PROMPT-TEMPLATES.md`, doesn't exist at v10
  so it's correctly skipped).

  Drift on `.claude/settings.json` post-dry-run is now correctly
  detected:

  ```
  error: --apply refused; working-tree fingerprint changed since --dry-run
    recorded sha:  ed3b... (files=13)
    current sha:   a199... (files=13)
  ```

  Pre-fix this would have proceeded silently.

- **F2 (SHOULD):** `grep -c 'reserved for BD-095' scripts/lib/*.sh
  scripts/lib/migrate-v10-to-v11/*.sh` returns 0 across all 35 files.

- **F3 (SHOULD):** Manual harness, fixture with synthesized
  `stage-S3.paused` sentinel:

  ```
  $ bash migrate-v10-to-v11.sh "$T"
  error: a paused migration exists for this target
    paused-sentinel: .../stage-S3.paused
  → Resolve the listed sidecars then run:
      PACK=... scripts/migrate-v10-to-v11.sh --resume ...
  Exit: 99
  ```

- **F4 (SHOULD):** Manual harness, same fixture:

  ```
  $ bash migrate-v10-to-v11.sh --apply "$T"
  error: --apply refused; a paused migration exists
    paused-sentinel: .../stage-S3.paused
  → Resolve the listed sidecars then run:
      PACK=... scripts/migrate-v10-to-v11.sh --resume ...
  Exit: 99
  ```

- **F5 (SHOULD):** All six pairwise mode-flag combinations tested
  end-to-end. Sample:

  ```
  $ bash migrate-v10-to-v11.sh --dry-run --apply "$T"
  error: multiple mode flags: --dry-run and --apply (only one of --dry-run / --apply / --resume permitted)
  Exit: 99
  ```

- **F6-F12 (NIT):** Code review against reviewer's suggested fixes;
  syntax-clean (`bash -n` PASS); regression test surface unaffected.

### Test surface

| Test | Pre-fix | Post-fix |
|---|---|---|
| `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 40 PASS | 61 PASS (40 pre-existing + 21 new in Group 7) |
| `scripts/tests/test-migrate-v10-to-v11.sh` | 43 PASS | 43 PASS |
| `scripts/tests/test-migrate-v10-to-v11-gates.sh` | 41 PASS | 41 PASS |
| `scripts/test-migrator-core.sh` | 19 PASS | 19 PASS |
| `scripts/test-migrator-manifest.sh` | 12 PASS | 12 PASS |
| `scripts/validate-pack.py` | 32 checks PASS | 32 checks PASS |

Total: 176 PASS post-fix (vs 155 pre-fix; +21 net new tests for the
F1 / F3 / F4 / F5 regressions).

### `bash -n` syntax checks

All modified `.sh` files pass `bash -n`:

- `scripts/lib/migrate-v10-to-v11/dry-run.sh` — OK
- `scripts/lib/migrate-v10-to-v11/apply.sh` — OK
- `scripts/lib/migrate-v10-to-v11/resume.sh` — OK
- `scripts/migrate-v10-to-v11.sh` — OK
- `scripts/lib/migrator-core.sh` — OK
- `scripts/lib/migrator-stages.sh` — OK
- `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` — OK

## Definition-of-Done checklist

| Item | Status |
|---|---|
| All 12 findings addressed (F1-F12) | PASS |
| F1 fingerprint covers full 13/14 manifest paths | PASS (verified end-to-end) |
| F2 grep-zero across migrator lib files | PASS |
| F3 bare-after-pause errors with --resume guidance | PASS (test 7.2) |
| F4 apply-after-pause errors with --resume guidance | PASS (test 7.3) |
| F5 duplicate mode flags fail loud (all 6 pairs) | PASS (test 7.4 × 6) |
| `bash -n` clean on every modified `.sh` | PASS |
| Existing test surface unaffected (regressions) | PASS (43+41+19+12 unchanged) |
| Extended test coverage for fixes | PASS (Group 7 +21 tests) |
| Validator: 32 checks PASS | PASS |
| Trinity rule respected (no CLAUDE/AGENTS/GEMINI edits) | N/A (no trinity files touched) |
| Out-of-scope files untouched | PASS (BD-101 / BD-129 / BD-130 / BD-131 territory respected) |
| Report uses standard sections | PASS |
| Branch + HEAD SHA recorded | PASS |
| Files-changed inventory included | PASS |
| New POQs disposition | PASS (none) |

All items: PASS.
