# PACK-REVIEW — BD-240: Re-frame `graph-first-context` (two-phase; discovery graph-first, grep/Read verification)

**Reviewer:** `pack-reviewer` (READ-ONLY) — pre-commit review of the uncommitted BD-240 implementation.
**Date:** 2026-06-20.
**Verdict:** **CLEAN — ready for the orchestrator to re-engage the coder for the patch.**

## Regime confirmation (runtime ground-truth)

| Item | Expected | Measured | OK |
|---|---|---|---|
| pwd | the BD-240 worktree | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab88a213fc61f86ee` | ✅ |
| HEAD | `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` | `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` | ✅ |
| Commit state | uncommitted (no commit) | HEAD unchanged after review; `git status --short` = 8 ` M` rows, no staged/committed | ✅ |
| Changed-file set | the 8 expected, nothing else | exactly the 8 below | ✅ |

**Changed files (8, all ` M`, uncommitted):**
```
 M .claude/agents/pack-docs-researcher.md
 M AGENTS.md
 M CLAUDE.md
 M GEMINI.md
 M pack-ops/OPTIONAL-FEATURES.md
 M pack-ops/PACK-AGENTS.md
 M pack-ops/PACK-CHAT.md
 M pack-ops/PACK-MEMORY-RATIONALE.md
```
No product (`project-template/` / `supporting-docs/`), no backlog/changelog, no `test-fixtures/manifest.txt`, no `.spawn-rule-manifest.txt`. Regime correct — proceeding with review.

---

## Verification results (independently re-measured at HEAD af73ffb)

### V1 — §2.2 two-phase text present + correct in trinity ×3, M-1 = (c) BOTH — **PASS**
`git diff` of CLAUDE/AGENTS/GEMINI shows the flat 5-item fall-through sentence replaced by the §2.2 two-phase block in all three. The block carries BOTH M-1 mechanics:
- **(a) structural census re-bind** — present verbatim: *"when the graph exists, the census runs the graph FIRST to find the candidate surfaces, THEN greps each to grep-zero"*.
- **(b) anti-rationalization sentence** — present verbatim: *"'my task is exhaustive enumeration, so I'll grep the whole tree' is the prohibited move, because the graph exists precisely to widen enumeration beyond your a-priori pattern."*

The 5 fall-throughs are re-scoped to P2/out-of-graph as items **(i)–(v)** ("each a P2 or out-of-graph need, none a license to skip P1"); items (i) and (iv) are explicitly bound to "AFTER discovery named it." No phantom 6th item. Matches DESIGN §2.2 / PLAN §3.1 exactly.

### V2 — Trinity byte-identity boundary — **PASS**
Shared-core block byte-identical across the three:
```
diff <(sed -n '/Two phases — the second never vetoes/,/prohibited move, because/p' CLAUDE.md) <(...AGENTS.md)  → exit 0 (empty)
diff <(...AGENTS.md) <(...GEMINI.md)                                                                          → exit 0 (empty)
```
Per-CLI tails UNTOUCHED and correctly divergent — the CLAUDE-only BD-226 path-injection tail was NOT ported:
```
grep -c "Path-injection under worktree isolation"  CLAUDE.md → 1   AGENTS.md → 0   GEMINI.md → 0
grep -c 'The `--graph` path is ALWAYS absolute'                AGENTS.md → 1   GEMINI.md → 1
```
The replace landed exactly at the in-line string boundary `…not in the graph). ` — CLAUDE resumes with `**Path-injection under worktree isolation`, AGENTS/GEMINI resume with `The \`--graph\` path is ALWAYS absolute`. The per-CLI openers are untouched (diff hunks begin after `(the G2 fallback).`). Boundary discipline (R-3) honored.

### V3 — B-1 stutter fix in PACK-MEMORY-RATIONALE.md — **PASS**
The "How to apply" opener was re-scoped LEFTWARD (not appended beside), yielding ONE clean clause:
```
grep -n "When .*graph.*exists" pack-ops/PACK-MEMORY-RATIONALE.md
  → 652: **How to apply.** When the graph exists, DISCOVERY/RECALL ("what relates to X /
grep -c "graph.json` exists, *When the graph exists" …  → 0   (double-When stutter absent)
grep -c "^\*\*How to apply\.\*\* When the graph exists" …  → 1  (single corrected opener)
```
The `**How to apply.** ` bold label is preserved; the replacement self-supplies the single "When the graph exists" clause and dovetails into the preserved G1/G2 sentence (`If the graph is absent or a query fails…`). No stutter, no orphaned dependent clause.

### V4 — OPTIONAL-FEATURES.md "When to skip Graphify" re-scoped — **PASS**
Old escape-hatch bullet gone; new VERIFICATION-precision bullet present; both legitimate NO-GRAPH bullets kept:
```
grep -c "exceptions, not the graph"  OPTIONAL-FEATURES.md  → 0   (old phrasing removed)
grep -n "precision AFTER discovery"  OPTIONAL-FEATURES.md  → L572 (new wording present; the
   "skip graph-first DISCOVERY" continuation wraps to L573 — verified by Read of L564-576)
