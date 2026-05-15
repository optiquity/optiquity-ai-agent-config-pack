# PACK-REVIEW-BD-130-RETRO

Retroactive per-BD review for BD-130
(`Wire tracker_doctor_run so pack tracker doctor works`).
Part of Batch 21c (per-BD retros for v11.0 BLOCKER cluster).

- Original commit: `1bdd1f5` (combined BD-129 + BD-130). Only the BD-130
  portion (`tracker_doctor_run` wiring) is in scope here.
- BD-130 status at review time: `Resolved` (per `BACKLOG.md:1920`).
- Scope anchor verified: BD-130 changes are confined to
  `scripts/pack-tracker.sh` (+2 lines), `scripts/tracker-migrate.sh`
  (-179 net), `scripts/lib/tracker-doctor.sh` (NEW, 201 lines), and
  `scripts/tests/tracker-bd130-doctor-wired-test.sh` (NEW, 114 lines).
  Implementation report at
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md`
  (now archived under v11/).
- Sibling commit content (`scripts/lib/tracker-config.sh`,
  `tracker-labels.sh`, `tracker-provider-gh.sh`,
  `tracker-bd129-gh-repo-test.sh`) is BD-129 and is NOT covered here.
- Per the prompt, this review did NOT consult any prior
  `PACK-REVIEW-*.md`.

Reviewer: pack-reviewer (retroactive). Methodology: `review` skill +
`architecture-review` skill applied to a wiring-fix BD with a small
relocation footprint.

---

## Verdict

The BLOCKER is fully and correctly resolved. `pack tracker doctor`
emits doctor-formatted output (banner + check lines + completion
summary) instead of `tracker_doctor_run: command not found`. The
function body was relocated byte-identically; behavior preservation is
verifiable by direct diff (see Evidence). Composition with the
co-shipped BD-129 is clean — the doctor path does not touch any of
BD-129's GH_REPO plumbing.

No MUST findings. Six SHOULD/MINOR findings and eight NIT findings
follow. None block ship; all are appropriate for a tech-debt sweep
batch or a follow-up doc-cleanup commit.

---

## Touch-point classification

| Touch point | Pre-BD-130 | Post-BD-130 | Net |
|---|---|---|---|
| `scripts/lib/tracker-doctor.sh` | absent | NEW (201 lines) | created |
| `scripts/pack-tracker.sh` | 434 lines | 436 lines | +2 (source line + shellcheck disable) |
| `scripts/tracker-migrate.sh` | ~370 lines | 188 lines | -178 net (function body removed; pointer comment kept) |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | absent | NEW (114 lines) | created |
| `BACKLOG.md` BD-130 entry | Open | Resolved | flipped (Pack Chat) |

Files touched by BD-130 are disjoint from BD-129's set. The combined
commit's "no shared files" claim (commit message) is verified.

---

## 6-dimension assessment

1. **Correctness.** The wiring fix works. `cmd_doctor` in both
   `pack-tracker.sh:159–173` and `tracker-migrate.sh:142–156` now
   resolves `tracker_doctor_run` to the lib-defined function. Live
   smoke test from the pack root and from `/tmp` both produce the
   doctor banner + WARN/INFO lines + completion summary. Test
   `tracker-bd130-doctor-wired-test.sh` 8/8 PASS confirmed in re-run.
   `set -eu` in both dispatchers does not interact pathologically with
   the lib body — failure paths are guarded by `2>/dev/null` /
   `|| echo ""` / `local x=$(cmd)` (the last form swallows -e because
   `local` is a builtin that always succeeds).

2. **Security.** No credential exposure, no shell-injection vectors
   introduced. The lib reads files (`jq`, `python3`, `find`, `cat`),
   writes one file (`.pack-tracker/capabilities.json`), and shells out
   only to `provider_capabilities` which is a static cat for the
   github backend. The `_TRACKER_PROVIDER_CONFIG_PATH` env-var export
   at line 168 is local to the doctor invocation; it persists in the
   parent process after `cmd_doctor` returns, but the value is the
   user's own tracker.toml path — not a privilege concern. (Could be
   a hygiene NIT to `unset` it before return.)

3. **Regressions.** None observed. The function body is byte-identical
   modulo lifting the ten-line `# Validates: ...` comment from above
   the function into the lib's file-level docstring. Diff against
   commit `39d835e` (pre-BD-130 HEAD) confirms no logic changes.
   `tracker-migrate-reverse-test` Groups 6.2/6.3 continue to exercise
   the function via the legacy `tracker-migrate.sh doctor` path and
   pass per the implementation report's tally (93/93). The
   tracker-migrate.sh trim removed only the inline function body —
   `grep` for `tracker_doctor_run` across `scripts/` shows two callers
   (cmd_doctor in each dispatcher) and one definition (the lib),
   confirming no orphaned helpers.

