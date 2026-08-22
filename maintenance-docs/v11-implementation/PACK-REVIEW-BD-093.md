# PACK-REVIEW-BD-093 — v11.0 (RC1) release-cut preparation

**Reviewer:** `pack-reviewer` (RO). **Date:** 2026-08-21.
**Verdict:** **NOT CLEAN — 1 BLOCKER, 5 MUST, 6 SHOULD, 7 NIT, 5 open items.**

The engineering in this change set is genuinely strong: the Check 4 defect
diagnosis is correct, the Check 39 measurement reproduces exactly, the
changelog's 136 BD citations all resolve, and the entire CI battery is green.
The findings below are real defects, not stylistic quibbles — and the BLOCKER
is a mismatch that ships in a public RC and reds CI on `main` at the cut.

---

## 0. Runtime verification (where I ran, and on what)

The harness refused every git invocation redirected at the target worktree
(`cd <target> && git …` and `git -C <target> …` both blocked as
"worktree-isolated agent's git operations must target its own worktree").
I did **not** circumvent that guard. Instead:

| Fact | How established | Value |
|---|---|---|
| Target worktree exists | `ls -d` | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a3e94ef9f38a11308` |
| Its branch | `cat .git/worktrees/agent-a3e94ef9f38a11308/HEAD` | `ref: refs/heads/worktree-agent-a3e94ef9f38a11308` |
| Its HEAD SHA | `cat .git/refs/heads/worktree-agent-a3e94ef9f38a11308` | `ee66ba57c355d449a536360061fd46d633651fbc` ✅ matches the expected SHA |
| My own isolated tree | `git rev-parse HEAD` / `git status --short` | `ee66ba57c355d449a536360061fd46d633651fbc`, **clean** |

Because my own checkout sits at the *identical* commit and is clean, a
`diff -rq` between the two trees is an exact substitute for
`git status --short` on the target, and per-file `diff -u` is an exact
substitute for `git diff`. All analysis below is against the **target
worktree's working tree**; all commands that needed to *execute* pack code
(`python3 scripts/validate-pack.py`, the test scripts, `graphify`) ran with
`cd` into the target worktree — plain `cd` is permitted, only git redirection
is blocked.

**Change set measured (not taken from the IMPL-REPORT):** 21 modified tracked
files + 8 deletions + 8 additions (the moves) + 1 new test file. The prompt's
"29 files modified" = 21 M + 8 D. Reconciled, no discrepancy.

### Battery results — all run by me, output quoted

```
$ python3 scripts/validate-pack.py
PASSED — all checks clean          exit=0   WARN lines: 22 (all advisory)  FAIL lines: 0

$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py
PASSED — all checks clean          exit=0   OK lines: 281  WARN: 22  FAIL: 0

$ bash test-fixtures/build.sh --verify
exit=0
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: 4ffbcf66cbe9255cbc0c2edc4d906c47edc885f6
  v11-flat-file OK: 283bf0bad769d69a431cc23a88c8137c0ca75f15
  v11-tracker-on OK: 4f322dc1adb5b2d5e00e2167c7e68e91fba1e20d
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
  existing-project-collision OK: 7eb05e434cf050e005b582d94eba9105b67abda0

$ python3 scripts/lib/ci-shard-plan.py --assert-coverage
ci-shard-plan --assert-coverage OK: 132 wired KEEP test(s) across 4 shard(s);
union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located in one shard.
exit=0

$ (every one of the 132 wired scripts, run individually after a full fixture build)
=== DONE ===
PASS:      132
FAIL:        0
```

Per-shard partition I derived from `--emit-matrix`: 37 / 31 / 32 / 32 = 132.
`scripts/tests/test-validate-pack-check-4.sh` **is** in the wired set (I grepped
the emitted matrix). Targeted logs: Check 4 test **23/23 PASS**; Check 39 test
**7/7 PASS**; Checks 32-33-34 test **129/129 PASS**.

**No count differs from the IMPL-REPORT.** Its verification claims reproduce.

---

## 1. BLOCKER

### B1 — README says `v11.0 (work)`; the changelog now says `v11.0 (RC1)`. The repaired Check 4 will red CI on `main` at the cut.

**Files:** `README.md:83`, `changelog/v11.md:242`.

```
README.md:83      | v11.0 (work) | May 2026     | Issue-tracker integration …
changelog/v11.md:242   ### v11.0 (RC1) — release candidate cut
```

`README.md` is **not** in this change set (verified: it does not differ between
the base and work trees). I reproduced the guard's selection:

```
row count: 25
rows[0] = 'v11.0 (work)'      <- the row Check 4 now compares
rows[-1]= 'v1'                <- the row it used to compare (the inertness)
normalized tag form: 'v11.0-work'
```

There is no `v11.0-work` tag and none is planned. Today Check 4 passes only via
an allowance — I observed it live:

```
$ python3 scripts/validate-pack.py --only-check 4
  OK: README.md version v11.0 (work) (linked worktree off dev branch `v11-dev` — tag will be created at release)
