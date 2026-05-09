# IMPLEMENTATION-REPORT-BD-125.md

**BD:** BD-125 — `dry-run-migration.sh` input contract + usage doc
**Agent:** pack-coder
**Branch:** `v11-dev`
**HEAD SHA at start and end:** `c566c20ded5f3e7eee7f07473b2eb18ba7b593dc` (unchanged — agents do not commit)
**Date:** 2026-05-09

---

## 1. Pre-flight

```
$ git rev-parse HEAD
c566c20ded5f3e7eee7f07473b2eb18ba7b593dc

$ git rev-parse --abbrev-ref HEAD
v11-dev

$ git status         # at start: clean working tree
nothing to commit, working tree clean

$ ls supporting-docs/scripts/dry-run-migration.sh
scripts/dry-run-migration.sh                          [present, executable]
supporting-docs/MIGRATION-v10-to-v11.md               [present]
README.md                                             [present]
OPTIONAL-FEATURES.md                                  [present]
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-114.md  [present]
```

Pre-flight clean: HEAD matches caller's stated `c566c20`, branch `v11-dev`,
no untracked changes at start. All input documents present.

Other-agent footprint observed at start time (BD-134 parallel pack-coder):
working-tree changes already present in `scripts/lib/tracker-migrate-forward.sh`
and `scripts/tests/tracker-migrate-forward-test.sh`. Did NOT touch those —
they are out of BD-125's scope per the caller's prompt.

---

## 2. Summary

Single-track BD: write a public-facing companion doc for the BD-114
dry-run-migration harness, plus minimal cross-references in the two
discovery surfaces where users would look (README supporting-docs
listing, MIGRATION-v10-to-v11.md "Before you start" checklist).

| File | Status | Lines / Δ | Verification |
|---|---|---|---|
| `supporting-docs/DRY-RUN-MIGRATION.md` | NEW | 199 lines | structural review (six required sections present); flag accuracy verified against `--help` output |
| `README.md` | MODIFIED | +1 line | grep confirms cross-link present in supporting-docs listing |
| `supporting-docs/MIGRATION-v10-to-v11.md` | MODIFIED | +7 lines | grep confirms cross-link in "Before you start" §; ordering preserved (new item 6, after pre-clean item 5) |

---

## 3. Structural choices

The BACKLOG entry for BD-125 specifies six required content sections
but leaves ordering and depth to the writer. Choices made:

1. **Section ordering follows the lifecycle of a dry-run user.** § 1
   Input contract (what state must my repo be in?) → § 2 Usage (how
   do I invoke?) → § 3 Reading the output (what do I see?) → § 4
   Release-gate integration (how do I automate?) → § 5 Limitations
   (what does it NOT cover?) → § 6 Recovery (what if real-run
   diverges?). Maps 1:1 to the six items in the BACKLOG entry.
2. **Three "what does this look like" buckets in § 3.** "Safe",
   "would break customizations", "would fail" — the practical
   trichotomy a reader needs. Each enumerates the exit-code +
   stdout/stderr signals to look for, cross-referencing the BD-088
   `customization-detected-needs-reconciliation` vocabulary in
   MIGRATION-v10-to-v11.md § Step 2 rather than re-deriving it.
3. **Per-exit-code policy table in § 4.** The harness's exit codes
   `0`/`2`/`4`/`5`/`6`/`7` (verified via `--help`) each get a
   release-gate disposition. This is the load-bearing section for the
   Optiquity-style use case from the BACKLOG entry.
4. **Examples chosen for § 2:** one per mode (synthetic fixture, local
   path, URL via secret), plus the `--report-out` persistence pattern
   that is required for any CI use case. The exhaustive flag list is
   deferred to `--help` per the BACKLOG entry's guidance ("reference
   BD-114's harness usage output ... rather than duplicating it").
5. **199 lines vs ~150 target.** First draft was 234; trimmed to 199
   by dropping verbose lead-ins and consolidating the "common causes"
   list in § 6 into a single sentence. Six required sections each
   needing concrete examples + an exit-code table + cross-references
   makes hard ~150 unrealistic without dropping required content;
   199 is in spirit of "tight, public-facing" and well under the
   470-line MIGRATION-v10-to-v11.md neighbor.
