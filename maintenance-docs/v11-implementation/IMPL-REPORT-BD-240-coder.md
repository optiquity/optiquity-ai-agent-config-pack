# IMPL-REPORT — BD-240: Re-frame `graph-first-context` (two-phase: discovery graph-first, grep/Read verification)

**Agent:** `pack-coder` (read-write, isolated worktree — Claude worktree-isolation model).
**Date:** 2026-06-20.
**Executes:** `/tmp/pack-handoff-bd240-plan/PLAN-BD-240-RECONCILED.md` (authoritative edit spec) +
`/tmp/pack-handoff-bd240-arch/DESIGN-BD-240-RECONCILED.md` (rule text + rationale; M-1 = mechanic (c) BOTH).
**Outcome:** All 8 in-scope surfaces edited; all 11 PREFLIGHT gates PASS; `validate-pack.py` exit 0. NO patch produced, NO commit (per the worktree-isolation model — patch is produced only after a reviewer confirms clean and the orchestrator re-engages).

---

## Runtime regime (verified at runtime — ground truth)

| Item | Measured value |
|---|---|
| **pwd** | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab88a213fc61f86ee` |
| **Isolated worktree?** | YES — path is under `.claude/worktrees/` (NOT the canonical `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` working dir). |
| **Worktree HEAD (pre-flight)** | `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` — MATCHES the expected base. |
| **Worktree HEAD (post-edit)** | `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3` — unchanged (no commit; edits live uncommitted in the worktree). |
| **Branch** | `worktree-agent-ab88a213fc61f86ee` (the worktree branch off the canonical HEAD). |

Base correct (HEAD == af73ffb). Proceeded.

---

## Per-task summary (8 surfaces, ONE logical re-framing)

### Surface 1 — `CLAUDE.md` (trinity) — REPLACE shared-core sentence
- **Anchor:** `## Pack memory` → `### Repo conventions` → bullet `**Graph-first context when the knowledge graph exists (BD-225).**`; the sentence `Fall through to grep/Read for:` … `deliberately not in the graph).`
- **Edit:** REPLACED that one flat 5-item fall-through sentence with the design §2.2 two-phase text (byte-identical across trinity). Edited at the STRING boundary — replaced up to and INCLUDING `not in the graph).`; the per-CLI tail (` **Path-injection under worktree isolation …`) on the same physical line is PRESERVED verbatim.
- **Line delta:** the single sentence (was wrapped over CLAUDE.md L645-650 partial) became a ~30-line two-phase paragraph; net +~24 wrapped lines inside the bullet. Opener, G1/G2, CLAUDE-only BD-226 path-injection tail, and `[roles: universal] [rationale: graph-first-context]` tag all UNCHANGED.

### Surface 2 — `AGENTS.md` (trinity) — REPLACE shared-core sentence (byte-identical to #1)
- **Anchor:** same bullet; shared-core sentence (was AGENTS.md L563-568 partial). Per-CLI tail is `The \`--graph\` path is ALWAYS absolute …`.
- **Edit:** REPLACED the shared-core sentence with the SAME §2.2 text (byte-identical to CLAUDE.md). Preserved up to ` The \`--graph\` path is ALWAYS absolute` tail VERBATIM. Did NOT port the CLAUDE-only BD-226 path-injection contract here.

### Surface 3 — `GEMINI.md` (trinity) — REPLACE shared-core sentence (byte-identical to #1)
- **Anchor:** same bullet; shared-core sentence (was GEMINI.md L540-545 partial). Per-CLI tail is `The \`--graph\` path is ALWAYS absolute …`.
- **Edit:** REPLACED with the SAME §2.2 text (byte-identical). Preserved the GEMINI/Antigravity tail VERBATIM. Did NOT port the injection contract.

