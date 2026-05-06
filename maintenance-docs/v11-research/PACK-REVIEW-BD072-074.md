# PACK-REVIEW-BD072-074 — Batch 1 (D-19 inflection-point recommendation system)

Reviewed at HEAD `0d62429` against:
- ARCHITECTURE-V3.md §28.1 (primary; §28.1.1 — §28.1.10)
- ARCHITECTURE-V3.md §I.1, §I.2, §I.4 (artifact + trinity matrix)
- ARCHITECTURE-V3.md §D.1, §D.2 (worked examples)
- ARCHITECTURE-V2.md §22.1 (verb table)
- IMPLEMENTATION-PLAN.md §1.8 + §3.3
- ARCHITECTURE-V3.1/V3.2/V3.3-DELTA.md (no D-19 deltas; nothing to cross-check)

No prior PACK-REVIEW reports were consulted.

---

## Verdict

**GO-WITH-FIXES.**

## Test totals (confirmed at HEAD `0d62429`)

`bash scripts/tests/<name>.sh` across 12 suites (one suite per file under
`scripts/tests/`):

| Suite | PASS |
|---|---|
| recommendation-test.sh | 47 |
| template-translations-test.sh | 44 |
| template-version-test.sh | 36 |
| test-issue-forms.sh | 78 |
| tracker-agent-read-test.sh | 31 |
| tracker-config-test.sh | 32 |
| tracker-errors-test.sh | 60 |
| tracker-init-test.sh | 95 |
| tracker-migrate-forward-test.sh | 111 |
| tracker-migrate-reverse-test.sh | 93 |
| tracker-migrate-roundtrip-test.sh | 39 |
| tracker-provider-test.sh | 65 |
| **Total** | **731 PASS / 0 FAIL across 12 suites** |

`python3 scripts/validate-pack.py` → **rc=0** ("PASSED — all checks clean").

Matches the cumulative-review baseline. No regressions on the v11.0 surface
(BD-060…BD-071) attributable to Batch 1.

## Net assessment

Batch 1 lands the V3 §28.1 inflection-point recommendation system end-to-end:
the `recommendation.sh` library, the `enable-recommendations` verb body, and
Step 8 in both surfaces' startup skills. The library faithfully implements the
state-file v1 schema (§28.1.4), the 5-guard `should_recommend` test including
the 25%-growth Guard 4 (§28.1.5), the corrupted-state-file deferral contract
(§28.1.4 last bullet), and the persistent-refusal state mutators (§28.1.6).
The 7-test surface (§28.1.10) is mapped 1:1 in `recommendation-test.sh`. Step 8
is byte-identical across the three pack-side CLI variants and across the four
client-side variants (the canonical at `project-template/skills/pm-startup/`
plus three distributed copies), matching the §I.4 trinity-propagation rule.
BD-073 wires the verb into the dispatcher (§28.1.9) and into the V2 §22.1 verb
table.

Three issues warrant fixes before relying on the recommendation system in
production. (1) The client-surface signal computation looks for
`BACKLOG.md` at the repo root, but every client project per the trinity
`Document locations` table places `BACKLOG.md` under `docs/project/` — the
recommendation will never fire on a real client project because all signals
will compute to 0. (2) The V3 §28.1.7 "Also past threshold" follow-up line is
formatted with a stray colon-semicolon (`Also past threshold:; …`) instead of
the spec wording. (3) The headline signal label is the raw signal key
(`bd_count_active`) rather than the human label (`BACKLOG entries (active)`)
the spec invites and the §D.2 worked example uses. The first is a BLOCKER for
client-side BD-074; the other two are WARNINGs.

Extension-point soundness for BD-075/076/077 (D-20 help-verb system) is
preserved — the `pack help` reference is correctly named in the prompt body
(line 439 of `recommendation.sh`), the `enable-recommendations` verb is
discoverable via the dispatcher case at line 419 of `pack-tracker.sh`, and the
auto-surface helper used by the verb is the same one BD-075 will use for
HELP-FRAGMENT routing.

---

## Per-BD verification matrix

| BD | Status | Findings traced |
|---|---|---|
| BD-072 | YELLOW | F-1 (BLOCKER, client-side BACKLOG path), F-2 (WARNING, "Also past threshold" formatting), F-3 (WARNING, signal-name labels), F-7, F-8 (NIT) |
| BD-073 | GREEN  | (no findings traced; verb body matches V3 §28.1.6 + V3 §28.1.9; tests cover idempotency and missing-state-file path) |
| BD-074 | YELLOW | F-1 (BLOCKER on client surfaces inherited from BD-072), F-4 (WARNING, vacant Step 5–7 in pack-startup), F-5 (NIT, README Repository Layout drift), F-6 (NIT, validate-pack does not enforce per-CLI parity yet — Check 21 lands in BD-082) |

