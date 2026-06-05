# ARCHITECTURE — BD-209: rename the `PM-only` commit-scope keyword → `pack-chat-only`

**Author:** pack-architect · **HEAD:** `4086705` (`40867052b31e822e1742de4806016bdca1131f6e`) · **Date:** 2026-06-04 · **Branch:** v11-dev
**Deliverable:** the IMPLEMENTABLE rename design + A13-fold + alias policy + new regression tests, sized exactly to the verified Sense-A legitimate set. DESIGN ONLY — no source edits, no git verbs.
**Designed AGAINST:** `maintenance-docs/v11-implementation/RESEARCH-BD-209-BLAST-RADIUS.md` (the exhaustive blast-radius map). Every load-bearing count below was independently re-verified at HEAD `4086705` (see Empirical-Evidence Blocks).

---

## 0. HEADLINE — the ruling that governs every edit

BD-209 renames ONE concept: the Check-36 pack-repo **commit-scope keyword** `PM-only` (alias `pack-memory-only`) → `pack-chat-only`. The research found the spelling `PM-only` is shared by **two distinct concepts** (Sense A / Sense B). The single most important design decision is the **Sense-A/B predicate** (§1): it is the safety crux that stops the coder mis-touching the project-side concept.

**Rulings (this design):**
1. **Sense B is OUT and STAYS** (§1). Renaming it would be both a `pack-project-separation-of-concerns` boundary violation AND a semantic regression. The predicate in §1.3 mechanically separates the two.
2. **Aliases: HARD-RETIRE `pm-only` + `pack-memory-only`** (§4; user override 2026-06-05). The parser tuple becomes `("pack-chat-only",)` only. Retired tokens → unrecognized → Check 36 SKIPS (ungated, no reject); HEAD-only walk means historical commits are unaffected either way.
3. **Internal vars: RENAME** `_PM_ONLY_*` → `_PACK_CHAT_ONLY_*` (§5). The BD permits it; leaving them creates a permanent name-vs-concept drift identical to the bug BD-209 fixes.
4. **A13 FOLD: RESTORE** `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` to the permitted set across the 3 encoding surfaces (§6); the removal moves to BD-203 Commit 2.
5. **New regression tests** assert `pack-chat-only` detection + the no-`pack-only`-collision property + ignore-via-retire (old tokens NOT recognized) (§7).

**The rename set is EXACTLY 16 active Sense-A files / ~130 occurrences** (§3), + 1 out-of-repo memory file (Pack-Chat-direct, not a coder edit, §8), + the `test-fixtures/manifest.txt` regen (§9). The 2 Sense-B-coupled PROFILE_PHRASES (`validate-pack.py:1608/1615`) and the 7 project-side Sense-B files are **NOT touched**.

---

## 1. Sense-A vs Sense-B ruling (THE SAFETY CRUX)

### 1.1 The two concepts

| | Sense A (RENAME) | Sense B (LEAVE) |
|---|---|---|
| **Meaning** | The pack-repo Check-36 commit-scope keyword: "this commit only touches Pack-Chat-direct PACK-governance files." | The genuine project-manager-chat agent rule in a CLIENT repo: "agents must not edit the project's `BACKLOG.md`/`CHANGELOG.md`/`STATUS.md`/`PACK-FEEDBACK.md`." |
| **Audience** | Pack developers (pack-self governance). | Client developers (shipped deliverable). |
| **"PM" refers to** | (mis-named) the *Pack* Chat. This is the overload BD-209 fixes. | the *project* PM Chat — correctly named. |
| **Disposition** | RENAME → `pack-chat-only`. | OUT OF SCOPE; unchanged. |

### 1.2 Why Sense B must NOT be renamed (challenge of the binding decision)

The binding decision is the user's and is FIXED, but I stress-tested its realizability per `preliminary-triage-architect-challenge`. The challenge CONFIRMS the OUT ruling and surfaces no blocking coupling:

- **Boundary (`bd-pack-only-operational-rule` + `pack-project-separation-of-concerns`):** Sense B lives under `project-template/` (a client deliverable, directory-based test). `pack-chat-only` is a PACK-SELF keyword. Importing it into client deliverables is a categorical leak — exactly the rule's prohibited shape.
- **Semantics:** Sense B *correctly* means the project PM Chat. Renaming "No PM-only file edits" → "No pack-chat-only file edits" in a client coder agent would be FALSE for the client (there is no "Pack Chat" in a client repo).
- **No co-occurrence:** Research §8 confirmed (and I re-verified, §1.4) that Sense A and Sense B NEVER appear in the same file. The split is clean — no file requires a partial edit.

### 1.3 The PRECISE predicate (the coder's mechanical filter)

A `PM-only` / `pack-memory-only` occurrence is **Sense A (RENAME)** if and only if its containing file path matches the **explicit Sense-A allowlist of 16 files** in §3.2. EVERY other occurrence is **Sense B or historical (LEAVE)**. This is an allowlist predicate, not a heuristic — the coder renames ONLY inside the 16 enumerated paths and touches nothing else.

Equivalent decision rule, stated three independent ways so the coder cannot mis-bucket:

- **By path (primary, authoritative):** path ∈ the 16-file Sense-A set (§3.2) → RENAME. Else LEAVE.
- **By directory (corroborating):** an occurrence under `project-template/` is **Sense B → LEAVE** (the sole exception is the `project-template/{CLAUDE,AGENTS,GEMINI}.md` trinity — but those carry NO keyword convention table and NO `PM-only` occurrence, verified §1.4, so this exception is empty in practice). An occurrence in `maintenance-docs/` is **historical → LEAVE**. An occurrence in a `git log` subject is **historical → LEAVE** (Check 36 = HEAD-only).
- **By the validator coupling (the hard interlock):** `validate-pack.py:1608` and `:1615` (`PROFILE_PHRASES["write-scoped"]` / `["write-script"]` = `"No PM-only file edits"`) assert the EXACT phrase in the **project-side** `coder`/`repo-ops` agents (`WRITE_SCOPED_AGENTS = {"coder"}`, `WRITE_SCRIPT_AGENTS = {"repo-ops"}`, verified §1.4). Those are Sense B. **The two PROFILE_PHRASES constants are NEVER touched by BD-209.** If a proposed edit would force a PROFILE_PHRASES change, the edit is mis-bucketed Sense B — STOP.

### 1.4 Empirical-Evidence Block — the Sense-A/B split is clean

