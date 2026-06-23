# DESIGN — BD-243 BLOAT METHOD (escalation resolution + method refinement under binding user constraints)

Architect: FRESH architect instance (pack-architect, RO). I did NOT author `DESIGN-BD-243-FINAL.md`, the `CENSUS-DEFERRED-FEATURE-MENTIONS.md`, or `PLAN-BD-243-BLOAT-PHASE.md`; conclusions are my own (reconciliation-instance-independence).
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`, canonical HEAD `2780ada` (verified at runtime — `git rev-parse HEAD` = `2780adaa295c0b62fb9d5148c16639c35039bd64`), 2026-06-22. READ-ONLY; no edits, no patch, no state-changing git.
Status: ARCHITECT-READY — goes to the user, then the planner re-plans the bloat phase (planner sequences; I define the method + scope).

This design resolves the TWO escalated questions from `PLAN-BD-243-BLOAT-PHASE.md` §8 (the ARCHITECT-NEEDED flags) under the user's two BINDING rulings, and refines the bloat-reduction METHOD (DESIGN §C) accordingly. It does NOT re-sequence the bloat commits (planner's job).

---

## 0. THE TWO BINDING USER RULINGS (verbatim — the constraints this design encodes)

**Ruling 1 (escalation 1 — skill scope):**
> "all skills. But remember, the meaning and functionality must not change. Only the amount of text. This means, guardrails, rules, in and out of scope concepts must not change. If examples or patterns are used, there must be a good reason they are there. Do they add specificity that can not be explained otherwise? Why or why not?"

**Ruling 2 (escalation 2 — OPTIONAL-FEATURES.md):**
> "OPTIONAL-FEATURES is a human readable doc and not a process doc (and if it is ever used as a process doc, explain to me why). It is an output doc for reference only. The content must be useful to a person and the reduction in text can not remove the clarity and meaning. Structures, code, JSON, and similar examples must not be modified. This doc should follow the rules too, but in a human readable way."

These are CONSTRAINTS, not options. I encode them; I do not relitigate.

---

## A. THE EXAMPLES/PATTERNS JUSTIFICATION TEST (escalation 1 — the core)

Ruling 1 converts the bloat axis on skills from "aggressive terseness" (the §C framing) into a **strictly text-amount-only reduction with a zero-meaning-change invariant**. The §8 ARCHITECT-NEEDED-1 question ("are the technical-pattern skills in aggressive bloat scope, or only process skills?") is answered: **ALL skills are in scope, but the scope is TEXT AMOUNT ONLY — the same invariant on every skill class.** There is no two-tier policy. A technical skill and a process skill are reduced by the SAME test; the test simply REMOVES less from a substantive technical skill because more of its text is load-bearing.

### A.1 The KEEP/REMOVE rubric a bloat coder applies to EVERY example/pattern/snippet

For each example, pattern, code-snippet, or worked illustration in a skill, the coder asks the user's question literally:

> **Does this example add SPECIFICITY that the rule's prose alone cannot convey?**

Decompose "specificity the prose cannot convey" into three concrete sub-tests (KEEP if ANY is YES):

- **(S1) Concrete shape.** Does the example show a literal shape a reader would otherwise have to guess — an exact API call, a config-key path, a code construct, a filename grammar, a message format, a settings snippet? (e.g. `@Attribute(.externalStorage)`, `worktree.baseRef: "head"`, `2026-04-20-phase-35.md`). Prose can NAME a construct but cannot substitute for its exact form. KEEP.
- **(S2) Edge case / disambiguation.** Does the example pin down a case the reader would otherwise get WRONG — a counter-example, a "this NOT that" contrast, a boundary the prose states abstractly? (e.g. "`isolation` has only `"worktree"`; `head`/`none` are SETTINGS values, not parameter values"). KEEP.
- **(S3) Irreducible enumeration.** Is the example one item in a set the rule MUST enumerate to be correct (the deletion rules `.nullify`/`.cascade`/`.deny`/`.noAction`; the denied git-verb list)? Dropping an item changes what the rule covers. KEEP.

**REMOVE only if ALL three are NO** — i.e. the example is **pure redundant illustration** that restates in example form exactly what the adjacent prose already says, adding no shape, no edge case, no enumeration item. That is text-amount bloat. REMOVE it.

### A.2 The INVARIANT set — NEVER touched (Ruling 1's "must not change")

The reduction is forbidden from altering ANY of:

- **Guardrails** — what the skill protects against / prohibits.
- **Rules / directives** — the numbered/bulleted instructions the agent executes.
- **Triggers** — the load predicate, the "when this applies" conditions, applicability statements.
- **Exceptions / carve-outs** — every "except", "unless", "only when".
- **In-scope / out-of-scope concepts** — the skill's boundary statements (per the CENSUS §5 USER RULING, an "out of scope for this skill" statement is an OPERATIVE GUARDRAIL → KEEP; it bounds what the agent may do).
- **Frontmatter** (Check 1) — name/description/allowed-tools never stripped.

Only these are reducible: **redundant prose, hedging, restated-then-re-argued imperatives, padding, and redundant examples (A.1 REMOVE-class).** Nothing else.

### A.3 The reduction is text-amount-only — what that excludes from §C

§C's four bloat types (B1-B4) remain the mechanical TECHNIQUES, but Ruling 1 TIGHTENS their license on skills:

- **B1 (mega-bullet → table/sub-bullets):** PERMITTED as a pure RESHAPE — every clause survives as a row (the §C.2 clause-preserving method). This is text-amount-neutral-to-slightly-negative and meaning-preserving; allowed.
- **B2 (prose → table):** PERMITTED as a reshape where the prose enumerates cases. Allowed.
- **B3 (verbosity/hedging/restatement padding):** PERMITTED — this is the primary text-amount lever on skills. Delete padding; the directive + trigger survive verbatim-equivalent.
- **B4 (cross-file duplication):** NOT dedup-able (parity by design); reshape multiplies ×3, parity-locked.
- **NEW under Ruling 1 — redundant-example removal (A.1 REMOVE-class):** a fifth reducible class specific to skills. An example that fails all three S-tests is deleted.

What Ruling 1 EXCLUDES that a naive "aggressive terseness" pass might have done: **compressing substantive technical exposition by dropping detail.** On a technical skill, most prose IS the deliverable (it conveys S1/S2/S3 specificity in sentence form). A sentence that states a non-obvious threading rule, a save-time conflict semantic, or a performance consequence is NOT padding — it is the rule's content. The coder may only trim TRUE padding around it.

### A.4 Worked application (4 representative skills, both classes)

Measured at HEAD `2780ada`. Each shows 2-3 examples/passages with the verdict + the S-test reasoning.

#### A.4.1 `project-template/skills/apple-swiftdata-patterns/SKILL.md` (TECHNICAL, 271 ln)

- **Rule 8 deletion-rules enumeration** (`.nullify`/`.cascade`/`.deny`/`.noAction` with each one's behavior). **KEEP (S1 + S3).** Each rule names an exact API value (S1) AND is one item in the set the rule must enumerate to be correct (S3). The prose "choose explicitly" CANNOT substitute — a reader needs the literal set + each one's effect. Not reducible.
- **Rule 6 `@Attribute(.externalStorage)` example** ("for `Data` properties that may exceed a few KB (image blobs, large JSON payloads)"). **KEEP the attribute + the threshold; the parenthetical "(image blobs, large JSON payloads)" is borderline.** The attribute literal is S1 (exact API). The "few KB" threshold is S2 (the disambiguation of WHEN). The parenthetical examples add mild S1 specificity (what kind of Data) — a coder MAY trim to one example ("e.g. image blobs") but should not drop both; this is a marginal text-amount trim, not a substance change.
- **Lead-in to `## @Model macro design`** (if any restated framing exists): **REMOVE-class IF** it merely repeats the Applicability section's "these rules apply at the persistence boundary." That is restatement padding (fails S1/S2/S3). Verdict: text-amount trim.
- **Verdict for the skill:** mostly KEEP — this is substantive S1/S2/S3-dense content; the text-amount win is modest (trim restatement + over-long parentheticals), NOT a structural gutting. Ruling 1 protects exactly this.

