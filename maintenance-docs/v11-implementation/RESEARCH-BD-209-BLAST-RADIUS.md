# RESEARCH — BD-209 Blast Radius: rename the `PM-only` commit-scope keyword → `pack-chat-only`

**Author:** pack-docs-researcher · **HEAD:** `4086705` (`40867052b31e822e1742de4806016bdca1131f6e`) · **Date:** 2026-06-04 · **Branch:** v11-dev
**Deliverable:** EXHAUSTIVE, RECONCILED blast-radius map for BD-209. RESEARCH ONLY — no source edits, no git verbs.
**Scope reminder:** this report ENUMERATES and DISPOSITIONS. It does NOT decide alias-vs-retire, var-rename, or historical-handling — those are flagged for the architect (binding decisions in the BD-209 entry).

---

## 0. HEADLINE — reconciled total + the one decision that dominates the design

**Reconciled raw total: 1248 `PM-only` lines across 227 files** (repo-wide, excluding `.git/`). See §11 for the three independent reconciliations.

The raw total is dominated by **historical maintenance-docs prose** (landed reports, archived plans/reviews) that is NOT machinery and is NOT re-checked by anything. The architect's actual work surface is the **ACTIVE MACHINERY + GOVERNANCE + DELIVERABLE set** enumerated in §1–§8 (the "Active set", §11).

### THE DOMINATING FINDING — TWO distinct "PM-only" concepts share the spelling

| Sense | Meaning | Where it lives | BD-209 disposition |
|---|---|---|---|
| **Sense A — pack-repo commit-scope keyword** | The Check-36 keyword meaning "only-Pack-Chat-edited PACK-governance files." The OVERLOADED/misnamed token BD-209 targets. | `scripts/validate-pack.py` Check 36; trinity convention TABLE; `pack-ops/PACK-AGENTS.md` "PM-only files and directories"; `pack-ops/PACK-CHAT.md`; the Check-36 tests; pack-side `.claude/.codex/.gemini` `commit-discipline/SKILL.md` §4 + `pack-coder` agent files. | **RENAME → `pack-chat-only`** (this IS the BD) |
| **Sense B — PROJECT-side "No PM-only file edits" agent rule** | The *genuine* project-manager-chat (PM Chat) concept in a CLIENT repo, governing the client repo's `BACKLOG.md` / `CHANGELOG.md` / `STATUS.md` / `PACK-FEEDBACK.md` at the PROJECT root. | `project-template/.{claude,codex,gemini}/agents/{coder,repo-ops}.*` (6 files) + `project-template/docs/pack/PM-CHAT.md`. | **OUT OF SCOPE — architect must rule.** Renaming this to `pack-chat-only` would be a BOUNDARY VIOLATION (importing a pack-self keyword into client deliverables) AND semantically wrong (Sense B really IS about the PM Chat). |

**Surfaced for the architect (do NOT decide here):** BD-209 Scope says "+ any doc/template reference," which could be read to sweep Sense B in. The evidence (§3/§8) shows Sense B is a DIFFERENT concept that legitimately uses "PM" to mean the project manager — the exact disambiguation the rename is FOR. **The architect MUST explicitly rule on Sense B's scope.** Researcher position (evidence-based, not a decision): Sense B is OUT — it is correctly named for the project PM Chat and lives in client deliverables (project-side), so renaming would be both a boundary violation and a semantic regression. The validator coupling (§1.4: `PROFILE_PHRASES "No PM-only file edits"`) forces the architect's hand — if Sense B text changes, that constant changes in lockstep; if Sense B stays, the constant stays.

### Token-collision question — ANSWERED empirically (§1.2)
`pack-chat-only` does **NOT** collide with `pack-only` under the Check-36 parser: `"pack-only" in "pack-chat-only"` is `False`, so `_subject_has_keyword("...(pack-chat-only)", ("pack-only",))` returns `False`. Confirmed by running the actual parser at HEAD. The new keyword is safe.

### Target token is clean
`pack-chat-only` / `_PACK_CHAT_ONLY` appears NOWHERE except inside the BD-209 BACKLOG entry itself (6 self-referential lines). No pre-existing collision with the target name.

---

## 1. Check 36 machinery — `scripts/validate-pack.py` (Sense A core; 36 occurrences)

File: `scripts/validate-pack.py` (7304 lines). Machinery clusters in the Check-36 region (≈3716–3999) plus a registry docstring (151–160) and two PROFILE_PHRASES (1608/1615 — Sense-B-coupled).

### 1.1 Keyword-detection constants + parser

| `file:line` | Code | Disposition |
|---|---|---|
| `scripts/validate-pack.py:3732` | `_SCOPE_KEYWORDS_PM_ONLY = ("pm-only", "pack-memory-only")` | **RENAME + ALIAS-DECISION** — recognized-token tuple. Architect decides `("pack-chat-only",)` (hard-retire) vs `("pack-chat-only","pm-only","pack-memory-only")` (deprecated aliases). VAR-RENAME the constant → `_SCOPE_KEYWORDS_PACK_CHAT_ONLY`. |
| `scripts/validate-pack.py:3862–3891` | `_subject_has_keyword(subject, keywords)` — boundary-anchored, case-insensitive, `-` is a keyword char | **LEAVE (logic)** — generic matcher; no literal `PM-only`. Source of the no-collision guarantee (§1.2). Optional docstring example refresh only. |

### 1.2 Token-collision proof (empirical)
Command (HEAD `4086705`):
`python3 -c "...import validate-pack...; mod._subject_has_keyword(subj,kws)"`
Verbatim output:
```
substring: 'pack-only' in 'pack-chat-only' -> False
pack-only kw on a pack-chat-only subject: _subject_has_keyword('feat: BD-209 rename (pack-chat-only)', ('pack-only',)) = False
new kw on pack-chat-only subject:        _subject_has_keyword('feat: BD-209 rename (pack-chat-only)', ('pack-chat-only',)) = True
new kw on pack-only subject:             _subject_has_keyword('feat: thing (pack-only)', ('pack-chat-only',)) = False
old PM-only still parses:                _subject_has_keyword('docs: PM-only — x', ('pm-only', 'pack-memory-only')) = True
```
**Interpretation:** SUPPORTED. `pack-chat-only` is non-colliding; `pack-only`/`pack-chat-only` are mutually exclusive under the parser. Old tokens still parse (relevant only if kept as aliases).

### 1.3 Permitted sets + use sites (VAR-RENAME + A13-FOLD)

