# PLAN — BD-209: rename the Check-36 commit-scope keyword `PM-only`/`pack-memory-only` → `pack-chat-only` (HARD-RETIRE) + fold BD-203 A13

**Author:** pack-planner · **HEAD:** `4086705` (`40867052b31e822e1742de4806016bdca1131f6e`) · **Date:** 2026-06-04 · **Branch:** v11-dev
**Designed against:** `ARCHITECTURE-BD-209.md` (amended 2026-06-05, HARD-RETIRE) + `RESEARCH-BD-209-BLAST-RADIUS.md`. PLANNING ONLY — no source edits, no git verbs.
**Deliverable:** ordered implementation steps + commit shape + actor split + verification + residual gaps. Implements the design; does NOT redesign.

---

## 0. Goal + BD addressed

BD-209: rename the pack-repo Check-36 commit-scope keyword `PM-only` (alias `pack-memory-only`) → `pack-chat-only`, HARD-RETIRING the old tokens (parser tuple becomes `("pack-chat-only",)` only — a stray `(pm-only)` is unrecognized → Check 36 SKIPS, not rejects), rename the internal `_PM_ONLY_*` vars, and FOLD the BD-203 A13 fix (restore `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` to the permitted set across the 3 lockstep encoding surfaces). The rename is confined to the **16-file Sense-A allowlist**; the project-side Sense-B "No PM-only file edits" rule is **NOT touched**.

**Acceptance (from the BD entry):** keyword is `pack-chat-only` everywhere in the Sense-A set; Check 36 parses it + hard-retire tested; no token collision with `pack-only`; historical `(PM-only)` commits do not break CI; A13 fold restores BACKLOG/CHANGELOG (validate-pack green); commit-gating works end-to-end.

**Empirical-Evidence Block — HEAD + design-vs-reality reconciliation**
```
CLAIM: HEAD = 40867052…; the design's 16-file Sense-A set + all anchors match the tree.
COMMAND: git rev-parse HEAD; per-file greps for PM-only/pack-memory-only across the 16 files + the 7 Sense-B files
OUTPUT: HEAD 40867052b31e822e1742de4806016bdca1131f6e.
  Trinity: CLAUDE.md row :78 + prose :376/:379/:385/:404/:421/:444; AGENTS.md row :80 + prose :336/:339/:351/:370/:371/:387/:410; GEMINI.md row :60 + prose :303/:306/:318/:337/:338/:354/:377.
  validate-pack.py: :154-156 registry docstring, :1608/:1615 PROFILE_PHRASES (Sense-B — LEAVE), :3732 _SCOPE_KEYWORDS_PM_ONLY, :3734/:3740/:3757-3759 perm sets, :3908-3913 _is_pm_only_permitted, :3920/:3928-3930/:3950/:3982-3991 driver+docstring, :4527 comment.
  test: :50 required-symbol, :95/:96 T3a/T3b, :100 T4c, :107 helper, :119/:120 T6d/T6e=False.
  PACK-AGENTS.md :130/:154/:159/:162/:169; PACK-CHAT.md :15/:25/:101 (Sense-A) + :21/:23 (archetype, LEAVE); PACK-MEMORY-RATIONALE.md :179/:570/:573/:580/:588/:595; .spawn-rule-manifest.txt :57.
  SKILL.md ×3 :3/:107/:127/:129/:132/:168 (6 each). pack-coder ×3 (.claude:46/.gemini:48/.codex:25).
  Sense-B (MUST STAY): project-template coder/repo-ops ×6 + PM-CHAT.md:480; vp:1608/1615 PROFILE_PHRASES.
HEAD-SHA: 40867052…   DATE: 2026-06-04
INTERPRETATION: design matches reality. Per-file occurrence counts re-measured (§2A): trinity 12/12/11, validate-pack.py 37 (35 Sense-A + 2 Sense-B PROFILE_PHRASES), test file 18, PACK-AGENTS 4, PACK-CHAT 3, RATIONALE 6, manifest 1, SKILL ×3 = 6 each, pack-coder ×3 = 1 each. The test file's `§ "PM-only files and directories"` ref EXISTS as a multi-line comment (:128-129) — confirmed present, renamed by Group I (the prior single-line grep missed it; corrected at the plan-review gate).
CONCLUSION: SUPPORTED.
```

**Empirical-Evidence Block — AUTHORITATIVE count reconciliation (broadened pattern; settles 37 vs 36 vs 34)**
```
CLAIM: the authoritative per-file Sense-A counts are 12/12/11/37/18/4/3/6/1/6/6/6/1/1/1 (total 125;
       2 LEAVE in validate-pack.py; 123 renamed). The adversarial reviewer's "true 34" for
       validate-pack.py is WRONG; the ARCHITECTURE/RESEARCH "36" used a narrower pattern.
COMMAND: for each of the 16 files: grep -oE 'PM-only|pack-memory-only|PM_ONLY|pm[_-]only' <file> | wc -l
OUTPUT (HEAD 40867052, broadened pattern, by-occurrence):
  12 CLAUDE.md | 12 AGENTS.md | 11 GEMINI.md | 37 validate-pack.py | 18 test | 4 PACK-AGENTS |
  3 PACK-CHAT | 6 RATIONALE | 1 manifest | 6/6/6 SKILL ×3 | 1/1/1 pack-coder ×3  → SUM 125
  validate-pack.py per-occurrence (37): :154×2,:155,:156 | :1608,:1615 (LEAVE) | :3732×3 |
  :3734×2 | :3740 | :3744 | :3757,:3758 | :3759 | :3908,:3909,:3910,:3911,:3913 |
  :3920×2,:3928×2,:3929,:3930 | :3950×2,:3951 | :3982,:3983 | :3986,:3987,:3990,:3991 | :4527
HEAD-SHA: 40867052…   DATE: 2026-06-05
INTERPRETATION: 37 is correct. The ARCHITECTURE §3.1 / RESEARCH §11.3 "36" came from
  `grep -ocE "PM-only|pack-memory-only"` — a NARROWER 2-alternative pattern that (a) omits the
  `PM_ONLY`/`pm_only` symbol fragments and (b) counts by-LINE (`-c`) not by-occurrence (`-o`), so
  multi-occurrence lines (:154, :3732, :3734, :3920, :3928, :3950) under-count. The broadened
  by-occurrence pattern (`pm[_-]only`, `-o`) is the authoritative measure: 37 total, 2 LEAVE
  (PROFILE_PHRASES :1608/:1615), 35 Sense-A to-rename in validate-pack.py. The reviewer's "34"
  is unsupported by any pattern I can reproduce; Pack Chat's independent grep also returned 37.
  WHICH ARTIFACT WAS WRONG: none materially — ARCHITECTURE/RESEARCH "36" is a pattern/method
  artifact (narrower regex + by-line), not a substantive miss; their 16-file SET and dispositions
  are correct. The reviewer's "34" is the only disputed figure and it does NOT reproduce.
CONCLUSION: SUPPORTED — definitive count 125/2/123; validate-pack.py = 37 occ / 35 rename.
  NB: the count is DOCUMENTATION; the §6 grep GATE is the contract — accuracy stated, not relied on.
```

