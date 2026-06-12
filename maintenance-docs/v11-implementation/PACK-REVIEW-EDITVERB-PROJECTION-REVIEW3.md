# PACK-REVIEW — BD-204 edit-verb projection fix, reviewer pass 3 (FINAL)

**Date:** 2026-06-12
**Reviewer:** fresh pack-reviewer (pass 3 of the bounded cycle: 2 review/fix pairs complete + this final pass)
**Branch / HEAD:** v11-dev @ `6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6` (unchanged throughout; read-only git only)
**Scope:** the ENTIRE uncommitted 2-file change — `git diff` vs HEAD:
`scripts/lib/tracker-edit.sh` (+157/−2) + `scripts/tests/tracker-provider-test.sh` (+210/−0) = 367 insertions / 2 deletions.

## VERDICT: APPROVE — commit-ready

The change is internally consistent after three passes, fully green on the
complete CI battery (independently re-run by me, foreground, sandbox + isolated
clone), and the red-green I reproduced myself proves every new assertion has
teeth. Zero BLOCKER, zero MUST. One SHOULD and three NITs below — **all four
are pre-existing-at-HEAD adjacent cells** of the write-verb input-shape matrix
(the user-approved follow-up BD's scope), not defects introduced or worsened by
this change. They go to Pack Chat triage with a live anchor available; none
blocks this commit, and per `bounded-review-fix-cycle` (CLAUDE.md:458-465) no
fix-coder pass 3 attaches to this change.

---

## 1. F1 — projection-only guard: reach, fail-safe, carve-out, and the blob-less edge

**Guard placement and trace** (`scripts/lib/tracker-edit.sh:416-429`): the
guard sits inside the `has_content == "1"` branch, fires only when
`ed_raw_body` is empty, reads the current issue via `provider_get` (provider
abstraction, no raw `gh`), and refuses with a typed `validation` error BEFORE
any provider write when the current body contains `pack-entry-body-gz64`.

- **Blob-carrying issue + projection-only patch → REFUSE.** Verified by code
  trace and leg 4.7h (7 assertions: rc≠0, `ERROR: validation`, names
  `pack-entry-body-gz64`, actionable `--raw-body-file`, file-logged
  `provider_get` consult `get:42`, `TED_CALLS` empty, `__UNTOUCHED__` payload
  canary intact). The canonical resolve shape (`--status Resolved
  --resolution ...`) is exactly the leg's patch — the maiden-run-adjacent
  destruction shape is closed.
- **Fail-safe on unreadable body.** `provider_get` failure → typed refusal at
  `tracker-edit.sh:418-421`, `return 1` before any write. Never proceeds
  blind. (No test pins this branch — NIT-3.)
- **Status/label/title-only patches genuinely unreachable.** Trace:
  `has_content` (`tracker-edit.sh:344-348`) tests ONLY the five content keys
  (`description`/`context`/`resolution`/`file_symbol`/`raw_body`).
  `status`/`old_status`/`title`/`add_labels`/`remove_labels`/`body` never set
  it, so the entire recompose branch — guard included — is skipped, and the
  update payload carries no `body` key. On the CLI side, `cmd_edit`
  (`scripts/pack-tracker.sh:348-371`) only emits patch keys for non-empty
  flags, so a status/label/title-only invocation cannot smuggle a content key.
  Pinned by 4.7i (update dispatches, `provider_get` log EMPTY with the stub
  still armed from 4.7h, `has("body")` = false).
- **CRITICAL EDGE — issue WITHOUT a blob (pre-blob / inbound-lane): the guard
  correctly ALLOWS, and that is the right call.** Trace: blob marker absent →
  fall through to recompose → `provider_update` replaces the body with a
  blob-less composed body (composer emits no marker when raw_body is empty,
  `tracker-migrate-forward.sh:1097-1102`). Why allow is right: (a) there is no
  verbatim-span SSOT to destroy — the H2 IS the only representation, exactly
  the class both reverse comparators skip by design
  (`_tmr_check_blob_h2_divergence:834`, `_tmr_check_status_coherence:951`);
  (b) refusing would dead-end legacy/blob-less issues entirely — projection
  edit is their only edit lane, and supplying `--raw-body-file` on such an
  issue is the natural upgrade lane (it ADDs a blob); (c) the loss class that
  remains is visible (a hollow H2 on the issue page), unlike the silent blob
  destruction the guard closes. Residual: un-patched H2 fields are hollowed
  (NIT-2 — pre-existing; matrix-BD cell).

## 2. F2 — single-entry + id-match gates: correct; lib placement defensible

`tracker-edit.sh:449-461`: inside the parse-success branch, `length != 1` →
typed refusal naming the count; `.[0].pack_id != $pack_id` → typed refusal
naming both ids. Both fire BEFORE any provider op (pinned 4.7f/4.7g, including
the no-provider-op asserts via non-command-substitution invocation so stub
mutations would propagate if a write wrongly fired). Error wording mirrors
`cmd_new_entry` (`pack-tracker.sh:463-474`) faithfully.

**Layering — lib, not cmd_edit: defensible and arguably stronger.** The gates
live where the parse lives, exactly as new-entry's gates live where ITS parse
lives (cmd-level there, because new-entry parses at cmd level). Lib placement
additionally covers any future non-CLI caller of `tracker_edit_entry` with a
raw patch JSON — a cmd-level gate would not.

**One mirror-fidelity gap → SHOULD-1.** `cmd_new_entry`'s `n_parsed != 1` gate
also refuses **parsed 0** (an unparseable `--body-file` garbage span). The edit
path's gates sit inside `[[ -n "$_ted_parsed" && "$_ted_parsed" != "[]" ]]`
(`tracker-edit.sh:440`), so a parsed-0 raw_body falls through: derives nothing,
rides VERBATIM into the gz64 blob, rc=0. The next materialization emits the
blob raw_body verbatim into a tree file (`tracker-migrate-reverse.sh:1130`,
`body = e.get("raw_body","")`), i.e. a garbage entry file — the same corruption
class the F2 comment itself describes for wrong-id spans. The lib's contract
comment is carefully scoped ("a **parseable** raw_body must contain exactly ONE
entry span") but the parenthetical "the same single-entry + id-match gates
`cmd_new_entry` ... enforces" overstates the mirror on this one cell. Note this
cell is **pre-existing at HEAD**: the HEAD lib did no raw_body parse at all and
accepted garbage spans into the blob identically — this change narrowed the
class (parseable-but-wrong shapes now refuse) without closing it.

## 3. F4 — n/a normalization seam identity: verified

Lib (`tracker-edit.sh:373-379`): per-line `sed` `[[:space:]]` trim + `tr`
lowercase, equality against the bare token `n/a`. Parser
(`tracker-migrate-forward.sh:497`): `res.strip().lower() == "n/a"`, resolution
key only, applied in `flush_entry`. For every single-line value — the only
shape the `Resolved:`-line placeholder convention and the `--resolution` flag
realistically produce — the two are extensionally identical (trim +
case-fold + bare-token equality; placeholder-with-content like `n/a — new dir`
untouched on both sides). Normalized-empty then behaves as ABSENT, so with
raw_body present it derives through the parser, which applies the SAME rule to
the `Resolved:` line — agreement by construction. Pinned by 4.7e with the
hardest shape (` N/A ` explicit + `Resolved: n/a` raw_body → no `## Resolution`
H2 + REAL comparator CLEAN). Checked-and-accepted residual (no action): an
exotic multi-line explicit value like `"\nn/a"` python-strips to the token but
sed-per-line does not — that shape composes a literal H2 that DISAGREES with
the raw_body and the divergence comparator flags it loudly at the next
materialization; fail-loud, not silent.

## 4. Red-green — reproduced independently

Method: `.git`-stripped sandbox (`/tmp/rev3-edv/sb`, 3892 files) via ONE atomic
ledger script; RED = sandbox copy with `git show
HEAD:scripts/lib/tracker-edit.sh` substituted (pre-pass-1+2 lib) under the
full new test file.

- **GREEN:** `tracker-provider-test.sh` → **238 PASS / 0 FAIL**, "All tests
  passed."
- **RED (HEAD lib):** rc=1, **214 PASS / 24 FAIL** — and the 24 are EXACTLY
  the new legs: 4.7c (5), 4.7d (2), 4.7e (2), 4.7f (4), 4.7g (4), 4.7h (7);
  **4.7i green pre-fix** (the status-only carve-out claim holds), zero
  collateral red. This is consistent with the coder's pass-2 revert-only red
  (17 = my 4.7e/f/g/h subset) plus the pass-1 pins (7 = my 4.7c/d subset).
  Every new assertion has teeth.

## 5. Derivation seam — unchanged from pass-1 (spot-check)

`tracker-edit.sh:430-474`: raw_body → temp file → `_tmf_parse_backlog_file`
(the single grammar shared by forward migration loop, `cmd_new_entry` step 2 at
`pack-tracker.sh:459-461`, and the comparator at
`tracker-migrate-reverse.sh:839-854`) → fill ONLY empty `ed_*` fields from
`.[0]`. Explicit fields still override (4.7d). `mktemp` failure fails loud.
Composer call and blob handling byte-unchanged from the pass-1 shape. The
comparator-CLEAN-by-construction argument holds: composer input and comparator
expectation are now the same parse.

## 6. Battery, manifest, keyword, phase refs

Full CI `tests`-job battery re-run by me FOREGROUND via one atomic
ledger-resume script (`/tmp/rev3-edv/run.sh`); main tree read-only throughout
(post-run: HEAD unchanged, `git status --porcelain` = same 2 ` M` files + 6
pre-existing `??` docs, stash count 0).

| Where | Legs | Result |
|---|---|---|
| Sandbox: `validate-pack.py` + `PACK_VALIDATE_DEEP=1` | 2 | both PASS |
| Sandbox: subject suite | 238 asserts | 238/0 PASS |
| Sandbox: all remaining CI suites (13 tracker, 15 per-check validator, bd129/130/132/133/134, recommendation, pack-help, customization-preserve, realistic-ot, template-translations, template-version, issue-forms, per-entry, recommendation-state-schema, migrator-capability-translation, migrator-skills) | 40 | ALL PASS |
| Sandbox: live oracle `tracker-bd204-lossless-roundtrip-test.sh` | 1 | default-SKIP, rc=0, SKIP banner (no live GH call made anywhere this session) |
| Isolated clone (`git clone file://` + checkout v11-dev + 2-file overlay, `cmp`-verified byte-equal, v10 tag present): detect, init-project, migrate-v10-to-v11 ×4, migrator-core, migrator-manifest, fixture build `--all --clean`, manifest diff, fixture `--verify`, persona-contracts | 12 | ALL PASS |

**Total: 60 ledger steps / 0 failures** (the one transient `FAIL C-red` ledger
line was my own counter grepping uncolored output; the actual red shape above
is exactly correct).

- **Manifest (rule 7):** main-tree `git diff test-fixtures/manifest.txt` = 0
  lines; clone rebuild (`--all --clean`) → post-rebuild manifest diff = **0
  lines**; `--verify` PASS. Empty-diff claim VERIFIED — neither edited file is
  client-installed (`find test-fixtures -name tracker-edit.sh -o -name
  tracker-provider-test.sh` → no hits).
- **Scope keyword:** proposed subject carries `(pack-only)`; diff touches only
  `scripts/**` — no `project-template/`, no `supporting-docs/` → Check 36 safe.
- **Phase refs:** `git diff | grep -i phase` → zero hits in added text.
- **Trinity / README layout / migration docs:** N/A — no trinity file, no file
  add/move/remove, no client-shipped surface touched.

## 7. Cumulative internal consistency after three passes

- Contract comments re-verified against code line-by-line: the function-doc
  `resolution` paragraph (lib:200-207), PROJECTION DERIVATION + PRECEDENCE +
  RAW-BODY GUARDS + PROJECTION-ONLY GUARD paragraphs (lib:219-247), the §3.3a
  restatement closing sentence (lib:339-342), and the inline F4/F1/F2 comment
  blocks all describe exactly what the code does (one wording note folded into
  SHOULD-1).
- The deferral comment uses the typed format (`# TODO(tracker): TD-TBD —
  merge-edit for projection-only patches ...`, lib:412-415) per
  `pack-repo-code-comment-deferrals`, anchored to the user-approved matrix BD.
- Test-harness mechanics sound: 4.7h's `provider_get` stub logs to a FILE
  (subshell-safe — the lib calls it in command substitution); the stub
  deliberately stays armed for 4.7i (proves non-consultation) and is inert for
  4.8/4.9 (no content keys → branch never entered) and Group 5 (fresh `bash`
  processes; function stubs don't apply). Group 5's only content edit (5.5)
  carries `--raw-body-file` with a matching BD-002 header → no guard/gate
  interaction; suite green confirms.
- Both IMPL reports' claims check out against the working tree (line refs
  drift by a few lines as expected of archived artifacts; nothing load-bearing).

## 8. Findings

**SHOULD-1 — parsed-0 (unparseable) raw_body still rides garbage into the
blob SSOT, rc=0; new-entry refuses the identical input.**
`tracker-edit.sh:440` gates the single-entry/id checks behind parse-success,
so `{raw_body:"<garbage>"}` composes a garbage gz64 blob silently;
`cmd_new_entry`'s `n_parsed != 1` (`pack-tracker.sh:463-467`) refuses parsed-0.
Downstream, reverse emits the blob verbatim into a tree file
(`tracker-migrate-reverse.sh:1130`). Pre-existing at HEAD (HEAD did no parse at
all); narrowed but not closed by this change. Disposition options for triage:
(a) widen the gate — move the `n_parsed != 1` check outside the parse-success
conditional so parsed-0 refuses exactly like new-entry (~4 lines; no legitimate
raw_body is unparseable by contract — it is DEFINED as the verbatim span whose
first line is the bold header; no existing test pins parsed-0 acceptance); or
(b) name the cell explicitly in the matrix-BD anchor and align the "same gates
as cmd_new_entry" comment wording. Either satisfies; (a) is the
small-fix-now default.

**NIT-1 — legacy `body` key is an unguarded blob-destruction cell.** A patch
carrying only `body` (CLI `--body-file`) bypasses the recompose branch entirely
and `provider_update` replaces a blob-carrying body verbatim — same silent
destruction class F1 closes for projection fields. Pre-existing, untouched by
this change, documented as LEGACY. Belongs as a named cell in the matrix BD
(which the context note says will define the complete input-shape matrix).

**NIT-2 — projection-only edit on a blob-LESS issue hollows un-patched H2
fields.** The guard's allow is correct (§1 above), but the recompose composes
ONLY the patch's fields — e.g. `--resolution` alone leaves `## Description`
empty on a legacy issue. Pre-existing; visible (not silent); matrix-BD cell.

**NIT-3 — the F1 fail-safe branch is untested.** No leg stubs `provider_get`
to fail and pins the "cannot read the current issue body" refusal
(lib:418-421). A 3-line leg beside 4.7h would pin it; fold into the matrix BD's
test work if not added now.

## 9. Read-in-full attestation (agents-read-rule-docs-in-full)

| File | Lines | Read |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` § Pack memory | 590-line file; §140-590 read from DISK this session (on-disk version differs from session-context copy and was used as authoritative) | IN FULL |
| `scripts/lib/tracker-edit.sh` (post-fix) | 567 | IN FULL |
| `maintenance-docs/v11-implementation/IMPL-REPORT-EDITVERB-PROJECTION.md` | 293 | IN FULL |
| `maintenance-docs/v11-implementation/IMPL-REPORT-EDITVERB-PROJECTION-FIX1.md` | 291 | IN FULL |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | 43 | IN FULL |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | 15 | IN FULL (+ mandated follow-up: `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block, lines 206-233) |
| Section reads | — | `_tmf_parse_backlog_file` + flush_entry n/a rule (forward:402-600); `tmf_compose_issue_body` (forward:1075-1148); `_tmr_check_blob_h2_divergence` (reverse:800-915) + `_tmr_check_status_coherence` head (reverse:917-959) + verbatim emit (reverse:1130); `cmd_edit` + `cmd_new_entry` (pack-tracker.sh:240-511); Group-4 harness + all 4.x legs + Group 5 (provider test:900-1607); CI workflow run-steps (validate-pack.yml) |

No `PACK-REVIEW-*.md` file was read (the two on disk were excluded per the
prompt; the FIX1 IMPL-REPORT's §2 quotes of pass-1 findings were read as part
of that permitted report).

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git verbs against the main tree: `status --short/--porcelain`, `diff`/`diff --stat`, `rev-parse HEAD`, `show HEAD:scripts/lib/tracker-edit.sh`, `stash list`, plus `git clone file://<main>` (read-only on source; target `/tmp/rev3-edv/clone`) and `checkout v11-dev`/`tag -l`/`diff` INSIDE the clone only. Final check: HEAD `6a3f15c...` unchanged; `git status --porcelain` = same 2 ` M` + 6 pre-existing `??`; `git stash list | wc -l` = 0. No add/commit/push/tag/stash/reset/restore/checkout on the main tree. Output = this report only. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op on any repo file; `rm -rf` confined to self-created `/tmp/rev3-edv/{sb,red,clone}` rebuild paths inside the atomic script. GitHub MCP tools available mid-session were NEVER invoked; zero live GitHub calls (oracle log: "SKIP" banner, rc=0). No parent stop message received. | COMPLIANT |
| preflight-stop-means-stop | Emitted verbatim immediately before this Write: "PREFLIGHT: review complete; verification PASS; HEAD 6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-EDITVERB-PROJECTION-REVIEW3.md". All verification was green before the line. No stop/halt/revert message at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table, in the literal format of `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 219-233, read this session: "per-rule table `Rule \| Verification evidence \| Conclusion`"). Every row carries quoted non-empty evidence; no AMBIGUOUS terminal state. | COMPLIANT |
| agents-read-rule-docs-in-full | §9 attestation: all five mandated docs read in full with line counts (590-file/§140-590 from disk, 567, 293, 291, 43, 15) plus every prompt-mandated section read with line ranges. | COMPLIANT |
| verify-full-ci-suite | Ran by me, all FOREGROUND, ONE atomic ledger script (`/tmp/rev3-edv/run.sh`): `validate-pack.py` + `PACK_VALIDATE_DEEP=1` both PASS; subject suite 238/0; 40 further sandbox suites incl. INTEGRATION (`test-v11-realistic-ot`) ALL PASS; 12 isolated-clone legs (detect, init-project, migrate ×4, migrator-core/manifest, fixture build + manifest-diff 0 + `--verify`, persona-contracts) ALL PASS; live oracle default-SKIP rc=0. Total 60 steps / 0 failures. Red-green reproduced: RED-vs-HEAD 214/24, all 24 = new legs, 4.7i green. | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/` touched → rebuild verified: `bash test-fixtures/build.sh --all --clean` in the isolated clone (2 edited files `cmp`-verified byte-equal to working tree) → `git -C clone diff -- test-fixtures/manifest.txt` = 0 lines; clone `--verify` PASS; main-tree `git diff test-fixtures/manifest.txt \| wc -l` = 0. Empty-diff claim VERIFIED; nothing to stage. | COMPLIANT |
| pack-only | `git diff --stat` = exactly `scripts/lib/tracker-edit.sh` + `scripts/tests/tracker-provider-test.sh` (367+/2−); `git status --porcelain` shows no `project-template/`, no `supporting-docs/` modification; this report lands under `maintenance-docs/` (workflow artifact, Pattern-B exempt). `git diff \| grep -i phase` → 0 hits. Check-36 `pack-only` semantics hold for the proposed subject. | COMPLIANT |
| scope-deliverables-to-the-ask | Findings are exclusively on this change and its immediately adjacent pre-existing cells (each labeled pre-existing with disposition routed to the user-approved matrix BD); no out-of-scope redesign proposed; no file beyond this report written; verdict + per-criterion verification map 1:1 to the prompt's 7 success criteria (§1-§7). | COMPLIANT |
