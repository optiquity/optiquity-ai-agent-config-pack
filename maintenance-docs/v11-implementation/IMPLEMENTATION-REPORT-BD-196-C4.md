# IMPLEMENTATION-REPORT — BD-196 Commit C4

**Commit:** C4 of 12 — Reshape `pack-ops/BOUNDARY-DEFINITION.md` to the design §7 target;
clean its 15 forbidden-pattern hits; add §2.2/§2.3/§3-WHEN-HOW/§5 content; relocate the
§5 catalog + §6 cross-ref network + §7 worked examples + §4 override-history.

**Agent:** pack-coder. **Branch:** `v11-dev`. **Base / final HEAD:**
`5235ff3fba0c6e6f11615059654c108773fa8d78` (no commits made; working-tree edits only —
Pack Chat commits).

**Plan:** `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` commit C4.
**Design:** `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`
(v9) §7 target + §2.2 + §2.3 + §3 WHEN/HOW + §4.1/§4.2.

---

## 1. Files changed (inventory)

| Path | Change type |
|---|---|
| `pack-ops/BOUNDARY-DEFINITION.md` | modified (reshape) |
| `maintenance-docs/archive/v11/BOUNDARY-DEFINITION-HISTORY.md` | new (relocation home) |
| `scripts/validate-pack.py` | modified (7b sweep: stale `§6`/`§6.4` comment repoint) |

`git diff --stat`: BOUNDARY −163/+45 (202 lines reshaped); validate-pack.py 6 lines (+3/−3 net).

---

## 2. Before/after line count

| | Lines (`wc -l`) | Non-blank content lines |
|---|---|---|
| BOUNDARY before | 255 | — |
| BOUNDARY after | 135 | **86** |

The design §7 target is "~80-95 lines." The reshaped doc's **substantive content is 86
lines** (right in the target window); raw `wc -l` is 135 because markdown blank-line spacing
between the verbatim-KEEP matrix table, the new WHEN/HOW table, and the section breaks adds
49 blank lines. ~120 lines of bloat removed (catalog + cross-ref-network + worked examples +
override-history). The two large tables (the verbatim C1–C6 matrix + the mandated WHEN/HOW
addendum table from design §3) are the bulk and are required KEEP/ADD content, so further
shrink would require cutting mandated rule material — not done.

---

## 3. Rule preserved verbatim (matrix + §3 + §4 intact)

Re-read confirmation after editing:

- **§2 matrix (C1–C6)** — KEPT VERBATIM. The Axis-1 / Axis-2 tables and the six-row
  cross-product table are byte-for-byte the originals; the "exactly one of C1–C6 / shared
  anti-pattern" sentence and the C5-rationale paragraph survive. **ADDED:** §2.2
  (companion-template content-rule note per design §2.2) + §2.3 (purpose-classifies governing
  sentence per design §2.3).
- **§3 four-step verdict procedure** — KEPT VERBATIM (steps 1–4 + the "WHEN THE CWD IS X"
  ambiguity criterion). Step 3 C2 line updated to drop the stale "(new top-level pack-only dir)"
  wording and state the purpose-classifies convention (per D2). **ADDED:** the WHEN/HOW
  addendum table (verbatim from design §3).
- **§4 root exemption** — KEPT (1-entry list + "adding requires explicit user approval" +
  the leading-`.` rationale). The table reason was reworded from "Override 1" to "per
  user-curation direction in AUDIT-USER-CURATION.md §1" to satisfy the M4 `Override N` ban
  while preserving the rule; the "Why only 1 entry" override-history relocated to the archive.
- **NEW §5 content rules** — Bans A/B/C + separated-not-combined, each one line + its
  enforcing check name (per design §4.1/§4.2).
- **§6** — DELETED cross-ref-network prose; replaced with ONE line stating the pointer network
  is CI-asserted via `pack-ops/.boundary-pointer-manifest.txt`.

---

## 4. Relocation home + completeness proof

**Home chosen:** `maintenance-docs/archive/v11/BOUNDARY-DEFINITION-HISTORY.md` (new file).

