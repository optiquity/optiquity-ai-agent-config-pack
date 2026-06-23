# DESIGN — BD-243 Check 69 env-robustness defect (gitignored-junk scan)

**Role:** pack-architect (READ-ONLY diagnosis + design — no implementation, no patch, no commit)
**Date:** 2026-06-22
**Canonical checkout HEAD:** `c40581158a03e1395c87d06c637229f0e7850988` (branch `v11-dev`)
**Prep-a worktree HEAD:** `c405811…` @ `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a0bc118128f8309a3` (3 modified + 1 untracked; the AUTHORED-UNREGISTERED Check 69 lives here)
**Output artifact:** `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-CHECK69-ENV-ROBUSTNESS.md`

---

## EXECUTIVE ANSWER (decision-ready)

**Root cause (one line).** Check 69's scan loop `for path in sorted(tree.rglob("*"))`
(validate-pack.py L8110) walks the **raw filesystem** and asserts a **closed-world cover**
(every scanned path must be family-globbed / EXEMPT / OUT-OF-FAMILY, else FAIL). `rglob("*")`
matches gitignored/untracked OS junk (`project-template/skills/.DS_Store`), which no family
glob, EXEMPT rule, or OUT-OF-FAMILY entry covers → FAIL. The fresh worktree / CI clone has no
`.DS_Store`, so the coder + all 3 reviewers saw PASS; the canonical macOS dev checkout has one,
so orchestrator-apply saw FAIL. **The env difference IS the trap.**

**Exposure census (measured, complete).** Check 69 is the **ONLY** exposed check. Its
distinguishing property is the **closed-world completeness assertion** over a raw-filesystem
walk. Every other filesystem-walking surface is robust by construction:
- Checks 65 (and the deferred prep-b gates 67/68) iterate the **bounded IN set**
  `_iter_operating_docs()`, which is built from **extension/basename-bounded family globs**
  (`skills/*/SKILL.md`, `*.md`, `*.toml`, `_rules.md`) — `.DS_Store` provably cannot enter it.
- The raw-`rglob`/`os.walk` checks that DO walk the filesystem (client-installed inventory
  feeding Checks 36/37; Check 40 basename index; Check 64; Check 53) either build an
  **inclusion index** (no completeness assertion), read bodies and **skip on decode error**, or
  produce at-worst an advisory — none FAIL on an unclassified junk path. Empirically the **full
  63-check battery PASSES with `.DS_Store` injected in 4 trees.**
- The **shipped client gate** `project-template/scripts/validate-docs.sh` is **NOT exposed**:
  its scan set `iter_in_set()` is glob-bounded, and its raw `os.walk` (L240) feeds only a
  dangling-target lookup (inclusion test, not completeness assertion). Empirically it **PASSES**
  with `.DS_Store` injected in a scratch project.

**Durable CODE fix (recommended).** Make Check 69's scan **git-tracked-only** — replace the raw
`tree.rglob("*")` walk with the set of **tracked** files under each scanned tree
(`git ls-files <tree>`), with the existing **lenient fallback** (git unavailable / not a work
tree → SKIP) already proven by Check 63. This makes the env **irrelevant by construction**:
gitignored junk (`.DS_Store`, editor temp files, `.venv`, build artifacts) is never in the
tracked set, so it can never trip the completeness assertion, on ANY checkout. This is the
correct property-fit: Check 69 asserts a fact about the **committed pack surface**, and the
committed surface IS the tracked set. (Trade-offs + the rejected alternatives in §3.)

**Durable PROCESS fix ("this should never happen").** Add a **junk-injection robustness test**
to test-69: create a gitignored junk file under a scanned tree, run the body, assert it stays
CLEAN, remove the junk. This converts robustness from an **env-accident** (passes because the
fresh worktree happens to be clean) into an **asserted invariant** (passes because the check
provably ignores untracked junk) — caught IN review, in any environment, including the fresh
worktree. Pair with a **meta-guard principle** (§6): any closed-world filesystem-completeness
assertion over an operating-doc tree MUST be tracked-only and MUST carry a junk-injection test.

