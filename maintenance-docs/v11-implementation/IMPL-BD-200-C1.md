# IMPL-REPORT — BD-200 commit C1 — single-source capability tables + behavior-preserving refactor

**Role:** pack-coder (fresh). **Branch:** `v11-dev`. **HEAD on worktree:** `356afca41733e1f6a504a1eb88a544bde1ae43e4` (unchanged — no git state-changing verb run; Pack Chat stages + commits).
**Scope:** exactly C1 = T1 (NEW `project-template/scripts/capability-tables.sh`) + T2 (behavior-preserving edit to `scripts/add-capability.sh`). Plan: `PLAN-BD-200.md` §2 T1/T2, §3 dep #4, §5, §8. Design: `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.5 + §4.3.
**Date:** 2026-06-04.

---

## 1 — Files changed (inventory)

| Path | Change type | Surface |
|---|---|---|
| `project-template/scripts/capability-tables.sh` | **NEW** | project-template (client deliverable; ships via S5 glob) |
| `scripts/add-capability.sh` | **MODIFIED** (behavior-preserving) | pack-side |
| `scripts/tests/test-add-capability.sh` | **MODIFIED** (encoding-surface lock-step) | pack-side test infra |
| `test-fixtures/manifest.txt` | **MODIFIED** (regenerated) | test-fixtures |

Working tree at report time:
```
 M scripts/add-capability.sh
 M scripts/tests/test-add-capability.sh
 M test-fixtures/manifest.txt
?? project-template/scripts/capability-tables.sh
```

---

## 2 — What changed + why

### T1 — NEW `project-template/scripts/capability-tables.sh`
The single authored source of the three table functions, extracted from
`scripts/add-capability.sh`:
- `capability_skills()` — case → space-separated skill list (verbatim echo strings, every `:` branch preserved).
- `capability_files()` — case → conditional-files list (verbatim).
- `capability_install_checks()` — case → `cat <<'EOF'` heredocs with `:::`-delimited rows (**heredocs + rows preserved byte-for-byte** — proven in §3).

**Sourceable-only:** the file defines exactly the three functions; NO top-level side effects, nothing executes on source. `bash -n` clean.

