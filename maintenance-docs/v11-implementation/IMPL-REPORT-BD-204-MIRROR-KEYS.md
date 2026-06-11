# IMPL-REPORT — BD-204 surface-aware tracker.toml [mirror] writer (no-monolith repoint completes)

- **Branch:** v11-dev
- **HEAD at implementation:** `0fc2ec0254bbca1c25d5765adfd4e9bc94287847`
- **Date:** 2026-06-11
- **Coder:** fresh pack-coder, foreground verification throughout
- **Proposed commit subject:**
  `fix: v11 — BD-204 surface-aware tracker.toml [mirror] writer (pack omits; no-monolith repoint completes) (pack-only)`

## 1. Branch + final HEAD SHA

`git rev-parse HEAD` → `0fc2ec0254bbca1c25d5765adfd4e9bc94287847` on `v11-dev`.
No commits were made (agents never commit); the SHA is the worktree base all
diffs in §5 apply to.

## 2. Pre-flight check output

```
$ git rev-parse HEAD
0fc2ec0254bbca1c25d5765adfd4e9bc94287847
$ git status --short
?? tracker.toml
$ git branch --show-current
v11-dev
```

- `scripts/lib/` and `scripts/tests/` listings confirmed all named files
  present (`tracker-init.sh`, `tracker-config.sh`, `tracker-mirror.sh`,
  `tracker-init-test.sh`, `tracker-config-schema-test.sh`).
- `tracker.toml.pack-example` confirmed at pack root;
  `project-template/tracker.toml.project-example` confirmed (read-only).
- Pre-existing untracked root `tracker.toml` + gitignored `.pack-tracker/`
  confirmed present and NOT touched at any point (Pack-Chat-owned C-8
  runtime state).
- Monolith absence confirmed empirically: `ls` of `BACKLOG.md`, `STATUS.md`,
  `CHANGELOG.md` at pack root and under `pack-ops/` → all "No such file";
  `backlog/_toc.md` + `changelog/_toc.md` present.
- Environment note: a `github` MCP server was available in this session;
  per the NO-live-GitHub-calls constraint it was never invoked.

## 3. Per-task summary

| # | Task | File | Delta | Result |
|---|---|---|---|---|
| T1 | Surface-aware `[mirror]` writer | `scripts/lib/tracker-init.sh` | +54 / -12 | `_tracker_init_write_config` gains a 5th `surface` param; pack → omits `[mirror]` entirely; client → emits the exact current bare-name block (byte-parity proven, §6.1). Call site in `tracker_init_run` passes `"$surface"`. |
| T2 | Reconcile pack example to no-`[mirror]` | `tracker.toml.pack-example` | +13 / -10 | `[mirror]` table removed, replaced by an intent comment naming BD-203/BD-204/BD-206 and the Check-29 no-mirror semantics; stale header comment (monolith names as flat-file SSOT) corrected to the per-entry trees. |
| T3 | Check 29 per-surface `[mirror]` schema | `scripts/validate-pack.py` | +28 / -7 | `_validate_tracker_toml` gains required `mirror_required` param: client example requires the table; pack example admits absence as valid-by-construction; a PRESENT table is key-validated on either surface. Both call sites updated; both docstrings updated. The Check 29′ STALENESS leg needed no change — absence was already a clean soft-pass (see §4.2). |
| T4 | Config readers audit | `scripts/lib/tracker-config.sh`, `scripts/lib/tracker-mirror.sh` | 0 / 0 | NO change needed — evidence in §4.3. |
| T5 | Test extension — schema suite | `scripts/tests/tracker-config-schema-test.sh` | +48 / -21 | GOOD_PACK reshaped to no-`[mirror]` (Test 1 now pins pack-shape acceptance); Test 7 re-targeted to the client example (pins the client requirement); new Test 17 pins present-but-malformed `[mirror]` on the pack example still FAILs. Header strategy list updated. |
| T6 | Test extension — init suite | `scripts/tests/tracker-init-test.sh` | +47 / -1 | New legs 3.3b/3.3c (pack config has no `[mirror]` table / no mirror keys) and 3.5 ×7 (client-surface init end-to-end: config at `docs/pack/tracker.toml`, all 5 mirror keys present with current values, prefix TD). Group-4 header comment updated. |
| T7 | Ride-along figure correction | `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md` | +2 / -1 | §1 "162 Resolved closes succeeded live" → "167 ... per the flip-log `closed:     167` summary line". Verified against `/tmp/bd204-c8-flip.log` line 22 (`closed:     167`). |

## 4. Surface-decision evidence + Check 29′ behavior

### 4.1 The defect (reproduced before fixing)

`_tracker_init_write_config` (HEAD shape) hardcoded
`[mirror] enabled=true + location_backlog/status/changelog = "BACKLOG.md"/"STATUS.md"/"CHANGELOG.md"`
for ALL surfaces — the writer had no surface parameter even though
`tracker_init_run` had `surface` resolved in hand at the call site. On the
pack surface those files were deleted at BD-203, so every C-8-written root
`tracker.toml` made `validate-pack.py` fail 3 mirror checks (reproduced on
the real tree, §6.3).

### 4.2 Check 29′ absent-table behavior — before/after

- **Staleness leg (live config):** ALREADY a clean soft-pass before this fix.
  The BD-204 guard in `_check_mirror_staleness` (`scripts/validate-pack.py`,
  "no-mirror surface guard" comment block) soft-passes when the live config
  has no `[mirror]` table or `enabled` is false/absent, and still FAILs a
  config that DECLARES enabled mirrors with missing files. Pinned by
  pre-existing schema-suite Tests 15/16 (re-run green). No change made.
- **Example-schema leg:** this was the part where absence was NOT yet
  admitted — `_validate_tracker_toml` hard-required the `[mirror]` table for
  BOTH examples. Demonstrated empirically:

```
BEFORE — HEAD validator (git show HEAD:scripts/validate-pack.py) run against
the reconciled pack example in an isolated fixture root:
  FAIL: tracker.toml.pack-example — missing required key: mirror

AFTER — new validator, same fixture:
  OK: tracker.toml.pack-example — schema OK (prefix='BD', backend='github', mode='flat-file')
  OK: project-template/tracker.toml.project-example — schema OK (prefix='TD', ...)
```

- **End-to-end pin (new writer output through Check 29):** wrote a pack
  config with the NEW writer, promoted it to the Mode-3 state the C-8 flip
  produces (`forward_complete = true` + `last_forward_run`), ran
  `check_tracker_config` against a fixture root containing it plus both
  reconciled examples:

```
  OK: tracker.toml — no [mirror] table / mirror disabled — no-mirror surface, mirror-staleness check N/A
  E2E failures: []
  E2E: fresh pack init config + Mode-3 state -> Check 29 fully green
```

### 4.3 Reader audit — why tracker-config.sh / tracker-mirror.sh need no change

Production consumers of mirror keys, full grep
(`grep -rn "mirror\.location\|mirror\.enabled\|location_backlog|..." scripts/ project-template/scripts/` excluding tests):

- `scripts/validate-pack.py` — Check 29 only (handled, T3).
- `scripts/lib/tracker-init.sh` — the writer itself (handled, T1).
- NOTHING else. `scripts/lib/tracker-config.sh` has no mirror-key getter
  (`tracker_backend_name`/`tracker_repo_slug`/`tracker_id_prefix`/
  `tracker_mapping_file` only), and `tracker_config_get` returns rc=1 on an
  absent key by design — no caller assumes the table exists.
  `scripts/lib/tracker-mirror.sh` never reads `tracker.toml` at all (its
  three functions take explicit paths/slugs from callers). The C-1 reader
  repoint left no remaining `[mirror]` reader on the pack path.

### 4.4 Client-surface decision

`--surface client` keeps the exact current bare-name keys: the client model
still has monolith mirrors until BD-206 (confirmed against
`/backlog/BD-206.md`, which scopes the client-side no-mirror application,
explicitly "POST-BD-204 REFRESH" anchored), and
`project-template/tracker.toml.project-example` documents the bare names as
intentional ("trinity ## Document locations resolves to actual paths").
Byte-parity of the new client output vs the HEAD writer's output proven in
§6.1. The client example file was NOT edited (read-only parity awareness
only; pack-only scope).

## 5. Unified diffs (against base 0fc2ec0)

No new files were created besides this report. All six edits below are
targeted in-place edits (rule 8); untouched regions are byte-stable.

> **Fix pass 1 note (2026-06-11, per `PACK-REVIEW-BD-204-MIRROR-KEYS.md`
> NIT-3, fixes documented in `IMPL-REPORT-BD-204-MIRROR-KEYS-FIX1.md`):**
> the `tracker-init.sh` diff in §5.1 originally showed the pre-tweak
> intermediate (blob `7a70fca`, 4-line splice comment); it has been
> refreshed below to the final shape (blob `3d07852`, 7-line comment —
> the §6.2/§6.4 re-verified tweak). Fix pass 1 also further amended
> `tracker.toml.pack-example` (NIT-1) and
> `scripts/tests/tracker-init-test.sh` (NIT-2) beyond the snapshots
> below; those deltas live in the FIX1 report, not here.

### 5.1 scripts/lib/tracker-init.sh + scripts/validate-pack.py + tracker.toml.pack-example

