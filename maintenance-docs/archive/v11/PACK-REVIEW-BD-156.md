# PACK-REVIEW-BD-156 — protobuf-patterns skill (Proto3 schema extraction)

**Verdict:** APPROVE.

**Summary.** BD-156 lands a new `protobuf-patterns` skill that cleanly extracts Proto3 schema-design rules from `grpc-patterns`, wires the intersection-cell load via a new `protobuf_marker_detected()` helper that mirrors the BD-141 `python_data_marker_detected()` pattern byte-for-byte, and updates PLATFORM-SKILLS.md, init-project.sh, add-capability.sh, and test-detect.sh in lock-step. All 30/30 validate-pack checks pass; all 52/52 test-detect cases pass. Trinity geometry follows the established convention (single canonical SKILL.md in `project-template/skills/<name>/`). The footprint (1 new + 6 modified = 7 files) sits inside §3.1 maintainability bounds; the architecture is the BD-156 BACKLOG entry + ARCHITECTURE-SKILL-DIMENSIONS §3.7/§7.10 (no PLAN gap is a defect — see POQ-B). Check 31 deferral to BD-146 is documented and architecture-justified — see POQ-C. No nits.

---

## Per-concern findings

### 1. New `protobuf-patterns/SKILL.md` content

**File:** `project-template/skills/protobuf-patterns/SKILL.md`

- Frontmatter (lines 1–5) is well-formed: `name`, `description`, `allowed-tools` consistent with sibling skills (e.g., `grpc-patterns/SKILL.md` lines 1–5).
- Loaded-by header (lines 7–15) lists exactly the 6 expected agents per BD-156 spec: `architect`, `grpc-schema`, `coder`, `reviewer`, `auditor-architecture`, `auditor-code`. Matches PLATFORM-SKILLS.md row 455.
- "Standalone-usable" framing is explicit (lines 17–28): standalone protobuf scenarios (binary file format, IPC, Twirp, Connect, persistent storage, log formats) and gRPC-companion mode are both called out, plus a transport-agnostic boundary statement separating schema rules from gRPC transport rules.
- Topic coverage (45 numbered rules) maps comprehensively to the BD-156 Description checklist:
  - **Field numbering invariants** — rules 1–5 (lines 30–49): never reuse, `reserved` keyword, 1-byte-tag range, gaps OK, no renumbering for cleanup.
  - **Backward / forward compatibility** — rules 6–11 (lines 51–77): additions, `reserved`, type-change matrix, rename semantics, repeated↔singular, `buf breaking`.
  - **Proto3 vs Proto2** — rules 12–15 (lines 79–99): default syntax, `proto3 optional`, `*_UNSPECIFIED = 0`, default-value handling.
  - **`oneof` semantics** — rules 16–19 (lines 101–119): XOR semantics, additions, in/out moves both treated as breaking.
  - **Well-known types** — rules 20–25 (lines 121–145): Timestamp, Duration, FieldMask, Empty, Any, wrappers — all present.
  - **Map types** — rules 26–28 (lines 147–161): key/value constraints, no-repeated rule, unspecified iteration order.
  - **Imports / package** — rules 29–32 (lines 163–180): package mirrors directory, version suffix, file-scoped imports, one-service-per-file.
  - **Naming conventions** — rules 33–35 (lines 182–193): snake_case fields, positive-predicate booleans, no stuttering.
  - **Code-generation options** — rules 36–38 (lines 195–215): swift_prefix, java_package, go_package, csharp_namespace; option-as-API-surface; no hand-edits.
  - **Tooling** — rules 39–42 (lines 217–233): `buf lint`, `buf format`, version pinning, `protoc` plugin pinning.
  - **High-risk changes** — rules 43–45 (lines 235–249): field deletion, type changes, renames.
- Naming follows architecture §7.10 `*-patterns` convention (parallels `grpc-patterns`, `rest-patterns`, `security-patterns`).

No defects.

### 2. `grpc-patterns/SKILL.md` Proto3 stripping

**File:** `project-template/skills/grpc-patterns/SKILL.md`