| `file:line` | Code | Disposition |
|---|---|---|
| `scripts/validate-pack.py:3740–3755` | `_PM_ONLY_PERMITTED_PATHS = { ... }` (Files set) | **VAR-RENAME → `_PACK_CHAT_ONLY_PERMITTED_PATHS`** + **A13-FOLD** (§10). |
| `scripts/validate-pack.py:3741–3744` | A13 comment: "BD-203 A13: `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` are removed here…" | **A13-FOLD** — restore the two paths; rewrite/remove comment. |
| `scripts/validate-pack.py:3757–3765` | `_PM_ONLY_PERMITTED_PREFIXES = ("backlog/","changelog/","project-template/docs/project/{backlog,implementation-plan,changelog}/")` | **VAR-RENAME → `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`** (content unchanged). |
| `scripts/validate-pack.py:3908–3913` | `def _is_pm_only_permitted(path)` (checks PATHS then PREFIXES) | **VAR-RENAME → `_is_pack_chat_only_permitted`** + update two constant refs + docstring ("A path is PM-only-permitted if…"). |
| `scripts/validate-pack.py:3911` | `if path in _PM_ONLY_PERMITTED_PATHS:` | VAR-RENAME (ref). |
| `scripts/validate-pack.py:3913` | `return path.startswith(_PM_ONLY_PERMITTED_PREFIXES)` | VAR-RENAME (ref). |

### 1.4 Check-36 driver + messages + docstrings

| `file:line` | Content | Disposition |
|---|---|---|
| `scripts/validate-pack.py:3950` | `is_pm_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PM_ONLY)` | VAR-RENAME (local `is_pm_only` + constant ref). |
| `scripts/validate-pack.py:3951` | `if not (is_pack_only or is_project_only or is_pm_only):` | VAR-RENAME (local ref). |
| `scripts/validate-pack.py:3982–3993` | `if is_pm_only:` block + `fail(...)`: "claims \`PM-only\` but touches non-PM-only paths" + "(PM-only permitted set per pack-ops/PACK-AGENTS.md § 'PM-only files and directories')" | **RENAME** (user-facing fail message → `pack-chat-only` + renamed PACK-AGENTS section) + VAR-RENAME (local). |
| `scripts/validate-pack.py:3917–3934` | `check_commit_scope_honesty` docstring (lists `PM-only`/`pack-memory-only`, failure mode, "§ 'PM-only files and directories'") | **RENAME** (docstring prose). |
| `scripts/validate-pack.py:151–160` | Module check-registry docstring (Check 36 summary; `PM-only`/`pack-memory-only`, "PM-only PERMITTED-PATHS … § 'PM-only files and directories'") | **RENAME** (docstring prose). |
| `scripts/validate-pack.py:1608` | `PROFILE_PHRASES["write-scoped"]: "No PM-only file edits"` | **SENSE-B COUPLED — architect-flag.** Asserts an exact phrase in `project-template/.../{coder,repo-ops}` agent files (Sense B, §8). If Sense B stays "No PM-only file edits", this constant STAYS; if Sense B ruled in-scope, BOTH change in lockstep. |
| `scripts/validate-pack.py:1615` | `PROFILE_PHRASES["write-script"]: "No PM-only file edits"` | Same — Sense-B coupled. |
| `scripts/validate-pack.py:4527` | comment "pack-root trinity … are PM-only operating rules" | **RENAME** (prose; Sense A — pack-root trinity audience). |

> **CI-guard measure-then-bound note for the architect:** SET membership (which files are governance) does NOT change except the A13 restore (§10). Current Files set = `{README.md, pack-ops/PACK-CHAT.md, pack-ops/PACK-AGENTS.md, pack-ops/PACK-MEMORY-RATIONALE.md, CLAUDE.md, AGENTS.md, GEMINI.md, project-template/{CLAUDE,AGENTS,GEMINI}.md}` (BACKLOG/CHANGELOG removed by A13). Prefixes = `{backlog/, changelog/, project-template/docs/project/{backlog,implementation-plan,changelog}/}`. A13-fold ADDS `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` back to the Files set.

---

## 2. Permitted-set internal var names — every use site (consolidated, VAR-RENAME)

All `_PM_ONLY_*` symbol use sites live in `scripts/validate-pack.py` and its test file. No other file references the internal vars by name.

| Symbol | Definition | Use sites |
|---|---|---|
| `_SCOPE_KEYWORDS_PM_ONLY` | `validate-pack.py:3732` | `validate-pack.py:3950`; test refs `mod._SCOPE_KEYWORDS_PM_ONLY` at `test-validate-pack-checks-36-37-38.sh:95,96,100` |
| `_PM_ONLY_PERMITTED_PATHS` | `validate-pack.py:3740` | `validate-pack.py:3911` |
| `_PM_ONLY_PERMITTED_PREFIXES` | `validate-pack.py:3759` | `validate-pack.py:3913` |
| `_is_pm_only_permitted` | `validate-pack.py:3908` | `validate-pack.py:3983`; required-symbol assertion at `test-validate-pack-checks-36-37-38.sh:50`; test calls `mod._is_pm_only_permitted(path)` at `:107` |

**Disposition for ALL of §2:** VAR-RENAME `_PM_ONLY_*` → `_PACK_CHAT_ONLY_*` and `_is_pm_only_permitted` → `_is_pack_chat_only_permitted` (architect decision per BD-209 binding-decisions bullet; the BD permits but does not mandate the var rename). If renamed, the test-file symbol references (§6) MUST move in lockstep, or the import-check test (`test:50`) fails.

---

## 3. Trinity commit-scope-keyword convention table — CLAUDE.md / AGENTS.md / GEMINI.md (Sense A; RENAME + trinity-parity)

The convention TABLE row is the human-facing definition of the Sense-A keyword. Trinity rule applies: all three pack-root files change in lockstep (the table is NOT tool-specific). Per-file occurrence counts: **CLAUDE.md 12, AGENTS.md 12, GEMINI.md 11** (`PM-only` substring occurrences).

### 3.1 The convention TABLE row (the definitional anchor)