```

At the cut the tag becomes `v11.0-RC1` and `main` is force-pointed at `v11-dev`.
On the CI push to `main`: `git branch --show-current` = `main` (no `dev`
substring), and `actions/checkout@v6` produces a **primary** work tree so
`_check_4_dev_worktree_branch()` returns `""`. Check 4 therefore **FAILS**:
`README.md current version is v11.0 (work) (tag form v11.0-work) but no matching
git tag exists`. I confirmed `.github/workflows/validate-pack.yml` uses
`fetch-depth: 0` in all three jobs, so tags **are** fetched and the check is
genuinely live in CI — the guard is not inert there.

**This is not a coder defect.** `README.md`'s version table is pack-chat-only;
the coder could not touch it, and the IMPL-REPORT §8 "Note for the orchestrator"
correctly flags the sequencing. But as delivered, the change set is internally
inconsistent: one file in it declares an RC1 cut that another file contradicts.
Under "NO MISMATCHES" that is a blocker on the *batch*, not on the coder.

**Recommendation:** Pack Chat edits `README.md:83` to `| v11.0 (RC1) | …` in the
same commit that lands this change set, and creates the `v11.0-RC1` tag before
any push to `main`. Do not land the changelog H3 without the README row — they
are one atomic statement about what version this is.

---

## 2. MUST

### M1 — The new heredoc parser duplicates an existing one in the same file, with a strictly more brittle regex, and goes SILENTLY INERT on 4 of 4 realistic adapter shapes.

**File:** `scripts/lib/validate_checks/boundary_refs.py:1201-1232`
(`_parse_migrator_manifest_sources`), vs the pre-existing
`_migrator_heredoc_first_fields()` at **line 4625 of the same file**.

The pre-existing function already parses *these exact two hooks* — Check 47
calls it as `for func in ("migrator_directory_sweeps", "migrator_manifest")`
(line 4673). The new function re-implements it with:

```python
r"^" + re.escape(func) + r"\(\)\s*\{\s*\n\s*cat <<'EOF'\n(.*?)\nEOF\n"
```

which hard-codes (a) the marker literal `EOF`, (b) the single-quoted form, (c)
`cat` as the *first* statement after `{`, (d) a column-0 closer. The existing
one handles `<<-`, any `\w+` marker, quoted or not, and any preamble.

I ran both against synthetic adapters:

```
adapter variant                            | NEW _parse_migrator_...      | EXISTING _migrator_heredoc_first_fields
------------------------------------------------------------------------------------------------------------------
A baseline (cat <<'EOF', marker EOF)       | ok 1/1                       | ok 1/1
B marker renamed to ROWS                   | INERT ([],[])                | ok 1/1
C unquoted heredoc (cat <<EOF)             | INERT ([],[])                | ok 1/1
D a comment line before the cat            | ok 0/1                       | ok 1/1
E indented closer (<<- form)               | ok 0/1                       | ok 1/1
```

On variants B and C the parser returns `([], [])`, the leg's
`if mig_files or mig_dirs:` guard short-circuits, and Check 39 reports
`0 v10→v11 adapter manifest/sweep row(s) reverse-checked` **and passes**. That
is precisely the "silently inert guard manufacturing false confidence" defect
class BD-093 exists to fix in Check 4 — reintroduced, one check over, in the
same commit. Variant D is worse in one respect: it is *partially* inert (0 file
rows, 1 dir row), so the leg runs and looks healthy while checking nothing on
the hook that carried the actual stale row.

**Recommendation:** delete `_rows()` and call
`_migrator_heredoc_first_fields(text, "migrator_manifest")` /
`(…, "migrator_directory_sweeps")`. I verified this is a drop-in: both take the
first whitespace-delimited field, and TAB-separated manifest rows split
identically. Expected output on the real adapter is unchanged (12 file rows,
3 dir rows — measured below).

### M2 — The leg-3 test's anti-inertness assertion (T17) is inverted and cannot fire.

**File:** `scripts/tests/test-validate-pack-check-39.sh:637-646`

```python
srcs = bref._parse_migrator_manifest_sources()
if srcs != ([], []):
    f_rows, d_rows = srcs
    if not f_rows or not d_rows:
        failures.append("T17 real adapter parse returned %r" % (srcs,))
```

The outer `if srcs != ([], []):` gates the non-emptiness assertion on the result
already being non-empty. The *only* case it cannot detect is
`srcs == ([], [])` — the total-inertness case (M1 variants B and C). T17's own
comment says it exists to pin that the parse works; it does the opposite.

**Recommendation:** drop the outer guard and assert unconditionally that the
real adapter yields non-empty `f_rows` **and** `d_rows`. Additionally assert a
floor on the live summary — e.g. that
`validate-pack --only-check 39` prints a non-zero
`… adapter manifest/sweep row(s) reverse-checked` count. Without that, M1's
failure mode remains untestable even after M1 is fixed.

### M3 — `PACK-MEMORY-RATIONALE.md` still states the exact proposition `no_leak.py` was edited to retract.

**Files:** `pack-ops/PACK-MEMORY-RATIONALE.md:1293` vs
`scripts/lib/validate_checks/no_leak.py:26-28` and `:108-110`.

```
PACK-MEMORY-RATIONALE.md:1293
  two-tier keep-list until the separate scrubbed public copy is produced.

no_leak.py:26-28
  keeps are PERMANENT — this repo is the single work repo and goes public with
  its history intact, so there is no separate scrubbed copy and the
  internal-surface exemption is a settled decision, not pending cleanup; do not
  re-open it
```

Two live surfaces now assert opposite things about one settled decision, and
`PACK-MEMORY-RATIONALE.md` is the rationale SSOT for the `public-bound-no-leak`
rule. The file **is** edited by this change set (for the EXECUTION-PLAN path),
so it was open and the second site was missed. I grepped the whole tree for
`scrubbed`: this is the only remaining stale assertion (the trinity
`## Pack memory` entry carries no temporal qualifier, so trinity parity is
unaffected — correctly).

**Recommendation:** apply the same wording change at line 1293.

### M4 — The deleted-doc provenance sweep is selective: 10 code-comment references to a *different* deleted architecture doc survive in 5 pack-side source files.

I verified by `find` that `ARCHITECTURE-SKILL-DIMENSIONS.md` and
`PLAN-SKILL-DIMENSIONS.md` **exist=0** in the tree — same status as the two docs
the sweep targeted. Surviving references (counts by file):

```
  5  scripts/migrate-v10-to-v11.sh
  2  scripts/lib/validate_checks/agents_skills.py     (e.g. L1127-1128, a qualified path)
  1  scripts/lib/migrator-core.sh
  1  scripts/lib/migrator-skills.sh
  1  scripts/lib/validate_checks/singletons.py        (a file this change set edits)
  4  maintenance-docs/v11-implementation/ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md
  7  maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md   (a LIVE doc, allowlist K5)
  1  maintenance-docs/v11-implementation/ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md
```

`scripts/lib/validate_checks/agents_skills.py:1127` reads
`` canonical-cell source per `maintenance-docs/v11-implementation/ ``
`` ARCHITECTURE-SKILL-DIMENSIONS.md` §3 `` — a fully-qualified path to a file
that does not exist. Nothing catches this: Check 68's scope is the operating-doc
IN set ∪ README ∪ `project-template/**` ∪ `supporting-docs/**` — it does not
read `scripts/` comments or `maintenance-docs/`, **and** it resolves qualified
paths by basename-index membership anyway (verified at
`boundary_refs.py:4082-4086`).

Notably, the *changelog* text this same change set rewrote **did** fix the
parallel dangling claim — it removed the explicit
`ARCHITECTURE-SKILL-DIMENSIONS.md` / `PLAN-SKILL-DIMENSIONS.md` list from the
Scope C audit block. So the doc surface was corrected while the code surface
was not.

**Recommendation:** extend the identical treatment (fold the section pointer
into constraint text, or drop the pointer and keep the sentence) to the 10
source-file sites in this batch. Per `deferral-is-scope-creep` and
`no-deferral-without-user-direction` this is unblocked work in an unlaunched
v11.0 — it lands now unless the user explicitly defers it. The three
`maintenance-docs/` docs are reference records, not operating docs; I'd leave
those (option surfaced in OI-3 below).

### M5 — Two stale `K2-K6` cross-references survive after K6 was removed.

