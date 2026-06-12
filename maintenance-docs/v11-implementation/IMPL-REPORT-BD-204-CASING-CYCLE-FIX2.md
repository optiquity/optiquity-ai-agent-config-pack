# IMPL-REPORT — BD-204 casing+cycle batch, fix-coder pass 2 (FINAL)

- **Branch:** `v11-dev`; **HEAD:** `1c18b28c4d149d3e80565beafccc84f8d25b32f2`
  (unchanged — no git state changes made)
- **Date:** 2026-06-11
- **Coder:** fresh fix-coder (pass 2 of the bounded review/fix cycle)
- **Scope:** exactly the four user-approved findings from
  `PACK-REVIEW-BD-204-CASING-CYCLE-REVIEW2.md` (SHOULD-1 comment half,
  NIT-1, NIT-2, NIT-3). Comment/wording changes plus NIT-2's stderr
  surfacing; zero other behavior changes.
- **Files touched (both already in the batch footprint — no new
  modified files):**
  - `scripts/lib/tracker-migrate-forward.sh` (modified — SHOULD-1,
    NIT-2, NIT-3)
  - `scripts/tests/tracker-migrate-roundtrip-test.sh` (modified — NIT-1)

---

## 1. Per-finding before/after

### SHOULD-1 (comment half only) — pre-pass edge-vocabulary comment corrected to actual step-7 routing

**Anchor:** `scripts/lib/tracker-migrate-forward.sh`, the
`tmf_blockers_cycle_precheck` shell docstring ("Edge vocabulary"
paragraph) and the matching Python `edge_re` comment inside the same
function. The step-7 glob itself (`phase-[0-9][0-9]*.[0-9][0-9]*` in
the link loop) was NOT touched — that defect is anchored to a new BD
Pack Chat is opening (queued; see §4).

**Empirical re-verification before writing the comment** (the corrected
text states only what I measured):

```
$ for t in phase-3.2 phase-12.34 phase-9.9 phase-10.2 phase-3foo.4; do
    case "$t" in
      phase-[0-9][0-9]*.[0-9][0-9]*) echo "$t -> phase-task arm";;
      phase-[0-9]*)                  echo "$t -> parent arm";;
    esac; done
phase-3.2   -> parent arm
phase-12.34 -> phase-task arm
phase-9.9   -> parent arm
phase-10.2  -> parent arm
phase-3foo.4 -> parent arm
```

Note this is stricter than the reviewer's "matches only N≥10" phrasing:
the glob matches only when **both N and M** have two or more digits
(`phase-10.2` also falls to the parent arm). The comment states the
both-positions form.

**Before (docstring, 2 sentences of the paragraph):**

```
# Edge vocabulary: only tokens the step-7 link arms route to
# blocked-by edges participate — `BD-NNN`, `TD-NNN`, `phase-N.M`.
# Bare `phase-N` tokens are v10 sub-issue PARENT links (step 6) and do
# not participate in blocked-by cycle detection (same exclusion as the
# V3.3 §5.5 cycle checker). Step-7b phase-task `Dependencies` edges
...
```

**After:**

```
# Edge vocabulary: the participating tokens are those the step-7 link
# arms are DESIGNED to route to blocked-by edges (BD-108 F3) —
# `BD-NNN`, `TD-NNN`, `phase-N.M`. Bare `phase-N` tokens are v10
# sub-issue PARENT links (step 6) and do not participate in blocked-by
# cycle detection (same exclusion as the V3.3 §5.5 cycle checker).
# KNOWN GAP(functional): TD-TBD — step 7's actual phase-task glob
# (`phase-[0-9][0-9]*.[0-9][0-9]*`, the BD-108 F9 "tightening") only
# matches when BOTH N and M have two or more digits (`phase-12.34`
# matches; `phase-3.2` and `phase-10.2` fall to the `phase-[0-9]*`
# parent arm), so realistic single-digit `phase-N.M` blockers are
# misrouted to the sub-issue-parent path. Latent at v11.0
# (phase-tasks are never in the id-map per BD-108 §10.2, and both
# arms silent-skip absent targets); a dedicated backlog entry anchors
# the glob fix. Harmless for THIS pre-pass: `phase-N.M` tokens are
# pure sinks in the digraph (only BD/TD entries have outgoing edges),
# so they can never close a cycle, and the pre-pass matching a
# superset of actual step-7 routing cannot cause a false refusal.
# Step-7b phase-task `Dependencies` edges
...
```

