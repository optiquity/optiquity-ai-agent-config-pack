# ADVERSARIAL ARCH REVIEW — BD-272 — adversarial review of the `pack td` eradication design

> **Part of the BD-272 design chain** (as-landed reference record) — see `backlog/BD-272.md`. Chain order: `RESEARCH-BD-272-BOUNDARY-BLAST-RADIUS.md` → `ARCHITECTURE-BD-272.md` → **ADVERSARIAL ARCH REVIEW (this doc)** → `RECONCILIATION-ARCH-REVIEW-BD-272.md` → `AUDIT-BD-272.md`. Landed by BD-272 (paired report commit); the `pack td` eradication that shipped under BD-272 is the realized consumer of this chain.

**Status:** as-landed reference record (BD-272) · **Design HEAD:** `0d427f9` · **Branch:** v11-dev.
**Reviewer:** `pack-architect` (fresh, independent, adversarial instance — I did NOT author the design or the research).
**Mandate:** REFUTE the eradication design. Default to skepticism; a design that survives is trustworthy.
**Date:** 2026-07-23.
**Canonical checkout read:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.
**HEAD at read time:** `0d427f9` (verified: `git rev-parse --short HEAD` → `0d427f9`, branch `v11-dev`).
**Graph:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json` (used for affected/blast-radius discovery; grep/Read as verification gate — attested §Graph-first).
**Design under attack:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-272.md`.
**Research under attack:** `maintenance-docs/v11-implementation/RESEARCH-BD-272-BOUNDARY-BLAST-RADIUS.md`.

---

## 0. VERDICT — findings-to-reconcile (design is SUBSTANTIALLY SOUND; one MUST, one SHOULD, one NIT)

The design **survives the high-value CI-green attack** and the load-bearing /
delete-vs-rehome attack. I independently re-derived every check the design
claims stays green against the PROJECTED post-edit tree and **could not turn any
of them RED**. Both of the design's "corrections to the research" are
**CONFIRMED CORRECT** by my own measurement. The deletion set is genuinely
self-contained; the two cross-surface couplings (A and B) are real; the
atomic-commit shape is justified; the BD sequencing is accurate.

I found **one genuine MUST**: a surface the design (and the research) *factually
mis-classified* — `pack-ops/dashboard-approvals/dashboard.html` is a **TRACKED**
file, not the "untracked render artifact" both docs assert. This propagates into
the design's own verification gate: the §6.2 grep-to-zero command surfaces
`dashboard.html` as an **unaccounted survivor**, so the verification contract as
written is unsatisfiable / misleading. It does **not** flip the delete-now
decision or the commit shape, and it fails **no** CI check — but it is a factual
error inside the load-bearing verification step and must be reconciled.

This is **not a rubber-stamp**. The MUST is real. The design is trustworthy on
its core analysis and reconciles cheaply.

### Findings, ranked

