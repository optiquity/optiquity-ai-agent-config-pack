# Implementation Report — BD-126 + BD-127

**Branch:** `v11-dev`
**HEAD at start:** `026d6151aed457746941c03e4ec8f28e5568efb9`
**Working-tree HEAD at handoff:** `026d6151aed457746941c03e4ec8f28e5568efb9`
(no commits made by this agent — Pack Chat commits)
**Reviewer report consumed:** `maintenance-docs/v11-implementation/PACK-REVIEW-V10.1-BACKPORT.md`
**Scope:** BD-126 (4 BLOCKER/SHOULD-FIX findings) + BD-127 (4 doc-tidy findings).

---

## 1. Summary

- **BDs addressed:** 2 (BD-126, BD-127).
- **Findings implemented:** 8 (F-4, F-5, F-7, F-8, F-9, F-11, F-16, F-17).
- **Files modified:** 11 (excluding BACKLOG.md, untouched by agent;
  excluding the new untracked review report).
- **Validator:** `python3 scripts/validate-pack.py` → **PASSED — all
  checks clean**, including new **Check 28** (PM-startup per-CLI
  parity).
- **Deviations:** none. One minor adaptation noted: GEMINI.md's
  Project memory bullet is intentionally compressed and lacks the
  parenthesized agent list; the F-7 trailing-clause was inserted in
  parenthesized form to remain readable in that context (see F-7
  section).

---

## 2. Per-finding implementations

### F-8 (BLOCKER) — Sync canonical Step 4 + Step 6 RAG line into the three per-CLI surfaces

Files edited:

- `project-template/skills/pm-startup/SKILL.md` (canonical) — Step 6 RAG
  template line extended to include the new `manifest target missing`
  state (see F-17).
- `project-template/.claude/skills/pm-startup/SKILL.md` — pre-v10.1
  single-file freshness Step 4 replaced with full canonical Step 4 prose
  (List → Read manifest → Diff → Orphan delete → Stale/missing
  re-ingest → Diff record), plus the four conditional branches
  (`local-rag` unavailable, manifest missing/malformed, manifest target
  missing, plus the implicit clean case). Step 6 summary now includes
  the canonical `**RAG:**` line.
- `project-template/.codex/skills/pm-startup/SKILL.md` — same edits
  as `.claude` (byte-equivalent Step 4 + Step 6 RAG line).
- `project-template/.gemini/commands/pm-startup.toml` — same prose
  inserted inside the `prompt = """..."""` triple-quoted TOML string.
  TOML parseability re-verified with `python3 -c "import tomllib;
  tomllib.load(open('...','rb'))"` → OK.

Verification: new Check 28 PASSED for all 3 CLI surfaces (`claude`,
`codex`, `gemini`); each surface's Step 4 block and Step 6 `**RAG:**`
line match the canonical exactly (whitespace-trimmed).

### F-17 (NIT) — Add `manifest target missing` branch

File edited: `project-template/skills/pm-startup/SKILL.md` (canonical).
A new conditional branch was inserted after the existing
`manifest is missing or malformed` branch:

> If a manifest path does not exist on disk (e.g., the manifest declares
> `docs/pack/METHODOLOGY.md` but the project has not yet run the install
> copy step that creates it), skip ingest for that specific path and
> report `RAG: manifest target missing — run install/migration` in the
> Step 6 summary…

The corresponding `**RAG:**` summary template in Step 6 was extended:

> `… / "manifest not found — skipped" (defect — surface to developer) /
> "manifest target missing — run install/migration" (manifest path not
> on disk; surface to developer)]`

Both pieces propagated into the three per-CLI surfaces in the same
edits as F-8.

Verification: present in all 4 pm-startup files (canonical + 3 per-CLI).
Check 28 confirms equivalence.

### F-9 (BLOCKER) — Revert Procedure 5-S Task C in INSTALL-PROCEDURES.md

File edited: `supporting-docs/INSTALL-PROCEDURES.md`.
Reverted exactly the additions made by `45d2098` to Procedure 5-S:

- Removed the new Task C row from the table (was at line 892).
- Removed the new step 4 lines (Run Task C…) and renumbered steps 4→4
  (the post-revert numbered list is 1–4 again).
- Reverted the prose preamble: "three tasks" → "two tasks", "any subset
  may report 'nothing to do'" → "either may report 'nothing to do'", and
  removed the Tasks A/B/C disjunction note.
