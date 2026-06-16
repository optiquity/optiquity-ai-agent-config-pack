# IMPL-REPORT — BD-221 POQ-C5-1 — A2 fix (ref-qualification)

- **BD:** BD-221 (Antigravity transition) — POQ-C5-1
- **Fix:** A2 — qualify project-side bare refs (per `filename-uniqueness-heuristic`); NOT A1 (allowlist, rejected)
- **Scope keyword:** project-only
- **Regime:** IN-PLACE (parent working tree); agent did NOT stage or commit
- **Branch:** v11-dev
- **HEAD at pre-flight + completion (unchanged — no commit):** `f0952b6d82ed67b0e2988ad0787e7b4a773aba40`
- **Base contains the parked C5 pack-self bundle (uncommitted):** confirmed
  (`.agents-plugin/pack-agents/` untracked; `.gemini/agents/pack-*.md` deletions present)

---

## Problem (POQ-C5-1)

C5 created the pack-self plugin bundle `.agents-plugin/pack-agents/` containing
`plugin.json` + `RUNTIME-SUBAGENT-PATTERN.md`. Those two basenames already
existed in the C1 CLIENT bundle `project-template/.agents-plugin/optiquity-agents/`.
Two candidates per basename made every project-side **bare** backtick ref to
those basenames AMBIGUOUS, tripping Check 43
(`check_project_side_bare_internal_refs`) at the "ambiguous (2+ candidates,
none allowlisted, no same-dir match)" failure mode (validate-pack.py
`check_project_side_bare_internal_refs`, ambiguity branch at the `len(candidates) >= 2`
fail). Check 43 was GREEN at the post-C4 baseline; the C5 bundle regressed it.

Key validator-mechanics fact: Check 43's same-dir-legitimate exemption only
fires when `len(candidates) == 1`. With 2 candidates, even a ref **inside** the
client bundle (e.g. `auditor.md` saying "in this plugin") is ambiguous and
fails — so the in-bundle refs also had to be qualified, not just the trinity refs.

---

## The fix = A2 (qualify, per `filename-uniqueness-heuristic`)

`filename-uniqueness-heuristic`: structurally-required-collision basenames
(here: ecosystem-fixed `plugin.json`; plan-mandated `RUNTIME-SUBAGENT-PATTERN.md`
present in BOTH bundles) are exempt from the no-collision preference BUT **their
prose refs MUST carry path context**. So each project-side bare ref was qualified
to the CLIENT bundle path `.agents-plugin/optiquity-agents/<basename>` — these are
CLIENT docs referring to the CLIENT bundle, so they resolve unambiguously to the
client candidate. No allowlist entry (A1, rejected). `scripts/validate-pack.py`
untouched. The pack-self bundle (`.agents-plugin/pack-agents/`, C5's pack-only
work) untouched. Pack-root trinity untouched.

---

## Bare refs found → qualified (before → after, file:line)

The 4 firing Check-43 FAILs at the post-C5 pre-fix baseline (validate-pack
lines 301–304) were exactly these. Each is a backtick-delimited bare basename
on the walked client-installed surface.

### 1. `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md:10` — bare `` `plugin.json` ``