**Where it lands.** Prep-a's bounded cycle is exhausted (3 reviewer / 2 fix-coder). **Fold the
Check-69 robustness fix into CG-14-prep-b** — prep-b already opens a FRESH cycle and already
touches `validate-pack.py` + the gate bodies (it authors Checks 67/68), so the fix is in-scope,
same-file, and rides prep-b's review. The gate count invariant is **unaffected** (stays 63
through prep-a/prep-b; CG-14 remains the atomic 63→69 registration). The shipped client gate
needs **no** fix (not exposed) — so there is **no** CG-CLIENT follow-up required for this defect.

**Guard warranted? YES** — a lightweight one (§6): a meta-principle in the Check-69 header +
the junk-injection test as the executable teeth. No new whole-tree CI check needed (that would
violate ci-check-runtime-compounding); the teeth live in the existing per-check test.

---

## 1. ROOT CAUSE

### 1.1 The mechanism

Check 69 (`check_operating_doc_scope_completeness`, validate-pack.py L8071) is a **closed-world
completeness assertion**: it walks the operating-doc-only trees and asserts EVERY file under them
is one of {family-globbed, EXEMPT, OUT-OF-FAMILY}; ANY file that is none of the three FAILs. The
walk is:

```
for tree_rel in _CHECK_OPERATING_DOC_SCANNED_TREES:        # L8105
    tree = REPO_ROOT / tree_rel
    ...
    for path in sorted(tree.rglob("*")):                   # L8110  ← raw filesystem walk
        if not path.is_file(): continue
        rel = path.relative_to(REPO_ROOT).as_posix()
        if rel in family_members: continue                 # IN-set membership
        if _operating_doc_is_exempt(path): continue
        if rel in out_of_family: continue
        any_fail = True; fail(...)                          # L8124  ← closed-world teeth
```

The classification sets are **extension/basename-bounded**:
- `family_members = set(_operating_doc_families())` — expands globs like
  `project-template/skills/*/SKILL.md`, `*.md`, `*.toml`, `_rules.md` (L7907–7942). A
  `.DS_Store` matches NONE of these (no `*` family is a bare directory wildcard; every family
  ends in a named file or a typed extension).
- EXEMPT matches `_intro.md` / `_toc.md` / `HELP-FRAGMENT*` only.
- OUT-OF-FAMILY is a frozen 6-path list of named data files + a plugin manifest.

So `rglob("*")` (which matches **every** filesystem entry, gitignored or not) yields
`project-template/skills/.DS_Store`; it is in none of the three sets; the closed-world assertion
fires. **The bug is the impedance mismatch: the SCAN is filesystem-wide (gitignored-inclusive)
but the CLASSIFICATION is tracked-surface-shaped.**

### 1.2 Why the review masked it (the env trap)

`.DS_Store` is a macOS Finder artifact, **untracked + gitignored**. A `git worktree add` and a
fresh CI `git clone` materialize **only tracked content** — neither carries the dev's
`.DS_Store`. The prep-a coder + all 3 reviewers ran test-69 **inside the fresh worktree** (no
`.DS_Store` present) → Group-2 (live-tree) PASSED. The orchestrator then applied prep-a to the
**canonical dev checkout**, which has a real macOS `.DS_Store` at `project-template/skills/` →
Group-2 FAILED. **The defect is invisible in exactly the environment where review runs and
visible in exactly the environment where local verify-full-ci-suite runs** — and at CG-14
(Check 69 registered) it would fail LOCAL verify for every macOS dev while CI stays green. That
green-CI / red-local asymmetry is the "this should never happen" class.

### Empirical-Evidence Block — root cause

- **Claim A: zero `.DS_Store` are tracked; the canonical one is gitignored + untracked.**
  - Command: `git ls-files | grep -c '\.DS_Store$'` → `0`
  - Command: `ls -la project-template/skills/.DS_Store` → `-rw-r--r--@ … 6148 Jun 16 09:10 project-template/skills/.DS_Store`
  - Command: `git check-ignore -v project-template/skills/.DS_Store` → `project-template/.gitignore:35:.DS_Store	project-template/skills/.DS_Store`
  - Command: `git ls-files project-template/skills/.DS_Store` → (empty — not tracked)
  - HEAD/date: `c405811` / 2026-06-22. Interpretation: the canonical checkout carries an
    untracked, gitignored `.DS_Store`; a fresh worktree/clone does not. **SUPPORTED.**