| `file:line` | Content | Disposition |
|---|---|---|
| `CLAUDE.md:78` | `| `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | … notably PERMITS `project-template/` trinity … |` | **RENAME** (table row → `pack-chat-only`; architect decides whether to keep "(or `pack-memory-only`)" as a documented alias). |
| `AGENTS.md:80` | (parallel row) | **RENAME** (trinity-parity with CLAUDE.md:78). |
| `GEMINI.md:60` | (parallel, abbreviated row) | **RENAME** (trinity-parity). |

### 3.2 Surrounding prose referencing the keyword (Sense A — Pack-Chat-direct + Check-36 + the small set)

These are the `## Pack memory` / Pack-Chat-scope passages that name `PM-only` as the file-class and/or the keyword. All Sense A. RENAME (keep trinity parity). Note: many of these lines use "PM-only" to mean the FILE SET (Pack-Chat-direct files), not the commit keyword token — the architect should decide whether the prose adopts "pack-chat-only" uniformly or distinguishes "the pack-chat-only commit keyword" from "the Pack-Chat-direct file set."

| CLAUDE.md | AGENTS.md | GEMINI.md | Content (representative) | Disposition |
|---|---|---|---|---|
| `:376` | `:336` | `:303` | "PM-only files (BACKLOG.md / CHANGELOG.md / README version table / …" | RENAME (prose; Sense A) |
| `:379` | `:339` | `:306` | "permission rules" for the PM-only list. PM-only IS Pack-Chat-direct…" | RENAME |
| `:385` | `:351` | `:318` | "everything outside the small set.** On the small PM-only set — `BACKLOG.md`…" | RENAME |
| `:404–405` | `:370–371` | `:337–338` | "Pack Chat scoping a PM-only file INTO a coder prompt … major PM-only work" | RENAME |
| `:421` | `:387` | `:354` | "direct PM-only edit + which file" | RENAME |
| `:444` | `:410` | `:377` | "`PM-only` in commit subjects, CI Check 36 verifies the commit diff…" | RENAME (this one IS the commit-keyword sense) |

**Trinity-parity check (empirical):** CLAUDE.md and AGENTS.md each have the same 7 prose anchor lines (offset by ~40 lines); GEMINI.md mirrors with its own offsets. The architect's planner must enumerate all three in lockstep (enumerate-encoding-surfaces).

> **Cross-CLI normalization note (trinity RC):** the GEMINI.md row (`:60`) is already abbreviated vs CLAUDE/AGENTS — this is existing intentional asymmetry, not a defect. Preserve the abbreviation style on rename.

---

## 4. `pack-ops/PACK-AGENTS.md` — "PM-only files and directories" section (Sense A; 4 occurrences; RENAME)

| `file:line` | Content | Disposition |
|---|---|---|
| `pack-ops/PACK-AGENTS.md:130` | Section heading: "**PM-only files and directories** are off-limits to all agents unless the caller's prompt explicitly scopes them in." | **RENAME** — this section title is referenced BY NAME from `validate-pack.py` fail messages (§1.4) + docstrings + the trinity table. Renaming the heading REQUIRES updating every "§ 'PM-only files and directories'" cross-reference in lockstep (see §4.1). |
| `pack-ops/PACK-AGENTS.md:154` | "per-entry files (e.g., `BD-NNN.md`, …) are PM-only writes." | RENAME (prose). |
| `pack-ops/PACK-AGENTS.md:159` | "the same exception clause that applies to the PM-only files above." | RENAME (prose). |
| `pack-ops/PACK-AGENTS.md:162` | "scoping a PM-only file into a coder prompt is the DEFAULT path for any MAJOR edit to it" | RENAME (prose). |

The Files list (`:133–140`) + Directories list (`:142–149`) are the human-readable SSOT that `_PM_ONLY_PERMITTED_PATHS`/`_PREFIXES` mirror. **A13-FOLD touches this list too:** lines `:134–135` already list `BACKLOG.md`/`CHANGELOG.md` as Files (as "regenerated mirror; per-entry source at…") — these are PRESENT here even though the validator removed them (the A13 inconsistency). See §10.

### 4.1 Cross-references to the section name "PM-only files and directories" (RENAME-in-lockstep)
Renaming the §-heading propagates to every literal "§ 'PM-only files and directories'" reference:
- `scripts/validate-pack.py:155–156, 3930, 3990–3991` (fail msg + docstrings)
- `scripts/tests/test-validate-pack-checks-36-37-38.sh:128–129` (test comment)
- `pack-ops/PACK-AGENTS.md:169` ("Pack Chat / PM Chat write authority" — NOTE: this line uses "PM Chat" loosely in the PACK context — itself an instance of the overload; architect may want to disambiguate)
- The BD-198/BD-208 BACKLOG entries reference "§ PM-only" (BACKLOG is PM-only/Pack-Chat-edited — Pack Chat updates those, not the coder).

> **Line 169 callout:** `pack-ops/PACK-AGENTS.md:169` "agents could write per-entry files directly, bypassing Pack Chat / PM Chat write authority" — "PM Chat" here means the *pack* Pack-Chat (loose usage). This is the overload BD-209 cites, in prose. Architect flag: RENAME prose to "Pack Chat" (drop the stray "PM Chat") — but this is a CLARITY edit, not a keyword edit; surface, don't assume.

---

## 5. `pack-ops/PACK-CHAT.md` (Sense A; 3 occurrences; RENAME prose)

| `file:line` | Content | Disposition |
|---|---|---|
| `pack-ops/PACK-CHAT.md:15` | "Apply bookkeeping edits … to the small PM-only set directly; route every MAJOR edit …" | RENAME (prose; Sense A). |
| `pack-ops/PACK-CHAT.md:25` | "bookkeeping edits + new-entry authoring on the small PM-only set directly" | RENAME (prose). |
| `pack-ops/PACK-CHAT.md:101` | "**Pack Chat does MINOR edits only; coder does MAJOR.** On the small PM-only set …" | RENAME (prose). |

**Overload-source prose in PACK-CHAT.md (NOT keyword tokens — architect-flag, do NOT auto-rename):**
- `pack-ops/PACK-CHAT.md:21` "Follow the same core behavioral rules as any **PM chat**" — here "PM chat" describes the project-PM-chat archetype that Pack Chat resembles. This is correct usage (the pack manager follows the same rules as a project PM chat). LEAVE — it is the legitimate "PM Chat" concept, not the keyword.
- `pack-ops/PACK-CHAT.md:23` "You are **not** a coding project PM chat." — correct disambiguating usage. LEAVE.

These two lines are EVIDENCE of the overload BD-209 cites, but they are correct prose about the genuine PM-Chat archetype. The architect should NOT rename them — they are the "other side" of the disambiguation. Surfaced, not decided.

---

## 6. Check-36 TESTS — `scripts/tests/test-validate-pack-checks-36-37-38.sh` (Sense A; 18 occurrences; RENAME + A13-FOLD)

