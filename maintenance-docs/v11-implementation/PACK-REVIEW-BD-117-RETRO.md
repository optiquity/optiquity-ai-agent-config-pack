# PACK-REVIEW-BD-117-RETRO — RELEASE-GATE.md retroactive per-BD review

**Reviewer:** pack-reviewer (retroactive Batch 21c trial)
**Date:** 2026-05-15
**BD scope:** BD-117 only (RELEASE-GATE.md per-major-version pre-tag checklist)
**Original commit:** `6b2d5fc` (2026-05-12, "feat: v11 — BD-117 RELEASE-GATE.md per-major-version pre-tag checklist (Phase 3.5 Batch 4 first-half)")
**Reviewed HEAD:** working tree at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` on `v11-dev`
**Methodology:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (6 dimensions + touch-point classification + severity scheme)

---

## 1. Scope declaration

**In-scope binding invariant:** RELEASE-GATE.md is the authoritative
five-item pre-tag checklist for any major-version cut, version-agnostic
via `<N>` / `<N+1>` placeholders with v11.0 worked examples explicitly
labeled. Five items only; expansion requires architect+planner per
BD-159; `Last updated:` line is the maintenance hook.

**In-scope BDs:** BD-117 (this BD only).

**In-scope files (BD-117 commit `6b2d5fc` originally touched):**
- `maintenance-docs/v11-implementation/RELEASE-GATE.md` (NEW, 263 lines)
- `BACKLOG.md` (BD-117 entry status flip + File/Symbol path correction)
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` (Batch 4 row file-path correction)
- `IMPLEMENTATION-REPORT-BD-117.md` and `PACK-REVIEW-BD-117.md`
  (workflow artifacts, not under review per "no prior reviews to
  reviewer" rule — but referenced for context anchoring only)

**Out of scope:**
- BD-118 CI wiring (separately retro-reviewed in same Batch 21c group E).
- BD-093 release-pin (Open; consumes RELEASE-GATE; cross-concept
  dependency only).
- BD-114, BD-115, BD-116, BD-119 framework/contracts (each cited but
  out of scope here).
- BD-159 maintainability arch (placement-rule satisfied by the path
  correction; not re-litigated).

**Touch-point matrix vs other concepts:**

| Touch point | Class | Other concept(s) |
|---|---|---|
| `RELEASE-GATE.md` body (5 gate items) | OWNED | BD-117 only authors this doc |
| `RELEASE-GATE.md` cross-references to BD-093/114/115/116/118/119 | SHARED-RO | Other BDs read this list to know they are gated |
| Item-1 `MIGRATOR_*` env-var contract names + hook-function count | CONTRACT | BD-119 framework — changing names breaks adapter |
| Item-3 stdout substrings `Persona contract summary: 3/3 passed` / `All persona contracts PASS.` | CONTRACT | BD-116 `test-persona-contracts.sh` emits these — string drift breaks gate |
| Item-4 job names `validate` and `tests` | CONTRACT | BD-118 `.github/workflows/validate-pack.yml` defines these jobs — rename breaks gate |
| Item-5 stdout substrings `OK:` / `MISMATCH` | CONTRACT | BD-115/BD-120 `test-fixtures/build.sh --verify` emits these |
| Path `maintenance-docs/v11-implementation/RELEASE-GATE.md` | SHARED-RO | BD-159 §3.2 condition 5 enumerates this directory; BD-118 CI yml header references this exact path |

---

## 2. Methodology notes

**Artifacts surveyed:**
- `git show 6b2d5fc -- <file>` for the as-shipped diff of RELEASE-GATE.md.
- `maintenance-docs/v11-implementation/RELEASE-GATE.md` at current HEAD
  (post BD-138 batch renumbering: §2 line 38–39 now read "Batch 22" /
  "Batch 23" rather than the original "Batch 21" / "Batch 22").
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-117.md`
  (for design rationale only, per prompt; not re-reviewing).
- `BACKLOG.md` BD-117 entry (lines 1162–1176) for spec-vs-impl traceability.
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` §1.1,
  §4 Batch 4 row, §7 Verification gates summary.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` §4.1
  (adapter shape) for hook-function count cross-check.
- `scripts/migrate-v10-to-v11.sh` (lines 73–80) for `MIGRATOR_*` env vars.
- `scripts/lib/migrator-core.sh` (lines 89–134, 148–152) for declared
  hook-function count.
- `scripts/test-persona-contracts.sh` (lines 67, 69, 75, 81) for the
  exact stdout strings the gate's pass criterion asserts.
- `test-fixtures/build.sh` (lines 12, 66, 73, 715, 735, 746, 748, 794,
  808, 831, 844) for `--verify` flag and `OK:` / `MISMATCH` strings.
- `.github/workflows/validate-pack.yml` (lines 67, 81, 163, 173) for
  job names `validate` / `tests` and RELEASE-GATE-aware step names.
- `gh run list --help` output for `--commit` flag validity.
- Greps across pack repo for `RELEASE-GATE` references in
  `BACKLOG.md`, `CHANGELOG.md`, `README.md`, `CLAUDE.md`,
  `PACK-CHAT.md`, and the addendum/integration-architect docs.

**Tools/greps/tests used to ground findings:**
- `grep -nE "BD-093|BD-114|BD-115|BD-116|BD-118|BD-119"` against
  `RELEASE-GATE.md` for cross-reference completeness.
- Live execution of item-1 commands (`test -x`, `grep -q`, `grep -E`)
  against `scripts/migrate-v10-to-v11.sh` — all three pass.
- Live `grep` for the item-3 / item-5 stdout substrings against the
  scripts that emit them — all present verbatim.
- `gh run list --help | grep commit` — `--commit SHA` flag exists.

**Per-BD reviewer prompt did NOT load** any prior `PACK-REVIEW-BD-117.md`
content (per "no prior reviews to reviewer" rule). Reviewer reached
findings independently against `BACKLOG.md`, `IMPLEMENTATION-REPORT`,
arch docs, and the on-disk artifact.

---

## 3. Findings

### F1 — `four declarative hook functions` is numerically wrong (should be five)

**Severity:** SHOULD
**Dimension:** (a) Completeness — accurate description of the framework
**Touch-point class:** CONTRACT — adapter contract surface (BD-119)
**Evidence:**
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:54` —
  "uses the documented adapter contract (`MIGRATOR_*` env vars + the
  four declarative hook functions)."
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md:264–269`
  declares **five** hook functions in the adapter shape:
  `migrator_manifest`, `migrator_directory_sweeps`,
  `migrator_relocations`, `migrator_artifact_installs`,
  `migrator_post_report_hook`.
- `scripts/lib/migrator-core.sh:148–152` lists those same five names
  as the contract the core relies on.
- `scripts/migrate-v10-to-v11.sh` defines all five plus an optional
  sixth (`migrator_post_dispatch_hook`).

**Description:** Item 1 names "four declarative hook functions" but the
BD-119 framework's adapter contract enumerates five. A maintainer who
reads RELEASE-GATE before reading ARCHITECTURE-BD-119 would expect to
see four hooks defined and could miss the fifth (`migrator_post_report_hook`),
which is responsible for version-specific guidance text in the
customization report. The miscount is a small but real misrepresentation
of the contract this gate item asserts compliance with.

**Suggested fix:** Change line 54 from "the four declarative hook
functions" to "the five declarative hook functions
(`migrator_manifest`, `migrator_directory_sweeps`,
`migrator_relocations`, `migrator_artifact_installs`,
`migrator_post_report_hook`)". Naming them inline future-proofs the
gate against future hook-count drift — a maintainer changing the count
must update both ARCHITECTURE-BD-119 §4.1 and this gate description in
the same commit.

**Cross-concept impact:** BD-119 (canonical contract source); BD-093
(release-pin BD that consumes this gate text — needs the right number
to validate against). If a future major adds a sixth hook, this finding
also surfaces a maintenance pattern: list the hooks rather than
hard-code the count.

**Rule/principle violated:** Design best practice 1 (single source of
truth) — the count is defined in ARCHITECTURE-BD-119; RELEASE-GATE
restates it but drifted.

---

### F2 — §2 "Run order" mis-groups item 4 with working-tree state

**Severity:** SHOULD
**Dimension:** (a) Completeness / internal consistency
**Touch-point class:** OWNED (RELEASE-GATE prose only)
**Evidence:**
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:30–32` (§2 Run
  order):
  > "items 1 and 4 are working-tree state checks (run any time during
  > release prep); items 2, 3, 5 are command-driven and should be
  > re-run on the exact candidate-tag commit immediately before
  > tagging."
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:229–233` (§4
  Maintenance, contradicting paragraph above):
  > "Item ordering is significant for items 1 and 5 (they are
  > working-tree state — must be true at tag time) and for item 4 (CI
  > must run on the exact tag SHA — fix items 1, 2, 3, 5 first so the
  > candidate SHA is stable). Items 2 and 3 can be re-run independently
  > in any order."
- Item 4 itself (line 159–185) explicitly requires the workflow run on
  the **exact candidate-tag SHA** — i.e., the commit must be pushed
  and CI must have completed. That is *not* working-tree state; it is
  push-state plus CI-runtime state.

**Description:** §2 line 30 puts item 4 in the "working-tree state,
run any time" bucket; §4 line 229 correctly puts item 4 in its own
"must run on exact tag SHA" bucket and groups items 1 and 5 (not 1
and 4) as working-tree state. The two passages are mutually
inconsistent. §4's grouping is correct (item 5's `--verify` compares
HEAD fixtures to the committed manifest — that is working-tree state;
item 4's `gh run list --commit=$RELEASE_SHA` is push+CI state). §2
swaps item 4 and item 5.

**Suggested fix:** Edit line 30–32 to read: "items 1 and 5 are
working-tree state checks (run any time during release prep, but
items 2, 3, 4 must be re-run on the exact candidate-tag commit
immediately before tagging)." This aligns §2 with §4 and with item 4's
own asserts text.

**Cross-concept impact:** None outside this doc. Both passages are
internal prose. BD-093 release-pin is the consumer; ambiguous run-order
guidance could lead the release-pin author to skip a re-run of item 4
after a fixup commit.

**Rule/principle violated:** Design best practice 1 (single source of
truth) — same fact stated in two places, drifted.

---

### F3 — Item 4 common failure mode does not cover post-fixup re-verification

**Severity:** NIT
**Dimension:** (b) Edge cases (bounded — reachable from documented user
path: maintainer fixes item 1/2/3/5, pushes a fixup, re-runs gate)
**Touch-point class:** OWNED (gate prose)
**Evidence:**
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:182–185`:
  > "Common failure mode: the candidate-tag commit was created locally
  > but never pushed, so no CI run exists for that SHA. Push the commit
  > to its release branch, wait for CI, then re-run the gate. Do not
  > tag a SHA without a green CI run."

