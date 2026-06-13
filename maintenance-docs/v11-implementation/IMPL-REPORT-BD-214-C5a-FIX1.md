# IMPL-REPORT — BD-214 C5a FIX-1 (NIT-1: BD-185 title accuracy)

**Agent:** fresh pack-coder (single approved review fix)
**Date:** 2026-06-13
**Branch:** v11-dev
**Base HEAD (pre-flight):** cdfe87dd6a7a063d0a5c913265b7e230f144d3c8
**Final HEAD (unchanged — agents never commit):** cdfe87dd6a7a063d0a5c913265b7e230f144d3c8
**Working-tree note:** C5a edits were already in the working tree (uncommitted) at spawn; this fix layers ONE title-line edit on top of them. No commit/stage performed.

---

## The fix (NIT-1, user-approved 2026-06-13)

`backlog/BD-185.md` was re-scoped flat-file-only in C5a (tracker-mode execution
ordering moved to the new entry BD-216). The bold-header title still claimed
"tracker-mode execution ordering," which overclaimed the entry's CURRENT scope.

### Title change

| | Title text |
|---|---|
| **Old (line 2)** | `**BD-185 — Phase parts hierarchy + tracker-mode execution ordering**` |
| **New (line 2)** | `**BD-185 — Phase-parts hierarchy + flat-file execution ordering**` |

**Wording rationale (matched to the as-re-scoped body):**
- The body re-scopes the entry to its FLAT-FILE half (the `RE-SCOPE 2026-06-13`
  line; `File/Symbol (flat-file half — this entry):`; `Goal (flat-file half…)`;
  `Success Criteria (flat-file half — this entry)`). The tracker legs (SC6/SC7,
  P3, the `work-item.yml` Part field, TrackerProvider sync) are explicitly
  "MOVED to BD-216."
- "Phase-parts hierarchy" mirrors the body's hierarchy concept (P2: "Phase N →
  Parts (1..p)") and the entry's first half. Hyphenated "Phase-parts" matches
  the dominant in-body usage ("phase-parts structure," "phase-parts design,"
  "round-trip phase-parts").
- "flat-file execution ordering" mirrors the retained SC4 (flat-file leg):
  "Execution ordering of phases is expressible in flat-file mode via execution
  notes." The dropped "tracker-mode" qualifier is precisely the leg now carried
  by BD-216 (P3 / SC4-tracker).
- The edit touches ONLY the title text after `BD-185 — `. The ID, the em-dash,
  and the entire entry body are unchanged. No parenthetical before the em-dash;
  no letter suffix.

### Scope discipline
- Edited ONLY `backlog/BD-185.md` line 2 + regenerated `backlog/_toc.md`.
- No other entry touched. No BD-185 body change introduced by this fix (the body
  diff visible in `git diff` is the pre-existing C5a working-tree re-scope; my
  contribution is the single title line, confirmed by inspecting the diff).
- Nothing outside `backlog/` was modified.

---

## TOC regeneration

Regenerated via the sanctioned helper (never hand-edited):

```
bash -c 'source scripts/lib/per-entry/toc-regenerate.sh \
  && per_entry_regenerate_toc pack-backlog backlog'
# EXIT=0
```

(First attempt failed only because it was run under zsh — the helper uses
`${BASH_SOURCE[0]}` and must be sourced under bash. Re-run under `bash -c`
succeeded with EXIT=0. No partial/hand edit occurred.)

**Resulting BD-185 toc row** (`backlog/_toc.md:19`):
```
- [BD-185](./BD-185.md) — Phase-parts hierarchy + flat-file execution ordering
```

The toc regen also re-derived the other rows from the current entry files
(BD-100/102/105/171/174/216 row/section changes) — these reflect the C5a
working-tree state already present at spawn, NOT new content from this fix. The
only NEW content this fix introduces into `_toc.md` is the BD-185 title row.

---

## Verification — FULL CI suite (both jobs), run locally

### `validate` job

| Step | Command | Result |
|---|---|---|
| Run pack validation | `python3 scripts/validate-pack.py` | **EXIT=0** — `PASSED — all checks clean` |
| Run pack validation (DEEP) | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **EXIT=0** — `PASSED — all checks clean` |

