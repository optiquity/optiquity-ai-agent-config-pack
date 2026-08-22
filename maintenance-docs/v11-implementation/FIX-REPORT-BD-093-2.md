# FIX-REPORT-2 — BD-093 v11.0 (RC1) release cut, fix pass 2 of 2

**Agent:** `pack-coder` (fresh instance), fix pass 2 — the FINAL fix pass of
the bounded cycle.
**Date:** 2026-08-21

---

## 1. Runtime regime (verified, not assumed)

| Item | Value |
|---|---|
| Spawned-isolated worktree (MINE, unused for edits) | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a134efba42d724519` |
| Work worktree (TARGET, all edits here) | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a3e94ef9f38a11308` |
| Target branch | `worktree-agent-a3e94ef9f38a11308` |
| Target HEAD (pre-work and post-work, unchanged) | `ee66ba57c355d449a536360061fd46d633651fbc` |
| Expected HEAD per prompt | `ee66ba57c355d449a536360061fd46d633651fbc` — **MATCH** |

**How HEAD was verified (harness constraint disclosure).** The harness
REFUSED every `cd <target> && git …` invocation:

```
This agent is isolated in the worktree …agent-a134efba42d724519, but this
command changes directory to the shared checkout (…agent-a3e94ef9f38a11308)
before running git. Refusing to run it …
```

Per the prompt's instruction I did **not** work around it. I used the two
sanctioned fallbacks:

1. **`.git` plumbing reads** —
   `cat .git/worktrees/agent-a3e94ef9f38a11308/HEAD` → `ref: refs/heads/worktree-agent-a3e94ef9f38a11308`;
   `cat .git/refs/heads/worktree-agent-a3e94ef9f38a11308` → `ee66ba57c355d449a536360061fd46d633651fbc`.
2. **`diff -rq`** of MINE (clean at the same SHA — `git status --short`
   empty in my own worktree) against TARGET, to enumerate the pre-existing
   uncommitted change set.

No `git` verb was ever run against the target tree. Post-work re-read of
`.git/refs/heads/worktree-agent-a3e94ef9f38a11308` still returns
`ee66ba57c355d449a536360061fd46d633651fbc` — HEAD unmoved, nothing staged,
nothing committed.

---

## 2. Executive summary

| Task | Outcome | Edits |
|---|---|---|
| T1 — qualify bare `MERGE-STRATEGY.md` refs | **RESOLVED** | 12 refs qualified (+1 same-class ref, see OI-1) |
| T2 — changelog BD-280 honesty | **RESOLVED** | 1 block rewritten (3 lines → 11 lines) |
| T3 — re-verify carried-over list | **NO CHANGE NEEDED** (verified correct) | 0 |

Verification: `validate-pack.py` exit 0; `PACK_VALIDATE_DEEP=1` exit 0;
**132/132** wired tests pass; `test-fixtures/build.sh --verify` exit 0 (7/7
fixtures); shard `--assert-coverage` exit 0. Zero dangling cross-references
introduced.

---

## 3. T1 scoping premise — the load-bearing verification

The prompt correctly flagged this as the fact the whole task rests on: is
`supporting-docs/MIGRATION-v10-to-v11.md` installed into a client project?
If it were, pointing it at `pack-ops/…` would be a client-install
regression (P-missed-7), not a fix. I verified it **four independent ways**,
all agreeing: **NOT client-installed.**

### Leg 1 — `init-project.sh` copy sites

Only two files are copied out of `supporting-docs/`:

```
scripts/init-project.sh:922:  if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
scripts/init-project.sh:933:  if [[ -f "$PACK/supporting-docs/INSTALL-PROCEDURES.md" ]]; then
```

`MIGRATION-v10-to-v11.md` has no copy site.

### Leg 2 — the `_CLIENT_INSTALLED_FILES` install-map SSOT

The authoritative install inventory
(`scripts/init-project.sh`, `_CLIENT_INSTALLED_FILES_START/_END`, L1766–1800)
contains exactly two `supporting-docs/` rows:

```
#   supporting-docs/METHODOLOGY.md  ->  docs/pack/METHODOLOGY.md  [stage:S6,cmd_update]
#   supporting-docs/INSTALL-PROCEDURES.md  ->  docs/pack/INSTALL-PROCEDURES.md  [stage:S6,cmd_update]
```

`MIGRATION-v10-to-v11.md` is absent.

### Leg 3 — executed the validator's OWN client-surface function

Rather than reasoning about the map, I invoked the real
`_iter_client_installed_files()` from
`scripts/lib/validate_checks/boundary_refs.py` — the exact function Check 43
uses to decide what counts as a client surface:

```
total client-installed files walked: 184
supporting-docs/ entries on the client surface: ['supporting-docs/METHODOLOGY.md', 'supporting-docs/INSTALL-PROCEDURES.md']
IS 'supporting-docs/MIGRATION-v10-to-v11.md' ON CLIENT SURFACE? -> False
_CHECK_43_PACK_INTERNAL_PREFIXES = ('maintenance-docs/', 'pack-ops/')
_SANCTIONED_PACK_SIDE_SHIPPED = ()
```