**File:** `pack-ops/.operating-doc-history-allowlist.txt`

The K6 record (the `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` cross-ref) was
removed and line 24 was correctly updated `K2-K6` → `K2-K5`. Two sibling
references were not:

```
24:# K-set (BD-243 DESIGN §B.1): K1 live transitional pointer; K2-K5 live doc     <- fixed
30:# task time, the same class as K2-K6 but the BD is carried by the filename).   <- STALE
241:#        that is read at task time, not provenance. Same KEEP class as K2-K6   <- STALE
```

K6 no longer exists, so both surviving references name a nonexistent record.

The removal itself is **correct and well-judged**: I read
`check_operating_doc_no_history()` (`boundary_refs.py:3747-3830`) and confirmed
Check 65 does **not** enforce that allowlist records are live-matched — a dead
K6 would have sat there silently. Removing it honours the file's own
"sized to the KEEP set EXACTLY" contract. I also confirmed the removal is
load-bearing: `grep` for `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION` in
`pack-ops/PACK-CHAT.md` returns **zero** hits.

**Recommendation:** change both to `K2-K5`.

---

## 3. SHOULD

### S1 — The RC1 changelog block carries two wrong script paths, one a wrong filename.

**File:** `changelog/v11.md`, "_At the Scope C cut_" sub-block (rewritten by
this change set):

| Cited | Actual |
|---|---|
| `scripts/test-migrator-skills.sh` | `scripts/tests/fixture-dependent/test-migrator-skills.sh` |
| `scripts/test-migrate-v10-to-v11-capability-translation.sh` | `scripts/test-migrator-capability-translation.sh` (**different filename**) |

The block's preamble disclaims *currency of figures*, not *existence of paths* —
and the same rewrite removed the Scope A/B audit-report path precisely to avoid
a dead pointer ("fail-loud: no mirror, no dead pointer"). The treatment is
inconsistent within one block. **Recommendation:** correct both paths (the
second is a rename, so the old string never existed at any point).

### S2 — The RC1 block credits BD-117 with a deliverable that does not ship.

`changelog/v11.md` (RC1 block, line 193 of the block):
`- BD-117 — Per-major-version release-gate checklist.`

BD-117's `Resolved:` line names
`maintenance-docs/v11-implementation/RELEASE-GATE.md (263 lines)`. I verified
`find` → **exists=0**; it was deleted at BD-210. This same change set edits
`.github/workflows/validate-pack.yml:10-12` to say
"*The standalone RELEASE-GATE checklist doc was one of the superseded
maintenance-docs deleted at BD-210 - do not cite it.*" So the workflow header
disowns the artifact in the same commit the changelog claims it as a v11.0
deliverable. **Recommendation:** give BD-117 the same explanatory treatment the
MAINTAINER-CHECK-AUDIT line received (state the checklist shipped and was later
consolidated/deleted at BD-210, with no path cited).

### S3 — Check 39 leg 3 pathspec-scopes `git ls-files` but tests every row against that scope.

**File:** `scripts/lib/validate_checks/boundary_refs.py:1416-1419`

```python
["git", "ls-files", "--", "project-template"]
```

Every declared row — from either hook — is then tested for membership in that
set. A row whose source lives outside `project-template/` would FAIL with a
message asserting it "is NOT tracked at HEAD, so it does not ship", which would
be false. Currently vacuous (I measured: **all 15 rows are under
`project-template/`**), but the adapter contract in `migrator-core.sh` states no
such restriction, and `supporting-docs/` is an explicitly legitimate client-
deliverable root elsewhere in the same file (`_is_pack_side_ship_source`).

**Options:** (a) drop the pathspec (whole-tree `git ls-files`); (b) derive the
pathspec from the observed row prefixes; (c) skip-and-report rows outside the
pathspec. **Recommendation: (b)** — it keeps the single-subprocess cost, removes
the false-FAIL, and needs ~2 lines.

### S4 — `backlog/BD-204.md:9` (Deferred, but a LIVE design baseline) names a pre-move path.

```
… and the two BD-204 analysis docs `maintenance-docs/v11-implementation/
RESEARCH-BD-204-RESTART-INTEGRATION.md` + `PACK-REVIEW-BD-203-VS-LOCKED-COMPATIBILITY.md`.
```

The line's own framing is
`DESIGN BASELINE (named inputs — ADAPT, do NOT discard or silently ignore)`.
The doc moved to `maintenance-docs/archive/v11/`. `backlog/` is outside Check
68's scope, so nothing catches it.

The IMPL-REPORT (OI-7) classifies BD-204 with BD-138/BD-139 as "closed
historical entries describing what was true then". **That classification is
wrong on the evidence**: BD-204 is `Status: Deferred`, not Resolved, and the
cited line is a forward-pointing instruction for when the BD resumes.
BD-138/BD-139 *are* Resolved and their citations *are* historical — I agree with
leaving those. **Recommendation:** update BD-204:9's path (pack-chat-only file).

### S5 — `backlog/BD-093.md` (Open) names the pre-move path twice, and its Description does not cover four of the shipped changes.

Lines 7 (`File/Symbol`) and 16 (Description) cite
`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`. The IMPL-REPORT
surfaced this (OI-7) and recommends Pack Chat fix it at the status flip — I
agree with that disposition.

Additionally: BD-093's Description covers the changelog currency, the
audit-artifacts consolidation, the Pattern B sweep, and the immutable manifest.
It does **not** mention the Check 4 repair, the Check 39 leg-3 widening, the
`no_leak.py` decision record, the PACK-CHAT dangling-ref removal, or the
26-site provenance sweep. **Recommendation:** the `Resolved:` line must enumerate
all of them, or the closing record understates what landed under this BD.

### S6 — The RC1 block omits the "carried over" list its sibling v11.0 block has, and one v11.0-targeted BD is still Open.

The earlier `### v11.0` block ends with
`**Carried over to future work (v11-Active BDs Open at v11.0 cut):**`. The new
`### v11.0 (RC1)` block has no equivalent (grep for `Carried over|Open at` in
the block: zero hits). Backlog census at HEAD:

```
   1 Cancelled   23 Deferred   11 Deprecated   17 Open   235 Resolved
```

Of the 17 Open, 5 carry `Target: v11.1` (user-directed), 11 are untargeted
pre-v11 entries, BD-093 is the cut itself — and **BD-280 carries
`Target: v11.0`**:

> `**BD-280 — Dashboard doc-index staleness … (BD-210 fallout)**`
> `Target: v11.0 (… NON-BLOCKING …). Lands in v11.0 per no-deferral unless the user defers.`

