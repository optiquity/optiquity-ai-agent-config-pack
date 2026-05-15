# Conceptual Review Methodology

**Purpose:** structured methodology for reviewing a CONCEPT — a cross-cutting subject-matter area that spans multiple BDs and batches — to catch integration concerns, doc-set composition issues, and architectural drift that per-BD reviews and per-batch reviews structurally cannot see.

**Status:** v11.0 working methodology (created 2026-05-15). Folds into the `audit-methodology` SKILL when BD-110 lands in Batch 21. Until then, this doc is the canonical source.

**Empirical basis:** Established 2026-05-15 after the Batch 17 per-BD vs end-of-batch reviewer experiment empirically demonstrated that broader-scope reviews catch findings narrower-scope reviews miss (and vice versa). The 73% cross-cut ratio at end-of-batch suggested an even broader concept-level scope would catch a third class of findings.

---

## When to use

- Strategic checkpoints in major-version development, after the in-scope concept's implementation is complete across all its BDs/batches.
- 2-4 conceptual reviews per major version maximum. Beyond that = diminishing returns; institutional review fatigue; agent token cost.
- Best timing: after all impl batches ship, before final milestone audit. Concepts must be complete; otherwise findings are dominated by "not implemented yet."

## When NOT to use

- Mid-implementation. Implementation gaps dominate findings; signal-to-noise is poor.
- For deliverable-shaped scopes — those are per-BD or per-batch reviews; conceptual review is for cross-deliverable subject-matter areas.
- As a replacement for per-BD or per-batch review. Conceptual is additional, not substitute.
- Without a pre-declared concept-scope doc. Unbounded conceptual reviews spiral.

## The six review dimensions

Every finding the reviewer surfaces falls into one of these dimensions; the dimension is a mandatory finding field.

### (a) Completeness
Was the concept fully implemented across its in-scope BDs/batches? Surfaces gaps where a BD landed but didn't address a part of the concept it claimed to.

### (b) Edge cases (bounded)
Edge cases reachable from documented user paths in PM-CHAT.md / SETUP procedures, edge cases covered by existing test fixtures, and named failure-mode UX from V3.3-DELTA / V3 §27.1. **Not** speculative edge cases — those go in (f) only when explicitly in concept scope.

### (c) Touch points + cross-concept impact
Files, configs, scripts, docs, or other artifacts that mention the concept or participate in its execution. This is the highest-value dimension and the main reason conceptual review exists. See "Touch-point classification" below.

### (d) Pack rule adherence
Does the implementation violate any strategic or tactical established pack rule? Reference: `CLAUDE.md`, `PACK-CHAT.md`, pack memory `MEMORY.md` index + linked feedback files, `ARCHITECTURE-V*.md` family. Cite the rule by file + section/line for every finding.

### (e) Design best practice adherence
Reference: see "Design best practices" section below for the 7 universal principles.

### (f) Concept-specific
Escape hatch for invariants/properties/contracts unique to this concept. Pre-declared in the concept-scope doc; not added mid-review.

## Touch-point classification (mandatory per finding)

For every finding, the reviewer classifies the touch point into ONE of:

| Class | Meaning | Required follow-up |
|---|---|---|
| **OWNED** | File/symbol owned by this concept; only this concept reads/writes | Standard fix; no coordination |
| **SHARED-RO** | File/symbol read-only by other concepts (they consume but don't mutate) | Standard fix; verify no semantics change for consumers |
| **SHARED-RW** | File/symbol read AND written by ≥2 concepts (race-condition zone) | Coordination required; flag the other concept(s) explicitly |
| **CONTRACT** | The touch point IS the inter-concept contract (label name, schema field, verb signature, return shape) | **`ARCH` severity**: changing the contract requires re-architect across all dependent concepts |

This classification is a structural forcing function. Reviewers must think about cross-concept impact before proposing a fix.

## Severity scheme

Standard pack severity scheme extended with one new tier:

| Severity | Meaning |
|---|---|
| `BLOCKER` | Ship-stopper. Cannot land without resolution. |
| `MUST` | Correctness or contract violation. Fix before next major boundary. |
| `SHOULD` | Quality, clarity, or coverage gap worth fixing. |
| `NIT` | Polish. Fix unless trivial-to-decline per existing fix-all rule. |
| **`ARCH`** (new) | Fix would require re-architect across multiple concepts. Reviewer surfaces but does NOT propose a fix. Triggers a separate architect pass. |

## When to tag `ARCH`

Three triggers — any one is sufficient:

1. **Fix would change a CONTRACT touch point.** Example: changing the `derived-from:TD-NNN` label format breaks BD-106 + BD-107 + future BD-110 auditor.
2. **Fix requires changing procedure ordering between ≥2 concepts.** Example: "Forward migrate must run cycle-check store population BEFORE step 7" is a re-architecting of the migration phase order.
3. **Fix to this finding would create a new finding in another concept.** Example: fixing customization-preserve to detect Shape A markers might require Path 3 forbidden invariant to admit a new label class — net new POQ.

When `ARCH` triggers, the reviewer:
1. Tags severity as `ARCH`
2. Lists the architectural decision that needs revisiting (cite V3.x § or relevant doc)
3. Lists ALL other concepts affected
4. **Does NOT propose a fix** — fixes for `ARCH` findings come from a separate architect pass

## Race-condition detection heuristic

In this pack, "race" is procedural, not OS-level concurrency. The detection rule:

> For every artifact (file, label, id-mapping, sidecar field, config key) the concept references, ask: "What other concept reads or writes this artifact, and at what point in their procedure?" If another concept writes the artifact AFTER this concept reads it (or vice versa, depending on the dependency direction), that is a procedural race.

Concrete patterns from prior v11 work:
- Tracker init + customization preserve: init order matters — customization markers must be written BEFORE template overlay.
- Forward migrate + cycle-check store: cycle store written by `tracker_links_create_blocked_by`; if forward migrate bypasses it (Batch 17 F1), the store is empty and cycle detection is silently disabled.
- CI workflow + new test scripts: test scripts exist on disk but workflow doesn't invoke them (Batch 17 BD-108 F1) — CI green doesn't mean tests ran.

Reviewer template for race findings:
```
**Race:** Concept X writes <artifact> at <procedure step>;
Concept Y reads <artifact> at <procedure step>.
If <ordering condition>, <stale-state consequence>.
**Remediation:** <ordering constraint | shared lock | re-architect to remove the dependency>
```

## Rat-hole limits (operational discipline)

1. **Pre-declared in-scope concept list.** Review only touches concepts named in scope. Cross-references to other concepts are noted (one sentence) but not pursued.
2. **Time-box per finding.** If a finding takes more than ~5 minutes of reasoning to ground in evidence, escalate to `ARCH` and move on.
3. **No "the whole system is wrong" findings.** Those are user-initiated audit territory, not a single conceptual review.
4. **Findings spanning >3 concepts auto-`ARCH`.** If your fix touches 4+ concepts, you're not fixing a finding, you're re-architecting.
5. **Empirical anchoring required.** Every finding cites observable evidence (`file:line`, test failure, CI run, BACKLOG entry, prior commit). Reasoning-from-first-principles findings without evidence are not surfaced.

## Report shape

Every conceptual review report has these sections:

```
1. Scope declaration
   - In-scope concept name + binding invariant
   - In-scope BDs (list)
   - In-scope files (list or pattern)
   - Out-of-scope concepts (explicit; prevents drift)
   - Touch-point matrix vs other concepts

2. Methodology notes
   - Which artifacts were surveyed
   - Which tools/greps/tests were used to ground findings

3. Findings
   - Per finding:
     - Severity: BLOCKER | MUST | SHOULD | NIT | ARCH
     - Dimension: (a) | (b) | (c) | (d) | (e) | (f)
     - Touch-point class: OWNED | SHARED-RO | SHARED-RW | CONTRACT
     - Evidence: file:line, test, CI run, commit hash
     - Description: what's wrong, observed in context
     - Suggested fix (or "ARCH — separate architect pass needed")
     - Cross-concept impact (list of other concepts affected)
     - Rule/principle violated (cite source)

4. Coverage notes
   - What was IN scope but NOT reviewed (and why)

5. Re-architect summary
   - All ARCH findings collected
   - Named architectural decisions to revisit
   - Spawning architect pass per finding (or batched)
```

The Re-architect summary at the end is critical. Without it, ARCH findings get buried in the mix and forgotten. This section is the trigger for spawning a follow-up architect pass.

## Pack rules to reference (for dimension d)

Cite the rule by file + section/line for every (d) finding. No "violates pack convention" without the citation.

**From `CLAUDE.md` (pack-repo workflow):**
- Trinity rule (CLAUDE/AGENTS/GEMINI parity)
- Pack ops vs pack product separation
- Files agents may / must-not modify
- BACKLOG resolves in place (no Resolved section)
- CI validation must pass
- Commit message format / versioning rules / BD-NNN numbering

**From `PACK-CHAT.md` and pack memory `MEMORY.md` index:**
- Review/fix cycles per BD AND per batch (per `feedback_review_fix_one_cycle.md`)
- Fix all review findings (incl. nits)
- Implicit BD status flip on batch completion
- Agents never commit
- No prior reviews to reviewer
- No solutions in agent prompts
- Filename uniqueness heuristic
- Spawn sub-agents in background; no worktree isolation from non-main clones

**From `ARCHITECTURE-V1.md` and `V3.3-DELTA.md`:**
- Path 3 forbidden (V3.3 §1, §3 line 27)
- Trinity rule applicability (V3.3 §9.7)
- Per-CLI parity (V3.3 §8.4)
- V1 §6.0 bidirectionality contract
- V1 §5.3 reserved `link.kind` open-string family (no new operations)
- V1 §9 typed-error contract / V1 §9.6 partial-write
- V3 §27.1 Layer-2 named-recovery-verb pattern
- V3.3 §5.6 no silent retry / no silent fallback

## Design best practices (for dimension e)

Seven universal principles. Violations have empirically caused real bugs in v11. Cite source where applicable.

| # | Principle | Source / example |
|---|---|---|
| 1 | **Single source of truth** for content / rules / config | Trinity files; HELP-FRAGMENT pack-root vs project-template; spec sections vs implementation comments |
| 2 | **Bidirectionality / round-trip safety** — forward → reverse → forward is no-op | V1 §6.0; every tracker forward must have a reverse that produces byte-identical (or whitespace-tolerant) flat-file |
| 3 | **Typed errors with named recovery verb** | V1 §9 + V3 §27.1 Layer 2; uniform `tracker_error_emit` envelope; never bare `printf 'ERROR:'` |
| 4 | **Composition over special cases** — uniform mechanism for many uses | V1 §5.3 `link.kind` open-string family; avoid new ops per use case |
| 5 | **Mode-agnostic operational logic** — flat-file and tracker mode share the same logic; only the resolver differs | V1 §8.5 / D-6 trinity Document-locations resolver |
| 6 | **Idempotency for orchestration verbs** — re-running on already-applied state is no-op or replay-safe | V1 §6.4 checkpoint; `pack tracker init`, `pack td promote` |
| 7 | **Additive grammar extensions** — new forms admitted, existing forms continue to parse | V3.3 §5.3 (Blockers gain `phase-N.M`); V1 §6.7 whitespace tolerance |

If a finding violates a principle not on this list, document it as concept-specific (f) and note for inclusion in v(N+1) methodology revision.

## Reviewer agent / invocation

**Preferred (when available):** `pack-auditor` agent (BD-110, lands in Batch 21). Designed for "ongoing-state audit of pack repo" per V3.3 §8. Conceptual review is a natural extension of its scope.

**Fallback before BD-110 lands:** `pack-architect` invoked with explicit conceptual-review prompt template (cite this methodology doc + the concept-scope doc). The architect agent has the right cross-BD mental model but is not its primary mode.

**Wrong tool:** `pack-reviewer`. Its scope is pre-commit changes; conceptual review is about the surface as it currently exists, not about recent diffs.

## Concept-scope doc requirement

Every conceptual review requires a per-concept scope doc that pre-declares:
- Concept name + binding invariant
- In-scope BDs (list)
- In-scope files (list or pattern)
- Out-of-scope concepts (explicit; prevents drift)
- Touch-point matrix vs other concepts (which other concepts share which files with this one)
- Design intent references (V3.x § + relevant docs)
- Critical invariants
- Pre-existing test coverage (so reviewer doesn't re-derive what tests already prove)
- Known boundary conditions / failure modes

These docs live at `maintenance-docs/v{N}-implementation/CONCEPTUAL-AREA-{NAME}.md`. They are version-specific (concepts evolve across versions); the methodology itself is timeless.

## Future integration

When BD-110 (Batch 21) lands the `pack-auditor` agent + `audit-methodology` SKILL:
1. Fold this methodology doc's structural content into the SKILL (skill body cites this doc as the design source).
2. The standalone doc remains as canonical methodology reference.
3. The SKILL is the agent-invoked execution surface (`pack-auditor` reads it on every conceptual-review invocation).
4. Trinity rule applies to the SKILL (per-CLI replication); doesn't apply to this doc (single-file pack methodology).

For v12.0+ and beyond:
- Keep this methodology doc; revise based on empirical learnings from v11 trial reviews.
- For each major version's EXECUTION-PLAN, add a "Batch (pre-audit-N): conceptual area reviews" row listing the concepts in scope that version.
- Per-version concept-scope docs roll forward (concepts that persist across versions get new scope docs at the new version's `maintenance-docs/v{N}-implementation/`).

## Empirical validation requirement

A new conceptual area review approach must be empirically validated before institutionalization:

1. Run TRIAL conceptual review (informal; not in formal batch slot)
2. Compare findings against per-BD + per-batch reviews from same window
3. Quantify: findings count, cross-cut ratio, MUST-or-higher findings unique to this scope
4. Decide:
   - If unique value-add is real (e.g., ≥2 MUSTs not catchable by per-BD or per-batch) → institutionalize (add formal batch slot in next version's EXECUTION-PLAN)
   - If marginal → don't institutionalize; rely on existing review scopes + final milestone audit
5. Document empirical results in `maintenance-docs/v{N}-implementation/CONCEPTUAL-REVIEW-TRIAL-RESULTS.md`

The trial requirement applies on first introduction (v11.0) and may apply on substantial methodology revisions in later versions.
