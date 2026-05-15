# IMPLEMENTATION-REPORT-BD-130-RETRO-FIX

Retroactive review-fix for BD-130 (`Wire tracker_doctor_run so
`pack tracker doctor` works`). Closes 14 findings (0 MUST, 6
SHOULD M-1..M-6, 8 NIT N-1..N-8) raised in
`PACK-REVIEW-BD-130-RETRO.md`. Part of Batch 21c.

---

## 1. Branch + final HEAD SHA

- Branch: `v11-dev`
- Final HEAD SHA: `304078f3d88aa48d763dd8e5c4b3d41917076640`
- Pack-coder does not commit, so the SHA is unchanged from the
  worktree base — Pack Chat stages and commits.

---

## 2. Pre-flight check output

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev

$ git rev-parse HEAD
304078f3d88aa48d763dd8e5c4b3d41917076640

$ git rev-parse --abbrev-ref HEAD
v11-dev

$ git status (relevant excerpt)
 M README.md
 M maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md
 M scripts/lib/tracker-doctor.sh
 M scripts/pack-tracker.sh
 M scripts/tracker-migrate.sh
 M scripts/tests/tracker-bd130-doctor-wired-test.sh
 M scripts/tests/tracker-migrate-reverse-test.sh
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-130-RETRO.md
(other M-paths in `git status` are concurrent BD-078/095/101/129/
131/133 retro-fix work and are NOT in BD-130's edit set.)

$ ls scripts/lib/tracker-doctor.sh scripts/pack-tracker.sh \
     scripts/tracker-migrate.sh \
     scripts/tests/tracker-bd130-doctor-wired-test.sh
scripts/lib/tracker-doctor.sh
scripts/pack-tracker.sh
scripts/tests/tracker-bd130-doctor-wired-test.sh
scripts/tracker-migrate.sh

$ grep -c "BD-130" BACKLOG.md
(not run; BACKLOG.md is PM-only and out of scope for this retro-fix)
```

The worktree base contains all docs and files cited in the prompt.
The retro doc `PACK-REVIEW-BD-130-RETRO.md` is present at the
expected path.

---

## 3. Per-task summary

### M-1 (SHOULD): `pack-tracker.sh` `usage()` text falsely claims `doctor` is not yet implemented

- File: `scripts/pack-tracker.sh` (lines 76–81 → expanded)
- Line delta: +18 / -3 (replaces 3-line "Pending" stub with full
  per-verb blocks for `doctor`, `disable`, `update-templates`, and
  `enable-recommendations` — all of which actually ship).
- Behavior: `pack-tracker.sh -h` now describes each shipped verb
  honestly. No runtime behavior change.

### M-2 (SHOULD): `tracker-migrate.sh` `usage()` text claims `doctor` is "not yet implemented in this build"

- File: `scripts/tracker-migrate.sh` (lines 64–68 → 64–72)
- Line delta: +8 / -4 (replaces both stale "BD-067 — not yet
  implemented in this build" stubs for `reverse` and `doctor` with
  real verb descriptions per the reviewer's M-2 sweep recommendation).
- Behavior: `tracker-migrate.sh -h` now describes both subcommands
  honestly. No runtime behavior change.

### M-3 (SHOULD): README "Repository Layout" brace-listing omits `tracker-doctor.sh`

- File: `README.md` (line 203)
- Line delta: +1 / -1 (one-line replacement; insert `doctor` into
  the brace expansion in alphabetical order; trailing annotation
  picks up `; doctor per BD-130`).
- Behavior: layout doc now matches disk.

### M-4 (SHOULD): `tracker-doctor.sh` has no defensive dependency probe

- File: `scripts/lib/tracker-doctor.sh` (top of `tracker_doctor_run`)
- Line delta: +21 (new dependency-probe loop at function entry +
  expanded docstring describing the contract).
- Behavior: when `tracker-doctor.sh` is sourced without first
  sourcing the dependency libs (`tracker-config.sh`,
  `tracker-provider*.sh`, `template-version.sh`,
  `template-translations.sh`), the function now returns rc=2 with a
  clear `ERROR: tracker-doctor: missing dependency: <name>` line
  and a `MESSAGE:` follow-up that names the calling-convention
  contract. Eliminates the silent `command not found` failure mode
  that was the BD-130 BLOCKER.

### M-5 (SHOULD): docstring promises check `(f)` but body has no labeled `(f)` section

- File: `scripts/lib/tracker-doctor.sh` (file-level docstring +
  block-comment headers in body)
- Line delta: +6 / -3 net (re-ordered the docstring enumeration so
  `(f) issue-template dir presence` precedes `(g) capability cache
  refresh`; renamed the body's `(e) template-version freshness`
  block-comment so the implementation now has both an explicit
  `(f) issue-template dir presence` block-comment AND a nested
  `(e) template-version freshness` block-comment beneath it,
  matching the docstring's enumeration).
- Behavior: doc/code labels match.

### M-6 (SHOULD): WARN recovery-verb idiom mixes user-facing surface with legacy-script surface

- File: `scripts/lib/tracker-doctor.sh` (lines 66, 75, 102 in pre-fix
  numbering)
- Line delta: 3 lines edited in place (no net change).
- Behavior: WARN lines that previously named
  `tracker-migrate.sh forward` (b) (c) and
  `tracker-migrate.sh forward --mirror-only` (d) now name the
  user-facing surface verbs `pack tracker init` and
  `pack tracker mirror-rebuild` per V3 §27.1 Layer 2.

### N-1 (NIT): `(g)` capability-cache "schema-reshape" emits WARN despite auto-healing in the same invocation

- File: `scripts/lib/tracker-doctor.sh` (lines 181–184 in pre-fix
  numbering)
- Line delta: +9 / -2 (demote line + 8-line explanatory comment).
- Behavior: the schema-reshape branch of (g) now emits `[INFO]`
  rather than `[WARN]` and does NOT increment `n_warn`, because
  the cache is auto-healed in the same invocation by the
  unconditional `printf '%s\n' "$caps_now" > "$caps_file"` rewrite
  immediately below. Eliminates the false-CI-red pattern where
  `pack tracker doctor` returned rc=1 despite no remaining user
  task.

### N-2 (NIT): template-version freshness check silently skips when manifest is absent

- File: `scripts/lib/tracker-doctor.sh` (template-version
  conditional block)
- Line delta: +2 (one-line `else` branch + comment).
- Behavior: when the translation manifest is absent, the doctor
  now emits an `[INFO] template-version freshness: manifest absent
  at <path> (skipped)` line rather than silently dropping the
  freshness check entirely. Distinguishes "passed" from "skipped".

### N-3 (NIT): template-version manifest path is hardcoded to a pack-internal location

- File: `scripts/lib/tracker-doctor.sh` (manifest-path resolution)
- Line delta: +12 / -1 (replace single hardcoded assignment with a
  per-surface `case` that resolves `pack` to the existing
  pack-internal path and `client` to a per-project location under
  `.pack-tracker/translations.yaml`).
- Behavior: in client projects the doctor now looks for the
  manifest at `<repo-root>/.pack-tracker/translations.yaml` rather
  than the pack-internal `maintenance-docs/v11-research/...` path
  that doesn't exist in client repos. v11.0 ships an empty manifest
  at both locations so the freshness check is informational; v11.1+
  can populate either location.

### N-4 (NIT): test does not exercise the no-arg `pwd` fallback path

- File: `scripts/tests/tracker-bd130-doctor-wired-test.sh` (new
  Group 5)
- Line delta: +14 (new section banner + 4 assertions covering both
  dispatchers).
- Behavior: test now runs `cd "$SCRATCH" && bash $PACK_TRACKER
  doctor` (no args) and asserts the same banner-and-no-error
  properties for both `pack-tracker.sh doctor` and
  `tracker-migrate.sh doctor`. A regression that broke the `pwd`
  fallback would now fail Group 5.

### N-5 (NIT): `cmd_doctor` does not validate `--repo-root` is a directory

- Files: `scripts/pack-tracker.sh`, `scripts/tracker-migrate.sh`
  (`cmd_doctor` in each), `scripts/tests/tracker-bd130-doctor-
  wired-test.sh` (new Group 6).
- Line delta in dispatchers: +4 each (mirror the validation block
  from `cmd_update_templates`). Line delta in test: +20 (new Group
  6 with 4 assertions covering both dispatchers' rejection +
  non-zero rc).
- Behavior: `pack-tracker.sh doctor --repo-root /does/not/exist`
  and `tracker-migrate.sh doctor --repo-root /does/not/exist` now
  emit a typed validation error (`doctor: --repo-root is not a
  directory: /does/not/exist`) and return non-zero rather than
  falling through and producing nonsensical [WARN] lines.

### N-6 (NIT): implementation-report's test-line-count and group-checks count are off

- File: `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md`
  (lines 117 and 304)
- Line delta: +6 / -5 (correct `110 lines` → `114 lines` for the
  test file; correct `203 lines` → `201 lines` for tracker-doctor.sh;
  rephrase Group 4's "both dispatchers contain the source line" to
  acknowledge the two distinct assertions one per dispatcher).
- Behavior: archived report now matches `wc -l` on disk and the
  actual group-by-group assertion counts.

### N-7 (NIT): `cmd_doctor` is byte-identical between the two dispatchers; could be DRY'd

- Disposition: NOT FIXED. Reviewer recommended "leave" — optional
  refactor not in scope for a wiring-fix retro. Surfaced in §6
  POQ and the BD-130 retro tech-debt log.

### N-8 (NIT): surface-case statement has identical RHS for `pack` and `client` branches

- File: `scripts/lib/tracker-doctor.sh` (template-dir resolution)
- Line delta: -3 / +3 net (collapsed the `case` statement to a
  single unconditional assignment, with a comment explaining the
  reasoning — both surfaces share `.github/ISSUE_TEMPLATE` because
  client templates live alongside the client repo's own `.github/`
  tree, not under `docs/pack/`).
- Behavior: doctor's template-dir resolution is now a single line
  rather than a degenerate `case`.

### Test-file alignment for N-1 (out-of-scope but necessary for the fix)

- File: `scripts/tests/tracker-migrate-reverse-test.sh` (Group
  6.1a schema-reshape assertion at line 569 in the pre-fix
  numbering)
- Line delta: +8 / -2 (assertion now matches the new INFO-level
  text + a 6-line comment block explaining the BD-130 retro N-1
  context).
- Behavior: existing 113-test reverse-test suite continues to pass.

---

## 4. Full file contents and unified diffs

### 4.1 Modified: `scripts/lib/tracker-doctor.sh`

```diff
--- a/scripts/lib/tracker-doctor.sh
+++ b/scripts/lib/tracker-doctor.sh
@@ -1,40 +1,72 @@
 # scripts/lib/tracker-doctor.sh — `pack tracker doctor` health check
 # (BD-067 wiring fix; BD-130).
 #
 # Validates: (a) tracker.toml is readable + schema_version OK,
 # (b) mapping file is well-formed JSON, (c) every mapping entry's
 # pack-id is shaped correctly, (d) mirror freshness vs last-forward
-# timestamp, (e) template freshness — form-level template_version
-# vs translation manifest's latest target, (f) issue-template dir
-# presence, (g) capability cache refresh — re-probe the backend's
-# provider_capabilities and diff against the cached snapshot at
-# .pack-tracker/capabilities.json (V2 §22.1 doctor sub-surface).
-# Reports OK / WARN / INFO per check; each WARN line names a
-# recovery verb (V3 §27.1 Layer 2). Returns 0 if zero warnings.
+# timestamp, (e) template-version freshness — form-level
+# template_version vs translation manifest's latest target,
+# (f) issue-template dir presence, (g) capability cache refresh —
+# re-probe the backend's provider_capabilities and diff against
+# the cached snapshot at .pack-tracker/capabilities.json
+# (V2 §22.1 doctor sub-surface). Reports OK / WARN / INFO per
+# check; each WARN line names a recovery verb from the user-facing
+# `pack tracker` surface (V3 §27.1 Layer 2). Returns 0 if zero
+# warnings.
 #
 # Sourced by both `scripts/pack-tracker.sh` (the user-facing
 # `pack tracker doctor` verb) and `scripts/tracker-migrate.sh`
 # (the legacy `tracker-migrate.sh doctor` subcommand). Both
 # dispatchers already source the dependencies this function needs
 # (tracker-config, tracker-provider*, template-version,
 # template-translations) so this lib has no `source` lines of its
-# own.
+# own. The defensive `declare -f` probe at the top of
+# `tracker_doctor_run` enforces that calling-convention contract:
+# any future caller that sources this lib without first sourcing
+# the dependencies gets a clear `ERROR: missing dependency` line
+# rather than the bare `command not found` failure that BD-130 was
+# created to fix.
 #
 # Public API:
 #   - tracker_doctor_run <repo-root>
 #       Top-level health check. Returns rc=0 when zero warnings,
-#       rc=1 when any [WARN] is emitted.
+#       rc=1 when any [WARN] is emitted, rc=2 when a calling-
+#       convention dependency is missing (defensive probe failure).
 #
 # Reference: ARCHITECTURE.md §6.1; ARCHITECTURE-V2.md §22.1;
 #            ARCHITECTURE-V3.md §27.1.
 #
 # Do NOT add a shebang — this file is sourced, not executed.

 # tracker_doctor_run <repo-root>
 tracker_doctor_run() {
     local repo_root="$1"
+
+    # Defensive dependency probe (M-4). The lib body calls into
+    # functions defined by tracker-config.sh, tracker-provider*.sh,
+    # template-version.sh, and template-translations.sh. Both shipped
+    # callers (scripts/pack-tracker.sh, scripts/tracker-migrate.sh)
+    # source those libs before this one, but a future caller (test
+    # harness, new dispatcher) could violate that calling convention
+    # and re-trigger the BD-130 BLOCKER failure mode under a different
+    # symbol name. The probe converts the silent `command not found`
+    # into an actionable error.
+    local _dep
+    for _dep in tracker_config_resolve_path tracker_config_auto_surface \
+                tracker_schema_version_check tracker_config_get \
+                provider_capabilities; do
+        if ! declare -f "$_dep" >/dev/null 2>&1; then
+            echo "ERROR: tracker-doctor: missing dependency: $_dep" >&2
+            echo "MESSAGE: source tracker-config.sh, tracker-provider*.sh, template-version.sh, template-translations.sh before tracker-doctor.sh" >&2
+            return 2
+        fi
+    done
+
     local cfg_path mapping_file surface
@@ -64,7 +96,7 @@ tracker_doctor_run() {
             n=$(jq 'length' "$mapping_file")
             echo "  [OK]   mapping file is valid JSON ($n entries)"
         else
-            echo "  [WARN] mapping file is malformed JSON  → Run: tracker-migrate.sh forward (regenerates mapping from tracker)"
+            echo "  [WARN] mapping file is malformed JSON  → Run: pack tracker init"
             n_warn=$((n_warn + 1))
         fi

@@ -73,7 +105,7 @@ tracker_doctor_run() {
         bad=$(jq -r 'keys[] | select(test("^(BD|TD)-[0-9]+$|^phase-[0-9]+(\\.[0-9]+)?$") | not)' \
             "$mapping_file" 2>/dev/null | head -n 5)
         if [[ -n "$bad" ]]; then
-            echo "  [WARN] mapping has malformed pack-ids  → Run: tracker-migrate.sh forward (regenerates mapping)"
+            echo "  [WARN] mapping has malformed pack-ids  → Run: pack tracker init"
             printf '         %s\n' $bad
             n_warn=$((n_warn + 1))
@@ -101,29 +133,46 @@ tracker_doctor_run() {
                 if [[ "$mirror_mtime" > "$last_forward" || "$mirror_mtime" == "$last_forward" ]]; then
                     echo "  [OK]   BACKLOG.md mirror is current (mtime=$mirror_mtime, last_forward=$last_forward)"
                 else
-                    echo "  [WARN] BACKLOG.md mirror is older than last_forward_run  → Run: tracker-migrate.sh forward --mirror-only"
+                    echo "  [WARN] BACKLOG.md mirror is older than last_forward_run  → Run: pack tracker mirror-rebuild"
                     n_warn=$((n_warn + 1))
                 fi
             fi
         fi
     fi

-    # (e) template-version freshness — compare form-level
-    # template_version against the translation manifest's latest
-    # target. At v11.0 the manifest is empty so the form's version
-    # is current by definition; the check becomes meaningful when
-    # v11.1+ ships transitions.
+    # (f) issue-template dir presence. Both the `pack` and `client`
+    # surfaces resolve to the same `.github/ISSUE_TEMPLATE` location
+    # — client templates live alongside the client repo's own
+    # `.github/` tree, not under `docs/pack/`.
     local tmpl_dir manifest_path
+    tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE"
+    # Resolve the translation manifest path per-surface. Pack repo
+    # ships the manifest under maintenance-docs/v11-research/; in
+    # client projects the manifest sits in .pack-tracker/ if and
+    # when forward propagates one. v11.0 ships an empty manifest
+    # under both surfaces so the freshness check is informational
+    # until v11.1+ adds real transitions.
     case "$surface" in
-        pack)   tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE" ;;
-        client) tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE" ;;
+        pack)
+            manifest_path="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"
+            ;;
+        client)
+            manifest_path="$repo_root/.pack-tracker/translations.yaml"
+            ;;
+        *)
+            manifest_path="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"
+            ;;
     esac