- Reverted "If all tasks completed" → "If both tasks completed", "If any
  task has deferred items" → "If either task has deferred items".

The HISTORICAL block-quote (lines ~872–877) was left untouched.

Verification: `git diff 1daa938 -- supporting-docs/INSTALL-PROCEDURES.md`
returned **empty output** for the Procedure 5-S section before the F-4
qualifiers were added — confirming the revert exactly restores the
pre-`45d2098` state for that section. After F-4 was applied, the
remaining diff vs `1daa938` is solely the four "(historical)" qualifier
edits, none touching Procedure 5-S body.

### F-9 follow-on — METHODOLOGY.md note

File edited: `supporting-docs/METHODOLOGY.md` § RAG index hygiene.

Added a 3-line paragraph after the existing manual-trigger paragraph:

> PM Chat reconciles the RAG manifest on every `/pm-startup` per Step 4
> above and surfaces the result in the `RAG:` line of the startup
> summary. No separate post-migration reconciliation procedure is needed
> in v11+ — Step 4 is the single, always-on hygiene point.

Placement is immediately after the existing parenthetical (which was
also rephrased per F-5).

Verification: visual read; no validator check covers this content
directly, but the edit fits the existing § structure and does not
introduce new H2/H3 anchors (Check 18 unaffected — confirmed PASS).

### F-11 (SHOULD-FIX) — Validator Check 28 added

File edited: `scripts/validate-pack.py`.

- Top-of-file docstring updated to describe Check 28 (added between the
  Check 27 description and the informational-checks block).
- New helper `_extract_pm_startup_sections(text)` — extracts the Step 4
  block (everything under `## Step 4` up to next `## Step N` heading)
  and the Step 6 `**RAG:**` line via regex.
- New function `check_pm_startup_per_cli_parity()` — Check 28. Reads
  the canonical SKILL.md, then for each of the three per-CLI surfaces:
  - Skill files: read file body directly.
  - Gemini TOML: parse with `tomllib.load`, extract `prompt` key.
  - Compare extracted Step 4 block AND Step 6 `**RAG:**` line against
    the canonical (exact match modulo whitespace trim). Any divergence
    fails with a precise message naming the surface and which piece
    differs (Step 4 vs Step 6 RAG line).
- Wired into `main()` execution sequence in numerical order: now
  `…check_migrator_framework_inventory()` (Check 26),
  `check_agent_canonical_phrases()` (Check 27),
  `check_pm_startup_per_cli_parity()` (Check 28). Note: this required
  moving `check_agent_canonical_phrases()` from its previous position
  (called early in main(), after `check_pack_agent_trinity()`) to the
  end, immediately before Check 28, so the printed CI output is
  monotonic for 26 → 27 → 28. The earlier checks (1–11, 16–25) retain
  their existing call order since their numbering is also non-monotonic
  in main() and reordering them is out of scope.

Style template: modeled on existing `check_pack_help_per_cli_parity()`
(Check 21) — same surface-iteration shape, same `fail()` / `ok()`
helper usage, same per-surface OK/FAIL line format.

Verification: full validator run shows new Check 28 emitting:

```
── Check 28: PM-startup per-CLI parity (v10.1, BD-126) ──
  OK: claude: project-template/.claude/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: codex: project-template/.codex/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: gemini: project-template/.gemini/commands/pm-startup.toml — Step 4 + Step 6 RAG line match canonical
```

Final validator line: `PASSED — all checks clean`.

