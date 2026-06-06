# IMPL-REPORT — BD-204 Commit C-3 (full-CRUD `provider_update` wiring, Mode-3 pack edit path)

- **Branch:** `v11-dev`
- **HEAD (unchanged — agent never commits):** `3a8ba3e96f795c741eb0cdc78844d3396fd2afe0`
- **Scope:** pack-only (`scripts/` only; no `project-template/` / `supporting-docs/`).

## Investigation result (the open risk)

**No discrete Mode-3 pack edit entry point exists today.** The `pack tracker`
verb surface (`scripts/pack-tracker.sh`: init / status / mirror-rebuild /
disable / doctor / update-templates / enable-recommendations) has **no verb
or function that applies a `Status:` / `Resolution:` / `Description:` edit to a
tracked entry in tracker mode.** `provider_update` is called only project-side
in `tracker-promote.sh:801,1215` (TD-promotion Resolution body sync). The read
path exists (`tracker-agent-read.sh:_tar_read_entry_tracker` — pack-id → gh-id
via id-map → `provider_get`) but has no write counterpart.

⇒ Per the plan's "if it does NOT exist" branch, I **CREATED a new pack-side lib
function**, not wired an existing one.

## What I did — CREATED a new pack-side lib (named)

New file **`scripts/lib/tracker-edit.sh`**, public function
**`tracker_edit_entry <pack-id> <patch-json> [<repo-root>]`** — the symmetric
WRITE counterpart to `tracker-agent-read.sh`'s read path. It resolves pack-id →
gh-id via `.pack-tracker/id-map.json` (same lookup as the read side), then
mutates the tracker SSOT entirely through `provider_*` ops.

Wired into the dispatcher source block in `scripts/pack-tracker.sh` (sourced
alongside the other tracker libs).

## Update wiring (quoted) — reuses the `tracker-promote.sh:801` call shape

Payload built then applied via `provider_update "$gh_id" "$payload"` (the
`{body: ...}` + label-swap shape, parallel to the project-side caller):

```sh
payload=$(printf '%s' "$patch" | jq \
    --arg nl "${new_label:-}" \
    --arg ol "${old_label:-}" \
    '
    {}
    + (if (.title // "")  != "" then {title: .title} else {} end)
    + (if (.body  // "")  != "" then {body:  .body}  else {} end)
    + {add_labels:    ((.add_labels    // []) + (if $nl != "" then [$nl] else [] end) | unique)}
    + {remove_labels: ((.remove_labels // []) + (if ($ol != "" and $ol != $nl) then [$ol] else [] end) | unique)}
    ')

# 1. Update — body / title / labels (tracker-agnostic provider op).
if ! provider_update "$gh_id" "$payload" >/dev/null 2>&1; then
    tracker_error_emit "partial-write" \
        "tracker_edit: provider_update failed for $pack_id (gh-id $gh_id)" ...
    return 1
fi
```

The `status:*` label swap rides `remove_labels[old] → add_labels[new]` so a
`Status:` flip updates labels in the same `provider_update`.

## Open/closed boundary cross wiring (quoted) — DP-3 matrix (§2.6)

After the update, a status that crosses the open↔closed boundary fires
`provider_close` (with the DP-3 `state_reason`) or `provider_reopen`:

```sh
if [[ -n "$new_status" ]]; then
    local new_open old_open
    new_open=$(_ted_status_openness "$new_status")
    ...
    if [[ "$new_open" != "$old_open" ]]; then
        if [[ "$new_open" == "closed" ]]; then
            local reason
            reason=$(_ted_status_reason "$new_status")
            provider_close "$gh_id" "$reason" ...   # Resolved→completed; Deprecated/Cancelled→not_planned
        else
            provider_reopen "$gh_id" ...
        fi
    fi
fi
```

DP-3 matrix encoded in three tiny helpers (single source for openness +
state_reason + label):

| `Status:` | open/closed | `state_reason` | `status:*` label |
|---|---|---|---|
| Open | open | — | `status:open` |
| Unblocked | open | — | `status:unblocked` |
| Deferred | open | — | `status:deferred` |
| Resolved | closed | `completed` | `status:resolved` |
| Deprecated | closed | `not_planned` | `status:deprecated` |
| Cancelled | closed | `not_planned` | `status:cancelled` |

