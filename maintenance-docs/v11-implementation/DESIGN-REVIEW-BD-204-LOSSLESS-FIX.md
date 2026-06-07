# DESIGN-REVIEW-BD-204-LOSSLESS-FIX — independent regression/completeness review

> **Agent:** pack-reviewer (independent, adversarial). **Mode:** REVIEW ONLY; one report write; codebase read-only.
> **HEAD:** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`). **Branch:** `v11-dev`. **Date:** 2026-06-07. **Scope:** PACK-ONLY.
> **Under review:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (the design), backed by `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md`.
> **Method:** re-measured every load-bearing claim against the actual code at HEAD `feaa45d`. The design doc and census were treated as untrusted.
>
> **Bottom line up front.** The design's *diagnosis* is correct and well-evidenced (the 9-field drop, the dead carrier, the green-CI cause). The census is accurate. BUT the *fix as specified* contains a **BLOCKER-class internal contradiction** in the carrier mechanism and a **BLOCKER-class false claim about the existing reverse emitter**, and its CI-guard "byte-for-byte" leg would **FALSE-FAIL on ~20 real entries** as currently specified. The approach (carry-the-fields) is the right property-fit choice, but the concrete §3.3/§4.2 mechanism is under-specified and partly wrong about the code it builds on. **Verdict: PROCEED-WITH-FIXES** (the architect must resolve the carrier-shape contradiction, the empty-field normalization problem, and the prose-block capture gap before a planner sequences it).

---

## §A — REGRESSIONS

### A-1 [BLOCKER] The design's claim that the reverse render loop "already exists and is correct" is FALSE; the existing emit normalizes/re-orders, so the §4.2 byte-faithful guard FALSE-FAILS on real entries.

The design (§3.3 step 5, §3.6 R4, R10) repeatedly asserts the existing `_tmr_emit_pack_tree` render loop "already exists and is correct (renders `extra_fields` pairs as `Label: value` lines)" and that the fix "only needs the render to place each field at its ORIGINAL position." I re-read the loop. It does NOT round-trip carried fields byte-faithfully even today:

- It emits a **fixed template order** (`**id — title**`, Type, Status, Scope, Severity, Blockers, Unblocks, File/Symbol, Description, Context, Resolution, then appended extras) — NOT per-entry order.
- It **always emits** `Blockers: None` and `Unblocks: None` even when the source entry had no such line.
- It injects `Resolved: n/a` when resolution is empty.
- It appends `extra_fields` pairs **at the END** — directly contradicting the design's own §3.3 EE which proves Target sits between Status and Blockers in BD-204.

> **Empirical-Evidence Block (existing emit is fixed-order + injects empty fields).**
> `CMD`: `sed -n '740,800p' scripts/lib/tracker-migrate-reverse.sh`
> `OUT` (the render loop): `lines = [f"**{pid} — {title}**", f"Type: {typ}", f"Status: {status}"]` … unconditional `lines.append("Blockers: " + (", ".join(bl) if bl else "None"))` and `lines.append("Unblocks: " + (...))` … `else: lines.append("Resolved: n/a")` … then `for label, value in pairs: lines.append(f"{label}: {value}")` (extras LAST).
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the emit is a fixed-template projection, not a verbatim reproducer. `CONCL`: SUPPORTED — the "already correct" claim is FALSE.

> **Empirical-Evidence Block (20 real entries lack Blockers/Unblocks lines → byte-faithful leg false-fails).**
> `CMD`: `for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -qE '^Blockers:' || basename "$f"; done | wc -l`
> `OUT`: `20` (same count for `Unblocks:`). e.g. `backlog/BD-001.md` body is `**BD-001 — …**` / `Type:` / `Status:` / `Resolved:` / `Description:` — no Blockers/Unblocks line.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: a forward→reverse round-trip of BD-001 produces a body that INJECTS `Blockers: None` + `Unblocks: None` lines the original lacks. The §4.2 step-3 "reconstructed body == original body byte-for-byte" assertion is FALSE for all 20 entries even after the carrier fix. `CONCL`: SUPPORTED.

Consequence: the design's strongest regression net (R4: "the §4 byte-faithful guard against all 211 entries") and the guard's strong leg (§4.2 step 3) **cannot both be true and green** without ALSO rewriting `_tmr_emit_pack_tree` to (a) preserve per-entry field order and (b) suppress fields absent in the source. The design explicitly says it does NOT touch the emit beyond "activating" it. This is a load-bearing contradiction: either the byte-faithful guard is weakened (label-set only, not byte-equality) OR the emit must be rewritten (a much larger change than §3 admits). The architect must pick one and re-scope.

### A-2 [MUST] `extra_fields` appended-at-end vs the order-faithful requirement is self-contradictory within §3.

§3.3 step 5 says "the inline-render loop already exists and is correct"; the very next paragraph (§3.3 "Order-faithful carrier") then says the carrier must "record the COMPLETE ordered field sequence … the carrier is the entry's body lines themselves, verbatim." These are two **incompatible** mechanisms: (1) an `extra_fields` list of `[label,value]` pairs rendered into a fixed-order template with extras appended; vs (2) a verbatim body-blob round-tripped between header and back-pointer. The design oscillates between them without choosing. See §B-1 for the deeper consequence.

### A-3 [SHOULD] Phase-epic call site — low risk, correctly identified, but the arg-count detail is slightly off.

The design (R2) says the phase call site "passes `"" ""`." The actual call (`:959`) is a 4-arg call (`phase_id`, a synthesized description, `""`, `""`) — it omits the 5th (`file_symbol`) entirely, relying on the `${5:-}` default. Adding a 6th `extra_fields_json` param MUST also default (`${6:-}`) or the phase call breaks. The design's intent (empty block, harmless) is right; the planner must ensure the new param is defaulted, not positional-required. Low risk, but call it out so the coder doesn't make the phase path mandatory-arg.

### A-4 [SHOULD] Existing forward-test body assertions use `assert_contains`, so an appended block does not regress them — confirmed, in the design's favor.

> **Empirical-Evidence Block.** `CMD`: `grep -n 'assert_contains.*## ' scripts/tests/tracker-migrate-forward-test.sh`. `OUT`: body section checks are `assert_contains` (substring), e.g. `2.5 body has Description section … "## Description"`. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: appending a `pack-fields` block after the H2 sections does not break substring assertions. `CONCL`: SUPPORTED — R2's "harmless append" holds for the unit tests.

---

## §B — NEW PROBLEMS the design introduces

### B-1 [BLOCKER] The prose blocks (BD-204's HARD CONSTRAINT / DESIGN BASELINE / DECISION TIERS / …) are NOT "Label: value" field lines and are NOT captured by the §3.3 carrier rule — and they are ALREADY being shredded into `unblocks` today.

The design's carrier rule (§3.3) is: "capture EVERY other `Label: value` line." But the parser's `FIELD_LINE = ^([A-Z][A-Za-z/ -]+):` does **not** admit parentheses or digits before the colon. BD-204's ~9 design blocks have headers like `HARD CONSTRAINT (user 2026-06-04):` and `DECISION TIERS (calibration …):` — these do NOT match FIELD_LINE. Today they are swallowed as **continuation lines of the preceding field** (`Unblocks:`) and then **comma-shredded** by `parse_id_list` into dozens of garbage list items.

> **Empirical-Evidence Block (BD-204 prose blocks land in `unblocks`, comma-shredded).**
> `CMD`: `source scripts/lib/tracker-migrate-forward.sh; tail -n +2 backlog/BD-204.md > t; printf '\n---\n' >> t; _tmf_parse_backlog_file t | jq '.[0].unblocks'`
> `OUT` (abridged): `unblocks` contains the 4 real unblocks PLUS `"HARD CONSTRAINT (user 2026-06-04): **pack-only — … If it affects the project side at all"`, `"that is a VIOLATION.** CI Check 36 …"`, `"DESIGN BASELINE (named inputs — ADAPT"`, `"do NOT discard …"`, … — the entire prose-block region is in the unblocks list, split on every comma.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: BD-204's design blocks are not parsed as fields at all; they are absorbed into `unblocks` and corrupted. A carrier that "captures every `Label: value` line into extra_fields" would NOT recover them (they are not field lines), and the round-trip would re-emit them as a mangled `Unblocks:` list. `CONCL`: SUPPORTED — the §3.3 carrier rule, as literally specified (per-field-line capture), does NOT cover the largest substance in the worst-case entry it is meant to save.

This is the crux. The design has two carrier descriptions; only the SECOND one (§3.3 "Order-faithful carrier" — carry the entry's flat body **verbatim** as a blob) can actually preserve BD-204's prose blocks, because the per-field-line model (steps 1–5, the `extra_fields` `[label,value]` list) cannot represent a continuation-shredded prose block. The design must commit to the verbatim-blob model and drop the `extra_fields`-list framing — and once it does, A-1/A-2 apply (the existing fixed-order emit cannot render a verbatim blob; it must be replaced). The "minimal change / activate the dead loop" story collapses.

### B-2 [MUST] Delimiter-collision / fence-corruption risk is unanalyzed.

The design proposes a `<!-- pack-fields … -->` HTML-comment block carrying entry content verbatim. Entry bodies contain `-->`? `<!--`? a markdown fence? The census and design never measure whether any entry's content contains the chosen delimiter. If an entry's verbatim body contains `-->`, the HTML comment terminates early and the reverse parse corrupts. `ci-guard-measure-then-bound` demands measuring this before bounding the delimiter. The architect must (a) measure the delimiter-collision set across 211 entries and (b) specify an escaping or fence-choice that no entry content can break. (Note: BD-204's body cites `<!-- per-entry source … -->`-style strings and markdown — collision is plausible, not hypothetical.)

### B-3 [MUST] Double-render / divergence risk: the H2 Description/Context/Resolution sections AND the verbatim block both carry the same fields.

The design keeps the H2 sections "for human GH rendering" AND adds a verbatim block carrying the full body (which includes Description/Context/Resolution). The same content is now serialized twice in the Issue body. On a tracker-side human edit (the Mode-3 SSOT is the Issue), the two copies diverge — which wins on reverse? The design says reverse fidelity "rests on the verbatim block," implying the H2 sections become decorative/ignored on reverse. But then a human editing the GH-rendered `## Description` (the visible, editable part) has their edit **silently dropped** on regen (reverse reads the hidden block, not the visible section). This is a real Mode-3 data-loss path the design does not address. At minimum the architect must state the precedence rule and the human-edit story (this interacts with BD-204's "full CRUD true-SSOT" HARD constraint).