4. **Concurrency.** Not applicable. No shared mutable state, no
   actors, no threads. The capability-cache write at line 188–189 is
   not interlock-protected, but the doctor is interactive and serial
   per-invocation; concurrent doctor runs against the same target are
   not a documented use case.

5. **Architecture compliance.** The relocation matches the existing
   lib/dispatcher separation already used by `tracker-init.sh`,
   `tracker-migrate-forward.sh`, and `tracker-migrate-reverse.sh`.
   Option (a) was the right pick; option (b) (have pack-tracker.sh
   source tracker-migrate.sh) would have leaked tracker-migrate.sh's
   `cmd_*` dispatcher functions and `main` symbol into
   pack-tracker.sh's namespace, plus `set -euo pipefail` would
   short-circuit pack-tracker.sh's own `set` redeclaration. Option (a)
   is the only architecturally clean choice. The implementation
   report's rejected-alternative section captures this correctly.

6. **Idempotency.** The doctor is idempotent in the
   read-and-report sense: each invocation re-evaluates state and
   emits a fresh report. The (g) capability-cache write is idempotent
   for a steady-state cache (re-writing the same JSON content) and
   self-healing for a stale cache (overwriting the differing snapshot
   with the current re-probe). See N-1 for the UX concern about (g)'s
   WARN-level reporting of an auto-healed condition.

---

## Findings

### MUST

None.

### SHOULD

#### M-1 (drift) `pack-tracker.sh` `usage()` text falsely claims `doctor` is not yet implemented

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/pack-tracker.sh:76–78`
- Description: After BD-130, `pack tracker doctor` is fully
  implemented and works. But the dispatcher's `usage()` heredoc still
  reads:

      disable | doctor | update-templates | enable-recommendations
            Pending — surfaces a not-implemented validation error
            pointing at the BD that lands the verb.

  When the user runs `pack-tracker.sh -h` (or `pack-tracker.sh`
  without args), they are told `doctor` is pending, despite the very
  next BD entry showing the verb landed. Misleading user-facing text
  introduced by BD-130's incomplete cleanup.
- Fix: Move `doctor` out of the "Pending" group and add a real verb
  block:

      doctor [--repo-root PATH]
            Validate tracker.toml, mapping integrity, mirror
            freshness, template freshness, and capability cache
            (refreshes the cache as a side effect).

- Severity rationale: User-facing CLI doc lying about a shipped verb.
  Not a runtime defect, so SHOULD rather than MUST.

#### M-2 (drift) `tracker-migrate.sh` `usage()` text claims `doctor` is "not yet implemented in this build"

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tracker-migrate.sh:67–68`
- Description: Identical class to M-1 on the legacy entry path:

      doctor [--repo-root PATH]
            BD-067 — not yet implemented in this build.

  Same misleading-text issue. Both `cmd_doctor` and the verb itself
  work fine; the help text contradicts the dispatch behavior.
- Fix: Replace the "BD-067 — not yet implemented" stub with the same
  real description proposed in M-1. Note: the same dispatcher's
  `reverse` entry also reads "BD-067 — not yet implemented in this
  build." (line 64–65); that's outside BD-130 scope but is the same
  cleanup gap and is worth catching in the same sweep.
- Severity rationale: Same as M-1.