---

## V3 §28.1.10 7-test mapping to `scripts/tests/recommendation-test.sh`

| V3 §28.1.10 case | Implementing assertions in test file |
|---|---|
| 1. Threshold-cross fires once per material change | `Test-1a` (line 144) fresh-state fires; `Test-1b` (line 153) same signals same session no re-fire (Guard 4); `Test-1c` (line 158) 28% growth re-fires; `Test-1d` (line 163) 22% growth does not re-fire |
| 2. "Not now" silences for the session | `Test-2` (line 217) — verifies the contract that the lib does not mutate state on "not now"; in-session re-fire suppression is documented as caller responsibility (chat-side memory). The test does not directly exercise "subsequent operations same session — no re-fire", which is acceptable because that path is chat-loop, not lib-API |
| 3. "Don't ask again" persists | `Test-3a` (line 169) flag flipped; `Test-3b` (line 171) Guard 2 suppresses fire even on growth |
| 4. `enable-recommendations` clears | `Test-4a` (line 177–179) flag cleared + counter incremented; `Test-4b` (line 184) signals materially grown re-fire; group-5 verb integration tests `5.1`/`5.2`/`5.3` (lines 267–293) verify the dispatcher path |
| 5. Tracker mode disables recommendations | `Test-5` (line 188) Guard 1 suppresses |
| 6. Corrupted state file recovers | Group 2 lines 117–126 — corrupted JSON, recover with default + stamped `last_recommendation_shown_at` to defer this session per §28.1.4 |
| 7. Cross-machine refusal does not survive | `Test-7` (lines 195–200) — fresh state on "new machine" treats as un-refused; signals over threshold can fire there |

Coverage: 7/7 surface cases addressed. Test 2 has the smallest evidence
surface; the contract being verified is reasonable.

---

## Trinity-propagation check (V3 §I.4)

Pack-startup × 3 CLIs at pack-root (`/Users/david/Developer/optiquity-ai-agent-config-pack/`):

| File | Step 8 present | Body byte-equal to Claude variant |
|---|---|---|
| `.claude/skills/pack-startup/SKILL.md` | yes | (canonical) |
| `.codex/skills/pack-startup/SKILL.md`  | yes | yes — `diff` returns no output |
| `.gemini/commands/pack-startup.toml`   | yes (TOML wrapper) | yes — Step 8 body wrapped in `prompt = """ ... """` |

Pm-startup × 4 (canonical + 3 distributed) at `project-template/`:

| File | Step 8 present | Body byte-equal to canonical |
|---|---|---|
| `project-template/skills/pm-startup/SKILL.md` | yes | (canonical) |
| `project-template/.claude/skills/pm-startup/SKILL.md` | yes | yes — `diff` returns no output |
| `project-template/.codex/skills/pm-startup/SKILL.md`  | yes | yes — `diff` returns no output |
| `project-template/.gemini/commands/pm-startup.toml`   | yes (TOML wrapper) | yes — Step 8 body wrapped |

All 7 files contain the Step 8 block; per-CLI parity holds at byte level for
the SKILL.md variants and at body level for the TOML wrappers (TOML format
mandated by Gemini, per V3 §A.2 / §I.4).

---

## Findings

### F-1 — BLOCKER — client-surface BACKLOG.md is not located at the path the trinity table mandates

- File / symbol: `scripts/lib/recommendation.sh::_rec_compute_client_signals`
  (lines 145–170)
- Contract: `project-template/CLAUDE.md` "Document locations" table places
  `BACKLOG.md`, `STATUS.md`, `IMPLEMENTATION_PLAN.md` under
  `docs/project/`. V3 §D.2 worked example assumes this layout (the OT
  fixture has BACKLOG and IMPLEMENTATION_PLAN as project-tree files).
- Observation: line 147 hard-codes `local backlog="$repo_root/BACKLOG.md"`
  and only the plan path has a fallback (line 149:
  `[[ ! -f "$plan" ]] && plan="$repo_root/docs/project/IMPLEMENTATION_PLAN.md"`).
  `BACKLOG.md` has no equivalent fallback. On any real client project where
  the trinity table is honored (which is every project per V1 §8.4), the lib
  will compute `td_count_active=0`, `td_count_total=0`, and `backlog_kb=0`.
  Guard 3 (`should_recommend` line 326–339) will see no crossed signals.
  The recommendation will never fire on the client surface.
- The 7-test suite does not exercise this path because Group 1.2 (line 61)
  builds a synthetic `$TR_CLI/BACKLOG.md` at the fake-repo root.