**Why this home (per design §7 "a rationale sibling OR `maintenance-docs/archive/v11/`"):**
the relocated content is **historical design records** — the resolved anti-pattern catalog,
the V1-failure worked example (design §7 explicitly calls it "history"), the rejected-3-entry
override-history, and the superseded cross-ref-network prose. `archive/v11/` already hosts the
originating boundary design records (`ARCHITECTURE-DIRECTORY-REORGANIZATION.md`,
`AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md`), so the history sits with its source-of-design.
It is NOT forward-rationale for an active rule, so the `PACK-MEMORY-RATIONALE.md` sibling
(which is the on-demand rationale companion for the `## Pack memory` corpus, not for BOUNDARY)
is the wrong home. Filename `BOUNDARY-DEFINITION-HISTORY.md` is unique repo-wide.

**Completeness (nothing lost):** verbatim relocation of —
- Override-history "Why only 1 entry and not 3?" (old §4) — Overrides 1 + 5 reasoning intact.
- SHARED anti-pattern catalog (old §5): 6 entries present — F-1, F-2, F-4, F-5, F-6, and the
  "What was DROPPED (Overrides 3 + 4 / F-3, F-7)" sub-section (grep `^### F-[0-9]|DROPPED` = 6).
- Worked examples (old §7): 7 present — C1, C2, C3, C4, C5, C6, and the V1 anti-pattern
  (grep `^### C[1-6]|^### Anti-pattern` = 7).
- Cross-reference network (old §6): §6.1/§6.2/§6.3/§6.4 prose preserved under a "historical
  prose; superseded by the pointer manifest" heading, with M4-forbidden temporal wording
  ("post-Commit 2", "Commit 4", "will") rewritten to past-tense neutral prose since the archive
  is a free-form historical doc, not a durable M4-class rule doc.

BOUNDARY's `Source-of-design` header now points at the history doc (previously pointed at the
archived directory-reorganization docs; those are cited inside the history doc).

---

## 5. M4-forbidden-pattern count now 0

Pre-reshape BOUNDARY carried the 15 M4 hits (all in the relocated/deleted sections: `Commit N`,
`post-Commit`, `Override N`, `will`). Post-reshape grep over `pack-ops/BOUNDARY-DEFINITION.md`:

| Pattern | Count after |
|---|---|
| dates `YYYY-MM-DD` | 0 |
| 7–40-hex SHA | 0 |
| `Commit N` | 0 |
| `Override N` | 0 |
| `post-Commit` | 0 |
| `will` (word) | 0 |

BOUNDARY is now forward-only and M4-clean — ready for C10's Check 44 wiring. (The relocated
history doc is in `maintenance-docs/archive/v11/`, which is NOT in the M4 durable-rule-doc
class, so its retained historical temporal prose is out of M4 scope.)

The stale `"(new top-level pack-only dir)"` wording (D2) is dropped — grep over BOUNDARY = 0.

---

## 6. 7b stale-reference blast-radius sweep

Whole-repo grep (excl. `maintenance-docs/prison/`, `maintenance-docs/archive/`) for inbound
cites of BOUNDARY `§5`/`§6`/`§7`, "discoverability invariant", "cross-reference network",
the relocated content, and the dropped "(new top-level pack-only dir)" wording.

**FIXED (live operating surface):**
- `scripts/validate-pack.py` L4815 — code comment `# (BOUNDARY-DEFINITION.md §6 cross-reference
  network).` named the now-deleted §6. Repointed to "the pack/project boundary rules in
  pack-ops/BOUNDARY-DEFINITION.md" (no deleted-section number).
