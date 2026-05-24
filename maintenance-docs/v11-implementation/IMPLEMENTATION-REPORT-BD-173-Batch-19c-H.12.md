# IMPLEMENTATION-REPORT — BD-173 Batch 19c H.12 (Guardrail 3 — `_PROJECT_SIDE_ROOTS` scope expansion)

**Status:** APPLIED (post-reorder; ratifies cleaned state).

**Outcome:** All 4 in-scope edits applied per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §3 (revised post-2026-05-24 reorder); `python3 scripts/validate-pack.py` PASSES at HEAD `ad0392f` with Check 37 walking 159 project-side files; `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` PASSES with new Group 7 added (all 8 groups PASS, 0 FAIL); manifest verified consistent (no v11-* fixture drift — `scripts/validate-pack.py` and test script are pack-build tools not client-installed).

This IMPL-REPORT **OVERWRITES** the pre-existing STOP-AND-ESCALATE artifact at the same path (originally written 2026-05-24 by the prior H.12 coder before the reorder corrected the architect spec). The STOP-AND-ESCALATE evidence is preserved at `IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md` (the consolidated reorder audit doc committed in `df00104`).

---

## §1 Scope

Guardrail 3 implementation per the **revised post-reorder spec** at `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §3:

1. **Add helper** `_iter_client_installed_files()` to `scripts/validate-pack.py` returning the union of (a) all files under `project-template/` (recursive) + (b) explicit non-project-template entries from `_CLIENT_INSTALLED_FILES` parsed via existing `_parse_client_installed_files()`. Function body **verbatim** from §3.1.
2. **Replace** `_PROJECT_SIDE_ROOTS = ("project-template",)` constant with the documentation comment block from §3.2.
3. **Update** `_iter_project_side_files()` body to a thin alias delegating to `_iter_client_installed_files()` per §3.2 caller-update plan. The Check 37 call-site (`check_project_side_deny_list`) is **unchanged** — delegation is transparent.
4. **Append** Group 7 fixture-test cases T1–T4 to `scripts/tests/test-validate-pack-checks-36-37-38.sh` per §3.4.

**Files modified (2):**
- `scripts/validate-pack.py`
- `scripts/tests/test-validate-pack-checks-36-37-38.sh`

**Files created (1):**
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` (this report; OVERWRITES the pre-existing STOP-AND-ESCALATE artifact).

**Scope keyword justified:** `pack-only` — no `project-template/` or `supporting-docs/` paths touched.

**Commit-order note:** this is the SECOND-executed commit in the 2026-05-24 reorder (H.13 already landed at `78a3b80` + fix `ad0392f`). The PLAN H.12 NAME is preserved; commit log will show "Batch 19c.12" landing AFTER "Batch 19c.13" — numerical inversion intentional per the reorder.

---

## §2 Edits applied

### 2.1 `scripts/validate-pack.py`

**Edit 2.1.a — Add `_iter_client_installed_files()` helper.**

Inserted at module-level immediately before `_iter_project_side_files()`. Body verbatim from architect §3.1 (the helper definition block), with a docstring cross-reference appended pointing back to §3.1 + §3.2 (per pack convention "architect-doc-vs-reality reconciliation" in CLAUDE.md).

```python
def _iter_client_installed_files() -> list[Path]:
    """Return the union of:
      (a) all regular files under project-template/ (recursive), and
      (b) the explicit non-project-template files in _CLIENT_INSTALLED_FILES.

    This replaces _PROJECT_SIDE_ROOTS-based walks for Checks 37 + 43.
    The source-of-truth for (b) is _CLIENT_INSTALLED_FILES_START/_END
    in scripts/init-project.sh, parsed via Check 41's
    _parse_client_installed_files() helper.

    Returns repo-relative Path objects, sorted, deduplicated. Skips
    binary files (deferred to caller via UnicodeDecodeError handling).

    Contract: see `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`
    §3.1 for the verbatim function body + §3.2 for the rationale
    (replaces `_PROJECT_SIDE_ROOTS` constant; reuses the authoritative
    `_CLIENT_INSTALLED_FILES_START`/`_END` inventory in
    `scripts/init-project.sh` per BD-180 G).
    """
    out: list[Path] = []
    # (a) project-template/ recursive walk (existing behavior).
    root = REPO_ROOT / "project-template"
    if root.is_dir():
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            out.append(path.relative_to(REPO_ROOT))
    # (b) explicit non-project-template entries from _CLIENT_INSTALLED_FILES.
    entries, _, _, _, _ = _parse_client_installed_files()
    for entry in entries:
        if entry.startswith("project-template/"):
            continue  # already covered by (a)
        full = REPO_ROOT / entry
        if full.is_file():
            rel = full.relative_to(REPO_ROOT)
            if rel not in out:  # dedup defensive (project-template/ first)
                out.append(rel)
    return out
```

