# ADVERSARIAL-REVIEW-BD-239 — fresh independent pack-architect review of DESIGN-BD-239

**Role:** pack-architect (RO), FRESH independent ADVERSARY. Did NOT author DESIGN-BD-239; am NOT its researcher. **BD:** BD-239 (PROJECT-SIDE large-PHASE pipeline standard, LARGE — runs the full pipeline). **Mandate:** challenge the design hard; re-measure every load-bearing claim independently. **Output:** this review only (sole Write, under `/tmp`). **Next stage:** PM-chat triage → reconciliation (if NEEDS-REWORK) → user design review → planner.

---

## 0. Runtime regime (RO; verified)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381` |
| branch | `v11-dev` |
| `git status --short` | clean (the concurrent BD-238 C1 coder runs in its OWN isolated worktree; my canonical tree shows no uncommitted change) |
| graph | DISCOVERY queried (`graphify query … --graph /Users/…/graphify-out/graph.json --backend claude-cli --budget 1500`); returned only maintenance-doc review nodes (operating-doc rule bodies are not node-indexed at rule granularity) → grep/Read for VERIFICATION (G2 fallback, sanctioned). |
| memory | NO memory store read/written (user MEMORY PROHIBITION 2026-06-23 honored). |
| writes | EXACTLY ONE: this review. No source edits. Read-only git only. |

---

## 1. Verdict + severity summary

The design is **strong, evidence-dense, and substantially correct on its load-bearing claims** — I independently re-measured the 700-char cap (688, fits), project-vocabulary purity (clean), the grep-zeros (groupings=0, rationale-tags=0), the trinity structure (flat, no `###`), and the BD-245 facts. The pipeline shape, the size-tiering, the roster-leverage divergences, and the parity-drop call are sound. But the adversarial pass surfaces **two MAJOR gate-attribution errors** that would mislead the planner into encoding the wrong PREFLIGHT gates, **one MAJOR under-scoping of the BD-239↔BD-245 file overlap**, plus several MINOR/NIT items.