**Before (`edge_re` comment):**

```
# Tokens that become blocked-by edges in step 7 (most-specific-first
# routing in the link loop): BD-NNN / TD-NNN / phase-N.M. Bare phase-N
# is a sub-issue parent link, not a blocked-by edge.
```

**After:**

```
# Tokens step 7 is DESIGNED to route to blocked-by edges (BD-108 F3;
# most-specific-first routing in the link loop): BD-NNN / TD-NNN /
# phase-N.M. Bare phase-N is a sub-issue parent link, not a blocked-by
# edge. NOTE: this regex accepts single-digit phase-N.M, which step
# 7's actual glob currently misroutes to the parent arm (see the
# KNOWN GAP note in the shell-side docstring above) — a harmless
# superset here, since phase-N.M tokens are sinks and cannot close a
# cycle.
```

**Typed-deferral compliance:** the defect note uses the typed
`KNOWN GAP(severity): TD-TBD — title` format per pack-repo
code-comment-deferrals (severity `functional` from the
`project-template/CLAUDE.md` § "Deferral comments and BACKLOG hygiene"
vocabulary; `TD-TBD` is mandatory there — "never a real TD number"). No
BD number is cited because the anchor BD is queued but unassigned at
write time (highest existing entry is `backlog/BD-213.md`; no glob-
defect entry exists yet — verified by grep over the newest entries).
**Pack Chat:** when the glob-defect BD is opened, optionally substitute
the real BD id for the `TD-TBD` placeholder in this comment (one-token
bookkeeping edit).

### NIT-1 — roundtrip seam comment no longer overstates the before-source constraint

**Anchor:** `scripts/tests/tracker-migrate-roundtrip-test.sh`, the
comment above the `TMF_STABILIZE_SLEEP_SECS=0` assignment.

**Before:**

```
# keep runs fast; must be set BEFORE the libs are sourced (the lib
# captures the value at source time via ${TMF_STABILIZE_SLEEP_SECS:-2}).
```

**After:**

```
# keep runs fast; set before the libs are sourced so the lib's
# source-time default-assignment (${TMF_STABILIZE_SLEEP_SECS:-2}) keeps
# the override — the variable stays mutable after sourcing (the poll
# reads it at call time), so this placement is convention, not a hard
# requirement.
```

**Behavior claim verified:** the only lib reads are
`sleep "$TMF_STABILIZE_SLEEP_SECS"` inside the stabilization poll loop
(read at call time, not captured), and the source-time line is a
default-assignment (`:-`), so post-source assignment would override
equally. Grep evidence:

```
$ grep -n "TMF_STABILIZE_SLEEP_SECS" scripts/lib/tracker-migrate-forward.sh
109:# Test seam: TMF_STABILIZE_MAX_ATTEMPTS / TMF_STABILIZE_SLEEP_SECS
116:TMF_STABILIZE_SLEEP_SECS="${TMF_STABILIZE_SLEEP_SECS:-2}"
2320:                sleep "$TMF_STABILIZE_SLEEP_SECS" 2>/dev/null || true
2342:            sleep "$TMF_STABILIZE_SLEEP_SECS" 2>/dev/null || true
```

(line numbers from the pre-edit grep; the two `sleep` sites are inside
the close-stabilization poll and shifted down by my insertions —
symbols, not line numbers, are the stable reference.)

### NIT-2 — step-6 parent-link arm now surfaces stderr like the three blocked-by arms

**Anchor:** `scripts/lib/tracker-migrate-forward.sh`, the
`phase-[0-9]*)` parent arm of the step-7 link loop case statement
(calls `provider_sub_issue_create`).

**Before:**

```bash
if provider_sub_issue_create "$parent_gh_id" \
    "{\"existing_id\": \"$gh_id\"}" >/dev/null 2>&1; then
    linked_parent=$((linked_parent + 1))
else
    printf 'step-6 sub_issue_create: %s -> %s\n' \
        "$pack_id" "$raw" >> "$partial_failures"
fi
```

**After:**