grep -c "one-off task\|fresh clone with no graph" …        → 2   (both legit G1 bullets retained)
```
The re-scoped bullet frames the items as "precision AFTER discovery, not a reason to skip graph-first DISCOVERY when the graph exists — see the graph-first rule's two-phase model." Coherent with the re-framed trinity rule; no surviving contradiction.

### V5 — PACK-AGENTS.md + PACK-CHAT.md DIRECT-use additions are paraphrase + name-pointer (<60 contiguous verbatim chars) — **PASS**
Both append the SAME recall-heavy DIRECT-use sentence as a paraphrase ending in the rule NAME `graph-first-context`. Anti-restate hand-check against the first-120-char trinity OPENER candidate (the actual Check 46 target — `[:120]`):
```
longest contiguous whitespace-normalized overlap = 18 chars  (' / blast-radius / ')   → well under 60
```
Binding net: validate-pack Check 46 ran clean (V9). PACK-AGENTS.md append landed at the END of the bold-headed PARAGRAPH (after `…for the full contract.`), not at a non-existent `- ` list boundary (MINOR-2 honored); PACK-CHAT.md append landed at the end of the `- ` list bullet (after the BD-225 pointer).

### V6 — pack-docs-researcher.md INTERNAL-recall bullet — **PASS**
One Responsibilities bullet added after the "Return concise answers…" bullet and before the "Do not make file edits…" closer. Names the trinity rule by reference (`per trinity \`## Pack memory\` § "Graph-first context"`), directs `graphify query` against the orchestrator-injected `--graph` path FIRST, and frames "the whole recall in grep" as a recall defect. YAML frontmatter unchanged (`Bash` already in `tools:`); no `x-` client contract; mechanical one-bullet add (`skill-agent-maintenance-mechanical` satisfied).

### V7 — Slug grep-zero — **PASS**
```
grep -rln "rename-plans-measure-then-bound" CLAUDE.md AGENTS.md GEMINI.md \
  pack-ops/PACK-MEMORY-RATIONALE.md pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md  → exit 1 (zero hits)
```
The memory-only slug (M-3) was NOT introduced into any corpus/rationale/reference file — plain-language phrasing used instead. Pre-existing legit slug citations preserved: `cross-cli-reference-normalization` → 2, `bd-pack-only` → 1 in the rationale section.

### V8 — Product-clean (pack-only scope) — **PASS**
```
grep -rln "graph-first\|graphify" project-template/ supporting-docs/  → exit 1 (zero hits)
```
All 8 surfaces are pack-ops (pack-root trinity, `pack-ops/*`, `.claude/agents/*`). The `pack-only` scope claim is justified; `separate-pack-ops-from-product` holds.

### V9 — validate-pack.py full run IN THE WORKTREE — **PASS (exit 0)**
```
python3 scripts/validate-pack.py  → EXIT CODE: 0
PASSED — all checks clean
```
Checks of interest (quoted from the run):
- **Check 18** (Trinity H2 parity, pack-root + project-template) — OK (no H2 heading change; edit is inside an existing `### Repo conventions` bullet).
- **Check 45** — "23 corpus `[rationale: slug]` pointer(s); 23 rationale `## <slug>` section(s); sets are equal (bijection holds, no orphans)." Slug set undisturbed.
- **Check 46** — "anti-restate: 0 verbatim imperative-body restatements across 6 spawn-relevant surface(s) (49 candidate bodies scanned, >= 60 chars)." The DIRECT-use appends did not trip it.

### Enumerate-encoding-surfaces (lock-step) — **PASS (none required)**
No validator/test/fixture hardcodes the old fall-through sentence:
```
grep -rln "Fall through to grep/Read for: exact-string"        scripts/ test-fixtures/ tests/  → no hits
grep -rln "whole-file exact content\|archive-dir / excluded-category" scripts/ test-fixtures/  → no hits
```
The plan measured no encoding surface needing a lock-step update; independently re-confirmed. Check 46's surface SET (`_CHECK_46_ANTI_RESTATE_SURFACES`) and Check 45's bijection logic are content-agnostic to this body text, so no validator edit is owed.

### Graph-first dogfood (G1/G2) — ran
```
graphify query "graph-first-context rule propagation surfaces …" --graph \
  /Users/david/Developer/.../graphify-out/graph.json --backend claude-cli --budget 1500
  → "BFS depth=2 | 27 nodes found"  (coarse docs-researcher/BD-185/IMPL-REPORT cluster)
```
G1 satisfied (graph present at the INJECTED path — not recomputed from the worktree toplevel, where `graphify-out/` is absent). Graph is built at PRE-edit HEAD and coarse for exact bytes (G2), so the edit verification leaned on Read/grep of the worktree files — exactly the discovery-then-verify split this BD designs.