### B-4 [SHOULD] Idempotency across on/off/on cycles is asserted but not demonstrated.

BD-204's HARD constraint requires correctness "under REPEATED on/off/on/off transitions." The design's guard (§4.2) runs ONE forward+reverse. With the fixed-order emit (A-1), the FIRST reverse already changes byte layout (injected None lines, reordered extras); a SECOND forward→reverse would then operate on the already-normalized form. The design must show the round-trip reaches a fixed point after one cycle (idempotent) OR the guard must assert `reverse(forward(reverse(forward(x)))) == reverse(forward(x))`. Not analyzed.

### B-5 [SHOULD] Interaction with the line-1 back-pointer and `_CANON_HEADER_RE` is asserted handled (via `pe_strip_backpointer_stdin`) but the verbatim-blob boundary is fuzzy.

The verbatim carrier is "the entry's body lines between the bold-header and the back-pointer." But the per-entry file's line 1 IS the back-pointer (above the header), and the forward parser reads from line 2. The design says the guard strips the back-pointer via `pe_strip_backpointer_stdin`. Confirmed that helper exists (`scripts/lib/per-entry/_lib.sh:337`). But the design must specify whether the carrier captures the bold-header line itself (the title is already in the Issue title) — double-encoding the title is another divergence vector. Spell out the exact captured span.

