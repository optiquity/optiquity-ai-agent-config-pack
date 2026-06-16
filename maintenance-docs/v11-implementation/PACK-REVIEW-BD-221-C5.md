# PACK-REVIEW — BD-221 C5 (+ A2 fix) — pack-self plugin bundle + project-side ref-qualification

- **Reviewer:** fresh pack-reviewer (no prior PACK-REVIEW-* read)
- **Target:** BD-221 C5 pack-self bundle + the POQ-C5-1 A2 ref-qualification fix (combined, parked IN-PLACE, uncommitted)
- **Branch:** `v11-dev` — **HEAD:** `f0952b6d82ed67b0e2988ad0787e7b4a773aba40` (post-C4)
- **Date:** 2026-06-15
- **Regime:** in-place (read-only on codebase; single write = this report)

---

## 1. VERDICT

**CLEAN — APPROVE both scopes for separate commit (pack-only bundle + project-only A2 refs).** The expected post-C5(+A2) failing set matches EXACTLY ({5,17,18,21,28,39,41,52,55,56,57}); Check 43 is GREEN (the A2 fix restored it); the delta vs the post-C4 baseline is exactly {52,56} (→ restored at C8). The pack-self bundle is a genuinely SEPARATE artifact from C1's client bundle (no byte-copy, distinct pack-developer audience), preserves the 5 names exactly and the RO/RW two-class model, and carries the FORWARD-LOOKING markers. The A2 fix qualifies the 4 firing refs to the CLIENT bundle path with path context (not allowlist suppression), touches no validator, and introduces no pack-self concept into client docs. The two scopes are cleanly separable (disjoint path prefixes). No out-of-scope (C6/C8/C9/C10) surface touched. Zero git state change. No findings above NIT.

---

## 2. Findings

| Sev | File | Evidence | Action |
|---|---|---|---|
| — | — | No BLOCKER / MUST / SHOULD findings. | — |
| NIT | (process, not code) | POQ-C5-1 (Check 43 dual-bundle collision) was surfaced correctly by the C5 coder and resolved by the A2 fix (qualify-not-allowlist). The underlying PLAN GAP remains: the planner's §4 break-inventory never anticipated Check 43 nor assigned it a restoring step. The A2 fix landed the remediation, but the plan document itself is still un-amended. | Pack Chat: note the plan gap for the record (the realized fix supersedes it); no code action — already remediated in-tree. NOT a defect in C5/A2 output. |

No findings require a fix-coder pass. The lone NIT is a bookkeeping observation about the planner doc, not the reviewed change-set.

---

## 3. Expected-RED confirmation (header-aware)

**Command:** `python3 scripts/validate-pack.py` → `EXIT=1`, summary `FAILED — 56 issue(s) found`.

**Parse method:** each `FAIL:` line associated with its nearest preceding `── Check N ──` header (strict `^FAIL:` match — validate-pack emits failures at column 0). Naive `grep -i fail` over-counts: it falsely tags Check 61's OK banner (`... zero misplaced fixture tests`) because the word "fail" never appears but a loose `FAIL` token in the summary/registry banners can mis-bind; the strict column-0 `FAIL:` parse yields exactly 56 lines == the summary count, validating the parse.

**Actual failing set (header-aware):**
```
{5, 17, 18, 21, 28, 39, 41, 52, 55, 56, 57}
```
**Expected post-C5(+A2) set:** `{5, 17, 18, 21, 28, 39, 41, 52, 56, 55, 57}` → **MATCH = True.**

Per-check FAIL counts (post-fix): `{5:3, 17:1, 18:2, 21:1, 28:1, 39:5, 41:5, 52:5, 55:16, 56:1, 57:16}` (sum = 56, == summary).