An update-only edit (body tweak) and an open→open `Status:` change
(Open→Deferred) do NOT cross the boundary — `provider_update` only, no
close/reopen.

## No `provider_delete` (confirmed)

The only `provider_delete` string in `scripts/` is in my OWN comment in
`tracker-edit.sh` documenting that none was added (`grep -rn provider_delete
scripts/` → one comment line only). The "delete = close-with-`state_reason`"
mapping is honored: deprecation/cancellation route to `provider_close` with
`not_planned`. The provider op-set is NOT widened.

## Test assertion added

`scripts/tests/tracker-provider-test.sh` Group 4 (6 cases, 13 assertions),
matching the file's existing `STUB_CALLS`-style op-logging pattern (stubs
`provider_update`/`provider_close`/`provider_reopen` to log argv into
`TED_CALLS`; offline scratch id-map maps `BD-001 → 42`):

- **4.1** body-only edit → `provider_update` fires, NO boundary cross; returns `updated=true`.
- **4.2** Open→Deferred (both open) → `provider_update` only, NO boundary cross.
- **4.3** Open→Resolved → `provider_update` + `provider_close 42 completed`.
- **4.4** Open→Cancelled → `provider_close 42 not_planned` (DP-3 reason).
- **4.5** Resolved→Open → `provider_update` + `provider_reopen 42` (and NOT close).
- **4.6** unmapped pack-id → typed `not-found` error, zero provider ops dispatched.

## Verification commands + results (all PASS)

| Command | Result |
|---|---|
| `bash scripts/tests/tracker-provider-test.sh` | `Passed: 111 / Failed: 0 — All tests passed.` |
| `python3 scripts/validate-pack.py` | `PASSED — all checks clean` (Check 47 sanctioned set unchanged; Check 48 WARNs are pre-existing advisory-only) |
| `bash scripts/tests/test-v11-realistic-ot.sh` | `PASS: 33 / FAIL: 0 (33/33)` |
| `bash -n` on all 3 edited scripts | syntax OK |

## Manifest regen

`bash test-fixtures/build.sh --all --clean` → rc 0; `git diff --stat
test-fixtures/manifest.txt` → **empty**. The manifest tracks per-fixture
git SHAs of generated project trees (init-project output), not pack-repo
`scripts/lib/` contents; a new non-shipped pack lib changes no fixture SHA, so
an empty diff is correct. Nothing to stage. (Rule honored: regen run; non-empty
⇒ in scope; here empty.)

## Files changed (inventory)

| Path | Type |
|---|---|
| `scripts/lib/tracker-edit.sh` | **new** (pack-side lib; full contents below) |
| `scripts/pack-tracker.sh` | modified (+2 lines: source the new lib in the dispatcher) |
| `scripts/tests/tracker-provider-test.sh` | modified (+~95 lines: Group 4) |

`git status --short` at report time:
```
 M scripts/pack-tracker.sh
 M scripts/tests/tracker-provider-test.sh
?? scripts/lib/tracker-edit.sh
```

## Boundary discipline check

No project-side files edited. All three touched paths are under `scripts/`
(pack-side). No client-shipped surface (`project-template/`, `supporting-docs/`)
touched ⇒ the project-side-SSOT pre-flight (P-missed-7) does not apply. The new
function lives in a pack-side lib only; no reference to a pack-only orchestrator
role was injected into any client surface (none was touched).

## Plan deviations

None. (The plan explicitly anticipated both branches of step 1; I took the
"entry point does NOT exist → add a pack-side lib function" branch and named it.)

## New POQs

None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| Investigated for an existing Mode-3 edit entry point; reported result | PASS (none exists) |
| Update wired via `provider_update` reusing `tracker-promote.sh:801` shape | PASS |
| Open/closed boundary cross wired via `provider_close`/`provider_reopen` per DP-3 | PASS |
| Correct `state_reason` per DP-3 (completed / not_planned) | PASS |
| No `provider_delete` added; delete=close-with-reason honored | PASS |
| Tracker-agnostic — all CRUD via `provider_*`, never raw `gh` | PASS |
| Test assertion added matching existing style | PASS (Group 4) |
| `validate-pack.py` clean | PASS |
| Touched CRUD/provider test green | PASS (111/0) |
| `test-v11-realistic-ot.sh` green | PASS (33/0) |
| Manifest regen run | PASS (empty diff — correct) |
| pack-only scope held; no project-side edit | PASS |
| No git state change | PASS (HEAD `3a8ba3e` unchanged; all unstaged) |

