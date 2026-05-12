# PACK-REVIEW-BD-149.md

**Verdict:** APPROVE — BD-149 codifies the four-suffix naming convention faithfully to the architect spec; the BD-159 cross-reference uses the BACKLOG-recommended wording verbatim and points at headings that exist in all three pack-repo trinity files; the optional ambiguity tie-breaker is in scope (architecture §7.10 explicitly acknowledges the ambiguity it addresses) and recommended for retention.

---

## 1. Scope and inputs verified

- BD-149 BACKLOG entry — `BACKLOG.md:1394-1402` (Open, blockers BD-142/156/157/158/159 all Resolved per recent commits).
- Architect spec §7.10 — `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md:953-977`.
- Cross-reference shape §4.4 — `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md:238-252`.
- BD-159 canonical text — `CLAUDE.md:155-183` (`### Repo conventions` under `## Pack memory`); mirrored at `AGENTS.md:132-145+` and `GEMINI.md:110-123+`.
- Working-tree edit — `project-template/docs/pack/PLATFORM-SKILLS.md:562-610` (one file, +39 / -0 per IMPL report §3.5).
- Implementation report — `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-149.md`.

`scripts/validate-pack.py` (BD-146 in-flight) and the six untracked `maintenance-docs/v11-research/` files were not reviewed per prompt constraint.

---

## 2. Per-concern findings

### 2.1 Four-suffix naming convention codified — PASS

`PLATFORM-SKILLS.md:573-599` introduces `### Naming convention for new skills` with one bullet per suffix, each leading with the suffix in bold backticks, followed by the content rule and concrete examples drawn from the live catalog:

- `*-best-practices` (line 581) — `swift-best-practices`, `python-best-practices` ✓
- `*-language` (line 585) — `c-language`, `cpp-language`, `objc-language` ✓
- `*-architecture` (line 588) — `apple-architecture-core`, `ios-architecture`, `macos-architecture`, `python-server-architecture`, `python-data-architecture` ✓
- `*-patterns` (line 593) — `grpc-patterns`, `rest-patterns`, `security-patterns` plus the three v11.0 additions ✓

This is a direct realization of architecture §7.10's "Recommended disposition" paragraph (lines 969-976). All cited skill names appear as rows in the §"Full skill inventory" tables higher in the same file (verified inline at lines 446-464).

### 2.2 BD-156/157/158 cited as recent worked examples — PASS

`PLATFORM-SKILLS.md:595-599` cites all three new skills explicitly with their BD numbers:

- `protobuf-patterns` (BD-156, Proto3 schema design standalone of gRPC)
- `apple-swiftdata-patterns` (BD-157, SwiftData object-store rules)
- `swift-concurrency-patterns` (BD-158, modern Swift Concurrency + GCD)

Each parenthetical accurately describes the new skill's domain. No invented attributions.

### 2.3 v11.0 no-rename stance with BD-155 reference — PASS

`PLATFORM-SKILLS.md:576-579`: "**New skills must follow this convention.** Existing skills are not renamed in v11.0 — the cost of breaking external references outweighs the consistency benefit at this point; a future v12 enforcement migration is tracked under BD-155."

Matches architecture §7.10 user decision 7 ("Do not rename existing skills") and the BACKLOG description's "Enforcement migration ... is deferred to v12 (BD-155)" verbatim in spirit. Wording is semantically identical to the BACKLOG mandate.

### 2.4 Maintainability-rule cross-reference — PASS (verbatim BACKLOG-spec wording, target heading exists)

`PLATFORM-SKILLS.md:606-610` ships:

```
> **Maintainability rule.** Adding a new skill is a mechanical edit when
> it fits the existing dimensions, patterns, and naming conventions
> documented above. See the pack-repo trinity (`CLAUDE.md` / `AGENTS.md`
> / `GEMINI.md` `## Pack memory`) for the full mechanical-vs-structural
> threshold and the client `x-` preservation rule.
```

**Wording verification.** Compared character-by-character against the BACKLOG.md BD-149 File/Symbol-line recommended wording (`BACKLOG.md:1399`) — **byte-identical** to the BACKLOG specification. The BACKLOG entry is the authoritative spec per the prompt; matches it verbatim.

**Heading-existence verification.** The cited target `## Pack memory` is present in:

- `CLAUDE.md:93` (`## Pack memory (project-local learnings)`)
- `AGENTS.md:87` (`## Pack memory (project-local learnings)`)
- `GEMINI.md:68` (`## Pack memory (project-local learnings)`)