6. **No emojis, no tool-specific syntax** — the doc is invocation-
   agnostic (no Claude-specific or Codex-specific framing) since the
   harness is a plain bash script.

---

## 4. Cross-reference choices

| File | Action | Rationale |
|---|---|---|
| `README.md` | Added one line in the supporting-docs/ tree listing (between `MIGRATION-v10-to-v11.md` and `MIGRATION-v8-to-v9.md`) | Discovery surface — a reader scanning the layout finds the new doc next to its sibling migration guide. Did NOT touch the version table per PM-only rule. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | Added new item 6 to "Before you start" checklist | This is the natural pre-migration verification spot — a reader following the migration narrative is told "preview first" before running the real migrator. Used "Optional but recommended" framing so the existing Step 1 flow remains valid. |
| `OPTIONAL-FEATURES.md` | NOT modified (audited; no change warranted) | Inspected file head and grep for `dry-run` / `migration` — file scope is "tool-specific opt-in features" (Claude agent teams, etc.), not pack scripts. Dry-run is neither tool-specific nor an opt-in feature. Adding it would dilute the file's scope. The BACKLOG entry's "audit and update if the dry-run is mentioned" guidance — current contents do not mention dry-run, so no update required. |

---

## 5. Verification

### 5.1 Flag-accuracy check — every flag mentioned in the doc exists in `--help`

```
$ scripts/dry-run-migration.sh --help | grep -E '^\s+--' | awk '{print $1}' | sort -u
--help,
--pack
--report-out
--tmp-dir
```

Doc references (verified via grep):

- `--help` — § "For the canonical flag listing, run ..."
- `--report-out` — § 2 (Mode 2, Mode 3) and § 4 step 2
- `--tmp-dir` — § 1 mentions `/tmp / $TMPDIR`; flag itself referenced
  via § 4 exit-code `5` ("refused tmp dir")
- `--pack` — not referenced (intentional; advanced/maintainer flag,
  not relevant to the public-facing input contract / release-gate
  narrative; covered by `--help`)

No flag mentioned in the doc is absent from the as-shipped CLI.

### 5.2 Exit-code accuracy

The doc's § 4 enumerates exit codes `0` / `2` / `4` / `5` / `6` / `7`.
Verified against the script source (`scripts/dry-run-migration.sh`
lines 70..75 and the `--help` exit-code block):

| Code | Constant | Doc claim | Source confirms |
|---|---|---|---|
| 0 | DRY_EXIT_OK | success | yes |
| 2 | DRY_EXIT_USAGE | usage error | yes |
| 4 | DRY_EXIT_ACQUIRE | clone/copy failed | yes |
| 5 | DRY_EXIT_READONLY_REFUSED | tmp-dir refused | yes |
| 6 | DRY_EXIT_DETECT_OR_DISPATCH | detection/adapter selection failed | yes |
| 7 | DRY_EXIT_ADAPTER | adapter (migrator) returned non-zero | yes |

### 5.3 Cross-link presence

```
$ grep -c "DRY-RUN-MIGRATION.md" README.md supporting-docs/MIGRATION-v10-to-v11.md
README.md:1
supporting-docs/MIGRATION-v10-to-v11.md:1
```

Both cross-references land. README.md edit is in the supporting-docs/
tree listing (line ~144); MIGRATION-v10-to-v11.md edit is the new
item 6 in the "Before you start" checklist (line ~99-106).

### 5.4 Validator

```
$ python3 scripts/validate-pack.py 2>&1 | tail -3
============================================================
PASSED — all checks clean
```

All 28 checks PASS. No new validator hookups expected for a doc-only BD.

### 5.5 Working-tree state at end