```bash
if provider_sub_issue_create "$parent_gh_id" \
    "{\"existing_id\": \"$gh_id\"}" >/dev/null 2>"$link_err"; then
    linked_parent=$((linked_parent + 1))
else
    # BD-204 C-8 defect 2 (review-2 NIT-2):
    # surface the typed MESSAGE instead of
    # swallowing it — mirrors the three
    # blocked-by arms.
    local parent_link_reason
    parent_link_reason=$(sed -n 's/^MESSAGE: //p' "$link_err" | head -n 1)
    printf 'step-6 sub_issue_create: %s -> %s%s\n' \
        "$pack_id" "$raw" "${parent_link_reason:+ — $parent_link_reason}" \
        >> "$partial_failures"
fi
```

This is byte-for-byte the same pattern as the three blocked-by arms
(capture stderr to the shared `$link_err` mktemp file — truncated per
redirect, created once before the loop, cleaned at the existing two
cleanup sites; fold the first `MESSAGE:` line into the partial-failure
entry via a `:+`-guarded suffix). Provider errors do carry typed
`MESSAGE:` lines (`tracker_provider_gh_sub_issue_create` emits via
`tracker_error_emit` → `tracker_error_format`, whose output shape is
`ERROR:`/`MESSAGE:`/context/`→ Run:` — verified in
`scripts/lib/tracker-errors.sh`).

**Partial-write accounting unchanged:** still exactly one
`partial_failures` line per failure and the same `linked_parent`
increment on success; the only delta is the optional ` — <reason>`
suffix. No new `return` paths were added between the `mktemp` and the
cleanup sites.

**Encoding-surface sweep for the changed line shape:**

```
$ grep -rn "step-6 sub_issue_create" scripts/ --include="*.sh" \
    | grep -v "lib/tracker-migrate-forward.sh"
scripts/tests/tracker-migrate-forward-test.sh:1886:# emit a "step-6 sub_issue_create: BD-501 -> phase-3.2" entry (which
scripts/tests/tracker-migrate-forward-test.sh:1894:# "step-6 sub_issue_create: BD-501 -> phase-3.2" to partial_failures
scripts/tests/tracker-migrate-forward-test.sh:1897:if [[ "$output_bd108" != *"step-6 sub_issue_create: BD-501 -> phase-3.2"* ]]; then
```

The single executable consumer is an ABSENCE substring assertion
(forward-test 6.2); a suffix-append can neither create nor destroy that
substring, so the assertion's meaning is preserved (and the suite ran
green — §2).

### NIT-3 — pre-pass refusal message is now provider-neutral

**Anchor:** `scripts/lib/tracker-migrate-forward.sh`, the `MESSAGE:`
printf in `tmf_blockers_cycle_precheck`'s rc=2 branch.

**Before:**

```
MESSAGE: forward: Blockers data contains dependency cycle(s) — refusing before any provider call. GitHub cannot represent a blocked-by cycle (its own addBlockedBy validation rejects it); fix the Blockers: lines of the entries named below and re-run.
```

**After:**

```
MESSAGE: forward: Blockers data contains dependency cycle(s) — refusing before any provider call. Cyclic Blockers data is a data error regardless of tracker backend; fix the Blockers: lines of the entries named below and re-run.
```

Self-review note: my first draft said "a blocked-by cycle cannot be
represented in the tracker backend" — that is the same class of
absolute backend-representability claim the finding flagged; revised to
the data-error framing, which is true for any backend. The function
docstring's GitHub/addBlockedBy sentence was deliberately left intact —
it is incident narrative about the live C-8 flip (which ran the gh
backend), not a claim about the runtime layer, and the finding anchored
only the refusal message.

**Encoding-surface sweep:** Group 8 assertions pin `ERROR: validation`,
`Blockers data contains dependency cycle` (substring, retained
verbatim as the message prefix), and the `cycle path: ...` lines —
none pin the reworded sentence
(`grep -rn "GitHub cannot represent\|addBlockedBy validation" scripts/tests/`
→ no matches; `grep -rn "refusing before any provider call" scripts/tests/`
→ no matches). Forward-test Group 8 ran green (§2).

---

## 2. Verification evidence (all FOREGROUND, this session)

- Syntax: `bash -n` on both edited files → OK / OK.
- `python3 scripts/validate-pack.py` → `PASSED — all checks clean`
  (rc=0); `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` →
  `PASSED — all checks clean` (rc=0).
