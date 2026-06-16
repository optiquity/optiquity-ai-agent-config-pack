# IMPL-REPORT — BD-221 C3 (Project trinity prose conversion)

**Commit:** C3 — `feat: v11 — BD-221 project trinity prose conversion (project-only)`
**Agent:** pack-coder (fresh, C3). Ran **IN-PLACE** against the parent working tree.
**Branch:** `v11-dev`. **Base HEAD (pre-edit):** `75ce90f` (post-C2).
**Final HEAD (this report):** `75ce90fddbdc0c05780aeaa847aa1bf85c101de2` — NO commit made (agents-never-commit); edits left in the working tree for Pack Chat to stage/commit after the review/fix cycle.
**Regime:** in-place (working tree dirty on exactly the 3 scoped files; no `/tmp` handoff dir named, so no patch-emit/handoff write — report goes to the named parent-tree path).
**Date:** 2026-06-15. **bash:** 3.2.57 (no shell scripts touched in C3).
**`agy --version`:** N/A — C3 touches no executable surface; `agy` is referenced only as prose in the converted trinity. The plugin-bundle source paths and the `agy plugin install` command referenced in prose were landed by C1 and verified present (see "Tree-state preflight").

---

## 1. Scope (exactly plan §3 C3 + Smaller-1 + §5 forward-looking)

Project-only, lock-step across the three **project** trinity files:
`project-template/GEMINI.md`, `project-template/CLAUDE.md`, `project-template/AGENTS.md`.
Nothing else touched. No pack-root trinity, no plugin bundle, no config, no
validators, no install/migrators, no fixtures/manifest.

---

## 2. Tree-state preflight (C1/C2 landed; prose refs validated against the real tree)

| Concept (prose ref I wrote) | Actual on-disk state (post-C2) | Status |
|---|---|---|
| Client plugin bundle `.agents-plugin/optiquity-agents/` | `plugin.json`, `agents/` (16 templates), `RUNTIME-SUBAGENT-PATTERN.md` all present | EXISTS |
| `agy plugin install ./.agents-plugin/optiquity-agents` | matches the RUNTIME-SUBAGENT-PATTERN.md install line landed in C1 | CONSISTENT |
| `.agents/skills/` (skills install target) | C2 established `.agents/` (holds `mcp_config.json`); skills move to `.agents/skills/` per C2/C9 | CONSISTENT |
| `RUNTIME-SUBAGENT-PATTERN.md` fallback | present in the bundle; my GEMINI.md roster body points at it | CONSISTENT |
| old `.gemini/agents/` | already deleted by C1 (`ls` empty) | GONE |

No prose ref points at a path that does not exist post-C1/C2.

---

## 3. Per-file change list

### 3.1 `project-template/GEMINI.md` (+the heaviest edits; intrinsic-H2 owner)

