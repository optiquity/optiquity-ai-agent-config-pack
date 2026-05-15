# PACK-REVIEW-BD-107 — TD-NNN promotion-path tooling (Path 1 + Path 2 + direct close)

**Reviewer scope:** BD-107 (working tree since `f209b04`)
**Reviewer:** pack-reviewer (per-BD, no prior reviews; experiment 2026-05-15)
**Date:** 2026-05-15

## Summary

Clean-with-MUSTs. The implementation is structurally sound: V3.3 §3 / §7
spec compliance is high, Path 3 invariants are robust (verified by 5
grep-style assertions in the test suite, all passing), trinity-style
parity between pack-root and project-template HELP-FRAGMENT-TRACKER.md
is byte-identical (validate-pack Check 24 OK), §6.P architect-default
is correctly codified in PM-CHAT.md, and all 140 test assertions pass
across the three new test scripts. The validate-pack.py CI suite reports
clean (`PASSED — all checks clean`).

However, three production-correctness concerns surface that should be
addressed before merge: (1) the dispatcher (`scripts/pack-td.sh`) runs
under `set -euo pipefail` and crashes with bash-internal "unbound
variable" errors when value-bearing flags are passed without values
(bypasses the otherwise consistent typed-error pattern); (2) Path 1's
idempotency check uses a permissive substring match on the target token,
which produces false positives when phase numbers share a prefix
(e.g. `phase-7` matching a prior `phase-72` Resolution); (3) tracker-mode
promotion creates dynamic `derived-from:TD-NNN` and `promoted-to:phase-N`
labels via `provider_create` / `provider_set_labels` without
pre-creating them on the GitHub repo — modern `gh` CLI rejects unknown
labels at issue-create/edit time, so production tracker-mode flows are
likely to fail; the orchestrator masks the failure via `|| true`.

Counts by severity: BLOCKER 0 / MUST 3 / SHOULD 5 / NIT 5.

## Findings

### Finding F1
- **Severity:** MUST
- **Location:** `scripts/pack-td.sh:111,112,114,189`
- **Title:** Dispatcher crashes with bash-internal "unbound variable" error on value-less flags under `set -u`
- **Description:** `scripts/pack-td.sh` declares `set -euo pipefail` (line 34). The argument parser uses `shift 2` for the value-bearing flags `--to` (line 111), `--repo-root` (line 112), `--store-path` (line 114), and `--note` (line 189) without guarding against a missing `$2`. Reproducer:

  ```
  $ ./scripts/pack-td.sh promote --to
  /Users/.../scripts/pack-td.sh: line 111: $2: unbound variable
  ```

  This bypasses the otherwise consistent `tracker_error_emit "validation" "..."` pattern used everywhere else in this dispatcher and produces an internal-looking diagnostic rather than the typed error block downstream tools (PM Chat error renderer; CI test harness) expect. Verified on the actual binary in four call sites: `--to`, `--repo-root`, `--store-path`, and `cmd_resolve`'s `--note`.

- **Suggested fix:** Replace `--to)               target="$2"; shift 2 ;;` with `--to)               [[ $# -lt 2 ]] && { tracker_error_emit "validation" "promote: --to requires a value"; return 1; }; target="$2"; shift 2 ;;` and apply the same guard at `--repo-root`, `--store-path`, and `--note`. Alternative: pre-flight check `[[ $# -ge 2 ]]` at the top of each value-bearing branch. Either keeps the typed-error contract intact.
- **Source:** V1 §9 / D-7 typed-error pattern (every dispatcher surface emits via `tracker_error_emit`); pack-memory rule that error UX is uniform across the verb surface.

