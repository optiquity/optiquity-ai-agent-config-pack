# IMPL-REPORT — BD-204 gh close-reason vocabulary fix (C-8 live-flip defect)

- **Branch:** v11-dev
- **HEAD at implementation:** `84f6a83d02d8467362972b86d1eb642dec9f4177`
- **Date:** 2026-06-11
- **Coder:** fresh fix-coder (pack-coder), foreground verification throughout
- **Proposed commit subject:**
  `fix: v11 — BD-204 gh close-reason vocabulary at the CLI boundary + mock enforcement + Deprecated oracle canary (pack-only)`

## 1. Root-cause confirmation

`tracker_provider_gh_close` (`scripts/lib/tracker-provider-gh.sh`) passed the
provider INTERFACE token `not_planned` straight to `gh issue close --reason`.
The real gh CLI vocabulary takes a SPACE in the not-planned token. Local
re-run evidence (this session, 2026-06-11):

```
$ gh issue close --help | grep -i reason
  -r, --reason string         Reason for closing: {completed|not planned|duplicate}
  $ gh issue close 123 --reason "not planned"
```

(gh's own help example uses the quoted space form.) Consequence in the C-8
live flip (`/tmp/bd204-c8-flip.log` lines 26-33): `ERROR: partial-write` with
all five Deprecated/Cancelled entry closes failing —
`step-8 close: BD-021/022/023/103/123 — failed after 3 attempts` each.
`completed` (167 Resolved closes succeeded live, per the flip-log
`closed:     167` summary line) and `duplicate` are identical
in both vocabularies; only `not_planned` needed translation.

Why no harness caught it: every fake-gh `issue close` stub accepted any
`--reason` string (survey in §3 below), and the live-oracle fixture
(`scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md`) carried no
Deprecated/Cancelled entry (statuses pre-fix: 4×Open, 1×Unblocked, 1×Resolved,
1×Deferred — verified by full fixture read), so four rehearsals never
exercised the not-planned close live.

`--reason` audit across `scripts/lib/` (re-run after the fix): the only gh-CLI
close-reason invocation is `scripts/lib/tracker-provider-gh.sh` (now
translated); all other `--reason` matches are the test fakes' arg parsers.
All production callers (`scripts/lib/tracker-migrate-forward.sh` step-8 +
`_tmf_retry_one_close`; `scripts/lib/tracker-edit.sh` status mapping) speak
the interface vocabulary to `provider_close` and are untouched.

## 2. Fix 1 — provider-boundary translation

**File:** `scripts/lib/tracker-provider-gh.sh` (modified; +13/-1 net in one
function)

- `tracker_provider_gh_close`: interface vocabulary
  (`completed|not_planned|duplicate`) unchanged — validation case-arm,
  callers, and the success JSON (`"state_reason": "not_planned"`) untouched.
  New `cli_reason` local translates `not_planned` → `not planned` ONLY at the
  `gh issue close` invocation:

```bash
    local cli_reason="$reason"
    [[ "$reason" == "not_planned" ]] && cli_reason="not planned"
    _gh_run gh issue close "$id" --reason "$cli_reason" >/dev/null || return 1
```

- Docstring above the function records the defect, the two-vocabulary
  contract, and the C-8 evidence.

## 3. Fix 2 — mock vocabulary enforcement

Survey of every fake-gh that stubs `gh issue close` (grep evidence run this
session):

| Suite | Stub | Pre-fix behavior | Action |
|---|---|---|---|
| `tracker-provider-test.sh` | env-driven generic fake | ignored `--reason` | guard added (parses `--reason`/`-r`, rejects non-CLI vocabulary, exit 1) |
| `tracker-migrate-forward-test.sh` | Group 3 `FAKEGH` | tracked id, accepted any reason | guard added |
| `tracker-migrate-forward-test.sh` | 4.3 `FAKEGH_PF` | always exits 1 on close (its purpose) | unchanged — rejects everything by construction, trivially vocabulary-compliant |
| `tracker-migrate-forward-test.sh` | 4.4 `FAKEGH_REC` | tracked id, accepted any | guard added |
| `tracker-migrate-forward-test.sh` | 4.6 `FAKEGH_CP` | tracked id, accepted any | guard added |
| `tracker-migrate-forward-test.sh` | 5.3 `FAKEGH_C` | no-op success | guard added |
| `tracker-migrate-forward-test.sh` | 5.4 `FAKEGH_R1` | no-op success | guard added |
| `tracker-migrate-forward-test.sh` | 5.4 `FAKEGH_R2` | tracked id, accepted any | guard added |
| `tracker-migrate-forward-test.sh` | Group 6 `FAKEGH_BD108` | close in combined no-op arm | close arm split out + guard added |
| `tracker-migrate-roundtrip-test.sh` | stateful fake | parsed `--reason`, accepted any | guard added after parse |
| `tracker-bd134-close-retry-test.sh` | transient-close stub | wrong vocabulary could "recover" on retry | guard added BEFORE the transient simulation |
| `tracker-bd134-close-retry-test.sh` | persistent-close stub | always exits 1 (its purpose) | unchanged — same rationale as FAKEGH_PF |
| `tracker-migrate-reverse-test.sh` | (all fakes) | NO `issue close` stub exists (grep: zero `issue close` arms; reverse never closes) | N/A |

Guard shape (identical in every stub; escaped per each heredoc's quoting
style — unquoted heredocs use `\$` escapes, quoted heredocs use literals):

```bash
        # BD-204: enforce the REAL gh CLI close-reason vocabulary
        # {completed|not planned|duplicate} — nonzero exit otherwise.
        _cr=""; _cp=""
        for _ca in "$@"; do
            [[ "$_cp" == "--reason" ]] && _cr="$_ca"
            _cp="$_ca"
        done
        if [[ -n "$_cr" ]]; then
            case "$_cr" in
                completed|"not planned"|duplicate) ;;
                *)
                    echo "fake-gh: invalid --reason '$_cr' (real gh vocabulary: {completed|not planned|duplicate})" >&2
                    exit 1
                    ;;
            esac
        fi
```

(The error text is deliberately `fake-gh:`-prefixed — the real gh error
string was not captured live, so the fakes never claim to reproduce it
verbatim; only the accept/reject contract and the nonzero exit are mirrored.)

**New assertions:**

- `tracker-provider-test.sh` **1.9b** (4 legs, unit level): `provider_close 42
  not_planned` against the now-enforcing fake → rc=0; returned `state_reason`
  stays `not_planned`; `FAKE_GH_LOG` carries
  `issue close 42 --reason not planned`; negative grep proves
  `--reason not_planned` never reaches the CLI.
- `tracker-migrate-forward-test.sh` **Group 7** (8 legs, end-to-end forward
  path): self-contained mini-fixture with **BD-601 Status: Deprecated** and
  **BD-602 Status: Cancelled**, vocabulary-enforcing fake gh with
  closed-id tracking for the BD-132 stabilization poll. Asserts: rc=0; no
  partial-write; summary `closed:     2`;
  `issue close 601 --reason not planned` (Deprecated) and
  `issue close 602 --reason not planned` (Cancelled) both in the gh log;
  exactly 2 translated invocations; negative leg pins that the interface
  token never reaches the CLI. Pre-fix, this group reproduces the C-8 shape
  (both closes rejected 3x → partial-write rc=1).

**Existing assertions pinning the old invocation:** none existed at the gh-CLI
layer (that absence IS the gap). `tracker-provider-test.sh` 4.4/4.4b pin
`|close:42:not_planned` against a stubbed `provider_close` — that is the
INTERFACE vocabulary, which is intentionally unchanged; those assertions
remain correct and untouched.

**Mock-enforcement proof** (wrong-vocabulary close fails the fake — run this
session against the byte-extracted provider-test fake):

```
--- (a) PRE-FIX invocation shape against the hardened fake (expect rc=1):
fake-gh: invalid --reason 'not_planned' (real gh vocabulary: {completed|not planned|duplicate})
rc=1
--- (b) translated CLI form (expect rc=0):
rc=0
--- (c) fixed provider_close end-to-end against the hardened fake:
{"id": "42", "state": "closed", "state_reason": "not_planned"}
provider rc=0
log: issue close 42 --reason not planned
```

**Adjacent stale-comment fix** (per self-review mandate):
`tracker-migrate-forward-test.sh` header comment claimed the retry sweep is
exercised in "(4.3 + Group 7)" — no Group 7 existed pre-fix. Reworded to
"(4.3)" with a parenthetical noting the NEW Group 7 is the close-reason
group, preventing the stale pointer from colliding with the added group.

## 4. Fix 3 — live-oracle fixture coverage

**File:** `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md`
(modified; +15 lines): appended **BD-909 — Deprecated close-path canary**
(`Status: Deprecated`, Description, `Resolved: n/a`), matching the fixture's
entry grammar. Offline smoke (run this session): decompose yields 8 entry
files incl. `BD-909.md`; `_tmf_parse_backlog_file` parses
`pack_id=BD-909 status=Deprecated`; `_tmf_labels_for_entry` emits
`status:deprecated`; `tmf_compose_issue_body` rc=0 with gz64 blob present.

**File:** `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (modified;
3 hunks). The oracle's counts are dynamic (measured, never hard-coded — its
own EE-1 discipline), so most legs auto-adapt; the load-bearing additions:

1. **Seed leg:** `N_CLOSED_BASELINE` measured from the baseline tree
   (`grep -hcE '^Status: (Resolved|Cancelled|Deprecated)$'`, summed with the
   existing Deferred-canary awk idiom); `die` if < 2 so a future fixture edit
   cannot silently retire the canary. Computed value at this fixture: 2
   (BD-902 Resolved + BD-909 Deprecated); N_BASELINE 7 → 8.
2. **Post-forward close canary:** asserts the forward summary line
   `closed:     $N_CLOSED_BASELINE` (the exact summary format pinned by
   `tracker-bd134-close-retry-test.sh` 1.6 and `tracker-migrate-forward.sh`'s
   `  closed:     $closed`); reads BD-909's live state via
   `gh issue view --json state,stateReason` and asserts `state == CLOSED`;
   ECHOES (does not pin) the `stateReason` read-back — that casing/shape is
   exactly the live evidence the reverse decoder depends on (see POQ-2).
3. **Status oracle:** Deprecated canary count round-trips
   (`_dep_before == _dep_after`), mirroring the Deferred canary. This leg
   fails loudly on the next rehearsal if the live `stateReason` read-back
   does not decode through `_tmr_decode_status`'s `not_planned|duplicate` arm
   (+ `status:deprecated` label) back to Deprecated.

The oracle stays MANUAL-ONLY + DEFAULT-SKIP; it was NOT run live. SKIP-guard
verified: unattended invocation prints
`SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0.
Per-entry legs enumerating fixture ids (BD-903 DS-2, BD-904 KU-OPS-6/CRUD,
BD-905 corrupt-blob, BD-908 mid-cycle create, BD-998/999 probes) do not
collide with BD-909; the DS-1 loop and identity/count oracles include BD-909
automatically.

## 5. Files changed

| Path | Type | Scope |
|---|---|---|
| `scripts/lib/tracker-provider-gh.sh` | modified | Fix 1 (translation + docstring) |
| `scripts/tests/tracker-provider-test.sh` | modified | Fix 2 (fake guard + 1.9b) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | Fix 2 (7 stub guards, stale-comment fix, Group 7) |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified | Fix 2 (stateful fake guard) |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | modified | Fix 2 (transient stub guard) |
| `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md` | modified | Fix 3 (BD-909 canary) |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | modified | Fix 3 (oracle legs) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md` | new | this report |

`git diff --stat`: 7 files, +450/-8. No new source files besides this report,
so full-content reproduction is not required; every hunk is shown or quoted
above and re-readable via `git diff`. Untouched: `tracker.toml`,
`.pack-tracker/`, `backlog/` (C-8 runtime state, owned by Pack Chat).

## 6. Verification evidence

Modified suites (foreground, after all edits):

| Suite | Result |
|---|---|
| `tracker-provider-test.sh` | 160 passed, 0 failed (incl. 4 new 1.9b legs) |
| `tracker-migrate-forward-test.sh` | 190 passed, 0 failed (incl. 8 new Group 7 legs) |
| `tracker-migrate-roundtrip-test.sh` | 70 passed, 0 failed |
| `tracker-bd134-close-retry-test.sh` | 24 passed, 0 failed |
| `tracker-bd204-lossless-roundtrip-test.sh` | default-SKIP verified (rc=0, pinned SKIP line); `bash -n` clean |

`bash -n` clean on all six edited shell files.

Full CI battery (every step of `.github/workflows/validate-pack.yml`, run
foreground in CI order; "ENV" = fails ONLY on legs attributable to the
untracked C-8 runtime artifacts in the working tree — root `tracker.toml` +
gitignored `.pack-tracker/` — which are absent from the committed tree CI
checks out):

- `python3 scripts/validate-pack.py` — **rc=1, ENV**: exactly 3 issues, all
  `tracker.toml — mirror file 'BACKLOG.md'/'STATUS.md'/'CHANGELOG.md' ...
  does not exist on disk`. Zero issues from this change's files.
- `PACK_VALIDATE_DEEP=1 validate-pack.py` — Check 49
  `OK: 213 entries byte-faithful` + Check 50 OK; same 3 ENV issues only.
- PASS rc=0: test-detect (100), tracker-provider, tracker-config,
  tracker-agent-read, tracker-migrate-forward, tracker-migrate-reverse,
  tracker-migrate-roundtrip, test-tracker-phase-task, test-tracker-links,
  test-tracker-cycle-check, tracker-errors, tracker-config-schema,
  recommendation-state-schema, test-per-entry, checks-32-33-34, check-18,
  check-43, tracker-bd129, tracker-bd130, tracker-bd132, tracker-bd133,
  tracker-bd134, recommendation, pack-help, test-customization-preserve,
  test-init-project, test-migrator-core, test-migrator-manifest,
  test-migrator-capability-translation, test-migrator-skills,
  template-translations, template-version, test-issue-forms.
- **ENV-only failures** (each verified to fail ONLY on a leg that runs
  `validate-pack.py` against the pack root, or that trips on the live
  tracker state):
  - `tracker-init-test.sh` (92 pass / 3 fail): init's prior-state guard
    fires on the live `.pack-tracker/id-map.json` before flag validation
    (failure text names the path).
  - checks-36-37-38, check-39, check-41, check-16, check-19, check-42,
    check-44, check-45, check-46, check-removed-doc-advisory: each fails
    ONLY its "validate-pack.py exits 0 on HEAD" end-to-end leg (the 3 ENV
    issues); all synthetic/unit groups pass.
  - check-40: same e2e leg + its T3 basename-index leg, whose failure text
    names `PosixPath('tracker.toml')` (the untracked root artifact).
  - check-49 suite: Group 1 gates on the deep run's overall rc
    (`[[ "$deep_rc" -eq 0 ]]`); Check 49 itself printed OK with 213 entries.
  - migrate-v10-to-v11 {base, dry-run, gates, decompose}: `--apply` legs
    rc=31 because Gate 2's checklist includes "validate-pack.py passes
    against the pack source" (`scripts/lib/migrate-v10-to-v11/
    gate-2-phase-a-verify.sh` header); the gate output prints
    `[FAIL] validate-pack: validator exited 1`.
  - test-v11-realistic-ot: 32/33 pass; only C.1 ("validate-pack.py exits 0"
    against the pack root) fails.
  - persona-contracts: greenfield 191/0 and mid-dev 25/0 PASS; migrated-OT
    persona fails at the same Gate-2 validate-pack leg.
- `test-fixtures/build.sh --all --clean` — rc=0, manifest written;
  `--verify` — all six fixture rows OK.

**Tracker-mode behavior record (per prompt instruction; NOT fixed):** the
working tree carries the C-8 runtime `tracker.toml` (mode=tracker) and
`.pack-tracker/` state. Every battery deviation above traces to those two
artifacts; `tracker.toml` is untracked and `.pack-tracker/` is gitignored
(`.gitignore:12`), so CI on the pushed tree is unaffected. Pack Chat should
expect local validate-pack to stay red until the C-8 mirror-location
follow-up lands (POQ-1).

## 7. Manifest state (regenerate-manifest-v11-surface)

`scripts/` was touched → `bash test-fixtures/build.sh --all --clean` run
from pack root (rc=0). `git diff test-fixtures/manifest.txt` → **empty**.
Per the rule's canonical-authority clause, empty diff = no manifest staging
needed. Why empty is correct: the v11 fixtures are built by
`_run_v11_init` → `scripts/init-project.sh` from the working tree, and the
client-installed set includes only `scripts/lib/detect.sh` from
`scripts/lib/` (verified: `test-fixtures/v11-flat-file/scripts/lib/` contains
only `detect.sh`); neither `tracker-provider-gh.sh` nor anything under
`scripts/tests/` ships to fixtures. `build.sh --verify` confirms all six
rows match.

## 8. Plan deviations

Zero deviations from the three prescribed fixes. Two in-scope judgment calls,
both documented above: (a) the two always-fail close stubs (`FAKEGH_PF`,
bd134 persistent) were left unchanged — they exit nonzero on every close by
design, so they cannot mock-pass a wrong vocabulary; (b) the stale
"(4.3 + Group 7)" comment in the forward-test header was corrected because
the new Group 7 would otherwise collide with the dangling pointer.

## 9. Boundary discipline check

All eight touched paths are pack-side (`scripts/lib/`, `scripts/tests/`,
`maintenance-docs/`). No `project-template/`, `supporting-docs/`, or other
client-shipped surface was edited, and no edit adds a reference to a
pack-only mechanism from a project-side file. No project-side SSOT
investigation required; no boundary stop triggered.

## 10. New POQs

- **POQ-1 (Pack Chat / C-8 aftermath; pre-existing, surfaced here):** the
  C-8-written root `tracker.toml` declares `mirror.location_backlog/status/
  changelog` files that do not exist under the no-monolith model, making
  local `validate-pack.py` exit 1 (3 issues) and cascading into every local
  e2e leg listed in §6. Untracked → CI green, but any local full-battery run
  stays red until the tracker.toml mirror keys get the no-monolith
  treatment. Out of this task's scope (file owned by Pack Chat).
  Disposition: surface to Pack Chat for the C-8 resume/cleanup batch.
- **POQ-2 (live verification on C-8 resume):** the reverse decoder
  (`_tmr_decode_status`, `scripts/lib/tracker-migrate-reverse.sh`) matches
  `state_reason` against lowercase `not_planned|duplicate`. The
  representation gh returns for `--json stateReason` after a not-planned
  close is NOT verifiable offline (GraphQL enum is upper-case
  `NOT_PLANNED`; REST is `not_planned`; the supplied live evidence only
  shows `""` for an open issue). If gh returns a non-matching shape, a
  closed-Deprecated/Cancelled issue would decode through the `*` fallback
  to Resolved. The new oracle canary records the read-back verbatim and the
  Deprecated status-oracle leg fails loudly on mismatch, so the next
  rehearsal answers this empirically. Recommended immediate check after the
  C-8 close re-run:
  `gh issue view 21 -R DShaneNYC/optiquity-ai-agent-config-pack --json state,stateReason`
  — if the value is not exactly `not_planned`, open a BD to harden
  `_tmr_decode_status` (case/shape-insensitive match). Disposition: needs a
  tracked anchor (BD or typed deferral comment) per Pack memory if not
  resolved by the rehearsal — surfaced to Pack Chat with this report.
- **POQ-3 (informational):** the roundtrip stateful fake stores
  `stateReason` exactly as received (now necessarily CLI-vocabulary
  `"not planned"` for any future Cancelled/Deprecated mock entry), while
  `_tmr_decode_status` expects the interface token. No current mock fixture
  closes with not_planned through that fake, so nothing is red today; the
  correct store-side representation depends on POQ-2's live answer.
  Disposition: fold into the POQ-2 follow-up.

## 11. Definition of Done

| Item | Status |
|---|---|
| Fix 1: `not_planned` → `not planned` at the gh CLI boundary only; interface vocabulary + callers untouched | PASS (§2; proof §3c) |
| Fix 1: audit for other gh-CLI close-reason sites | PASS (§1 — single site) |
| Fix 2: every applicable fake-gh close stub rejects non-CLI vocabulary nonzero | PASS (§3 table + proof) |
| Fix 2: forward path asserted to close Deprecated AND Cancelled with translated reason | PASS (Group 7; 190/0) |
| Fix 2: stale/old-invocation assertions updated | PASS (none existed at CLI layer; interface pins kept — §3) |
| Fix 3: Deprecated entry in lossless fixture | PASS (BD-909; smoke §4) |
| Fix 3: oracle count/status assertions updated; default-SKIP preserved; not run live | PASS (§4, §6) |
| `bash -n` on all edited files | PASS |
| Modified suites green | PASS (160/190/70/24, 0 failed) |
| Full CI battery foreground; deviations recorded | PASS with ENV-only failures attributed (§6) |
| Manifest regen + diff check | PASS — rebuilt, diff empty (§7) |
| No git state changes; runtime C-8 files untouched | PASS (§12 R1/R9) |
| Self-review (line-number refs / absolute claims / stale comments / symbol names) | PASS (§12 R10 evidence; stale comment fixed §3) |

## 12. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Only read-only git verbs run this session: `rev-parse`, `status`, `diff`, `check-ignore` (read-only query). CI's `git checkout HEAD -- manifest.txt` step was deliberately NOT replicated (forbidden verb); substituted `build.sh --verify` + `git diff` (§7). End-state output = working-tree edits + this report. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive ops: no `rm -rf` outside self-created mktemp dirs, no `git rm`, no overwrite of trusted files. The three pre-existing C-8 artifacts untouched (R9 evidence). | COMPLIANT |
| 3. preflight-stop-means-stop | PREFLIGHT line emitted immediately before this Write: `PREFLIGHT: 7/7 in-scope file edits complete; verification PASS; HEAD 84f6a83...; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md`. No parent stop message was received at any point. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table; every row carries quoted evidence; format per `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (read this session, lines 206-236). | COMPLIANT |
| 5. agents-read-rule-docs-in-full | Read in full with line counts: `CLAUDE.md` ## Pack memory (within the 579-line file, supplied complete in session context); `/tmp/bd204-c8-flip.log` (34 lines); `feedback_verify_full_ci_suite.md` (42); `feedback_edit_in_place_not_full_rewrite.md` (14); `feedback_manifest_regen_on_v11_surface.md` (15); `feedback_agent_output_rules_applied_block.md` (14). Conditional MUST-READs honored: PACK-MEMORY-RATIONALE § rules-applied-verification-block + § regenerate-manifest-v11-surface read this session. | COMPLIANT |
| 6. verify-full-ci-suite | `validate-pack.py` (rc=1, 3 ENV issues) + DEEP (Check 49 OK 213 entries) + all 45 workflow test steps run FOREGROUND to completion in CI order (§6 per-suite table). Tracker-mode behavior recorded, not "fixed" (§6 note + POQ-1); `tracker.toml` untouched. | COMPLIANT |
| 7. regenerate-manifest-v11-surface | `bash test-fixtures/build.sh --all --clean` rc=0 → `git diff test-fixtures/manifest.txt` EMPTY → per the rule's canonical-authority clause no staging needed; cause verified (only `detect.sh` ships from `scripts/lib/`; `scripts/tests/` not in copy set) — §7. | COMPLIANT |
| 8. edit-in-place-not-full-rewrite | All 7 files changed via targeted Edit calls (no full-file Write of any existing file); edited regions re-read via `git diff` after editing (§ self-review run; provider/fixture/oracle hunks reproduced verbatim in session); untouched text byte-stable by Edit-tool construction + diff stat +450/-8. | COMPLIANT |
| 9. pack-only | End-state `git status --porcelain`: 7 ` M` lines (exactly the in-scope `scripts/` files) + pre-existing `?? tracker.toml` (untouched) + this report (new). No `project-template/`/`supporting-docs/` paths in the diff. | COMPLIANT |
| 10. scope-deliverables-to-the-ask | Exactly the three fixes implemented; two documented judgment calls within them (§8); out-of-scope discoveries routed to POQ-1/2/3 (§10) instead of being fixed. | COMPLIANT |

— end of report —
