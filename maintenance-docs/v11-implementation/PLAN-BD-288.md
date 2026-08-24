# PLAN-BD-288-READY — implementation plan (4 waves), all decisions closed

**Author:** `pack-planner`, spawn `planner-bd288-reconcile` — the RECONCILIATION instance.
I authored neither the design, nor the first plan, nor the adversarial review of it.
**Date:** 2026-08-23
**Tree:** `/Users/david/Developer/optiquity-ai-agent-config-pack`, branch `main`
**HEAD at every measurement in this document:** `47f8467`
**Working tree at authoring time:** one modified file, `pack-ops/session-state.json` — Pack Chat's
snapshot, out of scope for every wave. Live agent worktrees exist under `.claude/worktrees/`; no
wave touches them and no measurement here entered one.
**Design input:** `ARCHITECTURE-BD-288-FINAL.md` (`bd288-reconcile-20260823-170812/`), FINAL and
fully decided, plus the binding post-design decision **NOI-1 → (b)**.
**Status:** COMPLETE, and **there are no open gates**. Every decision this plan depends on is closed
and recorded in §9. The terminal marker at the foot of this file is the completeness signal — if you
do not see that marker, this document was truncated mid-write and must not be executed.

**This document is standalone and supersedes both `PLAN-BD-288.md` and `PLAN-BD-288-FINAL.md`.** A
coder needs this file and the repo — nothing else. Do not read the superseded plans; three of the
first plan's expected-output lines are wrong and one of its check specifications lands RED.

**What changed since `PLAN-BD-288-FINAL.md`** — three decisions, applied throughout:

1. **OI-R1 → (b), CLOSED.** `_CHECK_95_ALLOWLIST` grows 26 → 34 with the 8 measured-necessary
   basenames, each carrying its own Check-95-walk-scoped `reason:`. Check 95 does **not** read
   `_CHECK_40_ALLOWLIST`; the two guards stay independent. W3 is no longer gated (§2.1, §6.4).
2. **ROI-6's fact 1 restated to its measured form**, and placed at the constant where a maintainer
   tempted to deduplicate the two lists will read it (§6.4).
3. **The Check-81 path-token blind spot is folded into W1.** `_CHECK_81_PATH_TOKEN_RE` cannot
   extract a dot-leading path, so every dotfile surface is invisible to the cross-BD collision scan.
   Measured, specified, and proved safe here (§4.2b, EP-25…EP-28). **W1 still fits one bounded
   cycle** — the argument is in §4.7.

Every other open item is now closed by taking this plan's own recommendation; §9 is a decision
record, not an open list.

**Tool note.** The `Write` tool is not in this session's grant. This document was authored with Bash
heredocs into my own owned handoff directory. No repo file was written, no denied capability was
routed around.

**What this document is.** The design says WHAT and WHY. This says HOW and IN WHAT ORDER, at coder
granularity. Where the design was ambiguous at execution granularity I resolved it and said how;
where it was wrong I measured and said so (§2).

---

## 0. How to read this

| Section | Use |
|---|---|
| §1 | Pre-flight checklist — run before starting ANY wave |
| §2 | **Corrections to the design and to the superseded plan.** Read before W2/W3/W4. Five are load-bearing |
| §3 | Wave dependency graph + file-contention analysis |
| §4–§7 | W1 / W2 / W3 / W4 — file set, edits, ordering, verification gate, cycle fit, commit shape |
| §8 | Per-wave rollback position (what a twice-dirty review leaves behind) |
| §9 | Decision record — context, options, recommendation, DECISION, and where it is applied. All closed; no gates |
| §10 | Empirical-Evidence Blocks (EP-1 … EP-28) |
| §11 | Summary — what lands, in what order, against the acceptance criteria |
| §12 | Rules-Applied Verification Block |

**Conventions.**
- **[BINDING]** marks a constraint whose violation produces a GREEN gate and a WRONG tree, or a RED
  gate a reviewer will misdiagnose. These are the ones a review cannot catch by reading an exit code.
- Line numbers are measured at `47f8467` and are **navigation aids, not anchors**. Every edit is
  specified by its content so it survives drift.
- "the full battery" always means §1.6's six items, never `validate-pack.py` alone.
- Every number offered as an **expected output** in a verification gate was produced by a run
  recorded in §10. Where I could not reproduce a number, I say so at the gate rather than carrying
  it forward.

---

## 1. Pre-flight checklist (before ANY wave)

Run in order. Any failure stops the wave before an edit is made.

**1.1 Position.**
```
pwd                      # the isolated worktree for THIS commit
git rev-parse --short HEAD
git status --porcelain
```
Expect the worktree path (not the canonical checkout), the wave's base SHA, and a clean tree apart
from your own in-progress edits. The FIRST coder of a commit creates the worktree
(`isolation:"worktree"`); every later RW agent in that cycle REUSES it.

**1.2 Rules re-read from the in-repo SSOT** (never from a memory cache):
`CLAUDE.md` § "Pack memory", `pack-ops/PACK-MEMORY-RATIONALE.md` for any `[rationale: …]` you rely
on, `pack-ops/PACK-AGENTS.md` for the pack-chat-only list, `backlog/BD-288.md` for the acceptance
criteria, `README.md` for the version table.

**1.3 Baseline green.** The wave must start from a green tree, or you cannot attribute a later red
to your own edit:
```
python3 scripts/validate-pack.py            # expect: PASSED — all checks clean, exit 0
```

**1.4 Check 81 liveness pre-check — required from W1 onward. [BINDING]**
After W1 lands, Check 81's FAIL leg is live and keys on `pack-ops/session-state.json` `active[]`.
Before running the battery in any later wave:
```
python3 -c "import json;print(json.load(open('pack-ops/session-state.json')).get('active'))"
```
Every BD-ID that leads a member string must have a **structured** `File/Symbol` in its
`backlog/BD-*.md`. At `47f8467` `active[]` holds one member led by `BD-288` and BD-288 is
structured, so the tree is green — but Pack Chat REPLACES this field at every state transition, and
seven open BDs currently carry a bare/TBD `File/Symbol` (BD-020, BD-039, BD-187, BD-192, BD-202,
BD-223, BD-279 — measured, EP-6). If one of those is ever put in `active[]` while BD-288's waves are
in flight, the tree goes RED and the commit is blocked. This is the guard biting correctly, not a
defect; it is a live operational constraint on the whole sequence. See §9 D-6.

**1.5 Graph availability** (for discovery questions only; verification stays grep/Read):
```
ls -l /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json
graphify explain "<symbol>" --graph /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json --budget 1500 --backend claude-cli
```
Use the injected absolute path verbatim; never recompute it from your own toplevel (under worktree
isolation your toplevel has no `graphify-out/`). If absent, fall back to grep/Read and say so.

**Graph caveat, measured (EP-20). [BINDING for W3]** The graph's edge set for a check function lists
its **called** helpers only. `check_bare_pack_ops_refs()` shows `Degree: 7` with three
`--> [calls]` edges (`_build_basename_index`, `_strip_code_blocks`,
`_check_40_context_has_anchor`) and **no edge to `_CHECK_40_ALLOWLIST`**, because a dict membership
test carries no call edge. A "what does Check 40 use" question answered from the graph alone yields
an INCOMPLETE reuse list — that is exactly the omission §2.1 exists to correct. When you replicate a
check's behaviour, read its body.

**1.6 The full battery** — every wave runs ALL of it before writing an IMPL-REPORT:
1. `python3 scripts/validate-pack.py` → exit 0, `PASSED — all checks clean`
2. `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → exit 0 (reaches DEEP-only Check 49)
3. Both workflow jobs: the unsharded `validate` job and the dynamic `tests` matrix, plus
   `python3 scripts/lib/ci-shard-plan.py --assert-coverage`
4. `bash test-fixtures/build.sh --verify` (manifest correctness; the manifest is push-time per
   `regenerate-manifest-v11-surface` and is **not** regenerated per commit)
5. Every per-check test named in the wave's own §"verification gate"
6. The easy-to-miss set, named per wave: **Check 71** (skill-mirror byte-identity), **Check 83** +
   **Check 92** (new/edited wired test), **Check 59** + **Check 80** (registry count / doc-constant
   twin), **Check 66** (bullet concision), **Check 93** (no-leak), **Check 36** (commit-scope
   honesty)

**1.7 PREFLIGHT line.** Emit exactly one plain line before writing the IMPL-REPORT, and only after
every in-scope edit AND the full battery PASS:
`PREFLIGHT: N/N in-scope edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>`
If anything failed, report what went wrong INSTEAD of a partial IMPL-REPORT.

**1.8 You never commit.** No `git add`, `commit`, `push`, `tag`, `stash`, `rm`, `mv`, `reset`,
`restore`, `checkout`, `clean`, `merge`, `rebase`, `apply`, `branch`, `switch`, `worktree`,
`config`(write), `remote`(write), `pull`, `fetch`. Read-only verbs only. Pack Chat commits, with
explicit user approval. Plan your work up to the IMPL-REPORT, not past it.

---
## 2. Corrections — measured, not asserted

The design is sound in substance. Seven statements across the design and the superseded plan do not
survive measurement. Five change what a coder does. **§2.1 is the one that would have shipped a red
wave.**

### 2.1 [LOAD-BEARING, BLOCKER-CLASS] Check 40's exemption ladder has FOUR tiers, and tier 1 is a dict lookup

**What the design and the superseded plan say.** Check 95 "reuses `_strip_code_blocks`,
`_CHECK_40_BARE_REF_PATTERN`, `_CHECK_40_HYPERLINK_PATTERN`, `_check_40_context_has_anchor`, and the
same-dir-legitimate rule **verbatim. No new regex.**" That list is precisely Check 40's set of
**called** helpers.

**What Check 40 actually does** (`scripts/lib/validate_checks/boundary_refs.py:1897–1917`, read
verbatim, EP-21):

```
Tier 1: if basename in _CHECK_40_ALLOWLIST:            hits_allowlist += 1   <-- OMITTED from the reuse list
Tier 2: if _check_40_context_has_anchor(...):          hits_anchor    += 1
Tier 3: single candidate in the same directory:        hits_same_dir  += 1
        else FAIL
```

Tier 1 is a dict membership test, not a call — which is why it fell out of a reuse list built from
call sites, and why the knowledge graph (§1.5) does not show it either.

**Why the omission is invisible in the numbers — the root cause, proved (EP-22). [BINDING]**
The census artifact `c95-triage.json` carries **122** records (77 KEEP + 45 STRIP). I ran Check 40's
FULL four-tier ladder — with `_CHECK_40_ALLOWLIST` as tier 1 — over the 35-file walk and captured
its FAIL set:

```
C40-ONLY tier1, PRE-STRIP over the 35-file walk:
  {'hits': 269, 'tier1': 122, 'anchor': 11, 'same_dir': 16, 'FAIL': 120}
FAIL coordinate set vs the 122 triage records:
  in FAIL not in triage: []
  in triage not in FAIL: [('changelog/_rules.md', 32, 'vN.md'), ('changelog/_rules.md', 35, 'vN.md')]
```

The triage IS the ladder's FAIL set — 120 over the decided 35-file walk, plus the 2
`changelog/_rules.md` records that came from the superseded 37-file walk. So the 26-entry
`_CHECK_95_ALLOWLIST` is sized to the residue that survives **after** `_CHECK_40_ALLOWLIST` has
already cleared 122 occurrences. A check that omits tier 1 sees a larger population than the one the
allowlist was sized against.

**The measured consequence.** Running the ladder as the superseded plan specifies it —
`_CHECK_95_ALLOWLIST` (26) as the only tier-1 source — over the post-STRIP tree (EP-23):

```
POST-STRIP 26-entry (plan as written): {'hits': 224, 'tier1': 78, 'anchor': 11, 'same_dir': 21, 'FAIL': 114}
  top FAIL basenames: CLAUDE.md 30 | GEMINI.md 29 | AGENTS.md 27 | README.md 24
                      settings.json 1 | QUICKSTART.md 1 | tracker.toml 1 | report.md 1
```

**W3 implemented literally lands `rc=1` with 114 Check-95 failures.** The failure text says "qualify
the path OR add an allowlist entry", so the likeliest coder response is to qualify `CLAUDE.md` across
~110 trinity lines — which is wrong (each of the three has 2–3 candidates; see §6.4) and which would
also consume Check 66's 163-character margin.

**The fix, sized by leave-one-out necessity (EP-23).** `_CHECK_95_ALLOWLIST` grows **26 → 34** with
exactly the 8 basenames whose absence produces a FAIL. Removing any one of the 34 introduces at least
one new FAIL; **zero entries are redundant**, and the per-entry necessity counts sum to 189, which is
exactly the empty-allowlist probe's FAIL count:

```
FAIL with the full 34: 0
REDUNDANT entries (leave-one-out introduces 0 new FAILs): []
sum of per-entry necessity counts: 189   ==   EMPTY-allowlist probe FAIL count: 189
     of which: 75 from the original 26   +   114 from the 8 additions