---

## 1. Allowlist guard — the coder physically cannot stray outside Sense A

The single safety crux (design §1). The coder prompt MUST be constructed so straying is mechanically impossible:

1. **The coder's scope is the literal 16-file allowlist below (§2).** No path outside it may be edited. State this as a hard boundary in the spawn prompt.
2. **Sense-B DENY-list (NEVER touch), stated explicitly in the prompt:** `project-template/.claude/agents/coder.md`, `…/repo-ops.md`, `project-template/.codex/agents/coder.toml`, `…/repo-ops.toml`, `project-template/.gemini/agents/coder.md`, `…/repo-ops.md`, `project-template/docs/pack/PM-CHAT.md`, and the two `PROFILE_PHRASES` lines `scripts/validate-pack.py:1608` + `:1615` (`"No PM-only file edits"`).
3. **STOP-tripwire:** if any planned edit would change a `PROFILE_PHRASES` constant or any `project-template/` path, the edit is mis-bucketed Sense B — HALT and report, do not proceed (design §1.3 hard interlock).
4. **PREFLIGHT grep-proof (§5):** the coder must grep-prove `"No PM-only file edits"` is byte-unchanged in all 7 Sense-B locations before writing its IMPL-REPORT.

---

## 2. Task breakdown — every edit as an atomic task (file + anchor + change)

All edits are **targeted in-place anchor edits** (`edit-in-place-not-full-rewrite`); anchors are quoted strings, never line numbers. Grouped by surface. ALL tasks land in ONE coder commit (§3).

### Group A — `scripts/validate-pack.py` (var-rename + rename + A13 fold; the 2 PROFILE_PHRASES LEAVE)

| # | Anchor (current) | Change |
|---|---|---|
| A1 | `_SCOPE_KEYWORDS_PM_ONLY = ("pm-only", "pack-memory-only")` (:3732) | → `_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)` — HARD-RETIRE; ONLY `pack-chat-only` |
| A2 | `_PM_ONLY_PERMITTED_PATHS = {` (:3740) | rename → `_PACK_CHAT_ONLY_PERMITTED_PATHS`; **A13-FOLD: ADD** `"pack-ops/BACKLOG.md",` + `"pack-ops/CHANGELOG.md",`; replace the `# BD-203 A13: …removed here…` comment (:3741-3744) with the §6.3 restore narrative |
| A3 | `_PM_ONLY_PERMITTED_PREFIXES = (` (:3759) | rename → `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` (tuple content unchanged) |
| A4 | `def _is_pm_only_permitted(path)` + docstring "A path is PM-only-permitted if…" + body refs `_PM_ONLY_PERMITTED_PATHS`/`_PREFIXES` (:3908-3913) | rename def → `_is_pack_chat_only_permitted`; update both constant refs; docstring → "pack-chat-only-permitted" |
| A5 | **bare local var** `is_pm_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PM_ONLY)` (:3950 — NOTE: `is_pm_only` has NO leading underscore; the gate pattern `pm[_-]only` catches it) | → `is_pack_chat_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PACK_CHAT_ONLY)` |
| A6 | bare local ref `if not (is_pack_only or is_project_only or is_pm_only):` (:3951) | → `… or is_pack_chat_only):` (rename the `is_pm_only` reference; A5+A6+A7 must ALL flip together or a NameError results) |
| A7 | bare local `if is_pm_only:` block (:3982) + `offenders = [p for p in paths if not _is_pm_only_permitted(p)]` (:3983) + fail() message (:3986-3991) | → `if is_pack_chat_only:` (the LHS-defined-at-A5 local); ref → `_is_pack_chat_only_permitted`; fail msg "claims \`pack-chat-only\` but touches non-pack-chat-only paths …(pack-chat-only permitted set per pack-ops/PACK-AGENTS.md § 'pack-chat-only files and directories')". **Interlock: A5 (LHS) + A6/A7 (refs) flip atomically — renaming the tuple/LHS but leaving a `is_pm_only` ref = NameError; leaving the LHS = stale token the gate catches.** |
| A8 | `check_commit_scope_honesty` docstring (:3920 "`PM-only` / `pack-memory-only`"; :3928-3930 failure-mode + "§ 'PM-only files and directories'") | rename prose → single token `pack-chat-only` + renamed § name; drop the alias slash-form |
| A9 | Module registry docstring (:154-156 "`PM-only` / `pack-memory-only`"; "PM-only PERMITTED-PATHS …§ 'PM-only files and directories'") | rename prose → `pack-chat-only` + renamed § name |
| A10 | Comment "pack-root trinity … are PM-only operating rules" (:4527) | rename prose → "pack-chat-only operating rules" |
| A11 | Comment "PM-only PERMITTED-PATHS per …" (:3734) + "PM-only PERMITTED-PATH PREFIXES …§ 'PM-only files and directories'" (:3757-3758) | rename comment prose + renamed § name |
| A-LEAVE | `PROFILE_PHRASES["write-scoped"]`/`["write-script"]` = `"No PM-only file edits"` (:1608/:1615) | **LEAVE — Sense B. DO NOT TOUCH.** |

### Group B — trinity ×3 lockstep (CLAUDE.md / AGENTS.md / GEMINI.md)

Trinity rule: all three move in the SAME commit. The convention table is NOT tool-specific. GEMINI.md keeps its abbreviated style (`cross-cli-reference-normalization`).