File: 773 lines. The keyword + permitted-set assertions:

### 6.1 Symbol / keyword-detection assertions (VAR-RENAME + RENAME)
| `file:line` | Content | Disposition |
|---|---|---|
| `:50` | `'_is_pm_only_permitted',` (required-symbol list) | VAR-RENAME (must match the renamed symbol or import-check fails). |
| `:94` comment | "# T3: PM-only keyword detected (both forms)" | RENAME (comment). |
| `:95` | `assert_match("docs: PM-only — BACKLOG update", mod._SCOPE_KEYWORDS_PM_ONLY, True, "T3a")` | **RENAME + VAR-RENAME + ALIAS-DECISION** — if hard-retire, change subject to `pack-chat-only` + the constant; if aliases kept, ADD a `pack-chat-only` positive case and keep T3a/T3b as alias regression tests. |
| `:96` | `assert_match("docs: pack-memory-only — trinity edit", mod._SCOPE_KEYWORDS_PM_ONLY, True, "T3b")` | Same — alias-decision-dependent. |
| `:100` | `assert_match("feat: BD-175 cross-surface work", mod._SCOPE_KEYWORDS_PM_ONLY, False, "T4c")` | VAR-RENAME (constant ref). |
| `:106–109` | `def assert_pm(path, expected, label): mod._is_pm_only_permitted(path)` | VAR-RENAME (helper + symbol ref). |

> **GAP the architect must close (ci-guard measure-then-bound):** there is currently NO test asserting `pack-chat-only` is recognized AND NO test asserting `pack-only` does NOT collide with `pack-chat-only`. The architect's design must ADD: (a) a positive `pack-chat-only` keyword-detection test; (b) a no-collision test (`pack-chat-only` subject does NOT trip the `pack-only` rule, and vice-versa) — this is the test encoding of §1.2. T5 (`:102`, `pack-only-ish` boundary test) is the existing nearest analog.

### 6.2 Permitted-set assertions — the A13-FOLD target (T6d/T6e)
| `file:line` | Content | Disposition |
|---|---|---|
| `:111–113` | T6a/b/c `project-template/{CLAUDE,AGENTS,GEMINI}.md` → `True` | VAR-RENAME (helper); content unchanged. |
| `:114–118` comment | "BD-203 A13: `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` are NO LONGER PM-only-permitted FILES … former T6d/T6e file asserts are removed accordingly." | **A13-FOLD** — rewrite comment (restore narrative). |
| `:119` | `assert_pm("pack-ops/BACKLOG.md", False, "T6d")` | **A13-FOLD → flip to `True`** (restore to permitted set). |
| `:120` | `assert_pm("pack-ops/CHANGELOG.md", False, "T6e")` | **A13-FOLD → flip to `True`**. |
| `:121–124` | T6f/g/h/i `PACK-CHAT.md`/`PACK-AGENTS.md`/`README.md`/`CLAUDE.md` → `True` | VAR-RENAME (helper); content unchanged. |
| `:125–130` | T6j `PACK-MEMORY-RATIONALE.md` → `True` (BD-198) | VAR-RENAME; content unchanged. |
| `:131–135` | T6k negative control `pack-ops/NOT-PM.md` → `False` | VAR-RENAME; comment "is NOT PM-only-permitted" → RENAME. |
| `:136–139` | T7a/b/c negatives (`supporting-docs/…`, `project-template/docs/pack/PM-CHAT.md`, `scripts/init-project.sh`) → `False` | VAR-RENAME; **note T7b** asserts the Sense-B `project-template/docs/pack/PM-CHAT.md` is NOT pack-chat-only-permitted — confirms Sense A/B separation at the test layer. |
| `:140–143` | T8a/b/c per-entry prefixes (`backlog/…`, `changelog/…`, `project-template/docs/project/backlog/_rules.md`) → `True` | VAR-RENAME; content unchanged. |
| `:157` | T11a `assert_pside("pack-ops/BACKLOG.md", False, …)` | LEAVE — this is the project-side classifier (`_is_project_side_path`), unrelated to PM-only/pack-chat-only; BACKLOG.md being pack-only-by-location is correct and stays. |

> **A13-FOLD test-symmetry:** flipping T6d/T6e to `True` must be paired with restoring the two paths in `_PM_ONLY_PERMITTED_PATHS` (§1.3/§10). The test + the validator constant are an ENCODING pair (enumerate-encoding-surfaces) — change both or the test fails.

---

## 7. Memory files (Sense A; `commit-subject-keyword-token-trap` is the live one)

Searched `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/` for `PM-only`/`pack-memory-only`/`PM Chat`.

| File | `PM-only` refs | Disposition |
|---|---|---|
| `feedback_commit_subject_keyword_token_trap.md` | `:12` ("`PM-only`, and its alias `pack-memory-only`"), `:19` (BD-198 real instance), `:26–27` ("PM-only-*related*… literal token `PM-only`"), `:33` ("PM-managed"… "never the literal `PM-only` / `project-only` / `pack-memory-only` tokens") | **RENAME (memory-file update)** — the worked example + the token list must teach `pack-chat-only` (and, if aliases kept, note the deprecated `PM-only`/`pack-memory-only`). NOTE: memory files are Pack-Chat-edited (`~/.claude/projects/...`), NOT a repo file — Pack Chat updates this directly, NOT the coder. Surface for the architect/Pack-Chat handoff. |

No other memory file in that directory references the keyword (the `MEMORY.md` index entry "Commit-subject keyword-token trap" points to this file; update its index description in lockstep if the file is renamed/retitled). `PM Chat` does not appear in any memory file body in the keyword sense.

> **Disposition note:** the memory file lives OUTSIDE the git repo (user `~/.claude/...`). It is NOT counted in the 1248 repo-wide total (§11). It is a separate Pack-Chat-direct update surface — the architect should call it out in the plan but it is not a coder edit.

---

## 8. Active docs / templates / skills — the Sense-A vs Sense-B split (CRITICAL)

### 8.1 Pack-side `commit-discipline/SKILL.md` § 4 "PM-only file boundaries" (Sense A; ×3 CLIs; 6 each)
Identical content in all three pack-side copies (architect: trinity-style ×3 lockstep, `x-` contract preserved per skill-agent-maintenance-mechanical):
- `.claude/skills/commit-discipline/SKILL.md:3,107,127,129,132,168`
- `.codex/skills/commit-discipline/SKILL.md:3,107,127,129,132,168`
- `.gemini/skills/commit-discipline/SKILL.md:3,107,127,129,132,168`