**Edit 2.1.b — Replace `_PROJECT_SIDE_ROOTS` constant with documentation comment.**

Removed `_PROJECT_SIDE_ROOTS = ("project-template",)` (previously around L3769) and inserted the §3.2 documentation comment block verbatim:

```python
# `_PROJECT_SIDE_ROOTS` is REPLACED by `_iter_client_installed_files()`.
# See ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §3 for the contract.
# Reason: the previous constant restricted Check 37 to project-template/
# only, missing scripts/lib/detect.sh (installed verbatim per
# init-project.sh:894-895) and the other 4 client-installed files in
# pack-ops/ + supporting-docs/ + scripts/. The new helper parses the
# authoritative _CLIENT_INSTALLED_FILES inventory and walks the full
# client-installed surface.
```

`_PROJECT_SIDE_PATH_PREFIXES` (line ~3774) **UNCHANGED** per §3.2 explicit instruction (used by `_is_pack_only_path()` and `_is_project_side_path()` for Check 36 commit-scope classification — a different question than file-walk).

Verified by grep: no remaining `_PROJECT_SIDE_ROOTS` symbol references in code; only docstring/comment mentions remain (3 cross-reference mentions at L3768, L4077, L4087).

**Edit 2.1.c — Update `_iter_project_side_files()` to thin-alias delegation.**

Body replaced with a single-line delegation to the new helper. Docstring updated to mark the function DEPRECATED and reference the migration plan per §3.2:

```python
def _iter_project_side_files() -> list[Path]:
    """Thin alias delegating to `_iter_client_installed_files()`.

    DEPRECATED: kept as an alias so the Check 37 call-site
    (`check_project_side_deny_list`) does not need to change. Future
    cleanup may inline the delegation. See ARCHITECTURE-V11-GUARDRAILS-
    CONTRACT.md §3.2 for the migration plan.
    """
    return _iter_client_installed_files()
```

Call site preserved unchanged: `check_project_side_deny_list` at L4297 still calls `_iter_project_side_files()`. Delegation is transparent.

### 2.2 `scripts/tests/test-validate-pack-checks-36-37-38.sh`

**Edit 2.2.a — Append Group 7 (4 new test cases).**

Inserted between the existing Group 6 trailing `esac` (line ~568 pre-edit) and the `# Summary` section header. Test cases T1–T4 cover the architect §3.4 matrix:

| Test ID | Assertion | Source spec |
|---|---|---|
| G7.T1 | `_iter_client_installed_files()` includes `scripts/lib/detect.sh` (precondition for Check 37 detection on that surface — full end-to-end synthesis would require rewriting detect.sh which is out-of-scope and would break HEAD) | §3.4 T1 |
| G7.T2 | `_iter_client_installed_files()` includes `supporting-docs/METHODOLOGY.md` (pedagogical surface walked — anchor-phrase exemption still applies; end-to-end Check 37 PASS at HEAD validates the integration) | §3.4 T2 |
| G7.T3 | The 5 expected non-project-template extras are all returned: `pack-ops/HELP-FRAGMENT-TRACKER.md`, `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/pack-help.sh`, `scripts/lib/detect.sh`. Plus project-template trinity is also walked. | §3.4 T3 |
| G7.T4 | No duplicate Path entries in returned list (dedup is defensive — `project-template/` entries do not appear twice with `_CLIENT_INSTALLED_FILES` entries) | §3.4 T4 |

The Group 7 heredoc follows the same `python3 <<EOF` ... `EOF` pattern as Groups 2/5/6 (unquoted heredoc to permit `$REPO_ROOT`/`$VALIDATE` interpolation; backtick-wrapped tokens in Python comments removed to avoid spurious shell command-substitution attempts at heredoc parse time).

Line-delta: `+126 lines` (Group 7 block including header, heredoc, case block).

---

## §3 Verification

All verification commands executed at HEAD `ad0392f` (post-H.13-fix).

### 3.1 `python3 scripts/validate-pack.py`

**Result:** PASS.

```
── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──
  OK: Check 37 — 159 project-side file(s) walked; zero deny-list contamination (6 anchored LEGITIMATE-context hit(s) accepted; 585 fenced LEGITIMATE-content line(s) exempt per Guardrail 2)
...
============================================================
PASSED — all checks clean
```

