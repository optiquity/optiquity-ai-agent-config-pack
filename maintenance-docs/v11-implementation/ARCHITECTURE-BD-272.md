# ARCHITECTURE — BD-272 — the real eradication of the `pack td` cross-boundary violation

> **Part of the BD-272 design chain** (as-landed reference record) — see `backlog/BD-272.md`. Chain order: `RESEARCH-BD-272-BOUNDARY-BLAST-RADIUS.md` → **ARCHITECTURE (this doc)** → `ADVERSARIAL-ARCH-REVIEW-BD-272.md` → `RECONCILIATION-ARCH-REVIEW-BD-272.md` → `AUDIT-BD-272.md`. Landed by BD-272 (paired report commit); the `pack td` eradication that shipped under BD-272 is the realized consumer of this design.

**Status:** as-landed reference record (BD-272) · **Design HEAD:** `0d427f9` · **Branch:** v11-dev.
**Author:** `pack-architect` (fresh, read-only instance).
**Date:** 2026-07-23.
**Canonical checkout read:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.
**HEAD at read time:** `0d427f9` (`docs: v11 — BD-224 session-state refresh …`).
**Graph:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json` (25.9 MB, built 06:32 today).
**Input verified:** `maintenance-docs/v11-implementation/RESEARCH-BD-272-BOUNDARY-BLAST-RADIUS.md` (researcher; every load-bearing + interlock claim re-verified below — two corrections recorded).
**Deliverable:** a coder-ready eradication design. This doc designs; it does not edit source and does not make the user's value call.
**Next BD:** highest existing is `BD-271` (`ls backlog/BD-*.md | sort -n | tail -1` → 271); this work opens **`BD-272`** (Pack Chat re-reads the live tree before assigning — reservation lists are not authoritative).

---

## 0. Executive summary

`pack td` (`scripts/pack-td.sh` + `scripts/lib/tracker-promote.sh`, BD-107) is a
project-side TD→phase-promotion workflow wired into the pack's `pack <noun>` CLI
namespace, homed pack-side by the `scripts/pack-<noun>.sh` naming convention,
advertised on the CLIENT surface, whose backing NEVER ships to a client and has
NO runtime invoker. It is dead in practice (only its own 3 tests exercise it).
The user's goal: **eradicate it cleanly — there is no such thing as a pack TD.**

The design is a **DELETE** of the dead pack-backed machinery + a **lock-step
reconciliation** of every surface that encodes its state, landing as **one
cross-surface commit** (neutral framing — no scope keyword) that keeps the full
CI battery green at the commit boundary. "Eradicate" does NOT preclude a future
clean *project-side* TD-promotion verb — if wanted, that is authored fresh under
**BD-257** as a proper client deliverable (`project-template/scripts/`, project
naming, shipped + installed), never a resurrection of `pack td`. The eradication
is the clean PRECURSOR to BD-257 (the user's stated intent), and it is
evidence-supported below.

**Two corrections to the research (measure-then-bound, recorded in §3 EEBs):**

1. **Check 60 does NOT fail on an orphaned weight row.** The wired set is
   DISK-derived (`ci-shard-plan.py::parse_wired_tests`); weights are only LPT
   balancing hints looked up via `.get(path, DEFAULT_WEIGHT_S)`. A weight row
   for a deleted test is never looked up, so `--assert-coverage`
   (`union(shards)==keep_set`) stays green. The 3 weight rows must STILL be
   deleted (enumerate-encoding-surfaces / fail-loud hygiene), but the framing
   "removal WITHOUT deleting these rows FAILS Check 60" is inaccurate.
2. **The docs-gate interlock is the L3 allowlist-LIVENESS leg, not the dangling
   gate.** `test-validate-docs-template-fullscan.sh` L204-210 fails a `target:`
   allowlist record whose target string appears in NO corpus doc ("dead
   target"). Removing PM-CHAT.md's two `scripts/…` path refs makes both rows
   dead → the rows MUST be removed in the SAME commit. (Same conclusion as the
   research; the exact CI mechanism is now pinned.)

---

## 1. Graph-first attestation (graph-first-context)

Per `graph-first-context`, discovery used the graph FIRST, then grep/Read to
verify exact bytes:

- `graphify affected "scripts/lib/tracker-promote.sh" --graph <abs> --budget 1500
  --backend claude-cli` → `No unique node match` (the lib is sourced-only, not a
  top-level graph node); fell through to `query` per G2.
- `graphify query "pack td tracker-promote verb backing references" --graph <abs>
  --budget 1200 --backend claude-cli` → BFS depth-2, 33 nodes (surfaced the
  test-harness + detect neighbourhood; the pack-td/tracker-promote source nodes
  are library-internal).
- The graph confirmed there is NO reverse edge INTO `pack-td.sh`/`tracker-promote.sh`
  from any runtime surface (consistent with §3 EEB-2's "no invoker" finding);
  I then ran the completeness census with `git grep`/`grep`/`git ls-files` as the
  VERIFICATION gate on exact bytes (the graph widened candidate discovery; grep
  pinned the literal set). G1 satisfied; G2 fallback used once (affected → query).

---

## 2. The eradication manifest — every LIVE surface, DELETE vs EDIT (exact)

Verified live set: **6 whole-file/dir DELETEs + 11 in-place EDITs** across pack
and project surfaces (plus 4 verified NO-EDIT surfaces the research flagged).
CLASS-3 historical record (maintenance-docs/ + backlog/) is UNTOUCHED (§2.D).

### 2.A DELETE — whole file / whole dir (pack-side, dead machinery)

| # | Path | Size | Why DELETE (fail-loud-delete-old-source) |
|---|---|---|---|
| D1 | `scripts/pack-td.sh` | 337 L | The `pack td` verb dispatcher. No runtime invoker (§3 EEB-2). Un-backs every CLASS-1 client advertisement. |
| D2 | `scripts/lib/tracker-promote.sh` | 1474 L | The TD→phase orchestration library. Sourced ONLY by D1 + the 3 tests; no other lib sources it (§3 EEB-3). Dead once D1+tests go. |
| D3 | `scripts/tests/test-tracker-promote-path1.sh` | 629 L | Path-1 test; sources D1. |
| D4 | `scripts/tests/test-tracker-promote-path2.sh` | 562 L | Path-2 test; sources D1. |
| D5 | `scripts/tests/test-tracker-promote-direct.sh` | 340 L | Direct-close test; sources D1. |
| D6 | `scripts/tests/fixtures/tracker-promote/` (dir: `BACKLOG.md`, `id-map.json`, `IMPLEMENTATION-PLAN.md`) | dir | Test DATA consumed by D3-D5 via `FIXTURES="…/fixtures/tracker-promote"`. Inert (NOT in the wired-test glob — `ci-shard-plan.py` excludes `scripts/tests/fixtures/`). Delete with the tests. |

**Deletion is self-contained (verified §3 EEB-3):** nothing outside D1-D6 has a
RUNTIME dependency on any of them. `tracker-edit.sh` "matches" a
`tracker-promote.sh` grep only in two COMMENTS (E6), never a `source`/call.

### 2.B EDIT — in place (pack-side)

| # | Path | Exact edit | Interlock / rule |
|---|---|---|---|
| E1 | `scripts/ci-shard-weights.tsv` | DELETE rows **L89-91** (`test-tracker-promote-direct.sh`, `-path1.sh`, `-path2.sh`). | Check 60 hygiene; enumerate-encoding-surfaces (delete-test-keep-weight-row is the exact asymmetry to prevent). NOT CI-fatal if left (§3 EEB-4) but MUST go. |
| E2 | `scripts/tests/pack-help-test.sh` | FLIP the **2.2** assertion **L185-187** from `== *"pack td promote"* && == *"pack td resolve"*` / `t_pass "2.2 client pack td rows present"` to the **absent** form (`!= … && != …` / `t_pass "2.2 client pack td rows absent"`, `t_fail "2.2 client pack td rows leaked"`). Update the header comment **L4-8** and inline comments **L142-143, L155-158, L167-170** to state `pack td` rows are ABSENT on **both** surfaces. | **Coupling A** (cross-surface) with E9. This is the DIRECT interaction with recent work: `97277d6` reconciled 2.2 to assert PRESENT; eradication flips it to ABSENT. |
| E3 | `README.md` | DELETE the **`pack-td.sh`** line (**L221**) from the `scripts/` tree listing. Leave L220 (`pack-tracker.sh`, dormant) and L222 (`tracker-migrate.sh`, dormant) — those are the scoped-OUT tracker family (§4 OI-3). | **pack-chat-only** (commit-discipline §4) → scope into the coder prompt (sanctioned path per CLAUDE.md) OR Pack Chat applies at commit time. |
| E4 | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | **L212** row 6 "Idempotency for orchestration verbs" — replace the `` `pack td promote` `` example with a LIVE idempotent verb (e.g. `` `init-project.sh --update` `` or `` `activate-capability.sh` ``). | operating-docs: current-behavior only; no dead-verb example. |
| E5 | `scripts/lib/tracker-edit.sh` | **L35 + L491** — remove the dangling `tracker-promote.sh:801` file:line cite; reword to describe the `provider_update "$gh_id" "$payload"` payload shape without naming the deleted file (or point at `tracker-provider.sh` where `provider_update` is defined). | Dormant tracker family (BD-214) — COMMENT-only. Dangling file:line cite is also an `architect-doc-reality-reconciliation` drift risk. Not CI-fatal; fix in lock-step. |
| E6 | `scripts/lib/tracker-migrate-forward.sh` | **L72** — reword the comment to drop `` `pack td promote --to=phase-N.M` `` (generalise to "a subsequent link-creating cycle" or remove the sentence). | Dormant family — COMMENT-only. Not CI-fatal. |
| E7 | `scripts/lib/validate_checks/help_fragments.py` | **L333** (OPTIONAL) — the Check-89 comment uses `` `scripts/pack-td.sh`-shape `` as an illustrative regex-anchor example; update to a live file shape (e.g. `scripts/pack-help.sh`). | COSMETIC — an illustration of a regex SHAPE, not a live dependency. Check 89 is functionally unaffected (§3 EEB-5). |

### 2.C EDIT — in place (project-side, CLASS-1 client surfaces)

| # | Path | Exact edit | Interlock / rule |
|---|---|---|---|
| E8 | `project-template/scripts/.docs-gate-allowlist.txt` | DELETE the two FALSE rows: **L504-505** (`target: scripts/pack-td.sh` + reason) and **L507-508** (`target: scripts/lib/tracker-promote.sh` + reason), with their blank-line separators. Both reasons ("present after install, absent from the bare template") are FALSE — neither ships (§3 EEB-1). | **Coupling B** with E10. Mandatory-lockstep: once E10 removes the only corpus refs, these become "dead targets" → L3 liveness FAILS (§3 EEB-6). declare-verify-backing (the rows encode a false "present after install" claim). |
| E9 | `project-template/docs/pack/HELP-FRAGMENT.md` | DELETE the three `pack td …` rows in the Project-commands table (**L20-22**) AND the entire **`## TD promotion`** section (**L25-36**). KEEP the `pack help` row (L23) and the `## See also` block. | **Coupling A** with E2. HELP-FRAGMENT is a verb MANIFEST — with the verb gone there is nothing to advertise. |
| E10 | `project-template/docs/pack/PM-CHAT.md` | The `## TD resolution orchestration` section (**L745-862**). **MANDATORY in every option:** DELETE `### Verb shape` (**L843-852**) and `### Implementation reference` (**L854-861**, the two `scripts/…` path refs). **GRAIN = OPEN ITEM OI-2:** Option X (strip the `pack td …` verb tokens from the table L750-754 + prose L796/L800/L823, KEEP the three-outcome methodology as the manual PM-Chat workflow the section already describes at L811-814) vs Option Y (delete the whole L745-862 section). | **Coupling B** with E8 (the path refs are the live corpus refs). Value/scope call surfaced in §4 OI-2 (recommend X). |
| E11 | `supporting-docs/METHODOLOGY.md` (client-SHIPPED — installed to `docs/pack/METHODOLOGY.md` at init-project S6, verified L680-683) | **L1600, L1606, L1611, L1630** — strip the `pack td resolve` / `pack td promote --to=phase-N` / `--to=phase-N.M` verb tokens and the "`pack td promote` verb has no `--fold-into` flag" line from the Resolution-path decision logic; reword to the manual mechanism (mirror the E10 grain decision so the two client docs stay consistent). | dependency-direction-placement; operating-docs current-behavior only. Grain follows OI-2. |