1. **HOW TO USE comment** (top, above first H2 — allowlisted by Check 19): "Gemini CLI context file … loaded by Gemini CLI" → "Antigravity CLI context file … loaded by Antigravity CLI (`agy`) … (Antigravity reads GEMINI.md / AGENTS.md for backward compatibility)"; "Gemini CLI equivalent of CLAUDE.md" → "Antigravity CLI equivalent of CLAUDE.md".
2. **Capability policy:** "Gemini CLI may perform all major engineering tasks" → "Antigravity CLI may perform …".
3. **iOS 26 env override:** `override in .gemini/.env` → `export it in your shell environment, or via the env block of .agents/mcp_config.json` (audience-correct; `.gemini/.env` was deleted in C2).
4. **Skill loading:** `.gemini/skills/<name>/SKILL.md` → `.agents/skills/<name>/SKILL.md`.
5. **Tier 0 installation note:** the 3-CLI install-dir list `(.claude/skills/, .codex/skills/, .gemini/skills/)` → `(.claude/skills/, .codex/skills/, .agents/skills/)`.
6. **Custom skills:** `.gemini/skills/x-<name>/` → `.agents/skills/x-<name>/`.
7. **Project memory** (agent-def file paths): `.gemini/agents/<agent>.md` → `the Antigravity plugin bundle .agents-plugin/optiquity-agents/agents/<agent>.md`.
8. **Phase routing header:** "All three tools (Claude Code, Codex, Gemini CLI)" → "… Antigravity CLI".
9. **Phase-routing invocation note:** "For Gemini CLI, agent-run.sh translates --agent to Gemini's native @agent-name syntax" → "For Antigravity CLI (`agy`), agent-run.sh resolves --agent to the role defined in the plugin bundle (`.agents-plugin/optiquity-agents/agents/<name>.md`) and launches it via Antigravity's subagent mechanism" + inline forward-looking re-verify prose.
10. **Trinity-rule exception comment** (allowlisted opening "Trinity-rule exception"): rationale "Gemini CLI auto-discovers agents via filesystem scan of `.gemini/agents/`" → "The Antigravity CLI agent roster ships as a plugin bundle (`.agents-plugin/optiquity-agents/`) rather than being auto-discovered from a flat agents directory". H2-only-in-GEMINI exception preserved.
11. **`## Agent roster` BODY rewrite** (heading KEPT per Smaller-1): from `.gemini/agents/*.md` auto-discovery + `@agent-name` invocation → plugin-bundle description (`.agents-plugin/optiquity-agents/` = `plugin.json` + 16 `agents/*.md` + `RUNTIME-SUBAGENT-PATTERN.md`), `agy plugin install ./.agents-plugin/optiquity-agents`, `./agent-run.sh agy --agent <name>`, runtime `define_subagent` fallback pointer. 16-agent roster NAMES preserved verbatim. Forward-looking re-verify prose for agent invocation.
12. **H2 rename (Smaller-1):** `## Gemini CLI operating notes` → `## Antigravity CLI operating notes`.
13. **Operating-notes BODY vocabulary conversion:**
    - `/chat save`/`/chat resume` → `/resume` / `/switch` / `/fork` / `/rewind` (Antigravity session-management verbs).
    - `/compress` → "Antigravity manages conversation context automatically; rely on `/fork` and `/rewind`" (Antigravity context handling).
    - `save_memory … ~/.gemini/GEMINI.md` → "Persist facts to your global context file `~/.gemini/GEMINI.md`" + forward-looking re-verify prose on the memory-write verb.
    - `--approval-mode=plan` / Plan Mode → `/permissions` + `request-review` default posture.
    - "Gemini CLI native file write tools" → "Antigravity CLI native file write tools".

### 3.2 `project-template/CLAUDE.md` (lock-step cross-CLI co-refs — audience-correct, NOT byte-copy of GEMINI edits)

1. Tier 0 install-dir list gemini leg `.gemini/skills/` → `.agents/skills/`.
2. Custom-skills gemini leg `.gemini/skills/x-<name>/` → `.agents/skills/x-<name>/`.
3. Project-memory agent-def gemini leg `.gemini/agents/<agent>.md` → `the Antigravity plugin bundle .agents-plugin/optiquity-agents/agents/<agent>.md`.
4. Phase-routing header "Claude Code, Codex, Gemini CLI" → "… Antigravity CLI".
5. Phase-routing invocation note "For Gemini CLI … @agent-name" → Antigravity plugin-bundle resolution + forward-looking re-verify prose.

### 3.3 `project-template/AGENTS.md` (lock-step cross-CLI co-refs — audience-correct)

Same 5 conversions as CLAUDE.md (Tier 0 list, custom skills, agent-def path, phase-routing header, invocation note). The Codex-audience body remains more concise per the AGENTS.md trinity convention.

---

## 4. Measured gemini co-ref counts (before → after; grep-zero residue proof)

`grep -ic gemini` on the pristine (`git show HEAD:<path>`) vs the working-tree file:

| File | before | after | converted |
|---|---|---|---|
| `project-template/CLAUDE.md` | 8 | 3 | 5 |
| `project-template/AGENTS.md` | 9 | 4 | 5 |
| `project-template/GEMINI.md` | 27 | 9 | 18 |