- **Full CI battery:** all 54 `run: bash` commands extracted verbatim
  from `.github/workflows/validate-pack.yml`
  (`grep "run: bash" ... | sed 's/^ *run: //'` → 54 lines), run
  sequentially in the foreground in three chunks (1-18, 19-36, 37-54).
  **54/54 rc=0** (`grep -cv "rc=0" /tmp/bd204-fix2-results.txt` → `0`;
  results `/tmp/bd204-fix2-results.txt`, per-suite logs
  `/tmp/bd204-fix2-suite-N.log`). Includes check-40 (suite 19) on the
  REAL Mode-3 tree with root `tracker.toml` present, both fixture steps
  (47 `build.sh --all --clean`, 48 `--verify`), and
  `test-v11-realistic-ot.sh` (suite 49).
- Batch-affected suite counts (Passed/Failed): forward **199/0**,
  roundtrip **79/0**, reverse **150/0**, provider **162/0**, links
  **44/0**, cycle-check **28/0**, check-40 **FAIL: 0** — identical to
  the reviewer-pass-2 counts (the four fixes changed no assertion
  outcomes).
- Live oracle: `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
  default-SKIPs as designed (`SKIP: live-GH oracle (set
  PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0). **Zero live GitHub
  calls made by this fix pass.**

## 3. Plan deviations

None against the four-finding scope. One intra-finding refinement:
SHOULD-1's corrected comment states the glob matches only when BOTH N
and M have ≥2 digits (empirically verified), which is stricter than the
finding's "matches only N≥10" phrasing — the comment documents measured
behavior, per the finding's own intent ("correct the comment to the
actual behavior").

## 4. New POQs / items for Pack Chat

- **(carried from reviewer pass 2, not new)** The glob defect itself
  (`phase-[0-9][0-9]*.[0-9][0-9]*` misroutes single-digit `phase-N.M`)
  still needs its queued BD opened by Pack Chat (`deferred-work-
  tracked-anchor`). The code now carries the typed
  `KNOWN GAP(functional): TD-TBD` marker; substitute the assigned BD id
  for `TD-TBD` when the entry lands. Suggested BD content per the
  reviewer: fix the glob to match single-digit N/M (e.g. case-arm regex
  test) + a Group-6 assertion that can actually distinguish the
  phase-task arm from the parent arm (today both silent-skip absent
  targets — the pre-existing comment at forward-test assertion 6.2
  describes the arms' distinguishability inaccurately for the same
  reason; that test comment is BD-108-era, outside this pass's scope,
  and worth folding into the new BD).
- No other POQs.

## 5. Definition-of-Done checklist

| Item | Status |
|---|---|
| SHOULD-1 comment half corrected (docstring + `edge_re` comment), glob untouched | PASS |
| NIT-1 seam comment corrected | PASS |
| NIT-2 parent arm surfaces stderr, exact blocked-by-arm pattern, accounting unchanged | PASS |
| NIT-3 refusal message provider-neutral | PASS |
| No behavior change beyond NIT-2 surfacing | PASS (comment/wording only elsewhere; all suite counts unchanged) |
| Edited regions re-read after editing | PASS (all four regions re-read; quoted in §1 from re-read output) |
| Self-review: no line-number refs / absolute claims / symbol errors in edit text | PASS (symbols + § refs only; glob claim measured; revised my own NIT-3 absolute claim) |
| Full CI battery foreground green | PASS (54/54 rc=0 + validate-pack + DEEP) |
| Manifest byte-stable after rebuild | PASS (§ Rules table, row 7) |
| No live GitHub calls | PASS (oracle SKIP; battery uses fake-gh shims) |
| No git state changes; footprint unchanged + this report only | PASS (§ Rules table, rows 1/9) |

## 6. Files changed (this fix pass)

