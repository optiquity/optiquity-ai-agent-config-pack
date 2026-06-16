# PACK-REVIEW — BD-221 C6 (Gemini → Antigravity conversion, pack-only)

- **Reviewer:** fresh pack-reviewer (read-only)
- **Branch / HEAD:** `v11-dev` / `79d759115ace3d40d76311ea0845ce3a9a56e382`
- **Regime:** IN-PLACE (cwd = repo root; no `/tmp` handoff dir, no worktree).
  Verified via `git rev-parse HEAD` + `pwd`.
- **Scope reviewed:** the COMBINED parked C6 state (trinity conversion + skill
  moves from coder run 1; manifest fix + skill-body assessment from coder run 2).
- **Date:** 2026-06-16

---

## 1. VERDICT

**CLEAN — C6 is correct, minimal, and in-scope; ship it.** Post-C6 failing set
== baseline `{5,17,18,21,28,39,41,52,55,56,57}` exactly (no Check 46, no new
check); Check 19 + Check 46 both GREEN; trinity parity preserved with
audience-correct conversion; the 11-skill move is byte-preserving; the manifest
fix is the single boundary-investigation record only; and the POQ-C6-2
Task-2-zero decision is independently confirmed CORRECT (the Gemini tokens in
the moved bodies are preserved trinity filenames or byte-identical cross-CLI
shared prose — converting only `.agents` WOULD break parity).

---

## 2. Findings

| # | Severity | File | Evidence | Action |
|---|---|---|---|---|
| — | (none) | — | No BLOCKER / MUST / SHOULD / NIT found. All five verification items pass against independent measurement. | None. |

**Confirmed non-issues (examined, not findings):**

