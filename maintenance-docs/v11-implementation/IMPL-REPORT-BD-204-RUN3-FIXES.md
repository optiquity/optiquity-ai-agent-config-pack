# IMPL-REPORT — BD-204 rehearsal run-3 fixes (Defects A / B / C)

- **Branch:** `v11-dev`
- **HEAD at implementation (unchanged; no git state changes):** `451f20f4e4d665498aeb9101885fadb2ee503b5a`
- **Working tree at start:** clean (pre-flight `git status` empty)
- **Coder:** fresh pack-coder, 2026-06-10
- **Scope:** exactly the three run-3 defects + their test coverage (pack-only; no live GitHub calls — all verification mock-based)
- **Proposed commit subject:**
  `fix: v11 — BD-204 rehearsal run-3 fixes: idempotent blocked-by link + resolution-projection symmetry + oracle code-span needle (pack-only)`

## Evidence base

- `/tmp/bd204-rehearsal-run3.log` (137 lines, read in full): 57 PASS / 8 FAIL.
  The 8 failures reduce to: 1× KU-OPS-6 needle (Defect A), 2× forward-re-run
  `step-7 link blocked-by: BD-907 -> BD-901` partial-write (Defect B,
  lines 85-90 + 122-127), 1× post-CRUD reverse divergence abort (Defect C,
  lines 103-110) + 3 cascade failures from that abort (lines 111-114) +
  1× `re-forward sees all 8 entries` (line 129-130, also cascade — the
  8th entry never reached the tree because reverse 3 aborted).
- Live ground-truth from the archived scratch repo (embedded in the prompt):
  GH renders the neutralized span as `<code class="notranslate">…</code>`;
  post-update BD-904 blob carries `Resolved: n/a` verbatim while the visible
  body has ONLY a `## Description` H2.

---

## Defect A — oracle assertion needle (test bug)

**Root cause.** `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
asserted the literal needle `<code>` against `body_html`. Live GH emits
`<code class="notranslate">` — an attribute-carrying open tag — so the
literal closed-bracket needle can never match even though the feature
works (all four negative assertions passed live; zero live links).

**Fix.** Needle relaxed to the attribute-tolerant open-tag prefix `<code`.

**Empty-fetch guard (implemented — cheap).** If `$_904_html` were empty
(failed fetch), all four `assert_not_contains` legs would false-pass. Added
a non-emptiness `t_pass`/`t_fail` gate immediately after the fetch, BEFORE
the four negative assertions, so the leg is honest.

**Constraint kept:** the oracle's default-SKIP guard is untouched and remains
the first action — verified: `bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
with `PACK_TRACKER_LIVE_GH` unset prints
`SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` and exits 0.
The oracle was edited ONLY for Defect A (needle + guard); no other leg touched.

---

## Defect B — forward re-run link idempotency (lib bug)

### Root cause (incl. the store question)

The failing path on every forward RE-run is, by elimination over
`tracker_links_create_blocked_by` (scripts/lib/tracker-links.sh:196-276):

1. **Shape validation** — deterministic, passes (same ids as run 1).
2. **id resolution** — mapping intact across re-runs (the oracle's skip-all
   forward proves it), passes.
3. **Cycle check** (`tracker_cycle_check_would_form_cycle`) — re-adding
   `BD-907 blocked-by BD-901` BFS-walks from `BD-901` looking for `BD-907`;
   the store's only edge is `907→901`, so `901` has no out-edges → SAFE
   (rc=0). Verified offline against the store semantics in
   scripts/lib/tracker-cycle-check.sh:248-313. NOT the failure.
4. **`provider_link`** → `tracker_provider_gh_link` → GraphQL `addBlockedBy`
   on an edge that ALREADY EXISTS. **This is the failure.** Live GH's
   `addBlockedBy` is not idempotent for an existing edge (run-3 evidence:
   the step failed on BOTH re-runs, forward 2 and forward 3, and ONLY on
   re-runs — run 1 created the edge cleanly).
5. **`_tracker_cycle_check_store_add`** — write-side idempotent by
   construction (jq tuple-dedup at scripts/lib/tracker-cycle-check.sh:357-362);
   would have succeeded. NOT the failure.