| Severity | Count | Items |
|---|---|---|
| BLOCKER | 0 | — |
| MAJOR | 3 | M1 (Check-64/70 gate mis-attribution for the METHODOLOGY cite), M2 (BD-239↔BD-245 share METHODOLOGY.md **and** PM-CHAT.md — a real file overlap the §3.C wrinkle treats only at the trinity-heading level), M3 (DEFERRED-axis rationale for the groupings OMIT is factually wrong — the gate does not block a bare "groupings" mention) |
| MINOR | 4 | m1 (688-char margin is thin + arrow-heavy; code-point vs byte gap), m2 ("9-stage vs 8-stage" richer-deliverable framing is constructed), m3 (the elective skill-pointer manifest question is now answerable NO — design left it open), m4 (Check 70 listed as a METHODOLOGY-edit gate but it only fires if `validate-docs.sh` is edited, which §6.5 forbids) |
| NIT | 2 | n1 (P3's "OR a docs-researcher census is REQUIRED" is partly circular with the consequence), n2 (no explicit statement of WHO classifies a phase large/small at runtime vs the architect) |

**VERDICT: NEEDS-REWORK (3 major)** — none are purpose-defeating; all three are correctable by a reconciler with a few re-measurements and a tightened §9/§3.C. The design's CORE (pipeline + tiering + placement + parity-drop + project-vocabulary purity) survives the adversarial pass intact.

---

## 2. The wrinkle-C read (explicit, as mandated)

**My independent architectural read: the design's RECOMMENDED order (BD-245 first) is correct, BUT the design UNDER-STATES the coupling — and that changes the strength of the recommendation from "clean either way" to "BD-245-first is materially preferable."**

The design (§3.C) frames the interaction as a **one-token heading delta** (`## Project memory` vs `## Project rules`) confined to the trinity. That is incomplete. BD-245 (re-measured, EB-A5) renames the heading AND updates references in **`supporting-docs/METHODOLOGY.md` (~L145, ~L1611, ~L1615 "§ Project memory")** and **`project-template/docs/pack/PM-CHAT.md` (~L35)** AND the shipped `validate-docs.sh` literal — all in lock-step. BD-239 ALSO edits **METHODOLOGY.md** (the primary SSOT body, §6.1) and **PM-CHAT.md** (the anchor, §6.2). So BD-239 and BD-245 have a **real two-file overlap (METHODOLOGY.md + PM-CHAT.md)**, not merely a shared trinity heading.

Consequences:
- **If BD-245 runs first** (RECOMMENDED): BD-239 authors its METHODOLOGY section + PM-CHAT anchor + trinity bullet against the FINAL `## Project rules` name and the FINAL gate literal. Single clean pass. **Strongly preferred** — and more strongly than the design argues, because BD-239's METHODOLOGY/PM-CHAT edits would otherwise become moving targets for BD-245's reference sweep.
- **If BD-239 runs first** (FALLBACK): BD-239 lands a new METHODOLOGY section + a new PM-CHAT anchor + a new trinity bullet ALL under/around the `## Project memory` name. BD-245's rename census must then sweep not just the heading but BD-239's NEW METHODOLOGY/PM-CHAT cross-references too. The design's fallback hand-off note ("BD-245's rename census MUST include the BD-239 rule") is correct but SCOPED TOO NARROWLY — it says "rule," but the hand-off must name **all three BD-239 surfaces (trinity bullet, METHODOLOGY section heading-refs, PM-CHAT anchor)** that BD-245 will have to re-sweep.

Both orders remain SAFE (each gate stays green at each landing if the heading-name and the gate-literal agree at commit time — which they do within either single ordering). But the design's "one-token delta, clean either way" framing should be corrected to "BD-245-first is materially preferable because the two BDs share METHODOLOGY.md + PM-CHAT.md, not just the trinity heading; the fallback hand-off note must enumerate all three BD-239 surfaces." This is **M2** below. The sequencing decision remains the user's; my read tilts it more firmly toward BD-245-first than the design does.

---

## 3. MAJOR findings

### M1 — Gate mis-attribution: the METHODOLOGY cite is gated by the validate-docs DANGLING axis (with an EXISTING allowlist record), NOT Check 64/70

**Quoted (design §9.1, lines 302-304):**
> "The METHODOLOGY pointer in the trinity rule + the PM-CHAT anchor cite `docs/pack/METHODOLOGY.md` (the INSTALLED path). **Check 64 requires a cite to resolve** to `project-template/<basename>` or be a valid install target; **Check 70 enforces shipped-doc-gate structural parity** … the coder confirms the cite shape passes Check 64 + the validate-docs DANGLING axis"

**Quoted (design §9 row 1, line 291):** lists "Check 64/70 (cite-resolution + doc-gate parity)" as a gate on the METHODOLOGY edit.

**Independent re-measurement (EB-A1, EB-A2):**
- **Check 64 is scoped to MCP/config `.example` references ONLY**, not general doc-to-doc cites. Its failure message: *"dangling MCP/config .example reference … the cited deliverable template `project-template/{basename}` does NOT exist"* (`scripts/validate-pack.py` L7140-7155). A `docs/pack/METHODOLOGY.md` cross-reference in a trinity rule is NOT an MCP/config `.example` ref — Check 64 never evaluates it.
- **Check 70 polices the STRUCTURAL integrity of `project-template/scripts/validate-docs.sh` itself** (presence/executable/the 4 AXIS markers) — `_CHECK_70_CLIENT_GATE = "project-template/scripts/validate-docs.sh"` (L9026). It fires only if BD-239 edits `validate-docs.sh` — which §6.5 explicitly forbids. So Check 70 is IRRELEVANT to BD-239's actual edit-set.
- **The REAL gate** for a qualified-path file reference is the validate-docs **DANGLING axis** (`DANGLING_BACKTICK` regex matching a `/`-containing path with a known extension, `validate-docs.sh` L222-225). I confirmed `docs/pack/METHODOLOGY.md` matches the DANGLING regex. AND — critically — there is **already a `target: docs/pack/METHODOLOGY.md` allowlist record** (`project-template/scripts/.docs-gate-allowlist.txt` L390), which is why PM-CHAT's existing 4 cites of `docs/pack/METHODOLOGY.md` pass today (EB-A2).

**Why this is MAJOR (not MINOR):** the design instructs the planner to encode a "cite-resolution PREFLIGHT check" (§9.1, §12.2 PREFLIGHT-4) against **Check 64 + Check 70**. A coder running that PREFLIGHT would test the WRONG gates: Check 64 will trivially pass (it never looks at the cite) and Check 70 will trivially pass (the gate file is untouched) — giving a FALSE sense of coverage while the ACTUAL gate (DANGLING axis + the allowlist record) goes unverified. If a future wording used a qualified path NOT covered by the L390 record (e.g. a typo'd path), the mis-targeted PREFLIGHT would not catch it.

**Concrete fix:** retarget §9.1 + §9 row 1 + PREFLIGHT-4 to the validate-docs **DANGLING axis**: "the PM-CHAT anchor's `docs/pack/METHODOLOGY.md` cite is covered by the existing `target: docs/pack/METHODOLOGY.md` allowlist record (`.docs-gate-allowlist.txt` L390); the coder confirms the cite is byte-identical to the allowlisted form and runs `validate-docs.sh` DANGLING axis to 0 fails." Drop Check 64 and Check 70 from BD-239's gate list entirely (Check 70 fires only on a `validate-docs.sh` edit, which is out of scope; Check 64 is MCP/config-only).

**Bonus correctness the design MISSED (strengthens the design):** the TRINITY rule itself says "live in **METHODOLOGY**" — a **bare word, no `/`** (design §7.2 line 234). I confirmed a bare "METHODOLOGY" does NOT match the DANGLING regex at all (EB-A1). So the trinity bullet's METHODOLOGY pointer is gate-safe by construction and needs NO allowlist record. Only the PM-CHAT anchor (if it uses the qualified path) touches DANGLING — and that's already covered. The design's gate analysis is more pessimistic than reality on the trinity side and mis-named on the PM-CHAT side.

### M2 — BD-239↔BD-245 share METHODOLOGY.md AND PM-CHAT.md (a real file overlap), not just the trinity heading

**Quoted (design §3.C, line 89):**
> "the rule TEXT and placement are name-agnostic — a **one-token heading change is the only delta** between the two orders."

**Quoted (design §12.1, line 375):** "the rule text is name-agnostic (one-token delta)."

**Independent re-measurement (EB-A5):** BD-245's File/Symbol section (re-read at HEAD `e8ba9e7`) lists, for the rename lock-step, NOT just the trinity heading ×3 but explicitly:
> "PLUS every reference, in lock-step: `project-template/docs/pack/PM-CHAT.md` (~L35 …), `supporting-docs/METHODOLOGY.md` (~L145, ~L1611, ~L1615 "§ Project memory"), and the SHIPPED client gate … `validate-docs.sh`"

BD-239 edits METHODOLOGY.md (§6.1) and PM-CHAT.md (§6.2). **Therefore BD-239 and BD-245 touch the SAME two non-trinity files.** The interaction is NOT confined to a one-token heading change — if BD-239 lands first, BD-245's rename sweep must re-process BD-239's NEW content in METHODOLOGY.md and PM-CHAT.md (a moving target); if BD-245 lands first, BD-239 must author against the renamed references already present in those two files.

**Why MAJOR:** the design's §3.C fallback hand-off note (line 87) says "BD-245's rename census MUST include the BD-239 **rule**" — naming only the trinity bullet. It omits that BD-245 must also re-sweep BD-239's METHODOLOGY section heading-references and PM-CHAT anchor. A planner reading the design would scope the cross-BD hand-off to the trinity bullet alone and miss the two-file overlap, risking an incomplete BD-245 lock-step sweep (exactly the "moving target" risk the design itself warns of, but under-specified).

**Concrete fix:** revise §3.C + §12.1 to (a) drop "one-token delta is the only delta" — it is not; (b) state that BD-239 and BD-245 share METHODOLOGY.md + PM-CHAT.md; (c) in the FALLBACK branch, expand the hand-off note to enumerate **all BD-239 surfaces that reference the section name**: the trinity bullet, any METHODOLOGY section heading-reference, and the PM-CHAT anchor — so BD-245's `enumerate-encoding-surfaces` census re-measures the section AFTER BD-239 lands across all three. This makes the wrinkle-C recommendation (BD-245-first) MORE strongly preferred, consistent with §2 above.

### M3 — The DEFERRED-axis rationale for OMITting groupings is factually wrong

**Quoted (design §3.B, line 70):**
> "a forward-reference risks tripping the DEFERRED axis (validate-docs DEFERRED axis blocks 'future version'/'not yet'/'roadmap'/'slated' — EB-8) … **a forward-reference risks tripping the DEFERRED axis** and adds a dangling concept"

**Quoted (design §12.1, line 376):** "RECOMMENDED OMIT entirely (gate-safe; …). The user may direct a forward-reference, **but it risks the DEFERRED axis.**"

**Independent re-measurement (EB-A3):** the DEFERRED_PATTERN (`validate-docs.sh` L202-207) is:
```
\bdeferred\b|future (release|version)|\bnot yet (created|implemented|built|shipped)\b|once .{0,40}\b(land|ship)s?\b|\broadmap\b|coming soon|\bslated\b
```
The word "**groupings**" is NOT in this set. A bare, non-dependent mention of "groupings" (e.g. "the size unit is the phase; groupings organize phases") would NOT trip the DEFERRED axis. The axis fires only on deferral *phrasing* (deferred / future release|version / not yet X / roadmap / coming soon / slated / once X lands). The design's claim that "a forward-reference risks tripping the DEFERRED axis" is wrong as stated: it is the DEFERRAL LANGUAGE that trips the axis, not the concept name.

**Why MAJOR (not NIT):** the OMIT recommendation is presented to the USER (§12.1 decision 2) with a stated gate-rationale that is false. The user might reasonably conclude "I can't name groupings or I'll break the client gate" — which is incorrect. The CORRECT rationale for OMIT is the OTHER one the design also gives ("adds a dangling concept" / groupings is grep-zero project-side / BD-189 owns it) — that rationale is sound. But the gate-fear rationale must be struck, because it gives the user a false constraint.

**Concrete fix:** in §3.B + §12.1, strike "risks tripping the DEFERRED axis." Replace with the accurate rationale: OMIT because (a) groupings is grep-zero under `project-template/` (EB-2, confirmed), (b) BD-189 (after BD-206) owns the concept and BD-239 is ahead of it, so a forward-reference would be a dangling concept with no project-side definition — and IF named with deferral phrasing ("groupings, coming in a future version") it WOULD then trip DEFERRED. The decision (OMIT) is correct; only the gate-mechanics rationale needs fixing.

---

## 4. MINOR findings

### m1 — The 688-char Option A bullet is correct but thin-margin and arrow-heavy; flag the code-point-vs-byte gap

**Quoted (design §7.2):** "Option A (RECOMMENDED — a single tight pointer bullet, ≤700 chars, no allowlist needed)".

**Independent re-measurement (EB-A4):** I replicated the gate's EXACT collapse (`text = " ".join(x.strip() for x in cur)`, then `len(text)`) on the verbatim Option A bullet. Result: **688 code points** ≤ 700 → PASSES, **12 chars of margin**. The gate reads with `encoding="utf-8"` and measures `len()` on the decoded `str` = CODE POINTS, not bytes (confirmed `validate-docs.sh` L329). The same text is **708 BYTES** in UTF-8 (9 `→` + 1 `≥` are multi-byte). So the design's "≤700-char" claim is TRUE under the gate's actual measure, but anyone measuring bytes (e.g. `wc -c`) would see 708 and wrongly conclude a failure.

**Why MINOR:** the claim is correct and the design already mandates a coder PREFLIGHT re-measure (PREFLIGHT-2). But (a) 12-char margin is fragile — any wording tweak risks crossing 700; (b) the PREFLIGHT spec should explicitly say "measure code points via the gate's `len()` collapse, NOT bytes (`wc -c` over-counts the 9 arrows + 1 ≥ by ~20)." Recommend the design note the margin and the code-point measure explicitly, and lean toward Option B (two bullets) if the final wording adds any detail, since A has almost no headroom.

### m2 — The "9-stage BD-239 vs 8-stage BD-238" richer-deliverable framing is constructed

**Quoted (design §5, line 158):** "a 9-stage pipeline with an optional audit capstone and skill-named adversarial passes vs BD-238's 8-stage chain."

**Independent re-measurement:** the BD-238 RECONCILED rule body (§4.1, the canonical chain) contains **12 `→` arrows** (EB-A6) — i.e. its chain has more than 8 nodes if you count the user gates + reconciliation steps inline. The "8 vs 9" stage count is an artifact of how each design buckets sub-steps (BD-239 numbers 9 explicit stages incl. the optional audit; BD-238's reconciled doc never numbers its stages 1-8). The substantive divergences (D1-D5) are real and well-justified; the "8 vs 9, richer deliverable" headline is a presentational flourish, not a measured fact.

**Why MINOR:** harmless to the deliverable, but it is a state-claim ("BD-238's 8-stage chain") without an empirical block, and it slightly over-sells the divergence. Recommend softening to "BD-239 adds an optional audit capstone (stage 9) and skill-named adversarial passes that BD-238's chain did not name" — which is accurate and needs no stage-count comparison.

### m3 — The elective skill-pointer manifest question is now definitively answerable: NO

**Quoted (design §9 row 8 + line 300):** "if the row-6 skills are fixture inputs … editing them changes a fixture input → … `manifest-sync.sh` regenerates … The planner verifies whether `skills/*/SKILL.md` is a fixture input before deciding row 6."

**Independent measurement (EB-A7):** `grep -c "architecture-review/SKILL.md\|planning/SKILL.md" test-fixtures/manifest.txt` → **0**. The two skills are NOT manifest fixture inputs. So editing them does NOT change a manifest input; the manifest is a NOOP for row 6 regardless. The design left this as a plan-time TODO; it is answerable now.

**Why MINOR:** the design's conditional handling is safe (it would NOOP either way). But the open question is resolvable at design time and should be closed to spare the planner the lookup. Recommend stating: "confirmed `architecture-review/SKILL.md` and `planning/SKILL.md` are NOT in `test-fixtures/manifest.txt` (grep-0 at HEAD `e8ba9e7`); row 6, if taken, triggers NO manifest regeneration."

### m4 — Check 70 listed as a METHODOLOGY-edit gate, but it only fires on a `validate-docs.sh` edit

Covered under M1's Check-70 sub-point, repeated here for the gate-table audit: §9 row 1 lists "Check 64/70" as gating the METHODOLOGY edit. Check 70 polices `validate-docs.sh` structural parity (EB-A2); BD-239 does NOT edit `validate-docs.sh` (§6.5). Check 70 therefore never fires for BD-239. Remove it from row 1.

---

## 5. NIT findings

### n1 — P3's second clause is partly circular with the consequence

**Quoted (design §4.2 P3):** "Blast-radius … OR a docs-researcher blast-radius census is REQUIRED before design."

The signal "a census is REQUIRED before design" is itself a judgement that often co-determines whether the phase is large. Using "a required census" as a SIGNAL that helps decide LARGE/SMALL is mildly circular (you often know a census is needed BECAUSE the phase is large). BD-238's L3 has the identical clause, so this is inherited, not introduced. Recommend P3 lead with the objective half ("changes a contract/schema/interface that ≥3 surfaces depend on") and treat "census required" as a tie-break hint, not a co-equal yes/no test. NIT because it rarely changes the ≥2-signal outcome.

### n2 — No explicit statement of WHO classifies the phase at runtime

The design says (§4.1 stage 2) "The architect defines the large-vs-small-PHASE classification for THIS phase." But the SMALL tier's base flow may not spawn an architect at all (optional researcher → architect only if triggered). So for a borderline phase, WHO decides large/small BEFORE the architect is spawned? The existing project model puts up-front phase-gate decisions on the PM chat (Procedure 1, the planner-trigger check). The standard should state that the PM-chat applies the size criterion at the phase gate (the same place the planner-trigger check already runs), and the architect REFINES it if spawned. NIT because the criterion's yes/no tests are mechanical enough for the PM-chat to apply; just name the actor.

---

## 6. What I CONFIRMED accurate (the design's core survives)

Re-measured independently and SUPPORTED:
- **700-char cap value + matcher binding** (EB-A4): cap=700, `project_memory_bullets()` finds the section via `l.strip() == "## Project memory"`. The pack-1300/project-700 divergence is real and is the sharpest project-side difference, exactly as §7.1 claims.
- **Option A fits** (EB-A4): 688 code points ≤ 700 under the gate's exact measure.
- **Project-vocabulary purity** (EB-A8): the proposed shipped trinity bullet (§7.2) + the §6.1 METHODOLOGY content spec carry ZERO pack work-item tokens (no `BD-NNN`, no `backlog-item`, no `pack-*`, no `pack-ops`, no `[rationale:]`). The only BD-238/BD-245 mentions in the design are PLANNING CONTEXT in the design doc, not shipped text. **No leak. No BLOCKER.**
- **groupings grep-zero** under `project-template/` (EB-2 re-confirmed = 0).
- **No `[rationale:]` tags** in the project trinity Project-memory section (EB-A8 = 0); the no-rationale-bijection simplification (§7.3) is CORRECT — no project-side bijection/manifest surface exists, so none is needed.
- **Flat trinity structure** (EB-A8): 0 `###` sub-headings inside `## Project memory` — placement is a direct flat bullet, as §6.3 states.
- **METHODOLOGY source/install split** (EB-1 re-confirmed): source is `supporting-docs/METHODOLOGY.md`, installs to `docs/pack/METHODOLOGY.md`; design-against-the-source is correct.
- **P5 grounding** (EB-A3a): the existing planner-trigger condition #1 is "more than ~5 tasks, or … non-linear" (`METHODOLOGY.md` L317) — P5's reuse is faithful, not invented.
- **PM-CHAT execution half present** (EB-4 re-confirmed): 31 worktree mentions; the asymmetry-vs-BD-238 insight (§1) is real and is the design's best idea.
- **Parity-drop call** (measure-then-bound): re-applying the contract, I agree NO new project-side body-parity guard is warranted for BD-239 — the new bullet is short (688 chars, easy to keep ×3-identical), the residual body-drift risk is the SAME residual every existing trinity rule carries, and a correct body-parity check is a separate larger effort (normalize around GEMINI-intrinsic H2s, re-baseline every rule). DROP-not-defer is correct. The coder PREFLIGHT ×3-byte-identity attestation (§8.4) is the right sized-to-fit safeguard.
- **No new H2** (EB-A7): the proposed bullet adds 0 `##` lines; Check 18 H2-parity is auto-satisfied ×3.
- **The DROP-not-defer discipline** (§8.3): nothing is deferred to v11.1+; the guard is dropped, the wrinkles are resolved or surfaced. Compliant with no-deferral-without-user-direction.

---

## 7. Disposition for the reconciler

3 MAJOR are correctable by a fresh reconciler with these edits (no re-architecture needed):
1. **M1:** retarget §9.1 / §9 row 1 / PREFLIGHT-4 from Check 64/70 to the validate-docs DANGLING axis + the existing `target: docs/pack/METHODOLOGY.md` allowlist record (L390); note the trinity bare-word pointer is DANGLING-exempt.
2. **M2:** revise §3.C / §12.1 — drop "one-token delta is the only delta"; state the METHODOLOGY.md + PM-CHAT.md two-file overlap with BD-245; expand the fallback hand-off note to enumerate all BD-239 surfaces BD-245 must re-sweep; tilt the recommendation more firmly to BD-245-first.
3. **M3:** strike the DEFERRED-axis fear from the groupings OMIT rationale (§3.B / §12.1); keep the sound dangling-concept / BD-189-owns-it rationale.

MINOR/NIT (m1-m4, n1-n2) are cleanup the reconciler should fold in opportunistically but are not blocking.

The design's PURPOSE (codify a size-tiered project-side pipeline that ships in project vocabulary) is fully served; no purpose-defeating gap; no pack-concept leak (no BLOCKER). The verdict is NEEDS-REWORK only because the three MAJOR gate/coupling errors would mislead the planner's PREFLIGHT design and the cross-BD hand-off — they must be fixed before the planner consumes the doc.


---

## 8. Empirical-Evidence Blocks

All measured at HEAD `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, branch `v11-dev`, 2026-06-23, in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

**EB-A1 — Check 64 is MCP/config-`.example`-only; the trinity bare-word METHODOLOGY pointer is DANGLING-exempt; a qualified path matches DANGLING (M1).**
- Command: `sed -n '7140,7175p' scripts/validate-pack.py` ; Python replication of `DANGLING_BACKTICK` (`validate-docs.sh` L222-225) against `'live in METHODOLOGY.'` and `` 'see `docs/pack/METHODOLOGY.md`' ``.
- Output (verbatim): Check 64 failure text — *"dangling MCP/config .example reference `{token}`: the cited deliverable template `project-template/{basename}` does NOT exist"*; DANGLING replication — `'live in METHODOLOGY.' -> DANGLING match: False (none)` ; `` 'see `docs/pack/METHODOLOGY.md`' -> DANGLING match: True (docs/pack/METHODOLOGY.md) ``.
- Interpretation: Check 64 evaluates MCP/config `.example` cites, not doc-to-doc cross-references. The DANGLING axis requires a `/`-qualified path; the trinity bullet's bare "METHODOLOGY." is not matched; only a qualified `docs/pack/METHODOLOGY.md` cite (the PM-CHAT anchor) is.
- Conclusion: SUPPORTED — the design's Check-64 attribution for the METHODOLOGY cite is wrong; the real gate is the DANGLING axis, and only the PM-CHAT anchor (qualified path), not the trinity bullet (bare word), is exposed.

**EB-A2 — Check 70 polices `validate-docs.sh` structure (fires only on a gate edit); an existing allowlist record covers the qualified METHODOLOGY cite (M1, m4).**
- Command: `sed -n '9011,9030p' scripts/validate-pack.py` ; `grep -n "METHODOLOGY" project-template/scripts/.docs-gate-allowlist.txt` ; `grep -rn "docs/pack/METHODOLOGY.md" project-template/docs/pack/PM-CHAT.md`.
- Output (verbatim): `_CHECK_70_CLIENT_GATE = "project-template/scripts/validate-docs.sh"` with `_CHECK_70_AXIS_MARKERS = (# AXIS: history, # AXIS: deferred, # AXIS: bloat, # AXIS: dangling)`; allowlist L390 `target: docs/pack/METHODOLOGY.md`; PM-CHAT cites `docs/pack/METHODOLOGY.md` at L138, L150, L167, L894.
- Interpretation: Check 70 asserts the shipped gate's structural integrity; it fires only when `validate-docs.sh` is edited (BD-239 forbids that, §6.5). The qualified METHODOLOGY cite is already DANGLING-allowlisted (L390), which is why PM-CHAT's 4 existing cites pass.
- Conclusion: SUPPORTED — Check 70 is irrelevant to BD-239's edits; the PM-CHAT anchor cite is gate-safe via the existing DANGLING `target:` record, not Check 64/70.

**EB-A3 — the DEFERRED axis does NOT block a bare "groupings" mention (M3).**
- Command: `sed -n '202,207p' project-template/scripts/validate-docs.sh`.
- Output (verbatim): `DEFERRED_PATTERN = re.compile(r"\bdeferred\b|future (release|version)|\bnot yet (created|implemented|built|shipped)\b|once .{0,40}\b(land|ship)s?\b|\broadmap\b|coming soon|\bslated\b", re.IGNORECASE)`.
- Interpretation: the pattern matches deferral PHRASING (deferred / future release|version / not yet X / once X lands|ships / roadmap / coming soon / slated). The token "groupings" is absent from the alternation. A non-dependent mention of "groupings" without deferral language does not match.
- Conclusion: SUPPORTED — the design's "a groupings forward-reference risks tripping the DEFERRED axis" is factually wrong; OMIT is correct but on dangling-concept/BD-189-ownership grounds, not gate-fear.

**EB-A3a — P5 grounding: the existing planner-trigger threshold.**
- Command: `sed -n '311,320p' supporting-docs/METHODOLOGY.md`.
- Output (verbatim): `### Planner trigger rule … 1. The phase has more than ~5 tasks, or task dependencies within the phase are non-linear (one task must complete before another starts …)`.
- Interpretation: P5 ("more than ~5 tasks OR non-linear intra-phase deps") faithfully reuses planner-trigger condition #1.
- Conclusion: SUPPORTED — P5 (D3) is grounded in a real documented threshold, not invented.

**EB-A4 — the 700-char cap, matcher binding, and the Option A 688-code-point measure (m1).**
- Command: `grep -n "BLOAT_BULLET_CHAR_CAP" project-template/scripts/validate-docs.sh` ; `sed -n '253,287p' project-template/scripts/validate-docs.sh` (the `project_memory_bullets` collapse) ; `grep -n 'raw = open' project-template/scripts/validate-docs.sh` ; Python replication of the collapse `" ".join(x.strip() for x in lines)` + `len()` on the verbatim §7.2 Option A bullet, plus `.encode("utf-8")` length.
- Output (verbatim): `213:BLOAT_BULLET_CHAR_CAP = 700` ; `if l.strip() == "## Project memory": start = i` ; `text = " ".join(x.strip() for x in cur); yield cur_line, len(text), text[:60]` ; `329: raw = open(path, encoding="utf-8").read()` ; replication — `Collapsed char count (len): 688 … FITS <=700? True … Number of → arrows: 9 … Number of ≥ chars: 1 … UTF-8 byte length: 708`.
- Interpretation: the gate caps each `## Project memory` bullet at 700, found by the literal heading, measured as `len()` of the whitespace-collapsed text on a utf-8-decoded `str` = code points. Option A = 688 code points (PASS, 12 margin) but 708 bytes (a `wc -c` measure would falsely flag it).
- Conclusion: SUPPORTED — Option A fits under the gate's actual measure; the design's "≤700-char" claim is correct; the margin is thin and the code-point-vs-byte distinction must be in the PREFLIGHT.

**EB-A5 — BD-239 and BD-245 share METHODOLOGY.md AND PM-CHAT.md (M2).**
- Command: `grep -n "Project memory\|Project rules\|validate-docs\|METHODOLOGY\|PM-CHAT\|after BD-232\|Target:\|Large-BD" backlog/BD-245.md`.
- Output (verbatim, key): title — "rename `## Project memory` → `## Project rules`"; `Target: v11.0 — directly after BD-232`; File/Symbol — "PLUS every reference, in lock-step: `project-template/docs/pack/PM-CHAT.md` (~L35 …), `supporting-docs/METHODOLOGY.md` (~L145, ~L1611, ~L1615 "§ Project memory"), and the SHIPPED client gate … `validate-docs.sh`"; Type — "Large-BD standard: researcher → architect (+ adversarial) → planner (+ adversarial) → coder waves".
- Interpretation: BD-245's rename lock-step touches METHODOLOGY.md + PM-CHAT.md + validate-docs.sh, not only the trinity heading. BD-239 also edits METHODOLOGY.md (§6.1) + PM-CHAT.md (§6.2). The two BDs overlap on two non-trinity files. BD-245 is itself a LARGE full-pipeline BD.
- Conclusion: SUPPORTED — the §3.C "one-token delta is the only delta" framing under-states the coupling; the fallback hand-off note must enumerate all BD-239 surfaces, not just the trinity bullet.

**EB-A6 — BD-238 reconciled chain has 12 arrows (the "8-stage" claim is constructed) (m2).**
- Command: `sed -n '121,138p' /tmp/pack-handoff-bd238-arch/DESIGN-BD-238-RECONCILED.md | grep -o "→" | wc -l`.
- Output (verbatim): `12`.
- Interpretation: the BD-238 canonical rule chain has 12 `→` transitions; it is never numbered "8 stages" in its own doc. "8 vs 9 stage" is a presentational bucketing, not a measured fact.
- Conclusion: SUPPORTED — the §5 "richer 9-stage vs 8-stage" headline is a flourish; the substantive divergences (D1-D5) stand independently.

**EB-A7 — the two elective skills are NOT manifest inputs; the proposed bullet adds no H2 (m3).**
- Command: `grep -c "architecture-review/SKILL.md\|planning/SKILL.md" test-fixtures/manifest.txt` ; `sed -n '224,235p' /tmp/pack-handoff-bd239-arch/DESIGN-BD-239.md | grep -cE "^##"`.
- Output (verbatim): manifest grep → `0`; H2-in-bullet grep → `0`.
- Interpretation: `architecture-review/SKILL.md` + `planning/SKILL.md` are absent from `test-fixtures/manifest.txt` (row-6 edits trigger no manifest regen); the proposed bullet introduces no `##` heading (Check 18 auto-satisfied).
- Conclusion: SUPPORTED — the open manifest question (§9 row 8) resolves NO; the H2-parity claim (§7.4) holds.

**EB-A8 — project-vocabulary purity + no rationale tags + flat structure (the no-BLOCKER core).**
- Command: `sed -n '225,234p' DESIGN-BD-239.md | grep -niE "\bBD-?[0-9]|backlog-item|pack-[a-z]|pack memory|\[rationale"` (proposed shipped bullet) ; `grep -c "rationale:" project-template/CLAUDE.md` ; `awk '/^## Project memory/{f=1} f&&/^## /&&!/^## Project memory/{exit} f&&/^### /{print}' project-template/CLAUDE.md` ; `grep -rln "groupings" project-template/`.
- Output (verbatim): proposed bullet pack-token grep → "NO pack-concept tokens in proposed bullet"; `rationale:` count in project CLAUDE.md → `0`; `### ` sub-headings in the Project-memory section → (none printed); groupings under project-template/ → `0`.
- Interpretation: the shipped trinity bullet uses only project vocabulary (no BD/backlog-item/pack-*/pack-memory/[rationale]); the project trinity carries no `[rationale:]` tags (no bijection surface); the section is flat (no `###`); groupings is grep-zero.
- Conclusion: SUPPORTED — NO pack-concept leak (no BLOCKER); the no-rationale-bijection simplification is correct; flat-bullet placement is correct; OMIT-groupings rests on grep-zero.

---

## 9. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Ran only read-only verbs: `git rev-parse HEAD` → `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`, `git status --short` → empty, plus `grep`/`sed`/`Read`/`graphify query`/`python3` measurement. NO `add/commit/push/checkout/restore/stash/branch/tag/worktree/merge/rebase` or any state-changing verb. Sole Write = this review at `/tmp/pack-handoff-bd239-arch/ADVERSARIAL-REVIEW-BD-239.md`. No memory store read/written (MEMORY PROHIBITION honored). | COMPLIANT |
| 2 | **reconciliation-instance-independence / fresh-agent-default** | I am a FRESH independent adversary; I did NOT author DESIGN-BD-239 nor RESEARCH-BD-239. I re-measured every load-bearing claim FROM SOURCE (EB-A1…EB-A8) rather than deferring to the design's EBs — and overturned 3 of its gate/coupling claims (M1 Check-64/70; M2 file-overlap; M3 DEFERRED-axis) on independent evidence. | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §8 carries EB-A1…EB-A8: each finding (Check 64/70 scope; DEFERRED pattern; 700-cap + 688-measure; BD-245 file overlap; BD-238 arrow count; manifest/H2; vocabulary purity) backed by the actual command + verbatim output + HEAD `e8ba9e7` + interpretation + SUPPORTED conclusion. | COMPLIANT |
| 4 | **pack-side-project-concepts-deliverable-only** | EB-A8: grepped the design's PROPOSED SHIPPED text (the §7.2 trinity bullet + the §6.1 METHODOLOGY spec) for `BD-NNN`/`backlog-item`/`pack-*`/`pack memory`/`[rationale]` → ZERO hits. The only BD-238/BD-245 mentions in the design are planning context in the DESIGN doc, not shipped deliverable text. NO leak → no BLOCKER. | COMPLIANT |
| 5 | **ci-guard-design-measure-then-bound** | Independently re-applied the contract to the parity-drop (§6): MEASURED the existing project-side gates (validate-docs 4 axes confirmed PASS over 106 docs; Check 18/70 scopes read from source); CATEGORIZED the new bullet's only new risk (×3 body drift, recoverable, 688-char pointer); BOUNDED — a correct body-parity check is a separate larger effort; agreed DROP-not-defer. Also re-measured each gate the design names and corrected three mis-attributions (M1/m4) so the planner's PREFLIGHT targets the RIGHT gate (DANGLING axis), not a no-op gate. | COMPLIANT |
| 6 | **operating-docs-no-history-no-bloat** | Judged the trinity rule against the 700-char shipped cap (EB-A4: 688 ≤ 700, PASS) and the history/deferred axes (EB-A3: the proposed text carries no history/deferral phrasing); flagged the thin 12-char margin (m1) and corrected the false DEFERRED-axis rationale (M3). The rule is pointer-shaped/terse, chain in METHODOLOGY (uncapped) — compliant with the terse-no-history standard. | COMPLIANT |
| 7 | **deferral-is-scope-creep / no-deferral-without-user-direction** | Confirmed the design folds-in-or-drops: the parity guard is DROPPED (not deferred, no follow-up scheduled, §8.3); groupings is OMITted in-scope (not punted to a later BD by BD-239); nothing pushed to v11.1+. The wrinkle-C ordering is a USER SEQUENCING decision (two v11.0 lead-block BDs), correctly surfaced — NOT a deferral. My M2 sharpens the sequencing read without deferring anything. | COMPLIANT |
| 8 | **rules-applied-verification-block** | This table — rules 1-8, each name + quoted/measured evidence + terminal conclusion (no empty evidence, no AMBIGUOUS). | COMPLIANT |

---

*End of ADVERSARIAL-REVIEW-BD-239. Fresh independent adversary; one Write (this review) under /tmp; read-only git only; no memory store used. VERDICT: NEEDS-REWORK (3 major) — M1 (Check-64/70 gate mis-attribution → retarget to the DANGLING axis), M2 (BD-239↔BD-245 share METHODOLOGY.md + PM-CHAT.md, not just the trinity heading → expand the wrinkle-C hand-off, tilt to BD-245-first), M3 (the DEFERRED-axis rationale for OMITting groupings is factually wrong → keep OMIT on dangling-concept grounds). NO BLOCKER: project-vocabulary purity is clean (no pack-concept leak), the 700-char Option A bullet fits (688), the parity-drop is sound, the no-rationale-bijection simplification is correct. The design's core (pipeline + tiering + roster-leverage + placement) survives the adversarial pass; the 3 major are correctable gate/coupling errors that would mislead the planner's PREFLIGHT design and the cross-BD hand-off if left unfixed.*