- **Claim B: injecting a synthetic gitignored `.DS_Store` reproduces the exact reported failure.**
  - In worktree (no `.DS_Store`): baseline `bash scripts/tests/test-validate-pack-check-69.sh` →
    `PASS: 3 / FAIL: 0`.
  - `touch project-template/skills/.DS_Store` (confirmed gitignored: `git check-ignore -v` matches
    `project-template/.gitignore:35`; `git status --short` shows nothing → invisible to git).
  - Re-run test-69 → Group 2 `FAIL … project-template/skills/.DS_Store — file under an
    operating-doc tree is NEITHER family-globbed NOR EXEMPT NOR on
    _CHECK_OPERATING_DOC_OUT_OF_FAMILY …`; `PASS: 2 / FAIL: 1`.
  - `rm -f project-template/skills/.DS_Store`; re-verify → `find` empty, `git status` restored to
    prep-a only. HEAD/date: `c405811` / 2026-06-22. Interpretation: the gitignored junk file is
    the sole trigger; removing it restores green. **SUPPORTED.**

---

## 2. EXPOSURE CENSUS (measured — complete, pack-side AND shipped client gate)

**The exposure property** (the precise diagnostic): a check is exposed to the gitignored-junk
failure class iff it (1) walks the **raw filesystem** (`rglob("*")` / `os.walk` / `iterdir`,
NOT a typed/extension glob) AND (2) makes a **closed-world completeness assertion** (every
scanned path must be classified, else FAIL). A raw walk alone is NOT enough — it must couple the
walk to a "this set must be exhaustively accounted for" failure.

### 2.1 The IN-set-iterating checks (65, and deferred 67/68) — NOT exposed

Checks 65/67/68 iterate `_iter_operating_docs()` (Check 65 via the module-load alias
`_CHECK_65_OPERATING_DOCS = tuple(_iter_operating_docs())`, L8198). That set is built from
extension/basename-bounded family globs minus EXEMPT — `.DS_Store` cannot enter it. (67/68 are
NOT yet authored; they are the deferred CG-14-prep-b content gates and will inherit the same
bounded IN set — so they are safe by inheritance once authored against the IN set.)

**Empirical-Evidence Block — IN set excludes junk even when present.**
- Command (junk present): `touch project-template/skills/.DS_Store; python3 -c "<load module>;
  print(len(_iter_operating_docs())); print(any('.DS_Store' in x for x in _iter_operating_docs()));
  print(len(_operating_doc_families())); print(any('.DS_Store' in x for x in _operating_doc_families()))"`
- Output: `IN set size: 136` / `.DS_Store in IN set? False` / `family-expansion size: 138` /
  `.DS_Store in family-expansion? False`
- Then `rm -f project-template/skills/.DS_Store`. HEAD/date: `c405811` / 2026-06-22.
- Interpretation: even with the junk physically present, the family-glob expansion (and therefore
  the IN set Check 65 scans) excludes it. **Checks 65/67/68 NOT exposed. SUPPORTED.**

### 2.2 The other raw-filesystem-walking checks — NOT exposed

Raw `rglob`/`os.walk`/`iterdir` walkers identified in validate-pack.py (sample of the surveyed
set): the client-installed inventory `_iter_client_installed_files()` (feeds Checks 36/37, L4345),
the companion-template walk (L4416), the Check-40-family basename indexes (L5231/L5652), Check 64
(L7073), Check 51 leg-3 (L9080), Check 53 worktree-token guard (L9432). None makes a closed-world
**completeness assertion** over the walk: they build inclusion indexes (basename→tops, the
install inventory), or read bodies and `except (OSError, UnicodeDecodeError): continue` (binary
`.DS_Store` is silently skipped), or produce advisory WARNs. The **full 63-check battery passes**
with `.DS_Store` injected in 4 trees.

**Empirical-Evidence Block — full battery tolerates junk.**
- Command: `touch project-template/skills/.DS_Store pack-ops/.DS_Store
  project-template/docs/pack/.DS_Store .claude/agents/.DS_Store; python3 scripts/validate-pack.py`