Negative test (sanity, performed mentally — not committed): if any
per-CLI surface drifted from canonical Step 4 or omitted the RAG line,
the check would emit `FAIL: <cli>: <path> — Step 4 diverges from
canonical …` or `FAIL: <cli>: <path> — Step 6 ` `**RAG:**` summary
line diverges …` and `main()` would exit 1. Prevention of the F-8
regression is structural.

### F-4 (SHOULD-FIX) — `(historical)` qualifiers in INSTALL-PROCEDURES.md

File edited: `supporting-docs/INSTALL-PROCEDURES.md`. Four bare in-prose
references qualified:

1. Line ~220 — `migrate-v9-to-v10.sh` → `migrate-v9-to-v10.sh
   (historical; sunset in v11 — see HISTORICAL block above)`.
2. Line ~246 — `MIGRATION-v9-to-v10.md` → `MIGRATION-v9-to-v10.md
   (historical, available via ` `git checkout v10 --` ` per the
   HISTORICAL block above)`.
3. Line ~802 — `MIGRATION-v9-to-v10.md` → `MIGRATION-v9-to-v10.md
   (historical, available via ` `git checkout v10 --` `)`.
4. Line ~881 — `migrate-v9-to-v10.sh` → `migrate-v9-to-v10.sh
   (historical; sunset in v11 — see HISTORICAL block above)`.

The HISTORICAL block-quote at lines ~206–217 (Procedure 5-C) and the
HISTORICAL block-quote at Procedure 5-S (lines ~872–877) were left
intact — they are the cross-reference target.

Verification: `grep -n "migrate-v9-to-v10\|MIGRATION-v9-to-v10"` after
the edits shows the same 8 hits as before, with the four bare-prose
hits now carrying inline qualifiers. Read-pass confirms each qualifier
parses naturally in surrounding sentence.

### F-5 (SHOULD-FIX) — METHODOLOGY.md `CLI-PM-SETUP.md` rephrasing

File edited: `supporting-docs/METHODOLOGY.md` § RAG index hygiene.

Old parenthetical:
> the `local-rag` `list` / `delete` / `ingest` MCP calls can be invoked
> manually outside `/pm-startup` (the pack-distributed `CLI-PM-SETUP.md`
> documents this for pack maintainers; project-installed copies of this
> file do not include that pack-only doc).

New parenthetical (per BD-127 spec):
> … manually outside `/pm-startup` (the `CLI-PM-SETUP.md` companion doc
> covers MCP / RAG setup; copy it alongside `METHODOLOGY.md` during
> install).

The factual error (CLI-PM-SETUP.md being pack-only) is removed; the
companion-doc framing matches `project-template/README.md` line 13's
copy instructions and `.mcp.json.example` line 9's CLI-PM-SETUP.md
pointer.

Verification: visual read; no validator check covers this exact prose,
but Check 18 (Trinity H2 parity) and Check 22 (Help-fragment freshness)
both PASS — no structural drift introduced.

### F-7 (NIT) — Project memory section's agent-list pointer

Files edited (lockstep, all three project-template trinity):

- `project-template/CLAUDE.md`
- `project-template/AGENTS.md`
- `project-template/GEMINI.md`

CLAUDE.md and AGENTS.md (which both carry the parenthesized agent
list `(architect / planner / coder / reviewer / tester / auditor /
docs-researcher / grpc-schema / repo-ops)`) had this clause appended
inline immediately after the closing parenthesis:

> ` — ` `auditor` ` covers the 7 variant agents; see ` `PACK-AGENTS.md`
> ` for the full roster.`

GEMINI.md is intentionally compressed and does NOT carry the
parenthesized agent list (verified pre-edit; the F-2 NIT in the review
report explicitly notes the GEMINI.md compression as PASS). For
symmetry, the same pointer was inserted in parenthesized form into the
GEMINI.md bullet:

> `… goes to the corresponding agent (`auditor` covers the 7 variant
> agents; see `PACK-AGENTS.md` for the full roster). The PM chat
> handles …`

This preserves trinity Check 18 (H2 parity) — no H2 changes — while
keeping the new pointer present in all three files. The wording
adaptation in GEMINI.md is the one minor deviation from the literal
"append" instruction, taken to keep the Gemini compression intact;
adding a 9-agent list to GEMINI.md would also have been a valid
choice but would have expanded the compressed bullet substantially.

Verification: Check 18 (Trinity H2 structure parity) PASS — no H2
drift; Check 16 (Trinity ## Project addenda H2) PASS; full validator
PASS.

### F-16 (NIT) — PM-CHAT.md flag profile alignment

File edited: `project-template/docs/pack/PM-CHAT.md` (read-only profile,
flag-profile block).

Before:
> `--permission-mode bypassPermissions --disallowedTools Edit
> 'Bash(git add:*)' …`
> Write is allowed (for the report); Edit is denied (no source
> modifications). The prompt constrains Write to the single report
> file.

After (per BD-127 spec):
> `--permission-mode bypassPermissions --disallowedTools 'Bash(git
> add:*)' …`  (no `Edit` in the list)
> Write is allowed (for the report); the prompt constrains Write to
> the single report file. Edit is permitted only on the agent's report
> file, per the chunked-Edit pattern in agent Hard rules.