**Description:** Item 4's common failure mode covers only the "never
pushed" case. A more frequent failure path is: items 1/2/3/5 caught a
problem, the maintainer pushed a fixup commit, the candidate-tag SHA
moved, and the prior CI run no longer matches. The doc nowhere says
"after every fixup commit, re-verify items 2, 3, and 4 because the SHA
moved" in item 4. §4 line 231 partially addresses this for item 4
ordering ("fix items 1, 2, 3, 5 first so the candidate SHA is stable"),
but the maintainer reading item 4 in isolation would not be reminded
to look back at §4.

**Suggested fix:** Append to item 4 common failure mode:
> "Note: any fix to items 1/2/3/5 that lands a fixup commit changes
> the candidate-tag SHA. After each fixup, re-run items 2, 3, 5
> against the new SHA and re-verify item 4 against the new SHA's CI
> run before tagging."

**Cross-concept impact:** None — internal prose. BD-093 release-pin
discipline benefits.

**Rule/principle violated:** Design best practice 6 (idempotency for
orchestration verbs) — re-running on already-applied state is no-op
or replay-safe; the doc does not articulate the replay path explicitly.

---

### F4 — `EXECUTION-PLAN-V11.0.md §7` Pre-tag check row does not cite RELEASE-GATE

**Severity:** SHOULD
**Dimension:** (c) Touch points + cross-concept impact
**Touch-point class:** SHARED-RO (BD-117 reads-from §7; BD-093 will
write to §7 indirectly via pre-tag work)
**Evidence:**
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md:435`:
  > "| Pre-tag check | Batch 24 | all BDs in §1.1–1.5 Resolved;
  > BD-059 verified-closed; CI fully green; final audit clean;
  > per-entry split mirror+TOC in-sync (Check 32+33) | Hold release;
  > resolve gates first |"
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:36–40`:
  > "This gate is separate from per-batch CI gates (those are
  > documented in EXECUTION-PLAN-V11.0.md §7) and separate from the
  > final milestone audit (Batch 22) and dog-food migration (Batch 23).
  > Those run earlier in the release sequence; this gate is the last
  > barrier before `git tag`."