| Requirement | Result | Evidence |
|---|---|---|
| Set == expected exactly | ✅ | actual == expected (set equality, above) |
| **Check 43 GREEN** | ✅ | L300–301: `OK: Check 43 — 157 project-side / client-installed file(s) walked; zero pack-internal bare cross-references (... + 8 same-dir-legit + 129 client-installed-legit ...)`. 43 NOT in failing set. |
| Delta vs post-C4 baseline {5,17,18,21,28,39,41,55,57} = {52,56} | ✅ | new breaks = {52,56}; nothing else added; no baseline check flipped |
| **52** present (`check_pack_rw_ro_two_class`, → C8) | ✅ | L344–348: 5× `FAIL: Check 52 — agent file .gemini/agents/pack-*.md not found (measured pack set is 5 agents × 3 CLIs)` |
| **56** present (`check_destructive_git_verb_parity`, → C8) | ✅ | L357: `FAIL: Check 56 (Guard-C) — verb-parity surface .gemini/agents/pack-coder.md not found (measured enumeration set is 10 surfaces)` |
| No unexpected new break (esp. no Check 43) | ✅ | only {52,56} are new; Check 43 went 4 FAIL → GREEN via A2 |

**Cause attribution of the {52,56} breaks** is correct and confined to C5's pack-agent-dir deletion (both checks fail on the now-absent `.gemini/agents/pack-*.md` representative paths). They are the plan's named C5 hard breaks, restored at C8 by re-expressing the measured set to the plugin roster. ✅

---

## 4. Independent verification

### 4a. Working-tree state matches the claimed two-scope change-set

`git status --short` + `git ls-files --others .agents-plugin/` (IMPL reports excluded):

- **Pack-only (C5 bundle):** 5 ` D` rows `.gemini/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md`; untracked `.agents-plugin/pack-agents/` = exactly 7 files (`plugin.json`, `RUNTIME-SUBAGENT-PATTERN.md`, `agents/pack-{5}.md`).
- **Project-only (A2):** 3 ` M` rows under `project-template/` (`GEMINI.md`, `.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md`, `.agents-plugin/optiquity-agents/agents/auditor.md`).
- HEAD unchanged: `git rev-parse HEAD` = `f0952b6...` (no commit).

### 4b. Pack-self bundle: SEPARATE from C1 (`pack-project-separation-of-concerns`)

- **Byte-copy check** — every pack bundle file (7) × every C1 client bundle file (18) via `cmp -s`: **zero matches** ("(no BYTE-COPY pairs — all distinct)"). NOT a byte-copy of C1's `optiquity-agents` templates. ✅
- **Distinct bundle name:** `plugin.json` → pack = `"name": "pack-agents"`; client = `"name": "optiquity-agents"`. ✅
- **Distinct audience:** pack bundle carries pack-developer vocabulary throughout (`pack-ops/PACK-AGENTS.md`, `/backlog/`, `/changelog/`, `maintenance-docs/`, Pack Chat, `project-template/`); per-file hit counts {RUNTIME:4, docs-researcher:3, reviewer:5, coder:25, architect:11, planner:5}. pack-architect description = "pack architecture and design decisions — file structure, naming conventions, cross-tool parity, migration strategy, version planning." The C1 client bundle carries NONE of the pack-self vocabulary (`grep -l "pack-ops/PACK-AGENTS|Pack Chat|/backlog/BD-"` over `optiquity-agents/` → empty). ✅
- **plugin.json description self-declares pack-internal:** "... NEVER shipped to client projects — pack-internal tooling only." ✅

### 4c. Names preserved EXACTLY + RO/RW two-class model

