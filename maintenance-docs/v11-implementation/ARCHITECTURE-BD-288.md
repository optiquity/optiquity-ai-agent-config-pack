# ARCHITECTURE-BD-288-FINAL — CI guards that do not bite

**Author:** `pack-architect`, spawn `architect-bd288-reconcile`
**Date:** 2026-08-23
**Tree:** `/Users/david/Developer/optiquity-ai-agent-config-pack`, branch `main`
**HEAD at every measurement:** `47f8467`
**Working tree:** one modified file, `pack-ops/session-state.json` (Pack Chat's snapshot), out of
scope for everything here; nothing else modified.
**Status:** FINAL. All 13 adversarial findings resolved; all 14 design decisions (OI-1…OI-8,
ROI-1…ROI-6) closed by the user. Input to the planner stage.

This is a **complete standalone design**. A planner and coders work from this file alone. It does
not require reading `ARCHITECTURE-BD-288-FULLSCOPE.md`, `ADVERSARIAL-BD-288.md`, or
`ARCHITECTURE-BD-288-RECONCILED.md`.

**Tool note.** The `Write` tool is unavailable in this session (`No such tool available: Write`).
This document and its three artifacts were produced with Bash heredocs into my own owned handoff
directory. No repo file was written; no denied capability was routed around.

---

## 0. Artifacts

| Artifact | Location | Contents |
|---|---|---|
| **`c288-check95-allowlist.json`** | **this directory (NEW)** | the **26** `_CHECK_95_ALLOWLIST` entries under the decided ROI-3=(b) walk, each with its occurrence count, its **measured citing files**, and a ready-to-paste `reason:` string — the ROI-6 requirement, pre-derived so the coder does not re-measure |
| **`c288-client-triage.json`** | this directory | all **29** client-side occurrences with a KEEP/STRIP verdict, fix recipe, visible-on profiles, and rationale — the client twin of `c95-triage.json` |
| `c95-triage.json` | `bd288-architect2-20260823-141506/` | the 122 pack-side bareness would-FAIL occurrences with per-occurrence verdicts. **Superseded in count by ROI-3=(b)** (120 now in scope) but every retained record is unchanged and re-verified; the 2 dropped records are the `changelog/_rules.md` `vN.md` pair |
| `c68-residue.json` | `bd288-architect2-20260823-141506/` | the 13 refs unresolved under the install-path-aware resolver |
| `c68-fallback-only.json` | `bd288-architect2-20260823-141506/` | the 299 qualified refs resolving only through Check 68's basename fallback |
| `c40-census.json` | `bd288-architect2-20260823-141506/` | the raw 277-hit bareness census |

**Evidence convention.** Every state-claim carries an Empirical-Evidence Block (`EV-n`) with the
command, verbatim output, the SHA, an interpretation, and a SUPPORTED / NOT-SUPPORTED / PARTIAL
conclusion. Blocks marked **[re-verified]** were re-run in this final pass because a decision
changed their inputs; blocks marked **[carried]** were measured earlier at the same SHA and are
reproduced here so this document stands alone.

---

## 1. Decision record — everything is closed

### 1.1 The 13 adversarial findings

| # | Finding | Resolution | § |
|---|---|---|---|
| B-1 | the wave map landed Check 95 one wave ahead of its 45-occurrence fix-set → 45 hard FAILs | guard + fix-set are ONE commit, three times over | §7.1 |
| B-2 | Check 71 skill-mirror byte-identity absent from the encoding surfaces | 12 mirror files enumerated per wave; Check 71 in the battery | §6.6, §8 |
| M-3 | OI-1(b) radius unmeasured, wrong matcher | measured with Check 43's own matcher **including its fence-skip leg**: 14 / 5 KEEP / 9 STRIP | §5.1 |
| M-4 | OI-1(b) broke the file-contention analysis | the coupling is stronger than stated — its fix-set is also the client gate's fix-set | §7.1, §7.3 |
| M-5 | client residue omitted the gate's allowlist leg | ground truth from the REAL gate: **10** on the overlay, not 61 or 23 | §5.3 |
| M-6 | 32 of 61 client occurrences had no verdict | all **29** carry an individual verdict in `c288-client-triage.json` | §5.4 |
| S-7 | runtime conclusion void under OI-4=(a) | restated for the chosen option against the named budgets | §9 |
| S-8 | `changelog/` exclusion mis-cited its sibling | **dissolved by ROI-3=(b)** — the exclusion is now bare `changelog/`, which IS the sibling's shape; no new prefix form exists anywhere in the design | §4.3, §5.5 |
| S-9 | `_CHECK_95_ALLOWLIST` basename-keyed | user decision (c), reaffirmed as ROI-6=(a); justification recorded | §4.3 |
| N-10 | "audience-aware" overclaims | reworded to "install-path-aware" throughout | §3 |
| N-11 | stale Check-96 / W6 / "Optional W0" | struck; none appears anywhere in this document | §7 |
| N-12 | Check 83 + Check 92 constraints on a new test | stated with their bug classes; L8 pre-audited against both | §6.5, §5.6 |
| N-13 | acceptance criterion names a non-existent surface | the `core.py` ledger named as the surface that exists | §6.1 |

### 1.2 The 14 design decisions — all CLOSED by the user

| ID | Decision | Effect on this design |
|---|---|---|
| OI-1 | **(b)** extend Check 43 with a `project-template/` prefix leg | §4.4 — implemented as a SEPARATE constant, never a `_CHECK_43_PACK_INTERNAL_PREFIXES` edit (§5.2) |
| OI-2 | **(b)** triage the client residue against a real install, not the overlay alone | §5.4 — fulfilled by the six-profile matrix + ROI-2's standing L8 leg |
| OI-3 | **(a)** pack-storage form in the pack-side `boundary-investigation/SKILL.md` | §4.2 |
| OI-4 | **(a)** NO memoization of `_build_basename_index()` | §9 — no W0, no cache, no reset helper |
| OI-5 | **(a)** NO git-ref existence guard | no Check 96, no W6 |
| OI-6 | **(a)** Check 9's missing per-check test is noted, not worked | not in scope; recorded here so it is visible, not lost |
| OI-7 | **(a)** allowlist `agent-run.sh`; do NOT broaden the shared anchor set | §4.3 |
| OI-8 | **(a)** allowlist the trinity shorthand; do NOT touch the qualified-path regex | §4.3 |
| **ROI-1** | **(b)** widen the conditional to "the citing file is in the client-installed walk"; drop the `startswith("project-template/")` guard | §4.4, §5.1 — population 11 → **14**, STRIP set 6 → **9**, post-fix residue still **0** (EV-2) |
| **ROI-2** | **(b)** accept the profile matrix AND add the **L8** leg to the standing fullscan test | §5.6, §6.4 row 13, §7.4 — folded into W4; W4 still fits one cycle (EV-4) |
| **ROI-3** | **(b)** exclude the history trees **wholesale**, per the literal constraint | §4.3, §5.5 — walk 37 → **35**, allowlist 27 → **26**, prefixes become bare `backlog/` + `changelog/`, post-fix FAILs still **0** (EV-1) |
| **ROI-4** | **(a)** ship W3 merged; §7.5's split stays a live fallback | §7.4, §7.5 |
| **ROI-5** | **(a)** fix the one fenced instance as content; add no new guard | §5.4 STRIP class C |
| **ROI-6** | **(a)** basename allowlist keys stand | §4.3 — with the two distinguishing facts recorded as the user directed |

**One NEW open item** was surfaced by applying ROI-3=(b) and is NOT silently resolved: see
**NOI-1** (§11) — `changelog/_rules.md` ends up gated on neither axis.

---

## 2. Settled inputs, carried forward and NOT re-derived

Independently reproduced across the design, adversarial, and reconciliation passes at this SHA:

- the live pack-doc surface under no bareness gate; **299** fallback-only qualified refs with
  **282** would-FAIL on naive removal; the raw bareness census — **277** hits over the 37-file
  walk, **269** over the 35-file walk ROI-3=(b) decided (EV-1 gives both).
- the install-path-aware ladder's **13**-item residue and its per-token verdicts (6 new
  `pack-ops/.dangling-ref-allowlist.txt` records).
- the three client-gate defects, verbatim at `validate-docs.sh:426`, `:282-291`, `:425`.
- Check 81 inert against live data; **Check 82 NOT affected** and biting; every `active[]` string
  member leads with its BD-ID.
- OI-3's evidence, the Check-80 doc↔constant twin, and the `README.md` ×2 sizing.

Everything a user decision touched has been re-measured in §5 and is labelled **[re-verified]**.

---

## 3. The shape of the fix

All four defects share one root cause: **reference resolution in this repo is not
install-path-aware.** A pack doc and a client doc citing the same file must cite it by different
paths, and no current mechanism knows that. Check 68 papers over it with a basename fallback that
also swallows genuinely-moved files; the bareness axis does not run on the 35 files where the
audience is mixed; the client twin carries the same fallback plus two of its own.

"Install-path-aware", not "audience-aware": leg A of the new resolver is an **unconditional
union**, not keyed on who is citing. Narrowing it by citer would break real references — 105 of its
247 resolutions come from non-`project-template/` citers, all legitimate. The mechanism is correct;
only the old label overclaimed.

One new concept — an install-path-aware resolution leg derived from the existing
`_CLIENT_INSTALLED_FILES` inventory — reused rather than two independent mechanisms.

---

## 4. The four fixes, specified

### 4.1 Check 81 — matcher decoupled from its data

`_check_81_active_bd_ids()` (`cross_bd.py:706-710`) admits an `active[]` member only when it is a
`dict` carrying a `bd` key. The live snapshot has carried plain strings continuously since
2026-07-16, so the FAIL leg cannot fire against any member of today's data: the check registers,
prints OK, and gates nothing.

**The data is correct; the matcher is the defect.** `dashboard-render.py` does
`" ".join(session.get("active", []) or [])` (raises on a dict member) and
`pack-ops/DASHBOARD-SPEC-PACK.md` is a verbatim user-owned spec documenting the string form.
Neither is edited.

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

The leading anchor is evidence-derived: one historical member reads
`'BD-224 @ design pass … pack-lead (BD-25…'`, whose SECOND, mid-string BD-ID is **not** an active
BD, so a permissive `re.findall(r"BD-\d+", member)` would wrongly gate it. The dict leg is retained
because 32 commits of history carry that shape; this is not a mirror of a deleted SSOT (the SSOT is
the live `session-state.json`, unchanged), so `fail-loud-delete-old-source` does not read on it.

**Check 82 requires no change** — its trigger is `_check_81_iter_open_bds()` (`Status:`-keyed),
never `active[]`; it parses 63 surfaces and emits 4 real WARNs today. The acceptance criterion
"Check 82's trigger is re-verified … and fixed if it shares the inertness" is satisfied by that
verification with a **no-change** verdict, which the coder records rather than edits.

**Anti-vacuity is mandatory.** Against HEAD's snapshot the fixed matcher yields `{"BD-288"}` and
BD-288's own `File/Symbol` is structured, so the check would still PASS. A test asserting only
"the fixed matcher returns non-empty" proves nothing. The test MUST stage a synthetic snapshot
whose `active[]` holds a descriptive STRING naming a BD whose `File/Symbol` is bare, and assert a
**non-zero exit**; then mutation-prove it by restoring the dict-only matcher.

### 4.2 Check 68 — install-path-aware resolution

The bare-ref leg (`token in index`) is **unchanged** — resolving a bare reference through the
basename index is correct for a bare reference; bareness is Check 95's axis, not Check 68's.

```
# current
if (REPO_ROOT / token).exists():                        resolve   # direct
if Path(token).name in index:                           resolve   # <-- DELETE (blind to moved files)

# proposed
if (REPO_ROOT / token).exists():                        resolve   # direct
if (REPO_ROOT / "project-template" / token).exists():   resolve   # leg A: client-install prefix
src = _client_install_dest_to_source().get(token)
if src and (REPO_ROOT / src).exists():                  resolve   # leg B: install-map reverse
→ fall through to the existing anchor-window and allowlist escapes, then FAIL
```

Leg B reuses `_parse_client_installed_files()` (`boundary_refs.py:2847`), extended to return the
DEST column it currently discards; a new `_client_install_dest_to_source()` returns the reverse
dict. No new parsing, no new file read.

**Ledger:** `764 = 389 direct + 247 legA + 39 legB + 75 allowlist + 1 anchor + 13 residue`. Of the
13, **2 are genuine dead pointers** the fallback has been hiding —
`.claude/skills/boundary-investigation/SKILL.md:73-74`, citing
`project-template/docs/pack/INSTALL-PROCEDURES.md` and
`project-template/supporting-docs/METHODOLOGY.md`; neither exists, and
`project-template/supporting-docs/` is not even a directory. The other 11 are KEEP across 6 tokens
→ 6 new `pack-ops/.dangling-ref-allowlist.txt` records (51 → 57), each with a `reason:`.

**OI-3=(a):** rewrite the two cells to the **pack-storage form**
`supporting-docs/INSTALL-PROCEDURES.md` and `supporting-docs/METHODOLOGY.md`. The reader is a pack
agent in the pack repo, every other row in that table uses pack-storage paths, and under the new
ladder (a) resolves on the direct leg while the client form would resolve only on leg B. The
project-side twin already uses the client form — mirror-but-customize working as intended.