### Finding F2
- **Severity:** MUST
- **Location:** `scripts/lib/tracker-promote.sh:575`
- **Title:** Path 1 idempotency check uses permissive substring match that false-positives across phase-number prefixes
- **Description:** The duplicate-run guard at line 575 reads `if [[ "$existing_resolution" == *"$target"* ]] && [[ -f "$plan_path" ]] && grep -qE "^## Phase $phase_n " "$plan_path" 2>/dev/null`. The `*"$target"*` substring glob is too permissive: a TD whose Resolution names `phase-72` will substring-match a fresh `target=phase-7` invocation. In a long-running project with both phase-7 and phase-72 sections in the plan (which is the realistic v11 use case — the M-allocator already supports `phase-103`, tests cover it), the `grep -qE "^## Phase $phase_n "` second clause does anchor on `^## Phase 7 ` (with trailing space) which prevents the broader plan-file false-positive, but the first clause (Resolution substring) still false-fires. The compound `&&` is only as tight as its loosest clause from the user's perspective: if both prefix-matching phases exist in the plan AND the TD already has a "promoted to phase-72" Resolution, line 575 refuses a legitimate `--to=phase-7` promotion.
- **Suggested fix:** Tighten the substring match to a right-anchored form: replace `*"$target"*` with `*"to $target]"*` (matching the canonical Resolution emit shape `[YYYY-MM-DD, completed, promoted to phase-N]`). Or use regex: `[[ "$existing_resolution" =~ promoted\ to\ $target\] ]]`. Either eliminates the prefix-collision class. Test 3.4 currently passes because the fixture has only phase-7 — add a `phase-72` companion to lock the regression.
- **Source:** V3.3 §3.3 "Round-trip safety" contract — the idempotency guard must not refuse legitimate distinct-phase promotions; ARCHITECTURE-V3.3-DELTA.md:152.