#### A.4.2 `project-template/skills/api-design/SKILL.md` (TECHNICAL, 51 ln — already terse)

- **Rule 21 protocol-selection list** (gRPC → `grpc-patterns`, REST → `rest-patterns`, etc.). **KEEP (S1 + S3).** Each row maps a concrete protocol to a concrete skill name (S1) and is an enumeration item (S3). Not reducible.
- **Rule 9 error-payload triple** ("machine-readable code, human-readable message, optional structured detail"). **KEEP (S3).** The three-part enumeration IS the rule's content; dropping a part changes the contract.
- **Verdict:** ESSENTIALLY ZERO reduction. This skill is already at the floor — every line carries an S-test-passing directive or enumeration. A bloat coder should report "no reducible bloat found" rather than invent trims. (Demonstrates the test does not force reduction where none exists — the meaning-invariant dominates.)

#### A.4.3 `.claude/skills/commit-discipline/SKILL.md` (PROCESS, 275 ln — largest pack skill)

- **§1 pre-flight `bash` block** (`pwd` / `git rev-parse HEAD` / `git rev-parse --abbrev-ref HEAD` / `git log --oneline -10` / `ls …` with inline `# Detect regime` comments). **KEEP (S1).** These are the exact commands the agent runs + the exact regime-detection signal (`worktree-agent-*` path). Prose cannot substitute for the literal command set. Not reducible (and it is a code block — see also escalation-2 protection class).
- **§1 prose restating the class-default after the bash block already states it** (the "DEFAULT is set by your agent class, but you VERIFY…" paragraph if it re-explains what a later section covers). **REMOVE-class candidate (fails S1/S2/S3) IF it duplicates §2's regime-verification content.** This is B3 restatement — the canonical process-skill bloat. Text-amount trim; the directive survives in §2.
- **§3 git-state-change ban verb enumeration.** **KEEP (S3).** The denied verb list is an enumeration the guardrail must carry in full; dropping a verb narrows the ban (a meaning change — forbidden by Ruling 1's "guardrails must not change").
- **Verdict:** moderate reduction — the process skill carries real B3 restatement padding (the bloat the user targets), but its command blocks and verb enumerations are protected S1/S3 content.

#### A.4.4 `project-template/skills/audit-methodology/SKILL.md` (PROCESS, 159 ln)

- **Rule-20 / rule-44 platform forward-looks** ("web / Android / embedded once those skills land, deferred…"). **The DEFERRED-FEATURE forward-look is STRIPPED by the STRIP phase (CENSUS §2.8 / §5), NOT the bloat phase.** The bloat phase sees the already-stripped form ("Apple today" / "the current detection list is Apple-centric"). The KEPT guardrail ("applies whenever any UI platform skill is loaded") is an in/out-of-scope concept → INVARIANT (A.2). No bloat-phase action on these lines beyond confirming the strip landed.
- **Verdict:** confirms the boundary — escalation-1's test operates ONLY on the post-strip text; it never re-touches what the STRIP phase already resolved (no double-touch, §5.3 of the plan).

### A.5 The verification contract (how a reviewer proves meaning/functionality unchanged)

The §C.3 clause-set-diff is RETAINED and EXTENDED for skills under Ruling 1. For every skill a bloat commit touches, the reviewer produces:

1. **Invariant-set diff (the meaning proof).** Enumerate the skill's INVARIANT set (A.2: every guardrail + rule + directive + trigger + exception + in/out-of-scope statement) from `git show HEAD:<skill>` (the strip-clean baseline) and from the post-bloat file. **The two invariant sets MUST be EQUAL.** A non-empty asymmetric diff = a meaning-loss BLOCKER. This is the literal encoding of "meaning and functionality must not change."
2. **Example-removal justification log.** For every example/pattern/snippet the commit REMOVED, the IMPL-REPORT records the A.1 verdict: "removed — failed S1 (no concrete shape), S2 (no edge case), S3 (not an enumeration item); pure restatement of `<the prose it duplicated>`." An example removed WITHOUT this log entry is a BLOCKER (the coder must prove the REMOVE-class, per the user's "why or why not?").
3. **Example-retention spot-check.** The reviewer samples KEPT examples and confirms each passes at least one S-test (catches an over-zealous coder who kept padding OR an under-zealous one who should have trimmed — the latter is a NIT, the former is fine).
4. **Frontmatter intact (Check 1)** + **no net new directive/clause** (the diff is removals + reshapes only; a bloat commit never ADDS a rule).

The proof obligation is symmetric to the strip phase's grep-zero but for MEANING: the strip proves "no forbidden token survives"; the bloat proves "no invariant clause was lost."

---
## B. OPTIONAL-FEATURES.md — escalation 2 resolution

### B.1 Process-doc question — direct answer to the user

**Finding: `pack-ops/OPTIONAL-FEATURES.md` is NOT executed as a process doc — no script, install step, or agent-execution path READS, SOURCES, or PARSES its prose as instruction. BUT two validators PARSE it as a presence/length target, and that is the "if it is ever used as a process doc, explain to me why" case you asked me to surface. Detail below.**

I greped every script (`*.py`, `*.sh`), validator, install-map, and agent file for references to the doc (EE-OPT-CONSUME). The references fall into three classes:

**Class 1 — pure human cross-references (NOT process consumption).** Other docs POINT a human reader at it: `README.md:45`, `QUICKSTART.md:45`, `CLAUDE.md:392` ("see OPTIONAL-FEATURES"), `project-template/docs/pack/PM-CHAT.md`, `RUNTIME-SUBAGENT-PATTERN.md:77`, the `boundary-investigation`/`pack-help` skills, `agent-run.sh:280` (a comment). These are "go read this for reference" pointers — consistent with the user's "output doc for reference only." No machine reads the doc here.

**Class 2 — the install map (DELIVERY, not execution).** `scripts/init-project.sh:1246` carries the install-map row `project-template/docs/pack/OPTIONAL-FEATURES.md:docs/pack/OPTIONAL-FEATURES.md:generic` — i.e. the PROJECT copy is COPIED to client installs at init. This treats the file as a shipped artifact (a deliverable), not as an executed process doc. It moves the bytes; it does not act on their content.

**Class 3 — TWO validators that PARSE its content (the "used as a process doc" case — this is what I must explain to you).** Two CI checks read the file and assert things about its TEXT:
  - **Check 54 (`check_optional_features_presence`, "Guard-A′")** reads BOTH OPTIONAL-FEATURES surfaces and asserts each contains the three literal substrings **`baseRef`, `bgIsolation`, `permissions.deny`** (`_CHECK_54_REQUIRED_TOKENS`, validate-pack.py:9280). It FAILS the build if any token is missing. Purpose: guarantee the worktree-isolation feature + its in-session backstop recipe "must not silently vanish from the docs" (BD-197 Note 14).
  - **Check 44 (`check_durable_doc_concision`)** reads the pack copy and (a) scans for the `will ` pattern (teeth) and (b) emits an ADVISORY when the doc exceeds its per-doc line ceiling **271** (`_CHECK_44_DURABLE_DOCS`, validate-pack.py:7763). The advisory NEVER fails the build.

**Why this is not a contradiction of your ruling, and what it means for the bloat:** The doc itself is human-readable reference output (your characterization is correct — nothing executes its PROSE). But CI treats two NARROW PROPERTIES of it as contracts: (1) it must keep mentioning three settings tokens (Check 54), and (2) its length is advisory-tracked (Check 44). So the bloat reduction is constrained by these as GUARDRAILS, not by any execution semantics:
  - The reduction MUST keep the literal strings `baseRef`, `bgIsolation`, and `permissions.deny` present in BOTH surfaces, or Check 54 turns the build RED. (This aligns perfectly with your "structures, code, JSON, settings examples must not be modified" — these three tokens ARE the settings examples Check 54 protects.)
  - The 271 line ceiling is ADVISORY ONLY — it cannot fail the build; it is a smell signal. The bloat may or may not reach it (§B.3).

**Bottom line for you:** OPTIONAL-FEATURES is a reference doc, treated as such everywhere except two CI guards that lock (a) the presence of three settings tokens and (b) an advisory length. Neither makes it a "process doc" in the execute-as-instruction sense; both are content-presence guardrails the bloat must respect.

### B.2 The human-readable reduction method (Ruling 2 encoded)

The reduction reduces TEXT AMOUNT without losing clarity or meaning, applying the `operating-docs-no-history-no-bloat` rule "in a human-readable way" (Ruling 2). Concretely:

**REDUCIBLE (prose only):**
- **Restatement padding** — the same fact stated in "What it is" then re-stated in "When this matters" then re-argued in "How to enable." (The worktree section §111-293 has three consecutive paragraphs that each re-explain that isolation is the class-keyed default — EE-OPT-STRUCT. Collapse to one statement + the consequence.)
- **Hedging / persuasive padding** — "it is worth noting that," "importantly," doubled parentheticals, sentences that argue WHY a rule is good after already stating the rule.
- **B2 prose-that-should-be-a-table** — where enumerable settings/consequences are narrated (e.g. the `baseRef` "head"/"fresh" consequences could be a 2-row table) the coder MAY reshape to a table IF it improves human readability (Ruling 2's "useful to a person") — a reshape, not a deletion.

**PROTECTED (NEVER modified — Ruling 2's explicit list):**
- **All fenced code/JSON/text/bash blocks** — measured: 8 fence markers, 38 fenced lines total (the `settings.json` JSON block §52-58, the agent-team config §65-72, the worktree `baseRef` JSON §188-194, the graphify JSON §221-240, the bash recipe §436-438). EE-OPT-STRUCT. These are reference content a reader copies verbatim. UNTOUCHED.
- **Inline settings specifications** — the literal setting names, enum value sets, and defaults stated in prose: `worktree.baseRef: "head"`, the `["head","fresh"]` value set, `worktree.bgIsolation` `(enum ["worktree","none"], default "worktree")`, `permissions.deny`, `isolation:"worktree"`. These ARE the "settings examples" Ruling 2 protects AND the Check-54 tokens (B.1). A bloat reword MUST preserve every one verbatim. (This is the structures/settings class — protected even though it sits in prose lines, not fences.)
- **Structure** — section headers (the 11 H1-H3), the privacy/secrets D3 subsection content, the §1.1 backend caveat ("do NOT 'correct' it" — an operative instruction), and any worked example shape.

**The operative distinction:** a line is REDUCIBLE only if it is prose that ADDS NO settings token, NO code/JSON/structure, and NO new clarity for a human — i.e. it restates or pads. Everything that conveys a settings value, a copyable shape, or a distinct human-useful fact is PROTECTED. This is the A.1 S-test (S1 concrete shape / S2 disambiguation) applied in human-readable form, exactly as Ruling 2 directs ("follow the rules too, but in a human readable way").

### B.3 The 271 ceiling re-derivation (measure-then-bound)

**The 271 ceiling's basis (EE-CEIL-BASIS):** validate-pack.py:7752-7754 documents the derivation: `271 = ceil(235 × 1.15)` — i.e. the ceiling = measured-cleaned-content × 1.15 growth headroom, and the recorded "measured cleaned" baseline for OPTIONAL was **235 lines**. The doc is now **544 lines** (EE-OPT-SIZE) — 2.3× the 235 the ceiling was derived against. The growth is the graphify section (§324-544, ~220 lines, added after the 235 baseline) plus the worktree section's prose expansion.

**Measure-then-bound on the projected post-bloat content:**

The legitimately-IRREDUCIBLE content of OPTIONAL-FEATURES, under Ruling 2's protection rules, is:
- **Protected fenced blocks:** 38 lines + 8 fence markers = 46 lines (EE-OPT-STRUCT). UNTOUCHABLE.
- **Section headers:** 11 lines. UNTOUCHABLE (structure).
- **The settings-spec prose lines** (the lines carrying `baseRef`/`bgIsolation`/`permissions.deny`/enum/default literals + the §1.1 backend caveat + the privacy/secrets D3 facts): a human-readable doc covering FIVE distinct features (Agent Teams, worktree isolation, Codex optional, Antigravity optional, graphify) each needs a minimal prose skeleton (what it is, how to enable, the settings) around its protected blocks.

**I cannot discharge the exact post-bloat line count read-only** (the actual reduction is the coder's work, and ci-guard-measure-then-bound forbids me asserting a number I did not measure against the reduced text). What I CAN bound:
- The 544 → ≤271 target is a **64%+ reduction**. Given that ~46 lines are protected fences/markers + 11 headers + 73 blank lines (EE-OPT-STRUCT: 73 blanks) = ~130 structural/protected lines BEFORE any settings-prose, hitting 271 requires the remaining ~414 prose/settings lines to compress to ~141. That is plausible for the restatement-heavy worktree section but is NOT guaranteed for a five-feature human-readable doc that must keep each feature's enable-steps + settings legible.
- **The 271 number is STALE** — it was derived from a 235-line measured baseline that PRE-DATES the graphify section. A ceiling derived against pre-graphify content cannot correctly bound post-graphify content.

**Recommendation (the measure-then-bound discipline applied):**
1. The bloat coder reduces OPTIONAL-FEATURES per §B.2 to its legitimately-irreducible human-readable floor (protected content + minimal clear prose), measuring the result with `wc -l`.
2. **Re-derive the ceiling FROM the measured reduced content:** `new_ceiling = ceil(measured_reduced_lines × 1.15)` — the SAME formula the existing ceiling used (validate-pack.py:7752). This keeps the ceiling anchored to real cleaned content, never speculative.
3. If `measured_reduced_lines ≤ 235`, the existing 271 ceiling STANDS — no change. If `235 < measured_reduced ≤ 271`, 271 still holds (under ceiling) — no change. **Only if `measured_reduced > 271`** (the irreducible human-readable content genuinely exceeds it — likely given the graphify addition) does the coder UPDATE the ceiling, in the SAME pack-only commit, to `ceil(measured_reduced × 1.15)`.

**Lock-step surfaces if the ceiling changes (enumerate-encoding-surfaces):**
- `scripts/validate-pack.py` `_CHECK_44_DURABLE_DOCS` — the `("pack-ops/OPTIONAL-FEATURES.md", 271)` tuple row (validate-pack.py:7763) → new value. The accompanying comment block (validate-pack.py:7752-7754) that records "OPTIONAL 235" must be updated to the new measured baseline in the same edit.
- **The Check-44 TEST needs NO value edit (EE-TEST-MOCK).** `scripts/tests/test-validate-pack-check-44.sh` uses a SYNTHETIC doc with a mocked `_CHECK_44_DURABLE_DOCS` (`mod._CHECK_44_DURABLE_DOCS = ((SYNTH_DOC, advisory_ceiling),)`, line 118) and a parameterized `advisory_ceiling` — it does NOT hard-code the real 271. So changing the real ceiling row touches ONLY the one tuple + its comment; the test is unaffected. (This is a clean measure-then-bound surface — the value is not duplicated.)
- No other surface encodes 271 (greped: only validate-pack.py:7763 + the comment).

This is a pack-only edit inside the OPTIONAL-FEATURES bloat commit (the plan's CB-01); it keeps that commit's `pack-only` scope keyword clean (Check 36).

**Do NOT over-terse to hit a stale number.** Ruling 2 is explicit: "the reduction in text can not remove the clarity and meaning." If reaching 271 would force dropping human-useful clarity or a settings example, the coder re-derives the ceiling UP to the irreducible floor instead. The advisory exists to FLAG bloat, not to force a doc below its legitimate content (it never fails the build, so there is no functional pressure to undershoot meaning).

---
## C. Bloat-method refinement + plan impact

### C.1 Reconciliation with DESIGN §C (what the rulings CHANGE or TIGHTEN)

DESIGN §C established the four bloat types (B1-B4), the §C.2 clause-preserving conversion for rules >~800 chars, and the §C.3 reviewer clause-set-diff. The two rulings refine §C as follows:

| §C element | Status under the rulings | Change / tightening |
|---|---|---|
| **B1 mega-bullet → table** | RETAINED | Now a pure RESHAPE (every clause = a row); on skills, additionally constrained to the A.2 invariant set — no clause that is a guardrail/rule/trigger/exception/scope-statement may be dropped, only reshaped. |
| **B2 prose → table** | RETAINED | On OPTIONAL-FEATURES, allowed ONLY where it improves human readability (Ruling 2) and never reshapes a protected code/JSON/settings block. |
| **B3 padding deletion** | RETAINED, becomes the PRIMARY lever | This is the legitimate "text-amount-only" reduction on both skills and OPTIONAL-FEATURES. |
| **B4 cross-file duplication** | RETAINED | Unchanged (parity-locked ×3 / ×2). |
| **§C.2 clause-preserving method** | RETAINED + EXTENDED | Extended from "rules" to "skill examples" via the A.1 S-test: the clause-enumerate step now also enumerates the EXAMPLE set and tags each KEEP/REMOVE with its S-test verdict. |
| **§C.3 reviewer clause-set-diff** | RETAINED + EXTENDED | Becomes the A.5 invariant-set diff for skills (guardrails/rules/triggers/exceptions/scope-statements equal before/after) + the example-removal justification log. |
| **§C.4 sizing / "aggressive terseness"** | TIGHTENED | The phrase "aggressive terseness" is SUPERSEDED for skills by "text-amount-only, zero-meaning-change." There is NO aggressive deletion of substantive content. The §8 ARCHITECT-NEEDED-1 worry ("aggressive terseness on technical skills risks deleting substance") is RESOLVED: the method structurally cannot delete substance because the A.2 invariant set + the A.1 S-test protect every substantive line; only padding + redundant illustration go. |

**Net:** the rulings do not overturn §C — they CALIBRATE it. §C's techniques (B1-B4, clause-preserving) are the HOW; the rulings impose the meaning-invariant + the protected-content set as the GUARDRAILS on the how.

### C.2 Impact on the bloat-phase plan (`PLAN-BD-243-BLOAT-PHASE.md`)

The planner re-plans after this design; I flag what must change (I do NOT re-sequence):

1. **"All skills in scope" does NOT change the bloat UNIVERSE.** The plan's §2.2 already lists pack skills (CB-04), pack agents (CB-05), and project skills (CB-09b) as IN. Ruling 1 confirms ALL of them stay IN — it does NOT add or remove files. So the **commit count is UNCHANGED** (9, with the CB-09a/b split option intact) and the **CB-* partition is UNCHANGED**.

2. **What the planner MUST update — the two §8 ARCHITECT-NEEDED flags are now RESOLVED, so delete them and fold their resolution into the per-commit method:**
   - **§8 flag 1 (technical-skill bloat policy)** → RESOLVED by §A: ALL skills, text-amount-only, the A.1 S-test + A.2 invariant set is the method. The planner replaces the "ARCHITECT NEEDED" flag with the A.1/A.5 method for CB-04 (pack skills), CB-05 (pack agents), and CB-09b (project skills). The expected REDUCTION on technical skills is now correctly framed as MODEST (most lines are S-test-passing content), not aggressive — the planner should not size CB-09b as a large line-delta commit.
   - **§8 flag 2 (OPTIONAL-FEATURES ceiling re-derivation)** → RESOLVED by §B.3: the coder reduces to the human-readable floor, then re-derives the ceiling FROM the measured reduced content (≤271 → no change; >271 → update the one tuple row + comment, no test edit). The planner replaces the conditional "ARCHITECT NEEDED" with this deterministic recipe for CB-01.

3. **The verification PLAN (plan §7) gains the A.5 obligations for skill commits:** the invariant-set diff + the example-removal justification log are added to the reviewer's per-commit proof for CB-04, CB-05, CB-09b (alongside the existing clause-set-diff). For CB-01 the §B.3 measured-re-derivation is added to the coder PREFLIGHT (measure `wc -l`; re-derive ceiling; update tuple if needed).

4. **OPTIONAL-FEATURES protected-content guardrail (plan §7 / CB-01):** add an explicit pre-commit check that the three Check-54 tokens (`baseRef`, `bgIsolation`, `permissions.deny`) survive in the pack copy AND that all fenced blocks are byte-unchanged (a `git diff` on fence-delimited ranges = empty). The coder runs `python3 scripts/validate-pack.py --only-check 54` (must exit 0) before the IMPL-REPORT — this is the cheap insurance that the settings-example protection held.

5. **No change to the CG (strip) phase.** The deferred-feature forward-looks on skills (CENSUS §2.8) are STRIPPED in their CG commits, not the bloat phase — the bloat phase operates on post-strip text (the plan's no-double-touch invariant, §5.3). The planner keeps this boundary; CB-09b never re-touches a line CG-12 already resolved.

### C.3 Snippet-stability contract relevance (the bloat reword vs Check-65 allowlist)

The plan's §6.2 C-SNIP contract is BINDING and UNCHANGED by these rulings, and it INTERSECTS escalation 2:

- **OPTIONAL-FEATURES carries an allowlisted snippet** — the plan's §6.2 C-SNIP-1 table lists `pack-ops/OPTIONAL-FEATURES.md` with the K13 snippet `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md`. A bloat reword of the graphify section MUST keep that snippet substring matchable (C-SNIP-2: leave it verbatim, or co-update the allowlist record in the same pack-only commit). Because the snippet is a doc-filename token in prose (NOT a fenced block), the §B.2 protection does not automatically cover it — the coder must treat it as a third protected token alongside the Check-54 trio. The C-SNIP-3 dry-activation probe (set `_CHECK_65_OPERATING_DOCS` to just the touched file, run `--only-check 65`, expect exit 0, discard) is the per-commit insurance that the reword did not break the allowlist match.
- **Skills generally carry no Check-65 allowlist snippets** (the §6.2 table's snippet-bearing files are the trinity, RATIONALE, PACK-CHAT, PACK-AGENTS, backlog/_rules, PACK-FEEDBACK, changelog meta — not the technical skills). So CB-04/CB-05/CB-09b bloat rewords are not snippet-constrained EXCEPT where a skill happens to carry an allowlisted line; the coder runs the §6.2 inventory step per file regardless (if a file has zero allowlist records, the step is a no-op).
- **Principle:** any bloat reword on ANY doc carrying allowlisted lines must keep every snippet substring matchable, or co-update the allowlist record in the same commit. This is the plan's existing contract; the rulings add OPTIONAL-FEATURES's K13 graphify snippet + the Check-54 trio as the concrete protected tokens for CB-01.

---

## D. EMPIRICAL-EVIDENCE BLOCKS

All measurements @ HEAD `2780ada` (`2780adaa295c0b62fb9d5148c16639c35039bd64`), branch `v11-dev`, 2026-06-22, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery during research; the authoritative gate for every exact-state claim is grep / `wc -l` / file read (G2 fallback per graph-first-context — the BD-243-era surfaces are stale in the graph per the design's EE-V10 / census EE-GRAPH).

**EE-HEAD — runtime HEAD = `2780ada`; clean re BD-243 (untracked plan docs only).**
- Cmd: `git rev-parse HEAD; git branch --show-current; git log --oneline -3`.
- Output (verbatim): `2780adaa295c0b62fb9d5148c16639c35039bd64`; `v11-dev`; `2780ada fix: v11 — BD-243 regenerate test-fixtures/manifest.txt …`, `be94aa8 … strip PACK-FEEDBACK deferred-skills leak (CG-13)`, `7f2e952 … strip platform-future-skills forward-looks from project skills (CG-12)`.
- Interpretation: HEAD is the prompt's canonical `2780ada`; CG-12/CG-13 (project skill strips) have LANDED — the bloat phase will see post-strip skill text.
- Conclusion: **SUPPORTED.**

**EE-SKILL-COUNTS — pack skills (11) + project skills (37) line counts.**
- Cmd: `wc -l .claude/skills/*/SKILL.md project-template/skills/*/SKILL.md | sort -rn`.
- Output (verbatim, top): pack — `commit-discipline 275`, `verification-harness 241`, `boundary-investigation 185`, `implementation-report 154`, `pack-startup 106` (pack total 1218); project — `python-observability-patterns 527`, `swift-concurrency-patterns 418`, `apple-swiftdata-patterns 271`, `protobuf-patterns 249`, `pm-startup 206`, `audit-methodology 159`, `api-design 50` (project total 3614).
- Interpretation: 48 skills total; the largest are technical (python-observability 527, swift-concurrency 418) — exactly the §8-flagged "aggressive terseness risks substance" set, now protected by §A. ALL are in scope text-amount-only.
- Conclusion: **SUPPORTED.**

**EE-OPT-SIZE — OPTIONAL-FEATURES line counts (both surfaces).**
- Cmd: `wc -l pack-ops/OPTIONAL-FEATURES.md project-template/docs/pack/OPTIONAL-FEATURES.md`.
- Output (verbatim): `544 pack-ops/OPTIONAL-FEATURES.md`; `425 project-template/docs/pack/OPTIONAL-FEATURES.md`.
- Interpretation: pack copy 544 (the hard bloat target vs the 271 advisory); project copy 425 (no ceiling, B3-only).
- Conclusion: **SUPPORTED.**

**EE-OPT-STRUCT — protected vs reducible content in pack OPTIONAL-FEATURES.**
- Cmd: python pass classifying each line (in-fence / fence-marker / blank / header / prose).
- Output (verbatim): `total 544`; `fenced content lines (protected) 30`; `fence marker lines 8`; `blank 73`; `header (H1-H6) 11`; `prose/other 422`; `protected total (fenced+markers) 38`. Headers via `grep -nE '^#{1,3} '`: 11 sections (Agent Teams §19, worktree §111, Codex §294, Antigravity §301, Adding entries §308, Graphify §324 + 4 graphify sub-sections). Fences via `grep -nE '^```'`: `52 json`, `58`, `65 text`, `72`, `221 json`, `240`, `436 bash`, `438`.
- Interpretation: ~46 protected lines (fences+markers) + 11 headers + 73 blanks = ~130 structural/protected; ~414 prose+settings lines are the reduction surface, of which the settings-spec lines (Check-54 trio + enums/defaults) are additionally protected. The graphify section (§324-544 ≈ 221 lines) is the dominant addition vs the 235 baseline.
- Conclusion: **SUPPORTED.**

**EE-OPT-CONSUME — who references / consumes OPTIONAL-FEATURES.**
- Cmd: `grep -rn "OPTIONAL-FEATURES" --include="*.py" --include="*.sh" --include="*.md" --include="*.toml" --include="*.json" .` (minus .git, maintenance-docs, /tmp); plus focused `*.py`/`*.sh`.
- Output (verbatim, key): human cross-refs — `README.md:45`, `QUICKSTART.md:45`, `CLAUDE.md:392`, `RUNTIME-SUBAGENT-PATTERN.md:77`, `agent-run.sh:280` (comment); install map — `scripts/init-project.sh:1246` `…OPTIONAL-FEATURES.md:docs/pack/OPTIONAL-FEATURES.md:generic`; validators — `scripts/validate-pack.py:7763` ceiling tuple, `:9271-9272` `_CHECK_54_OPTIONAL_FEATURES_SURFACES`, `:9320` `missing = [tok for tok in _CHECK_54_REQUIRED_TOKENS if tok not in text]`. NO script/agent SOURCES or PARSES the prose as instruction.
- Interpretation: reference doc everywhere; the ONLY machine reads are Check 54 (3-token presence) + Check 44 (will-scan + advisory length) + the install-copy. None executes its prose → it is NOT a process doc; it has two content-presence guardrails.
- Conclusion: **SUPPORTED.**

**EE-CHECK54 — Check 54 mandates 3 literal tokens in BOTH surfaces, FAILS if missing.**
- Cmd: read validate-pack.py:9271-9332.
- Output (verbatim): `_CHECK_54_REQUIRED_TOKENS = ("baseRef", "bgIsolation", "permissions.deny")`; `missing = [tok for tok in _CHECK_54_REQUIRED_TOKENS if tok not in text]`; on missing → `fail(... is MISSING worktree-isolation documentation token(s) ...)`.
- Interpretation: these three settings tokens are a hard CI contract — the bloat reduction MUST preserve them verbatim in both copies (aligns with Ruling 2's "settings examples must not be modified").
- Conclusion: **SUPPORTED.**

**EE-CEIL-BASIS — the 271 ceiling = ceil(235 × 1.15), derived from measured cleaned content.**
- Cmd: read validate-pack.py:7750-7764.
- Output (verbatim): comment "each doc's per-doc ADVISORY line ceiling, DERIVED from its measured cleaned content as ceil(measured * 1.15) … (BOUNDARY 135, CONCEPTUAL-REVIEW 298, DRY-RUN 199, HELP-PACK 48, MERGE 484, OPTIONAL 235)"; tuple `("pack-ops/OPTIONAL-FEATURES.md", 271)`.
- Interpretation: 271 = ceil(235×1.15); the 235 baseline pre-dates the graphify section (now ~221 lines) → the ceiling is STALE relative to current legitimate content; re-derivation FROM the measured reduced content is the measure-then-bound fix.
- Conclusion: **SUPPORTED.**

**EE-CEIL-ADVISORY — Check 44 currently emits the 271 advisory (never fails).**
- Cmd: `python3 scripts/validate-pack.py --only-check 44`.
- Output (verbatim): `OK: pack-ops/OPTIONAL-FEATURES.md — ADVISORY: 544 lines exceeds the per-doc advisory ceiling 271 (derived from measured cleaned content). Advisory only — not a failure …`; `PASSED — all checks clean`.
- Interpretation: the ceiling is advisory-only — no functional pressure to undershoot meaning; the bloat targets it as a smell signal, not a build gate.
- Conclusion: **SUPPORTED.**

**EE-TEST-MOCK — the Check-44 test does NOT hard-code 271 (mocked synthetic doc).**
- Cmd: `grep -n "271\|_CHECK_44_DURABLE_DOCS\|advisory_ceiling" scripts/tests/test-validate-pack-check-44.sh`.
- Output (verbatim): `118: mod._CHECK_44_DURABLE_DOCS = ((SYNTH_DOC, advisory_ceiling),)`; `95: advisory_ceiling: int = 10000`; `174: run_check_with_synthetic(body, "", advisory_ceiling=5)`; no literal `271`.
- Interpretation: changing the real OPTIONAL ceiling row touches ONLY the tuple + its comment in validate-pack.py; the per-check test is value-agnostic (uses a synthetic ceiling) → clean single-surface edit.
- Conclusion: **SUPPORTED.**

**EE-CHECK65-INERT — Check 65 is registered but inert (no bloat-phase gate change).**
- Cmd: `grep -n "_CHECK_65_OPERATING_DOCS = " scripts/validate-pack.py; grep -n "CHECK_REGISTRY_EXPECTED_COUNT = " scripts/validate-pack.py`.
- Output (verbatim): `7926:_CHECK_65_OPERATING_DOCS = ()`; `496:CHECK_REGISTRY_EXPECTED_COUNT = 63`.
- Interpretation: the gate enforces nothing during the bloat phase (activates at CG-14 on the final tree, per the plan §6) — confirms the bloat reword's only Check-65 exposure is the future activation, which the C-SNIP contract + the C-SNIP-3 dry probe insure against.
- Conclusion: **SUPPORTED.**

**EE-SKILL-EXAMPLES — representative skill example content (worked-application basis).**
- Cmd: read `apple-swiftdata-patterns/SKILL.md` (1-75), `api-design/SKILL.md` (full), `commit-discipline/SKILL.md` (headers + 6-40).
- Output (verbatim, key): swiftdata rule 8 enumerates `.nullify`/`.cascade`/`.deny`/`.noAction` with effects; rule 6 `@Attribute(.externalStorage)` "(image blobs, large JSON payloads)"; api-design rule 21 protocol→skill list; commit-discipline §1 `bash` pre-flight block (`pwd`/`git rev-parse HEAD`/`git rev-parse --abbrev-ref HEAD`/`git log --oneline -10`/`ls`), §3 verb-ban enumeration.
- Interpretation: confirms the A.4 verdicts — enumerations (S3) + API literals (S1) + command blocks (S1) dominate technical/process skills; pure restatement padding is the minority and the legitimate reduction target.
- Conclusion: **SUPPORTED.**

---
## E. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only git verbs run: `git rev-parse HEAD`, `git branch --show-current`, `git log --oneline -3`, `git status --short` (snapshot only). Sole write = this design doc via `cat >>` to the caller-specified `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-BLOAT-METHOD.md`. No repo-file edit; no patch; no `git add`/`commit`/`apply`/state-changing verb. | COMPLIANT |
| **reconciliation-instance-independence** | FRESH architect; did NOT author `DESIGN-BD-243-FINAL.md` / `CENSUS-DEFERRED-FEATURE-MENTIONS.md` / `PLAN-BD-243-BLOAT-PHASE.md`. Reached own conclusions: formalized the A.1 S1/S2/S3 example test (new); answered the process-doc question with the Check-54/Check-44 finding (B.1); re-derived the ceiling basis (235×1.15) and recommended a measured re-derivation rather than adopting 271 (B.3); resolved both §8 ARCHITECT-NEEDED flags. Encoded the two user rulings verbatim as binding constraints; did not relitigate. | COMPLIANT |
| **empirical-evidence-blocks** | Every state-claim backed by EE-HEAD / EE-SKILL-COUNTS / EE-OPT-SIZE / EE-OPT-STRUCT / EE-OPT-CONSUME / EE-CHECK54 / EE-CEIL-BASIS / EE-CEIL-ADVISORY / EE-TEST-MOCK / EE-CHECK65-INERT / EE-SKILL-EXAMPLES: each = command + verbatim output (counts/paths/quotes) + HEAD `2780ada` + 2026-06-22 + interpretation + SUPPORTED. Skill counts via `wc -l`; OPTIONAL structure via python line-classifier; consumption via grep; ceiling basis via source read; test-mock via grep. | COMPLIANT |
| **ci-guard design — measure-then-bound** | The ceiling re-derivation (B.3): MEASURED first (544 total; 38 fenced; 11 headers; 73 blank; the 235-baseline-vs-current-544 staleness — EE-OPT-STRUCT/EE-CEIL-BASIS); does NOT assert a speculative new number — instead bounds the method (`new_ceiling = ceil(measured_reduced × 1.15)`, only if measured_reduced > 271) so the value is anchored to real cleaned content; enumerated the exact lock-step surfaces (the one tuple row + comment; test needs no edit — EE-TEST-MOCK); never widens speculatively. The Check-54 token-preservation is sized to exactly the 3 authored tokens (no broader). | COMPLIANT |
| **user prescriptive authority / pack-architect spawn protocol** | The two user rulings (§0) are encoded as BINDING constraints: Ruling 1 → the §A text-amount-only invariant + A.2 invariant set; Ruling 2 → the §B human-readable reduction + protected code/JSON/settings set + the process-doc explanation the user explicitly requested. No ruling relitigated; the process-doc finding is surfaced (per the user's "explain to me why") not buried. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered exactly: the examples/patterns justification test (§A) with a 4-skill worked application across both classes; the OPTIONAL-FEATURES escalation-2 resolution (§B: process-doc answer + reduction method + ceiling re-derivation); the §C reconciliation with §C + plan-impact + snippet-stability relevance. Did NOT re-sequence the bloat commits (named what the planner must update; left sequencing to the planner) and proposed no new features. | COMPLIANT |
| **graph-first-context** | Discovery used graph-first intent; the authoritative gate for every exact-state claim is grep / `wc -l` / file read (the process-doc consumption question is a grep-over-scripts question, which the prompt designates authoritative). G2 fallback exercised for BD-243-era surfaces (stale in graph). The injected absolute graph path form was available; QUERY-only, never built. | COMPLIANT |
| **rules-applied-verification-block** | This table — every rule in the prompt's Rules-in-force block has measured/quoted evidence + a terminal COMPLIANT conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

**END — DESIGN-BD-243-BLOAT-METHOD.md**