**Boundary (zero pack-self tokens — this file ships to clients, walked by Check 43/37):**
- Header docstring names the realized **client-side** consumer concretely: `scripts/activate-capability.sh` (its installed sibling) — satisfying `architect-doc-reality-reconciliation` (file+symbol, no line numbers) while staying boundary-clean.
- Stripped from the moved comments: all `BD-NNN` tokens, the `maintenance-docs/...ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` path, and the pack-side references `add-capability.sh` / `init-project.sh` / `pack_skill_coverage_for()` / `$PACK`. The two retained `scripts/lib/detect.sh::<fn>()` references are boundary-legitimate: `detect.sh` is in `_SANCTIONED_PACK_SIDE_SHIPPED` (`validate-pack.py:4159`) — it is a real client-resident file, so naming it in a client surface is not a pack-self leak (consistent with the plan's F8 "client-installed script basenames are not pack-self tokens" classification).
- **Comments only** were edited for boundary cleanliness; the **function OUTPUT** (echo strings + heredoc rows + return codes) is byte-identical to the pre-refactor source (proven §3) — so no behavior changed.

### T2 — EDIT `scripts/add-capability.sh` (behavior-preserving)
- Deleted the three inline function BODIES (`capability_skills` / `capability_files` / `capability_install_checks`).
- Added a lazy-source helper `_load_capability_tables()` that `source`s `"$PACK/project-template/scripts/capability-tables.sh"` (pack→pack read of the pack's own template tree — `pack-project-separation` satisfied: pack-side reads `$PACK/project-template/...`, never the client copy). Guarded against double-source via `_CAPABILITY_TABLES_LOADED`; dies with `EXIT_PACK_INVALID` if the tables file is absent.
- **R1 — LOAD-BEARING placement (EEB-PACK-ORDER):** the `source` lives ONLY inside `_load_capability_tables()`, which is invoked as the FIRST statement of `stage_a1_resolve()`. `stage_a1_resolve` runs AFTER `stage_a0_preflight` (which validates `$PACK` at the `die "PACK environment variable not set"` check). The tables are first CALLED later in `stage_a1_resolve` (`capability_skills`/`capability_files`). So `$PACK` is guaranteed set before the source dereferences it. There is exactly ONE `source "$tables"` line (inside the helper) — NO top-level `source "$PACK/..."`. Verified §4.
- **Preserved in `add-capability.sh`** (consumer logic, not tables): `warn_if_missing_skills()` and `probe_tool_present()` — untouched. All stages A0–A8, arg parsing, helpers, exit codes UNCHANGED.

### Lock-step encoding-surface fix (`scripts/tests/test-add-capability.sh`)
The test's `load_install_checks_fn()` previously `sed`-extracted `capability_install_checks()` from `add-capability.sh`. That function relocated to `capability-tables.sh`, so the extraction would (and did) fail — an asymmetric-coverage break per `enumerate-encoding-surfaces`. Verification step 4 of the C1 prompt explicitly scopes in "any test that sources/calls these tables." Fix: point the loader at the new authored source and `source` it whole (it is sourceable-only). Added `CAP_TABLES_SH` var; rewrote `load_install_checks_fn()`. Mechanical, no assertion changes. Result: 19/19 PASS (was 10/19 mid-edit).

---

## 3 — No-drift evidence (behavior-preserving proof)

**Mechanism:** extracted the three function definitions from the pre-refactor `add-capability.sh` (`git show HEAD:scripts/add-capability.sh`, then awk-extracted the three `fn() { … ^}` blocks into `old-tables.sh`); copied the post-refactor authored file as `new-tables.sh`; sourced each and dumped `capability_skills` / `capability_files` / `capability_install_checks` output + return code for **every supported `<dim>:<val>`** (all 19 real branches) plus 2 unknown args (`bogus:unknown`, `unknown:thing`) to exercise the `*) return 1` / `*) echo ""` / `*) :` default arms; `diff -u` the two dumps.

**Capabilities covered (21 args):** `language:{python,swift,cpp,c,objc}`, `platform:{macos,ios,android,web-browser,embedded-mcu}`, `protocol:{grpc,rest,graphql,realtime,messaging,soap}`, `deployment:{apple,linux-container}`, `role:python-server`, `bogus:unknown`, `unknown:thing`.

**Result (captured diff — EMPTY):**
```
--- DIFF (old vs new) ---
NO-DRIFT confirmed: byte-identical
     201 out-old3.txt
     201 out-new3.txt
     402 total
```
201 lines of resolved output (skills + files + install-check heredocs + rc per cap), **byte-identical** pre- vs post-refactor. Re-run AFTER the boundary comment edits — still byte-identical (comments do not affect function output). Behavior-preserving acceptance MET.

---

## 4 — `$PACK`-unset regression check (R1)

Ran `env -u PACK bash scripts/add-capability.sh --project /tmp --add language:python`:
```
add-capability.sh — add pack-supported capability to v10 project

── A0 — pre-flight ──
error: PACK environment variable not set (or pass --pack <path>)
exit=10
```
The script dies at **A0** with the **same message and exit code (10)** as before — it does NOT fail earlier with a source error. Confirms the `source` executes only after `$PACK` validation.

Placement confirmation:
- `grep '^[[:space:]]*source "\$tables"'` → single hit (line inside `_load_capability_tables`).
- `_load_capability_tables` is called only from `stage_a1_resolve` (one call site).
- No top-level `source "$PACK/..."` exists.

---

## 5 — Test results

`bash scripts/tests/test-add-capability.sh` → **19 PASS, 0 FAIL** (exit 0).
- Group 1 (table coverage): sources `capability-tables.sh`; all 10 row-content assertions pass (`protocol:grpc` buf/protoc-gen-swift/grpcio-tools; `language:python` python3/uv; `language:swift` swift/swift-format; `platform:macos` xcodebuild; `protocol:rest` empty; `:::` separator count = 5).
- Group 2 (end-to-end): runs the FULL `add-capability.sh` pipeline (`PACK=$REPO_ROOT … --add protocol:grpc`), which now resolves tables via `_load_capability_tables`; A7 banner, A8 banner, buf/protoc-gen-swift probes, prompt discovery block, G6-install, Form I, buf-in-discovery, no-leak — all pass. This is the integration proof that the lazy-source path works in the real pipeline.

---

## 6 — Manifest

`bash test-fixtures/build.sh --all --clean` regenerated `test-fixtures/manifest.txt`. Diff vs HEAD:
```
-v11-realistic-ot  2a84786c776e80801e446c6b1f9c2d0649c2eff0
-v11-flat-file  08851e36f6db37078ab87e7671aa4a15cf83dd0f
-v11-tracker-on  6f5d47c89f6f2deddcb2e94d08cefc3ede619bdd
+v11-realistic-ot  e97888b6121b3e1490f513c9851a9dd80da18f90
+v11-flat-file  3fc3036d6fe8ccc764ef836b2f084e39ab9df6fe
+v11-tracker-on  d83c27df1438e154bc8d159b185b3c44de14cbbd
```
**Three `v11-*` rows MOVED** (the new `project-template/scripts/capability-tables.sh` is S5-copied into every v11 fixture → fixture content + SHA changes). **`v10-minimal`, `v10-realistic-ot`, `existing-project-mid-dev` UNCHANGED** — matches PLAN R4 (v10 fixtures use the v10 init; existing-project is pre-install). Left in working tree for Pack Chat to stage in the C1 commit.

---

## 7 — validate-pack

`python3 scripts/validate-pack.py` → **`PASSED — all checks clean`**.
- **Check 43** — "157 project-side / client-installed file(s) walked; zero pack-internal bare cross-references" — the new `project-template/scripts/capability-tables.sh` walked clean.
- **Check 37** — "169 project-side file(s) walked; zero deny-list contamination" — clean.
- **Check 41 / 47** — untouched (no install-map edit, frozen `_SANCTIONED_PACK_SIDE_SHIPPED` 2-tuple unchanged; `capability-tables.sh` ships via the `project-template/` recursive walk, invisible to Check 47 — no allowlist growth).
- The only non-OK lines are two pre-existing **Check 48** advisory WARNs (`pack-ops/BACKLOG.md` `V10-PREDESIGN.md` citations) — advisory-only, exit code unaffected, unrelated to C1.

---

## 8 — Plan deviations

1. **`scripts/tests/test-add-capability.sh` edited** (not named in PLAN §1 affected-files, but in-scope per C1-prompt verification step 4 "any test that sources/calls these tables" + the `enumerate-encoding-surfaces` rule). Mechanical loader retarget; no assertion change. NOT a design deviation — a required lock-step encoding-surface update the relocation forced. Documented here for transparency.
2. **Boundary comment edits inside the moved tables** (beyond a pure byte-verbatim copy of comments): the C1 prompt requires the new `project-template/` file carry ZERO pack-self tokens, which is incompatible with copying the original `BD-NNN` / `maintenance-docs/` / pack-side-script comment text verbatim. Resolution: function OUTPUT is verbatim (proven §3); only COMMENTS were neutralized for boundary cleanliness. This honors both "preserve heredocs/rows byte-for-byte" (data preserved) and "zero pack-self tokens" (comments cleaned). No behavior impact.

No other deviations.

---

## 9 — New POQs introduced

- **POQ-C1-1 (stale cross-reference, out of C1 scope — SURFACED not fixed).** `scripts/lib/detect.sh` (~the `deployment-apple`/`deployment-python` D5 reciprocal-mapping comment) cites `scripts/add-capability.sh::capability_skills()`. C1 moved `capability_skills()` to `project-template/scripts/capability-tables.sh`, so the cite is now stale (names the wrong file). It is a **comment only — no runtime impact** (C1 verification all-green). `detect.sh` is NOT in T1/T2 scope (not in PLAN §1 affected files), so per the GOALS "out-of-scope issues surfaced not silently fixed" + the strict C1 scope fence, I did NOT edit it. **Disposition recommendation:** Pack Chat routes a one-line cross-ref correction (point the comment at `capability-tables.sh::capability_skills()`) into a later BD-200 commit (C-anything touching `scripts/`) or a small follow-up, per `architect-doc-reality-reconciliation`. No anchor is load-bearing today.

---

## 10 — Definition-of-Done checklist

| Item | Result |
|---|---|
| T1 file exists at `project-template/scripts/capability-tables.sh`, sourceable-only, defines exactly the 3 functions | **PASS** |
| T1 zero pack-self tokens (Check 43/37 clean) | **PASS** |
| T1 docstring names realized client consumer (file+symbol, no line numbers) | **PASS** |
| T2 inline bodies deleted; replaced by lazy `source` after `$PACK` validation (R1) | **PASS** |
| T2 `warn_if_missing_skills()` + `probe_tool_present()` preserved | **PASS** |
| `bash -n` both files clean | **PASS** |
| No-drift: byte-identical table output for every capability (incl. unknown args) | **PASS** (201 lines, empty diff) |
| No `$PACK`-unset regression (dies at A0, exit 10, same message) | **PASS** |
| `test-add-capability.sh` green | **PASS** (19/19) |
| Manifest regenerated; v11-* moved, v10-*/existing unchanged; left in tree | **PASS** |
| `validate-pack.py` → PASSED all clean (Check 43/37 walk new file; 41/47 unmoved) | **PASS** |
| No git state-changing verb run (HEAD unchanged) | **PASS** |
| Out-of-scope issue surfaced as POQ not silently fixed | **PASS** (POQ-C1-1) |

---

## 11 — Full content of new file

`project-template/scripts/capability-tables.sh` (NEW — full contents for re-apply):

```bash
#!/usr/bin/env bash
# capability-tables.sh — single authored source of the capability → (skills,
# files, install-checks) resolution tables.
#
# SOURCEABLE-ONLY: this file defines three functions and has NO top-level
# side effects. Sourcing it defines exactly capability_skills(),
# capability_files(), and capability_install_checks(); nothing executes on
# source. Its consumer is the sibling scripts/activate-capability.sh, which
# sources this file (`source "$(dirname "$0")/capability-tables.sh"`) to
# resolve a requested capability into its skill list, conditional files,
# and tool install-checks.
#
# Adding a new capability row: extend capability_skills() AND
# capability_files() AND capability_install_checks() — three parallel
# surfaces, one capability per case branch.

# ── Capability → (skills, files) resolution table ──────────────────────────
# Mirrors the conditional-removal table, inverted.

capability_skills() {
    local cap="$1"
    case "$cap" in
        # python-data-architecture and python-observability-patterns also
        # load via marker predicates at auto-detect time. Here they are
        # added unconditionally to the language:python skill set — declaring
        # the capability explicitly (coarser tool) pulls in the full
        # Python-skill family declaratively. The marker-gated intersection
        # load (PLATFORM-SKILLS.md Intersection table) still applies at
        # PM-chat skill-selection time.
        language:python)    echo "python-best-practices python-data-architecture python-observability-patterns dependency-python" ;;
        # swift-concurrency-patterns is D1-implied for D1 ∈
        # {ios, macos} alongside swift-best-practices — every Apple
        # project deals with concurrency, no marker predicate. Added
        # to the language:swift capability row so capability-addition
        # registers the skill on the same path as
        # swift-best-practices. The companion intersection-loaded
        # skill (apple-swiftdata-patterns) remains marker-gated and
        # is NOT added here — see the apple-swiftdata-patterns
        # comment under platform:macos / platform:ios.
        language:swift)     echo "swift-best-practices swift-concurrency-patterns apple-architecture-core dependency-swift" ;;
        language:cpp)       echo "cpp-language" ;;
        language:c)          echo "c-language" ;;
        language:objc)      echo "objc-language" ;;
        # platform:macos / platform:ios add the Apple-platform
        # skill set deterministically. The companion
        # `apple-swiftdata-patterns` skill is intersection-loaded by
        # marker (`scripts/lib/detect.sh::swiftdata_marker_detected()`),
        # not by capability — a project that uses SwiftData
        # (`import SwiftData` OR `@Model`) will have the marker
        # fire and the intersection-table loader pulls in
        # apple-swiftdata-patterns alongside the platform skills
        # listed here. See PLATFORM-SKILLS.md "Intersection table".
        platform:macos)     echo "macos-architecture apple-architecture-core" ;;
        platform:ios)       echo "ios-architecture apple-architecture-core" ;;
        # Forward-declared D1 platform rows. The SKILL.md targets ship in a
        # later phase (web-architecture / android-architecture /
        # embedded-mcu-architecture); until then warn_if_missing_skills() emits
        # a stderr warning when the resolved skill directory is absent, but the
        # operation still proceeds so PM-chat-driven projects can declare D1
        # ahead of skill ship.
        platform:android)      echo "android-architecture" ;;
        platform:web-browser)  echo "web-architecture" ;;
        platform:embedded-mcu) echo "embedded-mcu-architecture" ;;
        # protocol:grpc adds grpc-patterns only. The companion
        # `protobuf-patterns` skill is intersection-loaded by marker
        # (`scripts/lib/detect.sh::protobuf_marker_detected()`), not by
        # capability — the same `.proto` files that justify a `grpc`
        # capability also trigger the marker, so intersection loading
        # picks up protobuf-patterns automatically. Standalone-protobuf
        # projects (binary file format / IPC / Twirp / Connect) load
        # protobuf-patterns via the marker without ever declaring
        # protocol:grpc. See PLATFORM-SKILLS.md "Intersection table".
        protocol:grpc)      echo "grpc-patterns" ;;
        protocol:rest)      echo "rest-patterns" ;;
        protocol:graphql)   echo "graphql-patterns" ;;
        protocol:realtime)  echo "realtime-patterns" ;;
        protocol:messaging) echo "messaging-patterns" ;;
        protocol:soap)      echo "soap-patterns" ;;
        # D5 deployment surface. `deployment:apple` is the Apple-app
        # deployment surface (a D5 deployment surface, not a D3 architectural
        # role). `deployment:linux-container` carries `deployment-python`.
        deployment:apple)             echo "deployment-apple" ;;
        deployment:linux-container)   echo "deployment-python" ;;
        # role:python-server is a legitimate D3 role token. Resolved skill
        # list per the intersection table: D2=python ∩ D3=server →
        # python-server-architecture + python-data-architecture.
        # `deployment-python` is NOT in this row; it loads via the
        # `deployment:linux-container` D5 row.
        # python-observability-patterns: the D3=server branch loads
        # observability unconditionally (alongside the marker-gated load for
        # non-server Python processes). This row encodes the explicit-D3
        # declaration path; the marker-gated intersection-table load handles
        # the auto-detect path.
        role:python-server) echo "python-server-architecture python-data-architecture python-observability-patterns" ;;
        *) return 1 ;;
    esac
}

capability_files() {
    local cap="$1"
    case "$cap" in
        language:python)
            echo "pyproject.toml pyrightconfig.json server scripts/bootstrap-python.sh scripts/format-python.sh scripts/validate-python.sh scripts/test-python.sh" ;;
        language:swift)
            echo "scripts/bootstrap-swift.sh scripts/format-swift.sh scripts/validate-swift.sh scripts/test-swift.sh" ;;
        protocol:grpc)
            echo "proto scripts/proto-gen.sh scripts/validate-proto.sh" ;;
        *) echo "" ;;
    esac
}

# ── Capability → install-check rows ────────────────────────────────────────
# Each capability emits zero or more rows of the shape:
#     <tool>:::<install-command>:::<purpose>
# where <tool> is the binary or package name probed by the discovery stage,
# and <install-command> is the concrete command the developer runs if the
# probe reports missing. Rows are newline-separated; fields are `:::`-
# delimited (not pipe — install commands themselves often contain `|` as
# an "or" separator between platform alternatives, which would break
# pipe-based parsing). Mirrors the kickoff Form-I shape
# (INSTALL-PROCEDURES.md § 7.2.3 / 7.3.1 / 7.3.2) applied at
# capability-addition time.
#
# Discovery is read-only: `command -v <tool>` for binaries; `python3 -c
# 'import <pkg>'` may be added by future rows for Python-package probes.
# The consuming script never installs anything — discovery reports status;
# the emitted PM-chat prompt repeats the install commands so Procedure 6 can
# drive Form I follow-ups under developer approval.
capability_install_checks() {
    local cap="$1"
    case "$cap" in
        language:python)
            cat <<'EOF'
python3:::see https://www.python.org/downloads/ (Python 3.12+ recommended):::Python interpreter required by scripts/bootstrap-python.sh and scripts/test-python.sh
uv:::brew install uv  (macOS) | curl -LsSf https://astral.sh/uv/install.sh | sh  (Linux):::Project-standard Python package manager (pyproject.toml workflow)
EOF
            ;;
        language:swift)
            cat <<'EOF'
swift:::install Xcode 26.3+ from the App Store, or swift.org/install for Linux:::Swift toolchain required by scripts/bootstrap-swift.sh / validate-swift.sh
swift-format:::brew install swift-format  (macOS) | swift package update + use SPM plugin (Linux):::Formatter invoked by scripts/format-swift.sh
EOF
            ;;
        platform:macos|platform:ios)
            cat <<'EOF'
