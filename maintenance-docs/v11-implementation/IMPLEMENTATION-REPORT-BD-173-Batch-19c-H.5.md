# IMPLEMENTATION-REPORT — BD-173 Batch 19c.5 (H.5)

**Scope:** METHODOLOGY.md substantive additions — three distinct
procedural additions per V2 §D.4 (mid-phase planner triggers), §D.2
(rule-placement sub-section, SUBSIDIARY to D-11 omniscience principle),
and §C.12 (`/tmp` ephemerality REVISED-WORDING paragraph).

**Branch:** `v11-dev`
**HEAD at start (and end — agents do not commit):** `c9d6dba4747abd772944b62b6d4e5a74919475d2`
**Coder:** pack-coder
**Commit (planned):** H.5 — `feat: v11 — BD-173 METHODOLOGY.md substantive additions (mid-phase planner, rule placement subsidiary to PM-chat omniscience, /tmp ephemerality) (Batch 19c.5)`

---

## §1 — Scope

Three substantive additions to `supporting-docs/METHODOLOGY.md`:

1. **§D.4 — H4 sub-section** "Planner trigger conditions (mid-phase)"
   inserted in Part 5 → Workflow 4, AFTER the architect-trigger H4
   cluster ("Architect trigger conditions" + "What the PM chat does when
   a trigger fires" + the trailing CLAUDE.md/AGENTS.md callout) and
   BEFORE `### Workflow 5 — Full-codebase audit (auditor agent)`.

2. **§C.12 — `>` callout paragraph** "/tmp reports are ephemeral"
   (REVISED-WORDING per audit §3.1.12 — "Pack Chat" cross-side audience
   cite replaced with PACK-FEEDBACK.md channel) inserted in Part 9
   IMMEDIATELY AFTER the "What agents can and cannot modify" table
   close and BEFORE the "Desktop Commander scope for PM chat"
   sub-section.

3. **§D.2 — H3 sub-section** "Rule placement: trinity vs PM-CHAT.md vs
   METHODOLOGY.md" inserted in Part 9 AFTER the "Desktop Commander scope
   for PM chat" sub-section and BEFORE the `---` separator preceding
   Part 10. SUBSIDIARY framing to D-11 omniscience principle with
   forward-reference to Part 1 (H.16 will close the forward-pointer).

**Files touched (in-scope):**
- `supporting-docs/METHODOLOGY.md` — 3 substantive additions (+81 lines, -0)
- `test-fixtures/manifest.txt` — regenerated per RC9 (v11-* row drift —
  3 fixture rows changed because `supporting-docs/` is v11-surface)

**Files NOT touched (out of scope confirmed):** see §6.

---

## §2 — Edits applied

### 2.1 — Edit 1: §D.4 NEW H4 sub-section "Planner trigger conditions (mid-phase)"

**Insertion anchor located:** Part 5 → Workflow 4 → after the H4 cluster
that ends at the trailing `>` callout block ("CLAUDE.md and AGENTS.md
changes: ... beyond the general architect pass approval.") and before
`### Workflow 5 — Full-codebase audit (auditor agent)`. Anchor located
via durable header content — not by line numbers (line numbers had
drifted from PLAN's L510-533 reference due to H.1's callout additions;
at HEAD `c9d6dba` the H4 cluster ends at L572 and Workflow 5 starts at
L574).

**Edit type:** NEW H4 sub-section, sibling to "Architect trigger
conditions" and "What the PM chat does when a trigger fires".

**Before context (METHODOLOGY.md L569-574 at HEAD `c9d6dba`):**

```
> **CLAUDE.md and AGENTS.md changes:** The architect agent may propose changes to
> `CLAUDE.md` or `AGENTS.md` only if the root cause cannot be addressed by fixing
> `ARCHITECTURE.md` or `IMPLEMENTATION-PLAN.md` alone. These require an additional
> explicit user approval beyond the general architect pass approval.

### Workflow 5 — Full-codebase audit (auditor agent)
```

**V2 §D.4 text block applied verbatim** (from `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L718-752):

- H4 header: `#### Planner trigger conditions (mid-phase)`
- Sibling-to-architect-triggers framing paragraph
- 3 triggers P-A, P-B, P-C (bulleted)
- "For each trigger" closing paragraph
- "Planner-vs-architect demarcation" terminal paragraph (preserved
  byte-identical per V2 spec)

**After context (METHODOLOGY.md L572-608 after edit):**

```
> explicit user approval beyond the general architect pass approval.

#### Planner trigger conditions (mid-phase)

Sibling to the architect trigger conditions above, three
mid-phase planner triggers cover task-level revision needs:

- **Trigger P-A — Task-definition ambiguity surfaced by coder.**
  ...
- **Trigger P-B — Architect output names "planning pass needed"
  as the follow-up.**
  ...
- **Trigger P-C — Task-ordering revision discovered mid-phase.**
  ...

For each trigger, the planner pass produces an updated
IMPLEMENTATION-PLAN.md Phase N task block; PM chat presents to
user for approval before re-running the coder.

**Planner-vs-architect demarcation:** A "task-definition
ambiguity" (P-A) is a planning problem ...

### Workflow 5 — Full-codebase audit (auditor agent)
```

**Line delta:** +37 lines (header + 3 triggers + 2 closing paragraphs +
blanks).

---

### 2.2 — Edit 2: §C.12 NEW `>` callout paragraph "/tmp reports are ephemeral"

**Insertion anchor located:** Part 9 → IMMEDIATELY AFTER the "What
agents can and cannot modify" table close (final row "Deferral comments
in source | Writes TD-TBD only | Never | Replaces TD-TBD with TD-NNN or
removes | See Part 7 |") AND BEFORE `### Desktop Commander scope for PM
chat`. Anchor located via table-close + next-H3 content; at HEAD
`c9d6dba` the table closes at L1443 and the Desktop Commander H3 is at
L1445.

**Edit type:** NEW `>` callout paragraph (single block, no header).

**Before context (METHODOLOGY.md L1443-1445 at HEAD `c9d6dba`):**

```
| Deferral comments in source | Writes TD-TBD only | Never | Replaces TD-TBD with TD-NNN or removes | See Part 7 |

### Desktop Commander scope for PM chat
```

**V2 §C.12 text block applied verbatim** (from
`ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L551-560):

```
> **/tmp reports are ephemeral.** When an agent prompt specifies
> a `REPORT FILE:` path under `/tmp/...` (typically used for
> docs-researcher reports, architect mid-phase reports, or any
> report the developer does not want committed to the repo),
> treat the file as ephemeral: it is safe to share externally
> (for upstream debugging via PACK-FEEDBACK.md per Part 10),
> nothing to revert if discarded, and never to be committed.
> Reports intended for the repo are written under `docs/project/`
> per the standard prompt templates.
```

**REVISED-WORDING confirmed:** V1's "paste into Pack Chat for upstream
debugging" replaced with "for upstream debugging via PACK-FEEDBACK.md
per Part 10" per audit §3.1.12 — drops the "Pack Chat" cross-side
audience cite (meaningless at a client install).

**After context (METHODOLOGY.md L1477-1489 after edit):**

```
| Deferral comments in source | Writes TD-TBD only | Never | Replaces TD-TBD with TD-NNN or removes | See Part 7 |

> **/tmp reports are ephemeral.** When an agent prompt specifies
> a `REPORT FILE:` path under `/tmp/...` (typically used for
> docs-researcher reports, architect mid-phase reports, or any
> report the developer does not want committed to the repo),
> treat the file as ephemeral: it is safe to share externally
> (for upstream debugging via PACK-FEEDBACK.md per Part 10),
> nothing to revert if discarded, and never to be committed.
> Reports intended for the repo are written under `docs/project/`
> per the standard prompt templates.

### Desktop Commander scope for PM chat
```

**Line delta:** +10 lines (9 `>` lines + 1 blank).

---

### 2.3 — Edit 3: §D.2 NEW H3 sub-section "Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md"

**Insertion anchor located:** Part 9 → AFTER `### Desktop Commander
scope for PM chat` sub-section (which ends at "When Desktop Commander is
unavailable, the PM chat outputs file content and git commands for the
human to run manually. Both paths must always be available.") AND BEFORE
the `---` separator that precedes `## Part 10 — Pack Feedback Loop`.

**Edit type:** NEW H3 sub-section, SUBSIDIARY to D-11 omniscience
principle (to be landed in H.16 at Part 1 — Tool Roles). One inter-commit
forward reference is acknowledged per V2 §H.16 Ordering rationale; H.16
closes the forward-pointer.

**Before context (METHODOLOGY.md L1460-1464 after Edit 1+2, original
positions L1503-1506 after both prior edits):**

```
When Desktop Commander is unavailable, the PM chat outputs file content and
git commands for the human to run manually. Both paths must always be available.


---

## Part 10 — Pack Feedback Loop
```

**V2 §D.2 text block applied verbatim** (from
`ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L653-689):

- H3 header: `### Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md`
- Subsidiary-to-D-11 framing paragraph with forward-reference to Part 1
- 3 categories of rules (bulleted): PM-chat orchestration rules /
  Agent-affecting rules / Both-audience rules requiring duplication
- Closing paragraph (guides cleanup batches; does not retroactively
  renumber)

**After context (METHODOLOGY.md L1504-1547 after edit):**

```
When Desktop Commander is unavailable, the PM chat outputs file content and
git commands for the human to run manually. Both paths must always be available.

### Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md

This placement rule is SUBSIDIARY to the PM chat omniscience
obligation (Part 1 — Tool Roles). The default is single-source
authoritative with PM-chat injection-into-agent-prompts as the
delivery mechanism; duplication across surfaces is the EXCEPTION
documented below.

New rules added during pack maintenance fall into one of three
categories based on audience:

- **PM-chat orchestration rules** ...
- **Agent-affecting rules** ...
- **Both-audience rules requiring duplication** ...

This placement rule guides cleanup batches and pack-version
upgrades; it does not retroactively renumber existing rules.
Where a pre-existing duplicated rule still satisfies the
defense-in-depth conditions, leave it; where it does not,
schedule a single-source consolidation in a future cleanup batch.


---

## Part 10 — Pack Feedback Loop
```

**Line delta:** +34 lines (header + 4 framing paragraphs + 3 bulleted
categories + 1 closing paragraph + blanks).

**Blank-line discipline:** The original file had a double blank line
between "Both paths must always be available." and the `---` separator.
The new H3 sub-section is inserted with one blank line before it (to
follow "Both paths must always be available."), and the trailing double
blank + `---` is preserved unchanged. This matches METHODOLOGY.md's
convention of using `<blank>\n<blank>\n---` to separate Parts.

---

## §3 — Verification

### 3.1 — validate-pack.py — PASS

```
$ python3 scripts/validate-pack.py
...
── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

All 42 checks PASS. No new lint or schema issues introduced.

### 3.2 — Fixture build — PASS (manifest regenerated)

```
$ bash test-fixtures/build.sh --all --clean
── building v10-minimal ──            HEAD: 19558cbac58ed3e47642a6bbe64418a38c60bc16  [unchanged]
── building v10-realistic-ot ──       HEAD: 4c62945f72b037908b38967d5d8f019745263258  [unchanged]
── building v11-realistic-ot ──       HEAD: ed20f3eae0a177e6f8d132f3031cf6db00379d62  [DRIFT]
── building v11-flat-file ──          HEAD: 88ef91431c22cdc86a611ec4cc0038d170e22095  [DRIFT]
── building v11-tracker-on ──         HEAD: cc9f635933de26cd01de953876ebc69edbf992ca  [DRIFT]
── building existing-project-mid-dev  HEAD: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619  [unchanged]
manifest written: test-fixtures/manifest.txt
```

All 3 v11-* fixture rows drifted as expected (METHODOLOGY.md is copied
by `scripts/init-project.sh` stage S6 to client `docs/pack/` — confirmed
v11-surface per RC9 trigger). v10-* and existing-project rows unchanged.

### 3.3 — Manifest diff (RC9 required attachment)

```
$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

Manifest changes (canonical RC9 attachment):

```
-v11-realistic-ot  66d960011d4973430c91b9523a5de89787ac8fd1
-v11-flat-file  50ad26ea1cd2fef1c4b06062fafbfa2c82da2ff6
-v11-tracker-on  5b753394b508443b0384b7e2db98b4986f057e61
+v11-realistic-ot  ed20f3eae0a177e6f8d132f3031cf6db00379d62
+v11-flat-file  88ef91431c22cdc86a611ec4cc0038d170e22095
+v11-tracker-on  cc9f635933de26cd01de953876ebc69edbf992ca
```

Manifest is modified in the working tree, NOT staged (per agent rules —
Pack Chat stages with the H.5 commit).

### 3.4 — Anchor presence grep

```
$ grep -n "^### Rule placement\|^#### Planner trigger conditions\|/tmp reports are ephemeral" supporting-docs/METHODOLOGY.md
574:#### Planner trigger conditions (mid-phase)
1479:> **/tmp reports are ephemeral.** When an agent prompt specifies
1507:### Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md
```

Exactly 3 hits — one per V2 spec section, in the order Edit 1 → Edit 2
→ Edit 3 (Workflow 4 → Part 9 table-post → Part 9 sub-section).

### 3.5 — File diff stat

```
$ git diff --stat supporting-docs/METHODOLOGY.md
 supporting-docs/METHODOLOGY.md | 81 ++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 81 insertions(+)
```

81 net additions, 0 deletions — pure additive change per V2 spec.

### 3.6 — git status final

```
$ git status --short
 M supporting-docs/METHODOLOGY.md
 M test-fixtures/manifest.txt
```

Exactly the expected 2 modifications. No stray edits, no untracked
files.

---

## §4 — Cross-references

- **V2 §C.12** (`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L541-562)
  — `/tmp` ephemerality REVISED-WORDING text block (verbatim source for Edit 2).
- **V2 §D.2** (`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L640-689)
  — rule-placement REVISED-PLACEMENT text block (verbatim source for Edit 3).
- **V2 §D.4** (`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L712-754)
  — mid-phase planner triggers text block (verbatim source for Edit 1).
- **V2 §D.6** (`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L776-868)
  — PM-chat omniscience principle (the D-11 principle to which Edit 3
  is SUBSIDIARY). Edit 3's opening paragraph forward-references
  "Part 1 — Tool Roles" where H.16 will land the principle text per
  V2 §D.6.2.
- **V2 §C.0 cascade summary** (`maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L169-192)
  — confirms §C.12 is REVISED-WORDING (not REFRAME) and §D.2 placement
  cascades through D-11 omniscience principle.
- **PLAN H.5** (`maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` L251-286)
  — implementer entry naming the 3 substantive additions, insertion
  anchors (line numbers shown there are PLAN-time references; this
  IMPL-REPORT uses durable header content per the PLAN's "coder picks
  precise insertion" guidance).
- **PLAN H.16** (forward-reference closure) — when H.16 lands the
  D-11 omniscience principle text in Part 1 — Tool Roles, the
  forward-reference in Edit 3's opening paragraph resolves to a
  concrete in-doc anchor.
- **Audit §3.1.12** — original audit finding driving the V1→V2
  REVISED-WORDING for §C.12 (drops "Pack Chat" audience cite).

---

## §5 — Success-criteria checklist

| Criterion | Status | Evidence |
|---|---|---|
| 1. METHODOLOGY.md has 3 NEW additions at correct insertion anchors per V2 §D.4 / §D.2 / §C.12 | PASS | §2.1/§2.2/§2.3 above + §3.4 grep output |
| 2. Text blocks are byte-identical to V2 spec (verbatim) | PASS | §2.1/§2.2/§2.3 cite verbatim V2 source line ranges; cross-checked against `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L551-560 / L653-689 / L719-752 |
| 3. `python3 scripts/validate-pack.py` PASS | PASS | §3.1 — "PASSED — all checks clean" |
| 4. `bash test-fixtures/build.sh --all --clean` completes; manifest shows v11-* row drift | PASS | §3.2 + §3.3 — all 3 v11-* rows drifted; v10-* and existing-project rows unchanged |
| 5. IMPL-REPORT written to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.5.md | PASS | This file |

---

## §6 — Out-of-scope confirmations

Per the prompt's "Forbidden actions" list, NO files outside the
in-scope set were touched. Confirmed via `git status --short`:

```
 M supporting-docs/METHODOLOGY.md
 M test-fixtures/manifest.txt
```

Plus the new IMPL-REPORT file (this file) that the prompt explicitly
permits.

**Files NOT touched (verified):**
- `project-template/` — not in scope.
- `pack-ops/` — not in scope.
- `scripts/` — not in scope (`validate-pack.py` was invoked read-only;
  `test-fixtures/build.sh` was invoked but only wrote
  `test-fixtures/manifest.txt` which is in scope per RC9).
- `.claude/`, `.codex/`, `.gemini/` — not in scope.
- `maintenance-docs/v11-research/` — not in scope.
- `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md`
  and `PLAN-CLEANUP-BATCH-19C.md` — read-only (V2 spec + PLAN H.5
  source documents).

**Git state-changing verbs NOT invoked:** confirmed only read-only git
verbs used (`git rev-parse`, `git status`, `git diff` with `--stat` and
diff-output only). No `git add`, `git commit`, `git push`, `git tag`,
`git mv`, `git rm`, `git reset`, `git checkout -- <path>`,
`git restore`.

---

## §7 — Open questions / deferrals

**None.**

- All 3 V2 text blocks (§D.4, §D.2, §C.12) had unambiguous insertion
  anchors that resolved via durable header content (no line-number
  ambiguity remained after consulting METHODOLOGY.md at HEAD `c9d6dba`).
- No text-block discrepancy with V2 spec: all 3 blocks were applied
  byte-identical to the V2 source line ranges cited in §4.
- The one acknowledged forward-reference (Edit 3's pointer to "Part 1
  — Tool Roles" where the D-11 omniscience principle will land) is
  per V2 §H.16 Ordering rationale and PLAN H.5's third reviewer focus
  bullet ("§D.2 subsidiary reference clarity"). H.16 will close the
  forward-pointer in a later commit; this is not a defect.
- Boundary discipline check (per PREFLIGHT P-missed-7 guidance):
  METHODOLOGY.md is a project-side SSOT (copied to client
  `docs/pack/METHODOLOGY.md` by `scripts/init-project.sh` stage S6).
  All 3 edits cite project-side concepts (Workflow 4 architect/planner
  triggers, project agent-modification table, `docs/pack/PM-CHAT.md`
  audience, `docs/project/` paths, "PM chat" — never "Pack Chat",
  "PACK-AGENTS.md", or `pack-ops/` content). The §C.12 REVISED-WORDING
  explicitly removes the "Pack Chat" cross-side audience cite per audit
  §3.1.12 — this is precisely the boundary-discipline correction the
  edit ships. No pack-side references introduced.

---

## §8 — Files-changed inventory

| Path | Change type | Notes |
|---|---|---|
| `supporting-docs/METHODOLOGY.md` | modified | +81 lines / -0; 3 substantive additions per V2 §D.4 / §C.12 / §D.2 |
| `test-fixtures/manifest.txt` | modified | RC9 regen; 3 v11-* SHA rows updated |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.5.md` | new | This report |

---

**End of IMPL-REPORT for BD-173 Batch 19c.5 (H.5).**