**Scope becomes git-tracked.** `boundary_refs.py:4190-4200` still enumerates via `root.rglob("*")`.
Convert to `_git_tracked_relpaths()` with a lenient SKIP when git is unavailable — the Check 53 /
63 / 69 idiom. Selection is identical on a clean tree (`project-template` 181/181,
`supporting-docs` 10/10, symmetric difference empty), so the change is behaviour-preserving and
removes only the environment-artifact exposure. **Runtime constraint:** Check 68 already calls
`_build_basename_index()`, which itself calls `_git_tracked_relpaths()`; derive the new scope from
that SAME result rather than issuing a second `git ls-files` subprocess (§9).

**Prefix-keyed allowlist audit (BD-288's explicit question).** `_CHECK_40_ALLOWLIST` is
basename-keyed and structurally immune to a directory prefix. `_CHECK_68_EXCLUDE_PREFIXES` and
`_CHECK_64_EXCLUDE_PREFIXES` are consulted on paths derived from a **bounded subtree**, neither of
which can contain an agent worktree. The Check-53 fragility is latent-unreachable, not live; the
carried-forward recommendation to leave them alone HOLDS, and the `git ls-files` conversion closes
the class structurally. **No allowlist assertion is designed.** (One narrowing of
`_CHECK_68_EXCLUDE_PREFIXES` is raised separately as NOI-1, §11 — it is a coverage question, not a
fragility one.)

### 4.3 Check 95 — the bareness coverage gap

**A new check, not a widened Check 40.** Widening Check 40's glob would require exempting the KEEP
basenames in `_CHECK_40_ALLOWLIST`, which is keyed on **basename alone** and consulted at
`boundary_refs.py:1899` with no path scoping — so a future bare `ARCHITECTURE.md`,
`CHANGELOG.md`, or `validate.sh` authored into a `pack-ops/` doc would then pass silently. Widening
buys coverage on 35 files by surrendering teeth on the 10 the check already guards.

**Specification.**

- **Number:** 95 (verified free; the `core.py` ledger ends "(Next free numeric ID = 95.)").
- **Name:** `check_live_pack_doc_bare_refs`, in `boundary_refs.py` beside its siblings.
- **Candidate set:** git-TRACKED only, via `_git_tracked_relpaths()`; SKIP-lenient (`ok(...)`,
  return) when it returns `None`.
- **Walk:** `_iter_operating_docs() ∪ supporting-docs/*.md ∪ README.md`, MINUS Check 40's walk,
  MINUS `_iter_client_installed_files()`, MINUS `_CHECK_95_EXCLUDE_PREFIXES`. Derived by
  subtraction, not a frozen list, so a doc that later becomes client-installed migrates from Check
  95 to Check 43 with no edit and no file can fall between them. **Measured: 35 files / 431 KB**
  (EV-1).
- **Exclusions, code-enforced — ROI-3=(b):**
  ```python
  _CHECK_95_EXCLUDE_PREFIXES = (
      "maintenance-docs/",
      "backlog/",              # WHOLESALE per the user's standing constraint
      "changelog/",            # WHOLESALE per the user's standing constraint
      "test-fixtures/",
      "scripts/tests/fixtures/",
  )
  ```
  Every prefix is a **whole tree**. No entry-shaped prefix (`backlog/BD-`, `changelog/v`) appears
  anywhere in this design — which is what dissolves S-8: `changelog/` here is byte-identical to the
  `changelog/` already in `_CHECK_68_EXCLUDE_PREFIXES`, so the constant now genuinely mirrors its
  sibling instead of claiming to. **This exclusion is LOAD-BEARING** (unlike the superseded
  entry-shaped form, which excluded nothing): it drops `backlog/_rules.md` and
  `changelog/_rules.md` from the walk (EV-1).
- **Matching:** reuses `_strip_code_blocks`, `_CHECK_40_BARE_REF_PATTERN`,
  `_CHECK_40_HYPERLINK_PATTERN`, `_check_40_context_has_anchor`, and the same-dir-legitimate rule
  verbatim. **No new regex.** Note Check 40 does NOT consult the Guardrail-2 per-line fence, and
  Check 95 inherits that: **no member of the 35-file walk carries a fence**, so the two are
  consistent by measurement, not by accident (EV-6).
- **Exemption:** a new `_CHECK_95_ALLOWLIST: dict[str, str]`, **26 entries**, sized exactly to the
  measured KEEP basename set, each carrying a one-line rationale.
- **Failure message:** file:line, the basename, the candidate-set triage, and the two remediations
  (qualify the path, or add an allowlist entry with a rationale).

**ROI-6=(a) — basename keys stand, and here is why.** `_CHECK_95_ALLOWLIST` keeps **basename keys**,
consistent with its three sibling constants, AND **each entry's `reason:` field names the measured
citing files** so a reviewer can see the intended scope even though the matcher is broader. The
26 `reason:` strings are pre-derived in **`c288-check95-allowlist.json`** — the coder pastes them
rather than re-measuring. Two facts distinguish Check 95 from Check 40, and the user directed that
both be recorded:

1. **The two exemption sets are disjoint by construction.** Check 95's walk is Check 40's walk
   SUBTRACTED OUT, so a `_CHECK_95_ALLOWLIST` entry can **never** exempt anything under
   `pack-ops/`. The `pack-ops/` blinding that ruled out widening Check 40 is structurally
   unreachable here — it is not mitigated, it is impossible.
2. **The real comparison is broad-key versus no check at all.** Check 40 walks the pack's operating
   core, where a silently-exempted bare ref is exactly the leak the check exists to catch. Check 95
   walks 35 files currently walked by *nothing*. A basename-keyed exemption inside that set trades
   a bounded over-exemption for coverage that does not exist today.

The residual is real and stated rather than hidden: within the 35-file walk, allowlisting
`ARCHITECTURE.md` exempts it in all 35 files, not only the 3 where it was measured. The `reason:`
fields naming the measured citers are the chosen mitigation.

**Fix-recipe for the 45 STRIP occurrences.** A blanket "1 candidate → qualify to it" recipe is
UNSAFE here and is not used: bare `ARCHITECTURE.md` at
`supporting-docs/AGENT_KICKOFF_TEMPLATE.md:128` ("Write `ARCHITECTURE.md` at the repo root") means
the CLIENT's architecture doc, and its single pack candidate
`maintenance-docs/v11-research/ARCHITECTURE.md` is a coincidental basename collision — qualifying
to it would inject a false pointer into a client-facing instruction. Every occurrence carries an
individual verdict in `c95-triage.json`. The 45 STRIPs are homogeneous and mechanical — 11
basenames, each a pack-audience actionable pointer to exactly one pack-side file, **all 11 targets
verified to exist at HEAD**:

```
  15  init-project.sh                -> scripts/init-project.sh
   9  PACK-AGENTS.md                 -> pack-ops/PACK-AGENTS.md
   6  validate-pack.py               -> scripts/validate-pack.py
   4  PACK-CHAT.md                   -> pack-ops/PACK-CHAT.md
   3  PACK-MEMORY-RATIONALE.md       -> pack-ops/PACK-MEMORY-RATIONALE.md
   3  no_leak.py                     -> scripts/lib/validate_checks/no_leak.py
   1  HELP-FRAGMENT-PACK.md          -> pack-ops/HELP-FRAGMENT-PACK.md
   1  SETUP-EXISTING.md              -> supporting-docs/SETUP-EXISTING.md
   1  test-migrator-core.sh          -> scripts/test-migrator-core.sh
   1  migrate-v10-to-v11.sh          -> scripts/migrate-v10-to-v11.sh
   1  test-customization-preserve.sh -> scripts/tests/test-customization-preserve.sh
```

**OI-7=(a):** allowlist `agent-run.sh` only. `AGENTS.md:273` reads "pack repo has no
`agent-run.sh`"; the existing anchors (`in the pack repo`, `at the pack repo`, `pack-repo`) do not
match that wording. Broadening the anchor to bare `pack repo` would over-clear across the trinity;
adding a `pack repo has no` phrase edits a constant three checks share for one occurrence.

**OI-8=(a):** one `.dangling-ref-allowlist.txt` record for `CLAUDE/AGENTS/GEMINI.md` with a
`reason:` naming it a prose shorthand. Narrowing the shared qualified-path regex for one cosmetic
case is the wrong risk/benefit; rewording touches the pack-root trinity and a deliberate
`pack-ops/MERGE-STRATEGY.md` table cell.

**Guard bite:** projected post-fix Check-95 FAILures **0**; allowlist **26** with **zero** unbacked
entries; `'MERGE-STRATEGY.md' in allowlist? False` — the guard still FAILs the exact 12-reference
defect that motivated the BD (EV-1).

### 4.4 Check 43 — the self-tree prefix leg (OI-1(b) + ROI-1(b))

Seven-plus references authored on client-shipped surfaces cite `project-template/`-prefixed paths
that are **dead at every client install** (a client has no `project-template/` directory). They are
invisible to Check 68 (the paths exist in the pack repo and resolve directly) and to Check 43
(whose pack-internal prefixes are `maintenance-docs/` and `pack-ops/` only).

**The constant MUST be new. This is binding.** `_CHECK_43_PACK_INTERNAL_PREFIXES`
(`boundary_refs.py:2114`) is consulted in **two** places — the qualified-prefix leg at `:2571-2575`
**and the bare-ref class test at `:2650`**. Adding `project-template/` to that tuple makes every
basename resolving under `project-template/` a pack-internal target, and every client-shipped file
lives under `project-template/` in the pack repo. **Measured: 130 new FAILures across 26
legitimate basenames** (EV-3).

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

**ROI-1=(b) — the leg runs on the WHOLE walk.** There is no `rel_posix.startswith(prefix)` guard.
Check 43's walk IS the client-installed surface, so every walked file is a surface where a
`project-template/…` path is dead; the `startswith` scoping the prior design invented was an
unmeasured implementation detail that silently dropped 3 live occurrences in the two client-installed
`supporting-docs/` files.

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

Patterns are module-precompiled, not built per line × prefix, per `ci-check-runtime-compounding`.
Both new names go in `__all__`.

**The `target == citing file` carve-out**, exactly sized to 5. All 5 KEEPs are the
`*Copied from: project-template/<self-path>*` provenance banner — hand-authored in exactly 5 shipped
files, no generator, no assertion anywhere. They are source attribution, not actionable pointers,
and they stay accurate at a client install (they name where the file was copied FROM). They carry
no backticks, so the client gate's `DANGLING_BACKTICK` regex never sees them — consistent with
their absence from the 29-record client set. The carve-out cannot over-reach: equality with the
citing file's own repo-relative path means the reference is right.

**Population under ROI-1=(b): 14 occurrences = 5 carve-out KEEP + 9 STRIP.** Post-fix residue
**0** (EV-2). **These 9 are a SUBSET of the 10 client-side STRIPs in §5.4, not additional work** —
the same 9 occurrences are simultaneously this leg's fix-set and part of the client gate's
(the 10th is the fence-invisible one, which no pack-side gate reports). Do not count them twice;
the wave applies 10 distinct edits in total.

### 4.5 The client twin — `project-template/scripts/validate-docs.sh`

Three defects, and the fix order is a **three-site lock-step**, not two:

1. **Ref-side normalization** (`:425`): `norm = ref[2:] if ref.startswith("./") else ref`. A prefix
   strip, not `lstrip("./")`, which is a character-class strip that mangles every dot-directory path
   (`.claude/settings.json` → `claude/settings.json`).
2. **Allowlist-side normalization** (`:179`): the SAME bug in `_commit_record`,
   `dangling_targets.add(target.lstrip("./"))`. Today the two bugs cancel — both sides mangle
   identically. **Fix only the ref side and 2 live `target:` records go dead** (EV-5).
3. **Fallback removal** (`:426`): drop `or base in basenames`; `basenames` then has no consumer and
   is deleted along with its return value, per `fail-loud-delete-old-source`.

Plus a **bounded walk**: keep `os.walk` but prune `.git`, `.build`, `build`, `dist`,
`node_modules`, `.venv`, `venv`, `DerivedData`, `__pycache__`, `.mypy_cache`, `.ruff_cache` via
in-place `dns[:] = [...]`. `.pack-migration-backup/` is deliberately NOT pruned — there is a live
allowlisted reference into it.

**The client walk stays filesystem-derived.** The pack-side answer to a raw walk is `git ls-files`;
**that answer does not transfer**, and the pack's own test says so
(`test-validate-docs-template-fullscan.sh:10-14`): *"the gate globs the live tree, so a new
not-yet-tracked template doc is scanned exactly as a client install would scan it (a `git ls-files`
staging would silently exclude it)."* A freshly installed client may not be a git work tree at all.
The client fix therefore **splits** the two roles the pack fix merges. The client gate needs no
leg A / leg B: at a client install the client's paths ARE the install paths.

---

## 5. Measurements

### 5.1 EV-1 — ROI-3=(b): walk 35, allowlist 26, post-fix FAILs 0 **[re-verified]**

- **Command:** build the Check-95 walk by subtraction under both exclusion shapes; run Check 40's
  tier ladder verbatim (its two regexes, `_strip_code_blocks`, `_CHECK_40_ALLOWLIST`,
  `_check_40_context_has_anchor`, the same-dir rule, `_build_basename_index`) over each; join
  every would-FAIL against `c95-triage.json`; then project the post-fix state.
- **Output (verbatim):**
  ```
  ROI-3=(a) entry-shaped prefixes (superseded)
    prefixes: ('maintenance-docs/', 'backlog/BD-', 'changelog/v', 'test-fixtures/', 'scripts/tests/fixtures/')
    walk size: 37 | dropped by prefixes: []
    {'files': 37, 'hits': 277, 'allowlist': 122, 'anchor': 11, 'same_dir': 22, 'WOULD_FAIL': 122}
    triaged KEEP=77  STRIP=45  UNTRIAGED=0
    ALLOWLIST SIZE (distinct KEEP basenames) = 27

  ROI-3=(b) WHOLESALE history-tree exclusion (DECIDED)
    prefixes: ('maintenance-docs/', 'backlog/', 'changelog/', 'test-fixtures/', 'scripts/tests/fixtures/')
    walk size: 35 | dropped by prefixes: ['backlog/_rules.md', 'changelog/_rules.md']
    {'files': 35, 'hits': 269, 'allowlist': 122, 'anchor': 11, 'same_dir': 16, 'WOULD_FAIL': 120}
    triaged KEEP=75  STRIP=45  UNTRIAGED=0
    ALLOWLIST SIZE (distinct KEEP basenames) = 26
  ```
  and the backing / projection:
  ```
  allowlist entries: 26
  entries with ZERO measured backing in the 35-file walk: []
  dropped-from-27 entries: ['vN.md']
  PROJECTED POST-FIX Check-95 FAILures: 0
    (STRIPs qualified = 45, KEEPs cleared by the 26-entry allowlist = 75)
  MUTATION PROBE — 'MERGE-STRATEGY.md' in allowlist? False  -> guard still FAILs it
  MUTATION PROBE — 'vN.md' in allowlist? False  -> no longer needed; changelog/_rules.md left the walk
  ```
- **Interpretation.** The ROI-3=(a) row independently reproduces the carried-forward census
  digit-for-digit with `UNTRIAGED=0`, which validates the replication before the delta is read.
  ROI-3=(b) then drops exactly the two `_rules.md` files: 8 fewer hits (2 would-FAIL + 6 same-dir),
  120 would-FAIL, KEEP 77 → 75, **STRIP unchanged at 45** — so the fix-set and every wave that
  carries it are untouched. The allowlist loses exactly one entry, `vN.md`, whose only backing was
  the two `changelog/_rules.md` occurrences. **No other entry loses backing**; all 26 retain ≥1
  measured occurrence (per-entry counts and citers in `c288-check95-allowlist.json`). Post-fix
  FAILures are 0 and the guard still bites.
- **Conclusion:** SUPPORTED. ROI-3=(b) is green, exactly sized, and costs 2 would-FAIL KEEP
  occurrences of coverage.

**Consequence, stated plainly.** ROI-3=(b) is the *literal* reading of a constraint whose stated
rationale is about ~480 history entries; the two files it removes are live per-entry-tree
contracts. The measured cost of that reading is **zero FAILs** and one allowlist entry. It also
removes the only NEW prefix shape the design would have introduced, which is what dissolves
adversarial finding S-8 rather than working around it. It does leave a coverage gap that is
**not** what the constraint was aimed at — see **NOI-1** (§11).

### 5.2 EV-2 — ROI-1=(b): population 14, post-fix residue 0 **[re-verified]**

- **Command:** Check 43's own qualified-prefix leg, replicated exactly — the walk
  `_iter_client_installed_files()`, the extension filter, `_strip_code_blocks`, the Guardrail-2
  per-line **fence skip**, the raw-substring pattern, and `_check_43_context_has_anchor` — run
  with the `startswith` guard dropped, then with **line-targeted** projected edits applied.
- **Output (verbatim):**
  ```
  ROI-1=(a) narrow, HEAD                 scanned= 179  FAIL= 11  carved=0
  ROI-1=(b) WIDE,   HEAD                 scanned= 181  FAIL= 14  carved=0
  ROI-1=(b) WIDE, carve-out only         scanned= 181  FAIL=  9  carved=5
  ROI-1=(b) WIDE, line-targeted STRIPs   scanned= 181  FAIL=  5  carved=0
  ROI-1=(b) WIDE, PROJECTED POST-FIX     scanned= 181  FAIL=  0  carved=5
  ```
  the 3 occurrences the narrow conditional dropped:
  ```
    supporting-docs/METHODOLOGY.md:1984        -> project-template/docs/pack/PACK-FEEDBACK.md
    supporting-docs/INSTALL-PROCEDURES.md:1336 -> project-template/docs/pack/PM-CHAT.md
    supporting-docs/INSTALL-PROCEDURES.md:1367 -> project-template/docs/pack/prompts/pm-chat.md
  ```
  and the carve-out members (unchanged at 5):
  ```
    project-template/AGENTS.md:20   project-template/CLAUDE.md:22   project-template/GEMINI.md:18
    project-template/docs/pack/PACK-FEEDBACK.md:28   project-template/docs/pack/PM-CHAT.md:23
  ```
- **Interpretation.** The wide conditional scans 2 more files (181 vs 179) and catches 3 more
  occurrences — all three actionable "see X" pointers on files that ship to the client, all three
  already STRIPs in the client triage, so the client artifact needs no change and the pack side now
  catches them too. The four-cell table proves both halves are load-bearing: carve-out alone leaves
  9, STRIPs alone leave 5, together 0.
- **Conclusion:** SUPPORTED. Post-fix residue is **0** under the wide conditional.

#### EV-2b — a NEW implementation hazard surfaced by applying ROI-1=(b)

- **Command:** re-run the projection with a naive global find/replace instead of line-targeted
  edits, and compare the carve-out count.
- **Output (verbatim):**
  ```
  global-replace projection : FAIL=0  carved=4     <-- one banner destroyed
  line-targeted projection  : FAIL=0  carved=5     <-- correct

  HAZARD CHECK — files carrying a self-provenance banner that are ALSO a STRIP target string:
      project-template/docs/pack/PM-CHAT.md  <-- a blind global find/replace WOULD clobber its own banner
  ```
- **Interpretation.** `project-template/docs/pack/PM-CHAT.md` carries its self-provenance banner at
  line 23 **and** its own path is the string being stripped at
  `supporting-docs/INSTALL-PROCEDURES.md:1336`. A tree-wide `sed`/find-replace of
  `project-template/docs/pack/PM-CHAT.md` → `docs/pack/PM-CHAT.md` would silently rewrite the
  banner into a falsehood (it would then claim the file was copied from `docs/pack/PM-CHAT.md`) and
  the guard would stay green, because a rewritten banner simply stops matching. The same shape
  applies to `project-template/docs/pack/PACK-FEEDBACK.md` (banner at :28, path cited from
  `supporting-docs/METHODOLOGY.md:1984`).
- **Conclusion:** SUPPORTED. **Binding coder constraint: every STRIP in §4.4's set is a
  LINE-TARGETED edit at the file:line given in `c288-client-triage.json`. No tree-wide
  find/replace of any `project-template/…` path string.** This is not an open item — it has one
  correct answer — but it is recorded because a green gate does not catch the mistake.

### 5.3 EV-3 — the shared-constant hazard: 130 new FAILures **[carried]**

- **Command:** replicate Check 43's bare-ref class test with `project-template/` added to
  `_CHECK_43_PACK_INTERNAL_PREFIXES`, and count occurrences that newly FAIL.
- **Output (verbatim):**
  ```
  HEAD prefixes:  ('maintenance-docs/', 'pack-ops/')
  NAIVE extended: ('maintenance-docs/', 'pack-ops/', 'project-template/')

  NEW bare-ref class-test FAILures introduced by the naive shared-tuple edit: 130
  distinct basenames: 26
      23  validate.sh        15  format.sh        12  bootstrap.sh       11  test.sh
      10  pm-chat.md          6  agent-post-edit-check.sh                 6  proto-gen.sh
       4  pyproject.toml      4  format-swift.sh   4  validate-docs.sh    3  bootstrap-swift.sh
       3  bootstrap-python.sh 3  format-python.sh  3  validate-swift.sh   3  validate-python.sh
       3  validate-proto.sh   3  test-swift.sh     3  test-python.sh      3  verify-immutable.sh
       2  activate-capability.sh   (+6 more)
  ```
- **Interpretation:** every one of the 130 is a legitimate client-shipped file cited by bare name
  from a client-audience doc. A coder who "just extends the tuple" discovers this at CI time.
- **Conclusion:** SUPPORTED, and binding on §4.4's implementation.

### 5.4 The client gate — ground truth, and every occurrence verdicted

Both earlier passes hand-replicated the gate and both got the corpus size wrong (`refs: 362` and
`330` against a measured `312`); neither modelled `strip_blocks`'s `DENY-LIST-CONTENT` leg
(`validate-docs.sh:191-209`). I ran the **real shipped gate**, then a copy patched with the three
fixes, against staged install trees in `mktemp`. Nothing was written to the repo.

#### EV-4a — the real gate: green today, 10 after the fixes on the overlay **[carried]**

- **Command:** stage the exact `test-validate-docs-template-fullscan.sh` L5 overlay
  (`cp -R project-template/. → install/` plus the two `supporting-docs/` files into `docs/pack/`);
  run the shipped gate; then a copy patched with the three §4.5 fixes.
- **Output (verbatim):**
  ```
  [validate-docs] scanning 120 operating docs (4 axes: history / deferred / bloat / dangling)
                  + per-entry stream conformance
  [validate-docs] PASS — operating docs clean + per-entry streams schema-conformant.   rc=0

  === REAL PATCHED GATE on S6 overlay ===  10
    docs/pack/INSTALL-PROCEDURES.md:1336 `project-template/docs/pack/PM-CHAT.md`
    docs/pack/INSTALL-PROCEDURES.md:1367 `project-template/docs/pack/prompts/pm-chat.md`
    docs/pack/METHODOLOGY.md:12          `supporting-docs/METHODOLOGY.md`
    docs/pack/METHODOLOGY.md:1984        `project-template/docs/pack/PACK-FEEDBACK.md`
    .claude/agents/auditor-{architecture,ops}.md         `project-template/skills/audit-methodology/SKILL.md`
    .codex/agents/auditor-{architecture,ops}.toml        `project-template/skills/audit-methodology/SKILL.md`
    .agents-plugin/.../auditor-{architecture,ops}.md     `project-template/skills/audit-methodology/SKILL.md`
  ```
  my independent replication of the same configuration, for cross-check:
  ```
  docs in IN set: 120
  HEAD config (as shipped)                    : {'refs':312,'direct':206,'fallback':43,'allow':35,'placeholder':23,'anchor':5,'RESIDUE':0}
  design post-fix, allowlist lstrip NOT fixed : {'refs':312,'direct':239,'fallback':0,'allow':32,'placeholder':23,'anchor':6,'RESIDUE':12}
  design post-fix + allowlist lstrip fixed    : {'refs':312,'direct':239,'fallback':0,'allow':35,'placeholder':23,'anchor':5,'RESIDUE':10}
  ```
- **Interpretation:** replication predicts 10; the real gate reports exactly 10, validating the
  model end to end. The residue is not scattered — it is precisely the
  pack-storage-paths-on-client-surfaces axis.
- **Conclusion:** SUPPORTED, superseding both prior figures.

#### EV-5 — the `lstrip("./")` bug has a THIRD site **[carried]**

- **Command:** run the real gate patched with the ref-side and fallback fixes but NOT the
  allowlist-side strip.
- **Output (verbatim), the two occurrences present only in that configuration:**
  ```
  docs/pack/INSTALL-PROCEDURES.md:856  `.pack-migration-backup/v9.3-to-v10.0/reconcile-checklist.md` does not resolve
  skills/pm-startup/SKILL.md:139       `.agents/mcp_config.json` does not resolve
  ```
  Both have live `target:` records (`.docs-gate-allowlist.txt:504`, `:522`); 2 of the 13 records
  are dot-prefixed.
- **Interpretation:** today the ref-side and allowlist-side bugs cancel. Fixing two of three kills
  2 live records.
- **Conclusion:** SUPPORTED. **All three sites move in the same commit.**

#### EV-4b — the residue is install-profile-dependent (the OI-2 answer) **[carried]**

`init-project.sh` stage S9 (`stage_s9_conditional_remove`, `:1113-1200`) deletes language-specific
files when the corresponding marker is absent. The S6 overlay keeps every one, so an overlay-only
measurement is **structurally blind** to every reference into a removed file.

- **Command:** build the overlay, apply each S9 language profile by deleting exactly the paths S9
  names, and run the fully-patched real gate on each; plus the bare-template tree.
- **Output (verbatim):**
  ```
  ### keepall      (rm py=0 sw=0 pr=0)  files=183  dangling=10   (no extras)
  ### swift-only   (rm py=1 sw=0 pr=1)  files=169  dangling=12
       EXTRA: docs/pack/OPTIONAL-FEATURES.md:382 `scripts/test-python.sh`
       EXTRA: docs/pack/prompts/pm-chat.md:122   `./scripts/proto-gen.sh`
  ### python-only  (rm py=0 sw=1 pr=1)  files=173  dangling=27
       EXTRA: CLAUDE.md:287/288, AGENTS.md:272/273, GEMINI.md:283/284,
              docs/pack/INSTALL-PROCEDURES.md:1124/1125/1126/1347/1348x2,
              docs/pack/OPTIONAL-FEATURES.md:382, docs/pack/prompts/pm-chat.md:104x2/109/122
  ### swift+py     (rm py=0 sw=0 pr=1)  files=177  dangling=11
  ### py+proto     (rm py=0 sw=1 pr=0)  files=179  dangling=26
  ### swift+proto  (rm py=1 sw=0 pr=0)  files=175  dangling=11
  ### bare template (no overlay)                    dangling=6
  UNION across all trees: 28
  ```
- **Interpretation:** worst case is a **Python-only** client at 27 — 17 above the overlay, every one
  a Swift-conditional path cited from explicitly Swift-scoped prose ("Required first-time setup
  (Swift projects only)"). These are **KEEPs**: the reference is correct when the file is present.
  But they are false-reds at a real client install — the support incident OI-2=(b) exists to
  prevent, and invisible to the standing test as it exists today.
- **Conclusion:** SUPPORTED. The complete client occurrence set is the **union across profiles**.

**On OI-2's literal form.** The decision reads "triage against a REAL `scripts/init-project.sh`
run". That script refuses a target that is not a git repo (exit 11, `:1892`) or whose tree is dirty
(exit 12, `:1911`) — so a real run needs `git init` + `git add` + `git commit` in the target.
`agents-never-commit` forbids all of those to **every** pack agent, RW and RO alike, so the W4
coder cannot execute it either; a hook denied it when I attempted the scratch provisioning, and I
did not retry a variant or hide the verbs in a script. The profile matrix **dominates** a single
run for this purpose, because one run yields one language profile. Token substitution was checked
and is not a factor (the only `[PROJECT_NAME]` site is an emitted prompt string, `:1231`). The
residual gap — a client's own authored docs — is unknowable to the pack by construction.
ROI-2=(b) converts the measurement into a standing guarantee (§5.6).

#### EV-4c — 29 occurrences, each with a verdict **[carried]**

- **Command:** union the per-profile gate output, add the fence-invisible content defect, assign
  each occurrence a verdict, fix recipe, and visible-on profiles.
- **Output (verbatim):** `records: 29 {'STRIP': 10, 'KEEP': 19}` / `distinct new target: records: 6`.
  Full list: **`c288-client-triage.json`**.
- **Interpretation — the classes:**

  | Class | Occ | Verdict | Action |
  |---|---|---|---|
  | Pack-storage path, actionable pointer, citer under `project-template/` | 6 | **STRIP** | → `skills/audit-methodology/SKILL.md` in the 6 auditor agent files |
  | Pack-storage path, actionable pointer, citer a client-installed `supporting-docs/` file | 2 | **STRIP** | → `docs/pack/PM-CHAT.md`, `docs/pack/prompts/pm-chat.md` (edit `supporting-docs/INSTALL-PROCEDURES.md`) |
  | Pack-storage path, redundant sentence | 1 | **STRIP** | reword `supporting-docs/METHODOLOGY.md:1984` to drop the path; the preceding sentence already gives the client path |
  | Pack-storage path, deny-list-fenced (no gate sees it) — **ROI-5=(a)** | 1 | **STRIP** | `project-template/skills/boundary-investigation/SKILL.md:107` → `docs/pack/OPTIONAL-FEATURES.md`; **no new guard** |
  | Pack-repo SSOT self-banner | 1 | **KEEP** | `target: supporting-docs/METHODOLOGY.md` |
  | S9 conditional-removal path | 18 | **KEEP** | 5 `target:` records: `scripts/{validate,test,format}-swift.sh`, `scripts/test-python.sh`, `scripts/proto-gen.sh` |

- **Conclusion:** SUPPORTED. 10 STRIP / 19 KEEP / **6 new `target:` records** (13 → 19).

**The pack-repo-anchor hazard, decided.** `docs/pack/METHODOLOGY.md:12` reads *"One copy of this
file lives at `supporting-docs/METHODOLOGY.md` in the pack repo."* Pack-side this clears on Check
43's `in the pack repo` anchor. The client gate's `DANGLING_ANCHORS` — `("archived", "does not
exist", "no longer", "example", "e.g.", "placeholder", "for example", "such as", "orphan",
"mirror", "regenerated", "installed by", "refreshed by", "the live file is")` — has **no pack-repo
anchor**. Adding one would clear **6** measured lines to fix 1 (measured), so the resolution is a
single `target:` record: exactly sized, the project-side SSOT (P-missed-7), and consistent with
OI-7's rejection of anchor-broadening for one occurrence. `docs/pack/METHODOLOGY.md:1984` gets the
opposite treatment (STRIP) because there the path is redundant, and allowlisting a
`project-template/` path client-side would contradict the 9 STRIPs beside it.

#### EV-4d — post-fix GREEN on 8 trees, and the guard bites **[carried]**

- **Command:** apply all 10 STRIPs and all 6 `target:` records to the staged trees; run the
  fully-patched real gate on the bare template plus all 7 install profiles; then mutation-probe.
- **Output (verbatim):**
  ```
  === POST-FIX VERIFICATION (3 gate fixes + 10 STRIPs + 6 target: records) ===
    bare-template rc=0 dangling=0 | overlay-keepall rc=0 dangling=0 | swift-only rc=0 dangling=0
    python-only   rc=0 dangling=0 | swift+py        rc=0 dangling=0 | py+proto   rc=0 dangling=0
    swift+proto   rc=0 dangling=0 | none-detected   rc=0 dangling=0

  BITE A (moved-file ref)   -> docs/pack/PM-CHAT.md:1526 `docs/pack/MOVED-AWAY.md` does not resolve
  BITE B (wrong path, basename exists — the BD's originating mechanism)
                            -> docs/pack/PM-CHAT.md:1526 `docs/WRONGDIR/PM-CHAT.md` does not resolve
  BITE C (same ref, UNPATCHED HEAD gate)
                            -> [validate-docs] PASS — operating docs clean
  BITE D (dot-directory ref)-> docs/pack/PM-CHAT.md:1526 `.claude/NOPE/settings.json` does not resolve
  ```
- **Interpretation:** step 5 of `ci-guard-measure-then-bound` satisfied against the real gate on 8
  trees. **BITE C is the `declare-verify-backing` proof** — a qualified path that is wrong but
  whose basename exists passes *vacuously* on the shipped gate and FAILs on the hardened one.
- **Conclusion:** SUPPORTED.

### 5.5 EV-6 — the exclusion constant is now load-bearing, and no walk member is fenced **[re-verified]**

- **Command:** enumerate `_iter_operating_docs()` members under the history trees; compare the two
  exclusion shapes; test every member of the 35-file walk for a Guardrail-2 fence.
- **Output (verbatim):**
  ```
  total operating docs: 158
  backlog/*:   ['backlog/_rules.md']       changelog/*: ['changelog/_rules.md']
  maintenance-docs/*: 0   test-fixtures/*: 0   scripts/tests/fixtures/*: 0

  entry-shaped prefixes  -> dropped by prefixes: []                                   (INERT)
  wholesale  prefixes    -> dropped by prefixes: ['backlog/_rules.md', 'changelog/_rules.md']  (LOAD-BEARING)

  files carrying a DENY-LIST fence, repo-wide: 10
    all 10 are under project-template/ or are supporting-docs/{INSTALL-PROCEDURES,METHODOLOGY}.md
    -> every one is either in Check 43's walk or client-installed
    -> members of the 35-file Check-95 walk that carry a fence: 0
  ```
- **Interpretation.** Two facts the design must carry. (i) Under the superseded entry-shaped form,
  `_CHECK_95_EXCLUDE_PREFIXES` excluded **nothing** and its per-check test would have passed
  vacuously against the live tree; under ROI-3=(b) it excludes 2 real members, so the test can be
  written against reality — though §8 still requires a fixture leg to prove the *other* prefixes
  bite. (ii) Check 40 does not consult the per-line fence and Check 95 inherits that; since **no**
  walk member carries a fence, the two are consistent by measurement. A future fenced doc entering
  the walk would be scanned inside its fence — recorded so a later maintainer is not surprised.
- **Conclusion:** SUPPORTED.

### 5.6 EV-7 — ROI-2's L8 leg, sized and pre-audited **[re-verified]**

- **Command:** draft the L8 leg against the existing test's own harness symbols; count it; audit it
  against Check 83's three bug classes and Check 92.
- **Output (verbatim):**
  ```
  L8 draft lines: 36     non-comment, non-blank: 29
  --- Check 83 bug-class self-audit ---
    (c) grep -c ... || echo 0 double-zero idiom: absent
    (a) hardcoded dev path (/Users/, /home/, ~/):  absent
    (b) live gh call:                              absent
  --- Check 92 mktemp portability ---
    no mktemp invocation (reuses FIXTURE_BASE) — Check 92 N/A for this leg

  harness symbols the draft reuses, verified present:
    scripts/tests/test-validate-docs-template-fullscan.sh:79  FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-vdocs-fullscan.XXXXXX")"
    :80  trap 'rm -rf "$FIXTURE_BASE"' EXIT
    :84  fail()      :89  pass()      :252  INSTALL_ROOT="$FIXTURE_BASE/install"
  existing test length: 308 lines  ->  ~344 with L8
  ```
- **Interpretation:** L8 is 29 substantive lines that reuse L5's already-staged `$INSTALL_ROOT`,
  the existing `mktemp` root (already Check-92-portable), the existing trap cleanup, and the
  existing `pass`/`fail` counters. It introduces **no new infrastructure and no new mktemp**, and
  it is clean against all three Check-83 classes. Its roster is derived from
  `stage_s9_conditional_remove`, and a comment in the leg says so, so a future S9 change that
  desyncs is visible at the diff.
- **Conclusion:** SUPPORTED. L8 is a small mechanical addition, not a new test surface.

---

## 6. Encoding surfaces (`enumerate-encoding-surfaces`)

### 6.1 Adding Check 95

| # | Surface | Required edit |
|---|---|---|
| 1 | `scripts/lib/validate_checks/boundary_refs.py` | `check_live_pack_doc_bare_refs` body + `_CHECK_95_ALLOWLIST` (**26**) + `_CHECK_95_EXCLUDE_PREFIXES` (5 **whole-tree** prefixes) |
| 2 | same file, `__all__` | export the check + both constants (the facade resolves `check_*` by bare name) |
| 3 | `scripts/validate-pack.py` | one `CHECK_REGISTRY` tuple `(95, label, fn, budget_s)` |
| 4 | **`scripts/lib/validate_checks/core.py:210`** | `CHECK_REGISTRY_EXPECTED_COUNT` 91 → 92 (asserted by Check 59) |
| 5 | **`scripts/lib/validate_checks/core.py:150-210` — the numbered-check LEDGER** | append a BD-288 line in the established form; change the trailing `(Next free numeric ID = 95.)` → `= 96.`. **This is the surface BD-288's acceptance criterion is actually about** — there is no check-count prose in `validate-pack.py`'s header (its only "registry entries" hits are `:693` and `:701`, both about named-lambda late-binding) |
| 6 | `README.md` ×2 sites (version-table row **L83**, layout **L204**) | `91 invoked checks` → `92`; `91 registry entries total` → `92`; `86 numbered` → `87`; range `77–94` → `77–95`. Each string occurs exactly twice |
| 7 | Check 80 doc↔constant twin | the README count is a registered twin of `CHECK_REGISTRY_EXPECTED_COUNT`; both sides move together or Check 80 fails |
| 8 | `scripts/tests/test-validate-pack-check-95.sh` | NEW per-check test (constraints in §6.5) |
| 9 | `.github/workflows/validate-pack.yml` | wire the new test so Check 42 passes |
| 10 | `scripts/lib/ci-shard-plan.py` coverage | DISK-derived via `parse_wired_tests()`; verify with `--assert-coverage` (Check 60 mirrors it) |

### 6.2 Hardening Check 68

| # | Surface | Required edit |
|---|---|---|
| 1 | `boundary_refs.py` `check_dangling_file_refs` | replace the qualified-path ladder; scope from the `_git_tracked_relpaths()` result already fetched for the basename index |
| 2 | `boundary_refs.py` `_parse_client_installed_files` | return the DEST column; add `_client_install_dest_to_source()` |
| 3 | `boundary_refs.py` `__all__` | export the new helper |
| 4 | `pack-ops/.dangling-ref-allowlist.txt` | +6 `token:`/`reason:` records (51 → 57) |
| 5 | `.claude/skills/boundary-investigation/SKILL.md` L73-74 | the 2 OI-3 STRIP fixes |
| 6 | **`.codex/skills/boundary-investigation/SKILL.md` + `.agents/skills/boundary-investigation/SKILL.md`** | **byte-identical re-propagation (Check 71 — no allowlist)** |
| 7 | `scripts/tests/test-validate-pack-check-68.sh` | new legs: leg A, leg B, fallback-removal regression, tracked-scope assertion, mutation proofs |
| 8 | `scripts/tests/test-validate-pack-check-41.sh` | Check 41 also consumes `_parse_client_installed_files`; re-verify its legs against the widened return |

### 6.3 Fixing Check 81

| # | Surface | Required edit |
|---|---|---|
| 1 | `scripts/lib/validate_checks/cross_bd.py` `_check_81_active_bd_ids` | accept dict AND leading-anchored string |
| 2 | `scripts/tests/test-validate-pack-check-81.sh` | string-form FAIL-leg assertion + mutation proof |
| 3 | `scripts/tests/test-validate-pack-check-82.sh` | **no change** — re-run to confirm the shared iterator is untouched |
| 4 | `scripts/dashboard-render.py`, `pack-ops/DASHBOARD-SPEC-PACK.md`, `pack-ops/session-state.json` | **NO EDIT** — verified consistent; recorded so the reviewer confirms the non-edit is deliberate |

### 6.4 Check 43 self-tree leg + the client twin

| # | Surface | Required edit |
|---|---|---|
| 1 | `boundary_refs.py` | `_CHECK_43_SELF_TREE_PREFIXES` + `_CHECK_43_SELF_TREE_PREFIX_PATTERNS` + the leg with the `target == citing file` carve-out (§4.4). **NOT** an edit to `_CHECK_43_PACK_INTERNAL_PREFIXES` (EV-3) |
| 2 | `boundary_refs.py` `__all__` | export both new constants |
| 3 | `scripts/tests/test-validate-pack-check-43.sh` | new legs: (i) a `project-template/…` cite from a `project-template/` citer FAILs; (ii) **a `project-template/…` cite from a client-installed `supporting-docs/` citer ALSO FAILs** (the ROI-1=(b) widening — this leg would pass vacuously under the narrow conditional, so it is the one that proves the decision landed); (iii) the self-provenance banner is cleared; (iv) mutation proof |
| 4–9 | 6 client agent files — `project-template/{.claude,.codex,.agents-plugin/optiquity-agents}/agents/auditor-{architecture,ops}.{md,toml}` | **line-targeted** STRIP → `skills/audit-methodology/SKILL.md` |
| 10 | `project-template/skills/boundary-investigation/SKILL.md:107` | **line-targeted** STRIP → `docs/pack/OPTIONAL-FEATURES.md` (fence-invisible; ROI-5=(a): content fix, no guard) |
| 11 | `project-template/scripts/validate-docs.sh` | **3 lock-step edits**: `:425` ref-side prefix-strip, `:179` **allowlist-side** prefix-strip (EV-5), `:426` fallback removal + delete `basenames` and its return value; plus the bounded `os.walk` prune |
| 12 | same file, `--self-test` | one bite assertion per fixed defect |
| 13 | `project-template/scripts/.docs-gate-allowlist.txt` | +6 `target:`/`reason:` records (13 → 19) |
| 14 | `supporting-docs/INSTALL-PROCEDURES.md` | **line-targeted** STRIPs at :1336, :1367 |
| 15 | `supporting-docs/METHODOLOGY.md` | **line-targeted** STRIP-by-reword at :1984 |
| 16 | `scripts/tests/test-validate-docs-template-fullscan.sh` | L1/L3/L5 stay green; L3's **bidirectional** allowlist-liveness leg must accept the 6 new records (all are referenced by ≥1 corpus doc — verified); **NEW L8** S9-profile matrix (ROI-2=(b), §5.6) |
| 17 | Check 70 axis bijection | unchanged — no axis added or removed |

**Binding edit-mechanics constraint (EV-2b).** Rows 4–10, 14 and 15 are **line-targeted** edits at
the exact file:line in `c288-client-triage.json`. A tree-wide find/replace of any
`project-template/…` path string is prohibited: `project-template/docs/pack/PM-CHAT.md` and
`project-template/docs/pack/PACK-FEEDBACK.md` each carry their own `*Copied from:*` provenance
banner, and a global replace would rewrite those banners into falsehoods **while leaving every gate
green**.

### 6.5 Constraints on any NEW or newly-wired test file

A test wired into `.github/workflows/validate-pack.yml` automatically enters two other checks'
candidate sets.

- **Check 83** (`check_wired_test_ci_fragility`, `scripts/lib/validate_checks/wired_test_fragility.py`)
  statically scans every CI-wired test for three CI-environment-fragile bug classes: **(a)**
  hardcoded dev/home paths, **(b)** direct un-shimmed live-`gh` calls, **(c)** the
  `grep -c … || echo 0` double-zero idiom. Candidate set = the three-glob wired set MINUS
  `scripts/ci-test-wiring-allowlist.txt`. Applies to the NEW `test-validate-pack-check-95.sh` and
  to the L8 addition (the fullscan test is already in the candidate set).
- **Check 92** (`check_mktemp_t_portability`, `scripts/lib/validate_checks/mktemp_portability.py`)
  FAILs any `mktemp -t <prefix>XXXXXX` (including `-dt` / `-qt` / `-dqt`) or GNU-only `--tmpdir` /
  `-p DIR`. Portable form: `mktemp [-d] "${TMPDIR:-/tmp}/<prefix>.XXXXXX"`. Load-bearing here
  because §8 requires **`git init` fixture trees**, created in `mktemp` directories. L8 adds no
  `mktemp` and is unaffected (EV-7).

### 6.6 Check 71 — skill-mirror byte-identity

`check_pack_skill_mirror_identity` (`boundary_refs.py:4488`; registry tuple
`scripts/validate-pack.py:1217`) asserts byte-identity between `.claude/skills/<s>/SKILL.md` and
both `.codex/skills/<s>/SKILL.md` and `.agents/skills/<s>/SKILL.md`. Its docstring: *"no allowlist
(byte-identity is absolute)"*. There is no exemption path and **no propagation automation exists** —
mirrors are maintained by hand.

```
_CHECK_71_SKILL_MIRROR_DIRS = (".claude/skills", ".codex/skills", ".agents/skills")
git ls-files .claude/skills | .codex/skills | .agents/skills  ->  18 | 18 | 18
boundary-investigation 8cbf74f21e9e228750d015b154543ad9 x3   dashboard-render 0f046151ec18829825e59b35c4b3f107 x3
pack-help              d6d9f328a02a1c6cafb99e62a4b1b66d x3   verification-harness f000971860da2dd85a995eab3ac4ddfc x3
```

Mirrors are byte-identical today, so any canonical edit breaks Check 71 until re-propagated:

| Skill | Canonical edits | Wave | Mirror files |
|---|---|---|---|
| `boundary-investigation` | 2 dangling STRIPs (L73-74) | W2 | `.codex/`, `.agents/` |
| `boundary-investigation` | 5 bareness STRIPs | W3 | `.codex/`, `.agents/` |
| `dashboard-render` | 1 bareness STRIP | W3 | `.codex/`, `.agents/` |
| `pack-help` | 1 bareness STRIP | W3 | `.codex/`, `.agents/` |
| `verification-harness` | 1 bareness STRIP | W3 | `.codex/`, `.agents/` |

**W2 re-propagates 2 mirror files; W3 re-propagates 8.** `boundary-investigation` is touched in
both waves, so it is re-propagated twice — another reason W2 and W3 serialize.

### 6.7 The 45 bareness STRIP fixes — complete file list

Unchanged by ROI-3=(b): the two `_rules.md` files contributed **zero** STRIP occurrences (EV-1).

```
  7  CLAUDE.md                                       5  supporting-docs/MIGRATION-v10-to-v11.md
  7  AGENTS.md                                       5  supporting-docs/SETUP-EXISTING.md
  7  GEMINI.md                                       4  supporting-docs/SETUP-NEW.md
  5  .claude/skills/boundary-investigation/SKILL.md  2  supporting-docs/SETUP_TEMPLATE.md
  1  .claude/skills/dashboard-render/SKILL.md
  1  .claude/skills/pack-help/SKILL.md               = 45 occurrences / 11 files
  1  .claude/skills/verification-harness/SKILL.md      (+ 8 Check-71 mirror files)
```

The pack-root trinity is a `pack-chat-only` surface, so those three files are **scoped into the
coder prompt by Pack Chat** rather than edited by Pack Chat directly — the supported path per
`pack-chat-minor-edits-only`, not a boundary violation.

---

## 7. Parallel-vs-dependent implementation map (rule 10)

**Four waves. There is no W0, no W5, and no W6.**

### 7.1 The governing principle

**A guard and the fix-set that makes it green are ONE commit.** Treating "the guard proves the
edits are complete" as a *scheduling* dependency makes the guard's own commit red by construction:
Check 95's allowlist is sized to the KEEP set and the STRIPs are its complement, so the
intersection is empty and a check-without-fixes commit fails 45 times. Commit `47f8467` established
the correct shape for Check 53: guard, candidate-set fix, test, and mutation proof in one commit.

The principle applies **three** times:

| Guard | Its fix-set | Together in |
|---|---|---|
| Check 95 | the 45 bareness STRIPs | W3 |
| Check 43's self-tree leg | the 9 STRIPs + the self-provenance carve-out | W4 |
| the hardened client gate | the 10 client STRIPs + the 6 `target:` records | W4 |

The second and third overlap: 8 of Check 43's 9 STRIPs are also client-gate STRIPs (the 6 auditor
files + the 2 `INSTALL-PROCEDURES.md` pointers), and the 9th (`METHODOLOGY.md:1984`) is a client
STRIP too. **W4 cannot be split into a pack half and a client half without one of them being red.**

### 7.2 File contention

| File | W1 | W2 | W3 | W4 |
|---|:--:|:--:|:--:|:--:|
| `scripts/lib/validate_checks/cross_bd.py` | ● | | | |
| `scripts/lib/validate_checks/boundary_refs.py` | | ● | ● | ● |
| `.claude/skills/boundary-investigation/SKILL.md` (+2 mirrors) | | ● | ● | |
| `scripts/validate-pack.py`, `core.py`, `README.md`, workflow | | | ● | |
| `supporting-docs/{MIGRATION-v10-to-v11,SETUP-EXISTING,SETUP-NEW,SETUP_TEMPLATE}.md` | | | ● | |
| `project-template/**`, `supporting-docs/{INSTALL-PROCEDURES,METHODOLOGY}.md` | | | | ● |

```
        W1 ──────────────────────────────►   (parallel, own worktree; touches nothing else)

        W2 ──► W3 ──► W4                     (serial: all three edit boundary_refs.py;
                                              W2/W3 additionally share boundary-investigation/SKILL.md)
```

`supporting-docs/` appears in W3 and W4 on **disjoint files**; they serialize on `boundary_refs.py`
anyway, so nothing rests on that.

### 7.3 Semantic ordering, checked rather than assumed

The chain order is contention-driven. No wave makes another red:

- **W3's 45 STRIPs turn bare names into qualified paths Check 68 then evaluates.** All 11 targets
  exist and resolve on Check 68's **direct** leg, before and after W2 — verified EXISTS at HEAD:
  `scripts/init-project.sh`, `pack-ops/{PACK-AGENTS,PACK-CHAT,PACK-MEMORY-RATIONALE,HELP-FRAGMENT-PACK}.md`,
  `scripts/validate-pack.py`, `scripts/lib/validate_checks/no_leak.py`,
  `supporting-docs/SETUP-EXISTING.md`, `scripts/test-migrator-core.sh`,
  `scripts/migrate-v10-to-v11.sh`, `scripts/tests/test-customization-preserve.sh`. None of the 45
  lands on a client-installed surface, so Check 43 and Check 37 are untouched.
- **W4's client STRIPs produce client-form paths Check 68 evaluates.**
  `skills/audit-methodology/SKILL.md`, `docs/pack/PM-CHAT.md`, `docs/pack/prompts/pm-chat.md`,
  `docs/pack/OPTIONAL-FEATURES.md` all resolve on **leg A** after W2 (each exists under
  `project-template/`) and would have resolved on the basename fallback before it — so W4 is safe
  in either position; the chain simply places it last.
- **W4 cannot break Check 95**: everything W4 touches is either under `project-template/` or
  client-installed, and both are subtracted out of Check 95's walk by construction.
- **ROI-3=(b) touches no wave ordering** — it removes 2 files from one walk and 1 entry from one
  allowlist, both inside W3.

### 7.4 The waves

| Wave | Scope | Files | Parallel with | Why it fits ONE bounded cycle |
|---|---|---|---|---|
| **W1** | Check 81 matcher + FAIL-leg test + mutation proof; re-run Check 82's test as a no-change guard | `cross_bd.py`, `test-validate-pack-check-81.sh` | W2, W3, W4 | ~10 changed lines in one function; one new test group; zero shared files; the extraction rule is evidence-derived |
| **W2** | Check 68 install-path-aware ladder + git-tracked scope + 6 allowlist records + 2 OI-3 dangling STRIPs + 2 Check-71 mirrors | `boundary_refs.py`, `pack-ops/.dangling-ref-allowlist.txt`, `.claude/skills/boundary-investigation/SKILL.md` + 2 mirrors, tests 68 + 41 — **8 files** | W1 | One ladder, one parser widening, 6 records, 2 doc edits, 2 mirror propagations. The 13-item residue is fully enumerated; **no discovery remains** |
| **W3** | Check 95 body + **26**-entry allowlist + **5 whole-tree** exclusion prefixes + registry + `core.py` count **and ledger** + `README.md` ×2 + new test + CI wiring + **the 45 bareness STRIPs** + 8 Check-71 mirrors | `boundary_refs.py`, `validate-pack.py`, `core.py`, `README.md`, new test, workflow, trinity ×3, 4 `.claude/skills/*/SKILL.md`, 4 `supporting-docs/*.md`, 8 mirrors — **~25 files** | — | Largest wave. Fits because **every edit is enumerated with zero discovery**: 45 STRIPs line-by-line from `c95-triage.json`, 26 allowlist entries with `reason:` strings pre-derived in `c288-check95-allowlist.json`, and **the check is its own completeness oracle** — a green Check 95 means the census is closed, so the reviewer verifies a gate result rather than re-deriving 45 judgments. Check 71 is the mirror oracle. **ROI-4=(a):** ship merged; §7.5 stays a live fallback |
| **W4** | Check 43 self-tree leg (**wide**, ROI-1=(b)) + carve-out + its test; client gate 3 lock-step fixes + pruned walk + `--self-test` bites; 10 client STRIPs; 6 `target:` records; **L8 profile matrix** | `boundary_refs.py`, `test-validate-pack-check-43.sh`, `validate-docs.sh`, `.docs-gate-allowlist.txt`, 6 auditor files, `project-template/skills/boundary-investigation/SKILL.md`, `supporting-docs/{INSTALL-PROCEDURES,METHODOLOGY}.md`, `test-validate-docs-template-fullscan.sh` — **14 files** | W1 | See §7.6 — **VERDICT: FITS, with L8 included** |

**Critical path:** W2 → W3 → W4, with W1 in parallel from the start. Four commits.

### 7.5 Fallback if W3 will not converge (ROI-4 keeps this live, not the plan)

If W3 exceeds 2 review/fix pairs, split as **W3a → W3b**:

- **W3a** — the 45 bareness STRIPs + the 8 Check-71 mirrors only. Green because every qualified
  target exists (§7.3) and no gate yet asserts completeness.
- **W3b** — Check 95 + allowlist + exclusion constant + registry + `core.py` + README + test + CI
  wiring. Green on arrival because W3a already stripped its fix-set.

Both boundaries stay green; the cost is that W3a lands with no gate proving its completeness (the
evidence is `c95-triage.json` plus W3b arriving immediately after). **Do not take the split
pre-emptively.**

### 7.6 W4's bounded-cycle verdict, with L8 — my own assessment

The adversarial review's M-6 held that W4 could not absorb one bounded cycle. That was correct
**as W4 then stood**, and the reason was specific: §5.3 of the prior design left 32 of 61 client
occurrences described as *"triage individually"* and *"resolve during implementation"* — i.e. open
discovery inside a commit. ROI-2 adds work to that wave, so the verdict has to be re-taken rather
than assumed.

**VERDICT: W4 FITS one bounded review/fix cycle, with L8 included.** The evidence:

1. **The open discovery is gone — that was the whole of M-6.** All 29 client occurrences carry a
   design-time verdict, a fix recipe, and the profiles they appear on
   (`c288-client-triage.json`). Nothing is left to "resolve during implementation".
2. **The post-fix state is verified, not projected.** EV-4d ran the real patched gate on 8 trees
   and got `rc=0 dangling=0` on every one. The coder re-runs a verification I have already run; a
   reviewer checks 8 exit codes.
3. **W4 is smaller than W3** — 14 files against ~25, and 9 of the 14 are single-line STRIPs at
   given file:line coordinates.
4. **L8 adds 29 substantive lines and no infrastructure** (EV-7): it reuses L5's `$INSTALL_ROOT`,
   the existing portable `mktemp` root, the existing trap, and the existing `pass`/`fail`
   counters, and it is pre-audited clean against Check 83's three classes and Check 92. Its profile
   roster is the one I already executed — the coder transcribes a measured harness, it does not
   invent one.
5. **ROI-1=(b) made the wave simpler, not harder:** dropping the `startswith` guard removes a
   conditional and its edge case; the 3 extra occurrences it catches were already in the wave's
   STRIP set as client-gate fixes.

**The one strain point, named honestly.** The three-site `lstrip`/fallback change plus the
`--self-test` bite assertions is the most intricate code in the BD, and a reviewer must actually
read the `--self-test` legs rather than trust the exit code. If W4 does strain, the clean split is
**W4a** (Check 43 self-tree leg + its test + the 9 pack-side STRIPs — the whole leg is green on its
own, EV-2) → **W4b** (client gate + client allowlist + L8). Both boundaries green; W4b keeps the
client fix-set with its guard. As with §7.5, this is a fallback, not the plan.

---

## 8. Verification strategy (`verify-full-ci-suite`)

Every wave runs the FULL battery, not `validate-pack.py` alone:

1. `python3 scripts/validate-pack.py` → exit 0, `PASSED — all checks clean`.
2. `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → reaches DEEP-only Check 49.
3. **Both** jobs in `.github/workflows/validate-pack.yml`: the unsharded validate job AND the
   dynamic sharded `tests` matrix, including `ci-shard-plan.py --assert-coverage`.
4. `test-fixtures/build.sh --verify` (manifest correctness; the manifest is push-time per
   `regenerate-manifest-v11-surface` and is NOT regenerated per commit).
5. The wave's own per-check tests plus every test named in §6 for that wave.
6. **Named explicitly because they are easy to miss:** **Check 71** (skill-mirror byte-identity —
   any wave editing a `.claude/skills/*/SKILL.md`), **Check 83** and **Check 92** (any wave adding
   or editing a wired test), **Check 59** (registry count) and **Check 80** (doc↔constant twin) for
   W3, **Check 42** and **Check 60** (CI wiring / shard coverage) for W3.
7. W4 additionally: `test-validate-docs-template-fullscan.sh` — now **8** legs (L1–L7 plus the new
   **L8** profile matrix), including L3's bidirectional allowlist liveness — and
   `project-template/scripts/validate-docs.sh --self-test`.

**Anti-vacuity is mandatory (`declare-verify-backing`).** Every new guard leg is
**mutation-proved, not inspected** — revert the check body to its pre-fix form and confirm the new
assertions FAIL. Seven probes:

| Wave | Mutation | Must cause |
|---|---|---|
| W1 | restore the dict-only `isinstance(member, dict)` matcher | the string-form FAIL-leg assertion fires |
| W2 | restore `if Path(token).name in index: resolve` | the moved-file regression assertion fires |
| W2 | restore `root.rglob("*")` scope | the tracked-set assertion fires |
| W3 | empty `_CHECK_95_ALLOWLIST` **or** empty the walk set | the census assertions fire |
| W3 | **remove one prefix from `_CHECK_95_EXCLUDE_PREFIXES`** | the fixture-tree exclusion assertion fires (see below) |
| W4 | remove the `target == citing file` carve-out | the 5 self-provenance banners FAIL — proves the carve-out is load-bearing, not decorative |
| W4 | restore `or base in basenames` in the client gate | the wrong-path-but-basename-exists assertion fires |

The last probe is already demonstrated end-to-end in EV-4d (BITE C): the identical reference passes
vacuously on the shipped gate and FAILs on the hardened one.

**The Check-95 exclusion test must be BOTH live-tree and fixture-based.** Under ROI-3=(b) the
constant is load-bearing on the live tree for two of its five prefixes — `backlog/` and
`changelog/` really do drop `backlog/_rules.md` and `changelog/_rules.md` (EV-1, EV-6) — so those
two can be asserted against reality. The other three (`maintenance-docs/`, `test-fixtures/`,
`scripts/tests/fixtures/`) exclude **zero** live members, so an assertion phrased against the real
repo would pass vacuously. Assert those three against a **fixture tree** carrying a
`maintenance-docs/x.md`-shaped and a `test-fixtures/y.md`-shaped file.

**Regression test reproducing the original mechanism** (an explicit acceptance criterion): a
fixture doc carrying a BARE reference to a file that exists at a DIFFERENT path must FAIL Check 95,
and a QUALIFIED reference to a path that does not exist while its basename does must FAIL Check 68.
**Both fixture trees must be throwaway `git init` repos** — without `git init` the lenient
git-unavailable SKIP path swallows the assertion and the leg passes vacuously. This is the detail
`47f8467` recorded for Check 53's fixtures, and it is why §6.5's Check-92 `mktemp` constraint
applies.

**The ROI-1=(b) proof leg is load-bearing and easy to write vacuously.** Check 43's new test MUST
include a leg where the citing file is a client-installed `supporting-docs/` file, not one under
`project-template/`. Under the superseded narrow conditional that leg passes trivially; under the
decided wide conditional it FAILs. It is the only assertion that distinguishes the two.

---

## 9. Runtime (`ci-check-runtime-compounding`) — for OI-4=(a), no memoization

#### EV-8 — added cost is +16 to +36 ms against a 10 s hard-FAIL budget **[re-verified]**

- **Command:** read the budget constants and their enforcement; time the full battery ×3; time each
  component (median of 5–7); re-time Check 43 with the **wide** self-tree leg; re-size the Check-95
  scan over the **35**-file ROI-3=(b) walk.
- **Output (verbatim):**
  ```
  core.py:125  RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0
  core.py:126  RUN_CHECK_TOTAL_GENERAL_BUDGET_S  = 10.0
  run_check docstring: "A per-check overrun is a LOUD WARN (validate-pack still completes ...);
                        the TOTAL-RUN budget is the hard FAIL (main())."

  full battery wall time: real 2.33 / 2.19 / 2.22   then  2.04 / 1.97 / 1.96   -> PASSED
  _build_basename_index  median 12.3–15.4 ms   (750 basenames)
  _git_tracked_relpaths  median 13.5 ms        (NOT memoized)
  Check-68 rglob over its 2 include-trees: 266 paths, median 2.09 ms
  ROI-3=(b) Check-95 walk: 35 files / 441,529 bytes (431 KB); scan-only median 4.82 ms
  Check 43 median: 158.76 ms (HEAD) -> 166.27 ms (WIDE self-tree leg)   delta 7.51 ms
  walked files: 183
  ```
- **Interpretation — itemised:**

  | Change | Added cost | Note |
  |---|---:|---|
  | Check 95 (index build + scan over 35 files) | **+17 to +21 ms** | O(lines), two precompiled regexes, no subprocess, no tree walk. ROI-3=(b) shaved 2 files / 6 KB / ~0.7 ms off the scan |
  | Check 68 scope → git-tracked | **+11.4 ms**, or **−2.1 ms** | +13.5 (a second `git ls-files`) −2.1 (the rglob it replaces). **If the implementation derives the scope from the `_git_tracked_relpaths()` result Check 68 ALREADY fetches for its basename index, the delta is a 2.1 ms SAVING.** Specified in §4.2 / §6.2 |
  | Check 43 self-tree leg (**wide**, ROI-1=(b)) | **+7.5 ms** | up from +4.6 ms under the narrow form: without the `startswith` short-circuit the pattern runs on all 183 walked files instead of 181. Module-precompiled, one `finditer` per line |
  | Check 81 matcher | **≈0 ms** | one `re.match` over a handful of list members |
  | **Total** | **+36 ms worst case, +16 ms with §4.2's reuse** | |

  Against the binding constraint — `RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0`, a **hard FAIL** — the
  measured total run is 1.96–2.33 s across six runs, leaving **~7.7–8.0 s of headroom**. The
  addition consumes **~0.45 %** of that headroom. Check 95 alone is ~21 ms against the per-check
  **WARN** budget of 2.0 s, i.e. **~1 %** of it.
- **Conclusion:** SUPPORTED. **OI-4=(a) is comfortably safe** — the attack fails by roughly two
  orders of magnitude. No memoization, no cache, no `_reset_basename_index_cache()` helper; the 51
  test files that rebind `REPO_ROOT` in-process are left undisturbed. ROI-1=(b)'s extra 2.9 ms and
  ROI-3=(b)'s ~0.7 ms saving are both noise at this scale.

---

## 10. Cross-BD design-time collision scan (`cross-bd-collision-scan`)

**This BD's blast-radius set:** `scripts/lib/validate_checks/{boundary_refs,cross_bd,core}.py`,
`scripts/validate-pack.py`, `pack-ops/.dangling-ref-allowlist.txt`,
`project-template/scripts/validate-docs.sh`, `project-template/scripts/.docs-gate-allowlist.txt`,
`.github/workflows/validate-pack.yml`, `scripts/tests/`, `README.md`, `CLAUDE.md`, `AGENTS.md`,
`GEMINI.md`, `.claude/skills/`, `.codex/skills/`, `.agents/skills/`, `supporting-docs/`,
`project-template/{.claude,.codex,.agents-plugin}/agents/`, `project-template/skills/`.

#### EV-9 — 31 raw intersections; 9 with Open-status entries; 3 real COORDINATE signals **[carried]**

- **Command:** intersect the set above against the parsed structured `File/Symbol` path tokens of
  every non-Resolved `backlog/BD-*.md` (the Check-82 grammar); separately count project-side entries.
- **Output (verbatim, abridged to the Open-status rows):**
  ```
  open (non-Resolved) BDs with a structured File/Symbol scanned: 51
  COLLISIONS: 31   (Open-status subset: BD-037, BD-039, BD-109, BD-110, BD-171,
                    BD-172, BD-187, BD-192, BD-254, + BD-288 itself)
  BD-039 [Open]  supporting-docs/METHODOLOGY.md
  BD-187 [Open]  supporting-docs/{<filename-TBD>,METHODOLOGY,QUICKSTART}.md
  BD-192 [Open]  CLAUDE.md
  BD-254 [Open]  AGENTS.md | CLAUDE.md | GEMINI.md | project-template/
  BD-037/109/110/171/172 -> directory-level only, each naming a DIFFERENT specific file
  project-side backlog entries: 2  (skeletons; no client entry with a File/Symbol)
  ```
- **Interpretation:**

  | BD | Status | Overlap | Verdict |
  |---|---|---|---|
  | BD-037 / 109 / 110 / 171 / 172 | Open | directory-prefix only (`project-template/skills/`, `scripts/tests/`, `project-template/.claude/agents/`); each names a specific file this BD does not touch | **Not a collision.** Matcher artifact |
  | **BD-039** | Open, no v11.0 target | `supporting-docs/METHODOLOGY.md` — BD-039 adds a Mode section + Procedure-1 conditional logic; this BD reworks one sentence at :1984 | **COORDINATE, low.** Same file, disjoint sections |
  | **BD-187** | Open, blocked on BD-186 | authors a NEW `supporting-docs/<filename-TBD>.md`; this BD edits 6 existing files there | **COORDINATE, low.** Disjoint files. Worth telling BD-187's author that a new `supporting-docs/*.md` inherits Check 95 coverage automatically, because the walk is derived by subtraction |
  | **BD-192** | Open, blocked on "v11.0 ships" | `CLAUDE.md` | **COORDINATE, low.** Cannot co-edit inside this window |
  | **BD-254** | Open, `Target: v11.1` | trinity ×3 + `project-template/` | **COORDINATE, low.** Different sections (Graphify rules vs §6.7's bare-ref qualifications); explicitly post-launch |

  The 21 further intersections are with `Deferred` / `Deprecated` / `Cancelled` entries and carry no
  scheduling consequence; recorded so the count is honest rather than filtered silently.
- **Conclusion:** SUPPORTED — all real overlaps are COORDINATE signals of low strength; **none is a
  gate**. No resequencing required. W3's trinity edits land in one commit so a later BD-254 rebase
  sees one coherent change.

---

## 11. Decision record and the one new open item

### 11.1 Closed — implemented as decided, not reopened

OI-1…OI-8 and ROI-1…ROI-6 are all closed by the user; §1.2 records each decision and where it
lands. Two are worth restating because they cut against an architect recommendation and a coder
must not "helpfully" restore the alternative:

- **ROI-3=(b)** excludes `backlog/` and `changelog/` **wholesale**. My recommendation was (a),
  keeping the two `_rules.md` contracts in the walk. The user weighed it and chose the literal
  reading of their own constraint. **Do not reintroduce `backlog/BD-` or `changelog/v`.** The
  measured cost is zero FAILs and one allowlist entry (EV-1), and the choice dissolves adversarial
  finding S-8 outright.
- **ROI-6=(a)** keeps basename allowlist keys. **Do not "improve" this to path-scoped keys**; §4.3
  records the two facts that make the broader key correct here.

### 11.2 NOI-1 (NEW) — `changelog/_rules.md` ends up gated on neither axis

**Context.** ROI-3=(b) removes both `_rules.md` contracts from Check 95 (the bareness axis). On the
existence axis, Check 68's pre-existing `_CHECK_68_EXCLUDE_PREFIXES` is asymmetric between the two
sibling trees, and that asymmetry now becomes load-bearing:

```
_CHECK_68_EXCLUDE_PREFIXES = ('changelog/', 'backlog/BD-', 'maintenance-docs/',
                              'test-fixtures/', 'scripts/tests/fixtures/', '.git/')
  backlog/_rules.md        excluded from Check 68? False   -> existence axis COVERS it
  changelog/_rules.md      excluded from Check 68? True    -> existence axis does NOT cover it

qualified refs that would FAIL the hardened Check 68 if included:
  changelog/_rules.md: 0
  backlog/_rules.md:   0
```

So after BD-288: `backlog/_rules.md` keeps one axis (existence); **`changelog/_rules.md` has
none** — a live per-entry-tree contract that Pack Chat and every agent execute, with zero
cross-reference gating on either axis.

**This is not a re-argument of ROI-3.** The user's constraint is explicitly about a *bareness*
gate ("NOT to be brought under a bareness gate"); Check 68 is the existence axis, and it already
covers `backlog/_rules.md` today. The gap is in Check 68's constant, which predates BD-288 — but
BD-288 is the entry whose whole remit is guards that do not reach the reality they claim to verify,
and this is the last moment it is cheap to close.

**Options.**
- **(a)** Leave `_CHECK_68_EXCLUDE_PREFIXES` as-is. `changelog/_rules.md` stays ungated on both
  axes. Zero work.
- **(b)** Narrow `'changelog/'` → `'changelog/v'` in `_CHECK_68_EXCLUDE_PREFIXES`, restoring
  symmetry with its `backlog/BD-` sibling and returning `changelog/_rules.md` to the existence
  axis. One token, lands in **W2** (which already edits Check 68). **Measured cost: 0 FAILs** —
  the file's qualified refs all resolve.
- **(c)** Treat the constraint as covering both axes and additionally remove `backlog/BD-` in
  favour of a bare `backlog/`, so the two trees are symmetric in the *other* direction —
  `backlog/_rules.md` loses its existence coverage too.

**Recommendation: (b).** Evidence: (i) measured cost is zero — `changelog/_rules.md` produces no
would-FAIL refs under the hardened ladder, so the change is free today and only bites on a future
bad reference; (ii) it restores symmetry with `backlog/BD-`, which is the shape the sibling already
uses and the shape the design had to reason about for S-8; (iii) it is one token in a file W2 edits
anyway, so it adds no wave, no encoding surface beyond the constant, and no test file (Check 68's
existing per-check test gains one leg); (iv) the entry-shaped `changelog/v` prefix was measured
during S-8 and is correct for the 11 `vN.md` entries. Option (c) is the only option that *reduces*
coverage and I see no argument for it beyond symmetry-for-its-own-sake.

**However, this touches a tree the user named in a standing constraint, so it is the user's call,
and (a) is coherent** — it preserves the trees as a single untouched unit and costs nothing
measurable today. If the user picks (a), the fact should be recorded in the BD entry so the gap is
visible rather than silent. **Whichever is chosen, it lands in BD-288, in v11.0** — this is not a
proposal for a new BD, a phase 2, or a deferral.

### 11.3 Recorded, not open

- **OI-6 (Check 9 has no wired per-check test)** — decided (a): noted, not worked. Check 9's matcher
  does reach its claimed reality (it asserts named docs exist and they do); its gap is test
  coverage, not guard inertness. Recorded here so it is visible rather than lost.
- **The banner/STRIP-target collision (EV-2b)** — surfaced by applying ROI-1=(b), but it has one
  correct answer and no decision to make, so it is a **binding coder constraint** (§6.4), not an
  open item. It is called out because a green gate does not catch the mistake.
- **ROI-5's fence blind spot** — decided (a). The measured population is 1 defect of 18 fenced
  qualified refs; the other 3 allow-side refs are correct. A guard would need a 3-entry allowlist
  for a 1-instance population. The instance is fixed as content in W4.

---

## 12. Change summary

| Defect | Fix | Files | Wave |
|---|---|---|---|
| Check 81 matcher decoupled from its string data | accept dict AND leading-anchored string | `cross_bd.py` + test | W1 |
| Check 82 | **no change** — verified Status-keyed and biting | — | W1 (verify only) |
| Check 68 name-only qualified resolution | install-path-aware ladder (direct / template-prefix / install-map reverse); fallback deleted for qualified refs | `boundary_refs.py`, allowlist +6, 2 STRIPs, 2 mirrors, tests 68 + 41 | W2 |
| Check 68 raw-`rglob` scope | git-tracked, reusing the index's own `_git_tracked_relpaths()` result; lenient SKIP | `boundary_refs.py` | W2 |
| *(NOI-1, if the user picks (b))* `changelog/_rules.md` ungated on both axes | narrow `'changelog/'` → `'changelog/v'` in `_CHECK_68_EXCLUDE_PREFIXES` | `boundary_refs.py` + one test leg | W2 |
| Bareness coverage gap (35 files) | **NEW Check 95**, **26**-entry allowlist, **5 whole-tree** exclusion prefixes | `boundary_refs.py`, `validate-pack.py`, `core.py` (count **+ ledger**), `README.md` ×2, new test, workflow | W3 |
| 45 bareness STRIP occurrences | qualify to the measured single candidate | trinity ×3, 4 `.claude/skills`, 4 `supporting-docs/*.md`, 8 mirrors | W3 |
| Pack-storage paths on client surfaces (pack-side recurrence) | **`_CHECK_43_SELF_TREE_PREFIXES`** — a NEW constant on the qualified leg only, **no citer scoping** (ROI-1=(b)), with a `target == citing file` carve-out | `boundary_refs.py` + test | W4 |
| Client twin ×3 defects | 3 lock-step `lstrip`/fallback fixes (ref side, **allowlist side**, fallback) + pruned walk + `--self-test` bites | `validate-docs.sh` | W4 |
| Client residue | 10 line-targeted STRIPs + 6 `target:` records (13 → 19) | 6 auditor files, `project-template/skills/boundary-investigation/SKILL.md`, `supporting-docs/{INSTALL-PROCEDURES,METHODOLOGY}.md`, client allowlist | W4 |
| Profile-blind standing test | **L8** S9-profile-matrix leg (ROI-2=(b)) | `test-validate-docs-template-fullscan.sh` | W4 |

**Totals.** 1 new check (95). Allowlist growth: **26** `_CHECK_95_ALLOWLIST` entries, **+6**
`pack-ops/.dangling-ref-allowlist.txt` records (51 → 57), **+6** client `target:` records
(13 → 19). **57 reference edits** — 45 bareness STRIP + 2 Check-68 dangling STRIP + 10 client
STRIP. 12 Check-71 mirror propagations (2 in W2, 8 in W3 — `boundary-investigation` twice). 3
client-gate defect fixes + 1 walk prune. 2 matcher fixes (Check 81, Check 43). 1 new test file, 1
new test leg (L8), 7 mutation probes. **Zero deferrals. No new BD. No v11.1 item. No Check 96.**

---

## 13. Rules-Applied Verification Block

| Rule | Verification evidence (quoted, not summarized) | Conclusion |
|---|---|---|
| **agents-never-commit** | Every git verb issued in this pass was read-only: `rev-parse`, `status`, `ls-files`, `archive`, `grep`. Final state: `git status --porcelain` → ` M pack-ops/session-state.json` (the pre-existing Pack Chat snapshot, untouched by me). Earlier in this session, when scratch-provisioning included `git init` / `git config` / `git add` / `git commit` in a **mktemp target**, a hook denied it — *"intervention_mode=full requires a fresh approved-commit token … none present/fresh"* — and I did not retry a variant, hide the verbs inside a script, or ask a peer. That denial is why OI-2's literal form is unexecutable and is reported as such (§5.4), not worked around. | **COMPLIANT** |
| **per-action-approval-sub-agents** | My only writes are in my owned dir: `ARCHITECTURE-BD-288-FINAL.md`, `ARCHITECTURE-BD-288-RECONCILED.md`, `c288-check95-allowlist.json`, `c288-client-triage.json`, `_scratchpath.txt`, `_writetest.md`. Scratch confined to `mktemp -d` → `/tmp/bd288recon.9FSbtJ`. No `rm` outside that tree and my own dir; other agents' handoff dirs were read-only to me (I read `c95-triage.json` and wrote nothing there). Repo integrity re-verified after every profile harness run. | **COMPLIANT** |
| **empirical-evidence-blocks** | 13 blocks — EV-1, EV-2, EV-2b, EV-3, EV-4a, EV-4b, EV-4c, EV-4d, EV-5, EV-6, EV-7, EV-8, EV-9 — each with the command, verbatim output, HEAD `47f8467`, interpretation, and a terminal SUPPORTED verdict. Blocks re-run for this pass are marked **[re-verified]** (EV-1, EV-2, EV-2b, EV-6, EV-7, EV-8); blocks measured earlier at the same SHA are marked **[carried]** so the document stands alone without implying fresh measurement. | **COMPLIANT** |
| **ci-guard-measure-then-bound** | **(1) MEASURE** — EV-1 re-ran the full bareness census under the decided exclusion (`walk size: 35 … 'WOULD_FAIL': 120`), EV-2 the OI-1(b) leg (`WIDE, HEAD … FAIL= 14`), EV-4b the six-profile client matrix. **(2) CATEGORIZE** — `triaged KEEP=75 STRIP=45 UNTRIAGED=0` pack-side; `records: 29 {'STRIP': 10, 'KEEP': 19}` client-side; every occurrence individually verdicted. **(3) FIX-RECIPES** — §4.3's 11-basename table (all 11 targets verified EXISTS), §5.4's class table, §4.4's carve-out. **(4) SIZED EXACTLY** — `allowlist entries: 26 / entries with ZERO measured backing: []`, `dropped-from-27 entries: ['vN.md']`, carve-out `carved=5`, `distinct new target: records: 6`. **(5) VERIFY POST-FIX** — `PROJECTED POST-FIX Check-95 FAILures: 0`; `ROI-1=(b) WIDE, PROJECTED POST-FIX FAIL= 0 carved=5`; `rc=0 dangling=0` on **8** client trees. **git-TRACKED candidate set + lenient SKIP** for Checks 95 and 68; the client gate deliberately does NOT adopt it, on the pack's own recorded evidence. **ABSENCE-of-backing leg** — EV-6 shows 3 of the 5 exclusion prefixes exclude zero live members, so §8 requires a fixture leg for those three rather than a vacuous live-tree assertion. | **COMPLIANT** |
| **declare-verify-backing** | Seven mutation probes (§8), not inspections. The decisive one is run, not promised — EV-4d BITE C: `` `docs/WRONGDIR/PM-CHAT.md` `` FAILs the hardened gate while the shipped gate reports `PASS — operating docs clean`. Bite retained pack-side: `'MERGE-STRATEGY.md' in allowlist? False`. EV-3 is the same rule in the other direction — a mapping that would *over*-bite by 130. EV-2's four-cell table proves the carve-out and the STRIPs are each load-bearing (9 and 5 residue alone; 0 together). §8 flags the two legs that would otherwise pass vacuously: the three inert exclusion prefixes, and the ROI-1=(b) `supporting-docs/`-citer leg. | **COMPLIANT** |
| **ci-check-runtime-compounding** | EV-8, with the budget named and its enforcement quoted: `RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0` is the **hard FAIL**, `RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0` a WARN. Measured battery `2.33 / 2.19 / 2.22` then `2.04 / 1.97 / 1.96`. Added cost itemised and **re-measured for the decisions**: Check 95 `+17 to +21 ms` (35-file walk, `scan-only median 4.82 ms`), Check 43 `+7.51 ms` under ROI-1=(b)'s wide leg (up from +4.57 narrow, quoted), Check 68 `+11.4 / −2.1 ms`, Check 81 ≈0 → `+36 ms worst case`, ~0.45 % of ~7.7–8.0 s headroom. Every new matcher is O(lines) with module-precompiled patterns, no subprocess-per-entry; Check 95's walk is scoped by subtraction to 35 files. | **COMPLIANT** |
| **enumerate-encoding-surfaces** | §6, seven sub-tables. Both gaps the adversarial pass named are closed: **Check 71** (§6.6 — 12 mirror files, `md5` triples quoted, no allowlist, no propagation automation) and the **`core.py` ledger** (§6.1 row 5 — the surface the acceptance criterion is actually about; `validate-pack.py`'s only "registry entries" hits are `:693`/`:701`, both about named-lambda late-binding). Added: **Check 83 + Check 92** on any new/newly-wired test, with L8 pre-audited against both (EV-7); **Checks 59 / 80 / 42 / 60** named in §8; `test-validate-pack-check-41.sh` as a second consumer of `_parse_client_installed_files`; the 3 `supporting-docs/` STRIP files the original §10.5 omitted; and the **L8 leg** as a new row (§6.4 row 16). Deliberate NON-edits recorded (§6.3 row 4). | **COMPLIANT** |
| **verify-full-ci-suite** | §8 names the full battery: `validate-pack.py`, `PACK_VALIDATE_DEEP=1`, **both** workflow jobs including the sharded matrix with `--assert-coverage`, `test-fixtures/build.sh --verify`, per-wave tests, W4's now-**8**-leg fullscan plus `--self-test`, and the easy-to-miss set (71 / 83 / 92 / 59 / 80 / 42 / 60). Baseline green first: `PASSED — all checks clean`, 0 FAIL lines. | **COMPLIANT** |
| **dependency-direction-placement** | The client leg is a SEPARATE project-side change to `project-template/scripts/validate-docs.sh` and `.docs-gate-allowlist.txt`; no code, constant, or helper is shared with the pack side even where behaviour is analogous. The client fix is deliberately DIFFERENT (pruned `os.walk`, not `git ls-files`; no leg A/B), on the pack's own recorded evidence. The 6 new client `target:` records live in the client's own allowlist, never in `pack-ops/.dangling-ref-allowlist.txt`. L8 is a **pack-side test** exercising the shipped client gate — it adds no pack mechanism to client content. No dual-use file; `_SANCTIONED_PACK_SIDE_SHIPPED` untouched and not grown. | **COMPLIANT** |
| **boundary-investigation-precedes-pack-defaults (P-missed-7)** | Every client-side mechanism used is the project-side SSOT: `.docs-gate-allowlist.txt` `target:` records for all 19 client KEEPs (the gate's own documented mechanism, `validate-docs.sh:262-265`), the gate's `--self-test` for bite assertions, and the existing `test-validate-docs-template-fullscan.sh` **extended** by L8 rather than replaced by a new pack test. The pack-repo-anchor hazard was resolved with a project-side record rather than by importing the pack's anchor vocabulary into client content (adding `"in the pack repo"` to `DANGLING_ANCHORS` would clear 6 measured lines to fix 1). | **COMPLIANT** |
| **public-bound-no-leak** | This document and its artifacts live outside the repo and are not client/public surfaces. Every proposed edit to a client/public surface is a path qualification, a path correction, or a count bump — **no new prose vocabulary anywhere**. Check 93 is green at baseline: *"OK: Check 93 — no target-app literal-name leak in any git-tracked file (leg 1, tree-wide) and no domain-vocabulary … leak on client/public surfaces (leg 2 …)"*, and it stays in §8's battery. Neither the target project's name nor its domain vocabulary appears in this document. | **COMPLIANT** |
| **operating-docs-no-history-no-bloat** | This design is a REFERENCE doc and may carry history. Nothing proposed for an **operating** doc adds history: the 57 STRIP edits replace a bare filename or a pack-storage path with the correct path (no dated notes, no "per BD-NNN" provenance); `reason:` fields state what a token IS and which files cite it. **No deferred-or-unimplemented feature is described anywhere** — there is no Check 96, no W0, no W5, no W6, and no "deferred" text lands in any shipped file. NOI-1's option (b) is either built in W2 or not built; neither outcome puts a "deferred" mention in an operating doc. | **COMPLIANT** |
| **filename-uniqueness-heuristic** | `find . -name "<n>" -not -path './.git/*'` → `ARCHITECTURE-BD-288-FINAL.md` **0**, `c288-check95-allowlist.json` **0**, `c288-client-triage.json` **0**. The proposed in-repo file follows the existing unique per-check pattern (highest present is `check-94`). The `c288-` artifact prefix is deliberate so neither file is confused with the `c95-`/`c68-` artifacts in the other handoff dir. | **COMPLIANT** |
| **graph-first-context** | Discovery for this design ran graph-first against the injected absolute path, used verbatim: `graphify explain "check_project_side_bare_internal_refs" --graph /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json --budget 1500 --backend claude-cli` → 14 edges, establishing Check 43's call structure (including `_has_per_line_fence` / `_build_fence_skip_lineset`) **before** any check body was read; and `explain "check_pack_skill_mirror_identity"` → `Source: scripts/lib/validate_checks/boundary_refs.py L4488`. **The fence-skip finding that corrects both prior passes came from that first query.** This pass was verification of already-identified surfaces (P2), so grep/Read was the correct instrument throughout and no new discovery query was needed. | **COMPLIANT** |
| **deferral-is-scope-creep** | Nothing unblocked is pushed out. All 29 client and 120 in-scope pack occurrences carry a design-time verdict. The one decline (ROI-5, a new fence guard) was accepted by the user on measured LOGICAL FIT — `qualified refs inside DENY-LIST fences, repo-wide: 18 … NOT a pack-only deny-list path: 4`, of which exactly **1** is wrong and is fixed in W4. NOI-1 is surfaced as an in-BD option with a recommendation, explicitly **not** as a new BD, a phase 2, or a v11.1 item. | **COMPLIANT** |
| **no-deferral-without-user-direction** | Every option in §11 lands in BD-288, in v11.0. No v11.1 target, no follow-on BD, and no "resolve during implementation" appears anywhere — that phrase was M-6's defect and §5.4 eliminated it. NOI-1's option (b) is scoped into W2, a wave that already exists. | **COMPLIANT** |
| **open-item-surfacing** | The six ROI items are CLOSED and recorded as such (§1.2, §11.1), not reopened — including ROI-3, where the user chose against my recommendation and §11.1 tells the coder not to restore the alternative. **One NEW item, NOI-1, is surfaced rather than silently resolved** (§11.2), with context, three of my own options, a measured evidence base (`changelog/_rules.md: 0` would-FAIL refs; the `backlog/BD-` asymmetry quoted verbatim), and a recommendation of (b) — plus an explicit statement that (a) is coherent and the call is the user's because it touches a tree they named. Two further items are classified as **recorded, not open** (§11.3) with the reason given: OI-6 by user decision, and EV-2b's banner hazard because it has one correct answer and no decision to make. | **COMPLIANT** |
| **memory-not-an-ssot** | Every rule and contract relied on was re-read from the live in-repo SSOT at HEAD `47f8467` — the trinity `## Pack memory`, `backlog/BD-288.md`, `README.md`, and decisively the **check bodies themselves** rather than any prior document's account of them. That is what produced the fence leg, the two-leg constant (EV-3), the allowlist-side `lstrip` (EV-5), the non-existent header prose, and now EV-6's `_CHECK_68_EXCLUDE_PREFIXES` asymmetry: five places where a document's description of the code was wrong and the code was authoritative. No cached rule was acted on. | **COMPLIANT** |
| **large-bd-pipeline-standard** | This is the settled design going into the planner stage. §7 supplies a wave map with file-contention **and semantic** ordering (§7.3), a per-wave bounded-cycle rationale, a re-taken verdict for the wave whose fit was contested (§7.6), and designed fallbacks for both large waves (§7.5, §7.6) so the planner is not improvising at a strain point. Every state-claim carries its command and output for re-running. | **COMPLIANT** |
| **reconciliation-instance-independence** | I am the fresh third instance, author of neither input document. This pass is the **mechanical application of settled user decisions** to my own document, not a second reconciliation, and I did not re-argue ROI-3 — §11.1 records the user's choice and instructs the coder to hold it. Where a decision changed a measurement's inputs I re-ran the measurement rather than reasoning from the prior number (EV-1, EV-2, EV-6, EV-7, EV-8), and re-running EV-1 under the superseded shape first reproduced the carried census digit-for-digit with `UNTRIAGED=0`, validating the replication before the delta was read. | **COMPLIANT** |
| **bounded-review-fix-cycle** | §7.4 sizes each of the four waves to one cycle (max 2 review/fix pairs + 1 final pass) with a stated rationale. **W4's verdict is re-taken explicitly in §7.6** rather than assumed, because ROI-2 added scope to the wave the adversarial pass judged unfittable: FITS, on five pieces of evidence (open discovery eliminated; post-fix verified on 8 trees; 14 files vs W3's 25; L8 = 29 substantive lines with no new infrastructure, EV-7; ROI-1=(b) removed a conditional rather than adding one), with the single strain point named and a W4a/W4b fallback designed. §7.5 keeps the W3 fallback live per ROI-4=(a). | **COMPLIANT** |
| **cross-bd-collision-scan** (`[roles: architect]`) | §10/EV-9, keyed on the structured `File/Symbol` path tokens (the Check-82 grammar), not free text: `open (non-Resolved) BDs with a structured File/Symbol scanned: 51 / COLLISIONS: 31`, Open-status subset {BD-037, 039, 109, 110, 171, 172, 187, 192, 254}. Both backlogs covered (`project-side backlog entries: 2`, skeletons, no `File/Symbol`). Classified per collision; recorded as COORDINATE, none a gate. The decisions changed no blast-radius path, so the scan is carried unchanged. | **COMPLIANT** |
| **rules-applied-verification-block** | This table: every rule named in the spawn prompt, each with quoted evidence and a terminal conclusion. No entry is empty; no entry is AMBIGUOUS; no entry is N/A. | **COMPLIANT** |
| **spawn-unique-naming** | Spawn name `architect-bd288-reconcile` — shape `<role>-<bd>-<facet>` = `architect` + `bd288` + `reconcile`, lowercase kebab, 27 chars, matches `^[a-z0-9][a-z0-9-]{2,47}$`, distinct from `architect-bd288-fullscope`, `architect-bd288-adversarial`, and `architect-bd288-guardbite` within this cycle. | **COMPLIANT** |

---

**End of ARCHITECTURE-BD-288-FINAL.md**
