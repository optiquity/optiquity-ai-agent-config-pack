# PACK-REVIEW-BD-241 — pre-commit review of the BD-241 implementation (discoverable spawned agents: unique NAMES + Claude REGISTRY + name→agentId find + reconciliation-instance independence + stale cross-CLI claim correction)

**Reviewer:** pack-reviewer (READ-ONLY) · **Date:** 2026-06-20
**Verdict:** **CLEAN with ONE NIT** (1 NIT — cosmetic punctuation in S1; no BLOCKER / MUST / SHOULD). Implementation is ready to commit; the NIT is optional polish at the user's discretion.

---

## 0. Regime confirmation (rule 8 — pwd/HEAD ground-truth)

| Check | Required | Measured | Conclusion |
|---|---|---|---|
| pwd | the commit's live worktree | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a87126bf21d37bf80` | MATCH |
| HEAD | `797b4c5035496605348f4900efd95266de8d34d9` (post-BD-240 base) | `797b4c5035496605348f4900efd95266de8d34d9` | MATCH |
| changed-file set | EXACTLY 9 MODIFIED, nothing else | 9 `M` (below); no `??`, no out-of-scope | MATCH |
| out-of-scope guard | no `backlog/`, `changelog/`, `test-fixtures/manifest.txt`, `.gitignore`, OPTIONAL-FEATURES | `git diff --name-only \| grep -E "OPTIONAL-FEATURES\|BD-241\|backlog/\|changelog/\|.gitignore\|manifest"` → `(none)` | CLEAN |

`git status --short` (verbatim):
```
 M AGENTS.md
 M CLAUDE.md
 M GEMINI.md
 M pack-ops/PACK-MEMORY-RATIONALE.md
 M project-template/AGENTS.md
 M project-template/CLAUDE.md
 M project-template/GEMINI.md
 M project-template/docs/pack/PM-CHAT.md
 M supporting-docs/METHODOLOGY.md
```
Regime is correct. Review proceeded in this worktree.

---

## 1. Three corpus rules — present, correct, audience-correct, tagged