**Description:** RELEASE-GATE bills itself as "the last barrier before
`git tag`" and points to EXECUTION-PLAN §7 for context. EXECUTION-PLAN
§7 has a "Pre-tag check" row at Batch 24 that enumerates: BDs Resolved,
BD-059 closed, CI green, final audit clean, mirror+TOC in-sync — but
does NOT cite "RELEASE-GATE 5 items pass" as a Batch 24 pre-tag
criterion. The two docs do not point at each other from the §7 side.
A maintainer working from EXECUTION-PLAN at Batch 24 could miss the
RELEASE-GATE entirely.

**Suggested fix:** Out of BD-117 scope to fix (EXECUTION-PLAN row
edits are PM-only and would normally land at BD-093 release-pin work).
Surface for BD-093: add to the Pre-tag-check row pass criteria the
phrase "RELEASE-GATE.md 5 items satisfied (per-item evidence in
release-pin BD's `Resolved:` line)". Recording it here so the
back-link is not lost when BD-093 fires.

**Cross-concept impact:** BD-093 (consumer; would benefit); BD-138
batch renumbering already touched the §2 line 38–39 references in
RELEASE-GATE.md to keep them in sync — so the renumbering precedent
exists for cross-doc maintenance.

**Rule/principle violated:** Design best practice 1 (single source of
truth) and the pack memory "filename uniqueness / cross-reference
completeness" heuristic — RELEASE-GATE references EXECUTION-PLAN §7
but EXECUTION-PLAN §7 does not back-reference RELEASE-GATE.