xcodebuild:::install Xcode 26.3+ from the App Store:::Apple platform builds (xcodebuild + Simulator) require Xcode
xcrun:::installed alongside Xcode (no separate install):::simctl device discovery during validate-swift.sh / kickoff Procedure 7
EOF
            ;;
        platform:android)
            cat <<'EOF'
adb:::install Android Studio (https://developer.android.com/studio) which bundles platform-tools:::Android device + emulator interaction
java:::brew install --cask temurin@17  (macOS) | apt install openjdk-17-jdk  (Debian/Ubuntu):::JDK 17+ required by Android Gradle Plugin
EOF
            ;;
        platform:web-browser)
            cat <<'EOF'
node:::brew install node  (macOS) | nvm install --lts  (any platform):::Node.js runtime for web tooling and bundlers
EOF
            ;;
        platform:embedded-mcu)
            cat <<'EOF'
cmake:::brew install cmake  (macOS) | apt install cmake  (Debian/Ubuntu):::Cross-compile build orchestration for MCU targets
arm-none-eabi-gcc:::brew install --cask gcc-arm-embedded  (macOS) | apt install gcc-arm-none-eabi  (Debian/Ubuntu):::ARM Cortex-M cross compiler (adjust per MCU family)
EOF
            ;;
        language:cpp|language:c)
            cat <<'EOF'