---

## §C — COMPLETENESS

### C-1 [BLOCKER] The 19 dropped classes are NOT uniformly "Label: value" lines; the prose blocks (a documented part of the drop set) are not covered by the stated rule.

Per B-1: the design's own §1.6/census enumerate "~9 uncarried multi-line prose blocks" as part of BD-204's loss. The single carrier rule as written (§3.3 steps 1–5, per-field-line capture) does NOT cover them. Only the verbatim-blob variant does, and that variant is incompatible with the "activate the existing emit" plan (A-1, A-2). So the "one rule covers all 19 classes + the 11 no-Description entries" completeness claim (§3.4, the answer to prompt-item C) is **NOT met by the mechanism as specified**. It is achievable, but only by the verbatim-blob model with a rewritten emit — which the design has not committed to.

### C-2 [MUST] Multi-line / blank-line-separated values: 53 entries have multi-paragraph Descriptions; the carrier must preserve internal blank lines.

> **Empirical-Evidence Block.** `CMD`: python scan counting entries whose `Description` value contains an internal blank line. `OUT`: `multi-paragraph Description entries: 53`. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: 53 entries carry blank lines inside a field value. The current parser folds these into a single field value with embedded `\n`; the current emit re-emits them as `Description: <value-with-embedded-newlines>` (a single logical line whose continuation lines are unindented). A verbatim-blob carrier preserves them; an `extra_fields` `[label,value]` model with the current "Label: value" emit re-flattens them. `CONCL`: SUPPORTED — multi-line value preservation is a real requirement the per-field-line model handles only by accident of the embedded-newline hack; the design must verify it.