---

## Full contents — `scripts/lib/tracker-edit.sh` (new)

```sh
# scripts/lib/tracker-edit.sh — Mode-3 pack edit path (BD-204 §2.3).
#
# The full-CRUD "Update" verb for the tracker SSOT. When the pack is
# in tracker mode (Mode 3), an edit to a tracked entry — a `Status:`
# flip, a `Resolution:` fill, an edited `Description:`/body — is
# applied AGAINST the tracker (the SSOT), not against a flat file.
# The per-entry tree is regenerated FROM tracker state (§2.1, §2.5);
# tree files are not the edit target in Mode 3.
#
# This is the symmetric WRITE counterpart to tracker-agent-read.sh's
# READ path: both resolve pack-id → gh-id via the id-map, then call
# the provider abstraction. Read uses provider_get; edit uses
# provider_update + provider_close / provider_reopen on the open/closed
# boundary cross (DP-3 matrix, §2.6).
#
# CRUD mapping (BD-204 §2.3):
#   - Create — provider_create (forward migration Step 4/5; not here).
#   - Read   — provider_get / provider_list (tracker-agent-read.sh).
#   - Update — provider_update on body/labels (THIS file) + a
#              provider_close / provider_reopen when the new Status
#              crosses the open↔closed boundary (DP-3).
#   - Delete — NO hard-delete. The pack lifecycle resolves entries in
#              place by status flip (backlog/_rules.md); deprecation /
#              cancellation are CLOSED states, not deletions. So
#              "delete" maps to provider_close with a state_reason
#              (the Deprecated / Cancelled rows of DP-3) — there is NO
#              provider_delete op (adding one would widen the
#              abstraction with no consumer; §2.3).
#
# Tracker-agnostic: every mutation goes through a provider_* op, never
# a raw `gh` call. A Jira / Linear backend implements the same verbs
# (update / close / reopen), so this path ports unchanged.
#
# Reference: ARCHITECTURE-BD-204.md §2.3 (full CRUD), §2.6 / DP-3
# (status matrix + state_reason); tracker-promote.sh:801 (the
# provider_update call shape this reuses).
#
# Bash 3.2 compatible (macOS default). Do NOT add a shebang — this
# file is sourced, not executed.

# Source siblings idempotently when this file is sourced (mirrors the
# tracker-agent-read.sh source block). `declare -f` checks are cheap.
_ted_self="${BASH_SOURCE[0]:-$0}"
_ted_dir="$(cd "$(dirname "$_ted_self")" && pwd)"

# shellcheck disable=SC1091
[[ -z "$(declare -f tracker_error_emit 2>/dev/null)" ]] && \
    source "$_ted_dir/tracker-errors.sh"
# shellcheck disable=SC1091
[[ -z "$(declare -f tracker_mode 2>/dev/null)" ]] && \
    source "$_ted_dir/tracker-config.sh"
# shellcheck disable=SC1091
[[ -z "$(declare -f provider_update 2>/dev/null)" ]] && {
    source "$_ted_dir/tracker-provider.sh"
    source "$_ted_dir/tracker-provider-gh.sh"
}
unset _ted_self _ted_dir

# ─────────────────────────────────────────────────────────────────
# DP-3 status matrix (§2.6) — the single source of open/closed +
# state_reason + status:* label for every pack-backlog Status value.
# ─────────────────────────────────────────────────────────────────

# _ted_status_openness <Status>
# Emits "open" or "closed" on stdout per the DP-3 matrix. Open states:
# Open / Unblocked / Deferred. Closed states: Resolved / Deprecated /
# Cancelled. Unknown → open (safest: an unknown state stays live and
# visible in open-work queries rather than being silently closed).
_ted_status_openness() {
    case "$1" in
        Open|Unblocked|Deferred)        echo "open" ;;
        Resolved|Deprecated|Cancelled)  echo "closed" ;;
        *)                              echo "open" ;;
    esac
}

# _ted_status_reason <Status>
# Emits the GH state_reason for a CLOSED status per DP-3:
#   Resolved → completed ; Deprecated|Cancelled → not_planned.
# Empty for open states (no reason on a reopen/open issue).
_ted_status_reason() {
    case "$1" in
        Resolved)              echo "completed" ;;
        Deprecated|Cancelled)  echo "not_planned" ;;
        *)                     echo "" ;;
    esac
}

# _ted_status_label <Status>
# Emits the status:* label for a Status value per DP-3. Mirrors the
# forward-migration label map (tracker-migrate-forward.sh
# _tmf_labels_for_entry) and adds the Deferred row (§2.6 / DP-3).
_ted_status_label() {
    case "$1" in
        Open)        echo "status:open" ;;
        Unblocked)   echo "status:unblocked" ;;
        Deferred)    echo "status:deferred" ;;
        Resolved)    echo "status:resolved" ;;
        Deprecated)  echo "status:deprecated" ;;
        Cancelled)   echo "status:cancelled" ;;
        *)           echo "status:open" ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

# tracker_edit_mode [<repo-root>]
# Emits the active mode ("flat-file" or "tracker") on stdout (mirrors
# tracker_agent_read_mode). Edits are applied against the tracker only
# in tracker mode; in flat-file mode the per-entry tree is the SSOT and
# this path is a no-op (callers edit the tree directly).
tracker_edit_mode() {
    local repo_root="${1:-$(pwd)}"
    local cfg_path surface
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root" 2>/dev/null) || {
        echo "flat-file"
        return 0
    }
    tracker_mode "$cfg_path"
}

# tracker_edit_entry <pack-id> <patch-json> [<repo-root>]
#
# Apply an edit to a tracked entry against the tracker SSOT (Mode 3).
#
# <patch-json> describes the edit. Recognized keys (all optional):
#   body          — the recomposed Issue body (prose sub-blocks:
#                   Description / Context / Resolution / etc.)
#   title         — new title text
#   status        — the NEW pack Status value (Open / Unblocked /
#                   Deferred / Resolved / Deprecated / Cancelled).
#                   Drives BOTH a status:* label swap AND, when it
#                   crosses the open↔closed boundary, a provider_close
#                   (with the DP-3 state_reason) or provider_reopen.
#   old_status    — the PRIOR Status value, used to detect a boundary
#                   cross. When absent, the boundary cross is computed
#                   from the new status alone (close if new is closed,
#                   reopen if new is open) — idempotent on the backend.
#   add_labels    — extra labels to add (array; merged with the
#                   status:* label derived from `status`)
#   remove_labels — labels to remove (array)
#
# Mutation order (all provider_*; never raw gh):
#   1. provider_update — body / title / labels (the status:* label
#      swap rides remove_labels[old]→add_labels[new]).
#   2. provider_close / provider_reopen — ONLY when `status` crosses
#      the open↔closed boundary (DP-3). Update-only edits (a body
#      tweak, an open→open Status change like Open→Deferred) skip the
#      close/reopen entirely.
#
# Returns 1 with a typed error on missing args, flat-file mode, an
# unmapped pack-id, or a provider failure.
tracker_edit_entry() {
    local pack_id="$1"
    local patch="$2"
    local repo_root="${3:-$(pwd)}"

    if [[ -z "$pack_id" ]]; then
        tracker_error_emit "validation" "tracker_edit: pack-id required"
        return 1
    fi
    if [[ -z "$patch" ]]; then
        tracker_error_emit "validation" "tracker_edit: patch JSON required"
        return 1
    fi
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "tracker_edit: repo-root not a directory: $repo_root"
        return 1
    fi

    local mode
    mode=$(tracker_edit_mode "$repo_root")
    if [[ "$mode" != "tracker" ]]; then
        # Flat-file mode: the per-entry tree is the SSOT; this path
        # does not own flat-file edits. Surface a clear, non-fatal
        # signal so callers branch their own write.
        tracker_error_emit "validation" \
            "tracker_edit: not in tracker mode (mode=$mode); edit the per-entry tree directly"
        return 1
    fi

    # Resolve pack-id → gh-id via the id-map (same path as the read
    # side, tracker-agent-read.sh:_tar_read_entry_tracker).
    local mapping_file mapping gh_id cfg_path surface
    mapping_file="$repo_root/.pack-tracker/id-map.json"
    if [[ ! -f "$mapping_file" ]]; then
        tracker_error_emit "not-found" \
            "tracker_edit: tracker mode but mapping file absent at $mapping_file"
        return 1
    fi
    mapping=$(cat "$mapping_file")
    gh_id=$(printf '%s' "$mapping" | jq -r --arg k "$pack_id" \
        'if has($k) then .[$k].id else empty end')
    if [[ -z "$gh_id" || "$gh_id" == "null" ]]; then
        tracker_error_emit "not-found" \
            "tracker_edit: $pack_id not in mapping (tracker mode)"
        return 1
    fi

    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root" 2>/dev/null) || cfg_path=""
    [[ -n "$cfg_path" ]] && export _TRACKER_PROVIDER_CONFIG_PATH="$cfg_path"

    # Parse the patch.
    local new_status old_status
    new_status=$(printf '%s' "$patch" | jq -r '.status // empty')
    old_status=$(printf '%s' "$patch" | jq -r '.old_status // empty')

    # Build the provider_update payload (§2.3; reuses the
    # tracker-promote.sh:801 `provider_update "$gh_id" "$payload"` call
    # shape). The status:* label swap rides add_labels / remove_labels:
    # remove the old status:* label, add the new one.
    local new_label old_label
    if [[ -n "$new_status" ]]; then
        new_label=$(_ted_status_label "$new_status")
    fi
    if [[ -n "$old_status" ]]; then
        old_label=$(_ted_status_label "$old_status")
    fi

    local payload
    payload=$(printf '%s' "$patch" | jq \
        --arg nl "${new_label:-}" \
        --arg ol "${old_label:-}" \
        '
        {}
        + (if (.title // "")  != "" then {title: .title} else {} end)
        + (if (.body  // "")  != "" then {body:  .body}  else {} end)
        + {add_labels:    ((.add_labels    // []) + (if $nl != "" then [$nl] else [] end) | unique)}
        + {remove_labels: ((.remove_labels // []) + (if ($ol != "" and $ol != $nl) then [$ol] else [] end) | unique)}
        ')

    # 1. Update — body / title / labels (tracker-agnostic provider op).
    if ! provider_update "$gh_id" "$payload" >/dev/null 2>&1; then
        tracker_error_emit "partial-write" \
            "tracker_edit: provider_update failed for $pack_id (gh-id $gh_id)" \
            "(no boundary cross attempted; re-run after addressing the backend failure)"
        return 1
    fi

    # 2. Open/closed boundary cross (DP-3). Only fires when the NEW
    # status is set AND it lands on the opposite side of the boundary
    # from the old status (or, when old_status is absent, whenever the
    # new status's side is determinable — close if closed, reopen if
    # open; idempotent on the backend).
    if [[ -n "$new_status" ]]; then
        local new_open old_open
        new_open=$(_ted_status_openness "$new_status")
        if [[ -n "$old_status" ]]; then
            old_open=$(_ted_status_openness "$old_status")
        else
            # No prior status given: treat as the inverse so any set
            # status applies its terminal state once (idempotent).
            old_open=""
        fi

        if [[ "$new_open" != "$old_open" ]]; then
            if [[ "$new_open" == "closed" ]]; then
                local reason
                reason=$(_ted_status_reason "$new_status")
                if ! provider_close "$gh_id" "$reason" >/dev/null 2>&1; then
                    tracker_error_emit "partial-write" \
                        "tracker_edit: provider_close failed for $pack_id (gh-id $gh_id, reason $reason)" \
                        "(body/label update succeeded; close failed — re-run after addressing the backend failure)"
                    return 1
                fi
            else
                if ! provider_reopen "$gh_id" >/dev/null 2>&1; then
                    tracker_error_emit "partial-write" \
                        "tracker_edit: provider_reopen failed for $pack_id (gh-id $gh_id)" \
                        "(body/label update succeeded; reopen failed — re-run after addressing the backend failure)"
                    return 1
                fi
            fi
        fi
    fi

    printf '{"pack_id": "%s", "gh_id": "%s", "updated": true}\n' "$pack_id" "$gh_id"
}
```