### Surface 4 — `pack-ops/PACK-MEMORY-RATIONALE.md` `## graph-first-context` "How to apply" — RE-SCOPE (B-1 fix)
- **Anchor:** `## graph-first-context` (heading at L638) → `**How to apply.**` paragraph.
- **Edit (B-1 / BLOCKER-1 FIX, option (a) — opener-INCLUSIVE replace):** REPLACED the run from (and INCLUDING) the existing opener clause `When \`$(git rev-parse --show-toplevel)/graphify-out/graph.json\` exists, query the graph FIRST …` through `… deliberately not in the graph).` with the design §3.2 phase-model text. KEPT the `**How to apply.** ` bold label; the replacement self-supplies ONE `When the graph exists,` clause. Result: single-"When" opener that dovetails into the preserved `If the graph is absent or a query fails …` G1/G2 sentence — NO double-"When" stutter.
- **PRESERVED:** the `## graph-first-context` heading (bijection slug), the `**Why.**` para, worked example, boundary note, `--graph`/`--budget`/backend lines, `**Rejected alternatives.**` para, and the PRE-EXISTING `cross-cli-reference-normalization` + `bd-pack-only` slug citations (those slugs DO exist in the corpus — left intact).

### Surface 5 — `pack-ops/OPTIONAL-FEATURES.md` "When to skip Graphify" — RE-SCOPE
- **Anchor:** `**When to skip Graphify.**` heading → the SECOND `- ` bullet (was L567-571).
- **Edit:** REPLACED that whole bullet (the `exact-string / SSOT-field / uncommitted / whole-file-verbatim → skip Graphify, not the graph` escape-hatch) with the design §3.3 VERIFICATION-framing bullet, including the explicit `(This is precision AFTER discovery, not a reason to skip graph-first DISCOVERY when the graph exists — see the graph-first rule's two-phase model.)`.
- **PRESERVED:** the first bullet (one-off task / one-time build) and the third bullet (fresh clone with no graph) — both legitimate NO-GRAPH cases.

### Surface 6 — `pack-ops/PACK-CHAT.md` graph-injection spawn **bullet** — EXTEND (DIRECT-use)
- **Anchor:** the `- ` LIST BULLET `**Inject the graph path into the prompt (BD-226, Claude-only).**`, ending `See trinity \`## Pack memory\` § "Graph-first context (BD-225)".`
- **Edit:** APPENDED ONE DIRECT-use sentence after the existing "See trinity …" pointer (recall-heavy / blast-radius / inventory spawn ⇒ prompt MUST DIRECT graph use for DISCOVERY + carry `graph-first-context` in Rules-in-force so the Rules-Applied block attests discovery). Paraphrase + name pointer (<60 contiguous chars of the trinity opener candidate). Pure APPEND — existing bullet body unchanged.

### Surface 7 — `pack-ops/PACK-AGENTS.md` graph-injection **bold-headed PARAGRAPH** — EXTEND (DIRECT-use, parity)
- **Anchor (MINOR-2):** the `**Inject the graph path into every spawn prompt (BD-226, Claude-only).**` BOLD-HEADED PARAGRAPH (L62-71) — NOT a `- ` list item — ending `… for the full contract.`
- **Edit:** APPENDED the SAME DIRECT-use sentence as §3.4 at the END of the paragraph body (after `for the full contract.`), before the blank line + `### Separate terminal session`. Paraphrase + name pointer. Pure APPEND — existing paragraph body unchanged.

### Surface 8 — `.claude/agents/pack-docs-researcher.md` — ADD one Responsibilities bullet
- **Anchor:** `Responsibilities:` list; AFTER the `Return concise answers …` bullet and BEFORE the `Do not make file edits unless explicitly asked.` closer.
- **Edit:** ADDED ONE INTERNAL-recall bullet (design §3.6): for an INTERNAL repo recall / blast-radius pass the knowledge graph is the PRIMARY discovery tool when it exists (per trinity § "Graph-first context") — run `graphify query` against the orchestrator-injected `--graph` path FIRST, verify with grep/Read; "doing the whole recall in grep is a recall defect." Name pointer to the trinity rule (not a body copy).
- **PRESERVED:** YAML frontmatter UNCHANGED (`tools: Read, Grep, Glob, WebSearch, Bash` — `Bash` already present, no frontmatter change). No `x-` client contract on this pack agent def.