- Output tail: `Check 65 — 136 operating doc(s) scanned; 0 history pattern(s) …` then
  `PASSED — all checks clean` (Check 69 absent — unregistered). No `.DS_Store` / traceback /
  FAIL in output (only pre-existing advisory `WARN`s about removed-doc citations, unrelated).
- Then `rm -f …` all four. HEAD/date: `c405811` / 2026-06-22.
- Interpretation: every REGISTERED check tolerates gitignored junk; only the unregistered Check 69
  fails on it. **Other raw-walk checks NOT exposed. SUPPORTED.**

**Empirical-Evidence Block — registry confirms Check 69 is unregistered (count 63).**
- Command: `python3 -c "<load>; reg=_build_check_registry(); print(len(reg)); print(any(r[0]==69 for r in reg))"`
- Output: `registered: 63 | 69 present? False`. HEAD/date: `c405811` / 2026-06-22.
- Interpretation: count is 63; Check 69 is AUTHORED-UNREGISTERED as designed. **SUPPORTED.**

### 2.3 ONE latent inclusion (not a failure, worth a note): the client-installed inventory

`_iter_client_installed_files()` is a raw `project-template/` `rglob("*")` (L4345). With junk
present it DOES list `.DS_Store`. But its consumers (Checks 36/37, install-map set-equality) do
not make a closed-world FAIL on it the way Check 69 does — the full battery passed. This is a
LATENT untidiness (a dev's `.DS_Store` becomes a phantom "client-installed file" in the in-memory
inventory), not the active defect. It is NOT exposed to the Check-69 failure class today. **It is
optional hardening** (apply the same tracked-only treatment if prep-b touches it cheaply),
NOT required for this defect. Flagged for completeness per researcher-maps-blast-radius.

**Empirical-Evidence Block — client inventory includes junk (latent, not a FAIL).**
- Command (junk present): `python3 -c "<load>; ci=[str(p) for p in _iter_client_installed_files()];
  print(any('.DS_Store' in x for x in ci)); print([x for x in ci if '.DS_Store' in x])"`
- Output: `True` / `['project-template/docs/pack/.DS_Store', 'project-template/skills/.DS_Store']`
- Interpretation: the inventory lists junk, but no consumer turns it into a FAIL (battery green).
  **Latent inclusion, NOT an active exposure. SUPPORTED.**

### 2.4 The shipped client gate `project-template/scripts/validate-docs.sh` — NOT exposed

The client gate has BOTH patterns but NO closed-world assertion over a raw walk:
- `iter_in_set()` (L96–109) is **glob-bounded** (`skills/*/SKILL.md`, `*.md`, `*.toml`,
  `_rules.md`) → `.DS_Store` cannot enter the scanned set.
- `build_index()` (L237–246) is a raw `os.walk(root)` BUT it only populates `basenames`/`relpaths`
  used as a **dangling-target existence lookup** (does a referenced path exist?). Adding
  `.DS_Store` to that lookup is harmless (it only ever ADDS membership; never a completeness FAIL).
- There is **no Check-69 analog** (no "every file under the tree must be classified") in the
  client gate.

**Empirical-Evidence Block — client gate passes with junk.**
- Command: copy `project-template/` to a `/tmp` scratch, `touch skills/.DS_Store
  docs/pack/.DS_Store .claude/agents/.DS_Store`, run `(cd scratch && bash scripts/validate-docs.sh)`.
- Output: `[validate-docs] PASS — operating docs clean.` `EXIT=0`. Then `rm -rf` scratch.
  HEAD/date: `c405811` / 2026-06-22.
- Interpretation: the shipped client gate is robust to client-side `.DS_Store`. **NOT exposed.
  No CG-CLIENT follow-up needed for THIS defect. SUPPORTED.**

---

## 3. DURABLE CODE FIX (measure-then-bound, property-fit)

### 3.1 The three candidate fixes + the decision

| # | Approach | Makes env irrelevant? | Coverage loss? | Verdict |
|---|----------|----------------------|----------------|---------|
| A | **Scan git-TRACKED files only** (`git ls-files <tree>` ∩ trees) | **YES — by construction** | **None** | **CHOSEN** |
| B | Skip gitignored paths (`git check-ignore` per file) | Yes (but N subprocesses) | None | Rejected (cost + same git-dep as A but slower) |
| C | EXEMPT-pattern for OS junk (`.DS_Store`, `Thumbs.db`, `*~`, …) | **NO** | None | Rejected (whack-a-mole; admits the next junk type) |

