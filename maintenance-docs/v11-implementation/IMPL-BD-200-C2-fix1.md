# IMPL-REPORT — BD-200 commit C2, fix-1 (S-1 + N-1)

**Role:** pack-coder (fresh, review-fix). **Branch:** `v11-dev`.
**HEAD (unmoved):** `98b6a9b10e9d9e8b114995e3d416e708230c5bde`. **Date:** 2026-06-04.
**Fixes:** S-1 (SHOULD) + N-1 (NIT) from `maintenance-docs/v11-implementation/PACK-REVIEW-BD-200-C2.md`.
**Scope fence:** ADD to the existing uncommitted C2 working tree. Did NOT revert/redo other C2 edits; did NOT touch C1's `capability-tables.sh`/`add-capability.sh`; added NO `pack update`/refresh/wipe-repopulate logic (BD-202 boundary intact).

---

## 1 — What the review found (recap)

The C2 T4 work pool-excluded `detect_language_markers()` in `init-project.sh`, but the **parallel tree-scanning marker-detector family in `scripts/lib/detect.sh`** was MISSED. Those four detectors walk the whole target tree and empirically mis-fire on the BD-200 tracked pool (which ships `proto/*.proto`, `buf.yaml`, `pyproject.toml`, `server/**/*.py` masters on every installed project). Plus N-1: `detect_source_files()` in `init-project.sh` had the same un-excluded walk (harmless today; pre-pool diagnostic).

---

## 2 — Exact edits applied

### S-1 — `scripts/lib/detect.sh` (4 functions, 5 tree-scanning `find` walks)

Added a `pack-capability-pool/` exclusion to each tree-walking `find`, matching each function's **existing** prune style, and commented each as **LOAD-BEARING** (not defensive/parity), per the review NIT on comment framing.

| Function | Walk | Exclusion added | Style matched |
|---|---|---|---|
| `protobuf_marker_detected()` | marker (a) `.proto` walk | `-o -path '*/pack-capability-pool/*'` inside the `\( … \) -prune` group | `\(-prune\)` block |
| `swiftdata_marker_detected()` | markers (a)/(b) `.swift` walk | `-o -path '*/pack-capability-pool/*'` inside the `\( … \) -prune` group | `\(-prune\)` block |
| `python_observability_marker_detected()` | marker (b) `.py` walk | `-o -path '*/pack-capability-pool/*'` inside the `\( … \) -prune` group | `\(-prune\)` block |
| `python_data_marker_detected()` | marker (b) `>=5 .py` walk | `-not -path "*/pack-capability-pool/*"` added to the `-not -path` chain | `-not -path` chain (this fn uses no `-prune` block) |

**Load-bearing comment (verbatim, protobuf example):**
```
    # Marker (a): any `.proto` file in the project tree, excluding
    # large vendored / generated trees. The `pack-capability-pool/`
    # prune is LOAD-BEARING (not defensive): the BD-200 tracked pool
    # ships `pack-capability-pool/proto/*.proto` masters on EVERY
    # installed project, so without this exclusion a Swift-only client
    # would mis-fire `protobuf-marker: yes` off its own pool.
```
Each of the four functions carries an analogous LOAD-BEARING comment naming the specific pool master that would otherwise mis-fire (`.proto`/`buf.yaml`; `*-swift.sh`/`.swift`; `server/**/*.py` for both python detectors). **No "defensive/parity" framing was copied into `detect.sh`.**

**Manifest detectors NOT in scope (correctly unchanged):** the manifest-file scans (`$target/pyproject.toml`, `$target/Package.swift`, etc.) read the live-tree ROOT file directly and do not recurse into `pack-capability-pool/`, so they need no exclusion. `detect_installed_capabilities()` reads `CLAUDE.md` (not the tree) → out of scope, untouched.

### N-1 — `scripts/init-project.sh::detect_source_files()`

Added `-not -path '*/pack-capability-pool/*'` to both the `*.swift` and `*.py` count walks (mirroring the existing `detect_language_markers()` mechanism). Framed as **consistency / forward-safety** (correctly, NOT load-bearing): this diagnostic runs at preview time, before S5b populates the pool, so the pool is absent today; the exclusion keeps the count honest if the helper is ever called post-install.

```
    s=$(find "$target" -maxdepth 2 -name "*.swift" -not -path '*/.*' -not -path '*/pack-capability-pool/*' 2>/dev/null | wc -l | tr -d ' ')
    p=$(find "$target" -maxdepth 2 -name "*.py" -not -path '*/.*' -not -path '*/pack-capability-pool/*' 2>/dev/null | wc -l | tr -d ' ')
