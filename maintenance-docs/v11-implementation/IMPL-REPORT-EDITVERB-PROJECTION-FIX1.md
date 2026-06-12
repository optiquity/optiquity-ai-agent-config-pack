# IMPL-REPORT — BD-204 edit-verb projection fix, fix-coder pass 2 (FINAL)

**Date:** 2026-06-12
**Branch:** v11-dev — HEAD `6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6` (unchanged
throughout; read-only git only).
**Scope:** reviewer pass-1 findings F1 (guard half), F2, F4, F5 from
`maintenance-docs/v11-implementation/PACK-REVIEW-EDITVERB-PROJECTION.md`,
applied to the SAME 2 uncommitted files as the projection fix:
`scripts/lib/tracker-edit.sh` + `scripts/tests/tracker-provider-test.sh`.
F3 and F1's full merge-edit UX are the user-approved new BD's scope —
NOT touched here (see §6).

## 1. Files changed

| Path | Type | Delta vs HEAD (pass-1 + pass-2 combined) |
|---|---|---|
| `scripts/lib/tracker-edit.sh` | modified | +159/−2 (pass 1 was +57/−0; pass 2 adds the 3 guard/normalization code blocks + doc updates) |
| `scripts/tests/tracker-provider-test.sh` | modified | +210/−0 (pass 1 was +66/−0; pass 2 adds legs 4.7e–4.7i) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-EDITVERB-PROJECTION-FIX1.md` | new | this report |

No other file touched. `git status --porcelain` after all work: the same
2 ` M` files + the pre-existing `??` maintenance docs (+ this report).

## 2. Per-finding before/after

### F1 (MUST, guard half) — projection-only edit refuses on a blob-carrying issue

- **Before:** a patch with content fields (description / context /
  resolution / file_symbol) but NO raw_body entered the `has_content`
  branch, recomposed via the composer's empty-raw_body branch (no
  `pack-entry-body-gz64` marker emitted), and `provider_update` REPLACED
  the issue body — silently destroying the existing blob (review probe P5).
- **After:** `scripts/lib/tracker-edit.sh:400-431` — when `ed_raw_body`
  is empty, the guard reads the CURRENT issue body via `provider_get`
  (the existing provider abstraction; no raw `gh`):
  - `provider_get` fails → typed `validation` refusal ("cannot read the
    current issue body … to verify it carries no pack-entry-body-gz64
    blob"; actionable: `--raw-body-file` or re-run). Fail-safe: never
    proceeds blind.
  - current body carries `pack-entry-body-gz64` → typed `validation`
    refusal naming the constraint: "recomposing from projection fields
    alone would silently destroy it; supply the FULL updated entry span
    via --raw-body-file (projection-field merge-edit is the follow-up
    merge-edit BD's scope)". rc=1, NO provider write dispatched.
  - blob-less current body → proceeds (nothing to destroy; pre-existing
    legacy behavior preserved).
- **Status/label-only patches keep working — verified in code and pinned:**
  `has_content` (`tracker-edit.sh:336-340`) tests ONLY the five content
  keys; `status` / `old_status` / `title` / `add_labels` / `remove_labels`
  / `body` never enter the recompose branch, so the guard is unreachable
  for them and the update payload carries no `body` key (existing issue
  body, blob included, untouched). Pinned by new leg 4.7i.
- The merge-edit deferral carries the typed comment format per pack
  memory `pack-repo-code-comment-deferrals`:
  `# TODO(tracker): TD-TBD — merge-edit for projection-only patches …`
  (`tracker-edit.sh:412-415`), anchored to the user-approved new BD.

### F2 (SHOULD) — single-entry + id-match guards on the raw_body parse

- **Before:** the derivation block derived from `.[0]` with no shape
  gates: a `**BD-002 — …**`-headed raw_body submitted for BD-001
  dispatched rc=0 and stored a wrong-id blob (review probe P8); a
  multi-entry raw_body rode both spans into the blob.
