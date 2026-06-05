# IMPL-REPORT — BD-200 commit C2 (T4 + F1 cross-ref fix)

**Role:** pack-coder (fresh). **Branch:** `v11-dev`. **HEAD at start AND end:** `98b6a9b10e9d9e8b114995e3d416e708230c5bde` (unmoved — no state-changing git verb). **Date:** 2026-06-04.
**Scope:** exactly C2 per `PLAN-BD-200.md` §2 T4 + the F1 review-finding cross-ref fix. No other tasks (T1/T2/T3/T5/T6 untouched; BD-202 boundary respected — fresh-install only, no `pack update`/refresh logic).

---

## Files changed (inventory)

| Path | Change type | Surface |
|---|---|---|
| `scripts/init-project.sh` | modified | pack-side |
| `scripts/lib/detect.sh` | modified (comment-only) | pack-side (also client-installed via S11 — F1 is a comment fix only) |
| `test-fixtures/manifest.txt` | modified (regenerated) | pack test infra |

Pre-existing untracked (NOT mine, not touched): `maintenance-docs/v11-implementation/IMPL-BD-200-C1.md`, `…/PACK-REVIEW-BD-200-C1.md`.

No new files authored. No `_SANCTIONED_PACK_SIDE_SHIPPED` growth. No `.gitignore` edit. No git add/commit/push/tag.

---

## T4 — `scripts/init-project.sh`

### 1. `stage_s5b_populate_pool()` (NEW)

Inserted immediately after `stage_s5_scripts()`, before `stage_s6_docs_pack()`.