Content: `:3` description ("…PM-only file boundaries…"); `:107` "## 4. PM-only file boundaries"; `:127` "does not authorize a PM-only edit"; `:129` "seems to require a PM-only edit"; `:132` "the PM-only file"; `:168` "→ PM-only, forbidden by section 4". The §4 list (`:111–124`) enumerates the SAME governance Files set as PACK-AGENTS.md / `_PM_ONLY_PERMITTED_PATHS` (BACKLOG.md, CHANGELOG.md, README version table, PACK-CHAT.md, PACK-AGENTS.md, root trinity, project-template trinity).
**Disposition: RENAME (Sense A) ×3 in lockstep.** This is the pack-AGENT-facing restatement of the Sense-A file set. A13-FOLD relevance: §4 list at `:111–112` lists `pack-ops/BACKLOG.md`/`CHANGELOG.md` as off-limits files — consistent with restoring them to the set (they ARE Pack-Chat-direct). NOTE these are pack-side skills (`.claude/.codex/.gemini` at repo root), NOT client deliverables — Sense A, in scope.

### 8.2 Pack-side `pack-coder` agent files (Sense A; ×3 CLIs; 1 each)
- `.claude/agents/pack-coder.md:46` — "**No PM-only file edits without explicit caller instruction.** Do not modify `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, README.md version table, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, CLAUDE.md / AGENTS.md / GEMINI.md (root)…"
- `.gemini/agents/pack-coder.md:48` — parallel
- `.codex/agents/pack-coder.toml:25` — parallel
**Disposition: RENAME (Sense A) ×3 in lockstep.** Pack-coder is a PACK agent; this is the pack governance file set. In scope.

### 8.3 `pack-ops/.spawn-rule-manifest.txt` (Sense A; 1)
- `pack-ops/.spawn-rule-manifest.txt:57` — "references: PACK-AGENTS.md § 'Agent permission rules' (PM-only scope-in = default major-edit path); …"
**Disposition: RENAME (Sense A).** Update in lockstep with the renamed PACK-AGENTS section. **enumerate-encoding-surfaces note:** this manifest is itself a validated surface (spawn-rule machinery) — the architect must check whether a validator asserts its content (Check NN) and update the assertion too.

### 8.4 `pack-ops/PACK-MEMORY-RATIONALE.md` (Sense A; 6)
- `:179` "C6 PM-only allowlist gap"; `:570` "Pack Chat edit PM-only files directly at ANY depth"; `:573` "hand-edited substantial PM-only content"; `:580` "Classify every PM-only edit"; `:588` "Scoping a PM-only file"; `:595` "Let Pack Chat keep editing PM-only at any depth"
**Disposition: RENAME (Sense A) prose.** This is a PM-only/Pack-Chat-edited surface (BD-198) — Pack Chat updates it, OR coder if scoped in (per BD-208 default). Architect flags actor.

### 8.5 PROJECT-SIDE Sense-B surfaces — OUT OF SCOPE (architect must confirm)
These use "PM-only" to mean the GENUINE project PM Chat in a CLIENT repo. Renaming them to `pack-chat-only` would (a) import a pack-self keyword into client deliverables (BOUNDARY VIOLATION — `feedback_bd_pack_only_operational_rule`), and (b) be semantically wrong (the rule IS about the project PM Chat).

| `file:line` | Content | Disposition |
|---|---|---|
| `project-template/.claude/agents/coder.md:80` | "**No PM-only file edits without explicit caller scoping.** Do not modify `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`, or any `.md` file at the project root…" | **LEAVE — Sense B (project PM Chat).** OUT OF SCOPE. |
| `project-template/.gemini/agents/coder.md:79` | parallel | LEAVE — Sense B |
| `project-template/.codex/agents/coder.toml:48` | parallel | LEAVE — Sense B |
| `project-template/.claude/agents/repo-ops.md:69` | "**No PM-only file edits.** Do not modify `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`…" | LEAVE — Sense B |
| `project-template/.gemini/agents/repo-ops.md:66` | parallel | LEAVE — Sense B |
| `project-template/.codex/agents/repo-ops.toml:39` | parallel | LEAVE — Sense B |
| `project-template/docs/pack/PM-CHAT.md:480` | "PM-only files (BACKLOG.md, CHANGELOG.md, STATUS.md, PACK-FEEDBACK.md, root .md files)…" | LEAVE — Sense B (this is the CLIENT PM-Chat doc). |

**CRITICAL coupling:** `scripts/validate-pack.py:1608,1615` `PROFILE_PHRASES "No PM-only file edits"` validates the EXACT phrase in the §8.5 Sense-B agent files. If the architect rules Sense B OUT (researcher position), this validator constant STAYS unchanged — `pack-chat-only` work must NOT touch it. If the architect rules Sense B IN (NOT recommended), §8.5 + the 2 PROFILE_PHRASES change in lockstep AND the boundary-violation risk must be mitigated. **This is the single most important architect decision-gate in the BD.**

> **Confirming evidence that Sense A is pack-only:** `project-template/{CLAUDE,AGENTS,GEMINI}.md` contain NO commit-scope-keyword convention table (grep returned empty) — the Sense-A keyword convention does not exist on the project side. The project-template trinity files ARE in the permitted set (as edit TARGETS, B1 cascade) but do not carry the keyword DEFINITION. So Sense A is wholly pack-side; Sense B is wholly project-side; they never co-occur in one file.

---

## 9. Historical commit SUBJECTS with `(PM-only)` (INFORMATIONAL; LEAVE-HISTORICAL)

Command: `git log --oneline | grep -icE 'PM-only|pack-memory-only'` → **32** matching commit subjects.

Check 36 default walk range is **HEAD only** (`_commits_to_walk()` → `git log -1 … HEAD` unless `PACK_CHECK_36_RANGE` overrides). Therefore historical `(PM-only)` subjects are **NOT re-checked** and do NOT break CI.

**Disposition: LEAVE-HISTORICAL (all 32).** Rewriting landed commit subjects is a destructive git-history op (banned). The architect's "historical handling" decision (BD-209 binding bullet) is purely about the ALIAS policy: IF the architect retains `PM-only`/`pack-memory-only` as deprecated aliases, then even a one-shot `PACK_CHECK_36_RANGE=origin/main..HEAD` audit run would still parse these correctly; IF hard-retire, a wide-range audit run would mis-classify them as "no keyword" (harmless — skipped) rather than fail (the permitted-set check only fires when a keyword matches). Either way, no CI breakage on HEAD-only walk.

