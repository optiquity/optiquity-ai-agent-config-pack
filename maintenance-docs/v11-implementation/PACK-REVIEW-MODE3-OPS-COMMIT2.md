# PACK-REVIEW-MODE3-OPS-COMMIT2 — BD-204 Mode-3 ops contract, Commit 2 (code/verbs/validation), reviewer pass 1

> **Agent:** pack-reviewer (fresh instance). **Date:** 2026-06-12 session.
> **Branch:** `v11-dev`. **Base HEAD (expected, verified at session start):**
> `358310e4e3586fd94d838e0097954c804638f530`.
> **HEAD at report time:** `de1e948` — moved by a REVIEWER-CAUSED probe
> commit, NOT by the change under review. See § INCIDENT (read first).
> **Scope:** the ENTIRE uncommitted change (26 modified files vs `358310e`)
> + `IMPL-REPORT-MODE3-OPS-COMMIT2.md` disclosures.
> **Authorities applied (later wins):** PLAN-BD-204-MODE3-OPS-CONTRACT.md →
> ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md →
> ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md (NORMATIVE, §B8 D2).
> ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md is SUPERSEDED (absence
> verified, §7). Prior-review exposure limited to
> PACK-REVIEW-MODE3-OPS-COMMIT1-REVIEW3.md §9 (NIT-1/NIT-2/ADVISORY-1 only).
> **No live GitHub calls by this reviewer:** zero real `gh` invocations, zero
> GitHub MCP calls; all `gh` executions in test runs hit fake/exploding stubs
> (probe logs quoted in §6.4).

---

## INCIDENT — reviewer-caused stray local commit (remediation required BEFORE the commit gate)