**Why the documented "idempotency store" did not prevent the re-attempt:**
the cycle-graph store (`.pack-tracker/links-graph.json`) has NO bug — its
idempotency is **write-side only** (`store_add` dedups tuples so the store
never accumulates duplicates). Nothing on the link-create path ever READS
the store (or the provider) for an already-exists check: the store is the
cycle-check runtime view (tracker-links.sh header, items 4-5: "persisted …
so subsequent **cycle checks** see it"), never a create-dedup. Using it as
a create-dedup would also be unsound: the store is written only AFTER
provider success, but store loss (fresh clone) or a GH-side unlink would
make a store-presence skip silently wrong. So the store SHOULD NOT have
handled it; the missing piece was a provider-truth consult.

### Fix (offline-verifiable; provider-truth read-before-write)

`scripts/lib/tracker-provider-gh.sh` `tracker_provider_gh_link`
(blocks/blocked-by arm): before resolving node-ids / mutating, query the
BLOCKED issue's existing edges via the SAME live-verified `Issue.blockedBy`
read shape the reverse path already uses
(`_tmr_fetch_first_class_blocked_by`, scripts/lib/tracker-migrate-reverse.sh:390-456;
`blockedBy(first: 50) { nodes { number } }`, `first: 50` == the documented
per-relationship ceiling so the read sees the full edge set). If the
blocking issue's number is already present → emit the normal success JSON
plus an additive `"already_linked": true` marker and skip the mutation.

Design properties:

- **No error-string classification** — the prompt's hard constraint. No
  captured live duplicate-edge error text exists; the fix never inspects
  mutation errors.
- **Best-effort read** — on ANY read failure (auth, network, mock
  returning `{}`, backend without the read surface) the code falls through
  to the mutation, i.e. exactly today's behavior. All existing fake-gh
  mocks that answer `api graphql` with `{}` are therefore unaffected
  (verified: full battery green).
- **Fixes all call sites** — forward step-7 (both blocked-by arms), step-7b
  phase-task deps, and any direct `provider_link` consumer, because the
  consult lives in the provider where the duplicate semantics belong.
- `kind="blocks"` is covered by the same operand inversion the mutation uses.
- `scripts/lib/tracker-links.sh` Step-4 comment extended to document the
  provider-truth decision and why the store is intentionally not consulted.

### Teeth proof (old-vs-new, empirical)

Scenario: fake gh with a duplicate-edge sentinel (`addBlockedBy` on an
existing edge → exit 1) + a `blockedBy(first` read served from state;
two consecutive `tracker_provider_gh_link 7 1 blocked-by` calls:

```
── OLD provider (HEAD 451f20f via git show): ──
old link 1 rc=0
old link 2 (re-run) rc=1          ← the run-3 failure shape
── NEW provider (fixed): ──
{"id": "7", "linked_to": "1", "kind": "blocked-by"}
new link 1 rc=0
{"id": "7", "linked_to": "1", "kind": "blocked-by", "already_linked": true}
new link 2 (re-run) rc=0          ← read-skip; no mutation re-attempt
```

---

## Defect C — resolution-projection asymmetry (lib bug)

### Root cause + which-side-is-canonical decision

The three projection actors disagreed on the **bare-`n/a` resolution** case:

1. **Parser** (`_tmf_parse_backlog_file`, scripts/lib/tracker-migrate-forward.sh:548):
   maps the `Resolved:` header onto the `resolution` key, so the grammar's
   unresolved placeholder `Resolved: n/a` parsed to the NON-empty value
   `"n/a"`.
2. **Composer** (`tmf_compose_issue_body`:951-953): emits `## Resolution`
   whenever resolution is non-empty → forward run 1 emitted a **phantom
   `## Resolution\n\nn/a` H2** for every unresolved entry.
3. **Comparator** (`_tmr_check_blob_h2_divergence`,
   scripts/lib/tracker-migrate-reverse.sh:809-899): re-parses the blob
   through the SAME parser → expected resolution `"n/a"` → expected a
   `## Resolution` H2.
4. **Update path** (the oracle CRUD leg / any `tracker_edit_entry` caller
   that treats an unresolved entry as having no resolution): recomposed with
   resolution `""` → visible body correctly has ONLY `## Description`.

Run-3 sequence: forward 1 emitted the phantom H2 (comparator happy on
reverses 1-2 because expected==stored phantom); the status-flip update
recomposed WITHOUT the phantom (semantically correct — the entry is
unresolved); reverse 3's comparator then expected `"n/a"` vs stored `""`
→ false `(Resolution)` divergence → abort → the 3 cascade failures.

**Canonical side: the empty-resolution representation.** Evidence:

- The grammar's unresolved placeholder is `Resolved: n/a` (every open entry
  in `/backlog/` — dozens of hits; the run-3 oracle fixture; `backlog/_rules.md`
  documents entries resolve by "filling the `Resolved:` line").