---

### F5 — Item 3 omits BD-115 (mid-dev fixture) trace from item body

**Severity:** NIT
**Dimension:** (a) Completeness — traceability
**Touch-point class:** SHARED-RO (BD-115 fixture consumed by
mid-dev contract)
**Evidence:**
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:127–155` (item
  3 body) names BD-116 (persona contracts) and BD-088 (customization-
  preservation invariants) but does not name BD-115 (the mid-dev
  fixture the mid-dev contract requires).
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:251–252` (§5
  cross-references) does name BD-115 with the correct trace.

**Description:** §5 cross-references BD-115; item 3 body does not.
This is asymmetric — every other BD cited in §5 is also named in the
item it gates (BD-114 → item 2, BD-116 → item 3, BD-118 → item 4,
BD-119 → item 1). BD-115 stands out as cited only in §5. Either it
should be removed from §5 (it's transitively covered via BD-116) or
named in item 3's body for consistency.

**Suggested fix:** Add a one-sentence line in item 3 common-failure-mode
or pass-criterion: "(The `mid-dev` contract requires the BD-115
mid-development fixture under `test-fixtures/existing-project-mid-dev/`
to be built and verified — see item 5.)" This also forward-links item 3
to item 5 in a way that aids the run order in §4.

**Cross-concept impact:** BD-115 (transitive). NIT-level since the
contract aggregator (`test-persona-contracts.sh`) emits a clear failure
diagnostic if the fixture is missing.

**Rule/principle violated:** Design best practice 1 (single source of
truth) — §5 cross-ref list and per-item bodies should be symmetric.

---

### F6 — Item 1 grep regex `^MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)=` overly strict on whitespace

**Severity:** NIT
**Dimension:** (e) Design best practice — graceful handling
**Touch-point class:** OWNED (gate command)
**Evidence:**
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:64`:
  > `grep -E '^MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)=' \`
- `scripts/migrate-v10-to-v11.sh:73–75` matches this exactly (no
  leading whitespace):
  ```
  MIGRATOR_FROM_VERSION="v10"
  MIGRATOR_TO_VERSION="v11"
  MIGRATOR_BASELINE_TAG="${V10_TAG:-v10}"
  ```
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md:258–260`
  shows the canonical adapter shape declares these vars at the top
  level (also no leading whitespace). So the current regex is
  framework-conformant for the v10→v11 case.