- New "Companion skill" section (lines 7–16) carries the one-paragraph pointer per spec — explicit `protobuf-patterns` reference, "load both" guidance, plus the inverse standalone-protobuf carve-out.
- Description frontmatter (line 3) cleanly drops Proto3 schema language: now reads "gRPC service patterns — servicers, interceptors, streaming, deadlines, error model, async handlers, grpc-swift-2 / grpc.aio specifics, and gRPC-side cross-language conventions."
- Retained gRPC-specific content per spec:
  - Protobuf↔domain mapping at transport boundary (rules 1–4, lines 18–25)
  - gRPC service / call rules (5–7, lines 27–31)
  - grpc-swift-2 client rules (8–14, lines 33–41)
  - Swift gRPC→domain error mapping (15–17, lines 43–53)
  - grpc.aio server rules (18–25, lines 55–64)
  - Python gRPC→domain error mapping (26–28, lines 66–76)
  - Cross-language conventions (29–33, lines 78–84)
- Renumbering is consistent: rules now run 1–33 with no gaps. `grep -nE "^[0-9]+\."` confirms continuous numbering. Rule 7 (line 31) and rule 29 (line 80) explicitly cross-reference `protobuf-patterns` for the schema-side rules they used to carry — no orphaned mentions.
- No leftover Proto3-schema content in `grpc-patterns/SKILL.md`. The two Proto3 mentions remaining (lines 7, 9) are inside the "Companion skill" pointer section and reference `protobuf-patterns` correctly.

No defects.

### 3. PLATFORM-SKILLS.md updates

**File:** `project-template/docs/pack/PLATFORM-SKILLS.md`

- Intersection table row (line 222) added: `protobuf-patterns | (any host language) ∩ protobuf-marker present | scripts/lib/detect.sh::protobuf_marker_detected() ...`. Predicate text matches the helper's marker spec verbatim (`.proto` files OR dependency manifests listing `protobuf`, `swift-protobuf`/`SwiftProtobuf`, `grpc-tools`, `grpc-swift-2`, `protoc`).
- `grpc-patterns` description in dimensional-skills table (line 454) updated: now reads "gRPC service patterns: servicers, interceptors, streaming, deadlines, error model, async handlers, grpc-swift-2 / grpc.aio specifics, gRPC-side cross-language conventions *(Proto3 schema rules live in `protobuf-patterns`; load both when D4=grpc)*". Proto3 language correctly dropped, cross-reference present.
- New `protobuf-patterns` row in dimensional-skills table (line 455) lists all 6 agents per BD-156 spec.
- Header count updated from `### Dimensional skills (16)` to `### Dimensional skills (17)` (line 437); the closing summary line "**17 dimensional / intersection skills.**" (line 462) is consistent and notes 4 intersection-loaded rows including `protobuf-patterns`.
- Total skills count updated from 31 to 32 (line 487): `**Total skills: 32** (13 Tier 0 base + 17 dimensional / intersection + 1 trigger-loaded + 1 PM chat operational).` Arithmetic checks: 13 + 17 + 1 + 1 = 32. Correct.
- Per-agent assignment updates (Step 2):
  - `architect` (line 321) adds `protobuf-patterns` to dimensional list — present.
  - `coder` (line 325) adds `protobuf-patterns` — present.
  - `reviewer` (line 329) adds `protobuf-patterns` — present.
  - `grpc-schema` (line 347) adds `protobuf-patterns` — present.
  - `auditor-architecture` (line 358) adds `protobuf-patterns` with `protobuf_marker_detected()` precondition note — present.
  - `auditor-code` (line 364) adds `protobuf-patterns` with marker-precondition note — present.
- Worked examples updated to include `protobuf-patterns` in three relevant scenarios: Python gRPC server (lines 274, 276), monorepo (lines 284, 286). `tester` row (line 333) intentionally does NOT add `protobuf-patterns` — consistent with BD-156 spec listing 6 agents and `tester` not among them.

No defects.

### 4. `detect.sh` `protobuf_marker_detected()`

**File:** `scripts/lib/detect.sh`

- Function definition lines 437–498. Header comment block (lines 395–436) is comprehensive and matches the BD-141 documentation style.
- Function structure mirrors `python_data_marker_detected()` (lines 341–393):
  - Single positional arg defaulting to `${1:-.}` (line 438).
  - Missing/non-existent target tolerated as `no` with no stderr (lines 439–442).
  - Single-line literal output `protobuf-marker: yes|no` for tight-contract caller comparison (per the BD-141 byte-comparison pattern).
