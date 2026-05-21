# IMPLEMENTATION-REPORT — BD-175 T1 NIT fix (line-number → section-name anchor)

**Branch:** `v11-dev`
**HEAD at start:** `b5221ee2b4ff2f652a9f883c2dfe051b811123bb`
**HEAD at finish:** `b5221ee2b4ff2f652a9f883c2dfe051b811123bb` (no commits — agents never commit per pack memory)
**Scope:** Single REPLACE edit per T1 per-commit reviewer NIT (PACK-REVIEW-BD-175-SHOULD-1.md) — replace soft locator "line ~329 area" in `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §6.1 "Unchanged from §6" paragraph with a section/paragraph-name anchor, per pack memory rule that architect docs must reference sections/symbols rather than line numbers (line numbers drift).

---

## §1 — Summary

Single-locator REPLACE per F4-bundle T1 per-commit review NIT
(PACK-REVIEW-BD-175-SHOULD-1.md). The §6.1 "Unchanged from §6"
paragraph (added in T1 fix-coder pass commit `fd8eb10`) contained the
soft locator phrase `"the 'New skill' paragraph above, line ~329
area"`. The "New skill" paragraph identifier was already present and
correct; the appended `, line ~329 area` clause is the line-number
reference that pack memory forbids in architect docs. Replaced with
`at the top of §6` — a stable section-name anchor that does not drift
when surrounding content is edited. Net: +1 line / -1 line edit, no
behavior change, anchor remains semantically equivalent and now drift-
proof. No manifest regen required (`maintenance-docs/` is not v11-
surface per Pack memory § "Regenerate test-fixtures/manifest.txt on
every v11-surface commit").

---

## §2 — File changed

| Path | Change type | Lines | Notes |
|---|---|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` | modified | +1 / -1 | §6.1 "Unchanged from §6" paragraph (file line 483 at HEAD `b5221ee`); replaces soft locator with section-name anchor |

`git diff --stat`:

```
 .../v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md   | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

`git status --short` (full working tree at finish):

```
 M maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
 M pack-ops/BACKLOG.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F2A.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-SHOULD-1.md
```

**Pre-existing working-tree state (NOT touched by this fix):**
- `M pack-ops/BACKLOG.md` — pre-existing modification at session start;
  outside this prompt's scope.
- `?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F2A.md`
  — pre-existing untracked file at session start.
- `?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-SHOULD-1.md`
  — pre-existing untracked file at session start (this is the review
  report whose NIT triggered this fix-coder pass).

The only working-tree change attributable to this session is the
single `M` on the ARCHITECTURE doc plus the new IMPLEMENTATION-REPORT
file at the path named in the prompt.

---

## §3 — Edit applied

**File:** `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`
**Location:** §6.1 "Unchanged from §6" paragraph (was line 483 at HEAD `b5221ee` pre-edit)

### BEFORE (exact quote, 2-line context)

```
`.gemini/skills/boundary-investigation/` (the "New skill" paragraph
above, line ~329 area). Pack-repo agents load skills at run-time from
```

### AFTER (exact quote, 2-line context)

```
`.gemini/skills/boundary-investigation/` (the "New skill" paragraph
at the top of §6). Pack-repo agents load skills at run-time from
```

### Effective change

```
- above, line ~329 area). Pack-repo agents load skills at run-time from
+ at the top of §6). Pack-repo agents load skills at run-time from
```

Net: 1 line replaced. Phrase change is `above, line ~329 area` →
`at the top of §6`. Semantics preserved (still points to the same
target paragraph); the "New skill" paragraph identifier in the same
sentence carries the precise pointer.

---

## §4 — §6 paragraph-anchor justification

**Why "at the top of §6":**

Read of §6 (lines 325-340) confirms:

- §6 heading: `## §6 — Mechanism M4: boundary-investigation skill (new pack skill)` (line 325)
- §6 first body content (line 327): `**Goal:** Concentrate the SSOT-investigation methodology...`
- §6 third paragraph (line 329 — the target): `**New skill: \`boundary-investigation\`** (proposed path: \`.claude/skills/boundary-investigation/SKILL.md\`, with parallel \`.codex/skills/\` and \`.gemini/skills/\` versions per the existing pack-skill trinity convention).`

The "New skill" paragraph IS at the top of §6 — it's the third
content paragraph (after the §6 heading, then **Goal**, then **New
skill**). Within §6 there is also a `Skill content sketch` paragraph
(line 331) and the embedded skill YAML+markdown. The phrase "at the
top of §6" is the most natural English anchor that:

1. Distinguishes the **New skill** identifier line (paragraph) from
   the sketch-block paragraphs further down in §6.
2. Doesn't depend on a heading the paragraph itself doesn't have
   (the **New skill** paragraph is bold-leading, not a `###` sub-
   heading — so "the §6.x heading" wording would not apply).
3. Drift-proof: §6 may grow but the **New skill** paragraph will
   remain the top-of-section identifier paragraph by construction
   (it's the load-bearing skill-existence claim — moving it
   downward would change §6 structure substantively, which would
   be visible in any diff that touched §6).
4. The "New skill" phrase quoted already in the §6.1 sentence
   carries the precise pointer (search-friendly) — `"at the top of
   §6"` is the supporting context, not a standalone locator.

**Reviewer-suggested phrasing match:** PACK-REVIEW-BD-175-SHOULD-1.md
proposed exactly `(the 'New skill' paragraph at the top of §6)`.
The §6.1 sentence already contained `the "New skill" paragraph
above`; this fix replaced only the `above, line ~329 area` suffix
with the reviewer's `at the top of §6` — preserving the existing
"New skill" identifier and matching reviewer phrasing exactly modulo
the kept `the "New skill" paragraph` prefix.

---

## §5 — Verification command output

### Step 1 — HEAD SHA

```
$ git rev-parse HEAD
b5221ee2b4ff2f652a9f883c2dfe051b811123bb
```

### Step 2 — Pre-edit locator scan (the soft locator existed)

```
$ grep -n "line.*329\|~329\|line ~" maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
483:above, line ~329 area). Pack-repo agents load skills at run-time from
```

Exactly one hit at line 483 — the §6.1 "Unchanged from §6" paragraph,
as the prompt described.

### Step 3 — §6.1 sub-section context (pre-edit excerpt at the locator)

```
**Unchanged from §6:** The pack-side boundary-investigation skill at
pack-repo root `.claude/skills/boundary-investigation/`,
`.codex/skills/boundary-investigation/`, and
`.gemini/skills/boundary-investigation/` (the "New skill" paragraph
above, line ~329 area). Pack-repo agents load skills at run-time from
CLI-prefixed dirs at the pack root — this is structurally different
from project-side ship-via-install and was correctly described in §6.
```

### Step 4 — §6 paragraph-anchor confirmation (the target paragraph)

```
$ sed -n '325,331p' maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
## §6 — Mechanism M4: boundary-investigation skill (new pack skill)

**Goal:** Concentrate the SSOT-investigation methodology into a single skill loaded by every actor whose work could trigger the regression. Single canonical home for the methodology; agent prompts reference the skill by name instead of duplicating the methodology in N places.

**New skill: `boundary-investigation`** (proposed path: `.claude/skills/boundary-investigation/SKILL.md`, with parallel `.codex/skills/` and `.gemini/skills/` versions per the existing pack-skill trinity convention).
```

Confirms the **New skill** paragraph IS at the top of §6 (third
content paragraph after the heading + Goal paragraph).

### Step 5 — Post-edit locator scan (zero hits in §6.1 area)

```
$ grep -n "line.*329\|~329" maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
(no output — zero matches)
```

The `~329` reference is gone. No other `line ~329` references existed
elsewhere in the doc.

### Step 6 — Working-tree scope (only the intended file modified)

```
$ git status --short
 M maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
 M pack-ops/BACKLOG.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-F2A.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-SHOULD-1.md
```

The `pack-ops/BACKLOG.md` `M` and the two `??` review reports are
PRE-EXISTING (present at session start; not touched by this fix).
Sole change attributable to this session is the `M` on the
ARCHITECTURE doc plus the new IMPL-REPORT path.

### Step 7 — Diff size (tiny, as expected)

```
$ git diff --stat maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
 .../v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md   | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### Step 8 — Full diff (for audit)

```diff
diff --git a/maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md b/maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
index 4951519..591322d 100644
--- a/maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
+++ b/maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md
@@ -480,7 +480,7 @@ until F4-bundle implementation.
 pack-repo root `.claude/skills/boundary-investigation/`,
 `.codex/skills/boundary-investigation/`, and
 `.gemini/skills/boundary-investigation/` (the "New skill" paragraph
-above, line ~329 area). Pack-repo agents load skills at run-time from
+at the top of §6). Pack-repo agents load skills at run-time from
 CLI-prefixed dirs at the pack root — this is structurally different
 from project-side ship-via-install and was correctly described in §6.