- Filenames + `name:` frontmatter both = `pack-architect / pack-coder / pack-docs-researcher / pack-planner / pack-reviewer` (5/5 identical to the deleted originals; confirmed against `git show HEAD:.gemini/agents/pack-*.md`). No renames. ✅
- **Two-class model preserved:** new `pack-coder.md` = "**Source-write within scope.** ... read-write (RW) agent"; the other 4 = "**Read-only.** ... read-only (RO) agent." All 5 reference `pack-ops/PACK-AGENTS.md` § "Two agent classes" and carry "You NEVER run a state-changing git verb." Matches the deleted originals' class assignment exactly. ✅
- **Roles faithfully adapted (not stubs):** line counts 86/191/84/88/88 + 99 (RUNTIME) = 636 total; pack-coder carries 21 RW-emit/boundary/PREFLIGHT/`P-missed-7`/in-place/isolation references. ✅
- **FORWARD-LOOKING markers present** on every template: line-1 HTML comment `<!-- RE-VERIFY at impl: plugin agents/ inner template schema ... gemini-cli #27305, antigravity.google/docs/cli-plugins -->`, line-5 `# RE-VERIFY at impl: model IDs — reference the Antigravity default model; do not pin a Gemini model string`, plus `plugin.json` `comment-RE-VERIFY` field. HTML comments are legitimate here (bundle files, NOT trinity). ✅

### 4d. A2 ref-qualification: 4 refs qualified to CLIENT bundle path; Check 43 GREEN

`git diff` (project-side) confirms the 4 firing refs now carry the `.agents-plugin/optiquity-agents/<basename>` (CLIENT) path with surrounding prose preserved:

1. `RUNTIME-SUBAGENT-PATTERN.md:7-8` — bare `` `plugin.json` `` → `` `.agents-plugin/optiquity-agents/plugin.json` `` ("in this directory" preserved; line wrapped).
2. `agents/auditor.md:36` — bare `` `RUNTIME-SUBAGENT-PATTERN.md` `` → `` `.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` `` ("in this plugin" preserved).
3. `GEMINI.md:458` — bare `` `plugin.json` `` → `` `.agents-plugin/optiquity-agents/plugin.json` ``.
4. `GEMINI.md:459` — bare `` `RUNTIME-SUBAGENT-PATTERN.md` `` → `` `.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` ``.

- **Check 43 GREEN** (validate-pack L301) — the 4 ambiguous refs now resolve unambiguously to the single client candidate; `same-dir-legit` count = 8, `client-installed-legit` = 129. ✅
- **Path-context qualification, NOT allowlist suppression** (`filename-uniqueness-heuristic`): `git diff --stat scripts/validate-pack.py` → empty; `_CHECK_43_ALLOWLIST` untouched. The structurally-required collision (`plugin.json` ecosystem-fixed; `RUNTIME-SUBAGENT-PATTERN.md` plan-mandated in both bundles) is exempt from the no-collision preference precisely because its prose refs now carry path context — the rule's prescribed remedy. ✅

### 4e. Scope separability + no out-of-scope edits