- Marker (a) — `.proto` file scan (lines 446–454):
  - Excludes `node_modules`, `.git`, `build`, `.venv`, `venv`, `.tox` — broader than BD-141's tests-only exclusion, justifiably so for `.proto` files which can validly live in `tests/`.
  - Uses `find ... -prune ... -o -type f -name '*.proto' -print | head -n 1 | grep -q .` — short-circuits on first match.
- Marker (b) — manifest scan (lines 460–488):
  - Reuses BD-141's negated-character-class boundary construction (`(^|[^A-Za-z0-9_-])(${pkgs})($|[^A-Za-z0-9_.-])`) — exactly the right pattern to avoid the documented landmines.
  - Splits Python pkgs (`protobuf|grpc-tools|grpcio-tools|protoc`) and Swift pkgs (`swift-protobuf|SwiftProtobuf|grpc-swift-2|grpc-swift`) into separate scans because the Swift list must be case-sensitive (preserves `SwiftProtobuf` vs `swift-protobuf` distinction) while Python uses `grep -i`. Correct.
  - One small expansion vs BD-156 spec: the helper also adds `grpcio-tools` (Python) and `grpc-swift` (Swift, in addition to `grpc-swift-2`). Both are reasonable real-world packages in active use; spec lists are not exclusive lower bounds. Documented inline. Acceptable.
- Marker generic (lines 489–495): `buf.yaml` / `buf.gen.yaml` presence triggers detection — covers fresh-skeleton repos with no committed `.proto` yet. Sensible signal; documented.

No defects. The "protobuf-marker:" key contract is unambiguous — `init-project.sh` line 269 compares against the full literal `"protobuf-marker: yes"` exactly per BD-141 byte-comparison precedent.

### 5. `init-project.sh` `pack_skill_coverage_for proto)`

**File:** `scripts/init-project.sh`

- New `proto)` case (lines 266–274) placed alongside existing `swift)` and `python)` cases. Comment block (lines 257–265) explains the rationale clearly.
- Wires the helper via `protobuf_marker_detected "$target_dir"` (line 268) and compares against `"protobuf-marker: yes"` literal (line 269) — exact mirror of the python case (lines 250–251).
- Outputs `grpc-patterns,protobuf-patterns` when marker positive (line 270), `grpc-patterns` when negative (line 272). Always emits `grpc-patterns` because the language-marker for `proto` is itself a strong gRPC signal — consistent with the existing v10 contract for the proto language marker.

No defects.

### 6. `add-capability.sh`

**File:** `scripts/add-capability.sh`

