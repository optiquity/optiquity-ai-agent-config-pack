# PACK-REVIEW — BD-221 C4 (Client docs conversion, project-only)

## 1. VERDICT

**APPROVE-WITH-FIX** — C4 satisfies the baseline-delta contract exactly
(Check 31 RESTORED green, Check 54 stays green, no new break; post-C4
failing set = `{5,17,18,21,28,39,41,55,57}` as expected) and converts all 7
client docs Gemini→Antigravity cleanly; the ONE required fix is the
`bd-pack-only` leak — the `BD-217 coordination` token in **two** client
HTML comments (MUST). All other claims independently verified true.

- Repo: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
- Branch: `v11-dev`; HEAD: `e8eb0a5d2f061ac53c8c9ab66b10bd81c3dc37b4`
  (post-C3, unchanged — no git/source state mutated by this review)
- Regime: IN-PLACE, UNCOMMITTED (7 ` M` files + the C4 IMPL-REPORT untracked)
- This review is READ-ONLY; the single write is this report.

---

## 2. FINDINGS

| # | Sev | File / loc | Evidence | Action |
|---|-----|-----------|----------|--------|
| F1 | **MUST** | `project-template/docs/pack/OPTIONAL-FEATURES.md:283` AND `project-template/docs/pack/PM-CHAT.md:878` | Two C4-INTRODUCED HTML comments carry a `BD-217 coordination` token in CLIENT content. Confirmed both are NEW (`git diff … | grep '^+'` shows exactly these two `+` lines carry `BD-`). `bd-pack-only-operational-rule`: no pack-self concept — including BD-NNN — may appear in client `project-template/` content. A `BD-217` token in a client doc is a boundary LEAK. The plan's C4 register row mandated the phrase (plan §3 C4 / §5), so the violation is sourced from the plan, not invented — but the rule overrides the register. The coder self-flagged it in the IMPL-REPORT ("visibility flag … not a blocker") and SHOULD-have escalated it to a finding, not a footnote. | **Drop the `BD-217 coordination` phrase from BOTH comments; keep the `antigravity.google/docs/*` re-verify pointer.** E.g. `<!-- RE-VERIFY at impl: Antigravity worktree feature, antigravity.google/docs/getting-started -->`. Route to fix-coder (Pack-Chat triage). NOTE: the plan §3 C4 / §5 register text should ALSO be corrected so a later commit does not re-introduce the token — but the plan is a `/tmp` handoff doc, out of C4's commit scope; surface for Pack-Chat. |
| F2 | NIT | (pre-existing; NOT C4) `PM-CHAT.md:342,344`; `prompts/coder.md:86-87,205-206`; `prompts/reviewer.md:103-104` | `Pack Chat` / `pack-*` / `maintenance-docs/` / `pack-ops/` tokens appear in these lines, but they are PRE-EXISTING (absent from C4's `^+` diff) and the coder.md/reviewer.md instances are the boundary-rule TEXT itself naming the forbidden tokens (legitimate self-reference). Out of C4's introduced scope — flagged for visibility only, NOT charged to C4. The PM-CHAT.md `the Pack Chat` instances (L342/344) are a separate pre-existing question for a future boundary audit (possibly a project-side `bd-pack-only` debt), but they are not C4 deltas. | No C4 action. Optional: open a future audit note for the PM-CHAT.md L342/344 pre-existing `Pack Chat` refs (not BD-221 C4 scope). |

No BLOCKER. No SHOULD beyond the above.

---

## 3. EXPECTED-RED / BASELINE-DELTA CONFIRMATION

`python3 scripts/validate-pack.py` at HEAD `e8eb0a5` with the C4 working-tree
edits applied → **exit 1; "FAILED — 50 issue(s) found"** (RED-by-design; this
is an intermediate-red cluster commit, restored by C8/C9 per plan §4).

**Post-C4 failing set (variant-aware, header-mapped parse of every FAIL line):**

```
{5, 17, 18, 21, 28, 39, 41, 55, 57}
```

| Check | Status post-C4 | In baseline? | Notes |
|---|---|---|---|
| 31 | **GREEN (RESTORED)** | YES (was RED) | The C4 deliverable — REMOVED from failing set ✓ |
| 54 | **GREEN** | n/a | Stayed green ✓ |
| 5 | RED | yes | content axis → C8 (deleted gemini agents) |
| 17 | RED | yes | content axis → C8 (`.env.example` missing) |
| 18 | RED `[project-template]` | yes | content axis → C8 (C3 H2 rename; `## Antigravity CLI operating notes` not yet in `GEMINI_INTRINSIC_H2S`) |
| 21 | RED | yes | content axis → C8 (`.gemini/.env.example` exception) |
| 28 | RED | yes | content axis → C8 (pm-startup `.toml` surface missing) |
| 39 | RED | yes | install-map axis → C9 (orphaned `cmd_update` rows) |
| 41 | RED | yes | install-map axis → C9 (orphaned `_CLIENT_INSTALLED_FILES` rows) |
| 55 | RED | yes | content axis → C8 (deleted gemini agent files) |
| 57 | RED | yes | content axis → C8 (deleted gemini verb-parity surfaces) |

**Delta vs the stated post-C3 baseline `{5,17,18,21,28,31,39,41,55,57}`:**
exactly ONE removal — **Check 31** — and ZERO additions. The post-C4 set is
a strict subset of the baseline (only 31 removed). **No new break introduced.**

- **Check 31 GREEN proof (quoted verbatim):**
  ```
  ── Check 31: Skill-cell consistency (BD-146, v11) ──
    OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 2 rows (header matches)
    OK: PLATFORM-SKILLS.md — total skills: 37 (header sum, inventory row count, and disk count all agree)
    OK: Skill-cell consistency: 37 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts
  ```
- **Check 54 GREEN proof (quoted verbatim):**
  ```
  OK: Check 54 (Guard-A′) — OPTIONAL-FEATURES presence holds across 2 surface(s)
  (pack + project): all 3 mandated tokens (`baseRef`, `bgIsolation`,
  `permissions.deny` recipe) documented in each.
  ```

**Baseline-31-RED soundness (independently reasoned, no git revert needed).**
37 SKILL.md dirs on disk; `pack-help/SKILL.md` exists on disk (pre-C4). Check
31 requires every disk skill to map to exactly one inventory cell. Before the
C4 inventory-row addition the inventory totaled 36 → `pack-help` was an orphan
→ Check 31 RED. The C4 edit added the row → 37 → green. The baseline-includes-31
claim is therefore provably correct; C4 is the commit that clears it.

---

## 4. INDEPENDENT VERIFICATION

### 4.1 Client docs converted (Gemini→Antigravity) — grep-zero confirmed
Per-file grep across all 7 C4 files:
- `Gemini CLI` (the CLI): **0** in every file. ✓
- `.gemini/` workspace path tokens: **0**, except `PM-CHAT.md:926`
  `~/.gemini/GEMINI.md` — the LEGITIMATE global Antigravity context-file path
  (kept per the C3 trinity convention: Antigravity reads the GEMINI.md
  hierarchy). ✓
- Residual lowercase/mixed `gemini` (excluding `GEMINI.md` filename +
  `~/.gemini/GEMINI.md`): **0** in every file. ✓
- Antigravity/`.agents/`/`agy` present in all 7 files (PM-CHAT 21, OPT-FEAT 11,
  PLATFORM-SKILLS 2, pm-chat 4, auditor 4, coder 1, reviewer 1). ✓
- H2 conversion: `## Antigravity CLI — Optional features` at OPTIONAL-FEATURES.md
  L281 (was `## Gemini CLI — Optional features`); the body is honestly
  forward-looking ("Status: Forward-looking — no opt-in steps to run today …
  the pack ships nothing that depends on it yet"). No premature opt-in steps. ✓
- PLATFORM-SKILLS.md `.gemini/skills/`→`.agents/skills/`: 0 residual `.gemini/`. ✓
- `prompts/{pm-chat,auditor,coder,reviewer}.md` converted, 0 `Gemini CLI`. ✓

### 4.2 Check-31 restoration (A1) — inventory honesty confirmed
- `_INVENTORY_SUBSECTIONS` (validate-pack.py L3100) = `["Tier 0 base skills",
  "Dimensional skills", "Trigger-loaded skills", "PM chat operational skill"]`
  — `"PM chat operational skill"` is **singular**.
- PLATFORM-SKILLS.md L486 header = `### PM chat operational skill (2)` — header
  TEXT byte-exact to the constant (singular "skill" preserved; only `(1)`→`(2)`
  bumped). The parser regex keys on the exact header + parenthesized count, so
  this is honest-green, not a faked pluralization. ✓
- `pack-help` row added at L499 with honest classification: "Show all pack
  commands … the `/pack-help` quick reference … | PM chat / any tool user (not
  an agent) |". ✓
- Total bumped: L501 `**Total skills: 37** (… 2 PM chat operational)`. ✓
- Prose generalized L488 "These skills are …" (body text, not regex-parsed —
  safe). ✓
- **`pack-help` classification honest (no faked per-CLI cells):** its SKILL.md
  is a uniform skill (`name: pack-help`, `allowed-tools: Bash`, body runs
  `bash scripts/pack-help.sh`); its own Notes state it "replaces the former
  Gemini-CLI `.gemini/commands/pack-help.toml` slash-command" and installs to
  the workspace `.agents/skills/<name>/SKILL.md` uniformly like every other
  skill. So it is genuinely a uniform PM-chat operational helper (same class as
  `pm-startup`), NOT a per-CLI command → no cross-CLI cell asymmetry, no POQ. ✓
- Check 31 reports `'PM chat operational skill': 2 rows (header matches)` +
  `total skills: 37 … all agree` + `no orphans, phantoms, or double-counts`. ✓

### 4.3 Check-54 token survival
`baseRef`=10, `bgIsolation`=6, `permissions.deny`=4 in the project
OPTIONAL-FEATURES.md (identical to the IMPL-REPORT pre/post counts). Tokens
live in the Claude Code "Isolated parallel agents (worktree isolation)" section
(NOT under the converted Antigravity H2), so the conversion preserved them.
Dedicated test `bash scripts/tests/test-validate-pack-check-54.sh` → **PASS: 3
/ FAIL: 0** ("All tests passed."). No C8 token-repin required. ✓

### 4.4 Scope (project-only)
- `git diff --name-only` = exactly the 7 files, all under
  `project-template/docs/pack/`; `git diff --stat` = `+86 / −57`. ✓
- `scripts/validate-pack.py` / `_INVENTORY_SUBSECTIONS` (C8), trinity
  CLAUDE/AGENTS/GEMINI.md (C6), `test-fixtures/manifest.txt` (C10) — all
  UNTOUCHED (`git diff --name-only | grep …` → none). ✓
- Manifest correctly NOT regenerated (C10-only model, plan F3; the 7 edited
  docs are not manifest-tracked → no drift from deferral). ✓
- HEAD unchanged (`e8eb0a5`); no git state mutated. ✓

### 4.5 Other pack-self leak (beyond the flagged BD-217)
Scan for `maintenance-docs` / `pack-architect|coder|planner|reviewer|docs-researcher`
/ `pack-ops/` / `Pack Chat`: the only **C4-INTRODUCED** pack-self tokens are the
two `BD-217` markers (F1). All other hits (`Pack Chat` in PM-CHAT.md L342/344;
the boundary-rule self-references in coder.md/reviewer.md) are PRE-EXISTING
(absent from the `^+` diff) and out of C4 scope (F2). ✓

---

## 5. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Git verbs used were read-only ONLY: `git rev-parse HEAD` (→ `e8eb0a5d2f061ac53c8c9ab66b10bd81c3dc37b4` before and after), `git status --short`, `git diff [--stat/--name-only]`. No add/commit/push/stash/checkout/reset/restore/apply/worktree/branch/tag. HEAD unchanged. The single file write is this report at the prompted path. `validate-pack.py` ran read-only. | COMPLIANT |
| **bd-pack-only-operational-rule** | `git diff … | grep '^+' | grep BD-` → exactly two C4-added lines, both `BD-217 coordination` HTML comments: `OPTIONAL-FEATURES.md:283` + `PM-CHAT.md:878`. BD-NNN in client `project-template/` content is a categorical leak → reported as F1 (MUST) with the drop-the-phrase/keep-the-doc-pointer fix. No other C4-introduced pack-self token (maintenance-docs / pack-* / pack-ops/ / Pack Chat) found in the 7 files. | COMPLIANT (rule applied; violation found + reported) |
| **ci-guard-design-measure-then-bound** | Measured `_INVENTORY_SUBSECTIONS` (L3100, "PM chat operational skill" singular), disk skill count (37), `pack-help/SKILL.md` existence, the inventory header `### PM chat operational skill (2)` (text byte-exact, count bumped only), the `pack-help` row classification, and total `37`. Confirmed Check 31's parser requirements are honestly satisfied (header matches, counts agree, no orphans) — honest green, not a faked cell. `pack-help` is a uniform skill (Bash/pack-help.sh, installs to `.agents/skills/`), so no per-CLI asymmetry. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed EXACTLY C4 (the 7 `project-template/docs/pack/` files); led with the VERDICT; flagged out-of-scope/pre-existing tokens as F2 (not charged to C4); confirmed validate-pack.py/trinity/manifest untouched. No coverage sprawl. | COMPLIANT |
| **verify-full-ci-suite** | Ran `python3 scripts/validate-pack.py` (full battery, all checks, no `--only-check`); parsed every FAIL line header-mapped (variant-aware: Check 18 `[project-template]` + `[pack-root]`). Quoted the post-C4 failing set `{5,17,18,21,28,39,41,55,57}` + the delta (only 31 removed, no new break) + the Check 31/54 OK banners verbatim. Also ran the dedicated `test-validate-pack-check-54.sh` (3/0) to confirm the OPTIONAL-FEATURES surface edit did not shift Check-54 token presence. | COMPLIANT |
| **agents-read-rule-docs-in-full** | Read IN FULL (direct Read tool, not derived): the C4 IMPL-REPORT (`IMPL-REPORT-BD-221-C4.md`, 363 ln); the plan `PLAN-BD-221-ANTIGRAVITY-CONVERSION-FINAL-v2.md` (452 ln, both pages — incl. §3 C4 at L161-165, §4 cluster-push, §5 register, §6 verification); CLAUDE.md `## Pack memory` (system-reminder full content, incl. the `bd-pack-only`/`P-missed-7` rules); `/backlog/_rules.md` + `/changelog/_rules.md`. Did NOT read any prior `PACK-REVIEW-*` report (none exists for C4; none consulted). | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT for each; no empty evidence; no AMBIGUOUS. | COMPLIANT |

---

*End of PACK-REVIEW-BD-221-C4.md — read-only review, HEAD `e8eb0a5`,
2026-06-15. Verdict: APPROVE-WITH-FIX (one MUST: the BD-217 client-doc leak at
OPTIONAL-FEATURES.md:283 + PM-CHAT.md:878). Baseline-delta contract satisfied
(Check 31 restored green, Check 54 green, no new break). No git/source state
changed.*