### 2.D UNTOUCHED — CLASS-3 historical record (explicit boundary; do NOT scrub)

Per `fail-loud-delete-old-source` (live source is separated from historical
record; the record is NOT scrubbed):

- **`maintenance-docs/**`** (79 files: `IMPLEMENTATION-REPORT-BD-107.md`,
  `PACK-REVIEW-BD-107.md`, the audit docs, etc.) — the audit trail. UNTOUCHED.
  (BD-210 may later prune superseded maintenance-docs on its OWN authority; that
  is not this fix's job.)
- **`backlog/BD-107.md`** (Status: Resolved — verified) — the origin governance
  entry + the BD-076/204/222/224/251 in-body references. UNTOUCHED.
- **`pack-ops/dashboard-approvals/dashboard.html`** — untracked render artifact
  (regenerated by `scripts/dashboard-render.py`); NOT a source surface. UNTOUCHED.

### 2.E Verified NO-EDIT (research surfaces that need no change)

- **`scripts/ci-test-wiring-allowlist.txt`** — the 3 promote tests are NOT
  allowlist ENTRIES; they appear only in the L22-43 comment narration. The sole
  parsed entry is `tracker-bd204-lossless-roundtrip-test.sh` (stays). Check 42
  validates parsed entries (comments skipped). NO functional edit. *(Optional:
  trim the stale L22-43 measurement narration; not required, not CI-fatal.)*
- **`scripts/tests/test-validate-pack-check-89.sh`** — the `/pack-td` /
  `/pack-tracker` non-regression is asserted with a SYNTHETIC `pack-testonly`
  fixture (case C5, L264-269), never the real `pack-td.sh`. NO edit.
- **`pack-ops/HELP-FRAGMENT-PACK.md`** — no live `pack td` refs (BD-224 removed
  them). NO edit.
- **Check 89 logic** (`help_fragments.py::check_help_fragment_command_skill_parity`)
  — matches `/pack-*` slash spans, not `scripts/…` spans; deleting `pack-td.sh`
  cannot regress it (§3 EEB-5). NO functional edit (E7 is a cosmetic comment).

---

## 3. CI-interlock plan (ci-guard-measure-then-bound) — the battery MUST stay green

For EACH of the six named interlocks: the CURRENT matching state (measured),
the reconciling edit, and the projected post-fix state. Every state-claim
carries its command + captured output + HEAD/date + conclusion.

### EEB-1 — the backing does NOT ship (grounds the whole delete-vs-mirage call)

- **Commands (HEAD `0d427f9`, 2026-07-23):**
  - `find project-template -name pack-td.sh -o -name tracker-promote.sh` → *(empty)*.
  - `grep -n "_SANCTIONED_PACK_SIDE_SHIPPED" scripts/lib/validate_checks/boundary_refs.py` →
    `_SANCTIONED_PACK_SIDE_SHIPPED = ( "scripts/lib/detect.sh", "scripts/pack-help.sh", )` (L593-596).
  - `grep -n "METHODOLOGY.md" scripts/init-project.sh` → S6 copies
    `$PACK/supporting-docs/METHODOLOGY.md → $TARGET/docs/pack/METHODOLOGY.md` (L680-683).
- **Interpretation:** neither `pack-td.sh` nor `tracker-promote.sh` is under
  `project-template/`, neither is a sanctioned pack-side shipped lib, so neither
  is copied at install. The `.docs-gate-allowlist.txt` reasons "present after
  install" (E8) are FALSE. METHODOLOGY.md IS shipped, so E11 is a client-facing
  edit.
- **Conclusion: SUPPORTED.** The backing is unshipped; delete removes a mirage,
  not a live client capability.

### EEB-2 — no runtime invoker (grounds "dead in practice")

- **Commands:** `ls scripts/pack scripts/pack.sh bin/pack` → all `No such file`.
  `grep -rn "pack-td.sh" scripts/pack-help.sh scripts/lib/detect.sh` → *(empty)*.
- **Interpretation:** there is NO unified `pack` dispatcher that routes `pack td`
  to `pack-td.sh`; `pack-help.sh` only prints help. `pack-td.sh` is invoked only
  by D3-D5.
- **Conclusion: SUPPORTED.** Deletion breaks no runtime path.

### EEB-3 — the deletion set is self-contained

- **Commands:**
  - `grep -rln "tracker-promote\|tracker_promote_" scripts/tests/` minus the 3
    promote tests → *(empty)*.
  - `grep -rln "source.*tracker-promote\|tracker-promote.sh" scripts/lib/` →
    `tracker-edit.sh`, `tracker-promote.sh` (self). Reading `tracker-edit.sh`
    L35/L491: both hits are COMMENTS ("the `provider_update` call shape this
    reuses"), NOT a `source`/call.
  - `grep -l "pack-td.sh" scripts/tests/test-tracker-promote-*.sh` → all three.
- **Interpretation:** only D3-D5 use `tracker-promote.sh`; only the comment E5
  mentions it elsewhere; the 3 tests source D1. No live cross-dependency escapes
  D1-D6.
- **Conclusion: SUPPORTED.**

### EEB-4 — Check 60 (CI shard coverage)

- **What it does now** (`singletons.py::check_ci_shard_coverage` L1436 →
  `ci-shard-plan.py --assert-coverage`): the wired KEEP set is DISK-derived
  (`parse_wired_tests()` globs `scripts/test*.sh + scripts/tests/*.sh +
  scripts/tests/fixture-dependent/*.sh` minus the allowlist; L117-124).
  `cmd_assert_coverage` (L320-378) asserts `union(shards) == keep_set`,
  pairwise-disjoint, fixture-cohesion. Weights (`load_weights` L175-202) feed
  ONLY the LPT balance via `_weight_for = weights.get(path, DEFAULT_WEIGHT_S)`
  (L205-207). `ci-shard-weights.tsv` L89-91 currently weight the 3 promote tests.
- **After the fix:** deleting D3-D5 removes them from the disk glob → they leave
  `keep_set`; shards are recomputed from `keep_set`, so `union==keep_set` holds.
  The 3 weight rows, if left, are never `.get`-looked-up → **no failure** — but
  E1 deletes them for hygiene. **Measurement (no independent weights check):**
  `grep -rn "ci-shard-weights" scripts/lib/validate_checks/*.py scripts/validate-pack.py`
  → only `WEIGHTS_PATH` in `ci-shard-plan.py`; NO check asserts weight-row
  liveness.
- **Reconciling edit:** E1 (delete L89-91). **Projected state:** `--assert-coverage`
  GREEN (union==keep_set over the shrunk disk set). CORRECTION to research:
  leaving the rows is NOT Check-60-fatal.
- **Conclusion: reconciled GREEN.**

### EEB-5 — Check 89 + `help_fragments.py` pack-td exclusion

- **What it does now** (`help_fragments.py::check_help_fragment_command_skill_parity`
  L370): git-`ls-files` parity of `/pack-*` slash-command rows in
  `HELP-FRAGMENT-PACK.md` ↔ backing `pack-*` skills. The L333 comment notes the
  closing-backtick anchor EXCLUDES `scripts/pack-td.sh`-shape spans (a
  `scripts/…` path is not a `/pack-*` command). `test-validate-pack-check-89.sh`
  C5 (L264-269) proves this with a SYNTHETIC `` `scripts/pack-testonly.sh` ``
  span → 0 failures.
- **After the fix:** `pack-td.sh` is not advertised as `/pack-td` anywhere; the
  matcher never keyed on the real file; the test uses `pack-testonly`. Deleting
  `pack-td.sh` changes NOTHING functional here.
- **Reconciling edit:** none required. E7 (update the L333 illustrative example
  off the deleted file) is COSMETIC.
- **Conclusion: GREEN unchanged.**

### EEB-6 — Check 23 + the client docs-gate (L3 allowlist liveness)

- **Check 23** (`help_fragments.py::check_help_fragment_completeness` L284):
  iterates `scripts/` on DISK; every `.sh`/`.py` executable must be listed in
  `HELP-FRAGMENT-PACK.md` OR carry `# pack-internal: true`. `pack-td.sh` passes
  today ONLY via `# pack-internal: true` (L2). **After delete:** it is no longer
  in `iterdir()` → not scanned → Check 23 passes trivially (one fewer
  `flagged_internal`). Reconciling edit: none beyond D1. **GREEN.**
- **Client docs-gate — the real interlock is L3 liveness, NOT the dangling gate.**
  `test-validate-docs-template-fullscan.sh` L124-231 runs the L3 leg against the
  REAL `project-template/` corpus + the REAL allowlist. L204-210 (quoted):
  ```python
  target = r.get("target")
  if target:
      n_target += 1
      norm = target.lstrip("./")
      if not any(norm in txt for txt in corpus_text.values()):
          dead.append("dead target: %r — no corpus doc references it" % target)
  ```
  `sys.exit(1 if dead else 0)`. The corpus is `docs/pack/*.md` (incl. PM-CHAT.md)
  + the METHODOLOGY/INSTALL overlays, EXCLUDING HELP-FRAGMENT.md.
- **Measurement:** `grep -rn "scripts/pack-td.sh\|scripts/lib/tracker-promote.sh"
  project-template/ supporting-docs/METHODOLOGY.md` → the ONLY corpus doc refs
  are **PM-CHAT.md L856-857** (`scripts/lib/tracker-promote.sh`, `scripts/pack-td.sh`);
  the other two hits are the allowlist rows themselves (the allowlist file is NOT
  in the corpus).
- **After the fix:** E10 removes PM-CHAT.md L854-861 → the corpus no longer
  contains either path string → the two `target:` rows become **dead targets** →
  L3 FAILS *unless* E8 deletes them in the SAME commit. **Coupling B is
  CI-fatal.**
- **Reconciling edit:** E8 + E10 together. **Projected state:** L3 GREEN
  (2 fewer records; the removed refs were their only backing).
- **Conclusion: reconciled GREEN — E8 and E10 are inseparable.**

### EEB-7 — pack-help-test.sh 2.2 (the direct interaction with recent work)

- **What it does now** (L167-190): copies the REAL `HELP-FRAGMENT.md` into a
  fixture, renders `pack-help.sh --surface client`, and asserts (L185-187)
  `== *"pack td promote"* && == *"pack td resolve"*` → `t_pass "2.2 client pack
  td rows present"`. Sibling 2.1 (L159-161) asserts the rows ABSENT on the pack
  surface. The header L4-8 narrates "ABSENT on the PACK surface … PRESENT on the
  CLIENT surface." This test is WIRED (`scripts/tests/*.sh` → disk KEEP set → a
  shard → runs in CI). `97277d6` (this session) reconciled 2.2 to the PRESENT
  form.
- **After the fix:** E9 removes the rows from HELP-FRAGMENT.md → the PRESENT
  assertion FAILS.
- **Reconciling edit:** E2 — FLIP 2.2 to the ABSENT form and correct the L4-8 +
  inline comments (now "absent on BOTH surfaces"). **Cross-surface Coupling A**
  (pack test ↔ project fragment) → same commit.
- **Conclusion: reconciled GREEN — E2 and E9 are inseparable and cross-surface.**

### Interlock summary

| Interlock | Now | Edit | After |
|---|---|---|---|
| Check 60 shard coverage | 3 disk tests + 3 weight rows in `keep_set` | D3-D5 + E1 | GREEN (disk-derived; orphan-row-tolerant) |
| Check 89 `/pack-*` parity | synthetic-fixture non-regression | none (E7 cosmetic) | GREEN unchanged |
| Check 23 exec↔fragment | `pack-td.sh` passes via `# pack-internal` | D1 | GREEN (drops out) |
| Check 42 wiring allowlist | 3 tests are comment-only, not entries | none | GREEN unchanged |
| Client docs-gate L3 liveness | 2 `target:` rows backed by PM-CHAT L856-857 | **E8+E10 (lockstep)** | GREEN (refs+rows gone together) |
| pack-help-test 2.2 | asserts client rows PRESENT | **E2+E9 (lockstep, cross-surface)** | GREEN (asserts ABSENT) |

---

## 4. Open items — context + options + evidence/logic recommendation (open-item-surfacing)

### OI-1 — Delete-now vs re-home (the pivotal value call) — RECOMMEND: DELETE now; a future clean verb ships fresh under BD-257

**Context.** `pack td` is a coherent, tested, DEAD-in-practice, client-advertised
project workflow whose backing never ships (EEB-1/2/3). The four prior passes'
individually-correct insight — "TD→phase promotion is a CLIENT workflow" — is
true and is exactly why the fix direction is non-obvious: if the workflow belongs
client-side, either the backing must SHIP client-side, or the advertising must be
REMOVED. The current cell is the worst one: advertised where it cannot run.

**Options with evidence:**
- **(A) DELETE now (eradicate) — RECOMMENDED.** Evidence: it is dead machinery
  (no invoker, no client copy, only its own tests exercise it — EEB-1/2/3);
  `fail-loud-delete-old-source` favors deleting unshipped dead code over keeping
  a mirage; smallest surface; removes the CI-interlock burden; and it satisfies
  the user's explicit goal ("there is no such thing as a pack TD"). Critically,
  DELETE does NOT lose the *methodology* — the three-outcome TD-resolution model
  survives in the client docs (OI-2 Option X) as the manual PM-Chat workflow the
  docs already describe (PM-CHAT.md L811-814 has PM Chat writing the phase entry
  directly; the verb was only ever an optional JSON/patch emitter).
- **(B) Re-home the backing to `project-template/scripts/` (revive as a shipped
  client verb).** Evidence AGAINST doing it in THIS fix: `tracker-promote.sh`
  sits atop the dormant/deferred tracker-lib family (provider/labels/links/
  phase-task — BD-214 deferred indefinitely), so re-homing pulls a deferred
  dependency subtree client-side OR requires severing it; and it revives a
  feature that has NEVER executed for any client. Re-home is a *build-a-feature*
  decision, not a *fix-a-violation* decision.

**Recommendation (logic + evidence):** **DELETE now.** The eradication removes
the dead pack-backed verb + its false advertising; the client TD-resolution
METHODOLOGY is preserved (OI-2 X). If — later — the user wants an EXECUTABLE
client TD-promotion verb, it is authored **fresh under BD-257** as a proper
project-side deliverable (lives in `project-template/scripts/`, project/`pm-*`
naming, in the install map, shipped + installed, its own tests) — NOT a
resurrection of `pack td` and NOT a pack-backed verb. **"Eradicate" and "a future
clean project-side verb" are compatible; the former does not preclude the
latter.** This is the user's value call; the evidence points to DELETE-now
because nothing is lost that a clean BD-257 verb could not re-establish better.

### OI-2 — The PM-CHAT.md / METHODOLOGY.md edit grain — RECOMMEND: Option X (strip verb, keep methodology)

**Context.** E10/E11 must (mandatorily) delete the dead-verb blocks (PM-CHAT.md
`### Verb shape` + `### Implementation reference`; METHODOLOGY.md L1630). The
remaining three-outcome decision model (direct close / Path 1 / Path 2) is
verb-INDEPENDENT client methodology.

**Options:**
- **(X) Strip the `pack td …` verb tokens, KEEP the methodology** as the manual
  PM-Chat workflow (the docs already describe PM Chat editing
  `docs/project/implementation-plan/phase-N.md` directly — PM-CHAT.md L812).
- **(Y) Delete the whole `## TD resolution orchestration` section** (and the
  METHODOLOGY resolution-path block), handing all TD-resolution guidance to
  BD-257.

**Recommendation:** **Option X.** Evidence/logic: (1) TD entries and TD→phase
promotion ARE legitimate client concepts (four audits + the user-locked frame
"TD entries are CLIENT-ONLY"); the user's "no such thing as a pack TD" targets
the pack-backed VERB, not the client's TD-resolution methodology. (2) The
methodology stands COMPLETE on manual PM-Chat editing (verb was optional). (3)
Deleting valid, executable client guidance over-reaches the eradication and would
leave a gap until BD-257. **Caveat / hand-off to BD-257:** if the user prefers to
consolidate ALL client TD-resolution guidance under BD-257's clean-surface
design, Option Y is clean too — the choice is which BD owns the surviving
methodology prose. Either way E8/E9/E10-mandatory/E11-mandatory are identical;
only the fate of the methodology PROSE differs. Recommend X, flag the choice.

### OI-3 — Scope of the dormant tracker family — RECOMMEND: scope OUT (BLOCKED test)

**Context.** `pack-tracker.sh` + `tracker-migrate.sh` + ~18 `scripts/lib/tracker-*.sh`
share `pack td`'s root cause (project-concept CLI machinery homed pack-side by
the `pack-<noun>.sh` convention) but are dormant/deferred (BD-214 Resolved;
README L220/L222 "dormant, deferred per BD-214 — verbs refuse") and advertised on
NO client surface (`grep "pack tracker" project-template/docs/pack/` → 0).

