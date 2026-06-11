# PACK-REVIEW — BD-204 rehearsal run-3 fixes (Defects A / B / C)

- **Reviewer:** fresh pack-reviewer, 2026-06-10 (pass 1 of the bounded cycle)
- **Branch / HEAD:** `v11-dev` @ `451f20f4e4d665498aeb9101885fadb2ee503b5a` (unchanged; no git state changes this session)
- **Scope reviewed:** the ENTIRE uncommitted diff — 8 files, +326/−3, all under `scripts/` (verified `git diff --numstat` total `+326 -3`; `git status --porcelain` = exactly the 8 modified files + the untracked coder IMPL-REPORT + this report)
- **Verification:** full CI battery run FOREGROUND locally (every `.github/workflows/validate-pack.yml` step + DEEP validate + off-CI promote suites); all green. Live oracle stayed default-SKIP. No live GitHub calls; all probes mock-based.

## Verdict

**APPROVE-WITH-FIXES.** The three lib/test fixes are correct, well-scoped,
and genuinely pinned by the new mock coverage — I verified each defect's fix
independently (direction probes, read-failure degradation probe, parser
edge-case probes, old-vs-new teeth proof) rather than taking the IMPL-REPORT's
word. The code is commit-ready as-is. The fixes requested are
documentation-level: one SHOULD (an inaccurate audit claim in the IMPL-REPORT
that gets committed with the change) and one NIT (re-run summary cosmetics).
POQ-1 disposition recommendation: FIX NOW in this cycle (see below).

---

## 1. Defect B — read-before-write link idempotency (`scripts/lib/tracker-provider-gh.sh:609-644`)

