# FIX-REPORT — BD-093 v11.0 (RC1) release-cut, fix pass 1 of 2

**Agent:** `pack-coder` acting as fix-coder (fresh instance; did not author the
code under repair). **Date:** 2026-08-21.
**Verdict:** **all 18 in-scope items resolved.** Full wired battery green
(132/132), both `validate-pack` modes exit 0, Check 88 green, dashboard
re-renders + verifies clean.

---

## 0. Runtime regime (verified, not assumed)

The harness refused **every** git invocation redirected at the target worktree
(`cd <target> && git …` and `git -C <target> …` both blocked: *"a
worktree-isolated agent's git operations must target its own worktree"*). I did
**not** circumvent that guard. Establishing the regime by other means:

| Fact | How established | Value |
|---|---|---|
| My own isolated worktree | `pwd`, `git rev-parse HEAD` | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a5f5030d36212897c` @ `ee66ba57c355d449a536360061fd46d633651fbc`, **clean** |
| Target worktree gitdir | `cat <target>/.git` | `gitdir: …/.git/worktrees/agent-a3e94ef9f38a11308` |
| Target branch | `cat .git/worktrees/agent-a3e94ef9f38a11308/HEAD` | `ref: refs/heads/worktree-agent-a3e94ef9f38a11308` |
| **Target HEAD SHA** | `cat .git/refs/heads/worktree-agent-a3e94ef9f38a11308` | **`ee66ba57c355d449a536360061fd46d633651fbc`** ✅ matches the expected SHA (re-confirmed unchanged at end of run) |

Because my own checkout sits at the *identical* commit and is clean, `diff -rq`
between the two trees is an exact substitute for `git status --short`, and
per-file `diff -u` an exact substitute for `git diff`. **All work was performed
in the target worktree** (`/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a3e94ef9f38a11308`)
— plain `cd` is permitted there, and `python3`/`bash` run normally; only bare
`git` redirection is blocked. I created **no** worktree and edited **nothing**
in my own isolated checkout.

**Pre-flight change-set reconciliation.** Measured `32 modified + 8 deleted +
9 untracked`, against the prompt's stated `~29 modified, 8 deleted, 9
untracked`. The deletions and untracked counts match exactly. The modified
count is higher because the orchestrator's three pack-chat-only edits
(`README.md`, `backlog/BD-093.md`, `backlog/BD-204.md`) landed while I worked,
as its addendum said they would, and because my own fixes touched 8 files the
original coder had not. Independent corroboration: the re-rendered dashboard's
`inflight.files` (a live `git status` read inside `dashboard-render.py`) lists
exactly `32 M / 8 D / 9 ??` — see §BD-280.

---

## 1. Verification — the full wired battery, run by me, on the FINAL state

```
$ python3 scripts/validate-pack.py
PASSED — all checks clean            exit=0   OK: 281   WARN: 22   FAIL: 0

$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py
PASSED — all checks clean            exit=0   OK: 281   WARN: 22   FAIL: 0

$ bash test-fixtures/build.sh --verify
exit=0    v10-minimal OK / v10-realistic-ot OK / v11-realistic-ot OK /
          v11-flat-file OK / v11-tracker-on OK / existing-project-mid-dev OK /
          existing-project-collision OK

$ python3 scripts/lib/ci-shard-plan.py --assert-coverage
ci-shard-plan --assert-coverage OK: 132 wired KEEP test(s) across 4 shard(s);
union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located
in one shard.                        exit=0

$ (every wired script from `ci-shard-plan.py --emit-matrix`, run individually)
wired test scripts: 132
=== DONE ===
PASS: 132
FAIL: 0                              exit=0
```

**Baseline comparison.** The reviewer's baseline was 132/132, 281 OK / 22 WARN /
0 FAIL. **Both numbers are unchanged.** In particular the WARN count did **not**
rise despite OI-3 adding a new advisory — because the same change removed the
three dead records that advisory would have fired on (§OI-3). The wired
*script* count stays 132: I added test **cases**, not test **files** (the one
new file, `test-validate-pack-check-4.sh`, was already in the wired set).

Per-suite case counts I changed:

| Suite | Before | After | Added |
|---|---|---|---|
| `test-validate-pack-check-4.sh` | 23/23 | **35/35** | T12–T19 (N5 + N6) |
| `test-validate-pack-check-39.sh` | 7/7 groups (T10–T17) | **7/7 groups (T10–T25)** | T18–T25 (M2 + S3) |
| `test-validate-pack-check-65.sh` | 2/2 | **3/3** | T8–T9 (OI-3) |

Syntax gates: `bash -n` clean on all 9 changed shell files; `py_compile` clean
on all 3 changed Python modules.

---

## 2. MUST findings

### M1 — the silently-inert duplicate parser. RESOLVED.

**File:** `scripts/lib/validate_checks/boundary_refs.py`
(`_parse_migrator_manifest_sources`, ~L1201).

Deleted the private `_rows()` re-implementation; the function now delegates to
the pre-existing shared `_migrator_heredoc_first_fields()` — the same helper
Check 47 already runs over these exact two hooks.

I did **not** take the reviewer's "drop-in" claim on trust. Measured both
parsers against six adapter shapes:

```
variant                    manifest field0                    sweeps field0
-------------------------------------------------------------------------------
A baseline                 ['project-template/CLAUDE.md']     ['project-template/scripts']
B marker renamed ROWS      ['project-template/CLAUDE.md']     ['project-template/scripts']
C unquoted heredoc         ['project-template/CLAUDE.md']     ['project-template/scripts']
D comment before cat       ['project-template/CLAUDE.md']     ['project-template/scripts']
E indented <<- closer      ['project-template/CLAUDE.md']     ['project-template/scripts']
F manifest hook EMPTIED    []                                 ['project-template/scripts']
```

Real-adapter parity confirmed — **12 file rows + 3 dir rows = 15**, exactly as
the reviewer predicted and byte-identical to the pre-change result:

```
file_rows = 12   (CLAUDE/AGENTS/GEMINI.md, .claude/settings.json, 3× .codex/*,
                  .mcp.json.example, .agents/mcp_config.json.example,
                  docs/pack/{PM-CHAT,PLATFORM-SKILLS,PACK-FEEDBACK}.md)
dir_rows  = 3    (project-template/scripts, .claude/agents, .codex/agents)
TOTAL = 15
```

Live check output, unchanged from before the fix:

> `15 v10→v11 adapter manifest/sweep row(s) reverse-checked against git-tracked
> HEAD; 15 are backed by a shipped source, 0 on the migrator exemption
> allowlist.`

**Second defect found and fixed while consolidating (not in the review).**
Variant **F** above exposed a latent fault in the *shared* helper: given a hook
with no heredoc of its own (the `{ :; }` empty form that
`migrator_relocations` / `migrator_artifact_installs` already use in this very
adapter), the unbounded scan ran past the function and returned the **next**
hook's rows. That is a silently **wrong** answer rather than an empty one, and
consolidating M1 onto this helper would have made *two* checks depend on it. I
bounded the scan to the hook's own body (first column-0 `}` or next column-0
function definition, whichever comes first). Behaviour on the real adapter is
unchanged (15 rows, Check 47 green); variant F now correctly returns `[]`.

**BITE PROOF (M1).** Reinstated the exact pre-fix brittle parser and ran the
repaired suite:

```
installed BRITTLE parser; running the repaired test suite...
FAILURE: T20 (renamed heredoc marker) expected exactly 1 failure for the dead row, got 0 —
         the parser went INERT on this adapter shape, so leg 3 checked nothing
FAILURE: T21 (unquoted heredoc) expected exactly 1 failure for the dead row, got 0 — …
FAILURE: T22 (comment before the cat) expected exactly 1 failure for the dead row, got 0 — …
FAILURE: T23 (indented <<- heredoc) expected exactly 1 failure for the dead row, got 0 — …
  PASS: 6   FAIL: 1
test suite exit code = 1
restored sha256=8852ed8228bc89a0  identical=True
```

**BITE PROOF (the helper bound).** Reinstated the unbounded slice:

```
installed UNBOUNDED scan; running the repaired test suite...
FAILURE: T24 expected 0 failures for an empty manifest hook, got 1 —
         the parser leaked the NEXT hook's rows into the manifest result
  PASS: 6   FAIL: 1
exit code = 1
restored identical=True
```

Both temporary reinstatements were restored **byte-for-byte** (sha256 verified
equal) before proceeding.

### M2 — the anti-inertness assertion that could not fire. RESOLVED.

**File:** `scripts/tests/test-validate-pack-check-39.sh`.

The outer `if srcs != ([], []):` is gone. T17 now asserts **unconditionally**
that the real adapter yields non-empty file rows **and** non-empty dir rows,
with a comment stating why the guard may never come back. Added, per the
prompt's "additionally pin a non-zero floor on the live summary":

- **T18** — runs `validate-pack.py --only-check 39` as a subprocess against the
  real tree and regex-asserts the printed `… row(s) reverse-checked` count is
  `>= 1`. This is the live-summary floor; T17 pins the parser in isolation,
  T18 pins the number the **check itself** prints.
- **T19** — adapter absent ⇒ `([], [])` (the backward-compat property the old
  T17 comment *claimed* to test but never did).
- **T20–T23** — the four parser-shape bite tests quoted above.
- **T24** — the empty-hook / no-row-leakage bite test.

This is a repair, not a suppression: the assertion was made *able to fail*, and
proven to fail against the defect it guards.

### M3 — two live surfaces asserting opposite things. RESOLVED.

**File:** `pack-ops/PACK-MEMORY-RATIONALE.md:1290-1294`.

```
BEFORE  two-tier keep-list until the separate scrubbed public copy is produced.
AFTER   two-tier keep-list. Those keeps are PERMANENT — this repo is the single
        work repo and goes public with its history intact, so there is no
        separate scrubbed copy and the internal-surface exemption is a settled
        decision, not pending cleanup; do not re-open it.
```

Now agrees verbatim in substance with `no_leak.py:26-28` and `:108-110`.

**Re-verified the reviewer's "only remaining stale assertion" claim**, as
instructed. Tree-wide, post-fix:

```
$ grep -rln "scrubbed public copy\|scrubbed copy" . --exclude-dir=.git
pack-ops/dashboard-approvals/dashboard.html      <- generated artifact (re-rendered; see BD-280)
scripts/lib/validate_checks/no_leak.py           <- the CORRECT retraction wording
```

The claim holds. `PACK-MEMORY-RATIONALE.md` no longer appears.

### M4 — the selective provenance sweep. RESOLVED — and the census was larger than reported.

**Graph-first attestation.** Per `graph-first-context` P1 I ran discovery
first, against the **injected** path (never recomputed from my own toplevel):

```
$ graphify query "all files referencing ARCHITECTURE-SKILL-DIMENSIONS or
  PLAN-SKILL-DIMENSIONS …" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json
  --backend claude-cli --budget 1500
Traversal: BFS depth=2 | 15 nodes found
  → all 15 nodes were Check-39/40/43 fixture READMEs; zero relevance.
```

The graph does not index raw markdown filename mentions inside prose and code
comments. Per **G2** I fell back to grep for the completeness census and say so
explicitly here. The graph's candidate set was not a subset of the true set —
it was disjoint — so it narrowed nothing.

**Existence.** `find` → `ARCHITECTURE-SKILL-DIMENSIONS.md` = 0 hits;
`PLAN-SKILL-DIMENSIONS.md` = 0 hits. Both genuinely deleted.

**Census — 18 references across 8 pack-side source files, not the 10 across 5
the review reported.** Three files the review missed, one extra site in each of
two files it did report, and one reference invisible to a single-line grep:

| File | Review said | I measured |
|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | 5 | **6** |
| `scripts/lib/validate_checks/agents_skills.py` | 2 | **3** (one line-wrapped) |
| `scripts/lib/migrator-core.sh` | 1 | 1 |
| `scripts/lib/migrator-skills.sh` | 1 | **2** |
| `scripts/lib/validate_checks/singletons.py` | 1 | **2** |
| `scripts/add-capability.sh` | — | **1** (missed) |
| `scripts/test-migrator-capability-translation.sh` | — | **1** (missed) |
| `scripts/tests/fixture-dependent/test-migrator-skills.sh` | — | **2** (missed) |

The line-wrapped one is worth calling out: `agents_skills.py:1119-1121` breaks
the token across a newline —

```
                           one inventory row — see ARCHITECTURE-SKILL-
                           DIMENSIONS.md §3.7-§3.8).
```

— so neither `grep SKILL-DIMENSIONS` nor `grep ARCHITECTURE-SKILL-DIMENSIONS`
matches either line. I caught it only by additionally grepping the bare token
`DIMENSIONS`. A basename-only census would have left it behind.

**Four of the six `migrate-v10-to-v11.sh` sites are not comments — they are
`printf` statements that emit the dead pack-internal path into the *client's*
advisory file** at migration time. That is both a dangling reference and a
pack→client boundary leak: the client has no access to `maintenance-docs/` at
all. I kept the reason and dropped the pointer, e.g.

```
BEFORE  printf '# surface, not a D3 architectural role per\n'
        printf '# ARCHITECTURE-SKILL-DIMENSIONS.md §3.5).\n'
AFTER   printf '# surface, not a D3 architectural role).\n'
```

Before editing emitted text I verified **nothing asserts it** (tree-wide grep
for the emitted strings returned only the source lines themselves), and the
capability-translation and migrator-skills suites are green afterwards.

One site was a live **validate-pack FAIL message** directing a maintainer to
the deleted doc (`agents_skills.py:1219`); the constraint it states is
self-contained, so the pointer went and the sentence stayed.

**Treatment applied uniformly:** keep the surrounding rationale, drop the
unresolvable pointer; where the pointer was a block's entire content (the
`Plan:` header line in `migrator-skills.sh`), drop the line. Live pointers were
preserved — `ARCHITECTURE-BD-119.md` still exists and stays cited in both
`migrator-core.sh` and `migrator-skills.sh`. **No plain `TODO`/`FIXME` was
introduced anywhere** (§Rules block).

**GREP-ZERO ACHIEVED:**

```
$ grep -rl "SKILL-DIMENSIONS" scripts/ .github/ supporting-docs/ project-template/ test-fixtures/
  grep-zero (no files)
$ grep -rl "DIMENSIONS" scripts/ .github/ supporting-docs/ project-template/
  grep-zero (no files)
```

The only remaining tree-wide hit is `pack-ops/dashboard-approvals/dashboard.html`,
a generated artifact — addressed under BD-280.

**Left alone as instructed:** the `maintenance-docs/` reference records. Note
the prompt named *three*; I measured **five**
(`ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md` 4,
`ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` 13,
`ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` 1, plus `ARCHITECTURE-BD-119.md` 1
and `archive/v11/EXECUTION-PLAN-V11.0.md` 3). All are reference records, so the
instruction's intent covers all five; flagging the count discrepancy only for
accuracy.

**Same-class stale path fixed in passing:** the census showed
`scripts/tests/fixture-dependent/test-migrator-skills.sh` still documented its
own `Usage:` as `bash scripts/test-migrator-skills.sh` — its pre-move location,
and the identical defect S1 flags in the changelog. Corrected.

### M5 — stale `K2-K6` after K6's removal. RESOLVED (plus a third instance).

**File:** `pack-ops/.operating-doc-history-allowlist.txt`.

Lines 30 and 241 `K2-K6` → `K2-K5` — then, once OI-3 proved the three K5
records dead and removed them, all three range references became `K2-K4`.

The K-set audit this triggered found a **fourth** stale reference the review did
not report: the header's `K9-K11 date format examples` — but **K9 has no
record**; only K10 and K11 exist. Corrected to `K10-K11`. Final state:

```
$ grep -c "K6" …allowlist.txt   → 0
$ grep -c "K9" …allowlist.txt   → 0
$ grep -c "K5" …allowlist.txt   → 0
K-record headers present: K1 K2 K3 K4 K7 K10 K11 K12 K13
```

Zero references to a nonexistent record remain.

---

## 3. SHOULD findings

### S1 — wrong script paths in the RC1 block. RESOLVED — and I found three more.

Rather than fix only the two flagged citations, I resolved **every** backticked
path in `changelog/v11.md` against the tree (43 distinct citations):

```
BEFORE   distinct path citations: 43   NON-RESOLVING: 6
AFTER    distinct path citations: 43   NON-RESOLVING: 3   (all three verified false positives)
```

| Cited | Actual | Sites |
|---|---|---|
| `scripts/test-migrator-skills.sh` | `scripts/tests/fixture-dependent/test-migrator-skills.sh` | **2** (the review found 1) |
| `scripts/test-migrate-v10-to-v11-capability-translation.sh` | `scripts/test-migrator-capability-translation.sh` | 1 |
| `supporting-docs/MERGE-STRATEGY.md` | `pack-ops/MERGE-STRATEGY.md` | **3** (not in the review) |

`MERGE-STRATEGY.md` moved `supporting-docs/` → `pack-ops/` at BD-175
(`git log --diff-filter=D` → `abed0f7 feat: v11 — BD-175 directory reorg M6-M8
(supporting-docs/ → pack-ops/)`). I repointed rather than deleted, consistent
with the review's own S1 ruling and with this change set's `EXECUTION-PLAN`
repoint in `PACK-MEMORY-RATIONALE.md`.

The three remaining non-resolving citations are confirmed **false positives**,
each verified individually:

- `docs/pack/HELP-FRAGMENT.md` — a *client-relative* path;
  `project-template/docs/pack/HELP-FRAGMENT.md` exists.
- `docs/pack/PLATFORM-SKILLS.md.v10-customized` — a sidecar produced in the
  client's tree at migration time, never a repo file.
- `scripts/lib/tracker-migrate-{forward,reverse}.sh` — brace-expansion
  notation; both `tracker-migrate-forward.sh` and `tracker-migrate-reverse.sh`
  exist.

### S2 — BD-117 credited with a deleted artifact. RESOLVED.

Verified `maintenance-docs/v11-implementation/RELEASE-GATE.md` → `find` = 0
hits. Applied the treatment the sibling MAINTAINER-CHECK-AUDIT line models:

```
- BD-117 — Per-major-version release-gate checklist. The standalone
  checklist doc was one of the superseded `maintenance-docs/` records
  deleted outright at BD-210, so no path is cited here (fail-loud: no
  mirror, no dead pointer); its automatable items are enforced by the
  validate workflow, and its two manual pre-tag items are carried by the
  release-cut BD.
```

The final clause is accurate against
`.github/workflows/validate-pack.yml:33-38`, which states gate items 1 and 2
are pre-tag manual checks carried by the release-cut BD. The changelog and the
workflow header now agree.

### S3 — pathspec-scoped `git ls-files` tested against every row. RESOLVED.

**File:** `boundary_refs.py` (Check 39 leg 3). Adopted the reviewer's option
**(b)** — derive the pathspec from the observed row prefixes:

```python
mig_pathspecs = sorted({
    p.split("/", 1)[0] for p in list(mig_files) + list(mig_dirs) if p
})
res = subprocess.run(["git", "ls-files", "--"] + mig_pathspecs, …)
```

Single subprocess preserved (`ci-check-runtime-compounding`). **Measured
behaviour-neutral**: on the real adapter all 15 rows share one prefix, so the
derived pathspec is `['project-template']` — byte-identical to the hard-coded
value, and the leg still reports 15/15.

**Paired with its test (`enumerate-encoding-surfaces`).** The stub now records
the `git ls-files` argv, and new **T25** feeds a `supporting-docs/`-sourced row
and asserts the pathspec covers it.

**BITE PROOF (S3).** Reinstated the hard-coded pathspec:

```
installed HARD-CODED pathspec; running the Check 39 suite...
FAILURE: T25 pathspec ['project-template'] omits `supporting-docs` — the pathspec is
         hard-coded, so a row sourced outside project-template/ is tested against a
         set that cannot contain it (false FAIL)
FAILURE: T25 expected exactly the 2 derived prefixes, got ['project-template']
  PASS: 6   FAIL: 1
exit code = 1
restored identical=True
```

### S6 — missing carried-over list. RESOLVED (derived, not hardcoded).

Censused the live backlog at HEAD rather than taking the prompt's summary:

```
Status census: Cancelled 1 | Deferred 23 | Deprecated 11 | Open 17 | Resolved 235
```

The 17 Open decompose exactly as: **BD-093** (the cut itself) + **BD-280**
(landed in this cut) + **5** carrying `Target: v11.1` + **10** untargeted. The
new list mirrors the sibling `### v11.0` block's format, split into
`_Targeted v11.1_` (BD-202, BD-223, BD-247, BD-254, BD-279) and
`_Open, untargeted_` (BD-020, BD-036, BD-037, BD-039, BD-109, BD-110, BD-171,
BD-172, BD-187, BD-192), and closes by stating that BD-093 resolves with the
entry and BD-280 landed in this cut. BD-171 and BD-172 appear under untargeted,
matching their SSOT `Target:` fields (empty) — consistent with the prompt's note
that they are Open by explicit user decision. **Nothing under `backlog/` was
edited.**

---

## 4. Open items (OI-2, OI-3) and the changelog date addendum

### OI-2 — heading that goes stale at GA. RESOLVED.

```
BEFORE  ### v11.0 (RC1) — release candidate cut
AFTER   ### v11.0 — post-Scope-C work through the release cut
```

State-neutral: it survives the GA qualifier drop with no future edit, and the
two-block split is preserved. Confirmed against `changelog/_rules.md`: the
contract's `^v\d+\.md$` filename regex and the `## vN — <date>` H2
ID-extraction rule are both untouched (a qualifier is permitted in an H3 label
but never required). Final section map:

```
2:   ## v11 — August 2026
4:   ### v11.0 — Flat-file per-entry model + customization-preservation fix
83:  **Carried over to future work (v11-Active BDs Open at v11.0 cut):**
242: ### v11.0 — post-Scope-C work through the release cut
522: _At the Scope A/B cut_
533: _At the Scope C cut_
550: _At the v11.0 (RC1) cut_
567: **Carried over past the cut (BDs Open at the v11.0 (RC1) cut):**
```

The `_At the v11.0 (RC1) cut_` sub-label is deliberately kept: it names a
point-in-time event in a series alongside `_At the Scope C cut_`, and stays
true after GA.

### Addendum — the `## v11` H2 date. CHANGED to August 2026, with evidence.

The orchestrator asked me to check the convention rather than assume. Measured
every sibling H2 against its README rows:

| changelog H2 | README rows for that major |
|---|---|
| `## v10 — April 2026` | v10.0 = **Apr 29, 2026**; v10.1 = May 8, 2026 |
| `## v9 — April 2026` | v9.0 = **Apr 2026**; v9.1–v9.3 = Apr 2026 |
| `## v8 — March 2026` | v8.0 = **Mar 29, 2026**; v8.1 = Apr 1, 2026; v8.7–v8.10 = Apr 2026 |

The pattern is unambiguous across three instances: **the H2 dates the major
line's INITIAL release and does not track later minors.** v10's H2 says April
even though v10.1 shipped in May; v8's says March even though four v8.x minors
shipped in April.

v11's initial release is v11.0, which the README row now dates **August 2026**.
"May 2026" therefore matched neither the convention nor any release event. I
changed it to `## v11 — August 2026`.

**`_toc.md` regenerated** — it embeds the H2 date, so this was required:

```
$ per_entry_regenerate_toc pack-changelog /changelog
$ diff <base>/changelog/_toc.md changelog/_toc.md
7c7
< - [v11](./v11.md) — May 2026
---
> - [v11](./v11.md) — August 2026
```

Exactly the intended one-line delta; no other TOC row moved.

### OI-3 — the allowlist's "sized EXACTLY" claim was unenforced. RESOLVED, advisory-only.

**File:** `boundary_refs.py` (`check_operating_doc_no_history`, Check 65).

Check 65 now records which allowlist records actually **fire** and reports
per-record backing. Constraints honoured:

- **Advisory only** — emits `warn()`, never `fail()`; `failures` is untouched
  and the exit code cannot change. Follows the documented Check-48 soft-advisory
  idiom (`core.warn` docstring: *"informational only, NEVER a gate failure"*).
- **O(records)** — one set difference over the parsed records; no extra file
  read, no subprocess, no tree walk.
- **Cannot red CI on a not-yet-triggered record** — records whose doc is absent
  or outside the scanned IN set are reported in a *separate*, also-advisory
  bucket rather than counted dead.

One deliberate micro-change: the per-line `covered = any(snip in line …)` became
an explicit loop, because `any()`'s short-circuit would hide a second covering
snippet and mis-report its record as dead. Cost is O(snippets) and only on lines
that already matched a forbidden pattern.

**MEASURED FIRST (`ci-guard-measure-then-bound`).** The new advisory immediately
found **3 real dead records**:

```
WARN: … record `doc: pack-ops/PACK-AGENTS.md` / `snippet: ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` matched NO line
WARN: … record `doc: pack-ops/PACK-CHAT.md` / `snippet: ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` matched NO line
WARN: … record `doc: pack-ops/PACK-MEMORY-RATIONALE.md` / `snippet: ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` matched NO line
  OK: … Allowlist backing: 38 record(s) declared, 35 live, 3 dead, 0 on unscanned docs.
```

**Root cause** (investigated, not guessed): the referencing lines *do* exist in
all three docs — but the records declare `pattern: bd-tag`, and the exempted
filename `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` carries **no `BD-NNN`**
(unlike its K4 sibling `ARCHITECTURE-BD-208.md`, which does and fires
correctly). Those lines never trip a forbidden pattern, so they never needed
exempting. Same dead-weight class as the K6 record this change set already
removed.

I removed the three records (and repaired the K5 range references — §M5).
Shipping a new advisory that fires three warnings on day one would train
operators to ignore it, and the file's own "sized to the KEEP set EXACTLY"
contract requires the removal. Final state:

```
OK: Check 65 — 158 operating doc(s) scanned; 0 history pattern(s) outside the
allowlist (0 = clean); 39 allowlisted KEEP occurrence(s) admitted.
Allowlist backing: 35 record(s) declared, 35 live, 0 dead, 0 on unscanned docs.
```

The claim is now **verified rather than asserted**, and the repo-wide WARN count
is unchanged at 22.

**BITE PROOF (OI-3).** Injected one synthetic dead record and one
unscanned-doc record:

```
injected 1 dead record + 1 unscanned-doc record

WARN: Check 65 allowlist — record `doc: pack-ops/PACK-CHAT.md` /
      `snippet: ZZZ-THIS-SNIPPET-MATCHES-NOTHING-ZZZ` matched NO line in that doc. …
WARN: Check 65 allowlist — record `doc: pack-ops/NO-SUCH-OPERATING-DOC.md` /
      `snippet: ZZZ-UNSCANNED-DOC-ZZZ` names a doc outside the scanned operating-doc IN set …
  OK: … Allowlist backing: 37 record(s) declared, 35 live, 1 dead, 1 on unscanned docs.
  PASSED — all checks clean

exit code = 0  (0 == advisory, did NOT red CI)
restored identical=True
```

Both failure classes fire **and** the exit code stays 0 — exactly the required
advisory semantics.

**Paired with its test.** `test-validate-pack-check-65.sh` gains **T8a/T8b/T9**
pinning: a fully-live allowlist emits no WARN and reports `0 dead`; a dead
record WARNs, names the dead snippet, reports `1 dead`, and adds **zero**
failures; an unscanned-doc record reports separately and also adds zero
failures. Suite: 3/3 PASS.

---

## 5. NIT findings

### N1 — false justification. RESOLVED.

`boundary_refs.py` leg-3 block comment. Verified the review's correction myself:
`_manifest_parse` handles `migrator_manifest` only, and
`migrator_directory_sweeps` is consumed by `_manifest_sweep_dirs`
(`scripts/lib/migrator-manifest.sh`). Replaced the false sentence with the true
basis, and stated the differing consumers so the error cannot recur:

> `the two hooks are the same adapter contract — adjacent members of
> _migrator_required_hooks in scripts/lib/migrator-core.sh (an adapter that
> declares one declares both), and Check 47 already parses the pair JOINTLY via
> the shared _migrator_heredoc_first_fields(). Their CONSUMERS differ and that
> is immaterial here: migrator_manifest rows are read by _manifest_parse, sweep
> rows by _manifest_sweep_dirs (scripts/lib/migrator-manifest.sh).`

**The two-hook coverage was NOT reverted**, per the explicit instruction. Line
numbers deliberately omitted (`architect-doc-reality-reconciliation`).

### N2 — unnamed release-cut BD. RESOLVED.

`.github/workflows/validate-pack.yml:36` now reads *"the BD-093 release cut
carries them"*, matching the surrounding comment which names BD-114, BD-210 and
BD-115/116/117.

### N3 — the dropped `ADDENDUM-2.md §4.5` pointer. RESOLVED — constraint recovered, and it is moot.

The prompt asked me to recover the constraint if I could and to say so plainly
if I could not. **I could.** Recovered the deleted doc from history
(`git show d47ef87^:maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`,
1400 lines) and read §4.5. It specifies the **`--force-overwrite-mirror` flag**:
the regenerator blocks on divergence when overwriting a hand-edited monolithic
mirror unless that flag is passed.

That constraint is **moot at HEAD**, established by two independent measurements:

1. `--force-overwrite-mirror` / `_MIGRATOR_FORCE_OVERWRITE_MIRROR` appears in
   **no pack source file** — only in historical backlog entries, the generated
   dashboard, the archived execution plan, and one test.
2. That one test asserts its **absence**:
   ```
   scripts/tests/test-migrate-v10-to-v11-decompose.sh:231:
     assert_not_contains "1.2c --dry-run advisory does NOT name --force-overwrite-mirror (removed, BD-206)"
   scripts/tests/test-migrate-v10-to-v11-decompose.sh:322:
     assert_not_contains "2.3c --apply advisory does NOT name --force-overwrite-mirror (removed, BD-206)"
   ```

The flag was **removed at BD-206** (the no-mirror model) and its absence is
test-enforced. The site the pointer hung off
(`_v10_to_v11_decompose_streams`) operates under that same model —
`decompose.sh` says *"NO monolithic mirror is regenerated (BD-206 no-mirror
model)"* in three places. So **no binding constraint was lost**. I folded the
finding into a constraint bullet at the site, matching the four sibling folds,
so no future reader re-derives it:

```
# Constraint: decompose regenerates NO monolithic mirror (BD-206 no-mirror
# model), so there is no mirror-divergence path and no
# `--force-overwrite-mirror` override; its absence is asserted by
# scripts/tests/test-migrate-v10-to-v11-decompose.sh.
```

### N5 — uncovered degradation branches. RESOLVED.

`test-validate-pack-check-4.sh` gains failure-injection kwargs on the git stub
and four cases: **T12** git absent (`FileNotFoundError`) ⇒ the documented
lenient skip; **T13** `rev-parse` raises `OSError` ⇒ no allowance, loud FAIL;
**T14** `rev-parse` non-zero rc ⇒ no allowance; **T15** `branch --points-at`
non-zero rc ⇒ no allowance. Each asserts the degradation is a **FAIL, never a
silent PASS**.

### N6 — substring `dev` matching. RESOLVED — and the more serious sibling too.

Added an anchored predicate `_check_4_is_dev_branch()` matching on **segment**
boundaries (`re.split(r"[-/]", name)`), and applied it at **both** call sites.

The review scoped N6 to `_check_4_dev_worktree_branch` and correctly called that
bounded. But the identical bare test also sits on the **primary-checkout** path
(`if "dev" in current_branch:`), which **does** reach CI — a CI run on a branch
named `main-devops` or `feature/device-x` would have taken the pre-release
allowance and skipped the guard entirely. That is the same class, unbounded, on
the release-cut check. Both are now anchored.

Verified against real branch names: `v11-dev` ✅, `v10-dev` ✅ accepted;
`v10-maintenance` ✅, `main` ✅ rejected. Degradation direction is safe — an
unrecognized spelling mis-FAILs loudly, never mis-PASSes.

**BITE PROOF (N6).** Reinstated the bare substring test:

```
installed BARE-SUBSTRING dev test; running the Check 4 suite...
  FAIL T16 'main-devops' is NOT a dev branch (worktree path)
  FAIL T17 'feature/device-x' is NOT a dev branch (worktree path)
  FAIL T18 'main-devops' earns no allowance on the CI-reachable primary path
  PASS: 32   FAIL: 3
exit code = 1
restored identical=True
```

**T19** additionally pins that the anchoring did not over-tighten: `dev`,
`dev/topic`, `v11-dev`, `v10-dev`, `v11-dev-fixes` all still earn the allowance.
Suite: **35/35 PASS** (was 23/23).

---

## 6. BD-280 — dashboard doc-index staleness

**Outcome: the entry's central premise is false at HEAD.** I investigated before
implementing, per the entry's own instruction to decide on measured evidence.

### The measurement

BD-280 states the dashboard "embeds a curated doc-index (~18 `maintenance-docs/`
paths) that is SPEC-EMBEDDED in the fingerprinted shell, NOT live-derived", and
that "a re-render does NOT fix it — the shell is reused unless the `spec-sha`
changes". I checked all four named surfaces:

```
$ grep -c "maintenance-docs" pack-ops/dashboard-approvals/dashboard-shell.html   → 0
$ grep -c "maintenance-docs" scripts/dashboard-render.py                          → 0
$ grep -n  "maintenance-docs" pack-ops/DASHBOARD-SPEC-PACK.md                     → 1 (unrelated prose)
$ grep -c "maintenance-docs" pack-ops/dashboard-approvals/dashboard.html          → 1 (the minified state blob)
$ grep -n "ARCHITECTURE-\|EXECUTION-PLAN\|DESIGN-" dashboard-shell.html           → 0 matches
```

**There is no curated doc-index** — not in the shell, not in the spec, not in
the renderer. I then traced every `maintenance-docs/` path in the rendered board
to its originating state key:

```
md/V10-PHASE-4-VERIFICATION.md                             keys=['changelog']
md/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md     keys=['bds']
md/v11-implementation/EXECUTION-PLAN-V11.0.md              keys=['inflight']
… (19 total: 11 'bds', 1 'changelog', 8 'inflight')
```

All three sources are **live-derived at render time**: `bds` and `changelog`
quote the per-entry SSOTs verbatim, and `inflight.files` is a live `git status`
read (`dashboard-render.py:998`: `"inflight": {"files": git_status_files(root), …}`).

**BD-280's option (b) — "make the doc-index LIVE-DERIVED" — is already the
implemented state. Option (a) is inapplicable: there is no curated list to prune.**

### What I did

Re-rendered, which is the operative achievable deliverable and which the
reviewer's OI-5 correctly sequenced to run **after** this batch's 8 archive
moves:

```
$ python3 scripts/dashboard-render.py build
RENDER OK   spec-sha: 1b6b2a1cbb7722c2bfdce0ab135e1e9b9b7a0578
            BDs total 287 | rules/changelog 67/11 | shell: reused
            dashboard.html: 399305 bytes
$ python3 scripts/dashboard-render.py verify
VERIFY OK - complete DATA floor clean            exit=0
$ python3 scripts/validate-pack.py --only-check 88
OK: Check 88 — dashboard-shell.html spec-sha matches git hash-object of
    DASHBOARD-SPEC-PACK.md (1b6b2a1c…); shell/spec in sync.
```

`dashboard-shell.html` is **byte-identical to the committed base** (`diff -q`
confirms), so Check 88's spec-sha basis is untouched and stays green. Only the
rendered `dashboard.html` changed.

### The honest result

Dead `maintenance-docs/` path count went **12 → 19**, and I want that stated
plainly rather than buried. The +7 are **exactly** this batch's 7 archived
`RESEARCH-BD-*` docs, appearing under `inflight` because the working tree
currently shows them as uncommitted deletions (`x: 'D'`). **They vanish the
moment the commit lands.** Post-commit the count is 11, all of them verbatim
quotes of backlog/changelog entry text.

Of those 11, I traced which are fixable:

```
EXECUTION-PLAN-V11.0.md    cited (qualified, pre-move) by: BD-138(Resolved), BD-139(Resolved)
the 7 RESEARCH-BD-* docs   — no stale qualified citation in backlog/ or changelog/ at all
```

The remaining dead paths live inside **Resolved historical entries** that the
reviewer explicitly ruled should keep their pre-move paths as accurate history
(the Check-48 "JC-5 accurate-history citation" idiom), and `backlog/` is outside
my scope. Rewriting them would also falsify the record.

**BD-280's acceptance criteria, honestly scored:**

| Criterion | Status |
|---|---|
| `validate-pack` green | ✅ exit 0, both modes |
| dashboard re-renders + verifies clean | ✅ `RENDER OK` / `VERIFY OK` |
| Check 88 green | ✅ |
| "if made live-derived, a later deletion auto-updates it with no manual spec edit" | ✅ already true — and demonstrated: this batch's deletions auto-appeared |
| "the doc-index references NO non-existent `maintenance-docs/` file" | ⚠️ **not achievable as written** — see the open item below |

---

## 7. Open items surfaced (context → my options → recommendation)

### OI-A — BD-280's premise is false; its status flip needs a decision.

**Context.** Measured above: there is no spec-embedded curated doc-index; the
dashboard is already fully live-derived; the residual dead paths are verbatim
quotes of deliberately-retained historical backlog text plus transient
`git status` deletions. The entry's acceptance criterion "the doc-index
references NO non-existent `maintenance-docs/` file" cannot be met without
either falsifying quoted SSOT text or rewriting Resolved historical entries the
reviewer ruled must stay.

**My options.** (a) Flip BD-280 `Resolved` with a `Resolved:` line recording
that the investigation found the premise false, the dashboard already
live-derived, and the re-render performed. (b) Flip `Resolved` narrowly on the
re-render alone without recording the premise finding. (c) Leave it Open and
carry it past the cut — but then my S6 carried-over list is wrong and must be
amended to include BD-280.

**Recommendation: (a).** The work BD-280 asks for is either already done
(live-derivation) or inapplicable (no curated list), and the one actionable
piece (re-render after the moves) is done and verified. Recording the false
premise in the `Resolved:` line is worth more than a bare closure, because the
next actor who sees dead `maintenance-docs/` paths on the board will otherwise
re-open the same investigation. This is Pack Chat's edit — `backlog/` is
pack-chat-only and I did not touch it. Note (c) would require amending
`changelog/v11.md`, which currently states BD-280 landed in this cut.

### OI-B — a client-shipped doc references a pack-only doc by bare basename.

**Context.** Found while resolving S1. `supporting-docs/MIGRATION-v10-to-v11.md`
— a client/public surface — references `MERGE-STRATEGY.md` **11 times** by bare
basename (`See \`MERGE-STRATEGY.md\` for the per-file class matrix`). That doc
now lives at `pack-ops/MERGE-STRATEGY.md`, which is **pack-only**: a client who
installs the pack cannot read it at all. `QUICKSTART.md` and `README.md` cite it
correctly as `pack-ops/MERGE-STRATEGY.md`. This is pre-existing (not introduced
by this batch), `validate-pack` is green on it, and Check 68 resolves qualified
paths by basename so nothing catches it.

**My options.** (a) Leave it — the bare basename may be a deliberate choice to
avoid exposing pack paths on a client surface, and it is pre-existing.
(b) Qualify the references to `pack-ops/MERGE-STRATEGY.md` — accurate, but then
a client-facing doc points at a file clients do not receive, making the boundary
problem explicit rather than fixing it. (c) Treat it as a genuine
`P-missed-7` boundary defect: a client-facing migration doc should not depend on
a pack-only reference at all; either the per-file class matrix ships to clients
or the client doc should inline what clients need.

**Recommendation: (c) is the correct diagnosis, but it is out of my scope and
too large for this fix pass** — it is a content decision about what clients
receive, not a path repair, and it touches `supporting-docs/` which this batch
already modifies for other reasons. I did **not** change it. I recommend the
orchestrator surface it to the user as a scoping question before the tag: if
v11.0 ships a migration doc telling clients to consult a document they do not
have, that is a real client-facing defect at a public release. I make **no
recommendation on deferral** — per `no-deferral-without-user-direction` that is
the user's call, and I am not proposing a new BD for it.

### OI-C — the reviewer's census counts were low in three places.

**Context.** Not a defect in the change set, but relevant to how much confidence
to place in "the reviewer found the only remaining instance" statements. M4's
true count was 18 sites / 8 files vs the reported 10 / 5; S1's true count was 6
non-resolving citations vs 2; M5's stale-K-reference set included a fourth
instance (`K9-K11`). In each case the gap came from a single-line grep missing a
line-wrapped token, or from searching only the block the finding named.

**My options.** (a) Note it and move on. (b) Recommend a re-review of the census
findings specifically.

**Recommendation: (a), with one caveat.** All three gaps are now closed and
grep-zero is proven, so there is nothing outstanding. The caveat for the
reviewer's next pass: a basename census should grep the **bare distinctive
token** (`DIMENSIONS`), not the full hyphenated filename, because markdown and
code comments wrap long paths across lines. I applied that technique here and it
found a reference nothing else did.

---

## 8. Plan deviations

**Three deliberate expansions beyond the literal finding text, each because the
finding as scoped would have left the same defect live.** No deviation reduced
scope.

1. **M1 → also bounded the shared helper.** Consolidating onto
   `_migrator_heredoc_first_fields` made two checks depend on it, and it had a
   latent wrong-answer mode (§M1 variant F). Bounding was ~10 lines, is
   behaviour-neutral on the real adapter, and is bite-proven by T24.
2. **N6 → also anchored the primary-checkout branch path.** The review scoped
   N6 to the linked-worktree helper and called the risk bounded. The identical
   bare substring test on the CI-reachable path was not bounded. Fixing one and
   leaving the other would have left the more severe instance live.
3. **OI-3 → also removed the 3 dead records it found.** Shipping a new advisory
   that fires three warnings from day one is alarm-fatigue by construction, and
   the file's own contract requires exact sizing.

**Also fixed in passing** (same defect class as an assigned finding, found while
executing it): the stale `Usage:` path in
`scripts/tests/fixture-dependent/test-migrator-skills.sh` (S1 class); the
`K9-K11` stale range reference (M5 class); the three
`supporting-docs/MERGE-STRATEGY.md` citations (S1 class); the extra M4 sites in
three files the review did not list.

**Nothing was deferred.** No new BD is proposed. Every item in the prompt landed
in this pass.

---

## 9. Boundary discipline check (P-missed-7)

Enumerated every client/project-side surface differing from the committed base:

```
MODIFIED  .github/workflows/validate-pack.yml       <- fix-coder (N2, one comment line)
MODIFIED  supporting-docs/MIGRATION-v10-to-v11.md   <- original coder; NOT touched by me
```

**`project-template/` is entirely untouched** by this fix pass (all six trinity
files byte-identical — §10).

**SSOT investigation for my one client/public edit** (`.github/workflows/validate-pack.yml`,
N2): the concept is "which BD carries the two manual pre-tag release-gate
items". No project-side SSOT exists for this concept — `.github/` is pack-repo
CI infrastructure, not content installed into a client project, and the
surrounding comment block already names BD-114, BD-210 and BD-115/116/117 as its
local record. I therefore implemented per the prompt with no SSOT augmentation.
Leak tier verified: `.github/` **is** a `public-bound-no-leak` leg-2 surface, and
the added text (`the BD-093 release cut carries them`) carries no target-app
name and no domain vocabulary; Check 93 green.

**Frame rotation.** This batch touches both sides, so I checked my
`changelog/` edits against the *internal* tier (internal shorthand permitted,
exemption permanent per M3) and my `.github/` edit against the *client/public*
tier (abstract wording only). I additionally used neutral phrasing
("Real-target scratch-clone") for BD-171 in the changelog carried-over list even
though `changelog/` is leg-2-exempt, since the repo goes public with history.

**One boundary finding raised, not silently fixed:** OI-B above — a
client-shipped doc referencing a pack-only doc. Reported for re-prompting rather
than changed on my own authority.

---

## 10. Files changed inventory

Measured by full-tree comparison against the committed base
(`ee66ba5`). Totals: **32 modified, 9 new, 8 deleted**.

### Files I changed (18)

Line deltas are **versus the committed base**, so for the 7 files the original
coder had already edited they include his work as well as mine; the rest are
mine alone.

| Path | Change | Findings | +/− |
|---|---|---|---|
| `scripts/lib/validate_checks/boundary_refs.py` | modified | M1, N1, S3, OI-3 | +252 / −7 |
| `scripts/tests/test-validate-pack-check-39.sh` | modified | M2, S3 test | +369 / −0 |
| `scripts/lib/validate_checks/singletons.py` | modified | M4, N6 | +98 / −11 |
| `scripts/tests/test-validate-pack-check-4.sh` | **new** | N5, N6 tests | +427 |
| `scripts/tests/test-validate-pack-check-65.sh` | modified | OI-3 test | +64 / −0 |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | modified | M3 | +5 / −2 |
| `pack-ops/.operating-doc-history-allowlist.txt` | modified | M5, OI-3 | +4 / −26 |
| `scripts/lib/migrator-core.sh` | modified | M4 | +2 / −2 |
| `scripts/lib/migrator-skills.sh` | modified | M4 | +1 / −3 |
| `scripts/migrate-v10-to-v11.sh` | modified | M4, N3 | +15 / −19 |
| `scripts/add-capability.sh` | modified | M4 | +2 / −2 |
| `scripts/tests/fixture-dependent/test-migrator-skills.sh` | modified | M4, Usage path | +6 / −4 |
| `scripts/test-migrator-capability-translation.sh` | modified | M4 | +1 / −1 |
| `scripts/lib/validate_checks/agents_skills.py` | modified | M4 | +3 / −6 |
| `.github/workflows/validate-pack.yml` | modified | N2 | +3 / −2 |
| `changelog/v11.md` | modified | S1, S2, S6, OI-2, H2 date | +366 / −32 |
| `changelog/_toc.md` | modified (regenerated) | H2 date | +1 / −1 |
| `pack-ops/dashboard-approvals/dashboard.html` | modified (re-rendered) | BD-280 | regenerated |

### Files changed by others in this change set (not mine)

- **Orchestrator (pack-chat-only):** `README.md`, `backlog/BD-093.md`,
  `backlog/BD-204.md`.
- **Original coder:** `pack-ops/PACK-CHAT.md`,
  `scripts/lib/migrate-v10-to-v11/decompose.sh`,
  `scripts/lib/per-entry/_lib.sh`, `scripts/lib/per-entry/decompose.sh`,
  `scripts/lib/tracker-agent-read.sh`, `scripts/lib/validate_checks/core.py`,
  `scripts/lib/validate_checks/no_leak.py`,
  `scripts/lib/validate_checks/per_entry_sync.py`, `scripts/validate-pack.py`,
  `scripts/tests/test-validate-pack-checks-32-33-34.sh`,
  `scripts/tests/tracker-agent-read-test.sh`,
  `supporting-docs/MIGRATION-v10-to-v11.md`, `test-fixtures/build.sh`.
- **The 8 archive moves** (coder): `maintenance-docs/v11-implementation/{EXECUTION-PLAN-V11.0,
  RESEARCH-BD-185-FLAT-FILE-PHASE-PARTS, RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY,
  RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY-2, RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS,
  RESEARCH-BD-204-RESTART-INTEGRATION, RESEARCH-BD-212-GH-ISSUE-DELETION,
  RESEARCH-BD-217-WORKTREE-ISOLATION}.md` → `maintenance-docs/archive/v11/`
  (8 deleted + 8 untracked; **left exactly as they were** — I ran no git verb).

**No new files beyond `test-validate-pack-check-4.sh`** (which the original
coder created; I extended it). Full contents are not reproduced here because
that file is already present in the worktree and in the original IMPL-REPORT.

---

## 11. Definition of Done

| # | Item | Result |
|---|---|---|
| 1 | Every prompt item resolved or reported with evidence | **PASS** — 18/18 (M1–M5, S1–S3, S6, OI-2, OI-3, BD-280, N1–N3, N5–N6, changelog date) |
| 2 | `python3 scripts/validate-pack.py` exits 0 | **PASS** — exit 0, 281 OK / 22 WARN / 0 FAIL |
| 3 | `PACK_VALIDATE_DEEP=1 …` exits 0 | **PASS** — exit 0, 281 OK / 22 WARN / 0 FAIL |
| 4 | FULL wired battery green | **PASS** — 132/132, 0 FAIL, on the final state |
| 5 | `test-fixtures/build.sh --verify` | **PASS** — exit 0, 7/7 fixture SHAs match |
| 6 | Shard self-check | **PASS** — `--assert-coverage OK: 132 wired KEEP test(s) across 4 shard(s)` |
| 7 | Check 88 green after BD-280 | **PASS** — spec-sha in sync; shell byte-identical to base |
| 8 | Zero dangling cross-references introduced | **PASS** — M4 grep-zero; changelog 43 citations, 3 non-resolving all proven false positives |
| 9 | `_toc.md` regenerated for edited per-entry trees | **PASS** — `changelog/_toc.md` regenerated via `per_entry_regenerate_toc`; 1-line delta |
| 10 | Bite proof for M1, M2, OI-3 | **PASS** — plus S3 and N6, all with restore-verified byte-identity |
| 11 | No state-changing git verb | **PASS** — see Rules block |
| 12 | Test-count change stated | **PASS** — wired files unchanged at 132; cases 23→35, T10-T17→T10-T25, 2→3 |

---

## 12. Rules-Applied Verification Block

| Rule | Verification evidence (measured, quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | Zero state-changing git verbs issued. My only git invocations were `git rev-parse HEAD`, `git rev-parse --abbrev-ref HEAD`, `git status --short`, `git branch -a --format`, `git log --oneline --diff-filter=D`, and `git show d47ef87^:<path>` — all read-only, and all executed in **my own** worktree (the harness independently blocked every cross-worktree git redirection and I did **not** work around it; I used `diff -rq`, `cat` of `.git` plumbing files, and the renderer's own `git status` read instead). No `git diff > patch` was produced — the prompt says produce NO patch. The 8 unstaged renames are untouched: `diff -rq` still shows each of the 8 as *Only in* base / *Only in* work, never both. | **COMPLIANT** |
| **per-action-approval-sub-agents** | No `rm`/`rm -rf`/`rmdir`/`unlink`/`git rm`/`find … -delete`/`mv`/`shred`/`truncate` executed by me. All scratch written to my OWNED handoff dir only (`/Users/david/.local/state/optiquity-pack-handoff/bd093-fix-20260821-174741/scratch/`: 20 fixer/probe scripts, `testlogs/`, `.GOOD` backups, `dashboard.html.PRE`). Nothing deleted outside it — nothing deleted at all. The five temporary source reinstatements (bite proofs) each wrote back a byte-identical restore, verified by sha256 or `==` comparison and reported inline: `restored identical=True` ×5. `dashboard-render.py build` writes via its own `mkstemp`+`os.replace` and is the sanctioned tool BD-280 names. | **COMPLIANT** |
| **bounded-review-fix-cycle** | This is fix pass **1 of 2**. All 18 items fixed in this single pass; nothing partially patched and nothing punted to a hypothetical pass 2. Two items I could not correctly fix within scope are reported as open items (OI-A BD-280 status flip — `backlog/` is not mine; OI-B client-doc boundary — a content decision needing user scoping) rather than half-applied. | **COMPLIANT** |
| **Real fixes only — no green-the-test band-aids** | M2 was literally a broken assertion; I made it **able to fail** and then proved it fails: with the brittle parser reinstated the suite returns `PASS: 6  FAIL: 1` / `exit code = 1` with T20–T23 naming the inertness. No assertion was deleted, no test commented out, no expectation loosened to match buggy output, no exception swallowed, no sleep added. OI-3's advisory was deliberately made non-gating **and** its three real findings were fixed rather than allowlisted away (38 declared → 35 declared, 35 live, **0 dead**). | **COMPLIANT** |
| **edit-in-place-not-full-rewrite** | Every edit was an exact-string replacement executed by a fixer script that ABORTS unless the occurrence count matches exactly (`sys.exit("ABORT %s: expected %d, found %d")`). It fired twice and prevented wrong edits: `ABORT S1 test-migrator-skills.sh: expected 2, found 1` and `ABORT OI-3 record firing snippets: expected 1, found 2` (the second caught that `covered = any(...)` occurs in BOTH Check 65 and Check 67 — a blind replace-all would have silently altered Check 67). No file was rewritten. Section maps re-read after editing: `changelog/v11.md` (`grep -n "^## \|^### \|^_At \|^\*\*Carried"` → 8 headings, structure intact + parallel) and the allowlist K-set (`K1 K2 K3 K4 K7 K10 K11 K12 K13`). | **COMPLIANT** |
| **verify-full-ci-suite** | Wired set enumerated from the real CI source (`ci-shard-plan.py --emit-matrix`), never by hand: `wired test scripts: 132`. Ran **all 132 individually** on the final state: `PASS: 132  FAIL: 0`, exit 0. Plus `validate-pack.py` (exit 0), `PACK_VALIDATE_DEEP=1 validate-pack.py` (exit 0), `build.sh --verify` (exit 0, 7 fixtures), `--assert-coverage` (exit 0, "union == wired_KEEP_set; pairwise-disjoint"). I ran the full battery **twice** — once before the final S3 test edit and once after it — so the quoted 132/132 is against the exact final tree. | **COMPLIANT** |
| **enumerate-encoding-surfaces** | Every code change moved in lock-step with its test: M1/helper-bound → `test-validate-pack-check-39.sh` T17–T24; S3 → same file T25 (stub extended to record the `ls-files` argv); N5/N6 → `test-validate-pack-check-4.sh` T12–T19 (23→35 cases); OI-3 → `test-validate-pack-check-65.sh` T8a/T8b/T9 (2→3). `__all__` checked for new symbols: `_parse_migrator_manifest_sources` kept its name so the existing `__all__` entry and the test's Group-0 symbol assertion still resolve; `_check_4_is_dev_branch` is module-private, consumed only in-module, and `singletons.py` has no `__all__` gate for it (verified by `py_compile` + the 35/35 suite exercising both call sites). Changelog paired with its generated `_toc.md`. Dashboard paired with Check 88 + `verify`. | **COMPLIANT** |
| **declare-verify-backing** | Refused to accept a passing run as evidence for any guard. Bite proof produced for **five** items, each by reinstating the defect and observing failure, then restoring byte-identically: **M1** (brittle parser → T20–T23 fire, exit 1), **helper bound** (unbounded scan → T24 fires, exit 1), **N6** (bare substring → T16/T17/T18 fire, exit 1), **S3** (hard-coded pathspec → T25 fires, exit 1), **OI-3** (synthetic dead + unscanned records → both WARN classes fire, exit stays 0). OI-3 itself exists to make a records-style claim load-bearing: "sized to the KEEP set EXACTLY" is now measured (`35 record(s) declared, 35 live, 0 dead`) rather than asserted. | **COMPLIANT** |
| **ci-guard-measure-then-bound** | **M1:** measured both parsers against 6 adapter shapes before substituting; real-adapter output unchanged (12 file + 3 dir = 15 rows). **S3:** measured the derived pathspec on the real tree → `['project-template']`, byte-identical to the hard-coded value, so the change is provably behaviour-neutral; candidate set still drawn from `git ls-files` (tracked), never an FS walk, and still SKIP-lenient when git is unavailable (T16). **OI-3:** measured against the real allowlist BEFORE bounding — found 3 dead records, categorised each (all STRIP: they declare `pattern: bd-tag` but the exempted filename carries no `BD-NNN`, unlike its K4 sibling `ARCHITECTURE-BD-208.md`), applied the fix-recipe (removal), and verified the post-fix state clean (`0 dead, 0 on unscanned docs`). Allowlist sized exactly to the legitimate set: 35 = 35 live. **BD-280:** measured all four named surfaces before implementing, which is how the false premise was found. Absence-of-backing verified in every case, not merely target-exists. | **COMPLIANT** |
| **ci-check-runtime-compounding** | **S3** adds **zero** subprocesses — the derived pathspec is a set comprehension over ≤15 already-parsed rows feeding the *same single* `git ls-files` call. **OI-3** is O(records): one set difference over 35 parsed records, no extra file read, no subprocess, no tree walk; the per-line `any()`→loop change costs O(snippets) and only on lines that already matched a forbidden pattern. **M1** removes a regex compile+search per hook and reuses the helper Check 47 already invokes. **N6** adds one `re.split` on a branch name, on a path that was already about to FAIL. No whole-tree walk introduced anywhere; BD-280 added no check at all (the dashboard is not CI-gated). | **COMPLIANT** |
| **operating-docs-no-history-no-bloat** | `PACK-MEMORY-RATIONALE.md` (M3): replaced a stale forward-pointer with the settled decision — no dated note, no SHA, no "BD-NNN did X" narration added; net +5/−2. The allowlist (M5/OI-3): net **−22 lines** — the file got tighter, and the only additions are range corrections. `DASHBOARD-SPEC-PACK.md`: **not edited** (BD-280 needed no spec change). N3's added constraint bullet states a *current* invariant ("decompose regenerates NO monolithic mirror") plus a live test pointer — not history. Line numbers deliberately omitted from all new cross-references (they drift). The changelog and `.github/` comment are reference/CI surfaces, not operating docs, so BD provenance is appropriate there. | **COMPLIANT** |
| **public-bound-no-leak** | Client/public surfaces I touched: exactly one — `.github/workflows/validate-pack.yml` (N2, one comment line). Added text `the BD-093 release cut carries them` carries no target-app name and no domain vocabulary. `project-template/` untouched (all 6 trinity files sha-identical to base). Internal surface touched: `changelog/v11.md` — internal tier, exemption permanent; I nonetheless used neutral phrasing ("Real-target scratch-clone") rather than the internal codename, since the repo goes public with history. M3 **records** the exemption's permanence without weakening the check: `no_leak.py` is byte-untouched by me (`_CLIENT_PREFIXES`, `_CLIENT_ROOT_FILES`, `_LEG2_ALLOWLIST` unchanged). Check 93 green: *"no target-app literal-name leak in any git-tracked file (leg 1, tree-wide) and no domain-vocabulary … leak on client/public surfaces"*. My own wording throughout this report stays abstract. | **COMPLIANT** |
| **pack-repo-code-comment-deferrals** | Grepped every file I edited for `TODO`/`FIXME`/`XXX`/`HACK`/"fix later". Exactly one hit: `scripts/lib/migrator-skills.sh:251: tmp=$(mktemp "${TMPDIR:-/tmp}/pack-skill-rename.XXXXXX")` — a portable mktemp template, pre-existing, and Check 92 green. **Zero untyped deferrals introduced.** M4 and N3 were the live risk here: at every site where a dead pointer was removed I either kept self-contained rationale or folded a *current* constraint (N3), never a plain `TODO`. No site needed a typed `TD-TBD` forward-pointer, because no site deferred work. | **COMPLIANT** |
| **graph-first-context** | Used the **injected** path `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json` verbatim; never recomputed from my own toplevel. Ran discovery **first** for M4's site census (the P1 recall question) with `--backend claude-cli --budget 1500`: `Traversal: BFS depth=2 | Start: ['Files','Files','Files'] | 15 nodes found` — all 15 were Check-39/40/43 fixture READMEs, i.e. disjoint from the true set, because the graph does not index filename mentions inside prose/code comments. Per **G2** I fell back to grep and say so explicitly in §M4. The completeness census then ran grep as its **verification** gate to grep-zero, not as a substitute for discovery. All other reads were legitimate fall-throughs: verification of named surfaces (exact bytes/counts), SSOT field VALUES (`Status:`/`Target:` in `backlog/`, `changelog/_rules.md`), freshly-changed/uncommitted files, and whole-file content of named files. | **COMPLIANT** |
| **memory-not-an-ssot** | Re-read the live in-repo SSOT rather than trusting the prompt's summaries: `changelog/_rules.md` in full before editing the changelog (which is how I established that `_toc.md` embeds the H2 date and therefore **did** need regeneration — the opposite of the reviewer's correct-at-the-time note that it did not); `backlog/BD-280.md` in full for its own acceptance criteria (which is how the false premise surfaced); `CLAUDE.md`'s pack-memory and versioning sections; `core.warn`'s docstring for the advisory contract; `migrator-core.sh`'s hook contract for N1; the allowlist header for M5/OI-3. I also re-derived S6 from the live backlog (17 Open, censused) instead of hardcoding the prompt's list, and re-derived M4/S1/M5 censuses instead of trusting the review's counts — all three turned out larger. No cached rule acted on. | **COMPLIANT** |
| **deferral-is-scope-creep** / **no-deferral-without-user-direction** | **Nothing was deferred and no new BD is proposed.** All 18 items landed in this pass. Where a finding's stated scope would have left the same defect live I expanded rather than deferred (§8: the helper bound, the primary-checkout `dev` anchor, the 3 dead allowlist records) — three expansions, zero contractions. The two items I did not change (OI-A BD-280's status flip, OI-B the client-doc boundary) are surfaced with context, options and a recommendation for the orchestrator/user, not deferred by me: OI-A is a `backlog/` edit outside my write scope, and OI-B is a user-scoping decision where I explicitly decline to recommend deferral. | **COMPLIANT** |
| **deferred-work-tracked-anchor** | Nothing leaves this report as an unanchored "should probably". Every open item names concrete files and a concrete action: OI-A → `backlog/BD-280.md` (`Status:`/`Resolved:` lines, Pack Chat's edit) and, if the user chooses to carry it, the `changelog/v11.md` carried-over list I authored; OI-B → `supporting-docs/MIGRATION-v10-to-v11.md` (11 sites) + `pack-ops/MERGE-STRATEGY.md`; OI-C → closed, nothing outstanding. N3's recovered-but-moot constraint is anchored in-code at the `migrate-v10-to-v11.sh` decompose site with a live test pointer. | **COMPLIANT** |
| **open-item-surfacing** | Three open items in §7, each with (1) measured context, (2) **my own** options, (3) an evidence- or logic-based recommendation: **OI-A** BD-280's false premise → recommend (a) Resolve with the finding recorded, backed by the four-surface grep measurement and the state-key provenance trace; **OI-B** client doc → pack-only doc → diagnose (c) as correct but explicitly decline to change it, with the 11-site count and the `QUICKSTART`/`README` contrast as evidence; **OI-C** census-count gaps → recommend (a) with the bare-token grep technique as the actionable lesson. No recommendation rests on memory, and none defers or delays work to another or a new BD. BD-280's (a)-vs-(b) design choice was resolved on measurement (both options inapplicable — §6) rather than fabricated certainty, and N3 was reported as recovered-and-moot with the git-history quote and the two `assert_not_contains` lines as proof rather than an invented constraint. | **COMPLIANT** |
| **preflight-stop-means-stop** | The single-line PREFLIGHT was emitted **only after** all 18 fixes and the entire verification set passed — 132/132 wired, both `validate-pack` modes exit 0, fixture verify, shard coverage, Check 88, dashboard verify, and all five bite proofs with byte-identical restores. Nothing partial is presented as complete: §6 states plainly that BD-280's dead-path count rose 12→19 and why, §7 states what I did not fix, and §8 lists every deviation. No parent stop/halt/revert message was received at any point. | **COMPLIANT** |
| **Trinity rule** | All six trinity files byte-identical to the committed base — `CLAUDE.md` `0a57bb2964c70f98`, `AGENTS.md` `1ed4d1bcbbf306e3`, `GEMINI.md` `1be1d39560bca92e`, `project-template/CLAUDE.md` `072c8aa7ad6ce475`, `project-template/AGENTS.md` `2e4d9e359207e8bd`, `project-template/GEMINI.md` `a364f613dccb4fe8` (sha256[:16], base == work for all six). No trinity edit made, so no parallel edit was owed. | **N/A: no trinity file touched** |
| **P-missed-7 / boundary-investigation** | §9. One client/public surface edited (`.github/workflows/validate-pack.yml`, N2); project-side SSOT investigated and none exists for the concept ("which BD carries the manual pre-tag gate items") — `.github/` is pack CI infrastructure, not client-installed content, and the surrounding comment is its own local record, so implemented per prompt with no SSOT augmentation. `project-template/` untouched. No pack-only reference was added to any client-installed surface. Frames rotated between pack-side and project-side for the leak tier (internal `changelog/` vs public `.github/`). One boundary defect found and **raised rather than fixed** (OI-B). | **COMPLIANT** |
| **pack-chat-only files untouched** | `README.md`, `backlog/BD-093.md`, `backlog/BD-204.md` differ from base but were edited by the **orchestrator**, per its addendum — I did not open them for writing. `pack-ops/PACK-CHAT.md` differs but was the original coder's edit, untouched by me. I did edit two files the orchestrator explicitly scoped into my prompt: `changelog/v11.md` (S1/S2/S6/OI-2/date) and `pack-ops/.operating-doc-history-allowlist.txt` (M5/OI-3) — scoping a pack-chat-only file into a coder prompt is the supported path, not a violation. **No BD `Status:` flip was made** (OI-A defers that to Pack Chat by design). | **COMPLIANT** |