The "client `x-` preservation rule" referenced in the closing clause is present at `CLAUDE.md:172-174` (under `### Repo conventions`), and trinity-mirrored at `AGENTS.md:145+` and `GEMINI.md:123+`. Cross-reference resolves correctly.

**Shape conformance.** The shipped wording is a faithful superset of architecture §4.4's illustrative shorter shape (lines 238-242) — §4.4 explicitly says BD-149 may use either the §4.4 illustrative wording or the BACKLOG-recommended wording. The implementer correctly chose the BACKLOG version per its authoritative status. Blockquote formatting matches the §4.4 illustrative rendering and visually separates the cross-reference from the surrounding skill-content prose.

### 2.5 Adjacent-scope addition — ACCEPT (in scope, recommend retention)

The implementer added a single-sentence ambiguity tie-breaker paragraph at `PLATFORM-SKILLS.md:601-604`:

> When the suffix is genuinely ambiguous (e.g., a new skill could plausibly be `*-best-practices` or `*-architecture`), choose the suffix that matches the dominant content of the SKILL.md, and record the rationale in the BACKLOG entry that creates the skill.

**Disposition: ACCEPT (in scope).** Rationale:

1. **Architect doc explicitly raises the ambiguity.** §7.10 line 964-967 surfaces the exact ambiguity the tie-breaker resolves: "Why is Swift `best-practices` but C `language`? Why is Python's architecture split into `*-architecture` skills while Swift's is split into `*-architecture-core` + leaf `*-architecture`?" §7.10's recommended disposition documents the convention but does not give authors guidance for borderline cases. The tie-breaker paragraph fills exactly that gap.
2. **Operational, not structural.** It does not introduce a new dimension, suffix, or rule — it operationalizes existing rules for the borderline case. By BD-159 §3.1/§3.2, this is mechanical: no new top-level doc, no new check, no new SKILL.md, no new script.
3. **Single sentence; reversible.** Even if Pack Chat later prefers a strict-spec rendering, removal is one-line trivial. No content elsewhere depends on it.
4. **Records rationale in BD.** The "record the rationale in the BACKLOG entry" clause aligns with the v11 pattern of capturing structural decisions in the creating BD (cf. BD-141, BD-156, BD-157, BD-158 all carrying rationale paragraphs in their Description fields).

The IMPL report flagged this as "optional scope adjacent to the strict spec — flagged here for review" (IMPLEMENTATION-REPORT-BD-149.md §2.2). I concur with the implementer's flagging discipline; my disposition is to keep it.

### 2.6 No out-of-scope edits — PASS

Per IMPL report §3.4 (`git status --short`): one tracked file modified (`project-template/docs/pack/PLATFORM-SKILLS.md`). The six untracked `maintenance-docs/v11-research/*.md` files are out-of-band per prompt and were not touched. No changes outside the target file.

### 2.7 No section-restructure side effects — PASS

The pre-existing `## Extending this file` section (`PLATFORM-SKILLS.md:562-571`) is preserved verbatim — the existing introductory paragraph pointing readers at `ARCHITECTURE-SKILL-DIMENSIONS.md §3 / §4 / §6` is intact at lines 564-571. The new content is **additive**: a new `### Naming convention for new skills` H3 subsection at line 573 plus a closing blockquote at line 606 — both nested under the existing H2. No deletions, no header-level changes, no reordering. IMPL report §3.5 confirms `+39 / -0` (additive only).

### 2.8 validate-pack 30/30 PASS — PASS

IMPL report §3.1 captures `python3 scripts/validate-pack.py` returning "PASSED — all checks clean" with 30/30 PASS. No regression. Markdown-only edit; no script touched.

### 2.9 Maintainability principle (BD-159 §3.1 mechanical-edit conditions) — PASS

Cross-checked against `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.1 conditions:

| §3.1 mechanical signal | BD-149 footprint | Pass |
|---|---|---|
| Existing-dimension fit | Edits an existing PLATFORM-SKILLS.md section; codifies an existing four-suffix convention surfaced in §7.10 | PASS |
| Existing pattern fit | No new skill-organization pattern | PASS (N/A) |
| Existing naming-convention fit | Codifies the convention; introduces no new suffix | PASS |
| Existing validator coverage | No new check; relies on existing 30 checks | PASS |
| Bounded file footprint | 0 new files in pack-product (this report goes to `maintenance-docs/` workflow-artifact scope per `## Pack memory` exemption); 1 edited file (PLATFORM-SKILLS.md); 0 new top-level docs; 0 new scripts; 0 new validate-pack checks | PASS |
| No agent-permission expansion | No edit to "What agents must never modify" / PM-only files / trinity rule | PASS |