POST-STRIP 34-entry: {'hits': 224, 'tier1': 197, 'anchor': 8, 'same_dir': 19, 'FAIL': 0}
```

**Correction to the adversarial review's own arithmetic, re-derived.** The review reports the split
as "8 load-bearing, 10 inert" out of `_CHECK_40_ALLOWLIST`'s 18. Measured, the honest split is:

- **8 NECESSARY** — `AGENTS.md` (27), `CLAUDE.md` (30), `GEMINI.md` (29), `README.md` (24),
  `QUICKSTART.md` (1), `report.md` (1), `settings.json` (1), `tracker.toml` (1) = **114**.
- **`LICENSE.md` — NOT necessary, and MUST NOT be added.** It has 3 occurrences in the walk
  (`README.md:311`, `:321` ×2), but `LICENSE.md` has exactly one candidate, at the repo root, and
  the citing file is also at the repo root — so **tier 3 (same-dir) clears all three**. Adding it
  would be an entry with zero necessity, which is what "sized EXACTLY to the measured legitimate
  set" forbids.
- **9 with zero occurrences in the walk** — `BD-NNN.md`, `HELP-FRAGMENT.md`, `LICENSE`, `MEMORY.md`,
  `TD-NNN.md`, `feedback_review_fix_cycle.md`, `id-map.json`, `manifest.txt`, `phase-N.md`.

So the addition is **exactly 8**, not 8-of-a-10-way-split. §6.4 carries the 34 entries.

**This is a settled decision, not a gate. See §9 D-1**, which records the four options with their
measured costs and closes at (b): `_CHECK_95_ALLOWLIST` grows 26 → 34 and Check 95 does NOT consult
`_CHECK_40_ALLOWLIST`. W3 is free to start.

### 2.2 [LOAD-BEARING] There is no CI-workflow edit for the new test

**Design §6.1 row 9:** *"`.github/workflows/validate-pack.yml` — wire the new test so Check 42
passes."*

**Measured (EP-1):** test wiring has been disk-derived since the BD-219 redesign.
`scripts/lib/ci-shard-plan.py:parse_wired_tests()` builds the wired set from three non-recursive
directory listings — `scripts/test*.sh`, `scripts/tests/*.sh`,
`scripts/tests/fixture-dependent/*.sh` — minus `scripts/ci-test-wiring-allowlist.txt`, and its own
docstring says *"the wired set is derived FROM DISK, independent of the workflow yml (which no
longer carries a static matrix)."* The workflow's `plan` job calls `--emit-matrix` at run time.
Check 42 no longer asserts wiring equality; it asserts allowlist validity and partitionability.

**Consequence.** A new `scripts/tests/test-validate-pack-check-95.sh` is wired **by existing**.
**W3 makes NO edit to `.github/workflows/validate-pack.yml`.** A coder who "wires" it by hand would
be inventing a static matrix entry the dynamic model does not have, and `.github/` is a Check-93
leg-2 public surface — an unnecessary edit there is pure downside. The acceptance criterion "a
per-check test file is authored and wired into `.github/workflows/validate-pack.yml` so Check 42
passes" is satisfied by authoring the file at the wired path and verifying `--assert-coverage`.

### 2.3 [LOAD-BEARING] The install-map parser has FIVE unpack sites and a docstring that forbids the change

**Design §6.2 row 2:** widen `_parse_client_installed_files()` to return the DEST column; §6.2 row 8
names `test-validate-pack-check-41.sh` as the only downstream surface.

**Measured (EP-2).** `_parse_client_installed_files()` returns a 5-tuple, unpacked at **five**
sites, all of which break on an arity change:

| # | Site | Consumer |
|---|---|---|
| 1 | `scripts/lib/validate_checks/boundary_refs.py:647` | `_iter_client_installed_files()` |
| 2 | `scripts/lib/validate_checks/boundary_refs.py:2377` | Check 43 |
| 3 | `scripts/lib/validate_checks/boundary_refs.py:3011` | Check 41 |
| 4 | `scripts/lib/validate_checks/boundary_refs.py:4798` | Check 47 (`_SANCTIONED_PACK_SIDE_SHIPPED` set-equality) |
| 5 | `scripts/tests/test-validate-pack-check-41.sh:87` | the wired test |

Sites 1, 2 and 4 use the positional form `entries, _, _, _, _ = _parse_client_installed_files()`,
which raises `ValueError` on a 6-tuple.

And `boundary_refs.py:2949` — the docstring of the sibling `_parse_client_installed_file_stages()`
— reads verbatim: *"Sibling of `_parse_client_installed_files()` (whose 5-tuple arity is UNCHANGED
and whose unpack sites stay intact)."* Widening the tuple makes that sentence false.

**That sibling is also the precedent.** `_parse_client_installed_file_stages()` needed a *different
column* off the same `_CLIENT_INSTALLED_FILES` block and solved it with a self-contained second
parse rather than widening the tuple. Measured cost of that parse: **0.128 ms** median;
`_parse_client_installed_files()` itself is **0.132 ms** (EP-3).

**Resolution — the plan overrides the design's mechanism, not its behaviour.** W2 adds
`_client_install_dest_to_source()` as a **self-contained sibling parser** modelled line-for-line on
`_parse_client_installed_file_stages()`. `_parse_client_installed_files()` keeps its 5-tuple arity,
all five unpack sites stay untouched, the `:2949` docstring stays true, and Checks 41/43/47 need no
re-verification beyond running their tests. Cost: **+0.13 ms** against a 10.0 s hard-FAIL budget
with ~7.5 s of headroom. The design's stated goal ("no second `git ls-files` subprocess", §4.2) is
about the *subprocess*, and this touches no subprocess.

Design §6.2 row 8 (re-verify `test-validate-pack-check-41.sh`) becomes a **run-only** step: no edit.

The independent build performed by the adversarial pass confirms this is executable as specified:
`_client_install_dest_to_source()` modelled on the sibling yields **29** entries, matching the
inventory size Check 41 reports, and I re-derived the same 29 (EP-4).

### 2.4 [LOAD-BEARING] The `lstrip("./")` bug has a third site, and it is not where the design says

**Design §4.5 / the spawn brief:** *"the `lstrip("./")` bug has three sites, one of them the
allowlist loader."*

**Measured (EP-5), `git grep 'lstrip("\./")'` tree-wide — exactly three hits:**
```
project-template/scripts/validate-docs.sh:180        dangling_targets.add(target.lstrip("./"))
project-template/scripts/validate-docs.sh:424            norm = ref.lstrip("./")
scripts/tests/test-validate-docs-template-fullscan.sh:208        norm = target.lstrip("./")
```

So the composition the design gives is wrong in two ways:

1. **The gate has TWO `lstrip` sites, not three.** The design's third item (`:426`, `or base in
   basenames`) is the *fallback removal* — a different defect that travels with them, not a third
   `lstrip`.
2. **The genuine third `lstrip` is in the pack-side test**, at
   `scripts/tests/test-validate-docs-template-fullscan.sh:208`, inside L3's allowlist-liveness leg —
   whose own comment says it parses *"with the gate's exact grammar … (mirror of
   load_allowlist/_commit_record)"*. Fix the gate's two sites and leave the test's, and that
   "mirror" claim becomes false.

**Is the test's site a live bug today?** No. L3 tests `norm in txt` — substring containment against
corpus text — so for `.agents/mcp_config.json` the mangled `agents/mcp_config.json` is still a
substring of the correct citation and the record is not falsely reported dead. It is benign-but-
lying, not broken.

**Resolution.** W4 fixes **all three** sites in one commit: the gate's two (behaviour) and the
test's one (mirror honesty). One line in the test; it keeps the comment true and stops a future
maintainer reading L3 as the authoritative normalization and getting the wrong rule. This is inside
BD-288's client-gate lock-step, not new scope.

**Measured line numbers**, which differ from the design's by one in both directions — key on
content, not the number: allowlist side `:180` (design said `:179`), ref side `:424` (design said
`:425`), fallback `:426` (design correct), `build_index` walk `:282–291` (design correct).

### 2.5 [LOAD-BEARING] Check 66 has 163 characters of headroom on one growing bullet

The design does not mention Check 66 (operating-doc bullet-concision, cap 1300 chars) anywhere.
W3's 21 trinity STRIPs lengthen the bullets that contain them.

**Measured (EP-7)** — every bullet in the pack trinity that grows, with its post-edit length:

| File | Bullet (first line) | now | +grow | after | headroom |
|---|---|---:|---:|---:|---:|
| CLAUDE.md | `- **Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern.**` | 626 | +8 | 634 | 666 |
| CLAUDE.md | `- **What Pack Chat CAN edit directly**` | 674 | +9 | 683 | 617 |
| CLAUDE.md | `- **Pack Chat does MINOR edits only…**` | 2341 | +27 | 2368 | **allowlisted** |
| CLAUDE.md | `- **Dependency-direction governs file location…**` | 1124 | +8 | 1132 | 168 |
| CLAUDE.md | `- **The pack is public-bound…**` | 1017 | +28 | 1045 | 255 |
| AGENTS.md | (same five) | … | … | … | ≥363 except 168 / 255 |
| GEMINI.md | `- **What Pack Chat CAN edit directly**` | 1128 | +9 | 1137 | **163** |
| GEMINI.md | `- **Dependency-direction governs…**` | 1124 | +8 | 1132 | 168 |
| GEMINI.md | `- **The pack is public-bound…**` | 1017 | +28 | 1045 | 255 |

**Verdict: SAFE, with the tightest margin at 163 characters.** The one already-over-cap bullet
(`Pack Chat does MINOR edits only`, 2341 chars) is covered by
`pack-ops/.bullet-concision-allowlist.txt`, and that allowlist keys on a **snippet of the bullet's
FIRST line** (the bolded rule name) — none of the 45 STRIPs touches a first line, so no snippet
match is broken. Check 44's doc ceilings cover only `pack-ops/` durable docs, none of which W3
touches. The adversarial pass reproduced every figure in this table by applying the 21 STRIPs to
scratch copies and re-running `doc_concision._check_66_iter_bullets` — including the row this table
elides (`AGENTS.md` 928 → 937, headroom 363) and `allowlisted=True` on the over-cap bullet
post-edit.

**Resolution.** Check 66 is a named item in W3's verification gate, and W3's coder adds **no prose**
to a trinity bullet beyond the path qualification itself. Do not "improve" a sentence while
qualifying it.

### 2.6 The `validate-pack.py` header carries no check-count prose — and its enumeration stops at 42

BD-288's acceptance criterion says *"the `scripts/validate-pack.py` header check-count prose … [is]
updated in lock-step."* The design (§6.1 row 5) says that surface does not exist and names
`core.py`'s ledger instead.

**Measured (EP-8).** `validate-pack.py`'s module docstring is 283 lines and contains no count
assertion — its only `registry entries` hits are `:693` and `:701`, both about named-lambda
late-binding. It *is* a numbered per-check enumeration, but the enumeration **stops at Check 42**
(then two unnumbered informational entries); Checks 43–94 are absent from it entirely.

**Resolution.** The design is right, with one addition a coder needs: **do not add a Check-95 entry
to that docstring.** Adding one would make 95 the only check between 43 and 95 that appears there.
The real count surfaces are `core.py:210` (`CHECK_REGISTRY_EXPECTED_COUNT`), the `core.py` ledger
comment above it, and `README.md` ×2.

### 2.7 Minor, non-behavioural

- Design §4.4 says `_CHECK_43_PACK_INTERNAL_PREFIXES` is *"consulted in **two** places."* Measured:
  three — `:2311` (the module-level precompiled-pattern dict comprehension), `:2571` (qualified-
  prefix leg), `:2650` (bare-ref class test). The design's conclusion is unaffected — `:2311` feeds
  `:2571` — and its **binding** instruction (use a separate constant; EV-3's 130 new FAILures) is
  correct and is followed verbatim.
- Design §4.2 discusses `_CHECK_64_EXCLUDE_PREFIXES` alongside `_CHECK_68_EXCLUDE_PREFIXES` as
  though adjacent. Measured: it lives in `scripts/lib/validate_checks/examples.py:142`, not
  `boundary_refs.py`. No action — the design's decision was to leave both alone.
- **Correction to the superseded plan.** Its §2.6 named `pack-ops/.docs-gate-allowlist.txt`. **No
  such file exists.** Measured (EP-9): `git ls-files | grep -i docs-gate-allowlist` returns exactly
  one path, `project-template/scripts/.docs-gate-allowlist.txt`, and its dot-prefixed records are at
  `:501` (`.agents/mcp_config.json`) and `:522` (`.pack-migration-backup/…`). The line numbers were
  right; the path was crossed with the pack-side `pack-ops/.dangling-ref-allowlist.txt`. §7.1 and
  §7.5 use the correct path throughout.

### 2.8 Everything else I re-measured, and it held

EV-1's walk-by-subtraction reproduces **exactly**: 37 files under the superseded entry-shaped
prefixes, **35 files / 441,529 bytes** under the decided wholesale prefixes, dropping precisely
`backlog/_rules.md` and `changelog/_rules.md` (EP-10). The 45 STRIPs across 11 files reproduce, and
the STRIP coordinate set is **set-identical** to the FAIL set of the full four-tier ladder run
pre-STRIP (EP-23). All 11 pack STRIP targets and all 4 client STRIP targets exist at HEAD (EP-11).
All 10 client STRIP coordinates verify at their **pack-source** path with the SAME line number
(EP-12). The 13-item Check-68 residue verifies line by line, with the same coordinates (EP-13).
Check 71's 12 mirror files and their byte-identity verify (EP-14). The fixed Check-81 matcher yields
`{'BD-288'}` and leaves the tree GREEN (EP-6). The adversarial pass additionally applied all four
coordinate tables (45 + 21 + 10 + 9 line-targeted edits) with **zero misses**; those tables are
carried forward unchanged and are not re-derived here.

---
## 3. Wave dependency graph — contention analysis

I enumerated each wave's file set, computed the pairwise intersections, and separately checked
whether any wave can make another red.

### 3.1 File contention matrix (measured, EP-15)

| File | W1 | W2 | W3 | W4 |
|---|:--:|:--:|:--:|:--:|
| `scripts/lib/validate_checks/cross_bd.py` | ● | | | |
| `scripts/tests/test-validate-pack-check-81.sh` | ● | | | |
| `scripts/tests/test-validate-pack-check-82.sh` | ● | | | |
| `scripts/lib/validate_checks/boundary_refs.py` | | ● | ● | ● |
| `pack-ops/.dangling-ref-allowlist.txt` | | ● | | |
| `.claude/skills/boundary-investigation/SKILL.md` (+ `.codex/`, `.agents/` mirrors) | | ● | ● | |
| `scripts/tests/test-validate-pack-check-68.sh` | | ● | | |
| `scripts/validate-pack.py` · `core.py` · `README.md` | | | ● | |
| `.claude/skills/{dashboard-render,pack-help,verification-harness}/SKILL.md` (+ 6 mirrors) | | | ● | |
| `CLAUDE.md` · `AGENTS.md` · `GEMINI.md` (pack root) | | | ● | |
| `supporting-docs/{MIGRATION-v10-to-v11,SETUP-EXISTING,SETUP-NEW,SETUP_TEMPLATE}.md` | | | ● | |
| `scripts/tests/test-validate-pack-check-95.sh` (NEW) | | | ● | |
| `scripts/tests/test-validate-pack-check-43.sh` | | | | ● |
| `project-template/scripts/validate-docs.sh` · `.docs-gate-allowlist.txt` | | | | ● |
| `project-template/{.claude,.codex,.agents-plugin/…}/agents/auditor-*` (6) | | | | ● |
| `project-template/skills/boundary-investigation/SKILL.md` | | | | ● |
| `supporting-docs/{INSTALL-PROCEDURES,METHODOLOGY}.md` | | | | ● |
| `scripts/tests/test-validate-docs-template-fullscan.sh` | | | | ● |

**Pairwise intersections.**
- W1 ∩ W2 = W1 ∩ W3 = W1 ∩ W4 = **∅**
- W2 ∩ W3 = `{boundary_refs.py, .claude/skills/boundary-investigation/SKILL.md + its 2 mirrors}`
- W2 ∩ W4 = W3 ∩ W4 = `{boundary_refs.py}`

**The `supporting-docs/` question, settled by measurement (EP-16).** W3 and W4 both touch
`supporting-docs/`, but on **disjoint files split along the client-install boundary**: W4's two
(`INSTALL-PROCEDURES.md`, `METHODOLOGY.md`) are the *only* two `supporting-docs/` members of
`_iter_client_installed_files()`, so they live in Check 43's walk and are subtracted OUT of Check
95's; W3's four are non-installed and live in Check 95's walk. The split is not a coincidence to be
managed — it is the same boundary the two checks are defined by. Nothing rests on it anyway,
because W3 and W4 already serialize on `boundary_refs.py`.

### 3.2 The graph

```
   W1 ─────────────────────────────────────────────►   (own worktree; intersects nothing)

   W2 ──────► W3 ──────► W4
   (boundary_refs.py in all three; W2/W3 additionally share boundary-investigation/SKILL.md ×3)
```

**Critical path: W2 → W3 → W4. W1 runs in parallel from the start. Four commits.**

### 3.3 Semantic ordering — checked, not assumed

No wave makes another red. Three claims, each verified:

1. **W3's 45 qualifications resolve under Check 68 both before and after W2.** All 11 STRIP targets
   exist at HEAD (EP-11), so every qualified form resolves on Check 68's **direct** leg — the leg
   W2 does not touch. And none of the 11 STRIP-source files is client-installed (EP-16), so Checks
   43 and 37 never walk them.
2. **W4's client STRIPs resolve under Check 68 after W2.** `skills/audit-methodology/SKILL.md`,
   `docs/pack/PM-CHAT.md`, `docs/pack/prompts/pm-chat.md`, `docs/pack/OPTIONAL-FEATURES.md` each
   exist under `project-template/` (EP-11) → leg A. Before W2 they resolved on the basename
   fallback. W4 is therefore position-independent; the chain just puts it last.
3. **W4 cannot break Check 95.** Every file W4 touches is either under `project-template/` or
   client-installed, and both are subtracted out of Check 95's walk by construction — verified by
   the walk enumeration (EP-10: the 35-member list contains **no** `pack-ops/` path and **no**
   `project-template/` path, both printed as empty lists).

**Why W2 before W3 rather than the reverse.** They must serialize; the order is a choice. W2 first,
because (a) W2 is the smaller of the two and lands the `boundary-investigation/SKILL.md` mirror
propagation once in a 2-mirror wave before W3 does it again in an 8-mirror wave, and (b) W4 depends
on W2's leg A for the cleanest reading of its own post-fix state. Reversing to W3 → W2 would also be
green; it is not preferred.

**NOI-1 touches no ordering.** It narrows one string inside `_CHECK_68_EXCLUDE_PREFIXES` in W2.

---

## 4. W1 — Check 81, decoupled from its data on BOTH axes

**Parallel with:** W2, W3, W4 (intersects nothing). **Base:** any wave base. **Commit 1 of 4.**
**3 files.**

**W1 fixes two decouplings in the same guard family, one layer apart.** The `active[]` matcher is
blind to member **SHAPE** (it accepts a dict, the surface emits a string). The path-token regex is
blind to path **PREFIX** (it cannot begin a token at `.`, so no dotfile surface is extractable).
Both are the entry's defect class — a registered check that runs, prints OK, and does not reach the
reality it claims to verify — and fixing only the first ships a guard that still cannot see any
`.claude/` / `.codex/` / `.github/` surface. They travel together.

### 4.1 File set and the exact edit at each

| # | File | Edit |
|---|---|---|
| 1 | `scripts/lib/validate_checks/cross_bd.py` | (a) `_check_81_active_bd_ids()` (`:689–711`): add a string leg beside the retained dict leg; (b) `_CHECK_81_PATH_TOKEN_RE` (`:616–620`): admit a leading `.` in the FIRST character class only, and update the grammar comment above it |
| 2 | `scripts/tests/test-validate-pack-check-81.sh` | new Group-1 legs T7–T9 + the shape mutation proof; new dot-leading structured-ness leg T10 + its mutation proof; extend the header Coverage block |
| 3 | `scripts/tests/test-validate-pack-check-82.sh` | new leg T6 — two open BDs sharing a **dot-leading** surface ⇒ a WARN naming it (this file moves from RUN-ONLY to EDIT, see §4.2b) |

**Verify-only, NO EDIT** — record the non-edit and its evidence in the IMPL-REPORT so the reviewer
sees it was deliberate:

| File | What to record |
|---|---|
| `scripts/dashboard-render.py` | `" ".join(session.get("active", []) or [])` — the string-form consumer; the data shape is correct and stays |
| `pack-ops/DASHBOARD-SPEC-PACK.md` | verbatim user-owned spec documenting the string form; never edited |
| `pack-ops/session-state.json` | Pack Chat's snapshot; out of scope |
| `backlog/_rules.md:58` | *"a structured repo-relative path list (≥1 backtick repo-relative path token …)"* — a prose contract the regex currently fails to honour for dot-leading paths. The fix makes the doc TRUE; the doc needs no edit (and is pack-chat-only) |
| `scripts/validate-pack.py:753–754` | names `_CHECK_81_PATH_TOKEN_RE` in a Cluster-G symbol enumeration only — no grammar description, so **no edit** (measured, EP-27) |
| `_DOC_CONSTANT_TWINS` | `_CHECK_81_PATH_TOKEN_RE` is **not** an enrolled Check-80 twin (measured: the 5 enrolled twins are `_PACK_CHAT_ONLY_PERMITTED_PATHS`, `_TRACKER_BACKENDS`, `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`, `CHECK_REGISTRY_EXPECTED_COUNT`) — no twin lock-step |

### 4.2a Edit (a) — the `active[]` shape leg

Replace the loop body at `cross_bd.py:706–710`:

```python
for member in active:
    if isinstance(member, dict):                    # legacy shape, retained
        bd = member.get("bd")
        if isinstance(bd, str) and re.match(r"^BD-\d+$", bd):
            ids.add(bd)
    elif isinstance(member, str):                   # current shape
        m = re.match(r"\s*(BD-\d+)\b", member)      # LEADING anchor only
        if m:
            ids.add(m.group(1))
```

**Two things a coder must not "simplify":**

- **The leading anchor is not stylistic. [BINDING]** `re.match` + `\s*` + `\b` means only a BD-ID
  that OPENS the member is gated. A permissive `re.findall(r"BD-\d+", member)` would also gate the
  second, mid-string ID in a historical member of the form
  `'BD-224 @ design pass … pack-lead (BD-25…'` — an ID that is not an active BD. The adversarial
  pass read every historical revision of `pack-ops/session-state.json` and found **6 distinct**
  string members carrying a second, mid-string BD-ID (127 string members / 60 dict members seen).
  Use `re.match`.
- **The dict leg stays.** The dict shape has a long committed history and the wired test's own
  synthetic fixtures build it (`test-validate-pack-check-81.sh:142`,
  `"active": [{"bd": b, "sub_step": "x"} for b in active_bd_ids]`) — deleting the dict leg would
  make T1–T6 vacuous. This is not a deleted-SSOT mirror (the SSOT is the live
  `session-state.json`, unchanged), so `fail-loud-delete-old-source` does not read on it.

Docstring: state that `active[]` members may be a dict carrying `bd` (legacy) or a string whose
LEADING token is the BD-ID (current), and why the anchor is leading-only. No dated notes, no
"BD-288 did X" — `cross_bd.py` docstrings are reference, but keep it to what the code does.

### 4.2b Edit (b) — the path-token regex's dot-leading blind spot

**The defect, reproduced (EP-25).** `_CHECK_81_PATH_TOKEN_RE` opens
`` r"`([A-Za-z0-9_][A-Za-z0-9_./-]*…" `` — the FIRST character class excludes `.`, and the pattern is
anchored to a literal backtick, so a backtick span that begins with a dot yields **no token at all**:

```
CURRENT regex:
  `.claude/agents/pack-planner.md`        -> []
  `.github/workflows/validate-pack.yml`   -> []
  `.claude/skills/`                       -> []
  `.codex/`                               -> []
  `scripts/validate-pack.py`              -> ['scripts/validate-pack.py']
```

Both consumers are blinded by it: `_check_81_field_is_structured()` (Check 81's structured-ness
test) and Check 82's `surface → [BD-IDs]` map. **The cross-BD collision scan cannot see a single
dotfile surface** — not `.github/workflows/`, not `.claude/agents/`, not `.codex/skills/`. This is
the same class as edit (a) one layer down, and `backlog/_rules.md:58` already promises the behaviour
the regex does not deliver.

**The edit — ONE character. [BINDING: change the FIRST character class only.]**

```python
_CHECK_81_PATH_TOKEN_RE = re.compile(
    r"`([A-Za-z0-9_.][A-Za-z0-9_./-]*"      # <-- leading `.` admitted HERE only
    r"(?:/[A-Za-z0-9_./-]+|\.[A-Za-z0-9_]+|/))"
    r"(?:`|(?<=/)(?=<))"
)
```

Do **not** touch the continuation class, the three-way alternation, or the placeholder-segment
terminator. The alternation is what bounds the false positives (see below), and the terminator
carries the BD-257↔BD-037 placeholder fix.

**Why this is safe — measure-then-bound, five steps, all run (EP-25, EP-26, EP-27).**

1. **MEASURE FIRST.** I ran both regexes over the full backlog corpus and over the exact field set
   Check 81/82 read, and enumerated every span whose token set changes.
2. **SUPERSET PROPERTY — nothing existing is lost or altered.** Corpus-wide over all 288
   `backlog/BD-*.md`: CURRENT 825 distinct tokens / 2829 occurrences; WIDENED 893 / 3046; and
   **zero CURRENT tokens change count** under the widening. The change is purely additive.
3. **ZERO NEW FALSE-POSITIVE CLASSES.** The named risk — a backticked bare extension tokenizing as
   a path — is measured absent, because the grammar still requires a `/` or a `.<ext>` *after* the
   first segment:

   ```
   WIDENED:  `.md` -> []      `.sh` -> []      `.example` -> []      `.gitignore` -> []
   ```

   The two shapes that DO newly tokenize and are not real paths — a prose ellipsis
   (`` `.codex/skills/...` ``) and a slash-joined shorthand (`` `.claude/.codex/.gemini` ``) — are the
   SAME shapes the CURRENT regex already produces for non-dot spans (`` `scripts/skills/...` `` and
   `` `CLAUDE/AGENTS/GEMINI.md` `` both tokenize today, measured). The widening introduces no class
   that does not already exist.
4. **BLAST RADIUS IS ADVISORY-ONLY.** Check 82 never calls `fail()` — its only executable emitters
   are `warn()` and `ok()`, and its docstring states the rule ("ADVISORY backstop … NEVER `fail()`").
   Check 81's FAIL leg fires only for a BD in `active[]` whose field is unstructured, and
   `_check_81_field_is_structured()` tests the TBD markers **before** the token search, so a token
   can never rescue a placeholder field.
5. **VERIFY POST-FIX, and it does not move Check 81 at all.** Measured on the live tree
   (EP-26): **zero** structured-ness flips — all 7 currently-unstructured active BDs stay
   unstructured, and the mechanism is explained: BD-020/187/192 *would* find a token but carry TBD
   markers that dominate; BD-039/202/223/279 find no token or have no field. Check 81's OK line is
   byte-identical before and after. The only behavioural change is Check 82's advisory map.

**What the widening actually buys, on the live tree (EP-26).** In the load-bearing scope — the
`File/Symbol` fields of the 16 active-state open BDs — it recovers **6 distinct tokens / 7
(BD,token) pairs across 4 entries** (BD-109, BD-110, BD-171, BD-288), and **0 dot-leading spans in
that scope remain unextracted**. Check 82's map goes 63 → 69 distinct surfaces and 4 → 5 shared, and
the one new WARN is a real, live collision the guard could not previously see:

```
WARN: shared edit surface `.github/workflows/validate-pack.yml` is claimed by 2 open BDs:
      BD-171, BD-288 — coordinate/sequence these ...
```

That is the guard biting on BD-288's own entry. **Expect that WARN after W1 — it is the acceptance
evidence, not a regression.** Name it in the commit message so a reviewer does not read the +1 WARN
as a defect.

**Population, across three scopes — report the load-bearing one (EP-26).** Different scopes give
very different counts, which is why prior figures disagree:

| Scope | Entries | Tokens the widening newly extracts |
|---|---:|---|
| **S3 — `File/Symbol` fields of ACTIVE-state BDs (what Checks 81/82 read)** | 14 with a field, of 16 active | **6 unique / 7 occ / 4 entries**; 0 dot-leading spans left unextracted |
| S2 — `File/Symbol` fields, ALL BD entries regardless of status | 245 | 43 unique / 80 occ / 40 entries |
| S1 — whole-file text, all `backlog/BD-*.md` | 288 | 68 unique / 217 occ / 70 entries |

Raw counts of "backticked dot-leading spans" are **not** a usable planning figure: in S1 that count
is 218 unique / 427 occurrences, but it is inflated by backtick-pairing artifacts (prose spans that
begin at a sentence-final period). Plan against S3; S1/S2 are context.

**Runtime: free.** Measured, 200 full passes over every active `File/Symbol` field: CURRENT
0.030 ms, WIDENED 0.029 ms — inside noise, against the `RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0`
hard-FAIL budget. A character-class widening is O(field length) with no new backtracking path.

**Comment update, required.** The ~35-line block above the constant describes the grammar ("a
backtick span whose first segment is followed by EITHER …"). Add one clause recording that the first
character class admits a leading `.` so dot-directory surfaces (`.claude/`, `.github/`, `.codex/`)
tokenize, and that the *continuation* grammar is unchanged, which is what keeps a bare extension
(`` `.md` ``) from tokenizing. Keep it terse and forward-facing — no dated note, no "BD-288 did X".

### 4.3 Intra-wave ordering

Free — three files, no ordering constraint between (a) and (b): they touch different symbols in the
same module and neither reads the other. Suggested: (b) regex first (it is one character and its
tests are the more intricate), then (a), then the two test files, so each test is written against
shipped behaviour rather than an imagined one.

### 4.4 Test legs (the anti-vacuity requirement)

**A test asserting only "the fixed matcher returns non-empty" proves nothing** — against the live
snapshot the fixed matcher yields `{'BD-288'}` and BD-288 is structured, so Check 81 PASSES either
way. Required legs, all inside the existing synthetic trees (never mutate the real tree):

**In `scripts/tests/test-validate-pack-check-81.sh`:**

| Leg | Synthetic `active[]` | Backlog fixture | Assert |
|---|---|---|---|
| **T7** | `["BD-901 @ some descriptive text"]` (STRING) | `BD-901.md` open, `File/Symbol: TBD` | **non-zero exit** — the FAIL leg fires against the string form |
| **T8** | `["BD-902 @ design pass … (BD-903 …)"]` (STRING, second ID mid-line) | `BD-902.md` structured; `BD-903.md` open with a bare `File/Symbol` | **exit 0** — only the LEADING ID is gated; BD-903 WARNs, does not FAIL |
| **T9** | `[{"bd": "BD-904", "sub_step": "x"}]` (DICT) | `BD-904.md` open, bare `File/Symbol` | **non-zero exit** — the retained dict leg still bites (regression) |
| **T10** | `["BD-905 @ text"]` (STRING) | `BD-905.md` open, `File/Symbol:` naming **only** a dot-leading path, e.g. `` `.github/workflows/validate-pack.yml` `` — and NO TBD marker | **exit 0** — the field is STRUCTURED. Under the current regex it tokenizes to nothing, so the field reads unstructured and the check FAILs |

**In `scripts/tests/test-validate-pack-check-82.sh` (this file becomes an EDIT):**

| Leg | Synthetic fixture | Assert |
|---|---|---|
| **T6** | two open BDs whose `File/Symbol` fields both name the same **dot-leading** surface (e.g. `` `.claude/agents/pack-planner.md` ``) | exit 0 **and** a WARN line naming that surface and both BD-IDs |

T6 is modelled on the existing T4/T5 (which already prove the bare-directory and
placeholder-segment cases on the same synthetic-tree harness) and needs no new infrastructure. The
five existing legs pass **unchanged** — measured: T1–T5 assert on non-dot synthetic surfaces
(`scripts/shared-thing.py`, `project-template/`, `project-template/skills/`), none of which the
widening touches (the superset property, EP-25).

**Mutation proofs [BINDING], two of them, run not inspected.** `47f8467` established the pattern
("Guard teeth verified by mutation, not inspection"):

| # | Mutation | Must cause |
|---|---|---|
| 1 | revert the matcher body in-process to the **dict-only** form | T7 flips from FAIL-detected to exit 0 |
| 2 | revert the regex's first character class to `[A-Za-z0-9_]` | **T10 flips to a FAIL** (the dot-leading field reads unstructured) **and T6's WARN disappears** (no token ⇒ no map entry ⇒ no shared surface) |

Mutation 2 is the one that proves the regex change BITES. Without it, T10 and T6 could both be
written in a form that passes under either regex.

**Fixture idiom.** Reuse each file's existing synthetic-tree harness and `_patch_root`-style
REPO_ROOT rebinding. Neither check draws a git-tracked candidate set, so their fixtures do **not**
need `git init` (unlike Check 95's — §6.9). No new `mktemp`, so Check 92 is N/A; no hardcoded dev
path, no live `gh`, no `grep -c … || echo 0` — Check 83 clean by construction.

### 4.5 Verification gate

| Item | Expected |
|---|---|
| `python3 scripts/validate-pack.py` | exit 0, `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 …` | exit 0 |
| Check 81 line, before | `every active-design BD (0 in session-state active[]; 0 with a structured File/Symbol)` |
| Check 81 line, after | `every active-design BD (**1** in session-state active[]; **1** with a structured File/Symbol)` **+ the same 7 advisory WARNs** (BD-020/039/187/192/202/223/279) — measured, EP-6. The WARN set does **not** change: the regex widening produces **zero** structured-ness flips (EP-26) |
| Check 82 line, before | `4 shared surface(s) WARNed across 63 distinct surface(s)` — measured, EP-26 |
| Check 82 line, after | `**5** shared surface(s) WARNed across **69** distinct surface(s)` — measured, EP-26 |
| Check 82 new WARN | exactly one, naming `.github/workflows/validate-pack.yml` claimed by BD-171 and BD-288. **This is the acceptance evidence for edit (b), not a regression** |
| Check 82 FAIL count | **0**, before and after — Check 82 has no executable `fail()` call (EP-27) |
| `bash scripts/tests/test-validate-pack-check-81.sh` | all groups pass; T7/T8/T9/T10 present |
| `bash scripts/tests/test-validate-pack-check-82.sh` | all groups pass; T1–T5 **unchanged**, T6 present |
| Mutation probe 1 | dict-only matcher restored ⇒ T7 flips to exit 0 |
| Mutation probe 2 | first char class reverted to `[A-Za-z0-9_]` ⇒ T10 FAILs and T6's WARN disappears |
| Check 83 / 92 | green on both edited wired tests |
| `ci-shard-plan.py --assert-coverage` | green |
| `test-fixtures/build.sh --verify` | green |

**What proves the guard BITES rather than merely passing.** For edit (a): the
`0 in session-state active[]` → `1 in session-state active[]` transition in Check 81's own OK line,
plus T7's non-zero exit, plus mutation 1 — the first two alone could both be true of an
over-permissive matcher, and T8 bounds it. For edit (b): the `63 → 69` / `4 → 5` transition in Check
82's own OK line, the named new WARN, plus T10 + T6 + mutation 2.

### 4.6 What W1 explicitly does NOT do

- It does **not** widen the token grammar beyond the first character class. `` `.gitignore` `` still
  yields no token — an extension-less dot file is the same case as extension-less `` `LICENSE` ``
  today, which also yields nothing. That is a pre-existing grammar boundary, unchanged here, and
  changing it would require a real grammar redesign with its own census.
- It does **not** attempt to suppress the two prose shapes that newly tokenize (the ellipsis and the
  slash-joined shorthand). Both already occur for non-dot spans today, both cost at most one
  spurious advisory WARN, and bounding them would mean editing a grammar three legs depend on.
- It does **not** touch `backlog/_rules.md`, `scripts/validate-pack.py`, or the Check-80 twin
  registry — measured, none is an encoding surface for this constant (§4.1).

### 4.7 Bounded-cycle fit — **W1 still FITS one cycle, with the regex fix added**

The bounded cycle is 2 review/fix pairs + 1 final reviewer pass. W1 fits, and the argument is about
**remaining discovery**, not file count:

- **Edit (a): zero discovery.** The matcher shape is given verbatim, the anchor rule is derived from
  a named historical member class verified against the file's full history, the retained dict leg is
  justified by measured history plus the test's own fixtures, and the post-fix Check-81 output is
  measured in advance (EP-6).
- **Edit (b): zero discovery, and this is where the addition could have cost a cycle.** The
  measurement the coder correctly declined to make is done here: the change is **one character**,
  named exactly; the superset property is proved corpus-wide (0 current tokens change); the
  false-positive class the coder flagged is measured **absent** (`` `.md` ``/`` `.sh` ``/`` `.example` ``
  all yield nothing); the two questionable shapes are shown to be pre-existing rather than new; the
  blast radius is bounded to advisory WARNs by reading both consumers; the structured-ness impact is
  measured at **zero flips**; and the exact before/after OK lines for both checks are recorded. A
  coder pastes a character and writes two legs.
- **Sizing.** ~10 changed lines in one function, 1 character in one constant, ~6 lines of comment,
  and 5 test legs (4 in the check-81 file, 1 in the check-82 file) — all against harnesses that
  already exist, including T4/T5 as direct models for T6.
- **Still zero shared files with any other wave**, so W1's cycle cannot collide with the W2→W3→W4
  chain and a W1 failure blocks nothing (§8).
- **The two edits are separable if the cycle strains.** They touch different symbols in one module
  and neither reads the other; either lands green alone (edit (b) alone changes only Check 82's
  advisory map; edit (a) alone is the FINAL plan's W1). That fallback exists but should **not** be
  taken pre-emptively — splitting would ship a guard that reaches its data on one axis and not the
  other, which is the outcome folding (b) into W1 exists to prevent.

### 4.8 Commit shape

**Subject:** `fix: v11 — BD-288 Check 81 reaches its data on both axes: active[] string form + dot-leading path tokens (pack-only)`

**Scope keyword: `pack-only` is CLAIMABLE.** Check 36 denies `project-template/` and
`supporting-docs/` for a `pack-only` claim (`_PROJECT_SIDE_PATH_PREFIXES`, `boundary_refs.py:224`);
W1 touches neither — all three files are `scripts/`. Verify with `git diff --name-only` before
claiming.

**The message must record:**
- **Both decouplings, named as one defect class:** the `active[]` matcher blind to member SHAPE, the
  path-token regex blind to path PREFIX. Fixing only the first ships a guard that still cannot see
  any dotfile surface.
- the shape defect as **data-drift decoupling**, not "a matcher that never worked" — the dict form
  was correct when authored, the data drifted to strings, the matcher went inert.
  `backlog/BD-288.md` carries the correction of record for the opposite claim in `cfd5b02`.
- why the leading anchor is leading-only, with the historical member class that forces it.
- why the dict leg is retained (committed history + the test's own fixtures).
- **the regex change as ONE character in the FIRST character class**, with the four measurements
  that bound it: superset property (825→893 distinct, 2829→3046 occurrences, **0 current tokens
  changed**); bare extensions still yield nothing; the two questionable shapes are pre-existing for
  non-dot spans; runtime 0.030 → 0.029 ms.
- **the live effect, by number:** Check 82 goes `4 shared / 63 distinct` → `5 shared / 69 distinct`,
  with the one new WARN naming `.github/workflows/validate-pack.yml` claimed by BD-171 and BD-288 —
  stated as the acceptance evidence so the +1 WARN is not read as a regression.
- **that Check 81's FAIL/WARN legs are unmoved by the regex change** — 0 structured-ness flips,
  because `_check_81_field_is_structured()` tests the TBD markers before the token search.
- Check 82 verified to have **no executable `fail()`**, so the blast radius is advisory-only.
- `dashboard-render.py` / `DASHBOARD-SPEC-PACK.md` / `session-state.json` / `backlog/_rules.md` /
  `validate-pack.py` / the Check-80 twin registry explicitly NOT edited, and why each is not an
  encoding surface.
- both mutation proofs, stated as run: dict-only matcher ⇒ T7 fires; reverted char class ⇒ T10 FAILs
  and T6's WARN disappears.
- the before/after Check-81 and Check-82 numbers, and the unchanged 7 advisory WARNs.

---

## 5. W2 — Check 68 install-path-aware resolution + NOI-1

**Depends on:** nothing. **Blocks:** W3, W4 (`boundary_refs.py`). **Parallel with:** W1.
**Commit 2 of 4.** **8 files.**

### 5.1 File set and the exact edit at each

| # | File | Edit |
|---|---|---|
| 1 | `scripts/lib/validate_checks/boundary_refs.py` | (a) replace Check 68's qualified-path ladder; (b) add `_client_install_dest_to_source()`; (c) convert Check 68's include-tree scope to git-tracked; (d) **NOI-1**: `_CHECK_68_EXCLUDE_PREFIXES` `'changelog/'` → `'changelog/v'`; (e) `__all__` export |
| 2 | `pack-ops/.dangling-ref-allowlist.txt` | +6 `token:`/`reason:` records (51 → 57) |
| 3 | `.claude/skills/boundary-investigation/SKILL.md` | 2 STRIPs at `:73`, `:74` |
| 4 | `.codex/skills/boundary-investigation/SKILL.md` | **byte-identical re-propagation** |
| 5 | `.agents/skills/boundary-investigation/SKILL.md` | **byte-identical re-propagation** |
| 6 | `scripts/tests/test-validate-pack-check-68.sh` | new legs + 3 mutation proofs |
| 7 | `scripts/tests/test-validate-pack-check-41.sh` | **RUN ONLY, no edit** (see §2.3) |
| 8 | `scripts/tests/test-validate-pack-check-43.sh` | **RUN ONLY, no edit** — second consumer of `_iter_client_installed_files()`; confirm unaffected |

### 5.2 Edit (a) — the resolution ladder

Current, at `boundary_refs.py:4231–4237`:
```python
if is_qualified:
    if (REPO_ROOT / token).exists():
        resolved += 1
        continue
    if Path(token).name in index:      # <-- DELETE: blind to moved files
        resolved += 1
        continue
```
Replace with:
```python
if is_qualified:
    if (REPO_ROOT / token).exists():                       # direct
        resolved += 1
        continue
    if (REPO_ROOT / "project-template" / token).exists():   # leg A: client-install prefix
        resolved += 1
        continue
    src = dest_to_source.get(token)                         # leg B: install-map reverse
    if src and (REPO_ROOT / src).exists():
        resolved += 1
        continue
```
then fall through unchanged to the existing anchor-window escape, the allowlist escape, and the
FAIL. **The leg order is direct → legA → legB → anchor → allowlist → FAIL, and it is load-bearing
for the gate numbers in §5.9. [BINDING]** Do not reorder; in particular do not hoist the allowlist
escape above the resolution legs.

**The bare-ref leg (`token in index`, the `else:` branch) is UNCHANGED. [BINDING]**
Resolving a *bare* reference through the basename index is correct for a bare reference; bareness is
Check 95's axis, not Check 68's. Deleting it here would collide with W3.

**Leg A is an unconditional union — no citer scoping.** 105 of its 247 resolutions come from
non-`project-template/` citers, all legitimate. The mechanism is install-path-aware, not
audience-aware; do not add a `rel.startswith("project-template/")` guard.

`dest_to_source` is built ONCE before the file loop (never per line, per
`ci-check-runtime-compounding`).

**Leg A and leg B are not decorative — measured (EP-17):** on the current scope the hardened ladder
resolves `legA = 247`, `legB = 39`, leaving a 13-item residue. **Leg B alone carries 39 references**,
which is why the ladder cannot ship without the sibling parser (§8's decomposition guidance).

### 5.3 Edit (b) — `_client_install_dest_to_source()`, as a sibling parser

**Per §2.3, do NOT widen `_parse_client_installed_files()`'s 5-tuple.** Model the new helper on
`_parse_client_installed_file_stages()` (`boundary_refs.py:2946`), which already solves exactly this
problem for a different column:

```python
def _client_install_dest_to_source() -> dict[str, str]:
    """Reverse the `_CLIENT_INSTALLED_FILES` inventory: project_relpath -> pack_relpath.

    Sibling of `_parse_client_installed_files()` (whose 5-tuple arity is UNCHANGED and
    whose unpack sites stay intact) and of `_parse_client_installed_file_stages()`.
    Check 68's leg B consumes this to resolve a reference written in the CLIENT's
    install-path form against the pack-storage path it is copied from. Returns {} if
    init-project.sh is absent or the markers are not exactly-once (lenient).
    """
```
Body: same marker guard, same `re.search(rf"{START}\s*\n(.+?)\n[^\n]*{END}", text, re.DOTALL)`
extraction, same `#   <pack>  ->  <proj>` line shape; map `proj -> pack` (strip any trailing
`[stage:…]`). **Measured: the reverse map yields exactly 29 entries** (EP-4), matching the inventory
size Check 41 reports. Measured cost of that parse: **0.13 ms** (EP-3).

Export `_client_install_dest_to_source` in `__all__` next to `_parse_client_installed_files`.

### 5.4 Edit (c) — git-tracked scope, reusing one `git ls-files`

Current `boundary_refs.py:4190–4200` enumerates via `root.rglob("*")` over
`_CHECK_68_INCLUDE_TREES = ("project-template", "supporting-docs")`.

**The constraint the design gives is a runtime one: do not issue a second `git ls-files`.** Check 68
already calls `_build_basename_index()` (`:4164`), which internally calls `_git_tracked_relpaths()`
(**10.8 ms**, not memoized — EP-3). Naïvely calling `_git_tracked_relpaths()` again in Check 68
costs +10.8 ms and buys nothing.

**Do this** — an optional parameter, backward-compatible for Check 40 and Check 43, the other two
callers of `_build_basename_index()` (measured: exactly three callers, EP-18):
```python
def _build_basename_index(rels: list[str] | None = None) -> dict[str, list[Path]] | None:
    if rels is None:
        rels = _git_tracked_relpaths()
    if rels is None:
        return None
    ...unchanged...
```
Check 68 then:
```python
rels = _git_tracked_relpaths()
if rels is None:
    ok("git unavailable (not a git work tree) — skipping (lenient)")
    return
index = _build_basename_index(rels)
...
for tree in _CHECK_68_INCLUDE_TREES:
    prefix = tree + "/"
    for rel_posix in rels:
        if rel_posix.startswith(prefix) and not _excluded(rel_posix):
            scope.add(rel_posix)
```
Net runtime: **−2.1 ms** (the rglob it replaces) and zero new subprocess.

**Acceptable fallback if the optional parameter is judged too invasive:** call
`_git_tracked_relpaths()` a second time in Check 68 (+10.8 ms, still ~0.14 % of the 10.0 s
hard-FAIL budget). Do NOT keep the rglob.

**Lenient SKIP is mandatory** — `rels is None` ⇒ `ok(...)` + `return`, the Check 53 / 63 / 69 idiom.
Selection is identical on a clean tree (`project-template` 181 rglob / 181 tracked,
`supporting-docs` 10 / 10, symmetric difference empty — measured independently by the adversarial
pass), so this is behaviour-preserving and removes only environment-artifact exposure.

### 5.5 Edit (d) — NOI-1, decided (b)

In `_CHECK_68_EXCLUDE_PREFIXES` (`boundary_refs.py:4107–4113`), change the first member. Measured
current value: `('changelog/', 'backlog/BD-', 'maintenance-docs/', 'test-fixtures/',
'scripts/tests/fixtures/', '.git/')`.
```python
_CHECK_68_EXCLUDE_PREFIXES = (
    "changelog/v",           # was "changelog/" — NOI-1(b): restores changelog/_rules.md
    "backlog/BD-",           #   to the existence axis, symmetric with this sibling
    "maintenance-docs/",
    "test-fixtures/",
    "scripts/tests/fixtures/",
    ".git/",
)
```
**Measured cost: 0 FAILs** (EP-17) — `changelog/_rules.md` produces no would-FAIL qualified refs
under the hardened ladder. It adds **+1 file and +6 references** to the scope (228 → 229,
1830 → 1836), of which +2 land on the allowlist and +4 resolve. The change is free today and bites
only on a future bad reference.

**Do not touch `backlog/BD-`.** Option (c) — making both bare — is the only option that *reduces*
coverage and was not chosen.

**Note the interaction with W3, and do not "harmonize" them. [BINDING]** After this edit,
`_CHECK_68_EXCLUDE_PREFIXES` is entry-shaped for the two history trees while W3's
`_CHECK_95_EXCLUDE_PREFIXES` is wholesale (`backlog/`, `changelog/`). That asymmetry is deliberate:
the user's standing constraint is about a **bareness** gate (Check 95), and Check 68 is the
**existence** axis, which already covers `backlog/_rules.md` today. A coder who makes the two
constants match "for consistency" reverses a user decision in one direction or the other. State the
asymmetry and its reason in a short comment at each constant.

### 5.6 Edit (e) — the 6 allowlist records

Append to `pack-ops/.dangling-ref-allowlist.txt` (measured today: **51** `token:` records → 57). All
11 backing occurrences are enumerated in EP-13; every record below has ≥1 measured citer, so none is
unbacked. Place each in the group its `reason:` names — the file is grouped `G1`…`G7` with header
comments at `:34, :80, :132, :154, :170, :183, :199`.

| Group | `token:` | `reason:` | Backed by (measured) |
|---|---|---|---|
| G1 | `CLAUDE/AGENTS/GEMINI.md` | `G1 — trinity prose shorthand naming the three CLI files as a set; not a path (no file of this name exists by design).` | `AGENTS.md:491`, `CLAUDE.md:610`, `GEMINI.md:463`, `pack-ops/MERGE-STRATEGY.md:57` |
| G7 | `docs/project/ARCHITECTURE.md` | `G7 — a CLIENT-side project path named from a client-audience doc; no pack-repo file is the referent.` | `project-template/docs/pack/PM-CHAT.md:155` |
| G2 | `docs/project/backlog/_toc.md` | `G2 — runtime-GENERATED per-entry index (regenerated after every entry edit per this stream's _rules.md); absent from the shipped template by design.` | `project-template/docs/project/backlog/_rules.md:22` |
| G2 | `docs/project/changelog/_toc.md` | `G2 — runtime-GENERATED per-entry index (regenerated after every entry edit per this stream's _rules.md); absent from the shipped template by design.` | `project-template/docs/project/changelog/_rules.md:22` |
| G2 | `docs/project/groupings/_toc.md` | `G2 — runtime-GENERATED per-entry index (regenerated after every entry edit per this stream's _rules.md); absent from the shipped template by design.` | `project-template/docs/project/groupings/_rules.md:23` |
| G7 | `docs/ARCHITECTURE.md` | `G7 — a CLIENT-side project path in setup prose that explicitly guards on its presence ("if present" / "already present at"); no pack-repo file is the referent.` | `supporting-docs/SETUP-EXISTING.md:277`, `:292`, `:306` |

**Sizing check, measured (EP-19).** None of the 6 tokens is already on the allowlist (intersection
empty), and each token's total occurrence count across Check 68's whole post-NOI-1 scope is exactly
its backing count — 4 + 1 + 1 + 1 + 1 + 3 = **11**, with no occurrence anywhere else in scope. The
six records are therefore sized exactly to the residue; none over-reaches.

**OI-8 = (a) is settled:** the `CLAUDE/AGENTS/GEMINI.md` record is the resolution. Do **not** narrow
the shared qualified-path regex for one cosmetic case, and do **not** reword the trinity or the
`pack-ops/MERGE-STRATEGY.md` table cell.

### 5.7 Edit (f) — the 2 OI-3 STRIPs, then the mirrors

`.claude/skills/boundary-investigation/SKILL.md`, two table rows, measured verbatim at HEAD:
```
:73  | Install + setup procedures | `project-template/docs/pack/INSTALL-PROCEDURES.md` |
:74  | Methodology + procedures   | `project-template/supporting-docs/METHODOLOGY.md` (when applicable) |
```
Neither path exists; `project-template/supporting-docs/` is not even a directory (EP-11). Rewrite to
the **pack-storage form**:
```
:73  | Install + setup procedures | `supporting-docs/INSTALL-PROCEDURES.md` |
:74  | Methodology + procedures   | `supporting-docs/METHODOLOGY.md` (when applicable) |
```
The reader is a pack agent in the pack repo; under the new ladder the pack-storage form resolves on
the **direct** leg while the client form would resolve only on leg B. The project-side twin
(`project-template/skills/boundary-investigation/SKILL.md`) already carries the client form —
mirror-but-customize working as intended, and it is W4's file, not W2's.

### 5.8 Intra-wave ordering — [BINDING]

```
  1. (a) ladder  +  (b) helper  +  (c) scope  +  (d) NOI-1  +  (e) __all__      — boundary_refs.py
  2. the 6 allowlist records                                                     — .dangling-ref-allowlist.txt
  3. (f) the 2 STRIPs in .claude/skills/boundary-investigation/SKILL.md
  4. propagate byte-identically to .codex/ and .agents/                          ← MUST follow 3
  5. test legs
```

**Two orderings are load-bearing:**

- **Step 1 before step 2, or the tree is red between them.** Deleting the basename fallback makes
  the 13-item residue FAIL until the 6 records + the 2 STRIPs land. Guard and fix-set are ONE
  commit; within the commit, land the constant before you run anything.
- **Step 4 immediately after step 3. [BINDING]** Check 71
  (`check_pack_skill_mirror_identity`, `boundary_refs.py:4488`) asserts byte-identity across
  `.claude/skills`, `.codex/skills`, `.agents/skills` and its docstring says *"no allowlist
  (byte-identity is absolute)"*. There is **no propagation automation** — the copies are
  hand-maintained. All four skills are byte-identical today (md5 triples, EP-14). Editing the
  canonical copy without the two mirrors is an immediate red gate. Propagate by copying the whole
  file, not by re-applying the edit by hand: `md5 -q` the three afterwards and confirm they match.

### 5.9 Verification gate

**Live baseline, for comparison** (`python3 scripts/validate-pack.py` at `47f8467`, EP-17):
```
OK: Check 68 — 228 file(s) scanned; 1830 file/path reference(s) checked; 1597 resolved,
    28 self-flagged-non-existent (anchor-cleared), 205 allowlisted (non-existent by design);
    0 dangling outside the allowlist (complete).
```

**Post-W2 expectation. [BINDING on the four structural terms; the resolved/allowlisted split is a
projection — read the note below before treating a mismatch as a defect.]**

| Term in Check 68's OK line | Before | After W2 | Status |
|---|---:|---:|---|
| files scanned | 228 | **229** | **BINDING** (+1 = `changelog/_rules.md`, NOI-1) |
| file/path references checked | 1830 | **1836** | **BINDING** (+6 from the same file) |
| resolved | 1597 | **1590** | projection |
| self-flagged-non-existent (anchor-cleared) | 28 | **28** | **BINDING** (unchanged) |
| allowlisted | 205 | **218** | projection |
| dangling outside the allowlist | 0 | **0** | **BINDING** |
| — | | `resolved + anchor + allowlisted + dangling == refs` | **BINDING** (1590 + 28 + 218 + 0 = 1836) |

**Three things about this line the superseded plan got wrong, and one thing I could not reproduce.
[BINDING]**

1. **`764` is NOT the number the check prints.** `refs_checked` increments for **every** token,
   qualified and bare (`boundary_refs.py`, the `for token, is_qualified in tokens:` loop). Measured
   split at `47f8467`: qualified 764, bare 1066, total 1830. `764` is the qualified-only
   sub-population.
2. **The six-term ledger `389 direct + 247 legA + 39 legB + 75 allowlist + 1 anchor` is NOT
   printed.** The OK line emits a single `resolved` term with no leg split, and this plan does
   **not** schedule a message-format change. Treat that ledger as an **analytic decomposition the
   coder computes** to satisfy itself the legs work — not as a line to grep for. Its post-fix form,
   measured (EP-17): `391 direct + 247 legA + 39 legB + 86 allowlist + 1 anchor = 764` on the
   qualified sub-population.
3. **The superseded ledger did not sum.** `389 + 247 + 39 + 75 + 1 = 751`, not 764; the missing 13
   was the residue term it dropped.
4. **Honest note on the split.** My `resolved`/`allowlisted` projection (1590 / 218) is derived by
   replicating the ladder in the leg order §5.2 specifies, against a replication that reproduces the
   live OK line **term for term** (228 / 1830 / 1597 / 28 / 205 / 0 — EP-17). The adversarial pass,
   which built W2 in a scratch tree, reported the same four BINDING terms (229 / 1836 / 28 / 0) but
   a different split, `1576 resolved / 232 allowlisted` — 14 references on the other side. I could
   not reproduce that split from the mechanism this plan specifies, and I tested and ruled out the
   most likely cause (an allowlist escape hoisted above legs A/B: measured, **zero** legA/legB-
   resolvable tokens are also on the allowlist, EP-19). **If your run shows the split at 1576/232,
   do not "fix" it and do not report a defect — re-read your leg ORDER against §5.2 and record which
   you shipped in the IMPL-REPORT.** The four BINDING terms and the sum invariant are what prove the
   wave; the split is diagnostic.

| Other gate items | Expected |
|---|---|
| `python3 scripts/validate-pack.py` | exit 0, `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 …` | exit 0 |
| Check 68 allowlist size | **57** `token:` records (was 51); every new record backed by ≥1 measured citer (EP-13, EP-19) |
| **Check 71** | green — the 3 `boundary-investigation/SKILL.md` copies byte-identical (`md5 -q` ×3 equal) |
| Check 40 / 43 | green and **unchanged** — they call `_build_basename_index()` with no argument |
| Check 41 / 47 | green — run `scripts/tests/test-validate-pack-check-41.sh` unmodified; the 5-tuple arity is intact |
| `scripts/tests/test-validate-pack-check-68.sh` | all groups pass |
| `scripts/tests/test-validate-pack-check-43.sh` | passes unmodified |
| Check 83 / 92 | green on the edited wired test |
| `--assert-coverage`, `build.sh --verify` | green |

**What proves the guard BITES — three mutation probes, run, not inspected [BINDING]:**

| # | Mutation | Must cause |
|---|---|---|
| 1 | restore `if Path(token).name in index: resolve` on the qualified branch | the **moved-file** leg fires: a fixture citing `docs/WRONGDIR/PM-CHAT.md` (basename exists elsewhere) must FAIL under the hardened ladder and PASS under the restored one |
| 2 | restore `root.rglob("*")` scope | the **tracked-set** assertion fires: an untracked file dropped into the fixture's `project-template/` must be absent from the scanned set |
| 3 | revert `'changelog/v'` → `'changelog/'` | the **NOI-1** leg fires: `changelog/_rules.md` must be IN the scope set under `changelog/v` and OUT under `changelog/`, and the scanned-file count must move by exactly 1 |

**Fixture requirement [BINDING]:** the tracked-scope legs must run in a **throwaway `git init`
repo**. Without `git init`, `_git_tracked_relpaths()` returns `None`, the lenient SKIP swallows the
assertion, and the leg passes vacuously. This is the detail `47f8467` recorded for Check 53's
fixtures. Use `tempfile.mkdtemp(prefix="vp-check68-")` in Python (the idiom
`test-validate-pack-check-53.sh:120,131–134` uses) — **not** shell `mktemp -t`, which Check 92 FAILs.
Rebind `REPO_ROOT` on the facade **and every loaded `validate_checks.*` submodule** (the BD-256 W3
wave-invariant, `test-validate-pack-check-53.sh:98–112`); a facade-only patch does not bite.

### 5.10 Bounded-cycle fit

**FITS.** Not because it is 8 files — because **no discovery remains**. The 13-item residue is fully
enumerated with per-token verdicts and verified coordinates (EP-13); the 6 `reason:` strings are
written out in §5.6 and their sizing is measured (EP-19); the two STRIP targets are verified to
exist and their replacements are given verbatim; the ladder is given as code with its leg order
marked binding; the `dest_to_source` helper has a working sibling to copy and its output size (29)
is measured. The wave was independently **implemented end-to-end** by the adversarial pass from the
same specification and landed green on the first run, with Checks 40/41/43/68/71/80/83/92,
`checks-58-59-60` and `--assert-coverage` all `rc=0` — the strongest available evidence that no
discovery remains. The one place a reviewer must read code rather than an exit code is the
sibling-parser marker guard (§5.3) — bounded, one function.

### 5.11 Commit shape

**Subject:** `fix: v11 — BD-288 Check 68 install-path-aware resolution + git-tracked scope (pack-only)`

**Scope keyword: `pack-only` is CLAIMABLE.** No `project-template/` path and no `supporting-docs/`
path is touched — the two STRIPs are in `.claude/`/`.codex/`/`.agents/` skills, and the allowlist is
`pack-ops/`. Verify with `git diff --name-only` before claiming.

**The message must record:**
- the ladder before/after, its leg ORDER, and the qualified-only resolution decomposition with its
  six terms — labelled explicitly as an analytic decomposition, not a printed line.
- that the **bare-ref leg is unchanged** and why (bareness is Check 95's axis).
- leg A is an **unconditional union**, not citer-scoped, with the 105-of-247 non-`project-template/`
  citer figure; and leg B carries 39 references, so the ladder and the parser are one change.
- that `_parse_client_installed_files()`'s 5-tuple arity is deliberately **unchanged**, naming the
  five unpack sites and the `:2949` sibling docstring that asserts it — and that
  `_client_install_dest_to_source()` follows `_parse_client_installed_file_stages()`'s precedent at
  a measured 0.13 ms and yields 29 entries.
- the git-tracked conversion, with the selection-identity evidence (`project-template` 181/181,
  `supporting-docs` 10/10, symmetric difference empty) and the lenient SKIP.
- the 2 genuine dead pointers the fallback had been hiding, by path.
- **NOI-1 = (b)**, as a user decision, with the measured cost (0 FAILs; +1 file, +6 references) and
  the explicit note that Check 68's constant is now entry-shaped while Check 95's is wholesale —
  deliberately, because the user's constraint is about the bareness axis.
- the three mutation probes, stated as run.
- the four BINDING OK-line terms as observed, and — if the split differs from 1590/218 — which leg
  order shipped.

---
## 6. W3 — Check 95 + the 45 bareness STRIPs (the largest wave)

**Depends on:** W2 (`boundary_refs.py`, `boundary-investigation/SKILL.md` ×3). **Blocks:** W4.
**Commit 3 of 4.** **24 files.**

**This wave is not gated.** The shape of Check 95's tier-1 exemption is decided at §9 D-1 = (b):
`_CHECK_95_ALLOWLIST` carries 34 entries and Check 95 does NOT consult `_CHECK_40_ALLOWLIST`. Every
number in §6.4 and §6.9 is the (b) number.

**Governing principle, three times over in this BD: a guard and the fix-set that makes it green are
ONE commit. [BINDING]** Check 95's allowlist is sized to the KEEP set and the 45 STRIPs are its
complement — measured, the intersection is empty and the STRIP set is *exactly* the ladder's
pre-STRIP FAIL set (EP-23), so a check-without-fixes commit FAILs 45 times by construction, and a
fixes-without-check commit lands 45 edits with nothing asserting completeness. `47f8467` established
the shape for Check 53: guard, candidate-set fix, test, and mutation proof in one commit.

### 6.1 File set

| # | File | Edit |
|---|---|---|
| 1 | `scripts/lib/validate_checks/boundary_refs.py` | `check_live_pack_doc_bare_refs` + `_CHECK_95_ALLOWLIST` (34) + `_CHECK_95_EXCLUDE_PREFIXES` (5) + `__all__` ×3 |
| 2 | `scripts/validate-pack.py` | one `CHECK_REGISTRY` tuple `(95, label, fn, budget_s)` |
| 3 | `scripts/lib/validate_checks/core.py` | `CHECK_REGISTRY_EXPECTED_COUNT` `91` → `92` (`:210`) **and** the ledger comment above it |
| 4 | `README.md` | 2 sites (L83 version table, L204 layout), **4 number tokens each** |
| 5 | `scripts/tests/test-validate-pack-check-95.sh` | NEW |
| 6–8 | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | 7 STRIPs each |
| 9–12 | `.claude/skills/{boundary-investigation,dashboard-render,pack-help,verification-harness}/SKILL.md` | 5 / 1 / 1 / 1 STRIPs |
| 13–20 | the same four skills under `.codex/skills/` and `.agents/skills/` | **byte-identical re-propagation ×8 (Check 71)** |
| 21–24 | `supporting-docs/{MIGRATION-v10-to-v11,SETUP-EXISTING,SETUP-NEW,SETUP_TEMPLATE}.md` | 5 / 5 / 4 / 2 STRIPs |

**NOT edited (per §2.2 and §2.6):** `.github/workflows/validate-pack.yml` — wiring is disk-derived;
`scripts/validate-pack.py`'s module docstring — its per-check enumeration stops at Check 42.

**Pack-chat-only note.** The pack-root trinity is a pack-chat-only surface. Pack Chat SCOPES it into
this coder prompt; that is the supported path per `pack-chat-minor-edits-only`, not a boundary
violation.

### 6.2 The new check — specification

- **Number 95** — verified free: `core.py`'s ledger ends `(Next free numeric ID = 95.)` and
  `CHECK_REGISTRY_EXPECTED_COUNT = 91` at `core.py:210` (measured).
- **Name** `check_live_pack_doc_bare_refs`, in `boundary_refs.py` beside its siblings.
- **Candidate set:** git-TRACKED only, via `_git_tracked_relpaths()`; `ok(...)` + `return` when it
  returns `None` (lenient SKIP). After W2 the whole-repo `rels` list is available — reuse it, do not
  add a subprocess.
- **Walk, derived by SUBTRACTION, never a frozen list:**
  `_iter_operating_docs() ∪ supporting-docs/*.md ∪ README.md`, MINUS Check 40's walk
  (`pack-ops/*.md` minus `{BACKLOG.md, CHANGELOG.md, DASHBOARD-SPEC-PACK.md}`), MINUS
  `_iter_client_installed_files()`, MINUS `_CHECK_95_EXCLUDE_PREFIXES`, **then intersected with the
  tracked set: `walk &= set(rels)`. [BINDING — see the next bullet.]** Subtraction means a doc that
  later becomes client-installed migrates from Check 95 to Check 43 with no edit, and no file can
  fall between them. **Measured: 35 files / 441,529 bytes (EP-10), reproduced independently, with
  zero `pack-ops/` and zero `project-template/` members.**
- **The tracked intersection is not decoration — it is the difference between the claim and the
  mechanism. [BINDING]** All four terms of the walk expression are FILESYSTEM-derived, not
  git-derived: `_iter_operating_docs()` expands `_CHECK_OPERATING_DOC_FAMILIES` with
  `REPO_ROOT.glob(entry)` (measured — its own docstring says "auto-discovered by family glob");
  `supporting-docs/*.md` is a `glob`; `_iter_client_installed_files()` is an `rglob` walk plus a
  parsed inventory. Without the intersection, an untracked `.md` dropped into `supporting-docs/` is
  scanned — the exact failure mode `ci-guard-measure-then-bound` names, and a check that claims a
  git-tracked candidate set while walking the filesystem is the same declare-without-backing defect
  BD-288 exists to fix. Measured (EP-24): all 35 current walk members are git-tracked, symmetric
  difference empty, so the intersection is behaviour-preserving today and costs nothing at run time
  (`rels` is already in hand for the lenient-SKIP guard and `_build_basename_index`).
- **Matching — the exemption ladder is FOUR tiers and tier 1 must be named explicitly. [BINDING]**
  Reuse `_strip_code_blocks`, `_CHECK_40_BARE_REF_PATTERN`, `_CHECK_40_HYPERLINK_PATTERN`,
  `_check_40_context_has_anchor`, and the same-dir-legitimate rule **verbatim — no new regex** —
  AND replicate Check 40's tier structure in order:

  | Tier | Test | Counter |
  |---|---|---|
  | 1 | `if basename in _CHECK_95_ALLOWLIST` | `hits_allowlist` |
  | 2 | `if _check_40_context_has_anchor(stripped_lines, lineno)` | `hits_anchor` |
  | 3 | single candidate in `index` whose parent dir == the citing file's dir | `hits_same_dir` |
  | — | else | `fail(...)` |

  Tier 1 is a **dict membership test**, not a helper call — which is why it is absent from every
  call-derived reuse list (§1.5, §2.1). Under option (b) Check 95 consults **only**
  `_CHECK_95_ALLOWLIST` at tier 1; it does **not** read `_CHECK_40_ALLOWLIST`.
- **Guardrail-2 fence:** Check 40 does not consult the per-line fence and Check 95 inherits that.
  Measured (EP-24): the intersection of `_CHECK_37_PER_LINE_FENCE_FILES` (10 members) with the
  35-file walk is **empty**, so the two are consistent by measurement rather than by accident.
- **Failure message:** `file:line`, the bare basename, the candidate-set triage (0 / 1 / 2+
  candidates), and the two remediations — qualify the path, or add an allowlist entry with a
  rationale. State that the allowlist is sized to the KEEP set EXACTLY and must not be widened to
  admit a real bare ref.
- **OK line, exact term set.** Emit, in this order, so §6.9's gate is greppable:
  `<N> file(s) scanned; <N> hit(s); <N> allowlisted-basename clear(s); <N> anchor; <N> same-dir;
  <N> bare refs outside the allowlist (complete).`

### 6.3 `_CHECK_95_EXCLUDE_PREFIXES` — 5 whole-tree prefixes

```python
_CHECK_95_EXCLUDE_PREFIXES = (
    "maintenance-docs/",
    "backlog/",              # WHOLESALE per the user's standing constraint (ROI-3=(b))
    "changelog/",            # WHOLESALE per the user's standing constraint (ROI-3=(b))
    "test-fixtures/",
    "scripts/tests/fixtures/",
)
```
**Every prefix is a whole tree. Do NOT reintroduce `backlog/BD-` or `changelog/v` here. [BINDING]**
The architect recommended the entry-shaped form; the user weighed it and chose the literal reading
of their own constraint. Under the entry-shaped form this constant excluded **nothing** (measured:
`dropped_by_prefix = []`) and its per-check test would have passed vacuously; under the wholesale
form it drops exactly `backlog/_rules.md` and `changelog/_rules.md` (EP-10), so the constant is
load-bearing and the test can be written against reality.

Add a one-line comment recording that Check 68's sibling constant is entry-shaped **by a separate
decision on a different axis** (§5.5), so a later maintainer does not "harmonize" them.

### 6.4 `_CHECK_95_ALLOWLIST` — 34 entries, basename-keyed, `reason:` naming the measured citers

**ROI-6 = (a): basename keys stand. Do NOT "improve" this to path-scoped keys. [BINDING]** Two facts
make the broader key correct here and both are recorded at the constant:
1. **The two WALKS — not the two entry sets — are disjoint by construction.** Check 95's walk is
   Check 40's walk SUBTRACTED OUT (measured: the 35-member walk contains zero `pack-ops/` paths,
   EP-10), so a `_CHECK_95_ALLOWLIST` entry can **never** exempt anything under `pack-ops/`. The
   `pack-ops/` blinding that ruled out widening Check 40 is not mitigated here — it is structurally
   unreachable. The two ENTRY sets deliberately **overlap on 8 basenames** (Block B) that both
   walks legitimately exempt; that overlap is not duplication to be removed, and it adds no net
   exemption anywhere, because all 8 are already exempt in Check 40's walk.
2. **The real comparison is broad-key versus no check at all.** Check 95 walks 35 files currently
   walked by nothing.

The residual is real and stated rather than hidden: allowlisting `ARCHITECTURE.md` exempts it in all
35 files, not only the 3 where it was measured. The `reason:` fields naming the measured citers are
the chosen mitigation.

**Place this text AT the constant, verbatim (§9 D-2). [BINDING]** It is the sentence that stops a
later maintainer "deduplicating" `_CHECK_95_ALLOWLIST` against `_CHECK_40_ALLOWLIST` and
reintroducing 114 failures:

> The two WALKS are disjoint by construction — Check 95's walk is Check 40's walk SUBTRACTED OUT
> (measured: zero `pack-ops/` members) — so no `_CHECK_95_ALLOWLIST` entry can exempt anything under
> `pack-ops/`. The two ENTRY sets deliberately OVERLAP on 8 basenames that both walks legitimately
> exempt; that overlap is not duplication to be removed. Check 95 does NOT consult
> `_CHECK_40_ALLOWLIST`: coupling the two would make this check's teeth a function of a constant
> owned by another check.

**Sizing — leave-one-out necessity, measured (EP-23). [BINDING]** The `occ` column below is the
number of NEW Check-95 FAILs that appear if that single entry is removed from the constant, against
the post-STRIP tree. **Every one of the 34 is non-zero: zero entries are redundant.** The column sums
to **189**, which equals the empty-allowlist probe's FAIL count exactly — the arithmetic closure that
proves the set is sized to the measured legitimate population and no larger.

**Block A — the 26 residue entries** (75 occurrences; the census's KEEP set minus the 2
`changelog/_rules.md` records ROI-3=(b) removes from the walk — see §6.5's reconciliation note):

| # | key (basename) | occ | `reason:` |
|---:|---|---:|---|
| 1 | `agent-run.sh` | 9 | see the corrected text below — do NOT paste the pre-derived one |
| 2 | `AGENT_KICKOFF.md` | 1 | client-side artifact / coincidental-basename; no pack file is the referent; measured in supporting-docs/SETUP-NEW.md |
| 3 | `ARCHITECTURE.md` | 4 | client-side artifact / coincidental-basename; no pack file is the referent; measured in .claude/skills/architecture-review/SKILL.md, supporting-docs/AGENT_KICKOFF_TEMPLATE.md, supporting-docs/SETUP-NEW.md |
| 4 | `BACKLOG.md` | 7 | client-side artifact / coincidental-basename; no pack file is the referent; measured in AGENTS.md, CLAUDE.md, GEMINI.md, supporting-docs/DEPENDENCIES.md, supporting-docs/MIGRATION-v10-to-v11.md |
| 5 | `bootstrap.sh` | 3 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/DEPENDENCIES.md |
| 6 | `CHANGELOG.md` | 5 | client-side artifact / coincidental-basename; no pack file is the referent; measured in AGENTS.md, CLAUDE.md, GEMINI.md, supporting-docs/MIGRATION-v10-to-v11.md, supporting-docs/SETUP-EXISTING.md |
| 7 | `config.yml` | 1 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/MIGRATION-v10-to-v11.md |
| 8 | `format.sh` | 2 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/DEPENDENCIES.md |
| 9 | `IMPLEMENTATION-PLAN.md` | 5 | client-side artifact / coincidental-basename; no pack file is the referent; measured in AGENTS.md, CLAUDE.md, GEMINI.md, supporting-docs/MIGRATION-v10-to-v11.md |
| 10 | `IMPLEMENTATION_PLAN.md` | 1 | client-side artifact / coincidental-basename; no pack file is the referent; measured in supporting-docs/MIGRATION-v10-to-v11.md |
| 11 | `inbound.yml` | 2 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/MIGRATION-v10-to-v11.md |
| 12 | `migrate-vN-to-vM.sh` | 1 | filename GRAMMAR pattern, not a file; measured in supporting-docs/SETUP-NEW.md |
| 13 | `MIGRATION-v9-to-v10.md` | 1 | retired/historical name cited in migration prose; measured in supporting-docs/SETUP-EXISTING.md |
| 14 | `MIGRATION-vN-to-vM.md` | 4 | filename GRAMMAR pattern, not a file; measured in README.md, supporting-docs/SETUP-EXISTING.md, supporting-docs/SETUP-NEW.md |
| 15 | `OPTIONAL-FEATURES.md` | 1 | directory named in the same sentence; bareness is contextually resolved; measured in .claude/skills/boundary-investigation/SKILL.md |
| 16 | `PACK-FEEDBACK.md` | 1 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/PRE-RECONCILE-v10-to-v11.md |
| 17 | `PLATFORM-SKILLS.md` | 1 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/PRE-RECONCILE-v10-to-v11.md |
| 18 | `plugin.json` | 3 | directory named in the same sentence; bareness is contextually resolved; measured in GEMINI.md, supporting-docs/MIGRATION-v10-to-v11.md |
| 19 | `PROMPT-TEMPLATES.md` | 2 | retired/historical name cited in migration prose; measured in supporting-docs/MIGRATION-v10-to-v11.md, supporting-docs/PRE-RECONCILE-v10-to-v11.md |
| 20 | `proto-gen.sh` | 3 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/DEPENDENCIES.md |
| 21 | `pyproject.toml` | 4 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/DEPENDENCIES.md, supporting-docs/MIGRATION-v10-to-v11.md |
| 22 | `pyrightconfig.json` | 1 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/MIGRATION-v10-to-v11.md |
| 23 | `RUNTIME-SUBAGENT-PATTERN.md` | 3 | directory named in the same sentence; bareness is contextually resolved; measured in GEMINI.md, supporting-docs/MIGRATION-v10-to-v11.md |
| 24 | `SETUP.md` | 1 | client-side artifact / coincidental-basename; no pack file is the referent; measured in supporting-docs/SETUP-NEW.md |
| 25 | `SKILL.md` | 3 | ecosystem-fixed name (filename-uniqueness structural exemption); measured in AGENTS.md, CLAUDE.md, GEMINI.md |
| 26 | `validate.sh` | 6 | client-installed file named from a client-audience doc; bare form is the client-relative shape; measured in supporting-docs/DEPENDENCIES.md |

**Block B — the 8 tier-1 entries the census presupposed** (114 occurrences; §2.1). These are the
basenames `_CHECK_40_ALLOWLIST` cleared during the census, so the census never triaged them; without
them Check 95 FAILs 114 times. Each carries a **Check-95-walk-scoped** rationale, not a copy of
Check 40's `pack-ops/`-audience one:

| # | key (basename) | occ | `reason:` |
|---:|---|---:|---|
| 27 | `CLAUDE.md` | 30 | pack-root trinity basename cited as a SET in parity/sync prose ("keep CLAUDE.md, AGENTS.md, GEMINI.md in sync"); 3 candidates exist in the index (pack root, project-template/, xcode-companion-templates/), so no single qualification is correct and the same-dir tier cannot reach it; measured in .claude/skills/{boundary-investigation,commit-discipline,dashboard-render,pack-refresh}/SKILL.md, CLAUDE.md, supporting-docs/{AGENT_KICKOFF_TEMPLATE,MIGRATION-v10-to-v11,PRE-RECONCILE-v10-to-v11,SETUP-EXISTING,SETUP-NEW,SETUP_TEMPLATE}.md |
| 28 | `GEMINI.md` | 29 | pack-root trinity basename, same set-shorthand class as CLAUDE.md; 2 candidates (pack root, project-template/); measured in .claude/agents/pack-coder.md, .claude/skills/{boundary-investigation,commit-discipline,pack-refresh}/SKILL.md, CLAUDE.md, GEMINI.md, supporting-docs/{MIGRATION-v10-to-v11,PRE-RECONCILE-v10-to-v11,SETUP-EXISTING,SETUP-NEW}.md |
| 29 | `AGENTS.md` | 27 | pack-root trinity basename, same set-shorthand class as CLAUDE.md; 3 candidates (pack root, project-template/, xcode-companion-templates/Codex/); measured in .claude/agents/pack-coder.md, .claude/skills/{boundary-investigation,commit-discipline,pack-refresh}/SKILL.md, AGENTS.md, CLAUDE.md, supporting-docs/{AGENT_KICKOFF_TEMPLATE,MIGRATION-v10-to-v11,PRE-RECONCILE-v10-to-v11,SETUP-EXISTING,SETUP-NEW}.md |
| 30 | `README.md` | 24 | pack-root landing-page doc; 6 candidates in the index (pack root plus 5 subtree READMEs), and every citation is pack-root-audience; measured in .claude/skills/{commit-discipline,dashboard-render,implementation-report,pack-help,pack-startup,pack-status}/SKILL.md, AGENTS.md, CLAUDE.md, GEMINI.md, supporting-docs/SETUP-EXISTING.md |
| 31 | `QUICKSTART.md` | 1 | pack-root installer doc; 1 candidate at the repo root, so the two README.md citations clear on the same-dir tier and only the cross-directory citation needs the entry; measured in .claude/skills/pack-help/SKILL.md |
| 32 | `settings.json` | 1 | Claude-Code user/project config, external to the pack repo; the reference is deliberately scope-agnostic (the same key lives at EITHER ~/.claude/settings.json OR .claude/settings.json), so qualifying to one of the 4 candidates would misrepresent the documented choice; measured in .claude/skills/commit-discipline/SKILL.md |
| 33 | `report.md` | 1 | generated at runtime by scripts/lib/customization-report.sh; 0 candidates in the repo, so there is no path to qualify to; measured in supporting-docs/MIGRATION-v10-to-v11.md |
| 34 | `tracker.toml` | 1 | generated by `pack tracker init`; 0 candidates in the repo (the pack ships tracker.toml.pack-example), so there is no path to qualify to; measured in supporting-docs/MIGRATION-v10-to-v11.md |

**Total: 34 entries, 189 measured necessity-occurrences, zero redundant entries.**

**`LICENSE.md` must NOT be added, and this is a trap. [BINDING]** It is in `_CHECK_40_ALLOWLIST` and
it has 3 occurrences in the Check-95 walk (`README.md:311`, `:321` ×2) — so a coder reconciling
against Check 40 will reach for it. Measured: `LICENSE.md` has exactly ONE candidate, at the repo
root, and the citing file is also at the repo root, so **tier 3 clears all three occurrences**. Its
leave-one-out necessity is 0. Adding it makes the constant not-exactly-sized. The same is true of
the other 9 `_CHECK_40_ALLOWLIST` members, which have zero occurrences in the walk at all
(`BD-NNN.md`, `HELP-FRAGMENT.md`, `LICENSE`, `MEMORY.md`, `TD-NNN.md`,
`feedback_review_fix_cycle.md`, `id-map.json`, `manifest.txt`, `phase-N.md`).

**One `reason:` correction the coder must apply — `agent-run.sh`.** The pre-derived text reads
*"no pack file is the referent"*, which is FALSE as written: `git ls-files | grep agent-run.sh`
returns exactly one candidate, `project-template/agent-run.sh` (EP-20). Every one of the 9 citations
names the CLIENT's copy at the client's project ROOT (`./agent-run.sh` in `SETUP-NEW.md:442`,
`SETUP-EXISTING.md:398`), and `CLAUDE.md:272–273` says outright *"The pack repo has no
`agent-run.sh` — that's a project template helper."* Qualifying to `project-template/agent-run.sh`
would misdirect a client reader AND contradict that sentence. Use instead:

> `client-root artifact — every citation names the CLIENT's project-root copy (installed from project-template/agent-run.sh); the pack repo itself has none, which CLAUDE.md/AGENTS.md/GEMINI.md state outright. Qualifying to the template path would misdirect a client reader; measured in .claude/skills/commit-discipline/SKILL.md, AGENTS.md, CLAUDE.md, GEMINI.md, README.md, supporting-docs/DEPENDENCIES.md, supporting-docs/SETUP-EXISTING.md, supporting-docs/SETUP-NEW.md`

This is OI-7 = (a) implemented correctly: allowlist `agent-run.sh` only; do **not** broaden the
shared anchor set. `AGENTS.md:273` reads "pack repo has no `agent-run.sh`" and the existing anchors
(`in the pack repo`, `at the pack repo`, `pack-repo`) do not match that wording; broadening to bare
`pack repo` would over-clear across the trinity, and adding a `pack repo has no` phrase edits a
constant three checks share for one occurrence.

**The rejected alternative, recorded so it is not re-proposed (§9 D-1 option (a)).** Having Check 95
consult `_CHECK_95_ALLOWLIST | _CHECK_40_ALLOWLIST` also reaches FAIL = 0 — measured, the OK line
would read `35 file(s) scanned; 224 hit(s); 200 allowlisted-basename clear(s); 8 anchor; 16 same-dir;
0 bare refs outside the allowlist` (EP-23), differing only in the tier-1/anchor/same-dir attribution.
It was rejected on two measurements: it admits **10 keys with zero necessity** in this walk (9 with
no occurrence at all, plus `LICENSE.md`), breaking the exactly-sized requirement; and it makes Check
95's teeth a function of a constant Check 40 owns, so a later `_CHECK_40_ALLOWLIST` widening for a
`pack-ops/` reason would silently widen Check 95 across 35 unrelated files. **Do not implement it.**

---
### 6.5 The 45 STRIPs — every occurrence, with its target

**[BINDING] Every STRIP is a LINE-TARGETED edit at the coordinate below.** Two files carry the same
basename on two different lines and three carry two distinct basenames on ONE line
(`CLAUDE.md:609`, `AGENTS.md:490`, `GEMINI.md:462` each carry `PACK-CHAT.md` AND `PACK-AGENTS.md`) —
work per occurrence, not per file. A tree-wide find/replace is prohibited in this wave for the same
reason it is in W4 (§7.6).

**Completeness, proved.** The 45 STRIP coordinates are **set-identical** to the FAIL set produced by
running the full four-tier ladder (with `_CHECK_95_ALLOWLIST ∪ _CHECK_40_ALLOWLIST` at tier 1) over
the walk pre-STRIP (EP-23: `union-variant PRE-STRIP FAIL count: 45 | triage STRIP count: 45 | set
identical: True`). Nothing is missing and nothing is surplus.

**The 77-vs-75 reconciliation, so it is not a trip hazard (EP-10, EP-23).** `c95-triage.json` records
`Counter({'KEEP': 77, 'STRIP': 45})` — 122 records. §6.4's Block A has **75**, not 77. The delta is
exactly two records, `changelog/_rules.md:32` and `:35`, both basename `vN.md`, both dropped from the
walk by ROI-3=(b)'s wholesale `changelog/` exclusion. The 26 distinct KEEP basenames after that
exclusion are exactly Block A's 26. **Both numbers are correct; they describe different walks.** The
2 dropped records contributed **zero** STRIPs, so the fix-set is unchanged by that decision.

The 11 targets, all verified to EXIST at HEAD (EP-11):

| bare basename | → qualified target | occ |
|---|---|---:|
| `init-project.sh` | `scripts/init-project.sh` | 15 |
| `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` | 9 |
| `validate-pack.py` | `scripts/validate-pack.py` | 6 |
| `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` | 4 |
| `PACK-MEMORY-RATIONALE.md` | `pack-ops/PACK-MEMORY-RATIONALE.md` | 3 |
| `no_leak.py` | `scripts/lib/validate_checks/no_leak.py` | 3 |
| `HELP-FRAGMENT-PACK.md` | `pack-ops/HELP-FRAGMENT-PACK.md` | 1 |
| `SETUP-EXISTING.md` | `supporting-docs/SETUP-EXISTING.md` | 1 |
| `migrate-v10-to-v11.sh` | `scripts/migrate-v10-to-v11.sh` | 1 |
| `test-customization-preserve.sh` | `scripts/tests/test-customization-preserve.sh` | 1 |
| `test-migrator-core.sh` | `scripts/test-migrator-core.sh` | 1 |

**Total 45 occurrences over 11 basenames / 11 files.**

Per-file coordinates (line numbers measured at `47f8467`; key on the backticked basename on
that line, not the number). The adversarial pass applied all 45 at these coordinates by asserting
the named backticked token is present on the named line before replacing it — **45 applied, 0
misses**.

**`.claude/skills/boundary-investigation/SKILL.md`** — 5 STRIP(s)

| line | bare | → |
|---:|---|---|
| 99 | `HELP-FRAGMENT-PACK.md` | `pack-ops/HELP-FRAGMENT-PACK.md` |
| 99 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |
| 99 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` |
| 121 | `SETUP-EXISTING.md` | `supporting-docs/SETUP-EXISTING.md` |
| 165 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |

**`.claude/skills/dashboard-render/SKILL.md`** — 1 STRIP(s)

| line | bare | → |
|---:|---|---|
| 23 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |

**`.claude/skills/pack-help/SKILL.md`** — 1 STRIP(s)

| line | bare | → |
|---:|---|---|
| 3 | `validate-pack.py` | `scripts/validate-pack.py` |

**`.claude/skills/verification-harness/SKILL.md`** — 1 STRIP(s)

| line | bare | → |
|---:|---|---|
| 239 | `test-migrator-core.sh` | `scripts/test-migrator-core.sh` |

**`AGENTS.md`** — 7 STRIP(s)

| line | bare | → |
|---:|---|---|
| 348 | `validate-pack.py` | `scripts/validate-pack.py` |
| 475 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |
| 490 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |
| 490 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` |
| 492 | `PACK-MEMORY-RATIONALE.md` | `pack-ops/PACK-MEMORY-RATIONALE.md` |
| 697 | `init-project.sh` | `scripts/init-project.sh` |
| 787 | `no_leak.py` | `scripts/lib/validate_checks/no_leak.py` |

**`CLAUDE.md`** — 7 STRIP(s)

| line | bare | → |
|---:|---|---|
| 359 | `validate-pack.py` | `scripts/validate-pack.py` |
| 600 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |
| 609 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |
| 609 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` |
| 611 | `PACK-MEMORY-RATIONALE.md` | `pack-ops/PACK-MEMORY-RATIONALE.md` |
| 816 | `init-project.sh` | `scripts/init-project.sh` |
| 918 | `no_leak.py` | `scripts/lib/validate_checks/no_leak.py` |

**`GEMINI.md`** — 7 STRIP(s)

| line | bare | → |
|---:|---|---|
| 317 | `validate-pack.py` | `scripts/validate-pack.py` |
| 444 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |
| 462 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` |
| 462 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` |
| 464 | `PACK-MEMORY-RATIONALE.md` | `pack-ops/PACK-MEMORY-RATIONALE.md` |
| 669 | `init-project.sh` | `scripts/init-project.sh` |
| 760 | `no_leak.py` | `scripts/lib/validate_checks/no_leak.py` |

**`supporting-docs/MIGRATION-v10-to-v11.md`** — 5 STRIP(s)

| line | bare | → |
|---:|---|---|
| 53 | `migrate-v10-to-v11.sh` | `scripts/migrate-v10-to-v11.sh` |
| 346 | `validate-pack.py` | `scripts/validate-pack.py` |
| 391 | `validate-pack.py` | `scripts/validate-pack.py` |
| 507 | `init-project.sh` | `scripts/init-project.sh` |
| 835 | `test-customization-preserve.sh` | `scripts/tests/test-customization-preserve.sh` |

**`supporting-docs/SETUP-EXISTING.md`** — 5 STRIP(s)

| line | bare | → |
|---:|---|---|
| 12 | `init-project.sh` | `scripts/init-project.sh` |
| 63 | `init-project.sh` | `scripts/init-project.sh` |
| 149 | `init-project.sh` | `scripts/init-project.sh` |
| 284 | `init-project.sh` | `scripts/init-project.sh` |
| 358 | `init-project.sh` | `scripts/init-project.sh` |

**`supporting-docs/SETUP-NEW.md`** — 4 STRIP(s)

| line | bare | → |
|---:|---|---|
| 70 | `init-project.sh` | `scripts/init-project.sh` |
| 80 | `init-project.sh` | `scripts/init-project.sh` |
| 144 | `init-project.sh` | `scripts/init-project.sh` |
| 145 | `init-project.sh` | `scripts/init-project.sh` |

**`supporting-docs/SETUP_TEMPLATE.md`** — 2 STRIP(s)

| line | bare | → |
|---:|---|---|
| 73 | `init-project.sh` | `scripts/init-project.sh` |
| 85 | `init-project.sh` | `scripts/init-project.sh` |

**Two things the 45 STRIPs must not do. [BINDING]**

1. **Add nothing but the directory prefix.** Do not reword, do not "improve" a sentence while
   qualifying it. Check 66's tightest post-edit margin is **163 characters** on
   `GEMINI.md`'s `- **What Pack Chat CAN edit directly**` bullet (§2.5, EP-7); prose added on top of
   the qualification eats it.
2. **The trinity is a parity surface.** The 7 STRIPs in `CLAUDE.md`, the 7 in `AGENTS.md` and the 7
   in `GEMINI.md` are the same seven rules; all 21 land in this one commit, per the trinity rule.
   Verify parity by diffing the three affected regions after the edit, not by trusting the line
   table.

### 6.6 Registry, count, ledger, README — the lock-step set

**These four move together or CI fails in two places at once.**

| Surface | Edit | Enforced by |
|---|---|---|
| `scripts/validate-pack.py` `CHECK_REGISTRY` | add `(95, "<label>", check_live_pack_doc_bare_refs, <budget_s>)` | Check 59 |
| `scripts/lib/validate_checks/core.py:210` | `CHECK_REGISTRY_EXPECTED_COUNT = 91` → `92` | Check 59 (`len(registry) == constant`) |
| `core.py` ledger comment (directly above `:210`) | append a BD-288 line in the established form; change the trailing `(Next free numeric ID = 95.)` → `(Next free numeric ID = 96.)` | prose only — no check, but it is the surface BD-288's acceptance criterion is actually about |
| `README.md` L83 **and** L204 | `91 invoked checks` → `92`; `91 registry entries total` → `92`; `86 numbered` → `87`; `77–94` → `77–95` | Check 80 binds the **first two only** |

**Check 80's exact binding, measured (EP-21).** `cross_bd.py:353–376` extracts
`(\d+)\s+invoked checks|(\d+)\s+registry entries total` from `README.md` and asserts the resulting
SET equals `{str(CHECK_REGISTRY_EXPECTED_COUNT)}`. A partial drift (one phrase updated, the other
stale) yields a 2-element set and a clean named FAIL. The sibling `86 numbered` and the `77–94`
range are **deliberately not extracted** — the twin row's own comment says binding them would break
the bijection because they are different quantities. So those two are correctness-by-hand: update
them, and know that no gate catches it if you don't.

**Each of the four strings occurs exactly twice tree-wide** — once at README L83, once at L204;
`git grep -c` returns `README.md:2` for each and no other file matches. **8 token edits total**
(measured, EP-21).

**A second, larger lock-step consequence.** `CHECK_REGISTRY_EXPECTED_COUNT` is asserted against
`len(_build_check_registry())` by **exactly 30 per-check test files** (measured, EP-21:
`test-validate-pack-check-{23, 43-44-junk, 62, 63, 64, 66, 67, 68, 69, 70, 71, 73, 74, 75, 77, 78,
79, 80, 83, 84, 85, 86, 87, 88, 89, 90, 92, 93, 94}.sh` plus
`test-validate-pack-checks-58-59-60.sh`). Every one compares dynamically — **no test hardcodes 91**
— so bumping the constant without the registry tuple, or the reverse, reds essentially the whole
per-check suite at once. That is a feature: it makes the lock-step un-forgettable. Land the registry
tuple and the constant in the same edit pass.

**Ledger line, suggested form** (match the file's established shape; no dated notes, no "per BD-NNN"
provenance beyond the established `BD-NNN adds Check N` idiom the ledger already uses):

> `# BD-288 adds Check 95 (live-pack-doc bare cross-reference scanner — the bareness axis over the`
> `# 35 live pack-doc surfaces walked by neither Check 40 nor Check 43; one new registry entry):`
> `# 91 → 92. (Next free numeric ID = 96.)`

### 6.7 Check 71 — 8 mirror propagations

`_CHECK_71_SKILL_MIRROR_DIRS = (".claude/skills", ".codex/skills", ".agents/skills")`; 18 skills ×3,
all byte-identical today (EP-14); **no allowlist, no propagation automation**.

W3 edits four canonical `.claude/skills/*/SKILL.md` files, so eight mirrors must follow:

| Canonical | STRIPs | Mirrors |
|---|---:|---|
| `.claude/skills/boundary-investigation/SKILL.md` | 5 | `.codex/skills/…`, `.agents/skills/…` |
| `.claude/skills/dashboard-render/SKILL.md` | 1 | `.codex/skills/…`, `.agents/skills/…` |
| `.claude/skills/pack-help/SKILL.md` | 1 | `.codex/skills/…`, `.agents/skills/…` |
| `.claude/skills/verification-harness/SKILL.md` | 1 | `.codex/skills/…`, `.agents/skills/…` |

`boundary-investigation` is propagated in W2 (for its `:73–74` STRIPs) and AGAIN in W3 (for its
`:99/:121/:165` STRIPs) — the second reason W2 and W3 serialize.

**Note for the coder:** the `.codex/` and `.agents/` mirrors are NOT in `_iter_operating_docs()`
(measured, EP-22), so Check 95 never scans them and no content gate covers them independently.
**Check 71 byte-identity is the only thing holding them in sync.** Propagate by whole-file copy,
then `md5 -q` all three and confirm equality.

### 6.8 Intra-wave ordering — [BINDING]

```
  1. the 45 STRIPs across the 11 files                         ← FIRST
  2. the 8 Check-71 mirror propagations                        ← MUST follow 1
  3. _CHECK_95_EXCLUDE_PREFIXES + _CHECK_95_ALLOWLIST (34) + the check body + __all__
  4. registry tuple + CHECK_REGISTRY_EXPECTED_COUNT + ledger   ← together, one pass
  5. README.md ×2 sites, 8 tokens                              ← MUST accompany 4 (Check 80)
  6. scripts/tests/test-validate-pack-check-95.sh