### C-3 [SHOULD] Values containing `:` and markdown — handled by the parser's greedy `(.*)` capture, no completeness gap there.

`FIELD_LINE` captures `group(2)` as `.*`, so a value containing `:` (e.g. `Target: v11.0 (launch-gate item, user 2026-06-04).`) is captured whole. Confirmed via the BD-204 parse (Target captured intact). No gap. Recorded for the architect's reassurance.

### C-4 [SHOULD] Target/Position structured scalars — covered by the carrier IF the verbatim-blob model is adopted; lost under the per-field model only if they fail FIELD_LINE (they don't). They DO match FIELD_LINE.

> **Empirical-Evidence Block.** `CMD`: python `FIELD_LINE.match` over BD-204 lines. `OUT`: `Target`, `Position`, `Scope`, `Out of scope`, `Problem`, `References` all MATCH FIELD_LINE (captured). The only non-matching prose-block label is `DECISION TIERS (…)`. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: Target/Position are recoverable by the per-field rule; the prose blocks are not. `CONCL`: SUPPORTED — the structured scalars are the EASY case; the prose blocks (B-1/C-1) are the hard, uncovered case.

---

## §D — THE CI GUARD

### D-1 [MUST] Implementable in-process? Yes for the pure-function path, but the design under-specifies the harness and ignores that the existing emit is not a pure reproducer.

The drop happens in pure parse/compose/reconstruct/emit functions (no `gh`) — confirmed. A validate-pack check can shell out to the libs per entry, no network. Feasible. BUT the guard's **strong leg** (byte-for-byte body equality, §4.2 step 3) is NOT implementable green against the current emit (A-1: 20 entries get injected None lines; fixed-order; etc.). As specified the guard either:
- **FALSE-FAILS** on the 20 no-Blockers/Unblocks entries (byte-equality leg) — unless the emit is rewritten; OR
- is **weakened** to a label-SET assertion (expected-labels ⊆ reconstructed-labels), which would NOT catch order corruption, value corruption, or the prose-block shredding (B-1) — i.e. it would **FALSE-PASS** the very BD-204 prose-block loss it is meant to catch (the labels Type/Status/…/Position would all be present even if the prose-block content is mangled inside `unblocks`).

This is the guard's central design risk: the label-set leg is too weak (false-pass on B-1), the byte leg is unachievable without an emit rewrite (false-fail on A-1). The architect must reconcile: define a normalized canonical form for the equality (so the emit's legitimate normalizations don't false-fail) AND make it strong enough to catch content corruption.

### D-2 [SHOULD] "No drop-allowlist" is correctly held; measure-then-bound is honored at the MEASURE step.

§4.3 correctly refuses a drop-allowlist (it would re-admit the bug) and sizes the guard to "zero dropped fields." The MEASURE step (28 labels, all 211 entries) is done and independently confirmed. This part is sound.

### D-3 [BLOCKER] The guard's post-fix "runs clean" verification is asserted LOGICALLY, not empirically — and §A-1/§B-1 show it would NOT run clean as specified.

§4.3 says "I verified the post-fix projection logically … the coder confirms empirically at implementation." Per `ci-guard-measure-then-bound` step 5 ("verify post-design the guard runs clean against the projected post-fix state"), a logical-only verification is INCOMPLETE — and here it is also WRONG: against the actual emit, the post-fix tree does NOT diff clean (A-1 injected lines; B-1 prose blocks). The architect deferred the load-bearing empirical check to the coder, but the design's whole premise ("activate the existing correct emit") is the thing that fails that check. The post-design verification must be done at design time for a guard this central; doing it would have surfaced A-1/B-1.