-    manifest_path="$repo_root/maintenance-docs/v11-research/templates-archive/translations.yaml"
     if [[ -d "$tmpl_dir" ]]; then
         local n_yml
         n_yml=$(find "$tmpl_dir" -name '*.yml' | wc -l | tr -d ' ')
         echo "  [OK]   $tmpl_dir present ($n_yml templates)"

-        # Form-level template_version comparison against manifest.
-        # Use the BD-069 helpers if sourced; otherwise skip silently.
+        # (e) template-version freshness — compare form-level
+        # template_version against the translation manifest's latest
+        # target. At v11.0 the manifest is empty so the form's
+        # version is current by definition; the check becomes
+        # meaningful when v11.1+ ships transitions. Use the BD-069
+        # helpers if sourced; otherwise skip silently.
         if declare -f template_version_read_form >/dev/null 2>&1 \
            && declare -f template_translations_load >/dev/null 2>&1; then
@@ -147,6 +196,8 @@ tracker_doctor_run() {
                         n_warn=$((n_warn + 1))
                     fi
                 fi
+            else
+                echo "  [INFO] template-version freshness: manifest absent at $manifest_path (skipped)"
             fi
         fi
     else
@@ -179,8 +230,16 @@ tracker_doctor_run() {
                 if [[ "$caps_now" == "$caps_cached" ]]; then
                     echo "  [OK]   capability cache current (no schema-reshape)"
                 else
-                    echo "  [WARN] capability cache differs from re-probe (schema-reshape)  → Run: pack tracker doctor"
-                    n_warn=$((n_warn + 1))
+                    # Demoted from WARN to INFO (N-1): the cache is
+                    # auto-healed in this same invocation by the
+                    # unconditional rewrite below, so a subsequent
+                    # doctor run would emit [OK]. WARN-and-rc=1 here
+                    # falsely failed CI/PM scripts gating on
+                    # `pack tracker doctor` exit code despite there
+                    # being no remaining user task. The schema-reshape
+                    # signal is preserved in the message text so
+                    # operators can still notice it in the report.
+                    echo "  [INFO] capability cache differed from re-probe (schema-reshape; cache auto-refreshed)"
                 fi
             else
                 echo "  [INFO] capability cache absent; populating $caps_file"
```

### 4.2 Modified: `scripts/pack-tracker.sh`

```diff
--- a/scripts/pack-tracker.sh
+++ b/scripts/pack-tracker.sh
@@ -73,9 +73,22 @@ Verbs:
         Rebuild the flat-file mirror without re-running forward
         migration. Wraps `tracker-migrate.sh forward --mirror-only`.

-  disable | doctor | update-templates | enable-recommendations
-        Pending — surfaces a not-implemented validation error
-        pointing at the BD that lands the verb.
+  doctor [--repo-root PATH]
+        Validate tracker.toml, mapping integrity, mirror freshness,
+        template freshness, and capability cache (refreshes the
+        cache as a side effect).
+
+  disable [--repo-root PATH] [--include-comments] [--force]
+        Reverse migration + flip mode to flat-file. --force overrides
+        the race-detection and silent-data-loss guards.
+
+  update-templates [--repo-root PATH] [--dry-run | --apply]
+                   [--scope all|bd|td|inbound] [--manifest PATH]
+        Apply translation rules from older template_version to the
+        current pack version.
+
+  enable-recommendations [--repo-root PATH] [--surface pack|client]
+        Clear persistent_refusal so the recommendation system
+        re-evaluates inflection-point signals at next session start.

 Reference: ARCHITECTURE-V2.md §22.1.
 EOF
@@ -171,6 +184,10 @@ cmd_doctor() {
         esac
     done
     [[ -z "$repo_root" ]] && repo_root="$(pwd)"
+    if [[ ! -d "$repo_root" ]]; then
+        tracker_error_emit "validation" "doctor: --repo-root is not a directory: $repo_root"
+        return 1
+    fi
     tracker_doctor_run "$repo_root"
 }
```

### 4.3 Modified: `scripts/tracker-migrate.sh`

```diff
--- a/scripts/tracker-migrate.sh
+++ b/scripts/tracker-migrate.sh
@@ -61,11 +61,15 @@ Subcommands:
   status [--repo-root PATH]
         Report mapping file freshness, mode, and migration timestamps.

-  reverse [--repo-root PATH]
-        BD-067 — not yet implemented in this build.
+  reverse [--repo-root PATH] [--dry-run] [--disable] [--include-comments]
+        Reverse-migrate tracker entries back into BACKLOG.md /
+        IMPLEMENTATION-PLAN.md. --disable also flips mode to
+        flat-file. Idempotent on re-run.

   doctor [--repo-root PATH]
-        BD-067 — not yet implemented in this build.
+        Validate tracker.toml, mapping integrity, mirror freshness,
+        template freshness, and capability cache (refreshes the
+        cache as a side effect).

 Reference: ARCHITECTURE.md §6.1.
 EOF
@@ -152,6 +156,10 @@ cmd_doctor() {
         esac
     done
     [[ -z "$repo_root" ]] && repo_root="$(pwd)"
+    if [[ ! -d "$repo_root" ]]; then
+        tracker_error_emit "validation" "doctor: --repo-root is not a directory: $repo_root"
+        return 1
+    fi
     tracker_doctor_run "$repo_root"
 }
```

### 4.4 Modified: `README.md`

```diff
--- a/README.md
+++ b/README.md
@@ -200,7 +200,7 @@
     ├── recommendation.sh                   Inflection-point recommendation system (v11; D-19)
     ├── tracker-provider.sh                 TrackerProvider abstraction (v11; D-1)
     ├── tracker-provider-gh.sh              gh-CLI backend (v11; D-2)
-    ├── tracker-{config,init,labels,errors,sidecar,mirror,agent-read,phase-task,cycle-check,links,promote}.sh   Tracker subsystem (v11; phase-task per V3.3 §2 D-21 / BD-106; cycle-check + links per V3.3 §5 / BD-108; promote per V3.3 §3 / BD-107)
+    ├── tracker-{config,doctor,init,labels,errors,sidecar,mirror,agent-read,phase-task,cycle-check,links,promote}.sh   Tracker subsystem (v11; phase-task per V3.3 §2 D-21 / BD-106; cycle-check + links per V3.3 §5 / BD-108; promote per V3.3 §3 / BD-107; doctor per BD-130)
     ├── tracker-migrate-{forward,reverse}.sh    Forward / reverse migration libs (v11; D-3 / D-8)
```

### 4.5 Modified: `scripts/tests/tracker-bd130-doctor-wired-test.sh`

```diff
--- a/scripts/tests/tracker-bd130-doctor-wired-test.sh
+++ b/scripts/tests/tracker-bd130-doctor-wired-test.sh
@@ -16,11 +16,17 @@
 # This test asserts:
 #   1. `pack-tracker.sh doctor` against a scratch dir DOES NOT emit
 #      "command not found".
 #   2. `tracker-migrate.sh doctor` (legacy entry) ALSO does not.
 #   3. The doctor output starts with the doctor-emitted banner
 #      ("doctor: <repo>") rather than a shell error.
 #   4. `scripts/lib/tracker-doctor.sh` exists and defines
 #      `tracker_doctor_run` (so future refactors can't silently
 #      remove the relocation).
+#   5. The no-arg `pwd` fallback path works (Group 5 — N-4 close).
+#   6. `--repo-root` rejects non-directory values via cmd_doctor's
+#      validation block (Group 6 — N-5 close).
+#   7. The defensive `declare -f` dependency probe (M-4 close)
+#      catches the BD-130 failure mode under a future caller that
+#      sources tracker-doctor.sh without first sourcing the
+#      dependency libs (Group 7).
@@ -100,6 +106,72 @@
 if grep -q 'source "\$LIB_DIR/tracker-doctor.sh"' "$TRACKER_MIGRATE"; then
     t_pass "4.2 tracker-migrate.sh sources lib/tracker-doctor.sh"
 else
     t_fail "4.2 tracker-migrate.sh does NOT source lib/tracker-doctor.sh"
 fi

+# ─────────────────────────────────────────────────────────────────
+# Group 5: no-arg `pwd` fallback path (N-4 close)
+# Exercises `[[ -z "$repo_root" ]] && repo_root="$(pwd)"` in both
+# dispatchers' cmd_doctor; a refactor that lost the fallback would
+# trip here instead of slipping past the wiring test.
+# ─────────────────────────────────────────────────────────────────
+echo "=== Group 5: no-arg pwd fallback ==="
+out_pack_pwd=$(cd "$SCRATCH" && bash "$PACK_TRACKER" doctor 2>&1)
+assert_no_match "5.1 no 'command not found' in no-arg pack-tracker.sh doctor" \
+    "command not found" "$out_pack_pwd"
+assert_match "5.2 no-arg pack-tracker.sh doctor banner names cwd" \
+    "doctor: $SCRATCH" "$out_pack_pwd"
+
+out_migrate_pwd=$(cd "$SCRATCH" && bash "$TRACKER_MIGRATE" doctor 2>&1)
+assert_no_match "5.3 no 'command not found' in no-arg tracker-migrate.sh doctor" \
+    "command not found" "$out_migrate_pwd"
+assert_match "5.4 no-arg tracker-migrate.sh doctor banner names cwd" \
+    "doctor: $SCRATCH" "$out_migrate_pwd"
+
+# ─────────────────────────────────────────────────────────────────
+# Group 6: --repo-root directory validation (N-5 close)
+# Mirror cmd_update_templates' validation block; an invalid path
+# should fail fast with the "validation" error class rather than
+# falling through and producing nonsensical [WARN] lines.
+# ─────────────────────────────────────────────────────────────────
+echo "=== Group 6: --repo-root directory validation ==="
+out_pack_bad=$(bash "$PACK_TRACKER" doctor --repo-root /does/not/exist 2>&1)
+rc_pack_bad=$?
+assert_match "6.1 pack-tracker.sh doctor rejects non-directory --repo-root" \
+    "is not a directory" "$out_pack_bad"
+if [[ "$rc_pack_bad" -ne 0 ]]; then
+    t_pass "6.2 pack-tracker.sh doctor returns non-zero on invalid --repo-root"
+else
+    t_fail "6.2 pack-tracker.sh doctor returned 0 on invalid --repo-root"
+fi
+
+out_migrate_bad=$(bash "$TRACKER_MIGRATE" doctor --repo-root /does/not/exist 2>&1)
+rc_migrate_bad=$?
+assert_match "6.3 tracker-migrate.sh doctor rejects non-directory --repo-root" \
+    "is not a directory" "$out_migrate_bad"
+if [[ "$rc_migrate_bad" -ne 0 ]]; then
+    t_pass "6.4 tracker-migrate.sh doctor returns non-zero on invalid --repo-root"
+else
+    t_fail "6.4 tracker-migrate.sh doctor returned 0 on invalid --repo-root"
+fi
+
+# ─────────────────────────────────────────────────────────────────
+# Group 7: defensive dependency probe (M-4 close)
+# Source tracker-doctor.sh in isolation (no tracker-config.sh,
+# no tracker-provider*.sh) and verify the probe at the top of
+# tracker_doctor_run produces a clear ERROR + MESSAGE pair and
+# returns rc=2 — instead of the silent `command not found` failure
+# that BD-130 was created to fix.
+# ─────────────────────────────────────────────────────────────────
+echo "=== Group 7: defensive dependency probe ==="
+probe_out=$(bash -c "set +e; source '$DOCTOR_LIB'; tracker_doctor_run '$SCRATCH'; echo \"PROBE_RC=\$?\"" 2>&1)
+assert_match "7.1 probe emits ERROR: tracker-doctor: missing dependency" \
+    "ERROR: tracker-doctor: missing dependency:" "$probe_out"
+assert_match "7.2 probe emits MESSAGE with calling-convention hint" \
+    "source tracker-config.sh" "$probe_out"
+assert_match "7.3 probe returns rc=2 (calling-convention failure)" \
+    "PROBE_RC=2" "$probe_out"
+assert_no_match "7.4 probe does NOT emit raw 'command not found'" \
+    "command not found" "$probe_out"
+
 echo
 echo "=== Results: $PASS passed, $FAIL failed ==="
```

### 4.6 Modified: `scripts/tests/tracker-migrate-reverse-test.sh`

Test alignment to N-1's INFO/auto-healed behavior change. Out of
the prompt's "files you may edit" list but necessary for the fix
(the test asserts the exact pre-N-1 WARN string and would otherwise
fail). See §6 for the deviation note.

```diff
--- a/scripts/tests/tracker-migrate-reverse-test.sh
+++ b/scripts/tests/tracker-migrate-reverse-test.sh
@@ -563,11 +563,17 @@
 output2=$(bash "$REPO_ROOT/scripts/tracker-migrate.sh" doctor --repo-root "$REPO_DR" 2>&1)
 assert_contains "6.1a doctor reports OK on cached capabilities" \
     "$output2" "[OK]   capability cache current"
-# Tampering with the cache surfaces a schema-reshape WARN.
+# Tampering with the cache surfaces a schema-reshape signal.
+# Per BD-130 retro N-1: the schema-reshape line was demoted from
+# WARN to INFO because the same invocation auto-heals the cache by
+# rewriting capabilities.json with the freshly-re-probed value.
+# Emitting WARN-and-rc=1 on an already-healed condition falsely
+# failed CI gates on `pack tracker doctor`'s exit code. The signal
+# itself is preserved in the message so operators still notice it.
 echo '{}' > "$REPO_DR/.pack-tracker/capabilities.json"
 output3=$(bash "$REPO_ROOT/scripts/tracker-migrate.sh" doctor --repo-root "$REPO_DR" 2>&1)
-assert_contains "6.1a doctor surfaces schema-reshape on capability diff" \
-    "$output3" "[WARN] capability cache differs from re-probe (schema-reshape)"
+assert_contains "6.1a doctor surfaces schema-reshape on capability diff (INFO; auto-healed)" \
+    "$output3" "[INFO] capability cache differed from re-probe (schema-reshape; cache auto-refreshed)"
 rm -rf "$REPO_DR"
```

### 4.7 Modified: `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md`

```diff
--- a/maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md
+++ b/maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md
@@ -114,16 +114,18 @@
 test below confirm this), code consolidated into the shared lib.

-### NEW: `scripts/tests/tracker-bd130-doctor-wired-test.sh` (110 lines)
+### NEW: `scripts/tests/tracker-bd130-doctor-wired-test.sh` (114 lines)

-Regression guard for the wiring. Four groups, 8 assertions:
+Regression guard for the wiring. Four groups, 8 assertions
+(Groups 1+3 each have 2 assertions; Group 4 has 2 source-line
+assertions, one per dispatcher):
 - Group 1: `scripts/lib/tracker-doctor.sh` exists and defines
-  `tracker_doctor_run()`.
+  `tracker_doctor_run()` (2 assertions).
 - Group 2: `pack-tracker.sh doctor --repo-root <scratch>`
   produces the doctor banner and contains no `command not found`
-  .
-- Group 3: same for `tracker-migrate.sh doctor`.
-- Group 4: both dispatchers contain the
-  `source "$LIB_DIR/tracker-doctor.sh"` line (so a future
-  refactor that removes the source can't silently re-break the
-  verb).
+  (2 assertions).
+- Group 3: same for `tracker-migrate.sh doctor` (2 assertions).
+- Group 4: each dispatcher contains the
+  `source "$LIB_DIR/tracker-doctor.sh"` line (2 assertions, one
+  per dispatcher) so a future refactor that removes the source
+  can't silently re-break the verb.
@@ -298,7 +300,7 @@
 ## Files changed inventory

-| `scripts/lib/tracker-doctor.sh` | NEW | 203 lines; ... |
+| `scripts/lib/tracker-doctor.sh` | NEW | 201 lines; ... |
@@ -304,7 +306,7 @@
-| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | NEW | 110 lines; 8 / 8 pass. ... |
+| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | NEW | 114 lines; 8 / 8 pass. ... |
```

(Diff abbreviated above; the actual edits land under the same
docstring/inventory lines and preserve all surrounding text. See
the on-disk file for the canonical form.)

---

## 5. Verification output

### 5.1 `bash -n` on every modified `.sh` file

```
$ bash -n scripts/lib/tracker-doctor.sh && echo OK
OK
$ bash -n scripts/pack-tracker.sh && echo OK
OK
$ bash -n scripts/tracker-migrate.sh && echo OK
OK
$ bash -n scripts/tests/tracker-bd130-doctor-wired-test.sh && echo OK
OK
$ bash -n scripts/tests/tracker-migrate-reverse-test.sh && echo OK
OK
```

All five touched shell files parse cleanly.

### 5.2 M-1 / M-2 stale-string greps

```
$ grep -n "Pending — surfaces" scripts/pack-tracker.sh
(no match — stale string removed)

$ grep -n "BD-067 — not yet implemented" scripts/tracker-migrate.sh
(no match — both stale `reverse` and `doctor` strings removed)

$ bash scripts/pack-tracker.sh -h 2>&1 | grep -A 2 "doctor"
  doctor [--repo-root PATH]
        Validate tracker.toml, mapping integrity, mirror freshness,
        template freshness, and capability cache (refreshes the

$ bash scripts/tracker-migrate.sh -h 2>&1 | grep -A 2 "doctor"
  doctor [--repo-root PATH]
        Validate tracker.toml, mapping integrity, mirror freshness,
        template freshness, and capability cache (refreshes the
```

Both dispatchers now describe the doctor verb honestly.

### 5.3 M-3 README brace-listing fix

```
$ grep -n "tracker-{" README.md
203:    ├── tracker-{config,doctor,init,labels,errors,sidecar,mirror,agent-read,phase-task,cycle-check,links,promote}.sh   Tracker subsystem (v11; phase-task per V3.3 §2 D-21 / BD-106; cycle-check + links per V3.3 §5 / BD-108; promote per V3.3 §3 / BD-107; doctor per BD-130)
```

`doctor` is now in the brace expansion in alphabetical order
between `config` and `init`; the trailing annotation is updated
to credit BD-130.

### 5.4 M-4 defensive-probe paste + would-have-caught-BD-130 invocation

The new probe block at top of `tracker_doctor_run`:

```bash
local _dep
for _dep in tracker_config_resolve_path tracker_config_auto_surface \
            tracker_schema_version_check tracker_config_get \
            provider_capabilities; do
    if ! declare -f "$_dep" >/dev/null 2>&1; then
        echo "ERROR: tracker-doctor: missing dependency: $_dep" >&2
        echo "MESSAGE: source tracker-config.sh, tracker-provider*.sh, template-version.sh, template-translations.sh before tracker-doctor.sh" >&2
        return 2
    fi
done
```

Test invocation that would catch the BD-130 failure mode now:

```
$ bash -c "set +e; source scripts/lib/tracker-doctor.sh; \
           tracker_doctor_run /tmp; echo \"PROBE_RC=\$?\"" 2>&1
ERROR: tracker-doctor: missing dependency: tracker_config_resolve_path
MESSAGE: source tracker-config.sh, tracker-provider*.sh, template-version.sh, template-translations.sh before tracker-doctor.sh
PROBE_RC=2
```

The pre-N-1 failure mode (a future caller sourcing tracker-doctor.sh
without the dependency libs and getting `tracker_config_resolve_path:
command not found`) is now converted into an actionable error with
rc=2 and a concrete remediation in the message.

### 5.5 M-5 docstring/body label alignment

Docstring (lines 4-15 of tracker-doctor.sh):

```
# Validates: (a) tracker.toml is readable + schema_version OK,
# (b) mapping file is well-formed JSON, (c) every mapping entry's
# pack-id is shaped correctly, (d) mirror freshness vs last-forward
# timestamp, (e) template-version freshness — form-level
# template_version vs translation manifest's latest target,
# (f) issue-template dir presence, (g) capability cache refresh ...
```

Body labels (grep on the in-function block-comment headers):

```
$ grep -n "^    # ([a-g])" scripts/lib/tracker-doctor.sh
75:    # (a) tracker.toml
88:    # (b) mapping file shape
99:        # (c) per-entry pack-id shape
114:    # (d) mirror freshness — compare BACKLOG.md mtime against
142:    # (f) issue-template dir presence. Both the `pack` and `client`
170:        # (e) template-version freshness — compare form-level
206:    # (g) capability cache refresh (V2 §22.1 doctor sub-surface).
```

All seven docstring-promised checks (a)-(g) are now present as
labeled body block-comments. The (e)/(f) ordering is intentional
in the body: (f) is the outer "is the dir present at all?" check
and (e) is the inner "if present, are the form versions current?"
freshness comparison nested under (f). Docstring enumeration order
remains alphabetical so the contract reads naturally.

### 5.6 N-1 capability-cache CI red-vs-green before/after

Synthetic scratch with valid tracker.toml + ISSUE_TEMPLATE dir +
deliberately stale capabilities.json (no other doctor warnings):

**BEFORE** (using `git show 1bdd1f5:scripts/lib/tracker-doctor.sh`
in a synthetic dispatcher that sources current deps + the OLD lib):

```
=== BEFORE (1bdd1f5 lib): only schema-reshape pending ===
doctor: /var/folders/.../tmp.MLPlxK636V
  [OK]   tracker.toml schema_version supported
  [INFO] no mapping file (expected before first forward run)
  [OK]   .../tmp.MLPlxK636V/.github/ISSUE_TEMPLATE present (0 templates)
  [OK]   template-version freshness: ... manifest=0 transitions (current)
  [WARN] capability cache differs from re-probe (schema-reshape)  → Run: pack tracker doctor
doctor: completed with 1 warning(s)
---rc_BEFORE=1
```

**AFTER** (current lib with N-1 fix; cache re-staled to reproduce
the same delta):

```
=== AFTER (current lib): only schema-reshape pending ===
doctor: /var/folders/.../tmp.MLPlxK636V
  [OK]   tracker.toml schema_version supported
  [INFO] no mapping file (expected before first forward run)
  [OK]   .../tmp.MLPlxK636V/.github/ISSUE_TEMPLATE present (0 templates)
  [OK]   template-version freshness: ... manifest=0 transitions (current)
  [INFO] capability cache differed from re-probe (schema-reshape; cache auto-refreshed)
doctor: clean
---rc_AFTER=0
```

CI gating on `pack tracker doctor`'s exit code now passes (rc=0,
"doctor: clean") when there's no remaining user task. The
schema-reshape signal is preserved in the `[INFO]` text so
operators still see it in the report. A subsequent doctor run on
the same repo emits `[OK] capability cache current (no schema-
reshape)` because the cache was auto-healed.

### 5.7 Wiring test (BD-130's own regression guard)

```
$ bash scripts/tests/tracker-bd130-doctor-wired-test.sh
=== Group 1: scripts/lib/tracker-doctor.sh exists ===
  pass: 1.1 lib file present at scripts/lib/tracker-doctor.sh
  pass: 1.2 lib defines tracker_doctor_run()
=== Group 2: pack-tracker.sh doctor wires the function ===
  pass: 2.1 no 'command not found' in pack-tracker.sh doctor output
  pass: 2.2 pack-tracker.sh doctor emits 'doctor:' banner
=== Group 3: tracker-migrate.sh doctor wires the function ===
  pass: 3.1 no 'command not found' in tracker-migrate.sh doctor output
  pass: 3.2 tracker-migrate.sh doctor emits 'doctor:' banner
=== Group 4: both dispatchers source tracker-doctor.sh ===
  pass: 4.1 pack-tracker.sh sources lib/tracker-doctor.sh
  pass: 4.2 tracker-migrate.sh sources lib/tracker-doctor.sh
=== Group 5: no-arg pwd fallback ===
  pass: 5.1 no 'command not found' in no-arg pack-tracker.sh doctor
  pass: 5.2 no-arg pack-tracker.sh doctor banner names cwd
  pass: 5.3 no 'command not found' in no-arg tracker-migrate.sh doctor
  pass: 5.4 no-arg tracker-migrate.sh doctor banner names cwd
=== Group 6: --repo-root directory validation ===
  pass: 6.1 pack-tracker.sh doctor rejects non-directory --repo-root
  pass: 6.2 pack-tracker.sh doctor returns non-zero on invalid --repo-root
  pass: 6.3 tracker-migrate.sh doctor rejects non-directory --repo-root
  pass: 6.4 tracker-migrate.sh doctor returns non-zero on invalid --repo-root
=== Group 7: defensive dependency probe ===
  pass: 7.1 probe emits ERROR: tracker-doctor: missing dependency
  pass: 7.2 probe emits MESSAGE with calling-convention hint
  pass: 7.3 probe returns rc=2 (calling-convention failure)
  pass: 7.4 probe does NOT emit raw 'command not found'

=== Results: 20 passed, 0 failed ===
```

20/20 PASS. Test was extended from 8 assertions to 20 assertions
to cover N-4 (no-arg pwd fallback), N-5 (--repo-root directory
validation in both dispatchers), and M-4 (defensive dependency
probe). All new assertions pass; the original 8 assertions
continue to pass.

### 5.8 Reverse test (existing schema-reshape coverage)

```
$ bash scripts/tests/tracker-migrate-reverse-test.sh 2>&1 | tail -3
=== Summary ===
Passed: 113
Failed: 0
```

113/113 PASS. The schema-reshape assertion (Group 6.1a) was
updated to match the new INFO-level text per N-1; all other
assertions continue to pass without modification.

### 5.9 Other doctor-touching tests

```
$ bash scripts/tests/tracker-errors-test.sh 2>&1 | tail -3
=== Summary ===
Passed: 60
Failed: 0

$ bash scripts/tests/test-tracker-cycle-check.sh 2>&1 | tail -3
=== Summary ===
Passed: 26
Failed: 0

$ bash scripts/tests/test-tracker-links.sh 2>&1 | tail -3
=== Summary ===
Passed: 43
Failed: 0
```

All three doctor-adjacent suites pass without modification.

### 5.10 Pack validator

```
$ python3 scripts/validate-pack.py 2>&1 | tail -3

============================================================
PASSED — all checks clean
```

`validate-pack.py` clean. README.md edit + script edits do not
trip any of the 32 validator checks.

---

## 6. Plan deviations

1. **Scope expansion: edited `scripts/tests/tracker-migrate-reverse-
   test.sh` (line 569 schema-reshape assertion).** This file is not
   in the prompt's "Files you may edit" list, but the existing
   Group 6.1a assertion `assert_contains "6.1a doctor surfaces
   schema-reshape on capability diff" "$output3" "[WARN] capability
   cache differs from re-probe (schema-reshape)"` asserts the exact
   pre-N-1 WARN string. The N-1 fix changes the emitted text to
   `[INFO] capability cache differed from re-probe (schema-reshape;
   cache auto-refreshed)`, which would have failed the existing
   assertion. The fix is to update the assertion in lock-step with
   the lib change, preserving the schema-reshape coverage intent
   while reflecting the new auto-healed-INFO behavior. Decision:
   apply the test update as part of this retro-fix because (a) it's
   not on the BD-129/BD-131/etc. concurrent owners' lists, (b) the
   test would otherwise break and force a follow-up commit, and
   (c) the prompt's N-1 success criteria implicitly require the
   test to pass against the new behavior. Surfaced here so Pack
   Chat can verify the scope expansion is acceptable before
   committing.

2. **N-7 NOT FIXED.** Reviewer recommended "leave" — optional
   refactor not in scope for a wiring-fix retro. The two
   `cmd_doctor` definitions in `pack-tracker.sh` and
   `tracker-migrate.sh` remain byte-identical (modulo the new N-5
   directory-validation block, which is also identical between
   the two). Surfaced as POQ-1 below for Pack Chat's tech-debt log.

No other deviations from the prompt or the retro doc's recommended
dispositions.

---

## 7. POQs (Planner-Open-Questions) introduced

### POQ-1: DRY the duplicated `cmd_doctor` between `pack-tracker.sh` and `tracker-migrate.sh`

- **Problem:** After this retro-fix, both dispatchers contain a
  byte-identical 18-line `cmd_doctor` (arg-parser + directory
  validation + `tracker_doctor_run` call). Any future change to
  the surface (e.g., a new flag, additional validation) needs to
  be applied in two places.
- **Disposition:** DEFERRED. Reviewer's N-7 recommended "leave".
  Refactor is structural (would require either moving the arg
  parser into `tracker_doctor_run` itself or introducing a new
  `tracker_doctor_main` wrapper in the lib + adjusting both
  dispatchers' source order) and falls under the
  architect-then-planner workflow per the pack memory rule on
  "skill and agent maintenance is mechanical by default; structural
  change requires architect-then-planner."
- **Recommended default:** Park in the BD-130 retro tech-debt log.
  Promote to a new BD only if a future change to the doctor surface
  forces the duplication question.

### POQ-2: client-surface translation manifest path semantics

- **Problem:** N-3 fix routes the `client` surface to
  `<repo-root>/.pack-tracker/translations.yaml`, but no part of
  v11.0's `pack tracker init` currently propagates the manifest
  there. The check is therefore always-skipped in client repos
  (with the new N-2 INFO line surfacing the skip rather than
  hiding it). When v11.1+ ships real translations, the question
  "where do client repos get the manifest from?" becomes live.
- **Disposition:** DEFERRED. Reviewer's N-3 disposition was
  "future BD".
- **Recommended default:** When a v11.1+ planner spec ships with
  real template-version transitions, capture the manifest-
  propagation question as part of that BD's success criteria
  (probably a new step in `tracker_init_run` that copies or
  generates the per-project manifest). For v11.0, the per-surface
  resolution + INFO-level skip line is the right shape — the
  client-surface check informs the user that the manifest is
  absent rather than silently passing.

---

## 8. Definition-of-Done checklist

Per the prompt's "Constraints" + "Verification" sections:

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | No state-changing git verbs run | PASS | Section 1: HEAD SHA unchanged (`304078f`); Section 2 pre-flight uses only read-only verbs |
| 2 | M-1: stale "Pending" string removed from `pack-tracker.sh` `usage()` | PASS | §5.2 grep returns no match |
| 3 | M-2: stale "BD-067 — not yet implemented" strings removed from `tracker-migrate.sh` `usage()` (both `reverse` and `doctor`) | PASS | §5.2 grep returns no match |
| 4 | M-3: README line 203 brace-listing includes `tracker-doctor.sh` | PASS | §5.3 grep shows `doctor` in alphabetical position |
| 5 | M-4: defensive `declare -f` probe added; demonstrably catches BD-130 failure mode | PASS | §5.4 paste + invocation; §5.7 Group 7 (4 assertions) |
| 6 | M-5: docstring `(a)`-`(g)` enumeration matches body block-comment labels | PASS | §5.5 grep + paste shows all seven labels in body |
| 7 | M-6: WARN recovery-verb idiom uses user-facing `pack tracker` surface only | PASS | §4.1 diff shows three `tracker-migrate.sh forward...` → `pack tracker init` / `pack tracker mirror-rebuild` replacements |
| 8 | N-1: capability-cache schema-reshape no longer false-fails CI | PASS | §5.6 before/after: rc=1 → rc=0 with `doctor: clean`; signal preserved in `[INFO]` text |
| 9 | N-2: silent-skip on missing manifest replaced with `[INFO] ... (skipped)` | PASS | §4.1 diff shows new `else` branch |
| 10 | N-3: manifest path resolved per-surface | PASS | §4.1 diff shows per-surface `case` |
| 11 | N-4: test exercises no-arg pwd fallback | PASS | §5.7 Group 5 (4 assertions) |
| 12 | N-5: `cmd_doctor` validates `--repo-root` is a directory in both dispatchers | PASS | §5.7 Group 6 (4 assertions); §4.2 + §4.3 diffs |
| 13 | N-6: archived implementation report line counts corrected | PASS | §4.7 diff shows 110→114 (test) + 203→201 (lib) corrections |
| 14 | N-7: not in scope for this fix | INFO | §6 deviation note + §7 POQ-1 |
| 15 | N-8: degenerate surface `case` collapsed | PASS | §4.1 diff shows collapse to single unconditional assignment |
| 16 | All `bash -n` syntax checks clean | PASS | §5.1: all five touched .sh files OK |
| 17 | BD-130 wiring test (extended) passes | PASS | §5.7: 20/20 PASS |
| 18 | BD-130-adjacent test (`tracker-migrate-reverse-test.sh`) still passes | PASS | §5.8: 113/113 PASS |
| 19 | Other doctor-touching suites unaffected | PASS | §5.9: errors 60/60, cycle-check 26/26, links 43/43 |
| 20 | `validate-pack.py` clean | PASS | §5.10: PASSED — all checks clean |
| 21 | Trinity files (CLAUDE/AGENTS/GEMINI) NOT touched | PASS | Edit set excludes those files; no project-template surface change |
| 22 | Concurrent coders' files NOT touched | PASS | Edit set scoped to BD-130-owned files only; reverse-test alignment is BD-067/BD-130-era code, not on any concurrent owner's list |

22/22 items PASS or properly INFO-noted.

---

## 9. Proposed commit message

Per the pack convention `feat: vN — BD-NNN <description>` /
`fix: vN — BD-NNN <description>`. The work is a fixup of an
already-shipped BD, so `fix:` is the right verb:

```
fix: v11 — BD-130 retro-fix (M-1..M-6 + N-1..N-6 + N-8)

Closes 13 of 14 findings from PACK-REVIEW-BD-130-RETRO.md
(M-1..M-6 SHOULDs + 7 of 8 NITs; N-7 left per reviewer):

- M-1/M-2: replace stale "Pending"/"BD-067 not yet implemented"
  strings in pack-tracker.sh + tracker-migrate.sh `usage()` with
  honest verb descriptions
- M-3: insert `doctor` into README brace-listing (line 203)
- M-4: add defensive `declare -f` probe at top of
  `tracker_doctor_run`; converts silent `command not found` into
  actionable rc=2 error if a future caller sources the lib without
  the dependency libs
- M-5: align docstring (a)-(g) enumeration with body block-
  comment labels (split previous (e)+(f) conflation; (f) outer
  presence check, (e) inner freshness comparison nested under (f))
- M-6: replace `tracker-migrate.sh forward...` recovery verbs in
  WARN lines with `pack tracker init` / `pack tracker mirror-
  rebuild` per V3 §27.1 Layer 2 user-facing-surface contract
- N-1: demote schema-reshape from WARN to INFO (cache is auto-
  healed in same invocation); CI gating on `pack tracker doctor`
  exit code no longer false-reds on already-resolved condition
- N-2: surface missing-manifest as `[INFO] ... (skipped)` rather
  than silently dropping the freshness check
- N-3: resolve translation-manifest path per-surface (pack vs
  client)
- N-4: extend wired-test with Group 5 (no-arg pwd fallback path)
- N-5: add `--repo-root` directory validation to both cmd_doctor
  definitions; extend wired-test with Group 6
- N-6: correct line counts in archived
  IMPLEMENTATION-REPORT-BD-130.md (110→114 test lines, 203→201
  lib lines)
- N-8: collapse degenerate surface case in template-dir resolution

Wired-test extended from 8 to 20 assertions (adds Groups 5/6/7
for N-4/N-5/M-4 coverage). Schema-reshape assertion in
tracker-migrate-reverse-test.sh updated to match new INFO text.
All test suites green: wired 20/20, reverse 113/113, errors 60/60,
cycle-check 26/26, links 43/43; validate-pack.py PASSED.

N-7 (DRY duplicated cmd_doctor) deferred per reviewer "leave"
recommendation; surfaced as POQ-1 in retro-fix report.
```

---

## Files changed inventory

| Path | Change | Notes |
|---|---|---|
| `scripts/lib/tracker-doctor.sh` | MODIFIED | +103 / -34 net; M-4 probe (~18 lines), M-5 docstring re-order + body re-label, M-6 recovery-verb fix (3 lines), N-1 demote (~9 lines), N-2 manifest-skip INFO (1 line), N-3 per-surface case (~12 lines), N-8 case collapse |
| `scripts/pack-tracker.sh` | MODIFIED | +24 / -3 net; M-1 usage rewrite (~18 lines), N-5 directory-validation in `cmd_doctor` (4 lines) |
| `scripts/tracker-migrate.sh` | MODIFIED | +14 / -4 net; M-2 usage rewrite (~10 lines), N-5 directory-validation in `cmd_doctor` (4 lines) |
| `README.md` | MODIFIED | +1 / -1; M-3 brace-list insertion of `doctor` |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | MODIFIED | +72 / -0; N-4 Group 5 (no-arg pwd, 4 assertions), N-5 Group 6 (validation, 4 assertions), M-4 Group 7 (probe, 4 assertions); test count 8 → 20 |
| `scripts/tests/tracker-migrate-reverse-test.sh` | MODIFIED | +8 / -2; N-1 alignment of Group 6.1a schema-reshape assertion + 6-line context comment |
| `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-130.md` | MODIFIED | +6 / -5; N-6 line-count and group-checks-count corrections |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-130-RETRO-FIX.md` | NEW | This report |

End of report.