Integrity-relevant checks (general run), quoted:
- **Check 33** (toc in-sync): `OK: backlog/_toc.md byte-identical (22180 bytes)` —
  the regenerated toc matches the tree (my new title is correctly reflected).
- **Check 34** (cross-refs): `OK: cross-reference integrity: 3069 reference(s)
  across 227 per-entry file(s); all resolved to defined IDs` — title change is
  ID-neutral; all refs still resolve.
- **Check 32′** (no monolith): `OK: backlog/ — no monolith present; … filenames
  conform`.
- **DEEP Check 49** (field/body faithfulness incl. title length):
  `OK: Check 49 — 216 entries byte-faithful (codec-lossless + parse-faithful),
  control-char-clean, title ≤ 256 codepoints …` — new BD-185 title is within the
  256-codepoint provider limit.

Pre-existing advisory (NOT a gate failure, NOT introduced by this fix):
Check 48 WARNs on removed-doc citations, including `backlog/BD-193.md:45 cites
ARCHITECTURE-BD-185.md / PLAN-BD-185.md`. These are accurate-history JC-5
advisories, unrelated to the title text; exit code unaffected (`OK: Check 48 …
advisory only`).

### `tests` job — every wired script (per-name, NOT sampled)

Extracted the complete run-command list from both jobs in
`.github/workflows/validate-pack.yml` and ran EACH. All 58 wired
invocations returned EXIT=0.

Part 1 (checks + tracker suites) — all PASS (EXIT=0):
```
detect.sh • tracker-provider • tracker-config • tracker-init • tracker-agent-read
• tracker-migrate-forward • tracker-migrate-reverse • tracker-migrate-roundtrip
• tracker phase-task • tracker links • tracker cycle-check • tracker error mapping
• tracker-config-schema • recommendation-state-schema • per-entry helper
• checks 32/33/34 • checks 36/37/38 • check 39 • check 40 • check 41 • check 18
• check 16 • check 19 • check 42 • check 43 • check 44 • check 45 • check 46
• check 48 removed-doc • check 49/50 field-faith • check 50 codec
• check 51 flip-block • tracker deferral gate
=> ===PART1_DONE fail=0===
```

Part 2 (migrators, fixtures, integration) — all PASS (EXIT=0):
```
tracker BD-129 gh-repo • BD-130 doctor-wired • BD-132 init-disable race
• BD-133 header-preservation • BD-134 close-retry • recommendation • pack-help
• customization-preserve • init-project • migrate-v10-to-v11
• migrate dry-run/apply/resume • migrate verification gates • migrate decompose
• migrator-core • migrator-manifest • migrator-capability-translation
• build test fixtures • restore committed manifest (via /tmp backup, no git)
• fixture manifest verify • v11-realistic-ot integration • migrator-skills
• persona contracts • template-translations • template-version • issue-forms
=> ===PART2_DONE fail=0===
```

**Manifest-restore note (git-state-ban compliance):** the CI `tests` job restores
the committed manifest with `git checkout HEAD -- test-fixtures/manifest.txt`.
That state-changing-looking git verb is BANNED for agents and was denied by the
harness. I reproduced the CI step's INTENT read-only: backed up the committed
`test-fixtures/manifest.txt` to `/tmp` (SHA `8337c164…`) before the
`build.sh --all --clean` step, then restored it via `cp` from the /tmp backup.
Post-run verification confirms `test-fixtures/manifest.txt` is back at SHA
`8337c164449d51bd46fc3224f22bbe56b179d3d3` and `git status --short test-fixtures/`
is EMPTY (no manifest/fixture delta).

---

## Rule 6 — Manifest (backlog/ is not a v11-surface)

`backlog/` is not under `project-template/`, `scripts/`, `pack-ops/`, or
`supporting-docs/`, so the `regenerate-manifest-v11-surface` rule does not apply.
Confirmed: `git status --short | grep -i manifest` returns nothing (exit 1), and
`git status --short test-fixtures/` is empty. No fixture-manifest change.

---

## Files changed (inventory)