```

Three orderings are load-bearing:

- **Step 1 before step 3.** Landing Check 95 before its fix-set makes the commit red 45 times. The
  two must be in one commit, and within that commit the fixes precede the check so the first battery
  run you do is meaningful.
- **Step 2 immediately after step 1.** Check 71 has no allowlist; a canonical edit without its
  mirrors is an immediate red gate.
- **Steps 4 and 5 in the same pass.** Check 80 compares the README numbers against the constant;
  Check 59 compares the constant against the registry length; 30 per-check tests compare the same.
  Any partial application reds all three at once.

**Steps 1+2 alone are green.** The adversarial pass built exactly that boundary — 45 STRIPs + 8
mirrors, nothing else — and ran `validate-pack.py` and `PACK_VALIDATE_DEEP=1` to `rc=0, PASSED — all
checks clean`. That makes §6.11's W3a/W3b split a genuinely available fallback rather than an
assertion, and it means a coder can take a green checkpoint mid-wave.

---
### 6.9 Verification gate

| Item | Before | After |
|---|---|---|
| `validate-pack.py` | `PASSED`, exit 0 | `PASSED`, exit 0 |
| `PACK_VALIDATE_DEEP=1` | exit 0 | exit 0 |
| Check 59 | `CHECK_REGISTRY has 91 entr(y/ies)` | `92` |
| Check 80 | green | green — README doc-set `{92}` == const-set `{92}` |
| **Check 95** (new) | n/a | see the exact line below |
| **Check 66** | green | green — tightest margin 163 chars (§2.5) |
| **Check 71** | green | green — 12 SKILL.md files, 4 md5 triples equal |
| Check 40 | green | green — walk unchanged (`pack-ops/*.md`, 10 files) |
| Check 43 | green | green — none of the 11 STRIP files is client-installed (EP-16) |
| Check 68 | green (post-W2: 229/1836/0 dangling) | green — the 45 newly-qualified refs resolve on the **direct** leg (all 11 targets exist, EP-11) |
| Check 93 | green | green — path qualifications only; no new vocabulary on the trinity / `supporting-docs/` / `README.md` |
| `test-validate-pack-check-95.sh` | n/a | all groups pass |
| 30 count-invariant per-check tests | pass | pass |
| `--assert-coverage` | green | green — picks up the new test **from disk** with no workflow edit (§2.2) |
| `build.sh --verify` | green | green |

**Check 95's expected OK line — measured, not projected (EP-23). [BINDING]**

```
OK: Check 95 — 35 file(s) scanned; 224 hit(s); 197 allowlisted-basename clear(s);
    8 anchor; 19 same-dir; 0 bare refs outside the allowlist (complete).
```

| Term | Value | Where it comes from |
|---|---:|---|
| files scanned | **35** | the walk, reproduced independently (EP-10) |
| hits | **224** | POST-STRIP population. 269 is the PRE-STRIP figure; the 45 STRIPs stop being bare refs |
| allowlisted-basename clears | **197** | OCCURRENCES cleared at tier 1, not the 34 entry count |
| anchor | **8** | tier 2 |
| same-dir | **19** | tier 3 |
| bare refs outside the allowlist | **0** | the gate |

**Every one of the six terms was wrong or unreachable in the superseded plan** (`35 / 269 / 26 / 11
/ 16 / 0`): `269` is the pre-STRIP population, `26` is an ENTRY count where the check counts
OCCURRENCES, and `11 / 16` are the anchor/same-dir split under a tier-1 that is neither of the two
candidate constants. Under option (a) the line reads `35 / 224 / 200 / 8 / 16 / 0` (§6.4). **A
reviewer who compares against the superseded numbers reports a mismatch on a green tree.**

**What proves Check 95 BITES rather than merely passing — five things, all required [BINDING]:**

1. **Census-closure probe.** Empty `_CHECK_95_ALLOWLIST` in-process ⇒ the check must FAIL on the
   live post-STRIP tree with **exactly 189 failures** (measured, EP-23; decomposes as 75 from Block
   A + 114 from Block B). If it still passes, the walk is empty and the check is inert. **The
   superseded plan said 75 and the adversarial review corrected it to 197; both are wrong as a
   FAILURE count.** 197 is the number of tier-1 CLEARS; when tier 1 is emptied, 8 of those 197 fall
   through to tier 2 (anchor, 8 → 14) and tier 3 (same-dir, 19 → 21), leaving **189** FAILs. Assert
   189.
2. **Walk-non-empty probe.** Assert the derived walk is exactly **35** files against the live tree,
   and that it contains `README.md` and at least one `supporting-docs/*.md` and one
   `.claude/skills/*/SKILL.md`, and contains **no** `pack-ops/` path and **no** `project-template/`
   path (both measured empty, EP-10). A subtraction bug that empties the walk otherwise passes
   silently.
3. **Exclusion probe — BOTH live-tree and fixture-based [BINDING].** Under the decided wholesale
   form, `backlog/` and `changelog/` really do drop `backlog/_rules.md` and `changelog/_rules.md`,
   so assert those two against the live tree. The other three
   (`maintenance-docs/`, `test-fixtures/`, `scripts/tests/fixtures/`) exclude **zero** live members
   (measured, EP-10: `dropped_by_prefix` lists exactly the two `_rules.md` files) — an assertion
   phrased against the real repo passes vacuously for them. Assert those three against a **fixture
   tree** carrying a `maintenance-docs/x.md`-shaped and a `test-fixtures/y.md`-shaped file, and
   mutation-prove by removing one prefix and confirming the fixture leg fires.
4. **The originating-mechanism regression [BINDING, an explicit acceptance criterion].** A fixture
   doc carrying a BARE reference to a file that exists at a DIFFERENT path must FAIL Check 95. This
   is the `MERGE-STRATEGY.md` mechanism reproduced. Corollary probe on the live constant:
   `'MERGE-STRATEGY.md' in _CHECK_95_ALLOWLIST` must be **False** — the guard still catches the exact
   12-reference defect that motivated the BD.
5. **Tracked-set probe + `git init` fixture trees [BINDING].** Every fixture leg runs in a throwaway
   `git init` repo. Without it, `_git_tracked_relpaths()` returns `None`, the lenient SKIP fires,
   and the leg passes with zero failures. Use `tempfile.mkdtemp(prefix="vp-check95-")` from Python
   — **not** shell `mktemp -t`, which Check 92 FAILs — and rebind `REPO_ROOT` on the facade AND
   every loaded `validate_checks.*` submodule. **In that fixture tree, additionally drop an
   UNTRACKED `.md` into `supporting-docs/` and assert it is absent from the scanned set** — this is
   the only leg that proves §6.2's `walk &= set(rels)` intersection is present, because on the
   canonical tree the tracked and on-disk sets coincide (EP-24) and a live-tree assertion passes
   either way.

**New-test constraints (Check 83 + Check 92).** A test at `scripts/tests/*.sh` enters both
candidate sets automatically. Check 83 statically bans (a) hardcoded dev/home paths (`/Users/`,
`/home/`, `~/`), (b) direct un-shimmed live-`gh` calls, (c) the `grep -c … || echo 0` double-zero
idiom. Check 92 FAILs `mktemp -t <prefix>XXXXXX` (incl. `-dt`/`-qt`/`-dqt`) and GNU-only
`--tmpdir`/`-p DIR`; the portable shell form is `mktemp [-d] "${TMPDIR:-/tmp}/<prefix>.XXXXXX"`.
Following `test-validate-pack-check-53.sh` and using Python's `tempfile.mkdtemp` sidesteps Check 92
entirely.

**Filename.** `scripts/tests/test-validate-pack-check-95.sh` — measured:
`find . -name "test-validate-pack-check-95.sh" -not -path './.git/*'` returns nothing, and the
highest per-check test present is `check-94`. No collision.

### 6.10 Bounded-cycle fit

**FITS, and the argument is about discovery, not size.** W3 is the largest wave (24 files) but
carries **zero open discovery**, with no remaining decision gate (§9 D-1 and D-12 are both closed):

- The 45 STRIPs are enumerated line by line with their targets (§6.5), every target verified to
  exist (EP-11), and the STRIP set proved set-identical to the ladder's FAIL set (EP-23).
- The 34 allowlist entries arrive with their `reason:` strings written out (§6.4) — 26 carried
  forward with one correction applied for `agent-run.sh`, 8 authored here from measured citers.
- Every allowlist entry's necessity is measured by leave-one-out (EP-23), so the "sized EXACTLY"
  claim is a measurement the reviewer can re-run, not a judgement.
- The walk is reproduced independently at 35 files / 441,529 bytes (EP-10), so the reviewer checks a
  number rather than re-deriving a subtraction.
- **The check is its own completeness oracle.** A green Check 95 means the census is closed; the
  reviewer verifies a gate result, not 45 individual judgments.
- **Check 71 is the mirror oracle** for the 8 propagations — byte-identity is absolute and
  mechanically verifiable with `md5`.
- The two count lock-steps (Check 59, Check 80) plus 30 per-check count tests make a partial
  application impossible to miss.

The two places a reviewer must read rather than run: the walk-by-subtraction expression (does it
subtract Check 40's walk and `_iter_client_installed_files()` and the prefixes, **and intersect with
`rels`**?) and the fixture-based exclusion + untracked-file legs (do they actually assert the three
inert prefixes and the tracked intersection?). Both bounded.

**What B-1 cost the cycle, and why it is now paid.** The superseded plan left a coder to rediscover
tier 1 of the exemption ladder and re-derive its membership mid-commit, inside a wave whose own text
asserted zero open discovery — a red first battery run with 114 failures and a failure message
pointing at the wrong remedy. That discovery is done: the membership is measured (8), the necessity
of each is measured, the redundant candidates are named and excluded, and every expected number is
re-derived. §6.4's Block B is a paste, not an investigation.

**ROI-4 = (a): ship W3 merged. The §6.11 split stays a live fallback — do NOT take it pre-emptively.**

### 6.11 Fallback if W3 will not converge

If W3 exceeds 2 review/fix pairs, split into **W3a → W3b**:

- **W3a** — the 45 bareness STRIPs + the 8 Check-71 mirrors only. **Measured green standalone**: the
  adversarial pass built exactly this tree and ran `validate-pack.py` and `PACK_VALIDATE_DEEP=1` to
  `rc=0, PASSED — all checks clean`. Checks 40, 66, 68, 71, 93 and the operating-doc content gates
  all absorb the qualifications.
- **W3b** — Check 95 + the 34-entry allowlist + exclusion constant + registry + `core.py` count and
  ledger + README ×2 + the new test. Green on arrival because W3a already stripped its fix-set.

Both boundaries stay green. The cost is that W3a lands with no gate proving its completeness (the
evidence is then `c95-triage.json` plus W3b arriving immediately after).

### 6.12 Commit shape

**Subject:** `feat: v11 — BD-288 Check 95 live-pack-doc bareness gate + the 45 qualifications`

**Scope keyword: NONE is claimable. [BINDING]** W3 touches `supporting-docs/` (4 files), which
Check 36's `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")` denies for a
`pack-only` claim. `pack-chat-only` is also unavailable — `boundary_refs.py`, `validate-pack.py`,
`core.py` and the new test are outside the pack-chat-only permitted set. Use neutral framing and
**say in the message that no keyword is claimed and why**, exactly as `47f8467` did ("Mixed pack and
supporting-docs surfaces, so no scope keyword is claimed and Check 36 skips").

**The message must record:**
- why a NEW check rather than a widened Check 40: `_CHECK_40_ALLOWLIST` is basename-keyed and
  consulted at `boundary_refs.py:1899` with no path scoping, so widening Check 40's WALK to cover
  these 35 files would require adding the 26 residue basenames to `_CHECK_40_ALLOWLIST`, which would
  then exempt them inside `pack-ops/` too — buying coverage on 35 files by surrendering teeth on the
  10 the check already guards. That direction of contamination is what the separate check prevents.
- **the tier-1 inheritance, explicitly** — that Check 95 replicates Check 40's FOUR-tier ladder, that
  the census was taken with `_CHECK_40_ALLOWLIST` at tier 1 (proved: the 122-record triage is that
  ladder's FAIL set), and that the 8 Block-B entries exist because of it. This is the single most
  important sentence in the message: it is the reason the constant is 34 and not 26, and without it
  a later maintainer "cleaning up the duplication" against Check 40 reintroduces 114 failures.
- the walk as a subtraction **intersected with the tracked set**, with the measured size (35 files /
  441,529 bytes), the two files the wholesale exclusion drops, and the untracked-file probe.
- **ROI-3 = (b) as a user decision taken against the architect's recommendation**, with the measured
  cost (0 FAILs, one allowlist entry `vN.md` dropped, 77 KEEP → 75) — so a later reader does not
  "restore" the entry-shaped form.
- **ROI-6 = (a)**: basename keys, with fact 1 in its restated form (§9 D-2) — the two WALKS are
  disjoint by construction, the two ENTRY sets deliberately overlap on 8 keys, and no exemption
  crosses between them because all 8 are already exempt in Check 40's walk. Name the rejected
  alternative (consulting `_CHECK_40_ALLOWLIST`) and why: 10 zero-necessity keys + cross-check
  coupling.
- the residual over-exemption, stated plainly, and the `reason:`-names-the-citers mitigation.
- the leave-one-out sizing result: 34 entries, zero redundant, necessity sum 189 == the
  empty-allowlist probe.
- the 45 qualifications by count and basename, that all 11 targets were verified to exist, and that
  the STRIP set is set-identical to the ladder's pre-STRIP FAIL set.
- the count lock-step: registry +1, `CHECK_REGISTRY_EXPECTED_COUNT` 91 → 92, README ×2 (4 tokens
  each), ledger next-free-ID 95 → 96.
- **that no `.github/workflows/validate-pack.yml` edit was needed**, with the reason (wiring is
  disk-derived via `ci-shard-plan.py:parse_wired_tests()` since the BD-219 redesign) — otherwise a
  reviewer will read its absence as an omission against the BD's acceptance criterion.
- the five bite probes, stated as run, including the 189-failure census-closure count and
  `'MERGE-STRATEGY.md' in allowlist? False`.
- Check 66's measured headroom, so the reviewer knows it was considered.

---
## 7. W4 — Check 43's self-tree leg + the client twin

**Depends on:** W3 (`boundary_refs.py`). **Blocks:** nothing. **Commit 4 of 4.** **14 files.**

**The governing principle fires twice more in this one wave, and they overlap.** Check 43's
self-tree leg ships with its 9 STRIPs; the hardened client gate ships with its 10 STRIPs and 6
`target:` records. Eight of Check 43's nine STRIPs are ALSO client-gate STRIPs (the 6 auditor files
+ the 2 `INSTALL-PROCEDURES.md` pointers) and the ninth (`METHODOLOGY.md:1984`) is a client STRIP
too — so **W4 cannot be split into a pack half and a client half without one of them being red.**
The 9 pack-side STRIPs are a SUBSET of the 10 client STRIPs, not additional work: **the wave applies
10 distinct edits in total.** The 10th (`skills/boundary-investigation/SKILL.md:107`) is
deny-list-fenced and invisible to every pack-side gate.

### 7.1 File set

| # | File | Edit |
|---|---|---|
| 1 | `scripts/lib/validate_checks/boundary_refs.py` | `_CHECK_43_SELF_TREE_PREFIXES` + `_CHECK_43_SELF_TREE_PREFIX_PATTERNS` + the leg with the `target == citing file` carve-out + `__all__` ×2 |
| 2 | `scripts/tests/test-validate-pack-check-43.sh` | 4 new legs incl. the ROI-1(b) proof leg + mutation proof |
| 3 | `project-template/scripts/validate-docs.sh` | 3 lock-step fixes + `basenames` deletion tail + bounded `os.walk` + `--self-test` bite legs |
| 4 | `project-template/scripts/.docs-gate-allowlist.txt` | +6 `target:`/`reason:` records (13 → 19) |
| 5 | `scripts/tests/test-validate-docs-template-fullscan.sh` | **NEW L8** profile matrix + the `lstrip` mirror fix (§2.4) |
| 6–11 | the 6 auditor agent files under `project-template/` | 1 line-targeted STRIP each |
| 12 | `project-template/skills/boundary-investigation/SKILL.md` | 1 line-targeted STRIP (fence-invisible) |
| 13 | `supporting-docs/INSTALL-PROCEDURES.md` | 2 line-targeted STRIPs |
| 14 | `supporting-docs/METHODOLOGY.md` | 1 line-targeted STRIP-by-reword |

**Check 70's axis bijection is unchanged** — no axis is added or removed from the client gate.

**Measured record counts (EP-9):** `project-template/scripts/.docs-gate-allowlist.txt` carries **13**
`target:` records and **81** `snippet:` records today → **19 + 81 = 100** after W4, which is the
figure L3 reports.

### 7.2 Edit 1 — Check 43's self-tree leg

**The constant MUST be new. This is binding and it is measured.** Adding `project-template/` to
`_CHECK_43_PACK_INTERNAL_PREFIXES` (measured value at HEAD: `("maintenance-docs/", "pack-ops/")`)
introduces **130 new FAILures across 26 legitimate basenames**, because that tuple feeds not only
the qualified-prefix leg (`:2571`) but also the **bare-ref class test** (`:2650`) — and every
client-shipped file lives under `project-template/` in the pack repo. (It also feeds the
precompiled-pattern dict at `:2311`; three consumers, not two — §2.7.)

```python
# Qualified prefixes that are pack-internal when cited from a CLIENT-INSTALLED
# file (a client install has no project-template/ directory, so such a path is
# dead at every install). Deliberately NOT merged into
# _CHECK_43_PACK_INTERNAL_PREFIXES: that tuple ALSO feeds the bare-ref class
# test, where project-template/ would make every client-shipped basename a
# pack-internal target (measured: 130 new FAILures across 26 basenames).
_CHECK_43_SELF_TREE_PREFIXES = ("project-template/",)

_CHECK_43_SELF_TREE_PREFIX_PATTERNS = {
    prefix: re.compile(
        re.escape(prefix) + r"([A-Za-z0-9_/\.-]+(?:\.[A-Za-z0-9]+)+)"
    )
    for prefix in _CHECK_43_SELF_TREE_PREFIXES
}
```
Patterns are **module-precompiled**, not built per line × prefix (`ci-check-runtime-compounding`).
Both names go in `__all__`.

The leg, inside Check 43's existing per-line loop:
```python
for prefix in _CHECK_43_SELF_TREE_PREFIXES:
    for m in _CHECK_43_SELF_TREE_PREFIX_PATTERNS[prefix].finditer(line):
        full_target = prefix + m.group(1)
        if full_target == rel_posix:
            continue                               # self-provenance banner
        if _check_43_context_has_anchor(stripped_lines, lineno):
            hits_anchor += 1
            continue
        fail(...)
```

**ROI-1 = (b): the leg runs on the WHOLE walk. There is NO `rel_posix.startswith(prefix)` guard.
[BINDING]** Check 43's walk IS the client-installed surface, so every walked file is a surface where
a `project-template/…` path is dead. The `startswith` scoping the superseded design invented
silently dropped 3 live occurrences in the two client-installed `supporting-docs/` files
(`METHODOLOGY.md:1984`, `INSTALL-PROCEDURES.md:1336`, `:1367`). Measured, replicated independently
by the adversarial pass: narrow scans **179** files and catches **11**; wide scans **181** and
catches **14**; carve-outs **5**; fenced-skipped occurrences **1**; post-STRIP residue **0**
(9 STRIPs + 5 carve-outs = 14).

**The `target == citing file` carve-out, exactly sized to 5.** All 5 KEEPs are the
`*Copied from: project-template/<self-path>*` provenance banner, hand-authored in exactly 5 shipped
files, with no generator and no assertion anywhere:
`project-template/AGENTS.md:20`, `project-template/CLAUDE.md:22`, `project-template/GEMINI.md:18`,
`project-template/docs/pack/PACK-FEEDBACK.md:28`, `project-template/docs/pack/PM-CHAT.md:23`.
They are source attribution, not actionable pointers, and they stay accurate at a client install
(they name where the file was copied FROM). The carve-out cannot over-reach: equality with the
citing file's own repo-relative path means the reference is right.

**Post-fix residue: 0.** The four-cell measurement proves both halves are load-bearing — carve-out
alone leaves 9, STRIPs alone leave 5, together 0.

### 7.3 [BINDING] The banner / STRIP-target collision — the reason no tree-wide replace is allowed

`project-template/docs/pack/PM-CHAT.md` carries its own `*Copied from:*` provenance banner at line 23
**and** its own path is the string being stripped at `supporting-docs/INSTALL-PROCEDURES.md:1336`. A
tree-wide `sed` / find-replace of `project-template/docs/pack/PM-CHAT.md` → `docs/pack/PM-CHAT.md`
would silently rewrite that banner into a falsehood — it would then claim the file was copied from
`docs/pack/PM-CHAT.md` — and **every gate would stay green**, because a rewritten banner simply
stops matching the carve-out. The identical shape applies to
`project-template/docs/pack/PACK-FEEDBACK.md` (banner at `:28`, path cited from
`supporting-docs/METHODOLOGY.md:1984`).

Measured: a global-replace projection yields `FAIL=0 carved=4` — one banner destroyed, gate green.
The line-targeted projection yields `FAIL=0 carved=5`.

**Therefore: every STRIP in W4 is a LINE-TARGETED edit at the exact coordinate in §7.4. No tree-wide
find/replace of any `project-template/…` path string.** This is not an open item — it has one
correct answer — but a green gate does not catch the mistake, so it is stated as a constraint.

### 7.4 The 10 client STRIPs — client coordinate, PACK-SOURCE coordinate, and the fix

All 10 coordinates were re-verified at the PACK-SOURCE path and the line numbers hold
unchanged (EP-12) — the install is a copy, so client line == pack-source line. The adversarial pass
applied all 10 at these coordinates with **0 misses**, including the `METHODOLOGY.md:1984` reword.

| # | edit THIS pack-source file:line | cited (client view) | reference to strip | rewrite to |
|---:|---|---|---|---|
| 1 | `project-template/.claude/agents/auditor-architecture.md:37` | `.claude/agents/auditor-architecture.md:37` | `project-template/skills/audit-methodology/SKILL.md` | `skills/audit-methodology/SKILL.md` |
| 2 | `project-template/.claude/agents/auditor-ops.md:31` | `.claude/agents/auditor-ops.md:31` | `project-template/skills/audit-methodology/SKILL.md` | `skills/audit-methodology/SKILL.md` |
| 3 | `project-template/.codex/agents/auditor-architecture.toml:19` | `.codex/agents/auditor-architecture.toml:19` | `project-template/skills/audit-methodology/SKILL.md` | `skills/audit-methodology/SKILL.md` |
| 4 | `project-template/.codex/agents/auditor-ops.toml:19` | `.codex/agents/auditor-ops.toml:19` | `project-template/skills/audit-methodology/SKILL.md` | `skills/audit-methodology/SKILL.md` |
| 5 | `project-template/.agents-plugin/optiquity-agents/agents/auditor-architecture.md:41` | `.agents-plugin/optiquity-agents/agents/auditor-architecture.md:41` | `project-template/skills/audit-methodology/SKILL.md` | `skills/audit-methodology/SKILL.md` |
| 6 | `project-template/.agents-plugin/optiquity-agents/agents/auditor-ops.md:35` | `.agents-plugin/optiquity-agents/agents/auditor-ops.md:35` | `project-template/skills/audit-methodology/SKILL.md` | `skills/audit-methodology/SKILL.md` |
| 7 | `supporting-docs/INSTALL-PROCEDURES.md:1336` | `docs/pack/INSTALL-PROCEDURES.md:1336` | `project-template/docs/pack/PM-CHAT.md` | `docs/pack/PM-CHAT.md` (edit the pack source `supporting-docs/INSTALL-PROCEDURES.md`) |
| 8 | `supporting-docs/INSTALL-PROCEDURES.md:1367` | `docs/pack/INSTALL-PROCEDURES.md:1367` | `project-template/docs/pack/prompts/pm-chat.md` | `docs/pack/prompts/pm-chat.md` (edit `supporting-docs/INSTALL-PROCEDURES.md`) |
| 9 | `supporting-docs/METHODOLOGY.md:1984` | `docs/pack/METHODOLOGY.md:1984` | `project-template/docs/pack/PACK-FEEDBACK.md` | reword: drop the pack-storage path (the preceding sentence already gives the client path `docs/pack/PACK-FEEDBACK.md`); e.g. "The template ships with the pack." (edit `supporting-docs/METHODOLOGY.md`) |
| 10 | `project-template/skills/boundary-investigation/SKILL.md:107` | `skills/boundary-investigation/SKILL.md:107` | `project-template/docs/pack/OPTIONAL-FEATURES.md` | `docs/pack/OPTIONAL-FEATURES.md` |

**Classes, for the commit message:**

| Class | Occ | Action |
|---|---:|---|
| Pack-storage path, actionable pointer, citer under `project-template/` | 6 | → `skills/audit-methodology/SKILL.md` in the 6 auditor agent files |
| Pack-storage path, actionable pointer, citer a client-installed `supporting-docs/` file | 2 | → `docs/pack/PM-CHAT.md`, `docs/pack/prompts/pm-chat.md` |
| Pack-storage path, redundant sentence | 1 | reword `supporting-docs/METHODOLOGY.md:1984` to drop the path |
| Pack-storage path, deny-list-fenced (no gate sees it) — **ROI-5 = (a)** | 1 | `project-template/skills/boundary-investigation/SKILL.md:107` → `docs/pack/OPTIONAL-FEATURES.md`; **content fix, no new guard** |

**ROI-5 = (a) is settled: fix the one fenced instance as content, add NO new guard.** The measured
population is 1 defect among 18 fenced qualified refs; the other 3 allow-side refs are correct. A
guard would need a 3-entry allowlist for a 1-instance population.

### 7.5 The 6 new `target:` records (13 → 19)

| # | `target:` (as authored) | occ | `reason:` |
|---:|---|---:|---|
| 1 | `scripts/proto-gen.sh` | 1 | conditionally-installed proto script — init-project.sh stage S9 removes it when no proto marker is detected; the citing prose is explicitly proto-scoped, so the reference is correct when the file is present and absent-by-design otherwise. |
| 2 | `scripts/format-swift.sh` | 3 | conditionally-installed Swift script — init-project.sh stage S9 removes it when no Swift marker is detected; the citing prose is explicitly Swift-scoped, so the reference is correct when the file is present and absent-by-design otherwise. |
| 3 | `scripts/test-python.sh` | 1 | conditionally-installed Python script — init-project.sh stage S9 removes it when no Python marker is detected; the citing prose is explicitly Python-scoped, so the reference is correct when the file is present and absent-by-design otherwise. |
| 4 | `scripts/test-swift.sh` | 7 | conditionally-installed Swift script — init-project.sh stage S9 removes it when no Swift marker is detected; the citing prose is explicitly Swift-scoped, so the reference is correct when the file is present and absent-by-design otherwise. |
| 5 | `scripts/validate-swift.sh` | 6 | conditionally-installed Swift script — init-project.sh stage S9 removes it when no Swift marker is detected; the citing prose is explicitly Swift-scoped, so the reference is correct when the file is present and absent-by-design otherwise. |
| 6 | `supporting-docs/METHODOLOGY.md` | 1 | **[BINDING wording — see below]** `pack-repo SSOT self-banner — this doc names its own single-source-of-truth location in the pack repo. Pack-side that line clears on Check 43's "in the pack repo" anchor; the client gate's DANGLING_ANCHORS carries no pack-repo anchor, and adding one would clear 6 measured lines to fix 1, so the exactly-sized resolution is this record.` |

**[BINDING] Record 6's `reason:` prose is LOAD-BEARING for a PACK-side gate. Do not reword it.**
This is the sharpest trap in W4 and nothing in the record's own semantics reveals it.

`project-template/scripts/.docs-gate-allowlist.txt` lives under `project-template/`, so it is inside
**Check 43's** walk — verified: `_iter_client_installed_files()` returns it explicitly (EP-9) — and
`.txt` is in Check 43's extension set (`_CHECK_40_FILE_EXTS = md|sh|py|toml|yml|yaml|json|txt`).
Check 43 FAILs **any** literal `supporting-docs/<X>.<ext>` substring on a walked file
(`boundary_refs.py:2449–2489`, the pre-install-only leg), unless `_check_43_context_has_anchor`
clears it within ±2 lines. So the `target: supporting-docs/METHODOLOGY.md` line is itself a Check-43
hit, and the ONLY thing clearing it is the anchor token in the `reason:` prose two lines away.

Measured, in-process against the real `_check_43_context_has_anchor` (EP-19):

```
reason: BD-288 probe record.                                    -> anchor_cleared = False   (Check 43 FAILs)
reason: pack-repo SSOT self-banner ... in the pack repo ...     -> anchor_cleared = True    (clears)
reason: conditionally-shipped pack-side SSOT doc; the client
        install has no supporting-docs/ directory ...           -> anchor_cleared = False   (Check 43 FAILs)
_CHECK_43_ANCHOR_PHRASES = ('in the pack repo','at the pack repo','pack-repo','in the project',
                            'at the client','post-install','does not exist','archived')
_CHECK_43_ANCHOR_WINDOW = 2   (window is lowercased and joined, so casing does not matter)
```

The third variant is exactly the kind of "clearer" rewording a reviewer would suggest, and it reds
Check 43 at a line whose semantics give no hint why. **The `reason:` must contain `pack-repo` or
`in the pack repo` within ±2 lines of the `target:` line.** If it is hard-wrapped, the anchor may
sit on any line inside the window. §7.10's gate asserts this explicitly.

**Why the record cannot avoid the collision.** The token the client gate must match IS
`supporting-docs/METHODOLOGY.md`, because that is the exact string cited at
`docs/pack/METHODOLOGY.md:12` (verified: *"One copy of this file lives at
`supporting-docs/METHODOLOGY.md` in the pack repo."*). Changing the `target:` breaks the record.
Adding `supporting-docs/` to a Check-43 exemption would weaken a live guard tree-wide to accommodate
one record. Constraining the `reason:` wording is the cheapest correct answer.

Backing citers, measured — every record is referenced by ≥1 corpus doc, so L3's bidirectional
liveness leg accepts all six:

- `scripts/proto-gen.sh` — `docs/pack/prompts/pm-chat.md:122`
- `scripts/format-swift.sh` — `docs/pack/INSTALL-PROCEDURES.md:1126`, `:1348`, `docs/pack/prompts/pm-chat.md:109`
- `scripts/test-python.sh` — `docs/pack/OPTIONAL-FEATURES.md:382`
- `scripts/test-swift.sh` — `AGENTS.md:273`, `CLAUDE.md:288`, `GEMINI.md:284`, `docs/pack/INSTALL-PROCEDURES.md:1125`, `:1348`, `docs/pack/OPTIONAL-FEATURES.md:382`, `docs/pack/prompts/pm-chat.md:104`
- `scripts/validate-swift.sh` — `AGENTS.md:272`, `CLAUDE.md:287`, `GEMINI.md:283`, `docs/pack/INSTALL-PROCEDURES.md:1124`, `:1347`, `docs/pack/prompts/pm-chat.md:104`
- `supporting-docs/METHODOLOGY.md` — `docs/pack/METHODOLOGY.md:12`

**Authoring form for `scripts/proto-gen.sh` — resolved here, because the artifact is ambiguous.**
The triage records this reference as `./scripts/proto-gen.sh` (that is how
`docs/pack/prompts/pm-chat.md:122` cites it). Author the `target:` record **without** the `./`
prefix: `target: scripts/proto-gen.sh`. Both forms work after the fix (the ref side strips `./` from
the reference and the allowlist side strips `./` from the record, so they meet at the same string),
but the unprefixed form matches the shape of the 11 existing non-dot-directory records — only
genuine dot-DIRECTORY targets (`.agents/mcp_config.json`, `.pack-migration-backup/…`) carry a
leading dot, and after the fix that dot is preserved rather than eaten. Keeping `./` on a record
would make the file look as though a leading `./` were meaningful.

### 7.6 Edit 3 — `project-template/scripts/validate-docs.sh`, three lock-step fixes

**All three move in the same commit. [BINDING]** Today the ref-side and allowlist-side bugs
*cancel*: both sides mangle identically, so dot-prefixed records still match. Fix two of three and
**2 live `target:` records go dead** — measured, the two occurrences that appear only in that
configuration:
```
docs/pack/INSTALL-PROCEDURES.md:856  `.pack-migration-backup/v9.3-to-v10.0/reconcile-checklist.md` does not resolve
skills/pm-startup/SKILL.md:139       `.agents/mcp_config.json` does not resolve
```
Both have live records in **`project-template/scripts/.docs-gate-allowlist.txt`** — measured at
`:501` and `:522`; 2 of the 13 records are dot-prefixed (EP-9). (**Note:** the superseded plan named
this file `pack-ops/.docs-gate-allowlist.txt`, which does not exist — §2.7.)

| # | Site (measured at `47f8467`) | Current | Fixed |
|---:|---|---|---|
| 1 | `:424` ref side, in the dangling axis | `norm = ref.lstrip("./")` | `norm = ref[2:] if ref.startswith("./") else ref` |
| 2 | `:180` allowlist side, in `_commit_record` | `dangling_targets.add(target.lstrip("./"))` | `dangling_targets.add(target[2:] if target.startswith("./") else target)` |
| 3 | `:426` fallback | `if norm in relpaths or base in basenames:` | `if norm in relpaths:` |

`lstrip("./")` is a **character-class** strip, not a prefix strip: it eats every leading `.` and `/`
character, so `.claude/settings.json` becomes `claude/settings.json`. That is the bug.

**Fix 3 has a 10-site deletion tail.** Once `or base in basenames` goes, `basenames` has no consumer
and is deleted along with its return value, per `fail-loud-delete-old-source`.

**Provenance note, corrected.** The superseded plan attributed this table to
`git grep -n basenames project-template/scripts/validate-docs.sh` minus two prose hits. Measured
(EP-9), that grep returns **11** lines: 9 code sites (283, 289, 291, 371, 426, 441, 446, 1933, 1934)
plus the 2 prose hits at `:531` and `:1306`. The table's tenth row, `:425`, matches **`base`**, not
`basenames` — it is dead code once the fallback goes, found by reading the function rather than by
that grep. The table's CONTENT is complete and correct; only its stated provenance was wrong. Use
the table, not the grep.

| Line | Current | After |
|---:|---|---|
| 283 | `basenames = set()` | delete |
| 289 | `basenames.add(fn)` | delete |
| 291 | `return basenames, relpaths` | `return relpaths` |
| 371 | `def scan_doc(rel, root, by_doc, dangling_targets, basenames, relpaths):` | drop the `basenames` parameter |
| 425 | `base = os.path.basename(ref)` | delete (dead once the fallback goes; matches `base`, not `basenames`) |
| 426 | `if norm in relpaths or base in basenames:` | `if norm in relpaths:` |
| 441 | `basenames, relpaths = build_index(root)` | `relpaths = build_index(root)` |
| 446 | `basenames, relpaths))` (the `scan_doc` call at `:445–446`) | drop the argument |
| 1933 | `basenames, relpaths = build_index(td)` (inside `run_selftest`) | `relpaths = build_index(td)` |
| 1934 | `fails = scan_doc(fname, td, {}, set(), basenames, relpaths)` | drop the argument |

Miss `:1933–1934` and `--self-test` raises `NameError` at run time while the main scan is green —
`validate-docs.sh --self-test` is in W4's gate precisely to catch that.

**Edit 3b — bound the walk.** Keep `os.walk` (see below) but prune in place at `:284–290`:
```python
PRUNE = {".git", ".build", "build", "dist", "node_modules", ".venv", "venv",
         "DerivedData", "__pycache__", ".mypy_cache", ".ruff_cache"}
for dp, dns, fns in os.walk(root):
    dns[:] = [d for d in dns if d not in PRUNE]
```
`.pack-migration-backup/` is deliberately **NOT** pruned — there is a live allowlisted reference into
it (`docs/pack/INSTALL-PROCEDURES.md:856`).

**The client walk stays filesystem-derived. [BINDING] Do NOT apply the pack's `git ls-files`
answer here.** The pack's own test says why, verbatim at
`scripts/tests/test-validate-docs-template-fullscan.sh:10–14`: *"the gate globs the live tree, so a
new not-yet-tracked template doc is scanned exactly as a client install would scan it (a
`git ls-files` staging would silently exclude it)."* A freshly installed client may not be a git
work tree at all. The client gate also needs no leg A / leg B: at a client install the client's
paths ARE the install paths. This is `dependency-direction-placement` and P-missed-7 working as
intended — mirror-but-customize, not a shared mechanism. **Note the deliberate asymmetry with
§6.2**, where the PACK-side check MUST intersect with the tracked set: the two surfaces have
different truth conditions, and this plan applies each rule where it belongs rather than uniformly.

### 7.7 Edit 3c — `--self-test` bite legs, one per fixed defect

`run_selftest()` (`:1908`) has a `gate(text, expect_fail, label, fname="CLAUDE.md")` helper that
writes ONE file into a `tempfile.TemporaryDirectory()`, builds the index, and runs `scan_doc`. Extend
it with two optional parameters — `extra_files: dict[relpath, content] | None` (seeded into the temp
tree before indexing) and `targets: set[str] | None` (passed as `dangling_targets`) — then add:

| Leg | Setup | Assert | Proves |
|---|---|---|---|
| **fallback bite** | doc cites `` `docs/WRONGDIR/PM-CHAT.md` ``; extra file `docs/pack/PM-CHAT.md` exists | **FAIL** | the wrong-path-but-basename-exists reference no longer resolves vacuously — the BD's originating mechanism |
| **moved-file bite** | doc cites `` `docs/pack/MOVED-AWAY.md` ``; no such file | **FAIL** | plain dead pointer still caught |
| **dot-dir PASS** | doc cites `` `.claude/settings.json` ``; extra file `.claude/settings.json` exists | **PASS** | the ref-side prefix strip is correct — under `lstrip("./")` this resolves to `claude/settings.json`, misses `relpaths`, and (with the fallback gone) would FAIL |
| **dot-dir bite** | doc cites `` `.claude/NOPE/settings.json` ``; no such file | **FAIL** | the prefix strip did not become a blanket pass |
| **dot-dir allowlist** | doc cites `` `.agents/mcp_config.json` ``, no such file, `targets={".agents/mcp_config.json"}` | **PASS** | the allowlist-side prefix strip preserves the leading dot — this is the leg that would have caught fixing 2 of 3 sites |

The third and fifth legs are the ones that distinguish a correct three-site fix from a
two-site one. Without them a partial fix passes `--self-test`. **Measured: `--self-test` returns
`rc=0` both BEFORE and AFTER the three-site fix with none of these legs present** — the exit code
alone proves nothing, which is why §7.11 marks reading the legs as the wave's strain point.

### 7.8 Edit 5 — `test-validate-docs-template-fullscan.sh`

**(a) L8, the S9 install-profile matrix (ROI-2 = (b)).** ~29 substantive lines. It reuses L5's
already-staged `$INSTALL_ROOT`, the existing `FIXTURE_BASE="$(mktemp -d
"${TMPDIR:-/tmp}/test-vdocs-fullscan.XXXXXX")"` root (`:79`, already Check-92-portable), the existing
`trap 'rm -rf "$FIXTURE_BASE"' EXIT` (`:80`), and the existing `fail()` / `pass()` counters
(`:84`, `:89`). **It introduces no new infrastructure and no new `mktemp`.**

For each S9 language profile, copy `$INSTALL_ROOT`, delete exactly the paths
`stage_s9_conditional_remove` (`scripts/init-project.sh:1113–1200`) names for that profile, run the
shipped gate, and assert `rc=0`:

| Profile | S9 removals | expected |
|---|---|---|
| keepall | none | `rc=0`, dangling 0 |
| swift-only | python + proto sets | `rc=0`, dangling 0 |
| python-only | swift + proto sets | `rc=0`, dangling 0 |
| swift+py | proto set | `rc=0`, dangling 0 |
| py+proto | swift set | `rc=0`, dangling 0 |
| swift+proto | python set | `rc=0`, dangling 0 |
| none-detected | all three sets | `rc=0`, dangling 0 |

Add a comment in the leg naming `stage_s9_conditional_remove` as the roster's source, so a future S9
change that desyncs is visible at the diff.

**Why this leg exists, with the worst case corrected.** The S6 overlay keeps every conditional file,
so an overlay-only measurement is **structurally blind** to every reference into a removed file.
**The worst-case profile is `none-detected`, not `python-only`** — the superseded plan named
python-only. The correction is a proof, not just a count: reading
`stage_s9_conditional_remove` (measured, EP-9), `none-detected` removes the python set ∪ the swift
set ∪ the proto set, while `python-only` removes only the swift ∪ proto sets. The former is a strict
SUPERSET, so `dangling(none-detected) ≥ dangling(python-only)` necessarily, with strict inequality
iff at least one live reference targets a python-set path — and there is one:
`scripts/test-python.sh`, cited at `project-template/docs/pack/OPTIONAL-FEATURES.md:382` (verified).
The adversarial pass measured the gap at exactly one occurrence (python-only 18, none-detected 19
with the original 13 records; 27 and 28 counting the 9 gate-visible STRIPs). **Nothing rests on the
magnitude** — all 7 profiles are `rc=0 dangling=0` post-fix — but state the profile correctly, since
§7.8 uses it to justify L8's roster.

**Pre-audited clean:** no `grep -c … || echo 0`, no hardcoded `/Users/`/`/home/`/`~/` path, no live
`gh` call (Check 83's three classes); no `mktemp` invocation at all (Check 92 N/A). Test length
308 → ~344 lines.

**(b) L3's `lstrip` mirror fix (§2.4).** At `:208`, change
`norm = target.lstrip("./")` → `norm = target[2:] if target.startswith("./") else target`. One line.
The leg's own comment claims it parses *"with the gate's exact grammar … (mirror of
load_allowlist/_commit_record)"*; after Edit 3 the gate uses a prefix strip, so leaving the test's
character-class strip makes that comment false. Benign today (L3 does substring containment, so no
record is falsely reported dead) — fixed for mirror honesty, in the same commit as the thing it
mirrors.

**(c) L3 accepts the 6 new records with no other change** — every one is referenced by ≥1 corpus doc
(§7.5), and the corpus includes the two overlay SOURCES via `OVERLAY_MAP`, which is where
`docs/pack/METHODOLOGY.md:12`'s `supporting-docs/METHODOLOGY.md` citation lives. L1, L5, L7 stay
green unchanged. Verified end-to-end by the adversarial pass: `7/7 legs`, L3 reporting
`100 records (81 snippet + 19 target) against 121 corpus docs; 0 dead`.

### 7.9 Intra-wave ordering — [BINDING]

```
  1. the 3 validate-docs.sh lock-step fixes + the basenames deletion tail + the walk prune
  2. the 6 target: records                                   ← MUST accompany 1 (and precede any run)
  3. the 10 line-targeted client STRIPs                      ← MUST accompany 1
  4. Check 43's self-tree leg + constants + __all__
  5. --self-test bite legs
  6. test-validate-pack-check-43.sh legs
  7. test-validate-docs-template-fullscan.sh: L8 + the L3 lstrip line
```

Three orderings are load-bearing:

- **Steps 1, 2 and 3 are one atomic set.** Fixing the gate without the STRIPs and the records makes
  the client gate report failures on every profile — measured by the adversarial pass at exactly the
  10 §7.10 predicts on the overlay, by path, and up to 19 on `none-detected` with the original 13
  records. The guard and its fix-set are one commit.
- **All three `lstrip`/fallback sites in step 1 together.** Two of three kills 2 live records
  (§7.6).
- **Step 3 precedes any client-gate run.** More sharply: **the 6 `target:` records must be in place
  before the STRIPs are evaluated**, or the S9-conditional KEEPs surface as failures and mask
  whether the STRIPs landed. Author the records first within step 2/3.

### 7.10 Verification gate

| Item | Expected |
|---|---|
| `python3 scripts/validate-pack.py` | exit 0, `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 …` | exit 0 |
| **Check 43** | green; the self-tree leg reports **0** FAIL with **5** carve-out clears; **181** files walked, 14 wide occurrences |
| **Check 43, record-6 anchor assertion [BINDING]** | after the 6 `target:` records land, re-run Check 43 and confirm green. If it FAILs at `project-template/scripts/.docs-gate-allowlist.txt:<line of record 6>`, the `reason:` prose lost its `pack-repo` / `in the pack repo` anchor — restore it (§7.5). **Re-verify after ANY reword of that reason.** |
| Check 41 / 47 | green (untouched by W4) |
| Check 70 | green — axis markers + wiring unchanged |
| Check 85 | green — the session-state narration twins are untouched by the dangling-axis edits, but W4 edits `validate-docs.sh` so this runs |
| Check 93 | green — the STRIPs replace pack-storage paths with client paths on client surfaces, which is the direction the rule wants |
| Check 92 / 83 | green on the edited fullscan test |
| `bash project-template/scripts/validate-docs.sh --self-test` | exit 0, **with the 5 new bite legs present** — the exit code alone is not evidence (§7.7) |
| `bash scripts/tests/test-validate-pack-check-43.sh` | all groups pass, incl. the 4 new legs |
| `bash scripts/tests/test-validate-docs-template-fullscan.sh` | **8 legs** (L1–L7 + L8), all pass; L3 line reports **19** target records / 100 total, **0** dead |
| `--assert-coverage`, `build.sh --verify` | green |

**Check 43's four new test legs [BINDING on leg (ii)]:**

| Leg | Fixture | Assert |
|---|---|---|
| (i) | a `project-template/…` cite from a `project-template/` citer | **FAILs** |
| (ii) | a `project-template/…` cite from a **client-installed `supporting-docs/` citer** | **FAILs** |
| (iii) | a `*Copied from: project-template/<self-path>*` banner whose target == the citing file | **cleared** by the carve-out |
| (iv) | mutation: remove the `target == citing file` carve-out | the 5 self-provenance banners FAIL |

**Leg (ii) is the one that proves ROI-1 = (b) landed, and it is easy to write vacuously.** Under the
superseded narrow conditional it passes trivially (the citer is not under `project-template/`, so
the leg never runs). Under the decided wide conditional it FAILs. It is the only assertion that
distinguishes the two designs — if a coder writes leg (i) and skips leg (ii), a later reviewer
cannot tell which conditional shipped.

**Client-gate bite probes, run against the real shipped gate on staged trees, not inspected
[BINDING]:**

| Probe | Assert |
|---|---|
| A — moved-file ref | `docs/pack/MOVED-AWAY.md` does not resolve → FAIL |
| B — wrong path, basename exists (**the BD's originating mechanism**) | `docs/WRONGDIR/PM-CHAT.md` does not resolve → FAIL |
| C — the same reference on the **UNPATCHED** gate | `PASS — operating docs clean` (this is the `declare-verify-backing` proof: the shipped gate passes it *vacuously*) |
| D — dot-directory ref | `.claude/NOPE/settings.json` does not resolve → FAIL |
| E — restore `or base in basenames` | probe B flips to PASS |

**Post-fix green on 8 trees** — the bare template plus all 7 install profiles, each `rc=0
dangling=0`. Independently measured by the adversarial pass on a staged install tree with the real
shipped gate; this is the measurement L8 converts into a standing guarantee.

### 7.11 Bounded-cycle fit

**FITS, with L8 included.** An earlier adversarial verdict that this wave could not absorb one cycle
was correct *as the wave then stood*, and the reason was specific: 32 of 61 client occurrences were
described as *"triage individually"* / *"resolve during implementation"* — open discovery inside a
commit. That is gone:

1. **All 29 client occurrences carry a design-time verdict, a fix recipe, and the profiles they
   appear on.** Nothing is left to resolve during implementation. Both tables are in §7.4 and §7.5
   with pack-source coordinates verified against the tree (EP-12).
2. **The post-fix state is verified, not projected** — the real patched gate ran on 8 trees and
   returned `rc=0 dangling=0` on every one, with each of the six records backed by at least one
   profile in which its absence FAILs.
3. **W4 is smaller than W3** — 14 files against 24, and 10 of the 14 changes are single-line STRIPs
   at given coordinates.
4. **L8 adds ~29 substantive lines and no infrastructure**, reusing L5's `$INSTALL_ROOT`, the
   existing portable `mktemp` root, the existing trap and the existing counters; its profile roster
   is one already executed.
5. **ROI-1 = (b) made the wave simpler** — dropping the `startswith` guard removes a conditional and
   its edge case, and the 3 extra occurrences it catches were already in the wave's STRIP set as
   client-gate fixes.

**The two strain points, named.**
- The three-site `lstrip`/fallback change with its 10-site `basenames` deletion tail, plus the 5
  `--self-test` bite legs, is the most intricate code in the BD. A reviewer **must read the
  `--self-test` legs** rather than trust the exit code: an exit-0 `--self-test` with the dot-dir
  PASS leg missing is exactly the state a two-of-three fix produces.
- **Record 6's `reason:` wording** (§7.5). It is one line of prose holding a pack gate green, and it
  is the one item in W4 a well-intentioned improvement will break.

**Fallback if W4 strains** (do not take pre-emptively): **W4a** = Check 43's self-tree leg + its test
+ the 9 pack-side STRIPs (the leg is green on its own); **W4b** = the client gate + its allowlist +
L8. Both boundaries green; W4b keeps the client fix-set with its guard.

### 7.12 Commit shape

**Subject:** `fix: v11 — BD-288 Check 43 self-tree leg + client doc-gate three-site hardening`

**Scope keyword: NONE is claimable. [BINDING]** W4 touches `project-template/` (8 files),
`supporting-docs/` (2), AND pack-side `boundary_refs.py` + 2 test files — so neither `pack-only` nor
`project-only` holds, and `pack-chat-only` is unavailable. Say so in the message.

**The message must record:**
- the defect: seven-plus references on client-shipped surfaces citing `project-template/`-prefixed
  paths that are dead at every client install, invisible to Check 68 (they exist in the pack repo)
  and to Check 43 (whose pack-internal prefixes were `maintenance-docs/` and `pack-ops/` only).
- **why the constant is new**, with the measured 130-new-FAILures figure and the three-consumer
  reason (the shared tuple also feeds the bare-ref class test).
- **ROI-1 = (b)**: the leg runs on the whole walk, no citer scoping; 179→181 files, 11→14
  occurrences, the 3 that the narrow form dropped named by path.
- the carve-out, sized to exactly 5, with the 5 banner files named and the reason equality is safe.
- **the banner/STRIP-target collision** and the fact that every STRIP was line-targeted because of
  it — including that a global replace leaves the gate green while destroying a banner.
- **all three `lstrip`/fallback sites**, with the measured consequence of fixing only two (2 live
  `target:` records go dead, both named) — and the fourth surface, the pack-side test's mirror line.
- why the client walk stays filesystem-derived, quoting the pack's own test comment, **and why the
  pack-side Check 95 does the opposite** — different surfaces, different truth conditions.
- the 10 STRIPs and 6 `target:` records (13 → 19 target / 100 total), with the pack-repo-anchor
  decision: a `target:` record rather than widening `DANGLING_ANCHORS`, because adding a pack-repo
  anchor would clear 6 measured lines to fix 1.
- **that record 6's `reason:` prose is load-bearing for Check 43**, with the measured three-variant
  result, so a future reword is not attempted blind.
- **ROI-5 = (a)**: the fenced instance fixed as content, no new guard, with the 1-of-18 population.
- L8 and what it guarantees, naming `none-detected` as the worst-case profile with the
  superset-of-removals reason.
- probes A–E stated as run, and probe C called out as the `declare-verify-backing` proof.
- that no scope keyword is claimed and why.

---
## 8. Per-wave rollback position

The bounded cycle is **max 2 review/fix pairs + 1 final reviewer pass = 3 reviewer spawns / 2
fix-coder spawns per commit**. If the tree is still dirty after the final reviewer pass, the cycle
STOPS — there is no fix-coder pass 3 — and Pack Chat spawns `pack-architect` to diagnose root cause
and propose a path forward.

**What is true of every wave when that happens.** The work lives in the commit's isolated worktree
and **nothing has reached the canonical tree** — RW agents produce no patch on return; the patch is
produced only after a reviewer confirms the work CLEAN, at which point Pack Chat SendMessages the
most-recent RW agent for `git diff > <handoff>/changes.patch`, then applies and commits with user
approval. So a twice-dirty wave leaves: canonical unchanged and green at the wave's base SHA; the
worktree carrying partial work; **the worktree KEPT** (a failed or aborted commit keeps it as the
recovery fallback — never torn down on failure, never left to auto-removal). The next actor is
`pack-architect`, reading the worktree in place.

| Wave | Canonical state if twice dirty | Worktree state | Next actor's first question |
|---|---|---|---|
| **W1** | at base SHA, green. W2/W3/W4 are unaffected — W1 shares no file with any of them, so the critical path continues without it | `cross_bd.py` + `test-…-81.sh` + `test-…-82.sh` partial | Which of the two edits is dirty? They are **separable** (§4.7): edit (a) the `active[]` shape leg + T7/T8/T9, edit (b) the path-token char class + T10/T6. Either lands green alone. Prefer reducing to one edit over abandoning the wave — but do NOT ship (a) alone as the final state, since that is the guard-blind-to-dotfiles outcome folding (b) in exists to prevent |
| **W2** | at base SHA, green. **W3 and W4 are BLOCKED** — both need `boundary_refs.py` | ladder / helper / scope / NOI-1 / allowlist / 3 SKILL.md copies partial | Which sub-change is dirty? See the decomposition constraint below — **(a) and (b) are NOT separable** |
| **W3** | at base SHA, green. **W4 BLOCKED** | up to 24 files partial | Take the §6.11 W3a/W3b split. Both halves are measured green at their boundary. Do NOT attempt a third fix pass on the merged wave |
| **W4** | at base SHA, green. Nothing blocked — W4 is terminal | up to 14 files partial | Take the §7.11 W4a/W4b split. If the strain is in the `--self-test` legs specifically, W4a (Check 43 leg + its test + the 9 pack-side STRIPs) is green standalone and de-risks the remainder |

**W2 decomposition constraint — corrected. [BINDING]** The superseded plan told a recovery architect
that W2's four parts "(a) ladder, (b) sibling parser, (c) tracked scope, (d) NOI-1 are separable
commits." **That is false for (a) and (b).** The ladder's leg B *is* `dest_to_source.get(token)`;
without the sibling parser there is no map, and the 39 references leg B resolves fall through to the
anchor window, then the allowlist, then FAIL. Measured (EP-17): `legA = 247, legB = 39`. Landing (a)
without (b) is a **39-failure commit**. The correct guidance:

> **(a) requires (b) — they are ONE commit.** (c) tracked scope and (d) NOI-1 are independent of
> both and of each other. The 6 allowlist records + the 2 SKILL.md STRIPs (and their 2 mirrors)
> must travel with (a)+(b), because the hardened ladder is what makes their 13 residue occurrences
> FAIL.

**One cross-wave recovery note.** Because W1 shares no file with the chain, a W1 failure never
blocks anything and a W1 rollback never invalidates W2/W3/W4 work in flight. Conversely, if W2 has
to be decomposed, the decomposition changes W3's and W4's **base SHA** but not their file sets or
their edits — re-verify §3.1's contention matrix against the new bases before resuming, since
`boundary_refs.py` is the shared file in all three.

**Live-worktree ASK gate (rule 9).** A commit's own reviewer / fix-coder is rule-fixed to that
commit's worktree — no ask. Any OTHER agent spawned while a live worktree with uncommitted work
exists means Pack Chat ASKS the user BOTH placement (which tree) AND disposition (reuse vs abandon);
it never self-decides either. With W1 running in parallel against the chain, that gate will fire.

---

## 9. Decision record — every item closed

Everything the design's §1.1 and §1.2 tables decided is closed and implemented as recorded; NOI-1 is
decided (b) and planned into W2 (§5.5). The items below are what the planning and reconciliation
passes surfaced. **All are now CLOSED** — the user's standing authorization for the remainder of
BD-288 directs that every agent recommendation be taken and every finding fixed without per-item
triage, so each item below records its context, its options, its recommendation, the decision, and
where the decision is applied. **There are no open gates on this plan.** Nothing is deferred,
nothing becomes a new BD, all of it lands in BD-288 in v11.0.

Commits are unaffected by that authorization and still require the user's explicit approval.

### D-1 (was OI-R1) — Check 95's tier-1 exemption. **DECIDED: (b).**

**Context.** §2.1: Check 95 must clear 8 basenames that `_CHECK_40_ALLOWLIST` clears today and the
26-entry `_CHECK_95_ALLOWLIST` does not — `CLAUDE.md` (30 occurrences), `GEMINI.md` (29),
`AGENTS.md` (27), `README.md` (24), `QUICKSTART.md` (1), `report.md` (1), `settings.json` (1),
`tracker.toml` (1) = **114** over the 35-file walk. Without them W3's first battery run is `rc=1`.

**Options.** **(a)** Check 95 consults `_CHECK_95_ALLOWLIST ∪ _CHECK_40_ALLOWLIST` — one `or`, and
it makes the design's EV-1 projection literally true, but the effective exemption surface becomes 44
basenames of which **10 have zero necessity** in this walk (9 with no occurrence at all, plus
`LICENSE.md` whose 3 occurrences are all cleared by tier 3), and Check 95's teeth become a function
of a constant another check owns. **(b)** Grow `_CHECK_95_ALLOWLIST` 26 → 34, each new entry with
its own Check-95-walk-scoped `reason:`; the two guards stay independent. **(c)** Qualify the 114
occurrences — rejected on measured candidate counts (`CLAUDE.md` 3 candidates, `AGENTS.md` 3,
`GEMINI.md` 2, `README.md` 6, `settings.json` 4; `report.md` and `tracker.toml` have **zero**, so
there is no path to qualify to), and it would consume Check 66's 163-character margin. **(d)** Shrink
the walk to exclude the trinity and `README.md` — rejected: BD-288's acceptance criteria name both
explicitly.

**Recommendation and DECISION: (b).** Evidence: leave-one-out measurement shows (b) is exactly sized
(zero redundant entries; necessity sum 189 == the empty-allowlist probe's FAIL count) while (a)
admits 10 keys with zero necessity — the precise thing `ci-guard-measure-then-bound` step 4 and
`declare-verify-backing` forbid; and (b) keeps the two guards independent, which is the property
§6.12's own commit rationale says the separate check exists to preserve — making Check 95's teeth a
function of `_CHECK_40_ALLOWLIST` is the same coupling hazard §6.12 uses to argue against widening
Check 40 in the first place. **Applied at** §2.1, §6.2 (tier 1 names `_CHECK_95_ALLOWLIST` only),
§6.4 (34 entries, Blocks A + B), §6.9 (the OK line and probe 1), §6.10, §6.12, §11.

### D-2 (was OI-R1's rider) — ROI-6's fact 1, restated. **DECIDED: restate, at the constant.**

**Context.** The user's ROI-6 = (a) records two facts, the first as *"the two exemption sets are
disjoint by construction."* Under D-1 the two ENTRY sets deliberately overlap on 8 basenames
(measured: today's intersection is ∅), while the property the fact protects — no
`_CHECK_95_ALLOWLIST` entry can exempt anything under `pack-ops/` — is unaffected, because it rests
on the WALKS being disjoint (measured: zero `pack-ops/` members in the 35-file walk). Left as
written, the sentence invites a maintainer to "deduplicate" the two constants and reintroduce 114
failures.

**Options.** (a) Restate to the measured form at the constant. (b) Leave the wording and rely on the
commit message. (c) Say nothing.

**Recommendation and DECISION: (a).** Evidence: the commit message is not where a maintainer editing
a constant is reading; (c) leaves a sentence that is literally false about the shipped code. **The
text to place at `_CHECK_95_ALLOWLIST`:**

> The two WALKS are disjoint by construction — Check 95's walk is Check 40's walk SUBTRACTED OUT
> (measured: zero `pack-ops/` members) — so no `_CHECK_95_ALLOWLIST` entry can exempt anything under
> `pack-ops/`. The two ENTRY sets deliberately OVERLAP on 8 basenames that both walks legitimately
> exempt; that overlap is not duplication to be removed. Check 95 does NOT consult
> `_CHECK_40_ALLOWLIST`: coupling the two would make this check's teeth a function of a constant
> owned by another check.

**Applied at** §6.4.

### D-3 (NEW) — the Check-81 path-token blind spot. **DECIDED: fold into W1 and fix.**

**Context.** `_CHECK_81_PATH_TOKEN_RE`'s first character class is `[A-Za-z0-9_]`, excluding `.`, and
the pattern is backtick-anchored — so every dot-leading backticked path in a `File/Symbol` field is
unextractable, and the cross-BD collision scan cannot see any `.claude/` / `.codex/` / `.github/`
surface (EP-25). Pre-existing; surfaced by a coder on separate work who correctly declined to fix it
without measurement, because naive widening risks false positives against backticked bare extensions.

**Options.** **(a)** Fold into W1 and fix — same guard, same defect class one layer down.
**(b)** Fix in a later wave. **(c)** Leave it and record it.

**Recommendation and DECISION: (a).** Evidence: W1's whole subject is Check 81 reaching the reality
it claims to verify; shipping only the `active[]` fix leaves a guard blind to every dotfile surface,
so W1 would ship the defect it exists to fix. (b) fails the `deferral-is-scope-creep` test — it is
not SIZE (one character), not BLOCKED, and the LOGICAL FIT argument runs the other way (this belongs
with the sibling matcher, in the file W1 already opens). (c) leaves a live guard inert on a whole
class of surfaces.

**The measurement the coder asked for, done (EP-25…EP-27).** The false-positive risk is measured
**absent**: bare extensions (`` `.md` ``, `` `.sh` ``, `` `.example` ``) still yield nothing, because the
grammar requires a `/` or a `.<ext>` after the first segment. The change is purely additive
(corpus-wide, **0** existing tokens change). The two questionable shapes that do newly tokenize are
pre-existing for non-dot spans. The blast radius is advisory-only (Check 82 has no executable
`fail()`; Check 81's TBD-marker gate runs before the token search — measured **0** structured-ness
flips). **Applied at** §4 in full; W1's cycle-fit is re-argued with the addition at §4.7.

### D-4 (was OI-R2) — the Check-68 post-fix `resolved`/`allowlisted` split. **DECIDED: (a).**

**Context.** §5.9. My replication reproduces the LIVE OK line term for term
(228 / 1830 / 1597 / 28 / 205 / 0) and projects post-W2 as 229 / 1836 / **1590** / 28 / **218** / 0.
The adversarial pass, which built W2 for real, reports the same four structural terms but the split
as **1576 / 232**. Both cannot be right; the four structural terms and the sum invariant hold in both.

**Options.** (a) State the measured projection, mark the four structural terms BINDING and the split
diagnostic, and tell the coder what a divergence means. (b) State the adversarial figure instead.
(c) Gate only on `0 dangling`.

**Recommendation and DECISION: (a).** Evidence: my replication is validated against the live printed
line term-for-term, so its ladder is faithful to the shipped check, and the projection follows from
the leg order §5.2 specifies; I tested and ruled out the likeliest divergence cause (an allowlist
escape hoisted above legs A/B — measured, **zero** legA/legB-resolvable tokens are on the allowlist,
EP-19). (c) discards real anti-vacuity value: a green Check 68 with an empty scope also reports
"0 dangling", and it is the `229 file(s) scanned` / `1836 references` pair that rules that out.
(b) would carry forward a number I cannot derive — the defect class this reconciliation exists to
remove. **Applied at** §5.9.

### D-5 (was OI-R3) — `_parse_client_installed_files()`. **DECIDED: (b), the sibling parser.**

**Context.** The design says to extend the function to return the DEST column. Measured, that changes
a 5-tuple consumed at five unpack sites — three positional — and falsifies the sibling docstring at
`:2949` (EP-2).

**Options.** (a) Widen the tuple to 6. (b) Add `_client_install_dest_to_source()` as a self-contained
sibling parser modelled on the existing `_parse_client_installed_file_stages()`. (c) Change `entries`
to a list of tuples — rejected: it silently changes the meaning of a value four call sites iterate
over.

**Recommendation and DECISION: (b).** Evidence: the file already contains the precedent; the design's
actual constraint is about a **subprocess**, and (b) adds none; measured cost 0.13 ms against a
10.0 s budget with ~7.5 s of headroom; (a)'s churn lands in three checks otherwise out of W2's scope.
The adversarial pass independently built (b) and it landed green with Checks 41/43/47 passing
unmodified, the reverse map yielding the same 29 entries I measured. **Applied at** §5.3.

### D-6 (was OI-R4) — Check 81 goes live against a file Pack Chat rewrites. **DECIDED: (a).**

**Context.** After W1, Check 81's FAIL leg fires for any BD named in `active[]` whose `File/Symbol`
is bare/TBD. Measured (EP-6): `active[]` holds one member led by `BD-288`, BD-288 is structured, the
tree is GREEN — and **seven** open BDs carry a bare/TBD field and WARN (BD-020, BD-039, BD-187,
BD-192, BD-202, BD-223, BD-279). Pack Chat REPLACES `active[]` at every state transition, so if one
of those seven lands there while W2/W3/W4 are in flight, the tree goes RED and the commit is blocked.
This is the guard biting correctly, not a defect.

**Options.** (a) Record it as an operational constraint — a pre-flight step plus a line in W1's
commit message. (b) Structure the seven WARNing BDs' fields now. (c) Do nothing.

**Recommendation and DECISION: (a).** Evidence: the risk window is small and bounded (BD-288 is the
only BD in active design for these four waves); (b) edits seven backlog entries BD-288 has no remit
over — the entry's standing constraint grows scope for work *surfaced by* BD-288, and these seven
pre-date it and are unrelated to the guard family; (c) leaves a coder debugging a red gate with no
pointer. **Applied at** §1.4 and §4.8. Note the regex fix does **not** change this set: measured
**0** structured-ness flips, so the seven WARNs are the same seven before and after (EP-26).

### D-7 (was OI-R5) — the pack-side test's third `lstrip("./")`. **DECIDED: (a), fix in W4.**

**Context.** `scripts/tests/test-validate-docs-template-fullscan.sh:208` carries the same
`lstrip("./")` in a block whose comment says it is a *"mirror of load_allowlist/_commit_record"*
(§2.4, EP-5). Benign today — L3 does substring containment — but after W4 the thing it claims to
mirror uses a prefix strip.

**Options.** (a) Fix it in W4, one line, in the same commit as the gate change it mirrors. (b) Leave
it and adjust the comment to say it is deliberately laxer. (c) Leave it entirely.

**Recommendation and DECISION: (a).** Evidence: `enumerate-encoding-surfaces` names *"every TEST that
asserts its content invariants"* as a lock-step surface, and this test explicitly declares itself the
mirror; the change is one line inside a file W4 already edits for L8; (c) leaves a false statement in
a file whose whole job is to notice drift. **Applied at** §7.8(b).

### D-8 (was OI-R6) — record 6's `reason:` prose is load-bearing for Check 43. **DECIDED: (a).**

**Context.** §7.5, measured in-process (EP-19). `target: supporting-docs/METHODOLOGY.md` sits on a
Check-43-walked surface and clears ONLY because its `reason:` prose contains an anchor phrase within
±2 lines. A neutral reason, or the "clearer" reword a reviewer would suggest, reds Check 43.

**Options.** (a) State it as a [BINDING] wording constraint and assert it in the gate, with a
re-verify instruction after any reword. (b) Write the `target:` in a form Check 43 does not flag —
**checked and impossible**: the token the client gate must match IS `supporting-docs/METHODOLOGY.md`,
the string cited at `docs/pack/METHODOLOGY.md:12`. (c) Add `supporting-docs/` to a Check-43 exemption
— rejected: weakens a live guard tree-wide for one record.

**Recommendation and DECISION: (a).** Evidence: (b) is impossible on inspection of the citing line,
(c) trades a guard's teeth for a comment, (a) costs two sentences and one gate row. The failure is
silent from the record's semantics, so the gate assertion is doing real work. **Applied at** §7.5
and §7.10.

### D-9 (was OI-R7) — the `agent-run.sh` allowlist `reason:`. **DECIDED: (a), use the corrected text.**

**Context.** The pre-derived `reason:` says *"no pack file is the referent"*, but
`git ls-files | grep agent-run.sh` returns exactly one candidate, `project-template/agent-run.sh`
(EP-20). The verdict (allowlist it) is right; the stated reason is not, and `reason:` fields are what
a reviewer re-verifies.

**Options.** (a) Use the corrected text. (b) Keep the pre-derived text.

**Recommendation and DECISION: (a).** The corrected text is written out verbatim in §6.4 and states
the true reason: every citation names the CLIENT's project-ROOT copy, and the pack trinity says
outright that the pack repo has none, so qualifying to the template path would both misdirect a
client reader and contradict the sentence it sits in. **Applied at** §6.4.

### D-10 (was OI-R8) — `boundary-investigation/SKILL.md` rows 73–74. **DECIDED: (a), rewrite, add nothing.**

**Context.** W2 rewrites two cells of a table headed "project-side SSOT" to paths outside
`project-template/`. The table's other rows all name `project-template/…` paths.

**Is that wrong?** No — checked, not assumed. Rows 70–72 name pack-storage paths that happen to live
under `project-template/`; rows 73–74 name paths that do not exist at all
(`project-template/supporting-docs/` is not even a directory, EP-11). The pack-storage path for those
two SSOTs genuinely is `supporting-docs/…`.

**Options.** (a) Rewrite the two cells and add nothing. (b) Rewrite and add a parenthetical noting
these two ship from `supporting-docs/` into `docs/pack/`.

**Recommendation and DECISION: (a).** Evidence: `operating-docs-no-history-no-bloat` requires
operating docs stay terse; the reader is a pack agent in the pack repo, for whom the pack-storage
path is the actionable one; the client twin already carries the client form. If a W2 reviewer flags
the apparent inconsistency, (b) is a one-clause answer — do not pre-empt it. **Applied at** §5.7.

### D-11 (was OI-R9) — `README.md`'s `86 numbered` and `77–94`. **DECIDED: (a), update by hand.**

**Context.** Check 80 binds only `<N> invoked checks` and `<N> registry entries total` (EP-21); its
own twin-row comment says the siblings are DIFFERENT quantities with no backing constant and are
intentionally not extracted. So W3 updates `86` → `87` and `77–94` → `77–95` by hand, and nothing
catches an omission.

**Options.** (a) Update them and rely on review. (b) Enrol them in Check 80. (c) Delete them.

**Recommendation and DECISION: (a).** Evidence: (b) is ruled out by the twin row's own reasoning —
binding a different quantity to that constant breaks the bijection, and binding it to a new derived
quantity is a Check-80 redesign outside BD-288's remit; (c) removes true and useful information. §6.6
plans (a) and states plainly that no gate catches an omission, which is the honest position. This is
a pre-existing gap BD-288 neither creates nor widens. **Applied at** §6.6.

### D-12 (was OI-R10) — should W3 be pre-split? **DECIDED: (a), keep W3 merged.**

**Context.** §6.10 argues W3 fits one cycle on zero remaining discovery; §6.11 keeps the W3a/W3b
split as a fallback (ROI-4 = (a), a closed user decision). D-1's fix adds 8 allowlist rows and six
number corrections to a wave already carrying 24 files. W3a is measured green standalone and
W3b-with-34-entries is measured green on arrival.

**Options.** (a) Keep W3 merged — D-1's fix is fully pre-derived here, so it adds rows, not
discovery. (b) Take the split pre-emptively.

**Recommendation and DECISION: (a).** Evidence: the bounded-cycle test is about REMAINING DISCOVERY,
not row count, and after §2.1 and §6.4 Block B nothing about the tier-1 exemption is left to
discover — membership measured, per-entry necessity measured by leave-one-out, redundant candidates
named and excluded, every expected number re-derived. Eight table rows with written-out `reason:`
strings are the cheapest work in the wave. ROI-4 = (a) is a closed user decision and there is no
measured reason to reopen it; the split stays available at no structural cost if the cycle strains.
The contingency I attached to this in the prior revision — "provided D-1 closes before the wave
starts" — is **satisfied**: D-1 is closed. **Applied at** §6.10, §6.11.

---

## 10. Empirical-Evidence Blocks

All measurements at **HEAD `47f8467`**, in the canonical checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack`, working tree carrying only the pre-existing
` M pack-ops/session-state.json`. No repo file was written. Blocks marked **[re-derived]** were
measured by me in this pass; blocks marked **[carried + confirmed]** were measured by an earlier
pass and confirmed here by a spot check named in the block.

### EP-1 [re-derived] — test wiring is disk-derived; no workflow edit is needed
- **Command:** `sed -n '117,124p' scripts/lib/ci-shard-plan.py`;
  `grep -c '^[^#]' scripts/ci-test-wiring-allowlist.txt`;
  `grep -n 'emit-matrix\|assert-coverage' .github/workflows/validate-pack.yml`
- **Output (verbatim, abridged):**
  ```
  def parse_wired_tests():                      # NOTE: no workflow_text arg
      """Wired KEEP set = {scripts/test*.sh + scripts/tests/*.sh
         + scripts/tests/fixture-dependent/*.sh} - allowlist.
      BD-219 redesign (dynamic auto-regen): the wired set is derived FROM DISK,
      independent of the workflow yml (which no longer carries a static matrix).
  allowlist non-comment entries: 1
  .github/workflows/validate-pack.yml:150  run: echo "matrix=$(python3 scripts/lib/ci-shard-plan.py --emit-matrix)" >> "$GITHUB_OUTPUT"
  .github/workflows/validate-pack.yml:234  run: python3 scripts/lib/ci-shard-plan.py --assert-coverage
  ```
- **Interpretation.** The `tests` matrix is generated at run time from three directory listings minus
  a 1-entry allowlist. A new `scripts/tests/test-validate-pack-check-95.sh` is wired by existing.
- **Conclusion: SUPPORTED.** Design §6.1 row 9 is **NOT-SUPPORTED** — no workflow edit exists to make.

### EP-2 [re-derived] — `_parse_client_installed_files()` has five unpack sites and an arity-asserting docstring
- **Command:** `git grep -n '_parse_client_installed_files' -- scripts/`;
  `sed -n '2948,2951p' scripts/lib/validate_checks/boundary_refs.py`
- **Output (verbatim, abridged):**
  ```
  boundary_refs.py:647     entries, _, _, _, _ = _parse_client_installed_files()
  boundary_refs.py:2377        entries, _, _, _, _ = _parse_client_installed_files()
  boundary_refs.py:2847  def _parse_client_installed_files() -> tuple[list[str], int, int, bool, bool]:
  boundary_refs.py:3012        _parse_client_installed_files()
  boundary_refs.py:4798    entries, start_count, end_count, _, _ = _parse_client_installed_files()
  test-validate-pack-check-41.sh:87  entries, start_count, end_count, regex_matched, body_has_content = mod._parse_client_installed_files()

  boundary_refs.py:2949    Sibling of `_parse_client_installed_files()` (whose 5-tuple arity is
  boundary_refs.py:2950    UNCHANGED and whose unpack sites stay intact). Check 41 clause (e)
  ```
- **Interpretation.** Five unpack sites; three positional and fatal on an arity change. The return
  annotation is an explicit 5-tuple. The sibling's docstring asserts the arity the design proposes
  to change.
- **Conclusion: SUPPORTED.** Design §6.2's surface enumeration is **PARTIAL** — it names one of five.

### EP-3 [carried + confirmed] — parser and git-helper costs, against the named budget
- **Command (carried):** in-process timing, median of 9 (parsers) / 5 (git helpers).
  **Confirmed here:** `grep -n 'RUN_CHECK_.*BUDGET_S' scripts/lib/validate_checks/core.py`;
  `/usr/bin/time -p python3 scripts/validate-pack.py` ×2.
- **Output (verbatim):**
  ```
  _parse_client_installed_files median ms:       0.132     (carried)
  _parse_client_installed_file_stages median ms: 0.128     (carried)
  _git_tracked_relpaths median ms:              10.792     (carried)
  _build_basename_index median ms:              11.784     (carried)
  core.py:125  RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0        (confirmed)
  core.py:126  RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0        (confirmed)
  battery, two consecutive runs:  real 2.54  |  real 2.40     (confirmed, this pass)
  ```
- **Interpretation.** A second parse of the install-map block costs 0.13 ms against a 10.0 s hard-FAIL
  budget with ~7.5 s of headroom at the measured 2.40–2.54 s run. A second `git ls-files` costs
  10.8 ms, ~83× more, which is why §5.4 threads the existing `rels` through instead. No budget line
  was emitted in any run.
- **Conclusion: SUPPORTED.** The budget every timing claim in this plan is measured against is
  `RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0` (hard FAIL) with `RUN_CHECK_PER_CHECK_WARN_BUDGET_S =
  2.0` (WARN), both at `scripts/lib/validate_checks/core.py:125–126`.

### EP-4 [re-derived] — the `_CLIENT_INSTALLED_FILES` reverse map yields 29 entries
- **Command:** parse `scripts/init-project.sh` for lines matching `#\s+(\S+)\s+->\s+(\S+)`; build
  `proj -> pack`; count.
- **Output (verbatim):** `dest_to_source entries: 29`
- **Interpretation.** The sibling-parser recipe in §5.3 is executable from the block as it exists,
  and 29 matches the inventory size Check 41 reports. The adversarial pass, which built the helper
  for real, reports the same 29.
- **Conclusion: SUPPORTED.**

### EP-5 [re-derived] — three `lstrip("./")` sites, one of them in the pack-side test
- **Command:** `git grep -n 'lstrip("\./")' -- .`
- **Output (verbatim, complete):**
  ```
  project-template/scripts/validate-docs.sh:180:        dangling_targets.add(target.lstrip("./"))
  project-template/scripts/validate-docs.sh:424:            norm = ref.lstrip("./")
  scripts/tests/test-validate-docs-template-fullscan.sh:208:        norm = target.lstrip("./")
  ```
  and, separately, `sed -n '424,427p' project-template/scripts/validate-docs.sh`:
  ```
  424:            norm = ref.lstrip("./")
  425:            base = os.path.basename(ref)
  426:            if norm in relpaths or base in basenames:
  427:                continue
  ```
- **Interpretation.** The gate has TWO `lstrip` sites, not three; the design's third item is the
  fallback at `:426`, a different defect. The genuine third `lstrip` is in the pack-side test whose
  comment claims to mirror `_commit_record`. `:425` is the dead `base` assignment.
- **Conclusion: PARTIAL** on the design's composition (count right, membership wrong), **SUPPORTED**
  on the substance that all three must move together.

### EP-6 [carried + confirmed] — Check 81's matcher today, and the 7 WARNing BDs
- **Command (carried):** monkey-patch `_check_81_active_bd_ids` in-process with the §4.2 body; call
  `check_open_bd_structured_surface_field()`. **Confirmed here:**
  `sed -n '700,712p' scripts/lib/validate_checks/cross_bd.py`;
  `python3 scripts/validate-pack.py | grep 'Check 81' -A 8`; read the live `active[]`.
- **Output (verbatim, abridged):**
  ```
  cross_bd.py:706-711    for member in active:
                             if isinstance(member, dict):
                                 bd = member.get("bd")
                                 if isinstance(bd, str) and re.match(r"^BD-\d+$", bd):
                                     ids.add(bd)
                         return ids                       <-- no string leg
  live active[]: ['BD-288 @ planner stage. Design FINAL and fully decided: ...']
  WARN: backlog/BD-020.md — ... bare/TBD/missing `File/Symbol` ...
  WARN: backlog/BD-039.md   WARN: backlog/BD-187.md   WARN: backlog/BD-192.md
  WARN: backlog/BD-202.md   WARN: backlog/BD-223.md   WARN: backlog/BD-279.md
  current matcher ids: set()      fixed matcher ids: {'BD-288'}     (carried)
  test fixture form: test-validate-pack-check-81.sh:142
      "active": [{"bd": b, "sub_step": "x"} for b in active_bd_ids],
  ```
- **Interpretation.** The shipped matcher has a dict leg and no string leg, and the live `active[]`
  carries a string — so the FAIL leg cannot fire today. The fix takes the check from `0 in active[]`
  (inert) to `1 in active[]` (biting) with the tree green. Exactly 7 open BDs WARN — the §9 D-6
  hazard. The existing test builds DICT members, so T1–T6 are non-vacuous today and the dict leg
  must be retained.
- **Conclusion: SUPPORTED.**

### EP-7 [carried + confirmed] — Check 66 headroom under W3's trinity STRIPs
- **Command (carried):** load `doc_concision`, iterate `_check_66_iter_bullets` over each trinity
  file's `## Pack memory` section, map each STRIP line to its containing bullet, add the
  qualification's character growth. **Independently reproduced** by the adversarial pass, which
  applied all 21 STRIPs to scratch copies at the stated coordinates (0 misses) and re-ran the
  iterator before and after.
- **Output (verbatim, the growing bullets):**
  ```
  === CLAUDE.md: 69 bullets before, 69 after; cap 1300
    bullet@  356  626 ->  634  grow=+8   headroom= 666
    bullet@  594  674 ->  683  grow=+9   headroom= 617
    bullet@  606 2341 -> 2368  grow=+27  headroom=-1068  allowlisted=True
    bullet@  807 1124 -> 1132  grow=+8   headroom= 168
    bullet@  915 1017 -> 1045  grow=+28  headroom= 255
  === AGENTS.md: 63 before, 63 after ===  @471 928 -> 937 headroom=363
  === GEMINI.md: 70 before, 70 after ===  @440 1128 -> 1137 headroom=163   <-- tightest
  OVER CAP and NOT allowlisted: []   (all three files)
  allowlist record shape: doc: + snippet: - **Pack Chat does MINOR edits only; coder does every MAJOR
  ```
- **Interpretation.** No bullet crosses the cap. The one already-over-cap bullet is allowlisted on a
  FIRST-LINE snippet, and no STRIP touches a first line, so no snippet match breaks (verified
  `allowlisted=True` post-edit). Tightest post-edit margin: 163 characters.
- **Conclusion: SUPPORTED** — safe, and thin enough that "qualify the path, add no prose" is a
  constraint rather than a style note. The design does not mention Check 66 at all.

### EP-8 [carried] — `validate-pack.py`'s header has no count prose and its enumeration stops at 42
- **Command:** extract the module docstring with a regex;
  `grep -n 'invoked checks\|registry entries' scripts/validate-pack.py`
- **Output (verbatim):**
  ```
  docstring lines: 283
  last numbered entry: "  42. CI test-wiring allowlist is valid + bounded (BD-184, BD-219 redesign): ..."
  then: "Two additional informational checks (no number, soft / advisory): ..."
  grep 'registry entries' -> 693:# named-lambda registry entries late-bind ...
                             701:# above. The Check-16 named-lambda registry entries below late-bind
  ```
- **Interpretation.** No count assertion; the per-check enumeration ends at 42 with 43–94 absent
  entirely. Adding a Check-95 entry would make 95 the only check between 43 and 95 present there.
- **Conclusion: SUPPORTED** — the design's claim holds, with the added instruction not to add one.

### EP-9 [re-derived] — the client allowlist's real path, its record counts, the `basenames` grep, and the S9 roster
- **Command:** `git ls-files | grep -i docs-gate-allowlist`;
  `grep -n '^target: \.' project-template/scripts/.docs-gate-allowlist.txt`;
  `grep -c '^target:'` and `grep -c '^snippet:'` on the same file;
  `git grep -n basenames project-template/scripts/validate-docs.sh`;
  `sed -n '1113,1205p' scripts/init-project.sh`;
  `grep -rn 'scripts/test-python.sh' project-template/docs`
- **Output (verbatim, abridged):**
  ```
  git ls-files | grep -i docs-gate-allowlist
      project-template/scripts/.docs-gate-allowlist.txt          <-- the ONLY one; no pack-ops/ copy
  501:target: .agents/mcp_config.json
  522:target: .pack-migration-backup/v9.3-to-v10.0/reconcile-checklist.md
  target: records = 13     snippet: records = 81     (total 94; -> 19 + 81 = 100 after W4)

  git grep -n basenames <gate>   -> 11 lines: 283 289 291 371 426 441 446 1933 1934  (9 code)
                                              531 1306                                (2 prose)
      :425 is `base = os.path.basename(ref)` — matches `base`, NOT `basenames`

  stage_s9_conditional_remove():
      if (( has_python == 0 )): pyproject.toml pyrightconfig.json scripts/bootstrap-python.sh
                                scripts/format-python.sh scripts/validate-python.sh
                                scripts/test-python.sh  + server/
      if (( has_swift  == 0 )): scripts/bootstrap-swift.sh scripts/format-swift.sh
                                scripts/validate-swift.sh scripts/test-swift.sh
      if (( has_proto  == 0 )): scripts/proto-gen.sh scripts/validate-proto.sh + proto/

  project-template/docs/pack/OPTIONAL-FEATURES.md:382:
      (`scripts/test.sh`, `scripts/test-swift.sh`, `scripts/test-python.sh`,
  ```
- **Interpretation.** (i) The superseded plan's `pack-ops/.docs-gate-allowlist.txt` does not exist;
  the line numbers were right and the path was wrong. (ii) §7.6's 10-row table cannot be attributed
  to that grep — the grep yields 9 code rows and `:425` is found by reading the function. (iii)
  `none-detected` removes python ∪ swift ∪ proto while `python-only` removes only swift ∪ proto, a
  STRICT SUPERSET, so `dangling(none-detected) ≥ dangling(python-only)` necessarily; and
  `scripts/test-python.sh` has a live citation, so the inequality is strict. The worst-case profile
  is `none-detected`, not `python-only`.
- **Conclusion: SUPPORTED (N-1, N-3, N-4 of the adversarial review, all three re-derived here).**

### EP-10 [re-derived] — the Check-95 walk: 35 files / 441,529 bytes, with zero pack-ops/ and zero project-template/ members
- **Command:** build the walk by subtraction from live symbols —
  `_iter_operating_docs() ∪ supporting-docs/*.md ∪ {README.md}` minus Check 40's walk minus
  `_iter_client_installed_files()` minus the wholesale prefixes.
- **Output (verbatim):**
  ```
  WALK SIZE: 35   bytes: 441529
  dropped by prefixes: ['backlog/_rules.md', 'changelog/_rules.md']
  operating docs: 158   client installed: 183   c40 walk: 10
  pack-ops/ members in walk: []
  project-template/ members in walk: []
  members: 5 .claude/agents/pack-*.md | 18 .claude/skills/*/SKILL.md
           AGENTS.md CLAUDE.md GEMINI.md README.md | 8 supporting-docs/*.md
  ```
- **Interpretation.** An exact, independent reproduction of the design's EV-1 headline figures. The
  three non-history exclusion prefixes (`maintenance-docs/`, `test-fixtures/`,
  `scripts/tests/fixtures/`) drop **nothing** live, which is why §6.9 probe 3 must be fixture-based
  for those three. The empty `pack-ops/` list is what makes §6.4's fact 1 true; the empty
  `project-template/` list is what makes §3.3 claim 3 true.
- **Conclusion: SUPPORTED.**

### EP-11 [re-derived] — every STRIP target exists; the two OI-3 targets do not
- **Command:** `[ -f <path> ]` over all 11 pack STRIP targets, the 4 client STRIP targets, and the
  4 OI-3 paths.
- **Output (verbatim):**
  ```
  scripts/init-project.sh OK   pack-ops/PACK-AGENTS.md OK   scripts/validate-pack.py OK
  pack-ops/PACK-CHAT.md OK     pack-ops/PACK-MEMORY-RATIONALE.md OK
  scripts/lib/validate_checks/no_leak.py OK   pack-ops/HELP-FRAGMENT-PACK.md OK
  supporting-docs/SETUP-EXISTING.md OK   scripts/migrate-v10-to-v11.sh OK
  scripts/tests/test-customization-preserve.sh OK   scripts/test-migrator-core.sh OK
  project-template/skills/audit-methodology/SKILL.md OK   project-template/docs/pack/PM-CHAT.md OK
  project-template/docs/pack/prompts/pm-chat.md OK   project-template/docs/pack/OPTIONAL-FEATURES.md OK
  project-template/docs/pack/INSTALL-PROCEDURES.md  ABSENT
  project-template/supporting-docs/METHODOLOGY.md   ABSENT
  project-template/supporting-docs (dir)            ABSENT
  supporting-docs/INSTALL-PROCEDURES.md EXISTS   supporting-docs/METHODOLOGY.md EXISTS
  ```
- **Interpretation.** All 15 replacement targets exist, so no wave introduces a dangling reference.
  The two OI-3 cells are genuine dead pointers the Check-68 fallback has been hiding, and
  `project-template/supporting-docs/` is not even a directory.
- **Conclusion: SUPPORTED.**

### EP-12 [carried + confirmed] — the 10 client STRIP coordinates hold at their pack-source paths
- **Command (carried):** `sed -n '<line>p' <pack-source-path>` for all 10. **Confirmed:** the
  adversarial pass applied all 10 at these coordinates by asserting the named token is present on
  the named line before replacing — 10 applied, 0 misses. I independently verified the KEEP-side
  anchor line (below) because §7.5's binding constraint rests on it.
- **Output (verbatim, abridged):**
  ```
  project-template/.claude/agents/auditor-architecture.md:37   ... `project-template/skills/audit-methodology/SKILL.md` rule 21
  project-template/.claude/agents/auditor-ops.md:31            ... `project-template/skills/audit-methodology/SKILL.md`
  project-template/.codex/agents/auditor-architecture.toml:19  ... rule 21 ...
  project-template/.codex/agents/auditor-ops.toml:19           ... rule 21 ...
  project-template/.agents-plugin/optiquity-agents/agents/auditor-architecture.md:41
  project-template/.agents-plugin/optiquity-agents/agents/auditor-ops.md:35
  project-template/skills/boundary-investigation/SKILL.md:107  `project-template/docs/pack/OPTIONAL-FEATURES.md`)
  supporting-docs/INSTALL-PROCEDURES.md:1336  `project-template/docs/pack/PM-CHAT.md` § Before starting a new
  supporting-docs/INSTALL-PROCEDURES.md:1367  `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff is
  supporting-docs/METHODOLOGY.md:1984         The template ships at `project-template/docs/pack/PACK-FEEDBACK.md`.
  KEEP-side anchor line, verified this pass — supporting-docs/METHODOLOGY.md:11-12:
      > **Single source of truth:** One copy of this file lives at
      > `supporting-docs/METHODOLOGY.md` in the pack repo. Copy it to your project
  ```
- **Interpretation.** Every client coordinate maps to the pack-source path at the SAME line number.
  `METHODOLOGY.md:1984` confirms the reword recipe. `METHODOLOGY.md:12` is the citation the client
  `target:` record must match verbatim, which is why §7.5 option (b) is impossible.
- **Conclusion: SUPPORTED.**

### EP-13 [re-derived] — the Check-68 residue: 13 items, 6 tokens, all coordinates live
- **Command:** replicate Check 68's scope and hardened ladder in-process; print every FAIL.
- **Output (verbatim, complete):**
  ```
  FAILS: 13
    .claude/skills/boundary-investigation/SKILL.md:73  project-template/docs/pack/INSTALL-PROCEDURES.md
    .claude/skills/boundary-investigation/SKILL.md:74  project-template/supporting-docs/METHODOLOGY.md
    AGENTS.md:491                    CLAUDE/AGENTS/GEMINI.md
    CLAUDE.md:610                    CLAUDE/AGENTS/GEMINI.md
    GEMINI.md:463                    CLAUDE/AGENTS/GEMINI.md
    pack-ops/MERGE-STRATEGY.md:57    CLAUDE/AGENTS/GEMINI.md
    project-template/docs/pack/PM-CHAT.md:155                  docs/project/ARCHITECTURE.md
    project-template/docs/project/backlog/_rules.md:22         docs/project/backlog/_toc.md
    project-template/docs/project/changelog/_rules.md:22       docs/project/changelog/_toc.md
    project-template/docs/project/groupings/_rules.md:23       docs/project/groupings/_toc.md
    supporting-docs/SETUP-EXISTING.md:277  docs/ARCHITECTURE.md
    supporting-docs/SETUP-EXISTING.md:292  docs/ARCHITECTURE.md
    supporting-docs/SETUP-EXISTING.md:306  docs/ARCHITECTURE.md
  allowlist size today: 51 token: records
  ```
- **Interpretation.** 11 non-OI-3 items over 6 distinct tokens → 6 new records take the allowlist
  51 → 57; each has ≥1 measured citer, so none is unbacked. The 2 remaining residue items are the
  OI-3 STRIPs. Coordinates match the earlier pass and the adversarial pass exactly.
- **Conclusion: SUPPORTED.**

### EP-14 [re-derived] — Check 71: 12 mirror files, byte-identical today
- **Command:** `md5 -q` per skill across `.claude/skills`, `.codex/skills`, `.agents/skills`.
- **Output (verbatim):**
  ```
  boundary-investigation 8cbf74f21e9e228750d015b154543ad9  x3
  dashboard-render       0f046151ec18829825e59b35c4b3f107  x3
  pack-help              d6d9f328a02a1c6cafb99e62a4b1b66d  x3
  verification-harness   f000971860da2dd85a995eab3ac4ddfc  x3
  ```
- **Interpretation.** All four skills W2/W3 touch are byte-identical across the three trees, so any
  canonical edit reds Check 71 until re-propagated. 4 canonical + 8 mirrors = 12 files.
- **Conclusion: SUPPORTED.**

### EP-15 [derived] — file contention: W1 intersects nothing; W2/W3/W4 share `boundary_refs.py`
- **Command:** enumerate each wave's file set from §5.1 / §6.1 / §7.1, compute pairwise
  intersections.
- **Output:** `W1∩W2 = W1∩W3 = W1∩W4 = ∅`;
  `W2∩W3 = {boundary_refs.py, .claude/skills/boundary-investigation/SKILL.md, .codex/…, .agents/…}`;
  `W2∩W4 = W3∩W4 = {boundary_refs.py}`.
- **Interpretation.** W1 is genuinely parallel; W2→W3→W4 must serialize.
- **Conclusion: SUPPORTED.**

### EP-16 [re-derived] — the W3/W4 `supporting-docs/` split lies exactly on the client-install boundary
- **Command:** compute `_iter_client_installed_files()` and intersect with each wave's
  `supporting-docs/` set and with W3's 11 STRIP files.
- **Output (verbatim):**
  ```
  non-project-template members of the client-installed set:
      ['supporting-docs/INSTALL-PROCEDURES.md', 'supporting-docs/METHODOLOGY.md']
  W3 STRIP files that ARE client-installed (must be 0): []
  W4 supporting-docs files client-installed:
      ['supporting-docs/INSTALL-PROCEDURES.md', 'supporting-docs/METHODOLOGY.md']
  ```
- **Interpretation.** W3's four `supporting-docs/` files are non-installed (Check 95's walk); W4's two
  are the only installed ones (Check 43's walk). Disjoint by the same boundary the two checks are
  defined by. Also confirms §3.3 claim 1.
- **Conclusion: SUPPORTED.**

### EP-17 [re-derived] — Check 68's ladder: live, current-replicated, hardened, and post-W2
- **Command:** replicate Check 68's scope and ladder in-process (operating docs ∪ README ∪
  `project-template/**` ∪ `supporting-docs/**`, minus `_CHECK_68_EXCLUDE_PREFIXES`) under three
  configurations, then simulate the full post-W2 state (NOI-1 scope + hardened ladder + 6 records +
  the 2 STRIPs applied in memory).
- **Output (verbatim):**
  ```
  LIVE, from `python3 scripts/validate-pack.py`:
    OK: Check 68 — 228 file(s) scanned; 1830 file/path reference(s) checked; 1597 resolved,
        28 self-flagged-non-existent (anchor-cleared), 205 allowlisted (non-existent by design);
        0 dangling outside the allowlist (complete).

  REPLICATED, current scope + current ladder:
    files=228 refs=1830 direct=1298 basefall=299 anchor=28 allow=205 FAIL=0     (1298+299 = 1597 resolved)
    QUALIFIED: {'refs':764,'direct':389,'basefall':299,'allow':75,'anchor':1}
    BARE     : {'refs':1066,'direct':909,'allow':130,'anchor':27}

  current scope + HARDENED ladder:
    files=228 refs=1830 direct=1298 legA=247 legB=39 basefall=0 anchor=28 allow=205 FAIL=13

  NOI-1 scope + HARDENED ladder:
    files=229 refs=1836 direct=1302 legA=247 legB=39 anchor=28 allow=207 FAIL=13

  POST-W2 (NOI-1 scope, hardened ladder, 6 records, 2 STRIPs applied):
    files=229 refs=1836 resolved=1590 anchor=28 allowlisted=218 FAIL=0
    (of resolved: legA=247 legB=39)     sum check: 1590+28+218+0 = 1836 == refs
  ```
- **Interpretation.** The replication reproduces the LIVE OK line term for term, which validates the
  ladder before any delta is read. `refs_checked` is the TOTAL (qualified 764 + bare 1066 = 1830),
  so the superseded plan's `764` expectation was the qualified-only sub-population. Leg B carries 39
  references, so the ladder cannot ship without the parser (§8). NOI-1 costs 0 FAILs and moves the
  scope by +1 file / +6 references. The post-W2 projection is 229 / 1836 / 1590 / 28 / 218 / 0.
- **Conclusion: SUPPORTED** for the four structural terms and the ladder figures; **PARTIAL** for the
  resolved/allowlisted split, which the adversarial pass's built implementation reports as 1576/232
  — see §9 D-4, where I record that I could not reproduce that split and what I ruled out.

### EP-18 [re-derived] — `_build_basename_index()` has exactly three callers
- **Command:** `git grep -n '_build_basename_index' -- scripts/` (excluding `scripts/tests`).
- **Output (verbatim):**
  ```
  boundary_refs.py:1761  def _build_basename_index() -> dict[str, list[Path]] | None:
  boundary_refs.py:1847      index = _build_basename_index()      # Check 40
  boundary_refs.py:2357      index = _build_basename_index()      # Check 43
  boundary_refs.py:4164      index = _build_basename_index()      # Check 68
  boundary_refs.py:4904      "_build_basename_index",             (the __all__ export)
  ```
- **Interpretation.** An optional `rels` parameter defaulting to `None` is backward-compatible for
  Checks 40 and 43 and lets Check 68 avoid a second `git ls-files`.
- **Conclusion: SUPPORTED.**

### EP-19 [re-derived] — the client `target:` record's Check-43 anchor dependency, the 6 records' sizing, and the leg-order test
- **Command:** (i) run the real `_check_43_context_has_anchor` against three candidate `reason:`
  texts placed 1–2 lines below `target: supporting-docs/METHODOLOGY.md`;
  (ii) read `_CHECK_43_ANCHOR_PHRASES` / `_CHECK_43_ANCHOR_WINDOW` and Check 43's
  `supporting-docs/<X>` leg at `boundary_refs.py:2449–2489`; (iii) confirm
  `project-template/scripts/.docs-gate-allowlist.txt` is in `_iter_client_installed_files()`;
  (iv) count occurrences of the 6 new Check-68 tokens across the whole post-NOI-1 scope;
  (v) count legA/legB-resolvable tokens that are also on the Check-68 allowlist.
- **Output (verbatim):**
  ```
  (i) neutral reason              -> anchor_cleared = False    (Check 43 FAILs)
      plan §7.5 reason            -> anchor_cleared = True     (clears)
      "conditionally-shipped ..." -> anchor_cleared = False    (Check 43 FAILs)
  (ii) _CHECK_43_ANCHOR_PHRASES = ('in the pack repo','at the pack repo','pack-repo','in the project',
                                   'at the client','post-install','does not exist','archived')
       _CHECK_43_ANCHOR_WINDOW = 2   (window joined and .lower()ed)
       Check 43 leg: for m in re.finditer(r"supporting-docs/([A-Za-z0-9_-]+(?:\.[A-Za-z0-9]+)+)", line)
                     ... if _check_43_context_has_anchor(...): hits_anchor += 1; continue
                     ... fail("qualified reference `supporting-docs/{fname}` names the pre-install ...")
       _CHECK_40_FILE_EXTS = md|sh|py|toml|yml|yaml|json|txt      _CHECK_43_EXTRA_WALK_SUFFIXES = ('example','proto')
  (iii) docs-gate-allowlist in _iter_client_installed_files(): ['project-template/scripts/.docs-gate-allowlist.txt']
  (iv) total occurrences of the 6 NEW Check-68 tokens anywhere in scope:
       {'CLAUDE/AGENTS/GEMINI.md': 4, 'docs/project/ARCHITECTURE.md': 1, 'docs/project/backlog/_toc.md': 1,
        'docs/project/changelog/_toc.md': 1, 'docs/project/groupings/_toc.md': 1, 'docs/ARCHITECTURE.md': 3}
       sum: 11        overlap of the 6 with the existing 51-token allowlist: []
  (v) legA/legB-resolvable tokens that are ALSO on the allowlist: 0   {}
  ```
- **Interpretation.** (i)–(iii) prove M-3: the record sits on a Check-43-walked surface and clears
  ONLY via an anchor token in its own `reason:` prose; a "clearer" reword reds the check.
  (iv) proves the 6 Check-68 records are sized exactly to the 11 residue occurrences with no
  over-reach. (v) rules out the likeliest explanation for the §9 D-4 split disagreement.
- **Conclusion: SUPPORTED.**

### EP-20 [re-derived] — the graph corroborates the B-1 mechanism; `agent-run.sh` has one candidate
- **Command:**
  `graphify explain "_CHECK_40_ALLOWLIST" --graph /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json --budget 1500 --backend claude-cli`
  and the same for `check_bare_pack_ops_refs`; then `git ls-files | grep agent-run.sh` and
  `sed -n '270,274p' CLAUDE.md`.
- **Output (verbatim):**
  ```
  Node: _CHECK_40_ALLOWLIST   Degree: 1
    <-- check_bare_pack_ops_refs (Check 40) [references] [EXTRACTED]

  Node: check_bare_pack_ops_refs()   Source: scripts/lib/validate_checks/boundary_refs.py L1815   Degree: 7
    --> ok()  --> fail()  --> _build_basename_index()  --> _strip_code_blocks()
    --> _check_40_context_has_anchor()   <-- boundary_refs.py [contains]

  git ls-files | grep agent-run.sh  ->  project-template/agent-run.sh          (exactly one)
  CLAUDE.md:272-273  ... The pack repo has no `agent-run.sh` — that's a project template helper ...
  ```
- **Interpretation.** Check 40's extracted edge set lists exactly its four **called** helpers —
  precisely the superseded reuse list — and carries no edge for the dict lookup, which corroborates
  §2.1's mechanism independently of the replication and explains why the omission was easy to make.
  `_CHECK_40_ALLOWLIST` has exactly one consumer today, so a new check inherits nothing implicitly.
  Separately, `agent-run.sh` HAS one repo candidate, so the pre-derived `reason:` is false as
  written (§9 D-9).
- **Conclusion: SUPPORTED.** Discovery ran graph-first here; the grep was the verification step.

### EP-21 [re-derived] — count-encoding surfaces and the registry lock-step
- **Command:** `git grep -c "<token>"` for each of the four README number tokens plus a tree-wide
  `git grep -n` for each; `grep -rl CHECK_REGISTRY_EXPECTED_COUNT scripts/tests/*.sh | wc -l`;
  `sed -n '205,215p' scripts/lib/validate_checks/core.py`;
  `find . -name "test-validate-pack-check-95.sh" -not -path './.git/*'`.
- **Output (verbatim):**
  ```
  "91 invoked checks"          -> README.md:2   (2 hits tree-wide)
  "91 registry entries total"  -> README.md:2   (2 hits tree-wide)
  "86 numbered"                -> README.md:2   (2 hits tree-wide)
  "77–94"                      -> README.md:2   (2 hits tree-wide)
  count-invariant per-check tests referencing CHECK_REGISTRY_EXPECTED_COUNT: 30
  core.py:210  CHECK_REGISTRY_EXPECTED_COUNT = 91
  core.py ledger tail: "... 90 -> 91. (Next free numeric ID = 95.)"
  find test-validate-pack-check-95.sh -> 0 results; highest present is check-94
  Check 80 binding: count_re = re.compile(r"(\d+)\s+invoked checks|(\d+)\s+registry entries total")
  ```
- **Interpretation.** Four number tokens per site, eight in total; Check 80 binds `invoked checks`
  and `registry entries total` only. Exactly 30 per-check tests carry the count invariant. 95 is the
  next free ID and the new test filename does not collide.
- **Conclusion: SUPPORTED.**

### EP-22 [re-derived] — the `.codex/` and `.agents/` skill mirrors are in no operating-doc walk
- **Command:** intersect `_iter_operating_docs()` with the three mirror trees.
- **Output (verbatim):**
  ```
  codex mirrors in ops: []      agents mirrors in ops: []      count .claude/skills in ops: 18
  ```
- **Interpretation.** Only the `.claude/` canonical copies are operating docs, so Check 95 (and
  Checks 65/67/68/69) never scan the mirrors. **Check 71 byte-identity is the sole mechanism keeping
  them in sync** — which is why §5.8 and §6.8 make propagation an ordering constraint rather than a
  cleanup step.
- **Conclusion: SUPPORTED.**

### EP-23 [re-derived] — the four-tier ladder under every candidate tier-1, pre- and post-STRIP, plus leave-one-out necessity
- **Command:** replicate Check 40's four-tier ladder over the 35-file walk (its two regexes,
  `_strip_code_blocks`, `_check_40_context_has_anchor`, the same-dir rule, `_build_basename_index`),
  varying tier 1 only; suppress the 45 triage STRIP coordinates for the post-STRIP runs; then remove
  each of the 34 candidate entries one at a time and count the FAILs it introduces.
- **Output (verbatim):**
  ```
  triage: len 122   Counter({'KEEP': 77, 'STRIP': 45})
  C40 entries: 18   C95(plan) entries: 26   overlap C95_26 & C40: []

  PRE-STRIP  26-entry (plan as written) : {'hits':269,'tier1': 78,'anchor':11,'same_dir':21,'FAIL':159}
  POST-STRIP 26-entry (plan as written) : {'hits':224,'tier1': 78,'anchor':11,'same_dir':21,'FAIL':114}
     top FAIL basenames: CLAUDE.md 30 | GEMINI.md 29 | AGENTS.md 27 | README.md 24
                         settings.json 1 | QUICKSTART.md 1 | tracker.toml 1 | report.md 1
  PRE-STRIP  34-entry (26 + 8 measured) : {'hits':269,'tier1':197,'anchor': 8,'same_dir':19,'FAIL': 45}
  POST-STRIP 34-entry (26 + 8 measured) : {'hits':224,'tier1':197,'anchor': 8,'same_dir':19,'FAIL':  0}
  PRE-STRIP  26 + full C40 union        : {'hits':269,'tier1':200,'anchor': 8,'same_dir':16,'FAIL': 45}
  POST-STRIP 26 + full C40 union        : {'hits':224,'tier1':200,'anchor': 8,'same_dir':16,'FAIL':  0}
  POST-STRIP EMPTY tier1                : {'hits':224,'tier1':  0,'anchor':14,'same_dir':21,'FAIL':189}

  C40-ONLY tier1, PRE-STRIP             : {'hits':269,'tier1':122,'anchor':11,'same_dir':16,'FAIL':120}
     FAIL coordinate set vs the 122 triage records:
        in FAIL not in triage: []
        in triage not in FAIL: [('changelog/_rules.md',32,'vN.md'), ('changelog/_rules.md',35,'vN.md')]

  union-variant PRE-STRIP FAIL count: 45   triage STRIP count: 45   set identical: True

  leave-one-out necessity over the 34 (new FAILs introduced by removing that one entry):
     AGENTS.md 27 | AGENT_KICKOFF.md 1 | ARCHITECTURE.md 4 | BACKLOG.md 7 | CHANGELOG.md 5
     CLAUDE.md 30 | GEMINI.md 29 | IMPLEMENTATION-PLAN.md 5 | IMPLEMENTATION_PLAN.md 1
     MIGRATION-v9-to-v10.md 1 | MIGRATION-vN-to-vM.md 4 | OPTIONAL-FEATURES.md 1
     PACK-FEEDBACK.md 1 | PLATFORM-SKILLS.md 1 | PROMPT-TEMPLATES.md 2 | QUICKSTART.md 1
     README.md 24 | RUNTIME-SUBAGENT-PATTERN.md 3 | SETUP.md 1 | SKILL.md 3 | agent-run.sh 9
     bootstrap.sh 3 | config.yml 1 | format.sh 2 | inbound.yml 2 | migrate-vN-to-vM.sh 1
     plugin.json 3 | proto-gen.sh 3 | pyproject.toml 4 | pyrightconfig.json 1 | report.md 1
     settings.json 1 | tracker.toml 1 | validate.sh 6
  REDUNDANT entries (leave-one-out introduces 0 new FAILs): []
  sum of necessity counts = 189 == EMPTY-tier1 FAIL count = 189
  KEEP total 77 | KEEP in wholesale-excluded files: 2 (changelog/_rules.md:32,:35 both vN.md) | KEEP remaining: 75
  distinct KEEP basenames after exclusion: 26

  C40 entries with a tier-1 clear in the walk (9): AGENTS.md CLAUDE.md GEMINI.md LICENSE.md
      QUICKSTART.md README.md report.md settings.json tracker.toml
  C40 entries with ZERO occurrences in the walk (9): BD-NNN.md HELP-FRAGMENT.md LICENSE MEMORY.md
      TD-NNN.md feedback_review_fix_cycle.md id-map.json manifest.txt phase-N.md
  LICENSE.md occurrences: [('README.md',311),('README.md',321),('README.md',321)]
  LICENSE.md candidates: ['LICENSE.md']   (one, at the repo root == the citing file's dir -> tier 3 clears)
  candidate counts: CLAUDE.md 3 | AGENTS.md 3 | GEMINI.md 2 | README.md 6 | settings.json 4
                    QUICKSTART.md 1 | report.md 0 | tracker.toml 0
  ```
- **Interpretation.** (1) **B-1 confirmed**: the specified 26-entry check FAILs 114 times post-STRIP.
  (2) **Root cause proved**: the 122-record census IS the four-tier ladder's FAIL set (120 over the
  35-file walk + the 2 `changelog/_rules.md` records from the superseded 37-file walk), so the
  allowlist was sized to a residue that presupposes tier 1. (3) **The replication is validated
  before the delta is read**: the union variant's 45 pre-STRIP failures are set-identical to the
  triage's 45 STRIP verdicts. (4) **The fix is exactly 8**, and `LICENSE.md` is a near-miss that must
  be excluded because tier 3 already clears all three of its occurrences. (5) **Leave-one-out gives
  the exactly-sized proof**: zero redundant entries and a necessity sum that closes against the
  empty-allowlist probe at 189 — which is also the corrected magnitude for §6.9 probe 1 (the
  superseded plan said 75; the adversarial review corrected it to 197, which is the tier-1 CLEAR
  count, not the FAIL count). (6) **N-2 reconciled**: 77 and 75 are both correct and describe
  different walks.
- **Conclusion: SUPPORTED (B-1, M-1, S-3, N-2, and §9 D-1's option costs).**

### EP-24 [re-derived] — the walk is fully tracked today, and no walk member carries a Guardrail-2 fence
- **Command:** `git ls-files` vs the 35-member walk; intersect `_CHECK_37_PER_LINE_FENCE_FILES` with
  the walk.
- **Output (verbatim):**
  ```
  walk members: 35   all tracked: True   untracked walk members: []
  _CHECK_37_PER_LINE_FENCE_FILES: 10 members
     intersection with the 35-file walk: []
  ```
- **Interpretation.** §6.2's `walk &= set(rels)` intersection is behaviour-preserving today, which is
  exactly why a live-tree assertion cannot prove it is present — §6.9 probe 5's untracked-file leg is
  the only thing that can. And Check 95 inheriting Check 40's no-fence behaviour is consistent by
  measurement, not by accident.
- **Conclusion: SUPPORTED.**

### EP-25 [re-derived] — the Check-81 path-token blind spot, and the superset property of the one-character fix
- **Command:** run `_CHECK_81_PATH_TOKEN_RE` and the widened candidate
  `` r"`([A-Za-z0-9_.][A-Za-z0-9_./-]*(?:/[A-Za-z0-9_./-]+|\.[A-Za-z0-9_]+|/))(?:`|(?<=/)(?=<))" ``
  over named probe spans, then over the full text of all 288 `backlog/BD-*.md`, comparing token
  multisets.
- **Output (verbatim):**
  ```
  CURRENT pattern: `([A-Za-z0-9_][A-Za-z0-9_./-]*(?:/[A-Za-z0-9_./-]+|\.[A-Za-z0-9_]+|/))(?:`|(?<=/)(?=<))

  span                                    CURRENT                          WIDENED
  `.claude/agents/pack-planner.md`        []                               ['.claude/agents/pack-planner.md']
  `.github/workflows/validate-pack.yml`   []                               ['.github/workflows/validate-pack.yml']
  `.claude/skills/`                       []                               ['.claude/skills/']
  `.codex/`                               []                               ['.codex/']
  `.dangling-ref-allowlist.txt`           []                               ['.dangling-ref-allowlist.txt']
  `.agents-plugin/optiquity-agents/`      []                               ['.agents-plugin/optiquity-agents/']
  `.env.example`                          []                               ['.env.example']
  `scripts/validate-pack.py`              ['scripts/validate-pack.py']     ['scripts/validate-pack.py']
  `.gitignore`                            []                               []
  `.md`                                   []                               []
  `.sh`                                   []                               []
  `.example`                              []                               []
  `scripts/skills/...`                    ['scripts/skills/...']           ['scripts/skills/...']
  `CLAUDE/AGENTS/GEMINI.md`               ['CLAUDE/AGENTS/GEMINI.md']      ['CLAUDE/AGENTS/GEMINI.md']
  `.codex/skills/...`                     []                               ['.codex/skills/...']
  `.claude/.codex/.gemini`                []                               ['.claude/.codex/.gemini']

  corpus-wide over all 288 backlog/BD-*.md:
    CURRENT distinct tokens: 825   total occurrences: 2829
    WIDENED distinct tokens: 893   total occurrences: 3046
    CURRENT tokens whose count CHANGES under WIDE: 0   {}
  ```
- **Interpretation.** The blind spot is real and total: a dot-leading backtick span yields NOTHING,
  because the pattern is backtick-anchored and the first character class excludes `.`. The
  one-character fix is **purely additive** — every existing token is reproduced at the same count,
  corpus-wide. The false-positive class the fix was suspected of introducing is **absent**: a
  backticked bare extension still yields nothing, because the grammar requires a `/` or a `.<ext>`
  after the first segment. The two shapes that do newly tokenize and are not real paths (a prose
  ellipsis, a slash-joined shorthand) are the SAME shapes the CURRENT regex already produces for
  non-dot spans — the widening introduces no class that does not already exist.
- **Conclusion: SUPPORTED.** The fix is exactly one character in the FIRST character class.

### EP-26 [re-derived] — the live effect of the widening: population by scope, zero structured-ness flips, one new Check-82 WARN
- **Command:** (i) run `_check_81_iter_open_bds()` and diff the token set per active BD under both
  regexes; (ii) evaluate `_check_81_field_is_structured()` under both; (iii) rebuild Check 82's
  `surface → [BD-IDs]` map under both; (iv) execute `check_open_bd_structured_surface_field()` and
  `check_cross_bd_surface_advisory()` in-process under both, capturing stdout; (v) repeat the token
  diff across three scopes.
- **Output (verbatim):**
  ```
  active-state open BD entries (Check 81/82's real candidate set): 16
    distinct (BD,token) pairs  CURRENT=68  WIDENED=75  NEW=7
    active BDs gaining >=1 token: 4 -> ['BD-109','BD-110','BD-171','BD-288']
    distinct NEW tokens: 6
       1x .claude/agents/pack-auditor.md          1x .codex/agents/auditor-issue-tracking.toml
       1x .codex/agents/pack-auditor.toml         1x .gemini/agents/auditor-issue-tracking.md
       1x .gemini/agents/pack-auditor.md          2x .github/workflows/validate-pack.yml

  structured-ness flips (Check 81 FAIL/WARN leg impact): 0   []
    currently UNSTRUCTURED active BDs: BD-020 BD-039 BD-187 BD-192 BD-202 BD-223 BD-279
      BD-020 tbd_markers=['to be created','n/a']  WIDE_finds_token=True   -> still unstructured
      BD-187 tbd_markers=['tbd']                  WIDE_finds_token=True   -> still unstructured
      BD-192 tbd_markers=['tbd','n/a']            WIDE_finds_token=True   -> still unstructured
      BD-039/BD-279 tbd or no token; BD-202/BD-223 no File/Symbol field

  Check 82 surfaces: CURRENT distinct=63 shared=4 | WIDENED distinct=69 shared=5
  NEW shared surface: ('.github/workflows/validate-pack.yml', ['BD-171','BD-288'])

  in-process execution of Checks 81+82:
    CURRENT: OK: Check 81 — every active-design BD (0 in session-state `active[]`; 0 with a
                 structured File/Symbol) ... 7 not-yet-active open BD(s) ... WARNed
             OK: Check 82 — 4 shared surface(s) WARNed across 63 distinct surface(s)
             FAIL lines: 0   WARN lines: 11
    WIDENED: OK: Check 81 — (byte-identical to the line above)
             WARN: shared edit surface `.github/workflows/validate-pack.yml` is claimed by
                   2 open BDs: BD-171, BD-288 — coordinate/sequence these ...
             OK: Check 82 — 5 shared surface(s) WARNed across 69 distinct surface(s)
             FAIL lines: 0   WARN lines: 12

  population by scope (tokens NEWLY EXTRACTED by the widening):
    S3 File/Symbol, ACTIVE-state only : 14 entries with a field ->  6 unique /  7 occ /  4 entries
                                        dot-leading spans still unextracted in this scope: 0
    S2 File/Symbol, ALL BD entries    : 245 entries          -> 43 unique / 80 occ / 40 entries
    S1 whole-file, ALL BD entries     : 288 entries          -> 68 unique / 217 occ / 70 entries
    (raw "backticked dot-leading spans" in S1: 218 unique / 427 occ / 129 entries — inflated by
     backtick-PAIRING artifacts, e.g. prose spans beginning at a sentence-final period; not a
     usable planning figure)
  ```
- **Interpretation.** In the load-bearing scope the widening recovers 6 distinct tokens across 4
  active BDs and leaves **zero** dot-leading spans unextracted. Check 81 is **behaviourally
  unmoved** — its OK line is byte-identical and there are zero structured-ness flips, because
  `_check_81_field_is_structured()` tests the TBD markers BEFORE the token search, so a recovered
  token can never rescue a placeholder field. The only behavioural change is Check 82's advisory
  map, which gains exactly one WARN — a real collision on BD-288's own entry that the guard could
  not previously see. FAIL count is 0 under both regexes, so the change cannot red the tree. The
  three scopes explain why prior population figures disagree: they measure different sets.
- **Conclusion: SUPPORTED.** The fix bites where it should and moves nothing it should not.

### EP-27 [re-derived] — the blast radius and the complete encoding-surface set for `_CHECK_81_PATH_TOKEN_RE`
- **Command:** `inspect.getsource()` on both consumers, counting emitter calls;
  `git grep -n '_CHECK_81_PATH_TOKEN_RE' -- .`; `grep -n` the check-82 test's assertions;
  enumerate `_DOC_CONSTANT_TWINS`; read `backlog/_rules.md:48–60`.
- **Output (verbatim):**
  ```
  Check 81 source: fail( x1   warn( x1
  Check 82 source: fail( x1   warn( x1
     -- the Check-82 `fail(` occurrence is in its DOCSTRING ("ADVISORY backstop ... NEVER `fail()`
        — the Check-48 precedent"); the executable emitters in its body are warn() and ok() only.

  git grep '_CHECK_81_PATH_TOKEN_RE' outside cross_bd.py:
     scripts/validate-pack.py:754   # surface grammar (`_CHECK_81_OPEN_BD_STATES` /
                                    # `_CHECK_81_TBD_MARKERS` / `_CHECK_81_PATH_TOKEN_RE`) ...
     -- a Cluster-G symbol ENUMERATION only; no grammar description -> NO EDIT
     (no hit in either wired test)

  test-validate-pack-check-82.sh asserts on synthetic surfaces only:
     T1 'scripts/shared-thing.py'  T2 distinct surfaces  T3 three BDs
     T4 'project-template/'        T5 'project-template/skills/'
     -- none dot-leading -> the 5 existing legs pass UNCHANGED under the widening

  _DOC_CONSTANT_TWINS (5): _PACK_CHAT_ONLY_PERMITTED_PATHS | _TRACKER_BACKENDS |
     _CHECK_54_REQUIRED_TOKENS | _CHECK_56_CANONICAL_VERBS | CHECK_REGISTRY_EXPECTED_COUNT
     -- _CHECK_81_PATH_TOKEN_RE is NOT enrolled -> no Check-80 twin lock-step

  backlog/_rules.md:56-59:
     A `File/Symbol` field for a BD in active design ... is a structured repo-relative
     path list (>=1 backtick repo-relative path token; no bare/TBD placeholder),
     so the cross-BD shared-surface scan can key on it.
     -- a prose contract with no char-class detail; the fix makes it TRUE -> NO EDIT
  ```
- **Interpretation.** The blast radius is bounded to advisory output: Check 82 cannot fail, and
  Check 81's fail path is unreachable from a token because the TBD gate precedes it. The complete
  encoding-surface set is the constant plus its grammar comment, plus the two wired tests (one
  gaining a leg because its coverage is now incomplete, not because it breaks). Three candidate
  surfaces are measured NOT to be surfaces: `validate-pack.py`'s symbol enumeration, the Check-80
  twin registry, and `backlog/_rules.md`'s prose contract — which the fix makes true rather than
  stale, the `declare-verify-backing` shape one level up.
- **Conclusion: SUPPORTED.**

### EP-28 [re-derived] — the widening's runtime cost
- **Command:** 200 full passes of each regex over every active-state `File/Symbol` field.
- **Output (verbatim):**
  ```
  CURRENT: 0.030 ms per full pass over all active fields
  WIDENED: 0.029 ms per full pass over all active fields
  ```
- **Interpretation.** Inside measurement noise, against
  `RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0` (hard FAIL) and
  `RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0` (WARN) at `core.py:125–126`. A character-class widening
  is O(field length) and adds no backtracking path; the candidate set (~16 small fields) is
  unchanged.
- **Conclusion: SUPPORTED.**

---

## 11. Summary — what lands, in what order

| # | Wave | Files | Scope keyword | Depends on |
|---|---|---:|---|---|
| 1 | Check 81 on BOTH axes: `active[]` string form + dot-leading path tokens + 5 test legs + 2 mutation proofs | 3 | **`pack-only`** | — (parallel) |
| 2 | Check 68 install-path-aware ladder + git-tracked scope + NOI-1 + 6 records + 2 STRIPs + 2 mirrors | 8 | **`pack-only`** | — |
| 3 | Check 95 + **34-entry** allowlist + 5 exclusion prefixes + registry/count/ledger/README + new test + 45 STRIPs + 8 mirrors | 24 | **none claimable** | W2 |
| 4 | Check 43 self-tree leg + client gate 3-site fix + 10 STRIPs + 6 `target:` records + L8 | 14 | **none claimable** | W3 |

**No wave is gated on a decision.** D-1 is closed at (b); §9 records every other decision.

**Totals.** 1 new check (95). **3 matcher fixes** — Check 81's `active[]` shape leg, Check 81's
path-token prefix class, Check 43's self-tree leg. Allowlist growth: **34** `_CHECK_95_ALLOWLIST`
entries (26 residue + 8 tier-1), +6 `pack-ops/.dangling-ref-allowlist.txt` records (51 → 57), +6
client `target:` records (13 → 19 target / 100 total). **57 reference edits** — 45 bareness STRIPs
+ 2 Check-68 dangling STRIPs + 10 client STRIPs. 12 Check-71 mirror propagations (2 in W2, 8 in
W3 — `boundary-investigation` twice). 3 client-gate defect fixes + 1 walk prune + 1 test-mirror
`lstrip` fix. 1 new test file, 1 new test leg (L8), **15 mutation/bite probes** (W1 ×2, W2 ×3,
W3 ×5, W4 ×5 minus the shared originating-mechanism probe counted once per side). **Zero deferrals.
No new BD. No phase 2. No v11.1 item. No Check 96.**

**What changed from `PLAN-BD-288-FINAL.md`:**

| # | Change | Where |
|---|---|---|
| 1 | **D-1 closed at (b)** — W3 is no longer gated; the "do not start until OI-R1 closes" block is removed | §2.1, §6, §9 D-1 |
| 2 | **ROI-6's fact 1 restated** to its measured form, placed at the constant | §6.4, §9 D-2 |
| 3 | **NEW: the Check-81 path-token dot-leading blind spot folded into W1** — one character, measured safe, with 2 new test legs and a second mutation proof | §4 (rewritten), §9 D-3, EP-25…EP-28 |
| 4 | W1 grows 2 files → 3 (`test-validate-pack-check-82.sh` moves RUN-ONLY → EDIT) and its cycle-fit is re-argued | §4.1, §4.7 |
| 5 | §9 converts from an open-item list to a decision record; every item closed by taking this plan's own recommendation | §9 |

**What changed from the original `PLAN-BD-288.md`** (carried forward from the FINAL revision, so a
reviewer who read the original knows what to re-check):

| # | Change | Where |
|---|---|---|
| 1 | Check 95's ladder gains its missing **tier 1** and `_CHECK_95_ALLOWLIST` grows 26 → 34 | §2.1, §6.2, §6.4 |
| 2 | Check 95's expected OK line corrected `35/269/26/11/16/0` → `35/224/197/8/19/0` | §6.9 |
| 3 | Check 95 probe 1's magnitude corrected `75` → **189** (not 197 — that is the CLEAR count) | §6.9 |
| 4 | Check 95's walk gains the `walk &= set(rels)` intersection the git-tracked claim requires, and a probe that proves it | §6.2, §6.9 probe 5 |
| 5 | Check 68's expected OK line corrected: `764` → the real 1836-total line; the six-term ledger relabelled as an analytic decomposition; four terms BINDING, the split diagnostic | §5.9, §9 D-4 |
| 6 | §8's W2 decomposition guidance corrected: (a) ladder and (b) parser are **not** separable | §8 |
| 7 | Client record 6's `reason:` wording marked **[BINDING]** for Check 43, with the gate assertion | §7.5, §7.10, §9 D-8 |
| 8 | `pack-ops/.docs-gate-allowlist.txt` → `project-template/scripts/.docs-gate-allowlist.txt` | §2.7, §7.6 |
| 9 | The 77-vs-75 KEEP delta reconciled explicitly | §6.5 |
| 10 | Worst-case install profile corrected `python-only` → `none-detected`, with the superset proof | §7.8 |
| 11 | §7.6's 10-row table provenance corrected (the grep yields 9 rows; `:425` matches `base`) | §7.6 |

**Against BD-288's acceptance criteria** — every clause is covered:

| Acceptance clause | Where it lands | Evidence |
|---|---|---|
| bareness axis over the 8 non-installed `supporting-docs/` + `README.md` + pack-root trinity + per-CLI operating docs | W3 | walk measured at 35 files / 441,529 bytes (EP-10) |
| exclusion set intact and code-enforced | W3 §6.3 | 5 wholesale prefixes; the 2 they drop measured (EP-10) |
| measure-then-bound: full occurrence list, per-occurrence KEEP/STRIP, fix-recipes, allowlist sized EXACTLY with one-line rationales, verified post-fix state | W3 §6.4, §6.5, §6.9 | 122-record census reconciled to the ladder's FAIL set; 45 STRIPs set-identical to the pre-STRIP FAIL set; **leave-one-out: zero redundant entries, necessity sum 189 == the empty-allowlist probe**; post-fix `FAIL=0` (EP-23) |
| git-TRACKED candidate set with lenient SKIP | W2 §5.4, W3 §6.2 | the intersection is explicit and probe-5 proves it (EP-24) |
| Check-68 basename fallback no longer resolves a qualified path whose own path does not exist | W2 §5.2 | hardened ladder measured: `basefall` 299 → 0 (EP-17) |
| client twin reconciled under mirror-but-customize as a separate project-side copy | W4 §7.6 | explicitly NOT `git ls-files`, with the pack's own test comment quoted |
| a per-check test authored and wired so Check 42 passes | W3 §6.9 | wiring is disk-derived; `--assert-coverage` is the proof (EP-1); no workflow edit exists to make |
| `validate-pack.py` header check-count prose + README count updated in lock-step | W3 §6.6 | §2.6's correction: the real surface is `core.py`'s ledger + constant + README ×2 (EP-8, EP-21) |
| a regression test reproducing the original mechanism | W3 probe 4, W4 probe B | bare-ref-to-a-moved-file must FAIL |
| **Check 81's FAIL leg demonstrably fires against the string form**, with `dashboard-render.py` and `DASHBOARD-SPEC-PACK.md` left consistent | W1 §4.4 | T7 + mutation probe 1; both consumers recorded as verify-only (EP-6) |
| **Check 82's trigger re-verified against the same reality and fixed if it shares the inertness** | W1 §4.2b, §4.4 | **It did share it — on the other axis.** Check 82's trigger is `Status:`-keyed (so the `active[]` defect does not reach it), but its `surface → BDs` map consumes `_CHECK_81_PATH_TOKEN_RE` and was blind to every dot-leading surface. Fixed, and proved by T6 + mutation probe 2 + the measured `4 → 5` shared / `63 → 69` distinct transition (EP-25…EP-27) |
| full battery green: both CI jobs + `PACK_VALIDATE_DEEP=1` + `build.sh --verify` + the shard plan | §1.6, every wave | measured baseline `PASSED — all checks clean`, 2.40–2.54 s (EP-3) |

**Note on the last two rows.** In the FINAL revision, Check 82's acceptance clause was satisfied by a
recorded *no-change* verdict — Check 82's trigger is Status-keyed, so the `active[]` inertness never
reached it. That verdict was correct on the axis it examined and incomplete on the other: the
measurement in EP-25…EP-27 shows Check 82 *was* inert on every dotfile surface, through a shared
extractor. W1 now fixes both, which is what the clause "re-verified against the same reality and
fixed if it shares the inertness" actually asks for.

---

## 12. Rules-Applied Verification Block

| Rule | Verification evidence (quoted, not summarized) | Conclusion |
|---|---|---|
| **agents-never-commit** | Every git verb I issued was read-only: `rev-parse`, `status --porcelain`, `ls-files`, `grep`. No `add`/`commit`/`push`/`tag`/`stash`/`rm`/`mv`/`reset`/`restore`/`checkout`/`clean`/`merge`/`rebase`/`cherry-pick`/`revert`/`am`/`apply`/`branch`/`switch`/`worktree`/`config`/`remote`/`update-ref`/`update-index`/`pull`/`fetch`/`gc`/`filter-branch`/`notes`/`replace` was run. I did not enter any `.claude/worktrees/` checkout. Final canonical state, measured at exit: `git status --porcelain` → ` M pack-ops/session-state.json` (the pre-existing Pack Chat snapshot, byte-untouched by me); `git rev-parse --short HEAD` → `47f8467`. The three new decisions changed nothing about this: every regex measurement ran in-process against strings read from the repo, monkey-patching a module attribute in my own Python process and restoring it, never editing a file. My only write is this document. | **COMPLIANT** |
| **per-action-approval-sub-agents** | My only write outside the OS temp roots is `/Users/david/.local/state/optiquity-pack-handoff/bd288-planreconcile-20260823-215731/PLAN-BD-288-READY.md` — my owned dir, authored by `cat >` / `cat >>` heredocs because `Write` is not in this session's grant. Section drafts and every measurement script live under `/private/tmp/claude-501/.../scratchpad/planrec/`, the session scratch root (an OS temp root). I ran no `rm`, `rm -rf`, `rmdir`, `unlink`, `git rm`, `find … -delete`, `mv`, `shred` or `truncate` anywhere — not against the repo, not against another agent's handoff dir, not against a shared root; the prior `PLAN-BD-288-FINAL.md` in my own dir was READ to assemble this document and left in place, not overwritten or deleted. Other agents' dirs were READ-only throughout. | **COMPLIANT** |
| **empirical-evidence-blocks** | 28 blocks, EP-1 … EP-28 (§10), each carrying the actual command, verbatim output (counts, paths, quoted OK lines, exit codes — not paraphrase), HEAD `47f8467`, an interpretation, and a terminal SUPPORTED / PARTIAL / NOT-SUPPORTED verdict, labelled `[re-derived]` / `[carried + confirmed]` / `[derived]`. The four blocks added for this revision (EP-25…EP-28) back every state-claim in the new §4.2b: the blind spot itself, the superset property, the absence of the suspected false-positive class, the three-scope population, the zero structured-ness flips, the one new Check-82 WARN, the complete encoding-surface set, and the runtime. No block is empty. | **COMPLIANT** |
| **ci-guard-measure-then-bound** | Applied twice — once to Check 95 (carried forward) and once, freshly, to the Check-81 regex. **For the regex: (1) MEASURE FIRST** — both patterns run over named probes, over all 288 backlog entries, and over the exact field set the two consumers read (EP-25, EP-26), *before* proposing the change. **(2) CATEGORIZE** — every newly-tokenizing shape enumerated and classified: genuine dot-leading paths (KEEP, the point of the change), bare extensions (measured to yield NOTHING), and two prose shapes (ellipsis, slash-joined shorthand) classified as pre-existing because the current regex already produces them for non-dot spans. **(3) FIX-RECIPE** — one character in the FIRST character class, with an explicit [BINDING] instruction not to touch the continuation class, the alternation, or the placeholder terminator (the alternation is what bounds the false positives). **(4) SIZED EXACTLY** — the change is the minimum that admits a leading dot; corpus-wide, **0** existing tokens change count, so nothing is admitted beyond the target class. **(5) VERIFY POST-FIX** — both checks executed in-process under both regexes: Check 81 byte-identical, Check 82 `4→5` shared / `63→69` distinct, FAIL count 0 under both (EP-26). **For Check 95** the same five steps are at §2.1/§6.4/§6.9, with leave-one-out necessity (zero redundant entries; necessity sum 189 == the empty-allowlist probe) as the step-4 proof, and `walk &= set(rels)` plus probe 5's untracked-file leg as the git-TRACKED requirement (EP-23, EP-24). | **COMPLIANT** |
| **declare-verify-backing** | The BLOCKER I inherited was this rule failing on a plan — a recorded mapping (26 entries ⇒ 0 FAILs) with no backing in the specified mechanism — so I hold every projection here to the mechanism it specifies. For the new work: I did not assert that the regex is safe, I **ran both patterns** and published the token multisets (EP-25); I did not assert Check 81 is unaffected, I **executed** it under both and compared its OK line byte-for-byte (EP-26); I did not assert Check 82 cannot fail, I **read its source and counted emitters**, and recorded that its one `fail(` occurrence is inside its docstring (EP-27). The same discipline flags the reverse case at §5.9: where a number could not be produced by the specified mechanism I did not carry it — four Check-68 terms are BINDING and the split is diagnostic, with §9 D-4 stating what I could not reproduce and what I ruled out. Note the shape §4.2b closes: `backlog/_rules.md:58` *declares* "≥1 backtick repo-relative path token" while the matcher could not extract a whole class of them — a declared contract with no backing in the mechanism, one level up from the check itself. | **COMPLIANT** |
| **ci-check-runtime-compounding** | The budget every timing claim is measured against is named and quoted from the SSOT: `core.py:125–126` — `RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0` (WARN), `RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0` (hard FAIL). Battery measured this pass at `real 2.54` / `real 2.40`, ~7.5 s headroom, no budget line emitted (EP-3). The new regex change is measured, not estimated: 200 full passes over every active `File/Symbol` field give CURRENT 0.030 ms vs WIDENED 0.029 ms (EP-28) — a character-class widening is O(field length) and adds no backtracking path, over an unchanged ~16-field candidate set. Carried-forward costs likewise measured: sibling parser 0.128–0.132 ms; `_git_tracked_relpaths` 10.792 ms, which is why §5.4 threads the existing `rels` through instead of a second `git ls-files` (net −2.1 ms); `dest_to_source` built ONCE before the file loop; Check 43's self-tree patterns module-precompiled. | **COMPLIANT** |
| **enumerate-encoding-surfaces** | For the new edit I enumerated the surfaces encoding `_CHECK_81_PATH_TOKEN_RE`'s expected state and checked each rather than assuming (EP-27): the constant + its ~35-line grammar comment (EDIT); `test-validate-pack-check-81.sh` (EDIT — T10 + mutation 2); `test-validate-pack-check-82.sh` (**EDIT — this is the one a file-count-driven reading would miss**: its five existing legs pass unchanged because they assert on non-dot synthetic surfaces, so the file does not *break*, but its coverage is now incomplete and T6 is the leg that proves the fix bites). Three candidates measured NOT to be surfaces, each recorded with its evidence: `scripts/validate-pack.py:754` (symbol enumeration, no grammar), the Check-80 `_DOC_CONSTANT_TWINS` registry (5 enrolled twins, this constant not among them), and `backlog/_rules.md:58` (prose contract with no char-class detail, made true rather than stale by the fix). Carried forward: the four count surfaces, the 30 count-invariant tests, Check 71's 12 mirror files, Check 66's allowlist snippets, and the four surfaces missing from my inputs and added in the FINAL revision (tier 1 of the ladder; the client allowlist as a Check-43-walked surface; Check 68's OK-line message; the fullscan test's mirror `lstrip`). | **COMPLIANT** |
| **verify-full-ci-suite** | §1.6 defines the battery for every wave and it is not `validate-pack` alone: `validate-pack.py`, `PACK_VALIDATE_DEEP=1`, **both** workflow jobs including the dynamic `tests` matrix, `ci-shard-plan.py --assert-coverage`, `test-fixtures/build.sh --verify`, the wave's per-check tests, and the easy-to-miss set. W1's gate now names **both** wired tests plus Checks 83/92 on both, and states the expected Check-82 OK-line transition so the +1 WARN is verified rather than discovered. W4 additionally runs the 8-leg fullscan test and `validate-docs.sh --self-test`, with §7.7 recording that its exit code is `rc=0` both before and after the fix so the legs must be read. Baseline greenness measured, not assumed (EP-3, EP-17). | **COMPLIANT** |
| **dependency-direction-placement** | Unchanged by the three decisions, and re-checked: W1's three files are all pack-side (`scripts/lib/validate_checks/cross_bd.py`, `scripts/tests/…`), so the new edit creates no cross-boundary artifact and claims `pack-only` truthfully. W4's client leg remains a SEPARATE project-side change; measured, there is exactly ONE `.docs-gate-allowlist.txt` in the repo and it is project-side (EP-9). No code, constant, or helper is shared across the boundary even where behaviour is analogous — §7.6 keeps the client gate on a pruned `os.walk` and §6.2 makes the opposite call for the pack-side check, with the asymmetry named as deliberate. `_SANCTIONED_PACK_SIDE_SHIPPED` is untouched and not grown. | **COMPLIANT** |
| **boundary-investigation-precedes-pack-defaults (P-missed-7)** | No project-side change is added by this revision — the new edit is entirely pack-side. The carried-forward W4 work still uses the project-side SSOTs I read in the shipped gate rather than any pack analogue: `_commit_record`'s allowlist mechanism, `DANGLING_ANCHORS`, the `run_selftest` `gate()` harness EXTENDED rather than replaced, and the existing fullscan test extended by L8 rather than a new pack test authored. The pack-repo-anchor hazard at `docs/pack/METHODOLOGY.md:12` is resolved with a project-side `target:` record rather than by importing pack anchor vocabulary into `DANGLING_ANCHORS` (adding one would clear 6 lines to fix 1). §9 D-8's fix stays on the project side (record wording) rather than weakening the pack gate. | **COMPLIANT** |
| **public-bound-no-leak** | This plan lives outside the repo and is not a client/public surface; it contains neither the target project's name nor its domain vocabulary — only path strings, check names, basenames and counts. The new edit touches `scripts/` only and adds no prose to any shipped surface. Every edit directed onto a client/public surface elsewhere is a path qualification, a path correction, or a count bump — no new prose vocabulary anywhere; the trinity STRIPs are constrained to add nothing but the directory prefix (§6.5). `.github/` is not edited by any wave (§2.2), which removes a leg-2 surface from the blast radius entirely — note that W1 now makes `.github/workflows/validate-pack.yml` *visible to Check 82 as a claimed surface*, which is a WARN about a path string in a backlog entry, not an edit to that file. Check 93 is in every wave's gate and green in the measured baseline. | **COMPLIANT** |
| **operating-docs-no-history-no-bloat** | This plan is a REFERENCE doc, so it may and does carry history. Nothing it directs an actor to WRITE into an operating doc adds history. The one new piece of directed prose is §4.2b's grammar-comment update, and it is specified as *"one clause recording that the first character class admits a leading `.` … Keep it terse and forward-facing — no dated note, no 'BD-288 did X'"* — a live statement of what the code does. The D-2 text placed at `_CHECK_95_ALLOWLIST` is likewise a forward-facing statement of why two constants overlap, not provenance. **No deferred or unimplemented feature is described in any shipped file** — no Check 96, no W0, no W5, no phase 2. §9 D-10 explicitly declines to add an explanatory parenthetical to `boundary-investigation/SKILL.md` on terseness grounds. | **COMPLIANT** |
| **pack-repo-code-comment-deferrals** | This plan directs **zero** deferral comments into pack-repo source: nothing is deferred — §9 is a decision record with no open item — so no `# TODO(scope): TD-TBD`, `# KNOWN GAP(severity): TD-TBD` or `# VERIFY(source): TD-TBD` marker is called for, and correspondingly no plain `# TODO`, `# fix later` or `# FIXME` either. Every comment the plan specifies (§4.2b's grammar clause, §5.3's helper docstring, §5.5 and §6.3's constant-asymmetry notes, §6.4's D-2 text, §6.6's ledger line, §7.2's constant rationale, §7.8's S9-roster provenance note) states current, implemented reality. The scratch Python behind EP-10/13/17/19/23/25/26/28 lives only under the OS temp root and is not proposed for the repo. | **COMPLIANT** |
| **graph-first-context** | Graph present and used for the one genuine P1 DISCOVERY question of the reconciliation pass — *"what else consumes `_CHECK_40_ALLOWLIST`, and what does the graph say Check 40 uses?"* — with the injected absolute path verbatim (EP-20): `Degree: 1`, `<-- check_bare_pack_ops_refs (Check 40) [references]`, and Check 40's `Degree: 7` listing exactly four `--> [calls]` helpers and **no allowlist edge**. That answer is load-bearing twice and is the evidence for §1.5's BINDING caveat. **For this revision's new work I used grep/Read and in-process execution rather than the graph, and that is the correct instrument, not a shortcut:** the question was not "what relates to X" but "what does this regex extract from this corpus, and what do its consumers do with the result" — exact bytes and executed behaviour, carve-outs (i) and (iv). I did run the discovery half properly first: `git grep -n '_CHECK_81_PATH_TOKEN_RE' -- .` to establish the consumer set before reading any of them (EP-27), which is what surfaced `validate-pack.py:754` as a candidate surface to check and clear. No query errored, so G2 fallback was not needed. | **COMPLIANT** |
| **deferral-is-scope-creep** | Nothing unblocked is pushed out, and this revision is where the rule bit hardest. The new regex defect is **pre-existing and out of BD-288's original scope**, and I applied the size/blocked/fit test rather than the convenience answer: it is not SIZE (one character), not BLOCKED, and LOGICAL FIT runs *toward* W1 (same check family, same defect class, the file W1 already opens, and shipping without it leaves the guard blind to every dotfile surface). So it lands now, in W1 — §9 D-3 records the reasoning. All eleven adversarial findings likewise remain scoped into the wave they belong to. The only work I recommend NOT doing is §9 D-6 option (b) (structuring seven unrelated BDs' fields), defended on LOGICAL FIT with file evidence: those entries pre-date BD-288 and are unrelated to the guard family. The §6.11/§7.11 splits and §4.7's (a)/(b) separability note are named as fallbacks explicitly not to be taken pre-emptively, not as deferrals. No follow-on BD is recommended anywhere. | **COMPLIANT** |
| **no-deferral-without-user-direction** | Every recommendation lands in BD-288, in v11.0. No v11.1 target, no follow-on BD, no phase 2. The phrase "resolve during implementation" appears nowhere — §4.7, §5.10, §6.10 and §7.11 all argue cycle fit on the ground that open discovery is gone. Where I override an input's mechanism (§2.1's tier-1 fix, §2.3's sibling parser) or add scope (§4.2b's regex), the work lands in the same wave, in this BD. There are no open gates left to defer behind. | **COMPLIANT** |
| **open-item-surfacing** | Twelve items surfaced, now as a decision record (§9, D-1…D-12), each with (1) context including the measurement that produced it, (2) my OWN options — four for D-1, three for most, two for D-9/D-10/D-12 — and (3) an evidence- or logic-based recommendation naming the evidence, followed by the decision and where it is applied. None relies on memory; none defers work to another or a new BD; none recommends opening one. Under the standing authorization I took my own recommendation on every item, including the two the prior revision held back: D-1 (the tier-1 shape, previously a user gate) and D-12's contingency, which is now satisfied. **I made no call on measurement alone where evidence was absent** — there is no "no recommendation can be given" item left, and D-4 is the one place I explicitly publish a figure I could not reproduce rather than silently choosing, with what I tested and ruled out. Where I differ from the adversarial pass I say so with the measurement: its 8-vs-10 split (corrected to 8 necessary + `LICENSE.md` + 9 absent), its probe-1 magnitude (197 is a CLEAR count; the FAIL count is 189), its N-3 handling (superset proof), and its post-fix Check-68 split (not adopted). | **COMPLIANT** |
| **memory-not-an-ssot** | Every rule and contract relied on was read from the live in-repo SSOT at `47f8467` — the pack-root `CLAUDE.md` `## Pack memory`, `backlog/BD-288.md` (the acceptance criteria quoted in §11), `backlog/_rules.md` (the File/Symbol contract quoted in §4.1), `README.md` — and, decisively, **the check bodies themselves** rather than any document's account of them. That produced the BLOCKER (tier 1 read at `boundary_refs.py:1897–1917`), and it produced this revision's new work too: I read `_CHECK_81_PATH_TOKEN_RE`'s actual pattern and its 35-line grammar comment, `_check_81_field_is_structured()`'s marker-before-token ordering, and both consumers' emitter calls, rather than trusting the reported symptom. The reported figures (98 tokens / 90 entries; 60 tokens / 28 fields) were **re-measured, not adopted** — §4.2b publishes my own three-scope table and explains why all three counts differ. | **COMPLIANT** |
| **bounded-review-fix-cycle** | Each wave is sized to one cycle (max 2 review/fix pairs + 1 final reviewer pass) and the argument is made in terms of REMAINING DISCOVERY, not file count. **§4.7 re-argues W1's fit with the addition and answers the question explicitly: W1 still FITS** — the measurement the coder correctly declined to make is done here (one character named exactly; superset property proved corpus-wide; the suspected false-positive class measured absent; blast radius bounded by reading both consumers; zero structured-ness flips; exact before/after OK lines for both checks), leaving a coder to paste a character and write two legs against harnesses that already exist, with T4/T5 as direct models for T6. §4.7 also records the (a)/(b) separability fallback and why it should not be taken pre-emptively. §5.10, §6.10 and §7.11 carry forward unchanged, W3's now free of its gate contingency (§9 D-12). §8 states what a twice-dirty review leaves behind and that the next actor is `pack-architect`, never a third fix pass. | **COMPLIANT** |
| **reconciliation-instance-independence** | I am the fresh third instance, spawn `planner-bd288-reconcile`, author of none of the design, the superseded plan, or the adversarial review — and I applied the same independence to the two inputs that arrived with this revision. The reported regex defect I **reproduced from the source** rather than accepting (EP-25), and the reported population figures I **re-measured and did not adopt**, publishing three scopes and explaining the divergence rather than picking one (§4.2b, EP-26). I likewise did not accept the implicit framing that the fix is risky: I measured the specific risk named (bare extensions) and found it absent, then measured two shapes nobody had named and found them pre-existing. Carried forward from the prior revision: three corrections to the adversarial review (its 8-vs-10 split, its probe-1 magnitude, its N-3 handling), one figure declined with reasons (D-4), and independent reproduction of everything it got right. | **COMPLIANT** |
| **rules-applied-verification-block** | This table: every rule named in the calling prompt's "Rules in force" block, each with quoted evidence — actual command output, file path, count, or quoted line — and a terminal conclusion. No entry is empty; no entry is AMBIGUOUS; no entry is N/A. | **COMPLIANT** |
| **spawn-unique-naming** | Spawn name `planner-bd288-reconcile` — shape `<role>-<bd>-<facet>` = `planner` + `bd288` + `reconcile`, lowercase kebab, 23 characters, matches `^[a-z0-9][a-z0-9-]{2,47}$`, and is distinct from every other live spawn in this session (`architect-bd288-adversarial`, `architect-bd288-fullscope`, `architect-bd288-guardbite`, `architect-bd288-reconcile`, `coder-bd288-agenttoolgrant`, `coder-bd288-hygiene`, `planner-bd288-adversarial`, `planner-bd288-waves`, `reviewer-bd288-agenttools`, `reviewer-bd288-cycle1`, `reviewer-bd288-cycle2`) — in particular distinct from `architect-bd288-reconcile`, which shares the facet but not the role token. This document is my second output under the same spawn, not a new spawn. | **COMPLIANT** |

---

END OF PLAN-BD-288-READY