---

## Rules-Applied Verification Block

| Rule / READ-IN-FULL doc | Evidence (quoted/measured) | Conclusion |
|---|---|---|
| **Tracker portability** | All CRUD via `provider_*`: the only `gh` token in `tracker-edit.sh` is the comment "never a raw `gh` call"; ops used are `provider_update`/`provider_close`/`provider_reopen`/`provider_get`(read side). `grep -n "gh " scripts/lib/tracker-edit.sh` → comment lines only. | COMPLIANT |
| **Pack/project separation** | `git status --short` → `M scripts/pack-tracker.sh`, `M scripts/tests/tracker-provider-test.sh`, `?? scripts/lib/tracker-edit.sh` — all under `scripts/`; zero `project-template/`/`supporting-docs/` paths. `tracker-promote.sh` project-side path untouched. | COMPLIANT |
| **Pattern-matching antipattern** | No `provider_delete` op added — `grep -rn provider_delete scripts/` → 1 hit, my own comment documenting its absence. Delete mapped to `provider_close` w/ `state_reason` (property-fit, not CRUD-symmetry reflex). | COMPLIANT |
| **Verify the FULL CI suite** | `tracker-provider-test.sh` 111/0; `validate-pack.py` "PASSED — all checks clean"; `test-v11-realistic-ot.sh` 33/0. All quoted in Verification table above. | COMPLIANT |
| **Regenerate manifest on v11-surface commits** | `build.sh --all --clean` rc 0; `git diff --stat test-fixtures/manifest.txt` empty (new non-shipped pack lib changes no fixture SHA). Regen run; nothing to stage. | COMPLIANT |
| **Agents never commit** | No state-changing git verb run; HEAD `3a8ba3e` == pre-flight HEAD; all changes unstaged (`git status --short`). | COMPLIANT |
| **PREFLIGHT + STOP-MEANS-STOP** | Emitted one PREFLIGHT line after all edits + verification PASS, before this Write. No parent stop received. | COMPLIANT |
| **Rules-Applied Verification Block** | This table. | COMPLIANT |
| READ: `PLAN-BD-204.md` § Commit C-3 | Read lines 251–280 directly; took the "entry point does NOT exist → add pack-side lib" branch it names. | COMPLIANT |
| READ: `ARCHITECTURE-BD-204.md` §2.3 | Read lines 385–423 directly; CRUD design (Update wiring, delete=close, no `provider_delete`, tracker-agnostic note) applied. | COMPLIANT |
| READ: `ARCHITECTURE-BD-204.md` §2.6 / DP-3 | Read lines 129–168 directly; the 6-row open/closed + state_reason matrix encoded in `_ted_status_openness`/`_ted_status_reason`/`_ted_status_label`, incl. the Deferred=open row. | COMPLIANT |
| READ: `tracker-provider.sh` (signatures) | Read full file; `provider_update`/`provider_close`/`provider_reopen` exist (`:129`,`:130`,`:131`); no `provider_delete` in op-set. | COMPLIANT |
| READ: `tracker-promote.sh` :801 call shape | Read lines 770–830; reused `provider_update "$gh_id" "$payload"` with a jq-built `{body: ...}`-shaped payload. | COMPLIANT |
| READ: the `pack tracker` edit surface | Read `pack-tracker.sh` in full; confirmed no existing Mode-3 edit entry point. | COMPLIANT |
| READ: chosen test file | Read `tracker-provider-test.sh` (harness + Group 3 op-log pattern); Group 4 matches `STUB_CALLS`-style argv logging. | COMPLIANT |
| READ: `CLAUDE.md` ## Pack memory | Read in full (system context); applied agents-never-commit, manifest-regen, full-CI, separation, deferral rules. | COMPLIANT |
| READ: `feedback_tracker_portability.md` | Read directly; vendor logic behind provider abstraction — all CRUD via `provider_*`. | COMPLIANT |
| READ: `feedback_pack_project_separation_of_concerns.md` | Read directly; new function is a pack-side lib only. | COMPLIANT |
| READ: `feedback_pattern_matching_out_of_context_antipattern.md` | Read directly; rejected `provider_delete` (no property-fit). | COMPLIANT |
| READ: `feedback_verify_full_ci_suite.md` | Read directly; ran integration test `test-v11-realistic-ot.sh`, not just validate-pack. | COMPLIANT |
| READ: `feedback_manifest_regen_on_v11_surface.md` | Read directly; ran regen on `scripts/` touch. | COMPLIANT |
| READ: `feedback_agent_output_rules_applied_block.md` | Read directly; this block present with per-rule evidence. | COMPLIANT |