#### M-3 (drift) README "Repository Layout" brace-listing omits `tracker-doctor.sh`

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/README.md:203`
- Description: The Repository Layout section enumerates tracker-lib
  files via brace expansion:

      ├── tracker-{config,init,labels,errors,sidecar,mirror,agent-read,phase-task,cycle-check,links,promote}.sh   Tracker subsystem (v11; ...)

  The new `tracker-doctor.sh` (created by BD-130) is missing from
  this list. Per the pack rule "If files are added, moved, or
  removed, verify the Repository Layout section in README.md is
  updated", BD-130 should have updated this line. README is normally
  PM-only, so the cleanup belongs to Pack Chat — but the gap is
  attributable to BD-130.
- Fix: Add `doctor` to the brace list:

      ├── tracker-{config,doctor,init,labels,errors,sidecar,mirror,agent-read,phase-task,cycle-check,links,promote}.sh   Tracker subsystem (v11; ...)

  Trivial alphabetical insertion; the whole one-line block stays
  intact.
- Severity rationale: Layout-doc drift; not a runtime defect; PM-only
  file so the agent-side cleanup is bounded.

#### M-4 (robustness) `tracker-doctor.sh` has no defensive dependency probe

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-doctor.sh:33` (`tracker_doctor_run`)
- Description: The lib's file-level docstring asserts:

      Both dispatchers already source the dependencies this function
      needs (tracker-config, tracker-provider*, template-version,
      template-translations) so this lib has no `source` lines of its
      own.

  This is a calling-convention contract that future authors can
  unknowingly violate. If a new dispatcher (or a test harness) sources
  `tracker-doctor.sh` directly without first sourcing
  `tracker-config.sh`, the call to `tracker_config_resolve_path`
  (line 40) will produce `command not found` — and we are right back
  in the BD-130 failure mode, in a new caller. The pre-BD-130 inline
  definition didn't have this issue because the function shared the
  dispatcher's source list by definition.
- Fix: Either (a) add a one-time defensive probe at the top of
  `tracker_doctor_run`:

      for _dep in tracker_config_resolve_path tracker_config_auto_surface \
                  tracker_schema_version_check tracker_config_get \
                  provider_capabilities; do
          declare -f "$_dep" >/dev/null 2>&1 || {
              echo "ERROR: tracker-doctor: missing dependency: $_dep" >&2
              echo "MESSAGE: source tracker-config.sh, tracker-provider*.sh, template-version.sh, template-translations.sh before tracker-doctor.sh" >&2
              return 2
          }
      done

  or (b) source the dependencies idempotently at the top of the lib
  itself (mirror the pattern in `tracker-provider.sh:54–59` for
  `tracker-errors.sh`). Approach (b) makes the lib self-contained and
  removes the calling-convention burden entirely.
- Severity rationale: The current code works for both shipped
  callers; the risk is to future callers. SHOULD rather than MUST.

#### M-5 (drift) Docstring promises check `(f)` but the body has no labeled `(f)` section

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-doctor.sh:7–9` (docstring) vs
  lines 113 / 124 / 159 (body labels).
- Description: The lib header docstring lists checks `(a)` through
  `(g)`. The function body has labeled comment headers for `(a)`,
  `(b)`, `(c)`, `(d)`, `(e)`, and `(g)`. There is no `(f)` header;
  the `(f)` check ("issue-template dir presence") is implemented
  inside the `(e)` block, conflated with the template-version
  freshness check. The text:

      # (e) template-version freshness — compare form-level
      #     template_version against the translation manifest's
      #     latest target. ...
      ...
      if [[ -d "$tmpl_dir" ]]; then           ← this is (f)
          local n_yml
          n_yml=$(find "$tmpl_dir" -name '*.yml' | wc -l | tr -d ' ')
          echo "  [OK]   $tmpl_dir present ($n_yml templates)"
          ... (e) template-version freshness inside ...
      else
          echo "  [WARN] $tmpl_dir absent  ..."  ← also (f)

  The drift is inherited from the BD-067 inline definition; BD-130
  was the natural cleanup window because the relocation rewrote the
  surrounding docstring. The drift was preserved instead.
- Fix: Either (i) renumber the docstring to drop `(f)` and call the
  combined check `(e) issue-template dir presence + template-version
  freshness`, or (ii) split the body so `(f)` has its own labeled
  block before the freshness comparison. Option (i) is one-line
  smaller; option (ii) better matches the docstring's enumeration.
- Severity rationale: Docstring/code drift, not a runtime defect.

#### M-6 (consistency) WARN recovery-verb idiom mixes user-facing surface with legacy-script surface

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-doctor.sh:51,55,66,75,102,148,155,182`
- Description: Per V3 §27.1 Layer 2 (in-error verb-naming), every
  WARN line should name a recovery verb. The doctor lib does this,
  but mixes two surfaces:
  - user-facing: `pack tracker init` (lines 51, 55, 155);
    `pack tracker update-templates --dry-run` (line 148);
    `pack tracker doctor` (line 182).
  - legacy-script: `tracker-migrate.sh forward (regenerates ...)`
    (lines 66, 75); `tracker-migrate.sh forward --mirror-only` (line
    102).

  The user installed `pack tracker` as the canonical surface;
  `pack-tracker.sh` exposes `mirror-rebuild` as the LCD wrapper for
  `tracker-migrate.sh forward --mirror-only`. The legacy-script
  references in WARN messages train the user to invoke the lower-
  level script — directly conflicting with V3 §27.1 Layer 2's intent
  of surfacing the user-facing verb at the failure site.