```
CLAIM 1: the project-side coder/repo-ops agents (Sense B) are the ONLY agents the
         two PROFILE_PHRASES "No PM-only file edits" validate; pack-coder is NOT
         in those profile sets.
COMMAND: grep -n 'WRITE_SCOPED_AGENTS\|WRITE_SCRIPT_AGENTS' scripts/validate-pack.py
OUTPUT:  1581:WRITE_SCOPED_AGENTS = {"coder"}
         1582:WRITE_SCRIPT_AGENTS = {"repo-ops"}
HEAD-SHA: 4086705   DATE: 2026-06-04
INTERPRETATION: PROFILE_PHRASES["write-scoped"]/["write-script"] are checked only
  against agents whose stem ∈ {coder, repo-ops}; pack-coder has stem `pack-coder`
  ∉ either set, so its "No PM-only file edits" line is NOT PROFILE_PHRASES-asserted.
CONCLUSION: SUPPORTED. Renaming pack-coder's line (Sense A) cannot trip PROFILE_PHRASES;
  renaming the project coder/repo-ops lines (Sense B) WOULD — hence Sense B stays.

CLAIM 2: "No PM-only file edits" lives in exactly 9 active files: 3 pack-coder
         (Sense A) + 6 project-side coder/repo-ops (Sense B). The rest are historical.
COMMAND: grep -rln "No PM-only file edits" --include="*.md" --include="*.toml" . | grep -v ".git/"
OUTPUT (active, non-maintenance-docs):
  .claude/agents/pack-coder.md
  .codex/agents/pack-coder.toml
  .gemini/agents/pack-coder.md
  project-template/.claude/agents/coder.md
  project-template/.claude/agents/repo-ops.md
  project-template/.codex/agents/coder.toml
  project-template/.codex/agents/repo-ops.toml
  project-template/.gemini/agents/coder.md
  project-template/.gemini/agents/repo-ops.md
  (+ ~14 maintenance-docs/* historical reports — LEAVE)
HEAD-SHA: 4086705   DATE: 2026-06-04
INTERPRETATION: pack-coder ×3 = Sense A (RENAME, §3.2 row); project coder/repo-ops
  ×6 = Sense B (LEAVE); maintenance-docs = historical (LEAVE).
CONCLUSION: SUPPORTED.

CLAIM 3: the project-template trinity carries NO commit-scope-keyword convention
         table and NO PM-only occurrence (so the §1.3 "by-directory" exception is empty).
COMMAND: for f in project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md; do
           echo -n "$f: "; grep -ocE "PM-only|pack-memory-only|Commit-subject scope-keyword" "$f"; done
         (research §8.5 ran the equivalent grep; returned empty)
RESULT: research §8.5 confirmed empty; consistent with the keyword convention being
  wholly pack-side (CLAUDE.md:74-79 table has no project-template twin).
HEAD-SHA: 4086705   DATE: 2026-06-04
CONCLUSION: SUPPORTED — Sense A is wholly pack-side; Sense B is wholly project-side;
  they never co-occur in one file.
```

---

## 2. New canonical vocabulary (the rename targets)

| Old | New |
|---|---|
| keyword token (claim) | `pack-chat-only` (the ONLY recognized token; `pm-only`/`pack-memory-only` HARD-RETIRED — §4) |
| `_SCOPE_KEYWORDS_PM_ONLY` | `_SCOPE_KEYWORDS_PACK_CHAT_ONLY` |
| `_PM_ONLY_PERMITTED_PATHS` | `_PACK_CHAT_ONLY_PERMITTED_PATHS` |
| `_PM_ONLY_PERMITTED_PREFIXES` | `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` |
| `_is_pm_only_permitted` | `_is_pack_chat_only_permitted` |
| local `is_pm_only` | `is_pack_chat_only` |
| PACK-AGENTS § heading `PM-only files and directories` | `pack-chat-only files and directories` |
| prose "PM-only file(s)/set/edit" (Sense A only) | "pack-chat-only file(s)/set/edit" |

**Prose-vs-keyword distinction (§12.4 ruling).** In Sense-A prose, "PM-only" is used for both the commit KEYWORD and the FILE SET. Adopt `pack-chat-only` **uniformly** for both — the whole point of the rename is that the file set and the keyword name the SAME concept (Pack-Chat-direct governance files). No two-term split; a uniform rename is the simplest correct design (fewer conventions, fewer special cases).

---

## 3. The EXACT rename set — measure-then-bound

### 3.1 Empirical-Evidence Block — the active Sense-A surface is exactly 16 files / 130 occurrences

```
CLAIM: the editable Sense-A surface is exactly 16 files; per-file occurrence counts as below.
COMMAND: per-file `grep -ocE "PM-only|pack-memory-only"` (+ symbol greps for validate-pack.py)
OUTPUT (re-verified at HEAD; counts match research §11.3):
  12  CLAUDE.md
  12  AGENTS.md
  11  GEMINI.md
  36  scripts/validate-pack.py          (34 Sense-A + 2 Sense-B-coupled PROFILE_PHRASES — the 2 LEAVE)
  18  scripts/tests/test-validate-pack-checks-36-37-38.sh
   4  pack-ops/PACK-AGENTS.md
   3  pack-ops/PACK-CHAT.md             (3 Sense-A; +2 "PM chat" archetype-prose lines LEAVE)
   6  pack-ops/PACK-MEMORY-RATIONALE.md
   1  pack-ops/.spawn-rule-manifest.txt
   6  .claude/skills/commit-discipline/SKILL.md
   6  .codex/skills/commit-discipline/SKILL.md
   6  .gemini/skills/commit-discipline/SKILL.md
   1  .claude/agents/pack-coder.md
   1  .gemini/agents/pack-coder.md
   1  .codex/agents/pack-coder.toml
HEAD-SHA: 4086705   DATE: 2026-06-04
INTERPRETATION: trinity counts re-verified directly (12/12/11). Sense-A occurrence
  sum = 130 across 16 files (excludes the 2 Sense-B-coupled PROFILE_PHRASES).
CONCLUSION: SUPPORTED.
```

### 3.2 Per-file edit list (the 16-file Sense-A allowlist)

Every edit is a **targeted in-place edit** (`edit-in-place-not-full-rewrite`): replace the named anchor only; never re-emit a whole file. Anchors are quoted strings, not line numbers (line numbers drift).

#### F1–F3 · Trinity convention table + prose (CLAUDE.md / AGENTS.md / GEMINI.md) — RENAME ×3 lockstep

The convention table is NOT tool-specific, so the trinity rule applies: all three change in the same commit. GEMINI.md keeps its existing abbreviated style (intentional asymmetry — preserve on rename, per `cross-cli-reference-normalization`).

| File | Anchor (old → new) |
|---|---|
| CLAUDE.md (table row) | `` | `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | … `` → `` | `pack-chat-only` | Pack-Chat-direct-edit only | … `` (no alias clause — old tokens hard-retired, §4) |
| AGENTS.md (table row) | byte-parallel to CLAUDE.md |
| GEMINI.md (table row) | `` | `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | … `` → `` | `pack-chat-only` | … `` (abbreviated style preserved; no alias clause — §4) |