### VERIFY-only (no edit) — `pack-ops/OPTIONAL-FEATURES.md` §Graphify pointer (§3.7)
- The pointer `The graph-first rule … governs WHEN to prefer the graph and when to fall through to grep/Read` (L373-374) reads TRUE post-edit — the two-phase model is a sharper statement of WHEN, not a change to the pointer's claim. **No edit made** (matches the design's expectation).

---

## Verification commands + results

### The 11 PREFLIGHT grep gates (all PASS)

| # | Gate | Command (essence) | Result |
|---|---|---|---|
| 1 | Trinity shared-core byte-identity | `diff` of `sed -n '/Two phases — the second never vetoes/,/prohibited move, because/p'` across CLAUDE/AGENTS/GEMINI (CLAUDE/AGENTS stripped of indent) | EMPTY diff both pairs — **IDENTICAL** ✅ |
| 2 | Rename-slug grep-ZERO (M-3) | `grep -rln "rename-plans-measure-then-bound"` over the 6 corpus/rationale/reference files | exit 1, **0 hits** ✅ |
| 3 | Tag survival | `grep -c "\[rationale: graph-first-context\]"` + `grep -c "\[roles: universal\] \[rationale: graph-first-context\]"` over trinity ×3 | **1 each** (both forms) ✅ |
| 4 | Bijection slug survival | `grep -c "^## graph-first-context$" PACK-MEMORY-RATIONALE.md` | **1** ✅ |
| 5 | Anti-restate paraphrase hand-check (OPENER) | confirm appended PACK-CHAT/PACK-AGENTS sentences do NOT contain the ≥60-char opener candidate `When a knowledge graph exists, prefer the graph for orientation` | **0 hits** of the opener substring in either append; both appends present (1 each) ✅ |
| 6 | Per-CLI tail preservation | `grep -c "Path-injection under worktree isolation"` (CLAUDE=1; AGENTS/GEMINI=0); `grep -c "The \`--graph\` path is ALWAYS absolute"` (AGENTS/GEMINI=1) | CLAUDE=1, AGENTS=0, GEMINI=0; `--graph` tail AGENTS=1, GEMINI=1 ✅ |
| 7 | Pre-existing rationale citations preserved | `grep -c "cross-cli-reference-normalization"` / `bd-pack-only` in PACK-MEMORY-RATIONALE.md | **2** / **1** (≥1 each) ✅ |
| 8 | Product-clean (scope gate) | `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` | exit 1, **0 hits** ✅ |
| 9 | OPTIONAL-FEATURES skip-list re-scoped | (a) `grep -c "exceptions, not the graph\."`→0; (b) new wording present (`precision AFTER discovery, not a reason to skip\n  graph-first DISCOVERY`, multiline)→FOUND; (c) `grep -c "one-off task\|fresh clone with no graph"`→2 | (a) **0**; (b) **present** (line-wrapped — confirmed via multiline grep + token confirms `precision AFTER`=1, `not a reason to skip`=1); (c) **2** ✅ |
| 10 | validate-pack full PREFLIGHT (BINDING net) | `python3 scripts/validate-pack.py` | **exit 0; "PASSED — all checks clean"** ✅ |
| 11 | Rationale double-"When" stutter grep-ZERO (B-1/G-NEW) | multiline stutter grep → 0; `grep -c "^\*\*How to apply\.\*\* When the graph exists"`→1; old `$(git rev-parse…graph.json\` opener gone | stutter **0**; single-"When" opener **1**; old opener **0** ✅ |

### validate-pack.py (gate 10 detail — the binding net)

- **Exit code: 0** — final line `PASSED — all checks clean`. 239 `OK:` lines; **zero** FAIL/ERROR/WARN.
- **Check 18 [pack-root]** Trinity H2 structure parity: `CLAUDE.md ↔ AGENTS.md H2 structures match (5 sections); GEMINI.md adds 1 intrinsic H2, otherwise matches` — **OK**.
- **Check 45** rule↔rationale bijection: `23 corpus [rationale: slug] pointer(s); 23 rationale ## <slug> section(s); sets are equal (bijection holds, no orphans)` — **OK**. (Confirms the plan's invariant: slug-set UNCHANGED — BD-240 added/removed zero tag + zero heading.)
- **Check 46** anti-restate: `0 verbatim imperative-body restatements across 6 spawn-relevant surface(s) (49 candidate bodies scanned, ≥60 chars)` — **OK**. (PACK-CHAT/PACK-AGENTS appends did NOT trip it.)
- **Check 44** durable-doc concision: OPTIONAL-FEATURES.md `ADVISORY: 576 lines exceeds … 271. Advisory only — not a failure.` — exactly as design N-1 predicted (informational; never gates).
- **Check 63** graphify-out never tracked — **OK** (no graphify-out change).