```diff
diff --git a/scripts/lib/tracker-init.sh b/scripts/lib/tracker-init.sh
index f7a91b8..3d07852 100644
--- a/scripts/lib/tracker-init.sh
+++ b/scripts/lib/tracker-init.sh
@@ -187,8 +187,10 @@ EOF
         return 0
     fi
 
-    # Step 1: write tracker.toml.
-    if ! _tracker_init_write_config "$cfg_path" "$backend" "$repo" "$id_prefix"; then
+    # Step 1: write tracker.toml. Surface-aware (BD-204): the pack
+    # surface omits the [mirror] table (no monolith mirrors exist
+    # post-BD-203); the client surface keeps it until BD-206.
+    if ! _tracker_init_write_config "$cfg_path" "$backend" "$repo" "$id_prefix" "$surface"; then
         return 1
     fi
     echo "init: tracker.toml written at $cfg_path"
@@ -314,8 +316,23 @@ _tracker_init_prompt() {
 # Write a tracker.toml from a parsed flag set (V1 §3.1).
 # Idempotent: re-running init re-writes the file; opted_in_at is
 # preserved if the file already exists in tracker mode.
+#
+# Surface-aware [mirror] emission (BD-204, completing the BD-203
+# no-monolith repoint):
+#   - surface=pack   → OMIT the [mirror] table entirely. The pack
+#     surface deleted its monolith mirrors at BD-203 — the /backlog/
+#     and /changelog/ per-entry trees (+ regenerated _toc.md) are the
+#     sole flat representation, and _toc.md regeneration is not a
+#     "mirror file" in the Check 29 sense. validate-pack.py's
+#     _check_mirror_staleness treats the absent table as a no-mirror
+#     surface (staleness N/A soft-pass).
+#   - surface=client → KEEP the bare-name mirror keys. The client
+#     model still has monolith mirrors until BD-206 lands; bare names
+#     are intentional (the project trinity ## Document locations
+#     resolves them to actual paths — see
+#     project-template/tracker.toml.project-example).
 _tracker_init_write_config() {
-    local path="$1" backend="$2" repo="$3" id_prefix="$4"
+    local path="$1" backend="$2" repo="$3" id_prefix="$4" surface="$5"
     local dir
     dir=$(dirname "$path")
     mkdir -p "$dir"
@@ -339,6 +356,28 @@ _tracker_init_write_config() {
         fi
     fi
 
+    # Build the surface-conditional [mirror] block (see function
+    # docstring). The heredoc's two leading empty lines carry the
+    # newline after the opted_in_by line plus the blank line before
+    # [mirror]; command substitution strips the trailing newline, so
+    # the template's own blank line before [id_namespace] closes the
+    # block. Pack surface: mirror_block stays empty and the config
+    # flows straight from [mode] to [id_namespace].
+    local mirror_block=""
+    if [[ "$surface" == "client" ]]; then
+        mirror_block=$(cat <<'MIRROR_EOF'
+
+
+[mirror]
+enabled = true
+location_backlog   = "BACKLOG.md"
+location_status    = "STATUS.md"
+location_changelog = "CHANGELOG.md"
+regenerate_on_write = true
+MIRROR_EOF
+)
+    fi
+
     cat > "$path" <<EOF
 # tracker.toml — written by \`pack tracker init\` on $now_iso
 schema_version = 1
@@ -350,14 +389,7 @@ repo = "$repo"
 [mode]
 state = "tracker"
 opted_in_at = "$opted_in_at"
-opted_in_by = "$opted_in_by"
-
-[mirror]
-enabled = true
-location_backlog   = "BACKLOG.md"
-location_status    = "STATUS.md"
-location_changelog = "CHANGELOG.md"
-regenerate_on_write = true
+opted_in_by = "$opted_in_by"$mirror_block
 
 [id_namespace]
 prefix = "$id_prefix"
diff --git a/scripts/validate-pack.py b/scripts/validate-pack.py
index cde216a..71230dc 100755
--- a/scripts/validate-pack.py
+++ b/scripts/validate-pack.py
@@ -2598,7 +2598,8 @@ _TRACKER_PREFER = ("gh", "mcp", "auto")
 _TRACKER_SCHEMA_VERSION = 1
 
 
-def _validate_tracker_toml(path: Path, expected_prefix: str) -> bool:
+def _validate_tracker_toml(path: Path, expected_prefix: str,
+                           mirror_required: bool) -> bool:
     """Validate a single tracker.toml example file.
 
     Returns True on PASS, False on FAIL. Records each failure via
@@ -2608,6 +2609,13 @@ def _validate_tracker_toml(path: Path, expected_prefix: str) -> bool:
     `expected_prefix` is the [id_namespace].prefix value the example
     file is supposed to ship with — "BD" for the pack-side example,
     "TD" for the client-side example.
+
+    `mirror_required` is the per-surface [mirror] requirement (BD-204):
+    True for the client-side example (the client model keeps monolith
+    mirrors until BD-206), False for the pack-side example (the pack
+    deleted its monolith mirrors at BD-203, so the table's absence is
+    valid-by-construction). When the table IS present, its keys are
+    validated on either surface.
     """
     rel = path.relative_to(REPO_ROOT)
     if not path.is_file():
@@ -2681,9 +2689,14 @@ def _validate_tracker_toml(path: Path, expected_prefix: str) -> bool:
              f"{list(_TRACKER_MODES)}, got {mode_state!r}")
         failed = True
 
-    # [mirror] table — presence of the table itself, plus the four
-    # operational keys init-project / mirror regen rely on.
-    mirror = _require("mirror", dict)
+    # [mirror] table — surface-conditional presence (BD-204). Required
+    # on the client surface (mirror_required=True); optional on the
+    # pack surface, where the no-monolith shape omits it entirely.
+    # When present (either surface), the table and its operational
+    # keys are validated as before.
+    mirror = None
+    if mirror_required or "mirror" in data:
+        mirror = _require("mirror", dict)
     if mirror is not None:
         for k, ty in (
             ("enabled", bool),
@@ -2854,7 +2867,10 @@ def check_tracker_config() -> None:
     Both the pack-side `tracker.toml.pack-example` and the client-side
     `project-template/tracker.toml.project-example` must parse as TOML
     and carry the required keys/types per
-    `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1.
+    `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1. The [mirror]
+    table requirement is per-surface (BD-204): required on the client
+    example, optional-by-construction on the pack example (the pack
+    deleted its monolith mirrors at BD-203).
 
     Catches schema drift in the example files that ship to clients
     via `init-project.sh` (per-BD-080 stage S11). If the examples
@@ -2881,8 +2897,13 @@ def check_tracker_config() -> None:
     pack_example = REPO_ROOT / "tracker.toml.pack-example"
     client_example = REPO_ROOT / "project-template" / "tracker.toml.project-example"
 
-    _validate_tracker_toml(pack_example, expected_prefix="BD")
-    _validate_tracker_toml(client_example, expected_prefix="TD")
+    # mirror_required is per-surface (BD-204): the pack example omits
+    # [mirror] (no monolith post-BD-203); the client example keeps it
+    # until BD-206.
+    _validate_tracker_toml(pack_example, expected_prefix="BD",
+                           mirror_required=False)
+    _validate_tracker_toml(client_example, expected_prefix="TD",
+                           mirror_required=True)
 
     # V1 §A.2 acceptance criterion B — mirror-staleness warning when
     # a live tracker.toml exists, mode is tracker, and forward
diff --git a/tracker.toml.pack-example b/tracker.toml.pack-example
index 5f9fff8..11f3715 100644
--- a/tracker.toml.pack-example
+++ b/tracker.toml.pack-example
@@ -1,7 +1,8 @@
 # tracker.toml — pack repo tracker configuration (example)
 #
 # This file is OPTIONAL. Without it, the pack runs in flat-file mode
-# (BACKLOG.md / STATUS.md / CHANGELOG.md as source-of-truth).
+# (the /backlog/ + /changelog/ per-entry trees as source-of-truth;
+# the pack has no monolith mirror files post-BD-203).
 #
 # To enable tracker mode for the pack repo:
 #   1. Copy this file to `tracker.toml` in the pack root.
@@ -30,14 +31,15 @@ state = "flat-file"
 # opted_in_at = "2026-05-15T12:00:00Z"
 # opted_in_by = "you@example.com"
 
-[mirror]
-# Whether write paths regenerate the markdown mirror automatically.
-enabled = true
-# Bare names; trinity ## Document locations resolves to actual paths.
-location_backlog   = "BACKLOG.md"
-location_status    = "STATUS.md"
-location_changelog = "CHANGELOG.md"
-regenerate_on_write = true
+# NO [mirror] table on the pack surface (BD-204, completing BD-203's
+# no-monolith repoint). The pack deleted its monolith mirrors at
+# BD-203 — the /backlog/ + /changelog/ per-entry trees (with
+# regenerated _toc.md) are the sole flat representation, and _toc.md
+# regeneration is not a "mirror file" in the Check 29 sense.
+# validate-pack.py treats the absent table as a no-mirror surface
+# (mirror-staleness N/A). The client-side example
+# (project-template/tracker.toml.project-example) keeps its [mirror]
+# table until BD-206 retires the project-side monolith mirrors.
 
 [id_namespace]
 # "BD" for the pack repo; "TD" for client projects.
```