**Description:** The regex requires the variable to start in column 1.
The framework's canonical shape mandates that, and the v10→v11 adapter
follows it — so the test passes. But a future maintainer who indents the
declaration (e.g., inside a `if [[ ... ]]; then ... fi` block, or under
`function init_versions()`) would silently fail the gate even though the
adapter contract is satisfied. The regex is brittle relative to a
maintainer who wraps the declarations.

**Suggested fix:** Either (a) tighten the framework spec in
ARCHITECTURE-BD-119 §4.1 to forbid wrapping the env-var declarations
(making the regex's strictness intentional) and add a comment to that
effect in the gate command; or (b) loosen the regex to
`grep -E '^[[:space:]]*MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)='`
to tolerate indentation. (a) is the safer choice for v11.0; the framework
contract benefits from explicit "no wrapping" guidance.

**Cross-concept impact:** BD-119 (framework contract clarification).
Defer to BD-119 author / a future BD-119 doc tightening BD; not a
BD-117 fix.

**Rule/principle violated:** None violated; this is a robustness gap
in the gate test.

---

### F7 — Item 4 pass criterion does not specify what to do when CI is in-flight

**Severity:** NIT
**Dimension:** (b) Edge cases (bounded)
**Touch-point class:** OWNED (gate prose)
**Evidence:**
- `maintenance-docs/v11-implementation/RELEASE-GATE.md:174–180` lists
  pass criteria but does not name the `in_progress` / `queued` states
  that `gh run list` may report.

**Description:** A maintainer running the gate immediately after
pushing a release commit may see `status: "in_progress"` rather than
`completed`. The pass criterion says `status == "completed"` and
`conclusion == "success"`, which is correct, but it does not tell the
maintainer "wait for the run to finish before re-checking." A NIT
explicit reminder would help.

**Suggested fix:** After the pass-criterion bullets, add one bullet:
> "If `status` is `queued` or `in_progress`, wait for the run to
> finish (`gh run watch <run-id>`) and re-check; do not proceed to tag
> until `status` is `completed` and `conclusion` is `success`."

**Cross-concept impact:** None.

**Rule/principle violated:** None; UX gap only.

---

## 4. Coverage notes

**In scope but not exercised by this review:**
- The `MIGRATION-v<N>-to-v<N+1>.md` "expected diff shape" cross-link
  in item 2 was confirmed to point at an existing file
  (`supporting-docs/MIGRATION-v10-to-v11.md` Phase A — line 6 "Forced
  v10→v11 changes"), but the *content correctness* of the expected diff
  shape vs. what the migrator actually produces against real OT was
  not verified — that is the BD-114 dry-run's empirical job, not a
  BD-117 documentation correctness check.
- The `gh run list ... --json status,conclusion,name,headSha` field
  list was not run against a real release-cut SHA (would require a
  release-pin commit which doesn't exist yet); spot-checked only the
  flag's existence in `gh run list --help`.
- No live execution of `scripts/test-persona-contracts.sh` or
  `bash test-fixtures/build.sh --verify` against current HEAD was done
  — out of scope for retroactive doc review; both scripts shipped
  green in their own batches.

**Trinity rule:** N/A — RELEASE-GATE.md is not a trinity file; the
trinity exemption holds.

**CI validation:** Not re-run for this review. The original commit
recorded validate-pack 31/31 PASS and the working tree has not had a
material RELEASE-GATE.md edit since (only the BD-138 batch-renumbering
sweep at line 38–39, which is a docs-only renumber).

---

## 5. Re-architect summary (`ARCH` findings)

**None.** No finding required re-architecture across multiple concepts.
F1 (hook count) and F4 (EXECUTION-PLAN cross-ref) are CONTRACT/SHARED-RO
respectively but have local fixes that don't change the shape of the
contract — the contract is in BD-119, and this gate just needs to
restate it accurately.

---

## 6. Summary table

| # | Severity | Dimension | Touch-point | Location | One-liner |
|---|---|---|---|---|---|
| F1 | SHOULD | (a) | CONTRACT | RELEASE-GATE.md:54 | "four hook functions" should be "five" + name them |
| F2 | SHOULD | (a) | OWNED | RELEASE-GATE.md:30 vs :229 | §2 says items 1+4 are working-tree state; §4 correctly says 1+5 |
| F3 | NIT | (b) | OWNED | RELEASE-GATE.md:182–185 | Item 4 fail mode misses post-fixup re-verification path |
| F4 | SHOULD | (c) | SHARED-RO | EXECUTION-PLAN-V11.0.md:435 | Pre-tag-check row does not cite RELEASE-GATE; surface for BD-093 |
| F5 | NIT | (a) | SHARED-RO | RELEASE-GATE.md:127–155 | Item 3 body omits BD-115 trace; only §5 cites it |
| F6 | NIT | (e) | OWNED | RELEASE-GATE.md:64 | Item 1 grep regex brittle to indentation |
| F7 | NIT | (b) | OWNED | RELEASE-GATE.md:174–180 | Item 4 pass criterion silent on in-flight CI runs |

**Counts:** 0 BLOCKER, 0 MUST, 3 SHOULD, 4 NIT, 0 ARCH.

---

## 7. Methodology friction notes

**Friction items found in the prompt or methodology:**

1. **`Output file` path vs. `READ-only constraints` interaction.** The
   prompt's "Read-only constraints" item says "No Edit/Write on source
   files. The output file is the only file you write." This is clear,
   but the system reminder section about agent file writes ("Do NOT
   Write report/summary/findings/analysis .md files") creates a
   superficially conflicting signal. The prompt's explicit output-path
   instruction overrides the generic guidance, but the override is
   not stated in the system reminder itself — adding "exception:
   write the report file specified by the calling prompt" to the
   reminder would remove the friction.

2. **"Touch-point classification" for prose-only docs.** The methodology
   defines OWNED / SHARED-RO / SHARED-RW / CONTRACT in terms of
   files/symbols. RELEASE-GATE.md is prose, so the classification's
   most useful application here is at the **substring** level (the
   gate's pass-criterion strings are CONTRACT touch points to the
   scripts that emit them). The methodology could note that
   substring-level CONTRACT classification is valid for prose docs
   that assert exact-match against script output.

3. **`Reference docs` in prompt names files that exist as `IMPLEMENTATION-PLAN-V11.0.md`
   in `maintenance-docs/v11-implementation/`** — the prompt cites
   `IMPLEMENTATION-PLAN-V11.0.md` but the actual file in that dir is
   `EXECUTION-PLAN-V11.0.md` (and there is no `IMPLEMENTATION-PLAN-V11.0.md`
   in `maintenance-docs/v11-implementation/`; only `IMPLEMENTATION-REPORT-BD-117.md`).
   The reviewer used `EXECUTION-PLAN-V11.0.md` as the canonical plan
   doc. Surface this for prompt-template correction so future Batch
   21c retro-reviews don't waste time looking for a non-existent file.

4. **No explicit guidance on whether BD-138 batch-renumbering edits to
   the doc body (RELEASE-GATE.md:38–39 changed from "Batch 21" /
   "Batch 22" to "Batch 22" / "Batch 23") should themselves be in
   review scope.** I treated them as out of scope for BD-117 retro
   (they are BD-138 work) and only flagged the non-renumbered Batch
   24 cross-reference gap (F4), which is BD-093 scope. A note in the
   prompt template clarifying "review the doc as it stands today,
   but only flag findings traceable to BD-117's original spec /
   implementation" would tighten the scope.

---

## 8. Reviewer disposition

Three SHOULD-level findings (F1, F2, F4) and four NIT-level findings
(F3, F5, F6, F7). Per the standing fix-all rule and the implicit-
status-flip-on-batch-completion rule, all findings should be addressed
in the BD-117 retro-fix commit, with F4 surfaced as a hand-off note
for BD-093.

No BLOCKER, no MUST. The doc is fundamentally sound: 5 items as
specified, version-agnostic with worked examples, cross-references to
all six dependent BDs, maintenance discipline locked, and every
asserted command + pass criterion verified to work against the current
working-tree state. Findings are quality / completeness improvements,
not correctness defects in the gate's gating ability.