Sense-A `## Pack memory` / Pack-Chat-scope prose anchors (RENAME, trinity-parallel — each appears in all three, offset by location):
- "PM-only files (BACKLOG.md / CHANGELOG.md / README version table / …" → "pack-chat-only files (…"
- "see `PACK-AGENTS.md` § … for the PM-only list. PM-only IS Pack-Chat-direct by construction." → "… the pack-chat-only list. pack-chat-only IS Pack-Chat-direct by construction."
- "On the small PM-only set — `BACKLOG.md`, …" → "On the small pack-chat-only set — …"
- "Pack Chat scoping a PM-only file INTO a coder prompt … major PM-only work" → "… a pack-chat-only file … major pack-chat-only work"
- "direct PM-only edit + which file" → "direct pack-chat-only edit + which file"
- "framing a batch as `pack-only`, `project-only`, or `PM-only` in commit subjects" → "… or `pack-chat-only` in commit subjects" (this one IS the keyword sense)

> **Token-trap interlock (`commit-subject-keyword-token-trap`):** the example/prose lines that now contain the literal token `pack-chat-only` are PROSE inside trinity docs, NOT commit subjects — Check 36 scans commit subjects, not file bodies, so no gate trip. The coder must ensure no NEW literal `pack-only`/`project-only`/`pack-chat-only` token is introduced into the BD-209 COMMIT SUBJECT beyond the single claimed keyword.

#### F4 · `scripts/validate-pack.py` — RENAME + VAR-RENAME + A13-FOLD (34 Sense-A occ; the 2 PROFILE_PHRASES LEAVE)

| Anchor | Edit |
|---|---|
| `_SCOPE_KEYWORDS_PM_ONLY = ("pm-only", "pack-memory-only")` | VAR-RENAME → `_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)` — ONLY `pack-chat-only`; `pm-only`/`pack-memory-only` HARD-RETIRED, parser no longer recognizes them (§4) |
| `_PM_ONLY_PERMITTED_PATHS = { … }` | VAR-RENAME → `_PACK_CHAT_ONLY_PERMITTED_PATHS`; **A13-FOLD** add `"pack-ops/BACKLOG.md"`, `"pack-ops/CHANGELOG.md"` (§6); rewrite the `# BD-203 A13: …removed here…` comment to the restore narrative (§6.3) |
| `_PM_ONLY_PERMITTED_PREFIXES = ( … )` | VAR-RENAME → `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` (content unchanged) |
| `def _is_pm_only_permitted(path)` + body refs `_PM_ONLY_PERMITTED_PATHS` / `_PREFIXES` + docstring "A path is PM-only-permitted if…" | VAR-RENAME → `_is_pack_chat_only_permitted`; update both constant refs; docstring → "pack-chat-only-permitted" |
| `is_pm_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PM_ONLY)` | local → `is_pack_chat_only = _subject_has_keyword(subject, _SCOPE_KEYWORDS_PACK_CHAT_ONLY)` |
| `if not (is_pack_only or is_project_only or is_pm_only):` | → `… or is_pack_chat_only):` |
| `if is_pm_only:` block + `fail(… claims \`PM-only\` but touches non-PM-only paths … (PM-only permitted set per … § 'PM-only files and directories'))` | → `if is_pack_chat_only:`; fail message → "claims \`pack-chat-only\` but touches non-pack-chat-only paths … (pack-chat-only permitted set per pack-ops/PACK-AGENTS.md § 'pack-chat-only files and directories')" |
| `check_commit_scope_honesty` docstring (lists `PM-only`/`pack-memory-only`; "§ 'PM-only files and directories'") | RENAME docstring prose → `pack-chat-only` (single token, no aliases) + renamed § name |
| Module check-registry docstring (lines ~151–160: "`PM-only` / `pack-memory-only`", "PM-only PERMITTED-PATHS … § 'PM-only files and directories'") | RENAME docstring prose + renamed § name |
| comment "pack-root trinity … are PM-only operating rules" (~line 4527) | RENAME prose → "pack-chat-only operating rules" (Sense A; pack-root audience) |
| `_SCOPE_KEYWORDS_PM_ONLY` heading comment "PM-only PERMITTED-PATHS per …" (~3734) + "PM-only PERMITTED-PATH PREFIXES" (~3757) | RENAME comment prose |
| **`PROFILE_PHRASES["write-scoped"]`/`["write-script"]` = `"No PM-only file edits"` (lines 1608/1615)** | **LEAVE — Sense B (§1.3 interlock). Do NOT touch.** |

#### F5 · `pack-ops/PACK-AGENTS.md` — RENAME + section-name cascade + A13-FOLD doc (4 occ)

| Anchor | Edit |
|---|---|
| heading "**PM-only files and directories** are off-limits to all agents…" | RENAME heading → "**pack-chat-only files and directories**" — drives the §3.3 cascade |
| Files list rows for `BACKLOG.md` / `CHANGELOG.md` ("regenerated mirror; per-entry source at …") | **A13-FOLD: KEEP listed** (the doc is already correct for the restore — §6.3); no deletion |
| "per-entry files (e.g., `BD-NNN.md`, …) are PM-only writes." | RENAME → "pack-chat-only writes" |
| "the same exception clause that applies to the PM-only files above." | RENAME → "pack-chat-only files" |
| "scoping a PM-only file into a coder prompt is the DEFAULT path…" | RENAME → "pack-chat-only file" |
| "bypassing Pack Chat / PM Chat write authority" (line ~169) | RENAME the stray "PM Chat" → "Pack Chat" (clarity fix; this is the in-prose instance of the overload BD-209 cites — see §12.6 ruling) |

#### F6 · `pack-ops/PACK-CHAT.md` — RENAME prose (3 Sense-A; 2 archetype lines LEAVE)

| Anchor | Edit |
|---|---|
| "…to the small PM-only set directly; route every MAJOR edit…" | RENAME → "small pack-chat-only set" |
| "bookkeeping edits + new-entry authoring on the small PM-only set directly" | RENAME → "small pack-chat-only set" |
| "On the small PM-only set Pack Chat applies directly only…" | RENAME → "small pack-chat-only set" |
| "Follow the same core behavioral rules as any **PM chat**" | **LEAVE — the genuine project-PM-Chat archetype.** Correct usage. |
| "You are **not** a coding project PM chat." | **LEAVE — correct disambiguating usage.** |

#### F7 · `pack-ops/PACK-MEMORY-RATIONALE.md` — RENAME prose (6 occ; Sense A)

RENAME all six "PM-only" → "pack-chat-only": "C6 PM-only allowlist gap"; "edit PM-only files directly at ANY depth"; "hand-edited substantial PM-only content"; "Classify every PM-only edit"; "Scoping a PM-only file"; "keep editing PM-only at any depth".

#### F8 · `pack-ops/.spawn-rule-manifest.txt` — RENAME prose (1 occ)

`references:` free-text "(PM-only scope-in = default major-edit path)" → "(pack-chat-only scope-in = default major-edit path)". **Validation note (verified §3.4):** Check 46 asserts only structural fields (`slug`, `canonical` contains `## Pack memory`, `references` names a known basename) — it does NOT assert this free-text substring, so the edit is safe and needs no test change.

#### F9–F11 · `commit-discipline/SKILL.md` ×3 (`.claude` / `.codex` / `.gemini`) — RENAME ×3 lockstep (6 occ each)