| # | Severity | Finding | Reconciles by |
|---|---|---|---|
| **F1** | **MUST** | `pack-ops/dashboard-approvals/dashboard.html` is **TRACKED** (not "untracked"), contains live `pack td promote` text, and is **NOT excluded** by the design's §6.2 grep-to-zero gate — it appears as `Binary file … matches`, an unexplained survivor. | (a) reclassify as a tracked GENERATED record (Check-69/86-exempt); (b) add `':!pack-ops/dashboard-approvals/*'` to the §6.2 grep gate; (c) do NOT hand-edit it. |
| **F2** | **SHOULD** | Under OI-2 Option X, the surviving methodology prose keeps `promoted-to:` / `derived-from:` **label mechanics** (PM-CHAT L753-754; METHODOLOGY L1608/L1613/L1616) that are GH-issue **tracker-mode** constructs — incoherent in flat-file mode (the sole supported mode). Not introduced by the fix, but it bears on the X-vs-Y grain call and is a leftover the narrow grep pattern won't catch. | Surface the label-coherence tradeoff in the OI-2 decision so the user rules X vs Y with it visible. |
| **F3** | **NIT** | E3 is labeled "README.md pack-chat-only." Only the README **version table** is pack-chat-only (PACK-AGENTS.md L133/L200); the `scripts/` tree listing (L221) is ordinary coder-editable content. Prescribed handling (coder edits it) is correct regardless — harmless mislabel. | Drop the pack-chat-only characterization for E3 (or note only the version table is). |

Everything else the design asserts, I **re-ran and confirmed** (§2–§7 below).

---

## 1. Completeness of the blast radius — INDEPENDENTLY RE-GREPPED (mandate #1)

**Census re-run (HEAD `0d427f9`, 2026-07-23):**
```
git grep -iE "pack[ -]td|pack_td|tracker[-_]promote"                  → 856 lines / 99 files
git grep -iE "…" -- ':!maintenance-docs/*' ':!backlog/*'              → 192 lines / 19 files
```
The 19 LIVE files match the design's manifest surfaces **exactly** — with the
single classification defect at F1. Per-file line counts I measured:
`dashboard.html`(binary), `CONCEPTUAL-REVIEW-METHODOLOGY.md`(1),
`HELP-FRAGMENT.md`(7), `PM-CHAT.md`(11), `.docs-gate-allowlist.txt`(2),
`README.md`(1), `ci-shard-weights.tsv`(3), `ci-test-wiring-allowlist.txt`(2),
`tracker-edit.sh`(2), `tracker-migrate-forward.sh`(1), `tracker-promote.sh`(47),
`help_fragments.py`(1), `pack-td.sh`(18), `pack-help-test.sh`(12),
`test-tracker-promote-direct.sh`(27), `-path1.sh`(21), `-path2.sh`(29),
`test-validate-pack-check-89.sh`(2), `METHODOLOGY.md`(4). That is 18 design-covered
files + `dashboard.html` (the F1 anomaly).

### Extra-literal sweep (the literals the broad regex can MISS)

| Literal | LIVE hits beyond the manifest | Verdict |
|---|---|---|
| `td promote` / `td resolve` (bare, no `pack` prefix) | none | clean |
| `promote --to=phase` | only `dashboard.html` (F1) + already-covered files | **F1** |
| `tracker_promote` (function names) | ONLY the 5 deletion-set files (`tracker-promote.sh`, `pack-td.sh`, 3 tests) | self-contained ✓ |
| `promoted-to` | `tracker-labels.sh`, `tracker-phase-task.sh`, `tracker-init-test.sh`, `boundary_refs.py:65`, PM-CHAT/METHODOLOGY label prose | scoped-out dormant tracker family (OI-3) + kept-methodology labels → **F2** |
| `/pack-td` (slash-command) | none live (only the check-89 synthetic) | clean |

**Under-scanned surfaces the design might have missed — I checked each; ALL CLEAN:**
```
.github/**                          → git grep pack-td|tracker-promote → 0 hits (no test runner references them)
.mcp.json* / Makefile / *.mk        → 0 hits
**/SKILL.md, **/skills/**           → 0 hits
**/agents/**, .claude/agents/**     → 0 hits
scripts/init-project.sh             → 0 hits (not installed, not asserted)
scripts/lib/detect.sh, pack-help.sh → 0 hits
project-template & pack-root trinity (CLAUDE/AGENTS/GEMINI.md) → 0 hits
pack-ops/PACK-CHAT.md, PACK-AGENTS.md, OPERATING-MODES.md      → 0 hits
```
**Conclusion:** the design's DELETE/EDIT manifest is complete for every LIVE
surface **except** its mis-classification of `dashboard.html` (F1). No missed
live advertising/backing surface. `enumerate-encoding-surfaces` upheld modulo F1.

---

## 2. F1 (MUST) — `dashboard.html` is TRACKED, and the grep-to-zero gate does not exclude it

**Empirical-Evidence Block (HEAD `0d427f9`, 2026-07-23):**
- **Tracked?**
  - `git ls-files --error-unmatch pack-ops/dashboard-approvals/dashboard.html` → prints the path, **exit 0** (⇒ tracked).
  - `git log --oneline -- pack-ops/dashboard-approvals/dashboard.html` → `861834f feat: v11 — BD-224 track dashboard board (D1): commit all three approvals files; dashboard.html -diff -merge + Check 69 classify …`.
  - `git check-ignore -v …/dashboard.html` → **exit 1** (NOT gitignored).
  - `scripts/lib/validate_checks/boundary_refs.py` L3353-3361 enumerates `pack-ops/dashboard-approvals/dashboard.html` (+`-shell.html`,`-url.txt`) in Check 69's EXEMPT set: *"generated non-doc DATA files (the record), NOT operating docs."* `validate-pack.py` L1310 Check 86 (`check_dashboard_approvals_file_cap`) caps the git-**TRACKED** set at exactly those three. **Three checks treat it as a tracked file.**
- **Contains `pack td`?** `git grep -iE "pack[ -]td|…" -- '…'` reports `Binary file pack-ops/dashboard-approvals/dashboard.html matches`; the `promote --to=phase` sweep confirms it embeds `pack td promote --to=phase` text (BD-107/BD-224 `#state` JSON snapshot).
- **The design's own §6.2 step-5 gate, run verbatim:**
  ```
  git grep -iE "pack[ -]td|pack_td|tracker[-_]promote" -- ':!maintenance-docs/*' ':!backlog/*'
  ```
  → returns `Binary file pack-ops/dashboard-approvals/dashboard.html matches` among the hits. The dir is **not** excluded by `:!maintenance-docs/*` `:!backlog/*`.

**Interpretation.** The design (§2.D bullet 3, §2.E context, and the research
§1.4) call `dashboard.html` an *"untracked render artifact … NOT a source
surface. UNTOUCHED."* **The "untracked" premise is false at HEAD `0d427f9`.** The
file is committed, tracked, and explicitly enumerated by Checks 69/86.

**Two impacts:**
1. **Factual (design rationale rests on a false premise).** The correct
   rationale is *"TRACKED generated record; Check-69/86-exempt; regenerated by
   `dashboard-render.py`; embeds CLASS-3 BD-107 history — leave untouched, never
   hand-edit."* The disposition (untouched) is still right; the *reason* given is
   wrong.
2. **Verification-gate GAP (the load-bearing defect).** §6.2 step-5 says the gate
   should return *"ONLY the intended survivors (the dormant tracker family E5/E6
   comment sites … and CLASS-3 excluded)."* `dashboard.html` is **neither** a
   dormant-tracker comment site **nor** CLASS-3-excluded by the gate's path
   filters. A reviewer running the literal command sees an **unexplained binary
   match** and will either (a) wrongly flag the eradication incomplete, (b) burn a
   review cycle investigating, or worst (c) hand-edit a **generated** file —
   which is semantically wrong (regenerated on next render) and risks tripping
   Check 86/88.

**Why F1 is a MUST, not a BLOCKER.** No CI check fails: Check 69 exempts the
file from doc-content gates; Checks 86/88 are file-cap and shell↔spec-sync
(untouched — the eradication does not add/remove files in that dir); no check
validates the dashboard's *text* against `pack-td` existence. And the embedded
`pack td` text is an immutable consequence of preserving BD-107 history (a fresh
render would re-embed it), so it is effectively embedded CLASS-3.

**Remediation (cheap):**
- Reclassify in §2.D: *tracked generated record (Check-69/86-exempt), embeds
  BD-107 CLASS-3 snapshot, regenerated by `dashboard-render.py` — not hand-edited.*
- Amend the §6.2 step-5 gate to `… -- ':!maintenance-docs/*' ':!backlog/*' ':!pack-ops/dashboard-approvals/*'`.
  I verified this closes the gap: with that exclusion added, the gate returns **no**
  binary/dashboard survivor (`git grep … ':!pack-ops/dashboard-approvals/*' | grep -i "binary\|dashboard"` → exit 1, empty).

---

## 3. CI-green REFUTATION — I tried to turn EACH check RED and FAILED (mandate #2)

Re-derived every affected check's matching logic against the PROJECTED post-edit
tree (`ci-guard-measure-then-bound`). **None goes red.** Evidence per check:

### 3.1 Check 60 (shard coverage) — GREEN; research was WRONG, design's Correction #1 is RIGHT
`scripts/lib/ci-shard-plan.py`: `parse_wired_tests()` (L117-151) derives the wired
KEEP set from **DISK** (`os.listdir` of `scripts/`, `scripts/tests/`,
`scripts/tests/fixture-dependent/`) minus the allowlist — the weights TSV is
**not** an input to the KEEP set. `load_weights()` (L175-202) → dict; `_weight_for`
(L205-207) = `weights.get(path, DEFAULT_WEIGHT_S)`. `cmd_assert_coverage`
(L320-378) asserts `union(shards) == keep_set` (both disk-derived) + pairwise-disjoint
+ fixture-cohesion.
- **Delete D3-D5:** they leave the disk glob → leave `keep_set`; shards recompute
  from `keep_set`; `union == keep_set` holds. **GREEN.**
- **Orphan weight rows (if E1 skipped):** a TSV path not on disk is never
  `.get`-looked-up → **no failure.** I confirmed no independent weights-liveness
  check exists (`grep -rn ci-shard-weights scripts/lib/validate_checks/*.py
  scripts/validate-pack.py` → only `WEIGHTS_PATH` in `ci-shard-plan.py`).
- **VERDICT:** The research's *"Removing the 3 tests WITHOUT deleting these rows
  FAILS Check 60"* (§1.3 item 1, C2-i) is **REFUTED**. The design's Correction #1
  is **CONFIRMED**. (E1 still deletes L89-91 for hygiene — correct.)
- **No hidden count gate:** `test-ci-shard-plan.sh` uses synthetic partitions +
  a `"expected 4 shards"` assertion (shard COUNT, not test count); it does **not**
  hardcode the tracker-promote test names. `CHECK_REGISTRY_EXPECTED_COUNT = 86`
  (core.py L190) counts validate-pack CHECKS, not tests — unchanged (no check
  removed). **No count assertion regresses.**

### 3.2 Check 89 + `help_fragments.py` — GREEN unchanged (EEB-5 confirmed)
`check_help_fragment_command_skill_parity` matches `/pack-*` slash spans, not
`scripts/…` spans. `test-validate-pack-check-89.sh` references `/pack-td` /
`/pack-tracker` only in **comments** (L40, L267); case C5 uses a **synthetic**
`scripts/pack-testonly.sh` span (verified L262-270). Deleting `pack-td.sh` changes
nothing. L333 is an illustrative **comment** (E7 cosmetic). **GREEN.**

### 3.3 Check 23 (exec ↔ HELP-FRAGMENT-PACK) — GREEN (drops out)
`check_help_fragment_completeness` (L284) iterates `scripts_dir.iterdir()` (disk).
`pack-td.sh` passes today only via `# pack-internal: true` (verified L2). After
D1 it leaves `iterdir()` → not scanned → passes trivially. The
`len(flagged_internal)` at L326 is an informational print, **not** an asserted
count. **GREEN.**

### 3.4 Check 42 + `ci-test-wiring-allowlist.txt` — GREEN unchanged
The sole PARSED entry is `tracker-bd204-lossless-roundtrip-test.sh` (verified:
`grep -vE '^\s*#|^\s*$'` → that one line). The 3 promote tests are comment-only
narration. Check 42 skips comments. **NO edit, GREEN** (design 2.E correct).

### 3.5 Client docs-gate L3 liveness — GREEN only with E8+E10 LOCKSTEP (Correction #2 CONFIRMED)
`test-validate-docs-template-fullscan.sh` L205-210 (quoted): for each allowlist
`target:` record, if `norm = target.lstrip("./")` appears in **no** corpus doc,
`dead.append(...)` → `sys.exit(1)`. Corpus = `IN_GLOBS` over `docs/pack/*.md` +
OVERLAY_MAP (`METHODOLOGY.md`, `INSTALL-PROCEDURES.md`); the allowlist file itself
is **not** in the corpus.
- **Sole backing measured:** `grep -rn "scripts/pack-td.sh\|scripts/lib/tracker-promote.sh"
  project-template/ supporting-docs/` → the two PATH strings appear in the corpus
  **only at PM-CHAT.md L856-857** (the other two hits are the allowlist rows
  themselves, not corpus). METHODOLOGY.md carries only verb tokens, not the path
  strings.
- **After E10** removes PM-CHAT L854-861 → both path strings vanish from the
  corpus → the two `target:` rows become **dead targets** → L3 FAILS **unless E8
  removes them in the same commit.**
- **VERDICT:** Correction #2 **CONFIRMED** — the interlock is the L3 liveness leg
  (not a generic dangling-reference gate). **E8+E10 are CI-fatally inseparable.**
  E8 line numbers verified (L504-505 pack-td.sh row; L507-508 tracker-promote.sh row).

### 3.6 pack-help-test.sh 2.2 (Coupling A) — GREEN only with E2+E9 LOCKSTEP, and it is genuinely CROSS-SURFACE
`pack-help-test.sh` L177 (quoted): `cp "$REPO_ROOT/project-template/docs/pack/HELP-FRAGMENT.md"
"$TR_CLI2/docs/pack/"` then renders `pack-help.sh --root "$TR_CLI2"` and L185-187
asserts `*"pack td promote"* && *"pack td resolve"*` PRESENT. It reads the **REAL**
project fragment — **not** a synthetic fixture. So E9 (remove rows) breaks the
PRESENT assertion; E2 must flip it to ABSENT. **E2 (pack-side test) ↔ E9
(project-side doc) are inseparable AND cross-surface.** Confirmed atomic. (E2
line numbers verified L185-187; header/inline comments at L142-143/L155-158/L167-170
also need the ABSENT rewrite — design covers this.)

### 3.7 Fixtures (D6) — no manifest interaction
`scripts/tests/fixtures/tracker-promote/` is not in `test-fixtures/manifest.txt`
(`git grep -l tracker-promote -- '*manifest*'` → empty) and not swept by the wired
glob (`parse_wired_tests` never recurses into `scripts/tests/fixtures/`). **No
manifest / Check-62 interaction.** Delete-with-tests is safe.

### Interlock scoreboard (my independent re-derivation)
| Check | Design says | I measured | Agree? |
|---|---|---|---|
| 60 shard coverage | GREEN (disk-derived, orphan-row-tolerant) | GREEN; orphan rows tolerated | ✓ (research refuted) |
| 89 `/pack-*` parity | GREEN unchanged | GREEN | ✓ |
| 23 exec↔fragment | GREEN (drops out) | GREEN | ✓ |
| 42 wiring allowlist | GREEN (comment-only) | GREEN | ✓ |
| docs-gate L3 liveness | GREEN iff E8+E10 lockstep | GREEN iff E8+E10 | ✓ |
| pack-help-test 2.2 | GREEN iff E2+E9 lockstep (cross-surface) | GREEN iff E2+E9, cross-surface | ✓ |
| 35 tracker-phase-task | (not listed) | GREEN — unaffected (dormant family) | ✓ (see §4) |
| 59 registry count (86) | (not listed) | GREEN — no check removed | ✓ |

**No check I can construct goes RED at the commit boundary given the full
manifest.** The CI-green attack FAILS.

---

## 4. The design's two "corrections" to the research — BOTH VERIFIED CORRECT (mandate #3)

- **Correction #1 — "Check 60 does NOT fail on an orphaned weight row."**
  **CONFIRMED (design right, research wrong).** Proof in §3.1: `parse_wired_tests`
  is disk-derived; weights are `.get(path, DEFAULT)` LPT hints; no weights-liveness
  check exists. The research's C2-i / §1.3-item-1 claim is refuted. (The rows are
  still deleted by E1 for hygiene — non-fatal but correct.)
- **Correction #2 — "the interlock is the L3 allowlist-LIVENESS leg; PM-CHAT
  L856-857 are the ONLY corpus refs."** **CONFIRMED.** Proof in §3.5: the dead-target
  logic is L205-210; a full corpus grep shows the two path strings appear only at
  PM-CHAT L856-857; METHODOLOGY carries verb tokens, not path strings; the allowlist
  file is not in the corpus. Removing L856-857 without E8 makes both rows dead
  targets → L3 exit 1. The exact CI mechanism is correctly pinned.

Both corrections improve on the research and are evidence-grounded. No refutation.

---

## 5. Load-bearing / delete-vs-rehome — the workflow IS dead; delete-now is safe (mandate #4)

Independently re-verified every "dead" claim:
- **No `pack` dispatcher:** `ls scripts/pack scripts/pack.sh bin/pack pack` → all
  `No such file`. No router maps `pack td` → `pack-td.sh` (`git grep` for a
  `case … td)` / dispatch → none). EEB-2 **SUPPORTED**.
- **Backing does not ship:** `find project-template -name pack-td.sh -o -name
  tracker-promote.sh` → empty; `_SANCTIONED_PACK_SIDE_SHIPPED =
  {scripts/lib/detect.sh, scripts/pack-help.sh}` (boundary_refs.py L593-596) — neither
  file a member; `init-project.sh` has **0** references. EEB-1 **SUPPORTED**.
- **Deletion set self-contained:**
  - `git grep -nE "tracker_promote_[a-z_]+|next_phase_task_M|phase_task_M_in_use"
    -- 'scripts/lib/*.sh' ':!…tracker-promote.sh'` → **empty** (no external caller of
    the exported functions).
  - Only live `source` of `tracker-promote.sh`: `scripts/pack-td.sh:65` (itself
    deleted). `git grep "source[^#]*tracker-promote" -- ':!scripts/tests/*'
    ':!maintenance-docs/*' ':!backlog/*'` → that ONE line.
  - `tracker-edit.sh` L35/L491 and `tracker-migrate-forward.sh` L72 are **COMMENTS**
    (verified: `grep "source[^#]*tracker-promote" tracker-edit.sh` → exit 1, no
    match). They cite a *call shape*, not a runtime dependency. **Deleting the lib
    does NOT break the dormant tracker family** (E5/E6 fix the stale comments).
  - No 4th test: `git grep -ilE "tracker_promote"` → exactly the 5 deletion-set
    files. `test-tracker-phase-task.sh` uses `tracker_labels_promoted_to` (a
    tracker-labels.sh function), not `tracker_promote_*`.
- **No presence gate:** `grep -rnE "tracker-promote\.sh|pack-td\.sh"
  scripts/lib/validate_checks/*.py scripts/validate-pack.py` → only the
  help_fragments.py L333 **comment** (E7). No validator asserts these files EXIST.

**VERDICT:** `pack td`/`tracker-promote.sh` is dead in practice — only its own 3
tests exercise it, nothing live invokes it, nothing live sources it, no lib calls
its functions, no check demands its presence. **Delete-now breaks no runtime
path** (`declare-verify-backing` re-verified: not-shipped, no-invoker, comment-only
cross-refs — all re-measured, not accepted from the design). The delete-vs-rehome
call (DELETE now; a future verb ships fresh under BD-257) is sound; re-home would
import the BD-214-deferred tracker subtree, confirmed dormant.

---

## 6. Commit-shape + atomicity — SOUND (mandate #5)

- **One cross-surface commit is forced, not a stylistic choice.** Coupling A
  (E2↔E9) spans pack-side test ↔ project-side doc and is CI-fatally inseparable
  (§3.6); Coupling B (E8↔E10) is CI-fatally inseparable (§3.5). At least one commit
  MUST be cross-surface, so **no clean `pack-only`/`project-only` split keeps the
  battery green at every boundary.** A 2-commit split (pack-only delete + a
  cross-surface advertising-removal commit) is *theoretically* possible — a
  `{D1-D6,E1,E4-E7}` pack-only commit stays green because pack-help-test 2.2 (still
  PRESENT-form) still reads the un-edited HELP-FRAGMENT — but the second commit is
  still cross-surface and the split adds no auditability value while separating the
  delete from its own advertising-removal (inviting an inverted-violation
  intermediate state). The single atomic commit is the cleaner, correct call.
- **Scope keyword: correctly NONE.** `pack-only` denied (touches
  `project-template/` E8/E9/E10 + `supporting-docs/` E11); `project-only` denied
  (touches `scripts/`, `README.md`, `pack-ops/…`). Per CLAUDE.md the no-keyword case
  = "Check 36 skipped (no claim to verify)" — **no misfire.** Check 36 only bites a
  CLAIMED scope; neutral framing is correct.
- **Check 36 does not otherwise trigger:** it verifies a subject keyword against
  the diff; with no keyword there is nothing to verify. Confirmed against the
  CLAUDE.md convention table.
- **CLASS-3 is all history — EXCEPT the F1 mis-label.** `maintenance-docs/**` +
  `backlog/BD-107.md` (Status: Resolved, verified) are genuine record, correctly
  untouched. The one item the design mis-filed under "untouched artifact" is
  `dashboard.html` — which is *tracked*, but its content is embedded CLASS-3, so
  the untouched disposition is right for the wrong stated reason (F1).

**Atomicity verdict: the couplings are real, the single-commit shape is
justified, the scope-keyword call is correct.**

---

## 7. BD-272 / BD-257 / BD-136 sequencing — accurate (mandate #6)

Re-ran the collision scan against the live tree (HEAD `0d427f9`):
- **Next number:** `ls backlog/BD-*.md | … | sort -n | tail` → highest is **271** →
  **BD-272** correct.
- **Statuses (all verified by `grep Status: backlog/BD-N.md`):** BD-257 **Open**,
  BD-205 **Open**, BD-210 **Open**, BD-136 **Open**, BD-214 **Resolved**, BD-185
  **Deferred**, BD-107 **Resolved**. Every status the design cites is correct.
- **BD-257 DIRECT collision** (owns client `docs/pack/` + `project-template/scripts/`;
  E9/E10 co-edit `HELP-FRAGMENT.md`/`PM-CHAT.md`) is real → sequence eradication as
  the clean PRECURSOR to BD-257. Defensible: it hands BD-257 a settled client
  surface and preserves the re-home option explicitly. **Not scope-creep** — a new
  BD-272 is warranted (it is a distinct, cross-surface deletion with its own CI
  interlocks; not a sub-part of any open BD).
- **BD-136** (trinity marker preservation) — the design's "minimal, serialize
  same-file if concurrent" call is correct: E10 removes a normal `## TD resolution
  orchestration` H2, not a `[CONDITIONAL]` marker section; no marker-grammar
  interaction.
- **No missed collision.** BD-247 (form-family), BD-202 (`pack update` engine),
  BD-093/205/210 — none structurally intersect the manifest beyond the noted NOTE-level
  overlaps. The scan is keyed on structured paths, not free-text.

**Sequencing verdict: SUPPORTED — BD-272 → BD-257.**

---

## 8. F2 (SHOULD) — surviving label mechanics under OI-2 Option X

**Context.** Option X strips the `pack td` verb tokens but KEEPS the three-outcome
methodology. The surviving prose still instructs applying **`promoted-to:phase-N`
/ `promoted-to:phase-N.M` / `derived-from:TD-NNN` LABELS** — PM-CHAT L753-754
("Resolved with `promoted-to:phase-N` label") and METHODOLOGY L1608/L1613/L1616.
Those labels are **GH-issue tracker-mode** constructs (see `tracker-labels.sh`,
Check 35's label family). **Flat-file per-entry mode is the sole supported mode**
(pack CLAUDE.md Project goals) and has no such labels.

**Options:**
- (i) **Keep as-is under X** — the label prose predates the eradication and BD-257
  owns the client TD surface; defer the coherence fix to BD-257.
- (ii) **Reword the surviving methodology to flat-file terms** in the same commit
  (drop/translate the `promoted-to:` label mechanics to the flat-file `Resolved:` +
  phase-entry-creation the docs already describe at PM-CHAT L811-814).
- (iii) **Prefer Option Y** (delete the whole section, hand all TD-resolution
  guidance to BD-257), sidestepping the label-coherence question entirely.

**Recommendation (logic-based).** Surface the label-coherence tradeoff to the user
**as part of the OI-2 X-vs-Y ruling** — it is currently invisible in the design's
OI-2 framing, which presents X as "keep the methodology, verb was optional" without
noting the surviving methodology carries tracker-mode label mechanics. If the user
rules **X**, pair it with option (ii) (reword labels to flat-file terms) so the
eradication does not leave semi-coherent guidance; if the user rules **Y**, the
question dissolves. Also note: the design's §6.2 grep-to-zero pattern does **not**
include `promoted-to`, so leftover label prose is invisible to that gate — under X
these are intentional survivors, but the design should say so explicitly. This does
**not** affect CI-green or the delete decision; it refines the grain call.

---

## 9. F3 (NIT) — E3 README pack-chat-only mislabel

The design (§6.2) states *"README.md (E3) is pack-chat-only."* Per PACK-AGENTS.md
L133 (*"Writing to README.md **version table** | Pack chat only"*) and L200
(*"README.md (version table)"*), only the **version table** is pack-chat-only. E3
edits the `scripts/` directory tree listing (L221 — verified `pack-td.sh` line,
with L220 `pack-tracker.sh` + L222 `tracker-migrate.sh` the scoped-out dormant
family). That listing is ordinary README content a coder edits directly; no
pack-chat-only carve-out is needed. **Harmless** — the prescribed handling (coder
edits it, whether via scope-in or direct) reaches the same result; the governance
characterization is simply imprecise. No CI check validates the README `scripts/`
tree against disk (`grep` of `validate_checks/*.py` for a readme-tree validator →
none), so removing the line has no interlock. Recommend dropping the pack-chat-only
label for E3.

---

## 10. What the design got RIGHT (attack vectors that FAILED)

For the record, these attacks were tried and each **failed** — the design is
correct on all of them: EEB-1 (unshipped), EEB-2 (no invoker), EEB-3
(self-contained), EEB-4/Correction-1 (Check 60 orphan-row tolerance), EEB-5 (Check
89), EEB-6/Correction-2 (docs-gate L3 liveness), EEB-7/Coupling-A (real
cross-surface), Check 23/42/59/35 green, no hidden count gate, fixtures
manifest-clean, all under-scanned surfaces clean, atomic-commit shape justified,
scope-keyword correctly none, BD sequencing accurate, CLASS-3 (maintenance-docs +
backlog) correctly untouched. The design is trustworthy on its core analysis.

---

## 11. Rules-Applied Verification Block

**reconciliation-instance-independence.** Evidence: I am a fresh instance; I neither
authored the design nor the research. Every conclusion rests on my own re-run
commands (§1–§7), not deference — I confirmed what held (both corrections) AND
found what did not (F1). **Conclusion: COMPLIANT.**

**agents-never-commit.** Evidence: I ran only read-only verbs (`git rev-parse`,
`git grep`, `git ls-files`, `git log`, `git check-ignore`, `ls`, `grep`, `sed`,
`wc`) + `mkdir`/`cat >` to the OUTPUT report path only. No `git add/commit/
checkout/restore/…`. HEAD unchanged at `0d427f9`. Sole write: this report under
`…/packtd-eradication-adv-20260723/`. **Conclusion: COMPLIANT.**

**memory-not-an-ssot.** Evidence: every finding cites a command re-run at HEAD
`0d427f9` with captured output — e.g. `git ls-files --error-unmatch …dashboard.html`
(exit 0), `ci-shard-plan.py` L117-207/320-378, `test-validate-docs-template-fullscan.sh`
L205-210, `pack-help-test.sh` L177/185-187, `boundary_refs.py` L593-596/L3353-3361.
No claim rests on the design's assertions or memory. **Conclusion: COMPLIANT.**

**empirical-evidence-blocks.** Evidence: §2 (F1), §3 (each check), §5 (load-bearing),
§7 (BD scan) each carry the command run + captured output + HEAD/date + interpretation
+ conclusion. **Conclusion: COMPLIANT.**

**ci-guard-measure-then-bound.** Evidence: §3 re-derives each affected guard's
matching logic against the PROJECTED post-edit state (disk-derived wired set;
`.get(default)` weights; L3 substring liveness; Check-23 `iterdir`; fixtures
non-recursion) and projects green/red; guards confirmed to draw from disk /
`git ls-files`. **Conclusion: COMPLIANT.**

**enumerate-encoding-surfaces.** Evidence: §1 independently enumerates every `pack
td` encoding surface incl. the extra-literal sweep (`promoted-to`, `promote
--to=phase`, `tracker_promote`, `/pack-td`) and the under-scanned set
(`.github/`, `.mcp.json`, skills, agents, init-project, trinity, operating docs);
found the one surface the design mis-classified (F1). **Conclusion: COMPLIANT.**

**declare-verify-backing.** Evidence: §5 re-verifies not-shipped (find + sanctioned-set
membership), no-invoker (dispatcher `ls` + router grep), and comment-only cross-refs
(`grep "source[^#]*tracker-promote"` → exit 1) by my own measurement, not accepted
from the design. **Conclusion: COMPLIANT.**

**cross-bd-collision-scan.** Evidence: §7 re-runs the keyed scan — next number
(271→272), all cited BD statuses re-grepped, BD-257 DIRECT / BD-136 minimal
confirmed. **Conclusion: COMPLIANT.**

**open-item-surfacing.** Evidence: each finding (F1/F2/F3) carries context, my own
options, and an evidence/logic recommendation; F2 gives three options + a
recommendation; none deferred to a new BD. **Conclusion: COMPLIANT.**

**graph-first-context.** Evidence: discovery used the graph at the injected path for
affected/blast-radius orientation, then `git grep`/`Read` as the verification gate
on exact bytes (the census, line numbers, and check logic were all grep/Read-verified).
G1 satisfied; grep used as the completeness gate per the rule. **Conclusion: COMPLIANT.**

**rules-applied-verification-block.** Evidence: this section — each in-force rule
named with quoted/pathed evidence + a terminal COMPLIANT conclusion; no AMBIGUOUS
state. **Conclusion: COMPLIANT.**

---

*End of ADVERSARIAL-ARCH-REVIEW-BD-272.md (handoff name: `ADVERSARIAL-PACKTD-ERADICATION.md`). Adversarial review only — I attack, I do
not redesign. Verdict: findings-to-reconcile (F1 MUST, F2 SHOULD, F3 NIT); the
design's core CI-green + self-containment analysis and both research-corrections
survive independent re-derivation.*