**Options:** (a) scope OUT — fix only `pack td` (the live-advertised acute
instance), edit only the dormant family's dangling COMMENT refs (E5/E6); (b)
scope IN — treat the whole pack-side tracker home as one cleanup.

**Recommendation:** **scope OUT.** This is NOT a deferral of unblocked work — it
passes the `deferral-is-scope-creep` BLOCKED test with concrete evidence: the
tracker family exposes NO unbacked client capability (advertised nowhere, verbs
refuse), so it fails the acute-violation test that makes `pack td` urgent; and it
is genuinely BLOCKED on the deferred tracker-redesign group (BD-185 `Deferred`;
no OPEN tracker-redesign BD at HEAD `0d427f9`). Bundling ~18 libs + a dispatcher
would balloon the blast radius for zero live-safety gain. The design NOTES the
shared root cause and flags the family for the tracker-redesign group; it edits
only E5/E6 (dangling comment refs the DELETE creates).

### OI-4 — The false `.docs-gate-allowlist.txt` rows — RECOMMEND: delete in lockstep (already E8)

**Context.** The two rows encode a FALSE "present after install" claim
(EEB-1) and are the interlock that MASKED the dangling reference. They are not a
neutral bystander.

**Options:** (a) DELETE (E8) — the only correct action once E10 removes the refs
(else L3 liveness fails, EEB-6). (b) leave — impossible: dead targets fail L3.