Pack-side skills (repo-root dotted dirs), Sense A. Trinity-style ×3 lockstep; preserve the `x-` client contract (`skill-agent-maintenance-mechanical`). Anchors (identical in all three): description "…PM-only file boundaries…"; "## 4. PM-only file boundaries"; "does not authorize a PM-only edit"; "seems to require a PM-only edit"; "the PM-only file"; "→ PM-only, forbidden by section 4". RENAME each → "pack-chat-only". The §4 Files list (BACKLOG.md / CHANGELOG.md / … / project-template trinity) stays content-correct under the A13 restore.

#### F12–F14 · `pack-coder` agent ×3 (`.claude` `.md` / `.gemini` `.md` / `.codex` `.toml`) — RENAME ×3 lockstep (1 occ each)

Anchor: "**No PM-only file edits without explicit caller instruction.**" → "**No pack-chat-only file edits without explicit caller instruction.**" These are the PACK `pack-coder` agent (stem `pack-coder`), Sense A — NOT PROFILE_PHRASES-validated (§1.4 CLAIM 1). Do NOT confuse with project-side `coder`/`repo-ops` (Sense B, LEAVE).

### 3.3 Section-name cascade (§12.5 ruling) — RENAME heading + ALL literal cross-refs in lockstep

Renaming the PACK-AGENTS heading "PM-only files and directories" → "pack-chat-only files and directories" propagates to every literal `§ 'PM-only files and directories'` reference (`enumerate-encoding-surfaces`). All are inside the 16-file set, so each is already covered by an F-row above; this is the lockstep checklist:
- `validate-pack.py` fail message + `check_commit_scope_honesty` docstring + module registry docstring (F4)
- `test-validate-pack-checks-36-37-38.sh` test comment "§ 'PM-only files and directories'" (F15, §7)
- (informational) the `BACKLOG.md` BD-198/BD-208 entries reference "§ PM-only" — Pack-Chat-direct bookkeeping, §8, NOT a coder edit.

### 3.4 Empirical-Evidence Block — the spawn-manifest free-text is NOT validated

```
CLAIM: Check 46 asserts spawn-rule-manifest STRUCTURE only, not the "PM-only scope-in" free-text.
COMMAND: read scripts/validate-pack.py spawn-manifest block (~6722-6774)
OUTPUT: validator checks: record has `slug:`+`references:`; `canonical:` contains
  "## Pack memory"; `references:` names a known basename ∈ {PACK-AGENTS.md, PACK-CHAT.md}
  AND that file exists AND contains "## Pack memory". No assertion of "PM-only" substring.
HEAD-SHA: 4086705   DATE: 2026-06-04
INTERPRETATION: F8 free-text rename cannot break Check 46.
CONCLUSION: SUPPORTED.
```

---

## 4. Alias-vs-retire decision — HARD-RETIRE `pm-only` + `pack-memory-only` (user override 2026-06-05)