**What happened.** For the prompted Check 29″ red-probe ("probe a simulated
tracked tracker.toml in an isolated copy") I created an "isolated copy" via
`cp -R . /tmp/c29probe` and ran `git add -f tracker.toml && git commit` inside
it. This repo directory is a **linked git worktree** — its `.git` is a POINTER
FILE (`gitdir: /Users/david/Developer/optiquity-ai-agent-config-pack/.git/worktrees/optiquity-ai-agent-config-pack-v11-dev`),
which `cp -R` copied verbatim. The "isolated" copy therefore shared the REAL
repository's gitdir, and the probe commit landed on the real `v11-dev` branch:

```
de1e948 probe: tracked tracker.toml   (Author: probe <probe@x>)
  tracker.toml | 23 +++++++++++++++++  (1 file changed)
```

**Damage scope (verified read-only, evidence quoted):**

- ONE stray local commit `de1e948` on `v11-dev`, containing only
  `tracker.toml` (23 lines, byte-identical to the live on-disk file —
  `git show de1e948:tracker.toml | wc -l` → 23; `wc -l tracker.toml` → 23).
- **NOT pushed** — `git log origin/v11-dev..HEAD --oneline` → only `de1e948`.
- The 26-file change under review is **fully intact**: `git diff --name-only
  HEAD | wc -l` → 26 (same set as at `358310e`); index clean
  (`git diff --cached --stat | wc -l` → 0); no staged residue.
- Worktree metadata intact: the gitdir backpointer still reads
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.git`.
- The live `tracker.toml` FILE BYTES are untouched (23 lines before/after);
  `.pack-tracker/` untouched. The sabotage/hermeticity probes touched only
  real file copies in `/tmp` (`grep -c SABOTAGE scripts/lib/tracker-migrate-reverse.sh` → 0).
- All green verification results in §5 were captured BEFORE the incident;
  the incident does not alter the working tree or the change's content.

**Why this is a rules violation.** `agents-never-commit` forbids state-changing
git verbs. I believed the probe targeted a self-provisioned scratch copy (the
sanctioned `/tmp`-clone pattern); the worktree pointer file defeated the
isolation. The violation is recorded as VIOLATED in the Rules-Applied block.
I performed NO remediation (reset/restore are also forbidden verbs).

**Remediation recipe (Pack Chat, with user approval, BEFORE staging Commit 2):**

```
git reset --mixed 358310e4e3586fd94d838e0097954c804638f530
```

This moves `v11-dev` back to the intended base; the working tree is untouched;
`tracker.toml` returns to untracked and is immediately covered by the new
root-anchored `/tracker.toml` ignore in the working-tree `.gitignore`. After
the reset, Check 29″ returns green (proven: it passed against the untracked
state in the pre-incident full runs, §5).

**Lesson for pack memory (suggested):** "isolated copy" probes of a linked
WORKTREE must use `git clone` (which creates a self-contained `.git`), never
`cp -R` (which copies the gitdir pointer). My own later baseline probe used
`git clone --no-hardlinks` and was correctly isolated.

---

## VERDICT: **APPROVE-WITH-FIXES**

The change itself is correct, contract-faithful, and fully green (validate ×2 +
52/52 suites + fixture verify, all foreground). One MUST (stale README verb
enumeration) and two SHOULDs. Separately, the INCIDENT above requires the
Pack-Chat reset before the commit gate — it is reviewer-caused, not a defect
of the change.

| # | Severity | Finding | Anchor |
|---|---|---|---|
| MUST-1 | MUST | README layout row's `pack-tracker.sh` verb list omits the three new verbs | `README.md:197` |
| SHOULD-1 | SHOULD | Doctor leg (h) `provider_list … 100` truncates against 213 live entries (no id-map union like the roster) | `scripts/lib/tracker-doctor.sh:341` |
| SHOULD-2 | SHOULD | Pack emit-phase failure (flip=0) still stamps `last_tree_regen`, prints `tree-rebuild: complete.`, returns rc=0 | `scripts/lib/tracker-migrate-reverse.sh` step 9 |
| NIT-1 | NIT | Pre-existing: 7 unwrapped read-only `gh repo view` calls in the reverse suite (count unchanged vs baseline) | `scripts/lib/tracker-migrate-reverse.sh:428` |

---

## 1. What was reviewed (census)

`git diff HEAD` (base `358310e`): 26 files, +1,662/−82, matching the
IMPL-REPORT §13 inventory exactly. Every changed hunk was read: the three new
verbs + dispatch + usage in `scripts/pack-tracker.sh` (+356); the `tree_only`
engine arm, `_tmr_check_status_coherence`, `_tmr_update_tracker_toml` arg-3,
guard-message neutralization in `scripts/lib/tracker-migrate-reverse.sh`
(+156/−12); `tracker_edit_stamp_last_write` + success-only call site in
`scripts/lib/tracker-edit.sh` (+65); forward `mirror_only` message (+1/−1);
`scripts/tracker-migrate.sh` help (+4); doctor legs (d)/(h) (+115/−19);
`_gh_list_fields` + list-normalizer (+12/−1); Check 29″ + Check 32′ markers +
header docstrings in `scripts/validate-pack.py` (+78/−6); `.gitignore` (+5);
all 6 test suites; the 9 doc surfaces (trinity ×3, README, pack-startup ×3
copies, HELP-FRAGMENT-PACK/TRACKER, OPTIONAL-FEATURES,
tracker.toml.pack-example). Current-state context reads: emit/atomicity-gate
region, `_tmr_emit_pack_tree` write loop, `_tmr_decode_body_blob`,
`_tmr_decode_status`, `tracker_edit_entry` gating, roster build, provider
sourcing block in `pack-tracker.sh`, `_gh_normalize_issue`.

## 2. Verb correctness (success criterion 1)

- **`tree-rebuild` is genuinely no-flip / tree-only.** Traced: verb passes
  `tracker_migrate_reverse_run "$repo_root" 0 0 0 "$force" 1` (dry=0, flip=0,
  comments=0, tree_only=1). With `tree_only=1` the pack branch writes ONLY the
  per-entry tree via `_tmr_emit_pack_tree` (whose final action is
  `per_entry_regenerate_toc` — `_toc.md` coupled by construction) and SKIPS
  `_tmr_emit_implementation_plan` / `_tmr_emit_status` / both header strips
  (guarded `if [[ "$tree_only" != "1" ]]`). `_tmr_update_tracker_toml` flips
  `mode.state` only when arg-2 `flip=1`; the verb always passes 0. Tests 8.1
  assert mode unchanged + no root STATUS.md/IMPLEMENTATION-PLAN.md; my own
  `ls STATUS.md IMPLEMENTATION-PLAN.md` at pack root → both absent.
- **One-way overwrite is structural and the test has teeth.** The
  `_tmr_emit_pack_tree` write loop runs `pe_write_atomic "$dest"`
  unconditionally per entry (no skip-if-exists). **Revert-probe performed:**
  in a `/tmp` file-copy I inserted `[[ -f "$dest" ]] && continue  # SABOTAGE`
  after `dest=` and re-ran the suite → exactly the two 8.2 assertions failed
  ("sentinel survived" + byte-equality), 188/2. The leg detects the regression.
- **Gates fail loud:** flat-file refusal (typed validation, names the SSOT —
  leg 8.3); pack-surface-only ×2 seams — verb gate AND engine seam (PD-C),
  both naming BD-207 (leg 8.4, both asserted).
- **`edit` / `new-entry` are thin (OQ-4 clean).** `cmd_edit` is pure
  flag→patch-JSON mapping onto `tracker_edit_entry`'s documented keys
  (sentinel-guarded file reads preserve trailing newlines; empty-patch
  refusal; repeatable label flags via jq array append). The flat-file gate
  lives in the lib (`tracker_edit_entry` → `tracker_edit_mode` → returns 1
  typed in flat-file mode) — verified in current `tracker-edit.sh`.
  `cmd_new_entry` reuses the REAL forward grammar end-to-end:
  `_tmf_parse_backlog_file` (parse) → `tmf_compose_issue_body` (the single
  codec; size gate intact) → `_tmf_labels_for_entry` (forward label map) →
  `provider_create` → `tmf_mapping_set`/`tmf_mapping_save` →
  `tracker_edit_stamp_last_write` → the tree-rebuild engine path. NO new
  codec, NO raw `gh` (grep: zero direct `gh` invocations in the new verb
  bodies; all backend traffic is `provider_*`). Group 5 proves the byte-
  faithful round-trip (`cmp` lines 2..EOF vs input span), duplicate-id and
  shape/mismatch refusals, and the DP-3 close path (`issue close 77 --reason
  completed`). All required libs are sourced by `pack-tracker.sh` (verified
  sourcing block).
- **`mirror-rebuild` pack-surface retirement:** the forward `mirror_only` pack
  guard now names `pack tracker tree-rebuild` (leg 4.5 asserts); the CLIENT
  arm is byte-unchanged and regression-pinned (NEW leg 4.5b: rc=0, header
  refreshed, body preserved). `tracker-migrate.sh` help points reverse users
  at the verb.

## 3. Coherence comparator + freshness keys (success criteria 2–3)

- **Blocking at every materialization path.** `_tmr_check_status_coherence`
  is invoked inside `tracker_migrate_reverse_reconstruct` immediately after
  `_tmr_check_blob_h2_divergence`; BOTH the tree_only arm and the full
  reverse/disable path route every issue through reconstruct. A comparator
  failure feeds the `n_skipped` silent-data-loss guard, which aborts BEFORE
  any tree write and BEFORE the Step-9 stamp (leg 8.5 e2e asserts "no tree
  file written"; code path verified).
- **`--force` semantics match the body comparator:** blob-wins, WARNed never
  silent; the tree gets the blob's `Status:` because the emit writes
  `raw_body` verbatim (leg 8.5 e2e asserts `Status: Resolved` reaches the
  tree file). Skip conditions are field-faithful (no blob → skip; no
  `Status:` line → skip — matches `/backlog/_rules.md` § Entry contract's
  field-faithful clause).
- **No false positives on clean state (probed):** unit leg "matching
  blob/projection passes" + the 8.1 happy path (coherent fixture, rc=0) +
  the full reverse Groups 4/5 (idempotency) all green in my runs.
- **Doctor leg (h) is advisory-only:** WARN + rc=1, never mutates; INFO-skips
  in flat-file mode, when decoders/provider unsourced, and on provider
  failure (leg-(g) pattern). Legs 9.4/9.5 green. (Coverage truncation:
  SHOULD-1.)
- **Freshness keys.** `last_tracker_write` is stamped ONLY after the full
  mutation sequence (the call is the last statement before the success
  printf; every failure path returns earlier) — legs 4.9a/b/c prove
  success-stamps / failed-update-no-stamp / failed-boundary-cross-no-stamp.
  `last_tree_regen` rides `_tmr_update_tracker_toml` arg-3, passed 1 on every
  PACK materialization (tree_only AND full reverse/disable; client surface
  passes 0). Doctor leg (d) compares lexicographically (ISO-8601-Z sound),
  WARNs with the recovery verb, and INFO-tolerates absent keys (R4) — legs
  9.1–9.3 green; the live repo stays rc=0 pre-first-stamp. Dry-run exits at
  the pre-existing `dry_run == 1` branch BEFORE Step 9 — no dry-run stamping.
  (Emit-failure stamping: SHOULD-2.)

## 4. Check 29″ / Check 32′ / gitignore (success criterion 4)

- **Check 29″ red-green proven.** Green: pre-incident full `validate-pack.py`
  + DEEP both "PASSED — all checks clean" against the untracked live file.
  Red: my probe (the one that caused the INCIDENT) demonstrated the real
  validator failing `FAIL: tracker.toml is git-TRACKED at the pack root …
  git rm --cached tracker.toml` with overall rc=1. Per-check Test 18a/b/c
  legs (scratch self-provisioned git repos) green in my battery run.
- **Check 32′ asserts what Commit 1 actually landed.** `_RULES_MODE_MARKERS`
  strings match the COMMITTED docs exactly: `backlog/_rules.md:28` "**Flat-file
  mode (default).**", `:36` "**Tracker mode (`state = "tracker"` …**";
  `changelog/_rules.md:26` "**Mode invariance.**". Marker-presence only, no
  prose pinning; allowlist sized to exactly the two pack streams
  (`.get(stream_key, ())` leaves project streams unasserted — BD-206/207).
  Header docstring items 29 and 32 updated in lock-step. Red/green legs
  A7/A7b/F6 green.
- **Gitignore anchoring proven with my own probes:**
  `git check-ignore -v tracker.toml` → `.gitignore:17:/tracker.toml` (rc=0);
  the three fixture `tracker.toml` files → rc=1 (NOT ignored);
  `git ls-files | grep -c tracker.toml` → 5 (tracked set unchanged).
  Root-anchored as AMENDMENT-2 §B0 EE mandates; comment block carries the
  §B5-surface-6 user-facing text + anchoring rationale.

## 5. Verification battery (FOREGROUND, complete — all pre-incident)

- `python3 scripts/validate-pack.py` → **PASSED — all checks clean** (rc=0).
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **PASSED** (rc=0).
- **All 52 workflow `tests:`-job suites, workflow order, 52/52 rc=0** (4
  foreground chunks; per-suite line captured: reverse "All tests passed"
  [190/0 in probe run], provider/forward/config/init/agent-read/roundtrip/
  phase-task/links/cycle/errors all pass; schema PASS:40; per-entry PASS:57;
  checks-32 PASS:96; every `test-validate-pack-check-*` green; bd129 14/0,
  bd130 36/0, bd132 29/0, bd134 24/0; detect 100/0; init-project, all 4
  migrate-v10-to-v11 suites, migrator-core 19/0, manifest 12/0,
  capability-translation 12/0; integration `test-v11-realistic-ot.sh`
  **33/33**; migrator-skills 19/0; persona contracts PASS; template suites +
  issue-forms green).
- Fixture sequence: `build.sh --all --clean` rc=0 → manifest diff **0 lines**
  → `build.sh --verify` → **6/6 rows OK** (SHAs match the IMPL-REPORT §8
  values exactly: `19558cb…/4c62945…/ae3fc6f…/f9705c2…/944ddee…/a54e081…`).
- `bash -n` on all 13 edited shell files → clean; `ast.parse` on
  `validate-pack.py` → OK; `pack-tracker.sh -h` renders the 3 new verb rows.
- Live oracle: default-SKIP (not run). Zero real `gh` calls by this reviewer.

## 6. Coder disclosures (success criterion 6)

### 6.1 PD-A (`provider_list` gains `body`/`state_reason`) — VERIFIED

The architecture §3 layer-2 / §4.1 leg-(h) contract requires "labels + state
+ body in one paginated read — no per-issue provider_get sweep"; the
pre-change `_gh_list_fields` carried neither `body` nor `stateReason`, so the
claim "required by the architecture" is TRUE. Extension is additive and
correct: the GET field set (line 223) already carried `body,stateReason`
through the same `gh … --json` field vocabulary; the list normalizer's
`state_reason` lowercasing matches `_gh_normalize_issue` exactly (lines
263/328); existing consumers read `.id/.number/.labels` only. Mock parity:
fake-gh list payloads tolerate present/absent fields via `.get()` defaults
(legs 8.5/9.x include `body`+`stateReason` where needed; old mocks without
them normalize to `""`/null). Zero pins on the old field string
(`grep -rn "number,title,state,labels,milestone" scripts/` excl. provider →
0 hits).

### 6.2 PD-B (manifest empty diff) — VERIFIED BY INDEPENDENT REBUILD

I re-ran `bash test-fixtures/build.sh --all --clean` myself: rc=0,
`git diff test-fixtures/manifest.txt` → **0 lines**, `--verify` 6/6 OK. The
mechanism checks out: fixtures contain NO copy of any changed file
(`find test-fixtures -name pack-tracker.sh -o -name tracker-migrate-reverse.sh`
→ empty; fixture `scripts/` dirs come from `project-template/scripts/`); the
sanctioned pack-side-shipped set `{scripts/lib/detect.sh, scripts/pack-help.sh}`
is untouched; the client-copied TRACKER fragment is the project-template one,
not `pack-ops/`. The trigger fired, the rebuild ran, the canonical authority
(the post-rebuild diff) says nothing rides. Correct application of the
manifest rule's "if empty … no staging needed" arm.

### 6.3 PD-C (engine-seam BD-207 guard) — VERIFIED

Defensive double of the verb gate at the engine seam
(`tree_only==1 && surface!=pack` → typed fail naming BD-207) so a direct
engine call cannot over-emit on a client surface; the client branch's emit
code is untouched (confirmed in the diff — the client `else` arm is
unmodified). Both seams test-pinned (leg 8.4 + 8.4-engine). Sound deviation,
correctly disclosed.

### 6.4 POQ-2 (Group-6 hermeticity) — VERIFIED CLOSED, with one pre-existing residual

Probe: ran the full edited reverse suite with an exploding `gh` stub
(`exit 99`, logs every invocation) FIRST on PATH. Result: suite **green
(190/0)**; the leak log shows **ZERO `gh issue list` calls** — the POQ-2
exposure class (live list against `fixture-org/fixture-repo`) is eliminated
by the Group-6 fake-gh wrap. Residual: 7 × `gh repo view --json
nameWithOwner` reached the stub (origin `tracker-migrate-reverse.sh:428`,
read-only, `2>/dev/null ||` fallback-tolerated). Baseline check: a proper
`git clone --no-hardlinks` of the repo (pre-change code, 150 assertions)
leaks the SAME 7 calls — pre-existing, count unchanged by this diff (NIT-1).

### 6.5 POQ-3 (edit no-auto-rebuild vs new-entry auto-rebuild) — VERIFIED CONSISTENT

The documented contract is batch-cadence, not per-edit: `/backlog/_rules.md`
§ Write authority — "After any tracker write batch — and ALWAYS before
committing tree state — run `pack tracker tree-rebuild`" (line 147-148);
PACK-CHAT.md regen-cadence section likewise. NO doc promises that `edit`
materializes the tree; the `edit` usage text explicitly says "Run
`tree-rebuild` afterward". `new-entry`'s rebuild-finish is what its own usage
+ HELP row + the D2-1/PLAN recipe specify ("then runs the tree-rebuild
path"). Keep-as-is is the coherent default; no doc drift.

## 7. Hygiene sweeps (success criterion 7)

- **Superseded amendment content ABSENT:** `git diff | grep -c
  "tracker-id-map\|pack-ops/tracker-id-map"` → 0 (no resolver rename, no
  id-map relocation, no `!negation` carve-out; `.pack-tracker/` ignore intact).
- **Zero phase refs in added pack-side prose:** added-line grep excluding
  `scripts/lib` + `scripts/tests` → 0 hits; the 4 in-engine hits are the
  pre-existing "legacy/phase issues" idiom + re-indented engine lines
  (deliverable-construction surface — allowed class).
- **No line-number references in added text:** only the structural
  "lines 2..EOF" convention. Docstrings cite file + symbol throughout.
- **Old guard wording gone:** repo-wide grep → the only hit is the suite's
  own negative pin (8.6).
- **`pack-only` keyword clean (Check-36 simulation reproduced):**
  `git diff --name-only` (26 paths) ∩ deny set
  `{project-template/, supporting-docs/}` → **0**. The IMPL report is
  maintenance-docs (pack-side). Subject (§15 of IMPL-REPORT) carries the
  PLAN §3.3 keyword form.
- **Trinity parity (my own hashes):** added-hunk shasum CLAUDE == AGENTS
  (`8a85dbe695a4ab01645c549d89a4fd3c9aab7d5e` ×2); GEMINI
  (`9442e7f8…`) differs only via its pre-existing condensed-prose head — same
  clause set, census `grep -c "committed state"` → 3/3/3. Pack-startup:
  `.claude`/`.codex` byte-identical (`766e9ea9…` ×2); `.gemini` prompt body
  diffed byte-equal to the SKILL body.
- **Routed findings closed:** NIT-1 "(committed state)" qualifier present at
  trinity head lines ×3, README rows 185/187/278/279, pack-startup Step-2
  prose ×3. NIT-2A `forward_complete` conjunct + `tracker_mode()` citation in
  ALL three CLI copies. NIT-2B: the TRACKER-fragment `mirror-rebuild` row is
  now client-surface-scoped with the pack fail-loud pointer, and the
  colloquial mapping row is split tree-rebuild/mirror-rebuild.
- **Live state untouched:** `tracker.toml` 23 lines before/after (file
  bytes); `.pack-tracker/` never written. (The probe COMMIT of the file is
  the INCIDENT — file content itself unchanged.)
- **No new top-level files;** the only new file is the IMPL-REPORT
  (workflow-artifact class, exempt). BD-204 stays Open (C-8 pending) — no
  BACKLOG flip due.

## 8. Findings (detail)

### MUST-1 — `README.md:197` stale `pack-tracker.sh` verb enumeration

`README.md:197` (Repository Layout, `scripts/` block):
`pack-tracker.sh  Tracker — init / status / mirror-rebuild / disable / doctor
/ update-templates / enable-recommendations (v11)` — omits `tree-rebuild`,
`edit`, `new-entry`. The same diff updated the parallel verb list in
`pack-ops/HELP-FRAGMENT-PACK.md:30` and touched four OTHER README rows
(NIT-1), so this is a missed encoding surface (enumerate-encoding-surfaces),
and README's layout section is the trinity-named authoritative structure
reference. The PLAN §3.1 claim that HELP-FRAGMENT-PACK.md is "the only
pack-side help surface listing the verb set" did not account for this row.
Fix: add the three verbs to the line (mirroring the HELP-fragment ordering).

### SHOULD-1 — doctor leg (h) coverage truncated at 100 vs 213 live entries

`scripts/lib/tracker-doctor.sh:341` —
`provider_list '{"label":"bd-entry","state":"all"}' 100`. The live tree has
**213** BD entries (`ls backlog/BD-*.md | wc -l`), and `gh issue list
--limit 100` returns at most 100, so on the real Mode-3 repo the advisory
checks ≤47% of pack-owned issues with no signal that the rest were skipped
(the OK line prints the checked count, but a user won't know 213 was the
target). The REVERSE roster has the same `100` limit but is protected by the
id-map union fallback (`roster + mapping gh_ids`, then per-issue
`provider_get`) — leg (h) deliberately has no per-issue sweep, so it has no
such recovery. The architecture's "enumerate pack-owned issues via
provider_list" intent is not met at live scale. Fix: raise the limit (e.g.
1000, matching the forward stabilization wait's awareness of the >200 case at
`tracker-migrate-forward.sh:2272`) and/or WARN when `coh_n == limit`.
Advisory-layer only (the blocking comparator covers every materialized
entry), hence SHOULD not MUST.

### SHOULD-2 — emit-phase failure still stamps `last_tree_regen` + reports success

`scripts/lib/tracker-migrate-reverse.sh` Step 9: with `flip_mode=0` (the
tree-rebuild arm), `_tmr_emit_pack_tree … || emit_failed=1` does not gate
anything downstream — the atomicity gate fires only for `flip_mode==1` — so a
partial emit failure (a) stamps `migration.last_tree_regen`, (b) prints
`tree-rebuild: complete.`, (c) returns rc=0. (a) newly masks the doctor
leg-(d) staleness WARN this commit introduces; (b)/(c) make the NEW verb lie
on its happy-path summary. Inherited engine shape (the non-flip reverse has
always stamped `last_reverse_run` and returned 0 on emit failure; the
architecture §2 accepts converging partial state), but the freshness key now
has a CONSUMER, and the edit-side stamp is explicitly success-only — symmetry
argues the regen stamp should be too. Comparator/guard failures are NOT
affected (they abort pre-emission, pre-stamp — verified + test-pinned). Fix:
pass `_stamp_tree=1` only when `emit_failed==0`, and gate the summary/rc.
Low probability (`pe_write_atomic` disk failures), hence SHOULD.

### NIT-1 — pre-existing reverse-suite `gh repo view` leak (unchanged)

7 unwrapped read-only `gh repo view --json nameWithOwner` invocations escape
the fake-gh wraps in `tracker-migrate-reverse-test.sh` (origin:
`tracker-migrate-reverse.sh:428` fallback when `GH_REPO` resolution runs
outside a wrap). Identical count at pre-change baseline; failure-tolerated
(suite green with `gh` exploding). Out of this commit's scope; tracked here
per nits-become-tech-debt. Optional follow-up: suite-global fake-gh PATH or
`GH_REPO` export at suite head.

### Observation (no action) — `cmd_edit` carries no pack-surface gate

`tree-rebuild`/`new-entry` gate pack-surface; `cmd_edit` relies on the
surface-neutral `tracker_edit_entry` (which gates tracker-mode only, typed).
A client-surface tracker-mode `edit` is a legitimate lib operation (the
client mirror path is forward-driven), and neither PLAN D2-1 nor the
architecture asked for a surface gate on `edit`. Noted for BD-206/207's
client-verb pass; not a defect.

## 9. READ-IN-FULL attestation (path + line count, read this session)

| # | File | Proof |
|---|---|---|
| 1 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | `## Pack memory` section read via Read tool (lines 140–590 of 590; full file content also present in session context). |
| 2 | `maintenance-docs/v11-implementation/PLAN-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL, 451 lines (§0–§9, EE-1..EE-8, OQ-1..OQ-3). |
| 3 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` | Read IN FULL, 556 lines (§0–§9). |
| 4 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md` | Read IN FULL, 624 lines (§B0–§B12 incl. the normative §B8 D2 table). |
| 5 | `maintenance-docs/v11-implementation/IMPL-REPORT-MODE3-OPS-COMMIT2.md` | Read IN FULL, 410 lines (edit inventory §13, disclosures §10/§11, DoD §14). |
| 6 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` | Read IN FULL, 43 lines. |
| 7 | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | Read IN FULL, 15 lines; conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` read directly (lines 206–235). |
| 8 | `/backlog/_rules.md` (151 lines) + `/changelog/_rules.md` (77 lines) | Each read IN FULL via Read tool (pack per-entry tree contracts). |
| 9 | `PACK-REVIEW-MODE3-OPS-COMMIT1-REVIEW3.md` | §9 Findings ONLY (lines 235–272: NIT-1 / NIT-2 / ADVISORY-1) + heading map — prompt-permitted scope; no other PACK-REVIEW file opened. |
| 10 | Section-reads, each verified directly: full `git diff HEAD` per file (all 26); `scripts/lib/tracker-migrate-reverse.sh` current-state regions (`_tmr_emit_pack_tree` write loop, `_tmr_decode_body_blob`, `_tmr_decode_status`, emit/atomicity/Step-9 region 1659–1800, roster 1432–1460, dry-run exits); `scripts/lib/tracker-edit.sh` 170–260 (gating) + new function; `scripts/pack-tracker.sh` sourcing block + usage + all three new verbs; `scripts/lib/tracker-doctor.sh` legs (d)/(h); `scripts/lib/tracker-provider-gh.sh` list/get fields + both normalizers (`tracker_provider_gh_list` body); `scripts/validate-pack.py` Check 29″/32′ hunks + `_RULES_MODE_MARKERS`; `.gitignore` hunk; all 6 test-suite hunks; trinity/README/pack-startup/HELP/OPTIONAL-FEATURES/pack-example hunks; `README.md:193–201`; `.github/workflows/validate-pack.yml` run-line extraction (54 lines → 52 suites + 2 fixture steps). |

## 10. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | VIOLATED — one state-changing git sequence escaped containment: `git add -f tracker.toml && git commit` intended for the `/tmp/c29probe` "isolated copy" landed on the REAL `v11-dev` because `cp -R` copied the worktree's `.git` POINTER FILE (`gitdir: …/.git/worktrees/optiquity-ai-agent-config-pack-v11-dev`), creating stray local commit `de1e948 "probe: tracked tracker.toml"` (1 file, 23 lines, unpushed — `git log origin/v11-dev..HEAD` → only `de1e948`). All other git verbs this session were read-only (`rev-parse`, `status`, `diff`, `log`, `show`, `ls-files`, `check-ignore`, `clone` of source); the Test-18 suite's scratch `git init/add/commit` ran inside genuinely self-contained `mktemp` repos. NO remediation performed (reset is also a forbidden verb) — recipe surfaced in § INCIDENT for Pack Chat + user. Outputs otherwise = this report only; zero repo-content edits. | VIOLATED: stray probe commit `de1e948` (full disclosure + remediation recipe in § INCIDENT) |
| **per-action-approval-sub-agents** | No intentional destructive op on trusted files: `rm -rf` limited to my own `/tmp` probe dirs (`/tmp/c29probe`, `/tmp/sabprobe`, `/tmp/headclone`, `/tmp/explodegh*`); live `tracker.toml` bytes (23 lines) + `.pack-tracker/` untouched; report path verified new (`PACK-REVIEW-MODE3-OPS-COMMIT2.md` absent from the maintenance-docs listing read at session start). The INCIDENT above is the one unintended state change — surfaced and stopped, not self-remediated. | COMPLIANT (with the INCIDENT cross-reference) |
| **preflight-stop-means-stop** | Emitted before this Write, verbatim: `PREFLIGHT: review complete; verification PASS on the 26-file change (validate ×2 green pre-incident, 52/52 suites green, probes done) with one reviewer-caused git-state INCIDENT disclosed (stray local commit de1e948; remediation required); HEAD 358310e expected / de1e948 actual; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-MODE3-OPS-COMMIT2.md`. Every command ran FOREGROUND to completion (zero background tasks armed). No parent stop/halt/revert message received. | COMPLIANT |
| **agent-output-rules-applied-block** | This table: 9 rows (one per prompt "Rules in force" item), each with quoted command/output evidence; zero empty cells; no AMBIGUOUS row; the one violation stated as VIOLATED with reason, per the format read this session at `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (lines 206–235). | COMPLIANT |
| **agents-read-rule-docs-in-full** | §9 attestation: all 5 prompt-named read-in-full files with line counts (CLAUDE.md Pack-memory 140–590/590; PLAN 451; ARCH 556; AMENDMENT-2 624; IMPL-REPORT 410; memories 43 + 15) + `_rules.md` pair (151/77) + every instructed section-read enumerated (row 10); REVIEW3 exposure bounded to the permitted §9 sections. | COMPLIANT |
| **verify-full-ci-suite** | §5: `validate-pack.py` rc=0 "PASSED — all checks clean"; `PACK_VALIDATE_DEEP=1` rc=0; **52/52** workflow suites run FOREGROUND in workflow order (counts quoted §5: detect 100/0, per-entry 57, checks-32 96, schema 40, bd130 36/0, integration v11-realistic-ot 33/33, …); fixture `build.sh --all --clean` rc=0 + manifest diff 0 lines + `--verify` 6/6 OK. Live oracle default-SKIP. All runs pre-incident; the working tree they tested is unchanged since. | COMPLIANT |
| **regenerate-manifest-v11-surface** | Independent rebuild performed by ME: `bash test-fixtures/build.sh --all --clean` → rc=0; `git diff test-fixtures/manifest.txt | wc -l` → **0**; `--verify` → 6/6 rows OK (SHAs match IMPL-REPORT §8). Mechanism verified: changed files absent from fixtures (`find test-fixtures -name pack-tracker.sh …` → empty); sanctioned shipped set untouched. PD-B claim CONFIRMED — empty diff, nothing to stage. | COMPLIANT |
| **pack-only (BD-204 HARD constraint)** | Check-36 simulation reproduced: `git diff --name-only` → 26 paths, `grep -cE "^(project-template/|supporting-docs/)"` → **0**. IMPL-REPORT path is `maintenance-docs/` (pack-side). My sole write (this report) is also pack-side maintenance-docs. The stray probe commit touches only root `tracker.toml` (also outside the deny set) and is slated for removal pre-commit. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Findings limited to real defects with file:line anchors (1 MUST + 2 SHOULD + 1 NIT + 1 no-action observation); clean areas stated as checked with the evidence that cleared them (§§2–7); no scope inflation (no new BD numbers assigned, no project-side asks, pre-existing items labeled as such); the INCIDENT section is mandatory disclosure, not scope creep. | COMPLIANT |

---

**End of PACK-REVIEW-MODE3-OPS-COMMIT2.md**