- Check 37 file-walk count: **159** (pre-edit was project-template-only; post-edit includes 5 explicit non-project-template extras per §3.3 audit + project-template recursive).
- Fenced exemption count: **585 lines** (H.13's per-line fence covers the legitimate dual-surface refs; H.12 expansion now ratifies the cleaned state without producing FAILs — per §3.3 corrected ordering contract).
- All 42 checks (Check 0 through Check 42) PASS.

### 3.2 `bash scripts/tests/test-validate-pack-checks-36-37-38.sh`

**Result:** PASS — 8 groups, 0 FAIL.

```
=== Group 0: Module import + check-function registration ===
  PASS validate-pack.py imports + Check 36/37/38 functions registered
=== Group 1: Check 36 keyword detection + scope rules ===
  PASS ... [3 sub-tests pass]
=== Group 2: Check 37 deny-list + anchor-phrase unit tests ===
  PASS Check 37 anchor-phrase detection unit tests
=== Group 3: Check 38 exemption-list + signal-count unit tests ===
  PASS Check 38 exemption-list + threshold unit tests
=== Group 4: End-to-end validate-pack.py exit-status on HEAD ===
  PASS validate-pack.py exits 0 with all checks including 36/37/38 on HEAD
=== Group 5: Synthetic fixture sanity tests ===
  PASS Synthetic fixture Check 37 sanity tests
=== Group 6: Per-line fence (Guardrail 2) unit tests ===
  PASS Group 6 — Guardrail 2 per-line fence unit tests
=== Group 7: Check 37 scope expansion (Guardrail 3) unit tests ===
  PASS Group 7 — Guardrail 3 scope expansion unit tests

=== Summary ===
  PASS: 8
  FAIL: 0
```

Group 7 confirmation via grep (per prompt success criterion):

```
$ grep -A 2 "Group 7" scripts/tests/test-validate-pack-checks-36-37-38.sh | head -10
# Group 7: Check 37 scope expansion (Guardrail 3 — BD-173 H.12)
# ─────────────────────────────────────────────────────────────────
#
--
printf "\n=== Group 7: Check 37 scope expansion (Guardrail 3) unit tests ===\n"
python3 <<EOF
--
    0) t_pass "Group 7 — Guardrail 3 scope expansion unit tests" ;;
    *) t_fail "Group 7 — Guardrail 3 scope expansion unit tests failed" ;;
```

### 3.3 Manifest regeneration

Per BD-176 rule (any commit touching `scripts/` MUST regenerate `test-fixtures/manifest.txt`):

```
$ bash test-fixtures/build.sh --all --clean
... [all 6 fixtures rebuilt]
manifest written: test-fixtures/manifest.txt

$ git diff --stat test-fixtures/manifest.txt
(empty — no drift)

$ bash test-fixtures/build.sh --verify
  v10-minimal OK
  v10-realistic-ot OK
  v11-realistic-ot OK
  v11-flat-file OK
  v11-tracker-on OK
  existing-project-mid-dev OK
```

**No manifest drift observed.** Rationale: `scripts/validate-pack.py` and `scripts/tests/test-validate-pack-checks-36-37-38.sh` are pack-build tools, NOT client-installed content. The `_CLIENT_INSTALLED_FILES` inventory does not list them, and `init-project.sh` does not mass-copy them (line 1260 mass-copies `project-template/scripts/*`, not the pack-root `scripts/`). Per BD-176 rationale, the rule is intentionally inclusive of false-positives; the rebuild correctly produced no manifest change in this case.

### 3.4 Working tree state

```
$ git status --porcelain
 M scripts/tests/test-validate-pack-checks-36-37-38.sh
 M scripts/validate-pack.py
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md

$ git diff --stat scripts/validate-pack.py scripts/tests/test-validate-pack-checks-36-37-38.sh
 .../tests/test-validate-pack-checks-36-37-38.sh    | 126 +++++++++++++++++++++
 scripts/validate-pack.py                           |  74 ++++++++----
 2 files changed, 179 insertions(+), 21 deletions(-)
```

---

## §4 Cross-references

- **Architect contract (revised):** `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §3 — verbatim function body (§3.1), replacement comment block (§3.2), pre-sweep correction (§3.3, including the "Pre-sweep PASS verification (CORRECTED 2026-05-24 per STOP-AND-ESCALATE evidence)" paragraph), and T1–T4 test cases (§3.4).
- **Planner spec (revised):** `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` H.12 entry.
- **Reorder audit:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md` (committed in `df00104`; preserves STOP-AND-ESCALATE evidence, Pack Chat triage, user direction Option B+B2, corrected doc-revision chain).
- **H.13 IMPL-REPORT:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` (per-line fence landed at `78a3b80`; H.13 fix at `ad0392f`; provides the fence coverage that H.12 ratifies).
- **CLAUDE.md pack convention:** "Architect-doc-vs-reality reconciliation" — the new helper's docstring carries the §3.1/§3.2 cross-reference per pattern; the architect doc already names this consumer via the §3 cross-reference chain.

---

## §5 Success criteria checklist

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | `_iter_client_installed_files()` added per §3.1 | **PASS** | Edit 2.1.a; verified via `hasattr(mod, '_iter_client_installed_files')` returning True |
| 2 | `_PROJECT_SIDE_ROOTS` constant removed; documentation comment in its place per §3.2 | **PASS** | Edit 2.1.b; verified via `hasattr(mod, '_PROJECT_SIDE_ROOTS')` returning False; comment block at L3768-3775 |
| 3 | `_iter_project_side_files()` delegates per §3.2; call-site unchanged | **PASS** | Edit 2.1.c; call site at L4297 verified unchanged |
| 4 | Group 7 test cases T1-T4 added per §3.4 | **PASS** | Edit 2.2.a; `grep -A 2 "Group 7"` confirms; 4 test cases inside `python3 <<EOF` block |
| 5 | `python3 scripts/validate-pack.py` PASS at HEAD (expanded scope ratifies cleaned state) | **PASS** | §3.1; Check 37 reports 159 walked files + 0 contamination + 585 fenced lines |
| 6 | `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` PASS including new Group 7 | **PASS** | §3.2; 8 groups PASS, 0 FAIL |
| 7 | Manifest v11-* row drift | **PASS** (no-drift expected; BD-176 false-positive rebuild) | §3.3; manifest rebuilt + diff empty + verify OK |
| 8 | Commit is `pack-only` scope — ONLY `scripts/` files + manifest + IMPL-REPORT touched | **PASS** | §3.4; no `project-template/` or `supporting-docs/` paths touched |
| 9 | IMPL-REPORT at correct path, OVERWRITES pre-existing artifact | **PASS** | This file at the prompt-specified path; Read-before-Write performed per Write tool rule |

---

## §6 Out-of-scope confirmations

**No project-template/, supporting-docs/, or maintenance-docs/ source files touched.** Working-tree diff confirms only:
- `scripts/validate-pack.py` (modified — in scope per §3.1 + §3.2)
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` (modified — in scope per §3.4)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` (untracked — this IMPL-REPORT, overwrites pre-existing STOP-AND-ESCALATE artifact)

**`scripts/init-project.sh` NOT touched** (read-only per prompt — the new helper parses its `_CLIENT_INSTALLED_FILES_START`/`_END` markers via the existing `_parse_client_installed_files()`).

**`IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md` NOT touched** (historical record preserved per prompt).

**Pack-only scope keyword justified for Check 36:** the diff is exclusively under `scripts/` + `maintenance-docs/` (neither in `_PROJECT_SIDE_PATH_PREFIXES` = `("project-template/", "supporting-docs/")`); no project-side paths means `pack-only` claim is honest.

**Trinity rule N/A:** no CLAUDE.md / AGENTS.md / GEMINI.md files touched (pack-root or project-template).

---

## §7 Open questions / deferrals

**None.** The revised spec resolved cleanly:

- The original H.12 coder's STOP-AND-ESCALATE (26 leaks) is fully addressed by the H.13 fence expansion (4 dual-surface fence-files: METHODOLOGY.md, INSTALL-PROCEDURES.md, detect.sh, pack-help.sh) plus the pre-existing H.10 leak sweep — see §3.3 corrected ordering contract.
- The "self-validating change" principle holds at every commit in the reordered sequence: H.10 + H.11 + H.13 land first (cleaning + fencing), then H.12 lands AFTER (ratifying with expanded scope).
- No new POQs surfaced during implementation.
- No architect-spec issues observed — the §3.1 function body, §3.2 replacement text, and §3.4 test cases applied verbatim without ambiguity.

**Note on the test script's heredoc syntax:** during initial Group 7 execution, two stderr warnings emerged from bash interpreting backtick-wrapped tokens (`` `maintenance-docs/` `` and `` `Pack Chat` ``) inside Python comments as command-substitution attempts (the heredoc delimiter is unquoted `EOF` to permit `$REPO_ROOT`/`$VALIDATE` interpolation, matching Groups 2/5/6). Resolved by removing the backticks from those two specific comment lines; tests still pass and Python parses identically. Pattern-consistent with Groups 2/5/6 (which avoid backtick-wrapped tokens in their comments for the same reason).

---

## §8 Files changed inventory

| Path | Type | Change |
|---|---|---|
| `scripts/validate-pack.py` | source | modified (+74 / -21 lines net per `git diff --stat`; 3 logical edits per §2.1) |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | test | modified (+126 lines; Group 7 block appended) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` | report | new file (OVERWRITES pre-existing STOP-AND-ESCALATE artifact at same path; previous content preserved in the consolidated reorder audit doc at `IMPLEMENTATION-REPORT-BD-173-Batch-19c-REORDER-H.12-H.13.md`) |

**Total: 2 in-scope source edits + 1 IMPL-REPORT (overwrite).** No manifest drift; manifest rebuilt and verified consistent.