- The reverse emitter's own inverse rule (`_tmr_emit_backlog`:987-990)
  writes `Resolution: <res>` when res is non-empty, **else `Resolved: n/a`**
  — i.e. the emitter already defines bare-n/a as the empty-resolution
  serialization. Pre-fix, `emit(parse(...))` byte-MORPHED every canonical
  `Resolved: n/a` entry into `Resolution: n/a` (parse∘emit asymmetry);
  post-fix it round-trips.
- The composer's empty-omission rule (no `## Resolution` for empty) is
  pinned by existing test legs (forward-test 2.5).

**Fix:** the parser is the bug. `_tmf_parse_backlog_file` `flush_entry` now
normalizes a bare (whitespace-trimmed, case-insensitive) `n/a` on the
`resolution` key to `""`. All three actors now agree mechanically: the
composer omits the H2, the comparator (which re-parses through THIS parser)
expects no H2, and an empty-resolution recompose matches both.

**Constraints kept:** blob stays the verbatim round-trip source (raw_body
capture untouched — Check 49 PARSE-FAITHFUL leg green; the `Resolved: n/a`
LINE rides the blob byte-verbatim and is re-emitted verbatim on the pack
surface). Comparator stays fail-loud on REAL divergence (2.1f-ii leg: a
real one-word H2 edit on the SAME n/a entry still flags rc=1). No per-field
carve-out in the carry path and none in the comparator — the normalization
is at the single parse point both sides share.

**Optional-H2 audit (File/Symbol, Context):** neither has a bare-`n/a`
placeholder convention. The emitter omits both lines when empty (no `n/a`
else-branch — only the Resolved line has one). The only real-world `n/a`
near these fields is content-bearing (`backlog/BD-022.md:8` —
`File/Symbol: n/a — new …`), which the exact-bare-match normalization does
NOT touch (verified empirically: parses to `n/a — new dir` unchanged).
`Resolution: n/a` (the non-canonical header spelling) normalizes identically
— semantically the same "no resolution". Its occurrences: test fixtures
(`scripts/tests/fixtures/tracker-promote/BACKLOG.md` + the path1/path2 promote
tests) PLUS one non-test occurrence — `scripts/pack-td.sh:259`, inside the
human-facing BACKLOG-patch advisory heredoc printed to stderr. That occurrence
is prose (advisory text, never parsed), so it is unaffected by the Defect-C
parse change; all three promote suites pass (rc=0, FAIL: 0).

### Teeth proof (old-vs-new, empirical)

```
OLD parser (HEAD 451f20f via git show) on 'Resolved: n/a' entry: resolution=[n/a]
NEW parser:                                                      resolution=[]
NEW parser, real text 'Resolved: 2026-04-01 — fixed in abc1234.': [2026-04-01 — fixed in abc1234.]
NEW parser, 'File/Symbol: n/a — new dir':                          [n/a — new dir]   (untouched)
```

### Knock-on fixture canonicalization

`scripts/tests/fixtures/tracker-links/BACKLOG-phase-task-blockers.md`
carried the non-canonical `Resolution: n/a` placeholder; links-test 4.1
asserts parse→emit SHA-256 byte-identity, which only ever held as an
accident of the old parser (and which the old parser simultaneously BROKE
for every canonical `Resolved: n/a` entry). Changed the one line to the
canonical `Resolved: n/a`; the leg now pins the canonical round-trip
(test-tracker-links.sh: 43 passed / 0 failed).

---

## New mock test coverage (reproducing the run-3 topologies)