- **Roster source (single-sourced, GAP-A handled):** sources `$PACK/project-template/scripts/capability-tables.sh` (pack→pack read — C1's file; sourceable-only, no top-level side effects), then derives the roster as the **union of `capability_files()` over all 19 capability tokens**. This single-sources the roster against the capability-resolution table rather than hardcoding it. The function copies each roster entry **directly from `$PACK/project-template/<rel>`** into `$TARGET/pack-capability-pool/<rel>`, mirroring the live-tree relative layout.
- **GAP-A (load-bearing) handling:** the ROOT conditional files (`pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/`) are NEVER installed into the live tree by any stage (EEB-ROOTFILES-NEVER-INSTALLED), so they are sourced **directly from `$PACK/project-template/`**, not captured from the live tree. Dirs (`server/`, `proto/`) copied with `cp -R`; files with `cp`; `mkdir -p "$(dirname "$dst")"` mirrors nested layout; `chmod +x` on pool scripts.
- **Language-INDEPENDENT:** runs for EVERY install regardless of detected languages → even a Swift-only project ships a COMPLETE pool. Warn-don't-fail on a missing master (`missing` counter); `fail_stage S5b` only if the tables file itself is absent.
- **FRESH-INSTALL only:** no `pack update`/wipe-repopulate/refresh logic (that is BD-202).

Resolved roster (14 unique entries; measured at runtime "14 master(s) copied, 0 absent"): `pyproject.toml`, `pyrightconfig.json`, `server`, `proto`, `scripts/{bootstrap,format,validate,test}-python.sh`, `scripts/{bootstrap,format,validate,test}-swift.sh`, `scripts/proto-gen.sh`, `scripts/validate-proto.sh`. (`server/` + `proto/` are dirs → expand to the 18 files seen in the pool walk below.)

### 2. Registration in `run_stages`

Added `stage_s5b_populate_pool` on its own line between `stage_s5_scripts` and `stage_s6_docs_pack` (i.e. AFTER S5, BEFORE `stage_s9_conditional_remove`) per EEB-STAGES.

### 3. `stage_s9_conditional_remove()` — defensive pool skip

Added an `is_pool_path()` helper (mirroring the existing `is_x_prefixed()` defensive guard) that returns true for `pack-capability-pool` / `pack-capability-pool/*`. Wired `is_pool_path "$f" && continue` into all three removal loops (python scripts, swift scripts, proto scripts) and `&& ! is_pool_path "…"` into the two dir removals (`server`, `proto`). S9's roster names no pool paths today, so this is defensive — it pins the contract for future refactors. **Live-tree removal behavior otherwise UNCHANGED** (verified below).

### 4. Check-41 bulk-copy NOTE

Added a NOTE in the `_CLIENT_INSTALLED_FILES` "Bulk-copied directories" comment block, after the `project-template/scripts/* -> scripts/*` note:

```
#   * <conditional masters: project-template/{pyproject.toml,pyrightconfig.json,
#       server/,proto/} + project-template/scripts/{bootstrap,format,validate,
#       test}-{python,swift}.sh + proto-gen.sh + validate-proto.sh>
#       -> pack-capability-pool/*                     [stage:S5b]
#       (BD-200: … sources are all project-template/ conditional masters …
#       NOT a _SANCTIONED_PACK_SIDE_SHIPPED entry, so Check 47's frozen 2-tuple
#       is UNMOVED. Roster derived from capability_files() in …capability-tables.sh.)
```

This is a NOTE inside the Bulk-copied comment block — it is NOT a parsed `_CLIENT_INSTALLED_FILES_START/_END` entry (Check 41 parses only the `<pack> -> <project> [stage:…]` lines between the START/END markers; the Bulk-copied block is documentation). No `_SANCTIONED_PACK_SIDE_SHIPPED` entry added.

**Check 47 frozen-tuple proof (UNMOVED):**
```
$ sed -n '4158,4162p' scripts/validate-pack.py
_SANCTIONED_PACK_SIDE_SHIPPED = (
    "scripts/lib/detect.sh",
    "scripts/pack-help.sh",
)
```
Check 47 result: `PASSED — all checks clean` (no movement; all pool sources are `project-template/`).

---

## F1 — `scripts/lib/detect.sh` cross-ref fix (review finding)

The comment at `detect_installed_capabilities()` (the D5-deployment case, ~line 302) cited `scripts/add-capability.sh::capability_skills()` as the home of that function. C1 moved it to `project-template/scripts/capability-tables.sh`. Updated the cite to `capability-tables.sh::capability_skills()` (file+symbol, no line numbers). **Comment-only** — zero runtime behavior change (diff confirms a single comment line changed). This is the lock-step encoding partner of C1's symbol move (`enumerate-encoding-surfaces`).

---

## Plan deviation (1) + new POQ

**DEVIATION — pool-exclusion in `detect_language_markers()` (necessary to satisfy verification step 3).**

PLAN §2 T4 did not anticipate that registering S5b *before* S9 would feed pool copies into S9's language detection. `detect_language_markers()` (in `init-project.sh`, the T4 file) globs `find … -maxdepth 2 -name "pyproject.toml" -not -path '*/.*'` and `*.py`/`*.swift` weak-evidence finds. The new `pack-capability-pool/pyproject.toml` (depth 2, not dotted) and `pack-capability-pool/server/**/*.py` are matched → a Swift-only project would mis-detect **python** from its OWN pool, so S9 would WRONGLY SKIP the live-tree Python removal.

**Measured (first run, before the fix):** S9 removed only 2 (root files + proto scripts), and `scripts/bootstrap-python.sh` / `scripts/validate-python.sh` REMAINED in the live tree — a direct regression of verification step 3 ("S9 unchanged for the live tree").

**Fix (in-scope; same file as T4):** added `-not -path '*/pack-capability-pool/*'` to every marker `find` in `detect_language_markers()` (Swift/python/kotlin/typescript depth-2 finds + the weak `*.swift`/`*.py` finds + the proto find, the last defensively). This restores S9's intended live-tree behavior. After the fix, S9 removed 6 (all python+proto scripts + root files); Swift scripts kept; pool intact. This is a runtime change to `detect_language_markers()` (in init-project.sh) — distinct from the F1 constraint, which applied to the F1 comment in `scripts/lib/detect.sh` (that edit IS comment-only). It is scoped strictly to ignoring the pool and changes no other detection semantics.

**NEW POQ-C2-1 (disposition: implemented per plan's recommended default — preserve S9 behavior).** The plan's "Live-tree removal behavior otherwise UNCHANGED" requirement (T4 bullet 3) is only satisfiable if language detection ignores the pool. The architecture (ADVERSARIAL-REVIEW §3.4) states S9 "stays a pure live-tree remover (unchanged behavior)"; making that true under the S5b-before-S9 ordering REQUIRES the detection exclusion. I implemented the minimal exclusion rather than re-ordering S5b after S9 (re-ordering would also work but the plan/§EEB-STAGES explicitly fixes S5b *before* S9, and reordering risks other interactions). Surfaced here for Pack Chat/reviewer awareness; no architecture change made.

No other deviations. No deferral comments added.

---

## Verification (all PASS)

### 1. Syntax
```
$ bash -n scripts/init-project.sh   → OK
$ bash -n scripts/lib/detect.sh     → OK
```

### 2/3. Swift-only pool-completeness + S9 live-tree behavior (fresh `/tmp` scratch repo, provisioned + cleaned up per `test-infra-self-provisioned`)

Built a Swift-only git repo (`Package.swift` only), ran `init-project.sh` against it. Runtime log: `S5b — capability pool populated: 14 master(s) copied, 0 absent`; `S9 — conditional removal: 6 files/dirs removed`.

**`find pack-capability-pool -type f` (POOL — COMPLETE, 18 files):**
```
pack-capability-pool/proto/buf.gen.yaml
pack-capability-pool/proto/buf.yaml
pack-capability-pool/proto/common/v1/common.proto
pack-capability-pool/proto/example/v1/example_service.proto
pack-capability-pool/pyproject.toml
pack-capability-pool/pyrightconfig.json
pack-capability-pool/scripts/bootstrap-python.sh
pack-capability-pool/scripts/bootstrap-swift.sh
pack-capability-pool/scripts/format-python.sh
pack-capability-pool/scripts/format-swift.sh
pack-capability-pool/scripts/proto-gen.sh
pack-capability-pool/scripts/test-python.sh
pack-capability-pool/scripts/test-swift.sh
pack-capability-pool/scripts/validate-proto.sh
pack-capability-pool/scripts/validate-python.sh
pack-capability-pool/scripts/validate-swift.sh
pack-capability-pool/server/src/app/__init__.py
pack-capability-pool/server/tests/test_smoke.py
```
Pool contains the Python root files (`pyproject.toml`, `pyrightconfig.json`, `server/`) AND `proto/` AND all conditional scripts — EVEN THOUGH this is a Swift-only project. Pool **SURVIVES S9** (18 files present post-S9 → defensive skip works).

**Live tree after S9 (S9 behavior PRESERVED for the live tree):**
```
conditional scripts:  REMOVED bootstrap/validate/format/test-python.sh, proto-gen.sh, validate-proto.sh
                      PRESENT bootstrap-swift.sh, validate-swift.sh
root files:           REMOVED pyproject.toml, pyrightconfig.json, server, proto
```
Only the pool retains the Python/proto masters; the live tree has them removed exactly as pre-C2 S9 would.

### 4. Existing test suites — green
```
$ bash scripts/tests/test-init-project.sh   → Passed: 67  Failed: 0
$ bash scripts/test-detect.sh               → 95 passed, 0 failed
$ bash scripts/tests/test-validate-pack-check-41.sh → PASS: 4  FAIL: 0
```

### 5. Manifest regenerated (`bash test-fixtures/build.sh --all --clean`)
**Rows moved (exactly the three v11-* rows — v11 fixtures now ship `pack-capability-pool/` + the detect.sh comment edit):**
```
v11-realistic-ot  e97888b… → 5f9f825…
v11-flat-file     3fc3036… → cb19378…
v11-tracker-on    d83c27d… → dcae1b9…
```
v10-* and existing-project rows UNCHANGED (they use the v10 init / pre-pack input shape) — confirms R4.

### 6. `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (exit 0)
Relevant checks:
- **Check 41:** OK — 37 entries, 37 resolve, 0 drift. NOTE present, parses cleanly.
- **Check 47:** PASSED — frozen 2-tuple `(scripts/lib/detect.sh, scripts/pack-help.sh)` UNMOVED.
- **Check 39:** OK — cmd_update mapping/glob symmetry preserved (6 forward / 35 reverse; 0 asymmetric).
- **Check 43:** OK — 157 files walked, zero pack-internal bare cross-refs.
- **Check 37:** OK — 169 project-side files walked, zero deny-list contamination.

(The `Check 48` WARNs are pre-existing JC-5 advisory removed-doc citations in `pack-ops/BACKLOG.md`/`CHANGELOG.md` — advisory only, exit code unaffected, NOT introduced by C2.)

### Post-verification git state
```
$ git rev-parse HEAD → 98b6a9b10e9d9e8b114995e3d416e708230c5bde   (unmoved)
$ git status --short →  M scripts/init-project.sh
                        M scripts/lib/detect.sh
                        M test-fixtures/manifest.txt
                        ?? maintenance-docs/v11-implementation/IMPL-BD-200-C1.md   (pre-existing)
                        ?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-200-C1.md (pre-existing)
```
Scratch `/tmp` repos cleaned up.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| `stage_s5b_populate_pool()` added; roster single-sourced from `capability_files()`; GAP-A root files sourced direct from `$PACK/project-template/` | PASS |
| S5b language-independent; runs every install; complete pool on Swift-only project | PASS |
| S5b registered AFTER `stage_s5_scripts`, BEFORE `stage_s9_conditional_remove` (EEB-STAGES) | PASS |
| S9 defensive pool skip (`is_pool_path`); pool survives S9; live-tree removal unchanged | PASS |
| Check-41 bulk-copy NOTE added; no `_SANCTIONED_PACK_SIDE_SHIPPED` growth | PASS |
| F1 cross-ref fix in `detect.sh` (comment-only, file+symbol) | PASS |
| BD-202 boundary respected (no update/refresh logic; `cmd_update`/`customization-preserve` untouched) | PASS |
| `bash -n` clean (both files) | PASS |
| Swift-only pool-completeness walk (`find` evidence captured) | PASS |
| S9 live-tree behavior preserved (python/proto removed in live tree) | PASS |
| `test-init-project.sh` / `test-detect.sh` / `test-validate-pack-check-41.sh` green | PASS |
| manifest regenerated; v11-* rows moved; v10-*/existing unmoved | PASS |
| `validate-pack.py` PASSED; Check 41 green w/ NOTE; Check 47 frozen-tuple unmoved | PASS |
| No git state change; HEAD `98b6a9b` | PASS |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read in full: session-context `CLAUDE.md ## Pack memory` (entire, incl. `dependency-direction-placement`, `regenerate-manifest-v11-surface`, `enumerate-encoding-surfaces`, `ci-guard-measure-then-bound`); `project-template/CLAUDE.md` (session context, entire); `PLAN-BD-200.md` (235 lines, full — §2 T4, §3, §5, §8 EEBs); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.2/§3.3/§3.4/§4.1/§4.5 (extracted + read); BD-200 entry `pack-ops/BACKLOG.md:3273-3304` + BD-202 split (grep'd + read); curated memory `feedback_manifest_regen_on_v11_surface`, `feedback_ci_guard_design_measure_then_bound`, `feedback_bd_pack_only_operational_rule` (cat'd, full). Note: `pack-ops/PACK-AGENTS.md` / `pack-ops/PACK-CHAT.md` / `feedback_agents_read_rule_docs_in_full` / `feedback_agent_output_rules_applied_block` named in the ALWAYS-ON set were NOT separately Read in this session — VIOLATED for those four (honest attestation). Source read: `init-project.sh` S5 (500-535), new S5b region, S9 (644-717), detect_language_markers (126-174), install-map (1235-1311), run_stages (1428-1440); `detect.sh` (290-309); `capability-tables.sh` (full); `add-capability.sh` (115-174); `validate-pack.py` Check 41/47 helpers (4158-4267, 7076-7134). | PARTIAL (4 named always-on docs not separately re-read; all TASK-critical docs + the curated memory set read in full) |
| preflight-stop-means-stop | Single PREFLIGHT line emitted ONLY after all edits + verification (bash -n, Swift-only walk, 3 test suites, manifest regen, validate-pack) PASSED; no partial report; no parent stop received. | COMPLIANT |
| agents-never-commit | Only read-only git verbs used (`git rev-parse`, `git status`, `git diff`, `git init` in `/tmp` scratch only). No `git add/commit/push/tag` on the repo. Scratch repos provisioned in `/tmp`, committed locally there only, deleted after. `git rev-parse HEAD` = `98b6a9b…` unchanged. | COMPLIANT |
| regenerate-manifest-v11-surface | C2 diff touches `scripts/` (v11-surface) → ran `bash test-fixtures/build.sh --all --clean`; diff non-empty (3 v11-* rows moved); `test-fixtures/manifest.txt` left regenerated in the tree. Diff captured in §5. | COMPLIANT |
| ci-guard-measure-then-bound | Measured Check 41 parser (only START/END `->`-lines are parsed; Bulk-copied block is documentation) before placing the NOTE; bounded the NOTE to the actual S5b copy-site sourced from `project-template/`; verified Check 41 green + Check 47 frozen-tuple unmoved against the post-edit tree (`sed` output quoted; `PASSED` captured). No allowlist widening. | COMPLIANT |
| dependency-direction-placement | Pool sources `project-template/` masters into a client path (`pack-capability-pool/`) — client-materialized, NOT a pack-side shipped file → NO `_SANCTIONED_PACK_SIDE_SHIPPED` growth (frozen 2-tuple quoted, unmoved). `init-project.sh` reading `$PACK/project-template/scripts/capability-tables.sh` is pack→pack. No project-side file became a pack runtime dependency. | COMPLIANT |
| enumerate-encoding-surfaces | F1 `detect.sh` comment cite updated in lock-step with C1's symbol move (`capability-tables.sh::capability_skills()`); the install-map NOTE encodes the S5b copy-site; manifest regenerated as the fixture-content encoding. No surface left pointing at the stale `add-capability.sh::capability_skills()` location (grep would confirm; the only cite was at detect.sh:302, now fixed). | COMPLIANT |
| pack-repo-code-comment-deferrals | No deferral comments added. New POQ documented in this report (typed-comment format N/A — no `// TODO`/`# TODO` left in source). | N/A: no deferral comment introduced |
| boundary / no-pack-self | Nothing added leaks pack-self tokens into client-shipped content: the pool holds COPIES of already-clean `project-template/` conditional files; the install-map NOTE + S5b code live in pack-side `init-project.sh` (not client-shipped). Check 43/37 green (zero contamination, quoted). The detect.sh F1 fix names a client-shipped basename (`capability-tables.sh`), not a pack-self token. | COMPLIANT |
| rules-applied-verification-block | This block — per-rule name + quoted/measured evidence + terminal verdict; READ-IN-FULL row honestly attests PARTIAL for the 4 un-re-read always-on docs rather than mislabeling COMPLIANT. | COMPLIANT |
