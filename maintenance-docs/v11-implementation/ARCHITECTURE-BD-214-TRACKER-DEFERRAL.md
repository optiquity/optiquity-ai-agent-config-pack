# ARCHITECTURE — BD-214 Tracker-Deferral Cleanup + Restarted Track-2 Re-baseline (unified design)

**Author:** pack-architect (fresh spawn). **Date:** 2026-06-12.
**HEAD:** `0027b106789e09bad2d7cdb380c8c499d7d0f747` (branch `v11-dev`) + working-tree
dated note on `backlog/BD-214.md` + untracked census report. **Read-only except this file.**
**Primary inputs:** `RESEARCH-TRACKER-DEFERRAL-CENSUS.md` (BD-214 census),
`RESEARCH-REBASELINE-INVENTORY.md` (Track-2, 41 entries, HEAD 1c18b28 — freshness re-verified §1),
`RESEARCH-BD-212-GH-ISSUE-DELETION.md` (deletion rules), the 2026-06-12 user decision record.

## Update log (2026-06-13) — nine user decisions + BD-185 split + `_order.md` finding + Track A/B carve-out

This is a TARGETED in-place update absorbing decisions that POST-DATE the original
2026-06-12 design. The original design body is preserved; only the sections named
below changed. **Nothing outside this doc was edited.**

What changed and why:
- **US-1..US-9 RESOLVED.** §11's user-decision queue is annotated with the fixed
  2026-06-12/13 user rulings (held 213-issue + 49-label deletion = BD-214 FINAL
  step on explicit GO, §11/US-1+US-8; `changelog/v11.md` reword applied by a coder
  at C3 with literal old→new text supplied here, US-2; Blockers-cycle check
  re-anchored to BD-215, US-3; BD-185 split + BD-216, US-4; BD-188/212/213
  deferred-no-version cluster, US-5; BD-206 v11.0 + monolith-delete + `_order.md`
  create/reconcile, US-6; BD-102/174 Deprecate, BD-100→BD-205 merge, BD-198
  Resolve, US-7; 93-doc deletion at C5, US-9).
- **BD-185 SPLIT (US-4).** BD-185 RE-SCOPED flat-file-only, STAYS v11.0 + in the
  launch gate; NEW **BD-216** (next integer, confirmed by reading the tree —
  highest existing is BD-215) carries the tracker legs DEFERRED no-version. Hard
  constraint added: BD-185's phase-parts design MUST be DETERMINISTICALLY
  SERIALIZABLE (one canonical machine-parseable serialization; no free-prose
  ambiguity) so BD-215 can round-trip phase-parts. BD-185 → blocks → BD-215 wired.
- **`_order.md` FINDING (US-6).** The flat-file execution-ordering support-file
  `_order.md` is PREDESIGNED but UNBUILT (zero `_order.md` files exist in the
  tree). BD-206 must CREATE it for the project implementation-plan stream (phase
  order is not numerically recoverable, unlike `/backlog/`); if the predesign
  conflicts with the BD-203 as-built per-entry shape, the predesign is UPDATED to
  match BD-203. Recorded as Track-B input; NOT designed here.
- **Track A / Track B carve-out** (new §10.5). The phase-parts/ordering
  IMPLEMENTATION (BD-185 flat-file build, BD-206 conversion + `_order.md`, BD-216)
  is carved OUT of C1–C6 and deferred to its own docs-researcher → architect
  pipeline AFTER C6. C1–C6 carry Track-A cleanup + the MECHANICAL entry re-scope
  TEXT only (decided scope + constraints + pointers), never those BDs'
  implementation.

Sections edited this pass: §0 (decision summary D-J + a new "post-update" line),
§9 (Track-2 disposition table — BD-185 split row + BD-216 row + US-5/US-6/US-7
annotations + the deterministic-serializability + BD-185→215 wiring notes), §10
(commit plan — C6 entry-re-scope/BD-216-authoring confirmation; US-2 in C3 with
literal text; US-3 BD-204/BD-215 notes in C6), NEW §10.5 (Track A/B carve-out),
§11 (US-1..US-9 outcomes), §6 (the literal `changelog/v11.md` old→new block,
US-2), §14 (Rules-Applied block refresh). All other sections UNCHANGED.

## 0. Decision summary

Fixed user constraints (2026-06-12, non-negotiable, not re-litigated here): tracker deferred
indefinitely, no release version; flat-file per-entry is the SOLE supported mode both surfaces;
tracker code retained DORMANT where well-designed, cruft deleted; flip ABILITY blocked both
surfaces with a clear deferred message; D-19 stops recommending; entry format unchanged (BD-215
owns redesign); GH issues: DELETE ALL 213, execution HELD; rehearsal scratch repos already
user-deleted; Track 2 restarted from scratch, executed together with this cleanup; local
tracker state deleted, .gitignore guard stays.

Architect decisions this doc makes:

| # | Decision | One-line rationale |
|---|---|---|
| D-A | Flip-block = 2 code layers (mode-detection clamp in `tracker_mode()` + verb gates on `init` / `enable-recommendations` / `tracker-migrate.sh forward`) + advertisement removal | The clamp is the single chokepoint every mode-dependent consumer already routes through (§3, EE-7); verb gates give the user-facing deferred message |
| D-B | Test-only env override `PACK_TRACKER_DEFERRAL_OVERRIDE=1` keeps dormant code testable | Dormant code must stay provably healthy (user: tracker returns); tests export it inside the test scripts, CI yml unchanged |
| D-C | `init-project.sh` S11 + v10→v11 migrator STOP installing `tracker.toml.example` to clients; HELP-FRAGMENT-TRACKER ships as a rewritten deferred stub | A config template whose only purpose is a blocked flip is advertisement; the fragment mechanism is pinned by Checks 22/23 + pack-help.sh, so rewrite beats delete |
| D-D | Both `tracker.toml.*-example` files stay COMMITTED (pack tree only) | They are the dormant feature's config record; Check 29 keeps validating them; cost ≈ 0 |
| D-E | New Check 51 (flip-block guard, 5 cheap grep legs, measured §6.3); Check 50 gets its missing dedicated test; Checks 29/30/35/49 KEEP | Guards the deferral against regression; closes the BD-184 wiring asymmetry |
| D-F | Queued tree-level Blockers-cycle check is NOT implementable as a CI gate in the existing entry format — re-anchor to BD-215 (US-3) | Measured: 17 false cycles from prose-form Blockers lines (EE-14); an allowlist that swallows them swallows real signal |
| D-G | Maintenance-docs: 14 KEEP (as-built architecture + named research baselines) / 93 DELETE (per-commit churn: IMPL/REVIEW/PLAN/SWEEP/ANALYSIS/DESIGN-REVIEW) (§8) | Fail-loud partition: resumption baseline ≠ process churn |
| D-H | All 21 dedicated code files + 25 test files + fixtures KEEP-DORMANT; tracker CI test steps keep running green | User: keep the good parts; green dormant tests are the health proof |
| D-I | GH deletion mechanics: manifest-first, GraphQL `deleteIssue` serial ≥1s, NOT_FOUND-idempotent, labels ride; one-shot /tmp script, NOT committed (§7); execution HELD | Per RESEARCH-BD-212; a committed verb for a dead feature is exactly what BD-212's deferral avoids |
| D-J | Track-2: per-entry dispositions §9; recommend Deferred for BD-185/BD-188/BD-212/BD-213 (prior-ruling flags raised), Deprecate BD-102/BD-174, merge BD-100→BD-205, Resolve BD-198, re-scope BD-206 flat-file-only v11.0 | Evidence per row; user decides every flagged row |
| D-J′ (2026-06-13 update) | RESOLVED per user: BD-185 SPLIT — flat-file half STAYS v11.0 + launch-gate; tracker half → NEW BD-216 (deferred no-version); BD-188/212/213 → Deferred no-version (cluster with the tracker-resumption release); BD-206 CONFIRMED v11.0 (+ monolith-delete + create/reconcile `_order.md`); BD-102/174 Deprecate; BD-100→BD-205 merge; BD-198 Resolve. Phase-parts/ordering IMPLEMENTATION is Track B (own pipeline after C6, §10.5). | §9 rows + §10.5; the entries' RE-SCOPE TEXT lands in C6, the implementation does not |

User-decision queue (decisions this design needs but does not own): see §11. **All nine (US-1..US-9) are now RESOLVED (2026-06-13) — §11 records each outcome; this design is updated to match.**

## 1. Evidence base (Empirical-Evidence Blocks)

All measurements taken 2026-06-12 at HEAD `0027b10` (tree = HEAD + the BD-214 dated note +
the untracked census file; verified via `git status --short` → ` M backlog/BD-214.md`,
`?? .../RESEARCH-TRACKER-DEFERRAL-CENSUS.md`).

> **EE-1 — dedicated tracker code.**
> Cmd: `wc -l scripts/pack-tracker.sh scripts/tracker-migrate.sh scripts/lib/tracker-*.sh scripts/lib/recommendation.sh`
> Output: `13053 total`; `ls scripts/lib/tracker-*.sh | wc -l` → `18` (+2 root scripts +
> recommendation.sh = 21 files). Census's 21/13,053 re-verified. SUPPORTED.

> **EE-2 — tracker tests.**
> Cmd: `wc -l scripts/tests/tracker-*.sh scripts/tests/test-tracker-*.sh scripts/tests/recommendation-*.sh scripts/tests/test-issue-forms.sh scripts/tests/test-validate-pack-check-49*.sh`
> Output: `15334 total`; tracker-named files `21` (+2 recommendation +1 issue-forms +1
> check-49 = 25). `ls scripts/tests | grep -i 'check-50\|codec'` → EMPTY: **Check 50 has no
> dedicated test** (census flag re-verified). SUPPORTED.

> **EE-3 — maintenance-docs name census.**
> Cmd: `find maintenance-docs \( -iname '*BD-204*' -o -iname '*MODE3*' -o -iname '*TRACKER*' \) | wc -l`
> Output: `108` = census's 107 + `RESEARCH-TRACKER-DEFERRAL-CENSUS.md` itself (written after
> the census ran; it matches `*TRACKER*`). Full path list captured; class counts: 41
> IMPL-REPORT + 42 PACK-REVIEW + 6 ARCHITECTURE + 4 DESIGN-REVIEW + 3 PLAN + 6 RESEARCH +
> 2 SWEEP + 1 ANALYSIS + 2 v11-research = 107. SUPPORTED (census count exact).

> **EE-4 — live GH state (read-only).**
> Cmd: `gh api 'search/issues?q=repo:DShaneNYC/optiquity-ai-agent-config-pack+type:issue' --jq .total_count` → `213`.
> `gh label list ... --jq '[.[] | select(.description=="v11 pack-managed label")] | length'` → `49`.
> Census re-verified. SUPPORTED.