**Recommendation:** DELETE (E8), lockstep with E10. Evidence: the sibling
`scripts/pack-help.sh` row (L501-502) is TRUE (it ships at S11), which is exactly
why the false `pack-td.sh` row went unnoticed — it was pattern-copied from a true
row. This is the `declare-verify-backing` failure the fix corrects.

---

## 5. Cross-BD coordination (cross-bd-collision-scan) — Empirical-Evidence Block

**Method (keyed scan, not free-text):** intersected THIS fix's structured surface
set — `project-template/docs/pack/{HELP-FRAGMENT.md,PM-CHAT.md}`,
`project-template/scripts/.docs-gate-allowlist.txt`, `supporting-docs/METHODOLOGY.md`,
`scripts/pack-td.sh`, `scripts/lib/tracker-promote.sh`, `scripts/tests/…`, the CI
wiring (`ci-shard-weights.tsv`, `pack-help-test.sh`), `README.md`,
`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` — against every OPEN BD (`grep -l
"Status: Open" backlog/BD-*.md`). Command: `head -8 backlog/BD-{257,136,214,205,210}.md`
read at HEAD `0d427f9`, 2026-07-23.

| Open BD | Structured collision | Signal | Sequencing |
|---|---|---|---|
| **BD-257** (Open) — "client (project-side) slash commands + execution foundation" | **DIRECT** — owns `project-template/skills/` + `project-template/scripts/` + client `docs/pack/`; E9/E10 co-edit `HELP-FRAGMENT.md` + `PM-CHAT.md`. | **COORDINATE / SEQUENCE (strongest).** | Eradication lands **BEFORE** BD-257 design (clean precursor — user intent). Evidence: BD-257 blockers say "Build against the settled client surface." Eradicating the dead verb + false advertising FIRST hands BD-257 a clean surface and lets it DELIBERATELY decide whether to author a fresh project-side TD-promotion verb (the OI-1 (B) home) — instead of inheriting the violation the way BD-224 did on the pack side. |
| **BD-136** (Open) — "trinity marker-section preservation" | Minimal — its scope is `[CONDITIONAL]` H2 markers on the trinity (`customization-preserve.sh` 12-class inventory), NOT the `docs/pack/` `## TD resolution orchestration` H2. `docs/pack/` is pack-controlled ("Pack version updates only"), not client-customized. | NOTE. | If BD-136 is concurrently editing `PM-CHAT.md`, serialize the same-file commits (rule 10). No marker-grammar interaction — E10 removes a normal H2, not a marker section. |
| **BD-214** (Resolved) — "tracker-deferral cleanup" | Root-cause sibling; established the dormant-tracker decision. | ALIGN. | OI-3 scope-out aligns with BD-214; E5/E6 touch only its dormant family's dangling comments. |
| **BD-205** (Open) — "v11.0 final readiness audit (last gate)" | Sequencing — a boundary fix this significant should land before the whole-tree audit. | COORDINATE (ordering). | Land the eradication in the closeout order BEFORE BD-205 (ruled order 189→224→**257**→136→236→210→205→093; insert the eradication BD-272 immediately, before BD-257). |
| **BD-210** (Open) — "pre-launch maintenance-docs cleanup" | Light/orthogonal — CLASS-3 (§2.D) is UNTOUCHED here; BD-210 may separately prune superseded `IMPLEMENTATION-REPORT-BD-107.md` etc. on its own authority. | NOTE (no gate). | Independent; do not pre-empt BD-210's history pruning. |