- **Before:** `bundle in this directory (`plugin.json` + `agents/`) is the **primary**`
- **After:** `bundle in this directory (`.agents-plugin/optiquity-agents/plugin.json` +` / `agents/`) is the **primary**`
  (prose "in this directory" preserved; the bare `plugin.json` now carries the client-bundle path; line wrapped to keep readable width)

### 2. `project-template/.agents-plugin/optiquity-agents/agents/auditor.md:36` — bare `` `RUNTIME-SUBAGENT-PATTERN.md` ``

- **Before:** `pattern — see` / `` `RUNTIME-SUBAGENT-PATTERN.md` in this plugin) and a subagent does not``
- **After:** `pattern — see` / `` `.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` in this plugin) and a subagent does not``
  (prose "in this plugin" preserved; the bare basename now carries the client-bundle path)

### 3. `project-template/GEMINI.md:458` — bare `` `plugin.json` ``

- **Before:** `` `.agents-plugin/optiquity-agents/` — a `plugin.json` manifest plus``
- **After:** `` `.agents-plugin/optiquity-agents/` — a `.agents-plugin/optiquity-agents/plugin.json` manifest plus``

### 4. `project-template/GEMINI.md:459` — bare `` `RUNTIME-SUBAGENT-PATTERN.md` ``

- **Before:** `` `agents/*.md` (16 role templates) and a `RUNTIME-SUBAGENT-PATTERN.md` fallback.``
- **After:** `` `agents/*.md` (16 role templates) and a `.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` fallback.``

### Refs deliberately NOT touched (already-resolving / not-firing — `scope-deliverables-to-the-ask`)

- `project-template/GEMINI.md:468` — already qualified
  (`.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md`); did not fire Check 43.
- `project-template/agent-run.sh:22,28` — plain `#`-comment prose mentions
  (`plugin.json`, `RUNTIME-SUBAGENT-PATTERN.md`) NOT in backtick-bare form; did
  not fire Check 43. Left as-is (touch nothing outside the ask).
- `project-template/.agents-plugin/optiquity-agents/plugin.json:5` — the
  `comment-RE-VERIFY` JSON string mentions `plugin.json`/`RUNTIME-SUBAGENT-PATTERN.md`
  as prose inside a value; not a backtick-bare ref; did not fire. Left as-is.

These are correct non-edits: only the 4 Check-43-FAILing bare refs were qualified.

---

## Verification

### Check 43 — GREEN (quoted banner, post-fix)

```
── Check 43: Project-side bare cross-reference scanner (BD-173) ──
  OK: Check 43 — 157 project-side / client-installed file(s) walked; zero pack-internal bare cross-references (566 allowlist-exempt + 16 anchor-phrase-exempt + 8 same-dir-legit + 129 client-installed-legit + 582 fenced-line(s) accepted)
```

### Full failing set — matches target (header-aware parse)

Command: `python3 scripts/validate-pack.py` → header-aware association of each
`FAIL:` line with its nearest preceding `── Check N ──` header.

- **Post-fix failing set:** `{5, 17, 18, 21, 28, 39, 41, 52, 55, 56, 57}`
- **Expected target set:** `{5, 17, 18, 21, 28, 39, 41, 52, 56, 55, 57}`
- **MATCH:** True
- **Check 43 present?** No (removed by the fix)
- **52 present (C5 pack-deletion break → restored at C8)?** Yes
- **56 present (C5 pack-deletion break → restored at C8)?** Yes
- **No other new break.**

Per-check fail counts (post-fix): `{5:3, 17:1, 18:2, 21:1, 28:1, 39:5, 41:5, 52:5, 55:16, 56:1, 57:16}`

Pre-fix baseline (with C5 bundle, before A2) for delta proof:
`{5, 17, 18, 21, 28, 39, 41, 43, 52, 55, 56, 57}` with `43:4`. Delta = Check 43
went `4 FAILs → GREEN`; every other check's count is byte-identical (no
collateral). This is the exact baseline-delta the fix targets.

### Scope verification

- `git diff --name-only` (my 3 project-side edits + the pre-existing parked C5
  `.gemini/agents/pack-*.md` deletions that were already in the tree):
  - `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` (MINE)
  - `project-template/.agents-plugin/optiquity-agents/agents/auditor.md` (MINE)
  - `project-template/GEMINI.md` (MINE)
  - `.gemini/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md`
    (PARKED C5 — pre-existing, NOT mine)
- `git diff --stat scripts/validate-pack.py` → empty (validator UNTOUCHED).
- `.agents-plugin/pack-agents/` (C5 pack-self bundle) → untracked, NOT modified by me.
- Pack-root trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` at repo root) →
  `git diff --name-only --` empty (UNTOUCHED).

### Manifest (`regenerate-manifest-v11-surface`) — N/A for this fix

`test-fixtures/manifest.txt` is a fixture-build content manifest, not a per-file
path listing. `scripts/init-project.sh` does NOT (yet) install the
`.agents-plugin/` bundle (`grep agents-plugin scripts/init-project.sh` → 0 hits),
so the bundle content does not flow into any fixture; `git diff --stat
test-fixtures/manifest.txt` is empty both at HEAD and after my edits. No manifest
regen is in scope for the A2 ref-qualification. (If/when a later C-step wires
`.agents-plugin/` into `init-project.sh`, the manifest-regen rule applies to THAT
commit — flagged here for Pack Chat, not actioned in this fix.)

---

## Files changed (inventory)

| Path | Change type | Author |
|---|---|---|
| `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` | modified (1 bare ref qualified) | this A2 fix |
| `project-template/.agents-plugin/optiquity-agents/agents/auditor.md` | modified (1 bare ref qualified) | this A2 fix |
| `project-template/GEMINI.md` | modified (2 bare refs qualified) | this A2 fix |

(The 5 `.gemini/agents/pack-*.md` deletions in the working tree are the PARKED
C5 pack-self bundle work present before this session — NOT part of this A2 fix.)

---

## Plan deviations

Zero. The fix is exactly A2 ref-qualification of the 4 firing bare refs, using
the client bundle path. No allowlist, no validator edit, no pack-self/trinity edit.

## New POQs

None.

---

## Definition-of-Done checklist

| Item | Result |
|---|---|
| Every project-side firing bare ref to the 2 basenames qualified | PASS (4/4) |
| Qualified to the CLIENT bundle path `.agents-plugin/optiquity-agents/` | PASS |
| Surrounding prose preserved (`edit-in-place-not-full-rewrite`) | PASS |
| Check 43 GREEN (banner quoted) | PASS |
| Failing set == `{5,17,18,21,28,39,41,52,56,55,57}` (no 43; 52/56 present) | PASS |
| No other new break vs post-C4 baseline | PASS |
| Allowlist NOT used (A1 rejected) | PASS |
| `scripts/validate-pack.py` NOT edited | PASS |
| Pack-self bundle `.agents-plugin/pack-agents/` NOT edited | PASS |
| Pack-root trinity NOT edited | PASS |
| Project-only scope (only project-side files touched by me) | PASS |
| No git state change (agent did not stage/commit) | PASS |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (measured/quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | All changes via Edit tool IN-PLACE. No git state-changing verb run; only read-only `git rev-parse`, `git status`, `git diff --name-only`, `git diff --stat`. HEAD unchanged: pre-flight `git rev-parse HEAD` = `f0952b6d82ed67b0e2988ad0787e7b4a773aba40`; same at completion (no commit). Pristine reads done via Read/`git diff` against HEAD, not checkout. | COMPLIANT |
| **filename-uniqueness-heuristic** | The fix EMBODIES this rule: `plugin.json` (ecosystem-fixed) + `RUNTIME-SUBAGENT-PATTERN.md` (plan-mandated in both bundles) are structurally-required collisions → their prose refs now carry path context (`.agents-plugin/optiquity-agents/<basename>`) rather than being suppressed via allowlist. 4 refs qualified; `_CHECK_43_ALLOWLIST` untouched (`git diff --stat scripts/validate-pack.py` empty). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | 4 targeted `Edit` calls on the ref strings only; surrounding prose preserved verbatim ("in this directory", "in this plugin", "manifest plus", "fallback" all intact — see the 3 `git diff` hunks quoted in §Verification, each a 1–3 line change). No full-file rewrites. | COMPLIANT |
| **bd-pack-only-operational-rule** | Qualified targets are CLIENT-bundle paths (`.agents-plugin/optiquity-agents/...`) in CLIENT docs (`project-template/...`). No pack-self concept introduced: no `pack-ops/`, no `maintenance-docs/`, no pack-* agent name, no Pack-Chat role reference added to any project-side file. Verified: the new path strings contain only `optiquity-agents` (client bundle), never `pack-agents`. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Exactly the 4 firing Check-43 bare refs qualified; the non-firing mentions (GEMINI.md:468 already-qualified; agent-run.sh `#`-comments; plugin.json JSON-value prose) deliberately left untouched — documented in §"Refs deliberately NOT touched". No validator/pack-self/trinity/manifest edits. | COMPLIANT |
| **verify-full-ci-suite** | Ran `python3 scripts/validate-pack.py` (full battery). Check 43 GREEN (banner quoted). Header-aware failing-set parse confirms `{5,17,18,21,28,39,41,52,55,56,57}` == target, no 43, 52/56 present (→C8), zero collateral vs pre-fix baseline (every other check's count byte-identical; only Check 43 changed 4→0). | COMPLIANT |
| **rules-applied-verification-block** | This block: per-rule, with quoted/measured evidence and a COMPLIANT/N-A/VIOLATED terminal conclusion; no AMBIGUOUS; no empty-evidence row. | COMPLIANT |
