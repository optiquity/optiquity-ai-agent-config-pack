# PACK-REVIEW-BD-144 — Skill-dimensions Batch 5: add-capability.sh D5 rename + migrator translation

**One-line summary.** Implementation matches architect/planner specs and BD-159 maintainability principle; both smoke tests pass (42/42 detect, 12/12 translation); one APPROVE-WITH-NITS finding: the new test runner `scripts/test-migrator-capability-translation.sh` is not wired into `.github/workflows/validate-pack.yml`, so the golden-snapshot regression guard will not run in CI.

**Verdict.** APPROVE WITH NITS.

---

## 1. Scope verified

Files inspected (read-only):

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/add-capability.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/detect.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/test-detect.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/test-migrator-capability-translation.sh` (NEW)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.github/workflows/validate-pack.yml`

Specs read:

- `ARCHITECTURE-SKILL-DIMENSIONS.md` §3.5 (D5 deployment), §3.7 (intersection table), §6.2 (add-capability D5 rename), §7.1 (forward-declared rows)
- `PLAN-SKILL-DIMENSIONS.md` §2 Batch 5 (BD-144), §7.1 (BD-144 expanded scope per resolution 3)
- `ARCHITECTURE-BD-119.md` §3.2 (adapter contract), §4 (per-version adapter shape)
- `CLAUDE.md` Pack memory § "Repo conventions" (BD-159 maintainability)

Not read (per reviewer-bias rule): no prior `PACK-REVIEW-*.md` files; BD-143 / BD-145 in-flight files left untouched.

---

## 2. Per-concern findings

### 2.1 D5 rename: `role:apple-app` → `deployment:apple` and `role:python-server` intersection fix

**APPROVE.** Matches architecture §3.5 / §3.7 and PLAN §7.1.

- `scripts/add-capability.sh:147-148` adds the new D5 rows
  (`deployment:apple` → `deployment-apple`,
  `deployment:linux-container` → `deployment-python`).
- `scripts/add-capability.sh:154` updates `role:python-server` to
  resolve to `python-server-architecture python-data-architecture` —
  exactly the §3.7 intersection (D2=python ∩ D3=server). The
  pre-Batch-5 `deployment-python` is correctly dropped from this row
  and migrated to the new `deployment:linux-container` D5 row.
- The legacy `role:apple-app)` case is **removed** from
  `capability_skills()` (verified absent via grep). No backwards-
  compatibility shim — clean rename. Per planner resolution 3
  ("replace immediately, with full migrator translation coverage")
  this is the intended behavior: clients are migrated forward via
  the S5c stage rather than carrying a dual-token shim.

### 2.2 Forward-declared platform rows + `warn_if_missing_skills` helper

**APPROVE.** Matches PLAN §2 step 1 + planner resolution 2
(forward-declared with directory-exists guard + warning).

- `scripts/add-capability.sh:132-134` declare the three forward rows:
  `platform:android` → `android-architecture`,
  `platform:web-browser` → `web-architecture`,
  `platform:embedded-mcu` → `embedded-mcu-architecture`. None of
  these SKILL.md targets ship in v11.0 yet (they ship in Phase 3 per
  PLAN §6.6).
- `scripts/add-capability.sh:170-179` defines `warn_if_missing_skills()`
  — checks `$PACK/project-template/skills/<skill>/SKILL.md`
  existence; emits stderr warning via `warn` for each absent SKILL.md
  but always returns 0 (advisory only — operation proceeds). This is
  the planner-resolved semantics.
- `scripts/add-capability.sh:282-284` invokes the helper from
  `stage_a1_resolve` after dedup, against the full resolved skill
  set. Good placement: warns once per resolved skill regardless of
  how many `--add` flags pulled it in.
- Comment block at `add-capability.sh:126-131` correctly documents
  the forward-declaration intent and the Phase 3 follow-up.

### 2.3 Reciprocal mapping in `detect.sh::detect_installed_capabilities()`