**Conclusion:** BD-149 is a mechanical edit under its own §3.1 criteria. No architect pass required for this batch.

---

## 3. Trinity rule check

Not applicable to BD-149 itself — `PLATFORM-SKILLS.md` is not a trinity file. The cross-reference *target* (`## Pack memory` § "Repo conventions") is trinity-mirrored across pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` per BD-159; verified above (§2.4). The reference text wisely names all three trinity files rather than singling out `CLAUDE.md`, which keeps the pointer trinity-symmetric.

---

## 4. Cross-reference integrity (project-wide grep impact)

The new content adds three potential cross-reference surfaces:

- **`### Naming convention for new skills`** — new H3 in PLATFORM-SKILLS.md. Not yet referenced from elsewhere (this is a new heading; no stale references possible).
- **BD-156 / BD-157 / BD-158 citations** — these BDs are Resolved in BACKLOG.md (verified at BACKLOG entries; commits `c2beaa0`, `8c117cf`, `8014186`). Citations match the resolved skill names.
- **BD-155 reference** — BD-155 is Open, blocked on v12 (verified at `BACKLOG.md:3550-3553`); BD-155's File/Symbol line itself references BD-149 ("v11.0 codification (BD-149) lands as documentation-only") so the bidirectional reference is consistent.

No stale references introduced; no existing references need updating.

---

## 5. Maintenance-docs / README / MIGRATION consistency

- **README.md repository layout** — not affected; no files added, moved, or removed.
- **MIGRATION-v10-to-v11.md** — BD-148 already documents skill-model changes; the BD-149 codification is documentation-only ("new skills must follow this convention") and does not change behavior any client would notice in v10→v11 migration. No MIGRATION-doc update required.
- **MERGE-STRATEGY.md** — PLATFORM-SKILLS.md merge-strategy entry already updated by BD-148 to note the v11 reframe. The §"Extending this file" extension is additive and additive-only; standard merge tooling handles it. No update required.
- **`scripts/validate-pack.py`** — no new files, no new directories, no new structural surfaces; validation accounts for all changes (30/30 PASS).
- **BACKLOG.md** — BD-149's BACKLOG entry is `Status: Open` at the time of review (BACKLOG.md:1396) with `Resolved:` blank (line 1401). The implicit-status-flip rule applies: after this APPROVE verdict the batch's final step should flip `Status: Open` → `Status: Resolved` and fill the `Resolved:` line with the commit SHA + summary.

---

## 6. Section-content quality review

A few small observations beyond the success-criteria checklist (none rising to a NIT level requiring a fix):

- **Bullet ordering matches §7.10.** The four bullets appear in the same order as architecture §7.10 line 957-962 (`*-best-practices`, `*-language`, `*-architecture`, `*-patterns`). Consistent.
- **`security-patterns` correctly classified as `*-patterns`.** It is a Tier 0 base skill but its name follows the `*-patterns` suffix; the bullet correctly names it as an example of `*-patterns` (line 595). Tier 0 vs intersection vs trigger orthogonality is a load-mechanism distinction, not a naming-suffix distinction; the bullet does not muddle the two.
- **No restatement of dimension-loading rules.** Per IMPL report §2.3 this was deliberate to avoid duplicating canonical content per the `## Pack memory` no-duplication clause. Confirmed: the new subsection focuses strictly on naming.
- **Blockquote rendering is the correct visual pattern** for a one-line cross-reference — matches architecture §4.4's own illustrative blockquote shape (line 239-242).

---

## 7. Summary disposition

| Concern | Result |
|---|---|
| 1. Four-suffix convention codified with examples | PASS |
| 2. BD-156/157/158 cited as recent `*-patterns` examples | PASS |
| 3. v11.0 no-rename stance + BD-155 follow-on | PASS |
| 4. Maintainability-rule cross-reference (verbatim BACKLOG wording, target headings exist in all 3 trinity files) | PASS |
| 5. Adjacent-scope ambiguity tie-breaker | ACCEPT (in scope, recommend retention) |
| 6. No out-of-scope edits | PASS |
| 7. No section-restructure side effects | PASS |
| 8. validate-pack 30/30 PASS | PASS |
| 9. BD-159 §3.1 mechanical-edit conditions | PASS |

**Verdict: APPROVE.** Ship as-is. After commit, flip BD-149 `Status: Open` → `Status: Resolved` per the implicit-status-flip rule and fill the `Resolved:` line with the commit SHA + a one-line summary citing the codified convention and the BD-159 cross-reference.