> **EE-5 — backlog states at current HEAD (inventory freshness).**
> Cmd: `grep -l "^Status: <S>" backlog/BD-*.md | wc -l` per state.
> Output: Open 28, Unblocked 1, Deferred 14, Resolved 167, Deprecated 4, Cancelled 1; 215
> files total. Delta vs the inventory (41 non-resolved over 213 files at 1c18b28): +BD-214
> (Open) +BD-215 (Deferred) new; BD-204, BD-207 Open→Deferred. 27+1+1=28 Open ✓; 11+3=14
> Deferred ✓. Non-resolved = 43. Every other inventory row's status unchanged. SUPPORTED —
> the inventory is fresh modulo exactly these four known deltas.

> **EE-6 — `tracker_mode()` is the single mode chokepoint.**
> Cmd: `grep -rln 'tracker_mode\b' scripts/ --include='*.sh' | grep -v tests`
> Output: `scripts/pack-tracker.sh, scripts/lib/tracker-agent-read.sh, scripts/lib/tracker-edit.sh,
> scripts/lib/tracker-config.sh, scripts/lib/tracker-doctor.sh, scripts/lib/tracker-migrate-forward.sh,
> scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh, scripts/lib/migrate-v10-to-v11/checkpoint.sh`
> (8 files; zero hits in validate-pack.py). `tracker_mode()` (tracker-config.sh:187) emits
> "tracker" ONLY when tracker.toml parses AND `mode.state=="tracker"` AND
> `migration.forward_complete=="true"`; all failures fall back "flat-file". The pack-startup /
> pm-startup skills document the SAME three-part test. SUPPORTED — clamping this one function
> (plus the skill-prose analog) makes every mode-dependent consumer flat-file.

> **EE-7 — D-19 live invokers.**
> Cmd: `grep -rln 'recommendation_should_recommend' . --exclude-dir=.git`
> Output (10): `.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-startup/SKILL.md`,
> `.gemini/commands/pack-startup.toml`, `project-template/{.claude,.codex,skills}/pm-startup/SKILL.md`,
> `project-template/.gemini/commands/pm-startup.toml`, `scripts/lib/recommendation.sh`,
> `scripts/tests/recommendation-test.sh`, `maintenance-docs/v11-research/PACK-REVIEW-BD072-074.md`.
> Interpretation: live invocation surface = exactly the 7 skill files (pack ×3 + project ×4);
> lib + test + maintenance-doc are not invokers. SUPPORTED — sized for the Check 51 leg-3 gate.

> **EE-8 — entry-content artifact grep-zero (BD-214 scope 1).**
> Cmd: `grep -rn '<!-- pack-entry-body-gz64:' backlog/ changelog/` → 1 hit, `backlog/BD-204.md:24`,
> MID-LINE inside a backticked prose example. Line-anchored `^<!-- pack-entry-body-gz64:` → 0.
> `grep -rn 'pack-id:' backlog/ changelog/ | grep -v 'per-entry source\|\`'` → 0.
> SUPPORTED — committed entry content carries ZERO actual tracker artifacts (census EE-1a/1b
> re-verified); the gate pattern must be LINE-ANCHORED to stay allowlist-free.

> **EE-9 — S11 / migrator client-install surface.**
> Cmd: `grep -n 'tracker' scripts/init-project.sh` → S11 banner :908; tracker.toml.example
> copy :941-943; install-map `project-template/tracker.toml.project-example:tracker.toml.example:generic`
> :1250 + map comments :1405. `grep -n 'tracker init\|tracker_init' scripts/migrate-v10-to-v11.sh scripts/lib/migrate-v10-to-v11/*.sh`
> + gate-3 header: "The v10→v11 migrator itself does not opt the user into tracker mode — it
> lays down the artifacts ... and points the user at `pack tracker init` in the post-report
> hook" (:710-711 prints the verb); example copy at migrate-v10-to-v11.sh:299-305. SUPPORTED —
> neither installer FLIPS mode; both ADVERTISE + lay flip materials.

> **EE-10 — CI workflow tracker family + actions versions.**
> Cmd: `grep -n 'name:' .github/workflows/validate-pack.yml | grep -i 'tracker\|recommendation\|issue\|check-49'`
> Output: **17 tracker-named test steps** (12 at lines 122-157 + 5 BD-129/130/132/133/134 at
> 209-223) + 2 recommendation steps (158, 224) + 1 issue-forms (294) = 20 family steps; deep
> field-faithfulness run step at :103; check-49 per-check test wired at :208.
> `grep -n 'uses:'` → `actions/checkout@v4` (:88, :109), `actions/setup-python@v5` (:91, :112).
> PARTIAL vs census: census said "16 tracker test steps" — actual count is **17** (census
> minor undercount; corrected here). Actions pins are pre-Node-24 majors → the user-fixed
> Node-24 bump applies to these 4 lines. SUPPORTED (with the census count corrected).

> **EE-11 — Blockers-cycle check feasibility (queued BD-204 anchor).**
> Cmd: python DFS over `BD-\d+` refs extracted from `^Blockers:` lines of all 215 entries.
> Output: `cycles: [[BD-135,BD-135],[BD-149,BD-149],[BD-172,BD-172],[BD-174,BD-174],
> [BD-200,BD-202,BD-200],[BD-200,BD-200],[BD-203,BD-204,BD-203],[BD-203,BD-204,BD-215,BD-207,BD-203],
> [BD-203,BD-204,BD-215,BD-207,BD-206,BD-203],[BD-206,BD-206],[BD-215,BD-207,BD-215],
> [BD-204,BD-215,BD-204],[BD-185,BD-205,BD-185],[BD-185,BD-185],[BD-199,BD-199],[BD-208,BD-208],
> [BD-209,BD-209]]` — **17 cycles, ALL prose-induced false positives** (self-mentions and
> narrative cross-mentions inside free-prose Blockers lines; e.g. BD-204's Blockers
> legitimately NARRATES "BD-215 ... blocks any resumption" while BD-215's Blockers narrates
> BD-204). The one true historical cycle (BD-094↔BD-095) is FIXED: `grep '^Blockers' backlog/BD-094.md`
> → `Blockers: BD-088, BD-085` (no BD-095); BD-095 still lists BD-094 (one-way, valid).
> NOT-SUPPORTED for a hard CI gate in the existing format → D-F / US-3.

> **EE-12 — BD-198 landed-but-Open.**
> Cmd: `grep -n '^Status' backlog/BD-198.md` → `Status: Open`. Inventory finding (work landed
> at cb460e6, all four AC surfaces verified) unchanged at this HEAD. SUPPORTED.

## 2. The keep-dormant line (BD-214 scope 3) — principle and application

**Principle (property-fit, not precedent):** a tracker artifact is KEEP-DORMANT iff it is
(a) executable/testable code or its direct test/fixture, (b) reachable only THROUGH the
blocked seams after §3 lands, and (c) part of the as-built design the user expects to resume
(TrackerProvider abstraction, migrators, gz64 codec, verbs, labels, forms, phase-task, links,
cycle-check, promote, doctor, errors, edit, agent-read, mirror, sidecar, header-snapshot —
the last two carry their existing BD-207 deletion anchor). It is BLOCK iff it is an
activation seam (§3). It is UPDATE iff it is prose presenting tracker as USABLE. It is
DELETE iff it is process churn with no resumption value (§8) or client-side flip material
(D-C). Nothing in the 21 code files met a DELETE bar: all are structured, provider-routed,
test-covered (15,334 test lines), and named by the user as the return path. **Zero code
deletions in BD-214** — the census's per-file KEEP-DORMANT preliminaries are CONFIRMED for
all 21 files (challenged individually; no overturn had evidence).

Census preliminaries OVERTURNED or resolved (`ARCH?` rows):
1. `tracker-config.sh` "BLOCK point candidate ARCH?" → CONFIRMED as the PRIMARY seam (EE-6).
2. `init-project.sh S11 install-vs-skip ARCH?` → SKIP the toml example install (D-C); keep
   the fragment install as a deferred stub.
3. `HELP-FRAGMENT-TRACKER.md UPDATE-or-DELETE ARCH?` → UPDATE (rewrite as stub): Checks 22/23 +
   `pack-help-test.sh` (26 tracker refs) + pack-help.sh inlining pin the fragment MECHANISM;
   deleting it forces validator surgery for zero gain.
4. Checks 49/50 "KEEP-DORMANT or RETIRE ARCH?" → KEEP both (49 already DEEP-gated, costs
   nothing un-gated; 50 is a cheap static self-guard) + add Check 50's missing test (D-E).
5. `changelog/v11.md KEEP-as-history vs UPDATE ARCH?` → UPDATE the unreleased v11.0 block
   (it currently advertises an unshipped-usable feature in release notes); needs user content
   approval (US-2).
6. `work-item.yml KEEP-DORMANT ARCH?` → KEEP-DORMANT both surfaces (locked BD-204 form-family
   baseline; pinned by check_issue_template_forms + test-issue-forms.sh; a rendered-but-inert
   GH form does not reach tracker mode). `inbound.yml` KEEP (live flat-file feedback channel
   per backlog/_rules.md).
7. `tracker-agent-read.sh flat-file branch live? ARCH?` → its flat-file branch remains valid
   under the clamp; KEEP-DORMANT, no special handling (EE-6).
8. `tracker-cycle-check.sh as seed for the tree-level check ARCH?` → MOOT for v11.0 (D-F):
   the tree-level check re-anchors to BD-215.
9. Census CI-step count 16 → corrected to 17 (EE-10).

## 3. Flip-block design (BD-214 scope 2) — every entry point enumerated

**Layer A — mode-detection clamp (the chokepoint).** `tracker_mode()` in
`scripts/lib/tracker-config.sh` gets a deferral clamp as its FIRST statement:

```bash
# BD-214 deferral clamp: tracker mode is deferred indefinitely (user 2026-06-12).
# Flat-file is the sole supported mode. PACK_TRACKER_DEFERRAL_OVERRIDE=1 is a
# TEST-ONLY seam keeping the dormant tracker code testable; never set it live.
if [[ "${PACK_TRACKER_DEFERRAL_OVERRIDE:-0}" != "1" ]]; then
    # If the file WOULD have evaluated tracker-mode, say so once (stderr).
    ... emit one-line "tracker mode is deferred; operating flat-file" notice ...
    echo "flat-file"; return 0
fi
```

Effect (EE-6): all 8 live consumers — verbs, agent-read, edit, doctor, forward migrator,
both v10→v11 migrator gates — collapse to flat-file. A hand-copied `tracker.toml` (from
either example) becomes INERT with a visible notice. This is the seam the census flagged
ARCH? and the one a verb-gate-only design would MISS.