### D-4 [MUST] The new per-check test MUST be wired into the workflow or Check 42 fails — the design's §4.5 names it but does not flag the wiring obligation.

> **Empirical-Evidence Block.** `CMD`: `sed -n '6486,6580p' scripts/validate-pack.py`. `OUT`: `check_ci_workflow_wires_per_check_tests` (Check 42) enumerates `scripts/tests/test-validate-pack-check*.sh` on disk and FAILs any file lacking a `bash scripts/tests/<file>` line in `.github/workflows/validate-pack.yml`; "This check intentionally has no exemption mechanism." `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the design's "a new per-check test" (§4.5) MUST be added to the workflow yml in the SAME commit, or Check 42 goes red. The design's §4.5 surface table omits `.github/workflows/validate-pack.yml`. `CONCL`: SUPPORTED — see G-1.

### D-5 [BLOCKER] The proposed check number "Check 48" is ALREADY TAKEN.

> **Empirical-Evidence Block.** `CMD`: `grep -nE 'Check 48' scripts/validate-pack.py`. `OUT`: `# ── Check 48 (BD-195 C6): JC-5 soft-advisory removed-doc guard ──` (`check_removed_doc_advisory`). Highest existing banner number = 48. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the new check is Check **49**, not 48. The design hedges ("48 is illustrative; coder reads the highest"), but §4.2 title, §4.5 table, and §5.b all hardcode "Check 48" — internally inconsistent and a copy-trap for the coder. `CONCL`: SUPPORTED. Severity is BLOCKER-for-the-doc-correctness (the design must not ship a wrong, taken number in three places); trivially fixed.

### D-6 [SHOULD] Runs in the unattended battery? The validate-pack check WOULD (it is a `check_*` call in `main()`); the C-7 oracle correctly stays manual-only.

> **Empirical-Evidence Block.** `CMD`: tail of `scripts/validate-pack.py` (`main()` body) + `ls .github/workflows/`. `OUT`: checks are plain calls in `main()` (e.g. `check_removed_doc_advisory()`); the single workflow `validate-pack.yml` runs `python3 scripts/validate-pack.py` + the per-check test battery. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: a new `check_*()` call lands in the unattended battery automatically; the C-7 oracle (default-SKIP, not `test-validate-pack-check*` named) stays out. `CONCL`: SUPPORTED — the guard runs unattended; the two-tier (Check 49 unattended + C-7 manual live) split is sound.

---

## §E — CONSTRAINT COMPLIANCE

| # | Constraint | Verdict | Evidence |
|---|---|---|---|
| 1 | NO carve-outs / per-legacy-field exceptions | **MET (in intent)** | §3.4: no field is named in carrier logic; no drop-allowlist (§4.3). The verbatim-blob model is genuinely field-agnostic. Caveat: the *mechanism* must actually be the blob model (B-1) for this to hold — the per-field model would force the prose-block special-casing the constraint forbids. |
| 2 | CI false-green concretely closed (a guard that catches THIS gap) | **PARTIALLY MET / AT RISK** | The label-set leg catches the simple Target/Position drop (§4.2 EE confirmed). But it FALSE-PASSES the prose-block shredding (B-1, D-1) and the byte leg is unachievable as specified (A-1, D-1, D-3). The guard needs the normalized-canonical-form redesign before it provably catches THIS gap in full. |
| 3 | If entries rewritten: per-entry zero-loss proof; design claims it rewrites NONE — verify | **MET** | §3.6 + R8: carry-fields, not rewrite. Confirmed no `backlog/BD-*.md` content edit is proposed (only `backlog/_rules.md` schema doc). The 211 entries are byte-untouched. The criterion-C proof is vacuous because zero entries change — correct. |
| 4 | BD-204 is a v11.0 launch gate (no deferral) | **MET** | §5.a/§5.b land C-4.5/4.6/4.7 in v11.0 before C-7/C-8; no deferral; the BD-212 alternative is surfaced as non-default, not recommended. Consistent with `no-deferral-without-user-direction`. |

Constraint 2 is the live risk; constraints 1/3/4 are met.

---

## §F — SEQUENCING