- Required action: add a fallback parallel to the plan fallback, e.g.
  `[[ ! -f "$backlog" ]] && backlog="$repo_root/docs/project/BACKLOG.md"`,
  and add a test fixture that places BACKLOG under `docs/project/` to lock
  this in.

### F-2 — WARNING — "Also past threshold" follow-up line has stray punctuation

- File / symbol: `scripts/lib/recommendation.sh::recommendation_render_prompt`
  (lines 400–424)
- Contract: V3 §28.1.7 line 941–942 specifies the follow-up line shape:
  `(BACKLOG.md size: 52 KB also past 45 KB threshold.)`. The §D.2 worked
  example (lines 1968) renders it as: `(Also past threshold: BACKLOG.md size: 60 KB; phase count: 60.)`.
- Observation: The accumulator at line 401 / 409 builds `also` starting
  with `; ` (semicolon-space), and line 424 attempts to strip a leading
  `" ; "` (space-semicolon-space) via `${also# ; }`. The actual prefix is
  `; ` (no leading space), so the strip does not match and the rendered
  line becomes `Also past threshold:; <name> <value> (threshold ≥ <thr>);
  …`. Test 4.2 only matches the substring `"Also past threshold"`, so the
  cosmetic break is not caught.
- Required action: change line 424 to strip `;` (single char, no spaces),
  or rebuild the `also` accumulator to use `, ` separators consistent
  with the §D.2 example. Add a test that asserts the leading punctuation
  is well-formed.

### F-3 — WARNING — headline signal label uses the raw key, not the human label V3 §28.1.7 invites

- File / symbol: `scripts/lib/recommendation.sh::recommendation_render_prompt`
  (line 421)
- Contract: V3 §28.1.7 line 937–938: "The signal-name field is filled by
  the chat: e.g., `BACKLOG entries (active): 124`." The §D.2 worked
  example (line 1961) renders `IMPLEMENTATION_PLAN.md size: 210 KB`,
  not `implementation_plan_kb: 210`.
- Observation: The lib emits the raw JSON key (`bd_count_active`,
  `implementation_plan_kb`) verbatim in the headline. Test 4.1
  (line 231) asserts on `bd_count_active: 105`, locking in the raw-key
  rendering.
- Severity: WARNING because the spec says the chat fills the field
  loosely. However the §D.2 worked example is the documented prompt
  shape and the raw key is jarring user-facing UX.
- Required action: introduce a `_rec_signal_label` helper that maps key
  → human label per signal, or update §28.1.7 to formalize the raw-key
  rendering. Either lib change or arch-doc update is required to close
  the divergence.

### F-4 — WARNING — pack-startup has vacant Steps 5/6/7 with no current BD claiming them

- File / symbol: `.claude/skills/pack-startup/SKILL.md` and the two
  parallel files (line 43 jumps from Step 4 → Step 8 at line 61); pm-startup
  jumps Step 6 → Step 8 (gap at Step 7).
- Contract: V3 §28.1.9 says "extended … Step 8 (after V1's Step 7
  triage queue)". V1 §10.2 (ARCHITECTURE.md line 1610) defines a Step 7
  "Triage queue" addition for pack-startup in tracker mode. The
  ARCHITECTURE.md §10.2 Step 7 was never landed in the pre-v11 surface;
  pre-Batch-1 pack-startup ended at Step 4.
- Observation: BD-074 commit message says "Step numbering preserves the
  gap at Step 7 (V1 §10.2 tracker-mode triage queue, added by a later
  BD)". A grep across `BACKLOG.md` and `IMPLEMENTATION-PLAN.md` finds no
  v11 BD that fills Steps 5–7 in pack-startup. Grep against the V3
  worked examples (D.1, D.2) does not reference any other inserted
  steps. Once v11 ships, pack-startup will have Steps 1, 2, 3, 4, 8 with
  three vacant integers. This is a documentation-cleanliness issue, not
  a correctness issue.
- Required action: either (a) consolidate-renumber Step 8 to Step 5
  with a Step 8 rename pending the V1 §10.2 backfill BD landing, or (b)
  open a BD that explicitly claims Steps 5/6/7 and references it in the
  trinity matrix.

### F-5 — NIT — README Repository Layout does not list BD-074 / BD-072 surfaces

- File / symbol: `README.md` lines 85–174 ("Repository Layout"
  section).
- Contract: Pack `CLAUDE.md` says "See `README.md` — the Repository Layout
  section is the authoritative reference."