This is decisive: `_CHECK_43_PACK_INTERNAL_PREFIXES` means a bare ref
resolving into `pack-ops/` **is** a FAIL — but only on a walked client
surface, and this file is not one. (Re-run post-edit: identical output.)

### Leg 4 — the repo's own test suite already classifies it

`scripts/tests/test-validate-pack-check-43.sh:387` encodes the same fact
independently, in the pack's own words:

```
# T1: FAIL (pre-install-only supporting-docs/MIGRATION-v10-to-v11.md
```

The test suite calls the file **"pre-install-only."** Check 43's T1 case
exists precisely because a bare `MIGRATION-v10-to-v11.md` on a *client*
surface is a leak — the doc itself is a pack-clone doc.

### Migrator leg

The migrator installs nothing from `supporting-docs/`. Its sole mention is
a user-facing message that already carries the `supporting-docs/` prefix:

```
scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh:111:
  say "[FAIL] lines above before re-running. See supporting-docs/MIGRATION-${_from}-to-${_to}.md"
```

**CONCLUSION: premise CONFIRMED.** The reader is working in the pack clone,
where `pack-ops/MERGE-STRATEGY.md` is present. Qualifying with `pack-ops/`
is correct and is *not* a boundary regression. I did not need to STOP.

---

## 4. T1 — qualify the bare `MERGE-STRATEGY.md` references

### Discovery method (graph-first, attested)

DISCOVERY/RECALL ran on the injected graph **before** any broad read:

```
graphify query "all files that reference or cite MERGE-STRATEGY.md" \
  --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json \
  --backend claude-cli --budget 1500
→ Traversal: BFS depth=2 | 13 nodes found
→ NODE Check 40 fixtures — pack-ops/ bare cross-reference scanner
     [src=scripts/tests/fixtures/bare-cross-refs/README.md]
```

The graph paid for itself here: it surfaced **validate-pack Check 40 — the
`pack-ops/` bare cross-reference scanner** — a governing convention an
a-priori grep for `MERGE-STRATEGY` would never have returned. That single
node is what told me (a) the repo has a *named, enforced* convention for
exactly this defect, (b) its remedy shape is path-qualification, and (c) its
scope is `pack-ops/` only — which is *why* `supporting-docs/` was never
covered. Grep was then used only for VERIFICATION at the named surfaces.

### Convention followed (measured, not assumed)

| Surface | Form used |
|---|---|
| `QUICKSTART.md:42` | ``[`pack-ops/MERGE-STRATEGY.md`](pack-ops/MERGE-STRATEGY.md)`` — path-qualified |
| `README.md:277` | bare, inside a directory-tree diagram (structurally correct there) |
| Check 40 test PASS case (`test-validate-pack-check-40.sh:100`) | ``see \`supporting-docs/MIGRATION-v10-to-v11.md\`` — path-qualified |
| The edited doc's own dominant style | path-qualified: ``docs/pack/PLATFORM-SKILLS.md`` ×8, ``scripts/pm-help.sh`` ×4, ``scripts/migrate-v10-to-v11.sh`` ×2, … |

The doc already cites everything else path-qualified. `MERGE-STRATEGY.md`
was the single largest bare-basename outlier at 12 hits. I adopted the
existing convention — backticked path-qualified — rather than inventing a
hyperlink form the doc does not otherwise use.

### Target resolution (unambiguous)

```
find … -name 'MERGE-STRATEGY.md' → pack-ops/MERGE-STRATEGY.md   (exactly one)
```

### Edit applied

Targeted in-place substitution (no restructuring, no content inlined, no
sentence meaning changed):

```
sed -i '' 's/`MERGE-STRATEGY\.md`/`pack-ops\/MERGE-STRATEGY.md`/g' \
  supporting-docs/MIGRATION-v10-to-v11.md
```

Pre-edit state: `grep -c 'pack-ops/MERGE-STRATEGY.md'` → **0** already
qualified (so no double-prefixing was possible).

### Evidence resolved — all 12 sites

```
54:  report format. See `pack-ops/MERGE-STRATEGY.md` for the per-file class matrix.
90:  the single-shot UX is preserved. See `pack-ops/MERGE-STRATEGY.md` §A1 for
218:   `pack-ops/MERGE-STRATEGY.md`); reconcile
224:   regardless of the reframe (see `pack-ops/MERGE-STRATEGY.md` per-file
252:`pack-ops/MERGE-STRATEGY.md`.
392:`pack-ops/MERGE-STRATEGY.md` § "12. `generic` — everything else" for the
413:   `pack-ops/MERGE-STRATEGY.md` for which classes can produce sidecars.
511:| 31 | `EXIT_GATE_FAILED` … See `pack-ops/MERGE-STRATEGY.md` §A1 for full gate semantics. |
530:for that gate. See `pack-ops/MERGE-STRATEGY.md` §A1 for the full gate
614:See `pack-ops/MERGE-STRATEGY.md` for the full per-file class matrix that explains
697:   and so on. See `pack-ops/MERGE-STRATEGY.md`.
827:This should never happen for the 12 documented classes (`pack-ops/MERGE-STRATEGY.md`).
```