### F-1 [SHOULD] C-4.5 (carrier) before C-4.6 (guard) is correct; but per A-1/D-3 the guard cannot be green after C-4.5 unless the emit rewrite is folded into C-4.5.

The order (carrier → guard → schema-doc) is right in principle (guard green only after the fix). But the design's C-4.5 scope ("activate the existing emit") is insufficient to make the guard green (A-1). The architect must expand C-4.5 to include the emit rewrite (order-faithful + suppress-absent-fields) OR weaken the guard. Until that is resolved, C-4.6 lands red on top of C-4.5. The sequencing is sound; the per-commit greenness is not, given the under-scoped C-4.5.

### F-2 [PASS] The §3.5/R9 METHODOLOGY-vs-_rules.md boundary is handled correctly.

> **Empirical-Evidence Block.** `CMD`: `grep -n '_PROJECT_SIDE_PATH_PREFIXES' scripts/validate-pack.py` ; `ls backlog/_rules.md`. `OUT`: `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")` — so editing `supporting-docs/METHODOLOGY.md` is DENIED under a `pack-only` commit (Check 36). `backlog/_rules.md` is pack-ops (NOT under those prefixes) → pack-only-clean. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the design's R9 recommendation (reconcile via `backlog/_rules.md` only; leave METHODOLOGY as the common-field template) keeps C-4.7 `pack-only`-clean and avoids the commit-subject-keyword-token-trap. `CONCL`: SUPPORTED — R9 is correctly diagnosed and the safe path chosen. METHODOLOGY.md does ship to clients (validate-pack `:5391` "client-installed"), confirming the design's premise.

### F-3 [SHOULD] Parked C-7 rebuild + C-8 ordering holds, but C-7 rebuild touches a fixture the guard also depends on — sequence the fixture edits in one commit.

C-7's fixture rebuild (§5.c) and the C-4.5/4.6 fixture additions (§4.5) both touch `scripts/tests/fixtures/`. Ensure the C-7 fixture changes do not land before the carrier (a fixture asserting drop-set round-trip would fail until C-4.5). The design's "C-7 stays manual + default-SKIP" keeps it out of CI, so a pre-fix C-7 fixture is harmless to CI — but the planner should still land the C-7 rebuild after C-4.5 for coherence. Minor.

---

## §G — ENUMERATE-ENCODING-SURFACES (independent enumeration vs the design's §4.5)

The design's §4.5 table is good but has **omissions**. Independently enumerated surfaces that encode the guard's expected state:

| Surface | In §4.5? | Note |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` (parser, composer, call site `:901`) | YES | — |
| `scripts/lib/tracker-migrate-forward.sh` **phase call site `:959`** | **NO** | Must default the new 6th param or the phase path breaks (A-3). §4.5 names only `:901`. |
| `scripts/lib/tracker-migrate-reverse.sh` (reconstruct, emit `:758`) | YES | But the emit needs a REWRITE, not "activate" (A-1) — §4.5 understates the change. |
| `scripts/validate-pack.py` new check | YES | Number is 49 not 48 (D-5). |
| `.github/workflows/validate-pack.yml` | **NO — OMISSION** | Check 42 FAILS if the new per-check test is not wired here (D-4). Must be in the lock-step set. |
| `scripts/tests/tracker-migrate-forward-test.sh` | YES | — |
| `scripts/tests/tracker-migrate-reverse-test.sh` | YES | — |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` + `fixtures/roundtrip/bd-v11.0/BACKLOG.md` | YES | — |
| C-7 test + `fixtures/tracker-bd204-lossless/BACKLOG.md` | YES | — |
| new per-check test for Check 49 | YES | — |
| `test-fixtures/manifest.txt` | YES | regen (scripts/ touched) — `regenerate-manifest-v11-surface`. |
| `backlog/_rules.md` | YES | — |
| **`backlog/_rules.md` ↔ `changelog/_rules.md` parity / any validator pinning `_rules.md` field-list text** | **PARTIAL** | R7 asserts "no validator pins `_rules.md` field-list text"; the coder must grep-confirm at impl (Check 34 cross-reference-integrity + any `_rules.md`-content check). Surfaced, not proven in the design. |
| **project-side parallel `_rules.md` (3 under `project-template/docs/project/`)** | **NO (correctly excluded)** | These encode the SAME schema but are PROJECT-side (pack-only-denied). The design correctly does NOT touch them — but it should NOTE that the pack/project schema docs will diverge until BD-206/207, so a reviewer doesn't flag the asymmetry as a defect. `pack-project-separation` (separate artifacts) makes this correct, but the design is silent on it. |