- Observation: The Repository Layout does not list:
  - `.codex/skills/pack-startup/` (new pack-root directory created by
    BD-074)
  - `.gemini/commands/pack-startup.toml` (new pack-root directory)
  - `scripts/lib/recommendation.sh` (the `lib/` row at line 170 only
    names `detect.sh`)
  - `scripts/tests/recommendation-test.sh`
  - `.pack-tracker/recommendation-state.json` (gitignored, but listed
    in V3 §I.1 as a v11 artifact)
  - `project-template/.codex/skills/pm-startup/`,
    `project-template/.gemini/commands/pm-startup.toml` (BD-074
    distributed copies)
- The README still captions `project-template/` as "Unified project
  template (v10)" at line 87.
- Severity: NIT because v11 is not yet released and a final README sweep
  is appropriate at v11 ship. Flagged for the v11 release sweep BD.

### F-6 — NIT — validate-pack.py has no per-CLI parity check for pack-startup / pm-startup files

- File / symbol: `scripts/validate-pack.py`
- Contract: V3 §I.4 line 2875: "validate-pack.py Check 21 (V3) verifies
  the per-CLI command-file parity."
- Observation: A grep for `pack-startup`, `pm-startup`, `pack-startup.toml`,
  `pm-startup.toml` against `scripts/validate-pack.py` returns zero
  matches. The new BD-074 files therefore have no CI gate enforcing
  per-CLI parity. Per the IMPLEMENTATION-PLAN, Check 21 lands in BD-082
  (still pending). Acceptable — flagged for completeness.
- Required action: covered by BD-082; ensure BD-082's Check 21 covers
  the BD-074 files.

### F-7 — NIT — `bd_count_total` is computed but never used by `should_recommend`

- File / symbol: `scripts/lib/recommendation.sh::_rec_compute_pack_signals`
  (line 134) and `_rec_compute_client_signals` (line 154).
- Contract: V3 §28.1.1 lists `bd_count_total` and `td_count_total` as
  tracked signals ("Includes resolved; informs the BACKLOG.md size
  picture"). V3 §28.1.2 does NOT define a threshold for either. V3
  §28.1.5 only iterates over thresholded signals.
- Observation: The lib emits both totals in JSON output (consistent
  with the spec listing them as tracked signals) but `_rec_signal_names`
  correctly excludes them from the iteration set. This is a correct
  reading of §28.1.1 + §28.1.2; flagging only because a reviewer might
  reasonably ask "why is this in the JSON if nothing reads it?" — it is
  in the JSON because the spec lists it as tracked.

### F-8 — NIT — Guard 4 dead-code in `_rec_threshold` lookup branch

- File / symbol: `scripts/lib/recommendation.sh::recommendation_should_recommend`
  (lines 358–367)
- Contract: V3 §28.1.5 Guard 4 pseudocode (lines 786–800).
- Observation: Line 358 fires when `last_v < thr`. Line 364 fires when
  `last_v > 0 && (now * 100) >= (last_v * 125)`. The `last_v > 0` check
  on line 364 is unreachable when line 358 returned (because `last_v=0
  < thr` for any positive `thr`). Cosmetic; harmless. Could be removed
  for clarity.

---

## Extension-point soundness for next-batch BDs (BD-075 / BD-076 / BD-077)

- BD-075 (`scripts/pack-help.sh`): the `recommendation_render_prompt`
  output references `pack help` at line 439. When `pack help` lands as a
  surface in BD-075, the prompt's call-to-action line will resolve.
  No coupling problem.
- BD-076 (HELP-FRAGMENT files): no overlap with Batch 1 surface.
- BD-077 (per-CLI `pack-help` command/skill, trinity-replicated × 2
  surfaces): the trinity-propagation matrix in V3 §I.4 lines 2860–2861
  is the contract BD-077 will follow. BD-074's compliance with §I.4 for
  pack-startup / pm-startup establishes the pattern BD-077 should mirror.
- The `tracker_config_auto_surface` helper used by BD-073's
  `cmd_enable_recommendations` is also the helper BD-075's
  surface-detection step needs (per IMPLEMENTATION-PLAN §1.9 BD-075
  description). No degradation.

---

## Closing line

GO-WITH-FIXES because BD-073 is clean, the BD-072 library faithfully
encodes V3 §28.1.4–§28.1.7, and BD-074 trinity propagation matches V3 §I.4
byte-for-byte. The blocking concern is F-1 (client-surface BACKLOG.md
path), which silently disables the recommendation system on the surface
that V3 §D.2 actually targets; without a fixture or BACKLOG-path fallback,
the client side of BD-074 will never fire in production. F-2 and F-3 are
production-quality polish on the prompt rendering. F-4 / F-5 / F-6 are
documentation hygiene that can ride along with the v11 ship sweep.