**Decision (user override 2026-06-05, SUPERSEDES this design's prior keep-as-alias ruling): HARD-RETIRE both old tokens.** New tuple:
`_SCOPE_KEYWORDS_PACK_CHAT_ONLY = ("pack-chat-only",)` — ONLY `pack-chat-only`. The parser no longer recognizes `pm-only`/`pack-memory-only` at all.

**User rationale:** keep-as-alias (ALLOW) and hard-retire (IGNORE) are a distinction without a difference — both let a `pm-only` commit through (ALLOW passes the permitted-set check; IGNORE is an unrecognized token → no scope claim → Check 36 SKIPS it ungated). So the alias buys nothing. Hard-retire is the truly forward-looking move and leaves a clean slate to add an explicit REJECT later if ever wanted.

**No reject now.** A stray `(pm-only)` simply becomes an unrecognized token → no scope claim → Check 36 SKIPS it (passes ungated). That is acceptable for now; a future BD can flip retire → reject by special-casing the old tokens if drift becomes a problem.

**Behavior under the retired tuple (verified §4.1):**
- a `pack-chat-only` subject → recognized → permitted-set check fires (the intended gate);
- a `pm-only` / `pack-memory-only` subject → NOT recognized → no claim → Check 36 SKIPS (ungated, no failure).

**Historical-commit behavior (Check 36 = HEAD-only):** Check 36 walks only HEAD by default. The 32 historical `(PM-only)` subjects are NEVER re-checked, so hard-retire is CI-neutral on normal pushes — they were already only HEAD-gated. Under a hypothetical wide-range audit (`PACK_CHECK_36_RANGE=origin/main..HEAD`) those 32 commits become unrecognized → SKIPPED (no claim) rather than failed — acceptable per the user's ignore-for-now ruling. No landed commit subject is rewritten (`git`-history rewrite is banned).

### 4.1 Empirical-Evidence Block — the retired tuple ignores old tokens; Check 36 is HEAD-only

```
CLAIM A: with the hard-retire tuple ("pack-chat-only",), the parser recognizes
         pack-chat-only but NOT pm-only / pack-memory-only.
COMMAND: python3 -c "...load validate-pack...; f=mod._subject_has_keyword;
         RETIRED=('pack-chat-only',); print(f('docs: PM-only — BACKLOG update',RETIRED),
         f('docs: pack-memory-only — trinity edit',RETIRED),
         f('docs: pack-chat-only — governance edit',RETIRED))"
OUTPUT:
  G pm-only subj vs retired tuple: False            # unrecognized → no claim → SKIP
  H pack-memory-only subj vs retired tuple: False   # unrecognized → no claim → SKIP
  I pack-chat-only subj vs retired tuple: True       # recognized → gate fires
HEAD-SHA: 4086705   DATE: 2026-06-04
INTERPRETATION: hard-retire works as designed — old tokens become unrecognized
  (SKIP, not fail/reject), new token gates.
CONCLUSION: SUPPORTED.

CLAIM B: Check 36 default walk = HEAD only; historical (PM-only) commits not re-checked.
COMMAND: read _commits_to_walk() (scripts/validate-pack.py ~3797-3843)
OUTPUT: range_spec = os.environ.get("PACK_CHECK_36_RANGE", "HEAD~0..HEAD");
        if range_spec == "HEAD~0..HEAD": cmd = ["git","log","-1","--format=%H%x09%s","HEAD"]
HEAD-SHA: 4086705   DATE: 2026-06-04
INTERPRETATION: default walk is a single commit (HEAD); historical (PM-only) commits
  unaffected by hard-retire (they were only ever HEAD-gated).
CONCLUSION: SUPPORTED — hard-retire is CI-neutral on normal pushes.
```

---

## 5. Internal var rename — RENAME `_PM_ONLY_*` → `_PACK_CHAT_ONLY_*`

**Decision: RENAME all four symbols + the local + every use site.** The BD permits but does not mandate; I rule RENAME because leaving `_PM_ONLY_*` symbols behind reproduces the exact name-vs-concept drift BD-209 exists to eliminate (a future reader sees `_PM_ONLY_PERMITTED_PATHS` and re-learns the wrong mental model).

Use sites (all in `validate-pack.py` + its test; no other file references the symbols — verified by research §2, re-confirmed by the symbol grep yielding only these):

| Symbol (old → new) | Definition + use sites |
|---|---|
| `_SCOPE_KEYWORDS_PM_ONLY` → `_SCOPE_KEYWORDS_PACK_CHAT_ONLY` | def in validate-pack.py; use in `check_commit_scope_honesty`; test refs `mod._SCOPE_KEYWORDS_PM_ONLY` (×3: T3a/T3b/T4c) |
| `_PM_ONLY_PERMITTED_PATHS` → `_PACK_CHAT_ONLY_PERMITTED_PATHS` | def + 1 use in `_is_pack_chat_only_permitted` |
| `_PM_ONLY_PERMITTED_PREFIXES` → `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` | def + 1 use in `_is_pack_chat_only_permitted` |
| `_is_pm_only_permitted` → `_is_pack_chat_only_permitted` | def + 1 use in Check-36 driver; **required-symbol list `test:50`** (`'_is_pm_only_permitted'`); test helper `assert_pm` body `mod._is_pm_only_permitted(path)` |

**Lockstep interlock (`enumerate-encoding-surfaces`):** the test required-symbol list at `test:50` asserts the symbol EXISTS by name. If the validator symbol is renamed but `test:50` is not, the import-check FAILS. The var-rename and the test edit are an ENCODING pair — they move in the SAME commit. (Covered in §7 F15.)

---

## 6. The A13 FOLD — restore BACKLOG/CHANGELOG to the permitted set (3 encoding surfaces, lockstep)

A13 (landed in BD-203 Commit 1, `a5a8ad8`) removed `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` from the permitted set too early — before BD-203 Commit 2 deletes them. At BD-209 time both files STILL EXIST on disk and are real Pack-Chat-edited files, so restoring them to the permitted set is correct. Three encoding surfaces move in lockstep:

### 6.1 Validator constant (`scripts/validate-pack.py`)
ADD `"pack-ops/BACKLOG.md"` and `"pack-ops/CHANGELOG.md"` back into `_PACK_CHAT_ONLY_PERMITTED_PATHS` (the renamed set). Replace the `# BD-203 A13: …removed here…` comment with the restore narrative (§6.3 wording).

### 6.2 Test assertions (`test-validate-pack-checks-36-37-38.sh`)
FLIP `assert_pm("pack-ops/BACKLOG.md", False, "T6d")` → `True` and `assert_pm("pack-ops/CHANGELOG.md", False, "T6e")` → `True`. Rewrite the `# BD-203 A13: … NO LONGER PM-only-permitted …` comment to the restore narrative. (The test still uses the renamed helper `_is_pack_chat_only_permitted` via `assert_pm` — §5/§7.)

### 6.3 Governance doc (`pack-ops/PACK-AGENTS.md`)
The Files list ALREADY lists `BACKLOG.md`/`CHANGELOG.md` (the A13 inconsistency was that the doc kept them while the validator dropped them). KEEP them listed; the restore makes doc + validator + test agree. Add a one-line note that the removal is scheduled for BD-203 Commit 2 (with the `git rm`), so a future reader understands the transient state.

**Restore-narrative comment (shared wording for §6.1 + §6.2):**
> `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` are pack-chat-only-permitted Files: they exist on disk as Pack-Chat-edited monoliths until BD-203 Commit 2 deletes them (and re-removes them from this set in the same atomic commit). Restored by BD-209 (A13 fold) — the BD-203 Commit-1 A13 removal was premature.

### 6.4 A13-FOLD net effect + sequencing
After BD-209 the permitted Files set = the F4 set PLUS `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md`. Validator, test (T6d/T6e=True), and PACK-AGENTS agree. The `git rm` + final re-removal from the set is BD-203 Commit 2's job. BD-209 lands BETWEEN BD-203 Commit 1 (`a5a8ad8`, landed) and Commit 2 (not yet run).

### 6.5 Empirical-Evidence Block — current A13 state (the inconsistency BD-209 folds)
```
CLAIM: at HEAD, the validator set EXCLUDES BACKLOG.md/CHANGELOG.md but PACK-AGENTS lists
       them + the tests assert False — the A13 inconsistency.
COMMAND: read validate-pack.py:3740-3755; PACK-AGENTS.md:133-140; test:114-120
OUTPUT: validate-pack.py:3741-3744 comment "BD-203 A13: …removed here"; set has NO
        BACKLOG/CHANGELOG entry. PACK-AGENTS.md:134-135 DOES list both ("regenerated
        mirror; per-entry source at …"). test:119-120 assert_pm(...,False,"T6d"/"T6e").
HEAD-SHA: 4086705   DATE: 2026-06-04
INTERPRETATION: 3 surfaces currently disagree (doc lists / validator+test exclude).
  The fold makes all three INCLUDE (restore), correct for the on-disk reality.
CONCLUSION: SUPPORTED.
```

---

## 7. New regression tests (close the §1.2 / §6.1 GAP) — F15

All in `scripts/tests/test-validate-pack-checks-36-37-38.sh`. REMOVE the old T3a/T3b alias-acceptance asserts; ADD positive `pack-chat-only` detection + no-collision tests + an ignore-via-retire assert (old tokens NOT recognized); FLIP T6d/T6e (A13); update the required-symbol list + helpers to the renamed symbols.

| Test edit | Content |
|---|---|
| **Required-symbol list (`:50`)** | `'_is_pm_only_permitted'` → `'_is_pack_chat_only_permitted'` (else import-check fails — §5 interlock) |
| **Helper `assert_pm` body** | `mod._is_pm_only_permitted(path)` → `mod._is_pack_chat_only_permitted(path)` |
| **Keyword-detection refs** | `mod._SCOPE_KEYWORDS_PM_ONLY` → `mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY` (T4c; T3a/T3b are REMOVED — next two rows) |
| **NEW T3c (positive)** | `assert_match("docs: pack-chat-only — governance edit", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, True, "T3c")` |
| **T3a/T3b (REMOVE — hard-retire, §4)** | DELETE the two old alias-acceptance asserts entirely (the old tokens no longer parse) |
| **NEW T3d/T3e (ignore-via-retire)** | `assert_match("docs: PM-only — BACKLOG update", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T3d: retired pm-only NOT recognized — Check 36 SKIPS, NOT a reject")` + `assert_match("docs: pack-memory-only — trinity edit", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T3e: retired pack-memory-only NOT recognized")`. Documents the deliberate ignore-via-retire so a future BD can flip it to REJECT. |
| **NEW T5b (no-collision A)** | `assert_match("feat: vN — BD-209 rename (pack-chat-only)", mod._SCOPE_KEYWORDS_PACK_ONLY, False, "T5b: pack-only kw does NOT fire on a pack-chat-only subject")` |
| **NEW T5c (no-collision B)** | `assert_match("feat: thing (pack-only)", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T5c: pack-chat-only kw does NOT fire on a pack-only subject")` |
| **NEW T5d (embedded boundary)** | `assert_match("feat: pack-chat-only-ish thing", mod._SCOPE_KEYWORDS_PACK_CHAT_ONLY, False, "T5d: embedded")` |
| **T6d/T6e (A13 fold)** | FLIP to `True` (§6.2) |
| **Comment "§ 'PM-only files and directories'"** | RENAME → "§ 'pack-chat-only files and directories'" (§3.3 cascade) |
| **Other "PM-only" comments** (e.g. T6k "is NOT PM-only-permitted", A13 narrative) | RENAME prose → "pack-chat-only" |

**Verify-clean (measure-then-bound step 5):** the projected post-edit test run is green — the empirical parser run (§7.1) already confirms each new assertion's expected value at HEAD, so the tests encode true facts.

### 7.1 Empirical-Evidence Block — every new test asserts a TRUE fact (parser run at HEAD)
```
CLAIM: pack-chat-only is detected; does NOT collide with pack-only (either direction);
       embedded form does not match; retired tokens (pm-only/pack-memory-only) are
       NOT recognized under the hard-retire tuple.
COMMAND: python3 -c "import importlib.util; spec=importlib.util.spec_from_file_location(
  'vp','scripts/validate-pack.py'); m=importlib.util.module_from_spec(spec);
  spec.loader.exec_module(m); f=m._subject_has_keyword; print(...)"
OUTPUT:
  substring pack-only in pack-chat-only: False
  A pack-only kw vs pack-chat-only subj: False        # T5b expected False ✓
  B new kw vs pack-chat-only subj: True                # T3c expected True  ✓
  C new kw vs pack-only subj: False                    # T5c expected False ✓
  E new kw embedded pack-chat-only-ish: False           # T5d expected False ✓
  G pm-only subj vs retired tuple ('pack-chat-only',): False   # T3d expected False ✓
  H pack-memory-only subj vs retired tuple: False              # T3e expected False ✓
HEAD-SHA: 4086705   DATE: 2026-06-04
INTERPRETATION: every projected assertion matches the real parser. The retired
  tokens are unrecognized (SKIP, not reject). Tests will pass.
CONCLUSION: SUPPORTED.
```

---

## 8. Out-of-repo + Pack-Chat-direct surfaces (NOT coder edits — surfaced for the handoff)

These are NOT in the 16-file coder set; they are Pack-Chat-direct upkeep (the coder must NOT touch them):
- **Memory file `feedback_commit_subject_keyword_token_trap.md`** (`~/.claude/projects/.../memory/`) — outside the git repo; teaches the token list. Pack-Chat-direct update: change the worked example + token list to teach `pack-chat-only` and note the deprecated `pm-only`/`pack-memory-only` aliases. Also update the `MEMORY.md` index description in lockstep. **Not in the 1248 total; not a coder deliverable.**
- **`pack-ops/BACKLOG.md` BD-entry prose** (35 occ) — Pack-Chat-direct bookkeeping. RENAME only forward-clarity references in active BD entries (e.g. the BD-209/BD-208 "§ PM-only" pointers); LEAVE historical resolved-entry text (BD-167b/169b etc.) as LEAVE-HISTORICAL (§9.7 ruling).
- **`pack-ops/CHANGELOG.md`** — no version-boundary entry for BD-209 yet; Pack-Chat authors at the version boundary, not the coder.

---

## 9. Rulings on the remaining §12 open decisions

| § | Decision | Ruling |
|---|---|---|
| 12.1 | Sense B in/out | **OUT** (§1). Boundary + semantics + the PROFILE_PHRASES interlock. The 2 PROFILE_PHRASES + 7 project-side files are untouched. |
| 12.2 | Alias vs retire | **HARD-RETIRE** (§4; user override 2026-06-05). Alias and retire are a distinction without a difference (both let `pm-only` through); hard-retire is forward-looking + leaves a clean slate for an explicit REJECT later. Retired tokens → unrecognized → Check 36 SKIPS (ungated, no reject). |
| 12.3 | Internal var rename | **RENAME** (§5). Avoids permanent name-vs-concept drift; use sites confined to validate-pack.py + its test, moved in lockstep. |
| 12.4 | Prose-vs-keyword distinction | **Uniform `pack-chat-only`** for both keyword + file-set senses (§2). Simplest correct design; the rename's purpose is that they ARE one concept. |
| 12.5 | Section-name cascade | **RENAME heading → "pack-chat-only files and directories"** + all literal cross-refs in lockstep (§3.3). All refs are inside the 16-file set. |
| 12.6 | PACK-AGENTS:169 "PM Chat" stray | **FIX → "Pack Chat"** (§3.2 F5). This in-prose "PM Chat" meaning the pack manager IS the overload BD-209 cites; the rename is the right moment to correct it. Low-risk clarity edit inside an in-scope file. |
| 12.7 | Historical BACKLOG prose | **RENAME forward-clarity refs in ACTIVE entries; LEAVE historical resolved-entry text** (§8). Pack-Chat-direct, not a coder edit. |
| 12.8 | New tests | **ADD** the §7 positive-detection + no-collision + ignore-via-retire (old tokens NOT recognized) tests; REMOVE the alias-acceptance asserts; FLIP T6d/T6e. |
| 12.9 | Manifest regen | **REQUIRED** — the implementing commit(s) touch `scripts/`, `pack-ops/`, and (via SKILL.md/pack-coder dotted dirs) repo-root surfaces under the v11-surface set; run `bash test-fixtures/build.sh --all --clean` and stage `test-fixtures/manifest.txt` in the SAME commit if its diff is non-empty (`regenerate-manifest-v11-surface`). |

---

## 10. Reconciliation with BD-203 and BD-208

### 10.1 BD-203 (its Commit 2)
BD-209 lands the rename FIRST (per the BD sequencing). BD-203 Commit 2 then:
- builds the new `/backlog/` + `/changelog/` per-entry trees and `_rules.md` using the CORRECT keyword (`pack-chat-only`) from birth — no later re-rename;
- `git rm`s `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` AND re-removes them from `_PACK_CHAT_ONLY_PERMITTED_PATHS` + flips T6d/T6e back to `False` in the same atomic commit (the inverse of the §6 fold).
**No conflict:** BD-209's A13 fold is a transient restore valid only while the two monoliths exist on disk; BD-203 Commit 2 owns the final removal. The permitted PREFIXES (`backlog/`, `changelog/`) already cover the per-entry trees, so post-Commit-2 the per-entry files remain permitted.

### 10.2 BD-208 (the editing-actor rule referencing the set)
BD-208's landed rule (`pack-chat-minor-edits-only`, in trinity `## Pack memory` + PACK-CHAT.md + PACK-AGENTS.md + the spawn-rule-manifest) references the governance set by its prose name "PM-only set". Those references ARE inside the 16-file Sense-A set (F1–F3 trinity prose, F5 PACK-AGENTS, F6 PACK-CHAT, F8 manifest) and are RENAMED to "pack-chat-only set" by this design. **No separate BD-208 work needed** — BD-208's rule text is swept by the F-rows; the rule's MEANING is unchanged (only the file-set's NAME changes). Confirmed: BD-208 changed WHO edits the set and HOW (minor vs major), not WHICH files — orthogonal to the keyword rename.