### Enumerate-encoding-surfaces check
- `grep -rln "Fall through to grep/Read for:\|deliberately not in the graph" scripts/` → exit 1, **0 hits**: no validator/test encodes the old fall-through text (confirms the plan's measurement).
- `grep -rln "Fall through to grep/Read for: exact-string" CLAUDE.md AGENTS.md GEMINI.md pack-ops/` → exit 1, **0 hits**: the old flat-list sentence is GONE from every surface.

### Files-changed inventory (`git status --short` / `git diff --name-only`)

| Path | Change type |
|---|---|
| `CLAUDE.md` | modified |
| `AGENTS.md` | modified |
| `GEMINI.md` | modified |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | modified |
| `pack-ops/OPTIONAL-FEATURES.md` | modified |
| `pack-ops/PACK-CHAT.md` | modified |
| `pack-ops/PACK-AGENTS.md` | modified |
| `.claude/agents/pack-docs-researcher.md` | modified |

Exactly 8 files — the plan's 8-surface set. **No** `project-template/`, **no** `supporting-docs/`, **no** `test-fixtures/manifest.txt`, **no** `.spawn-rule-manifest.txt`, **no** backlog/changelog. New-file count: 0 (all edits are in-place modifications of existing files). HEAD unchanged at `af73ffb…` (no commit).

---

## The §2.2 two-phase text landed (byte-identical across trinity ×3)

For re-application reference, the shared-core replacement text (as rendered with the bullet's 2-space continuation indent) reads:

> **(the G2 fallback).** **Two phases — the second never vetoes the first.** **(1) DISCOVERY / RECALL** — "what are ALL the surfaces related to X / where does Y live / blast radius of Z / what depends on W" — is **graph-FIRST and mandatory when the graph exists**: run a `graphify query`/`path`/`affected` to establish the candidate surface set BEFORE broad tree reads. grep/Read is NOT a substitute for the graph in this phase — an a-priori grep pattern bounds recall to what you already thought to search for, which is exactly the recall the graph exists to widen. **(2) VERIFICATION / PRECISION** — the exact bytes, line counts, or authoritative SSOT VALUE at an ALREADY-IDENTIFIED surface — is grep/Read's job; use it to confirm what discovery surfaced. Fall through to grep/Read (skipping the graph) ONLY for these — each a P2 or out-of-graph need, none a license to skip P1: **(i)** a VERIFICATION read of a named surface (exact bytes/counts — Read/grep AFTER discovery named it); **(ii)** an authoritative SSOT field VALUE (a BD `Status`, the README version table, a `_rules.md` contract — Read the source); **(iii)** freshly-changed / uncommitted files (`git diff`/Read — not yet in the graph); **(iv)** whole-file exact content of a named file (Read — after discovery named it); **(v)** content the graph deliberately does NOT index (archive-dir / excluded-category — Read/grep). A completeness census that must enumerate every literal occurrence (e.g. a rename completeness gate that greps every literal hit to grep-zero) RUNS the grep as its VERIFICATION gate but does NOT replace discovery: when the graph exists, the census runs the graph FIRST to find the candidate surfaces, THEN greps each to grep-zero — "my task is exhaustive enumeration, so I'll grep the whole tree" is the prohibited move, because the graph exists precisely to widen enumeration beyond your a-priori pattern. **(per-CLI tail follows — preserved verbatim).**

(The leading `(the G2 fallback). ` and the trailing per-CLI tail are PRESERVED context, not part of the replaced span; the replaced span is `**Two phases …` through `… your a-priori pattern.` followed by a space.)

---

## Plan deviations

**ZERO.** Every edit follows the plan §3.1-§3.6 exactly; the §3.7 VERIFY-only pointer was verified true (no edit), as the design expected; all measured exclusions (§2) were left untouched.

One execution NOTE (not a deviation): PREFLIGHT gate 9(b) and the gate-1 indent-strip required line-wrap-aware grep technique — the new OPTIONAL-FEATURES wording wraps across a line break (`skip` ends one line, `graph-first DISCOVERY` begins the next with a 2-space indent), so a naive single-line `grep -c "precision AFTER discovery, not a reason to skip graph-first DISCOVERY"` returns 0. Verified PRESENT via a multiline (`grep -Pzo … "\n\s+"`) match plus two token confirms (`precision AFTER`=1, `not a reason to skip`=1) and a direct read of the landed bullet. The content is correct; only the grep had to account for the wrap. Documented for the reviewer so this is not mis-read as a missing edit.

---

## New POQs introduced

**NONE.** No architecture gap surfaced; the design + plan were complete and internally consistent. M-1 was pre-decided as mechanic (c) BOTH (used the §2.2 text verbatim). No open question remained for the coder.

---

## Definition-of-Done checklist

| DoD item | PASS/FAIL |
|---|---|
| All 8 plan surfaces edited per §3.1-§3.6 | PASS |
| Trinity §2.2 text byte-identical across CLAUDE/AGENTS/GEMINI (gate 1) | PASS |
| Per-CLI openers + tails preserved; CLAUDE-only BD-226 injection NOT ported to AGENTS/GEMINI (gate 6) | PASS |
| B-1 fix: no double-"When" stutter in rationale; single-"When" opener (gate 11) | PASS |
| OPTIONAL-FEATURES skip-list re-scoped; one-off + fresh-clone bullets kept (gate 9) | PASS |
| PACK-CHAT + PACK-AGENTS DIRECT-use appended; paraphrase + name pointer, anti-restate-safe (gate 5, Check 46) | PASS |
| docs-researcher INTERNAL-recall bullet added; frontmatter unchanged | PASS |
| `rename-plans-measure-then-bound` slug NOT introduced anywhere (gate 2) | PASS |
| `[rationale: graph-first-context]` tag + `## graph-first-context` heading survive (gates 3, 4); Check 45 bijection 23↔23 | PASS |
| No validator/test encodes the old fall-through text (enumerate-encoding-surfaces) | PASS |
| Product-clean — no `project-template/` / `supporting-docs/` touched (gate 8) | PASS |
| Exactly 8 files changed; no manifest/spawn-rule-manifest/backlog/changelog touched | PASS |
| `validate-pack.py` exit 0, all checks clean (gate 10) | PASS |
| No state-changing git verb run; no patch produced; no commit | PASS |

---

## Rules-Applied Verification Block

| # | Rule (as in CLAUDE.md `## Pack memory`) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Commands run: `git rev-parse HEAD`/`git status`/`git status --short`/`git diff --name-only` (all read-only), `grep`/`sed`/`diff`/`wc`/`find`, `python3 scripts/validate-pack.py` (RO), `mkdir -p /tmp/...`, Edit/Read/Write tools. NO `add`/`commit`/`push`/`stage`/`stash`/`checkout`/`reset`/`apply`/etc. `git rev-parse HEAD` post-edit = `af73ffb5…` UNCHANGED. NO patch produced on return. Sole file writes = the 8 in-scope source edits + this IMPL-REPORT at `/tmp`. | COMPLIANT |
| 2 | preflight-stop-means-stop | Emitted the single PREFLIGHT line (`PREFLIGHT: 8/8 in-scope surfaces edited; verification PASS (11 PREFLIGHT gates + validate-pack exit 0); worktree HEAD af73ffb…; about to Write IMPL-REPORT to …`) ONLY after all 8 edits + all 11 gates + validate-pack exit 0 PASSED. No partial-report path taken (nothing failed). No parent stop message received. | COMPLIANT |
| 3 | edit-in-place-not-full-rewrite | Every surface was a targeted in-place Edit of a named sentence/bullet/paragraph (8 distinct `Edit` calls with exact `old_string` anchors); zero file rewrites. Re-read each region before editing (Read on CLAUDE/AGENTS/GEMINI regions, PACK-MEMORY-RATIONALE, OPTIONAL-FEATURES, PACK-CHAT, PACK-AGENTS, pack-docs-researcher) and confirmed the section map after via grep gates. | COMPLIANT |
| 4 | cross-cli-reference-normalization | The §2.2 shared-core text contains NO per-CLI path/command token (cites generic `graphify query`/`path`/`affected`) → byte-identical IS the parity target. Gate 1 `diff` → EMPTY across all three pairs. Did NOT "normalize" the shared core; did NOT touch per-CLI openers/tails (gate 6: CLAUDE injection tail=1, AGENTS/GEMINI=0; `--graph` tail AGENTS/GEMINI=1). | COMPLIANT |
| 5 | enumerate-encoding-surfaces | `grep -rln "Fall through to grep/Read for:\|deliberately not in the graph" scripts/` → exit 1, 0 hits — no validator/test encodes the old text (confirms plan measurement). Old flat-list sentence GONE from all surfaces (`grep -rln "Fall through to grep/Read for: exact-string" …` → exit 1, 0 hits). validate-pack.py exit 0 confirms all encoding-surface checks (18/44/45/46/62/63) green. | COMPLIANT |
| 6 | graph-first-context (dogfood + the rule being implemented) | This task was a directed in-place edit of an explicitly-enumerated 8-surface set supplied by the plan (every surface named + content-anchored), not an open-ended discovery/recall pass — DISCOVERY was already complete in the plan/design (EE-R8 census). No new blast-radius/inventory question arose that the plan had not already resolved, so no `graphify query` was needed (the injected path `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json` was available had one arisen). All work was P2 VERIFICATION (exact bytes/counts at the named surfaces) — grep/Read is the correct tool for that phase per the very rule being landed. G1/G2 honored implicitly (no graph query attempted ⇒ nothing to fall back from). | COMPLIANT |
| 7 | separate-pack-ops-from-product | `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` → exit 1, 0 hits (gate 8). All 8 edited surfaces are PACK-OPS (pack-root trinity, `pack-ops/*`, `.claude/agents/*`). `git diff --name-only` → exactly 8 pack-ops files, zero product paths. Scope keyword `pack-only` justified. | COMPLIANT |
| 8 | rules-applied-verification-block | This block present; one row per Rules-in-force rule with quoted/measured evidence + terminal conclusion (COMPLIANT/N/A/VIOLATED; no AMBIGUOUS, no empty evidence). | COMPLIANT |

---

*End of IMPL-REPORT-BD-240-coder.md. 8 surfaces edited in the isolated worktree; 11 PREFLIGHT gates PASS; `validate-pack.py` exit 0. NO patch, NO commit — edits left uncommitted in the worktree for the reviewer; the orchestrator re-engages this coder for the `git diff > <handoff>/changes.patch` patch-emit only after the review is clean.*