| Path | Change type | Note |
|---|---|---|
| `backlog/BD-185.md` | modified | Line 2 title text only (this fix). Body diff present in working tree is the pre-existing C5a re-scope, not this fix. |
| `backlog/_toc.md` | modified (regenerated) | BD-185 title row updated to the new title via the sanctioned helper; never hand-edited. |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C5a-FIX1.md` | new | This report. |

No other files written. No staging, no commit.

---

## Plan deviations
None. Single approved title edit + sanctioned toc regen + full-suite verification,
exactly as scoped.

## New POQs
None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| Title re-scoped to flat-file scope, accurate to body | PASS |
| Only title text after `BD-185 — ` changed (ID/em-dash/body untouched by this fix) | PASS |
| `_toc.md` regenerated via `per_entry_regenerate_toc` (not hand-edited) | PASS |
| TOC BD-185 row reflects new title | PASS |
| ID-extraction rule holds (text after em-dash; no pre-em-dash parenthetical; no letter suffix) | PASS |
| Check 33 toc in-sync | PASS (byte-identical) |
| Check 34 cross-refs resolve (ID-neutral) | PASS (3069 refs resolved) |
| Check 32′ no monolith | PASS |
| validate-pack general EXIT=0 | PASS |
| validate-pack DEEP (`PACK_VALIDATE_DEEP=1`) EXIT=0 | PASS |
| Full `tests` job — every wired script EXIT=0 | PASS (all 58 invocations) |
| No manifest/fixture delta; manifest restored to committed SHA | PASS |
| Out-of-scope untouched (only `backlog/` + this report) | PASS |
| No git state change (read-only git only) | PASS |

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only) | Final HEAD `cdfe87dd6a7a063d0a5c913265b7e230f144d3c8` == base HEAD; only `git rev-parse`/`status`/`diff` used; the one `git checkout -- <path>` CI step was DENIED by harness and replaced with a `cp` from a `/tmp` backup. `git status --short` shows only ` M backlog/BD-185.md`, ` M backlog/_toc.md` plus this new report. | COMPLIANT |
| 2 | Real fix (title accurate; body unchanged) | New title `**BD-185 — Phase-parts hierarchy + flat-file execution ordering**` matches body's `File/Symbol (flat-file half — this entry)` + retained `SC4 (flat-file leg)`; tracker legs `MOVED to BD-216`. `git diff backlog/BD-185.md` shows line-2 title is the only change I introduced atop the pre-existing C5a working tree. | COMPLIANT |
| 3 | Edit in place; re-confirm only title changed | Single `Edit` on line 2 + sanctioned toc regen. `git diff backlog/BD-185.md` line 2: `-…tracker-mode execution ordering**` / `+…flat-file execution ordering**` is the sole fix-introduced delta. | COMPLIANT |
| 4 | Integrity (Check 33 / 34 / 32′) | `OK: backlog/_toc.md byte-identical (22180 bytes)` (33); `OK: cross-reference integrity: 3069 reference(s) … all resolved` (34); `OK: backlog/ — no monolith present` (32′). | COMPLIANT |
| 5 | Verify FULL CI suite, no sampling | Both `validate` steps EXIT=0 (`PASSED — all checks clean`); all `tests` job invocations EXIT=0 (`===PART1_DONE fail=0===`, `===PART2_DONE fail=0===`). No test pins the BD-185 title string (Check 49 validates length generically; no test failed on the new title). | COMPLIANT |
| 6 | Manifest (backlog/ not v11-surface) | `git status --short | grep -i manifest` → empty (exit 1); `git status --short test-fixtures/` → empty; `shasum test-fixtures/manifest.txt` = `8337c164449d51bd46fc3224f22bbe56b179d3d3` (committed SHA). | COMPLIANT |
| 7 | Rules-Applied Verification Block present | This block. | COMPLIANT |
| 8 | PREFLIGHT + STOP-MEANS-STOP | Emitted: `PREFLIGHT: BD-185 title fix complete; _toc regenerated; FULL CI wired-test job verified locally; HEAD cdfe87dd6a7a063d0a5c913265b7e230f144d3c8; about to Write IMPL-REPORT to …IMPL-REPORT-BD-214-C5a-FIX1.md`. No parent stop message received. | COMPLIANT |