### 5.2 scripts/tests/* + ride-along

```diff
diff --git a/maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md b/maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md
index 1dea552..a3f6c89 100644
--- a/maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md
+++ b/maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md
@@ -24,7 +24,8 @@ $ gh issue close --help | grep -i reason
 live flip (`/tmp/bd204-c8-flip.log` lines 26-33): `ERROR: partial-write` with
 all five Deprecated/Cancelled entry closes failing —
 `step-8 close: BD-021/022/023/103/123 — failed after 3 attempts` each.
-`completed` (162 Resolved closes succeeded live) and `duplicate` are identical
+`completed` (167 Resolved closes succeeded live, per the flip-log
+`closed:     167` summary line) and `duplicate` are identical
 in both vocabularies; only `not_planned` needed translation.
 
 Why no harness caught it: every fake-gh `issue close` stub accepted any
diff --git a/scripts/tests/tracker-config-schema-test.sh b/scripts/tests/tracker-config-schema-test.sh
index 6a35523..79b0193 100755
--- a/scripts/tests/tracker-config-schema-test.sh
+++ b/scripts/tests/tracker-config-schema-test.sh
@@ -14,7 +14,10 @@
 #   4.  Wrong id_namespace.prefix on client-example → FAIL on that key
 #   5.  Mode value not in the supported set        → FAIL on mode.state
 #   6.  cli_acceleration.prefer not in supported set → FAIL on that key
-#   7.  Missing [mirror] table                     → FAIL on mirror
+#   7.  Missing [mirror] table on CLIENT example   → FAIL on mirror
+#       (BD-204: [mirror] is per-surface — required on the client
+#       example until BD-206; the PACK example omits it post-BD-203,
+#       which Test 1's no-[mirror] GOOD_PACK pins as PASS)
 #   8.  Missing migration.mapping_file             → FAIL on that key
 #   9.  TOML parse error                           → FAIL on parse
 #   10. schema_version = true (bool-as-int trap)   → FAIL on bool (F3)
@@ -22,6 +25,10 @@
 #   12. backend.repo empty string                  → FAIL on empty (F4)
 #   13. Live tracker.toml with stale mirror        → FAIL on staleness (F1)
 #   14. Live tracker.toml flat-file mode           → soft-pass (F1)
+#   15. Live tracker-mode toml, no [mirror]        → soft-pass (BD-204)
+#   16. Live tracker + declared-but-missing mirror → FAIL (BD-204)
+#   17. Pack example WITH [mirror] missing a key   → FAIL (BD-204:
+#       optional-when-absent, but validated when present)
 #
 # Usage: bash scripts/tests/tracker-config-schema-test.sh
 #
@@ -81,7 +88,9 @@ build_fixture() {
 export REAL_REPO_ROOT="$REPO_ROOT"
 
 # Canonical good bodies (modeled on the live example files; minimum
-# set of keys Check 29 inspects).
+# set of keys Check 29 inspects). GOOD_PACK carries NO [mirror] table
+# (BD-204: the live pack example omits it post-BD-203 — Test 1 passing
+# with this body pins that Check 29 accepts the no-[mirror] pack shape).
 read -r -d '' GOOD_PACK <<'TOML' || true
 schema_version = 1
 
@@ -92,13 +101,6 @@ repo = "DShaneNYC/optiquity-ai-agent-config-pack"
 [mode]
 state = "flat-file"
 
-[mirror]
-enabled = true
-location_backlog   = "BACKLOG.md"
-location_status    = "STATUS.md"
-location_changelog = "CHANGELOG.md"
-regenerate_on_write = true
-
 [id_namespace]
 prefix = "BD"
 
@@ -218,22 +220,26 @@ else
 fi
 rm -rf "$fix"
 
-# ── Test 7: Missing [mirror] table ──────────────────────────────────
-printf "\n=== Test 7: missing [mirror] table ===\n"
+# ── Test 7: Missing [mirror] table on the CLIENT example ────────────
+# BD-204: [mirror] is per-surface. The CLIENT example still requires
+# it (until BD-206); the PACK example legitimately omits it (Test 1's
+# GOOD_PACK has no [mirror] and passes). Strip the table from the
+# client body and pin the FAIL.
+printf "\n=== Test 7: missing [mirror] table on client example ===\n"
 # Strip the entire [mirror] block (table header + 5 keys).
-bad=$(printf '%s\n' "$GOOD_PACK" | awk '
+bad=$(printf '%s\n' "$GOOD_CLIENT" | awk '
   /^\[mirror\]$/ { skip=1; next }
   skip && /^\[/ { skip=0 }
   !skip { print }
 ')
-fix=$(build_fixture "$bad" "$GOOD_CLIENT")
+fix=$(build_fixture "$GOOD_PACK" "$bad")
 out=$(run_check29_at "$fix" 2>&1); rc=$?
-if [[ $rc -ne 0 ]]; then t_pass "7.1 missing mirror → exit nonzero"
-else t_fail "7.1 missing mirror → exit nonzero" "rc=$rc"; fi
-if echo "$out" | grep -q "missing required key: mirror"; then
-    t_pass "7.2 message names mirror as missing"
+if [[ $rc -ne 0 ]]; then t_pass "7.1 missing mirror on client → exit nonzero"
+else t_fail "7.1 missing mirror on client → exit nonzero" "rc=$rc"; fi
+if echo "$out" | grep -q "project-example — missing required key: mirror"; then
+    t_pass "7.2 message names mirror as missing on the client example"
 else
-    t_fail "7.2 message names mirror as missing" "out=${out:0:400}"
+    t_fail "7.2 message names mirror as missing on the client example" "out=${out:0:400}"
 fi
 rm -rf "$fix"
 
@@ -528,6 +534,31 @@ else
 fi
 rm -rf "$fix"
 
+# ── Test 17: Pack example WITH [mirror] but missing a key → FAIL ────
+# BD-204 negative case — [mirror] is OPTIONAL on the pack example, but
+# when the table IS present its keys are still validated (the schema
+# branch must not widen into ignoring a malformed table).
+printf "\n=== Test 17: pack example with malformed [mirror] ===\n"
+read -r -d '' PACK_BAD_MIRROR <<'TOML' || true
+[mirror]
+enabled = true
+location_backlog   = "BACKLOG.md"
+regenerate_on_write = true
+TOML
+bad="$GOOD_PACK
+
+$PACK_BAD_MIRROR"
+fix=$(build_fixture "$bad" "$GOOD_CLIENT")
+out=$(run_check29_at "$fix" 2>&1); rc=$?
+if [[ $rc -ne 0 ]]; then t_pass "17.1 present-but-malformed mirror on pack → exit nonzero"
+else t_fail "17.1 present-but-malformed mirror on pack → exit nonzero" "rc=$rc out=${out:0:400}"; fi
+if echo "$out" | grep -q "pack-example — missing required key: mirror.location_status"; then
+    t_pass "17.2 message names the missing mirror key on the pack example"
+else
+    t_fail "17.2 message names the missing mirror key on the pack example" "out=${out:0:400}"
+fi
+rm -rf "$fix"
+
 # ── Summary ─────────────────────────────────────────────────────────
 printf "\n=== Summary ===\n"
 printf "PASS: %d\n" "$PASS"
diff --git a/scripts/tests/tracker-init-test.sh b/scripts/tests/tracker-init-test.sh
index a399538..80434f7 100755
--- a/scripts/tests/tracker-init-test.sh
+++ b/scripts/tests/tracker-init-test.sh
@@ -10,7 +10,10 @@
 #   3. Templates verification — missing template files surface
 #      not-found typed code.
 #   4. tracker.toml emission — written shape matches V1 §3.1; opted_in_at
-#      preservation across re-runs; default values.
+#      preservation across re-runs; default values. Surface-aware
+#      [mirror] emission (BD-204): pack configs omit the table (no
+#      monolith post-BD-203); client configs keep the bare-name keys
+#      (until BD-206).
 #   5. Label canonical set — tracker_labels_canonical_set emits the
 #      expected count + every required family member.
 #
@@ -236,6 +239,21 @@ assert_eq "3.3 id_namespace.prefix=BD"  "BD"     "$(tracker_config_get "$cfg" id
 assert_eq "3.3 mapping_file path"       ".pack-tracker/id-map.json" \
     "$(tracker_config_get "$cfg" migration.mapping_file)"
 
+# 3.3b BD-204: pack-surface init writes NO [mirror] table. The pack
+# surface has no monolith mirrors post-BD-203 (per-entry trees are the
+# sole flat representation); validate-pack.py Check 29′ treats the
+# absent table as a no-mirror surface.
+if grep -q '^\[mirror\]' "$cfg"; then
+    t_fail "3.3b pack-surface config omits [mirror] table" "found [mirror] in $cfg"
+else
+    t_pass "3.3b pack-surface config omits [mirror] table"
+fi
+if grep -qE 'location_backlog|location_status|location_changelog|regenerate_on_write' "$cfg"; then
+    t_fail "3.3c pack-surface config has no mirror keys" "found a mirror key in $cfg"
+else
+    t_pass "3.3c pack-surface config has no mirror keys"
+fi
+
 # 3.4 opted_in_at persists across re-runs.
 prior_opted_in=$(tracker_config_get "$cfg" mode.opted_in_at)
 sleep 1   # ensure timestamp would change if we re-wrote it
@@ -245,6 +263,32 @@ export PATH="$PATH_SAVED"
 new_opted_in=$(tracker_config_get "$cfg" mode.opted_in_at)
 assert_eq "3.4 opted_in_at preserved across re-runs" "$prior_opted_in" "$new_opted_in"
 
+# 3.5 BD-204: client-surface init KEEPS the [mirror] table with the
+# bare-name keys (the client model still has monolith mirrors until
+# BD-206; bare names resolve via the project trinity ## Document
+# locations — see project-template/tracker.toml.project-example).
+TR_CLIOK=$(mktemp -d -t tinit-cliok.XXXXXX)
+mkdir -p "$TR_CLIOK/docs/pack"  # client surface marker
+mkdir -p "$TR_CLIOK/.github/ISSUE_TEMPLATE"
+touch "$TR_CLIOK/.github/ISSUE_TEMPLATE/work-item.yml"
+touch "$TR_CLIOK/.github/ISSUE_TEMPLATE/inbound.yml"
+touch "$TR_CLIOK/.github/ISSUE_TEMPLATE/config.yml"
+
+export PATH="$FAKE_BIN_TPL:$PATH_SAVED"
+output=$(tracker_init_run --repo-root "$TR_CLIOK" --backend github --repo your-org/y --no-forward 2>&1)
+rc=$?
+export PATH="$PATH_SAVED"
+assert_eq "3.5 client happy-path rc=0" "0" "$rc"
+cfg_cli="$TR_CLIOK/docs/pack/tracker.toml"
+[[ -f "$cfg_cli" ]] || t_fail "3.5 client tracker.toml exists at docs/pack/" "missing $cfg_cli"
+assert_eq "3.5 mirror.enabled=true"      "true"         "$(tracker_config_get "$cfg_cli" mirror.enabled)"
+assert_eq "3.5 mirror.location_backlog"  "BACKLOG.md"   "$(tracker_config_get "$cfg_cli" mirror.location_backlog)"
+assert_eq "3.5 mirror.location_status"   "STATUS.md"    "$(tracker_config_get "$cfg_cli" mirror.location_status)"
+assert_eq "3.5 mirror.location_changelog" "CHANGELOG.md" "$(tracker_config_get "$cfg_cli" mirror.location_changelog)"
+assert_eq "3.5 mirror.regenerate_on_write=true" "true"  "$(tracker_config_get "$cfg_cli" mirror.regenerate_on_write)"
+assert_eq "3.5 id_namespace.prefix=TD"   "TD"           "$(tracker_config_get "$cfg_cli" id_namespace.prefix)"
+rm -rf "$TR_CLIOK"
+
 rm -rf "$FAKE_BIN_TPL" "$TR_OK"
 
 # ─────────────────────────────────────────────────────────────────
```