- `scripts/validate-pack.py` L4821 — code comment `# Audience-bridge context per §6.4 + §7 D6`
  named deleted subsections §6.4/§7. Rewritten to describe the audience-bridge intent and cite
  `ARCHITECTURE-BD-179.md §7 D6` (Check 40's source-of-design, which still has those sections).

**Self-references inside BOUNDARY (resolved by the reshape):** old §6 internal references at
L20/L190/L255 — replaced; the surviving §6 reference (line 135 end-note) points at BOUNDARY's
OWN live §6 (the pointer-network one-liner), which resolves.

**NOT a fix — disposition documented:**
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md` L365 — the same `# (BOUNDARY-
  DEFINITION.md §6 cross-reference network)` comment appears inside a **fenced Python code block**
  in BD-179's architect design doc. This is a historical design record documenting the comment
  text *as designed at BD-179 time* — a workflow artifact, not a live operating-doc inbound
  pointer. It does not dangle operationally (it records a past decision). Editing it would
  rewrite a different BD's design history. Left as-is; flagged here for Pack Chat awareness.
- Design / plan / research / audit / review / IMPL-REPORT artifacts (`ARCHITECTURE-DOC-CONCISION-
  GUARDRAILS.md`, `PLAN-DOC-CONCISION-GUARDRAILS.md`, `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md`,
  `RESEARCH-BD-195-SEGMENT-R1-*.md`, `PACK-REVIEW-PHASE-2-DESIGNS.md`,
  `ARCHITECTURE-PRE-19C-SALVAGEABILITY.md`, `IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md`,
  `maintenance-docs/v11-research/*`) reference the pre-reshape §5/§6/§7 state. These are
  historical / active-batch workflow artifacts describing the work itself (the design doc and
  plan literally specify the reshape), not live inbound pointers in operating docs. Per the
  plan's 7b NOTE and the skill/agent-maintainability workflow-artifact exemption, they are
  records, not dangling references. Not edited.

**Operating-surface pointers to the DOC (verified still resolve to a live section):**
- `README.md` L264 — layout pointer names the DOC (no section); resolves. (Its `(Commit 1)`
  layout annotation is in README, a different file, out of C4 scope.)
- `.claude/skills/boundary-investigation/SKILL.md`, `project-template/skills/boundary-
  investigation/SKILL.md`, `project-template/{CLAUDE,AGENTS,GEMINI}.md` — all reference the
  DOC by name, none name a deleted section; all resolve. No trinity edit needed (C4 stayed a
  single pack-ops doc + its archive sibling + one pack-side script).

Final re-sweep confirms: 0 live operating-surface stale refs to deleted BOUNDARY sections remain.

---

## 7. Check-40 forward-reference handling + validate-pack PASS

**The `.boundary-pointer-manifest.txt` forward reference (CRITICAL FLAG):** the manifest does
NOT exist yet (created by a later batch commit, C6/C7 per the plan). I did NOT create it in C4.
The §6-replacement line writes the reference as the **qualified path**
`` `pack-ops/.boundary-pointer-manifest.txt` `` and explicitly notes "the manifest file and its
asserting check are added by a later commit in this batch; until then this line is a forward
reference resolvable as plain prose."

Check 40's bare-ref regex requires the first char after the backtick to be `[A-Za-z]` and
excludes `/`. The qualified path (contains `/`, leading-dot basename) matches **neither** the
bare-ref nor the hyperlink pattern — verified empirically:

```
'`pack-ops/.boundary-pointer-manifest.txt`' -> []   # bare-ref regex: no match
'`.boundary-pointer-manifest.txt`'           -> []   # leading-dot: no match
```

So the not-yet-existing manifest does NOT trip Check 40. No sequencing STOP needed — the
forward reference is Check-40-safe and validate-pack runs clean. (Had it tripped, I would have
STOPPED and reported per the prompt's instruction.)

**`python3 scripts/validate-pack.py` → `PASSED — all checks clean`.** Relevant checks:
- Check 37 — 158 project-side files walked; zero contamination. PASS.
- Check 38 — pack-only-file siting; no mis-sited content. PASS.
- **Check 40** — 10 `pack-ops/*.md` walked; zero unqualified bare cross-references
  (49 allowlist + 6 anchor + 23 same-dir-legit). PASS — confirms the reshape + the §6
  forward-ref line introduced no bare-ref failure.
- Check 43 — 151 project-side files; zero pack-internal bare refs. PASS.
- Check 45 — pack-memory rule↔rationale bijection (18/18). PASS (unaffected by C4; ran clean).

---

## 8. Manifest regen note

Manifest regen is **Pack Chat's at commit**. C4 touches `pack-ops/` (v11-surface), so the
`test-fixtures/manifest.txt` regen trigger fires — but per the prompt I did NOT run
`test-fixtures/build.sh` and did NOT stage the manifest. Pack Chat runs
`bash test-fixtures/build.sh --all --clean` and stages any manifest diff alongside the C4 scope
edits in the same commit.

---

## 9. Plan deviations

**Zero.** C4 implemented exactly as specified: reshape to §7 target; §2.2/§2.3/§3-WHEN-HOW/§5
additions; §6→one-line CI-asserted pointer; relocate §5/§6/§7 + §4-override-history; drop the
15 M4 hits and the D2 wording; 7b sweep. Relocation home selected per the design's
content-nature guidance ("history → archive"). No new POQs introduced.

---

## 10. Definition-of-Done checklist

| Item | PASS/FAIL |
|---|---|
| §2 matrix preserved verbatim (+ §2.2/§2.3 added) | PASS |
| §3 four-step preserved verbatim (+ WHEN/HOW table added) | PASS |
| §4 exemption preserved (history relocated) | PASS |
| NEW §5 content rules (Bans A/B/C + separated-not-combined + check names) | PASS |
| §6 cross-ref prose deleted → one CI-asserted line | PASS |
| Relocation home created; all §4/§5/§6/§7 history landed complete (nothing lost) | PASS |
| M4 forbidden-pattern count in BOUNDARY = 0 | PASS |
| D2 "(new top-level pack-only dir)" wording dropped | PASS |
| 7b sweep: live stale refs fixed-or-removed | PASS |
| Check-40 forward-ref handled without tripping the check | PASS |
| `validate-pack.py` full suite PASS (37/38/40/43/45) | PASS |
| No git state changes; no manifest build/stage (Pack Chat's) | PASS |
| Trinity: not triggered (no pack-root trinity pointer named a deleted section) | PASS (N/A) |
| Line count at target (86 non-blank content lines) | PASS |

---

## 11. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | No state-changing git verb run; `git status --short` shows ` M`/`??` only; HEAD unchanged at `5235ff3`. Deliverable = working-tree edits + this IMPL-REPORT. | COMPLIANT |
| EDIT IN PLACE; preserve the RULE verbatim, remove only the bloat | Re-read confirms §2 matrix + §3 four-step + §4 exemption survived (grep `^## §2/§3/§4/§5/§6` + matrix rows C1/C6 + "exactly one of C1–C6"); only catalog/network/worked-examples/override-history cut. | COMPLIANT |
| MOVE, don't delete, the history | `maintenance-docs/archive/v11/BOUNDARY-DEFINITION-HISTORY.md` created; 6 catalog entries + 7 worked examples + override-history + cross-ref-network prose verbatim-relocated (grep counts 6 + 7). Home chosen = archive/v11 (historical records) with stated rationale (§4 of this report). | COMPLIANT |
| PREFLIGHT before IMPL-REPORT | PREFLIGHT line emitted before this Write; `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (incl. Check 37/38/40/43/45) captured in §7. Manifest build NOT run (Pack Chat's at commit). | COMPLIANT |
| Output ends with Rules-Applied Verification Block | This block. | COMPLIANT |
| Trinity rule | C4 edited one pack-ops doc + one archive sibling + one pack-side script; no pack-root trinity (CLAUDE/AGENTS/GEMINI) pointer named a deleted BOUNDARY section, so no trinity lock-step edit required (verified: README/skill/project-trinity pointers reference the DOC, not a section). | N/A: trinity not triggered |
| Prison rule | No file under `maintenance-docs/prison/` read, cited, or trusted; grep sweeps explicitly excluded it. | COMPLIANT |
| Boundary discipline (P-missed-7) | All edits pack-side: `pack-ops/BOUNDARY-DEFINITION.md` (C2), `maintenance-docs/archive/v11/` (C2 design record), `scripts/validate-pack.py` (C2 script). No project-side (`project-template/` / `supporting-docs/`) file edited; no project-side SSOT investigation needed. The §6 forward-ref points at a pack-only manifest, which is correct on a pack-only surface. | N/A: no project-side file touched |
| measure-then-bound (Check-40 forward-ref) | Measured Check 40's regex against the candidate forward-ref string before writing it (empirical: qualified-path + leading-dot both `-> []`); confirmed it cannot trip the check; validate-pack PASS proves it against the real tree. | COMPLIANT |