| Path | Change type | Findings |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified (already in batch footprint) | SHOULD-1 (2 comment blocks), NIT-2 (parent arm), NIT-3 (message) |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified (already in batch footprint) | NIT-1 (1 comment) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CASING-CYCLE-FIX2.md` | new (this report) | — |

Not touched: `tracker.toml`, `.pack-tracker/`,
`ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md`,
`PLAN-BD-204-MODE3-OPS-CONTRACT.md` (appeared from the concurrent
planner thread during this session — owned by others), anything under
`backlog/` / `changelog/`.

## 7. READ-IN-FULL attestation (rule 5)

| File | Read | Lines |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (incl. full `## Pack memory`) | FULL via Read tool | 579 |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CASING-CYCLE-REVIEW2.md` | FULL via Read tool | 282 |
| `~/.claude/.../memory/feedback_edit_in_place_not_full_rewrite.md` | FULL via Read tool | 15 |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | FULL via Read tool | 43 |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | FULL via Read tool | 15 |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (conditional MUST-READ triggered by the memory file) | section read (lines 200-235) | — |
| `project-template/CLAUDE.md` § "Deferral comments and BACKLOG hygiene" (typed-format vocabulary for SHOULD-1's KNOWN GAP marker) | section read (lines 290-334) | — |

## 8. Boundary discipline check

No project-side or pack-shipped-to-client surface was edited
(`scripts/lib/` and `scripts/tests/` are pack-side, not client-shipped
— confirmed by the byte-stable fixture manifest after rebuild). The
one project-side file consulted (`project-template/CLAUDE.md` deferral-
comment section) was READ-ONLY, used as the canonical typed-format SSOT
that the pack-repo convention explicitly defers to. No boundary stop.

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git verbs run this session: `git rev-parse HEAD`, `git status`, `git status --porcelain`, `git diff --stat`, `git diff` (manifest). Final `git status --porcelain`: same 12 `M` entries as session start; HEAD `1c18b28c4d...` unchanged. No add/commit/push/tag/stash/reset/restore/checkout invoked. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op anywhere: no `rm -rf`, no `git rm`, no file overwrite of trusted content (all repo changes were targeted Edit calls on the two in-scope files); scratch artifacts confined to `/tmp/bd204-fix2-*`. | COMPLIANT |
| preflight-stop-means-stop | Emitted verbatim before this Write: `PREFLIGHT: 4/4 fixes complete; verification PASS; HEAD 1c18b28c4d149d3e80565beafccc84f8d25b32f2; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CASING-CYCLE-FIX2.md`. No parent stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; per-rule quoted evidence; conditional MUST-READ honored (`pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block read before constructing — format template followed). No empty rows. | COMPLIANT |
| agents-read-rule-docs-in-full | §7 table: CLAUDE.md 579 lines, review report 282 lines, three memory files 15/43/15 lines — each read IN FULL via Read tool (line counts include the system-reminder offset convention: memory files report their numbered content lines as Read emitted them). | COMPLIANT |
| verify-full-ci-suite | §2: `validate-pack.py` + DEEP both `PASSED — all checks clean`; 54/54 workflow `run: bash` commands rc=0 FOREGROUND (`grep -cv "rc=0" /tmp/bd204-fix2-results.txt` → `0`), incl. real-tree check-40 (suite 19) and `test-v11-realistic-ot.sh` (suite 49); live oracle default-SKIP confirmed (`SKIP: live-GH oracle...`, rc=0). Counts: forward 199/0, roundtrip 79/0, reverse 150/0, provider 162/0, links 44/0, cycle-check 28/0, check-40 FAIL: 0. | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/` touched → `bash test-fixtures/build.sh --all --clean` rc=0 (battery suite 47) + `--verify` rc=0 (suite 48); then `git diff --stat test-fixtures/manifest.txt \| wc -l` → `0` and `git status --porcelain test-fixtures/` → empty. Manifest byte-stable (edited paths are not client-shipped); nothing to stage. | COMPLIANT |
| edit-in-place-not-full-rewrite | Five targeted Edit calls total (4 fixes + 1 self-review revision of my own NIT-3 wording); zero Write calls on existing files; every edited region re-read after editing (re-read output quoted in §1); `git diff --stat` confirms only the two in-scope files moved beyond the pre-existing batch deltas. | COMPLIANT |
| pack-only | End-state `git status --porcelain` (§6): identical 12-file modified set, untracked set = pre-existing artifacts + others' `PLAN-BD-204-MODE3-OPS-CONTRACT.md` + this report only. Nothing under `project-template/` or `supporting-docs/`; zero live GitHub calls. | COMPLIANT |
| scope-deliverables-to-the-ask | Exactly the four findings fixed (§1); the glob defect, the forward-test 6.2 comment inaccuracy, and the docstring's incident-narrative GitHub mention were identified and deliberately NOT touched (out of scope; first is BD-queued, second noted for that BD in §4, third not flagged by the finding). | COMPLIANT |