### Read shape — CORRECT
The new read (`tracker-provider-gh.sh:636`) is byte-shape-identical to the
live-verified reverse-path read at `tracker-migrate-reverse.sh:437`
(`_tmr_fetch_first_class_blocked_by`):
`query { repository(owner: …, name: …) { issue(number: N) { blockedBy(first: 50) { nodes { number } } } } }`.
Same interpolation idiom, same `first: 50`, same jq extraction defensiveness
(`.nodes[]?`). The only difference is transport (`_gh_run gh api graphql`
directly vs the reverse helper's `provider_raw`), which matches the mutation
call style already in `tracker_provider_gh_link` — consistent.

### Direction keying — CORRECT (independently probed, all four quadrants)
The skip key (`tracker-provider-gh.sh:627-632`) inverts operands exactly as
the mutation does (`:649-655`). I ran the REAL provider against a /tmp fake gh
seeded with the single edge `issue 7 blockedBy 1` and a mutation-attempt
sentinel:

```
case 1: link 7 1 blocked-by (edge EXISTS)        → rc=0, "already_linked": true, mutations=0  ✓ skip
case 2: link 1 7 blocked-by (REVERSE dir, absent) → rc=0, no marker, mutations=1               ✓ write
case 3: link 1 7 blocks (SAME edge inverted)      → rc=0, "already_linked": true, mutations=1  ✓ skip
case 4: link 7 1 blocks (absent edge)             → rc=0, no marker, mutations=2               ✓ write
```

No quadrant skips the wrong edge or re-attempts the right one.

### Best-effort read failure — degrades to WRITE, never to silent skip (probed)
Re-ran case 1 with the fake's `blockedBy(first` arm replaced by `exit 1`:
result `rc=0`, NO `already_linked` marker, mutation attempted (`mutations=1`).
The skip fires ONLY on a successful read with positive edge presence
(`if existing=$(…); then if jq -e …` at `:637-639`); any read failure, `{}`
response, or jq parse failure falls through to the mutation — exactly today's
behavior. `2>/dev/null` on the read correctly suppresses the
`_gh_classify_error` block from the best-effort path so no spurious typed
error reaches callers.

### Pagination (`first: 50`)
Both the read and its comment inherit the reverse path's claim that 50 is the
documented per-relationship ceiling (`tracker-migrate-reverse.sh:437` uses the
identical bound; live-verified shape per BD-204 research). Not independently
verifiable offline. Failure analysis if the ceiling were ever exceeded: an
existing edge beyond the first 50 is missed by the read → the mutation is
re-attempted → live GH fails it → partial-write, i.e. degradation back to the
pre-fix fail-LOUD behavior, never a silent wrong-skip. Acceptable; no action.

### No-store-bug claim — VERIFIED INDEPENDENTLY
Read `tracker_links_create_blocked_by` in full (`tracker-links.sh:196-289`)
plus the cycle-check internals:
- Nothing on the create path reads the store as an exists-check; the only
  store read is the cycle BFS (`tracker-cycle-check.sh:248-313`), which for a
  re-added `907→901` walks out-edges FROM 901 (none) → SAFE rc=0. Confirms
  the coder's elimination step 3.
- `_tracker_cycle_check_store_add` (`tracker-cycle-check.sh:340-371`) dedups
  the `(source, target, kind)` tuple — write-side idempotent exactly as
  claimed; a re-run's store add would have succeeded.
- The store-is-not-a-create-dedup rationale in the new Step-4 comment
  (`tracker-links.sh:241-251`) is sound: the store is written only AFTER
  provider success and can drift from tracker truth (fresh clone, GH-side
  unlink), so provider-truth consult is the right layer. Claim CONFIRMED.

### Old-vs-new teeth proof — REPRODUCED INDEPENDENTLY
Sourced `git show HEAD:scripts/lib/tracker-provider-gh.sh` (old provider) vs
the working-tree provider against a duplicate-edge-sentinel fake:

```
OLD link1 rc=0 / OLD link2 rc=1   ← the run-3 failure shape
NEW link1 rc=0 / NEW link2 rc=0   ← read-skip, no re-attempt
```

### Consumers of the success JSON
`grep` over non-test `scripts/` shows no consumer parses `linked_to` /
`already_linked` — `tracker_links_create_blocked_by` discards provider stdout
(`tracker-links.sh:252`), `tracker-promote.sh:1090` discards it. The additive
key is safe. All call sites (step-7 both arms, step-7b phase-task deps via the
same orchestrator, direct `provider_link`) route through the provider, so the
fix covers them all, as claimed.

## 2. Defect C — bare-`n/a` resolution projection (`scripts/lib/tracker-migrate-forward.sh:477-498`)

### Single shared parse point — CONFIRMED
The normalization lives in `flush_entry` of `_tmf_parse_backlog_file`, which
is the one parser shared by: the forward composer call sites (shell
`tmf_compose_issue_body:933-975` AND the Python batch `compose():1063-1089` —
both have the empty-omission rule), the divergence comparator
(`_tmr_check_blob_h2_divergence`, `tracker-migrate-reverse.sh:809-899`, which
re-parses the blob through THIS parser at `:829`), and any parser-derived
edit-path recompose. `tracker_edit_entry` (`tracker-edit.sh:182-275`)
correctly needs no change: its contract is caller-supplied fields, and an
unresolved entry's caller-side resolution is now consistently `""` whether
hardcoded (the oracle's CRUD shape) or parser-derived.

### Blob verbatim — CONFIRMED
The normalization touches only the parsed `resolution` projection key; the
verbatim `raw_body` capture (`finalize_raw`, decoupled from `flush_entry` per
the comment block above it) is untouched by the diff. Pinned by reverse-test
2.1f's `blob raw_body (incl. 'Resolved: n/a' line) byte-faithful` assertion
and roundtrip 6.3's byte-verbatim reconstructions; Check 49 deep
field-faithfulness green (`PACK_VALIDATE_DEEP=1` PASSED).

### Three-actor agreement — CONFIRMED mechanically
Composer omits the H2 for `""` (forward-test 4.2 pins it); comparator
re-parses through the same parser so `exp_resolution=""` → `norm("")` ==
`norm("")` for a no-H2 body (reverse-test 2.1f pins rc=0, no divergence);
edit-path recompose with `""` matches both (roundtrip 6.3 pins the full
post-CRUD reverse). The comparator stays carve-out-free — a real Description
edit on the SAME n/a entry still flags (2.1f-ii: rc=1, names issue #81 +
Description).

### Case/variant handling — probed empirically against the real parser

```
Resolved: n/a                       → resolution=[]            (normalized)
Resolved: N/A                       → resolution=[]            (case-insensitive)
Resolved:  n/a␣                     → resolution=[]            (whitespace-trimmed)
Resolved: n/a.                      → resolution=[n/a.]        (NOT bare — untouched)
Resolved: n/a — superseded by BD-002 → resolution=[n/a — …]    (prefixed — untouched)
Resolution: n/a                     → resolution=[]            (both headers map to the key)
Resolved: 2026-04-01 — fixed in abc1234. → real text untouched
File/Symbol: n/a — new dir          → file_symbol=[n/a — new dir] (other keys untouched)
```

Non-bare variants (`n/a.`, `n/a — text`) stay non-empty, which is CONSISTENT
across all three actors (they share the parse point), so no new asymmetry —
they simply aren't the grammar placeholder and project an H2 everywhere.

### Inverse rule + canonicality — CONFIRMED
`_tmr_emit_backlog` (`tracker-migrate-reverse.sh:986-990`) writes
`Resolution: <res>` when non-empty, else `Resolved: n/a` — so post-fix
`emit(parse("Resolved: n/a"))` round-trips byte-identically where pre-fix it
morphed to `Resolution: n/a`. The pack tree has 40 live `^Resolved: n/a$`
entries (grep count) and zero `Resolution: n/a` entries; the canonical-side
decision is well-evidenced. One downstream behavior change verified as benign:
step 9 (`tracker-migrate-forward.sh:1740-1744`) no longer posts a literal
"n/a" Resolution comment when closing a Cancelled/Deprecated entry that
carries the placeholder — semantically correct.

### Knock-on fixture canonicalization — CORRECT, with one audit-claim error
`scripts/tests/fixtures/tracker-links/BACKLOG-phase-task-blockers.md` 1-line
change is forced by links-test 4.1's parse→emit byte-identity (now 43/0
green). However, see finding F-1: the IMPL-REPORT's supporting claim that
`Resolution: n/a` "appears nowhere outside test fixtures" is inaccurate.

## 3. Defect A — oracle needle + non-empty-fetch guard (`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh:394-409`)

- Needle `<code` (attribute-tolerant open-tag prefix) matches both `<code>`
  and the live-evidenced `<code class="notranslate">`. Substring semantics of
  `assert_contains` (`:81`) confirmed. Correct fix for the run-3 line-39 FAIL.
- The non-empty-fetch guard lands AFTER the `body_html` fetch and BEFORE the
  four `assert_not_contains` legs — those four can no longer false-pass on an
  empty fetch. Honest `t_pass`/`t_fail` accounting (helpers exist, `:77-78`).
- Default-SKIP guard untouched and still the FIRST action (`:56-66`);
  verified live: `bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
  with env unset → `SKIP: live-GH oracle (…)`, rc=0.
- Diff inspection confirms NO other oracle leg touched (two hunks only, both
  in the KU-OPS-6 section).

## 4. Coverage — the new mock legs genuinely pin the run-3 topologies

Inspected every assertion in the diff (not the IMPL-REPORT's summary):

- **Roundtrip 6.2 (re-run no-re-attempt):** runs forward TWICE with state +
  id-map INTACT — confirmed Group 3 is the only prior re-forward and it wipes
  both (`rm -f` at `:697-698`), so 6.2 is genuinely new coverage. The fake-gh
  `addBlockedBy` duplicate sentinel (`:299-306`) exits 1 on an existing edge;
  my old-provider probe proves a regression to write-without-read trips it
  (OLD re-run rc=1). 6.2 additionally pins `created:    0`, no `step-7 link
  blocked-by`, no `partial-write`, and edge-count invariance.
- **Roundtrip 6.3 (post-CRUD cascade):** real `provider_create` (BD-009) +
  id-map register + real `provider_update` (the fake's `issue edit` arm now
  applies `--body-file`/labels to state — previously a no-op, so the real
  update path is exercised) with the oracle's exact recompose shape
  (resolution EMPTY, raw_body flipped). Reverse 3 pins rc=0, no `divergence:`,
  BD-009 byte-verbatim, BD-002 `Status: Deferred` byte-verbatim, count==4
  (fixture filters to 3 BD entries + BD-009 — verified against
  `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` + the BD-only
  decompose in `_setup_test_repo`). All three run-3 cascade failures pinned.
- **Roundtrip 6.4:** re-forward post-CRUD pins `entries:    4` (the run-3
  line-129 analog) + no step-7 failure.
- **Reverse 2.1f / 2.1f-ii:** no-divergence on an n/a entry (rc=0 + stderr
  free of `divergence` + status Deferred decode + raw_body byte-faithful);
  real-edit-still-flags (rc=1, `divergence: issue #81`, `Description`).
- **Forward 1.1 / 4.2:** parser rule pinned directly (entry[0] empty,
  entry[2] real text still captured); composer omission pinned via the
  suite's grep idiom (`grep -q "^## Resolution"`), correctly anchored.

Fake-gh infrastructure check: the `blockedBy(first` read arm the new provider
read depends on is PRE-EXISTING in the roundtrip fake (`:325-338`, BD-111
reverse read side) and serves edges from state — so 6.2's read-skip is served
real data, not `{}`. Suites whose fakes answer graphql with `{}` (e.g. the
forward suite) degrade the read best-effort to the mutation, unaffected —
confirmed by the full green battery.

## 5. Verification + scope (independent, foreground)

Validators: `python3 scripts/validate-pack.py` → `PASSED — all checks clean`;
`PACK_VALIDATE_DEEP=1` → same.

Full `.github/workflows/validate-pack.yml` tests-job battery, every step run
locally foreground, rc=0 each: detect 100/0; tracker-provider / config / init
/ agent-read all-pass; forward **183/0**; reverse **147/0**; roundtrip
**70/0**; phase-task; links **43/0**; cycle-check; errors; config-schema 32/0;
recommendation-state-schema 19/0; per-entry 57/57; per-check suites
32-34 (85/85), 36-38, 39, 40, 41, 18, 16, 19, 42, 43, 44, 45, 46,
removed-doc-advisory, 49-field-faithfulness; bd129 14/0; bd130 24/0; bd132
29/0; bd133; bd134 24/0; recommendation; pack-help; customization-preserve;
init-project; migrate-v10-to-v11 (+dry-run +gates +decompose); migrator-core
19/0; migrator-manifest 12/0; migrator-capability-translation 12/0;
`test-fixtures/build.sh --all --clean` rc=0 + `--verify` all 6 rows OK;
realistic-ot **33/33**; migrator-skills 19/0; persona-contracts;
template-translations; template-version; issue-forms. Off-CI parser-adjacent:
promote-direct / path1 / path2 all rc=0, FAIL: 0. Live oracle: default-SKIP
confirmed (rc=0, pinned SKIP line).

Manifest claim verified: after `--all --clean` rebuild,
`git diff test-fixtures/manifest.txt` → EMPTY and
`git status --porcelain test-fixtures/` → empty; `--verify` all rows OK. No
manifest staging needed — the coder's claim is correct.

pack-only scope verified: `git diff --name-only` = exactly the 8 expected
`scripts/` files; untracked additions = the coder's IMPL-REPORT + this report
only. No `project-template/`, no `supporting-docs/`, no pack-chat-only paths.
Boundary discipline (P-missed-7 / review-skill item 0): no client-shipped
surface touched; the tracker libs are pack-side (not in the
`_SANCTIONED_PACK_SIDE_SHIPPED` set); no pack-only references introduced
anywhere client-visible.

## 6. POQ-1 assessment (pre-existing heredoc backtick noise)

CONFIRMED pre-existing at HEAD `451f20f`: reproduced
`scripts/tests/tracker-migrate-forward-test.sh: line 519: issue: command not
found` on stderr this session; the cause is the unquoted `<<FAKEGH` heredoc
whose BD-132 F-7 comment carries backticks (`` `issue list --state closed
--label …` `` spanning ~:535-536) executed as command substitution at heredoc
expansion. The diff's only forward-test hunks are at `@@ -117` and `@@ -818`
— the heredoc region is untouched, so the coder correctly left it unfixed
and surfaced it instead of silently scope-creeping.

**Disposition recommendation: FIX NOW in this cycle's fix-coder pass**
(default per `deferral-is-scope-creep`; fails all three carry-forward tests —
not SIZE (one-line backtick escape; do NOT quote the delimiter, which would
break the heredoc's many intended expansions), not BLOCKED, no LOGICAL FIT
elsewhere). It is harmless today but pollutes every CI run's stderr and can
mask a real `command not found`. If the user instead defers, it needs a
tracked anchor (typed `# TODO(scope): TD-TBD` or a BD) per
`deferred-work-tracked-anchor` — an archived POQ note is not an anchor.

## Findings

| # | Severity | Anchor | Finding |
|---|---|---|---|
| F-1 | **SHOULD** | `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-RUN3-FIXES.md` § Defect C "Optional-H2 audit" + Plan-deviation 2(c) | The audit claim "`Resolution: n/a` appears nowhere outside test fixtures" is **inaccurate**: `scripts/pack-td.sh:259` (a non-test, shipped-logic file) embeds `Resolution: n/a    → Resolution: $res_text` in its human-facing BACKLOG-patch advisory heredoc, and `scripts/tests/fixtures/tracker-promote/BACKLOG.md` (+ path1/path2 tests) pin the same spelling. Functional impact: **nil** — the advisory is prose (never parsed), the parser normalizes BOTH header spellings identically, and all three promote suites pass (rc=0, FAIL: 0). The fixture-canonicalization decision still stands on its other two grounds (emitter else-branch; 40 live `Resolved: n/a` entries). Fix: correct the IMPL-REPORT sentence before commit (the report ships in this commit); optionally note `scripts/pack-td.sh:259` as a known prose occurrence. No code change required. |
| F-2 | NIT | `scripts/lib/tracker-migrate-forward.sh:1872` (summary) | Post-fix, a skip-all forward RE-run reports `links: parent=0, blocked-by=N` because the `already_linked` skip returns success and `linked_blocked` increments — the run-3 log's re-run printed `blocked-by=0` only because the link FAILED. An operator may read a re-run summary as having created a new link. The provider's `already_linked` marker exists but the orchestrator discards provider stdout, so the summary cannot distinguish ensured-vs-created. Cosmetic; options: accept as "links ensured" semantics (document in the summary heredoc comment), or thread the marker through to a separate count. Not a correctness issue — the mock legs pin the behaviors that matter (no failure, no duplicate edge). |

No BLOCKER. No MUST. Everything else examined — Defect B direction/best-effort
/pagination/store-claim, Defect C parse-point/blob-verbatim/case-handling
/inverse-rule/edit-path, Defect A needle/guard/SKIP-ordering, all new test
legs' teeth, full battery, manifest, scope — is CLEAN as detailed above.

## What the implementation got right (review-skill item 14)

Root-cause quality is high on all three defects: B fixes the duplicate
semantics at the correct layer (provider truth, not store presence, not
error-string classification), C fixes the single shared parse point rather
than carving out the comparator, and A hardens the oracle's negative legs
while fixing the needle. The teeth proofs in the IMPL-REPORT reproduced
exactly under independent re-derivation. The plan-deviation notes (helper
idiom, fixture knock-on) are honest and verifiable.

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs this session: `git rev-parse HEAD`, `git status --porcelain` (×4), `git diff` (full/stat/name-only/numstat/manifest), `git show HEAD:scripts/lib/tracker-provider-gh.sh` (old-provider probe), `git stash list` (empty; read-only check), `git -C … show`. Zero add/commit/push/tag/stash-create/reset/restore/checkout. End-state porcelain = same 8 modified files + 2 untracked reports (9 lines). | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops on repo paths. Only `/tmp/bd204-rev` scratch created and `rm -rf /tmp/bd204-rev` removed (my own scratch); test-internal mktemp dirs cleaned by the suites themselves. `bash test-fixtures/build.sh --all --clean` (required by rules 6/7) rewrote `test-fixtures/` byte-identically — `git status --porcelain test-fixtures/` empty, net read-only. | COMPLIANT |
| preflight-stop-means-stop | Emitted before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 451f20f4e4d665498aeb9101885fadb2ee503b5a; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-RUN3-FIXES.md`. No parent stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; conditional MUST-READ honored: `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block read this session (lines 196-235); every row carries quoted measurement. | COMPLIANT |
| agents-read-rule-docs-in-full | Read IN FULL via Read tool with line counts: `CLAUDE.md` 580 lines (incl. the entire `## Pack memory` section); `/tmp/bd204-rehearsal-run3.log` 137 lines; `feedback_verify_full_ci_suite.md` 43 lines; `feedback_agent_output_rules_applied_block.md` 15 lines. Also read per system-prompt: `/backlog/_rules.md` 95 lines, `/changelog/_rules.md` 67 lines, skills `review`/`commit-discipline`/`architecture-review` (74/174/48 lines). Named code sections read in full: `tracker_provider_gh_link` (:560-679) + `_gh_run`/`_gh_owner_repo`; `flush_entry` + parse mapping + both composers + step-8/9 consumer (forward lib); `_tmr_check_blob_h2_divergence` (:780-899) + `_tmr_fetch_first_class_blocked_by` (:385-456) + emitter else-branch (:975-1000); `tracker_links_create_blocked_by` (:160-289) + cycle-check BFS/store_add; `tracker_edit_entry` (:130-289); oracle header+guard+helpers (:1-82) + edited KU-OPS-6 hunks; full `git diff` of all 8 files. | COMPLIANT |
| verify-full-ci-suite | `python3 scripts/validate-pack.py` → "PASSED — all checks clean" rc=0; `PACK_VALIDATE_DEEP=1` variant → same. EVERY workflow tests-job step run locally FOREGROUND (counts in §5: forward 183/0, reverse 147/0, roundtrip 70/0, links 43/0, detect 100/0, realistic-ot 33/33, fixtures build+verify rc=0, all per-check suites pass, …). Off-CI promote suites also run (3× rc=0). Live oracle default-SKIP verified (pinned SKIP line, rc=0). | COMPLIANT |
| regenerate-manifest-v11-surface | Ran `bash test-fixtures/build.sh --all --clean` rc=0 ("manifest written"); `git diff test-fixtures/manifest.txt` → EMPTY; `git status --porcelain test-fixtures/` → empty; `--verify` → all 6 rows OK (v11-flat-file f9705c27…, v11-tracker-on 944ddee3…, existing-project-mid-dev a54e081a… among them). Coder's empty-diff claim verified correct; no staging needed. | COMPLIANT |
| pack-only (BD-204 HARD) | `git diff --name-only` = 8 files, all `scripts/lib/*` / `scripts/tests/*`; `git status --porcelain` untracked = `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-RUN3-FIXES.md` + this report only. Zero `project-template/` / `supporting-docs/` / pack-chat-only paths. | COMPLIANT |
| scope-deliverables-to-the-ask | Findings F-1/F-2 are real defects in THIS change's deliverables (the committed IMPL-REPORT's audit claim; the change's new re-run summary behavior). POQ-1 assessment included because the prompt explicitly requested its confirmation + disposition; labeled pre-existing, not charged to the coder. No conjecture findings; design-ratified tradeoffs (best-effort read, `first: 50` degradation) documented as checked-clean, not as findings. | COMPLIANT |