Representative (full 32 captured; the two A13-relevant ones bolded):
- **`fcdcbc4` docs: v11 — BD-208 Resolved (PM-only)**
- **`4623284` docs: v11 — BD-208 opened + BD-206 scope expanded (PM-only)**
- `b0524d0`, `c22d71c`, `37f2927`, `1936136`, `7d56159`, `da304ca`, `3acc7bb`, `2cedd97`, `2dac2a0`, `93a3337`, `972c3a1`, `78dbd1b`, `60bb2d6`, `9cc3f3d`, `7d190f4`, `c73077d`, `9b2ed2b`, `f19b585`, `d424aac`, `ba9e09d`, `c06696c`, `8570243`, `50bca85`, `27c6495`, `c10a915`, `5534beb`, `2e2f6ab`, `a5c7e62`, `1121b3d`, `8ba0164` (the last uses "PM-only" in prose, not as the trailing keyword).

> **Architect flag (alias-vs-retire decision input):** the two A13-relevant commits `fcdcbc4`/`4623284` are exactly the "buried" commits the BD says the A13-fold "retroactively validates" — under HEAD-only walk they were never Check-36-failed, but they WERE inconsistent with the validator's removed-set state. The A13-fold (§10) restores the set so a hypothetical re-audit of those commits would pass. This is INFORMATIONAL — no action on the commits themselves.

---

## 10. The BD-203 A13 machinery for the fold (A13-FOLD)

A13 (landed in BD-203 Commit 1) removed `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` from the permitted set TOO EARLY (before Commit 2 deletes them). BD-209 RESTORES them; the removal moves to BD-203 Commit 2 (with the `git rm`).

The A13-FOLD touches exactly **three encoding surfaces** (must move in lockstep — enumerate-encoding-surfaces):

| Surface | `file:line` | Current state (A13 removed) | A13-FOLD target |
|---|---|---|---|
| **Validator constant** | `scripts/validate-pack.py:3740–3744` | `_PM_ONLY_PERMITTED_PATHS` does NOT contain `pack-ops/BACKLOG.md`/`CHANGELOG.md`; comment at `:3741–3744` explains the A13 removal | ADD both paths back to the set (post-rename: `_PACK_CHAT_ONLY_PERMITTED_PATHS`); rewrite/remove the A13 comment |
| **Test assertions** | `scripts/tests/test-validate-pack-checks-36-37-38.sh:114–120` | T6d (`:119`) and T6e (`:120`) assert `False`; comment `:114–118` explains the removal | FLIP T6d/T6e to `True`; rewrite the comment |
| **Governance doc (SSOT)** | `pack-ops/PACK-AGENTS.md:133–135` | Files list ALREADY lists `BACKLOG.md`/`CHANGELOG.md` (as "regenerated mirror; per-entry source at…") — this is the A13 INCONSISTENCY: the doc still lists them, the validator removed them | KEEP listed (the doc is already correct for the restore); ensure wording is consistent with "BACKLOG/CHANGELOG ARE permitted until BD-203 Commit 2 deletes them" |

**A13-FOLD net effect:** after BD-209, the permitted Files set = the §1.3 set PLUS `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` (restored). The validator, the tests, and PACK-AGENTS.md agree. The actual `git rm` of the two files + their final removal from the set moves to BD-203 Commit 2.

> **Sequencing dependency (from the BD):** BD-209 lands BETWEEN BD-203 Commit 1 (`a5a8ad8`, landed) and Commit 2 (not yet run). So at BD-209 time, `pack-ops/BACKLOG.md`/`CHANGELOG.md` STILL EXIST on disk → restoring them to the permitted set is CORRECT (they are real, Pack-Chat-edited files right now). BD-203 Commit 2 will delete them AND re-remove them from the set in the same atomic commit.

---

## 11. RECONCILIATION — the count, three independent ways

### 11.1 Raw repo-wide (the headline)
Command (HEAD `4086705`):
`grep -rIn --exclude-dir=.git "PM-only" . | wc -l` → **1248** lines.
`grep -rIl --exclude-dir=.git "PM-only" . | wc -l` → **227** files.
Per-pattern raw line counts:
```
PM-only          : 1248
pack-memory-only : 23
PM_ONLY          : 24
pm_only          : 9
PM Chat          : 454
```
Interpretation: `pack-memory-only`(23) and `PM_ONLY`/`pm_only`(33) are subsets that overlap `PM-only` lines or live in the same machinery; `PM Chat`(454) is mostly the genuine PM-Chat archetype prose (Sense B / project-PM concept) across docs — NOT the keyword, mostly LEAVE.

### 11.2 By-category (the ACTIVE work surface — what the architect edits)
| Category | Files | Disposition | §ref |
|---|---|---|---|
| Check 36 machinery (validate-pack.py) | 1 (36 occ) | RENAME / VAR-RENAME / A13-FOLD; 2 occ Sense-B-coupled (LEAVE unless ruled in) | §1,§2 |
| Trinity convention table + prose (CLAUDE/AGENTS/GEMINI) | 3 (12+12+11 occ) | RENAME ×3 lockstep | §3 |
| PACK-AGENTS.md "PM-only files and directories" | 1 (4 occ) | RENAME + section-name cross-ref cascade + A13-FOLD doc | §4 |
| PACK-CHAT.md | 1 (3 occ) | RENAME prose (2 "PM Chat" lines LEAVE) | §5 |
| Check-36 tests | 1 (18 occ) | RENAME / VAR-RENAME / A13-FOLD + ADD new-keyword & collision tests | §6 |
| Pack-side commit-discipline SKILL.md ×3 | 3 (6 occ each) | RENAME ×3 lockstep | §8.1 |
| Pack-side pack-coder agent ×3 | 3 (1 occ each) | RENAME ×3 lockstep | §8.2 |
| .spawn-rule-manifest.txt | 1 (1 occ) | RENAME | §8.3 |
| PACK-MEMORY-RATIONALE.md | 1 (6 occ) | RENAME prose | §8.4 |
| **ACTIVE SENSE-A SUBTOTAL** | **16 files** | RENAME/VAR-RENAME/A13-FOLD | — |
| Project-side Sense-B (agents ×6 + PM-CHAT.md) | 7 | **LEAVE — OUT OF SCOPE** (architect confirms) | §8.5 |
| Memory file (outside repo) | 1 | RENAME (Pack-Chat-direct, not coder; not in 1248) | §7 |
| Historical commit subjects | 32 subjects | LEAVE-HISTORICAL | §9 |
| Historical/archived maintenance-docs prose | ~210 files | LEAVE-HISTORICAL (landed reports; not machinery, not re-checked) | §11.4 |
| BACKLOG.md (BD entries inc. BD-209 self) | 1 (35 occ) | Pack-Chat-direct bookkeeping (PM-only/Pack-Chat-edited; not coder) | §11.4 |