- Fix: Replace legacy-script recovery verbs with their `pack tracker`
  equivalents:
  - line 66 / 75: `→ Run: pack tracker init` (init re-runs forward
    if needed; or add a forward-only verb name if/when it lands)
  - line 102: `→ Run: pack tracker mirror-rebuild`

  If a no-side-effect "forward only" wrapper is missing for the (b)
  / (c) cases, this finding is one input to the BD that adds it; in
  the meantime, `pack tracker init` is the closest user-facing
  recovery and is already what (a) suggests for the schema-mismatch
  case.
- Severity rationale: Inherited from pre-BD-130 (BD-067 + 5874aef
  authored these strings) but BD-130's relocation was the natural
  cleanup window — the docstring on line 13 explicitly cites
  "(V3 §27.1 Layer 2)" as the contract being upheld, so this is a
  visible doc-vs-code mismatch in the new lib.

### NIT

#### N-1 `(g)` capability-cache "schema-reshape" emits WARN despite auto-healing in the same invocation

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-doctor.sh:181–184`
- Description: When the cached capabilities differ from the live
  re-probe, the doctor emits:

      [WARN] capability cache differs from re-probe (schema-reshape)
             → Run: pack tracker doctor

  …and increments `n_warn`, which sets the doctor's overall rc to 1.
  But lines 188–189 unconditionally rewrite `capabilities.json` with
  the freshly-re-probed value, so the cache is *already healed* by
  the time the WARN line is printed. A subsequent doctor run will
  emit `[OK] capability cache current`. The WARN-and-rc=1 reporting
  falsely fails any CI/PM script that gates on `pack tracker doctor`
  exit code, even though there is no remaining user task.
- Fix: Demote to `[INFO]` (the schema-reshape is informational once
  auto-healed) and don't increment `n_warn`. If the
  schema-reshape signal is itself the actionable event (e.g., the
  user should re-run forward to re-derive labels), keep the rc=1 but
  rephrase as `[WARN] schema-reshape detected (cache auto-refreshed);
  re-run forward if labels/types changed → Run: pack tracker init`
  to make the user's next step concrete.
- Inherited from commit `5874aef` (BD-067-class fix), not introduced
  by BD-130. Calling out for the tech-debt log.

#### N-2 Template-version freshness check silently skips when manifest is absent

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-doctor.sh:131–153`
- Description: The conditional
  `if manifest_json=$(template_translations_load "$manifest_path" 2>/dev/null); then ... fi`
  silently elides the entire freshness check when the manifest file
  doesn't exist. The user gets `[OK] $tmpl_dir present (N
  templates)` and no signal that the freshness comparison was
  skipped. From the user's perspective, the check appears to have
  passed — but the freshness sub-check never ran.
- Fix: Add an `else` branch:

      else
          echo "  [INFO] template-version freshness: manifest absent at $manifest_path (skipped)"
      fi

  Distinguishes "passed" from "skipped" in the doctor report.
- Inherited; BD-130 relocation didn't introduce.

#### N-3 Template-version manifest path is hardcoded to a pack-internal location

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-doctor.sh:123`
- Description: `manifest_path="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"`
  hardcodes a path that exists only in the pack repo, not in client
  projects. When `pack tracker doctor` runs from a client repo, this
  manifest will not exist, and the freshness check is silently
  skipped (see N-2 for the silent-skip issue itself). Whether the
  manifest needs to be copied into client projects, or whether the
  doctor should resolve the path differently for the `client`
  surface case, is outside BD-130's scope — but the path resolution
  is wrong-by-design for the client surface.