- **After:** `scripts/lib/tracker-edit.sh:451-472` — inside the
  parsed-successfully branch, the SAME two gates `cmd_new_entry`
  enforces on the same grammar (`scripts/pack-tracker.sh:462-474`),
  with mirrored error wording:
  - parsed length ≠ 1 → typed `validation`: "raw_body must contain
    exactly ONE entry span (parsed N) — first line must be the
    \`**<pack-id> — <Title>**\` bold header".
  - `.[0].pack_id` ≠ target → typed `validation`: "edit target
    <pack-id> does not match the raw_body's bold-header ID <parsed-id>".
  Both refuse BEFORE any provider op.
- **Layering choice:** guards live in `tracker_edit_entry` (lib), not
  `cmd_edit` — matching WHERE THE PARSE HAPPENS, which is how new-entry
  does it (cmd_new_entry both parses and gates; the edit path parses in
  the lib, so it gates in the lib). The reviewer's F2 sizing ("~8 lines
  in the exact block touched; `_ted_parsed` already holds the values")
  presumed this placement. Unparseable raw_body behavior is unchanged
  (derives nothing; comparator skips unparseable blobs — pre-existing,
  documented branch).

### F4 (NIT) — explicit bare-`n/a` resolution through the parser's seam

- **Before:** explicit `resolution:"n/a"` was non-empty → overrode →
  composer emitted a phantom `## Resolution` H2 while the comparator
  (re-parsing the blob through the parser's n/a→empty rule) expected
  NONE → guaranteed divergence even when the input textually agreed
  with the raw_body (review probe P7).
- **After:** `scripts/lib/tracker-edit.sh:360-378` — immediately after
  the `ed_*` extraction, a bare (trimmed, case-insensitive) `n/a`
  explicit resolution normalizes to `""`, exactly mirroring the
  parser's `res.strip().lower() == "n/a"` rule (flush_entry in
  `_tmf_parse_backlog_file`, forward lib lines 477-498). One seam, no
  divergence-by-override: normalized-empty then behaves as absent, so
  with raw_body present it derives from the parse (which applies the
  SAME rule to the `Resolved:` line — the two sources agree by
  construction). Bash impl: sed leading/trailing-`[[:space:]]` trim +
  `tr '[:upper:]' '[:lower:]'` (bash 3.2 / BSD-safe; multiline values
  cannot collapse to `n/a` so the per-line trim is faithful to the
  single-line placeholder convention). Placeholder-with-content values
  (`n/a — new dir`) and real resolutions are untouched — the equality
  test is against the bare token only, same scope audit as the parser.
- Doc: the `resolution` patch-key doc (`tracker-edit.sh:200-207`) now
  states the normalization and names the parser seam.

### F5 (NIT) — contract-comment accuracy with the F1 guard landed