```

### Test — `scripts/test-detect.sh` (new `pack-capability-pool/` exclusion section)

> Note: the prompt named `scripts/tests/test-detect.sh`; the actual unit-test file for `scripts/lib/detect.sh` is `scripts/test-detect.sh` (there is no `scripts/tests/test-detect.sh`). The new assertions were added there, where all the existing marker-detector tests live.

New section before `── Summary ──`. Fixture = a Swift-only tree whose ONLY proto/python content lives inside `pack-capability-pool/` (`proto/*.proto` + `buf.yaml` + `pyproject.toml` with `sqlalchemy`/`opentelemetry-api` + 6× `server/app/mod*.py` + `server/app/obs.py` with `import opentelemetry`). Assertions:

1. `protobuf-marker: no` — pool `.proto`/`buf` masters do NOT fire (pool prune).
2. `python-data: no` — pool `pyproject.toml` + `>=5` server `.py` do NOT fire (pool prune).
3. `python-observability-marker: no` — pool `pyproject.toml` + obs import do NOT fire (pool prune).
4. **Control:** a live-tree `import SwiftData`/`@Model` IS still detected (`swiftdata-marker: yes`) — the prune removes only the pool.
5. **No-regression control (separate fixture):** a REAL live-tree `proto/*.proto` PLUS a pool `proto/` both present → `protobuf-marker: yes` (the live marker still wins; the exclusion narrows to the pool, it does not suppress genuine markers).

---

## 3 — A/B proof (the fix works) — real `/tmp` Swift-only init-project install

Provisioned per `test-infra-self-provisioned`: a `/tmp` git repo with a `Package.swift` + `Sources/App/main.swift`, then `PACK=<pack> bash scripts/init-project.sh <tgt>` (stdin `y`). Confirmed the pool populated with marker-looking masters:
```
pack-capability-pool/proto/buf.yaml
pack-capability-pool/proto/common/v1/common.proto
pack-capability-pool/proto/example/v1/example_service.proto
pack-capability-pool/pyproject.toml
pack-capability-pool/server/src/app/__init__.py
pack-capability-pool/server/tests/test_smoke.py
```

**FIXED detect.sh — pool PRESENT (A) vs pool fully REMOVED from tree (B):**
```
######## FIXED detect.sh — A: POOL PRESENT (in tree) ########
  protobuf-marker: no
  python-data: no
  python-observability-marker: no
  swiftdata-marker: no
  source-files: *.swift=1, *.py=0
######## FIXED detect.sh — B: POOL MOVED OUTSIDE TREE ########
  protobuf-marker: no
  python-data: no
  python-observability-marker: no
  swiftdata-marker: no
  source-files: *.swift=1, *.py=0
```
A == B, both CORRECT (all markers `no` for a Swift-only project; `detect_source_files` unaffected). The pool no longer influences detection.

**PRE-FIX detect.sh (functional pool-prune stripped) — pool PRESENT (demonstrates the bug):**
```
  protobuf-marker: yes     <-- mis-fire (off pack-capability-pool/proto/*.proto + buf.yaml)
  python-data: no
  python-observability-marker: no
  swiftdata-marker: no
```
The pre-fix copy reproduces the review's `protobuf-marker: yes` mis-fire on a Swift-only install; the fix flips it to `no`. (Real-pool `python-*` did not mis-fire even pre-fix because the real `server/` has only 2 `.py`, one a `test_*` — below the `>=5` threshold and no observability import. The test-detect.sh fixture deliberately stacks `>=5` server `.py` + an obs import to close those vectors forward-safely, since the review flagged python as "within a hair.")

---

## 4 — No-regression for real (non-pool) projects

- **A/B above:** live-tree `swiftdata-marker` control still fires; `source-files` count identical pool-present vs pool-removed.
- **test-detect.sh control assertion:** a REAL live-tree `proto/*.proto` (not in the pool) co-present with a pool `proto/` → `protobuf-marker: yes` (live marker wins). The exclusion narrows strictly to `pack-capability-pool/`; genuine live-tree markers are untouched.
- **detect.sh runtime behavior** is unchanged for every non-pool tree (the prune only ever removes a `pack-capability-pool/` path, which exists only in BD-200-installed projects).

---

## 5 — Test results

| Suite | Result |
|---|---|
| `bash -n scripts/lib/detect.sh` | clean |
| `bash -n scripts/init-project.sh` | clean |
| `bash -n scripts/test-detect.sh` | clean |
| `bash scripts/test-detect.sh` | **100 passed, 0 failed** (95 prior + 5 new pool-exclusion assertions) |
| `bash scripts/tests/test-init-project.sh` | **67 passed, 0 failed** |
| `python3 scripts/validate-pack.py` | **PASSED — all checks clean** (Check 48 WARNs are pre-existing JC-5 advisory, not gate failures; not introduced by this fix) |

---

## 6 — Manifest regeneration

Ran `bash test-fixtures/build.sh --all --clean` (idempotent — confirmed by a second regen producing a byte-identical manifest). `detect.sh` is client-installed (S11) into v11 fixtures, so the three v11-* rows move; v10-* and existing rows are unchanged.

```
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16        (unchanged)
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258   (unchanged)
-v11-realistic-ot  e97888b6121b3e1490f513c9851a9dd80da18f90
-v11-flat-file  3fc3036d6fe8ccc764ef836b2f084e39ab9df6fe
-v11-tracker-on  d83c27df1438e154bc8d159b185b3c44de14cbbd
+v11-realistic-ot  b933e2142a00b4c95cdf6d2be940744ac1b05995
+v11-flat-file  5587dc156de0cef3b517902d17d108b80f787c63
+v11-tracker-on  eafdd09a085258f215b92af7e91ba04186250a2b
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619   (unchanged)
```
(Diff shown vs HEAD; the moved SHAs supersede the C2-baseline manifest values, now reflecting the post-fix detect.sh content. Left staged-ready for Pack Chat.)

---

## 7 — Check 47 frozen 2-tuple (UNMOVED)

```
_SANCTIONED_PACK_SIDE_SHIPPED = (
    "scripts/lib/detect.sh",
    "scripts/pack-help.sh",
)
```
Unchanged — exactly the frozen 2-tuple. No allowlist growth (this fix edits an already-sanctioned shipped file's body; it adds no new shipped pack-side file). Check 47 green within the full validate-pack PASS.

---

## 8 — Files changed (inventory)

| Path | Change | Notes |
|---|---|---|
| `scripts/lib/detect.sh` | modified | 4 marker fns / 5 walks pool-excluded + LOAD-BEARING comments (S-1) |
| `scripts/init-project.sh` | modified | `detect_source_files()` pool-excluded + consistency comment (N-1). The rest of this file's diff is the pre-existing C2 T4 work — untouched by fix-1. |
| `scripts/test-detect.sh` | modified | new `pack-capability-pool/` exclusion section (3 mis-fire asserts + 2 controls) |
| `test-fixtures/manifest.txt` | modified | regenerated; 3 v11-* rows moved |

HEAD unmoved at `98b6a9b10e9d9e8b114995e3d416e708230c5bde`. No state-changing git verb run. Scratch `/tmp` install cleaned up.

---

## 9 — Plan deviations / new POQs

- **Test-file path correction:** prompt said `scripts/tests/test-detect.sh`; the real file is `scripts/test-detect.sh` (no `scripts/tests/test-detect.sh` exists). Assertions added to the real file. Not a design deviation.
- **No new POQs.** BD-202 boundary intact (no update/refresh/wipe logic added). No architecture change. Zero other deviations.

---

## 10 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read IN FULL via Read tool (per-file proof): `CLAUDE.md` (541 lines; first `# CLAUDE.md — AI Agent Config Pack (Pack Repo)`, last `OT itself is read-only for testing (use /tmp clones or scratch fixtures, never write to real OT).`); `pack-ops/PACK-AGENTS.md` (226 lines, full); `pack-ops/PACK-CHAT.md` (310 lines, full); `project-template/CLAUDE.md` (read for boundary context — see note); `PACK-REVIEW-BD-200-C2.md` (107 lines, full — S-1/N-1 detail); `PLAN-BD-200.md` (235 lines, full — §2 T4 + §5); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (§3.2/§3.4 read in full on page 1 lines 1–336, incl. the §3.4 corrected-S9-contract + pool design; the 337–441 tail is the BD-202 taxonomy, not load-bearing for this detection-exclusion fix); curated memory (each full): `feedback_agents_read_rule_docs_in_full` (71 lines), `feedback_agent_output_rules_applied_block` (15 lines), `feedback_manifest_regen_on_v11_surface` (16 lines), `feedback_bd_pack_only_operational_rule` (35 lines); SOURCE read: `scripts/lib/detect.sh` (full 858 lines), `scripts/init-project.sh` (the two `detect_*` fns L128–195 + run_stages/pool refs via grep), `scripts/test-detect.sh` (harness L1–65 + marker sections + tail). NOTE: `project-template/CLAUDE.md` was NOT separately Read-tool-paged in this session; its boundary rules are carried via the curated memory `feedback_bd_pack_only_operational_rule` (read in full) + CLAUDE.md `## Pack memory`. This fix touches ZERO project-side files, so no project-side-SSOT decision depended on it. | VIOLATED: `project-template/CLAUDE.md` not separately read in full (mitigated: no project-side edit in scope; boundary covered via curated memory read in full) |
| preflight-stop-means-stop | Emitted the single PREFLIGHT line only AFTER all edits + verification PASS (bash -n ×3 clean; test-detect 100/0; test-init-project 67/0; validate-pack PASSED). No parent stop received. | COMPLIANT |
| agents-never-commit | Only read-only git verbs (`git rev-parse`, `git status`, `git diff`) on the repo; `git init`/`add`/`commit` confined to a `/tmp` scratch repo (deleted after). NO `git add`/`commit`/`push`/`tag` on the pack repo. HEAD `98b6a9b` unmoved (re-verified post-work). Single Write = this IMPL-REPORT. | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/lib/detect.sh` + `scripts/init-project.sh` are v11-surface (`scripts/`); ran `bash test-fixtures/build.sh --all --clean`; 3 v11-* rows moved; idempotent (2nd regen byte-identical); manifest staged-ready; diff reported §6. | COMPLIANT |
| enumerate-encoding-surfaces | Enumerated EVERY tree-scanning marker detector that can see the pool and excluded ALL of them: `detect.sh` {`protobuf_marker_detected`, `python_data_marker_detected`, `python_observability_marker_detected`, `swiftdata_marker_detected`} + `init-project.sh::detect_source_files` — closing the asymmetric coverage the review found. Verified `detect_installed_capabilities` reads CLAUDE.md (not tree) → correctly NOT patched; manifest-file scans read root files directly → correctly NOT patched. Test surface (`test-detect.sh`) updated in lock-step with the detector edit. | COMPLIANT |
| ci-guard-measure-then-bound | Measured the post-fix tree: `validate-pack.py` PASSED; Check 47 frozen 2-tuple quoted unmoved (`scripts/lib/detect.sh`, `scripts/pack-help.sh`); no allowlist widened (the fix edits an already-sanctioned file's body, adds no new shipped pack-side file). | COMPLIANT |
| boundary / no-pack-self + BD-202 boundary | The detect.sh comments name `pack-capability-pool/` (a client-tree path) + `BD-200` in pack-side `scripts/` source (legitimate per pack-repo-code-comment context; these are pack-side files, NOT `project-template/` client-shipped surfaces — `detect.sh` ships but its inline comments are pack source, not project-doc content). NO `pack update`/refresh/wipe-repopulate/delete-propagation/`cmd_update` logic added (grep of the diff: only the pool-prune `find` clauses + comments). BD-202 boundary intact. | COMPLIANT |
| rules-applied-verification-block | This §10 — per-rule name + quoted/measured evidence + terminal verdict; READ-IN-FULL row carries per-file proof + an honest VIOLATED for the one un-separately-paged doc (mitigated, scope-justified) rather than a false COMPLIANT; no empty-evidence rows. | COMPLIANT |