- Fix: Either copy / generate a per-project manifest at init time,
  or have the case statement at lines 119–122 resolve `manifest_path`
  per-surface (currently both `pack` and `client` resolve to the
  same `$repo_root/.github/ISSUE_TEMPLATE`, but the manifest path
  uses a single pack-only fallback).
- Inherited.

#### N-4 Test does not exercise the no-arg `pwd` fallback path

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/tracker-bd130-doctor-wired-test.sh:82,92`
- Description: All `bash $PACK_TRACKER doctor ...` and
  `bash $TRACKER_MIGRATE doctor ...` invocations pass `--repo-root
  $SCRATCH`. The `cmd_doctor` line `[[ -z "$repo_root" ]] &&
  repo_root="$(pwd)"` is never exercised. A regression that broke
  the no-arg path (e.g., a refactor that lost the `pwd` fallback)
  would slip past this test.
- Fix: Add a Group 5 that `cd`s into `$SCRATCH` and runs `bash
  $PACK_TRACKER doctor` with no args, then asserts the same
  banner-and-no-error properties.
- Severity: NIT because the wiring-fix surface area is what BD-130
  legitimately needed to guard; the no-arg path was already covered
  by pre-existing tests in `tracker-migrate-reverse-test`. Adding it
  here would be defensive completeness.

#### N-5 `cmd_doctor` does not validate `--repo-root` is a directory

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/pack-tracker.sh:159–173` and
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tracker-migrate.sh:142–156`
- Description: `cmd_update_templates` (pack-tracker.sh:175–215)
  validates the directory:

      if [[ ! -d "$repo_root" ]]; then
          tracker_error_emit "validation" "update-templates: --repo-root is not a directory: $repo_root"
          return 1
      fi

  `cmd_doctor` does not. Passing `--repo-root /does/not/exist` falls
  through to `tracker_doctor_run`, which then trips on
  `tracker_config_auto_surface` (rc!=0 → silent fallback to `pack`),
  emits `doctor: /does/not/exist`, and produces nonsensical-looking
  WARNs about absent files. Not a defect, just a UX inconsistency
  with the sibling verb.
- Fix: Mirror the directory-validation block from
  `cmd_update_templates`. Trivial copy.
- Inherited; BD-130 didn't introduce, but it didn't tighten either.

#### N-6 Implementation report's test-line-count and group-checks count are off by ~4 / ~1

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md:117,304`
- Description: Report says
  `### NEW: \`scripts/tests/tracker-bd130-doctor-wired-test.sh\` (110 lines)`
  but `wc -l` on the file reports 114. Report also says
  "Group 4: both dispatchers contain the source ... line" — Group 4
  contains two distinct source-line checks (assertions 4.1 and 4.2),
  so it's two checks not one. Minor accuracy. The 8/8 PASS and the
  group/test-name labeling is otherwise correct.
- Fix: One-line correction in the implementation report (now under
  archive/v11/). PM-archived doc; cleanup is Pack-Chat-owned but no
  user-facing impact. Leave as-is unless a wider report-cleanup
  sweep is run.

#### N-7 `cmd_doctor` is byte-identical between the two dispatchers; could be DRY'd

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/pack-tracker.sh:159–173` and
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tracker-migrate.sh:142–156`
- Description: The arg-parser, validation, and `tracker_doctor_run`
  call are byte-identical between the two `cmd_doctor` definitions.
  BD-130's relocation moved the function body to a lib but left the
  arg-parser duplicated. A future maintenance cycle could move the
  arg-parser into `tracker_doctor_run` itself (or a sibling
  `tracker_doctor_main` wrapper in the lib) so the dispatchers
  collapse to a single call.
- Fix: Optional refactor; not in scope for a wiring fix. Calling
  out as low-priority duplication.

#### N-8 Surface-case statement has identical RHS for `pack` and `client` branches