- **Re-verified both flagged sites:**
  - Source-block comment (`tracker-edit.sh:57-62`, "the edit path is
    the producer that owns keeping the two views in sync"): now
    accurate as written — every content edit either regenerates both
    representations from one entry object (raw_body present) or is
    refused (projection-only against a blob-carrying issue) or has no
    blob to sync (blob-less issue, where only one representation
    exists). No overbreadth remains; left byte-unchanged.
  - §3.3a (i) restatement (`tracker-edit.sh:323-333`): appended the
    closing sentence "The projection-only guard below enforces the
    never-one-without-the-other claim on the one shape that could
    break it: content fields WITHOUT raw_body against a blob-carrying
    issue are refused fail-loud, never recomposed-by-destruction."
  - Function-doc raw_body key (`tracker-edit.sh:228-246`): new
    RAW-BODY GUARDS + PROJECTION-ONLY GUARD paragraphs document both
    new refusals and the status/label/title-only carve-out.
- No `KNOWN GAP` annotation needed (the reviewer's alternative applied
  only if F1 were anchored without the guard; the guard landed).

## 3. New test legs (Group 4, `scripts/tests/tracker-provider-test.sh`)

| Leg | Lines | Pins |
|---|---|---|
| 4.7e | 1114-1147 | F4: explicit `" N/A "` (trim + case-insensitivity) + raw_body `Resolved: n/a` → NO `## Resolution` H2; REAL `_tmr_check_blob_h2_divergence` comparator CLEAN (pre-fix DIVERGED) |
| 4.7f | 1149-1174 | F2 id-match: BD-002-headed raw_body for BD-001 → rc≠0, `ERROR: validation`, names both ids, NO provider op (stderr to tmp file, no command-substitution capture, so stub mutations would propagate if a write wrongly fired) |
| 4.7g | 1176-1193 | F2 single-entry: 2-span raw_body → rc≠0, `ERROR: validation`, "exactly ONE entry span (parsed 2)", NO provider op |
| 4.7h | 1195-1238 | F1: projection-only patch (canonical resolve shape `status:Resolved + resolution:…`) on a blob-carrying issue → rc≠0, `ERROR: validation`, names `pack-entry-body-gz64` + `--raw-body-file`, guard consulted `provider_get` (file-logged stub — the lib calls it in a subshell, so a variable stub would not propagate), NO provider write, update-payload canary `__UNTOUCHED__` intact (issue body unchanged in the fake's state) |
| 4.7i | 1240-1257 | F1 carve-out: status-only patch on the same blob-carrying issue still updates, NEVER calls provider_get (get-log empty), payload has NO `body` key |

## 4. Verification (all FOREGROUND; sandbox protocol)

All execution in `/tmp/fix2-edv` via ONE staged atomic script
(`/tmp/fix2-edv/run.sh`: build / subject / red / battery / clone /
oracle). Main tree never executed-in; written only at the 2 in-scope
files + this report. Sandbox = full repo copy excluding top-level
`/.git` (3891 files; fixture-internal `.git` build artifacts kept for
`--verify`).

### 4.1 Red-green (new legs have teeth)

- **RED:** reverted ONLY the three pass-2 CODE hunks (F4 normalization,
  F1 guard, F2 guards) in a sandbox copy via anchored-regex python
  revert (asserted applied), kept the new test legs → suite rc=1,
  **221 PASS / 17 FAIL**, and the 17 FAILs are EXACTLY the new
  4.7e (2) / 4.7f (4) / 4.7g (4) / 4.7h (7) assertions — nothing else
  red; 4.7i passes red (status-only worked pre-fix, as the carve-out
  claims).
- **GREEN:** working-tree files → rc=0, **238 PASS / 0 FAIL**,
  "All tests passed." (218 pre-pass-2 + 20 new assertions).

### 4.2 Full CI `tests`-job battery

- **Sandbox legs (46 PASS / 0 FAIL):** subject suite 238/0;
  `validate-pack.py` and `PACK_VALIDATE_DEEP=1` both "PASSED — all
  checks clean"; tracker-config / init / agent-read /
  migrate-forward / migrate-reverse / roundtrip / phase-task / links /
  cycle-check / errors / config-schema; recommendation-state-schema;
  test-per-entry; all 15 per-check validator suites (32-33-34,
  36-37-38, 39, 40, 41, 18, 16, 19, 42, 43, 44, 45, 46,
  removed-doc-advisory, 49-field-faithfulness); bd129 / bd130 / bd132 /
  bd133 / bd134; recommendation; pack-help; customization-preserve;
  template-translations; template-version; issue-forms;
  test-v11-realistic-ot; migrator-capability-translation;
  migrator-skills; fixture `--verify`.
- **Isolated-clone legs (12 PASS / 0 FAIL):** `git clone file://<repo>`
  (read-only on source) → `checkout v11-dev` inside the clone → overlay
  the 2 edited files (`cmp`-verified byte-exact) → v10-tag present +
  no `tracker.toml` leak verified → detect; init-project;
  migrate-v10-to-v11 ×4 (main / dry-run / gates / decompose);
  migrator-core; migrator-manifest; persona-contracts (3/3 — re-run
  after fixture build per CI ordering, see deviation D2);
  fixture build `--all --clean`; fixture `--verify`.
- **detect** runs in the clone, not the sandbox: its "real pack root →
  valid" leg asserts the pack root IS a git repo (`pack-path:
  not-a-repo` in the stripped sandbox by construction) — same
  repo-git-dependent classification pass 1 used.
- **Live oracle** `tracker-bd204-lossless-roundtrip-test.sh`:
  default-SKIP, rc=0 — "SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1
  + gh auth to run)". No live GitHub call made anywhere in this session.
- **Total: 58 distinct legs, 0 functional failures.**

### 4.3 Manifest (rule 7)

`scripts/` is v11-surface → rebuild mandatory. Ran
`bash test-fixtures/build.sh --all --clean` in the isolated clone
(content `cmp`-equal to the working tree for the 2 edited files) →
`git -C clone diff -- test-fixtures/manifest.txt` = **0 lines** (and
clone `--verify` passes all rows post-rebuild). Main-tree
`git diff test-fixtures/manifest.txt | wc -l` = **0**. Nothing to
stage — consistent with pass 1's finding (neither edited file is
client-installed; fixture `scripts/lib/` carries only `detect.sh`).

## 5. Plan deviations

- **D1 — provider_get-based guard (design-completing, per the prompt's
  own wording):** the prompt's F1 frames the refusal as "against an
  issue whose current body carries a `pack-entry-body-gz64` blob" with
  the body "UNCHANGED in the fake's state" — that requires reading the
  current body, so the guard calls `provider_get` (tracker-agnostic
  provider op; read-only; subshell-captured). The reviewer's sketch
  ("refuse whenever ed_raw_body is empty, optionally scoped by id
  regex") is strictly broader; the implemented check is precise (blob
  present → refuse; blob-less → legacy behavior preserved) and
  fail-safe (unreadable body → refuse).
- **D2 — harness ordering, not code:** my clone stage initially ran
  persona-contracts BEFORE the fixture build; CI builds fixtures first
  (workflow line 259 vs 287). Re-ran after the build: 3/3 PASS.
  No repo file involved.
- **D3 — test-stub mechanics:** first 4.7h draft logged provider_get
  calls into a shell variable; the lib invokes provider_get inside a
  command substitution (subshell), so the stub logs to a file instead
  (commented in the test). One sandbox iteration; final suite green.
- No other deviations: F2 wording mirrors new-entry's; F4 matches the
  parser's exact rule; F5 left the accurate 57-62 comment byte-stable.

## 6. New POQs / out-of-scope notes

- **No new POQs found** during implementation or verification.
- The user-approved merge-edit BD (F1 full UX + F3 status projection)
  is referenced from the guard's typed deferral comment
  (`TODO(tracker): TD-TBD —`, `tracker-edit.sh:412`) and the refusal
  message; Pack Chat may substitute the real BD number when the entry
  opens — not done here (BD numbering is Pack-Chat-only).
- **NIT for the merge-edit BD (not fixed — out of the F1/F2/F4/F5
  ask):** the `edit` verb's `usage()` text in `scripts/pack-tracker.sh`
  does not yet mention that content flags without `--raw-body-file`
  refuse on blob-carrying issues. The lib's typed error is the
  actionable surface; the help-text note folds naturally into the
  merge-edit BD that will rewrite those semantics anyway.

## 7. Definition of Done

| Item | Result |
|---|---|
| F1 guard half: projection-only on blob-carrying issue → typed validation refusal, rc≠0, body unchanged | PASS (legs 4.7h; code `tracker-edit.sh:400-431`) |
| F1: status/label-only patches keep working, verified in code + pinned | PASS (code trace §2-F1; leg 4.7i) |
| F2: single-entry + id-match guards matching cmd_new_entry, typed errors | PASS (code `tracker-edit.sh:451-472`; legs 4.7f/4.7g) |
| F2 mandated leg: BD-002-headed raw_body for BD-001 → typed error | PASS (leg 4.7f) |
| F4: explicit overrides share the parser's n/a seam; 4.7e leg added | PASS (code `tracker-edit.sh:360-378`; leg 4.7e incl. real-comparator CLEAN) |
| F5: contract comments re-verified / adjusted | PASS (§2-F5) |
| Red-green: new legs fail on pre-fix code | PASS (RED 17 fails, all new legs) |
| Full CI battery + validate-pack(+DEEP), foreground | PASS (58 legs, 0 failures; §4.2) |
| Live oracle default-SKIP | PASS (rc=0, SKIP banner) |
| Manifest rebuilt + diff checked | PASS (0-line diff; §4.3) |
| No git state changes; main tree limited to in-scope files + report | PASS (§4 + Rules block) |
| Bash 3.2 / BSD compatibility of new shell code | PASS (no bash-4 features; `tr`/`sed` POSIX classes; `[[ ]]` substring globs) |

## 8. Boundary discipline check

No project-side surface touched: the diff is exactly
`scripts/lib/tracker-edit.sh` + `scripts/tests/tracker-provider-test.sh`
(pack-side) + this report under `maintenance-docs/`. No
`project-template/`, no `supporting-docs/`. No pack-only reference was
added to any client-shipped file. SSOT investigation: N/A — no
project-side concept changed.

## 9. Read-in-full attestation (agents-read-rule-docs-in-full)

| File | Lines | Read |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` § Pack memory | 590-line file; §140-590 read from disk this session | IN FULL (on-disk version) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-EDITVERB-PROJECTION.md` | 286 | IN FULL |
| `scripts/lib/tracker-edit.sh` (pre-edit state) | 469 | IN FULL (post-edit: 567 lines; every edit tracked) |
| `~/.claude/.../memory/feedback_edit_in_place_not_full_rewrite.md` | 15 | IN FULL |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | 43 | IN FULL |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | 15 | IN FULL (+ mandated follow-up: `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block, lines 206-233) |
| Section reads | — | `cmd_edit` + `cmd_new_entry` guards (`pack-tracker.sh:240-520` + usage 74-140); n/a normalization (`tracker-migrate-forward.sh:460-519`); blob marker emit/detect (forward 1110/1228, reverse 684-707); `provider_get` shape (`tracker-provider-gh.sh:340-350`, `tracker-agent-read.sh:118-147`); Group-4 fake-gh harness + new legs (`tracker-provider-test.sh:880-1463` pre-edit) |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git verbs ran against the main tree: `rev-parse HEAD`, `status --porcelain`, `diff`/`diff --stat`, `branch --show-current`, plus `git clone file://<repo>` (read-only on source; target `/tmp/fix2-edv/clone`) and `checkout v11-dev` / `tag -l` / `diff` INSIDE the clone only. Final main-tree check: HEAD `6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6` unchanged; `git status --porcelain` = the same 2 ` M` files + pre-existing `??` docs (+ this report). No add/commit/push/tag/stash/reset/restore/checkout on the main tree. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op on repo files; `rm -rf` confined to self-created `/tmp/fix2-edv/*` (script-internal sandbox/red/clone rebuilds) and test-internal `mktemp` scratch. GitHub MCP tools available mid-session were NEVER invoked; zero live GH calls (oracle log: "SKIP: live-GH oracle"). No parent stop message received. | COMPLIANT |
| preflight-stop-means-stop | Emitted verbatim immediately before this report's Write: "PREFLIGHT: 4/4 fixes complete; verification PASS; HEAD 6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-EDITVERB-PROJECTION-FIX1.md". All edits + verification were green BEFORE the line. No stop/halt/revert message at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table, in the fenced per-rule format mandated by `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206-233, read this session): `Rule \| Verification evidence \| Conclusion`. Every row carries quoted non-empty evidence; no AMBIGUOUS terminal state. | COMPLIANT |
| agents-read-rule-docs-in-full | §9 attestation: all 6 mandated docs read in full with line counts (590 / 286 / 469 / 15 / 43 / 15) + the mandated section reads with line ranges. CLAUDE.md Pack memory read from DISK (lines 140-590), not relied on from session context. | COMPLIANT |
| verify-full-ci-suite | Ran by me, all FOREGROUND: `validate-pack.py` + `PACK_VALIDATE_DEEP=1` both "PASSED — all checks clean"; full CI tests-job battery **58 legs / 0 functional failures** = 46 `.git`-stripped-sandbox legs (incl. subject suite 238 PASS / 0 FAIL, test-v11-realistic-ot, all 13 tracker suites, all 15 per-check suites, fixture `--verify`) + 12 isolated-clone legs (all 9 repo-git-dependent suites incl. detect + persona-contracts 3/3 + fixture build/verify). Live oracle default-SKIP rc=0. Red-green: RED 221/17 (all 17 = new legs), GREEN 238/0. detect's sandbox run fails structurally (`pack-path: not-a-repo` — no `.git` by construction) and is covered by the clone PASS, same classification as pass 1. | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/` touched → rebuild ran: `bash test-fixtures/build.sh --all --clean` in the isolated clone (edited files `cmp`-verified equal to working tree) → `git -C clone diff -- test-fixtures/manifest.txt` = 0 lines; clone `--verify` PASS post-rebuild; main-tree `git diff test-fixtures/manifest.txt \| wc -l` = 0. Nothing to stage. | COMPLIANT |
| edit-in-place-not-full-rewrite | All changes via targeted Edit calls (6 on the lib incl. 3 test-leg-set edits on the test file; 0 full-file Writes on repo files). `git diff --stat` = "2 files changed, 367 insertions(+), 2 deletions(-)" — the 2 deletions are the two doc lines REPLACED by their expanded versions (resolution-key doc, raw_body GUARDS doc); all other pre-existing text byte-stable. Output re-read via the post-edit grep anchor sweep (§ line-anchor table) and the green suite. | COMPLIANT |
| pack-only | `git status --porcelain` = ` M scripts/lib/tracker-edit.sh`, ` M scripts/tests/tracker-provider-test.sh` + `??` docs under `maintenance-docs/` only. No `project-template/`, no `supporting-docs/` → Check-36 `pack-only` semantics hold. Zero phase refs introduced (new text mentions no project-side concept). | COMPLIANT |
| scope-deliverables-to-the-ask | Deliverables = exactly F1-guard / F2 / F4 / F5 + their test legs + this report. F3 untouched (no status-projection code added); merge-edit UX untouched (guard refuses; typed `TODO(tracker): TD-TBD` defers to the user-approved BD). The one adjacent observation (usage-text nit) is REPORTED (§6), not implemented. | COMPLIANT |