- **N1 — stale `.gemini/` refs in README.md / scripts / supporting-docs / install / `validate-pack.py`.** A repo-wide scan surfaces many references to the moved/deleted pack-self `.gemini/skills/*` and `.gemini/commands/*` paths (e.g. `README.md:94`, `supporting-docs/MIGRATION-v10-to-v11.md:509`, `supporting-docs/INSTALL-PROCEDURES.md:513`, `scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh`, `scripts/lib/detect.sh`, `scripts/persona-contracts/*`, `scripts/tests/*`, `scripts/lib/migrator-core.sh`). **Not a C6 defect** — these surfaces are explicitly assigned to C7 (rest of manifests), C8 (validators), C9 (install plumbing), and the broader BD-221 cross-cutting passes per the C6 contract. They are TRACKED by the C-sequence, and their live-check fallout is already captured in the baseline failing set (Checks 5/17/21/28/39/41/52/55/56/57) — see §3.
- **N2 — `validate-pack.py:1599` `GEMINI_INTRINSIC_H2S` still names `## Gemini CLI operating notes`.** C6 renamed the GEMINI.md H2 to `## Antigravity CLI operating notes` but (correctly) did NOT touch the validator, so Check 18 now flags the renamed H2. This is the intended, tracked Check-18 re-trip the IMPL-REPORT predicted (IMPL-REPORT §5 lines 216–218); C8 updates the allowlist. **Not a C6 defect** — validators are C8's scope.
- **N3 — `review` skill `.agents` ≠ `.claude` (but == `.codex`).** The `.claude/skills/review/SKILL.md` copy carries an extra `[roles: reviewer]` tag + a `Rule-SSOT routing` block absent from `.agents`/`.codex`. This asymmetry is PRE-EXISTING (the `.agents/review` copy is byte-identical to the deleted `.gemini/review` original — a pure move), contains ZERO Gemini tokens, and is unrelated to BD-221. **Not a C6 defect / not a missed conversion** (see §4.4).
- **N4 — `test-fixtures/manifest.txt` not regenerated.** The manifest-regen rule (`regenerate-manifest-v11-surface`) triggers on `pack-ops/` touches, but `manifest.txt` records per-fixture git SHAs computed from `project-template/` content only — it tracks zero pack-self `.gemini/`/`.agents/`/`pack-ops/` paths (`grep -c` → 0). C6 touches only pack-self surfaces, so a regen would be an EMPTY diff (the rule's "when the manifest diff is non-empty" condition is not met). Deferral to C10 is harmless. **Not a C6 defect.**

---

## 3. Baseline-delta confirmation

**Method:** `python3 scripts/validate-pack.py` (full battery, 61 checks);
header-aware parse — each `FAIL:` bound to its `── Check N ──` header via awk
(naive grep would mis-bind). Distinct failing-check numbers sorted unique.

| Property | Target | Measured | Verdict |
|---|---|---|---|
| Distinct failing set | `{5,17,18,21,28,39,41,52,55,56,57}` | `{5,17,18,21,28,39,41,52,55,56,57}` (11) | **PASS** |
| Check 46 absent (orphan restored) | absent | absent — `OK: Check 46 — boundary manifest: 11 surface(s) resolve …` | **PASS** |
| No new check appeared | none | no FAIL on any check `> 57`; Checks 58–61 all OK; highest check seen = 61 | **PASS** |
| Check 19 GREEN | green | `OK: [project-template] All three trinity templates free of body-section scaffolding comments` | **PASS** |
| Check 46 GREEN | green | `OK: Check 46 — boundary manifest: 11 surface(s) resolve … spawn manifest: 7 rule(s) resolve … anti-restate: 0 …` | **PASS** |

Raw tally line: `FAILED — 60 issue(s) found` — 60 sub-failures distributed
across the 11 distinct baseline checks (the count is sub-failures, NOT distinct
checks). The DISTINCT failing-check set is the 11 baseline numbers.

**Re-trip attribution (all baseline NUMBERS, owned by later commits):** Checks
18/21/56 are the direct C6 ripples (H2 rename, `.toml` pack-help parity,
verb-parity surface list) deferred to C8; Checks 5/17/28/39/41/52/55/57 are the
broader `.gemini` agent/config/install surface re-trips owned by C7–C9. None is
a NEW check; all sit in the post-C5 baseline.

---

## 4. Independent verification

### 4.1 Trinity (parity + audience-correct + prose)

- **Pack-root GEMINI.md H2 = `## Antigravity CLI operating notes`** —
  confirmed (`GEMINI.md:543`). The section body is fully converted (session
  verbs `/resume` `/switch` `/fork` `/rewind`; "Antigravity manages context
  automatically"; "Antigravity's subagent mechanism from `.agents-plugin/…`";
  "Antigravity CLI native file write tools").
- **No `## Agent roster` H2 in pack-root GEMINI.md** — confirmed ABSENT (it is
  project-template-only; the pack roster is the converted "Pack agent
  invocation" bullet). Correct pack-audience shape.
- **CLAUDE/AGENTS lock-step co-refs** — `grep "Gemini CLI"` across all three →
  NONE. Antigravity co-refs: CLAUDE.md (`## What this repo is` L16; the
  Trinity-exemption / dynamic-subagent conversions L352/L359–361/L374–376/L381),
  AGENTS.md ("What this repo is" L18), GEMINI.md (the operating-notes section +
  memory note). The dynamic-subagent conversion is present and correct
  (`define_subagent` / plugin-roster, CLAUDE.md L360).
- **Audience-correct asymmetry is sanctioned, not a violation.** Claude-only
  mechanics (Agent tool, `run_in_background`, Agent Teams / SendMessage) are
  correctly KEPT in CLAUDE.md under the explicit trinity-exemption bullet
  (CLAUDE.md L377–381); the three express the SAME shared rules. Per
  `cross-cli-reference-normalization` / ARCHITECTURE-BD-182 §4.1 the conversion
  substitutes the audience-correct value, not a byte-copy — verified.
- **Stale-token allowlist clean.** The only `.gemini`/"Gemini" hits in the
  trinity are: the `GEMINI.md` filename (trinity-member, allowlisted) and the
  global path `~/.gemini/GEMINI.md` (GEMINI.md L337, L547 — documented
  allowlist). No `.gemini/` self-reference outside those two global-path uses;
  no stale `Gemini CLI`.
- **Forward-looking notes are PROSE (Check 19 green).** `grep "<!--|-->"`
  across all three → 0 matches. The forward-looking note uses prose:
  "(Re-verify the exact memory-write verb against `antigravity.google/docs/*`
  before relying on a specific command …)" (GEMINI.md L547). No HTML comment
  introduced.

### 4.2 Skill moves

- **9 `.gemini/skills/` → `.agents/skills/` (content preserved).** `git status`
  shows 9 `D .gemini/skills/*/SKILL.md`; `.agents/skills/` holds the 9 +
  pack-help + pack-startup = 11 SKILL.md (set-equality). Sampled diffs
  (architecture-review, planning, verification-harness) against their git-HEAD
  `.gemini` originals → IDENTICAL (pure move, no content change).
- **2 commands → new skills.** `.gemini/commands/{pack-help,pack-startup}.toml`
  deleted; `.agents/skills/{pack-help,pack-startup}/SKILL.md` present with valid
  frontmatter (`name:` / `description:` / `allowed-tools:`). The `.toml`
  `prompt = """…"""` body → SKILL.md body, `description` → frontmatter, and the
  Gemini TOML `!{bash scripts/pack-help.sh}` → `` !`bash scripts/pack-help.sh` ``
  — an audience-correct conversion. `pack-help/SKILL.md:9` references
  `scripts/pack-help.sh` (so C8's Check-21 conversion will resolve). Neither
  new skill carries any Gemini token.

### 4.3 POQ-C6-1 manifest fix (minimal + correct)

- **`git diff pack-ops/.boundary-pointer-manifest.txt`** shows EXACTLY the
  boundary-investigation record: `surface: .gemini/skills/…` → `.agents/skills/…`
  and `role: Gemini …` → `Antigravity …`. 4 changed content lines = the single
  record only.
- **Check 46 resolves it:** `.agents/skills/boundary-investigation/SKILL.md`
  carries the `BOUNDARY-DEFINITION.md` pointer substring (`grep -c` → 1).
- **Minimality proven:** 0 remaining `.gemini` refs in the manifest; the only
  other skill surface line is `.claude/skills/review/SKILL.md` (L86, a `.claude`
  rule-SSOT routing pointer — NOT a moved skill, untouched, correctly left for
  any later commit). No OTHER moved skill (the 9 + 2) is referenced in this
  manifest. `pack-ops/.spawn-rule-manifest.txt` is UNTOUCHED and contains zero
  moved-skill / `.gemini` references. (The line-41 `documentation`-token hit is
  a header comment, not a surface ref.)

### 4.4 POQ-C6-2 — was Task-2-zero CORRECT? (the key judgment)

**Yes — independently confirmed CORRECT.** Exhaustive enumeration
(`grep -rniE "gemini|\.gemini|@<agent>|@pack-" .agents/skills/`) returns every
Gemini-flavored token in the 11 moved bodies. Every hit falls into exactly two
categories:

- **Category 1 — preserved trinity FILENAMES** (`GEMINI.md` /
  `project-template/GEMINI.md` as a literal trinity-member filename):
  boundary-investigation L18, L70; documentation L7, L18; commit-discipline
  L179, L182, L197, L198, L234. BD-221 does NOT rename trinity files;
  converting these would break the trinity rule + a real-file reference.
  Correct to keep.

- **Category 2 — cross-CLI-shared landscape enumerations** (`.gemini/` inside a
  `.claude/`/`.codex/`/`.gemini/` parallel set; "Gemini" as one of three
  tool-specific examples): boundary-investigation L15, L20; commit-discipline
  L202, L209, L214, L216; implementation-report L74.

**Decisive byte-identity evidence** (full-file `diff`, not line samples): each
of the four skills bearing these tokens is **byte-identical across all three
CLI copies**:

| Skill | `.agents` vs `.claude` | `.agents` vs `.codex` |
|---|---|---|
| commit-discipline | IDENTICAL | IDENTICAL |
| boundary-investigation | IDENTICAL | IDENTICAL |
| implementation-report | IDENTICAL | IDENTICAL |
| documentation | IDENTICAL | IDENTICAL |

Because the bodies are byte-identical shared prose, converting the Category-2
`.gemini/` tokens ONLY in `.agents` would DESYNCHRONIZE it from the unconverted
`.claude`/`.codex` copies and VIOLATE `cross-cli-reference-normalization`.
There are NO audience-correct self-references in the moved bodies (no
`@pack-name` aimed at this copy's own CLI, no "Antigravity CLI" describing this
copy's runtime, no `.agents/` self-path that should have replaced a `.gemini/`
self-path). Therefore **Task-2-zero is the correct disposition**, and POQ-C6-2
(escalate the SYMMETRIC `.claude`+`.codex`+`.agents` landscape normalization to
the BD-221 cross-cutting pass, rather than a unilateral `.agents` edit) is the
right call.

**No missed conversion found.** The one body-level cross-CLI difference among
the 9 moved skills — `review` (`.agents` ≠ `.claude`, but `== .codex`) — is a
PRE-EXISTING Claude-specific `[roles: reviewer]` + Rule-SSOT-routing addendum
with ZERO Gemini tokens; the `.agents/review` copy is byte-identical to the
deleted `.gemini/review` original (pure move). It is unrelated to BD-221 and is
NOT a missed audience-correct self-ref.

### 4.5 Scope

`git status --short` shows EXACTLY: 11 deletions (9 `.gemini/skills/` + 2
`.gemini/commands/`), 3 modified trinity files, 1 modified manifest, `.agents/`
(untracked), and the IMPL-REPORT (untracked). Explicit out-of-scope confirmation
(all → no): `validate-pack.py` (C8), `project-template/`, `init-project.sh`/install
(C9), `test-fixtures/manifest.txt` (C10), `.spawn-rule-manifest.txt` (C7), any
other `.boundary-pointer-manifest.txt` line (C7). All C6 work is pack-only.

---

## 5. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Read-only git only: `git rev-parse HEAD` (`79d7591…`), `git status --short`, `git diff`, `git show HEAD:…`. No state-changing verb run. Single file write = this report at the prompted path. | COMPLIANT |
| **trinity-rule** | Pack-root GEMINI.md H2 = `## Antigravity CLI operating notes` (L543); `grep "Gemini CLI"` across all three → NONE; co-refs converted lock-step (CLAUDE.md L16/L352/L359-361/L374-376/L381; AGENTS.md L18); Claude-only mechanics correctly kept under the explicit trinity-exemption bullet (legitimately asymmetric). The three express the same shared rules. | COMPLIANT |
| **cross-cli-reference-normalization** | Full-file `diff`: commit-discipline / boundary-investigation / implementation-report / documentation are byte-identical across `.agents`/`.claude`/`.codex`. The trinity conversion substitutes audience-correct values (operating-notes section, dynamic-subagent model), not a byte-copy. Task-2-zero PRESERVES cross-CLI parity; converting only `.agents` would VIOLATE this rule — correctly escalated as POQ-C6-2. | COMPLIANT |
| **filename-uniqueness-heuristic / pointer-manifest** | `git diff` of `.boundary-pointer-manifest.txt` = the single boundary-investigation record only (4 content lines); 0 remaining `.gemini`; `.agents/skills/boundary-investigation/SKILL.md` carries `BOUNDARY-DEFINITION.md` (`grep -c` → 1); no other moved skill referenced; `.spawn-rule-manifest.txt` untouched. Fix is minimal + correct. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed EXACTLY C6 (trinity + 11-skill move + one manifest line). `git status` shows no out-of-scope touch (validate-pack.py / project-template / install / manifest.txt / spawn-rule-manifest / other manifest lines all untouched). Verdict led §1; deferred surfaces flagged as confirmed non-issues (N1–N4) with C-sequence owners, not silently fixed. | COMPLIANT |
| **verify-full-ci-suite** | `python3 scripts/validate-pack.py` full battery run; header-aware FAIL→Check parse via awk. Distinct failing set == baseline `{5,17,18,21,28,39,41,52,55,56,57}` (11); no FAIL > 57 (58–61 OK); Check 19 OK; Check 46 OK. (No test-v11-*.sh edit in C6 — docs/skill/manifest surface only; validate-pack is the gating check per the contract, and the manifest fix is exercised by Check 46.) | COMPLIANT |
| **agents-read-rule-docs-in-full** | Read IN FULL: IMPL-REPORT-BD-221-C6.md (365 lines), `/backlog/_rules.md`, `/changelog/_rules.md`, `/backlog/BD-221.md`, CLAUDE.md `## Pack memory` (full, via system context). The dedicated BD-221 commit-slice plan doc was searched (`grep`/`find`) and not present as a standalone PLAN file — the C6 contract is fully specified by the prompt + IMPL-REPORT + BD-221 entry, which were read. No prior PACK-REVIEW-* report read. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, COMPLIANT terminal state for each; no empty evidence; no AMBIGUOUS. | COMPLIANT |

---

*End of PACK-REVIEW — BD-221 C6.*