```

All verification PASS.

---

## §6 — Out-of-scope observations (Pack Chat triage feed-in)

Per prompt §Out of scope, I am NOT editing these. Pack Chat may triage
them into a separate fix-coder pass or a tracked tech-debt BD.

A broader grep for line-number references in
`ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` surfaced these
candidates (other line-style locators that may also drift):

```
$ grep -n "line [0-9]\|line ~[0-9]\|L[0-9]\{3,\}" \
    maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md

416:docs/pack/PM-CHAT.md:47 § "Pack agent roster"). The corrected
534:| Subject contains literal `PM-only` or `pack-memory-only` | Only Pack-Chat-direct-edit surfaces per `PACK-AGENTS.md:142-148` PM-only Files list — see §8.1a below for the verbatim list. Notably **PERMITS** edits to `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (project-template trinity IS PM-only per PACK-AGENTS.md:148 — "root and `project-template/`"). Updated per Phase 3 reviewer finding B1-cascade + S6. |
618:PACK-AGENTS.md:148 PM-only list explicitly names "`CLAUDE.md` / `AGENTS.md` /
1216:  `HELP-FRAGMENT-TRACKER.md` (line 584 at HEAD `8014186`) as still
1221:  `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §3 row #9 (line 167) AND
1222:  B's M2 row in §6.1 (line 527) unconditionally relocate
1229:- **What was changed:** The §8.2 deny-list row at line 584 area was
1235:  (the M2 `pack-ops/` row at line 587, already added in this doc's
1246:  (§0-§15, §16.1-§16.6) are unchanged. Only the line 584 row cell
```

**Triage notes (informational — for Pack Chat, not for action in this
NIT):**

| Line | Locator | Subjective drift risk | Pack-Chat-fix candidate? |
|---|---|---|---|
| 416 | `docs/pack/PM-CHAT.md:47 § "Pack agent roster"` | LOW — `:line § "Section"` hybrid; the section name is the load-bearing anchor and is precise. The `:47` is redundant context. Could drop the `:47` without info loss. | Maybe (low priority); the `§` anchor already solves the drift problem. |
| 534 | `PACK-AGENTS.md:142-148` and `PACK-AGENTS.md:148` | MEDIUM — cross-file line ranges into PM-only file that may renumber. Hard-quoted line refs to a sibling file. The `"root and \`project-template/\`"` quote at end of cell IS the section anchor and would survive renumbering. | Yes — replace `PACK-AGENTS.md:142-148` with `PACK-AGENTS.md § "PM-only Files list"` (or whatever section name). |
| 618 | `PACK-AGENTS.md:148` | MEDIUM — same as above. | Yes — same approach. |
| 1216, 1221, 1222, 1229, 1235, 1246 | "(line N at HEAD `<sha>`)" pattern | LOW — these locators are SHA-pinned (`at HEAD 8014186`), which makes them stable for archeological reference at that SHA. They are NOT moving locators meant to track current state; they're audit-trail entries documenting WHAT WAS at a specific revision. The SHA-pinning is the intent. | NO — SHA-pinned line refs are a valid audit-trail pattern; don't "fix" these without confirming the surrounding text doesn't depend on the SHA-pin semantics. |

**Recommended Pack Chat triage call:** The lines 534 and 618 PACK-
AGENTS.md cross-file line-range references are the most natural
candidates for a follow-on fix-coder pass to bring the doc fully in
line with the no-line-numbers pack memory rule. Lines 1216-1246 are
audit-trail SHA-pinned references and should be LEFT AS-IS unless a
deliberate audit-pattern change is being made. Lines 416's hybrid
`:line § "Section"` is borderline — the section anchor already
solves drift, so the `:47` is harmless redundancy at worst.

Out-of-scope per prompt; logged here so the information is not lost.

---

## §7 — PREFLIGHT line (paste exactly)

```
PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD b5221ee2b4ff2f652a9f883c2dfe051b811123bb; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-T1-NIT.md
```

---

## Definition of Done

- [x] `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §6.1 "Unchanged from §6" paragraph no longer contains `"line ~329"` or `"~329"` — PASS (post-edit grep returns zero hits).
- [x] Section/paragraph-name anchor now used: `at the top of §6` — PASS.
- [x] Only `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` modified (plus the new IMPL-REPORT file at the path named in the prompt). PRE-EXISTING `M pack-ops/BACKLOG.md` + two pre-existing `??` review-report files are not session work. — PASS.
- [x] `git diff --stat` shows tiny diff (+1/-1) — PASS.
- [x] No state-changing git verbs run — PASS (only `git rev-parse`, `git status`, `git diff`).
- [x] PREFLIGHT line emitted before IMPL-REPORT write — PASS (see §7).
- [x] No manifest regen needed — PASS (`maintenance-docs/` is not v11-surface per pack memory rule "Regenerate test-fixtures/manifest.txt on every v11-surface commit"; only `project-template/` and `scripts/` trigger manifest regen).
- [x] Pack memory rule on architect-doc line-number references respected: prefer section/symbol names over line numbers — PASS.

---

## Files changed inventory

| Path | Change type |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` | modified |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-T1-NIT.md` | new (this report) |

No deletions. No renames. No trinity edits required (the change is in a `maintenance-docs/` architect doc, not a trinity-symmetry surface).

---

## Plan deviations

None. The edit landed exactly as the prompt described: replace the
soft locator with a section-name anchor. The reviewer-suggested
phrasing `at the top of §6` was confirmed precise (verified against
§6 structure at lines 325-340) and used verbatim.

## New POQs introduced

None. The out-of-scope line-number references logged in §6 are
informational triage feed-in for Pack Chat, not new POQs against the
architecture.
