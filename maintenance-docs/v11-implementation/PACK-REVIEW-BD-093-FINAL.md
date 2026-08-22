# PACK-REVIEW-BD-093-FINAL — v11.0 (RC1) release-cut, independent final pass

**Reviewer:** `pack-reviewer` (fresh, no prior review report supplied)
**Date:** 2026-08-21
**Verdict:** **CLEAN for release** — 0 BLOCKER, 0 MUST, 3 SHOULD, 3 NIT, 2 open items.
None of the findings is a functional defect, and none requires the bounded
review/fix cycle to reopen or an architect escalation. See § "Verdict" for the
disposition routing.

---

## 1. Runtime verification and method

| Item | Value |
|---|---|
| My own (isolated) checkout | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-aa7c4e82c2de39041` |
| My HEAD | `ee66ba57c355d449a536360061fd46d633651fbc` (branch `worktree-agent-aa7c4e82c2de39041`) |
| Work tree under review | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a3e94ef9f38a11308` |
| Work tree HEAD | `ee66ba57c355d449a536360061fd46d633651fbc` — read via plumbing |

The harness refused every `git` invocation redirected at the work tree:

```
This agent is isolated in the worktree .../agent-aa7c4e82c2de39041, but this
command changes directory to the shared checkout (.../agent-a3e94ef9f38a11308)
before running git. Refusing to run it
```