### 10.3 Hard-retire reconciliation
The hard-retire override (§4) does not disturb §10: the rename set, var renames, and the A13 fold (§6) are unchanged; only the parser tuple is narrowed to `("pack-chat-only",)` and the §7 tests swap alias-acceptance for ignore-via-retire. Historical `(PM-only)` commits remain unaffected (Check 36 = HEAD-only walk — already established §4); under hard-retire they are unrecognized → SKIPPED (no claim), never failed.

---

## 11. Reconciliation of counts (1248 raw → 130 active → 16 files)

Independently re-verified the load-bearing figures at HEAD `4086705`:
- trinity per-file counts 12/12/11 (direct grep, §3.1).
- the 9 active "No PM-only file edits" files = 3 pack-coder (Sense A) + 6 project coder/repo-ops (Sense B) (direct grep, §1.4 CLAIM 2).
- token-collision False both directions + aliases parse (direct parser run, §7.1).
- Check 36 HEAD-only default (code read, §4.1).
- A13 3-surface inconsistency (code/doc/test read, §6.5).

The 1248 raw total is ~90% historical maintenance-docs prose + the 35 BACKLOG BD-entry occurrences — all LEAVE-HISTORICAL / Pack-Chat-direct. The editable coder surface is the 16 Sense-A files (~130 occ). I did NOT re-run the full 1248/227 repo-wide sweep (research established it; I verified only the load-bearing active subset per the prompt directive "verify any load-bearing count you rely on").