| # | File:anchor | Change |
|---|---|---|
| B1 | CLAUDE.md:78 table row `| `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | …PERMITS `project-template/` trinity… |` | → `| `pack-chat-only` | Pack-Chat-direct-edit only | …` — **drop the "(or `pack-memory-only`)" alias clause** (hard-retire). Update the inner "ARE PM-only" → "ARE pack-chat-only" |
| B2 | AGENTS.md:80 (byte-parallel row) | parallel edit to B1 |
| B3 | GEMINI.md:60 (abbreviated row) | → `| `pack-chat-only` | Pack-Chat-direct-edit only | Per `pack-ops/PACK-AGENTS.md` pack-chat-only Files list — PERMITS `project-template/` trinity |` (abbreviated style preserved; no alias clause) |
| B4 | `## Pack memory` prose, each ×3 (CLAUDE :376/:379/:385/:404/:405/:421/:444; AGENTS :336/:339/:351/:370/:371/:387/:410; GEMINI :303/:306/:318/:337/:338/:354/:377) | rename every Sense-A "PM-only" → "pack-chat-only": "PM-only files (BACKLOG.md…"; "the PM-only list. PM-only IS Pack-Chat-direct"; "On the small PM-only set"; "scoping a PM-only file INTO a coder prompt …major PM-only work"; "direct PM-only edit + which file"; "`PM-only` in commit subjects" (this last is the keyword sense). Keep trinity parity ×3. |

> **Token-trap note (B-group):** these prose lines now contain the literal token `pack-chat-only` inside FILE BODIES — Check 36 scans only commit SUBJECTS, so no gate trip. The constraint is on the COMMIT subject only (§3 / §4).

### Group C — `pack-ops/PACK-AGENTS.md` (heading rename + cascade + A13 doc)

| # | Anchor | Change |
|---|---|---|
| C1 | heading "**PM-only files and directories** are off-limits…" (:130) | → "**pack-chat-only files and directories**" (drives the §3.3 cascade — every literal "§ 'PM-only files and directories'" ref in Group A renamed in lockstep) |
| C2 | Files list rows `BACKLOG.md`/`CHANGELOG.md` ("regenerated mirror; per-entry source at…") (:133-135) | **A13-FOLD: KEEP listed**; add a one-line note that removal is scheduled for BD-203 Commit 2 (§6.3) |
| C3 | "per-entry files (…) are PM-only writes." (:154) | → "pack-chat-only writes" |
| C4 | "the same exception clause that applies to the PM-only files above." (:159) | → "pack-chat-only files" |
| C5 | "scoping a PM-only file into a coder prompt is the DEFAULT path…" (:162) | → "pack-chat-only file" |
| C6 | "bypassing Pack Chat / PM Chat write authority." (:169) | rename the stray "PM Chat" → "Pack Chat" (design §12.6 clarity fix; in-scope file) |

### Group D — `pack-ops/PACK-CHAT.md` (3 Sense-A; 2 archetype LEAVE)

| # | Anchor | Change |
|---|---|---|
| D1 | "…to the small PM-only set directly; route every…" (:15) | → "small pack-chat-only set" |
| D2 | "bookkeeping edits + new-entry authoring on the small PM-only set directly" (:25) | → "small pack-chat-only set" |
| D3 | "On the small PM-only set Pack Chat applies directly only…" (:101) | → "small pack-chat-only set" |
| D-LEAVE | "Follow the same core behavioral rules as any **PM chat**" (:21) + "You are **not** a coding project PM chat." (:23) | **LEAVE — genuine project-PM-Chat archetype.** |

### Group E — `pack-ops/PACK-MEMORY-RATIONALE.md` (6 occ, Sense A prose)

| # | Anchor | Change |
|---|---|---|
| E1 | "C6 PM-only allowlist gap" (:179) | → "C6 pack-chat-only allowlist gap" |
| E2 | "Pack Chat edit PM-only files directly at ANY depth" (:570) | → "pack-chat-only files" |
| E3 | "hand-edited substantial PM-only content" (:573) | → "pack-chat-only content" |
| E4 | "Classify every PM-only edit" (:580) | → "pack-chat-only edit" |
| E5 | "Scoping a PM-only file" (:588) | → "pack-chat-only file" |
| E6 | "Let Pack Chat keep editing PM-only at any depth" (:595) | → "pack-chat-only" |

### Group F — `pack-ops/.spawn-rule-manifest.txt` (1 occ)

| # | Anchor | Change |
|---|---|---|
| F1 | `references:` free-text "(PM-only scope-in = default major-edit path)" (:57) | → "(pack-chat-only scope-in = default major-edit path)" — Check 46 asserts only structure, not this substring (design §3.4), so safe; no test change |

### Group G — `commit-discipline/SKILL.md` ×3 lockstep (.claude / .codex / .gemini; 6 occ each, identical)

Trinity-style ×3 lockstep; preserve the `x-` client contract (`skill-agent-maintenance-mechanical`). Anchors identical in all three (:3/:107/:127/:129/:132/:168):

| # | Anchor | Change |
|---|---|---|
| G1 | description "…PM-only file boundaries…" (:3) | → "pack-chat-only file boundaries" |
| G2 | "## 4. PM-only file boundaries" (:107) | → "## 4. pack-chat-only file boundaries" |
| G3 | "does not authorize a PM-only edit." (:127) | → "pack-chat-only edit" |
| G4 | "seems to require a PM-only edit" (:129) | → "pack-chat-only edit" |
| G5 | "the PM-only file." (:132) | → "the pack-chat-only file" |
| G6 | "→ PM-only, forbidden by section 4" (:168) | → "→ pack-chat-only, forbidden by section 4" |

Apply G1-G6 identically in `.claude/`, `.codex/`, `.gemini/` copies.

### Group H — `pack-coder` agent ×3 lockstep (.claude .md / .gemini .md / .codex .toml; 1 occ each)

| # | File:anchor | Change |
|---|---|---|
| H1 | `.claude/agents/pack-coder.md:46` "**No PM-only file edits without explicit caller instruction.**" | → "**No pack-chat-only file edits without explicit caller instruction.**" |
| H2 | `.gemini/agents/pack-coder.md:48` (parallel) | parallel edit |
| H3 | `.codex/agents/pack-coder.toml:25` (parallel) | parallel edit |

> These are the PACK `pack-coder` (stem `pack-coder`), Sense A — NOT PROFILE_PHRASES-validated (design §1.4 CLAIM 1). Do NOT confuse with project-side `coder`/`repo-ops` (Sense B, DENY).

### Group I — Check-36 tests `scripts/tests/test-validate-pack-checks-36-37-38.sh` (var-rename + test swap + A13 flip)