clang:::install Xcode Command Line Tools: xcode-select --install  (macOS) | apt install clang  (Debian/Ubuntu):::C/C++ compiler
cmake:::brew install cmake  (macOS) | apt install cmake  (Debian/Ubuntu):::Build orchestration (project-typical)
EOF
            ;;
        language:objc)
            cat <<'EOF'
clang:::install Xcode 26.3+ from the App Store:::Objective-C is built by clang shipped with Xcode
EOF
            ;;
        protocol:grpc)
            # Apple-side gRPC tooling rows mirror Procedure 7 §7.3.1.
            # Python rows mirror §7.3.2 — they're emitted unconditionally
            # here because protocol:grpc is dimension-only (the table doesn't
            # know whether the project also has language:python). The
            # discovery stage probes each tool independently; missing
            # Python tools on a Swift-only project show as "skip if
            # not adding Python" in the install-hint output.
            cat <<'EOF'
buf:::brew install bufbuild/buf/buf  (macOS) | go install github.com/bufbuild/buf/cmd/buf@latest  (any platform):::Proto lint + breaking-change detection (scripts/validate-proto.sh)
protoc-gen-swift:::brew install swift-protobuf:::Swift code generator for .proto files (Apple-side; skip if no Apple target)
protoc-gen-grpc-swift:::brew install grpc-swift:::Swift gRPC code generator (Apple-side; skip if no Apple target)
grpcio-tools:::uv add grpcio-tools  (in project root) | pip install grpcio-tools:::Python proto/gRPC code generator (skip if no Python target)
grpcio:::uv add grpcio  (in project root) | pip install grpcio:::Python gRPC runtime (skip if no Python target)
EOF
            ;;
        protocol:rest|protocol:graphql|protocol:realtime|protocol:messaging|protocol:soap)
            # No machine-level installs implied; tooling is library-level
            # and lands via language-package-manager rows on the language
            # capability the project already has.
            : ;;
        deployment:apple)
            cat <<'EOF'
