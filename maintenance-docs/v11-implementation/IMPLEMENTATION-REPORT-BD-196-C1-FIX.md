# IMPLEMENTATION-REPORT — BD-196 Commit C1 FIX (NIT-1)

**Fix-coder pass:** 1 of max-2. **Commit:** C1 review-fix.
**Finding fixed:** NIT-1 from `PACK-REVIEW-BD-196-C1.md` — `P-missed-7`
left untagged; user decided it IS spawn-relevant (pasted into agent
prompts touching project-side surfaces per the §9.3 test) and must be
tagged in C1.
**Plan/Design:** `PLAN-DOC-CONCISION-GUARDRAILS.md` § C1;
`ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §5.1 / §9.3 / §9.4 / §9.5.
**Branch:** `v11-dev`. **HEAD (no commits by coder):**
`96b174a6beed284b7bb90af4e56b3cc820ccb925`.
**Agent:** pack-coder (fix). **Date:** 2026-05-30.

---

## 1. What changed

In ALL THREE trinity files identically, the `## Pack memory` rule
`P-missed-7 — project-side investigation precedes pack-style defaults`
was tagged exactly like the other 20 spawn-relevant rules:

1. **Two-clause `<DIRECTIVE>+<TRIGGER>` imperative line (§5.1)** added as
   the rule's reshaped opening sentence, application-grade so an agent
   that never reads the rationale can apply it:
   > Before changing ANY project-side file (`project-template/` trees,
   > project-shipped content), investigate whether a project-side SSOT
   > exists for the concept and use it — never reach for a pack-style
   > mechanism (`pack-ops/` files, Pack Chat orchestrator role, pack-*
   > agent names, `maintenance-docs/` records) by default, since those
   > are PACK-ONLY and importing them is a client-install regression.
   - `<DIRECTIVE>` = investigate the project-side SSOT and use it; never
     reach for a pack-style mechanism by default.
   - `<TRIGGER>` = on any change to a project-side file
     (`project-template/` trees, project-shipped content).
2. **`[roles: universal]`** appended inline (controlled vocab).
3. **`[rationale: boundary-investigation-precedes-pack-defaults]`**
   appended inline (kebab-case, unique among the existing 20).

The original Why / body (the BD-175 V1/V3/V4 worked examples + the
`boundary-investigation` skill pointer) was LEFT IN PLACE — it moves in
C2, not here. No other rule's tag, name, or body was touched. Only the
`## Pack memory` section in each file changed.

## 2. `[roles:]` + `[rationale: slug]` assignment + rationale

| Field | Value | Justification |
|---|---|---|
| `[roles:]` | `universal` | §9.4: P-missed-7 governs ANY actor that touches a project-side surface — architect / planner / coder / reviewer all qualify, and the rule text itself names "reviewer, implementer, Pack Chat triage." When a rule applies across the full spawned-agent set, §9.4 assigns `universal` (the safe superset that never under-scopes), consistent with how the other broad cross-cutting rules — git-ban, Rules-Applied, STOP-MEANS-STOP, trinity, prison — were classified `universal` in C1. A role-subset (e.g. `architect planner coder reviewer`) would enumerate every controlled-vocab role anyway; `universal` is the canonical equivalent and matches the C1 convention. |
| `[rationale: slug]` | `boundary-investigation-precedes-pack-defaults` | Kebab-case (`^[a-z0-9]+(-[a-z0-9]+)*$`); semantically stable; maps 1:1 to the rule name "project-side investigation precedes pack-style defaults"; UNIQUE among the 20 existing slugs (zero collisions). The C2 rationale file `## <slug>` heading and the C3 bijection key on it. |

## 3. Re-read confirmation (21 slugs now; parity held; no other rule changed; count unchanged)

| Check | Result |
|---|---|
| `[rationale:]` tags per file | 21 / 21 / 21 (was 20 / 20 / 20; +1 for P-missed-7 only) |
| `## Pack memory` bullet count per file | 45 / 41 / 41 — UNCHANGED from HEAD (the 45-vs-41 split is the pre-existing Claude-only sub-section exemption) |
| Slug sets across trinity | byte-identical (sorted `diff` empty CLAUDE==AGENTS==GEMINI) |
| New slug present | exactly 1 occurrence per file |
| Duplicate slugs | none (`sort \| uniq -d` empty) |
| Other 20 tags touched? | NO — the only added lines mention `boundary-investigation-precedes-pack-defaults` / the reshaped P-missed-7 opening; no other rule's slug, roles, name, or body changed |
| P-missed-7 body (Why / BD-175 examples / skill pointer) | left in place verbatim (moves in C2) |
| Bold rule NAME `**P-missed-7 — project-side investigation precedes pack-style defaults.**` | byte-identical to HEAD; only post-name prose reshaped |