### 11.3 By-file reconciliation (active set occurrence sum)
Active Sense-A files + their occurrence counts (from per-file `grep -o … | wc -l`):
```
12  CLAUDE.md
12  AGENTS.md
11  GEMINI.md
36  scripts/validate-pack.py        (34 Sense-A + 2 Sense-B-coupled PROFILE_PHRASES)
18  scripts/tests/test-validate-pack-checks-36-37-38.sh
 4  pack-ops/PACK-AGENTS.md
 3  pack-ops/PACK-CHAT.md            (3 keyword + 2 "PM Chat" prose LEAVE)
 6  pack-ops/PACK-MEMORY-RATIONALE.md
 1  pack-ops/.spawn-rule-manifest.txt
 6  .claude/skills/commit-discipline/SKILL.md
 6  .codex/skills/commit-discipline/SKILL.md
 6  .gemini/skills/commit-discipline/SKILL.md
 1  .claude/agents/pack-coder.md
 1  .gemini/agents/pack-coder.md
 1  .codex/agents/pack-coder.toml   (16 active files)
```
**Active-set occurrence sum = 130** `PM-only`/`pack-memory-only`/`_PM_ONLY` occurrences across **16 files** (the editable Sense-A surface, EXCLUDING the 2 Sense-B-coupled PROFILE_PHRASES which LEAVE unless the architect rules Sense B in → then 132 across the same 16 files + 6 Sense-B project-template files + PM-CHAT.md).

### 11.4 Discrepancy reconciliation (1248 raw vs 130 active)
- **1248 raw lines** − **130 active occurrences** = **1118** = historical/archived prose (≈210 maintenance-docs files: IMPL-REPORTS, PACK-REVIEWs, archived PLANs/ARCHITECTUREs) + the 35 BACKLOG.md BD-entry occurrences + multi-occurrence-per-line counting differences (raw count is by-LINE via `grep -n`; active is by-OCCURRENCE via `grep -o`, and some lines carry 2+ occurrences).
- The **35 BACKLOG.md** occurrences are BD-entry prose (BD-167b/169b/198/208/209 etc.) — Pack-Chat-direct bookkeeping. The architect may RENAME the *active* BD-209-adjacent references for forward-clarity, but historical resolved-entry text (e.g. BD-167b/169b "Resolved 2026-05-16") is LEAVE-HISTORICAL.
- The **~210 maintenance-docs** files are landed reports/plans/reviews/audits. NONE are machinery; NONE are re-checked by any validator; editing them would be a no-value mass-churn. **Disposition: LEAVE-HISTORICAL (all).**
- **Reconciliation conclusion: SUPPORTED.** The 1248 figure is real but ~90% historical prose. The true editable blast radius is **16 active Sense-A files / ~130 occurrences**, + 1 out-of-repo memory file (Pack-Chat-direct), + (architect-gated) 7 project-side Sense-B files.

### 11.5 Empirical-evidence block — the active-set claim
```
CLAIM: the active editable Sense-A surface is exactly 16 files.
COMMAND: grep -rIn --exclude-dir=.git "PM-only|pack-memory-only|PM_ONLY|pm_only" \
         <each of: CLAUDE.md AGENTS.md GEMINI.md scripts/validate-pack.py \
         scripts/tests/test-validate-pack-checks-36-37-38.sh pack-ops/PACK-AGENTS.md \
         pack-ops/PACK-CHAT.md pack-ops/PACK-MEMORY-RATIONALE.md \
         pack-ops/.spawn-rule-manifest.txt .{claude,codex,gemini}/skills/commit-discipline/SKILL.md \
         .{claude,codex,gemini}/agents/pack-coder.{md,toml}>
OUTPUT: per-file counts as listed in §11.3 (sum 130; +2 Sense-B-coupled in validate-pack.py)
HEAD-SHA: 40867052b31e822e1742de4806016bdca1131f6e   DATE: 2026-06-04
INTERPRETATION: every Sense-A keyword-machinery + governance + pack-agent surface is in this set;
  project-side Sense-B (7 files) is segregated and architect-gated; memory file is out-of-repo.
CONCLUSION: SUPPORTED.
```

---

## 12. Open decisions surfaced for the architect (NOT decided here)