So RC1 is being cut with one self-declared v11.0 item outstanding, unrecorded in
the changelog. Per `no-deferral-without-user-direction` that is a user decision,
not an agent one. **Recommendation:** add a carried-over list to the RC1 block
naming BD-280 (and any other item the user elects to carry), and get an explicit
user ruling on whether BD-280 lands before the tag. Its anchor exists (BD-280 is
Open with a Target), so nothing is untracked either way.

---

## 4. NIT

- **N1 — a factual error in the load-bearing justification for the scope excess.**
  `boundary_refs.py:1169-1171` says the two hooks are
  "*read by the same `_manifest_parse`*". Verified false: `_manifest_parse`
  handles `migrator_manifest` only; `migrator_directory_sweeps` is consumed by
  `_manifest_sweep_dirs` (`scripts/lib/migrator-manifest.sh:434-449`). The
  *conclusion* is still right (see §5) — it rests on both hooks being
  `_migrator_required_hooks` members (`migrator-core.sh:163-164`) and on Check 47
  already parsing them jointly. Fix the sentence; keep the coverage.
- **N2** — `.github/workflows/validate-pack.yml:10` says "the release-cut BD
  carries them" without naming BD-093, while the surrounding comment names BDs
  throughout.
- **N3** — `scripts/migrate-v10-to-v11.sh:1041` dropped an
  `ADDENDUM-2.md §4.5` pointer without folding it into a constraint bullet,
  unlike the four sites that got the fold treatment. If §4.5 carried a binding
  constraint it is now unrecorded.
- **N4** — `scripts/tests/test-validate-pack-check-4.sh` is not added to the
  README Repository-Layout listing, and `README.md:254`'s Check-39 row still
  reads "BD-175 F2a tests — cmd_update mapping/glob symmetry" with no mention of
  leg 3. See OI-4 — this listing is systemically stale, so I do not weight the
  omission heavily against this change set.
- **N5** — Check 4's `FileNotFoundError` (git-absent) skip and
  `_check_4_dev_worktree_branch`'s `OSError` / `points_at.returncode != 0`
  branches are uncovered by the new test. The docstring advertises "no-tags/no-git
  skips"; only no-tags (T7) is covered.
- **N6** — `_check_4_dev_worktree_branch` matches any branch containing the
  substring `dev` (`main-devops`, `feature/device-x` qualify). Failure mode is a
  mis-PASS **only** inside a linked worktree — never in CI, never in the primary
  checkout — so the risk is bounded. Consider anchoring
  (`name.endswith("-dev") or name.startswith("dev")`).
- **N7** — `README.md:185` describes `archive/v11/` as "History extracted from
  operating docs (kept out of the live docs)"; it now also holds 8 superseded
  architecture/research records.

**Not findings (checked and cleared):** the 3-blank-line spacing in
`boundary_refs.py` matches the file's pre-existing house style throughout (I
counted 90+ such runs); `bash -n` clean on every changed shell file;
`py_compile` clean on both changed Python modules; **no untyped
`TODO`/`FIXME`/"fix later"** introduced (the `test-fixtures/build.sh` TODO hits
are deliberate synthetic fixture *content*, and the `XXX` hits are `mktemp`
templates); `pack-ops/PACK-CHAT.md`'s section removal leaves no orphaned `---`,
no empty section, and no dangling "Action items" reference anywhere in the repo.

---

## 5. RULING — the Check 39 scope excess (`migrator_directory_sweeps`)

**Ruling: SOUND. Keep the widened coverage. Do not revert.** Fix M1/M2/S3/N1 on
top of it.

The coder was directed to widen the reverse leg to `migrator_manifest` and also
covered `migrator_directory_sweeps`. Evidence I gathered independently:

1. **Both hooks are the same contract.** `scripts/lib/migrator-core.sh:163-164`
   lists them adjacently in `_migrator_required_hooks`. An adapter that declares
   one declares both.
2. **Both emit pack-side source paths that the migrator copies to a client.**
   Measured, post-change:
   ```
   migrator_manifest()          12 rows (TAB-separated; field 0 = pack source)
   migrator_directory_sweeps()   3 rows (whitespace; field 0 = pack dir)
   ```
3. **The pack's own precedent already treats them as one set.** Check 47
   (`_check_migrator_no_pack_side_client_copies`, `boundary_refs.py:4673`)
   iterates `for func in ("migrator_directory_sweeps", "migrator_manifest")`.
   Guarding only one in Check 39 would make Check 39 the *asymmetric* one.
4. **`enumerate-encoding-surfaces` cuts this way.** A dead sweep row is the
   identical defect (a declared mapping that ships nothing, invisible to every
   gate). Closing one and leaving the other reproduces the gap being closed.
5. **Zero cost, zero churn.** The dir leg reuses the *same single*
   `git ls-files` subprocess the file leg already needs; it adds only O(rows)
   set-membership over 3 rows. No allowlist growth (the allowlist is empty).
6. **It is not the residual-asymmetry trap.** I checked the other two
   path-emitting hooks: `migrator_relocations()` and
   `migrator_artifact_installs()` are both `{ :; }` in this adapter, so
   "cover every path-emitting hook" is *complete* at 2 of 2, not arbitrary at
   2 of 4.

### The measurement, reproduced independently

The block comment claims "13 rows -> 12 KEEP, 1 STRIP" for `migrator_manifest`
and "3 rows -> 3 KEEP, 0 STRIP" for `migrator_directory_sweeps`. Both reproduce
exactly:

```
=== base tree, pre-change ===
scripts/migrate-v10-to-v11.sh:118:project-template/docs/pack/PROMPT-TEMPLATES.md	docs/pack/PROMPT-TEMPLATES.md	generic	transform
find project-template -name PROMPT-TEMPLATES.md  ->  0

=== work tree, post-change: tracked-ness of every declared source ===
FILE rows (12):  all KEEP   (CLAUDE/AGENTS/GEMINI.md, .claude/settings.json,
                 3× .codex/*, .mcp.json.example, .agents/mcp_config.json.example,
                 docs/pack/{PM-CHAT,PLATFORM-SKILLS,PACK-FEEDBACK}.md)
DIR  rows (3) :  all KEEP   (project-template/scripts, .claude/agents, .codex/agents)
exemption allowlist size: 0
rows OUTSIDE project-template/ : (none)
```

13 = 12 + the stripped `PROMPT-TEMPLATES.md` row. Confirmed **STRIP** — the file
exists nowhere under `project-template/`. The allowlist is empty **by
measurement**, not by convenience — `ci-guard-measure-then-bound` satisfied.