- File / symbol:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-doctor.sh:119–122`

      case "$surface" in
          pack)   tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE" ;;
          client) tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE" ;;
      esac

- Description: Both branches assign the same value, so the case
  statement is degenerate. If the `client` surface was meant to
  resolve under `docs/pack/.github/ISSUE_TEMPLATE` (matching
  `tracker_config_resolve_path` which routes the client surface to
  `docs/pack/tracker.toml`), the implementation differs. If both
  surfaces really do share `.github/ISSUE_TEMPLATE`, the case can
  collapse to an unconditional assignment.
- Fix: Either correct the client-surface path or remove the case.
- Inherited; not BD-130-introduced.

---

## Positive findings (acknowledgments)

- The blocker is fully resolved at the user-facing layer: `pack
  tracker doctor` produces the expected banner-and-checks output
  from any cwd. Live-verified in this review.
- Relocation choice (option a) is the architecturally correct one —
  matches the surrounding `tracker-init.sh` /
  `tracker-migrate-{forward,reverse}.sh` pattern, avoids leaking
  `cmd_*` functions into pack-tracker.sh's namespace, and avoids the
  `set -euo pipefail` re-declaration risk that option (b) would have
  introduced.
- Function body relocation is byte-identical; verified by direct
  diff of the two ranges (only the floating ten-line `# Validates:`
  comment changed location).
- Source order in both dispatchers is correct — `tracker-config.sh`,
  `tracker-provider*.sh`, `template-version.sh`, and
  `template-translations.sh` are sourced before `tracker-doctor.sh`
  in both `pack-tracker.sh:53` and `tracker-migrate.sh:43`. Symbols
  resolve in order.
- Composition with the co-shipped BD-129 is verifiably clean:
  doctor's path does not call `_gh_run` or `tracker_labels_ensure`,
  and `provider_capabilities` is a static cat for the github backend
  with no remote calls — so BD-129's `GH_REPO` plumbing is not on
  the doctor path. The combined commit's "no shared files; no race
  risk" assertion holds.
- Wiring-regression test (`tracker-bd130-doctor-wired-test.sh`) is
  appropriately scoped: it guards the *defect class* (function
  unreachable from the dispatcher) without overlapping the doctor's
  per-check coverage which other suites already exercise. 8/8 PASS
  re-confirmed in this review.
- Trinity files (CLAUDE.md / AGENTS.md / GEMINI.md, root and
  project-template) are correctly NOT touched — the change is
  implementation-internal and has no project-template surface.
- README's `Repository Layout` is the only PM-only doc with drift
  (M-3); the other PM-only files (BACKLOG.md, CHANGELOG.md,
  PACK-CHAT.md, PACK-AGENTS.md) are appropriately untouched by the
  agent and were updated by Pack Chat at commit time.
- Implicit-flip rule was honored: BD-130 status is `Resolved` in
  BACKLOG.md per the same commit as the fix.
- The pointer comment left in `tracker-migrate.sh:158–161` is
  helpful — a future maintainer searching for the function in the
  legacy file finds the lib reference immediately.

---

## Evidence

### E-1. Function body byte-identical

      $ git show 39d835e:scripts/tracker-migrate.sh | sed -n '156,334p' > /tmp/old.sh
      $ git show 1bdd1f5:scripts/lib/tracker-doctor.sh | sed -n '33,201p' > /tmp/new.sh
      $ diff /tmp/old.sh /tmp/new.sh
      2,11d1
      < # Validates: (a) tracker.toml is readable + schema_version OK,
      < # ... (10 lines of inline comment that moved to file-level docstring)

Only difference is the relocation of the `# Validates:` comment
block from above the function to the file-level docstring. No logic
changes.

### E-2. Live smoke test passes

      $ bash scripts/pack-tracker.sh doctor --repo-root /tmp
      doctor: /tmp
        [WARN] tracker.toml absent at /tmp/tracker.toml  → Run: pack tracker init
        [INFO] no mapping file (expected before first forward run)
        [WARN] /tmp/.github/ISSUE_TEMPLATE absent  → Run: pack tracker init
      doctor: completed with 2 warning(s)

Banner emitted. No `command not found`.

### E-3. Wiring test passes

      $ bash scripts/tests/tracker-bd130-doctor-wired-test.sh
      ... (8 pass blocks)
      === Results: 8 passed, 0 failed ===