xcodebuild:::install Xcode 26.3+ from the App Store:::Apple-app deployment surface requires the full Xcode toolchain (archive + notarize)
EOF
            ;;
        deployment:linux-container)
            cat <<'EOF'
docker:::install Docker Desktop (https://docs.docker.com/get-docker/) or use Colima (brew install colima):::Container build + run for linux-container deployment
EOF
            ;;
        role:python-server)
            cat <<'EOF'
uv:::brew install uv  (macOS) | curl -LsSf https://astral.sh/uv/install.sh | sh  (Linux):::Project-standard Python package manager (pyproject.toml workflow)
EOF
            ;;
        *) : ;;
    esac
}
```

---

## 12 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL attestation | Read IN FULL: `CLAUDE.md` (entire, incl. `## Pack memory` — supplied verbatim in session context); `pack-ops/PACK-AGENTS.md` (226 lines); `pack-ops/PACK-CHAT.md` (310 lines); `project-template/CLAUDE.md` (456 lines); `PLAN-BD-200.md` (235 lines, full); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.5 (112–122) + §4.3 (169–181) + §3.6/§3.7 context (124–181); BD-200 entry in `pack-ops/BACKLOG.md` (3273–3305); curated memory files (full): `feedback_agents_read_rule_docs_in_full.md`, `feedback_agent_output_rules_applied_block.md`, `feedback_manifest_regen_on_v11_surface.md`, `feedback_pack_project_separation_of_concerns.md`, `feedback_bd_pack_only_operational_rule.md`. SOURCE read in full: `scripts/add-capability.sh` (829 lines). No skim/crop. | **COMPLIANT** |
| preflight-stop-means-stop | Emitted the single `PREFLIGHT: 2/2 …; verification PASS; HEAD 356afca…` line only AFTER all edits + all 6 verification steps PASS (syntax, no-drift, $PACK-unset, tests 19/19, manifest, validate-pack PASSED). No parent stop/halt received. | **COMPLIANT** |
| agents-never-commit | Only read-only git verbs used: `git rev-parse HEAD`, `git status`, `git diff`, `git show HEAD:scripts/add-capability.sh` (to /tmp, for no-drift). NO `git add`/`commit`/`push`/`tag`/`stash`. `git rev-parse HEAD` at report time = `356afca…` (unchanged from start). | **COMPLIANT** |
| regenerate-manifest-v11-surface | C1 touches `project-template/` + `scripts/` (v11-surface) → ran `bash test-fixtures/build.sh --all --clean`; manifest diff non-empty (3 v11-* rows moved); left staged-ready in tree (§6 diff quoted). v10-*/existing rows unchanged. | **COMPLIANT** |
| pack-repo-code-comment-deferrals | No deferral comments added in either file (grep of new file: no plain `# TODO`/`# FIXME`; none needed for C1). | **N/A: no deferrals introduced** |
| boundary / no-pack-self-in-project | `capability-tables.sh` ships to clients. Token scan: zero `pack-*`/`maintenance-docs/`/`BD-NNN`/`pack-ops/`/`from the pack`/`$PACK`/`.pack-add-capability`/`add-capability`/`init-project`/`pack_skill_coverage` after edits. Retained `scripts/lib/detect.sh::<fn>()` refs are boundary-legit (`detect.sh` ∈ `_SANCTIONED_PACK_SIDE_SHIPPED`, `validate-pack.py:4159` — client-resident). Check 43 (157 files, zero bare cross-refs) + Check 37 (169 files, zero contamination) PASS. | **COMPLIANT** |
| pack-project separation of concerns | Pack-side `add-capability.sh` sources `"$PACK/project-template/scripts/capability-tables.sh"` (pack→pack: pack op reads the pack's own template tree, never the client install). Client consumer (`activate-capability.sh`, C3) will source its OWN installed sibling. No cross-side substitution. | **COMPLIANT** |
| dependency-direction-placement | `capability-tables.sh` is a client deliverable at `project-template/scripts/`; ships via the `project-template/` recursive S5 walk (invisible to Check 47). NOT added to `_SANCTIONED_PACK_SIDE_SHIPPED` (frozen 2-tuple `detect.sh`+`pack-help.sh` unchanged — `validate-pack.py:4158-4161`). Check 47 PASS, no allowlist growth. No project-side file became a pack runtime dependency. | **COMPLIANT** |
| architect-doc-reality-reconciliation | The new file realizes the §4.3 single-source design; its header docstring names the realized consumer by file+symbol (`scripts/activate-capability.sh`, sourcing `capability-tables.sh`) — NOT line numbers. `add-capability.sh` `_load_capability_tables` docstring names the authored-source path + the stage it loads from. POQ-C1-1 surfaces the one stale reverse cross-ref in out-of-scope `detect.sh` for Pack Chat routing (not silently fixed). | **COMPLIANT** |
| rules-applied-verification-block | This §12 — per-rule name + measured evidence (command output, counts, line refs, diff) + terminal verdict; no empty-evidence rows; READ-IN-FULL attestation row present. | **COMPLIANT** |

**End of IMPL-REPORT — BD-200 C1.**