- **Disjoint path prefixes** — pack-only = `.agents-plugin/pack-agents/*` + `.gemini/agents/pack-*.md`; project-only = `project-template/*`. No file appears in both scopes; they commit cleanly as a `pack-only` commit + a `project-only` commit. ✅
- **No C6/C8/C9/C10 surface touched:** `git status --short` over `scripts/`, `pack-ops/`, pack-root trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`), `test-fixtures/`, `project-template/scripts/init-project.sh` → empty. No validator(C8) / pack-root-trinity(C6) / install(C9) / manifest(C10) edits. ✅
- **Manifest regen N/A:** the `.agents-plugin/` bundle is not yet wired into `init-project.sh` (no fixture flow), so `test-fixtures/manifest.txt` is unaffected — consistent with the plan's C10-only manifest directive and the A2 report's `regenerate-manifest-v11-surface` N/A note. (Flagged for whichever later C-step wires `.agents-plugin/` into install — not this change-set.) ✅

### 4f. No pack-self leak into client docs (`bd-pack-only-operational-rule`)

- The qualified targets are CLIENT-bundle paths (`.agents-plugin/optiquity-agents/...`) in CLIENT docs (`project-template/...`). `grep -rn "pack-agents" project-template/` (excluding `/backlog/`) → no hits: the project-side refs never point at the pack-self `pack-agents` bundle. ✅
- The pack-self bundle legitimately carries `pack-*` names — it IS pack content (pack-root, declared "NEVER shipped to client projects"), not client deliverable. ✅

---

## 5. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Read-only git only: `git rev-parse HEAD` → `f0952b6...` (unchanged); `git status --short`, `git diff`, `git ls-files --others`, `git show HEAD:...`. No `add`/`commit`/`rm`/`mv`/`checkout`/`apply` or any state-changing verb run. Single file write = this report at the prompt-specified path. | COMPLIANT |
| **pack-project-separation-of-concerns** | `cmp -s` over all 7×18 pack-vs-C1 pairs → "(no BYTE-COPY pairs — all distinct)"; bundle name `pack-agents` ≠ `optiquity-agents`; pack-developer vocab present in all 6 pack files, absent from the client bundle (`grep -l "pack-ops/PACK-AGENTS|Pack Chat|/backlog/BD-"` over `optiquity-agents/` empty). The two commit scopes have disjoint path prefixes → cleanly separable. | COMPLIANT |
| **filename-uniqueness-heuristic** | A2 qualifies the 4 colliding-basename refs with the client-bundle path context (`git diff` shows `plugin.json`→`.agents-plugin/optiquity-agents/plugin.json` etc.), NOT an allowlist suppression: `git diff --stat scripts/validate-pack.py` empty, `_CHECK_43_ALLOWLIST` untouched. The structurally-required collision (ecosystem-fixed + plan-mandated names) is the exempt category whose prose refs now carry path context per the rule. | COMPLIANT |
| **bd-pack-only-operational-rule** | Qualified targets = `.agents-plugin/optiquity-agents/...` (client bundle) in `project-template/...` (client docs); `grep -rn "pack-agents" project-template/` (excl `/backlog/`) → no hits — no pack-self path/concept introduced into client docs. Pack-self bundle legitimately carries `pack-*` names (pack-root content, "NEVER shipped to client"). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed EXACTLY C5 + the A2 fix; led with the VERDICT; the only out-of-scope observation (plan-doc gap) flagged as a NIT, not silently actioned. No edits proposed to anything outside the change-set. | COMPLIANT |
| **verify-full-ci-suite** | Ran full `python3 scripts/validate-pack.py` (no `--only-check`). Header-aware strict-`FAIL:` parse → `{5,17,18,21,28,39,41,52,55,56,57}` (56 lines == summary). Check 43 GREEN (L301 banner quoted); 52 (L344-348) + 56 (L357) present → C8; delta vs baseline = {52,56}; no unexpected break. Set == expected exactly. | COMPLIANT |
| **agents-read-rule-docs-in-full** | Read in full: IMPL-REPORT-BD-221-C5.md, IMPL-REPORT-BD-221-C5-A2-FIX.md, backlog/BD-221.md, CLAUDE.md `## Pack memory` (in context). Plan §3 C5 / §4 break-inventory exist only as planner output held by the orchestrator (no on-disk PLAN-BD-221 file — confirmed via `find . -name "*221*" | grep -i plan` empty); the C5 spec was reconstructed from the two IMPL-REPORTs + BD-221 entry. No prior PACK-REVIEW-* report read. | COMPLIANT |
| **rules-applied-verification-block** | This table: per-rule, quoted/measured evidence, terminal COMPLIANT (no empty evidence, no AMBIGUOUS). | COMPLIANT |

---

*End of PACK-REVIEW-BD-221-C5.md — read-only review, working-tree HEAD `f0952b6`, 2026-06-15. Verdict: CLEAN — approve the pack-only bundle commit + the project-only A2 ref-qualification commit. Expected-red contract met exactly; Check 43 green; {52,56}→C8. No fix-coder pass required (lone NIT is a plan-doc bookkeeping note, already remediated in-tree).*