### E-4. No orphaned callers after the trim

      $ grep -rn "tracker_doctor_run" scripts/
      scripts/tracker-migrate.sh:155:    tracker_doctor_run "$repo_root"   ← caller
      scripts/tracker-migrate.sh:158:# tracker_doctor_run is defined ...    ← pointer comment
      scripts/pack-tracker.sh:172:    tracker_doctor_run "$repo_root"      ← caller
      scripts/lib/tracker-doctor.sh:34:tracker_doctor_run() {              ← definition
      (test + lib-config comment-only matches omitted)

Two callers, one definition. Clean.

### E-5. No shared files with BD-129

      $ git show 1bdd1f5 --stat | tail -12
       BACKLOG.md                                         |   8 +-
       maintenance-docs/.../IMPLEMENTATION-REPORT-BD-129.md| 375 +++++++++++++++++++++
       maintenance-docs/.../IMPLEMENTATION-REPORT-BD-130.md| 314 +++++++++++++++++
       scripts/lib/tracker-config.sh                      |  43 +++       BD-129
       scripts/lib/tracker-doctor.sh                      | 201 +++++++++++       BD-130
       scripts/lib/tracker-labels.sh                      |  10 +        BD-129
       scripts/lib/tracker-provider-gh.sh                 |  13 +        BD-129
       scripts/pack-tracker.sh                            |   2 +        BD-130
       scripts/tests/tracker-bd129-gh-repo-test.sh        | 246 ++++       BD-129
       scripts/tests/tracker-bd130-doctor-wired-test.sh   | 114 +++++       BD-130
       scripts/tracker-migrate.sh                         | 185 +-----       BD-130

Disjoint sets per the commit message claim.

---

## Recommended dispositions

| Finding | Severity | Recommended action | Owner |
|---|---|---|---|
| M-1 pack-tracker.sh stale `usage()` | SHOULD | One-line edit; replace "Pending — surfaces a not-implemented" stub with the doctor verb description. Land in next agent-eligible touch of the file or in a doc-cleanup sweep BD. | pack-coder follow-up |
| M-2 tracker-migrate.sh stale `usage()` | SHOULD | Same shape as M-1; also update the parallel `reverse` line in the same heredoc since both BD-067 stubs are now misleading. | pack-coder follow-up |
| M-3 README brace-listing missing `tracker-doctor.sh` | SHOULD | One-character insertion in PM-only README; Pack Chat at next docs sweep. | Pack Chat |
| M-4 No defensive dependency probe in lib | SHOULD | Add the 5-line `for _dep in ...; do declare -f ...; done` block at top of `tracker_doctor_run`, OR add idempotent `source` lines in the lib's preamble (mirror `tracker-provider.sh:54–59`). | pack-coder |
| M-5 Docstring promises (f) but body has no (f) label | SHOULD | Re-label the docstring or split the body block. | pack-coder |
| M-6 WARN recovery-verb idiom inconsistent | SHOULD | Replace `tracker-migrate.sh forward` references with `pack tracker init` / `pack tracker mirror-rebuild` per V3 §27.1 Layer 2. | pack-coder |
| N-1 (g) WARN false-fails CI | NIT | Demote to INFO or rephrase to make the user's next step concrete. | tech-debt log |
| N-2 Silent-skip on missing manifest | NIT | Add `else echo "  [INFO] manifest absent (skipped)"`. | tech-debt log |
| N-3 Hardcoded pack-internal manifest path | NIT | Resolve per-surface; copy into client projects at init or skip cleanly. | future BD |
| N-4 No no-arg test path | NIT | Add Group 5 to wiring test. | tech-debt log |
| N-5 No directory validation in cmd_doctor | NIT | Mirror cmd_update_templates pattern. | tech-debt log |
| N-6 Implementation-report numerical inaccuracies | NIT | Optional one-line fix in the now-archived report. | leave |
| N-7 Duplicated cmd_doctor between dispatchers | NIT | Optional refactor. | leave |
| N-8 Degenerate surface case statement | NIT | Either correct or collapse. | tech-debt log |

---

## Closing

BD-130's wiring fix is correct and safely composed with BD-129. The
six SHOULD findings cluster around stale documentation
(`pack-tracker.sh` usage, `tracker-migrate.sh` usage, README layout,
docstring/code-label drift, recovery-verb-idiom inconsistency, and
defensive-dependency hygiene); none affect the runtime behavior of
`pack tracker doctor`, but together they reflect a missed
documentation-cleanup pass that would have been the natural cost of
the relocation. The eight NIT findings are mostly inherited from
pre-BD-130 commits and accumulate as tech-debt sweep candidates. No
finding is severe enough to require a re-cycle of BD-130 itself.

End of review.