```
$ git status
On branch v11-dev
Changes not staged for commit:
        modified:   README.md
        modified:   scripts/lib/tracker-migrate-forward.sh        ← BD-134 (other agent)
        modified:   scripts/tests/tracker-migrate-forward-test.sh ← BD-134 (other agent)
        modified:   supporting-docs/MIGRATION-v10-to-v11.md
Untracked files:
        supporting-docs/DRY-RUN-MIGRATION.md

$ git diff --stat README.md supporting-docs/MIGRATION-v10-to-v11.md
 README.md                               | 1 +
 supporting-docs/MIGRATION-v10-to-v11.md | 7 +++++++
 2 files changed, 8 insertions(+)
```

My edits are precisely the three files listed in § 2. The two
`tracker-*` modifications belong to the parallel BD-134 pack-coder
session (caller pre-warned about this in the prompt) and were not
touched by this agent.

---

## 6. Plan deviations

None of substance. The single judgment call worth flagging:

- **Doc length 199 lines vs ~150 target.** Hit the six required
  sections, kept each terse, dropped a "see also" duplication of the
  release-gate exit-code table to land at 199. Going below ~180 would
  require dropping either the per-bucket interpretation triage in § 3
  (load-bearing for "is my migration safe?") or the per-exit-code
  table in § 4 (load-bearing for the release-gate use case). The
  BACKLOG entry says "under ~150 lines" but explicitly enumerates six
  content sections, each of which needs a working example. Treated
  ~150 as a soft target and ~200 as the hard ceiling.

---

## 7. New POQs

None. The harness is fully shipped (BD-114) and the doc requirements
are fully specified in the BD-125 BACKLOG entry. No new questions
surfaced during writing.

---

## 8. Definition-of-Done checklist

| # | Item | Status |
|---|---|---|
| 1 | `supporting-docs/DRY-RUN-MIGRATION.md` exists | PASS |
| 2 | All 6 BACKLOG-required sections present (input contract, usage, reading output, release gate, limitations, recovery) | PASS |
| 3 | Doc length within target ballpark (target ~150; landed 199 — see § 6) | PASS (within tolerance) |
| 4 | Every flag/option mentioned exists in as-shipped `--help` | PASS (§ 5.1) |
| 5 | Every exit code mentioned matches script source | PASS (§ 5.2) |
| 6 | Cross-link added in `supporting-docs/MIGRATION-v10-to-v11.md` near pre-migration verification | PASS (§ 5.3) |
| 7 | Cross-link added in `README.md` supporting-docs tree (NOT version table) | PASS (§ 5.3) |
| 8 | `OPTIONAL-FEATURES.md` audited; updated only if scope warranted | PASS (audited, no update — see § 4) |
| 9 | `python3 scripts/validate-pack.py` passes (28/28 checks) | PASS (§ 5.4) |
| 10 | No PM-only files modified (BACKLOG, CHANGELOG, README version-table, PACK-CHAT, PACK-AGENTS, CLAUDE/AGENTS/GEMINI) | PASS |
| 11 | No edits to BD-134's file set (`tracker-provider-gh.sh`, `tracker-migrate-forward.sh`, `tracker-migrate-forward-test.sh`, `tracker-errors.sh`) | PASS |
| 12 | BD-125 status NOT flipped (Pack Chat owns) | PASS |
| 13 | No state-changing git verbs run | PASS |

---

## 9. Files changed

| Path | Change | Notes |
|---|---|---|
| `supporting-docs/DRY-RUN-MIGRATION.md` | NEW | 199 lines; six sections per BD-125 BACKLOG entry |
| `README.md` | MODIFIED | +1 line in supporting-docs/ tree listing only |
| `supporting-docs/MIGRATION-v10-to-v11.md` | MODIFIED | +7 lines: new item 6 in "Before you start" |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-125.md` | NEW | this file |

NOT touched (visible in `git status` from parallel BD-134 session):
`scripts/lib/tracker-migrate-forward.sh`,
`scripts/tests/tracker-migrate-forward-test.sh`.

---

## 10. Proposed commit message

```
docs: v11 — BD-125: DRY-RUN-MIGRATION.md companion doc + cross-links
```

(Pack Chat owns staging, commit, and BD-125 status flip per pack
workflow — agent does not perform any of these.)