Counts: **12 qualified / 0 bare remaining.**

```
grep -c 'pack-ops/MERGE-STRATEGY.md'  → 12
grep -oE '`MERGE-STRATEGY\.md`' | wc -l → 0
```

Target exists (no dangling ref):
`-rw-r--r-- 31332 pack-ops/MERGE-STRATEGY.md`.

Line count 887 → 887 (pure in-place substitution; nothing added or dropped).

---

## 5. T2 — changelog BD-280 honesty

### Source read (SSOT, not the prompt's paraphrase)

Per `memory-not-an-ssot` I read `backlog/BD-280.md`'s real `Resolved:` line.
Verbatim excerpts driving the rewrite:

> "the entry's **PREMISE IS FALSE** … There is **NO** spec-embedded curated
> doc-index: not in `…/dashboard-shell.html`, not in `…/DASHBOARD-SPEC-PACK.md`,
> not in `scripts/dashboard-render.py`. Every `maintenance-docs/` path the
> board shows is **ALREADY LIVE-DERIVED** … option (a) (prune a curated list)
> had nothing to prune. The one actionable piece — a re-render AFTER this
> batch's 8 archive moves … was performed: `RENDER OK` / `VERIFY OK`, Check 88
> green, shell byte-identical. Acceptance criterion … is **NOT ACHIEVABLE AS
> WRITTEN** and was not forced: the residual dead paths are verbatim quotes of
> Resolved historical entries (BD-138 / BD-139) …"

I independently corroborated the "8 archive moves" count: `diff -rq` shows
exactly 8 files relocated into `maintenance-docs/archive/v11/`
(EXECUTION-PLAN-V11.0, RESEARCH-BD-185, RESEARCH-BD-204 ×4, RESEARCH-BD-212,
RESEARCH-BD-217).

### The defect

`changelog/v11.md:600–602` claimed BD-280 "landed IN this cut" — reading as
a fix that was applied, which is exactly what did **not** happen:

```
BD-093 is the cut itself and resolves with this entry. BD-280 (dashboard
doc-index staleness) carried `Target: v11.0` and landed IN this cut, so it
is not carried over.
```

### The correction (applied — `changelog/v11.md:600–610`)

```
BD-093 is the cut itself and resolves with this entry. BD-280 (dashboard
doc-index staleness) carried `Target: v11.0` and resolves in this cut, so
it is not carried over. Its premise proved false on investigation: there
is no spec-embedded curated doc-index, and every `maintenance-docs/` path
the board renders was already live-derived, so there was no stale list to
prune. The one actionable item — a re-render after this cut's 8 archive
moves — was performed (`RENDER OK` / `VERIFY OK`, Check 88 green, shell
byte-identical). Its acceptance criterion is not achievable as written and
was deliberately not forced: the residual dead paths are verbatim quotes
of Resolved historical entries, whose pre-move citations are accurate
history.
```

Every clause traces to the `Resolved:` line; no claim was invented. The
"not carried over" conclusion is preserved (it is still true — BD-280 is
`Status: Resolved`). Dash style normalized to the document's em-dash house
convention.

Applied via an exact-match Python replace asserting `count == 1`
(`assert s.count(old) == 1`) — a surgical edit, not a rewrite. Only one
BD-280 mention exists in the changelog (`grep -n "BD-280" changelog/v11.md`
→ single hit at L600), so there is no second site to keep in sync.

Line count 602 → 610 (+8).

### `_toc.md` regeneration

`changelog/_rules.md` requires TOC regeneration after a release edit. The
changelog TOC is release-level only (filename + H2 date); my edit changed
body prose, not the `## v11 — August 2026` heading. Check 33 confirms it is
already in sync, so no regeneration was required:

```
── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/_toc.md byte-identical (34438 bytes)
  OK: changelog/_toc.md byte-identical (585 bytes)
```