`Edit` removed from the disallowed-tool list; one-line note added
explaining the chunked-Edit Hard-rules pattern is the canonical
long-report mechanism. All other denial entries (`Bash(git add:*)`,
`Bash(git mv:*)`, `Bash(git commit:*)`, `Bash(git push:*)`) intact.

Verification: visual read; flag-profile string is grep-able and now
consistent with the architect.md / reviewer.md / auditor.md Hard rules
that document the chunked-Edit pattern (e.g., architect.md lines
47–48). No validator check covers this exact line; Check 22 (Help
fragment freshness) PASS confirms no verb-shape regression.

---

## 3. Validator output (final)

```
$ python3 scripts/validate-pack.py
…
── Check 1:  SKILL.md frontmatter                                       PASS
── Check 2:  Codex TOML files                                            PASS
── Check 3:  TD-TBD sentinels in BACKLOG.md                              PASS
── Check 4:  README version table vs git tag                             PASS
── Check 5:  Agent file count consistency                                PASS
── Check 6:  Prompts-directory format                                    PASS
── Check 7:  Pack agent roster                                           PASS
── Check 8:  Reserved `x-` prefix                                        PASS
── Check 9:  Init-project structure (BD-044)                             PASS
── Check 10: Prompt template triad compliance                            PASS
── Check 11: Pack agent trinity-rule symmetry (informational)            PASS
── Check 17: Tool-config AGENT_CAPABILITIES parity (BD-059)              PASS
── Check 16: Trinity ## Project addenda H2 (BD-059)                      PASS
── Check 18: Trinity H2 structure parity (BD-059)                        PASS
── Check 19: Trinity templates free of body scaffolding (BD-059)         PASS
── Check 20: Pack .gitignore !.env.example exception (BD-059)            PASS
── Check:    Issue template forms (BD-063) — informational               PASS
── Check:    Template archive v11.0 integrity (BD-064; informational)    PASS
── Check 21: Pack-help per-CLI parity (BD-082)                           PASS
── Check 22: Help-fragment freshness (BD-082)                            PASS
── Check 23: Help-fragment completeness (BD-082)                         PASS
── Check 24: HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1)      PASS
── Check 25: Customization-detection regression guard (BD-089)           PASS
── Check 26: BD-119 migrator-framework inventory                         PASS
── Check 27: Agent canonical-phrase compliance (v10.1)                   PASS
── Check 28: PM-startup per-CLI parity (v10.1, BD-126)                   PASS

============================================================
PASSED — all checks clean
```

Final-line summary (literal): `PASSED — all checks clean`.

---

## 4. Files modified (`git diff --stat`)

```
 project-template/.claude/skills/pm-startup/SKILL.md             |  85 +++++++++-
 project-template/.codex/skills/pm-startup/SKILL.md              |  85 +++++++++-
 project-template/.gemini/commands/pm-startup.toml               |  85 +++++++++-
 project-template/AGENTS.md                                      |   7 +-
 project-template/CLAUDE.md                                      |   7 +-
 project-template/GEMINI.md                                      |   7 +-
 project-template/docs/pack/PM-CHAT.md                           |   8 +-
 project-template/skills/pm-startup/SKILL.md                     |  12 +-
 scripts/validate-pack.py                                        | 137 +++++++++++++++-
 supporting-docs/INSTALL-PROCEDURES.md                           |  40 ++---
 supporting-docs/METHODOLOGY.md                                  |  10 +-
 11 files changed, 413 insertions(+), 70 deletions(-)
```