## 6. Verification output (all FOREGROUND, this session)

### 6.1 Writer-shape probes (direct, isolated /tmp dirs)

- New writer, pack: `grep -c '\[mirror\]' p.toml` → 0; config flows
  `[mode]` → blank line → `[id_namespace]` (visually verified via sed dump).
- New writer, client vs HEAD writer (extracted via `git show
  HEAD:scripts/lib/tracker-init.sh`), same inputs, timestamps normalized:
  `diff` → empty → **"CLIENT BYTE-PARITY (modulo timestamps): OK"**.

### 6.2 Syntax checks

```
bash -n scripts/lib/tracker-init.sh                      → OK
bash -n scripts/tests/tracker-init-test.sh               → OK
bash -n scripts/tests/tracker-config-schema-test.sh      → OK
python3 ast.parse(scripts/validate-pack.py)              → parses OK
```

(`bash -n` of tracker-init.sh re-run after the final comment tweak → OK.)

### 6.3 Real tree

| Command | Result |
|---|---|
| `bash scripts/tests/tracker-config-schema-test.sh` | **PASS: 34 / FAIL: 0** (incl. new 7.1/7.2 retarget + 17.1/17.2) |
| `bash scripts/tests/tracker-init-test.sh` | **Passed: 101 / Failed: 3** — all 3 ENVIRONMENTAL, classified below |
| `python3 scripts/validate-pack.py` | **rc=1 — EXACTLY the 3 known POQ-1 issues** (`tracker.toml — mirror file 'BACKLOG.md'/'STATUS.md'/'CHANGELOG.md' ... does not exist on disk`), zero issues from this change. Expected: the EXISTING live `tracker.toml` still declares `[mirror]`; its correction is Pack Chat's separate edit per the prompt. Check 29's example-schema lines are OK for both examples on the real tree. |
| `bash test-fixtures/build.sh --all --clean` (run TWICE — after main edits and again after the final comment tweak) | rc=0 both times; `git diff --quiet -- test-fixtures/manifest.txt` → **MANIFEST DIFF EMPTY** both times |
| `bash test-fixtures/build.sh --verify` | rc=0 |