### `scripts/tests/tracker-migrate-roundtrip-test.sh` — new Group 6 (19 new asserts)

Fake-gh upgrades (test infra):
- `addBlockedBy` arm: **duplicate-edge sentinel** — exits 1 if the edge is
  already in state, mirroring live GH non-idempotency. Gives the re-run legs
  TEETH: a regression that re-attempts the mutation trips it (proven by the
  old-provider experiment above). Comment in the fake notes the error text
  is a STAND-IN (no live text captured) and production must never classify
  on it.
- `issue edit` arm (was a no-op): applies `--body-file` / `--add-label` /
  `--remove-label` to state so the REAL `provider_update` path is
  exercisable.

Legs (all PASS):
- **6.1** forward 1 rc=0; ≥1 first-class edge created.
- **6.2 (Defect B, repeated-cycle topology)** forward RE-run with state +
  id-map INTACT (Group 3 wipes both — this was the uncovered topology):
  rc=0, `created:    0`, NO `step-7 link blocked-by` failure, NO
  partial-write, edge set unchanged (no duplicate).
- **6.3 (Defect C + cascade, post-CRUD topology)** `provider_create`
  BD-009 mid-cycle + id-map register (BD-908 analog); blob-consistent
  status-flip update BD-002 Unblocked→Deferred via the REAL
  `provider_update` with the oracle's exact recompose call shape
  (parsed description + File/Symbol + flipped raw_body; resolution EMPTY
  because the entry carries `Resolved: n/a`); reverse 3: rc=0, NO
  divergence, **BD-009 appears byte-verbatim** (cascade #1 clears),
  **BD-002 `Status: Deferred` round-trips** byte-verbatim (cascade #2),
  **count == 4** (cascade #3).
- **6.4** post-CRUD re-forward: rc=0, `created:    0`, `entries:    4`
  (the run-3 line-129 analog), NO step-7 failure (Defect B re-pinned
  against the 4-entry tree).

### `scripts/tests/tracker-migrate-reverse-test.sh` — new 2.1f legs (8 new asserts)

- **2.1f** `Resolved: n/a` entry, composed body has NO phantom
  `## Resolution`; `tracker_migrate_reverse_reconstruct` rc=0 (no
  divergence); status decodes Deferred; blob raw_body (incl. the
  `Resolved: n/a` line) byte-faithful.
- **2.1f-ii** a REAL one-word visible-H2 edit on the SAME n/a entry STILL
  flags: rc=1, names `divergence: issue #81` + `Description` (no-carve-out
  proof).

### `scripts/tests/tracker-migrate-forward-test.sh` — 2 new asserts

- **1.1** `entry[0].resolution` EMPTY for bare `Resolved: n/a` (parser rule
  pinned directly; entry[2]'s real resolution text still captured).
- **4.2** parse→compose chain emits NO `## Resolution` for the n/a entry
  (uses the suite's grep idiom — this suite has no `assert_not_contains`
  helper; first attempt used the helper and silently no-opped with
  `command not found`, caught and corrected during verification).

---

## Files changed (inventory — all modified in place; no new/deleted files)

| Path | Type | Delta | What |
|---|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified | +22 / -0 | Defect C: parser bare-`n/a` → empty resolution normalization in `flush_entry` (comment + 3 code lines) |
| `scripts/lib/tracker-provider-gh.sh` | modified | +42 / -0 | Defect B: read-before-write in `tracker_provider_gh_link` blocks/blocked-by arm + idempotency docstring |
| `scripts/lib/tracker-links.sh` | modified | +11 / -0 | Defect B: Step-4 comment documenting provider-truth consult + why the cycle-graph store is not a create-dedup |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | modified | +12 / -1 | Defect A ONLY: `<code` needle + non-empty-fetch guard (default-SKIP guard untouched and still first) |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified | +175 / -0 (net; 1 arm split) | Group 6 (Defects B+C topologies) + fake-gh `issue edit` apply + addBlockedBy duplicate sentinel |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | +46 / -0 | 2.1f / 2.1f-ii legs (Defect C symmetry + fail-loud retention) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +18 / -0 | Parser + composer n/a assertions |
| `scripts/tests/fixtures/tracker-links/BACKLOG-phase-task-blockers.md` | modified | +1 / -1 | Non-canonical `Resolution: n/a` → canonical `Resolved: n/a` (links-test 4.1 byte-identity leg) |

`git diff --stat` total: 8 files, +326 / -3. End-state `git status --porcelain`
shows exactly these 8 files (+ this report once written) — pack-only; no
`project-template/`, no `supporting-docs/`, no PM-only files.

## Boundary discipline check (P-missed-7)

No project-side files touched. All 8 edits are pack-repo `scripts/`
surfaces (libs, tests, a test fixture). One project-side file was READ for
the Defect-C canonicality audit (`project-template/docs/project/backlog/_rules.md`,
read-only via grep/sed — confirms the project TD grammar has no bare-`n/a`
placeholder convention to preserve). No pack-only references added to any
client-shipped surface. No boundary-discipline stop required.

---

## Verification evidence (full CI battery, FOREGROUND, at the edited tree)

Syntax: `bash -n` on all 7 edited shell files → `SYNTAX-OK`.

Changed suites:

| Suite | Result |
|---|---|
| `tracker-migrate-forward-test.sh` | **183 passed / 0 failed** (was 182; +1 net after the two new asserts — see 4.2 note) |
| `tracker-migrate-reverse-test.sh` | **147 passed / 0 failed** (incl. all 8 new 2.1f legs) |
| `tracker-migrate-roundtrip-test.sh` | **70 passed / 0 failed** (incl. all 19 Group-6 legs) |
| `test-tracker-links.sh` | **43 passed / 0 failed** (4.1 byte-identity restored via fixture canonicalization; was 42/1 mid-implementation) |
| `tracker-bd204-lossless-roundtrip-test.sh` (no env) | `SKIP: live-GH oracle (…)`, rc=0 — default-SKIP guard intact |

Full unattended battery from `.github/workflows/validate-pack.yml` (every
step run locally, foreground, rc=0 each):
`test-detect` (100/0), `tracker-provider-test`, `tracker-config-test`,
`tracker-init-test`, `tracker-agent-read-test`, `test-tracker-phase-task`,
`test-tracker-cycle-check`, `tracker-errors-test`,
`tracker-config-schema-test`, `recommendation-state-schema-test`,
`test-per-entry`, per-check suites 32-34 / 36-38 / 39 / 40 / 41 / 18 / 16 /
19 / 42 / 43 / 44 / 45 / 46 / removed-doc-advisory / 49-field-faithfulness,
`tracker-bd129/130/132/133/134`, `recommendation-test`, `pack-help-test`,
`test-customization-preserve`, `test-init-project`,
`test-migrate-v10-to-v11` (+ dry-run, gates, decompose),
`test-migrator-core` (19/0), `test-migrator-manifest` (12/0),
`test-migrator-capability-translation` (12/0),
`test-fixtures/build.sh --all --clean` (rc=0) + `--verify` (all 6 rows OK),
`test-v11-realistic-ot` (rc=0), `test-migrator-skills` (19/0),
`test-persona-contracts` (37/0), `template-translations-test`,
`template-version-test`, `test-issue-forms`.
Off-CI but parser-adjacent: `test-tracker-promote-direct/path1/path2` — rc=0.

Validators:
- `python3 scripts/validate-pack.py` → `PASSED — all checks clean`
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → `PASSED — all checks clean`

Manifest (regenerate-manifest-v11-surface — `scripts/` touched → trigger
fired): `bash test-fixtures/build.sh --all --clean` rc=0, then
`git diff test-fixtures/manifest.txt` → **EMPTY** and
`git status --porcelain test-fixtures/` → empty. Per the trinity RC9 rule
the empty post-rebuild diff is the canonical authority: these tracker-lib /
test edits are not fixture-affecting content, so no manifest staging is
needed. `--verify` confirms all six rows unchanged.

---

## Plan deviations

1. **`assert_not_contains` → grep idiom in forward-test** (correction
   during verification, not a deviation from the defect plan): the forward
   suite has no such helper; the first attempt silently no-opped
   (`command not found` on stderr, no FAIL increment). Rewritten with the
   suite's own 2.5 grep idiom; assertion now prints and PASSes.
2. **Knock-on fixture edit** (`BACKLOG-phase-task-blockers.md`, 1 line):
   forced by the Defect-C parser fix — links-test 4.1's byte-identity leg
   pinned the non-canonical placeholder. Canonicalizing the fixture (rather
   than narrowing the parser rule to the `Resolved:` header only) was
   chosen because (a) the emitter's own else-branch defines `Resolved: n/a`
   as the empty-resolution serialization, (b) the old behavior byte-morphed
   every real `Resolved: n/a` entry on monolith emit, and (c) `Resolution:
   n/a` appears in no PARSED content outside test fixtures (its one
   non-test occurrence, `scripts/pack-td.sh:259`, is unparsed advisory
   prose in a stderr heredoc — see the Optional-H2 audit note above).

Zero deviations otherwise: no oracle legs beyond Defect A touched, no
tracker-edit.sh changes (its caller-supplied-fields contract is correct
once the parser projects n/a as empty), no error-string classification,
no live GitHub calls, no git state changes.

## New POQs introduced

- **POQ-1 (pre-existing, surfaced not fixed — out of scope):**
  `scripts/tests/tracker-migrate-forward-test.sh:519` emits
  `line 519: issue: command not found` on every run. Cause: the Group-3
  fake-gh is an UNQUOTED heredoc and the BD-132 F-7 comment inside it
  contains backticks spanning lines 535-536 (`` `issue list --state … ` ``),
  which bash executes as command substitution at heredoc expansion.
  Harmless (comment text only; suite passes 183/0) and present at HEAD
  `451f20f` (verified: my diff touches only lines ~119 and ~825+; the
  heredoc region is byte-identical). Disposition: report to Pack Chat for
  a trivial follow-up (escape the backticks or quote the heredoc comment).
- **POQ-2 (note, no action for v11.0):** issues composed PRE-fix carry the
  phantom `## Resolution\n\nn/a` H2; the fixed comparator would flag them
  as divergent on reverse (exp `""` vs stored `"n/a"`). No such issues
  exist outside archived throwaway scratch repos (v11.0 unlaunched; run-4
  rehearsal provisions a fresh scratch repo and composes post-fix), so no
  migration shim is warranted. Recorded so a future reader of an old
  scratch artifact isn't surprised.

## Definition of Done

| Item | Status |
|---|---|
| Defect A: needle matches GH's actual `<code class="notranslate">` rendering | **PASS** (`<code` prefix; comment cites live evidence) |
| Defect A: empty-fetch guard added; default-SKIP guard still first | **PASS** (guard verified: SKIP + rc=0 with env unset) |
| Defect B: root-cause identified incl. the store question | **PASS** (provider non-idempotent mutation; store is write-side-idempotent cycle-check view, never a create-dedup — documented in-code) |
| Defect B: offline-verifiable fix, no error-string classification | **PASS** (read-before-write via existing `Issue.blockedBy` shape; best-effort read) |
| Defect B: mock legs reproduce re-run topology + pin no-re-attempt | **PASS** (roundtrip Group 6.2/6.4 + duplicate-edge sentinel; old-provider teeth proof rc=1) |
| Defect C: canonical side determined with evidence; all three actors agree on n/a/empty | **PASS** (parser normalization; composer/comparator/edit now mechanically consistent) |
| Defect C: blob verbatim, comparator fail-loud, no per-field carve-outs | **PASS** (2.1f raw_body byte-faithful; 2.1f-ii real edit still flags; single-point parse fix, no comparator carve-out) |
| Defect C: File/Symbol + Context n/a-rule audited | **PASS** (no bare-n/a convention; content-bearing `n/a — …` untouched, empirically verified) |
| Defect C: mock legs — n/a + status-flip + reverse no-flag; real edit flags; 3 cascade failures clear | **PASS** (reverse-test 2.1f/2.1f-ii; roundtrip 6.3: BD-009 appears, count 4, Deferred round-trips) |
| Full CI battery green (verify-full-ci-suite) | **PASS** (every workflow step + DEEP validate, foreground, rc=0) |
| Manifest regen run; diff checked | **PASS** (rebuilt `--all --clean`; diff EMPTY → no staging needed; `--verify` OK) |
| pack-only scope | **PASS** (8 files, all `scripts/**`; + this report under `maintenance-docs/`) |
| No git state changes; no live GH calls | **PASS** (read-only git verbs only; all verification mock/offline) |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git verbs run this session: `git rev-parse HEAD`, `git status`, `git diff`, `git show HEAD:…` (teeth proofs). End-state `git status --porcelain` shows 8 modified working-tree files + this report; no add/commit/push/tag/stash/reset/restore/checkout invoked. | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops: no `rm -rf` on repo paths (only `/tmp/bd204-teeth` scratch I created + test-internal mktemp dirs), no `git rm`, no trusted-file overwrites (all edits targeted Edit calls). | COMPLIANT |
| preflight-stop-means-stop | Emitted before this Write: `PREFLIGHT: 8/8 in-scope file edits complete; verification PASS; HEAD 451f20f4e4d665498aeb9101885fadb2ee503b5a; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-RUN3-FIXES.md`. No parent stop message received. | COMPLIANT |
| agent-output-rules-applied-block | This table; per `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (read lines 196-235 this session); every row carries quoted evidence. | COMPLIANT |
| agents-read-rule-docs-in-full | Read IN FULL with line counts: `CLAUDE.md` (579 lines, full file incl. `## Pack memory`, verbatim in session context), `/tmp/bd204-rehearsal-run3.log` (137 lines, Read tool), `feedback_verify_full_ci_suite.md` (43 lines), `feedback_edit_in_place_not_full_rewrite.md` (15 lines), `feedback_manifest_regen_on_v11_surface.md` (16 lines), `feedback_agent_output_rules_applied_block.md` (15 lines) — all via Read tool, complete. Conditional MUST-READs honored: PACK-MEMORY-RATIONALE.md §§ rules-applied-verification-block + regenerate-manifest-v11-surface. Named code sections read: tracker-links.sh (full, 355 lines), tracker-edit.sh (full, 347), tracker-cycle-check.sh store/detector, tmf_compose_issue_body, tracker_migrate_forward_run create/link/summary, _tmr_check_blob_h2_divergence + reconstruct + _tmr_fetch_first_class_blocked_by, oracle KU-OPS-6 + CRUD legs (full file, 784 lines). | COMPLIANT |
| verify-full-ci-suite | `python3 scripts/validate-pack.py` → "PASSED — all checks clean"; `PACK_VALIDATE_DEEP=1` variant → same; EVERY `.github/workflows/validate-pack.yml` tests-job step run locally in FOREGROUND (counts in § Verification evidence — e.g. forward 183/0, reverse 147/0, roundtrip 70/0, links 43/0, detect 100/0, realistic-ot rc=0, fixtures build+verify rc=0). Live oracle stays default-SKIP (verified: SKIP line + rc=0; my Defect-A edit is below the untouched guard). | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/` touched → ran `bash test-fixtures/build.sh --all --clean` (rc=0, "manifest written"); `git diff test-fixtures/manifest.txt` → EMPTY (and `git status --porcelain test-fixtures/` empty); per RC9 the empty post-rebuild diff is canonical → no manifest staging needed; `--verify` confirms all 6 rows OK. | COMPLIANT |
| edit-in-place-not-full-rewrite | All 10 file changes were targeted Edit calls (one Write only for THIS new report + one Edit append); edited regions re-read via full `git diff` review (lib/oracle/fixture hunks reviewed line-by-line; test hunks scanned — only intended regions appear: `git diff … \| grep ^@@` shows exactly the planned hunks); untouched text byte-stable by Edit-tool construction + diff inspection. | COMPLIANT |
| pack-only | End-state `git status --porcelain`: 8 modified files all under `scripts/` + this report under `maintenance-docs/v11-implementation/`; zero `project-template/` / `supporting-docs/` / PM-only paths. | COMPLIANT |
| scope-deliverables-to-the-ask | Exactly defects A/B/C + their coverage; the two knock-ons (fixture canonicalization, forward-test helper idiom) are forced by the in-scope fixes and documented under Plan deviations; the out-of-scope discovery (heredoc-backtick noise) is surfaced as POQ-1, NOT silently fixed. | COMPLIANT |