### Finding F3
- **Severity:** MUST
- **Location:** `scripts/lib/tracker-promote.sh:636,847,651,930`
- **Title:** Tracker-mode promotion emits dynamic labels (`derived-from:TD-NNN`, `promoted-to:phase-N`) without ensuring they exist on the GH repo; failures silently swallowed
- **Description:** `tracker_labels_canonical_set` enumerates the static label family (`phase-epic`, `phase-task`, `template:phase-*`, status:*, severity:*, etc.) and `tracker_labels_ensure` (called only from `tracker-init.sh`) creates them via `gh label create`. The two dynamic per-entity labels BD-107 emits (`derived-from:TD-NNN` and `promoted-to:phase-N`) are NOT in the canonical set (by design — they're per-entity). When `provider_create` (line 637, 848) issues `gh issue create --label derived-from:TD-031,...` against a real GitHub repo, `gh ≥2.x` validates labels against the repo's label set and rejects unknown labels with exit code 1. Similarly, `provider_set_labels` at line 650 / 929 runs `gh issue edit --add-label promoted-to:phase-7` which fails identically. The orchestrator masks the failure with `>/dev/null 2>&1 || true` at lines 651 / 930 (label-set on the TD), so a production tracker-mode promotion would: succeed at `provider_create` for the new phase entity (assuming auto-create label fallback in older gh) OR fail with a hard error, then silently swallow the TD-close label update. The stub-backend tests do not exercise the missing-label code path; tests pass while production would fail.
- **Suggested fix:** Two options. (a) Call `_tracker_labels_create "$derived_label"` and `_tracker_labels_create "$promoted_label"` immediately before each `provider_create` / `provider_set_labels` invocation in `tracker_promote_path1` and `tracker_promote_path2`. Idempotent and matches the existing `gh label create --force` pattern. (b) Extend `tracker_labels_ensure` to take a dynamic-label-list argument and call it from the promotion library; cleaner separation but more change surface. (a) is the minimum-viable fix. Either way: remove the `>/dev/null 2>&1 || true` masking from lines 651-652 and 929-931; surface real failures via `tracker_error_emit "partial-write"`.
- **Source:** ARCHITECTURE-V3.3-DELTA.md §3.3 step 2 ("provider.create() with labels …, derived-from:TD-NNN") + §3.4 step 5 ("status:resolved + promoted-to:phase-N.M labels") — the spec requires these labels to actually be applied, not silently skipped on failure; V1 §9.6 partial-write error pattern.

### Finding F4
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-promote.sh:542-677` (Path 1) and `:706-957` (Path 2)
- **Title:** Library does not mutate BACKLOG.md; user invoking the verb directly leaves the TD in `Status: Open` with stale Resolution
- **Description:** V3.3 §3.3 step 3 reads "PM Chat re-keys the original TD-NNN: status flips to `Resolved`; Resolution field set to `[YYYY-MM-DD, completed, promoted to phase-N]`." The library deliberately does NOT mutate BACKLOG.md (per comment at lines 600-605: "delegated to PM Chat per the workflow rule… library returns the patch shape so PM Chat can apply it"). It emits `resolution_text` in the JSON result as a patch. This is a defensible PM-Chat-owns-BACKLOG seam — but a user invoking `pack td promote` directly via shell (not via PM Chat) gets IMPLEMENTATION-PLAN updated and tracker entity created BUT no BACKLOG mutation. The TD remains `Status: Open`, the Resolution stays `n/a`, and the next `pm-startup` Procedure-1 gate-check will re-surface the same TD as still-unblocked. The verb's behavior is asymmetric: tracker side advances, flat-file BACKLOG does not.
- **Suggested fix:** Two options. (a) Emit a warning to stderr in the library when invoked outside a PM-Chat session, with the patch text rendered as a copy-pasteable sed/awk recipe. (b) Add a `--apply-backlog-patch` flag to the dispatcher (default off; PM Chat passes it implicitly) that performs the BACKLOG mutation. Either lets the user understand or close the loop. The cleaner option is (b) with the flag defaulting to "on" when invoked via the dispatcher (i.e. the human-facing path), since PM Chat could pass `--no-apply-backlog-patch` when it intends to apply via its own editor. Document the asymmetry in the IMPLEMENTATION-REPORT call-out 5 (idempotency) or open a new call-out.
- **Source:** ARCHITECTURE-V3.3-DELTA.md §3.3 step 3 + §3.4 step 5 — the spec lists BACKLOG mutation as an explicit forward step.

### Finding F5
- **Severity:** SHOULD
- **Location:** `README.md:185-208` (Repository Layout section)
- **Title:** README Repository Layout missing `pack-td.sh`, `tracker-promote.sh`, and the BD-106/108 sibling libraries
- **Description:** The pack-memory rule "README layout. If files are added, moved, or removed, verify the Repository Layout section in README.md is updated" applies. BD-107 adds two new top-level files (`scripts/pack-td.sh`, `scripts/lib/tracker-promote.sh`) that are user-facing entry points (the dispatcher is referenced from `HELP-FRAGMENT-PACK.md`). The README's `scripts/` and `scripts/lib/` block at lines 185-208 does not list them. Pre-existing context: BD-106 added `scripts/lib/tracker-phase-task.sh` and BD-108 added `scripts/lib/tracker-cycle-check.sh` + `scripts/lib/tracker-links.sh` — none of those appear in the README either. BD-107 inherits responsibility for at least its own additions; the BD-106 / BD-108 omissions are pre-existing batch-17 debt but worth flagging together.
- **Suggested fix:** Add to README.md:
  - Line 186 area: `├── pack-td.sh                                 TD orchestration — promote (Path 1/2) / resolve (direct close per V3.3 §3) (v11)`
  - Line 202 brace list: extend to `tracker-{config,init,labels,errors,sidecar,mirror,agent-read,phase-task,cycle-check,links,promote}.sh` (or add new bullets for the BD-106/107/108 additions).
- **Source:** Pack-memory rule on README layout.

### Finding F6
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-promote.sh:636,847`
- **Title:** jq filter interpolates `$phase_n` via shell string-concatenation rather than `--arg`
- **Description:** Line 636 reads `'{title: $t, body: $b, labels: ["phase-epic", "phase-'"$phase_n"'", "template:phase-epic-v11.0", $dl]}'`. The `'"$phase_n"'` form interpolates a bash variable into the jq filter via string concatenation. `phase_n` is captured from `BASH_REMATCH[1]` against `^phase-([0-9]+)$` so the value is regex-constrained to digits-only and the interpolation cannot inject jq syntax in practice. But it deviates from the rest of the file's `--arg` discipline (every other variable in this very expression uses `--arg`/`--argjson`) and is the only style outlier on the security-sensitive path. Mirror at line 847 for Path 2.
- **Suggested fix:** Replace with `--arg pn "$phase_n"` and use `"phase-\($pn)"` inside the jq filter. Same pattern at line 847. Pure refactor; no behavior change.
- **Source:** Defensive-coding practice; consistency with the rest of the file's jq-arg style.

### Finding F7
- **Severity:** SHOULD
- **Location:** `scripts/tests/test-tracker-promote-path1.sh` and `path2.sh` (entire files)
- **Title:** Tests rely on stub backend that always succeeds; missing-label and failed-create code paths are not exercised
- **Description:** The Path 1 / Path 2 tracker-mode test groups (Group 4 in each) use `stub-backend.sh` which records call sites but always returns success. This is appropriate for verb-shape and routing coverage. But it leaves three real-world failure paths uncovered: (a) `gh issue create --label promoted-to:phase-N` fails because the label doesn't exist on the repo (Finding F3); (b) `gh issue edit --add-label …` returns rc≠0 because of auth / network / label-missing (currently swallowed by `|| true`); (c) the cycle-graph store write fails (BD-108 surface). Combined with the test fixture's small scale (3 TDs in BACKLOG.md), the coverage is structural rather than end-to-end.
- **Suggested fix:** Add at least one failure-path test per BD-107 batch:
  - In `test-tracker-promote-path1.sh`, override `_stub_record` to return rc=1 from `tracker_provider_stub_create` for one call site, assert that `tracker_promote_path1` returns rc=1 and emits a typed error.
  - In `test-tracker-promote-path2.sh`, override `tracker_provider_stub_link` to fail and assert that the dependency_edges array entry for the failed edge is omitted (current implementation skips silently — Finding F3 partner).
  - Optionally: a real-mode integration test gated behind `$BD107_INTEGRATION=1` that runs against a scratch GH repo via `gh` CLI. Per pack memory "test infra is self-provisioned" rule.
- **Source:** Pack memory — tests cover the spec contract end-to-end; V3.3 §3.5 label invariants must be enforced under real failure modes.

### Finding F8
- **Severity:** SHOULD
- **Location:** `scripts/lib/tracker-promote.sh:911`
- **Title:** Path 2 dependency-edge case-match `BD-[0-9]*` accepts pack-ids prefixed by BD but doesn't enforce the canonical shape
- **Description:** Line 911's case pattern is `phase-[0-9]*|TD-[0-9]*|BD-[0-9]*)`. Bash glob `BD-[0-9]*` matches `BD-029` and also `BD-029X`, `BD-029foo`, etc. The `${b_raw%% *}` first-token split at line 903 limits matches to whitespace-bounded tokens, and downstream `tracker_links_create_blocked_by` enforces the precise shape via `_tlk_is_valid_pack_id`. But the case glob is the dispatcher seam where well-formed-but-not-quite IDs could pass through to a stricter library and cause confusion. NIT-borderline; calling out because the spec contract for `Dependencies` parsing per V3.3 §5.3 names exactly `phase-\d+(\.\d+)?|TD-\d+|BD-\d+`.
- **Suggested fix:** Tighten the case pattern to use an extglob (already needed elsewhere in bash 3.2-compatible code) or a regex inside `[[` instead of `case`: `if [[ "$b_raw_id" =~ ^(phase-[0-9]+(\.[0-9]+)?|TD-[0-9]+|BD-[0-9]+)$ ]]`. Identical to V3.3 §5.3's regex.
- **Source:** ARCHITECTURE-V3.3-DELTA.md §5.3 line 276 — parser regex for Dependencies bullet entries.

### Finding F9
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-promote.sh:611-655` (Path 1 tracker-mode), `:833-933` (Path 2 tracker-mode)
- **Title:** Tracker-mode side effects are non-atomic; mid-flow failure leaves IMPLEMENTATION-PLAN updated but tracker entity partially created
- **Description:** Path 1 (and Path 2) write to IMPLEMENTATION-PLAN.md FIRST (line 595-598 / 818) then attempt tracker-side `provider_create` + `provider_set_labels` + `provider_close`. If `provider_create` fails after the plan write, the working tree carries the new phase block but no tracker entity exists. The user is left in a partial state with no transactional recovery. The orchestrator returns rc=1 from `provider_create`'s failure (line 638) but the plan-file mutation has already happened. The library does not roll back the plan-file edit.
- **Suggested fix:** Either (a) re-order: do `provider_create` first, then write the plan only on success (consistent with v10 "tracker is the source of truth in tracker mode" but contradicts BD-107's design that flat-file remains user-facing); or (b) wrap the plan write in a try/rollback: capture `cp "$plan_path" "$plan_path.pre-bd107"` before the append, restore on tracker failure. (b) is the minimum-disruption fix. The current behavior is documented as an idempotent-replay-safe design via the duplicate-run guard, but the partial-state user experience is rough.
- **Source:** V1 §9.6 / D-7 partial-write atomicity expectation.

### Finding F10
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-promote.sh:492-512`
- **Title:** `tracker_promote_phase_task_M_in_use` returns rc=1 ambiguously for both "invalid target" and "M is free"
- **Description:** When called with a target that doesn't match `^phase-([0-9]+)\.([0-9]+)$`, the function returns rc=1 at line 496. When called with a valid target where the M is free, it also returns rc=1 at line 511. The caller (`tracker_promote_path2` line 733) treats rc=1 as "M is free" without disambiguating. The path2 regex check at line 715 prevents the invalid case in practice, but the rc=1 overload is brittle if a caller ever forgets the upstream validation.
- **Suggested fix:** Disambiguate with rc=2 for "invalid input" vs rc=1 for "M is free". Or emit a typed error block for the invalid case so the caller can distinguish. Defensive only; the actual call site is safe.
- **Source:** Pack-memory error-discipline practice.

### Finding F11
- **Severity:** NIT
- **Location:** `BACKLOG.md:905`
- **Title:** BD-107 entry's File/Symbol field doesn't enumerate all four HELP-FRAGMENT files that were modified
- **Description:** The BACKLOG entry's File/Symbol names only `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` with a parenthetical "or wherever the tracker help fragment lives". The actual implementation extends FOUR HELP-FRAGMENT files: pack-root `HELP-FRAGMENT-PACK.md` (line +1), pack-root `HELP-FRAGMENT-TRACKER.md` (+20), project-template `HELP-FRAGMENT.md` (+4/-1), and project-template `HELP-FRAGMENT-TRACKER.md` (+20). Per pack memory, BACKLOG entries should accurately reflect deliverable scope. Per pack rules, agents do not modify BACKLOG.md — this is a flag for Pack Chat at commit time, not an agent-actionable change. NIT-level because the second backstamp ("HELP-FRAGMENT reconciliation note added") acknowledges the scope.
- **Suggested fix:** Pack Chat to consider a third backstamp at land time noting actual deliverable HELP-FRAGMENT files. Or leave as-is given the resolution backstamp pattern.
- **Source:** Pack-memory BACKLOG accuracy rule.

### Finding F12
- **Severity:** NIT
- **Location:** `scripts/lib/tracker-promote.sh:328-360`
- **Title:** Phase shell `**Goal:**` field only carries the first line of the TD's description
- **Description:** Line 330: `print('**Goal:** ' + (desc.split("\n")[0] if desc else f'(derived from {td_id}; architect to refine)'))`. The full TD description is multi-paragraph; only the first line goes into the Phase Goal. The remainder is reproduced inside the auto-generated 9.1 task's `Problem / Goal / Success` bullet (which DOES include multi-line content, line 336). The phase Goal therefore loses information. METHODOLOGY § Part 4 phase format requires a Goal — but a one-line Goal sourced from a multi-paragraph TD description may misrepresent intent.
- **Suggested fix:** Either accept the loss (architect always refines anyway per the comment at lines 296-299) — current behavior is defensible since the full description survives in the task's Problem bullet AND in the HTML-comment context block at line 357. Or stitch description sentences up to a punctuation boundary into Goal. Or leave Goal as a placeholder `(derived from TD-NNN; architect to refine)` and put the description in the task's Problem bullet only. Author judgment.
- **Source:** METHODOLOGY § Part 4 phase format; ARCHITECTURE-V3.3-DELTA.md §7.2 "architect produces the phase shell".

### Finding F13
- **Severity:** NIT
- **Location:** `scripts/pack-td.sh:1-244`
- **Title:** Dispatcher always sources the full tracker library set, even for flat-file invocations
- **Description:** Lines 44-64 unconditionally source ten library files (`tracker-config`, `tracker-provider`, `tracker-provider-gh`, `tracker-labels`, `tracker-cycle-check`, `tracker-links`, `tracker-mirror`, `tracker-migrate-forward`, `tracker-phase-task`, `tracker-promote`). For `pack td resolve <td-id>` (which is a pure flat-file marker that only uses `tracker_promote_direct_close`), this is overhead — sourcing `tracker-mirror.sh` etc. is unnecessary. Mirrors the precedent of `scripts/pack-tracker.sh` which has the same broad source pattern, so this is consistent with the existing dispatcher pattern.
- **Suggested fix:** Leave as-is — consistency with `pack-tracker.sh` outweighs micro-optimization. NIT only flagged because the BACKLOG-corrected scope mentioned "one-script-per-noun convention".
- **Source:** Consistency with existing `scripts/pack-tracker.sh` dispatcher pattern.

## Coverage notes

**What I reviewed:**
- V3.3 spec compliance: §3 (D-22 two-path + direct close), §3.1 outcome table, §3.2 direct close shape, §3.3 / §3.4 Path 1 / Path 2 mechanics, §3.5 label family (two kinds), §7.1 advisory heuristic, §7.2 PM Chat execution workflow, §7.3 verb shape. Library, dispatcher, and PM-CHAT all align with the spec.
- Path 3 invariants: confirmed `tracker_labels_folded_into` constructor absent; confirmed `--fold-into` is present in `scripts/pack-td.sh` ONLY as a typed-error rejection stanza (verified by python-regex audit, mirrored by test 5.2); confirmed no `(from TD-NNN)` inline body marker (only the comment-form `<!-- promoted from TD-NNN -->` which is V3.3-compliant prose-attribution, not the V3.2 Path 3 prose form); confirmed no `folded-into:` label literal in `tracker-promote.sh` or `pack-td.sh` non-comment lines; confirmed dispatcher rejects `--fold-into` with typed error naming "Path 3 forbidden".
- Trinity-style consistency across the 4 HELP-FRAGMENT files: pack-root `HELP-FRAGMENT-TRACKER.md` and project-template `HELP-FRAGMENT-TRACKER.md` are byte-identical (validate-pack Check 24 OK). `HELP-FRAGMENT-PACK.md` (pack-root) and `HELP-FRAGMENT.md` (project-template) reference the new verbs with consistent shape but different surface scope as expected.
- PM-CHAT.md ↔ METHODOLOGY.md ↔ HELP-FRAGMENT consistency: all three name the same three outcomes with the same verbs (`pack td resolve`, `pack td promote --to=phase-N`, `pack td promote --to=phase-N.M`) and the same "Path 3 is forbidden" stance. PM-CHAT.md's V3.3 §7.1 verbatim prompt block is byte-identical to V3.3-DELTA.md.
- §6.P architect-default: PM-CHAT.md correctly states "PM Chat invokes the **architect** … **by default**" for Path 1 (lines 476-479) and conditionally invokes the planner ("architect's call decides"). METHODOLOGY.md decision tree cites V3.3 §7.2 / §6.P. Library comment at lines 121-124 explicitly hands off architect-invocation to PM Chat's orchestration-policy layer (libraries are primitives).
- Dispatcher organization: `scripts/pack-td.sh` follows the `scripts/pack-<noun>.sh` precedent (parallel to `scripts/pack-tracker.sh` and `scripts/pack-help.sh`).
- `pack td resolve` baseline: BD-107's IMPLEMENTATION-REPORT §4 call-out 4 verified via grep that no prior baseline existed; BD-107 introduces `resolve` as a thin pass-through wrapper to `tracker_promote_direct_close`. Decision is reasonable and gives PM Chat a uniform JSON entry across all three V3.3 §3.1 outcomes.
- Path 1 / Path 2 idempotency: Path 1 guard at line 575 uses a substring match (see Finding F2); Path 2 guard at line 733 uses `tracker_promote_phase_task_M_in_use` which is strict.
- M-allocation semantics: `tracker_promote_next_phase_task_M` returns max+1 for existing tasks, 1 for sparse phases, 1 for missing plan files. Tests 1.1-1.5 cover the matrix.
- Direct-close wrapper: `tracker_promote_direct_close` is purely a JSON marker; emits empty `promotion_labels: []` and `new_entity: null`. Test Group 3 confirms zero side-effects (SHA-256 byte-identity of sidecar and BACKLOG after the call).
- BD-106 / BD-108 surface usage: Path 2 correctly calls `tracker_links_create_blocked_by` with the 5-argument signature (src, tgt, id-map, store, annotation). Path 1 uses `tracker_labels_derived_from` and `tracker_labels_promoted_to` via the BD-106 helpers. ID-map augmentation at line 884-886 correctly extends the in-memory map so `_tlk_resolve_id` can find the just-created `phase-N.M`.
- Error-handling pattern conformance: Library uses `tracker_error_emit "validation" / "not-found"` consistently; dispatcher is mostly consistent except for the `set -u` issues in Finding F1.
- Test coverage: 140 assertions across 3 test scripts. Coverage groups span: verb classification, pure formatters, forward orchestration (flat + tracker stub), reverse handlers, round-trip identity (SHA-256), label invariants, Path 3 forbidden invariants (5 grep checks), dispatcher integration, doc sanity. All passing.
- validate-pack alignment: full run passes (30 checks); pack-td.sh executable bit set; HELP-FRAGMENT verb tokens (`pack td promote`, `pack td resolve`) all resolve in the matching fragments.
- Security: jq filters use `--arg`/`--argjson` for variable input except at lines 636 / 847 (Finding F6); Python heredocs use `'PYEOF'` single-quoted delimiter which prevents bash variable interpolation (input comes via env vars only); no shell-injection surface in argument parsing.
- Pack memory compliance: agents-never-commit honored (working tree changes only); BD-NNN numbering matches BACKLOG; no destructive ops; mirror-rule honored for HELP-FRAGMENT-TRACKER.

**Intentionally deferred / out of scope per prompt:**
- Internals of BD-106 (`tracker-phase-task.sh`) and BD-108 (`tracker-links.sh`, `tracker-cycle-check.sh`) themselves; only BD-107's consumption surface was reviewed.
- Other `PACK-REVIEW-*.md` reports under `maintenance-docs/v11-implementation/` — explicitly excluded per pack memory ("never prior PACK-REVIEW-*.md reports").
- §6.P / §6.Q / §6.R MAINTAINER CHECK items — per prompt, treated as recommendation (a) implemented, not flagged as architecture gaps.
- Other `RESEARCH-*.md` / `ARCHITECTURE-PER-ENTRY-*.md` files in `maintenance-docs/v11-research/` — out of scope per prompt.