**Non-empty intersection = COORDINATE signal, not a gate.** The load-bearing
collision is **BD-257**. Recommendation: **sequence the eradication (BD-272)
immediately, as the clean PRECURSOR to BD-257**, exactly as the user intends. No
tracker-redesign BD is OPEN (BD-185 `Deferred`), so OI-3's scope-out strands no
active work. **Conclusion: SUPPORTED — sequence BD-272 → BD-257.**

---

## 6. Verification battery + commit shape

### 6.1 Commit shape — ONE cross-surface commit, neutral framing (no scope keyword)

**Why one commit, not a pack/project split.** Coupling A (E2 pack-help-test.sh 2.2
↔ E9 HELP-FRAGMENT.md rows) spans BOTH surfaces and MUST land atomically — a
split leaves one commit red (2.2 asserts PRESENT while the rows are gone, or vice
versa). Coupling B (E8 ↔ E10) must also land atomically (dead-target L3 failure).
Because Coupling A is inherently cross-surface, no clean pack-only/project-only
split keeps the battery green at every boundary. → **one commit.**

**Scope keyword (CLAUDE.md scope-keyword convention / CI Check 36):**
- `pack-only` — DENIED: the commit touches `project-template/` (E8/E9/E10) and
  `supporting-docs/` (E11).