I also verified the coder correctly did **not** over-delete: the surviving
`PROMPT-TEMPLATES.md` at `scripts/migrate-v10-to-v11.sh:271` is inside
`_v10_to_v11_relocate_legacy_docs`, operating on `$_MIGRATOR_TARGET` (the
**client's** tree, where a v9-era file may still exist). That reference is live
and correctly untouched.

The leg is live at HEAD — quoted from my `validate-pack` run:

> `15 v10→v11 adapter manifest/sweep row(s) reverse-checked against git-tracked
> HEAD; 15 are backed by a shipped source, 0 on the migrator exemption
> allowlist.`

12 + 3 = 15. Matches my measurement exactly.

**Bite proof:** the test's T11 (dead manifest row → exactly 1 FAIL, message
names the row and the hook) and T12 (dead sweep dir → exactly 1 FAIL) are real
bite tests, and T15 proves the allowlist is not a blanket. That satisfies
`declare-verify-backing` for the *row-level* logic. It does **not** cover
parser-level inertness — that is M1/M2.

**Runtime (`ci-check-runtime-compounding`):** one bounded subprocess + one file
read + O(15) set-membership. No per-row subprocess, no tree walk. Acceptable.
Check 4's addition is 3 extra `git` forks, and only on the branch that was about
to FAIL; once `README` says `v11.0 (RC1)` and the tag exists, the check short-
circuits at `readme_version_tag in tags` and the cost returns to zero.

---

## 6. Area-by-area assessment (the ones not already covered)

### 6.1 Check 4 — the repair itself is correct and well-tested

The inertness diagnosis reproduces (`rows[-1]` = `'v1'`, and `v1` is a tag that
has existed since v1 — so the guard passed unconditionally). The fix to
`rows[0]` is right for a newest-first table. Preserved behaviours I verified are
still exercised: bare-major tag match (T4), BD-242 display→tag normalization for
all six qualifier forms plus bare and `.PATCH` (T5), dev-branch allowance (T6),
no-tags skip (T7), empty-table FAIL (T8).

**The critical scenario the prompt asked about — `main` and `v11-dev` on the
same commit — is correctly handled and correctly tested.** T10 pins it:
primary checkout (`linked=False`), branch `main`, `points_at=["main","v11-dev"]`
→ `failures=1`, `worktree_allowance=False`. The gate is
`--git-dir == --git-common-dir`, which I confirmed empirically distinguishes the
two cases:

```
linked worktree : --git-dir  /…/optiquity-ai-agent-config-pack/.git/worktrees/agent-a3e94ef9f38a11308
                  --common   /…/optiquity-ai-agent-config-pack/.git          -> DIFFER -> allowance eligible
primary checkout: both resolve to <root>/.git                                -> EQUAL  -> allowance refused
```

CI is always a primary work tree, so the allowance cannot reach it. The
degradation direction is also safe: if a git version answered `--git-common-dir`
relatively and the paths compared *equal* in a worktree, the result is a
mis-FAIL (noisy), never a mis-PASS.

### 6.2 The 8 moved docs — census

**Graph-first attestation.** I ran three `graphify query` passes against the
injected graph before any grep. The graph surfaced a useful *candidate* set
(`pack-ops/PACK-CHAT.md`, `PACK-MEMORY-RATIONALE.md`, `backlog/BD-210`,
`BD-093`, `BD-205`, `supporting-docs/MIGRATION-v10-to-v11.md`,
`maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md`) but does not
index raw markdown filename mentions inside prose and code comments, so it
returned nothing usable for exhaustive recall. Per **G2** I fell back to grep
for the completeness census and say so explicitly here; the graph's candidates
were a strict subset of what the grep found, so recall was not narrowed.

**Stale QUALIFIED paths remaining outside `archive/`** (the checks cannot see
these — Check 68 basename-resolves *and* excludes `backlog/` +
`maintenance-docs/` from scope entirely):

| Site | Status | Assessment |
|---|---|---|
| `backlog/BD-093.md:7,16` | Open | **S5** — Pack Chat, at status flip |
| `backlog/BD-204.md:9` | Deferred, live design baseline | **S4** — fix |
| `backlog/BD-138.md:8`, `BD-139.md:12` | Resolved | Accurate history — leave (matches the Check-48 "JC-5 accurate-history citation" idiom) |
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md:887` | research record | Historical reference doc — leave; see OI-3 |
| `pack-ops/dashboard-approvals/dashboard.html:110` | generated | Owned by BD-280 (Open, Target v11.0) — do not hand-edit |

**Should any of the 8 not have moved?** `EXECUTION-PLAN-V11.0.md` is by far the
most-referenced (15 files, incl. two Open BDs and a live pack-ops doc) — but its
move is **explicitly directed by BD-093's own Description**
("*move `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` … to
`maintenance-docs/archive/v11/` via `git mv`*"), so it is user-sanctioned, not a
coder judgement call. The 7 `RESEARCH-*` docs are each referenced only from
Deferred/Resolved BDs or from other `v11-implementation` docs by bare basename.
**No move looks wrong to me.** `PACK-MEMORY-RATIONALE.md` — the one live
pack-ops pointer — was correctly repointed to
`maintenance-docs/archive/v11/EXECUTION-PLAN-V11.0.md`.

**`fail-loud-delete-old-source`:** verified no mirror remains at any of the 8 old
paths (`diff -rq` shows each as *Only in* base / *Only in* work, never both).

`scripts/tests/fixtures/bare-cross-refs/pack-ops-pass-anchor.md` mentions
`EXECUTION-PLAN-V11.0.md` only as "*canonical filename is …*" — a basename
assertion, still true after a directory move. Not stale.

### 6.3 The 26 comment edits — the WHY survived

I read every one of the structured `Architecture:` blocks. The conversion is
faithful: `_lib.sh`, `per-entry/decompose.sh` and `migrate-v10-to-v11/
decompose.sh` all preserve the parenthetical constraint text verbatim
("Layer 2 strip discipline", "`_rules.md` runtime-read scope split",
"signal-6 carve-out", "the back-pointer is a line-1 HTML comment ONLY",
the full sequencing sentence, the `_intro.md` install). What was dropped is
provenance-only (`§18.1 #3/#4 planner-deferred items resolved in this commit per
plan §5.4`, `§9.1 hook integration restated for the planner`) — correctly.

The two treatments (fold-to-constraint-list vs delete-the-pointer-keep-the-
sentence) are applied by a coherent rule: fold where the block was a pure
pointer list that would otherwise be emptied; inline-delete where the pointer
sat mid-sentence. `core.py` and `per_entry_sync.py` keep the entire explanatory
clause and lose only the `per §N` citation. Only N3 is a genuine loss.

### 6.4 The changelog block

- **Every BD citation resolves.** 136 distinct BDs cited; **0 missing entries**;
  135 `Resolved`; the sole non-Resolved is BD-093 itself (Open — it flips at
  batch close). This is a strong result and I could not fault it.
- **The RC1-cut figures are exactly right.** I reproduced the registry:
  ```
  registry entries: 91   distinct numbers: 86   unnumbered: 2
  numbers registering >1x: {16: 2, 18: 2, 19: 2}   range: 1..94
  ```
  matching "*91-entry check registry (86 distinct numbered checks spanning Check
  1–94 with retirement gaps; Checks 16, 18, and 19 each register twice; 2
  unnumbered entries)*" verbatim. "*132 test scripts … 4 dynamically-planned
  shards*" — confirmed. "*Check 93 … with a single measured allowlist entry*" —
  confirmed (`_LEG2_ALLOWLIST` has exactly one key).
- **Stream contract:** `changelog/_rules.md` admits
  `### vMAJOR.MINOR (X)` H3 subsections inside `vN.md`; the block conforms.
  `_toc.md` is keyed on the `## vN — <date>` H2 only, which is unchanged, so
  **no `_toc.md` regeneration is required** — its absence from the change set is
  correct, not an omission.