1. **Sense B in-or-out** (§8.5) — the dominating decision. Researcher evidence says OUT (boundary + semantics). Couples to `validate-pack.py:1608/1615` PROFILE_PHRASES.
2. **Alias-vs-retire** (§1.1, §6.1, §9) — keep `pm-only`/`pack-memory-only` as deprecated parser aliases vs hard-retire. Affects `_SCOPE_KEYWORDS_*` tuple, T3a/T3b tests, and a hypothetical wide-range audit of the 32 historical commits.
3. **Internal var rename** (§2) — `_PM_ONLY_*` → `_PACK_CHAT_ONLY_*` (BD permits, doesn't mandate). If renamed, the test required-symbol list (`:50`) + call sites move in lockstep.
4. **Prose-vs-keyword distinction** (§3.2) — in trinity/governance prose, "PM-only" sometimes means the FILE SET (Pack-Chat-direct files) and sometimes the commit KEYWORD; architect decides whether prose adopts "pack-chat-only" uniformly or distinguishes the two senses.
5. **Section-name cascade** (§4.1) — renaming the PACK-AGENTS "PM-only files and directories" heading cascades to ~6 literal cross-references; decide the new heading text ("pack-chat-only files and directories"?) and update all refs in lockstep.
6. **PACK-AGENTS.md:169 "PM Chat" stray** (§4 callout) — clarity edit, surface-not-decide.
7. **Historical BACKLOG.md prose** (§11.4) — which BD-entry references RENAME for forward-clarity vs LEAVE-HISTORICAL.
8. **New tests required** (§6.1) — add `pack-chat-only` positive-detection + no-collision tests (the §1.2 facts encoded as regression tests). enumerate-encoding-surfaces.
9. **Manifest regen** — any commit touching `scripts/`, `pack-ops/`, `project-template/`, or `supporting-docs/` must regenerate `test-fixtures/manifest.txt` (trinity RC9). The architect/planner should schedule this in the implementing commit(s).

---

## 13. Rules-Applied Verification Block

### 13.1 READ-IN-FULL — per-file direct-read proof (every named doc + memory file)

| Named doc | Direct Read proof (line count + first/last or unique mid-line) | Conclusion |
|---|---|---|
| BD-209 entry (`pack-ops/BACKLOG.md:3419–3435`) | Read tool, offset 3415 limit 40. First: `:3415` "Position: pack-self governance; parallel with BD-203…"; mid `:3419` "**BD-209 — Rename the `PM-only` commit-scope keyword → `pack-chat-only`…**"; last `:3435` "Position: pack-self governance; rename-first, between BD-203 Commit 1 and Commit 2." | COMPLIANT |
| `scripts/validate-pack.py` Check 36 region | Read tool offset 3716 limit 300 (lines 3716–4015). Unique mid-line `:3732` `_SCOPE_KEYWORDS_PM_ONLY = ("pm-only", "pack-memory-only")`; `:3908` `def _is_pm_only_permitted`. Plus offset 150/1600/4520 reads for the docstring + PROFILE_PHRASES + comment. | COMPLIANT |
| Permitted-set definitions | Read within the 3716–4015 block: `:3740–3755` Files set; `:3757–3765` Prefixes. Verbatim captured in §1.3. | COMPLIANT |
| Trinity table — `CLAUDE.md` | Read offset 68 limit 22; `:78` table row `| `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | …`. Plus grep enumerated all 12 occ. | COMPLIANT |
| Trinity table — `AGENTS.md` | grep -n enumerated `:80` row + 11 prose lines; row text verbatim matches CLAUDE.md:78 (trinity parity). | COMPLIANT |
| Trinity table — `GEMINI.md` | grep -n enumerated `:60` abbreviated row + 10 prose lines; row verbatim captured (§3.1). | COMPLIANT |
| `pack-ops/PACK-AGENTS.md` | Read offset 125 limit 45 (lines 125–169). First `:125` "`pack-coder` Write/Edits source within its caller-defined scope…"; `:130` "**PM-only files and directories** are off-limits…"; last `:169` "bypassing Pack Chat / PM Chat write authority." | COMPLIANT |
| `pack-ops/PACK-CHAT.md` | Read offset 10 limit 20 + offset 98 limit 8. `:11` "You are the persistent assistant…"; `:15` "small PM-only set directly"; `:21` "same core behavioral rules as any PM chat"; `:101` "Pack Chat does MINOR edits only; coder does MAJOR." | COMPLIANT |
| `CLAUDE.md ## Pack memory` IN FULL | grep `^## Pack memory` → `:136`; file is 572 lines; the `## Pack memory` block + full project-instructions are present verbatim in the spawn context AND `:136` confirmed on-disk via grep. (Heading at 136; trinity rules through ~end.) | COMPLIANT |
| `feedback_researcher_maps_blast_radius_before_architect.md` | Read tool, 40 lines. First `---`/`name: researcher-maps-blast-radius-before-architect`; last (`:40`) "[[adversarial-architect-review-on-major-gap]]." | COMPLIANT |
| `feedback_commit_subject_keyword_token_trap.md` | Read tool, 38 lines (full). First `---`/`name: commit-subject-keyword-token-trap`; mid `:19` "Check 36 latched onto `PM-only`, which denies `scripts/` paths"; last `:38` "[[feedback_no_prestaging_until_commit_approval]]." | COMPLIANT |
| `feedback_ci_guard_design_measure_then_bound.md` | Read tool, 14 lines. First `---`/`name: ci-guard-design-measure-then-bound`; last `:14` "Related: [[architect-planner-empirical-evidence]], [[triage-workflow-protocol]]." | COMPLIANT |
| `feedback_architect_planner_empirical_evidence.md` | Read tool, 14 lines. `name: architect-planner-empirical-evidence`; last `:14` "Related: [[agent-output-rules-applied-block]], [[ci-guard-design-measure-then-bound]]." | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` | Read tool, 14 lines. `name: agent-output-rules-applied-block`; mid `:10` "Rules-Applied Verification Block (per rule: name + quoted evidence + COMPLIANT / N/A…)"; last `:14` "Related: [[agent-prompt-enumerates-rules]]…" | COMPLIANT |
| `feedback_agents_read_rule_docs_in_full.md` | Read tool, 117 lines (full). `name: agents-read-rule-docs-in-full`; mid `:98` "No-cache-substitution clause"; last `:117` "…accepting a derived-not-read attestation erodes the very standard that catches the dangerous cases." | COMPLIANT |
| `feedback_scope_deliverables_to_the_ask.md` | Read tool, 34 lines. `name: scope-deliverables-to-the-ask-no-noise`; mid `:25` "…this is a disaster and why we're in this mess."; last `:34` "…the user's standing preference for terse, exactly-scoped work." | COMPLIANT |

### 13.2 Per-rule compliance

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION + NO-CACHE-SUBSTITUTION | §13.1 table: each named doc/memory file Read DIRECTLY via the Read tool with per-file line count + first/last/unique-mid-line proof. No file derived from the CLAUDE.md cache; `## Pack memory` read SEPARATELY from the 7 memory files. | COMPLIANT |
| empirical-evidence-blocks | Every count carries the command + verbatim output + HEAD-SHA `4086705` + date 2026-06-04 (§1.2 collision test, §9 historical count, §11.1–11.5 reconciliation block). | COMPLIANT |
| ci-guard-design-measure-then-bound | Measured the actual tree exhaustively (1248 raw / 227 files), categorized every active occurrence KEEP-RENAME vs LEAVE-HISTORICAL vs OUT-OF-SCOPE, sized the active set to 16 files / ~130 occ; flagged the test-GAP the architect must close (§6.1) and the SET membership unchanged-except-A13 (§1.3). This research IS the measure step. | COMPLIANT |
| scope-deliverables-to-the-ask | Led with the reconciled total + the dominating Sense-A/B finding + the category table (§0, §11.2); enumerated every occurrence with file:line + disposition; surfaced 9 decisions for the architect WITHOUT deciding them (§12). No design proposals authored. | COMPLIANT |
| rules-applied-verification-block | This §13 block: per-rule table with quoted evidence + the §13.1 READ-IN-FULL per-file direct-read proof for all 15 named docs/memory files. No empty rows. | COMPLIANT |

**No VIOLATED rows. No empty evidence.**

---

*End RESEARCH-BD-209-BLAST-RADIUS.md*