---

## BD-240 acceptance-criteria coverage (BD-240 L18)

| Criterion | Status | Evidence |
|---|---|---|
| Rule re-framed: DISCOVERY/RECALL graph-first, grep/Read = VERIFICATION layer | ✅ | §2.2 two-phase text in trinity ×3 (V1) |
| Fall-throughs no longer swallow recall-critical enumeration | ✅ | 5 items re-scoped to P2/out-of-graph (i)–(v); census re-bound + anti-rationalization (V1) |
| docs-researcher recall emphasis explicit | ✅ | pack-docs-researcher.md INTERNAL-recall bullet (V6) |
| spawn-prompt-direction + Rules-Applied-attestation DECIDED + documented | ✅ | DIRECT-use sentence on PACK-CHAT.md + PACK-AGENTS.md; attest rides existing `rules-applied-verification-block`, no new CI check (V5; DESIGN §4.3) |
| Propagated to trinity ×3 with Claude-only BD-226 path-injection caveat intact | ✅ | byte-identity + tail preservation (V2) |
| `[rationale: graph-first-context]` bijection + reference surfaces lock-step | ✅ | Check 45 23↔23 equal (V9); tags survive 1/1/1 |
| `.spawn-rule-manifest.txt` | ✅ (measured-out) | DESIGN §3.7 / PLAN §2 override the entry premise measure-then-bound — graph-first-context is not a manifest record; untouched; Check 46 reference-resolution green |
| `validate-pack` green | ✅ | exit 0 (V9) |
| architect-designed (not Pack-Chat-authored) | ✅ | DESIGN + PLAN reconciled docs; edits match the spec |

All criteria covered. Note the `.spawn-rule-manifest.txt` premise in the entry (L12/L18) is correctly OVERRIDDEN by the design's measure-then-bound finding — this is a documented, justified deviation, not a gap.

---

## Findings

**None.** No BLOCKER / MUST / SHOULD / NIT. The implementation matches the PLAN and DESIGN on every surface, every PREFLIGHT gate passes on independent re-measurement, and `validate-pack.py` is green (exit 0). The boundary discipline (trinity byte-identity of only the shared core; per-CLI tails preserved; CLAUDE-only injection NOT ported) is exact.

**Verdict: CLEAN.** Ready for the orchestrator to re-engage the coder to produce the reviewed-clean patch (`git diff > <handoff>/changes.patch`). No patch produced by this reviewer (RO); no edits; no state-changing git verb run.

---

## Rules-Applied Verification Block

| Rule (Rules-in-force) | Verification evidence (quoted/measured at HEAD af73ffb) | Conclusion |
|---|---|---|
| empirical-evidence-blocks | Every verdict backed by a quoted command + output: `git diff` excerpts (V1/V2); `diff <(sed…)` → exit 0 (V2); `grep -c "Path-injection…"` → 1/0/0 (V2); stutter greps → 0/1 (V3); slug grep `exit 1` (V7); product grep `exit 1` (V8); `python3 scripts/validate-pack.py` → `EXIT CODE: 0`, `PASSED — all checks clean` + Check 18/45/46 OK lines (V9). HEAD `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` recorded; conclusion CLEAN. | COMPLIANT |
| enumerate-encoding-surfaces | `grep -rln "Fall through to grep/Read for: exact-string" scripts/ test-fixtures/ tests/` → no hits; `grep -rln "whole-file exact content\|archive-dir / excluded-category" scripts/ test-fixtures/` → no hits. No validator/test encodes the edited body; Check 45/46 logic is content-agnostic to this text. No lock-step validator/test update owed. | COMPLIANT |
| graph-first-context | Ran the graph FIRST at the INJECTED path: `graphify query "…" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` → "BFS depth=2 \| 27 nodes found". G1 satisfied; graph coarse (built at pre-edit HEAD) → G2 fall-through to Read/grep for the actual edited bytes. | COMPLIANT |
| separate-pack-ops-from-product | `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` → exit 1 (zero hits). All 8 edited files are pack-ops surfaces. `pack-only` scope holds. | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | Commands run: `git -C … rev-parse HEAD` / `status --short` / `diff` (RO), `grep`/`sed`/`diff`/`python3` (RO), `graphify query` (RO), Read, one `mkdir -p /tmp/...`, and this report Write. No state-changing git verb; no patch; no edit to any repo file; HEAD unchanged (`af73ffb…`). Sole filesystem write = this report at `/tmp/pack-handoff-bd240-impl/PACK-REVIEW-BD-240.md`. | COMPLIANT |
| rules-applied-verification-block | This block present; one row per Rules-in-force rule with quoted evidence + terminal conclusion (no AMBIGUOUS); includes the graph-query-ran row. | COMPLIANT |

---
*End of PACK-REVIEW-BD-240.md — verdict CLEAN; validate-pack exit 0; no patch produced (RO).*