**Layer B — verb gates (the clear deferred message).** Same override seam; refusal text
states: tracker support is deferred indefinitely, flat-file per-entry is the supported mode,
and where the deferral is recorded (BD-214/BD-204 entries).
- `cmd_init` (`scripts/pack-tracker.sh:147`) refuses BEFORE `tracker_init_run`.
- `cmd_enable_recommendations` (`:738`) refuses (it re-arms D-19 — a recommendation seam the
  census did not tag BLOCK; **missed-seam #1**).
- `scripts/tracker-migrate.sh` FORWARD arm refuses (direct low-level flip path bypassing the
  init verb; **missed-seam #2**). Reverse arm stays un-gated (only meaningful FROM tracker
  mode, which is unreachable; and it is the escape hatch, never a flip).
- All other verbs (`status/doctor/disable/tree-rebuild/edit/new-entry/mirror-rebuild/
  update-templates`) need NO gate: under the clamp each already refuses or no-ops via its
  existing "not in tracker mode" typed-error paths. Planner adds a verification item: run
  each verb on a flat-file root and assert non-zero + typed error (no crash).

**Layer C — advertisement and recommendation removal.**
- D-19: Step 8 BODY in pack-startup (×3 CLI files) and pm-startup (×4 files) is replaced by
  a 3-line deferred note (step NUMBER kept — V3 §28.1.9 fixes the numbering; cheapest
  resumption). `recommendation.sh` itself: KEEP-DORMANT untouched (its Guard-1 semantics and
  tests stay valid). Post-change, NOTHING live writes `.pack-tracker/recommendation-state.json`
  → satisfies BD-214 scope 6 (no repo surface recreates local state; EE-7 shows the 7 skill
  files are the only live writers).
- S11 / migrator: stop copying `tracker.toml.example` (init-project.sh :941-943, :1250, map
  comments; migrate-v10-to-v11.sh :299-305); rewrite the migrator post-report `pack tracker
  init` pointer (:710-711) to a deferral sentence. HELP-FRAGMENT-TRACKER (both copies)
  rewritten as deferred stubs (§5).
- `.github/ISSUE_TEMPLATE/config.yml` blurbs: verify wording doesn't sell tracker mode
  (mechanical UPDATE if so).

**Entry-point table (proof obligation for AC "no reachable path"):**

| # | Entry point | Block |
|---|---|---|
| 1 | `pack tracker init` | Layer B refusal (+ Layer A makes even a forced product inert) |
| 2 | Hand-copied/authored `tracker.toml` | Layer A clamp + stderr notice |
| 3 | D-19 recommendation → init suggestion | Step-8 bodies removed (×7 files); `enable-recommendations` gated |
| 4 | `tracker-migrate.sh forward` direct | Layer B refusal |
| 5 | v10→v11 migrator Phase B | Never flips by itself (EE-9); Gate 3 auto-SKIPs under clamp; advertisement rewritten |
| 6 | init-project.sh S11 client install | toml example no longer installed; fragment = deferred stub |
| 7 | Other `pack tracker` verbs | Mode-dependent; inert under clamp (verified per verb) |
| 8 | GH web (issues/forms exist) | Filing an issue never flips mode; flat-file tooling ignores issues (existing model) |

Dormant-but-testable: every tracker test script exports `PACK_TRACKER_DEFERRAL_OVERRIDE=1`
(and the new gate tests assert the refusals WITHOUT it) — CI yml steps unchanged except
additions; dormant code stays green-proven. Flat-file behavior is untouched at every layer
(the clamp only ever STRENGTHENS the existing flat-file fallback).

## 4. Per-axis disposition over the ENTIRE census (scope of every occurrence)

Axis tags follow the census (§§1-9 there). Every census row is dispositioned; rows not
restated individually inherit their class row here.

**Axis A — entry content.** ZERO actual blobs/markers (EE-8): nothing to strip; the AC
grep-zero gate is codified as Check 51 leg 4 (line-anchored patterns, empty allowlist).
`backlog/_rules.md`: REWRITE the mode sections — "Source of truth" becomes flat-file-only
(tree is the SOLE SSOT, no monolith) + a short "Tracker mode (deferred)" paragraph stating
the deferral, the clamp, and that the contract's tracker-mode write procedure is suspended
until resumption; DELETE the "Published tree + single writing authority" tracker-publication
section and the tracker-mode write-authority arm; KEEP the field-faithful paragraph but
reword its justification to format-neutral ("the contract does not gate on a field allowlist;
extension fields are admitted and preserved") without presenting the migrator as live.
`changelog/_rules.md`: mode-invariance § shrinks to "flat-file in all cases" + one deferral
sentence. `backlog/_intro.md` pointer line: deferral wording. Resolved/Deprecated historical
entries (~60 files): KEEP untouched (immutable history). Live entries: per §9 table only.

**Axis B — code.** All 21 dedicated files KEEP-DORMANT (§2); seam edits per §3 only.
Shared-code rows: `pack-td.sh` KEEP, UPDATE its tracker-mode prose to "deferred" + fix the
`Resolution: n/a`→`Resolved: n/a` advisory typo (BD-204 note line 30 — fold here, fix-now);
`pack-help.sh` mechanism KEEP (fragment content changes); `init-project.sh` + migrator per
§3 Layer C; incidental refs (detect.sh, template-version.sh, translations, migrator-core,
persona-contracts, per-entry/decompose comment) KEEP — UPDATE only where prose says usable.
`project-template/scripts/`: zero tracker code (census-verified) — nothing to do.

**Axis C — validators + CI.** §6.

**Axis D — tests + fixtures.** All KEEP-DORMANT and green; lock-step UPDATE set:
`pack-help-test.sh` (26 tracker refs — pins fragment content), `test-init-project.sh`
(recommendation/S11 refs), `test-migrate-v10-to-v11-gates.sh`, `template-translations-test.sh`,
`test-validate-pack-check-40.sh` + any test pinning swept prose; tracker test scripts gain
the override export; gate tests added (§6). `scripts/tests/fixtures/` tracker fixtures KEEP.
`test-fixtures/build.sh` v11-tracker-on synthesis KEEP (writes fixture files directly; not a
flip path); manifest regenerated every v11-surface commit per standing rule.

**Axis E — operating docs.** Root trinity ×3: rewrite § Repo conventions "Per-entry trees —
sole SSOT" bullet to flat-file-only + 2-sentence deferral note (Mode-3 contract prose
deleted); rewrite § Project goals v11 first bullet to "flat-file per-entry is the sole
supported mode; tracker integration is deferred to a future release (no version)". The
"Resolved section" bullet drops its tracker-mode write-channel arm. `pack-ops/PACK-CHAT.md`:
"Backlog write paths by mode" section (lines 53-114) collapses to the flat-file procedure +
deferral note; D-19 prose (288-307) replaced by deferral note. `PACK-AGENTS.md`: zero refs —
no edit. `PACK-MEMORY-RATIONALE.md` (3) + `BOUNDARY-DEFINITION.md` (2): mechanical deferral
rewording. `.boundary-exempt-root.txt` line 5 (`tracker.toml.pack-example`): KEEP (file stays,
D-D). Skills: Step-8 bodies per §3 Layer C; `boundary-investigation` worked-example mentions
(×4 surfaces): KEEP (historical example, not advertisement) with a one-word "deferred"
qualifier where it implies usable; documentation/pack-help skill incidentals: mechanical.

**Axis F — user-facing.** `pack-ops/HELP-FRAGMENT-TRACKER.md` + project copy: rewritten
stubs — heading "Tracker commands (deferred)", 2-3 sentences (deferred indefinitely;
flat-file is the mode; `pack tracker` verbs refuse with a deferred message), retaining the
verb TOKENS the freshness check needs (Check 22 compares prose verb tokens against the
fragment — keeping one line naming `pack tracker init` as *refusing* keeps residual prose
mentions legal). `HELP-FRAGMENT-PACK.md` + project `HELP-FRAGMENT.md`: tracker verb rows
get a "(deferred)" qualifier or collapse to one deferred row. OPTIONAL-FEATURES (§125 pack /
§110 project): the "Tracker integration (v11)" walkthrough is REPLACED by a short deferred
section (what it was, that it is deferred, that code is dormant; no opt-in steps).
`PM-CHAT.md` (project): D-19 prose (512-531) + tracker-mode read/write paths (591-884)
collapse to flat-file procedure + deferral note. README.md: v11.0 version-table row reworded
(tracker = "deferred (dormant)"); layout rows for tracker files KEEP but annotated
"(dormant, deferred)" (:107, :138, :197-215, :255-271). QUICKSTART.md :43: deferral
rewording. `supporting-docs/DEPENDENCIES.md` (gh / gh-sub-issue rows): mark "required only
for the deferred tracker feature (dormant)". `supporting-docs/MIGRATION-v10-to-v11.md`
Phase B section: rewritten as "Phase B (tracker opt-in) — DEFERRED"; migration is Phase-A
complete without it. METHODOLOGY.md (1 occ): mechanical. Prompt files ×5: "flat-file mode
reads X; tracker mode reads the tracker" → "reads X (the per-entry tree)". Project
`docs/project/*/_intro.md` ×3 (5 occ each): mode paragraphs → flat-file-only + deferral
sentence (client `_rules.md` files have zero refs — census-verified, nothing to do).
`changelog/v11.md`: UPDATE unreleased v11.0 block per US-2. The LITERAL old→new replacement text the C3 coder applies is supplied in §6.6 (US-2 RESOLVED — user-approved 2026-06-13). MERGE-STRATEGY /
DRY-RUN-MIGRATION / CONCEPTUAL-REVIEW-METHODOLOGY rows: mechanical "(deferred)" annotations.

**Axis G — config/plumbing.** `.gitignore` (root + project-template): KEEP — this IS the
scope-6 recreation guard. Both toml examples: KEEP committed (D-D); client INSTALL stops
(D-C). Issue forms both surfaces: KEEP per §2 item 6. Local state: confirmed deleted
(census EE §7); nothing recreates it post-Step-8 removal (§3 Layer C).

**Axis H — maintenance-docs.** §8.

**Axis I — external GH.** §7 (design only; execution HELD).

## 5. Project-side story (what ships to clients after this change)

Honors dependency-direction: nothing new ships; two things STOP shipping or change content.

| Client artifact | Before | After |
|---|---|---|
| `tracker.toml.example` (client root) | Installed by S11 + v10→v11 migrator | **NOT installed** (existing clients keep their inert copy; the clamp makes it harmless — `pack --update` does not delete client files, acceptable) |
| `docs/pack/HELP-FRAGMENT-TRACKER.md` | Tracker verb walkthrough | Installed DEFERRED STUB (same path; mechanism + Checks 22/23 unchanged) |
| `docs/pack/HELP-FRAGMENT.md` | `pack tracker` rows as usable | Rows carry "(deferred)" |
| `docs/pack/OPTIONAL-FEATURES.md` / `PM-CHAT.md` / `docs/project/*/_intro.md` / prompts / trinity | Tracker-mode prose | Flat-file-only + deferral notes |
| pm-startup skill (×4 files) | Step 8 D-19 recommendation | Step 8 = deferred note (number reserved) |
| `.github/ISSUE_TEMPLATE/*` (client) | work-item + inbound + config | UNCHANGED (dormant form family + live inbound channel) |
| `project-template/scripts/` | zero tracker code | unchanged (zero) |

`_SANCTIONED_PACK_SIDE_SHIPPED` is NOT touched: the set stays exactly
`{scripts/lib/detect.sh, scripts/pack-help.sh}` (no new pack-side file ships; Check 47
unaffected). No project-side deliverable becomes a pack-runtime dependency.

## 6. Validator / CI redesign

### 6.1 Existing checks

| Check | Disposition | Notes |
|---|---|---|
| 22/23 help-fragment freshness/completeness | KEEP; surfaces edit in LOCK-STEP with fragment stubs | Verb tokens retained in stubs keep 22 green; 23 still sees pack-tracker.sh covered |
| 29 tracker-config (+29″ never-tracked guard) | KEEP unchanged | Examples stay committed (D-D); 29″ IS a recreation guard (scope 6); mirror-staleness leg inert without live toml |
| 30 recommendation-state schema | KEEP-DORMANT | Schema guard for dormant lib; soft-passes absent state |
| 32′ no-monolith / 33 toc / 34 cross-ref | KEEP | Flat-file infrastructure, not tracker cruft |
| 35 phase-task invariants | KEEP-DORMANT | Guards dormant lib health |
| 36/37/38 boundary + scope-honesty | KEEP | Incidental refs only; no semantic change |
| 39/41/46 cmd_update symmetry + `_CLIENT_INSTALLED_FILES` | UPDATE in the SAME commit as the S11 change | tracker.toml.example leaves the install map; set-equality checks re-pinned |
| 42 CI wires per-check tests | KEEP; governs the new tests | New `test-validate-pack-check-5*.sh` files MUST be wired same-commit |
| 47 sanctioned shipped set | KEEP unchanged | §5 |
| 48 removed-doc advisory | KEEP; `_REMOVED_DOC_BASENAMES` NOT grown for the §8 deletions | Advisory-only; adding ~93 basenames is noise without gate value; dangling cites in Deferred history are fail-loud-acceptable (memory rule) |
| 49 field-faithfulness (DEEP-gated) | KEEP as-is | Dormant-migrator health proof; already runs only under `PACK_VALIDATE_DEEP=1` CI step; codec exercised against the real tree keeps resumption honest |
| 50 no-reproduced-codec | KEEP + **ADD the missing dedicated test** (`test-validate-pack-check-50-codec-single-source.sh`) | Closes the measured BD-184 asymmetry (EE-2); cheap static check |
| unnumbered issue-template-forms | KEEP | Pinned dormant baseline + live inbound channel |

### 6.2 Checks that must also pass with the clamp active

`validate-pack.py` never calls `tracker_mode` (EE-6) — no validator depends on mode
detection; no check needs the override. The full battery + integration tests
(`test-v11-*.sh`) run per commit per the verify-full-CI-suite rule.

### 6.3 NEW Check 51 — flip-block guard (measure-then-bound applied)

Five cheap, bounded legs (no whole-tree scans; satisfies the runtime-compounding rule —
each leg is a grep over ≤3 named files or 2 bounded dirs):

| Leg | Assertion | Measured NOW | Post-fix projected |
|---|---|---|---|
| 1 | `tracker-config.sh` contains the BD-214 clamp marker (`PACK_TRACKER_DEFERRAL_OVERRIDE` + the dated comment) | absent (pre-fix, expected) | present → PASS |
| 2 | `pack-tracker.sh` init + enable-recommendations gates present; `tracker-migrate.sh` forward gate present | absent (pre-fix) | present → PASS |
| 3 | `recommendation_should_recommend` occurrences OUTSIDE allowlist {`scripts/lib/recommendation.sh`, `scripts/tests/`, `maintenance-docs/`} == 0 | 7 hits = the 7 skill files (EE-7) — ALL categorized STRIP (Step-8 rewrite is the fix-recipe) | 0 → PASS |
| 4 | Entry-content grep-zero: `^<!-- pack-entry-body-gz64:` and `^<!-- pack-id:` over `backlog/ changelog/` == 0 | 0 (EE-8; the BD-204:24 prose hit is mid-line, excluded by the anchor — allowlist EMPTY by construction) | 0 → PASS |
| 5 | `tracker.toml.example` absent from init-project.sh install map (anti-reintroduction) | present :1250 (STRIP via D-C) | absent → PASS |

Allowlists sized exactly to the measured legitimate set (leg 3: three prefixes; leg 4: none);
no borderline admissions. Guard verified to run clean against the projected post-fix tree
(every STRIP has a named fix-recipe landing in the same plan). Dedicated test
`test-validate-pack-check-51-flip-block.sh` wired same-commit (Check 42).

### 6.4 The queued Blockers-cycle check — finding (D-F)

The BD-204 dated note (2026-06-12) anchors a tree-level Blockers-cycle validate-pack check
to "the first Track-2 execution batch". MEASURED (EE-11): a regex-edge cycle detector finds
17 cycles on the current tree, ALL false positives from free-prose Blockers lines; an
allowlist admitting them would also admit real future cycles between the same entries —
defeating the guard. The check is therefore NOT cleanly implementable until Blockers becomes
machine-parseable, which is exactly BD-215's format spec. RECOMMENDATION (US-3): move the
anchor to BD-215 ("the canonical format makes Blockers a structured field; the cycle check
ships WITH the format validator"), recorded as a dated note on BD-204 + BD-215. The original
data defect (BD-094↔BD-095) is verified fixed (EE-11).

### 6.5 CI workflow edits

- All 20 tracker-family steps (EE-10) KEEP running (dormant health).
- ADD steps: check-50 test, check-51 test (Check 42 forces this).
- **Node-24 actions bump (user-fixed, deadline 2026-06-16):** `actions/checkout@v4`→ current
  Node-24 major and `actions/setup-python@v5` → current Node-24 major, at lines 88/91/109/112
  (coder verifies the exact latest majors at implementation time). Rides commit C2 (§10) —
  the first CI-touching commit, sequenced before the deadline.

### 6.6 — `changelog/v11.md` unreleased v11.0 block reword (US-2 — literal old→new the C3 coder applies)

US-2 RESOLVED (user-approved 2026-06-13): the `changelog/v11.md` unreleased v11.0
block currently presents the issue-tracker integration as a SHIPPED, usable v11.0
feature ("Scope A — Issue-tracker integration (D-1..D-23)"). With tracker deferred,
that release note advertises an unshipped-usable feature. The block is reworded to
"tracker = deferred/dormant, flat-file = the v11.0 model." **The architect supplies
the literal replacement; the architect does NOT edit `changelog/v11.md` — a CODER
applies this at C3** (changelog is user-governed content; the user has approved the
new text below). The change is SURGICAL: it rewrites ONLY the "Scope A" heading +
its lead framing and prepends a deferral preface; the D-1..D-23 bullet list is KEPT
as a dormant-feature inventory under a reframed heading (history is not erased — the
code that shipped is dormant, not deleted). Scopes B and C are untouched.

Measured current text (HEAD `0027b10`, `changelog/v11.md` lines 4-6):

```
### v11.0 — Issue-tracker integration + customization-preservation fix

**Scope A — Issue-tracker integration (D-1..D-23)**
```

OLD (the exact lines to replace — line 4 the H3 release title, and line 6 the
Scope-A H4 heading; line 5 is the blank line between them, preserved):

```
### v11.0 — Issue-tracker integration + customization-preservation fix
```
…and…
```
**Scope A — Issue-tracker integration (D-1..D-23)**
```

NEW (replaces the two lines above respectively; the blank line between is kept):

```
### v11.0 — Flat-file per-entry model + customization-preservation fix
```
…and…
```
**Scope A — Issue-tracker integration (D-1..D-23) — DEFERRED / DORMANT in v11.0**

> Tracker (GH Issues) integration is **deferred indefinitely, with no release
> version** (user 2026-06-12). **Flat-file per-entry is the sole supported mode in
> v11.0.** The tracker code listed below (D-1..D-23) is retained DORMANT and
> test-covered for a future resumption; the ability to flip to tracker mode is
> BLOCKED on both surfaces (BD-214), and resumption is gated on the entry-format
> redesign (BD-215) landing first. The D-1..D-23 inventory below is preserved as a
> record of the dormant feature, NOT as a list of shipped-usable functionality.
```

The C3 coder applies exactly this substitution (two heading lines + the inserted
blockquote preface), leaves the D-1..D-23 bullets verbatim as the dormant
inventory, and re-runs validate-pack + the changelog stream regen. No other
`changelog/v11.md` content changes. (If the C3 coder measures the live lines and
finds drift from the quoted current text, it surfaces the drift rather than
force-applying — the substitution is anchored on the two quoted heading strings.)

## 7. GH-issue deletion mechanics (DESIGN ONLY — execution HELD by the user)

Decision of record: DELETE ALL 213 issues (user, BD-214 dated note 2026-06-12); execution
waits for an explicit user GO. Grounded in `RESEARCH-BD-212-GH-ISSUE-DELETION.md` (read in
full): GraphQL-only `deleteIssue(input:{issueId})`, personal-repo owner-only, hard-delete,
no personal-account audit trail, `410 Gone` post-delete observable, ≥1s mutation pacing,
NOT_FOUND = already-deleted.

Procedure (Pack Chat runs interactively with per-step approval, or via a throwaway script in
`/tmp` — NOT committed to the repo: a committed verb for a dead feature is what the BD-212
deferral avoids; D-I):

1. **Preflight:** `gh auth status` (account `DShaneNYC`, classic scopes incl. `repo`);
   `repository.viewerCanAdminister == true` on the pack repo.
2. **Manifest FIRST (the only audit artifact that will exist):** page all issues
   (`gh api` search/list, paginated) capturing number, node `id`, title, state, labels, and
   the `<!-- pack-id: ... -->` value from each body → write
   `/tmp/bd214-gh-issue-deletion-manifest-<date>.json`; RECOMMEND the user archive a copy
   outside /tmp before GO (the repo does not carry it — operational ephemera).
3. **Candidate set:** every issue carrying the `bd-entry` label OR a pack-id marker
   (measured: all 213 carry `bd-entry`; EE-4). If ANY issue at execution time matches
   NEITHER (e.g., a fresh inbound-lane filing), STOP and surface it — it is not in the
   user's "all 213" decision.
4. **Delete loop:** serial, `deleteIssue` by node ID via `gh api graphql`; sleep ≥1s between
   mutations; honor `retry-after` / `x-ratelimit-reset`; exponential backoff on repeated
   secondary-limit hits; classify per errors[].type — `NOT_FOUND` → idempotent skip;
   FORBIDDEN-class → terminal stop. ~213 ops ≈ 4 min wall.
5. **Verify:** search total → 0 (or only non-candidate issues); spot-check one number via
   REST → `410 Gone`.
6. **Labels (riding recommendation, re-confirmed at GO — US-8):** delete the 49
   pack-managed labels (`gh label delete`, same ≥1s pacing; the 9 GitHub defaults stay).
7. **Record:** dated note on BD-214 with counts + manifest location.

Anchor while HELD: the BD-214 entry itself (Open) carries the decision + this design pointer.
Whether BD-214 stays Open until executed or the user re-anchors the held execution and lets
BD-214 resolve with the rest of the cleanup is **US-1**.

## 8. Maintenance-docs — the 107, each KEEP or DELETE

Partition rule (fail-loud, no archive): KEEP = describes the AS-BUILT dormant system or is a
named resumption/format input (BD-204 DESIGN BASELINE, BD-215 References); DELETE =
per-commit process churn (implementation/review/plan/sweep/point-in-time analysis) whose
content is superseded by the as-built state the KEEP set + code records. CI-safe: no
validator gates on maintenance-docs content (Check 48 is advisory and its frozen basename
set is deliberately NOT grown — §6.1); Check 34 validates ID-form refs only. Dangling
citations from Deferred history (e.g., BD-204 notes naming IMPL-REPORTs) are accepted per
the fail-loud memory rule.

**KEEP — 14 files:**

| File | Rationale |
|---|---|
| ARCHITECTURE-BD-204.md | As-built design record of the dormant pack tracker |
| ARCHITECTURE-BD-204-LOSSLESS-FIX.md | As-built gz64 field-faithful carrier design (named in BD-204 entry) |
| ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md | As-built Mode-3 ops contract incl. §5 R1-R8 (BD-207 resumption input) |
| ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT.md | Live amendment to the above |
| ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md | Live amendment (local-opt-in model; Check 29″ source) |
| ARCHITECTURE-BD-204-POST-BD211-RECON.md | As-built reconciliation with the BD-211 header grammar |
| RESEARCH-BD-204-GH-ISSUES-RULES.md | BD-215 named provider-constraint input (28-rule census) |
| RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md | Verification leg of the rules census |
| RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY-2.md | Second verification leg |
| RESEARCH-TRACKER-LANDSCAPE-RULES.md | BD-215 named tracker-landscape census input |
| RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md | Field-shape census — direct BD-215 format-design input |
| RESEARCH-BD-204-RESTART-INTEGRATION.md | Named DESIGN BASELINE input in the BD-204 entry |
| v11-research/IMPLEMENTATION-REPORT-RESEARCH-TRACKER-PRIMITIVES.md | BD-188/189 v11.1 groupings input (LIVE-classified per BD-189/192 constraint) |
| v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md | Same — v11.1 groupings input |

(`RESEARCH-TRACKER-DEFERRAL-CENSUS.md` and `RESEARCH-BD-212-GH-ISSUE-DELETION.md` are LIVE
BD-214 inputs, outside the 107; KEEP. The BD-204-entry-named v11-research DESIGN BASELINE
docs — DESIGN-BRIEF.md, ARCHITECTURE-V3.md, V3.1/V3.3 deltas, ARCHITECTURE.md — do not match
the 107 name patterns; they are BD-210's enumeration scope and stay untouched here. Note
`recommendation.sh` cites ARCHITECTURE-V3.md §28.1 — that doc must be LIVE-classified at
BD-210.)

**DELETE — 93 files** (rationale per class; the class IS the per-file rationale —
each is a point-in-time record of a commit cycle, superseded by the as-built tree):

- **41 IMPL-REPORT:** `IMPL-REPORT-BD-204-{C1,C2,C3,C4,C4-FIX1,C5,C5-CIFIX,C6,C6-FIX1,
  C-3-AMENDMENT,C-4.5,C-4.5-ADDENDUM,C-4.6,C-4.6-FIX1,C-4.7,C-7,C-7-FIX1,C-DOCS,C-DOCS-FIX1,
  C-DOCS-FIX2,C-RS,CASING-CYCLE,CASING-CYCLE-FIX1,CASING-CYCLE-FIX2,CLOSE-REASON-FIX,
  CLOSE-REASON-FIX-FIX1,ENTRY-REWRITE,GH-DEP-SHAPES,GHREPO-RESOLUTION,GHREPO-RESOLUTION-FIX1,
  GHREPO-RESOLUTION-FIX2,MIRROR-KEYS,MIRROR-KEYS-FIX1,RUN3-FIXES,RUN3-FIXES-FIX1}.md` +
  `IMPL-REPORT-MODE3-OPS-{COMMIT1,COMMIT1-FIX1,COMMIT1-FIX2,COMMIT2,COMMIT2-FIX1,COMMIT2-FIX2}.md`
- **42 PACK-REVIEW:** the matching `PACK-REVIEW-BD-204-*` set (36) + `PACK-REVIEW-MODE3-OPS-*`
  (6) — per-commit review churn
- **4 DESIGN-REVIEW:** `DESIGN-REVIEW-BD-204-{LOSSLESS-FIX,LOSSLESS-FIX-R2,LOSSLESS-FIX-R3,
  C46-RUNTIME}.md` — reviews of designs whose accepted form lives in the KEEP architecture docs
- **3 PLAN:** `PLAN-BD-204.md`, `PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md`,
  `PLAN-BD-204-MODE3-OPS-CONTRACT.md` — execution sequencing, dead after execution
- **2 SWEEP:** `SWEEP-BD-204-RULES-COMPLIANCE.md`, `SWEEP-REVIEW-BD-204.md` — point-in-time sweeps
- **1 ANALYSIS:** `ANALYSIS-BD-204-SHARED-TEST-BOUNDARY.md` — judgment of a then-uncommitted
  change set (HEAD 8572479, dirty tree); the boundary principle it stated is embodied in the
  committed test layout

Execution: the deletion is a user-approved destructive op (US-9) executed in commit C5
(§10); 14 + 93 = 107 ✓. BD-210's later pass inherits a tree already clean of the tracker
subset and the LIVE-classification constraints noted above.

## 9. Restarted Track-2 — disposition table (all 43 non-resolved entries; prior-ruling flags)

Prior Track-2 dispositions are VOID (user). Recommendations below are mine; **the user
decides every row** — rows with a PRIOR user ruling are flagged ⚑ so the user can re-confirm
or change it. Statuses re-verified at HEAD (EE-5). "Refresh" = targeted in-place entry edit
(coder-applied; entry re-scoping is MAJOR per pack-chat-minor-edits-only).

**No-change set (14 — inventory OUT rows, re-confirmed):** BD-020, BD-031, BD-036, BD-037,
BD-055, BD-056, BD-057, BD-058, BD-151, BD-152, BD-153, BD-154, BD-155, BD-201 — no
tracker dependency / no entry-machinery overlap; no edit.

**Fixed by user (4):** BD-204 Deferred ⚑(2026-06-12, fixed), BD-207 Deferred ⚑(fixed),
BD-215 Deferred ⚑(fixed), BD-214 Open until its FINAL step (US-1: the held 213-issue +
49-label deletion runs after C1–C6 on an explicit user GO, then BD-214 flips Resolved).
**US-3 RESOLVED (2026-06-13):** the queued tree-level Blockers-cycle validate-pack check
is RE-ANCHORED from "first Track-2 batch" to **BD-215** (measured: 17 false cycles in the
free-prose format, EE-11). This is documented in BD-215 scope (the cycle validator ships
WITH the format validator) + a dated note on BD-204; both edits land at C6.

**"No version" cluster semantic (US-5).** Deferred-no-version is NOT abandonment. The
deferred tracker cluster — {BD-204, BD-207, BD-215, BD-216, BD-188, BD-212, BD-213} —
all lands TOGETHER with the future tracker-resumption release. Each entry reads "no
release version; lands with the tracker-resumption release." BD-215 is the format-first
gate the whole cluster waits on (format before tracker).

**Recommendations (25):**

| BD | Status | Recommendation | Prior ruling ⚑ / evidence |
|---|---|---|---|
| BD-039 | Open | REFRESH: fix dead `supporting-docs/PM-CHAT.md` ref (→ `project-template/docs/pack/PM-CHAT.md`); write-target wording → per-entry flat-file vocabulary (drop mode-conditional) | — / inventory F1-F2 verified |
| BD-040 | Open | REFRESH: same ref fix; rename the colliding "Procedure 5"; stop-marker + write-channel prose simplifies to flat-file (mirror caveat until BD-206) | — / inventory F1-F3 |
| BD-093 | Open | REFRESH: monolith CHANGELOG refs → `/changelog/v11.md`; drop Mode-3 write-channel split (flat-file only); restate blockers to the live gate set | — / monolith deleted (BD-203) |
| BD-100 | Open | **DEPRECATE + MERGE → BD-205 (US-7 RESOLVED 2026-06-13)** (Deprecate BD-100 with a BD-205 pointer); the 3 carry-forwards (Check 23 persona-contracts gap + 2 contract-note audits) land VERBATIM in BD-205 text. | ⚑ BD-205 already declares the fold / CP windows passed → RESOLVED (US-7) |
| BD-102 | Open | **DEPRECATE (US-7 RESOLVED 2026-06-13):** premise dead twice (pack self-migrated via BD-203/204; tracker deferred — no flat→tracker dogfood exists to run). | ⚑ Batch-23 trio framing (superseded) → RESOLVED to Deprecate (US-7) |
| BD-105 | Open | RE-SCOPE: flat-file STATUS.md entry/phase links only; tracker dual-link half deferred-with-tracker; fix dead doctor path; orbit = BD-206 | ⚑ user ruling was DUAL-MODE links in the BD-206/207 orbit — tracker half voided by the deferral; re-confirm flat-file-only |
| BD-109 | Open | REFRESH: skip-rule restated per-entry flat-file; Check-28 numbering fix; audit subject absorbs BD-211 grammar; drop mode-aware clauses | — |
| BD-110 | Open | REFRESH: audit surface = per-entry tree (flat-file only); drop Mode-3/tracker-health legs + dead BD-100 CP dependency; cadence anchors to BD-205 | — |
| BD-136 | Open | REFRESH: archive path ref; validator count 30→47+ (next ≥51 after this design); symbol anchors for drifted lines; positioning → current gate order; note fixture dir exists | — / mode-independent content stands |
| BD-171 | Open | RE-SCOPE: real-OT v10.3 FLAT-FILE v10→v11 migration harness; DROP all tracker-toggle legs; archive-only disposal; fix dead memory ref. Recommend keep v11.0 (validates the flagship migration) | ⚑ v10.3 re-pin + archive-only are anchored user corrections (applied); Batch-23 framing superseded |
| BD-172 | Open | RE-ANCHOR only (positioning → BD-205); content verified intact | — |
| BD-174 | Open | **DEPRECATE (US-7 RESOLVED 2026-06-13):** no v10-shaped pack exists; multi-toggle purpose was tracker-mode (deferred); the C-7 oracle covered the live surface and rehearsal repos are user-deleted. | ⚑ archive-only correction (moot on deprecation) → RESOLVED to Deprecate (US-7) |
| BD-185 | Open | **SPLIT (US-4 RESOLVED 2026-06-13).** RE-SCOPE flat-file-only, **STAYS v11.0 + in the launch gate.** Flat-file half codifies in scope: phase-parts LIFECYCLE in METHODOLOGY (mid-work expansion mechanism; phase↔part↔task relationships; parts-are-evolution-only; no-renumber-across-transition invariant), execution-notes ordering, STATUS dashboard (SC5), v10→v11 whole-number pass-through (SC8 flat half), validate-pack part/ordering invariants. Delete the dead `Paused:` line; keep the F9-glob KNOWN-GAP anchor note. **HARD CONSTRAINT:** the phase-parts design MUST be DETERMINISTICALLY SERIALIZABLE (structure → one canonical machine-parseable serialization; no free-prose ambiguity; no nondeterministic ordering) — this is what lets BD-215 round-trip phase-parts. **WIRING:** BD-185 → blocks → BD-215. Tracker legs move to NEW BD-216 (row below). NOTE: this entry's RE-SCOPE TEXT lands at C6; the flat-file IMPLEMENTATION is Track B (§10.5), NOT C1–C6. | ⚑⚑ Batch-19d (2026-05-21) + launch-gate BD-203→204→197→185→205 (2026-06-04) — **RECONFIRMED: BD-185 (flat-file half) STAYS v11.0 + launch gate (US-4)** |
| BD-216 | NEW (Deferred, no version) | **AUTHOR a NEW entry (US-4 RESOLVED; next integer confirmed = 216, highest existing is BD-215).** Carries BD-185's TRACKER legs, DEFERRED no-version: work-item.yml Part field + part:M label (SC6), TrackerProvider bi-dir sync of part membership + order (SC7), tracker native execution ordering (P3 / SC4 tracker half), flat→tracker ordering init (SC8 tracker half). BLOCKED on tracker resumption (BD-215 → BD-204/207). BD-216 NAMES BD-185 as its semantic source. "No version" = lands with the tracker-resumption release cluster (US-5 semantic). NOTE: BD-216 is AUTHORED (entry text) at C6; its IMPLEMENTATION is Track B (§10.5). | NEW per the US-4 split (2026-06-13) |
| BD-187 | Open | REFRESH: settled-set basis grew (BD-211 grammar + field-faithful contract); drop tracker-lane adjacency note; v11.1+ stands | ⚑ v11.1+ deferral (2026-05-24) — unchanged |
| BD-188 | Open | **DEFER, no version (US-5 RESOLVED 2026-06-13).** Iteration/Project primitive is tracker-dependent end-to-end; blocked on tracker resumption (BD-215→BD-204/207) + BD-189. **"No version" SEMANTIC: NOT abandonment** — lands with the future tracker-resumption release as ONE cluster {BD-204, BD-207, BD-215, BD-216, BD-188, BD-212, BD-213}. Entry reads "no release version; lands with the tracker-resumption release." | ⚑ v11.1 parking-lot (2026-06-04) → RESOLVED to Deferred no-version (US-5) |
| BD-189 | Open | REFRESH: input pointers `pack-ops/BACKLOG.md` → `/backlog/BD-18x.md`; add no-tracker constraint note (groupings flat-file core proceeds; tracker-projection legs blocked per C7 graceful degradation); BD-210 LIVE-classification constraint noted | ⚑ v11.1 approved scope (2026-06-04) — core stands |
| BD-192 | Open | REFRESH: same pointer fix + BD-210 input-classification note | ⚑ v11.1 approved scope — stands |
| BD-197 | Unblocked | KEEP v11.0; FOLD the git-stash verb-enumeration deferral INTO the entry body NOW (its only anchor is a memory file slated for deletion with the BD-204 cleanup) | ⚑ v11.0 ruling (2026-06-04) stands |
| BD-198 | Open | **RESOLVE (US-7 RESOLVED 2026-06-13):** work landed at cb460e6 (all four AC surfaces verified by the inventory; Status still Open at this HEAD — EE-12); flip with a reconciling `Resolved:` line. | — / RESOLVED to Resolve (US-7) |
| BD-202 | Open | REFRESH: reversal-trigger watch-point → BD-205's audit cycle; note BD-206 changes the asset-class set | ⚑ v11.1 target (2026-06-04) stands |
| BD-205 | Open | REFRESH: re-enumerate gate set (BD-214+Track-2 applications, BD-197, BD-206 if confirmed, BD-210, then BD-093); absorb BD-100 carry-forwards (+ any BD-102/171/174 residue); drop tracker legs from audit scope; keep test-hygiene note | — |
| BD-206 | Open | **CONFIRMED v11.0, FLAT-FILE-ONLY (US-6 RESOLVED 2026-06-13).** RE-SCOPE to flat-file-only project per-entry no-mirror: drop ops-contract R1-R8 mode-conditional folds; KEEP OT-v10.3 census prerequisite, generalized-only guard, scrubbed fixtures, detect.sh repoint, client `[mirror]` retirement in Check 29, tracker-mirror.sh client legs. **SAME treatment as BD-203 — DELETE the project monoliths (BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md) for converted streams, NO regenerated mirror.** **`_order.md` FINDING:** the flat-file execution-ordering support-file `_order.md` is PREDESIGNED but UNBUILT (zero `_order.md` files exist — measured); BD-206 must CREATE it for the project implementation-plan stream (phase order is NOT numerically recoverable, unlike `/backlog/`); if the predesign conflicts with the BD-203 as-built per-entry shape, the predesign is UPDATED to match BD-203. **This is Track-B work — the entry RE-SCOPE TEXT lands at C6; the conversion + `_order.md` IMPLEMENTATION is Track B (§10.5), NOT designed here.** | ⚑ Target was "TBD — likely v11.0"; BD-207 forcing voided → CONFIRMED v11.0 flat-file-only (US-6) |
| BD-210 | Open | REFRESH: blocker set → (BD-214 unified plan, BD-206, BD-197, near/with BD-205); record that BD-214 already deleted the 93 tracker-churn docs; BD-189/192 + ARCHITECTURE-V3.md §28.1 LIVE-classification constraints | — |
| BD-212 | Open | **DEFER, no version (US-5 RESOLVED 2026-06-13).** A reset verb presupposes tracker mode; the one live need (delete 213 issues once) is covered by §7's held mechanics (now BD-214's FINAL step, US-1). Research doc KEEPS as resumption input. Lands with the tracker-resumption release cluster (US-5 semantic). | ⚑ v11.0 target (2026-06-11) → RESOLVED to Deferred no-version (US-5) |
| BD-213 | Open | **DEFER, no version (US-5 RESOLVED 2026-06-13).** Rides BD-207 + BD-212, both deferred. Lands with the tracker-resumption release cluster (US-5 semantic). | ⚑ v11.0 target (2026-06-11) → RESOLVED to Deferred no-version (US-5) |

Inventory §6 new-BD candidates, resolved: (1) F9 phase-glob defect — tracker-only, latent;
anchored by the in-code `KNOWN GAP` comment + a BD-185 deferral note; NO new BD. (2) OQ-A
edit/new-entry verbs — landed in `pack-tracker.sh` (dispatcher verified); moot/dormant.
(3) BD-197 git-stash anchor — folded into BD-197 (row above).

## 10. Commit sequencing (constraints the planner must honor)

Invariants on EVERY commit: full CI battery green (validate-pack + integration
`test-v11-*.sh`); trinity parity edits land in the SAME commit as their trinity location;
`test-fixtures/manifest.txt` regenerated when the diff touches `project-template/`,
`scripts/`, `pack-ops/`, or `supporting-docs/`; scope keywords only where the diff
qualifies (Check 36); flat-file behavior never broken at any boundary.

| # | Commit | Contents | Keyword | Manifest |
|---|---|---|---|---|
| C1 | flip-block code | tracker-config clamp; pack-tracker init + enable-recommendations gates; tracker-migrate forward gate; override exports in tracker/recommendation test scripts; gate tests; pack-td advisory typo | pack-only | yes |
| C2 | guards + CI | Check 51 (+test, wired); Check 50 dedicated test (+wired); **Node-24 actions bump** (lines 88/91/109/112) — MUST land before 2026-06-16 | pack-only | yes |
| C3 | pack-side surface sweep | root trinity ×3 (parity in-commit); PACK-CHAT.md; backlog/_rules + _intro; changelog/_rules; pack-ops fragments/OPTIONAL-FEATURES/MERGE-STRATEGY/etc.; QUICKSTART; README rows; pack-startup Step 8 ×3; PACK-MEMORY-RATIONALE; BOUNDARY-DEFINITION; **`changelog/v11.md` block reword — coder applies the LITERAL old→new text in §6.6 (US-2 RESOLVED)**; lock-step test edits (pack-help-test.sh etc.) | pack-only | yes |
| C4 | project-side + installers | init-project.sh S11 + install map; migrate-v10-to-v11.sh example-copy removal + post-report wording; Checks 39/41/46 re-pins (SAME commit); project trinity ×3; PM-CHAT; project OPTIONAL-FEATURES + fragments; pm-startup ×4; prompts ×5; project _intro ×3; DEPENDENCIES + MIGRATION + METHODOLOGY; lock-step tests (test-init-project, gates test, translations) | (none — mixed) | yes |
| C5 | maintenance-docs deletion | the 93 DELETE files (§8; user approval US-9; deletions executed by Pack Chat per per-action-approval) | pack-only | no |
| C6 | Track-2 entry applications (TEXT only) | `/backlog/` entry edits per §9 (coder-scoped; MAJOR edits) + `_toc.md` regen. Carries **Track-A MECHANICAL entry work + the entry RE-SCOPE TEXT only** (decided scope + constraints + pointers), NEVER Track-B implementation: deprecations (BD-102/174), BD-198 Resolve, BD-100→BD-205 merge, pointer/ref fixes, status flips, **AUTHOR new BD-216** (tracker legs, deferred no-version; names BD-185 as semantic source), **BD-185 re-scope** (flat-file-only + deterministic-serializability constraint + `Paused:`-line delete + BD-185→blocks→BD-215 wiring), **BD-206 re-scope** (v11.0 flat-file-only + monolith-delete + `_order.md` create/reconcile directive — TEXT), **BD-215 scope** (cycle validator ships WITH the format validator, US-3) + a **dated note on BD-204** re-anchoring the cycle check to BD-215 (US-3) + the BD-188/212/213 deferred-no-version cluster flips (US-5). | pack-chat-only | no |

Ordering rationale: C1/C2 first so every later commit is guarded (and Node-24 beats its
deadline); C3 before C4 keeps each sweep reviewable; the validator re-pins in C4 are
atomic with the install-map change (enumerate-encoding-surfaces); C5 independent; C6 last so
entry text can reference the landed state. Each commit takes the standard per-commit bounded
review/fix cycle. **BD-214 status (US-1 RESOLVED 2026-06-13):** BD-214 stays Open through
C1–C6; its FINAL step is the held 213-issue + 49-label deletion (§7 / US-8), run after
C1–C6 on an EXPLICIT user GO; BD-214 flips Resolved only after that deletion completes.
The 93-doc deletion (US-9) executes at C5 (Pack-Chat-executed; final list surfaced at the
C5 gate). **Track B (BD-185 flat-file build, BD-206 conversion + `_order.md`, BD-216) is
carved OUT of C1–C6 — see §10.5.**

## 10.5 Track A / Track B carve-out (user decision 2026-06-13)

The work this design governs splits into TWO tracks. **This design and its C1–C6
plan are TRACK A only.** The phase-parts/ordering IMPLEMENTATION is TRACK B and gets
its OWN research-first pipeline AFTER C6.

**Track A (this design → planner → C1–C6).** The tracker-deferral cleanup
(flip-block, artifact-strip, surface-sweep, validators, doc-deletion) + the
MECHANICAL Track-2 entry edits: deprecations (BD-102/174), BD-198 Resolve, BD-100→
BD-205 merge, pointer/ref fixes, status flips, BD-216 authoring, and ALL entry
re-scope TEXT (decided scope + constraints + pointers). C1–C6 write the
BD-185/BD-206/BD-216 ENTRY re-scope text but NOT their implementation.

**Track B (own docs-researcher → architect pipeline, AFTER C6 — NOT designed here).**
The phase-parts/ordering IMPLEMENTATION:
- **BD-185 flat-file build** — codify the phase-parts lifecycle in METHODOLOGY,
  execution-notes ordering, STATUS dashboard, v10→v11 whole-number pass-through,
  validate-pack part/ordering invariants. Track-B pipeline INPUT: the design MUST be
  DETERMINISTICALLY SERIALIZABLE (one canonical machine-parseable serialization; no
  free-prose ambiguity) so BD-215 can round-trip phase-parts.
- **BD-206 conversion + `_order.md`** — convert the project streams to per-entry
  no-mirror (DELETE project monoliths, no regenerated mirror) AND **CREATE the
  `_order.md` flat-file execution-ordering support-file** for the project
  implementation-plan stream. Track-B pipeline INPUTS (recorded, not designed):
  (a) `_order.md` is PREDESIGNED but UNBUILT — zero `_order.md` files exist in the
  tree today (measured; the predesign lives in ARCHITECTURE-BD-185-V2.md §5.3,
  ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md §A-1, and
  ARCHITECTURE-BD-203-V3-AMENDMENT.md §F.3 "`_order.md` if ever used"); (b) phase
  order is NOT numerically recoverable from filenames the way `/backlog/` BD-NNN
  ordering is — hence the support-file is REQUIRED for the implementation-plan
  stream; (c) **if the predesign conflicts with the BD-203 as-built per-entry shape
  (flat tree + generated `_toc.md`, audience+purpose meta-doc governance per
  ARCHITECTURE-BD-203-V3-AMENDMENT.md §F), the predesign is UPDATED to match
  BD-203** (BD-203 as-built wins).
- **BD-216** — the tracker legs (work-item Part field, TrackerProvider part/order
  sync, tracker native ordering, flat→tracker ordering init), deferred no-version
  with the tracker-resumption cluster (blocked on BD-215 → BD-204/207).

**Carve-out boundary.** C1–C6 NEVER touch Track-B implementation surfaces
(METHODOLOGY phase-parts mechanism, the project-stream conversion tooling,
`_order.md`, work-item Part field). The Track-B pipeline is sequenced after C6 with
its own docs-researcher (blast-radius enumeration) → architect → planner → coder. The
`_order.md` finding + the reconcile-to-BD-203 directive + the
deterministic-serializability constraint are the INPUTS that future pipeline
consumes; this design does NOT pre-design that pipeline.

## 11. User-decision queue — ALL RESOLVED (2026-06-13)

All nine decisions are FIXED by the user. The "Outcome" column records each ruling
and where this design applies it. (These are not re-litigated — applied verbatim.)

| # | Decision | Outcome (RESOLVED 2026-06-13) — where applied |
|---|---|---|
| US-1 | BD-214 close gate vs the HELD GH deletion | **RESOLVED.** The held 213-issue + 49-label deletion is BD-214's **FINAL step** — runs after commits C1–C6 on an explicit user GO, then BD-214 flips Resolved. **BD-214 stays Open until then.** Applied: §7 anchor, §9 "Fixed by user" block, §10 ordering rationale. |
| US-2 | `changelog/v11.md` unreleased-block reword (tracker = deferred/dormant) | **RESOLVED — approved.** Reworded to "tracker = deferred/dormant, flat-file = the v11.0 model." Applied by a **CODER at C3**; the architect supplies the LITERAL old→new replacement text (§6.6) and does NOT edit the changelog. |
| US-3 | Re-anchor the queued Blockers-cycle check | **RESOLVED — re-anchor to BD-215** (measured: 17 false cycles in free-prose format, EE-11). Documented in **BD-215 scope** (cycle validator ships WITH the format validator) + a **dated note on BD-204**; both land at C6. Applied: §6.4, §9, §10 C6 line. |
| US-4 | BD-185 disposition | **RESOLVED — SPLIT.** BD-185 RE-SCOPED flat-file-only, **STAYS v11.0 + in the launch gate** (METHODOLOGY phase-parts lifecycle, execution-notes ordering, STATUS SC5, v10→v11 whole-number pass-through SC8-flat, validate-pack invariants; delete dead `Paused:` line). NEW **BD-216** (next integer, confirmed) = the tracker legs, deferred no-version. HARD CONSTRAINT: BD-185 design DETERMINISTICALLY SERIALIZABLE. WIRING: BD-185 → blocks → BD-215. Applied: §9 BD-185/BD-216 rows, §10.5, §10 C6. |
| US-5 | BD-188 / BD-212 / BD-213 → Deferred, no version | **RESOLVED — all three Deferred no-version.** "No version" SEMANTIC: NOT abandonment — lands with the future tracker-resumption release as ONE cluster {BD-204, BD-207, BD-215, BD-216, BD-188, BD-212, BD-213}. Entries read "no release version; lands with the tracker-resumption release." Applied: §9 rows + cluster-semantic note. |
| US-6 | BD-206 confirmed v11.0 (flat-file-only) | **RESOLVED — CONFIRMED v11.0, flat-file-only.** SAME treatment as BD-203 — DELETE the project monoliths (BACKLOG/IMPLEMENTATION-PLAN/CHANGELOG), NO regenerated mirror. **FINDING:** `_order.md` predesigned-but-unbuilt; BD-206 must CREATE it for the project implementation-plan stream (phase order not numerically recoverable); reconcile predesign → BD-203 as-built if it conflicts. This is **Track B** (recorded, not designed). Applied: §9 BD-206 row, §10.5. |
| US-7 | BD-102/174 Deprecate; BD-100 merge→BD-205; BD-198 Resolve | **RESOLVED — approved.** BD-102 Deprecate; BD-174 Deprecate; BD-100 Deprecate+merge into BD-205 (3 carry-forwards land VERBATIM in BD-205: Check 23 persona-contracts gap + 2 contract-note audits); BD-198 Resolve (cb460e6, all 4 AC verified). Applied: §9 rows; entry TEXT at C6. |
| US-8 | The 49 pack-managed labels delete | **RESOLVED — delete WITH the held 213-issue deletion** (one run, same GO). Part of BD-214's FINAL step (US-1). Applied: §7 step 6. |
| US-9 | The 93-file maintenance-docs deletion | **RESOLVED — delete at commit C5** (Pack-Chat-executed; final list surfaced at the C5 gate). Applied: §8, §10 C5 line. |

## 12. Out-of-scope discoveries (surfaced, untouched)

1. **Check 23 persona-contracts gap** — `check_help_fragment_completeness` still iterates
   top-level `scripts/` only; BD-100 carry-forward (a); lands via the BD-205 merge (§9).
2. **Census CI-step count** — 16 stated, 17 measured (EE-10); corrected here, census file
   left untouched (it is a committed-state-accurate-enough input; this doc is the record).
3. **Stale Pack-Chat memory files** — `project_bd204_cycle_position.md` ("delete after
   BD-204 C-8" — C-8 abandoned), `project_bd204_c46_last_redesign.md`, and the Mode-3
   remainder of `project_pack_self_migration_launch_gate.md` are stale post-deferral.
   Out-of-repo Pack-Chat state; housekeeping note only (after BD-197's stash item is folded
   per §9, nothing in-tree depends on the cycle-position memory).
4. **EE-11 as BD-215 evidence** — the 17 prose-induced false cycles are direct empirical
   support for BD-215's structured-Blockers requirement; worth citing in the future BD-215
   design (no entry edit made here).
5. **`gh`/`gh-sub-issue` dependency weight** — with tracker deferred, the only live `gh`
   consumers are tests' live legs and the held deletion; DEPENDENCIES.md is UPDATE-scoped
   here, but a future slimming decision (drop gh-sub-issue from required deps) belongs to
   BD-210/BD-205-era review.

## 13. Architect-doc-vs-reality reconciliation (rule 10)

- `ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` (+2 amendments): KEPT as the dormant as-built
  contract; this design SUSPENDS its operational force (the clamp makes Mode 3 unreachable)
  without superseding its content — the §3 deferral notes in `backlog/_rules.md` and trinity
  point at the deferral, not at a rewrite of the contract. No addendum is added to the
  contract docs themselves (they describe dormant code accurately as-is; adding live-state
  notes to dormant references invites drift).
- `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` anticipation of "CI guard ... every push" (Check 49)
  is reconciled by D-E: the guard stays, DEEP-gated, as the dormant-health proof.
- The deleted PLAN/REVIEW/IMPL set (§8) is superseded-doc deletion under fail-loud — the
  reconciliation IS the deletion.
- This design realizes BD-214's census anticipation (`RESEARCH-TRACKER-DEFERRAL-CENSUS.md`
  §12 BD-214/BD-215 line) — confirmed: nothing in §4 Axis A bleeds into BD-215; the format
  is untouched.

## 14. Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git rev-parse HEAD`, `git status --short`, `git log --oneline -5`, `git diff backlog/BD-214.md` — all read-only. Zero `add/commit/push/tag/reset/stash/checkout` invocations. | COMPLIANT |
| 2. Read-only mandate | Sole writes: 3 chunked `cat >`/`cat >>` of THIS file at the prompt-specified path. `gh` calls: 2, both read-only (`gh api search/issues` count, `gh label list`). Zero mutations, zero deletions, zero other file edits. | COMPLIANT |
| 3. Empirical-Evidence Blocks | EE-1..EE-12 (§1) each carry command, verbatim output (counts/paths/cycle list), HEAD `0027b10` + date 2026-06-12, interpretation, conclusion. Census numbers independently re-measured where load-bearing: 13,053 code lines (EE-1), 15,334 test lines + no check-50 test (EE-2), 107 docs (EE-3), 213 issues / 49 labels (EE-4), CI steps corrected 16→17 (EE-10), entry grep-zero (EE-8), backlog states (EE-5). | COMPLIANT |
| 4. CI guard measure-then-bound | Check 51 (§6.3): every leg measured against the live tree (leg 3: 7 STRIP occurrences enumerated with fix-recipe; leg 4: 0 with line-anchor, empty allowlist; leg 5: 1 STRIP at init-project.sh:1250); allowlists sized exactly; post-fix clean state projected per leg. The queued cycle check was measured (EE-11: 17 false positives) and REJECTED as a gate rather than allowlisted — measure-then-bound's negative branch. | COMPLIANT |
| 5. Preliminary triage challenged | §2 lists 9 census ARCH?/preliminary rows individually resolved, incl. 2 OVERTURNS (S11 toml install → SKIP; v11.md → UPDATE) and 1 count correction (16→17); all 21 KEEP-DORMANT code rows challenged, none overturned (evidence: structured, provider-routed, 15,334 test lines, user return-path). Boundary-touching calls (S11, fragments, sanctioned set) held to the high bar — §5 ships NOTHING new, `_SANCTIONED_PACK_SIDE_SHIPPED` untouched. | COMPLIANT |
| 6. No pattern-matching out of context | Each design choice argued by property-fit: clamp at `tracker_mode()` because EE-6 proves it is the measured single chokepoint (not "checks-go-in-validate-pack" reflex); fragment REWRITE (not delete) because Checks 22/23 + pack-help-test pin the mechanism; one-shot /tmp deletion script (not a committed verb) because BD-212 is deferred; Check 48 basename set deliberately NOT grown (advisory noise vs gate value). | COMPLIANT |
| 7. Fail-loud on superseded docs | §8: 107/107 dispositioned, 14 KEEP each with a named resumption/as-built rationale, 93 DELETE by churn class — no archive, no prison; dangling-citation consequence accepted explicitly (Check 48 advisory-only, set not grown). | COMPLIANT |
| 8. Deferral discipline | User-authorized deferrals honored as fixed (BD-204/207/215, held deletion). Every NEW deferral recommendation is flagged for user decision with evidence: US-4 (BD-185 — BLOCKED tracker legs + not-launch-blocking remainder evidence), US-5 (BD-188/212/213 — BLOCKED on deferred tracker; BD-212's live need covered by §7). Nothing silently deferred; everything else lands in the v11.0 plan (§10). | COMPLIANT |
| 9. Dependency-direction | §5: sanctioned set verified unchanged (`{scripts/lib/detect.sh, scripts/pack-help.sh}` — quoted from trinity); no new pack-side file ships; client deliverables (fragment stub) stay on their existing project-side authoritative path; the removed install is a SHRINK, not a move. | COMPLIANT |
| 10. Architect-doc reconciliation | §13: 4 reconciliations named (ops contract suspended-not-superseded; LOSSLESS-FIX Check-49 anticipation → D-E; PLAN/REVIEW deletion = the reconciliation; census §12 line confirmed). | COMPLIANT |
| 11. Rules-Applied Verification Block | This table; 12 rows, one per prompt rule; every evidence cell carries a concrete measurement or section pointer with content; zero empty cells. | COMPLIANT |
| 12. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: design complete; about to Write /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` in the turn immediately before the first write chunk. No stop/halt/revert message received at any point. | COMPLIANT |

Read-in-full attestation: every file on the prompt's mandatory list was opened directly via
the Read tool this session — CLAUDE.md (591 lines incl. full `## Pack memory`),
RESEARCH-TRACKER-DEFERRAL-CENSUS.md (423), RESEARCH-REBASELINE-INVENTORY.md (659),
project_tracker_deferred_indefinitely.md (61), backlog/BD-214.md (15 + working-tree note via
`git diff`), BD-215.md (16), BD-204.md (37), BD-207.md (19), backlog/_rules.md (152),
changelog/_rules.md (77), BD-212.md (52), BD-213.md (33), BD-185.md (50), BD-188.md (34);
plus RESEARCH-BD-212-GH-ISSUE-DELETION.md (280 — relied on for §7) and the four named skills
(architecture-review, planning, documentation, commit-discipline SKILL.md, complete). No
named document was derived rather than read.


---

## 14a. Update-pass Rules-Applied Verification Block (2026-06-13 targeted update)

This addendum covers the 2026-06-13 targeted in-place update (US-1..US-9 + BD-185
split + `_order.md` finding + Track A/B carve-out). The §14 block above stands for
the original design; this block covers the update edits only.

| Rule (update prompt) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Update-pass git verbs: `git rev-parse HEAD` (read-only). Zero `add/commit/push/tag/reset/stash/checkout`. | COMPLIANT |
| 2. Edit in place, not full rewrite | Edits applied via anchored single-occurrence string replacements (each `assert count==1`): Update-log insert; §0 D-J′ row + queue line; §6.6 literal block insert; §9 BD-185 split → BD-216 row, BD-188/206/212/213/100/102/174/198 rows, fixed-by-user block; §10 C3/C6 lines + ordering rationale; §10.5 insert; §11 table rewrite (the queue table — the one section legitimately replaced, content preserved as outcomes). Section map confirmed intact below (§0–§14 all present + §6.6, §10.5, §14a added; none dropped). NOT a full rewrite. | COMPLIANT |
| 3. Empirical-Evidence Blocks (new state-claims) | (a) Next integer = BD-216: `ls backlog/BD-*.md | grep -oE 'BD-[0-9]+' | sort -t- -k2 -n | tail -3` → `BD-213 / BD-214 / BD-215`; `ls backlog/BD-216.md` → "No such file or directory"; HEAD `0027b10`, 2026-06-13 → SUPPORTED (216 is next). (b) `_order.md` predesigned-but-unbuilt: `find . -path ./.git -prune -o -name '_order.md' -print` → EMPTY (zero built files); `grep -rn '_order\.md'` → refs in ARCHITECTURE-BD-185-V2.md §5.3, ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md §A-1, ARCHITECTURE-BD-203-V3-AMENDMENT.md §F.3 ("`_order.md` if ever used") → SUPPORTED (designed, never created). (c) project implementation-plan stream lacks `_order.md`: `ls project-template/docs/project/implementation-plan/_*.md` → `_intro.md _rules.md` only → SUPPORTED. (d) `changelog/v11.md` current text: Read lines 4-6 → `### v11.0 — Issue-tracker integration + customization-preservation fix` / blank / `**Scope A — Issue-tracker integration (D-1..D-23)**`; BD-093 release-pin still in "Carried over to future work" (line 88) → SUPPORTED (block is unreleased). HEAD `0027b10`, 2026-06-13. | COMPLIANT |
| 4. Fixed decisions honored; conflicts surfaced | All nine decisions applied verbatim (§11 outcomes). No silent alteration. Surfaced observation: US-2 wording — `changelog/v11.md` v11.0 block is technically RELEASED-style prose but UNRELEASED (BD-093 pin pending); the §6.6 reword preserves the D-1..D-23 inventory as a dormant record rather than deleting history, and instructs the C3 coder to surface drift rather than force-apply. No decision changed. | COMPLIANT |
| 5. Fail-loud superseded docs (§8 unchanged) | §8 partition (14 KEEP / 93 DELETE) NOT altered by this update. `grep` confirms §8 body untouched. | COMPLIANT |
| 6. Architect-doc-vs-reality reconciliation | Named: the `_order.md` predesign (ARCHITECTURE-BD-185-V2.md / -ORDERING-ADDENDUM / BD-203-V3-AMENDMENT) is reconciled — recorded as predesigned-but-unbuilt with a "reconcile predesign → BD-203 as-built if it conflicts" directive routed to Track B (§10.5). BD-185 entry's anticipated tracker legs reconciled into new BD-216. | COMPLIANT |
| 7. Deferral discipline | Track B deferral is the user's explicit carve-out (recorded §10.5). BD-216/188/212/213 deferrals are the user's US-4/US-5 rulings. Nothing else silently deferred — the flat-file BD-185 half STAYS v11.0, BD-206 CONFIRMED v11.0. | COMPLIANT |
| 8. Rules-Applied Verification Block | This table (8 rows + read-attestation + section-map). Every evidence cell carries a concrete measurement or anchored section pointer; zero empty cells. | COMPLIANT |
| 9. PREFLIGHT + STOP-MEANS-STOP | `PREFLIGHT: update complete; section map confirmed intact; about to finalize` emitted in the message immediately before this finalization. No stop/halt/revert received. | COMPLIANT |

**Read-in-full attestation (update pass).** Read directly this pass: CLAUDE.md
(full, incl. `## Pack memory`); ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md (full, both
pages — 653 original lines, every section mapped); ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md
(full, 740 lines — characterized the `_order.md` predesign; NOT redesigned);
ARCHITECTURE-BD-203-V3-AMENDMENT.md (full, 245 lines — the as-built per-entry shape
`_order.md` must reconcile to); backlog/BD-185.md (50), BD-204.md (37), BD-206.md
(15), BD-207.md (19), BD-215.md (16). No named document was derived rather than read.

**Section-map confirmation (before → after).**
- BEFORE (original doc): §0, §1, §2, §3, §4, §5, §6 (6.1–6.5), §7, §8, §9, §10, §11, §12, §13, §14.
- AFTER (this update): Update log (new, top) + §0, §1, §2, §3, §4, §5, §6 (6.1–6.5 **+ 6.6 new**), §7, §8, §9, §10, **§10.5 (new)**, §11, §12, §13, §14, **§14a (new)**.
- Every original section is PRESENT and unmodified except the explicitly-edited ones (§0, §6 pointer + §6.6, §9, §10, §11, §14a). §1–§5, §7, §8, §12, §13, §14 are UNCHANGED. No section dropped.

**End of ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md**