**APPROVE.** Matches PLAN §2 step 3 + planner resolution 3 ("flip
both atomically"); no backwards-compat retention of the old `role:`
mappings.

- `scripts/lib/detect.sh:296-297` flips
  `deployment-apple` → `deployment:apple` and
  `deployment-python` → `deployment:linux-container` (replacing the
  pre-Batch-5 `role:apple-app` and `role:python-server` mappings —
  which were misclassified per architecture §3.5).
- Symmetric with `add-capability.sh::capability_skills()`: a project
  whose `**Active skills:**` line was written by `add-capability.sh
  --add deployment:apple` will round-trip through
  `detect_installed_capabilities` and re-emit `deployment:apple`.
- The case statement does NOT retain the legacy `role:` mappings.
  This is the planner-resolved "replace immediately" path, justified
  by the migrator translation stage shipping in the same batch
  (§2.5 below).
- Comment at `detect.sh:289-295` documents the flip and references
  the architecture sections.

### 2.4 `--help` text reflects D5 dimension and new tokens

**APPROVE.** Verified via `PACK=. bash scripts/add-capability.sh
--help`:

- `add-capability.sh:38-42`: "Recognized dimensions: platform,
  language, protocol, role, deployment." Examples include
  `role:python-server, deployment:apple, deployment:linux-container`.
- No `role:apple-app` reference in user-facing help. The remaining
  `role:apple-app` strings in `add-capability.sh` are a comment
  block (line 142–145) documenting the rename rationale — acceptable.

### 2.5 Migrator translation stage (S5c) — wired via BD-119 framework

**APPROVE.** Compliant with the BD-119 adapter contract; uses the
post-dispatch hook (the documented escape valve for monolith-
faithful behavior); idempotent.

- Adapter file `scripts/migrate-v10-to-v11.sh` continues to source
  `migrator-core.sh` (line 711) and declares the full MIGRATOR_*
  contract (lines 73–80). The new translation work does NOT
  introduce a separate framework bypass.
- `migrator_post_dispatch_hook` (line 134) appends the new helper
  call `_v10_to_v11_translate_capability_tokens` (line 148) — this
  is the documented escape hatch per ARCHITECTURE-BD-119 §3.2 ("use
  sparingly"); placement alongside `_v10_to_v11_relocate_legacy_docs`
  and `_v10_to_v11_install_v11_artifacts` is precedented and matches
  the existing adapter style per the comment at lines 22-42 (the
  hook is intentionally used to preserve byte-equivalent stdout +
  report.md from the pre-BD-119 monolith).
- Dry-run gate at line 140-143 short-circuits the hook in
  `_migrator_is_dryrun` mode, matching the BD-095 dry-run contract
  (info-line emitted; no writes).
- Helper `_v10_to_v11_translate_capability_tokens` (lines 532-685):
  - Token-boundary anchored regexes (lines 548-550) — matches the
    helper-internal pattern used in `python_data_marker_detected`.
    Substring matches like `role:apple-app-foo` cannot be touched.
  - Idempotent: rename is one-shot (line 581-583); append guarded
    by negative match against `lxc_pat` (lines 619-620).
  - Advisory file at `$_MIGRATOR_STATE_DIR/capability-rename.advisory`
    (line 535) created lazily on first touch; format mirrors the
    BD-035 S5b advisory shape (header + file:line:kind + before/
    after/rationale).
  - Atomic per-file write via mktemp + mv (lines 564, 670-674);
    failed mv calls `fail_stage S5` for framework-consistent exit.

**Migrator-framework compliance check.** PASSED. The adapter:
- Sources `migrator-core.sh` (no copy-and-rewrite).
- Declares MIGRATOR_FROM/TO_VERSION, MIGRATOR_BASELINE_TAG,
  MIGRATOR_OWN_SIDECAR_SUFFIX, MIGRATOR_PRIOR_SIDECAR_SUFFIXES.
- Implements `migrator_manifest`, `migrator_directory_sweeps`,
  `migrator_relocations` (no-op), `migrator_artifact_installs`
  (no-op), `migrator_post_dispatch_hook` (extended with S5c),
  `migrator_post_report_hook`.
- Inherits framework helpers (`say`, `info`, `fail_stage`,
  `_MIGRATOR_TARGET`, `_MIGRATOR_STATE_DIR`, `_migrator_is_dryrun`).
No framework bypass; no duplicate orchestration.

### 2.6 Test coverage

**APPROVE.** Both smoke runs green.

- `bash scripts/test-detect.sh` — 42 passed, 0 failed
  (was 40 pre-BD-144; +2 new BD-144 fixtures at lines 291-313:
  `caps-deployment-apple` and `caps-deployment-linux-container`).
  The existing fixture at line 282 (`caps-with-backticks`) is
  correctly updated to assert the new D5 mapping
  (`deployment:linux-container, language:python` rather than the
  pre-Batch-5 `language:python, role:python-server`).
- `bash scripts/test-migrator-capability-translation.sh` — 12 passed,
  0 failed. Twelve assertions cover:
  - T1.a × 3: each trinity capabilities line contains all four
    expected tokens (order-tolerant).
  - T1.b × 3: no surviving `role:apple-app` token (boundary-anchored).
  - T1.c × 2: advisory file exists; records exactly 6 line-touches
    (3 files × 2 edits).
  - T2.a × 1: re-run produces no new advisory.
  - T2.b × 3: trinity files byte-identical after re-run (idempotency).
- The test isolates the unit-under-test from the BD-095 mode dispatch
  via an awk-based helper extraction (line 119-123). This is a
  clever workaround that keeps the test focused on S5c behavior
  without provisioning a full v10-realistic-ot fixture; the sanity-
  check at line 126-130 guards against extraction silently failing
  when the helper signature changes.

### 2.7 Public contract preservation

**APPROVE.**

- Exec bits preserved on every modified `.sh`:
  `add-capability.sh` -rwxr-xr-x; `migrate-v10-to-v11.sh`
  -rwxr-xr-x; `test-detect.sh` -rwxr-xr-x; new
  `test-migrator-capability-translation.sh` -rwxr-xr-x.
  `lib/detect.sh` is `-rw-r--r--` which matches its sourced-only
  status (existing convention; not touched by this batch in a way
  that should change perms).
- v10 `deployment-apple` / `deployment-python` skills still
  detectable post-migration (verified by the test-detect.sh
  reciprocal-mapping fixtures at lines 294-313 and by the migrator
  translation test which asserts post-translation lines still parse
  correctly through the new D5 vocabulary).
- `bash -n` syntax check passed on all five files.
- `python3 scripts/validate-pack.py` — all 30 Checks PASSED.

### 2.8 Maintainability principle (BD-159 §3.1)

**APPROVE.** Within mechanical-edit bounds.

- File-count: 4 modified production scripts + 1 new test runner =
  5 ≤ 10.
- The new `test-migrator-capability-translation.sh` is "test
  infrastructure for new behavior" — explicitly acceptable per the
  BD-159 §3.1 mechanical-edit conditions and not a new architect/
  planner doc.
- No SKILL.md or AGENT.md content edits; no trinity
  CLAUDE/AGENTS/GEMINI changes.
- Comments thoroughly document the rationale (architecture
  cross-references at `add-capability.sh:126-131`, `:141-153`;
  `detect.sh:289-295`; `migrate-v10-to-v11.sh:498-531`).

---

## 3. Cross-reference / leftover-token check

`grep -nR "role:apple-app" scripts/ project-template/`:

- All hits in `scripts/migrate-v10-to-v11.sh`, `scripts/add-capability.sh`,
  `scripts/test-detect.sh`, `scripts/test-migrator-capability-translation.sh`,
  `scripts/lib/detect.sh` are **migrator helper code**, **test
  fixtures**, or **explanatory comments documenting the rename**.
- Zero hits under `project-template/` and `supporting-docs/` —
  user-facing pack product is clean.

This satisfies PLAN §7.1 step 8 verification ("`grep -nR
"role:apple-app" scripts/ project-template/` returns zero hits in
pack-product files").

---

## 4. POQs / blocking concerns

None blocking.

---

## 5. NIT (non-blocking)

**N1 — CI workflow not updated to run the new test.**
`.github/workflows/validate-pack.yml` already wires
`scripts/test-detect.sh` (line 55), `scripts/test-migrator-core.sh`
(line 103), `scripts/test-migrator-manifest.sh` (line 106), and
the various `scripts/tests/*.sh` runners. The newly-added
`scripts/test-migrator-capability-translation.sh` is not added.
Result: the BD-144 idempotency / golden-snapshot regression guard
runs locally but never in CI, so a future regression in the S5c
helper would slip past PR-level validation.

**Recommended fix.** Add one step to the `tests:` job in
`.github/workflows/validate-pack.yml` (parallel to lines 101-106):

```yaml
      - name: migrator capability-translation tests (BD-144)
        if: always()
        run: bash scripts/test-migrator-capability-translation.sh
```

This is a single-file, single-step addition. Per pack memory ("One
review/fix cycle per batch"), the parent should land this in the
current session's fix sweep rather than spawning a new BD.

---

## 6. Sanity check against BD-159 §3.1 mechanical-edit conditions

- Total file count modified: 5 (4 prod + 1 test). Within bounds.
- All edits are within existing dimensional architecture (no new
  dimension, no new pattern); the additions extend already-shipped
  capability-table and reciprocal-mapping mechanisms.
- The new test runner conforms to existing dimensions
  (`test-detect.sh` is the established sibling shape; the new
  runner uses the same fail/pass/assert_eq shell idiom and the
  same `mktemp -d -t ... XXXXXX` fixture pattern).
- No `x-` skill/agent contracts touched.
- Workflow artifact discipline respected: this is a coder
  deliverable (production code + test), not a new
  ARCHITECTURE-/PLAN-/IMPLEMENTATION-REPORT-style top-level doc.

PASS.

---

## 7. Summary table

| Concern | Verdict |
|---|---|
| 2.1 D5 rename + intersection fix | APPROVE |
| 2.2 Forward-declared platform rows + warn_if_missing_skills | APPROVE |
| 2.3 Reciprocal mapping in detect.sh | APPROVE |
| 2.4 --help text reflects D5 | APPROVE |
| 2.5 Migrator S5c stage via BD-119 framework | APPROVE |
| 2.6 Test coverage (42 detect + 12 translation) | APPROVE |
| 2.7 Public-contract preservation | APPROVE |
| 2.8 BD-159 maintainability | APPROVE |
| BD-119 framework compliance | PASS (no copy-and-rewrite) |
| Cross-reference cleanup | PASS |
| CI wiring | NIT N1 — wire new test into validate-pack.yml |

**Verdict.** APPROVE WITH NITS.