- Defects: **S1** (two wrong script paths), **S2** (BD-117), **S6** (no
  carried-over list).

### 6.5 `MIGRATION-v10-to-v11.md` — both fixes verified accurate

- `--no-interactive` **exists** (`scripts/migrate-v10-to-v11.sh:1104`), and the
  default really is TTY-keyed (`:73-74` "*Interactive when stdin is a TTY; the
  copy-paste + pause flow otherwise*"). The new prose is correct.
- The cross-reference "*see 'Interactive reconciliation' under Step 1*"
  resolves: heading at line 446, under `## Step 1 — Run the migration script`
  (line 437). Correct.
- The `git describe --tags` qualifier note matches the BD-242 scheme.
- `supporting-docs/` is a Check-93 leg-2 client/public surface; the run is green
  and the added text carries no domain vocabulary. Correct tier applied.

### 6.6 `no_leak.py` — comment-only, logic intact

Diff confirms the change touches only the module docstring (lines 23-27) and one
comment block (lines 104-110). `_CLIENT_PREFIXES`, `_CLIENT_ROOT_FILES` and
`_LEG2_ALLOWLIST` are byte-identical; no matcher weakened. Check 93 passes and
its wired test passes. The only defect is **M3** (the un-mirrored rationale doc).

### 6.7 Encoding-surface pairing (`enumerate-encoding-surfaces`)

| Surface changed | Paired test | Verdict |
|---|---|---|
| Check 4 (`singletons.py`) | **new** `test-validate-pack-check-4.sh` (23 cases) + `test-…-checks-32-33-34.sh` Tr.8 row-selection pin | Paired both ways ✅ |
| Check 39 leg 3 (`boundary_refs.py`) | `test-validate-pack-check-39.sh` Group 2c (T10-T17) + `__all__` export list updated + Group-0 symbol assertion updated | Paired, but see **M2** ⚠ |
| `no_leak.py` (comments) | logic unchanged; no test change needed | ✅ |
| `.github/workflows/validate-pack.yml` (comment) | Check 42 wiring unaffected | ✅ |
| `migrate-v10-to-v11.sh` (manifest row deleted) | Check 39 leg 3 + `test-migrator-manifest.sh` (green) | ✅ |
| 8 moved docs | no test encodes doc locations (verified) | ✅ nothing to pair |

No surface was updated without its test, and no test without its surface. The
one gap is *within* a test (M2), not a missing pairing.

---

## 7. Open items (context → my options → recommendation)

**OI-1 — the Check 39 scope excess.** Ruled in §5: **SOUND, keep.** Options were
(a) revert to `migrator_manifest` only, (b) keep both. Evidence for (b):
`migrator-core.sh:163-164` co-lists them; Check 47 already parses them jointly;
`migrator_relocations`/`migrator_artifact_installs` are empty so 2-of-2 is
complete coverage; 3 rows / 0 STRIP / 0 allowlist growth; the dir leg is free on
an already-required subprocess. **Recommendation: keep (b).**

**OI-2 — `### v11.0 (RC1)` as a second H3 under the same `v11.0`.**
`changelog/v11.md` now has `### v11.0 — …` and `### v11.0 (RC1) — …`. The stream
contract permits it and the block self-explains ("*part of the same v11.0
release*"). But at GA the qualifier drops and a reader sees a v11.0 changelog
with a section titled for a release candidate. *Options:* (a) leave as-is; (b)
retitle to something state-neutral (e.g. `### v11.0 — post-Scope-C work`) so the
heading survives the GA transition; (c) merge into the existing `### v11.0`
block. **Recommendation: (b).** It preserves the authoring intent, needs no
future edit at GA, and avoids a heading that will read as stale the moment the
qualifier is dropped. This is a `changelog/` (pack-chat-only) authoring
decision, so it is the user's call, not the coder's. No evidence points to (c)
— the two-block split carries real information about when things landed.

**OI-3 — the allowlist claims "sized to the KEEP set EXACTLY" but nothing
enforces it.** `pack-ops/.operating-doc-history-allowlist.txt`'s header asserts
exact sizing and says "*A reviewer re-verifies each `reason:` still names
LIVE-and-CURRENT work*" — a human-only control. I read
`check_operating_doc_no_history()` and confirmed Check 65 never checks whether a
record matched anything, so a dead record (exactly what K6 became) is invisible.
Under `declare-verify-backing` this is a records-style claim with no
load-bearing verification. It is **pre-existing**, not introduced here.
*Options:* (a) leave it — the manual re-verify is the stated control; (b) add an
unmatched-record WARN to Check 65 (Check-48 advisory idiom, no gate change,
~10 lines, O(records)); (c) make it a hard FAIL. **Recommendation: (b).** It
makes the existing prose claim actually load-bearing at negligible cost and
cannot red CI on a false positive. (c) risks failing on a legitimately
not-yet-triggered record. This is a scoping decision for the user — it is
adjacent to BD-093, not inside it, and I am **not** recommending it be deferred
to a new BD; if the user wants it in v11.0 it is a small, self-contained edit.

**OI-4 — the README Repository-Layout test enumeration is systemically stale.**
I compared disk to README: **61** `test-validate-pack-check*.sh` files exist;
**14** are listed; **47 are absent** (checks 44-94 are essentially entirely
missing). The listing appears frozen around the BD-173/BD-184 era. So N4 is one
instance of a much larger gap, and the section README.md advertises as "the
authoritative reference" is not. *Options:* (a) add only the new check-4 row
(closes N4, leaves 46 gaps); (b) regenerate the whole per-check listing;
(c) replace the enumeration with a one-line pointer ("per-check tests live in
`scripts/tests/`; the wired set is derived at CI time by
`scripts/lib/ci-shard-plan.py`") — which is *already true* and self-maintaining.
**Recommendation: (c).** The enumeration has no consumer (nothing validates it),
it has drifted 47/61, and a derived-set pointer cannot go stale. (a) leaves a
knowingly-wrong doc in a public release; (b) buys a snapshot that will drift
again. This touches `README.md` — pack-chat-only — so it is Pack Chat's edit.

**OI-5 — the dashboard snapshot carries pre-move paths.**
`pack-ops/dashboard-approvals/dashboard.html:110` embeds a minified JSON state
blob naming both `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` and
`EXECUTION-PLAN-V11.0.md`. **This already has a tracked anchor:** BD-280 is
`Status: Open`, `Target: v11.0`, and its title is literally "*Dashboard
doc-index staleness … (BD-210 fallout)*". *Options:* (a) hand-edit the generated
blob; (b) re-render after this sweep lands, under BD-280. **Recommendation:
(b).** Hand-editing a generated artifact is the wrong direction and Check 88
pins the shell against its spec-sha. Sequencing matters: BD-280's re-render must
run **after** these 8 moves, not before. See also **S6** — whether BD-280 lands
before the RC1 tag is the user's ruling.

---

## 8. What I did NOT verify

- I could not create a real primary checkout or a second worktree to exercise
  Check 4's allowance end-to-end (both require `git worktree` / `git checkout`,
  which `agents-never-commit` forbids). I verified the *linked-worktree* branch
  live in this tree, and the *primary-checkout* branch via the check's own
  stubbed T10 plus direct reading of the `--git-dir`/`--git-common-dir` gate.
- CI behaviour is inferred from the workflow file (`actions/checkout@v6`,
  `fetch-depth: 0`, primary work tree), not observed on a GitHub runner.
- I ran the 132 wired tests **serially in one tree**, not in the 4-shard CI
  matrix. Coverage equivalence is asserted by
  `ci-shard-plan.py --assert-coverage` (union == wired set, pairwise disjoint),
  which I ran and quoted.

---

## 9. Rules-Applied Verification Block

| Rule | Verification evidence (measured, quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | Zero state-changing git verbs issued. My only git invocations were `rev-parse`, `status --short`, `ls-files`, `tag`, `branch --points-at`, `branch --show-current` — all read-only. Working-tree proof: `git status --short` in my own tree returned empty at start and I wrote nothing into either checkout. The harness independently blocked all cross-worktree git redirection and I did not work around it. | **COMPLIANT** |
| **per-action-approval-sub-agents** | No `rm`/`rmdir`/`mv`/`git rm`/`find -delete`/`shred`/`truncate` executed. Scratch files written only to the session scratchpad (`/private/tmp/claude-501/…/scratchpad/`: `mkdiff.sh`, `enum.sh`, `runall.sh`, `census*.sh`, `check4.sh`, `check39.sh`, `claims.sh`, `chg.sh`, `mig.sh`, `deep.sh`, `style.sh`, `readme.sh`, `open.sh`, `brittle.py`, `full.diff`, `testlogs/`) and `mktemp` dirs created by the tests themselves. Sole repo-adjacent write: this report, in my owned handoff dir. | **COMPLIANT** |
| **verify-full-ci-suite** | Enumerated the wired set from the workflow's real source (`ci-shard-plan.py --emit-matrix`), not by hand: 37+31+32+32 = **132**. Ran all 132 individually after `test-fixtures/build.sh --all --clean`: `PASS: 132  FAIL: 0`. Plus `validate-pack.py` (exit 0), `PACK_VALIDATE_DEEP=1 validate-pack.py` (exit 0, 281 OK / 22 WARN / 0 FAIL), `build.sh --verify` (exit 0, 6/6 fixture SHAs match), `--assert-coverage` (exit 0). | **COMPLIANT** |
| **enumerate-encoding-surfaces** | Built the surface↔validator↔test↔workflow↔doc matrix in §6.7 for all six changed surfaces, in both directions. Found the pairing complete (no surface without a test, no test without a surface) and located the one *intra-test* gap (**M2**, T17's inverted guard). Also drove **M4** off this rule: the sweep updated code comments for two deleted docs but not a third with 10 identical references. | **COMPLIANT** |
| **declare-verify-backing** | Demanded bite proof for both guards rather than accepting a passing run. Check 4: T2 (newest row untagged, primary checkout, non-dev branch → `failures=1`) and T10 (`main` + `v11-dev` on one commit → `failures=1, worktree_allowance=False`) are genuine bite tests — accepted. Check 39: T11/T12/T15 bite at the row level — accepted; but I proved the *parser* layer has no bite proof and can go inert undetected (**M1** table, **M2**). | **COMPLIANT** |
| **ci-guard-measure-then-bound** | Reproduced the Check 39 measurement independently: 13 rows → 12 KEEP / 1 STRIP (`PROMPT-TEMPLATES.md`, `find` → 0 hits); sweeps 3 rows → 3 KEEP / 0 STRIP; `_CHECK_39_MIGRATOR_EXEMPTIONS` size **0**. Live summary quoted: "*15 … reverse-checked … 15 are backed by a shipped source, 0 on the migrator exemption allowlist*". Candidate set drawn from `git ls-files` (tracked), not a FS walk — verified in source at `boundary_refs.py:1416`; git-unavailable path SKIPs leniently (T16). Absence-of-backing case is caught (T11/T12). Reproduced Check 4's measurement too (`rows[-1]='v1'`, a tag that always exists). Flagged the one bounding error: **S3**, the pathspec scope. | **COMPLIANT** |
| **ci-check-runtime-compounding** | Check 39 leg 3: one bounded subprocess + one file read + O(15) set-membership; no per-row subprocess, no tree walk — read from source. Check 4: ≤3 extra `git` forks, and only on the branch already about to FAIL; once the README row and the tag agree it short-circuits at `readme_version_tag in tags` for zero added cost. Both acceptable; no finding raised on cost. | **COMPLIANT** |
| **operating-docs-no-history-no-bloat** | `pack-ops/PACK-CHAT.md`: the removed "Action items (PM coordination)" section was pure audit-trail pointing at a deleted doc — correct removal; verified no orphaned `---`, no empty section (`## ` / `---` map re-read), and zero repo-wide references to the removed section. `PACK-MEMORY-RATIONALE.md`: path-only repoint, no history added. The allowlist header edit removes a dead record, tightening the file — but leaves **M5** (two stale `K2-K6` refs). No history text added anywhere. | **COMPLIANT** |
| **public-bound-no-leak** | Check 93 green: "*no target-app literal-name leak in any git-tracked file (leg 1, tree-wide) and no domain-vocabulary … leak on client/public surfaces (leg 2 …), except the one allowlisted `x-brokerage-api` row-name keep*". Client/public surfaces touched: `supporting-docs/MIGRATION-v10-to-v11.md` and `.github/workflows/validate-pack.yml` — both clean, correct tier. Internal surface touched: `changelog/v11.md` — internal tier, correctly exempt. Verified `no_leak.py`'s change is comment-only (`_CLIENT_PREFIXES`, `_CLIENT_ROOT_FILES`, `_LEG2_ALLOWLIST` byte-identical), so the check's logic is not weakened. My own wording here stays abstract. Raised **M3** off this rule. | **COMPLIANT** |
| **fail-loud-delete-old-source** | `diff -rq` shows each of the 8 docs as *Only in* base **or** *Only in* work — never both. No mirror at any old path. Verified the cited-as-deleted docs are genuinely gone: `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION{,-ADDENDUM,-ADDENDUM-2}.md`, `PLAN-PER-ENTRY-SPLIT-BATCH-19.md`, `RELEASE-GATE.md`, `ARCHITECTURE-SKILL-DIMENSIONS.md`, `PLAN-SKILL-DIMENSIONS.md` → all `exists=0`; `ARCHITECTURE-PER-ENTRY-SPLIT.md` (still cited) → `exists=1`. Every new comment's "deleted at BD-210" claim is factually accurate. | **COMPLIANT** |
| **pack-repo-code-comment-deferrals** | Grepped all 11 changed source files for `TODO`/`FIXME`/`XXX`/`HACK`/"fix later" minus the typed forms. Every hit is a false positive or pre-existing: `mktemp … XXXXXX` templates (5); `migrate-v10-to-v11.sh:695` prose ("*not a manual-re-creation TODO*"); `test-fixtures/build.sh:849,858,864,867,875` = deliberate synthetic **fixture content** written into a WIP test project. **Zero untyped deferrals introduced.** | **COMPLIANT** |
| **graph-first-context** | Used the **injected** path `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json` verbatim; never recomputed from my own toplevel (correctly — `graphify-out/` is absent in the worktree, confirmed by `ls`). Ran 3 discovery queries with `--backend claude-cli --budget 1000-1500` **before** any broad read. They surfaced a candidate set but do not index markdown filename mentions in prose/comments, so per **G2** I fell back to grep for the completeness census and said so explicitly (§6.2). Verification reads (exact bytes, SSOT `Status:` values, whole-file content of named files, uncommitted working-tree files) correctly used grep/Read per the fall-through carve-outs. | **COMPLIANT** |
| **memory-not-an-ssot** | Re-read the live in-repo SSOT rather than trusting this prompt's summaries: `backlog/_rules.md` and `changelog/_rules.md` in full (which is how I established that `_toc.md` needs no regeneration — it is keyed on the `## vN` H2 only); `check_operating_doc_no_history()` and `check_dangling_file_refs()` source (which is how I established Check 65 has no dead-entry enforcement and Check 68 basename-resolves); the allowlist header; `migrator-core.sh`'s hook contract. Read both the pre- and post-change state of `PACK-CHAT.md` and `PACK-MEMORY-RATIONALE.md` via the base↔work diff. No cached rule acted on. | **COMPLIANT** |
| **deferral-is-scope-creep** / **no-deferral-without-user-direction** | Reported every defect at its true severity with the release cut imminent, and softened nothing: B1 is called a BLOCKER even though its file is pack-chat-only; M4 is called a MUST even though it is pre-existing and outside the coder's stated scope, because it is unblocked work in an unlaunched v11.0. I recommended **no** deferral to v11.1+ anywhere, and I flagged the one live instance of this rule in the change set itself (**S6**: BD-280 is Open with `Target: v11.0` and would be carried past the RC1 tag without an explicit user ruling). | **COMPLIANT** |
| **deferred-work-tracked-anchor** | Nothing in this report is an unanchored "should probably". Every item names a concrete file:line and a concrete action. The two items I recommend *not* fixing here both already carry live anchors: the dashboard snapshot → **BD-280** (Open, `Target: v11.0`), and BD-138/BD-139's historical citations → deliberately left per the Check-48 accurate-history idiom (a stated decision, not a deferral). | **COMPLIANT** |
| **open-item-surfacing** | Five open items in §7, each with context, my own options, and an evidence- or logic-based recommendation: OI-1 keep-the-widening (6 evidence points), OI-2 retitle the H3 (b), OI-3 add an unmatched-record WARN (b), OI-4 replace the README enumeration with a derived pointer (c), OI-5 re-render under BD-280 after the sweep (b). No recommendation rests on memory, and none defers or delays work to another or a new BD. | **COMPLIANT** |
| **preflight-stop-means-stop** | PREFLIGHT line emitted only after the review **and** its verification completed — all 132 wired tests finished (`exit code 0`), both validate-pack modes, `build.sh --verify`, and the shard self-check, before the line was written. §8 states explicitly what I could **not** verify, so nothing partial is presented as complete. No parent stop/halt message was received. | **COMPLIANT** |

---

## 10. Verdict

**NOT CLEAN.**

| Severity | Count | IDs |
|---|---|---|
| BLOCKER | 1 | B1 |
| MUST | 5 | M1, M2, M3, M4, M5 |
| SHOULD | 6 | S1, S2, S3, S4, S5, S6 |
| NIT | 7 | N1–N7 |
| Open items | 5 | OI-1 … OI-5 |

**The whole battery is green** (132/132 wired tests, both validate-pack modes,
fixture verify, shard coverage) — which is exactly why B1 and M1 matter: a green
run is not evidence here. B1 is a shipped mismatch that will red CI on `main` at
the cut. M1 reintroduces the *same* silently-inert-guard defect class that
BD-093 exists to fix, in the same commit, in the neighbouring check — and M2
means its own test cannot detect it.

**Minimum to land:** B1 + M1 + M2 + M3 + M5 (M5 and M3 are one-line edits; B1 is
a Pack-Chat README/tag sequencing action). M4 and the SHOULDs are the
"NO MISMATCHES" residue and I recommend all of them for this batch under
`deferral-is-scope-creep`.

**Routing note:** B1 (`README.md`), S4/S5 (`backlog/`), S1/S2/S6
(`changelog/`) and OI-4 all land in pack-chat-only files — Pack Chat's edits or
a coder scoped in by Pack Chat's prompt. M1, M2, M3, M5, S3 and the NITs are
coder work.