### Bullet A — `spawn-unique-naming` (trinity ×3, `### Agent invocation rules`)
- Tagged `[rationale: spawn-unique-naming]` in all three trinity files (Gate-2 measured: 1 in AGENTS.md, 1 in GEMINI.md; CLAUDE.md shows **2** — L376 is Bullet A's own tag, **L453 is the intentional cross-reference inside Bullet B's body** `(see \`### Agent invocation rules\` \`[rationale: spawn-unique-naming]\`)`, which is design-verbatim and does NOT break bijection — Check 45 reports 26↔26, no orphans).
- Load-bearing clauses byte-identical ×3: `uniqueness is a DISCIPLINE — no platform guarantees it` → `1/1/1` (CLAUDE/AGENTS/GEMINI).
- Audience-correct per CLI (NOT byte-copy): CLAUDE.md "In Claude Code the `name` is the Agent-tool `name` parameter (addressable via `SendMessage({to: name})`)…"; AGENTS.md "In Codex the `name` is the agent `name` field (the `nickname` is display-only)…"; GEMINI.md "On Antigravity address by the known agent ID / named-role type…". The coder added a parallel "; on [other CLIs] use the platform's agent-name field" tail in each (mirroring CLAUDE.md's two-part structure) — a reasonable audience-correct normalization, not a defect.
- **CONCLUSION: COMPLIANT.**

### Bullet B — `spawn-registry-find` (CLAUDE.md ONLY, `### Sub-agent behavior (Claude-only)`)
- Single-surface: `rationale: spawn-registry-find` → CLAUDE.md `1`, AGENTS.md `0`, GEMINI.md `0`. Correct (Claude-only).
- Inserted AFTER `**Agent-team stage lifecycle + per-commit fresh-coder.**` and BEFORE `**Trinity exemption.**` (CLAUDE.md L451-465) — exact placement per plan §2.1 B1.
- All load-bearing clauses present verbatim (CLAUDE.md L451-465): gitignored ledger `graphify-out/.pack-spawn-registry.jsonl`, `NEVER committed — agents-never-commit`, precedence `by NAME → by agentId`, `there is NO message-id addressing primitive`, and the LOAD-BEARING `Consult the registry ONLY after the \`fresh-agent-default\` gate authorizes a re-engage — this fixes HOW-to-find, not WHEN-to-reengage` (L461-462), plus the Claude-only/BD-217 scoping.
- **CONCLUSION: COMPLIANT.**

### Bullet C — `reconciliation-instance-independence` (trinity ×3, `### Agent invocation rules`)
- Tagged `[rationale: reconciliation-instance-independence]` → `1/1/1`.
- Inserted AFTER `**No prior reviews to pack-reviewer.**` in all three (CLAUDE.md L272+; AGENTS.md / GEMINI.md parallel) — correct independence-family placement.
- Load-bearing clauses byte-identical ×3: `NEVER the original author` → `1/1/1`; the docs-researcher exemption `with ONE exception: \`docs-researcher\`` → `1/1/1` (NOTE: the plan §12.2 gate-3 literal `EXCEPT \`docs-researcher\`` returns 0/0/0 — that is a stale PLAN-GATE LITERAL, not a coder defect; the rule text uses "exception:" not "EXCEPT", and the exemption IS present ×3); `REINFORCES \`fresh-agent-default\`` → `1/1/1`. The carve-outs (user override + architect challenge) and the fresh-agent-default reinforcement are all present.
- Audience-correct carve-out (1) per CLI (ONLY this clause differs): CLAUDE.md "in Claude Code via `SendMessage` to that instance — the BD-241 discoverability mechanism then re-finds it; on Codex / Antigravity via the platform's re-engage path"; AGENTS.md "in Codex via the platform's agent re-engage / `resume_agent` path (where its multi-agent messaging is enabled)"; GEMINI.md "on Antigravity via the platform's known-ID re-engage / idle-rewake path". Matches the design substitutions.
- **CONCLUSION: COMPLIANT.**

---

## 2. Three bare-slug rationale sections (Check 45 bijection)

`grep -nE "^## (spawn-unique-naming|spawn-registry-find|reconciliation-instance-independence)$" pack-ops/PACK-MEMORY-RATIONALE.md`:
```
641:## spawn-unique-naming
666:## spawn-registry-find
691:## reconciliation-instance-independence
```
- All three are BARE-SLUG headings (lowercase kebab, nothing after the slug) → match the Check 45 regex `^##\s+([a-z0-9][a-z0-9-]*)\s*$`.
- **Inserted off BD-240's EOF tail (F-3 fix):** section order is `## pack-chat-minor-edits-only` (L603) → R1 (L641) → R2 (L666) → R3 (L691) → `## graph-first-context` (L718). The three new sections sit in the interior block between `pack-chat-minor-edits-only` and `graph-first-context`, NOT at EOF — exactly per plan §3 F-3 placement directive.
- Each section is well-formed Why/How/Rejected and matches the design rationale bodies.
- **CONCLUSION: COMPLIANT.**

---

## 3. Four STRIPs grep-ZERO + five KEEP surfaces untouched

### STRIPs (stale phrasing removed)
| STRIP | Surface | grep literal | Count | Conclusion |
|---|---|---|---|---|
| S1 | CLAUDE.md | `have no peer-messaging equivalent — confirmed` | **0** | REMOVED |
| S2 | PACK-MEMORY-RATIONALE.md | `No SendMessage equivalent (confirmed absent per issue #12462)` | **0** | REMOVED (Antigravity line left untouched, verified — not in diff) |
| S3 | supporting-docs/METHODOLOGY.md | `no peer-messaging analog` / `hub-and-spoke` | **0 / 0** | REMOVED (audience-correct client wording; NO `#12462`/`multi_agent_v2`/`agy`/BD jargon in added lines — verified) |
| S4 | CLAUDE.md (L466-477, PARTIAL) | `none of which have equivalents` / `per research §2.5 / §2.7 / §3.5 / §3.7` | **0 / 0** | STALE LEG REMOVED |

**S4 partial-correction integrity (L418-CORRECTION):**
- Exemption opener PRESERVED: `This sub-section is Claude-specific` → `1` (unique to S4).
- `run_in_background` leg PRESERVED + reframed (L469: "the `run_in_background` parameter (Codex/Antigravity async spawning is implicit/platform-native, not a named parameter)").
- Corrected Agent-tool leg PRESENT: "built against Claude Code's Agent-tool mechanism" — line-wrapped across L467-468 ("built\n  against Claude Code's Agent-tool mechanism"), so the single-line grep returns 0 but `grep -n "Claude Code's Agent-tool mechanism"` → L468 confirms presence (a grep-literal/line-wrap artifact, NOT a content defect — the plan §0.1 NEW-1 anticipated this class). S4 text matches L418-CORRECTION §2 verbatim.

### KEEP surfaces (untouched, grep-still-present)
| KEEP | Surface | grep literal | Count |
|---|---|---|---|
| conditional guard | project-template/docs/pack/PM-CHAT.md | `if your CLI offers no peer-messaging, re-spawn a fresh` | **1** |
| per-project memory | project-template/docs/pack/PM-CHAT.md | `no equivalent per-project memory` | **1** |
| worktree (project) | project-template/docs/pack/OPTIONAL-FEATURES.md | `their worktree story is` | **1** |
| worktree (pack) | pack-ops/OPTIONAL-FEATURES.md | `their worktree story is` | **1** |
| BD-241 provenance | backlog/BD-241.md | (not in edit set) | NOT IN `git diff --name-only` |

The two OPTIONAL-FEATURES files and `backlog/BD-241.md` do NOT appear in `git diff --name-only` (confirmed). **CONCLUSION: COMPLIANT.**

---

## 4. Project surfaces + boundary discipline (P-missed-7) — the highest-risk area

### Project surfaces present
- **CPR1 (Bullet C ×3 project trinity `## Project memory`):** `project-template/{CLAUDE,AGENTS,GEMINI}.md` each carry the project-audience reconciliation bullet inside `## Project memory` (CLAUDE.md L410-419, after the `boundary-investigation` bullet, before `## Phase routing` L421; AGENTS/GEMINI parallel). Fits the section charter ("universal collaboration rules that apply project-wide regardless of agent role"). Audience-correct carve-out (1) per CLI ×3.
- **PR1 (naming, CLI-agnostic):** PM-CHAT.md L512 `**Name every spawn uniquely + descriptively.**` after `### In-session agent spawning` (L454) / `Spawn in the background` (L506).
- **PR2 (Claude-only registry blockquote):** PM-CHAT.md L560 `> **Spawn registry + name→id re-find (Claude-only).**` near the merge-back; says "Codex / Antigravity equivalents are a future pack version" (NOT "BD-217").
- **CPR2 (reconciliation prose, CLI-agnostic):** PM-CHAT.md L517 `**Reconciliation passes use a fresh instance.**` in the spawn section.

### Boundary discipline (P-missed-7) — PROJECT vocabulary only
| Boundary check | Command | Result | Conclusion |
|---|---|---|---|
| No Bullet B mechanism leak into project trinity | `grep -c "pack-spawn-registry\|name→agentId\|spawn-registry-find" project-template/{CLAUDE,AGENTS,GEMINI}.md` | `0/0/0` | CLEAN |
| No pack BD-refs in project trinity | `grep -n "BD-241\|BD-217\|BD-206" project-template/{CLAUDE,AGENTS,GEMINI}.md` | `(none)` | CLEAN |
| No pack-* agent names / pack-ops refs in PM-CHAT added lines | `git diff PM-CHAT.md \| grep ^+ \| grep -iE "BD-\|pack-ops\|PACK-AGENTS\|pack-architect\|pack-coder…"` | `(none)` | CLEAN |
| Claude-only MECHANISM not pushed onto Codex/Antigravity project audiences | project trinity Bullet C uses developer-override + per-platform re-engage; registry mechanism kept to PR2 `(Claude-only)` blockquote with "future pack version" | as designed | CLEAN |

The project trinity correctly drops the pack-specific "the BD-241 discoverability mechanism" phrase (CLAUDE.md pack-root retains it; project-template CLAUDE.md says only "on Claude Code via `SendMessage`"). Project vocabulary throughout ("project agent role", "developer", project roster). **CONCLUSION: COMPLIANT — no leaks.**

---

## 5. BD-240 untouched

- `git diff CLAUDE.md \| grep -i "graph-first"` → `(none)` — no edit to BD-240's graph-first rule in trinity.
- RATIONALE.md `## graph-first-context` body (L718+) unchanged; the only diff at that boundary is the `---` + blank-line separator INSERTED BEFORE it (the divider closing the new R3 section), not an edit to BD-240's content.
- **CONCLUSION: COMPLIANT — BD-240 region intact.**

---

## 6. Two-commit grouping (Check 36)

| Commit | Files | Scope keyword validity |
|---|---|---|
| Commit-1 (pack-ops ONLY) | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `pack-ops/PACK-MEMORY-RATIONALE.md` | `pack-only` VALID (no `project-template/` or `supporting-docs/`) |
| Commit-2 (product) | `supporting-docs/METHODOLOGY.md`, `project-template/{CLAUDE,AGENTS,GEMINI}.md`, `project-template/docs/pack/PM-CHAT.md` | NO keyword (mixed product; `project-only` does NOT fit because S3 is `supporting-docs/`) |

The 9 files partition cleanly — no file straddles both commits. The split is clean for Check 36. (Staging is the orchestrator's job; the partition is verified clean here.) **CONCLUSION: COMPLIANT.**

---

## 7. validate-pack.py (run IN the worktree) — PASS

`python3 scripts/validate-pack.py` → **`PASSED — all checks clean`** (exit 0). Load-bearing lines (verbatim):
```
Check 45 — 26 corpus `[rationale: slug]` pointer(s); 26 rationale `## <slug>` section(s);
  sets are equal (bijection holds, no orphans in either direction).
Check 46 — boundary manifest: 11 surface(s) … ; spawn manifest: 7 rule(s) resolve to `## Pack memory`;
  anti-restate: 0 verbatim imperative-body restatements across 6 spawn-relevant surface(s)
  (52 candidate bodies scanned, >= 60 chars).
Check 18 [project-template]: … (printed OK)
Check 18 [pack-root]: … (printed OK)
```
- **Check 45:** 23↔23 baseline + 3 (A/B/C) → **26↔26**, no orphans. The L453 cross-reference does NOT double-count. PASS.
- **Check 46:** spawn manifest still 7 (no new record — greenfield, per design DROP-P5); anti-restate 0 across 6 surfaces; candidates 49→**52** (the 3 new bullet bodies). PASS.
- **Check 18:** pack-root AND project-template parity both OK. PASS.
- (Advisory only, NOT a failure: `pack-ops/OPTIONAL-FEATURES.md` line-count advisory — pre-existing, untouched by BD-241.)

---

## 8. enumerate-encoding-surfaces — no lock-step validator/test update needed

- `grep -rn "confirmed absent\|hub-and-spoke\|no peer-messaging analog\|none of which have equivalents\|per research §2.5" scripts/` → `(none)` — no test/validator asserts the STRIPPED phrasings.
- No test hardcodes bullet counts in `### Agent invocation rules` / `### Sub-agent behavior`.
- Check 46's candidate count is computed live (`len(candidates)` at validate-pack.py L7741), not a hardcoded assertion — the 49→52 shift is absorbed automatically.
- Consistent with the design's measure-then-bound "NO new CHECK" decision (registry is gitignored runtime state; spawn names + reconciliation-instance choices are runtime decisions — empty matching set). **CONCLUSION: COMPLIANT.**

---

## 9. Findings

### NIT-1 (cosmetic punctuation) — S1 trailing `BD-217.).` in CLAUDE.md L450
**Location:** `CLAUDE.md` L444-450 (the `Trinity exemption:` tail of the `**Agent-team stage lifecycle + per-commit fresh-coder.**` bullet).
**Issue:** the S1 replacement parenthetical ends `…cross-CLI mapping is BD-217.).` — a period INSIDE the closing paren immediately followed by the sentence's own closing paren and a trailing period, yielding `.).`. The host sentence template is `…Claude-Code-specific (<PARENTHETICAL>).`; the design's RECONCILED §1.1 P3 replacement text was quoted WITH its own leading `(` and trailing `.)`, so substituting it into the already-parenthesized slot produced the doubled punctuation. Verbatim:
```
450:  cross-CLI mapping is BD-217.).
```
Compare the cleaner S4 standalone bullet (L477) which correctly ends `cross-CLI mapping is BD-217.` (single period, no stray paren).
**Severity:** NIT — purely cosmetic; does NOT affect any grep gate, Check 45/46/18, Check 36, or meaning. The stale phrasing is fully removed and the corrected premise is present and correct.
**Suggested fix (optional, at user discretion):** change L450 to `…cross-CLI mapping is BD-217.` (drop the inner period + close-paren so the host sentence's `).` is the only terminator) — i.e. the parenthetical content should not carry its own trailing `.)` when dropped into an existing `(...)` slot.
**This is the ONLY finding.** It does not block the commit.

---

## 10. Verdict

**CLEAN with ONE NIT.** Zero BLOCKER, zero MUST, zero SHOULD. The implementation faithfully realizes the PLAN-RECONCILED + DESIGN-RECONCILED + D3-ADDENDUM + L418-CORRECTION: 3 corpus rules (A/B/C) correct + audience-correct + tagged; 3 bare-slug rationale sections off BD-240's tail; 4 STRIPs grep-ZERO (S4 partial-correction preserves the exemption + `run_in_background` leg); 5 KEEP surfaces untouched; project surfaces present with clean P-missed-7 boundary discipline (no pack-only leaks, mechanism not pushed onto project audiences); BD-240 untouched; the 2-commit split partitions cleanly for Check 36; `validate-pack.py` exits 0 with Check 45 = 26↔26, Check 46 anti-restate 0 / 7 records, Check 18 parity ×2. The single NIT (cosmetic `.).` punctuation in S1) is optional polish. Ready to commit.

---

## 11. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks | Every verdict backed by command + verbatim output at HEAD `797b4c5`: `git status --short` (§0), per-slug `grep -c "rationale: …"` (§1), `grep -nE "^## …$"` rationale headings (§2), STRIP/KEEP grep counts (§3), boundary greps `0/0/0` (§4), `git diff CLAUDE.md \| grep graph-first` → none (§5), 2-commit partition `git diff --name-only` (§6), `python3 scripts/validate-pack.py` → `PASSED` with Check 45 = 26↔26 / Check 46 = 7 records 0 restate 52 candidates / Check 18 ×2 (§7), `grep -rn …stale… scripts/` → none (§8). | COMPLIANT |
| separate-pack-ops-from-product / P-missed-7 boundary discipline | §4 + §6: project surfaces use PROJECT vocabulary only — `grep -c "pack-spawn-registry\|name→agentId\|spawn-registry-find" project-template/{CLAUDE,AGENTS,GEMINI}.md` → `0/0/0`; `grep "BD-241\|BD-217\|BD-206" project-template/{CLAUDE,AGENTS,GEMINI}.md` → none; PM-CHAT added lines carry no pack-ops/pack-* refs; the Claude-only registry MECHANISM is confined to the PR2 `(Claude-only)` blockquote ("future pack version"), not pushed onto Codex/Antigravity project audiences. 2-commit split = pack-ops {CLAUDE/AGENTS/GEMINI/RATIONALE} vs product {METHODOLOGY + 4 project} — clean partition. | COMPLIANT |
| cross-cli-reference-normalization | §1: Bullet A + Bullet C per-CLI clauses are audience-correct, NOT byte-copied — CLAUDE/AGENTS/GEMINI carry distinct name-field / re-engage-path sentences while the load-bearing bodies are byte-identical (`uniqueness is a DISCIPLINE…` 1/1/1; `NEVER the original author` 1/1/1; `REINFORCES \`fresh-agent-default\`` 1/1/1). S3 METHODOLOGY uses client-audience wording with NO `#12462`/`multi_agent_v2`/`agy` jargon (verified absent in added lines). | COMPLIANT |
| enumerate-encoding-surfaces | §8: `grep -rn …stripped-phrasings… scripts/` → none; no test hardcodes bullet counts; Check 46 candidate count is live `len(candidates)` (validate-pack.py L7741). No validator/test needs a lock-step update — confirmed by the clean validate-pack run. | COMPLIANT |
| graph-first-context | Queried the INJECTED `--graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` (not my own worktree toplevel — which under isolation has no `graphify-out/`). Returned only fixture/provenance nodes (rule-corpus concept not a graph node) → G2 fallback to grep/Read of the worktree for all actual edits, the correct primary tool for this prose/rule-corpus BD. | COMPLIANT |
| agents-never-commit / per-action-approval-sub-agents | Read-only git only (`git rev-parse HEAD`, `git status --short`, `git diff`, `git diff --name-only`). ZERO state-changing git verbs. ZERO codebase edits/patch. Sole filesystem write = this review report at `/tmp/pack-handoff-bd241-impl/PACK-REVIEW-BD-241.md`. No patch produced (RO). | COMPLIANT |
| rules-applied-verification-block | This table — per-rule, quoted/measured evidence, terminal COMPLIANT for each; includes the graph-query-ran row below; no empty-evidence rows. | COMPLIANT |
| graph-query-ran (evidence row) | `graphify query "agent invocation rules sub-agent behavior reconciliation registry spawn naming" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` → `Traversal: BFS depth=2 … 15 nodes found`, all `pack-reviewer` agent + tracker-fixture `IMPLEMENTATION-PLAN.md` provenance nodes (zero rule-body nodes) → G2 fallback applied. | COMPLIANT |

---

*End PACK-REVIEW-BD-241. Read-only pre-commit review; no patch produced; no state-changing git verb run; sole write = this report. Verdict: CLEAN with ONE NIT (cosmetic S1 punctuation). validate-pack.py exit 0 (Check 45 = 26↔26, Check 46 = 7 records / 0 restate / 52 candidates, Check 18 pack-root + project-template). 2-commit split partitions cleanly. Ready to commit.*