Commands:
- `awk` bullet count over `## Pack memory` → `### Project goals` range: 45/41/41 unchanged.
- `grep -o "rationale: [a-z0-9-]*" | sort` → identical across the 3 files; 21 each.
- `git diff CLAUDE.md | grep '^+'` added lines confined to the P-missed-7 reshape + tag.

## 4. validate-pack.py PASS evidence

`python3 scripts/validate-pack.py` → exit `0`, final line
`PASSED — all checks clean`. Trinity-parity checks green:

```
── Check 11: Pack agent trinity-rule symmetry (informational) ──
── Check 16 [pack-root]: ... surface exempt (template-only) ──
── Check 18 [pack-root]: Trinity H2 structure parity (BD-059, BD-181) ──
── Check 19 [pack-root]: Trinity templates free of body scaffolding ──
PASSED — all checks clean
```

The inline `[roles:]` / `[rationale:]` tags are trinity text already
governed by the trinity rule; no structure check asserts on them yet
(correct for C1 — "NO check wired"). Parity holds by construction.

## 5. No manifest regen (pack-root trinity)

Edited paths are repo-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` —
NOT under any of the 4 manifest-regen trigger directories
(`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`).
They are pack-self-management ops files; `scripts/init-project.sh` does
not copy pack-root trinity to clients. No `test-fixtures/build.sh`
rebuild, no `manifest.txt` staging required.

## 6. Files changed (inventory)

| Path | Change type |
|---|---|
| `CLAUDE.md` | modified (`## Pack memory` → P-missed-7 only) |
| `AGENTS.md` | modified (`## Pack memory` → P-missed-7 only) |
| `GEMINI.md` | modified (`## Pack memory` → P-missed-7 only) |

No new source files, no deletions, nothing outside the trinity touched.

## 7. Plan deviations

ZERO. The fix applied exactly NIT-1's user-approved scope: tag the one
rule P-missed-7 (two-clause imperative + `[roles: universal]` +
`[rationale: boundary-investigation-precedes-pack-defaults]`), body
left for C2, trinity lock-step, no check wired, no manifest regen.
Result: 21 tagged rules.

## 8. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | Coder ran only `git rev-parse HEAD` / `git status` / `git diff` (read-only). HEAD `96b174a6…` unchanged start→end. No `add`/`commit`/`push`/`tag`/`mv`/`rm`. | COMPLIANT |
| EDIT IN PLACE — targeted Edit, count unchanged | Three targeted `Edit` calls (one per trinity file); no `Write` to any trinity file. Re-read: bullet count 45/41/41 unchanged; only P-missed-7 region changed; other 20 tags untouched. | COMPLIANT |
| TRINITY lock-step | Same `old_string`→`new_string` applied to CLAUDE/AGENTS/GEMINI; slug sets byte-identical (sorted `diff` empty); `[rationale:]` count 21 each; opening block was byte-identical at HEAD across all three before editing. | COMPLIANT |
| Preserve rule meaning (reshape + tag only) | Reshaped opening pulls existing requirement UP without altering what P-missed-7 requires (investigate project-side SSOT first; don't default to pack mechanisms). Original Why/body retained verbatim below. Bold NAME byte-identical to HEAD. | COMPLIANT |
| PREFLIGHT before fix-report | Emitted `PREFLIGHT: 3/3 … verification PASS … HEAD 96b174a6… about to Write fix-report …` immediately before this Write. | COMPLIANT |
| Verification before PREFLIGHT (validate-pack 11/16/18/19 + full suite) | `python3 scripts/validate-pack.py` exit `0`; `PASSED — all checks clean`; Checks 11/16/18/19 present and green. Pack-root trinity → NO manifest regen (documented §5). | COMPLIANT |
| Output ends with Rules-Applied Verification Block | This block. | COMPLIANT |
| STOP-MEANS-STOP | No parent stop/halt/revert/do-not-continue message received during the run. | N/A: no stop signal |
| PERMISSION BOUNDARIES (in-scope edits + fix-report; no git state change; no destructive ops) | Edited only the three trinity `## Pack memory` P-missed-7 entries + wrote this fix-report; no git state-changing or destructive verb run. | COMPLIANT |
| PRISON RULE | No file under `maintenance-docs/prison/` read, cited, or trusted; sources were the review NIT-1, the C1 IMPL-REPORT, the design (§5.1/§9.3/§9.4/§9.5), and the live trinity corpus. | COMPLIANT |

**End of IMPLEMENTATION-REPORT-BD-196-C1-FIX.md.**
