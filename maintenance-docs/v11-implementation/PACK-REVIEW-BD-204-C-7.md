# PACK-REVIEW — BD-204 C-7 REBUILD (live lossless oracle) — Review pass 1

- **Reviewer:** pack-reviewer (fresh instance), 2026-06-10
- **HEAD:** `c30c8d56082a9466a1164c94925667592a5a31bf` (branch `v11-dev`); change-set UNCOMMITTED
- **Change under review:** 3 NEW untracked files — `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (782 lines), `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md`, `scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml`; coder report `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-7.md` (untracked, intentional)
- **References applied:** PLAN-BD-204.md § "Commit C-7" (432–502) + §3.LF.7 (688–708) + §3.LF.9 + §3.LF.10; ARCHITECTURE-BD-204-LOSSLESS-FIX.md §5.c / §5.f / §11.2
- **My runs:** unattended SKIP/unit path ONLY. `PACK_TRACKER_LIVE_GH` never set; zero `gh` mutations; zero repo-file edits (this report is the sole write).

## VERDICT

**CLEAN at BLOCKER/MUST/SHOULD. 1 NIT.** All safety invariants hold and were reproduced; all PLAN legs are implemented and genuinely assert; all three coder resolutions are independently confirmed sound; scope is exactly the three new files.

Finding count: **BLOCKER 0 / MUST 0 / SHOULD 0 / NIT 1** (+1 out-of-scope item surfaced, §OOS).

---

## 1. Safety invariants (criterion 1) — ALL PASS, each reproduced

### 1a. Default-SKIP guard is the FIRST executed action — PASS
- Source order: `set -u` at test.sh:54; the guard at test.sh:60–65 is the first executable statement. NOTHING precedes it on any path — sourcing, self-guard, preflight, and every `gh` call sit below (first mutation is `gh repo create` at test.sh:221).
- The `[[ -z "${PACK_TRACKER_LIVE_GH:-}" ]] || ...` short-circuit means an unset env var skips WITHOUT invoking `gh` at all.
- Reproduced (env var confirmed `UNSET` first):
  ```
  SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)
  real 0.00  /  rc=0
  ```
  The printed line is byte-identical to the PLAN § C-7 step 5 pinned wording.

### 1b. NO `gh repo delete` anywhere — PASS
- `grep -n "delete\|DELETE"` over the source: every hit is a comment or message string (test.sh:41–47, 98–105, 138, 167–175, 199–214, 761–764). No `gh repo de`+`lete` invocation, no `gh api -X DELETE` anywhere.
- The split-pattern runtime self-guard (`_FORBIDDEN="gh repo de""lete"`, test.sh:101–104) greps its own source on every run and dies if the literal ever appears — the §5.f grep-guard requirement, implemented so it cannot match itself.

### 1c. Archive-not-delete disposal — PASS
- Success path: `gh repo archive "$SCRATCH_REPO" --yes` at test.sh:766; `isArchived == true` asserted at test.sh:771–772; archive failure on the success path dies with a loud "WRITABLE ORPHAN — archive it manually NOW" message (test.sh:769).
- Failure path: the EXIT trap `_cleanup` (test.sh:202–218) archives whenever `REPO_CREATED=1 && ARCHIVED=0`, and prints `TRAP: ARCHIVE FAILED — manually archive ... NOW` if even that fails — no writable orphan on any exit path.
- `RECOMMEND: manually delete the scratch repo <slug> ...` prints on EVERY exit path after creation (trap, test.sh:214) — prefix exactly per §3.LF.7 leg 8; the parenthetical is paraphrased to avoid self-tripping the grep-guard (coder resolution, assessed sound — the architecture's example parenthetical contains the forbidden literal).

### 1d. Credential-capability preflight is the FIRST live action — PASS
- Preflight block test.sh:147–178 precedes the first mutation (test.sh:221): gh ≥ 2.0 floor (151–156), token-scopes read requiring `repo` (160–166), explicit `delete_repo`-NOT-required recording (167–175), user-read check (177–178).
- Capability probes at first-use sites, each with the pinned `credential-preflight: token missing <permission> required for <step>; aborting before any live write` shape: CREATE = the repo create itself (test.sh:222), issue-WRITE = `tracker_labels_ensure` (test.sh:299), ARCHIVE = the disposal (test.sh:769). This probe-at-use-site model is EXPLICITLY the §5.f design ("the create itself proves create; ... `gh repo archive` at teardown proves archive") — conformant, not a shortcut.

### 1e. The real pack repo can never be a target — PASS
- Unique per-run naming: `SCRATCH_NAME="pack-bd204-oracle-$$-$(date +%s)"` (test.sh:185) — the §5.c-required pattern.
- Defense-in-depth refusals: (i) the `case` guard on `SCRATCH_NAME` (test.sh:190–193); (ii) the operative one — `tracker_repo_slug "$WORK_ROOT/tracker.toml"` must match `*/pack-bd204-oracle-*` (test.sh:258–261), which gates everything the migrator addresses, plus the substitution assert at 255–256. The fixture `tracker.toml` ships only the placeholder `scratch-owner/__BD204_SCRATCH_SLUG__`.
- Refusal logic exercised directly: `dshanenyc/pack-bd204-oracle-123-456` → ALLOW; `dshanenyc/optiquity-ai-agent-config-pack` → REFUSE; near-miss `dshanenyc/pack-bd204-oraclex` → REFUSE.
- `GH_REPO="$SCRATCH_REPO"` exported (test.sh:296) so even un-flagged `gh` calls target the scratch.

### 1f. Not wired into CI / run-all — PASS
- `grep -rn "tracker-bd204-lossless" .github/workflows/` → no match (rc=1). The workflow enumerates explicit `run:` lines (no `scripts/tests/*.sh` glob in any `run:` step). Repo-wide, the only `scripts/` references are the test itself and its own fixture comment; all other refs are `maintenance-docs/` design/plan docs (expected).

## 2. Leg completeness (criterion 2) — ALL legs present and asserting

Base § "Commit C-7" oracle legs:

| Leg | Implementation (test.sh) | Asserts? |
|---|---|---|
| Count oracle (dynamic, never hard-coded) | 271–279 (tree, `^BD-[0-9]+\.md$`), 283–286 (`--label bd-entry` lane), 336–337, 622–623, 664–665, 748–749 | yes — `assert_eq` before/after/issues |
| Identity oracle (pack-id sets) | 287–291, 340–341, 624–625 | yes — set equality via sorted lists |
| Content-faithfulness oracle (back-pointer stripped) | `verify_tree_faithful` 597–618; cycle 1 at 619, cycle 2 convergence at 671; per-file `cmp` via `pe_strip_backpointer_stdin` | yes — per-entry `t_fail` + diff head |
| Status oracle + Deferred canary | 629–634 (full distribution + explicit Deferred count; BD-906 is the Deferred fixture) | yes |
| No-monolith / no-sidecar | 637–646 (`! -f pack-ops/BACKLOG.md`; no `reverse.sidecar.*`), `_toc.md` regen 647–649 | yes |
| Repeated-cycle + interleaved CRUD | 656–671 (forward 2 `created: 0`/`skipped: N` + reverse 2 converges); 679–757 (`provider_create` BD-908 + blob-consistent `provider_update` status flip on BD-904 + reverse 3 byte-verbatim appearance + status round-trip + count N+1 + re-forward skip-all `entries: N+1`) | yes |

All pinned output tokens match the lib's actual summary format (`forward: complete.` / `entries:` / `created:` / `skipped:` at tracker-migrate-forward.sh:1843–1846; `reverse: complete.` at tracker-migrate-reverse.sh:1606).

§3.LF.7 rebuilt legs 1–10:

| # | Leg | Where | Verdict |
|---|---|---|---|
| 1 | Drop-set + no-Description fixtures | BACKLOG.md BD-901 (6 drop-set fields interleaved), BD-902 (no Description), BD-903 kept; exercised by DS-1 (354–383) + content oracle | implemented |
| 2 | Size leg | DS-3a composer fail-loud 417–429; DS-3b live near-budget 434–458; DS-3c live 422 460–474; probes unlabeled → excluded from count lane | implemented; reproduced offline (§4) |
| 3 | Pacing leg | live wall-clock ≥ N−1 s + no `rate-limit`/`abuse` token (320–327); fake-clock + retry-after unit variants are the unattended home (forward-test §2.8.7/2.8.8 — verified real, see §3) | implemented per leg-10 split |
| 4 | Autolink neutralization | BD-904 carries all 4 forms (`#123`, `@…`, 40-hex SHA, bare URL); live `body_html` asserted free of `user-mention`/`issue-link`/`commit-link`/live-href + `<code>` present (390–398); blob verbatim via DS-1 | implemented |
| 5 | Corrupt-blob | live PATCH of valid-base64-invalid-gzip payload; reconstruct rc=1 + `corrupt-blob` + never-empty text; FULL reverse run aborts; body restored (553–580) | implemented |
| 6 | Normalization comparator | DS-2: CRLF+trailing-ws → rc=0; one-word visible-H2 edit → rc=1 `divergence:`; `--force` → rc=0; body restored (492–545) | implemented |
| 7 | Credential preflight | §1d above | implemented |
| 8 | Archive-not-delete + grep-guard | §1b/§1c above | implemented |
| 9 | Repeatable multi-rehearsal | §1e above; no single-shot assumption | implemented |
| 10 | CI model: manual-only + default-SKIP; unit legs run unattended | §1a/§1f; unit homes are the EXISTING wired tests (header 20–39 enumerates them) — verified real and passing (§3) | implemented |

§11.2 map: DS-1 (354–383), DS-2 (492–545), DS-3 (409–474), KU-OPS-2/3 (320–327), KU-OPS-6 (390–398), KU-CRED (147–178 + 764–772). DS-4/DS-5 MOOT per architecture. No unmapped known-unknown.

No hollow legs: every leg routes through `assert_eq`/`assert_contains`/`t_fail` on a measured value; live-infrastructure failures `die` (rc 1) rather than soft-pass; DS-1 failure additionally hard-aborts with a "do NOT proceed to C-8" message (test.sh:383).

## 3. Unit-level legs run unattended (criterion 3) — PASS

Leg 10's unattended homes are pre-existing wired tests, each verified to exist, genuinely assert, and pass:

- `bash scripts/tests/tracker-migrate-forward-test.sh` → **"All tests passed."** (61.0 s). §2.8.5 (lines 271–286): over-budget compose rc=1 + `size-budget: entry BD-902` + `NEVER truncates`, within-budget rc=0 + blob present. §2.8.7 (429–448): pacing via sleep-log seam (first create un-paced; second sleeps ≥ interval). §2.8.8 (452–477): simulated `rate-limit-secondary` honors `Retry-After: 7` (asserted from the backoff log), aborts on non-pacing errors. §2.9.2 (366–384): 4-trigger-form neutralizer batch == single-record.
- `bash scripts/tests/tracker-migrate-reverse-test.sh` → **"All tests passed."** (27.9 s). §2.1b (270–282): feeds a PRESENT-but-corrupt `pack-entry-body-gz64` marker (jq-built issue), asserts rc=1 + `corrupt-blob: issue #77` + `NEVER emits an empty/partial entry body` — a mutation that made the decoder silently emit an empty body would flip rc to 0 and fail the `assert_eq`. §2.1d-i/ii/iii (299–347): CRLF+trailing-ws no-false-positive, one-word-edit caught (`divergence: issue #79` + section name), `--force` blob-wins WARN.
- `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` exists and is wired in the workflow (grep count 1) — the whole-tree decode∘encode identity home.

These ran in CI's battery before C-7 and are unchanged by C-7 (zero assertion drift introduced — the new test only cross-references them in its header).

## 4. Fixture canonicality (criterion 4) — PASS, reproduced

- All 7 entries BD-901..907 are suffix-free; the only parenthetical is POST-em-dash (BD-905 `**BD-905 — Parenthetical title stress (Qualifier Three)**`) — BD-211-canonical.
- Required shapes all present: drop-set interleave (BD-901: `Target:` after `Type:`, `Position:` after `Status:`, `Scope:` between `Blockers:`/`Unblocks:`, plus `Problem:`/`References:`/`Out of scope:`); no-`Description:` (BD-902); 4-form autolink (BD-904 — `#123`, bare `@pack-bd204-nobody`, 40-hex bare SHA, bare URL); sub-blocks-inside-Description (BD-903); parenthetical title (BD-905); Deferred (BD-906); large multi-block with all five `Goal:/Segments:/Steps:/State:/Scope:` blocks + an interior blank line + inline code span (BD-907).
- Reproduced offline (my own harness, lib functions, no gh): `per_entry_decompose` → exactly 7 canonical `^BD-[0-9]+\.md$` files; per-entry `decode(encode(raw))` `cmp` byte-identical **7/7** (including BD-907's interior blank line).
- `python3 scripts/validate-pack.py` with the fixtures present → **PASSED — all checks clean, real 1.33 s** (~baseline). `scripts/tests/fixtures` is already on validate-pack.py's synthetic-fixture exemption list (validate-pack.py:5226, OQ-S1), so the new dir is covered by existing policy, not a new carve-out.
- Statuses used (`Open`/`Resolved`/`Unblocked`/`Deferred`) are all in the lib vocabulary (tracker-migrate-forward.sh:2014–2021; tracker-labels.sh:84/92).

## 5. Scope (criterion 5) — PASS, reproduced

- `git diff --name-only HEAD` → EMPTY (no tracked file modified). `git status --short` → exactly `?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-7.md`, `?? scripts/tests/fixtures/tracker-bd204-lossless/`, `?? scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`.
- No `scripts/lib/` edit; no `project-template/` or `supporting-docs/` touch → `pack-only` keyword (PLAN §3.LF.7) is Check-36-safe.
- Manifest: I re-ran `bash test-fixtures/build.sh --all --clean` (rc=0) → `git diff -- test-fixtures/manifest.txt` EMPTY — the coder's empty-regen claim reproduced; per RC9 nothing owed to the commit.

## 6. Verification reproduction (criterion 6) — PASS

| Run | Result |
|---|---|
| `env -u PACK_TRACKER_LIVE_GH /usr/bin/time -p bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | pinned SKIP line; rc=0; **real 0.00 s** |
| `/usr/bin/time -p python3 scripts/validate-pack.py` | PASSED; **real 1.33 s** (~baseline) |
| `bash scripts/tests/test-v11-realistic-ot.sh` | **33/33 PASSED**, real 1.83 s (the only test that globs a fixtures root — it uses `test-fixtures/`, untouched) |
| `tracker-migrate-forward-test.sh` / `tracker-migrate-reverse-test.sh` | both "All tests passed." (61.0 s / 27.9 s) |
| Offline fixture + size-gate harness (§4, §7b) | 7/7 roundtrip OK; gate behavior confirmed |

Runtime-compounding: the test's unattended cost is the 0.00 s SKIP path and it is invoked by zero battery files — battery contribution is exactly zero. I did not re-run the full ~8-min battery (coder ran it: 56 PASS / 0 FAIL / 3 documented non-test skips, 478.61 s); the spot-runs above cover the integration test plus every test the change could interact with.

## 7. Coder's three surfaced resolutions (criterion 7) — all three SOUND

**(a) BACKLOG.md fixture + runtime decompose — CONFIRMED.** The precedent is real: `scripts/tests/tracker-migrate-roundtrip-test.sh:351–371` (`_setup_test_repo`) keeps its fixture as a `BACKLOG.md` monolith and builds the per-entry tree at runtime via `per_entry_decompose "pack-backlog" …`. The new oracle applies the same idiom (test.sh:251–252), keeps the PLAN-literal fixture filename, and — correctly — snapshots the DECOMPOSED tree as the byte-faithfulness baseline (test.sh:266–267), removing monolith-vs-tree formatting from the comparison. The as-built consumers (`tmf_parse_backlog_tree` on `$repo_root/backlog`; `_tmr_emit_pack_tree`) read trees, so this is the right seam.

**(b) DS-3a incompressible random payload — CONFIRMED; outcome-deterministic.** Reproduced in-process: a repeated-char 66,000-byte body composes rc=0 (gzips tiny — the gate does NOT fire, confirming the coder's premise that the naive payload is useless); 50,000 `os.urandom` bytes (base64-wrapped) → rc=1 with `size-budget: entry BD-999 projected body 67554 bytes exceeds provider body limit 65536 (margin 2048)`; the 45,000-byte near-budget probe composed 60,830 B < the 63,488 budget. Determinism: `os.urandom` is not seed-reproducible, but the ASSERTION OUTCOME is information-theoretically deterministic — gzip cannot compress 50,000 bytes of entropy below ~50,000, so the blob is always ≳66.7 k chars > 63,488 (and the near-budget probe always lands ~60.8 k with ~2.6 KB headroom). No repo rule forbids the randomness source. See NIT-1 for the one residual nit (bit-reproducibility for diagnosis).

**(c) Forward re-close observation — CONFIRMED real, correctly out of scope, correctly un-fixed.** `tracker-migrate-forward.sh:1674–1726` (steps 8+9) loops over every MAPPED entry — including skip-path entries — and for `Resolved|Cancelled|Deprecated` re-attempts `provider_close` and re-posts the Resolution comment when `resolution` is non-empty. This is lib behavior; PLAN § C-7 forbids lib edits in this commit ("C-7 is **test + fixture only**; no `scripts/lib/tracker-*.sh` edit"), so fixing it here would be a scope violation, and its live impact (gh's close-on-closed semantics) is BLOCKED on the user-gated rehearsal — surfacing for Pack Chat triage is the right disposition. See §OOS.

## 8. Plan conformance overall (criterion 8) — PASS

- The §3.LF.7 rebuild SUPERSEDES the base recipe's step-4 `gh repo delete` cleanup contract with archive-not-delete — the implementation follows the superseding spec (and `reference_gh_pat_no_delete`), as required.
- §5.c rebuild spec: every bullet realized (drop-set/no-Description fixtures, size, pacing, autolink, corrupt-blob, preflight, archive disposal + grep-guard, repeatable multi-rehearsal with the `pack-bd204-oracle-$$-<ts>` pattern, CI model). One acceptable adaptation: the near-budget body is GENERATED at runtime, never committed as a 60 KB fixture (test.sh:406–407) — the assertion semantics ("composed-body measurement, same gate as the guard") are fully preserved while keeping the fixture small; not a deviation in substance.
- §5.f: required-permission set stated verbatim in-source (test.sh:137–139, 175); delete explicitly not-required; pinned fail-loud message shape used at every probe.
- §11.2: every non-MOOT known-unknown has a live leg (§2 table).
- §3.LF.10 rehearsal support: every `gh` mutation is announced via `live_step` before it runs (test.sh:94) — the per-step-approval protocol's operator visibility.
- Live-pin risk accepted by design: assertions like `created:    N` / `divergence:` / `corrupt-blob` pin lib output; they are exercised only on the manual rehearsal, and all pinned tokens were verified against the current lib source (§2).

## Findings

### NIT-1 — DS-3 probes are outcome-deterministic but not bit-reproducible
`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh:418–424, 435–442` use `os.urandom`. The pass/fail outcome is guaranteed by the entropy bound (§7b), so the leg cannot flake — but a failed live DS-3b run cannot be re-run with the identical payload for diagnosis. A seeded generator (e.g. `random.Random(0).randbytes(...)`) gives the same incompressibility guarantee plus bit-reproducibility at zero cost. Cosmetic; live-path-only; no unattended impact.

## Out of scope — surfaced (not findings against C-7)

- **OOS-1 (= coder IMPL-REPORT §7, independently confirmed):** forward re-runs re-attempt `provider_close` + re-post the Resolution comment for every mapped Resolved/Cancelled/Deprecated entry (`tracker-migrate-forward.sh:1674–1726`). In the rehearsal, forward-2/forward-3 will hit this on BD-902 (Resolved, non-empty `Resolved:` text): expected effects are a close-on-closed no-op plus a DUPLICATE Resolution comment per re-run; if gh's close-on-closed instead errors, the close lands in the BD-134 retry sweep → `partial_failures`, and the oracle's `forward 2 rc=0` assertion will surface it loudly at rehearsal time. Pack Chat should triage as an as-built forward-idempotency item (lib scope, not C-7).

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Git verbs run this session: `git status --short` (output: `?? maintenance-docs/...IMPL-REPORT-BD-204-C-7.md`, `?? scripts/tests/fixtures/tracker-bd204-lossless/`, `?? scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`), `git diff --name-only HEAD` (empty), `git rev-parse HEAD` → `c30c8d56082a9466a1164c94925667592a5a31bf`, `git diff -- test-fixtures/manifest.txt` (empty). No `git add/commit/push/tag/checkout` issued. | COMPLIANT |
| 2 | per-action-approval-sub-agents | `echo "PACK_TRACKER_LIVE_GH=[${PACK_TRACKER_LIVE_GH:-UNSET}]"` → `PACK_TRACKER_LIVE_GH=[UNSET]`; the test run used `env -u PACK_TRACKER_LIVE_GH` and produced `SKIP: live-GH oracle ... / real 0.00 / rc=0` — no gh invocation. Zero `gh` mutations; only destructive op was `rm -rf "$W"` on my own `mktemp -d` dir (self-created, in the offline harness trap). No repo file edited except this report. | COMPLIANT |
| 3 | preflight-stop-means-stop | No stop/halt/revert message was received at any point in this session (full transcript: spawn prompt → review → this report). | COMPLIANT |
| 4 | rules-applied-verification-block | This table — per-rule quoted command output, terminal conclusions only; no empty-evidence rows, no AMBIGUOUS. | COMPLIANT |
| 5 | test-infra-self-provisioned | Verified the TEST encodes the contract (never executed live by me): `SCRATCH_NAME="pack-bd204-oracle-$$-$(date +%s)"` (test.sh:185); slug refusal exercised — `case` pattern output `ALLOW dshanenyc/pack-bd204-oracle-123-456` / `REFUSE dshanenyc/optiquity-ai-agent-config-pack` / `REFUSE dshanenyc/pack-bd204-oraclex`; disposal `gh repo archive "$SCRATCH_REPO" --yes` + `isArchived` assert (test.sh:766–772) + trap-archive (202–218); `grep "delete\|DELETE"` over the source → comments/strings only. | COMPLIANT |
| 6 | deferral-is-scope-creep + no-deferral-without-user-direction | All review findings classified (1 NIT, §Findings); OOS-1 is surfaced for Pack Chat triage with its BLOCKED evidence quoted ("PLAN § C-7: 'C-7 is **test + fixture only**; no `scripts/lib/tracker-*.sh` edit'" + live-confirmable-only-at-rehearsal), not a self-authorized deferral recommendation. | COMPLIANT |
| 7 | verify-full-ci-suite | Beyond `validate-pack.py` (`PASSED — all checks clean / real 1.33`): `test-v11-realistic-ot.sh` → `All v11-realistic-ot integration tests PASSED (33/33).`; `tracker-migrate-forward-test.sh` → `All tests passed.`; `tracker-migrate-reverse-test.sh` → `All tests passed.`; SKIP-wording sweep `grep -rn "SKIP: live-GH" scripts/ .github/` → only test.sh:63 (no other surface pins it). Full ~8-min battery not re-run — coder's run accepted per the calling prompt ("You do NOT need to re-run the full ~8-min battery"); spot-runs cover every output-pinning surface the change could touch. | COMPLIANT |
| 8 | ci-check-runtime-compounding | Measured, not estimated: unattended path `/usr/bin/time -p` → `real 0.00 / user 0.00 / sys 0.00`, rc=0; `grep -rn "tracker-bd204-lossless" .github/workflows/` → no match (battery invocation count for this test = 0); `validate-pack.py` stayed baseline at `real 1.33`. | COMPLIANT |
| 9 | enumerate-encoding-surfaces | Sweep of every surface that could ENCODE the change's expected state: workflows (`grep -rn "tracker-bd204-lossless" .github/workflows/` → none), validators (`validate-pack.py:5226` lists `scripts/tests/fixtures` on the pre-existing OQ-S1 exemption — green run confirms), tests pinning SKIP wording (`grep -rn "SKIP: live-GH"` → test.sh:63 only), repo-wide name refs (`grep -rln ... --exclude-dir=.git` → the 3 change files + 13 maintenance-docs design/plan/report docs, all expected), manifest (`git diff -- test-fixtures/manifest.txt` empty after regen). No asymmetric coverage found; the change introduces no validator-pinned output. | COMPLIANT |
| 10 | P-missed-7 / boundary rules | `git status --short` shows zero `project-template/` or `supporting-docs/` paths; `git diff --name-only HEAD` empty; the three new paths are all `scripts/tests/` (pack-side test infra). Fixture text is self-contained (no pack-ops/maintenance-docs refs in fixture entries — verified by reading both fixture files in full). | COMPLIANT |