**Method used (both legs, per the spawn prompt's instruction):**

1. **Plumbing reads.** `/Users/david/Developer/optiquity-ai-agent-config-pack/.git/worktrees/agent-a3e94ef9f38a11308/HEAD` → `ref: refs/heads/worktree-agent-a3e94ef9f38a11308`; that ref file → `ee66ba57c355d449a536360061fd46d633651fbc`. Matches the expected SHA.
2. **`diff -rq` against my own clean checkout at the same commit.** This is the authoritative change-set derivation, since both trees are at the identical commit — every difference is therefore an uncommitted change.

**Change-set shape reproduced exactly as briefed:**

- 35 `Files ... differ` (modified)
- 8 `Only in ./maintenance-docs/v11-implementation` (deleted)
- 9 untracked new (8 in `maintenance-docs/archive/v11/` + `scripts/tests/test-validate-pack-check-4.sh`)

Total 43 tracked-relevant paths. Remaining `Only in` entries were gitignored
build artifacts (`__pycache__`, built `test-fixtures/<persona>` dirs) and were
excluded.

**Graph-first discovery.** The injected graph
(`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json`,
10.5 MB) was queried FIRST for the moved-docs blast radius. It returned 136
nodes and usefully widened my candidate set beyond an a-priori guess
(`scripts/validate-pack.py`, `supporting-docs/METHODOLOGY.md`,
`project-template/docs/pack/PM-CHAT.md`, the tracker libs, the backlog tree,
`maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md`).
It indexes the **pre-move committed state**, so per G2 I fell through to grep
for the verification census — explicitly declared here as required.

---

## 2. Independent verification results (quoted output)

### 2.1 `python3 scripts/validate-pack.py`

```
============================================================
PASSED — all checks clean
```
90 `── Check` banners (Check 49 is DEEP-only). Exit 0.

### 2.2 `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py`

```
RC=0
── Check 94: install-merge token-wire guard + Case-3 KEEP-on-success backstop (BD-285 F9) ──
  OK: Check 94 — install-merge token wire intact ...
============================================================
PASSED — all checks clean
```
91 `── Check` banners. Exit 0.

Registry self-corroboration (Check 59, quoted):
```
OK: Check 59 — CHECK_REGISTRY has 91 entr(y/ies) (== CHECK_REGISTRY_EXPECTED_COUNT);
every entry is a well-formed (number, label, fn, budget) 4-tuple with a unique
label + callable fn. The no-flag full run executes every registered check.
```

### 2.3 Every wired test in BOTH jobs of `.github/workflows/validate-pack.yml`

The workflow has four jobs. I enumerated and exercised the wired set of each:

| Job | Wired step | Result |
|---|---|---|
| `validate` | `python3 scripts/validate-pack.py` | PASS (§2.1) |
| `validate` | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | PASS (§2.2) |
| `plan` | `ci-shard-plan.py --emit-matrix` | 4 shards: 37 / 31 / 32 / 32 = **132** |
| `tests` | `test-fixtures/build.sh --verify` (fixture-owning shard) | RC=0, 7/7 fixtures OK |
| `tests` | every script in every shard | **TOTAL=132 PASS=132 FAIL=0** |
| `tests-result` | `ci-shard-plan.py --assert-coverage` | OK |

Full battery (my own runner over the disk-derived matrix):
```
TOTAL=132 PASS=132 FAIL=0
--- failed ---
[exited with code 0]
```

Shard self-check:
```
ci-shard-plan --assert-coverage OK: 132 wired KEEP test(s) across 4 shard(s);
union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located
in one shard.
```

Fixture verify:
```
v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
v11-realistic-ot OK: 4ffbcf66cbe9255cbc0c2edc4d906c47edc885f6
v11-flat-file OK: 283bf0bad769d69a431cc23a88c8137c0ca75f15
v11-tracker-on OK: 4f322dc1adb5b2d5e00e2167c7e68e91fba1e20d
existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
existing-project-collision OK: 7eb05e434cf050e005b582d94eba9105b67abda0
```
No manifest regeneration is implied: `build.sh` changed comment-only, and
`--verify` passes against the committed manifest.

### 2.4 Warnings and runtime

22 `WARN:` lines in the DEEP run — **identical count (22) in my pre-change
clean tree**, all pre-existing Check 48 JC-5 accurate-history advisories
(`changelog/v8.md`, `changelog/v9.md`, `backlog/BD-030/044/046`). **The moves
introduced zero new dead-doc advisories.** No new `WARN` from the Check 65
dead-record advisory (it reports `0 dead, 0 on unscanned docs`).

Runtime: work tree `2.102s` total vs clean tree `1.987s` — a ~0.1 s delta for
three added guard legs. No per-check budget notice fired.

---

## 3. Guard correctness (areas 3, 4, 5) — bite proven independently

I constructed my own harnesses rather than relying on the authored tests.

### 3.1 Check 4 (`singletons.py:check_readme_version`) — REPAIRED, BITES

**The pre-fix defect, reproduced directly.** Running the *unmodified* checker
in my clean tree at the same HEAD:

```
── Check 4: README version table vs git tag ──
  OK: README.md version v1 matches git tag
```

The guard was comparing `version_rows[-1]` — `v1`, whose tag has existed since
v1 — so it passed unconditionally and caught nothing. Post-fix, the same tree
state yields:

```
── Check 4: README version table vs git tag ──
  OK: README.md version v11.0 (RC1) (linked worktree off dev branch `v11-dev` — tag will be created at release)
```

**Table-ordering premise verified.** The regex yields 25 rows, `[0]` =
`'v11.0 (RC1)'`, `[-1]` = `'v1'`. The README table is newest-first, so
`rows[0]` is correct.

**My independent bite harness** (stubbed git, synthetic README, shipped check
body). Result: `BITE PROVEN`.

| Input | Expected | Observed |
|---|---|---|
| primary checkout, branch `main`, newest row untagged | FAIL | `failures=1` — "README.md current version is v99.0 (RC1) (tag form `v99.0-RC1`) but no matching git tag exists" |
| primary checkout, branch `main-devops` (substring lookalike) | FAIL | `failures=1` |
| linked worktree, no dev branch at HEAD | FAIL | `failures=1` |
| primary checkout, matching tag present | PASS | `failures=0` |
| primary checkout, branch `v11-dev` | PASS | `failures=0` (dev allowance) |

**Design assessment.**
- `_check_4_is_dev_branch` splits on `[-/]` and tests segment membership. `v11-dev`, `dev`, `dev/topic`, `v11-dev-fixes` accept; `main-devops`, `feature/device-x` reject. Degradation is safe: an unrecognized dev spelling mis-FAILs loudly, never mis-PASSes.
- The linked-worktree allowance is gated on `--git-dir != --git-common-dir`. **CI is never a linked worktree**, so the allowance provably cannot leak into the CI path — the release-cut mismatch case stays enforced. Test T10 pins this and my harness independently confirms it.
- Leniency: git absent → `FileNotFoundError` → documented skip; no tags → skip; rev-parse/points-at non-zero or `OSError` → **no allowance** (loud FAIL), not a silent pass.
- Runtime: two extra `git` calls, **only on the path that was already about to FAIL**. Hot path untouched. Compliant with `ci-check-runtime-compounding`.

**Encoding-surface pairing verified in both directions.** The new
`scripts/tests/test-validate-pack-check-4.sh` (19 cases, hermetic — creates no
git repo, stages nothing) is wired: my clean tree's shard plan reports **131**
wired tests, the work tree **132**. The delta is exactly this file. Critically,
the *pre-existing* reproduction in
`scripts/tests/test-validate-pack-checks-32-33-34.sh:1263` mirrored the
production bug (`rows[-1]`) and was corrected to `rows[0]` in lock-step, plus a
new `Tr.8` multi-row assertion. Had that not been done, a test would have kept
asserting the buggy behavior.

### 3.2 Check 39 leg 3 (`boundary_refs.py`) — NEW, BITES

**Measurement claims reproduced exactly.** The block comment claims
`migrator_manifest()` 13 rows → 12 KEEP / 1 STRIP, and
`migrator_directory_sweeps()` 3 rows → 3 KEEP / 0 STRIP. My independent parse:

```
PRE-change  manifest rows=13  sweep rows=3
POST-change manifest rows=12  sweep rows=3
removed row(s): ['project-template/docs/pack/PROMPT-TEMPLATES.md']
sweeps unchanged: True ['project-template/scripts', 'project-template/.claude/agents', 'project-template/.codex/agents']

PRE-change unbacked manifest rows : ['project-template/docs/pack/PROMPT-TEMPLATES.md']
POST-change unbacked manifest rows: []
```

The post-STRIP legitimate set is 100 % backed, so
`_CHECK_39_MIGRATOR_EXEMPTIONS = {}` is **sized to exactly the legitimate set
(zero)** — measured, not assumed. Compliant with `ci-guard-measure-then-bound`.

**My independent bite harness.** Result: `LEG-3 BITE PROVEN`.

| Input | Expected | Observed |
|---|---|---|
| the real PRE-fix row set (PROMPT-TEMPLATES.md) | FAIL | `leg3_failures=1` — "declares a pack-side source that is NOT tracked at HEAD, so it does not ship" |
| fabricated ghost file row | FAIL | `leg3_failures=1` |
| fabricated ghost sweep dir | FAIL | `leg3_failures=1` — "declares a pack-side directory with no tracked files under it" |
| untracked-but-present-on-disk file | FAIL | `leg3_failures=1` (tracked-ness is the oracle, as documented) |
| the shipped post-fix row set | PASS | `leg3_failures=0` |

This is the **absence-of-backing** case, not merely target-exists — exactly what
`declare-verify-backing` demands.

**Design assessment.**
- Candidates drawn from `git ls-files -- <derived pathspecs>` — git-tracked, never a filesystem walk. The pathspec is *derived from the declared rows*, not hard-coded, so a row sourced outside `project-template/` cannot produce a false FAIL with a misleading message.
- Runtime: one bounded subprocess + one file read + O(16 rows) set membership. No per-row subprocess, no tree walk.
- Leniency: git absent / non-zero rc → `ok(... skipping ... (lenient))`.

**Shared-parser hardening — behavior-preserving and it fixes a real bug.**
`_migrator_heredoc_first_fields` is also used by Check 47, so I verified the
new body-bounding changes no current answer and that the bug it fixes is real:

```
hook migrator_manifest            old=12 new=12 identical=True
hook migrator_directory_sweeps    old=3  new=3  identical=True
PARSER HARDENING BEHAVIOR-PRESERVING ON CURRENT ADAPTER: True

empty-hook bleed: OLD parser returned ['project-template/docs/pack/GHOST.md'] ; NEW parser returned []
BLEED FIXED: True
```

A hook using the empty `{ :; }` form previously returned the **next** hook's
rows — a silently wrong answer. Now it returns `[]`. Check 47's tests pass
unchanged (part of the 132).

**Encoding surfaces paired:** `__all__` gained
`_CHECK_39_MIGRATOR_EXEMPTIONS` and `_parse_migrator_manifest_sources`;
`test-validate-pack-check-39.sh` gained both to its required-symbols list and a
new Group 2c that pins the leg against non-canonical-but-legal adapter shapes
(renamed heredoc marker, unquoted heredoc, comment-first body, `<<-` indented,
empty `{ :; }`). That is precisely the silently-inert class, tested.

### 3.3 Check 65 allowlist dead-record advisory — CORRECT, ADVISORY-ONLY

```
OK: Check 65 — 158 operating doc(s) scanned; 0 history pattern(s) outside the
allowlist (0 = clean); 39 allowlisted KEEP occurrence(s) admitted. Allowlist
backing: 35 record(s) declared, 35 live, 0 dead, 0 on unscanned docs.
```

`warn()` verified advisory by construction (`scripts/lib/validate_checks/core.py:92`):
"A `warn()` line is printed ... but does NOT append to `failures`, so it never
changes the exit code." Correct call — a record can be legitimately
un-triggered, so a hard FAIL would red CI on a false positive.

**The K5/K6 removals are correct, and I verified this is not a masked
regression.** `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` still appears in
`pack-ops/PACK-AGENTS.md` (×2), `PACK-CHAT.md` (×1) and
`PACK-MEMORY-RATIONALE.md` (×1) — unchanged counts before and after. The K5
records were removed anyway, and Check 65 still reports 0 outside-allowlist
hits. Reason: the `bd-tag` pattern is `BD-\d+`, and that filename contains no
BD digits, so the records could never fire — genuinely dead, exactly the class
the new advisory detects. K6's target was additionally deleted at BD-210. The
header's `K2-K6` → `K2-K4` and `K9-K11` → `K10-K11` edits match the resulting
record set (no K5/K6/K9 records remain).

The `any(...)` → explicit-loop change is required for correct usage tracking
(short-circuit would hide a second covering snippet and mis-report it dead).
Cost is O(snippets), incurred only on a line that already matched a forbidden
pattern.

---

## 4. Release-cut consistency — CLEAN (the BLOCKER-class question)

Every surface that states the version agrees:

| Surface | Value |
|---|---|
| `README.md:83` version row | `\| v11.0 (RC1) \| August 2026 \|` |
| `changelog/v11.md:2` H2 | `## v11 — August 2026` |
| `changelog/_toc.md` | `- [v11](./v11.md) — August 2026` |
| `pack-ops/dashboard-approvals/dashboard.html` state JSON | `version='11.0'`, `qualifier='RC1'`, `date='August 2026'` |
| Tag the cut will create | `v11.0-RC1` (= Check 4's `readme_version_tag` normalization of `v11.0 (RC1)`) |

No stray `v11.0 (work)` remains on any live surface. The only residual
occurrences are (a) `backlog/BD-253.md` / `BD-260.md` — accurate history of the
qualifier's introduction, (b) the dashboard's embedded BD entry text, and (c)
`test-validate-pack-checks-32-33-34.sh:1282` — a deliberate `Tr.7` fixture
testing `(work)` → `v11.0-work` normalization. All legitimate.

**No mismatch found.** This is the specific failure mode the cut had to avoid,
and it is clean.

*Non-finding, recorded because I checked it:* the new H3
`### v11.0 — post-Scope-C work through the release cut` carries no `(RC1)`
qualifier label. `changelog/_rules.md` says a going-forward H3 **MAY** carry a
release-state qualifier — optional, not required — and the block names
`_At the v11.0 (RC1) cut_` internally. Not a defect.

---

## 5. The changelog block — claims audited

**BD citations.** 152 distinct BD-NNN cited in the new block; **all 152 exist**
in `/backlog/`. Every BD cited in the shipped (non-carried-over) sections
carries `Status: Resolved` **except BD-093** — see Finding S1.

**Carried-over completeness.** The backlog holds exactly 16 `Status: Open`
entries. The block's `_Targeted v11.1_` (5: BD-202/223/247/254/279) plus
`_Open, untargeted_` (10: BD-020/036/037/039/109/110/171/172/187/192) = 15, and
BD-093 is handled explicitly in the tail prose. **16 = 15 + 1 — exact.** The
heading says "BDs Open at the cut", so `Deferred` (23), `Deprecated` (11) and
`Cancelled` (1) are correctly out of scope.

**Path citations.** Every backticked path in the new block resolves except
`deployment-python/SKILL.md` (Finding N1). Checked including trailing-slash
directory forms.

**Numeric claims — all reproduce exactly:**

| Claim | Verified |
|---|---|
| "91-entry check registry (86 distinct numbered ... 16/18/19 twice ... 2 unnumbered)" | Check 59 reports 91 == `CHECK_REGISTRY_EXPECTED_COUNT`; 86 + 3 + 2 = 91; default run 90 (Check 49 DEEP-only) |
| "CI wires 132 test scripts, partitioned across 4 dynamically-planned shards" | `--assert-coverage`: 132 across 4; shard sizes 37/31/32/32 |
| "Check 93 ... with a single measured allowlist entry" | Check 93 output: "except the one allowlisted `x-brokerage-api` row-name keep (OI-S7)" |
| "Check 4 ... compared the OLDEST table row and so passed unconditionally" | Reproduced verbatim: clean tree prints "README.md version v1 matches git tag" |

**Audit-artifacts consolidation.** Exactly **one** `**Audit artifacts` block
remains (`changelog/v11.md:516`), at the tail of the final H3, with
time-labelled sub-blocks (`_At the Scope A/B cut_`, `_At the Scope C cut_`,
`_At the v11.0 (RC1) cut_`). This satisfies BD-093's "consolidate ... into one
canonical position at the v11.0 changelog tail" and correctly scopes stale
figures to the moment they were true rather than deleting or falsifying them.

The Scope-C block's old enumeration of durable docs was dropped rather than
repointed — correct, since several of those docs (`ARCHITECTURE-SKILL-DIMENSIONS.md`,
`PLAN-SKILL-DIMENSIONS.md`, `PLAN-BD-119.md`) were deleted at BD-210 and
`EXECUTION-PLAN-V11.0.md` has now moved. Past tense + no dead enumeration is
the right handling under `fail-loud-delete-old-source`.

**`_toc.md` sync.** Both TOCs are correctly regenerated: `changelog/_toc.md`
date updated; `backlog/_toc.md` moves BD-280 out of Open into the Resolved
section. Check 33 (TOC-in-sync) passes.

---

## 6. The moved docs — independent census

Complete census of **qualified** stale references (`v11-implementation/<moved doc>`)
across the work tree. 13 hits, fully categorized:

| Location | Count | Assessment |
|---|---|---|
| `pack-ops/dashboard-approvals/dashboard.html:110` | 8 | **Not stale.** I parsed the embedded state JSON: all 8 sit in the `inflight` key, which is a live `git status` read showing these very files as `"x": "D"`. Transient; the next render after the commit drops them. Matches BD-280's resolution note exactly. |
| `backlog/BD-138.md:8`, `backlog/BD-139.md:12` | 2 | Resolved historical entries; deliberate retention documented in BD-280's `Resolved:` line. `backlog/` is a history surface. |
| `maintenance-docs/archive/v11/RESEARCH-BD-212...:275`, `...BD-185...:482` | 2 | Archived docs self-referencing their own pre-move path (Finding N3). |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md:887` | 1 | **Genuinely new stale path — Finding S2.** |

**Correctly repointed** (verified): `pack-ops/PACK-MEMORY-RATIONALE.md:442` and
`backlog/BD-204.md:9` both now cite `maintenance-docs/archive/v11/...`. All
other references to the eight basenames are bare (undirectoried) and remain
resolvable.

I did **not** rely on Check 34 for this, per the prompt's caution that it
resolves qualified paths by basename membership in the tracked-basename index
and therefore stays green on a stale-but-resolvable path. The census above is
grep-exhaustive over the work tree.

**Should each of the eight have moved?** See Open Item O1 — the criterion is
defensible but undocumented and slightly inconsistently applied.

---

## 7. Boundary discipline (area 8) — CORRECT, not a regression

`supporting-docs/MIGRATION-v10-to-v11.md` now points at `pack-ops/MERGE-STRATEGY.md`
and `pack-ops/DRY-RUN-MIGRATION.md`. I established independently whether that
file is client-installed:

- `scripts/init-project.sh:1622-1623` — the **only** `supporting-docs/` entries in the install map are `METHODOLOGY.md` and `INSTALL-PROCEDURES.md` (both → `docs/pack/`).
- `scripts/init-project.sh:1937` mentions `supporting-docs/MIGRATION-v10-to-v11.md` only inside a `say` console string pointing the reader at the pack repo — not an install.
- The migrator's 12 manifest rows are all `project-template/docs/pack/*`; its 3 sweeps are all `project-template/*`. No `supporting-docs/` install.

**Conclusion: `MIGRATION-v10-to-v11.md` is NOT client-installed.** Its audience
is a reader who has cloned the pack (`export PACK=/path/to/pack-repo`, per the
doc's own Step 3). The qualification is therefore **correct and an
improvement** — the previously bare `MERGE-STRATEGY.md` was ambiguous, and both
targets exist at `pack-ops/`. This is not a client-install regression, and
P-missed-7 is satisfied rather than violated.

**Backing verified for newly-described behavior** (`declare-verify-backing`):
the added paragraph describes `--no-interactive`, which really ships
(`scripts/migrate-v10-to-v11.sh:72, 1099, 1105, 1109`), and cross-references
"Interactive reconciliation", which exists at line 446 of the same doc. No
deferred/unimplemented feature is described.

---

## 8. Cross-cutting checks

- **Trinity parity — N/A but verified safe.** No trinity file (pack-root or `project-template/`) is in the change set. I confirmed the `public-bound-no-leak` rule body in all three (`CLAUDE.md:922`, `AGENTS.md:791`, `GEMINI.md:764`) already carries neutral "two-tier keep-list" wording with **no** "scrubbed public copy" language, so the area-6 permanence edit needed no trinity counterpart. Parity intact.
- **Area 6 (`no_leak.py`) did not weaken the check.** Diff is docstring/comment only; `_CLIENT_PREFIXES` and `_CLIENT_ROOT_FILES` are byte-identical. The rule text in `pack-ops/PACK-MEMORY-RATIONALE.md:1290` was updated in lock-step with the code comment — correct paired-surface maintenance.
- **No-leak tiers applied correctly.** The change set touches `supporting-docs/` and `.github/` (strict tier) and `changelog/` (internal tier). Check 93 passes both legs. No `project-template/` file was touched at all.
- **The comment sweep did NOT destroy rationale.** This was a specific concern and the handling is good: dead section-number citations were converted into inline constraint statements rather than deleted, e.g. `scripts/lib/migrate-v10-to-v11/decompose.sh` replaces 14 lines of dead `§` pointers with "Design constraints binding on this file (their source architecture + plan docs were deleted at BD-210; the constraints themselves still hold): — Sequencing: this 6th sub-op MUST run AFTER all 5 existing sub-ops ...". Same pattern in `per-entry/_lib.sh`, `per-entry/decompose.sh`, `tracker-agent-read.sh`, `test-validate-pack-checks-32-33-34.sh`. One reference was repointed to a live doc (`maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md §1.3`) — I verified that file exists.
- **Client-visible strings improved.** The sweep removed pack-internal doc citations from migrator *runtime advisory output* written into the client's repo (`migrate-v10-to-v11.sh:875, 925`) — a boundary improvement, not just a comment tidy.
- **`pack-ops/PACK-CHAT.md` section removal is well-formed.** The whole `## Action items (PM coordination)` section was removed because its single item asked for an edit to a doc deleted at BD-210 — unactionable. Resulting structure verified clean: `...user, never the agent.` / blank / `---` / blank / `## Session naming and resume`. No doubled separator or orphaned blank.
- **No deferral comments introduced.** No plain `TODO`/`FIXME`/"fix later" appears in the change set; `pack-repo-code-comment-deferrals` is not engaged.
- **`.github/` workflow edit** replaces a dead `RELEASE-GATE.md` citation with a tombstone note. The file already carries BD-NNN references throughout (BD-219, BD-115…), so this is consistent with its existing style, and a CI workflow is code, not an agent-executed operating doc — `operating-docs-no-history-no-bloat` does not bind it.

---

## 9. Findings

### SHOULD

**S1 — `backlog/BD-093.md` remains `Status: Open` while the changelog asserts it resolves with this entry.**
`backlog/BD-093.md:4` → `Status: Open`; `:20` → `Resolved: n/a`. The change set
updates only its two `File/Symbol`/Description paths. Meanwhile
`changelog/v11.md` (tail of the new block) states: *"BD-093 is the cut itself
and resolves with this entry."* My mechanical audit confirms this is the sole
disagreement: every other BD cited in the shipped sections is `Resolved`.
Secondarily, the `**Carried over past the cut (BDs Open at the v11.0 (RC1)
cut):**` list omits BD-093 even though it is Open — the tail prose covers it, so
no reader is misled, but a mechanical Open-set-vs-list check flags it.

*Why this is SHOULD and not MUST:* the underlying sequencing is sound and
deliberate. BD-093's own Description requires "validate-pack must pass on the
tagged commit", and the tag is created **after** this commit — so flipping to
`Resolved` now would itself assert something not yet true. The defect is
confined to one sentence's tense.

*Options:* (a) flip `BD-093.md` to `Resolved` in this commit with a
`Resolved:` line and regenerate `_toc.md`, accepting that the tag lands
moments later; (b) reword the changelog clause to be explicitly forward-looking
("BD-093 is the cut itself and resolves once the `v11.0-RC1` tag is created"),
leaving the flip to the post-tag bookkeeping commit; (c) accept as-is.

*Recommendation:* **(b).** Evidence: BD-093's Description conditions resolution
on the tagged commit, and the existing `Blockers:` line states "BD-093 is the
release-cut commit and runs LAST" — so (a) would record a resolution before its
stated acceptance condition holds, whereas (b) makes the changelog match the
sequence the entry itself specifies. This is a one-clause edit to a
pack-chat-only file that Pack Chat may apply directly (`/changelog/` tree is in
the small set; a wording change to an entry Pack Chat is authoring in this same
commit is not a substantive edit of already-landed content).

**S2 — New stale path: `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md:887`.**
The line reads:
```
| EXECUTION-PLAN-V11.0.md | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` | Batch sequencing. BD-185 lands at Batch 19d per `pack-ops/BACKLOG.md:1789`. |
```
That path was correct before this change set and is stale after it. It is the
only genuinely-new stale qualified reference outside the archive and the
history surfaces. No gate covers it (Check 40 scans `pack-ops/`, Check 43 scans
project-side; neither covers `maintenance-docs/`).

*Mitigating context, verified:* the same table row already cites
`pack-ops/BACKLOG.md` (deleted at BD-203) and two rows above cites
`maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`
(deleted at BD-210) — I confirmed both are absent. The doc is a historical
research artifact for BD-185 (`Status: Deferred`) and is demonstrably not
maintained as a live pointer surface. It is internal-only and cannot affect the
shipped pack or any client.

*Options:* (a) repoint the one path to `maintenance-docs/archive/v11/EXECUTION-PLAN-V11.0.md`;
(b) leave it, consistent with the doc's other pre-existing dead pointers;
(c) drop the `Path` cell for that row.

*Recommendation:* **(a).** A one-token edit that removes a defect this change
set introduced, without touching the pre-existing dead refs (which are BD-210 /
BD-203 history, out of this change set's scope). Cheapest correct action.

**S3 — `pack-ops/session-state.json` is stale at the release cut (pre-existing; orchestrator-owned).**
It records `"boundary_commit": "f35c66b"` (HEAD is `ee66ba5`, two commits
later), `"queue": ["BD-172", "BD-093"]` and
`"cycle_position": "BD-285 COMPLETE ... NEXT: BD-172 ... -> BD-093 (release
pin)"`. But BD-093 is the work in flight *now*, and BD-172 remains `Status:
Open` (reordered/skipped). `session-state-snapshot` requires Pack Chat to
REPLACE the fields on every state transition, and a release cut is
unambiguously one.

*Not introduced by this change set* — the file is not in the diff. Surfaced
because shipping the RC with a snapshot that misdescribes the frontier
undermines the resume contract `/pack-startup` depends on.

*Options:* (a) Pack Chat replaces the snapshot fields as part of this commit;
(b) update it in the post-tag bookkeeping commit; (c) leave it.

*Recommendation:* **(a).** Evidence: the snapshot is explicitly a Pack-Chat
bookkeeping surface Pack Chat may edit directly, and the rule says "REPLACES its
fields on every state transition" — not "at a convenient later commit". Doing it
in the cut commit is the lowest-risk moment and costs nothing.

### NIT

**N1 — `changelog/v11.md` cites `deployment-python/SKILL.md` unqualified.**
The skill lives at `project-template/skills/deployment-python/SKILL.md`; the
bare form does not resolve from the repo root. It is consistent with the bare
`deployment-python` skill-name usage at `changelog/v11.md:157`, so this reads as
skill-name shorthand rather than a path claim. *Recommendation:* qualify it, or
drop the `/SKILL.md` suffix so it is plainly a skill name. Either removes the
ambiguity; I marginally prefer qualifying, since the surrounding bullets cite
full repo-relative paths.

**N2 — `README.md` Repository Layout enumerates 2 of 10 files under `archive/v11/`.**
The description was correctly widened to "Extracted operating-doc history +
superseded design/research records", but the subtree still lists only
`BOUNDARY-DEFINITION-HISTORY.md` and `CONCEPTUAL-REVIEW-METHODOLOGY-HISTORY.md`
— an enumeration that was complete before the move and is now 2/10. Mitigating:
the same section does not list `v11-implementation/` or `v11-research/` at all,
so the layout is plainly illustrative; and this change set elsewhere
deliberately replaced an enumeration with a derived pointer for exactly this
drift reason. *Recommendation:* for internal consistency with that same
decision, drop the two-file enumeration and let the description carry it.

**N3 — Two archived docs self-reference their pre-move path.**
`maintenance-docs/archive/v11/RESEARCH-BD-212-GH-ISSUE-DELETION.md:275` and
`.../RESEARCH-BD-185-FLAT-FILE-PHASE-PARTS.md:482` cite
`maintenance-docs/v11-implementation/<their own name>`. *Recommendation:*
leave as-is. These are archived historical artifacts; their self-citation was
accurate when written, and rewriting archived history to track a later move is
the opposite of the `fail-loud` posture. Recorded for completeness only.

---

## 10. Open items (context, options, recommendation)

**O1 — The archive criterion is undocumented and applied inconsistently to two files.**
*Context:* the eight moved docs are `EXECUTION-PLAN-V11.0.md` (named explicitly
in BD-093) plus seven `RESEARCH-*.md`. The 20 files retained in
`maintenance-docs/v11-implementation/` are 11 `ARCHITECTURE-*`, 2 `DESIGN-*`,
1 `DECISION-*` — **and two `RESEARCH-*` files**:
`RESEARCH-BD-204-GH-ISSUES-RULES.md` and
`RESEARCH-BD-221-ANTIGRAVITY-DOCS-CAPTURE.md`. So an apparent
"research/workflow artifacts → archive, durable design → stay" rule has two
exceptions, and no doc, BD or `_rules.md` states the criterion.

*My options:* (a) accept — both retained files are plausibly durable reference
material (the former is the complete GH-Issues rule set still cited by
`ARCHITECTURE-BD-204-LOSSLESS-FIX.md`, which stayed; the latter is a captured
external-docs snapshot), so the split is defensible on durability rather than
filename prefix; (b) move the two for prefix consistency; (c) record the
criterion in writing.

*Recommendation:* **(a) accept, and do not move anything now.** Evidence:
BD-093's own scope names only "`EXECUTION-PLAN-V11.0.md` and the accumulated
workflow artifacts", not "all `RESEARCH-*`"; and moving
`RESEARCH-BD-204-GH-ISSUES-RULES.md` would strand the live cross-reference from
a doc that deliberately stayed. The inconsistency is in the *filename prefix*,
not in the durability judgement, and the durability judgement is the one that
matters. I flag it only so the orchestrator can confirm the judgement was
intentional rather than incidental. **No recommendation is offered on (c)** —
whether to write the criterion down is a governance preference I have no
evidence to decide, and I am explicitly not proposing a new BD.

**O2 — Pre-existing dangling reference on a line this change set edited.**
`backlog/BD-204.md:9` (`DESIGN BASELINE`) names two required architect inputs:
`maintenance-docs/archive/v11/RESEARCH-BD-204-RESTART-INTEGRATION.md` — which
this change set correctly repointed — and `PACK-REVIEW-BD-203-VS-LOCKED-COMPATIBILITY.md`.
I searched the entire work tree: **that second file does not exist anywhere.**
The entry says these are inputs the architect "ADAPTS, do NOT discard", so a
future BD-204 resumption would be missing a named HARD input.

*Not introduced here* (it was already dangling), but it sits on the exact line
the change set edited, so it is worth a decision now rather than being
rediscovered at resumption.

*My options:* (a) leave it — BD-204 is `Deferred`, so nothing is blocked today;
(b) drop the dead name from the baseline list; (c) replace it with whatever
superseded it.

*Recommendation:* **(a) leave it, unchanged, in this commit.** Evidence: BD-204
is `Status: Deferred` and gated behind BD-215, so there is no live consumer;
and under `fail-loud-delete-old-source` a dangling named input is *supposed* to
break loudly at resumption rather than be silently pruned — deleting the name
would destroy the only surviving record that such an input once existed.
**I can give no recommendation on (c)**, because I found no evidence of what,
if anything, superseded that document.

---

## 11. Verdict

**CLEAN for release.**

- **0 BLOCKER, 0 MUST.**
- 3 SHOULD (S1 changelog/backlog tense mismatch on BD-093; S2 one new stale internal path; S3 stale session-state snapshot).
- 3 NIT (N1 unqualified skill path; N2 partial README enumeration; N3 archived self-references — recommend no action).
- 2 open items, both recommended "accept as-is".

The three guard changes are the highest-risk surface in this change set and all
three **provably bite** against inputs I constructed independently; the Check 4
repair fixes a guard that I confirmed was passing unconditionally on the oldest
table row. Full CI is green across both workflow jobs (91 checks DEEP, 132/132
tests, fixtures 7/7, shard coverage exact). Release-cut version consistency —
the specific failure mode this cut had to avoid — is clean across all five
version-stating surfaces.

**Routing note on the bounded cycle.** None of the findings requires reopening
the review/fix cycle or an architect escalation:

- **S1** and **S3** are `pack-chat-only` bookkeeping edits (a changelog clause and a session-state field replacement) that `pack-chat-minor-edits-only` expressly authorizes Pack Chat to apply directly.
- **S2** is a single-token path correction in an internal `maintenance-docs/` file.
- **N1**/**N2** are optional polish; **N3** I recommend leaving alone.

If the orchestrator elects to apply none of them, I would still not call the
change set unfit to ship — S1/S2/S3 are precision issues on internal surfaces,
not functional defects, and nothing in the shipped pack or any client-installed
file is affected.

---

## 12. Rules-Applied Verification Block

**agents-never-commit** — *Evidence:* every `git` invocation I issued was
`git rev-parse`, `git ls-files`, `git tag`/`git branch` (inside stubbed test
harnesses), or read-only plumbing `cat` of `.git/worktrees/.../HEAD` and
`.git/refs/heads/...`. The harness independently blocked my two attempts to run
git against the work tree ("Refusing to run it"). No `commit`, `add`, `push`,
`checkout`, `apply`, `stash`, `tag`, `worktree`, `reset`, or `restore` was run.
The work tree is byte-identical to how I found it (I wrote nothing into it; all
scratch went to `$TMPDIR`-rooted scratchpad and my handoff dir). — **COMPLIANT**

**per-action-approval-sub-agents** — *Evidence:* my writes were
`/private/tmp/claude-501/.../scratchpad/{runall.sh,bite4.py,bite39.py,bite39b.py,census.sh,census2.sh,census3.sh,rest.sh,ver.sh,clog.py}`
(OS temp root) and exactly one deliverable at
`/Users/david/.local/state/optiquity-pack-handoff/bd093-finalreview-20260821-194946/PACK-REVIEW-BD-093-FINAL.md`
(my owned handoff dir). One `sed -i ''` was applied to my own scratchpad file
`bite4.py`. No `rm`, `rmdir`, `unlink`, `mv`, `shred`, `truncate`, `find -delete`
was executed anywhere. Nothing outside my owned dir was deleted or overwritten. — **COMPLIANT**

**bounded-review-fix-cycle** — *Evidence:* I graded 0 BLOCKER / 0 MUST /
3 SHOULD / 3 NIT. I explicitly declined to inflate S1 to MUST, recording the
reason (BD-093's Description conditions resolution on the tagged commit, so the
current tree state is internally coherent and only one sentence's tense is
off). I also declined to soften anything: S2 is reported as a real new stale
path despite being internal-only, and the pre-fix Check 4 defect is documented
with reproduced output rather than glossed. § "Routing note" states plainly that
no finding needs an architect. — **COMPLIANT**

**verify-full-ci-suite** — *Evidence:* I enumerated the wired set from
`.github/workflows/validate-pack.yml` (jobs `validate`, `plan`, `tests`,
`tests-result`) and ran all of it: `validate-pack.py` (90 checks, PASSED),
`PACK_VALIDATE_DEEP=1 validate-pack.py` (91 checks, RC=0, PASSED),
`ci-shard-plan.py --emit-matrix` (37/31/32/32), all 132 shard scripts
(`TOTAL=132 PASS=132 FAIL=0`), `test-fixtures/build.sh --verify` (RC=0, 7/7),
`ci-shard-plan.py --assert-coverage` (OK). Real counts quoted in §2. — **COMPLIANT**

**enumerate-encoding-surfaces** — *Evidence:* verified in both directions.
Check 4 ← new `test-validate-pack-check-4.sh` (wired: 131 tests in my clean tree
vs 132 in the work tree, delta = this file) **and** the pre-existing mirror in
`test-validate-pack-checks-32-33-34.sh:1263` corrected `rows[-1]`→`rows[0]` with
a new `Tr.8`. Check 39 leg 3 ← `__all__` gained `_CHECK_39_MIGRATOR_EXEMPTIONS`
and `_parse_migrator_manifest_sources`; `test-validate-pack-check-39.sh` gained
both symbols to its required list plus Group 2c. Check 65 ← `test-validate-pack-check-65.sh`
gained T8b (dead record) and T9 (unscanned doc). `no_leak.py` comment ←
`PACK-MEMORY-RATIONALE.md:1290` rule text updated in lock-step; trinity
confirmed already-neutral. No asymmetric surface found. — **COMPLIANT**

**declare-verify-backing** — *Evidence:* I reproduced bite proof for all three
guards rather than accepting the authored tests. Check 4: `BITE PROVEN`
(3 must-reject / 2 must-accept, output quoted §3.1). Check 39 leg 3:
`LEG-3 BITE PROVEN` including the **absence-of-backing** case and the real
historical `PROMPT-TEMPLATES.md` defect (§3.2). Check 65: confirmed advisory by
reading `core.py:92` `warn()` ("does NOT append to `failures`"). I also
verified the load-bearing reality behind the doc change: `--no-interactive`
really exists at `migrate-v10-to-v11.sh:72,1099,1105,1109`. — **COMPLIANT**

**ci-guard-measure-then-bound** — *Evidence:* reproduced the leg-3 measurement
independently — `PRE-change manifest rows=13 ... POST-change manifest rows=12`,
`removed row(s): ['project-template/docs/pack/PROMPT-TEMPLATES.md']`,
`sweeps 3→3`, `POST-change unbacked manifest rows: []` — confirming 12 KEEP /
1 STRIP and 3 KEEP / 0 STRIP, and that `_CHECK_39_MIGRATOR_EXEMPTIONS` is sized
to exactly zero. Candidate set drawn from `git ls-files -- <derived pathspec>`,
never a filesystem walk; lenient skip on git-unavailable verified in code and by
T12–T15. Absence-of-backing case proven (ghost file row, ghost sweep dir,
untracked-but-present file all FAIL). — **COMPLIANT**

**ci-check-runtime-compounding** — *Evidence:* measured whole-suite runtime,
work tree `2.102s total` vs clean tree `1.987s total` — ~0.1 s for three added
legs. Check 4 adds two `git` calls only on the already-about-to-FAIL path;
leg 3 adds one `git ls-files` + one file read + O(16 rows); Check 65's advisory
is an O(records) set difference with no new I/O. No per-check budget notice
fired in either run. — **COMPLIANT**

**operating-docs-no-history-no-bloat** — *Evidence:* `pack-ops/PACK-CHAT.md`
NET-REMOVES history (the dead `EXECUTION-PLAN-V11.0.md §A.4` pointer and the
whole `## Action items (PM coordination)` section whose sole item targeted a
BD-210-deleted doc); resulting structure verified well-formed. `pack-ops/PACK-MEMORY-RATIONALE.md`
replaces a deferred-feature description ("until the separate scrubbed public
copy") with a statement of current settled reality — removing, not adding, a
description of a non-existent future. `supporting-docs/MIGRATION-v10-to-v11.md`
adds only current-behavior prose (`--no-interactive`, verified shipped), no
dated notes or provenance. Changelog and backlog are history surfaces and I did
not apply this rule to them. — **COMPLIANT**

**public-bound-no-leak** — *Evidence:* Check 93 passes both legs: "no
target-app literal-name leak in any git-tracked file (leg 1, tree-wide) and no
domain-vocabulary / codename leak on client/public surfaces (leg 2,
project-template/ + supporting-docs/ + .github/ + repo-root README + pack-root
trinity), except the one allowlisted row-name keep (OI-S7)". The change set's
strict-tier touches (`supporting-docs/`, `.github/`, repo-root `README.md`) are
covered by that pass; `changelog/` is internal tier and correctly exempt. Area 6
verified comment-only: `_CLIENT_PREFIXES` / `_CLIENT_ROOT_FILES` byte-identical,
so the check's logic is not weakened. This report keeps its own wording
abstract. — **COMPLIANT**

**boundary-investigation / P-missed-7** — *Evidence:* established independently
that `supporting-docs/MIGRATION-v10-to-v11.md` is NOT client-installed — the
install map at `scripts/init-project.sh:1622-1623` carries only
`supporting-docs/METHODOLOGY.md` and `supporting-docs/INSTALL-PROCEDURES.md`;
line 1937's mention is a `say` console string; the migrator's 12 manifest rows
and 3 sweeps are all `project-template/*`. Therefore the `pack-ops/`
qualification is correct, not a client-install regression, and both targets
(`pack-ops/MERGE-STRATEGY.md`, `pack-ops/DRY-RUN-MIGRATION.md`) exist. — **COMPLIANT**

**pack-repo-code-comment-deferrals** — *Evidence:* the area-7 sweep introduces
no deferral markers. Grep of the change set found no plain `TODO`, `FIXME`, or
"fix later"; the sweep's replacements are declarative constraint statements
("Design constraints binding on this file ... the constraints themselves still
hold"), not deferrals. — **N/A: no deferral comment is introduced or modified
by this change set.**

**graph-first-context** — *Evidence:* ran
`graphify query "references to EXECUTION-PLAN-V11.0 RESEARCH-BD-185 ... maintenance-docs v11-implementation" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500`
→ `Traversal: BFS depth=2 | ... | 136 nodes found` BEFORE any broad tree read,
using the INJECTED path verbatim (never recomputed from my own toplevel). It
widened my candidate set to surfaces I had not pre-listed, including
`maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` —
which is where Finding S2 was found. The graph indexes the pre-move committed
state, so per G2 I fell through to grep for the verification/completeness
census and declared that fallback explicitly in §1 and §6. — **COMPLIANT**

**memory-not-an-ssot** — *Evidence:* read the live in-repo SSOT at the start of
work: `backlog/_rules.md` and `changelog/_rules.md` (both quoted/applied in
§5), `backlog/BD-093.md`, and — for the two operating docs this change set
edits — BOTH pre- and post-change state via `diff -u` of
`pack-ops/PACK-CHAT.md` and `pack-ops/PACK-MEMORY-RATIONALE.md` rather than
trusting either alone. No cached rule was acted on. — **COMPLIANT**

**deferral-is-scope-creep / no-deferral-without-user-direction** — *Evidence:*
I recommended no new BD for any finding. Every finding carries an inline
disposition (S1 reword, S2 one-token repoint, S3 snapshot replace, N1/N2 polish,
N3 leave). Where I recommend "accept as-is" (N3, O1, O2) the recommendation is
backed by concrete evidence (BD-204 `Status: Deferred` and gated behind BD-215;
`fail-loud-delete-old-source`; BD-093's scope wording), not by deferral. — **COMPLIANT**

**deferred-work-tracked-anchor** — *Evidence:* nothing leaves this report as an
unanchored "should probably". Each of S1/S2/S3/N1/N2 names an exact
file:line and a concrete edit; N3, O1 and O2 carry an explicit
"leave as-is / accept" recommendation with its evidential basis, so none is a
silent deferral needing an anchor. — **COMPLIANT**

**open-item-surfacing** — *Evidence:* §10 surfaces both open items with
(1) context, (2) my own enumerated options, (3) an evidence-based
recommendation — and, where evidence is absent, an explicit refusal rather than
a guess: O1(c) "**No recommendation is offered on (c)**" and O2(c) "**I can give
no recommendation on (c)**, because I found no evidence of what, if anything,
superseded that document." No recommendation relies on memory, and none defers
work to another or a new BD. — **COMPLIANT**

**preflight-stop-means-stop** — *Evidence:* the PREFLIGHT line
(`PREFLIGHT: review complete; verification run; HEAD
ee66ba57c355d449a536360061fd46d633651fbc; about to Write report to
/Users/david/.local/state/optiquity-pack-handoff/bd093-finalreview-20260821-194946/PACK-REVIEW-BD-093-FINAL.md`)
was emitted only AFTER the review and its full verification completed — all six
verification legs green, all three guard bite-proofs executed, both censuses
finished. No verification step was skipped or left incomplete, so no partial
disclaimer is required. No stop/halt instruction was received. — **COMPLIANT**