- `project-only` — DENIED: the commit touches `scripts/`, `README.md`,
  `pack-ops/…`, `ci-shard-weights.tsv`, `pack-help-test.sh`.
- → **NO scope keyword.** Use neutral framing so Check 36 is skipped (no false
  scope claim). Suggested subject: `feat: v11 — BD-272 eradicate pack td cross-boundary
  violation (dead pack-backed verb; cross-surface)`.

**pack-chat-only routing.** `README.md` (E3) is pack-chat-only. Scope it INTO the
coder prompt (the sanctioned path per CLAUDE.md "Pack Chat scoping a pack-chat-only
file INTO a coder prompt is the supported path"), so the whole eradication is one
coder patch + Pack-Chat apply/commit. Everything else (E1/E2/E4/E5/E6/E7/E8/E9/E10/E11
+ D1-D6) is coder-owned.

**One coder wave (no rule-10 parallelism).** The couplings force a single atomic
commit, so the work is one coder + the bounded review/fix cycle. No parallel
worktree waves apply (same-commit serialization).

### 6.2 The exact battery to run (verify-full-ci-suite)

Run the FULL wired battery — not `validate-pack` alone — in the coder's worktree
before the IMPL-REPORT, and again by the reviewer:

1. **`python3 scripts/validate-pack.py`** (both validate jobs) **AND**
   **`PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py`** — covers Check 23,
   Check 42, Check 47 (sanctioned-set equality — untouched, must stay green),
   Check 60, Check 89.
2. **Check 60 shard-plan re-derivation** — because 3 wired tests are deleted the
   shard PLAN changes: run `python3 scripts/lib/ci-shard-plan.py --assert-coverage`
   (must print `union == wired_KEEP_set`) AND the `--emit-matrix` path the CI
   `plan` job runs (confirm the matrix no longer lists the 3 tests).
3. **The full SHARDED suite** as CI runs it (every wired `scripts/test*.sh +
   scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh` minus the wiring
   allowlist), specifically:
   - `bash scripts/tests/pack-help-test.sh` → 2.1 (pack ABSENT) + flipped 2.2
     (client ABSENT) BOTH pass.
   - `bash scripts/tests/test-validate-docs-template-fullscan.sh` → **L3
     allowlist liveness** passes (0 dead targets).
   - `bash scripts/tests/test-validate-pack-check-89.sh` → C5 non-regression
     still passes (unchanged).
   - Confirm the 3 deleted `test-tracker-promote-*.sh` are simply absent (no
     runner references them — `.github/` has none).
4. **Client docs-gate on the template tree** — `bash project-template/scripts/validate-docs.sh`
   (scan mode) against `project-template/` → no dangling ref from the removed
   PM-CHAT.md paths; no unused-record failure.
5. **Grep-to-zero** the live surface (VERIFICATION gate): `git grep -iE
   "pack[ -]td|pack_td|tracker[-_]promote" -- ':!maintenance-docs/*' ':!backlog/*'`
   returns ONLY the intended survivors (the dormant tracker family E5/E6 comment
   sites if reworded to drop the token, and CLASS-3 excluded). Target: zero LIVE
   `pack td` advertising/backing.

### 6.3 Rollback

Every edit is a delete or a bounded text edit; the commit is atomic. Rollback =
do not apply the patch (RW agent produces the patch only after a clean review;
Pack Chat applies + commits with user approval). A FAILED battery keeps the
worktree as the recovery fallback (never torn down on failure).

---

## 7. Design-discipline challenge (design-discipline-challenge) — pack-boundary HIGH bar

Each preliminary triage decision is challenged on the tiered bar (pack-boundary
= HIGH).

- **DELETE vs re-home (OI-1) — HIGH bar, CHALLENGED.** Re-home is the property-fit
  temptation ("TD promotion belongs client-side, so ship it"). Challenged and
  REJECTED for this fix on evidence: the workflow has NEVER executed for a client
  (EEB-1/2), and `tracker-promote.sh` is entangled with the BD-214-deferred
  tracker family, so re-home imports deferred machinery. The property that
  actually fits is *delete-dead-code + author-fresh-if-wanted* — DELETE is
  intentional, evidence-based, and goal-aligned (the user's eradication goal),
  not a pattern-match. Re-home is preserved as an EXPLICIT future option under
  BD-257, not silently foreclosed.
- **Scope-out the dormant tracker family (OI-3) — HIGH bar, CHALLENGED.** The
  temptation is "same root cause → fix it all now." Challenged and REJECTED on
  the BLOCKED test with file evidence (advertised nowhere; verbs refuse per
  BD-214; BD-185 deferred; no open redesign BD). Scoping it in would be
  unbounded blast radius with no live-safety gain — the opposite of
  goal-aligned. Scope-out is the disciplined call, not convenience.
- **Keep the client TD methodology (OI-2 X) — HIGH bar, CHALLENGED.** The
  temptation is "delete everything `td`." Challenged: the eradication target is
  the pack-backed VERB, not the client's TD-resolution METHODOLOGY (a distinct,
  user-affirmed client concept). Keeping the methodology (reworded to manual) is
  boundary-correct; deleting it would over-reach and strand BD-257. Surfaced as
  the user's choice with a recommendation.
- **CLASS-3 untouched — HIGH bar, CHALLENGED.** The temptation is "scrub the
  BD-107 history so the tree reads clean." Challenged and REJECTED per
  `fail-loud-delete-old-source`: history is the audit trail; scrubbing it is a
  defect. BD-210 owns history pruning on its own authority.

---

## 8. What the planner/coder produces

1. **Planner:** confirm the atomic-commit shape (the two couplings), the OI-2
   grain decision (after the user rules X vs Y), and the battery order (§6.2).
   No parallel map (single commit).
2. **Coder (one wave, isolated worktree):** apply D1-D6 (deletes) + E1-E11
   (edits; E10/E11 per the ruled OI-2 grain; E3 README scoped-in as pack-chat-only;
   E7 optional-cosmetic). Run the full §6.2 battery. Emit the IMPL-REPORT
   (Section-2 preflight verbatim). NO patch on return; NO commit.
3. **Reviewer (RO):** re-run the full battery; verify grep-to-zero of live
   `pack td`; verify CLASS-3 untouched; verify the two couplings landed
   atomically. Then the sanctioned post-clean patch step.

---

## 9. Rules-Applied Verification Block

**agents-never-commit.** Evidence: I ran only read-only verbs (`git rev-parse`,
`git grep`, `git log`, `git ls-files`, `ls`, `grep`, `sed`, `wc`, `cat >>` to the
OUTPUT report only) plus `graphify query`; the SOLE file written is this design
doc under `…/packtd-eradication-arch-20260723/`. No `git add/commit/checkout/…`.
HEAD unchanged at `0d427f9`. **Conclusion: COMPLIANT.**

**memory-not-an-ssot.** Evidence: every claim cites a live file+line read at HEAD
`0d427f9` and re-verifies the research — e.g. `_SANCTIONED_PACK_SIDE_SHIPPED`
(`boundary_refs.py` L593-596), Check 60 (`singletons.py` L1436 + `ci-shard-plan.py`
L320-378), L3 liveness (`test-validate-docs-template-fullscan.sh` L204-210 quoted),
pack-help-test 2.2 (L185-187), docs-gate rows (`.docs-gate-allowlist.txt`
L504-508), PM-CHAT paths (L856-857). Two research claims were CORRECTED against
measurement (Check-60 orphan-row tolerance; the L3-liveness mechanism). No claim
rests on memory. **Conclusion: COMPLIANT.**

**empirical-evidence-blocks.** Evidence: §3 EEB-1…EEB-7 and §5 each carry the
command run, captured output, HEAD/date, interpretation, and a SUPPORTED/GREEN
conclusion for every state-claim (what deletes, what breaks, each check
before/after). **Conclusion: COMPLIANT.**

**ci-guard-measure-then-bound.** Evidence: §3 measures each affected check's
CURRENT matching logic (disk-derived wired set; `.get(default)` weights; L3
substring liveness; Check-23 `iterdir`), designs the reconciling edit, and
projects the post-fix GREEN state. Guards were confirmed to draw candidates from
disk/`git ls-files` (Check 89 uses `git ls-files`; Check 23/60 glob disk). No
allowlist was declared without measuring the tree. **Conclusion: COMPLIANT.**

**enumerate-encoding-surfaces.** Evidence: §2 enumerates EVERY surface encoding
`pack td` state — source (D1-D6), the 6 CI checks + their tests, the shard plan
(E1), client docs (E9/E10/E11), the false allowlist rows (E8), README (E3), the
methodology example (E4), the comment refs (E5/E6/E7) — and requires lock-step
removal; the delete-test-keep-weight-row asymmetry is explicitly called out (E1)
and the two atomic couplings are pinned. **Conclusion: COMPLIANT.**

**fail-loud-delete-old-source.** Evidence: §2.A DELETES the dead source (no
archive); §2.D separates and PRESERVES the historical record (maintenance-docs/ +
backlog/BD-107.md), stated as an explicit boundary; §7 challenges and rejects
history-scrubbing. **Conclusion: COMPLIANT.**

**dependency-direction-placement / pack-side-project-concepts-deliverable-only /
pack-project-separation-of-concerns.** Evidence: §0/§4 frame the fix by these — a
future clean client verb ships project-side (`project-template/scripts/`, in the
install map), never pack-backed; the violation is defined as the pack-side home +
client advertising + never-ships shape; the dormant tracker family (also
mis-homed) is scoped by the same axis (OI-3). **Conclusion: COMPLIANT.**

**cross-bd-collision-scan.** Evidence: §5 is a keyed EEB intersecting the fix's
structured surface set against every OPEN BD (BD-257 DIRECT, BD-136/205/210 NOTE,
BD-214 ALIGN), with the command + HEAD/date, and a sequencing recommendation
(BD-272 → BD-257). Keyed on structured paths, not free-text. **Conclusion:
COMPLIANT.**

**design-discipline-challenge.** Evidence: §7 challenges each triage
(delete-vs-rehome, tracker-family scope-out, methodology-keep, CLASS-3-untouched)
on the pack-boundary HIGH bar with property-fit reasoning, not pattern-matching.
**Conclusion: COMPLIANT.**

**operating-docs-no-history-no-bloat.** Evidence: E3/E4/E9/E10/E11 edits carry
only current-behavior text (delete the dead-verb rows/examples; no
"was removed by BD-272" narration in the operating docs); history lives in the
BD-272 entry + changelog, not the docs. **Conclusion: COMPLIANT.**

**graph-first-context.** Evidence: §1 attests graph-FIRST discovery
(`graphify affected` → `query`, G2 fallback used) then grep/Read verification of
exact bytes; the injected absolute `--graph` path + `--backend claude-cli` +
`--budget 1500/1200` were used. **Conclusion: COMPLIANT.**

**open-item-surfacing.** Evidence: §4 OI-1…OI-4 each carry context, the agent's
own options, and an evidence/logic recommendation; none is deferred to a
new/other BD (OI-3's scope-out is defended on the BLOCKED test with file
evidence, not a defer). **Conclusion: COMPLIANT.**

**rules-applied-verification-block.** Evidence: this section — each in-force rule
named as in MEMORY.md with quoted/pathed evidence + a terminal COMPLIANT
conclusion; no AMBIGUOUS state. **Conclusion: COMPLIANT.**

---

*End of ARCHITECTURE-BD-272.md (handoff name: `ARCHITECTURE-PACKTD-ERADICATION.md`). Design only; the user rules OI-1
(delete-now, recommended) and OI-2 (grain X, recommended); a planner/coder
executes; an adversarial + reconciliation pass precedes landing.*