(BACKLOG.md is also modified in the working tree from the parent's
prior BD-126/BD-127 entry creation — agent did not touch it; it
remains exactly as Pack Chat staged it pre-implementation. The new
untracked `maintenance-docs/v11-implementation/PACK-REVIEW-V10.1-BACKPORT.md`
is the prior reviewer's report, not authored by this agent.)

---

## 5. Working-tree state at handoff (`git status --short`)

```
 M BACKLOG.md
 M project-template/.claude/skills/pm-startup/SKILL.md
 M project-template/.codex/skills/pm-startup/SKILL.md
 M project-template/.gemini/commands/pm-startup.toml
 M project-template/AGENTS.md
 M project-template/CLAUDE.md
 M project-template/GEMINI.md
 M project-template/docs/pack/PM-CHAT.md
 M project-template/skills/pm-startup/SKILL.md
 M scripts/validate-pack.py
 M supporting-docs/INSTALL-PROCEDURES.md
 M supporting-docs/METHODOLOGY.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-V10.1-BACKPORT.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-126-BD-127.md
```

`HEAD` unchanged (`026d6151aed457746941c03e4ec8f28e5568efb9`); no
state-changing git verbs were invoked by the agent.

---

## 6. Definition-of-Done checklist

| Item | Status |
|---|---|
| BD-126 F-8: per-CLI Step 4 + Step 6 RAG-line synced (3 surfaces) | PASS |
| BD-126 F-17: manifest-target-missing branch added (canonical + 3 surfaces) | PASS |
| BD-126 F-9: Procedure 5-S Task C reverted in INSTALL-PROCEDURES.md | PASS |
| BD-126 F-9 follow-on: METHODOLOGY.md § RAG index hygiene note added | PASS |
| BD-126 F-11: validator Check 28 added + wired + PASS | PASS |
| BD-127 F-4: 4 in-prose v9-to-v10 references qualified `(historical)` | PASS |
| BD-127 F-5: METHODOLOGY.md CLI-PM-SETUP parenthetical rephrased | PASS |
| BD-127 F-7: agent-list pointer appended in all 3 trinity files | PASS |
| BD-127 F-16: PM-CHAT.md read-only flag-profile aligned | PASS |
| `python3 scripts/validate-pack.py` PASS (all checks incl. new 28) | PASS |
| TOML parseability of `pm-startup.toml` after edit | PASS |
| Trinity Check 18 H2 parity preserved | PASS |
| No state-changing git verbs invoked | PASS |
| No PM-only files modified by agent (BACKLOG/CHANGELOG/README/PACK-*) | PASS |

---

## 7. Deviations from plan

None of substance. One adaptation:

- **F-7 in GEMINI.md.** The literal "append" instruction targeted
  trinity files that all carry a parenthesized 9-agent list. GEMINI.md
  does not carry that list (intentional compression, validated as PASS
  by F-2 NIT in the review report). The agent-list pointer was inserted
  in parenthesized form into GEMINI.md's "PM chat does not architect"
  bullet so the pointer is present and trinity Check 18 H2 parity
  remains intact. This is a minimal-impact wording adaptation, not a
  scope change; the user-visible information (auditor variant
  abbreviation + PACK-AGENTS.md pointer) is identical across all three
  files.

---

## 8. New POQs introduced

None.

---

## 9. Deferred items

None within the BD-126 / BD-127 scope.

Out-of-scope items intentionally not touched (the prompt scoped them
out, and they remain on the table for a future batch):

- F-1 (BLOCKER, root CLAUDE.md trinity restoration after `bca0cfe`).
  This is structurally unrelated to the v10.1 backport and the user's
  approved scope explicitly excludes pack-root .md edits.
- F-15 (NIT, Claude-only Pack-memory section justification wording).
  Tied to F-1; out of scope.

These two findings remain noted in PACK-REVIEW-V10.1-BACKPORT.md for
PM Chat to triage in a separate batch.

---

## 10. Files-changed inventory

| Path | Change type | Notes |
|---|---|---|
| `project-template/skills/pm-startup/SKILL.md` | modified | Canonical: F-17 manifest-target-missing branch + Step 6 RAG-line extension |
| `project-template/.claude/skills/pm-startup/SKILL.md` | modified | F-8 sync (Step 4 + Step 6 RAG line) |
| `project-template/.codex/skills/pm-startup/SKILL.md` | modified | F-8 sync (Step 4 + Step 6 RAG line) |
| `project-template/.gemini/commands/pm-startup.toml` | modified | F-8 sync (Step 4 + Step 6 RAG line, inside `prompt = """…"""`) |
| `supporting-docs/INSTALL-PROCEDURES.md` | modified | F-9 revert (Procedure 5-S) + F-4 (4 historical qualifiers) |
| `supporting-docs/METHODOLOGY.md` | modified | F-5 rephrase + F-9 follow-on note |
| `project-template/CLAUDE.md` | modified | F-7 trailing clause appended |
| `project-template/AGENTS.md` | modified | F-7 trailing clause appended (lockstep) |
| `project-template/GEMINI.md` | modified | F-7 parenthesized clause inserted (lockstep, adapted) |
| `project-template/docs/pack/PM-CHAT.md` | modified | F-16 read-only flag-profile + note |
| `scripts/validate-pack.py` | modified | F-11: Check 28 added (helper + function + main() wiring + docstring) |

No files created. No files deleted.