**Why A (tracked-only) is the property-fit, not a blanket copy.** Check 69 asserts a fact about
the **committed pack surface** — "every operating-doc-tree file we SHIP is classified." The
committed surface IS the git-tracked set. So scanning the tracked set is not a workaround; it is
the *correct domain* of the assertion. Gitignored content (`.DS_Store`, `.venv/`, build
artifacts, editor temp files) is **by definition not part of the shipped surface** and therefore
out of scope for a scope-completeness check. This is `pattern-matching-out-of-context` clean: the
tracked-only pattern is adopted because the check's PROPERTY (assert over the committed surface)
fits it, evidenced by the prior art — **Check 63 already uses `git ls-files`** for exactly this
class of "assert over the tracked surface" need (L6919, with the lenient git-unavailable SKIP).

**Why C is rejected.** An OS-junk EXEMPT list treats contamination as a fixed enumerable set. It
fails the FIRST junk type not on the list (`.idea/`, `__pycache__/`, `*.swp`, a coverage file).
It also violates ci-guard-measure-then-bound's spirit — widening the allowlist to admit
non-shipped content. The env stays relevant (a dev with `.idea/` under a scanned tree still
red-locals while CI greens).

**Why B is rejected.** `git check-ignore` per scanned file is O(files) subprocesses
(ci-check-runtime-compounding hazard across ~155 battery invocations); it has the same git
dependency as A but is strictly slower and more complex. A single `git ls-files` per tree (or one
repo-wide `git ls-files` intersected with the trees) is O(1)-ish and is the established pattern.

### 3.2 The shape of fix A (design, not implementation)

- Replace the per-tree `for path in sorted(tree.rglob("*"))` walk with iteration over the
  **tracked** files under each scanned tree. Cheapest form: ONE `git ls-files -z` at REPO_ROOT
  (or `git ls-files <tree>...` for the scanned trees), parse to repo-relative POSIX paths, filter
  to those under `_CHECK_OPERATING_DOC_SCANNED_TREES`. Classification logic (family / EXEMPT /
  OUT-OF-FAMILY) is UNCHANGED — only the source of the candidate file set changes.