**G-1 [MUST]:** `.github/workflows/validate-pack.yml` is a required lock-step surface (Check 42, D-4) and is missing from §4.5. **G-2 [SHOULD]:** the `:959` phase call site is missing. **G-3 [SHOULD]:** note the intentional pack/project `_rules.md` divergence so it is not later mis-flagged.

---

## §VERDICT

**PROCEED-WITH-FIXES.**

The diagnosis is correct, the census is accurate, the approach (field-faithful carry, no carve-outs, an unattended in-process faithfulness guard, no entry rewrite, land-in-v11.0) is the right property-fit — this is NOT pattern-reuse and the rewrite-entries alternative is correctly rejected. But the *concrete mechanism* must be corrected before a planner sequences it. The architect must resolve, in a revised design:

**BLOCKERS (must fix before planning):**
- **A-1 / D-1 / D-3:** The existing reverse emit is NOT a byte-faithful reproducer (fixed order; injects `Blockers/Unblocks: None` on 20 entries; `Resolved: n/a`; appends extras last). The design's "activate the already-correct emit" premise is false. Either (a) rewrite the emit to be order-faithful + suppress-absent-fields, and scope that into C-4.5; or (b) redefine the guard's equality against a normalized canonical form. State which, with an empirical post-fix green check (not logical-only).
- **B-1 / C-1:** The prose blocks (BD-204's HARD CONSTRAINT / DESIGN BASELINE / DECISION TIERS / … — the bulk of the worst-case loss) are NOT `Label: value` field lines, are not captured by the §3.3 per-field rule, and are *currently shredded into `unblocks`*. Only the verbatim-body-blob carrier preserves them. Commit to the blob model explicitly and drop the contradictory `extra_fields`-`[label,value]`-list framing (A-2).
- **D-5:** "Check 48" is taken (BD-195 C6). The new check is Check 49; fix all three hardcoded occurrences.

**MUSTs (resolve in the revision):**
- **B-2:** Measure the delimiter-collision set across 211 entries; specify an escape/fence no entry content can break (`ci-guard-measure-then-bound`).
- **B-3:** Define the H2-section-vs-verbatim-block precedence and the human-edit-on-tracker data-loss story (interacts with the full-CRUD true-SSOT HARD constraint).
- **C-2:** Verify the carrier preserves internal blank lines for the 53 multi-paragraph-Description entries.
- **D-4 / G-1:** Add `.github/workflows/validate-pack.yml` to the lock-step surface set (Check 42 has no exemption).

**SHOULDs:** A-3/G-2 (phase call-site default param), B-4 (idempotency proof), B-5 (captured-span boundary incl. header), G-3 (note intentional pack/project `_rules.md` divergence).

The constraint set is mostly met (1, 3, 4 MET; 2 AT-RISK pending the guard redesign). No project-surface leak is introduced (pack-only honored; R9 correctly steers the schema edit to `backlog/_rules.md`). Once the carrier mechanism is made internally consistent (verbatim-blob), the emit is correctly scoped, and the guard's equality is defined against a normalized form strong enough to catch B-1, this is implementable and would close the green-CI gap. Until then it would ship a guard that either false-fails 20 entries or false-passes the prose-block loss — i.e. it would NOT reliably catch the exact class of bug it exists to catch.

---

## §RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` issued; only `git rev-parse HEAD` (read-only) + Read/Bash read-only measurement; the sole write is this ONE report. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op; no live GH (C-7 oracle READ only, never executed — `PACK_TRACKER_LIVE_GH` unset, no `gh repo create`); no file overwrite outside the report. | COMPLIANT |
| `empirical-evidence-blocks` | Every load-bearing finding (A-1, B-1, C-2, C-4, D-4, D-5, F-2) carries CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL. | COMPLIANT |
| `enumerate-encoding-surfaces` | §G independently enumerated surfaces and compared to §4.5; flagged the workflow yml (G-1), the `:959` phase site (G-2), and the project-side `_rules.md` divergence (G-3) as omissions/notes. | COMPLIANT |
| `verify-full-ci-suite` | Assessed the guard against the full battery: enumerated `.github/workflows/validate-pack.yml` (the single workflow), confirmed `python3 validate-pack.py` + the per-check test list + Check 42 wiring obligation (D-4); confirmed the new `check_*` runs unattended via `main()` and the C-7 oracle stays out (D-6). | COMPLIANT |
| `pattern-matching-out-of-context` | Challenged whether the carrier is property-fit; confirmed carry-the-fields is property-fit (a migration IS a faithful transport) and the verbatim-blob generalizes the existing marker idiom — but flagged that the design's per-field `extra_fields` framing is a mis-fit for the prose blocks (B-1), so the property-fit holds only for the blob variant. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly A–G + verdict + this block + the attestation; named what is wrong, did not author a replacement design. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | Verified the R9 boundary against actual code: `_PROJECT_SIDE_PATH_PREFIXES` includes `supporting-docs/` (F-2 EE); confirmed METHODOLOGY.md is client-installed (`:5391`); confirmed `backlog/_rules.md` is pack-ops/pack-only-clean. | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence, no AMBIGUOUS. | COMPLIANT |

## §READ-IN-FULL attestation (this session, at HEAD `feaa45d`)

| Document | Read proof |
|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` | Read full (1-641). The design under review; every §1-§9 claim assessed. |
| `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md` | Read full (1-436). Spot-checked, not trusted: re-ran the 9-key whitelist, 28-label census, dead-carrier, BD-204 parse — all confirmed. |
| `scripts/lib/tracker-migrate-forward.sh` | Read directly — parser `_tmf_parse_backlog_file` (375-496), `parse_id_list`/`flush_field`, composer `tmf_compose_issue_body` (595-635), call sites `:901` + `:959`. RAN the real parser on BD-204. |
| `scripts/lib/tracker-migrate-reverse.sh` | Read directly — `tracker_migrate_reverse_reconstruct` (506-600, the 12-key `jq -n` object), `_tmr_emit_pack_tree` render loop incl. the dead `extra_fields` read (700-800). |
| `scripts/validate-pack.py` | Read directly — `main()` check-call list, `check_ci_workflow_wires_per_check_tests` (Check 42, 6486-6580), `_PROJECT_SIDE_PATH_PREFIXES`, Check 48 (`check_removed_doc_advisory`, taken), the full `def check_` list + highest banner number. |
| `.github/workflows/validate-pack.yml` | Read the test-wiring + run-step list (the single workflow; tracker/migrate/per-check invocations). |
| `.github/ISSUE_TEMPLATE/work-item.yml` | Read via census reconciliation + marker-trio reference (no Scope/Target field; markers pack-id/template_version/pack-version). |
| `backlog/_rules.md` | Read full (entry contract 43-55; the `Position:` optional-field line). |
| `supporting-docs/METHODOLOGY.md` Part 7 | Read directly (1190-1220) — the 8-field common template; confirmed no `Position:`. |
| `backlog/BD-204.md` / `BD-206.md` / `BD-207.md` | Read full — BD-204's prose-block structure (B-1), the POST-BD-204 REFRESH anchors, BD-207's sidecar/header-snapshot deletion scope. |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | Read the header + default-SKIP guard (1-50). |
| `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md` | Read — confirmed BD-901/902/903 carry only carry-set top-level fields; BD-903 sub-blocks inside Description. |
| `scripts/tests/tracker-migrate-forward-test.sh` / `-reverse-test.sh` | Read the body-section assertions (assert_contains) + reconstruct asserts. |
| Curated memory (`ci_guard_design_measure_then_bound`, `verify_full_ci_suite`, `pack_project_separation_of_concerns`, `commit_subject_keyword_token_trap`, `architect_planner_empirical_evidence`, `scope_deliverables_to_the_ask`, `agent_output_rules_applied_block`) + CLAUDE.md `## Pack memory` | Carried as governing rules; reflected in the Rules-Applied block. |

**No named document was derived rather than read.** Every code path was re-measured live (the BD-204 parse and the 20-entry / 53-entry / Check-48-taken counts are this session's own command output at HEAD `feaa45d`).

**End of DESIGN-REVIEW-BD-204-LOSSLESS-FIX.md**