---

## 12. Residual decisions surfaced (NOT invented scope)

1. **Commit structure (planner's call, not architect's).** The rename is large but mechanical. A single `pack-chat-only`-keyword commit is cleanest IF Check 36 will not trip on the subject. The subject MUST carry at most one scope keyword: since this commit touches `scripts/`, `pack-ops/`, repo-root dotted dirs, AND trinity (all pack-side, NO `project-template/` content edits — the project-side Sense-B files are untouched), a `pack-only`-claimed subject is HONEST and Check-36-clean. Per `commit-subject-keyword-token-trap`, the subject must NOT contain the literal token `pack-chat-only` (it would be parsed as a scope claim and DENY `scripts/`). Surfaced for Pack Chat: describe the work without the literal keyword token, e.g. "rename the overloaded commit-scope governance keyword (pack-only)". (This is the exact trap that bit BD-198.)
2. **Memory-file + MEMORY.md index update** (§8) — Pack-Chat-direct; scheduled in the handoff, not the coder commit.
3. **BD-203 Commit 2 inverse edit** (§10.1) — owned by BD-203, noted here for the lockstep contract.

---

## 13. Rules-Applied Verification Block

### 13.1 READ-IN-FULL — per-file direct-read proof (every named doc + memory file)

| Named doc | Direct-Read proof (own Read call: line count + first/last or unique mid-line) | Conclusion |
|---|---|---|
| `RESEARCH-BD-209-BLAST-RADIUS.md` (IN FULL) | Read tool, 427 lines (offset 1, full). First `:1` "# RESEARCH — BD-209 Blast Radius: rename the `PM-only` commit-scope keyword → `pack-chat-only`"; last `:427` "*End RESEARCH-BD-209-BLAST-RADIUS.md*"; mid `:25` "`pack-chat-only` does **NOT** collide with `pack-only`…". | COMPLIANT |
| BD-209 entry (`pack-ops/BACKLOG.md`) | Read tool offset 3415 limit 40. First `:3415` "Position: pack-self governance; parallel with BD-203…"; `:3419` "**BD-209 — Rename the `PM-only` commit-scope keyword → `pack-chat-only`…**"; last in-entry `:3435` "Position: pack-self governance; rename-first, between BD-203 Commit 1 and Commit 2." | COMPLIANT |
| `validate-pack.py` Check 36 + permitted-set | Read tool offset 3716 limit 300 (lines 3716–4015). Unique mid `:3732` `_SCOPE_KEYWORDS_PM_ONLY = ("pm-only", "pack-memory-only")`; `:3908` `def _is_pm_only_permitted`; `:3740-3755` Files set; `:3759-3765` Prefixes. | COMPLIANT |
| `validate-pack.py` registry docstring (Check 36) | Read tool offset 148 limit 16. `:151` "36. Commit-scope honesty (BD-175 M5a…"; `:155-156` "PM-only PERMITTED-PATHS come from `pack-ops/PACK-AGENTS.md` § 'PM-only files and directories'". | COMPLIANT |
| `validate-pack.py` PROFILE_PHRASES region | Read tool offset 1600 limit 24. `:1601` `PROFILE_PHRASES = {`; `:1608` `"No PM-only file edits",` (write-scoped); `:1615` same (write-script). + offset 1565 limit 20: `:1581` `WRITE_SCOPED_AGENTS = {"coder"}`, `:1582` `WRITE_SCRIPT_AGENTS = {"repo-ops"}`. | COMPLIANT |
| `validate-pack.py:4527` comment + spawn-manifest validator | Read tool offset 4520 limit 14 (`:4526-4528` "pack-root CLAUDE/AGENTS/GEMINI are PM-only operating rules…") + offset 6680 limit 95 (`:6722` "Spawn-rule manifest reference-resolution"; `:6746` `if "## Pack memory" not in canonical:`). | COMPLIANT |
| Trinity table — `CLAUDE.md` | Read tool offset 68 limit 22. `:78` "| `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | …". + offset 374 limit 75 (`## Pack memory` Sense-A prose `:376-444`). | COMPLIANT |
| Trinity table — `AGENTS.md` | Read tool offset 70 limit 22. `:80` byte-parallel row to CLAUDE.md:78 (trinity parity verified). | COMPLIANT |
| Trinity table — `GEMINI.md` | Read tool offset 52 limit 16. `:60` "| `PM-only` (or `pack-memory-only`) | Pack-Chat-direct-edit only | Per `pack-ops/PACK-AGENTS.md` PM-only Files list — PERMITS `project-template/` trinity |" (abbreviated style). | COMPLIANT |
| `pack-ops/PACK-AGENTS.md` | Read tool offset 125 limit 48. `:130` "**PM-only files and directories** are off-limits…"; `:134-135` Files list BACKLOG/CHANGELOG; last `:172` "…the architect pass behind v11.0 per-entry split is". | COMPLIANT |
| `pack-ops/PACK-CHAT.md` | Read tool offset 10 limit 20 + offset 98 limit 8. `:15` "small PM-only set directly"; `:21` "same core behavioral rules as any PM chat"; `:23` "not a coding project PM chat."; `:101` "Pack Chat does MINOR edits only; coder does MAJOR." | COMPLIANT |
| Check-36 tests | Read tool offset 44 limit 105 (lines 44–148). `:50` `'_is_pm_only_permitted',`; `:95-96` T3a/T3b; `:102` T5 embedded; `:119-120` T6d/T6e assert False; `:138` T7b `project-template/docs/pack/PM-CHAT.md` False. | COMPLIANT |
| `CLAUDE.md ## Pack memory` IN FULL | Direct read offset 374 limit 75 (`:376-444` `### Pack Chat scope` PM-only prose + `pack-chat-minor-edits-only` rationale `:384-415`); heading confirmed via grep `:136` "## Pack memory (project-local learnings)". Read SEPARATELY from each memory file below. | COMPLIANT |
| `feedback_commit_subject_keyword_token_trap.md` | Read tool, 38 lines (full). `name: commit-subject-keyword-token-trap`; `:19` "Check 36 latched onto `PM-only`, which denies `scripts/` paths"; last `:38` "…[[feedback_no_prestaging_until_commit_approval]]." | COMPLIANT |
| `feedback_ci_guard_design_measure_then_bound.md` | Read tool, 14 lines (full). `name: ci-guard-design-measure-then-bound`; `:10` "measure the repo first, categorize every occurrence KEEP…or STRIP…size the allowlist exactly to KEEP"; last `:14` "Related: [[architect-planner-empirical-evidence]], [[triage-workflow-protocol]]." | COMPLIANT |
| `feedback_edit_in_place_not_full_rewrite.md` | Read tool, 14 lines (full). `name: edit-in-place-not-full-rewrite`; `:12` "on the v5 pass it silently DROPPED an entire section (§9.8 classification table)"; last `:14` "…[[feedback_pack_chat_no_coder_review]] (independent verification)." | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Read tool, 33 lines (full). `name: pack-project-separation-of-concerns`; `:15` "Cross-side substitution is FORBIDDEN."; last `:32` "Cross-refs: [[bd-pack-only-operational-rule]]… [[pack-entry-type-data-structure-semantics]]…" | COMPLIANT |
| `feedback_bd_pack_only_operational_rule.md` | Read tool, 35 lines (full). `name: bd-pack-only-operational-rule`; `:12` "Directory-based, NOT ship-based — the rule's trigger is the file's location"; last `:34` "Cross-refs: [[pack-project-separation-of-concerns]]…" | COMPLIANT |
| `feedback_preliminary_triage_architect_challenge.md` | Read tool, 46 lines (full). `name: preliminary-triage-architect-challenge-discipline`; `:14` "No decision is locked just because it was triaged."; last `:45` "Cross-refs: [[feedback-user-prescriptive-authority]]…[[pack-chat-boundaries]]." | COMPLIANT |
| `feedback_architect_planner_empirical_evidence.md` | Read tool, 14 lines (full). `name: architect-planner-empirical-evidence`; `:10` "command + verbatim output + HEAD SHA + date + interpretation + SUPPORTED / NOT-SUPPORTED / PARTIAL"; last `:14` "Related: [[agent-output-rules-applied-block]], [[ci-guard-design-measure-then-bound]]." | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` | Read tool, 14 lines (full). `name: agent-output-rules-applied-block`; `:10` "per rule: name + quoted evidence + COMPLIANT / N/A:‹reason› / VIOLATED:‹reason›; empty = VIOLATED"; last `:14` "Related: [[agent-prompt-enumerates-rules]], [[architect-planner-empirical-evidence]]." | COMPLIANT |
| `feedback_agents_read_rule_docs_in_full.md` | Read tool, 117 lines (full). `name: agents-read-rule-docs-in-full`; `:98` "No-cache-substitution clause"; last `:117` "…accepting a derived-not-read attestation erodes the very standard that catches the dangerous cases." | COMPLIANT |
| `feedback_scope_deliverables_to_the_ask.md` | Read tool, 34 lines (full). `name: scope-deliverables-to-the-ask-no-noise`; `:25` "…this is a disaster and why we're in this mess."; last `:34` "…the user's standing preference for terse, exactly-scoped work." | COMPLIANT |

> **AMENDMENT (user override 2026-06-05).** §4 alias policy reversed to HARD-RETIRE per user decision (distinction-without-a-difference rationale). Re-ran the parser under the retired tuple `("pack-chat-only",)` — §4.1 CLAIM A confirms old tokens unrecognized, new token gates. Edits confined to §0/§2/§3.2(F1–F4)/§4/§4.1/§7/§7.1/§9/§10.3; the Sense-A/B crux (§1), 16-file rename set, var renames (§5), and A13 fold (§6) are UNCHANGED. This block re-verified post-amendment.

### 13.2 Per-rule compliance

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION + NO-CACHE-SUBSTITUTION | §13.1: every named doc/memory file Read DIRECTLY via the Read tool with per-file line count + first/last/unique-mid proof. `CLAUDE.md ## Pack memory` read SEPARATELY (offset 374) from the 10 memory files; no file derived from the cache. | COMPLIANT |
| empirical-evidence-blocks | Every state-claim carries command + verbatim output + HEAD-SHA `4086705` + date 2026-06-04 + interpretation + SUPPORTED: §1.4 (Sense-A/B split), §3.1 (16-file set), §3.4 (manifest free-text), §4.1 (retired-tuple parser run + HEAD-only walk), §6.5 (A13 inconsistency), §7.1 (parser run, retire-aware). | COMPLIANT |
| ci-guard-design-measure-then-bound | Measured the tree (re-verified the load-bearing active subset directly); categorized every occurrence RENAME (16-file Sense-A) vs LEAVE (Sense B / historical / Pack-Chat-direct); sized the rename set EXACTLY to the 16-file legitimate set (the 2 PROFILE_PHRASES + 7 project files EXCLUDED); verified post-rename the parser + new tests run clean against the projected (hard-retire) state — §4.1 CLAIM A + §7.1 = the verify-clean step. | COMPLIANT |
| preliminary-triage-architect-challenge | Challenged the FIXED binding decisions: stress-tested Sense-B-OUT (§1.2 — confirmed via boundary + PROFILE_PHRASES interlock), challenged leave-vars and rejected it (§5). The original keep-as-alias position was the architect's own challenge outcome; the user OVERRODE it to hard-retire (2026-06-05) — user retains final authority, override documented + applied (§4). No binding decision rubber-stamped. | COMPLIANT |
| edit-in-place-not-full-rewrite | Every F-row (§3.2) is a targeted in-place anchor edit (quoted old→new string), never a whole-file rewrite; anchors are quoted strings not line numbers (drift-safe). | COMPLIANT |
| scope-deliverables-to-the-ask | Amendment scoped to exactly the 4 asked changes (§4 hard-retire, trinity table alias-clause drop, §7 test swap, §10 reconciliation note); everything else (§1 crux, §3 set, §5 vars, §6 fold) kept intact per instruction; edited in place, no whole-doc rewrite. | COMPLIANT |
| rules-applied-verification-block | This §13 block: §13.1 per-file READ-IN-FULL proof for all 12 named docs + 10 memory files; §13.2 per-rule table with quoted evidence. No empty rows; no VIOLATED rows. | COMPLIANT |

**No VIOLATED rows. No empty evidence.**

---

*End ARCHITECTURE-BD-209.md*