**Classification of the 3 real-tree init-test failures (legs 1.1/1.2/1.3):**
environmental, pre-existing-by-construction, NOT in the POQ-1 validate-pack
set but the same runtime-artifact root cause. Those legs call
`tracker_init_run` without `--repo-root`, defaulting to `$(pwd)` = the real
tree, where the Pack-Chat-owned gitignored `.pack-tracker/id-map.json` trips
the prior-state safety rail ("prior tracker state found") BEFORE flag
validation ever runs. That rail (tracker-init.sh, prior-state block in
`tracker_init_run`) is untouched by this diff, and the failure path never
reaches `_tracker_init_write_config`. Proof: the identical suite in the
isolated checkout (no `.pack-tracker/`) → **104/0** (§6.4).

### 6.4 Isolated checkout — FULL CI battery

Copy method: `rsync -a` of the working tree to `/tmp/bd204-impl-checkout`
EXCLUDING root `tracker.toml` + `.pack-tracker/` (prompt-sanctioned method).
The `.git` directory was file-copied in (CI runners have it; the detect
suite's "real pack root → valid" leg requires it) and ZERO git commands were
executed inside the copy — the CI step `git checkout HEAD --
test-fixtures/manifest.txt` was emulated by a saved-file copy/`cmp`
(result: manifest identical after rebuild, restore a no-op).

Every `run:` step of `.github/workflows/validate-pack.yml` (lines 95-296),
in CI order, all rc=0:

| Step | Result |
|---|---|
| `python3 scripts/validate-pack.py` | rc=0 — PASSED, all checks clean |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | rc=0 — PASSED, all checks clean |
| test-detect | rc=0, 100 passed, 0 failed |
| tracker-provider-test | rc=0, 160 |
| tracker-config-test | rc=0, 32 |
| **tracker-init-test** | **rc=0, 104 / 0 (incl. new 3.3b, 3.3c, 3.5 ×7)** |
| tracker-agent-read-test | rc=0, 57 |
| tracker-migrate-forward-test | rc=0, 190 |
| tracker-migrate-reverse-test | rc=0, 147 |
| tracker-migrate-roundtrip-test | rc=0, 70 |
| test-tracker-phase-task | rc=0, 100 |
| test-tracker-links | rc=0, 43 |
| test-tracker-cycle-check | rc=0, 26 |
| tracker-errors-test | rc=0, 60 |
| **tracker-config-schema-test** | **rc=0, 34 / 0** |
| recommendation-state-schema-test | rc=0, 19 |
| test-per-entry | rc=0, 57 |
| checks-32-33-34 / 36-37-38 / 39 / 40 / 41 / 18 / 16 / 19 / 42 / 43 / 44 / 45 / 46 / removed-doc-advisory / 49-field-faithfulness | rc=0 ×15, all "All tests passed." (32-33-34: PASS 85) |
| bd129 / bd130 / bd132 / bd133 / bd134 | rc=0 ×5 (14 / 24 / 29 / pass / 24) |
| recommendation-test / pack-help-test / test-customization-preserve | rc=0 ×3 |
| test-init-project / test-migrate-v10-to-v11 (+ -dry-run / -gates / -decompose) | rc=0 ×5 |
| test-migrator-core / -manifest / -capability-translation | rc=0 (19 / 12 / 12) |
| `test-fixtures/build.sh --all --clean` + manifest restore-emulation + `--verify` | rc=0; manifest identical; verify rc=0 |
| test-v11-realistic-ot | rc=0, 33/33 |
| test-migrator-skills / test-persona-contracts | rc=0 (19 / all PASS) |
| template-translations / template-version / test-issue-forms | rc=0 ×3 |
| Live oracle `tracker-bd204-lossless-roundtrip-test.sh` (unattended) | pinned `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0 — default-SKIP honored, NOT run live |

After the final tracker-init.sh comment tweak, the edited file was re-synced
into the copy and tracker-init-test re-run → 104/0 again.

## 7. Plan deviations

**None.** All work matches the user-approved design baseline (pass-1 review
POQ-1 assessment): pack omits `[mirror]`; client keeps current keys; example
reconciled; Check 29 example-schema branch added (the staleness leg needed
nothing); readers audited (no change needed); tests extended; ride-along
digit corrected. Two judgment calls within the stated scope, flagged for
transparency:

1. The pack example's HEADER comment (lines 3-5 of the file) named the
   deleted monoliths as the flat-file source-of-truth; reconciling "to the
   same no-`[mirror]` shape" was read as including this directly-
   contradicted comment. One sentence changed.
2. Schema-suite Test 7 could not survive as-was (its premise — pack example
   missing `[mirror]` → FAIL — is inverted by the approved design): it was
   re-targeted at the client example rather than deleted, preserving the
   missing-table failure-message pin.

## 8. POQs introduced

1. **`maintenance-docs/v11-research/ARCHITECTURE.md` §3.1 schema spec**
   presumably still shows `[mirror]` as an unconditional schema table.
   Out of scope (rule 10: maintenance-docs design records beyond the named
   ride-along were not in the deliverable list). Disposition: surfaced to
   Pack Chat — candidate for the architect-doc-vs-reality reconciliation
   chain (Pack memory) when BD-204 closes; recommended default: a §3.1
   addendum noting the per-surface `[mirror]` requirement realized at
   BD-204 (consumers: `scripts/lib/tracker-init.sh
   _tracker_init_write_config` + `scripts/validate-pack.py
   _validate_tracker_toml`).
2. **`tracker.toml.pack-example` `[mode]` comment** ("tracker = use tracker
   as source-of-truth; mirrors regenerated") is now slightly stale on the
   pack surface (nothing is regenerated there). Left unchanged — generic
   mode semantics, immediately clarified by the new no-`[mirror]` comment
   below it. Disposition: noted; Pack Chat may fold a 1-line tweak into the
   live-config correction commit or drop it.
3. **Init-suite legs 1.1-1.3 are cwd-sensitive** (fail on any cwd carrying
   `.pack-tracker/id-map.json` or lacking a surface marker). Pre-existing
   test design, green in CI by construction. Disposition: noted only; a
   hardening (explicit `--repo-root` temp dirs for those legs) would be a
   trivial future test-hygiene item, not anchored here per OQ-1
   (new-BD-opens need user discussion).

## 9. Boundary discipline check (P-missed-7)

No project-side file was edited: the diff touches `scripts/` (shared,
pack-only-permitted), pack-root `tracker.toml.pack-example`, and
`maintenance-docs/` reports. `project-template/tracker.toml.project-example`
was read for parity awareness ONLY. No pack-only reference was introduced
into any project-side surface; the client-surface behavior change is none —
byte-parity — and lives entirely in shared `scripts/` per the prompt's
scoping note. Project-side SSOT investigation: the client mirror contract's
project-side SSOT is `project-template/tracker.toml.project-example` (+ the
project trinity "## Document locations"), which this fix leaves untouched
and defers to BD-206 — consistent with that SSOT's current state.

## 10. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| Pack-surface init writes NO `[mirror]` | PASS | §6.1 probe (grep -c = 0); init-test 3.3b/3.3c green |
| Client-surface init keeps current bare-name keys, byte-identical | PASS | §6.1 byte-parity diff empty; init-test 3.5 ×7 green |
| `tracker.toml.pack-example` reconciled to no-`[mirror]` | PASS | §5.1 diff; Check 29 "schema OK" on real tree |
| Check 29′ absent-table behavior verified; absence valid-by-construction | PASS | §4.2 before/after + E2E probe; staleness leg pre-verified (Tests 15/16 green) |
| `tracker-config.sh` readers guarded if they assume the table | PASS (no change needed) | §4.3 exhaustive consumer grep |
| Tests pin all three required behaviors | PASS | init 3.3b/3.3c (pack no-mirror), 3.5 (client keys), schema Test 1 GOOD_PACK + Tests 7/17 (validate-pack accepts pack config/example without `[mirror]`, still rejects client-missing and pack-malformed) |
| Ride-along: 162 → 167 in prior IMPL-REPORT §1 | PASS | §5.2 diff; flip-log line `closed:     167` quoted |
| Modified suites green + isolated full battery green | PASS | §6.3 + §6.4 |
| Real-tree failures classified against POQ-1 set | PASS | §6.3 (3 validate-pack POQ-1 issues; 3 init-test cwd-artifact legs, same runtime-artifact root cause, proven environmental) |
| Manifest regenerated, diff empty | PASS | §6.3 (twice) |
| No touch of root `tracker.toml` / `.pack-tracker/` | PASS | end-state `git status` unchanged for both (§11) |

## 11. Files changed inventory

| Path | Type |
|---|---|
| `scripts/lib/tracker-init.sh` | modified |
| `scripts/validate-pack.py` | modified |
| `tracker.toml.pack-example` | modified |
| `scripts/tests/tracker-config-schema-test.sh` | modified |
| `scripts/tests/tracker-init-test.sh` | modified |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md` | modified (ride-along, 1 figure) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-MIRROR-KEYS.md` | new (this report) |

End-state `git status --short`: exactly the six ` M` entries above + the
pre-existing untracked `?? tracker.toml` (+ this report, untracked).
`test-fixtures/manifest.txt` NOT in the diff (rebuild produced no change).

## 12. Proposed commit subject

```
fix: v11 — BD-204 surface-aware tracker.toml [mirror] writer (pack omits; no-monolith repoint completes) (pack-only)
```

Check 36 note: the diff is exclusively pack-side (`scripts/`, pack-root
example, `maintenance-docs/`) — no `project-template/` or `supporting-docs/`
path anywhere; the `pack-only` keyword claim holds.

## Read-in-full attestation (rule 5)

| File | Lines read |
|---|---|
| `CLAUDE.md` incl. complete `## Pack memory` | 579 (full, in-context) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CLOSE-REASON-FIX.md` | 302 (full; §POQ-1 = Assessment 4) |
| `memory/feedback_verify_full_ci_suite.md` | 42 (full) |
| `memory/feedback_edit_in_place_not_full_rewrite.md` | 14 (full) |
| `memory/feedback_manifest_regen_on_v11_surface.md` | 15 (full) |
| `memory/feedback_agent_output_rules_applied_block.md` | 14 (full) |
| Conditional MUST-READs fired and honored | `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206-235) + § regenerate-manifest-v11-surface (lines 479-533) |
| Section reads per prompt | `tracker-init.sh` (full, 415 lines at base); Check 29′ + `_validate_tracker_toml` + `_check_mirror_staleness` (`validate-pack.py` 2600-2899); `tracker-config.sh` (full, 333); `tracker-mirror.sh` (full, 105); `tracker.toml.pack-example` (full); `project-template/tracker.toml.project-example` (mirror block, read-only); `tracker-init-test.sh` (full, 478 at base); `tracker-config-schema-test.sh` (full, 537 at base); `/backlog/BD-206.md` (head); skills: implementation-report, commit-discipline, verification-harness, boundary-investigation |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Git verbs this session: `rev-parse`, `status`, `branch --show-current`, `diff` (several), `show HEAD:<path>` (×2, read-only file extraction) — all read-only. No add/commit/push/tag/stash/reset/restore/checkout anywhere; the CI manifest-restore step was emulated with `cp`/`cmp` in the /tmp copy specifically to avoid `git checkout` there. Output = working-tree edits + this report. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive ops on trusted state: `rm -rf` only on self-created /tmp dirs (`bd204-writer-probe`, `bd204-impl-checkout`, mktemp fixtures); real-tree `tracker.toml` + `.pack-tracker/` untouched (end-state `git status` §11 = pre-flight shape + my 6 edits + this report). | COMPLIANT |
| 3. preflight-stop-means-stop | Emitted before this report's Write sequence: `PREFLIGHT: 6/6 in-scope file edits complete; verification PASS; HEAD 0fc2ec0254bbca1c25d5765adfd4e9bc94287847; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-MIRROR-KEYS.md`. No parent stop message received at any point. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table; per-rule quoted evidence; conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block read this session (format template followed). | COMPLIANT |
| 5. agents-read-rule-docs-in-full | Attestation table above — all six named files read IN FULL with line counts; section reads enumerated; both fired conditional rationale sections read. | COMPLIANT |
| 6. verify-full-ci-suite | Modified suites on the real tree (§6.3: schema 34/0; init 101/3 with all 3 classified environmental) + FULL CI battery in the isolated /tmp checkout (§6.4: every workflow `run:` step rc=0, FOREGROUND, per-step results tabled). Live oracle default-SKIP verified (pinned SKIP line, rc=0); NOT run live. Real-tree validate-pack failures = exactly the 3 POQ-1 issues which this fix intentionally does NOT clear (live-config edit is Pack Chat's). | COMPLIANT |
| 7. regenerate-manifest-v11-surface | `scripts/` touched → `bash test-fixtures/build.sh --all --clean` run on the real tree (twice; second after the final comment tweak) → rc=0; `git diff --quiet -- test-fixtures/manifest.txt` → EMPTY both times; `--verify` rc=0. Manifest therefore NOT in the edit set; stated reason verified in-session: fixture `scripts/lib/` trees carry only `detect.sh` (v11-tracker-on + v11-realistic-ot listed directly) — `tracker-init.sh` / `validate-pack.py` / tests / pack-root example do not ship into fixtures. | COMPLIANT |
| 8. edit-in-place-not-full-rewrite | All edits via targeted Edit calls (no full-file Write of any existing file). Edited regions re-read after editing: `tracker-init.sh` writer region (re-read, one comment-precision fix applied, re-verified with `bash -n` + writer probes + 104/0 suite), `tracker.toml.pack-example` (full re-read in-session); §5 diffs confirm untouched text byte-stable (context lines match base). | COMPLIANT |
| 9. pack-only | End-state `git status --short` = exactly the 6 in-scope ` M` files + pre-existing `?? tracker.toml` + this report (untracked, maintenance-docs). No `project-template/` or `supporting-docs/` path in the diff; manifest not drifted. | COMPLIANT |
| 10. scope-deliverables-to-the-ask | Deliverables = exactly: surface-aware writer (T1) + example reconcile (T2) + Check 29′ absent-table handling (T3) + reader audit (T4, no-op with evidence) + tests (T5/T6) + the one-figure ride-along (T7). Out-of-scope discoveries surfaced as POQs §8 (ARCHITECTURE §3.1 staleness, [mode] comment nit, init-test cwd-sensitivity) — none acted on. | COMPLIANT |

— end of report —