| # | Anchor | Change |
|---|---|---|
| I1 | required-symbol list `'_is_pm_only_permitted',` (:50) | → `'_is_pack_chat_only_permitted',` (else import-check fails — §5 interlock) |
| I2 | helper `assert_pm` body `mod._is_pm_only_permitted(path)` (:107) | → `mod._is_pack_chat_only_permitted(path)` (helper name `assert_pm` may stay; only the symbol ref changes) |
| I3 | `assert_match("docs: PM-only — BACKLOG update", mod._SCOPE_KEYWORDS_PM_ONLY, True, "T3a")` (:95) | **REMOVE** (hard-retire — old token no longer parses) |
| I4 | `assert_match("docs: pack-memory-only — trinity edit", mod._SCOPE_KEYWORDS_PM_ONLY, True, "T3b")` (:96) | **REMOVE** |
| I5 | T3 comment "# T3: PM-only keyword detected (both forms)" (:94) | rewrite → "# T3: pack-chat-only keyword detected; retired tokens NOT recognized" |
| I6 | (new, after T3 comment) | **ADD T3c (positive):** `assert_match("docs: pack-chat-only — governance edit", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, True, "T3c")` |
| I7 | (new) | **ADD T3d/T3e (ignore-via-retire):** `assert_match("docs: PM-only — BACKLOG update", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T3d: retired pm-only NOT recognized — Check 36 SKIPS, not reject")` + `assert_match("docs: pack-memory-only — trinity edit", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T3e: retired pack-memory-only NOT recognized")` |
| I8 | `assert_match("feat: BD-175 cross-surface work", mod._SCOPE_KEYWORDS_PM_ONLY, False, "T4c")` (:100) | → `mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY` (var-rename) |
| I9 | (new, near T5 embedded) | **ADD T5b/T5c/T5d (no-collision):** `assert_match("feat: vN — BD-209 rename (pack-chat-only)", mod._SCOPE_KEYWORDS_PACK_ONLY, False, "T5b: pack-only kw does NOT fire on a pack-chat-only subject")` + `assert_match("feat: thing (pack-only)", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T5c: pack-chat-only kw does NOT fire on a pack-only subject")` + `assert_match("feat: pack-chat-only-ish thing", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T5d: embedded")` |
| I10 | `assert_pm("pack-ops/BACKLOG.md", False, "T6d")` (:119) | **A13-FOLD → `True`** |
| I11 | `assert_pm("pack-ops/CHANGELOG.md", False, "T6e")` (:120) | **A13-FOLD → `True`** |
| I12 | A13 comment block (:114-118 "NO LONGER PM-only-permitted … former T6d/T6e file asserts are removed accordingly") | rewrite to the §6.3 restore narrative |
| I13 | **ALL remaining `PM-only` comment occurrences** — `# Scope-rule tests: PM-only PERMITTED-PATHS` (:104); `# T6: project-template trinity IS PM-only-permitted` (:105); `# …NO LONGER PM-only-permitted FILES…` (:115); `# T6j: …PACK-MEMORY-RATIONALE.md IS PM-only-permitted…` (:125) + `# …a PM-only commit touching the rationale doc` (:127) + `# …Mirrors the PACK-AGENTS.md § "PM-only files and directories"` (multi-line :128-129) + `# …PM-only-permitted, so a PM-only commit…` (:132); `# T7: supporting-docs is NOT PM-only-permitted` (:136); `# T8: per-entry tree directories are PM-only-permitted` (:140) | rename EVERY occurrence prose → "pack-chat-only"; rename the multi-line `§ "PM-only files and directories"` (:128-129) → `§ "pack-chat-only files and directories"` (this IS the §3.3 section-name cascade in the test surface — it EXISTS, multi-line) |
| I-CATCH-ALL | the test file in total has **18** occurrences under the broadened pattern `PM-only|pack-memory-only|PM_ONLY|pm[_-]only` (lines :50, :94, :95, :96, :100, :104, :105, :107, :115, :125, :127, :128, :132, :136, :140 — some lines carry 2; the test file has no bare `is_pm_only` local but `_is_pm_only_permitted` at :50/:107 is caught by `pm[_-]only`) | after I1-I13, run the §6 COMPLETENESS-VERIFICATION grep → ZERO `PM-only`-family tokens remain in the test file (no Sense-B-protected line exists in the test file, so the test file's allowed-exception count is ZERO) |

> **CASCADE CONFIRMED (corrects the prior plan's false "does NOT exist" note):** the test file DOES carry the section-name reference `§ "PM-only files and directories"` — it is the MULTI-LINE comment spanning :128-129 (`# … Mirrors the PACK-AGENTS.md § "PM-only files and / directories"`), which a single-line grep for the exact one-line phrase missed. It is renamed by I13 in lockstep with the C1 heading rename. There is NO phantom anchor and NO under-enumeration: Group I now covers every one of the test file's 18 occurrences, verified comprehensively by the §6 grep gate (not by hand-picking).

### Group J — manifest regen (`regenerate-manifest-v11-surface`)

| # | Task | Detail |
|---|---|---|
| J1 | regenerate `test-fixtures/manifest.txt` | run `bash test-fixtures/build.sh --all --clean`; stage `test-fixtures/manifest.txt` in the SAME commit IF its diff is non-empty. The commit touches `scripts/`, `pack-ops/`, and repo-root dotted dirs (`.claude/`, `.codex/`, `.gemini/`) — v11-surface (`scripts/`, `pack-ops/` are explicit v11-surface dirs). |

---

## 2A. Per-file coverage reconciliation (tasks == occurrences − Sense-B-protected)

Re-measured at HEAD `40867052` via `grep -oE 'PM-only|pack-memory-only|PM_ONLY|pm[_-]only' <file>` (the BROADENED pattern — `pm[_-]only` matches `pm-only`, `pm_only`, `is_pm_only`, `_is_pm_only`, `_is_pm_only_permitted`). For each Sense-A file: total occurrences, Sense-B-protected (LEAVE), Sense-A to-rename, and the task(s) that cover them. Coverage is enforcement-backed by the §6 COMPLETENESS-VERIFICATION grep, not by this table alone.

| File | Occ | Sense-B LEAVE | Sense-A rename | Covered by |
|---|---|---|---|---|
| CLAUDE.md | 12 | 0 | 12 | B1 (row :78 = 3 occ: `PM-only`×2 + the inner "ARE PM-only") + B4 prose (:376/:379×2/:385/:404/:405/:421/:444 = 9) |
| AGENTS.md | 12 | 0 | 12 | B2 (row :80 = 3 occ) + B4 prose (:336/:339×2/:351/:370/:371/:387/:410 = 9) |
| GEMINI.md | 11 | 0 | 11 | B3 (row :60 = 2 occ) + B4 prose (:303/:306×2/:318/:337/:338/:354/:377 = 9) |
| scripts/validate-pack.py | 37 | 2 (`:1608`,`:1615`) | 35 | A1 (:3732×3) A11 (:3734×2,:3757,:3758) A2 (:3740,:3744) A3 (:3759) A4 (:3908,:3909,:3910,:3911,:3913) A5 (:3950) A7 (:3983,:3986,:3987,:3990,:3991) A8 (:3920×2,:3928×2,:3929,:3930) A9 (:154×2,:155,:156) A10 (:4527) |
| scripts/tests/…36-37-38.sh | 18 | 0 | 18 | I1 (:50) I3 (:95) I4 (:96) I5 (:94) I8 (:100) I2 (:107) I12 (:115) I13 (:104,:105,:125,:127,:128,:132,:136,:140) — note :128 is the multi-line `§ "PM-only files and directories"` ref. Total 18. |
| pack-ops/PACK-AGENTS.md | 4 | 0 | 4 | C1 (:130) C3 (:154) C4 (:159) C5 (:162). Note: C6 renames a `PM Chat` (no hyphen) at :169 — NOT counted in the 4 `PM-only` occ; separate clarity fix. |
| pack-ops/PACK-CHAT.md | 3 | 0 | 3 | D1 (:15) D2 (:25) D3 (:101). The 2 archetype `PM chat` lines (:21/:23) are not `PM-only` occ; LEAVE. |
| pack-ops/PACK-MEMORY-RATIONALE.md | 6 | 0 | 6 | E1 (:179) E2 (:570) E3 (:573) E4 (:580) E5 (:588) E6 (:595) |
| pack-ops/.spawn-rule-manifest.txt | 1 | 0 | 1 | F1 (:57) |
| .claude/skills/commit-discipline/SKILL.md | 6 | 0 | 6 | G1-G6 (:3/:107/:127/:129/:132/:168) |
| .codex/skills/commit-discipline/SKILL.md | 6 | 0 | 6 | G1-G6 (identical anchors) |
| .gemini/skills/commit-discipline/SKILL.md | 6 | 0 | 6 | G1-G6 (identical anchors) |
| .claude/agents/pack-coder.md | 1 | 0 | 1 | H1 (:46) |
| .gemini/agents/pack-coder.md | 1 | 0 | 1 | H2 (:48) |
| .codex/agents/pack-coder.toml | 1 | 0 | 1 | H3 (:25) |
| **TOTAL** | **125** | **2** | **123** | every Sense-A occurrence assigned to a task; the 2 LEAVE = vp PROFILE_PHRASES |

**Under-enumeration flag (per the FIX directive):** the ONLY file the prior draft under-enumerated was the test file (Group I — now comprehensive). Re-reconciliation of the other 15 files with the BROADENED pattern (`pm[_-]only`, by-occurrence) finds NO further under-enumeration: every `PM-only`-family occurrence is assigned to a task, and the §6 grep gate (now using the broadened pattern that catches the bare `is_pm_only` local) would catch any residue regardless. **Count reconciliation:** validate-pack.py = 37 occ (NOT the reviewer's disputed 34; NOT a substantive miss vs ARCHITECTURE/RESEARCH 36 — that 36 is a narrower-pattern/by-line method artifact). Per-occurrence verbatim line:match lists captured in the §0 AUTHORITATIVE count block + §8 evidence.

---

## 3. Commit sequencing

**One commit (`pack-only`).** Justification:
- The rename is large but mechanical and INTERLOCKED — the var-rename (A1-A7) ↔ test required-symbol/helper (I1/I2/I8) are an ENCODING PAIR (`enumerate-encoding-surfaces`): if the validator symbol is renamed in a separate commit from the test, the intermediate commit's `validate-pack.py` import-check FAILS. They MUST land together. Likewise the A13-fold's 3 surfaces (A2 validator / I10-I12 test / C2 doc) must be atomic or an intermediate commit has a validator-vs-test disagreement. A multi-commit split cannot leave each intermediate commit validate-pack-green; a single commit is the only working-at-every-step shape.
- All touched paths are pack-side (`scripts/`, `pack-ops/`, repo-root trinity + dotted `.claude`/`.codex`/`.gemini` dirs, `test-fixtures/manifest.txt`). NO `project-template/` or `supporting-docs/` path is touched (Sense-B files are DENY). So a `pack-only` scope claim is HONEST and Check-36-clean.

**Commit file set (one commit):**
- `scripts/validate-pack.py` (Group A)
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (Group B)
- `pack-ops/PACK-AGENTS.md` (Group C)
- `pack-ops/PACK-CHAT.md` (Group D)
- `pack-ops/PACK-MEMORY-RATIONALE.md` (Group E)
- `pack-ops/.spawn-rule-manifest.txt` (Group F)
- `.claude/skills/commit-discipline/SKILL.md`, `.codex/skills/commit-discipline/SKILL.md`, `.gemini/skills/commit-discipline/SKILL.md` (Group G)
- `.claude/agents/pack-coder.md`, `.gemini/agents/pack-coder.md`, `.codex/agents/pack-coder.toml` (Group H)
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` (Group I)
- `test-fixtures/manifest.txt` (Group J, if diff non-empty)

**Scope keyword:** `pack-only`.

**Actor:** `pack-coder` (Groups A-J) → bounded review/fix cycle (§5) → Pack Chat commits.

---

## 4. The keyword-token trap on the LANDING commit (CRITICAL — BD-198 failure class)

After this commit lands, `pack-chat-only` BECOMES a recognized Check-36 token. The commit's OWN subject must therefore carry **no** literal scope-keyword token that would be mis-parsed as a scope claim against its own diff:

- The subject claims exactly ONE keyword: `pack-only` (the honest claim — pure pack-side diff).
- The subject MUST NOT contain the literal tokens `pack-chat-only`, `pm-only`, `pack-memory-only`, or a second `project-only` — any of which Check 36 would latch onto. In particular `pack-chat-only` would, after THIS commit makes it live, be parsed and DENY `scripts/` (the BD-198 trap exactly).
- Describe the work with NON-keyword vocabulary.

**Token-trap-safe subject (proposed):**
```
feat: v11 — BD-209 rename the overloaded commit-scope governance keyword + A13 fold (pack-only)
```
This contains only the single `pack-only` claim token; "commit-scope governance keyword" describes the renamed concept WITHOUT the literal `pack-chat-only` / `pm-only` / `pack-memory-only` tokens.

> Self-check before commit: `git show -s --format=%s HEAD` (post-commit) should contain exactly one of {`pack-only`, `project-only`, `pack-chat-only`} and it must be `pack-only`. (Pack Chat verifies; per `no-prestaging-until-commit-approval`, stage+commit named paths atomically at approval, no pre-staging.)

---

## 5. Actor + verification split

### 5.1 pack-coder deliverables (Groups A-J) — ONE commit's worth of edits
Coder edits the 16-file Sense-A set + the A13-fold + the new/swapped tests + regen the manifest. Coder does NOT touch Sense-B, does NOT commit.

**Coder PREFLIGHT (all must PASS before the IMPL-REPORT is written; per `preflight-stop-means-stop`):**
1. `python3 scripts/validate-pack.py` → GREEN (Check 43 + all checks).
2. `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` → all assertions PASS (incl. new T3c/T3d/T3e/T5b/T5c/T5d + flipped T6d/T6e).
3. **Sense-B-untouched grep-proof** (paste verbatim in the IMPL-REPORT):
   `grep -rn "No PM-only file edits" project-template/.claude/agents/coder.md project-template/.claude/agents/repo-ops.md project-template/.codex/agents/coder.toml project-template/.codex/agents/repo-ops.toml project-template/.gemini/agents/coder.md project-template/.gemini/agents/repo-ops.md project-template/docs/pack/PM-CHAT.md scripts/validate-pack.py`
   → must STILL show all 7 doc occurrences + `validate-pack.py:1608` + `:1615` byte-unchanged (PM-CHAT.md:480 reads "PM-only files (BACKLOG.md…"; the 2 PROFILE_PHRASES read `"No PM-only file edits"`).
4. **COMPLETENESS-VERIFICATION gate (measure-then-bound; catches ANY missed occurrence regardless of enumeration).** Run, across the exact 16-file Sense-A set:
   ```
   grep -rnE 'PM-only|pack-memory-only|PM_ONLY|pm[_-]only' \
     CLAUDE.md AGENTS.md GEMINI.md \
     scripts/validate-pack.py \
     scripts/tests/test-validate-pack-checks-36-37-38.sh \
     pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md pack-ops/PACK-MEMORY-RATIONALE.md \
     pack-ops/.spawn-rule-manifest.txt \
     .claude/skills/commit-discipline/SKILL.md .codex/skills/commit-discipline/SKILL.md .gemini/skills/commit-discipline/SKILL.md \
     .claude/agents/pack-coder.md .gemini/agents/pack-coder.md .codex/agents/pack-coder.toml
   ```
   → output MUST be EXACTLY the 2 documented Sense-B-protected lines and NOTHING else:
   - `scripts/validate-pack.py:1608:        "No PM-only file edits",` (PROFILE_PHRASES write-scoped — LEAVE)
   - `scripts/validate-pack.py:1615:        "No PM-only file edits",` (PROFILE_PHRASES write-script — LEAVE)
   ANY other matching line = a MISSED rename = PREFLIGHT FAIL (report what was missed, do NOT write a partial IMPL-REPORT). This grep is the authoritative completeness check — it does not depend on the §2 task enumeration being exhaustive; if a task list under-enumerates, this gate catches the residue.
   > **Pattern-blind-spot fix (plan-review HEAD `40867052`):** the lowercase alternative is `pm[_-]only`, NOT `pm-only`/`_is_pm_only` — the narrower form MISSED the bare local var `is_pm_only` (no leading underscore) at `validate-pack.py:3950`/`:3951`/`:3982` and the `pm_only` symbol fragments at `:3908`/`:3983`. Verified: `echo "if is_pm_only:" | grep -oE 'PM-only|pack-memory-only|PM_ONLY|pm-only|_is_pm_only'` → no match; the same with `pm[_-]only` → matches. `pm[_-]only` is strictly more inclusive (matches `pm-only`, `pm_only`, `is_pm_only`, `_is_pm_only`, `_is_pm_only_permitted`) with no new false positives.
5. Trinity parity: the three table rows (B1/B2/B3) + the ×3 prose (B4) express the same rule; SKILL ×3 (G) + pack-coder ×3 (H) lockstep-identical.
6. Manifest regen (J1) run; staged if diff non-empty.
7. PREFLIGHT line: `PREFLIGHT: N/N in-scope edits complete; validate-pack GREEN; Check-36 tests PASS; Sense-B UNTOUCHED (grep-proof attached); HEAD <SHA>; about to Write IMPL-REPORT to <path>`.

### 5.2 Pack Chat deliverables (NOT coder — Pack-Chat-direct upkeep)
These are flagged by the design (§8) as Pack-Chat upkeep, done DIRECTLY by Pack Chat (memory files + index are Pack Chat's own operating state), NOT coder edits:
- **Memory file `feedback_commit_subject_keyword_token_trap.md`** (`~/.claude/projects/…/memory/`) — update the worked example + token list to teach `pack-chat-only`; note `pm-only`/`pack-memory-only` are HARD-RETIRED (no longer parsed). Outside the git repo.
- **`MEMORY.md` index** — update the "Commit-subject keyword-token trap" description in lockstep.
- (At the version boundary, separately) `pack-ops/CHANGELOG.md` BD-209 entry + BD-209 BACKLOG status flip — Pack-Chat-direct bookkeeping, NOT this commit.

### 5.3 Review/fix cadence (`review-fix-cycle`)
Single-BD batch → one per-commit bounded cycle: coder → `pack-reviewer` pass 1 → (if findings) Pack-Chat triage to user → fix-coder pass 1 → reviewer pass 2 → … max 2 fix-coder + 1 final reviewer; architect escalation if still dirty. Pack Chat commits after a clean reviewer pass with user approval. Pack Chat does NO fixes itself.

---

## 6. Verification strategy

| Check | How | Pass criterion |
|---|---|---|
| validate-pack green | `python3 scripts/validate-pack.py` | exit 0; Check 36 + Check 46 (spawn-manifest) + Check 43 green |
| Check-36 regression tests | `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` | all PASS incl. new T3c (positive), T3d/T3e (retired-NOT-recognized), T5b/T5c/T5d (no-collision both directions + embedded), flipped T6d/T6e=True |
| hard-retire parser behavior | `_subject_has_keyword("docs: PM-only — x", _SCOPE_KEYWORDS_PACK_CHAT_ONLY)` | `False` (unrecognized → SKIP, not reject); `pack-chat-only` subject → `True` |
| no token-collision | T5b/T5c assertions | `pack-only` kw does NOT fire on a `pack-chat-only` subject and vice-versa |
| A13 fold restored | T6d/T6e=True + `pack-ops/BACKLOG.md`/`CHANGELOG.md` in `_PACK_CHAT_ONLY_PERMITTED_PATHS` + PACK-AGENTS Files list keeps them | validator + test + doc AGREE (all INCLUDE); validate-pack still green |
| trinity parity ×3 | diff the 3 table rows + the ×3 `## Pack memory` prose | same rule expressed; GEMINI abbreviated-style preserved |
| Sense-B untouched | §5.1 step-3 grep-proof | 7 doc occurrences + vp:1608/1615 byte-identical to HEAD `40867052` |
| COMPLETENESS-VERIFICATION (no Sense-A residue) — run by coder PREFLIGHT AND reviewer | `grep -rnE 'PM-only\|pack-memory-only\|PM_ONLY\|pm[_-]only' <the exact 16 Sense-A files>` (full file list in §5.1 step-4) | output is EXACTLY the 2 allowed exceptions and nothing else: `scripts/validate-pack.py:1608` + `:1615` (`"No PM-only file edits"` PROFILE_PHRASES, Sense-B, LEAVE). ANY other line = a missed rename = FAIL. This measure-then-bound gate is enumeration-independent. |
| manifest | `bash test-fixtures/build.sh --all --clean` then `git diff --stat test-fixtures/manifest.txt` | regenerated; staged in-commit if non-empty |
| landing-commit subject | §4 self-check | exactly one scope-keyword token = `pack-only`; no `pack-chat-only`/`pm-only`/`pack-memory-only` token in the subject |

---

## 7. Residual gaps + unknowns (surfaced, NOT resolved)

- **GAP-1 RESOLVED (was a prior-plan under-enumeration; now corrected).** The earlier draft hand-picked a subset of the test file's `PM-only` comments and FALSELY asserted the `§ "PM-only files and directories"` reference "does NOT exist" — a single-line grep missed the MULTI-LINE comment at `test:128-129`. Re-measured at HEAD `40867052`: the test file carries **18** `PM-only`-family occurrences (lines :50, :94, :95, :96, :100, :104, :105, :107, :115, :125, :127, :128, :132, :136, :140 — some carry 2). Group I is now a COMPREHENSIVE catch-all (I1-I13 + I-CATCH-ALL) covering every one, and the §6 COMPLETENESS-VERIFICATION grep gate (§5.1 step-4) enforces ZERO residue independent of the task enumeration. The `§ "PM-only files and directories"` test ref IS real and IS renamed (I13) in lockstep with the C1 heading + the validate-pack.py refs (:155-156, :3930, :3990-3991, :3758).
- **GAP-2 (sequencing dependency, owned by BD-203 — note only).** BD-209's A13-fold is a TRANSIENT restore valid only while `pack-ops/BACKLOG.md`/`CHANGELOG.md` exist on disk. BD-203 Commit 2 owns the INVERSE: `git rm` the two files AND re-remove them from `_PACK_CHAT_ONLY_PERMITTED_PATHS` + flip T6d/T6e back to `False` in the same atomic commit, AND build the new `/backlog/`+`/changelog/` trees with the CORRECT `pack-chat-only` keyword from birth. This plan does NOT do that work; it is noted for the lockstep contract.
- **GAP-3 (manifest diff unknown).** Whether `test-fixtures/manifest.txt` actually changes is unknown until `build.sh` runs — the SKILL/pack-coder/PACK-* files are content, so a non-empty diff is likely but not guaranteed. The coder regenerates and stages only if non-empty (J1 handles both branches; no decision needed).
- **No MAINTAINER CHECK NEEDED items.** All scope questions resolved against current repo state.

---

## 8. Rules-Applied Verification Block

### 8.1 READ-IN-FULL — per-file direct-read proof (every named doc + memory file)

| Named doc | Direct-Read proof (own Read/Bash call: line count or offset + first/last/unique-mid) | Conclusion |
|---|---|---|
| `ARCHITECTURE-BD-209.md` (IN FULL) | Read tool, 500 lines (offset 1, full). `:1` "# ARCHITECTURE — BD-209: rename the `PM-only` commit-scope keyword → `pack-chat-only`"; mid `:251` `_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)`; last `:500` "*End ARCHITECTURE-BD-209.md*". | COMPLIANT |
| `RESEARCH-BD-209-BLAST-RADIUS.md` (IN FULL) | Read tool, 427 lines (offset 1, full). `:1` "# RESEARCH — BD-209 Blast Radius…"; mid `:25` "`pack-chat-only` does **NOT** collide with `pack-only`…"; last `:427` "*End RESEARCH-BD-209-BLAST-RADIUS.md*". | COMPLIANT |
| BD-209 entry (`pack-ops/BACKLOG.md`) | Read tool offset 3410 limit 50. `:3419` "**BD-209 — Rename the `PM-only` commit-scope keyword → `pack-chat-only`…**"; `:3429` A13-fold binding decision; last in-entry `:3435` "Position: pack-self governance; rename-first, between BD-203 Commit 1 and Commit 2." | COMPLIANT |
| `scripts/validate-pack.py` Check 36 region | Read tool offset 3716 limit 300 + Bash `grep -noE 'PM-only\|pack-memory-only\|PM_ONLY\|pm[_-]only'` returning all 37 per-occurrence (incl. the bare locals `is_pm_only` at :3950/:3951/:3982 that the narrower pattern missed). `:3732` `_SCOPE_KEYWORDS_PM_ONLY`; `:3908` `def _is_pm_only_permitted`; `:3950` `is_pm_only = _subject_has_keyword(...)` (bare local, no leading `_`); `:3982` `if is_pm_only:`. :1608/:1615 PROFILE_PHRASES (LEAVE), :4527 comment. | COMPLIANT |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | Read tool offset 40 limit 110 + Bash `grep -nE 'PM-only\|pack-memory-only\|PM_ONLY\|pm[_-]only'` at HEAD `40867052` returning ALL 18 occurrences (lines :50,:94,:95,:96,:100,:104,:105,:107,:115,:125,:127,:128,:132,:136,:140). `:50` `'_is_pm_only_permitted',`; `:95-96` T3a/T3b; `:107` helper; `:119-120` T6d/T6e=False; `:128` MULTI-LINE `§ "PM-only files and / directories"` ref (CONFIRMED present — corrects the prior false "does NOT exist" note). | COMPLIANT |
| `CLAUDE.md ## Pack memory` IN FULL | Read tool offset 68 limit 22 (table region) + the full `## Pack memory` block present in spawn context (heading at CLAUDE.md `## Pack memory`); table row `:78` verbatim captured. Read SEPARATELY from each memory file below. | COMPLIANT |
| `feedback_commit_subject_keyword_token_trap.md` | Read tool, 38 lines (full). `name: commit-subject-keyword-token-trap`; `:19` "Check 36 latched onto `PM-only`, which denies `scripts/` paths"; last `:38` "…[[feedback_no_prestaging_until_commit_approval]]." | COMPLIANT |
| `feedback_manifest_regen_on_v11_surface.md` | Read tool, 16 lines (full). `name: manifest-regen-on-v11-surface`; `:11` "regenerates `test-fixtures/manifest.txt` …in the SAME commit when the diff is non-empty"; last `:15` "Related: test-infra self-provisioning (distinct concern)." | COMPLIANT |
| `feedback_no_prestaging_until_commit_approval.md` | Read tool, 24 lines (full). `name: no-prestaging-until-commit-approval`; `:10` "NEVER `git add` / stage files in advance."; last `:23` "Applies to every commit in this repo while concurrent sessions are possible…" | COMPLIANT |
| `feedback_review_fix_cycle.md` | Read tool, 33 lines (full). `name: review-fix-cycle`; `:12` "Per-commit cycle (max 3 reviewer / 2 fix-coder spawns)"; last `:32` "Cross-refs: [[pack-chat-boundaries]]…[[agent-prompt-enumerates-rules]]." | COMPLIANT |
| `feedback_ci_guard_design_measure_then_bound.md` | Read tool, 14 lines (full). `name: ci-guard-design-measure-then-bound`; `:10` "measure the repo first, categorize every occurrence KEEP …or STRIP …size the allowlist exactly to KEEP"; last `:14` "Related: [[architect-planner-empirical-evidence]], [[triage-workflow-protocol]]." | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Read tool, 33 lines (full). `name: pack-project-separation-of-concerns`; `:15` "Cross-side substitution is FORBIDDEN."; last `:32` "Cross-refs: [[bd-pack-only-operational-rule]]…" | COMPLIANT |
| `feedback_edit_in_place_not_full_rewrite.md` | Read tool, 14 lines (full). `name: edit-in-place-not-full-rewrite`; `:12` "on the v5 pass it silently DROPPED an entire section (§9.8 classification table)"; last `:14` "…[[feedback_pack_chat_no_coder_review]] (independent verification)." | COMPLIANT |
| `feedback_scope_deliverables_to_the_ask.md` | Read tool, 34 lines (full). `name: scope-deliverables-to-the-ask-no-noise`; `:25` "…this is a disaster and why we're in this mess."; last `:34` "…the user's standing preference for terse, exactly-scoped work." | COMPLIANT |
| `feedback_architect_planner_empirical_evidence.md` | Read tool, 14 lines (full). `name: architect-planner-empirical-evidence`; `:10` "command + verbatim output + HEAD SHA + date + interpretation + SUPPORTED / NOT-SUPPORTED / PARTIAL"; last `:14` "Related: [[agent-output-rules-applied-block]], [[ci-guard-design-measure-then-bound]]." | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` | Read tool, 14 lines (full). `name: agent-output-rules-applied-block`; `:10` "per rule: name + quoted evidence + COMPLIANT / N/A:‹reason› / VIOLATED:‹reason›; empty = VIOLATED"; last `:14` "Related: [[agent-prompt-enumerates-rules]], [[architect-planner-empirical-evidence]]." | COMPLIANT |
| `feedback_agents_read_rule_docs_in_full.md` | Read tool, 117 lines (full). `name: agents-read-rule-docs-in-full`; `:98` "No-cache-substitution clause"; last `:117` "…accepting a derived-not-read attestation erodes the very standard that catches the dangerous cases." | COMPLIANT |

### 8.2 Per-rule compliance

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION + NO-CACHE-SUBSTITUTION | §8.1: each named doc + 11 memory files Read DIRECTLY via Read tool with per-file line count + first/last/unique-mid proof; `CLAUDE.md ## Pack memory` read SEPARATELY from the memory files; nothing derived from cache. | COMPLIANT |
| empirical-evidence-blocks | §0 carries TWO blocks: HEAD+design-vs-reality AND the AUTHORITATIVE count-reconciliation (command + verbatim per-occurrence output + HEAD-SHA + interpretation settling 37-vs-36-vs-34 + SUPPORTED); §2A per-file reconciliation table backed by per-file `grep -oE 'PM-only\|pack-memory-only\|PM_ONLY\|pm[_-]only'` counts (125 total, 2 LEAVE, 123 rename). | COMPLIANT |
| commit-subject-keyword-token-trap | §4: landing-commit subject claims only `pack-only`; MUST NOT contain `pack-chat-only`/`pm-only`/`pack-memory-only`; token-trap-safe subject proposed + post-commit self-check specified. | COMPLIANT |
| manifest-regen-on-v11-surface | §2 Group J + §5.1 step-6 + §6 row: `bash test-fixtures/build.sh --all --clean`; stage manifest in SAME commit if diff non-empty (commit touches scripts/ + pack-ops/). | COMPLIANT |
| review-fix-cycle | §5.3: single-BD bounded cycle (coder → reviewer → triage → fix-coder, max 2 fix + 1 final reviewer + architect escalation); Pack Chat no fixes. | COMPLIANT |
| ci-guard-measure-then-bound | §0/§2/§2A measured the tree with the BROADENED pattern `pm[_-]only` (per-occurrence); categorized every occurrence RENAME (123 Sense-A) vs LEAVE (2 Sense-B PROFILE_PHRASES vp:1608/1615); sized the allowlist exactly to 123. **Gate blind-spot CLOSED:** the verify-clean grep was broadened from `pm-only\|_is_pm_only` (which missed the bare local `is_pm_only` at :3950/:3951/:3982 — verified `echo "if is_pm_only:" | grep -oE '…old…'` = no match) to `pm[_-]only` (matches; strictly more inclusive, no new false positives). The §6 gate runs by coder PREFLIGHT AND reviewer; output must be EXACTLY the 2 documented exceptions. New tests I6-I9 confirm the projected post-fix parser state (design §7.1). | COMPLIANT |
| edit-in-place | §2: every task is a targeted in-place anchor edit (quoted old→new string), never a whole-file rewrite. | COMPLIANT |
| scope-deliverables-to-the-ask | Plan delivers exactly (A) breakdown (B) commit shape (C) actor/verification split (D) verification (E) residual gap; no padding; GAP-1/2/3 fenced under §7. | COMPLIANT |
| agents-never-commit | This is a plan; Pack Chat commits (§3/§5.2). No git verbs proposed for any agent. | COMPLIANT |
| rules-applied-verification-block | This §8: §8.1 per-file READ-IN-FULL proof + §8.2 per-rule table; no empty rows; no VIOLATED rows. | COMPLIANT |

**No VIOLATED rows. No empty evidence.**

---

*End PLAN-BD-209.md*