- `protocol:grpc` row (line 144) preserves the existing `grpc-patterns` mapping. The decision NOT to add `protobuf-patterns` to this row is correct and well-defended in the comment block (lines 135–143): the `protobuf-patterns` skill is intersection-loaded by marker, not by capability declaration. Adding `.proto` files is what triggers the load; declaring `protocol:grpc` correctly does not bypass marker semantics.
- The comment also explains the inverse case: standalone-protobuf projects load `protobuf-patterns` via marker without ever declaring `protocol:grpc`. Architecture §3.7 intersection-cell loading model preserved.
- Shape consistent with the BD-141 precedent (line 114–118 explanation that `add-capability.sh` is coarser than `init-project.sh`'s auto-detect — the same logic applies here).

No defects.

### 7. `test-detect.sh`

**File:** `scripts/test-detect.sh`

- New `protobuf_marker_detected` test block (lines 315–409) covers 10 cases:
  1. Empty dir → `no` (line 318–320)
  2. Non-existent target → `no` tolerated, no stderr (lines 322–325)
  3. Marker (a) positive — `.proto` file in `proto/` tree (lines 327–336)
  4. Marker (a) excludes vendored — `.proto` in `node_modules/` (lines 338–344)
  5. Marker (b) Python — `pyproject.toml` lists `protobuf` (lines 346–356)
  6. Marker (b) Python — `requirements.txt` lists `grpcio-tools` (lines 358–365)
  7. Marker (b) Swift — `Package.swift` references `swift-protobuf` (lines 367–380)
  8. Substring rejection — `protobuf-c-bindings` alone → `no` (lines 382–390)
  9. Generic — `buf.yaml` present → `yes` (lines 392–400)
  10. Negative — manifests without protobuf tooling → `no` (lines 402–409)
- Coverage matches BD-156 spec (positive `.proto`, positive dep manifest, negative no-markers) and adds the substring-rejection regression test that the BD-141 negated-class pattern guarantees.
- Test count: ran `bash scripts/test-detect.sh` — `=== Results: 52 passed, 0 failed ===`. Matches the BD-156 IMPL-report-claimed 42→52 delta.

No defects.

### 8. Public contracts preserved

- `pack_skill_coverage_for()` signature unchanged: `pack_skill_coverage_for(lang, [target_dir])`. Output for the `swift` and `python` cases is unchanged; the `proto` case gained a richer output (`grpc-patterns,protobuf-patterns` when marker matches) but always still emits `grpc-patterns` so existing callers that only check for `grpc-patterns` substring presence continue to work.
- BD-141 byte-identical marker comparison preserved for python row (lines 250–251 in `init-project.sh`).
- Permission bits verified via `ls -la`:
  - `scripts/lib/detect.sh` — mode 644 (sourced, not executed) — correct, unchanged.
  - `scripts/init-project.sh` — mode 755 (executable) — correct.
  - `scripts/add-capability.sh` — mode 755 — correct.
  - `scripts/test-detect.sh` — mode 755 — correct.

No defects.

---

## POQ dispositions

### POQ-BD-156-A — Trinity geometry

**Disposition: ACCEPT (convention-following implementation correct).**

- The BD-156 spec File/Symbol line at `BACKLOG.md:1377` describes the new skill as a 3-copy trinity at `project-template/.claude/skills/protobuf-patterns/SKILL.md`, `.codex/skills/protobuf-patterns/SKILL.md`, `.gemini/skills/protobuf-patterns/SKILL.md` ("trinity copies, byte-identical per Check 9").
- Verification: every existing `*-patterns` and `*-architecture` skill in HEAD ships at the single canonical location `project-template/skills/<name>/SKILL.md`. Confirmed by directory listing — `project-template/skills/grpc-patterns/SKILL.md`, `project-template/skills/python-data-architecture/SKILL.md`, `project-template/skills/security-patterns/SKILL.md`, etc. The per-CLI `project-template/.claude/skills/`, `.codex/skills/`, `.gemini/skills/` trees do not exist in HEAD; `init-project.sh` is the distribution mechanism that fans out the canonical source to per-CLI trees in client projects at install time.
- Implementation correctly placed `protobuf-patterns/SKILL.md` at the canonical single location matching every sibling skill. The BD-156 spec's "trinity copies" wording was a spec-authoring error (it described a per-CLI fan-out that lives in client projects, not in pack source). The IMPL-report POQ-BD-156-A correctly identified this and chose convention-following.
- No fix needed. The pack convention is uniform; deviating to add three per-CLI source copies for one skill would create a maintenance hazard (drift risk between the 3 copies, plus duplication tax) and would not match Check 9 which validates trinity copies *in the project-template per-CLI trees that don't exist for skill source files at all*.
- Disposition therefore matches the v10.1 status quo and the architecture §3.7 intersection-cell pattern. No escalation.

### POQ-BD-156-B — PLAN-SKILL-DIMENSIONS.md gap

**Disposition: ACCEPT as expected for late-added BDs; recommend a follow-up plan-doc edit only if BD-150 sweep cleans it up.**

- BD-156 was added 2026-05-11 during the BD-142 model-validation checkpoint, after `PLAN-SKILL-DIMENSIONS.md` was written. The plan doc therefore has no BD-156 batch coverage by construction.
- The implementation correctly worked from the authoritative spec sources: BACKLOG.md BD-156 entry + `ARCHITECTURE-SKILL-DIMENSIONS.md` §3.7 (intersection-cell pattern) + §7.10 (naming convention).
- The sibling late-added BDs (BD-157, BD-158, BD-159) are also outside PLAN-SKILL-DIMENSIONS.md — this is a pattern, not a defect. Per CLAUDE.md "Pack memory" workflow rule, plan docs are not regenerated for late-added BDs unless the architect-pass routing trips.
- Recommended (non-blocking) follow-up: BD-150 (`CHANGELOG v11.0 entry + README skill-count refresh`) is the natural place to record that BDs 156/157/158/159 were added post-PLAN; that record alone is sufficient. No PLAN-SKILL-DIMENSIONS.md edit needed before v11.0 ships.

### POQ-BD-156-C — Check 31 deferral

**Disposition: ACCEPT — Check 31 is BD-146 scope; validate-pack 30/30 PASS holds without it.**

- BD-156 BACKLOG entry at `BACKLOG.md:1377` lists "MODIFIED `scripts/validate-pack.py` Check 31 (skill-cell consistency, added by BD-146) — must pass with new skill in intersection table" as part of the spec.
- BD-146 (`BACKLOG.md:1427`) ships Check 31. Per `BACKLOG.md:1364` and `:1386`, the dependency direction is BD-146 → BD-150 (CHANGELOG) for the version-row gating; BD-156 / BD-157 / BD-158 are *parallel* hard-blocker skills, not sequenced after BD-146.
- BD-146 has not yet shipped (Check 31 does not exist in `scripts/validate-pack.py`). Running `python3 scripts/validate-pack.py` returns "PASSED — all checks clean" with the highest existing check being Check 30 (Recommendation-state JSON schema, BD-079).
- Once Check 31 ships under BD-146, it will scan PLATFORM-SKILLS.md tables and the on-disk `project-template/skills/` directory; it will see `protobuf-patterns` listed in the intersection table (line 222 + line 455) and the SKILL.md present at `project-template/skills/protobuf-patterns/SKILL.md`. The "must pass with new skill in intersection table" requirement is therefore implicitly satisfied by BD-156's table updates — no BD-156-side code change for the not-yet-existent Check 31.
- Conclusion: Check 31 deferral to BD-146 is correct; current 30/30 PASS holds; BD-146 will inherit a clean intersection-table state when it lands.

---

## Sanity check against §3.1 mechanical-edit conditions

`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.1 enumerates 7 conditions; all must be true for a change to be mechanical.

1. **Trinity scope** — N/A in the per-CLI fan-out sense (skill source is single-canonical per pack convention; trinity rule applies to pack-repo CLAUDE.md/AGENTS.md/GEMINI.md and to *client project* per-CLI trees produced by init-project.sh). PLATFORM-SKILLS.md is a single file (no trinity copies). Edits uniformly applied. **PASS.**
2. **Existing dimension fit** — `protobuf-patterns` loads via the existing intersection-table mechanism (architecture §3.7) using an existing predicate shape (helper-function emits literal yes/no per BD-141). No new dimension, no new load mechanism. **PASS.**
3. **Existing pattern fit** — `standalone` pattern per architecture §2; no `core+layers` involved. **PASS.**
4. **Existing naming convention fit** — `*-patterns` suffix per §7.10. **PASS.**
5. **Existing validator coverage** — Check 9 (trinity-byte-identical, where applicable), Check 27 (per-agent skill list — already extended in BD-143 batch), Check 30 etc. — all pass. Check 31 deferral is by design (BD-146 scope). **PASS.**
6. **Bounded file footprint** — 1 new file (`protobuf-patterns/SKILL.md`), 6 modified files (`grpc-patterns/SKILL.md`, `PLATFORM-SKILLS.md`, `detect.sh`, `init-project.sh`, `add-capability.sh`, `test-detect.sh`). 0 new top-level docs, 0 new scripts (helper added to existing `lib/detect.sh`), 0 new validate-pack checks. Footprint sits within §3.1 bounds (0-3 new, 0-10 edited). **PASS.**
7. **No agent-permission expansion** — no change to "What agents must never modify", PM-only file list, trinity rule, agents-never-commit rule, or any "Pack memory" rule. **PASS.**

All 7 conditions hold. The §3.3 borderline case for "adding a new intersection-table row" applies and resolves mechanical: the predicate (`protobuf_marker_detected()`) composes existing dimension selectors (project-tree file presence + dependency-manifest scan) without introducing a new selector primitive. Architecture §3.3 explicitly cites BD-156 as a worked example of a mechanical intersection-cell addition.

---

## Files reviewed

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/protobuf-patterns/SKILL.md`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/grpc-patterns/SKILL.md`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PLATFORM-SKILLS.md`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/detect.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/add-capability.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/test-detect.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` (§3.7, §7.10)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` (§3.1, §3.3)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/BACKLOG.md` (BD-156 entry + cross-references)

## Smoke tests run

- `python3 scripts/validate-pack.py` → "PASSED — all checks clean" (30/30).
- `bash scripts/test-detect.sh` → `=== Results: 52 passed, 0 failed ===` (matches IMPL-report 42→52 delta).
