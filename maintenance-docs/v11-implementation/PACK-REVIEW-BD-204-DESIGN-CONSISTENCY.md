# PACK-REVIEW-BD-204-DESIGN-CONSISTENCY

**Reviewer:** pack-reviewer (READ-ONLY). **Target:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` (finalized, 3× swept). **HEAD:** `e83aed7` (`git rev-parse HEAD → e83aed72a25b5c3033c901b1ff0727f4a5258bae`). **Branch:** `v11-dev`. **Date:** 2026-06-06.

---

## HEADLINE: **PASS (with 2 SHOULD + 2 NIT findings; zero BLOCKER, zero MUST)**

The design is internally consistent against all five resolved decision points, carries zero live-sidecar mechanism, preserves the no-monolith invariant, contradicts no resolved choice, and satisfies the HARD tier. All six item-6 empirical claims re-verify TRUE against the actual built code. The findings are non-blocking: line-citation drift in the `Deferred`-insert anchor (SHOULD), an unmentioned second switch statement that also needs the new branch (SHOULD), and a measurement-completeness gap in the Check-29 EE block (NIT). None alters the design's correctness; all are planner/coder-precision issues. Design is implementable and ready for the planner.

---

## 1. Decision-recording fidelity — **PASS**

| DP | Required user choice (2026-06-06) | Recorded as | Verdict |
|---|---|---|---|
| DP-1 | (A) read-only regenerated mirror; writes → tracker via full CRUD; tree never authoritative in Mode 3 | `:98-102` "RESOLVED … (A) read-only regenerated mirror. Writes go to the tracker via full CRUD"; (B) "considered & rejected"; §2.1 `:256` / §2.5 `:555-559` consistent | MATCH |
| DP-2 | carrier = form family + Issue BODY (+ in-body `pack-extra-fields`); sidecar FILE dropped for v11.0; GH-only extras dropped, future-deferrable | `:106-125` RESOLVED; §2.4.1 `:461-465`; §2.4.3 `:530-535` GH-only extras dropped + future-BD note | MATCH |
| DP-3 | 6-row matrix APPROVED incl. NEW `Deferred` (open + `status:deferred`); `Pending/In Progress/Done` dormant-valid, not pruned | `:172-178` "APPROVED — the 6-row matrix"; `Deferred` row `:145`; "not pruned" `:177`; "considered & rejected" pruning | MATCH |
| DP-4 | regenerate `_toc.md` on EVERY Mode-3 tree-materialization | `:198-201` "regenerate `_toc.md` on EVERY Mode-3 tree-materialization (every regen pass)" | MATCH |
| DP-5 | RETIRE header-snapshot for pack surface; `_intro.md` human-only, untouched by reverse | `:227-231` "RETIRE the header-snapshot … `_intro.md` stays human-only and is untouched by reverse" | MATCH |

**`USER DECISION NEEDED` count:** `grep -n "USER DECISION NEEDED" → 0 hits (exit 1)`. **ZERO unresolved decisions remain.** All five DPs RESOLVED with exactly the prescribed choices.

---

## 2. No-live-sidecar — **PASS**

`grep -n sidecar` → 40 hits, every one classified as DROP-statement / drop-rationale / considered-&-rejected / negation / historical-or-locked-spec reference. **ZERO live round-trip carriers.** Representative classification:

- DROP statements: `:24,110-111,115,420-423,461-465,492,539,751-752` ("FILE is DROPPED", "Nothing rides a sidecar", "No sidecar file participates").
- Drop rationale: `:117-121,467-474` (flat-file has no comments/logs; GH-specific format non-portable).
- Considered-&-rejected / historical: `:18,22` (prior attempt's base64/sidecar reinvention), `:465` ("replaces the earlier 'retain the sidecar' position, which is withdrawn").
- Code-implication FLAG: `:869-878` (`tracker-sidecar.sh` unused on pack surface; remove-vs-dormant to planner/coder) — a negation of any live use.

The live carrier everywhere is "form family + Issue body / in-body `pack-extra-fields`" (§2.4 `:417-457`, §2.4.1 `:476-492`, §2.11 `:681-682`, §2.12 `:704-705`). No surviving live-sidecar mechanism.

---

## 3. No-monolith invariant — **PASS**

The 7-site retire/repoint table (§2.2 `:311-320`) is internally coherent: C1a/C2b/C7c RETIRE (pack), C1b REPOINT (Check 29′), C2a/C3/C4/C7b REPOINT to the tree. Re-verified against code:

- **Check 32′** (`validate-pack.py:3178+`) asserts the monolith file is ABSENT and FAILs if present — confirmed at `:3185-3187`. C2b (forward SKIPs Step-10 mirror regen) + C3 (reverse emits tree, not monolith) guarantee no monolith is ever written ⇒ Check 32′ stays green through forward + reverse + regen. Coherent.
- No design site reads or writes a monolith on the pack surface post-recipe; the EXAMPLE files retain `[mirror]` for the client surface (BD-207) — correctly scoped out, not a pack-side violation.

The design's "projected post-design state" claim (`:370-372`, Check 32′/29′/33 green) is consistent with the measured guard behavior.

---

## 4. No section contradicts a resolved choice — **PASS**

Swept §2.1/§2.4/§2.4.1/§2.5/§2.6/§2.10/§2.11/§2.12/§3/§4/§5 against the 5 resolved choices. No contradiction found:

- No section treats the tree as editable/authoritative in Mode 3 — §2.1 `:256` ("read-only regenerated mirror"), §2.5 `:555-559`, §3.1 `:711-727` all hold DP-1(A).
- No section references the sidecar as the Target/Position home — `Target:`/`Position:` route to the in-body `pack-extra-fields` block everywhere (§2.4 `:444-445`, §2.4.1 `:476-485`, §3.1 `:724-725`).
- §2.6 reverse-decoder language (`:565-568`) consistent with DP-3's `Deferred` row.
- §2.10 capability matrix (`:666-668`) consistent with DP-2 (carrier = form body + `pack-extra-fields`, NOT custom Issue Fields, NOT sidecar).
- §5 mini-block + main Rules-Applied table consistent with all five DPs.

---

## 5. HARD constraints (`backlog/BD-204.md:14`) — **PASS**

| HARD constraint | Satisfied by | Verdict |
|---|---|---|
| pack-only (no project-side edit) | §2.2 KEEPs the `tracker.toml.project-example` `[mirror]` table (`:337`); §2.6/DP-3 does NOT prune the shared form (`:169-170`); §4.2 edits only `surface=="pack"` branch (`:857`) | SATISFIED — no design step requires a `project-template/` edit |
| lossless reversibility (repeated on/off + interleaved CRUD) | §2.11 `:676-684`, §2.12 `:702-706`, §3.2 repeated-cycle + interleaved-CRUD oracle `:754-757` | SATISFIED |
| tracker-AGNOSTIC (provider_* only) | §4.1 `:810-832` — all GH logic behind `provider_*`; `Deferred`/lane/CRUD/identity use cross-tracker floors | SATISFIED |
| GA + personal-account ONLY | §2.10 `:657-672` — Issue Fields/Types EXCLUDED (org-only/preview) | SATISFIED |
| full-CRUD true-SSOT | §2.3 `:388-406` — wires `provider_update`; "delete = close-with-reason" | SATISFIED |
| issue-number independence | §2.7 `:589-593` — identity keyed on `pack-id` marker, never issue number | SATISFIED |
| surface/tree-generalizable | §4.2 `:843-851` — stream-key parameterized; client = BD-207 (untouched) | SATISFIED |

Surface-generalizable seam noted (§4.2); client branch correctly left to BD-207, not touched.

---

## 6. Item-6 re-verification (re-run against ACTUAL built code, NOT the doc's blocks)

| # | Claim in design | Re-run result (HEAD `e83aed7`) | Verdict |
|---|---|---|---|
| 6a | reverse decoder has NO `Deferred` branch (`_tmr_decode_status`) | `sed -n '188,249p' tracker-migrate-reverse.sh`: legacy labels branch `:200-208` (open/unblocked/resolved/cancelled/deprecated, no Deferred); closed branch `:222-242` (completed/not_planned, no Deferred); open branch `:244-248` (`status:unblocked`→Unblocked, else Open). `grep -ni deferred` → only `:34` (unrelated audit-log comment). **NO `Deferred` branch in either switch.** | MATCHES |
| 6b | `provider_update` exists but unwired for forward/BD migration | `tracker-provider.sh:129 provider_update()`; `grep -rn provider_update scripts/lib/` → called ONLY at `tracker-promote.sh:801,1215` (project-side TD-promotion). `tracker-migrate-forward.sh` calls `provider_create`/`provider_close`, never `provider_update`. | MATCHES |
| 6c | Check 29 requires `[mirror]` + fails on missing mirror file; Check 29′ soft-passes no-mirror without admitting claimed-but-missing | `validate-pack.py:2628 mirror = _require("mirror", dict)` + required-keys `:2630-2643`; staleness `:2756 "does not exist on disk"` fail. Schema leg requires `[mirror]`; staleness leg fails on missing file. Design's Check 29′ guard (`:343`) soft-passes (a) flat-file, (b) tracker-no-mirror, keeps failing (c) claims-mirror-but-missing — allowlist sized to KEEP only. | MATCHES (see Finding F3 NIT on EE-block completeness) |
| 6d | in-body markers exist in `work-item.yml` so `pack-extra-fields` sibling block is consistent | `work-item.yml:103-105` → `<!-- pack-id: PENDING -->`, `<!-- template_version: work-item-v11.0 -->`, `<!-- pack-version: v11 -->`. `pack-extra-fields` not yet present anywhere (`grep -rn pack-extra-fields .github/ scripts/` → 0 hits) — correctly described as NEW, consistent with the locked sibling trio. | MATCHES |
| 6e | status distribution sums to entry count | `grep -rh '^Status:' backlog/*.md \| sort \| uniq -c`: 168 Resolved, 28 Open, 11 Deferred, 3 Deprecated, 1 Unblocked, 1 Cancelled. Entry-file count = 212. `28+1+11+168+3+1 = 212`. | MATCHES |

**All six item-6 claims independently re-verified TRUE.** The DP-3 gap (11 Deferred entries, no decoder branch) is real in code and the fix closes it.

---

## 7. Severity-ranked findings

### BLOCKER — none
### MUST — none

### SHOULD-1 — `Deferred`-insert anchor cites the wrong line region (implementability)
DP-3 (`:158`) and §2.6 (`:568`) instruct the implementer to add the `status:deferred → Deferred` case at "the `tracker-migrate-reverse.sh:213-219` region" / "the open-state region of `_tmr_decode_status`." But `:213-219` is the canonical-object SETUP block (state/state_reason/label extraction), NOT a switch. The actual open-state `case` is at `:244-248`. The EE block at §2.6 `:573` correctly cites `:203-208,218-219` for the existing maps, but the prose insert-anchor (`:213-219`) misdirects. The intent ("parallel to the existing `status:unblocked` case") is recoverable, but the cited anchor is wrong. *Per pack memory, line numbers drift — but here the cited line is wrong at this very HEAD, not drifted.* Recommend the planner re-anchor by symbol (`_tmr_decode_status` open-state `case "$label"` block) not line.

### SHOULD-2 — second switch statement (legacy labels-only branch) also needs the `Deferred` case, unmentioned
`_tmr_decode_status` has TWO switch statements that map status labels: the legacy labels-only branch (`:200-208`, used by "existing labels-only test fixtures Group 1") AND the new canonical-object open branch (`:244-248`). BOTH currently map `status:unblocked` and BOTH lack a `Deferred` case. The design names only ONE insert site (the open-state branch). If the lossless audit ever exercises the legacy labels-array path for a deferred entry, it would decode to `Open` (the legacy default `:206`). The planner/coder should confirm whether the legacy branch is in-scope for the round-trip; if so, the `Deferred` case must be added in both switches. *Surfaced, not redesigned.*

### NIT-3 — Check-29 EE block understates the current missing-`[mirror]` failure mode
The §2.2.C1 EE block (`:326-332`) cites the staleness fail as the `is_file()` leg (`:2755-2758`). But the actual built `_check_mirror_staleness` hard-FAILs EARLIER at `:2740-2744` (`"[mirror] table missing/malformed; cannot check mirror-staleness"`) when `mode='tracker'` + `forward_complete=true` and the `[mirror]` table is absent — which is exactly the branch the no-mirror pack config hits. The design's fix-recipe (`:343`, add a top-of-function no-`[mirror]` soft-pass guard) is still correct in direction and the conclusion (no-mirror config FAILs Check 29 today) holds — but the EE block measured the wrong fail-line, so the planner should target the `:2740-2744` branch (not only the `is_file` leg) when implementing Check 29′. Measurement-completeness gap, not a design contradiction.

### NIT-4 — minor line-citation drift on the sidecar call site
§4.3 (`:871`) cites the reverse sidecar call at `:1126-1128`; the actual `tracker_sidecar_emit` call is at `:1128` (a 2-line drift, within the cited range). The header-snapshot call (`:1109`, C7c) is an exact match. Cosmetic; flagged for completeness only.

---

## Rules-Applied Verification Block

| Rule (prompt "Rules in force") | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **Empirical evidence (file:line / grep, HEAD `e83aed7`)** | Every §1-§7 result + all six item-6 rows cite re-run output: `grep "USER DECISION NEEDED" → 0`; `grep sidecar → 40 hits classified`; `_tmr_decode_status` `:188-249` quoted; `provider_update` only `tracker-promote.sh:801,1215`; `validate-pack.py:2628,2740-2744,2756`; `work-item.yml:103-105`; status `168+28+11+3+1+1=212`. All at HEAD `e83aed72a25b...`. | COMPLIANT |
| **Scope deliverables — no noise** | Report = PASS/FAIL + decision-fidelity + no-sidecar/no-monolith/contradiction/HARD + item-6 table + severity-ranked findings + this block. No redesign, no edge-case sprawl. | COMPLIANT |
| **Pattern-matching antipattern** | Each §4 contradiction-sweep item judged by actual section content (quoted line), not thematic resemblance; the two SHOULD findings rest on the literal switch-statement structure at `:200-208`/`:244-248`, not on theme. | COMPLIANT |
| **Pack/project separation** | Confirmed §5: no design step requires a `project-template/` edit (project-example `[mirror]` KEPT `:337`; shared form NOT pruned `:169-170`; only `surface=="pack"` branch edited `:857`). Surface-generalizable seam noted; client branch = BD-207, untouched. | COMPLIANT |
| **Enumerate ENCODING surfaces** | Verified the design names, for Check 29′/32′, the validator + tests + example-config in lock-step: §2.2 `:350-355` (validator fn + `test-*tracker*`/`test-validate-pack*` + `tracker.toml.pack-example` schema + CI workflow). Lock-step enumeration present. | COMPLIANT |
| **Surface, don't fix (read-only)** | No source file edited; the sole write is this ONE report at the prompted path. Findings surfaced, none redesigned. | COMPLIANT |
| **Rules-Applied Verification Block** | This table + the READ-IN-FULL attestation below; every row carries quoted evidence (none empty). | COMPLIANT |

### READ-IN-FULL attestation (this session)

| # | File | Direct-read proof |
|---|---|---|
| 1 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` | Read full (1-601 + 602-928) — all 5 DPs, 12 design areas, §3-§5. |
| 2 | `backlog/BD-204.md` | Read full (1-26) — HARD tier `:14`, reversibility, SSOT/mirror, generalizable, scope/out-of-scope. |
| 3 | `CLAUDE.md` `## Pack memory` | Read in full (session context) — empirical-evidence, ci-guard-measure-then-bound, pattern-matching, pack/project separation, enumerate-encoding-surfaces, scope-deliverables. |
| 4 | `scripts/lib/tracker-migrate-reverse.sh` | Read directly (`sed 188-270`, grep deferred/sidecar/header-snapshot) — `_tmr_decode_status` both switches, call sites `:1109,:1128`. |
| 5 | `scripts/lib/tracker-migrate-forward.sh` | grep `provider_*` — create/close wired, update unwired. |
| 6 | `scripts/lib/tracker-provider.sh` / `tracker-promote.sh` | grep `provider_update` — `:129` def; called only `tracker-promote.sh:801,1215`. |
| 7 | `scripts/validate-pack.py` | Read directly (`2624-2645`, `2699-2760`, `3178-3190`) — Check 29 `[mirror]` require + staleness fail branches; Check 32′ no-monolith. |
| 8 | `.github/ISSUE_TEMPLATE/work-item.yml` | Read directly (`100-106`, grep markers) — `pack-id`/`template_version`/`pack-version` `:103-105`; `pack-extra-fields` absent. |
| 9 | `backlog/*.md` | grep `^Status:` distribution + entry-file count = 212. |
| 10 | `scripts/lib/tracker-sidecar.sh` | `ls` — exists (14598 bytes), flagged unused-on-pack by design. |

**No named document was derived rather than read.** Every file above was opened directly via Read/Bash this session at HEAD `e83aed7`.

**End of PACK-REVIEW-BD-204-DESIGN-CONSISTENCY.md**