I edited nothing under `backlog/` (the orchestrator's surface).

---

## 6. T3 — re-verify the carried-over list

**Outcome: the list is already correct at HEAD. No change made.**

Re-derived from `backlog/` rather than trusting the existing text.

### All Open BDs at HEAD (16)

```
grep -l '^Status: Open' BD-*.md → BD-020 BD-036 BD-037 BD-039 BD-093 BD-109
BD-110 BD-171 BD-172 BD-187 BD-192 BD-202 BD-223 BD-247 BD-254 BD-279   (16)
```

BD-280 is absent → correctly Resolved, correctly excluded from the list.
BD-093 is the cut itself (the changelog says so in the same paragraph), so
carried-over = 16 − 1 = **15**.

### Targeted split — by actual `Target:` field

Only 5 Open BDs carry a `Target:` line at all, and all 5 are `v11.1`:

```
BD-202.md:Target: v11.1 (NOT v11.0) — see Disposition + reversal trigger.
BD-223.md:Target: v11.1 — moved out of v11.0 (user 2026-06-27) …
BD-247.md:Target: v11.1
BD-254.md:Target: v11.1 (user direction 2026-06-28 …)
BD-279.md:Target: v11.1 (user-directed 2026-08-02 …)
```

The other 10 (BD-020, BD-036, BD-037, BD-039, BD-109, BD-110, BD-171,
BD-172, BD-187, BD-192) have **no** `Target:` line → untargeted.

### Match against the changelog

| Section | Changelog lists | Re-derived | Verdict |
|---|---|---|---|
| `_Targeted v11.1_` | BD-202, BD-223, BD-247, BD-254, BD-279 | identical | **5/5 MATCH** |
| `_Open, untargeted_` | BD-020, BD-036, BD-037, BD-039, BD-109, BD-110, BD-171, BD-172, BD-187, BD-192 | identical | **10/10 MATCH** |

All 15 titles were also spot-verified against each entry's `**BD-NNN — …**`
title line and match.

BD-171 and BD-172 remain `Status: Open` and were **not touched**, per the
explicit user decision stated in the prompt.

One nicety worth noting (not a defect): the changelog renders BD-171 as
"Real-target scratch-clone…" while the entry title reads "Real-OT
scratch-clone…". The generalized wording is the *safer* form and I left it —
re-introducing the internal codename would move toward the `no-leak`
vocabulary, and the changelog gains nothing from it.

---

## 7. Open items surfaced

### OI-1 — `DRY-RUN-MIGRATION.md`: the identical defect, same file (FIXED — flag for easy revert)

**Context.** My census of the edited file found a *second* bare basename
resolving into `pack-ops/`, one line inside the same procedural section:

```
supporting-docs/MIGRATION-v10-to-v11.md:423 (before)
   would write. See `DRY-RUN-MIGRATION.md` for the full input
find … → pack-ops/DRY-RUN-MIGRATION.md   (exactly one location)
```

This is T1's defect class exactly — same file, same surface, same target
directory, same remedy — but the prompt named only `MERGE-STRATEGY.md`.

**My options.** (a) Fix it with the same substitution and flag it loudly.
(b) Leave it and surface only. (c) Silently widen — excluded by the rules.

**What I did and why: (a).** The rules-in-force text asks me not to widen
*silently* or ignore *silently*; the operative word is *silently*, so I am
flagging it here in its own section rather than burying it. I fixed it
because: this is fix pass 2 of 2 — there is **no pass 3**
(`bounded-review-fix-cycle`), so a known one-line defect of an
already-diagnosed class left in place at the release cut would either ship
or force an architect escalation on the final reviewer pass; and
`deferral-is-scope-creep` admits a deferral only on SIZE / BLOCKED /
LOGICAL FIT, none of which apply to a one-line change in a file I already
had open. Leaving 12 of 13 identical defects fixed is the worse outcome.

**Reverting is trivial** if the orchestrator disagrees — it is exactly one
line:

```
supporting-docs/MIGRATION-v10-to-v11.md:423 (after)
   would write. See `pack-ops/DRY-RUN-MIGRATION.md` for the full input
```

Target exists: `-rw-r--r-- 7656 pack-ops/DRY-RUN-MIGRATION.md`.

**Recommendation:** keep it. It is the same fix the orchestrator already
authorized in concept, and the doc is now internally consistent.

### OI-2 — Structural gap: no check scans non-client-installed `supporting-docs/` for bare pack-internal refs

**Context — this is the root cause of why T1 existed at all.** The pack has
two bare-cross-reference scanners and this file falls between them:

| Check | Walks | Covers this file? |
|---|---|---|
| Check 40 (BD-179) | `pack-ops/*.md` — "10 pack-ops/*.md file(s) walked" | No |
| Check 43 (BD-173 H.14) | the client-installed surface — "181 project-side / client-installed file(s) walked" | No (proved in §3 leg 3) |

`supporting-docs/MIGRATION-v10-to-v11.md` is in neither set, so 12 bare refs
accumulated undetected until a human review caught them at the release cut.

**Post-fix census of the whole surface** (all `supporting-docs/*.md`, every
backticked `*.md` basename, cross-checked against `pack-ops/` and
`maintenance-docs/` basenames):

```
TOTAL bare refs into pack-internal territory across supporting-docs/*.md: 17
```

All 17 residual hits are `ARCHITECTURE.md` (14) and `README.md` (3) — both
explicitly on `_CHECK_43_ALLOWLIST` as project-side-resolving /
ambiguous-by-design basenames ("Project-side docs/project/ARCHITECTURE.md",
"Project-side or pack-side README (resolves at both)"). They are basename
collisions with `maintenance-docs/` files, not defects. **After my fix there
are zero genuine bare pack-internal refs in `supporting-docs/`.**

**My options.** (a) Extend Check 40's walk to include non-client-installed
`supporting-docs/*.md` — the surface is now clean, so it would go green
immediately and stay clean. (b) Leave the gap; rely on review. (c) Do it now
myself.

**Recommendation: (a), but NOT by me and NOT now.** Adding a CI check at the
release cut, on the final fix pass, with no reviewer pass left to catch a
mistake, is the wrong risk trade — and `ci-guard-measure-then-bound` requires
an architect-grade measure-then-bound design pass (allowlist sized to the
legitimate set, absence-of-backing case covered), which is out of scope for a
bounded fix pass. The surface is clean *right now*, so nothing is shipping
broken. I am explicitly **not** proposing a new BD (the user has directed no
new BDs for v11.0); I am handing the orchestrator the measured evidence so
the user can decide. If the answer is "not for v11.0," the fix I just made
still stands on its own.

### OI-3 — BD-192 sits under "Open, untargeted" despite a "v11.1+" title (no change made)

**Context.** BD-192's title is "**v11.1+** Product Specialist (PS)
implementation," but it has **no `Target:` field**; it expresses timing via
`Blockers: v11.0 ships (then the v11.1 cycle architect pass can start)`. The
changelog lists it under `_Open, untargeted_` and abbreviates the title to
"Product Specialist (PS) implementation."

**Options.** (a) Leave as is — the split criterion is mechanically the
`Target:` field, and BD-192 has none. (b) Move it to `_Targeted v11.1_` on
the strength of its title/blockers.

**Recommendation: (a), leave as is.** The other 15 rows were placed by the
`Target:`-field criterion; moving BD-192 on title-prose alone would make the
list's rule inconsistent and unreproducible. A reader is not misled — it is
listed, it is Open, it is carried over. Flagging only so the final reviewer
does not read it as an oversight.

---

## 8. Files changed

| Path | Type | Delta |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a3e94ef9f38a11308/supporting-docs/MIGRATION-v10-to-v11.md` | modified | 13 lines modified in place (12 `MERGE-STRATEGY.md` + 1 `DRY-RUN-MIGRATION.md`); 887 → 887 lines |
| `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a3e94ef9f38a11308/changelog/v11.md` | modified | 1 paragraph rewritten (L600–610); 602 → 610 lines (+8) |

No new files. No deletions. No renames. Nothing under `backlog/` touched.
`diff -rq` MINE-vs-TARGET reports the same 59-entry changed set as the
pre-work baseline — I introduced no new changed paths beyond the two files
above, which were already in the set from fix pass 1.

All scratch (scripts, logs, matrix, census) was written to my owned handoff
dir only.

---

## 9. Verification — the FULL wired battery

Wired set enumerated from `.github/workflows/validate-pack.yml` (all four
jobs: `validate`, `plan`, `tests`, `tests-result`).

| Job / step | Command | Result |
|---|---|---|
| `validate` | `python3 scripts/validate-pack.py` | **exit 0** — `PASSED — all checks clean` |
| `validate` (deep) | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **exit 0** — `PASSED — all checks clean` |
| `plan` | `scripts/lib/ci-shard-plan.py --emit-matrix` | **exit 0** — 4 shards (37/31/32/32) |
| `tests` | every wired test script, CI run-loop semantics | **132/132 PASS, 0 FAIL** |
| `tests` (fixtures) | `test-fixtures/build.sh --verify` | **exit 0** — 7/7 fixtures OK |
| `tests-result` | `scripts/lib/ci-shard-plan.py --assert-coverage` | **exit 0** |

Battery summary line (`battery-results.txt`):

```
SUMMARY pass=132 fail=0 total=132
```

Shard self-check:

```
ci-shard-plan --assert-coverage OK: 132 wired KEEP test(s) across 4 shard(s);
union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group
co-located in one shard.
```

Fixture verify:

```
v10-minimal OK / v10-realistic-ot OK / v11-realistic-ot OK / v11-flat-file OK
v11-tracker-on OK / existing-project-mid-dev OK / existing-project-collision OK
```

**132/132 matches the stated prior baseline of 132/132 — no regression, no
test count drift.**

Checks most relevant to these edits:

```
Check 40 — 10 pack-ops/*.md file(s) walked; zero unqualified bare
  cross-references (66 allowlist-exempt + 2 anchor-phrase-exempt +
  15 same-dir-legit hit(s) accepted)
Check 43 — 181 project-side / client-installed file(s) walked; zero
  pack-internal bare cross-references
Check 93 — no target-app literal-name leak in any git-tracked file (leg 1)
  and no domain-vocabulary / codename leak on client/public surfaces (leg 2)
Check 33 — backlog/_toc.md byte-identical; changelog/_toc.md byte-identical
```

### Deliberate omissions from the CI recipe (with reasons)

- **`test-fixtures/build.sh --all --clean` — NOT run.** `--clean` deletes and
  rebuilds the fixture trees, a destructive filesystem operation on the repo
  outside my owned dir (`per-action-approval-sub-agents`). The fixtures were
  already built and present in the target worktree, so `--verify` compares
  real SHAs against the committed manifest and is the meaningful signal.
- **`git checkout HEAD -- test-fixtures/manifest.txt` — NOT run.** A
  state-changing git verb, categorically forbidden
  (`agents-never-commit`). It exists in CI only to undo the rebuild I did not
  perform, so skipping it is correct rather than a gap.
- **`manifest-sync.sh` — NOT run.** Push-time and orchestrator-owned
  (`regenerate-manifest-v11-surface`); no fixture input changed.

---

## 10. Definition of Done

| # | Item | Status |
|---|---|---|
| 1 | T1 resolved — every `MERGE-STRATEGY.md` ref resolves unambiguously | **PASS** (12/12; 0 bare remaining) |
| 2 | T1 premise verified, not assumed | **PASS** (4 independent legs, §3) |
| 3 | T1 matches the repo's existing citation convention | **PASS** (QUICKSTART + Check 40 remedy form + doc's own dominant style) |
| 4 | T1 made no structural/semantic change to the doc | **PASS** (887 → 887 lines; substitution only) |
| 5 | T2 changelog consistent with BD-280's real `Resolved:` line | **PASS** (§5, clause-by-clause traced) |
| 6 | T2 edited nothing under `backlog/` | **PASS** |
| 7 | T3 carried-over list re-derived from `backlog/` at HEAD | **PASS** (15/15 match; no change needed) |
| 8 | BD-171 / BD-172 untouched | **PASS** |
| 9 | `validate-pack.py` exit 0 | **PASS** |
| 10 | `PACK_VALIDATE_DEEP=1` exit 0 | **PASS** |
| 11 | Full wired battery green | **PASS** (132/132) |
| 12 | `build.sh --verify` + shard self-check green | **PASS** (both exit 0) |
| 13 | Zero dangling cross-references introduced | **PASS** (both targets exist; Checks 40/43 green) |
| 14 | No state-changing git verb run | **PASS** (HEAD unmoved) |
| 15 | No patch produced | **PASS** (no `git diff > …`) |
| 16 | Open items surfaced with options + recommendation | **PASS** (OI-1, OI-2, OI-3) |

**Plan deviations:** one, disclosed in full as **OI-1** (the same-class
`DRY-RUN-MIGRATION.md` line, fixed and flagged for trivial revert). No other
deviation.

**New POQs:** none.

---

## 11. Rules-Applied Verification Block

### agents-never-commit
**Evidence:** No state-changing git verb was run at any point. The only git
invocations attempted were `git rev-parse HEAD`, `git status --short`,
`git rev-parse --abbrev-ref HEAD` — all in MY OWN worktree, all read-only.
Every `cd <target> && git …` was REFUSED by the harness ("Refusing to run
it — a worktree-isolated agent's git operations must target its own
worktree") and I did not work around it; I used `.git` plumbing reads and
`diff -rq` instead (§1). Target HEAD before work:
`ee66ba57c355d449a536360061fd46d633651fbc`; after all edits, re-read of
`.git/refs/heads/worktree-agent-a3e94ef9f38a11308` →
`ee66ba57c355d449a536360061fd46d633651fbc`. Unmoved. I also declined the
CI recipe's `git checkout HEAD -- test-fixtures/manifest.txt` (§9).
**Conclusion:** COMPLIANT

### per-action-approval-sub-agents
**Evidence:** No `rm`, `rmdir`, `unlink`, `mv`, `shred`, `truncate`,
`find -delete`, or `git rm` was executed. All scratch went to my owned
handoff dir: `battery-results.txt`, `logs/`, `matrix.json`,
`premise_check.py`, `run-battery.sh`, `t2_edit.py`, `t2_dash.py`,
`census.py`, `validate-*.log`, `wired-tests.txt`, `fixture-verify.log`.
I explicitly declined `test-fixtures/build.sh --all --clean` because
`--clean` deletes fixture trees outside my owned dir (§9). Nothing outside
the handoff dir was deleted or destructively overwritten; the only writes
outside it were the two authorized in-scope source edits.
**Conclusion:** COMPLIANT

### bounded-review-fix-cycle
**Evidence:** Treated as fix pass 2 of 2 with no pass 3 available. This
directly drove the OI-1 decision — I fixed the one-line same-class
`DRY-RUN-MIGRATION.md` defect rather than deferring it, reasoning in §7
OI-1 that "there is **no pass 3**… a known one-line defect of an
already-diagnosed class left in place at the release cut would either ship
or force an architect escalation." Conversely I declined to author a new CI
check (OI-2) precisely because no reviewer pass remains to catch a mistake
in it. No partial patch was applied anywhere; both tasks requiring edits are
complete, and T3 is complete-by-verification.
**Conclusion:** COMPLIANT

### Real fixes only — no green-the-test band-aids
**Evidence:** No assertion was deleted, no test commented out, no exception
swallowed, no expectation retuned to match buggy output. Zero test files and
zero validator files were modified — the "Files changed" inventory (§8) is
exactly two documentation files. The battery result of 132/132 was obtained
against the unmodified test suite, and the pre-existing baseline was already
132/132, so nothing was suppressed to manufacture green. Both fixes address
the underlying defect (an ambiguous reference; an untrue changelog claim)
rather than a symptom.
**Conclusion:** COMPLIANT

### edit-in-place-not-full-rewrite
**Evidence:** T1 was a single targeted `sed` substitution of a backticked
token; the file's line count is unchanged, 887 → 887, proving no structural
rewrite. T2 was an exact-match replacement guarded by
`assert s.count(old) == 1`, touching one paragraph (602 → 610 lines). I
re-read the section map after each edit (`sed -n '598,614p'`,
`grep -n 'MERGE-STRATEGY'`) and confirmed the surrounding content intact.
Fix pass 1's earlier edits to both files were left undisturbed — the
`diff -rq` changed-path set is identical to the pre-work baseline (59
entries), i.e. I added no new changed paths and reverted none.
**Conclusion:** COMPLIANT

### verify-full-ci-suite
**Evidence:** Enumerated the wired set from
`.github/workflows/validate-pack.yml` across all four jobs, not
validate-pack alone. Ran: `validate-pack.py` (exit 0),
`PACK_VALIDATE_DEEP=1 validate-pack.py` (exit 0), `--emit-matrix` (exit 0,
4 shards), all 132 wired tests (`SUMMARY pass=132 fail=0 total=132`),
`test-fixtures/build.sh --verify` (exit 0, 7/7 fixtures),
`ci-shard-plan.py --assert-coverage` (exit 0, "132 wired KEEP test(s) across
4 shard(s)"). The two CI steps not run are disclosed with reasons in §9
(both are forbidden-verb or destructive steps whose purpose does not apply
because I did not rebuild fixtures).
**Conclusion:** COMPLIANT

### enumerate-encoding-surfaces
**Evidence:** I searched for every surface encoding expectations about this
doc's citation form:
`grep -rln "MIGRATION-v10-to-v11" scripts/tests/ scripts/lib/validate_checks/`
→ 7 hits. Each was inspected and each proved to be a *synthetic* fixture
string or a code comment using the basename as an illustrative example —
`test-validate-pack-check-40.sh:86,100` (tmpdir-generated fragments),
`test-validate-pack-check-43.sh:390` (`{"FOO.md": …}` tmpdir dict),
`boundary_refs.py:1505` (a regex-explaining comment), and fixture files under
`scripts/tests/fixtures/`. **None asserts on the real
`supporting-docs/MIGRATION-v10-to-v11.md` file's content**, so no validator
or test moves with this edit. Confirmed empirically: the full 132-test
battery passes unchanged. For the changelog, Check 33 verifies
`changelog/_toc.md` byte-identical, and `grep -n "BD-280" changelog/v11.md`
returned a single site, so there is no second surface to update.
**Conclusion:** COMPLIANT

### boundary-investigation / P-missed-7
**Evidence:** This was the gating investigation and is documented in full in
§3. Before pointing a `supporting-docs/` doc at a `pack-ops/` path I proved
the file is not client-installed by four independent legs: init-project.sh
copy sites (only METHODOLOGY.md + INSTALL-PROCEDURES.md); the
`_CLIENT_INSTALLED_FILES` install map (same two rows); executing the
validator's own `_iter_client_installed_files()` →
`IS 'supporting-docs/MIGRATION-v10-to-v11.md' ON CLIENT SURFACE? -> False`;
and the pack's own test suite calling it "pre-install-only"
(`test-validate-pack-check-43.sh:387`). I also confirmed the migrator
installs nothing from `supporting-docs/`. Because the file is NOT a client
surface, the `pack-ops/` pointer is correct rather than a client-install
regression — the premise held, so no STOP was required. Check 43 remains
green post-edit (181 files walked, zero pack-internal bare refs).
**Conclusion:** COMPLIANT

### public-bound-no-leak
**Evidence:** T1 edits `supporting-docs/` (strict client/public tier). The
substitution inserted only the literal directory token `pack-ops/` — no
project name, no domain vocabulary. T2/T3 touch `changelog/` (internal
tier). I introduced no internal codename anywhere, and specifically declined
to "correct" the changelog's generalized "Real-target scratch-clone" wording
back toward the BD's internal "Real-OT" title (§6), keeping the safer form.
This report keeps the rule's wording abstract. Verified by the gate itself:
`Check 93 — no target-app literal-name leak in any git-tracked file (leg 1,
tree-wide) and no domain-vocabulary / codename leak on client/public
surfaces (leg 2, project-template/ + supporting-docs/ + .github/ + repo-root
README + pack-root trinity)` — OK.
**Conclusion:** COMPLIANT

### operating-docs-no-history-no-bloat
**Evidence:** `MIGRATION-v10-to-v11.md` is a procedural operating doc, so I
added ZERO provenance narration while qualifying paths — no "per BD-NNN", no
dated note, no SHA, no rationale sentence. The change is purely the token
`MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md` (and one
`DRY-RUN-MIGRATION.md`), which is why the file's line count is unchanged at
887. The T2 edit adds history text, but its target is `changelog/v11.md` — a
history surface the rule explicitly does not constrain, per the prompt.
**Conclusion:** COMPLIANT

### ci-check-runtime-compounding
**Evidence:** I authored, modified, and deleted zero checks — the "Files
changed" inventory (§8) contains only two `.md` documentation files, no file
under `scripts/lib/validate_checks/` or `scripts/`. No check's per-invocation
cost changed. The rule is therefore not engaged by this work; it *is*
engaged by OI-2, which is exactly why I recommended that a new
`supporting-docs/` scanner go through an architect measure-then-bound pass
rather than being improvised here.
**Conclusion:** N/A: no check was authored or modified.

### graph-first-context
**Evidence:** DISCOVERY ran on the injected graph first, before any broad
read, using the injected path verbatim (never recomputed from my own
toplevel):
`graphify query "all files that reference or cite MERGE-STRATEGY.md" --graph
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json
--backend claude-cli --budget 1500` → `BFS depth=2 | 13 nodes found`. It
returned the load-bearing node `Check 40 fixtures — pack-ops/ bare
cross-reference scanner`, which an a-priori grep for `MERGE-STRATEGY` could
not have surfaced and which supplied the governing convention, its remedy
shape, and the scope gap that explains the defect. grep/Read was then used
only for P2 VERIFICATION at surfaces discovery had named (exact line
numbers, counts, file contents) and for authoritative SSOT field values
(BD `Status:`/`Target:` lines). The completeness census (§7 OI-2) followed
the prescribed order: graph first to find candidate surfaces, then grep each
to grep-zero. No query errored, so no fallback was needed.
**Conclusion:** COMPLIANT

### memory-not-an-ssot
**Evidence:** I re-read the live in-repo SSOT rather than acting on the
prompt's paraphrase or any cache. Specifically: `changelog/_rules.md` before
editing the changelog (which is what told me the TOC regeneration
requirement and the no-mirror contract), and `backlog/BD-280.md`'s actual
`Resolved:` line before writing T2 — quoted verbatim in §5 and traced
clause-by-clause into the new text. For T3 I re-derived the list from the
`backlog/` files themselves (`grep -l '^Status: Open'`, `grep -H '^Target:'`)
rather than trusting the existing changelog text or the prompt's framing.
The T1 premise was likewise re-verified against live repo state, not
accepted from the orchestrator's summary.
**Conclusion:** COMPLIANT

### deferral-is-scope-creep / no-deferral-without-user-direction
**Evidence:** Nothing unblocked was deferred. OI-1 (one-line, same class,
same file) was FIXED rather than deferred, with the reasoning stated in §7:
no SIZE, BLOCKED, or LOGICAL-FIT ground existed to defer it. OI-2 is the one
item not actioned; I defended it on concrete grounds — it requires an
architect-grade `ci-guard-measure-then-bound` design pass with an allowlist
sized to a measured legitimate set, and no reviewer pass remains to validate
a new CI check authored on the final fix pass — and I recorded the measured
evidence (post-fix census: 17 residual hits, all Check-43-allowlisted
basenames, zero genuine defects) so the surface is provably clean today.
I opened NO new BD, per the user's standing direction for v11.0, and routed
the decision to the orchestrator/user instead.
**Conclusion:** COMPLIANT

### open-item-surfacing
**Evidence:** Three open items are surfaced in §7, each with (1) context,
(2) my OWN options, and (3) an evidence-or-logic-based recommendation:
OI-1 (`DRY-RUN-MIGRATION.md` same-class defect — options a/b/c,
recommendation "keep it", with the exact revert line given); OI-2 (the
Check-40/Check-43 coverage gap — options a/b/c, recommendation "extend
Check 40, but not by me and not now", backed by the measured 17-hit census
and the walked-file counts 10 vs 181); OI-3 (BD-192 placement — options a/b,
recommendation "leave as is", backed by the `Target:`-field criterion that
placed the other 15 rows). No recommendation rests on memory, and none
defers or delays work to another or a new BD.
**Conclusion:** COMPLIANT

### preflight-stop-means-stop
**Evidence:** The PREFLIGHT line was emitted only AFTER all edits and all
verification passed — `validate-pack.py` exit 0, `PACK_VALIDATE_DEEP=1` exit
0, `SUMMARY pass=132 fail=0 total=132`, `build.sh --verify` exit 0,
`--assert-coverage` exit 0 — and it carries the real measured HEAD
`ee66ba57c355d449a536360061fd46d633651fbc` and the exact report path. Had
anything failed I would have reported the failure instead of this report. No
stop/halt/revert message was received from the parent during the task.
**Conclusion:** COMPLIANT

---

**End of FIX-REPORT-2.**