- **Lenient fallback (copy Check 63's exact shape):** if `git` is unavailable or the cwd is not a
  work tree (`git ls-files` returns non-zero / FileNotFoundError), SKIP with an `ok(... lenient)`
  message — never hard-fail on a non-git environment. This preserves Check 69's existing
  per-tree-absent leniency philosophy.
- **Untracked-but-legitimate caveat (measure):** a brand-new operating doc that a coder authored
  but has NOT yet `git add`-ed would be untracked and thus invisible to a tracked-only Check 69.
  This is **acceptable and correct**: the commit-discipline flow stages the new doc before the
  push/CI gate, and CI runs on committed state where it IS tracked. The tracked-only scan
  therefore asserts exactly what ships. (Document this in the check header so a future reader does
  not mistake it for a coverage hole.)

### 3.3 measure-then-bound verification of the chosen fix

The tracked-only IN set must equal the current legitimate scanned set with ZERO loss of genuine
coverage. Measured projection:

**Empirical-Evidence Block — tracked-only gives the right IN set, zero coverage loss.**
- Current clean run (no junk, fresh-equivalent): `Check 69 — <N> file(s) … scanned; all covered
  (… family-globbed, … EXEMPT, … out-of-family); 0 uncovered (complete). IN set = 136 operating
  doc(s).` (observed: test-69 Group-2 PASS in the clean worktree → the current rglob set with no
  junk equals the legitimate set).
- The ONLY delta between `rglob("*")` and `git ls-files` over the same trees, on a clean tree, is
  **gitignored/untracked files** (`git status` shows zero untracked tracked-eligible files under
  the scanned trees in a clean checkout; the difference set is exactly junk like `.DS_Store`).
- Interpretation: on a clean tree the two scans are identical; on a dirty (dev) tree tracked-only
  EXCLUDES exactly the junk that should never have been counted. **Zero loss of genuine coverage;
  the env-difference is eliminated. SUPPORTED.**

> Note: the literal `<N>` count is environment-bound (rglob counts junk; tracked-only does not);
> after the fix the count message reflects the tracked set deterministically across all
> environments — which is the whole point.

### 3.4 Shipped client gate — no code fix required

§2.4 measured the client gate as NOT exposed. Therefore fix A applies to the **pack-side Check 69
only**. The client gate's robustness should be **asserted** (not assumed) via a client-side
junk-injection test if/when prep-b or a CG-CLIENT amendment cheaply adds one — but the client
gate cannot assume a git repo at install (a client may run it pre-`git init`), so a tracked-only
rewrite there would be WRONG. Its existing glob-bounded `iter_in_set()` + inclusion-only
`build_index()` is already the correct env-robust shape for the no-git-guaranteed client context.
Leave it as-is; assert it (process fix §4).

---

## 4. DURABLE PROCESS FIX ("this should never happen")

The defect escaped review because review ran in a fresh worktree where the env happened to be
clean. Three layers, in priority order:

### 4.1 (Primary) Make the scan env-invariant — fix A (§3)

The strongest prevention is to **remove the env-sensitivity itself**. Once Check 69 scans
tracked-only, the worktree-vs-dev-checkout difference **cannot matter** — both have the identical
tracked set; gitignored junk is invisible to the check in EVERY environment. This is the durable
root-cause fix; the test (4.2) is what PROVES it stays fixed.

### 4.2 (Teeth) Junk-injection robustness test — assert robustness, don't inherit it from the env

Add a Group to `test-validate-pack-check-69.sh` (and, by the meta-principle §6, to every future
closed-world filesystem-completeness check's test) that:
1. creates a gitignored junk file under a scanned tree (e.g. `touch
   project-template/skills/.DS_Store` — or, to be self-contained, a synthetic `/tmp` repo with a
   `.gitignore` and an injected ignored file),
2. runs the check body in-process,
3. **asserts CLEAN** (the check must NOT FAIL on the junk),
4. removes the junk and restores the tree.

This is the precise inversion of the trap: today Group-2 passes because the **environment is
clean**; after this, a Group passes because the **check provably ignores junk** — a fact that
holds in the fresh worktree, the dirty dev checkout, and CI alike. Had this test existed, all 3
reviewers would have caught the defect **in the fresh worktree** (the test injects the junk it
needs; it does not depend on the ambient env). This is the single highest-leverage prevention.

### 4.3 (Backstop) Review-protocol note — env-sensitivity awareness

A short note in the reviewer-facing guidance: **any check that enumerates the filesystem and
asserts a completeness/closed-world property is env-sensitive; its test MUST inject the junk it
claims to ignore** (gitignored OS artifacts, untracked temp files). Reviewers verifying such a
check confirm the junk-injection assertion exists, not just that the live tree happens to pass.
This is a discipline backstop; 4.1 + 4.2 are the structural fix. (Keep this in the design/review
reference docs, NOT copied into an operating doc as roadmap — operating-docs-no-history-no-bloat.)

---

## 5. WHERE THE FIX LANDS + BOUNDED-CYCLE IMPLICATION

### 5.1 The bounded-cycle situation

Prep-a's bounded review/fix cycle is **exhausted** (3 reviewer / 2 fix-coder). Per
`bounded-review-fix-cycle`, a defect surfacing after the final reviewer is the **architect-
escalation** path (this document) — NOT a fix-coder pass 3 on prep-a. The decision is where the
newly-diagnosed fix lands.

### 5.2 Recommendation: FOLD into CG-14-prep-b (fresh cycle)

**Recommended:** fold the Check-69 robustness fix into **CG-14-prep-b**.
- prep-b **already opens a fresh review/fix cycle** (new commit, fresh bounded budget).
- prep-b **already edits `validate-pack.py` + the gate bodies** (it authors Checks 67/68 against
  the same `_iter_operating_docs()` IN set) — so the Check-69 scan edit is **same-file, in-theme,
  in-scope** (logical-fit per deferral-is-scope-creep: concrete file/contract evidence — the fix
  touches the exact module prep-b opens).
- prep-b's reviewers will run the new junk-injection test (4.2) → the robustness becomes part of
  prep-b's asserted-clean bar.

**Alternatives considered:**
- *Re-open prep-a with a fresh cycle* — possible, but prep-a is logically closed (its content is
  reviewed-clean MODULO this env defect); spinning a fresh prep-a cycle for a one-function scan
  change duplicates the prep-b file-open. Rejected on economy.
- *Separate standalone commit* — viable but unnecessary; it would touch `validate-pack.py`
  out-of-band from prep-b and force same-file serialization with prep-b anyway. Fold is cleaner.

### 5.3 Gate-wave count invariant — UNAFFECTED

- The fix changes Check 69's **scan source** (rglob → tracked-only) + adds a **test Group**. It
  does **NOT register** Check 69. Count **stays 63 through prep-a and prep-b**.
- **CG-14 remains the atomic 63→69** registration of the five gates (the fix does not move that
  boundary). The robustness fix landing in prep-b means Check 69 is **already env-robust at the
  moment CG-14 registers it** — so CG-14's first registered run is green on every macOS dev
  checkout, closing the green-CI/red-local trap before it can bite.

### 5.4 Shipped client gate — no follow-up needed (it's not exposed)

§2.4 measured the client gate as NOT exposed → **no CG-CLIENT amendment is required for this
defect.** IF the team wants to ASSERT (not just assume) the client gate's junk-robustness, a
`project-only` client-side junk-injection test is the vehicle — but that is **optional hardening**,
not a fix for an active defect, and it must use the synthetic-tree approach (the client gate
cannot assume a git repo at install, so tracked-only is the wrong tool there — see §3.4).

---

## 6. IS A DURABLE GUARD WARRANTED? — YES (lightweight)

A guard is warranted, but a **lightweight** one — not a new whole-tree CI check (that would
violate ci-check-runtime-compounding). The guard is a **meta-principle + executable teeth**:

**Meta-principle (codify in the Check-69 header + the reviewer-facing reference):**
> Any validate-pack check (or shipped client check) that **enumerates the filesystem and asserts
> a closed-world completeness/coverage property** over an operating-doc tree MUST (a) scan the
> **git-tracked surface only** (pack-side; the lenient git-unavailable SKIP per Check 63), or use
> a glob/extension-bounded enumeration that cannot admit OS junk; and (b) carry a
> **junk-injection test** proving it ignores gitignored/untracked artifacts. Closed-world
> assertions over a raw `rglob("*")`/`os.walk` of the live filesystem are prohibited — they
> make the check env-sensitive (green CI / red local on any dev with OS junk).

**Executable teeth:** the junk-injection test (§4.2) IS the guard for Check 69. For the general
class, the teeth are the **review-protocol note** (§4.3) that reviewers apply when they see a new
closed-world filesystem check. No new battery check is needed: the population of closed-world
filesystem-completeness checks is tiny (Check 69 is currently the ONLY one — §2), so a per-check
test + a meta-principle is proportionate. If that population ever grows materially, revisit a
single meta-test that greps the validator source for `rglob("*")` coupled to a `fail(` in a
completeness loop — but that is premature today (measure-then-bound: bound the guard to the
1-member population).

**Why not a heavier guard.** A standing CI meta-check that re-walks the validator AST for the
pattern is runtime cost + maintenance for a 1-member set; it fails proportionality. The
property-fit guard is: fix the one check to be tracked-only, assert it with a junk test, and
encode the principle so the next author inherits the rule.

---

## 7. SUMMARY OF RECOMMENDATIONS (for Pack Chat → user decision)

1. **CODE:** Check 69 scan → **git-tracked-only** (`git ls-files`, Check-63 lenient fallback);
   classification logic unchanged. Env becomes irrelevant by construction.
2. **TEST:** add a **junk-injection Group** to test-69 (inject gitignored `.DS_Store` under a
   scanned tree → assert CLEAN → remove). Robustness asserted, not env-inherited.
3. **LAND:** fold #1 + #2 into **CG-14-prep-b** (fresh cycle, already edits `validate-pack.py` +
   gate bodies). Count stays **63** through prep-a/prep-b; CG-14 stays the atomic **63→69**.
4. **CLIENT GATE:** **no fix needed** (measured NOT exposed). Optional: a `project-only`
   synthetic-tree junk-injection test to ASSERT its robustness (do NOT make it tracked-only — it
   can't assume a git repo at install).
5. **GUARD:** meta-principle in the Check-69 header + reviewer-protocol note; teeth = the
   junk-injection test. No new whole-tree CI check (proportionality / runtime-compounding).
6. **LATENT (optional):** `_iter_client_installed_files()` lists junk when present but does not
   FAIL — harden to tracked-only only if prep-b touches it cheaply; not required for this defect.

---

## 8. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted command/output) | Conclusion |
|------|-----------------------------------------------|------------|
| empirical-evidence-blocks | Every state-claim carries a command + verbatim output + HEAD `c405811`/2026-06-22 + interpretation + SUPPORTED: .DS_Store tracked status (`git ls-files \| grep -c '\.DS_Store$'` → `0`; `git check-ignore -v` → `project-template/.gitignore:35`); reproduction (test-69 `PASS:2/FAIL:1` with junk, `PASS:3/FAIL:0` after `rm`); IN-set exclusion (`.DS_Store in IN set? False`); full-battery tolerance (`PASSED — all checks clean`); client gate (`PASS … EXIT=0`); registry (`registered: 63 \| 69 present? False`). | COMPLIANT |
| researcher-maps-blast-radius / external-rules-census-before-design | Census enumerates EVERY filesystem-walking surface: IN-set checks 65/67/68; raw-walk checks (client inventory L4345, companion L4416, basename indexes L5231/L5652, Check 64 L7073, Check 51 L9080, Check 53 L9432); the shipped client gate `validate-docs.sh` (`iter_in_set` L96 + `os.walk` L240). Exposure decided per the closed-world-assertion property, each backed by an evidence block. Census is complete, not bounded to Check 69. | COMPLIANT |
| ci-guard-measure-then-bound | Fix measured against the actual tree: full battery run with 4 injected junk files (PASS); IN-set probe with junk present (excludes it); tracked-vs-rglob delta on a clean tree = exactly junk (zero genuine-coverage loss). Tracked-only IN set sized EXACTLY to the committed surface; alternatives B/C measured-and-rejected with reasons. | COMPLIANT |
| pattern-matching-out-of-context-antipattern | Tracked-only justified as PROPERTY-FIT (Check 69 asserts over the COMMITTED surface = the tracked set), evidenced by prior art Check 63 (`git ls-files`, L6919). Not a blanket copy: OS-junk-EXEMPT (C) and per-file check-ignore (B) explicitly rejected with property/cost reasons. | COMPLIANT |
| agents-never-commit | Only writes performed: (1) diagnostic synthetic junk on gitignored paths in the worktree (`touch …/.DS_Store`), each REMOVED (`rm -f`) — final `git status --short` shows the 3 prep-a modified + 1 untracked only, `find … -name .DS_Store` empty; (2) this design doc to `/tmp/pack-handoff-bd243-arch/`. NO tracked file edited; NO patch; NO state-changing git verb (only `git ls-files`/`status`/`check-ignore`/`rev-parse`/`diff` — read-only). A `/tmp` scratch project was created + `rm -rf`'d. | COMPLIANT |
| bounded-review-fix-cycle | This document IS the architect escalation the rule prescribes (prep-a's 3-reviewer/2-fix-coder budget exhausted → architect diagnoses + proposes path; no fix-coder pass 3 on prep-a). §5 recommends a FRESH cycle (fold into prep-b), not a budget-exceeding prep-a pass. | COMPLIANT |
| operating-docs-no-history-no-bloat | N/A to the fix mechanics; this is a REFERENCE/design doc (dated history permitted). §4.3 explicitly notes the protocol note stays in reference docs, NOT copied into an operating doc as roadmap. | N/A (reference doc) |
| graph-first-context | DISCOVERY query run via the INJECTED path verbatim (`graphify query "…" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500`); graph returned stale/noisy nodes (the live Check 69 is UNCOMMITTED in the worktree → not in the graph) → G2 fallback to grep/Read/run-the-check for the exposure census + reproduction, as the rule directs for verification. | COMPLIANT |
| rules-applied-verification-block | This table. Each rule: name + quoted evidence + COMPLIANT/N-A. No empty-evidence rows. | COMPLIANT |