(CLAUDE 8 / AGENTS 9 matches the plan §2/§3 co-ref counts. GEMINI's higher count includes the intrinsic-H2 + Agent-roster body + operating-notes block.)

### Residue allowlist (the after-counts are 100% allowlisted; NO stale tool/path token remains)

A targeted grep for the converted vocabulary tokens (`Gemini CLI`, `.gemini/`, `@agent-name`, `/chat save`, `/chat resume`, `/compress`, `approval-mode`, `save_memory`) across all 3 files returns ONLY:

```
project-template/GEMINI.md:491:- **Cross-session memory:** … `~/.gemini/GEMINI.md` … (Re-verify the exact memory-write verb …)
```

Every remaining `gemini`-matching line is one of:
- the `GEMINI.md` **filename** (header `# GEMINI.md`; `*Copied from: …/GEMINI.md*`; the root-level-files list; the trinity-rule reference to `GEMINI.md`; the "GEMINI.md hierarchy" / "Antigravity reads GEMINI.md / AGENTS.md for backward compatibility" prose) — STABLE-now per §5 register ("`GEMINI.md`/`AGENTS.md` backward-compat (trinity survives)");
- the `~/.gemini/GEMINI.md` **global context path** — STABLE-now per §5 register (global context honored).

Zero lowercase `.gemini/` workspace-path refs, zero `@agent-name`, zero `/chat`/`/compress`/`--approval-mode`, zero "Gemini CLI" tool references survive.

---

## 5. Trinity-parity confirmation (the three express the SAME rules)

Structural parity (H2 lists):

```
CLAUDE H2 count: 26   AGENTS H2 count: 26   GEMINI H2 count: 28
CLAUDE == AGENTS H2 list: True
GEMINI minus 2 intrinsic == CLAUDE: True
GEMINI extra beyond CLAUDE: ['## Agent roster', '## Antigravity CLI operating notes']
```

- CLAUDE.md and AGENTS.md carry an **identical 26-section H2 list**.
- GEMINI.md = those 26 sections + exactly the **2 designed intrinsic H2s** (`## Agent roster`, `## Antigravity CLI operating notes`).
- The ONLY trinity divergence is the Smaller-1 intrinsic-H2 rename, which is the designed-for-C8 condition (the `GEMINI_INTRINSIC_H2S` constant is rewritten in C8).
- Body rules express the same content; the only edits are CLI-specific path/command normalization (audience-correct per `cross-cli-reference-normalization` / ARCHITECTURE-BD-182 §4.1 — each trinity file references its OWN CLI's mechanism) and the GEMINI-only intrinsic sections. **No project rule was dropped or desynced.**

---

## 6. Baseline → post-C3 validate-pack delta (the deliverable verification)

Command: `python3 scripts/validate-pack.py` (general mode), parsed for the set of FAILing check numbers.

- **Baseline (post-C2):** `FAILED — 49 issue(s)`; failing-check set = **{5, 17, 21, 28, 31, 39, 41, 55, 57}** (the 9 expected C1/C2 intermediate-red checks; restored at C4/C8/C9).
- **Post-C3:** `FAILED — 51 issue(s)`; failing-check set = **{5, 17, 18, 21, 28, 31, 39, 41, 55, 57}**.
- **Delta (NEW failing checks):** **{Check 18}** ONLY. **Resolved:** none.

The +2 issue-count rise (49→51) is the 2 FAIL lines under Check 18, both expressing the SAME single H2-parity break:

```
── Check 18 [project-template]: Trinity H2 structure parity (BD-059, BD-181) ──
FAIL: [project-template] GEMINI.md H2 structure diverges from CLAUDE.md/AGENTS.md beyond the allowed Gemini-intrinsic H2s (['## Agent roster', '## Gemini CLI operating notes']):
FAIL:   in project-template/GEMINI.md only (and not in allowed-intrinsic set): ## Antigravity CLI operating notes
```

**Check 18 is the EXPECTED, trinity-H2-parity-related break, restored at C8** (when `GEMINI_INTRINSIC_H2S` is rewritten to include `## Antigravity CLI operating notes`). Check 18 [pack-root] stays OK (C6 owns the pack-root H2). No UNEXPECTED check broke; no CLAUDE↔AGENTS↔GEMINI parity violation (CLAUDE==AGENTS; GEMINI diverges only by the designed intrinsic-H2 set).

### 6.1 Interim defect detected and fixed BEFORE reporting (transparency)

The FIRST post-C3 validate run showed a SECOND break beyond Check 18: **Check 19** (`check_trinity_no_scaffolding_comments`) flagged 5 occurrences of the inline `<!-- RE-VERIFY at impl: … -->` HTML comments I had initially placed in the trinity body. Check 19 bans ANY body HTML comment outside a fixed allowlist (`HOW TO USE THIS TEMPLATE`, `Project addenda go here`, `Trinity-rule exception`, `DENY-LIST-CONTENT-*`). This was a **real defect I introduced**, NOT a trinity-H2 sibling break (it stemmed from new comments, not the H2 rename). **Fix:** converted all 5 forward-looking markers from HTML comments to inline parenthetical PROSE (preserving the forward-looking re-verify signal without a body scaffolding comment). After the fix, Check 19 [project-template] returns `OK` and the delta is Check-18-only. An HTML-comment self-audit confirms every surviving comment in the 3 files starts with an allowlisted opening (0 offenders).

### 6.2 Per-check test results (Check 18 / Check 19 cohort)

- `scripts/tests/test-validate-pack-check-19.sh`: **9 PASS / 0 FAIL** — green (scaffolding-comment fix verified).
- `scripts/tests/test-validate-pack-check-18.sh`: **5 PASS / 2 FAIL**. The 5 PASS groups exercise the check FUNCTION (synthetic within-trinity parity, GEMINI intrinsic carve-out, two-location label threading, Override-9 independence) — all green, proving the function is intact. The 2 FAIL are the SAME single expected break: the test's live-`project-template`-trinity assertion fails because the live GEMINI.md H2 (`## Antigravity CLI operating notes`) no longer matches the still-`Gemini`-shaped `GEMINI_INTRINSIC_H2S` constant. **This test's live-content assertion is in C8's repin cohort** (plan §3 C8: "any test pinning … 18 / the H2 constant — repin each"). EXPECTED, restored at C8 — not a real defect.

---

## 7. FORWARD-LOOKING markers placed (§5 register)

Per §5, unsettled specifics are NOT hard-coded; each carries a re-verify note. Because the trinity body is governed by Check 19 (no body HTML comments), the markers are placed as inline PROSE rather than `<!-- -->` comments:

| FL item (§5) | Location(s) | Form |
|---|---|---|
| Agent invocation (replaces `@agent-name`) | GEMINI.md ×2 (phase-routing note + Agent-roster body), CLAUDE.md ×1, AGENTS.md ×1 | "(Re-verify the Antigravity agent-invocation mechanism against `antigravity.google/docs/subagents` before relying on it; the subagent API is in preview.)" |
| `save_memory` verb → `~/.gemini/GEMINI.md` | GEMINI.md ×1 (operating notes) | "(Re-verify the exact memory-write verb against `antigravity.google/docs/*` before relying on a specific command; the verb name is unconfirmed for the preview CLI.)" |

STABLE-now items hard-coded without a marker (per §5): `agy` binary + `agy plugin install`; the `.agents/skills/<name>/SKILL.md` workspace path; the plugin SOURCE PATH `.agents-plugin/optiquity-agents/`; `~/.gemini/GEMINI.md` global context; the `/resume`/`/switch`/`/fork`/`/rewind` session verbs and `/permissions` (treated as the converged Antigravity vocabulary the plan directs).

---

## 8. Files-changed inventory

| Path | Change type | Line delta (git diff --stat) |
|---|---|---|
| `project-template/GEMINI.md` | modified | +/- per stat: 74 changed |
| `project-template/CLAUDE.md` | modified | 19 changed |
| `project-template/AGENTS.md` | modified | 19 changed |

`git diff --stat`: `3 files changed, 67 insertions(+), 45 deletions(-)`. No new files, no deletions. No file outside `project-template/{CLAUDE,AGENTS,GEMINI}.md` touched (scope guard honored: no validators/`GEMINI_INTRINSIC_H2S`, no pack-root trinity, no plugin bundle, no config, no docs, no install/migrators, no fixtures/manifest).

---

## 9. Boundary discipline check (project-side edits)

All 3 edited files are PROJECT-SIDE (`project-template/`). Per P-missed-7 / `boundary-investigation`:

- **Agent roster / invocation concept** — project-side SSOT investigated: `project-template/docs/pack/PM-CHAT.md` (agent roster) and `project-template/docs/pack/PLATFORM-SKILLS.md` (custom-agent matrix). My edits reference these project-side SSOTs by their project paths (the existing prose already pointed at `docs/pack/PLATFORM-SKILLS.md` § "Custom agents" and `docs/pack/INSTALL-PROCEDURES.md`); I preserved those references and did NOT introduce any pack-only target.
- **Skill loading / install** — project-side SSOT: `docs/pack/PLATFORM-SKILLS.md` + `scripts/init-project.sh` `stage_s4_skills()` (the existing prose's own references). Preserved.
- **NO pack-only reference introduced.** No `pack-ops/` file, no `pack-*` agent name, no `maintenance-docs/`, no capitalized `Pack Chat`, no BD-NNN added to the client trinity (verified by grep — the only "PM chat" mentions are the PRE-EXISTING client-side "PM chat" role, untouched). `bd-pack-only-operational-rule` clean.
- **No boundary discipline STOP triggered** — no edit needed a pack-only target.

---

## 10. Plan deviations

**One, fully resolved, zero net deviation in output.** The plan §5 register specifies the forward-looking markers as `<!-- RE-VERIFY at impl: … -->` HTML comments "(or `#` for non-markdown)". In the trinity body, an HTML comment trips Check 19 (`check_trinity_no_scaffolding_comments`), which is in the C8 cohort but is NOT supposed to break at C3. To keep the C3 delta to the single intended Check-18 break (and avoid introducing a real Check-19 defect), I rendered the forward-looking markers as inline PROSE re-verify notes instead of HTML comments. This preserves the §5 intent (the load-bearing re-verify signal + the doc URL) while respecting the Check-19 contract. No marker content was dropped; the doc URLs are retained. Surfaced here per `scope-deliverables-to-the-ask` (surface, don't silently diverge).

No other deviations.

---

## 11. New POQs

None.

---

## 12. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| GEMINI.md intrinsic H2 renamed → `## Antigravity CLI operating notes` | PASS | §6 H2 list; line 485-equivalent |
| `## Agent roster` heading KEPT; body rewritten to plugin roster + runtime invocation | PASS | §3.1 item 11; 16 names preserved |
| Operating-notes vocabulary converted (`/chat`/`/compress`/`--approval-mode`/`save_memory`) | PASS | §3.1 item 13; §4 residue grep |
| `.gemini/` path refs normalized (skills→`.agents/`, agents→`.agents-plugin/`) | PASS | §4 residue: 0 lowercase `.gemini/` workspace refs |
| CLAUDE.md lock-step co-refs converted (8) | PASS | §4 (before 8 → after 3) |
| AGENTS.md lock-step co-refs converted (9) | PASS | §4 (before 9 → after 4) |
| Audience-correct, NOT byte-identical copy | PASS | §5; CLAUDE/AGENTS use plugin-bundle path, GEMINI uses its own; bodies differ in concision |
| Trinity parity preserved (same rules) | PASS | §5: CLAUDE==AGENTS; GEMINI = +2 intrinsic only |
| Forward-looking markers placed (agent invocation, save_memory) | PASS | §7 |
| Baseline→post-C3 delta = Check 18 ONLY (trinity-H2, restored at C8) | PASS | §6 |
| No UNEXPECTED break / no parity violation | PASS | §6 (delta {18}); §6.1 Check-19 interim defect fixed |
| Scope guard: only the 3 project trinity files | PASS | §8 git diff --stat |
| No git state change (agents-never-commit) | PASS | §13 rule 1; HEAD unchanged `75ce90f` |
| No pack-self leak in client trinity | PASS | §9 |

---

## 13. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Git verbs run were read-only ONLY: `git rev-parse HEAD` (→ `75ce90fddbdc0c05780aeaa847aa1bf85c101de2`, unchanged pre/post), `git status --short`, `git diff --stat`, `git show HEAD:<path>` (to count pristine co-refs). NO add/commit/push/stage/checkout/reset/restore/merge/apply/worktree. Edits left in the working tree; report Written to the named parent-tree path. | COMPLIANT |
| 2 | trinity-rule | §5: CLAUDE.md H2 list == AGENTS.md H2 list (26 sections, byte-identical); GEMINI.md = those 26 + exactly the 2 intrinsic H2s. The 5 cross-CLI co-refs converted in CLAUDE + the 5 in AGENTS are the lock-step parallel of the GEMINI edits. Only divergence = the designed Smaller-1 intrinsic-H2 rename + the GEMINI-only `## Agent roster`. No rule dropped/desynced. | COMPLIANT |
| 3 | cross-cli-reference-normalization | §3.2/§3.3: CLAUDE/AGENTS use the audience-correct plugin-bundle path (`.agents-plugin/optiquity-agents/agents/<agent>.md`) and `.agents/skills/` — NOT a byte-copy of GEMINI's edits; each trinity file references its OWN CLI's mechanism per ARCHITECTURE-BD-182 §4.1. AGENTS body stays more concise per its convention. | COMPLIANT |
| 4 | preflight-stop-means-stop | Emitted ONE PREFLIGHT line only AFTER all edits + baseline-delta verification PASS (delta = Check 18 only; interim Check-19 defect detected and FIXED, not reported as done). No parent stop/halt received. PREFLIGHT reports the baseline→post-C3 delta, not a green claim. | COMPLIANT |
| 5 | edit-in-place-not-full-rewrite | All edits via targeted `Edit` calls (old_string→new_string), zero full-file `Write` of any trinity file. Section map re-confirmed post-edit (§5 H2 list parse + §6 grep + Check-19 self-audit). | COMPLIANT |
| 6 | scope-deliverables-to-the-ask | Exactly C3 (§3 C3 + Smaller-1 + §5 FL). Only the 3 project trinity files touched (§8 `3 files changed`). The §5-HTML-comment-vs-Check-19 conflict was SURFACED (§10), not silently resolved away; no out-of-scope edit. | COMPLIANT |
| 7 | verify-full-ci-suite | Ran `validate-pack.py` baseline AND post-C3; quoted both failing sets + the delta (§6). Ran the two directly-coupled per-check tests (Check 18, Check 19 — §6.2). Confirmed delta = trinity-H2 (Check 18, restored at C8) + the live-trinity Check-18 test assertion (C8 repin cohort); no unexpected/parity break. Green NOT expected at C3 (correctly). | COMPLIANT |
| 8 | rules-applied-verification-block | This table — every prompt rule has quoted/measured evidence + a non-empty terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---
*End of IMPL-REPORT-BD-221-C3.md — pack-coder C3, in-place, base HEAD `75ce90f`, 2026-06-15. Edits in working tree (3 project trinity files); NO commit. Baseline {5,17,21,28,31,39,41,55,57} → post-C3 adds {Check 18} (trinity-H2 parity, restored at C8); interim Check-19 scaffolding-comment defect detected and fixed (markers → inline prose); NO unexpected/parity break.*
