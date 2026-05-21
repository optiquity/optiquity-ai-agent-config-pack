# IMPLEMENTATION-REPORT-BD-183 — Extend Check 16 + Check 19 to cover pack-root trinity (parity guard, mirroring BD-181) + BD-181 NIT-1 fold-in

**BD:** BD-183 — Extend `scripts/validate-pack.py` Check 16 + Check 19 to cover pack-root trinity (parity guard, mirroring BD-181) + BD-181 NIT-1 fold-in
**Coder:** pack-coder (background spawn)
**Date:** 2026-05-21
**HEAD pre-implementation:** `a7ab1422c173ee9c3da96c998cfa5554867ee21a`
**Branch:** `v11-dev`
**Batch:** BD-175 emergency batch chain (BD-182 closed → **BD-183** → end-of-batch reviewer → Phase 6/7 close → Batch 19c resume)
**Trinity rule:** N/A (pack-internal `scripts/` work; not a trinity-content edit)
**Pack-architect spawn:** Not invoked (mechanical extension of proven BD-181 pattern per BD-183 entry; "Implementation pattern: mechanical pack-coder work (no architect spawn needed — generalizing existing checks is mechanical extension of the proven BD-181 pattern)")

---

## §1 Problem restatement

Per `pack-ops/BACKLOG.md` BD-183 entry L1680-L1709, `PACK-REVIEW-BD-181.md` §6 Observation A, and `PACK-REVIEW-BD-181.md` §4 NIT-1:

**Observation A (BD-181 review).** `scripts/validate-pack.py::check_trinity_addenda_h2` (Check 16, ~L1643) and `check_trinity_no_scaffolding_comments` (Check 19, ~L1268) both still hardcode `REPO_ROOT / "project-template" / name`. By the same parity-gap argument BD-181 applied to Check 18, the pack-root trinity has NO Check 16 or Check 19 guard today. Drift between pack-root trinity files for these check classes is undetected by CI until manual reviewer audit catches it.

**NIT-1 (BD-181 review).** The body of `check_trinity_h2_parity` uses the sentinel-`None` + lazy-resolve pattern for backward compatibility, but the sentinel-pattern intent (why `None` rather than a literal `REPO_ROOT/"project-template"` default) is not surfaced anywhere in the source. A maintainer might be tempted to "simplify" the default to a literal and break the design intent that call sites declare scope explicitly. NIT-1 recommends a 1-3 line in-source contract comment.

**Override 9 constraint (CRITICAL).** Both NEW Check 16 + Check 19 invocations MUST be INDEPENDENT — each checks WITHIN its own trinity location only. There is NO cross-location parity gate: pack-root and project-template trinity carry different audiences and different rules by design (per pack-root trinity § Rules → Trinity rule note paragraph at `CLAUDE.md` L104-L119).

**Goals.**

1. Generalize `check_trinity_addenda_h2()` (Check 16) with a base-path parameter; mirror BD-181 sentinel-None default + label threading pattern.
2. Generalize `check_trinity_no_scaffolding_comments()` (Check 19) similarly.
3. Add second invocations for pack-root trinity in `main()` for both checks IF the empirical pre-check is clean.
4. Both invocations enforce within-trinity parity independently (Override 9).
5. Fold in BD-181 NIT-1: add a 1-3 line sentinel-None call-site contract comment at `check_trinity_h2_parity`.
6. Add test fixtures for new pack-root coverage (PASS + FAIL synthetic cases for both checks; Override 9 isolation tests).

---

## §2 Empirical pre-implementation drift check (CRITICAL)

Per the prompt's `Empirical pre-implementation drift check` directive (mirroring the BD-181 pattern), BEFORE landing the second invocations in `main()`, I invoked the new generalized `check_trinity_addenda_h2(REPO_ROOT, "pack-root")` and `check_trinity_no_scaffolding_comments(REPO_ROOT, "pack-root")` against the live pack-root trinity at HEAD `a7ab142`.

### §2.1 Check 19 [pack-root] — CLEAN (PASSES)

```
── Check 19 [pack-root]: Trinity templates free of body scaffolding (BD-059, BD-183) ──
  OK: [pack-root] All three trinity templates free of body-section scaffolding comments
```

**Failures: 0.** Empirical confirmation: pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at repo root) contains ZERO HTML comments of any kind at HEAD. Therefore zero unallowed scaffolding comments. The pack-root invocation is SAFE to land.

### §2.2 Check 16 [pack-root] — DRIFT (FAILS 3×)

```
── Check 16 [pack-root]: Trinity ## Project addenda H2 (BD-059, BD-183) ──
FAIL: pack-root/CLAUDE.md — missing '## Project addenda' H2
FAIL: pack-root/AGENTS.md — missing '## Project addenda' H2
FAIL: pack-root/GEMINI.md — missing '## Project addenda' H2
```

**Failures: 3.** Pack-root trinity has NO `## Project addenda` H2 anywhere — and crucially, this is **BY DESIGN**, not drift.

### §2.3 Source-of-truth investigation and classification of the Check 16 finding

**Semantic analysis (per P-missed-7 boundary discipline investigation).** Check 16's purpose, per its docstring at `scripts/validate-pack.py::check_trinity_addenda_h2`:

> "v10 trinity templates carry `## Project addenda` H2 with the HTML-comment placeholder (OQ-P6 / OQ-5C-1, BD-059 C9). The H2 is the landing point for project-original sections during Procedure 5-C.2 reconciliation. Locking it via this check prevents accidental future removal."

The `## Project addenda` H2 + HTML-comment placeholder marker is **template-only** infrastructure. It exists ONLY for trinity files that get reconciled via Procedure 5-C.2 at client install / migration time. Its sole purpose is to provide a deterministic landing point for project-original sections being merged INTO the template.

**Pack-root trinity vs project-template trinity (architectural distinction).**

| Surface | Role | Lifecycle |
|---|---|---|
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` | TEMPLATE — copied to client `./` at `init-project.sh` stage S1 | Reconciled via Procedure 5-C.2 on upgrade migrations |
| Pack-root `{CLAUDE,AGENTS,GEMINI}.md` (repo root) | OPS DOC — canonical agent rules for pack-repo agents only | NEVER copied to clients; NEVER reconciled |

Pack-root trinity is the canonical operating document for agents working ON the pack repo itself. Per `scripts/init-project.sh` inspection (Stage S1 copies `project-template/` content, not repo-root files), pack-root trinity is NOT in the client install path. There is NO Procedure 5-C.2 reconciliation for pack-root trinity — there is no client-side surface for it to be reconciled against.

**Therefore Check 16's "drift" finding at pack-root is a SEMANTIC MISMATCH**: a template-only check is being applied to an ops-doc surface where the template-only concept (the `## Project addenda` H2) has no purpose. The H2 is correctly absent at pack-root. Calling this "drift" would conflate "missing required template scaffolding" with "ops-doc that legitimately has no template scaffolding."

This contrasts with the BD-181 precondition finding (pack-root H2 structure drift WITHIN trinity files). That was real drift — pack-root CLAUDE/AGENTS/GEMINI disagreed on H2 names within the same surface, violating the trinity rule's "symmetry is the default" mandate. The BD-181 precondition correctly aligned them.

The BD-183 Check 16 finding is different: pack-root trinity is internally consistent (all 3 files share "no `## Project addenda` H2"), but a template-only check would fail them all uniformly. Aligning would require ADDING template scaffolding to ops docs that have no reconciliation purpose — nonsensical.

### §2.4 BLOCKING surface for Check 16 pack-root invocation — CLOSED via Option (b) (user-approved 2026-05-21)

**Status:** RESOLVED. Pack Chat triaged the §2.3 semantic mismatch with the user; user selected **Option (b): add per-surface exemption mechanism**. Implementation landed in the same commit as the rest of BD-183 — see §3.7 for the exemption-mechanism design.

**Historical record (preserved for audit trail).** The original BLOCKING surface presented four options to Pack Chat:

- **(a) Confirm by-design omission as the permanent disposition.** Document that Check 16 is template-only by intent; close BD-183 with the asymmetric land state (Check 19 [pack-root] landed; Check 16 [pack-root] omitted by design).
- **(b) Add a per-surface exemption mechanism** (analogous to `GEMINI_INTRINSIC_H2S` per-CLI carve-out for Check 18) to formalize the template-only scope. A `_CHECK_16_EXEMPT_SURFACES = {"pack-root"}` set, with a real call site `check_trinity_addenda_h2(REPO_ROOT, "pack-root")` that runs but short-circuits with an `OK (exempt)` message. Makes the "pack-root is template-only-exempt" decision explicit in code rather than implicit in the omitted call site.
- **(c) Rename Check 16 conceptually** to "Trinity template-reconciliation landing point H2" — architect-pass scope.
- **(d) Add the `## Project addenda` H2 to pack-root trinity** — nonsensical given no reconciliation.

**User decision (2026-05-21):** Option (b). Rationale: makes the exemption self-discoverable at the function source, matches the existing `GEMINI_INTRINSIC_H2S` carve-out pattern from Check 18, and converts an implicit "comment in `main()`" design into an explicit mechanism that future maintainers can extend if additional surfaces ever need exemption.

### §2.5 Check 16 [pack-root] disposition (post-Option (b))

**Landed via exemption mechanism.** `check_trinity_addenda_h2(REPO_ROOT, "pack-root")` is called in `main()`. The function prints its section header and immediately short-circuits via the per-surface exemption check (`label in _CHECK_16_EXEMPT_SURFACES`), emitting an `OK (surface exempt)` message that cites BD-183 §2.4. No file reads occur (the short-circuit is BEFORE the per-file loop).

Empirically verified (post-Option (b)):

```
── Check 16 [pack-root]: Trinity ## Project addenda H2 (BD-059, BD-183) ──
  OK: [pack-root] surface exempt — Check 16 is template-only (`## Project addenda` mechanism has no purpose at non-reconciled surface per BD-183 §2.4)
```

### §2.6 Check 19 [pack-root] disposition

**Landed (unchanged from pre-Option (b)).** Empirical pre-check PASSES cleanly. The pack-root invocation is added to `main()` between `check_trinity_h2_parity(REPO_ROOT, "pack-root")` and any subsequent check. Closes the Check 19 parity-gap for pack-root trinity going forward — any future drift (e.g., a maintainer accidentally pastes scaffolding into a pack-root trinity file) will be flagged at validate-pack time. No exemption applies; the full check body runs.

---

## §3 Implementation

### §3.1 Check 16 generalization (`check_trinity_addenda_h2`)

**File:** `scripts/validate-pack.py::check_trinity_addenda_h2`

**Signature change.** Added two optional parameters with backward-compatible defaults, mirroring the BD-181 pattern exactly:

```python
def check_trinity_addenda_h2(
    trinity_root: Path = None,
    label: str = "project-template",
) -> None:
```

- `trinity_root`: directory containing the 3 trinity files. Default `None` resolves to `REPO_ROOT / "project-template"` at body entry (preserves the original no-arg behavior).
- `label`: human-readable surface name (used in FAIL / OK messages + file-path prefixes). Defaults to `"project-template"`.

**Body changes.**
- Replaced hardcoded `REPO_ROOT / "project-template" / name` with `trinity_root / name`.
- Threaded `label` into all FAIL/OK messages. Header line uses `Check 16 [{label}]: ...`.
- FAIL messages use `{label}/{name}` prefix (e.g., `pack-root/CLAUDE.md — missing '## Project addenda' H2`).
- OK messages use `[{label}] {name} — '## Project addenda' H2 with placeholder` form.
- **Added per-surface exemption short-circuit (BD-183 §2.4 Option (b)):** after printing the header and before the per-file loop, the function tests `if label in _CHECK_16_EXEMPT_SURFACES:` and short-circuits with an `OK (surface exempt)` message. Detailed design + rationale in §3.5 + §3.7.

**Sentinel-None comment** (mirrors NIT-1 fix applied at §3.3 for `check_trinity_h2_parity`):

```python
# Sentinel pattern: callers in main() pass explicit (trinity_root, label).
# `None` default kept for backward-compat with no-arg callers (test suite
# / external use). Do not collapse to a literal default — call sites
# declare their scope explicitly per BD-183 generalization design.
if trinity_root is None:
    trinity_root = REPO_ROOT / "project-template"
```

**Docstring expansion.** Added the BD-181-style parameter docs PLUS a critical "Semantic scope (BD-183 §2.4 Option (b))" paragraph that documents (a) the template-only scope of the check, (b) the rationale for the per-surface exemption mechanism, (c) the relationship between the `label` parameter and the `_CHECK_16_EXEMPT_SURFACES` module-level constant, and (d) cross-references to this IMPL-REPORT §2.4 + §3.7 for the design record. Future maintainers reading the docstring will understand both the original intent (template-only) and the Option (b) implementation (label-based exemption short-circuit).

### §3.2 Check 19 generalization (`check_trinity_no_scaffolding_comments`)

**File:** `scripts/validate-pack.py::check_trinity_no_scaffolding_comments`

**Signature change.** Identical to Check 16 — same `(trinity_root: Path = None, label: str = "project-template")` shape, sentinel-None default, same comment.

**Body changes.**
- Replaced hardcoded `REPO_ROOT / "project-template" / name` with `trinity_root / name`.
- Threaded `label` into all FAIL/OK messages. Header uses `Check 19 [{label}]: ...`.
- FAIL messages: `{label}/{name}:{line_no} — fresh-install scaffolding comment in body: ...`.
- OK message: `[{label}] All three trinity templates free of body-section scaffolding comments`.

**Docstring expansion.** Added BD-181-style parameter docs + Override 9 compliance note. No semantic-mismatch warning needed (unlike Check 16) — Check 19 applies cleanly at pack-root.

### §3.3 BD-181 NIT-1 fold-in (`check_trinity_h2_parity`)

**File:** `scripts/validate-pack.py::check_trinity_h2_parity`

**Change.** Added a 6-line sentinel-None contract comment immediately above the `if trinity_root is None:` line, per the PACK-REVIEW-BD-181 §4 NIT-1 recommendation:

```python
# Sentinel pattern (BD-181 / BD-183 NIT-1): callers in main() pass
# explicit (trinity_root, label). `None` default kept for backward-compat
# with no-arg callers (test suite Group 4 / external use). Do not collapse
# to a literal default like `trinity_root: Path = REPO_ROOT / "project-template"`
# — that would WORK for current callers but break the design intent that
# call sites declare scope explicitly per BD-181 generalization.
if trinity_root is None:
    trinity_root = REPO_ROOT / "project-template"
```

**Rationale.** The docstring already documents parameter semantics, but the sentinel-pattern intent (why `None` rather than a literal default) was not surfaced anywhere in the source. The comment closes that small documentation gap without adding source surface. PACK-REVIEW-BD-181 §4 NIT-1 estimated the fix at 4 lines; this implementation is 6 lines (including the cross-reference to the BD-181 / BD-183 NIT-1 lineage and a worked anti-example).

### §3.4 Pack-root invocation sites in `main()` (post-Option (b))

**File:** `scripts/validate-pack.py::main` (around the trinity-check cluster).

**Change.** Replaced the single `check_trinity_addenda_h2()` and `check_trinity_no_scaffolding_comments()` calls with explicit-arg forms; both checks now run at BOTH trinity locations:

```python
# ── BD-183: Check 16 generalized with (trinity_root, label). Both
# invocations run; pack-root short-circuits via the per-surface
# exemption mechanism (`_CHECK_16_EXEMPT_SURFACES`) because Check 16
# enforces template-only `## Project addenda` H2 infrastructure tied
# to Procedure 5-C.2 client reconciliation, which has no purpose at
# the non-reconciled pack-root surface. Exemption was BD-183 §2.4
# Option (b), user-approved 2026-05-21. Per Override 9, both
# invocations are independent.
check_trinity_addenda_h2(REPO_ROOT / "project-template", "project-template")
check_trinity_addenda_h2(REPO_ROOT, "pack-root")
# ── BD-181: Check 18 H2 parity runs INDEPENDENTLY at each trinity
# location. Per Override 9 compliance: pack-root and project-template
# trinity carry different audiences and different rules by design
# (per pack-root trinity § Rules → Trinity rule note paragraph).
# Each invocation enforces byte parity WITHIN its own trinity
# location only; there is NO cross-location parity gate.
check_trinity_h2_parity(REPO_ROOT / "project-template", "project-template")
check_trinity_h2_parity(REPO_ROOT, "pack-root")
# ── BD-183: Check 19 generalized with (trinity_root, label). Empirical
# pre-check at HEAD confirms pack-root trinity PASSES Check 19 (zero
# HTML comments at pack-root → zero scaffolding to find). Both
# invocations run independently per Override 9 — within-trinity
# parity at each location; no cross-location coupling.
check_trinity_no_scaffolding_comments(REPO_ROOT / "project-template", "project-template")
check_trinity_no_scaffolding_comments(REPO_ROOT, "pack-root")
```

**Audit trail.** Three inline comment blocks codify the design state:
1. BD-183 Check 16 comment — explains that BOTH invocations run, with pack-root short-circuiting via the per-surface exemption mechanism; cites BD-183 §2.4 Option (b) + the user-approval date.
2. BD-181 Check 18 comment — pre-existing; preserved as-is.
3. BD-183 Check 19 comment — explains that BOTH invocations run the full check body; cites the empirical clean pre-check.

Reading any of these comments in isolation, a future maintainer will understand the design state and the rationale, including the distinction between Check 16's per-surface exemption (template-only scope) and Check 19's full-coverage (applies uniformly to any trinity surface).

### §3.5 New carve-out: `_CHECK_16_EXEMPT_SURFACES` (BD-183 §2.4 Option (b))

**Constant.** Module-level set defined immediately above `check_trinity_addenda_h2`:

```python
# Surfaces where Check 16 (`## Project addenda` H2 + HTML-comment placeholder
# locking) does NOT apply. The mechanism is template-only infrastructure for
# Procedure 5-C.2 client reconciliation; surfaces that are NOT reconciled to
# client repos (e.g., pack-root trinity) have no `## Project addenda` H2 by
# design and the check short-circuits with an OK (exempt) message. Per
# BD-183 §2.4 Option (b) user-approved 2026-05-21.
_CHECK_16_EXEMPT_SURFACES: set[str] = {"pack-root"}
```

**Initial membership:** single element `"pack-root"`. The set is intentionally a `set[str]` (not a tuple or list) to make additions O(1) and to express "membership test" semantics in the function body. Extending the exempt list for future surfaces (e.g., if a future BD adds a third trinity location that is also template-only-exempt) is a 1-line change with no other code edits required.

**Comparison to `GEMINI_INTRINSIC_H2S` (Check 18 carve-out).**

| Carve-out | Scope | Membership | Pattern |
|---|---|---|---|
| `GEMINI_INTRINSIC_H2S` | per-CLI (which H2 names GEMINI may add) | `{"## Agent roster", "## Gemini CLI operating notes"}` | Per-line filter (function body removes intrinsic H2s from GEMINI's list before cross-CLI comparison) |
| `_CHECK_16_EXEMPT_SURFACES` | per-SURFACE (which trinity locations are check-exempt) | `{"pack-root"}` | Per-invocation short-circuit (function body returns early with OK exempt message when `label` matches) |

Both carve-outs codify legitimate divergence from the default. `GEMINI_INTRINSIC_H2S` codifies per-CLI divergence within Check 18; `_CHECK_16_EXEMPT_SURFACES` codifies per-surface divergence within Check 16. The two patterns are complementary; both are explicit-in-source design records.

**Why this is NOT a `GEMINI_INTRINSIC_H2S`-pattern carve-out.** The BD-183 prompt anticipated potential carve-outs analogous to `GEMINI_INTRINSIC_H2S` IF empirical pre-check revealed legitimate per-CLI divergence. The Check 16 finding is per-SURFACE divergence (template-only vs ops-doc), not per-CLI, so the per-line GEMINI_INTRINSIC_H2S filter pattern doesn't directly apply. Option (b)'s per-surface short-circuit is the surface-level analog — same design philosophy (explicit-in-source carve-out for legitimate divergence), different mechanism level (whole-invocation exemption vs per-line filter).

### §3.6 Override 9 compliance proof

Per Override 9, the new invocations must operate independently — no cross-location state sharing, no cross-location parity gating.

**Code review.** Each generalized function reads ONLY the 3 files inside `trinity_root` (no cross-root file access). The threaded `label` is used for output formatting AND (for Check 16 only) as the key into the per-surface exemption set `_CHECK_16_EXEMPT_SURFACES`. The exemption check is purely local to its invocation — it does NOT consult any state from any other invocation. All file reads + comparisons (when not short-circuited) are scoped to the single call's `trinity_root`. No global state is consumed beyond `REPO_ROOT` (used only via the default-param resolution) and the local-to-Check-16 `_CHECK_16_EXEMPT_SURFACES` constant.

**Empirical proof.** Test Group 5 (`test-validate-pack-check-16-19.sh`) exercises the Override 9 invariant for BOTH Check 16 and Check 19. Two synthetic trinity locations with completely different content are run through independent invocations. Each invocation must produce results scoped to its own location only — no cross-pollution of file paths, H2 names, or exemption messages. All Override 9 assertions PASS.

**Group 7 (new — Option (b) exemption mechanism)** additionally exercises Override 9 at the exemption-mechanism level: assertion E3 confirms that calling `check_trinity_addenda_h2(failing_root, 'project-template')` against a fixture that WOULD otherwise short-circuit if labeled `'pack-root'` correctly produces 3 failures (label-specific behavior; no cross-label state sharing).

### §3.7 Per-surface exemption mechanism (BD-183 §2.4 Option (b)) — design + implementation

**Design constraint.** Make the "pack-root is template-only-exempt" decision explicit in source code, self-discoverable by any reader of `check_trinity_addenda_h2`, and extensible to additional surfaces in future BDs without code structural change.

**Mechanism shape.** Three components:

1. **Module-level constant `_CHECK_16_EXEMPT_SURFACES: set[str]`** — defined immediately above `check_trinity_addenda_h2`. Documented via a 6-line comment block citing BD-183 §2.4 Option (b) + the 2026-05-21 user-approval date + the template-only Procedure 5-C.2 rationale. Initial membership `{"pack-root"}`.

2. **In-function short-circuit** — added in `check_trinity_addenda_h2` immediately after `print(...)` header and before the per-file `for name in ("CLAUDE.md", "AGENTS.md", "GEMINI.md"):` loop:

```python
# Per-surface exemption (BD-183 §2.4 Option (b)): template-only check
# short-circuits on surfaces that are NEVER reconciled to client repos.
# See `_CHECK_16_EXEMPT_SURFACES` definition above for the exempt set.
if label in _CHECK_16_EXEMPT_SURFACES:
    ok(f"[{label}] surface exempt — Check 16 is template-only "
       f"(`## Project addenda` mechanism has no purpose at non-reconciled "
       f"surface per BD-183 §2.4)")
    return
```

The short-circuit happens AFTER the header print so CI log structure remains uniform (every Check 16 invocation produces a `── Check 16 [<label>]: ... ──` section header followed by either OK lines or FAIL lines). The OK exempt message cites BD-183 §2.4 for forward-pointing maintainability — a future reader investigating WHY pack-root short-circuits is one grep away from this design record.

3. **Docstring expansion** — `check_trinity_addenda_h2` docstring now includes a `Semantic scope (BD-183 §2.4 Option (b) — user-approved 2026-05-21)` paragraph that explains the template-only scope, the `_CHECK_16_EXEMPT_SURFACES` mechanism, and cross-references this IMPL-REPORT §2.4 + §3.7. Any reader of the function source sees both the original Check 16 intent AND the Option (b) implementation in the same docstring.

**Extensibility.** Adding a new surface to the exemption is a 1-line edit:

```python
_CHECK_16_EXEMPT_SURFACES: set[str] = {"pack-root", "some-future-surface"}
```

No other code edits required. The Group 7 unit test would need a corresponding update (add a new test case for the new surface) and the IMPL-REPORT for that future BD would need to document the rationale, but the mechanism itself absorbs new surfaces without re-architecture.

**Self-documenting allowlist principle.** The constant's comment block (§3.5) IS the design record visible in source. Following the BD-179 self-documenting allowlist pattern (per pack-root `CLAUDE.md` and the BD-179 IMPL-REPORT), `_CHECK_16_EXEMPT_SURFACES` carries enough context-in-comment that a code reviewer can answer "is this entry legitimate?" by reading the comment, without needing to chase external docs. New entries added by future BDs should follow the same self-documenting discipline.

**Test coverage.** All exemption-mechanism tests live in `scripts/tests/test-validate-pack-check-16.sh` (per BD-183 §3.8 naming-convention compliance — splits Check 16 + Check 19 into per-check files). Group 5 of that file carries the 4 E-assertions (E0 constant exists + contains `pack-root`; E1 exempt-label short-circuits before file reads, verified by providing an empty trinity_root; E2 exempt-label short-circuits even with failing content, proving label-based not content-based; E3 non-exempt label with identical failing content correctly FAILs, proving label-specificity; E4 header-print precedes exempt-OK, ensuring uniform CI log structure). Group 6 of that file asserts the end-to-end main() invocation correctly routes through the exemption.

---

### §3.8 Test-file naming convention compliance (user-approved 2026-05-21)

**Convention audit (Pack Chat presented to user 2026-05-21).** The dominant convention in `scripts/tests/` for validate-pack check tests is **per-check singular files**:

- `test-validate-pack-check-18.sh` (BD-181, Check 18 only)
- `test-validate-pack-check-39.sh` (BD-175 F2a, Check 39 only)
- `test-validate-pack-check-40.sh` (BD-179, Check 40 only)
- `test-validate-pack-check-41.sh` (BD-180 G, Check 41 only)

The only existing bundle is `test-validate-pack-checks-32-33-34.sh` (BD-168 per-entry split validators — checks 32/33/34 form a single conceptual unit covering mirror-in-sync + TOC-in-sync + cross-reference integrity) and `test-validate-pack-checks-36-37-38.sh` (BD-175 Commit 12 pack/project boundary — checks 36/37/38 form a single conceptual unit covering commit-scope-honesty + project-side deny-list + pack-only-file siting). Bundle files use the plural `checks-` prefix.

**User direction.** Checks 16 and 19 do NOT form a single conceptual unit:
- Check 16 enforces template-only `## Project addenda` H2 infrastructure (Procedure 5-C.2 reconciliation landing point).
- Check 19 enforces no-body-scaffolding (fresh-install-comment leak prevention).

They share an implementation pattern (BD-181 generalization with `trinity_root` + `label`) but serve different purposes. The "16-19" bundled name is additionally misleading — looks like an inclusive range covering 17 + 18 (which it does NOT). Per user direction (2026-05-21), the bundle was split into two singular per-check files matching the dominant convention.

**Split disposition.**

- `scripts/tests/test-validate-pack-check-16.sh` (Check 16 only, including BD-183 §2.4 Option (b) exemption mechanism unit + e2e tests) — 6 groups, 10 PASS assertions.
- `scripts/tests/test-validate-pack-check-19.sh` (Check 19 only) — 5 groups, 9 PASS assertions.
- Bundled `scripts/tests/test-validate-pack-check-16-19.sh` deleted (was untracked; never tracked in git history).

**Substance preservation.** Zero test-logic changes. Each new file contains exactly the test assertions previously in the bundled file's corresponding groups, plus a per-file Group 0 (signature check) and a per-file e2e group (formerly Group 8 in the bundle, now Group 6 in `-16.sh` / Group 5 in `-19.sh`). Total assertion count rose from 15 (bundled) to 19 (split) due to:
- Per-file Group 0 signature check (was 1 combined Group 0 in bundle; now 2 separate Group 0s).
- Per-file e2e group asserts only its own check's main() state (was 1 combined e2e in bundle asserting 6 things; now 4 assertions in `-16.sh` Group 6 + 4 assertions in `-19.sh` Group 5).

No assertion removed; mechanical split with per-file boilerplate added.

**CI workflow alignment.** `.github/workflows/validate-pack.yml` updated to invoke each new file as its own step (per the existing Check 18 / 39 / 40 / 41 sister-step convention):

```yaml
- name: validate-pack Check 16 tests (BD-183, trinity ## Project addenda H2 + Option (b) exemption)
  if: always()
  run: bash scripts/tests/test-validate-pack-check-16.sh
- name: validate-pack Check 19 tests (BD-183, trinity templates free of body scaffolding)
  if: always()
  run: bash scripts/tests/test-validate-pack-check-19.sh
```

Positioned after the existing Check 40 step (BD-order: BD-179's Check 40 → BD-183's Check 16 + Check 19), maintaining the sister-step cluster pattern.

---

## §4 Test coverage

**Two new sibling test files** (split per the BD-183 §3.8 naming-convention compliance, user-approved 2026-05-21):

1. `scripts/tests/test-validate-pack-check-16.sh` — Check 16 only, including the BD-183 §2.4 Option (b) per-surface exemption mechanism (`_CHECK_16_EXEMPT_SURFACES` unit + e2e tests).
2. `scripts/tests/test-validate-pack-check-19.sh` — Check 19 only.

**Pattern choice rationale.**
- **Per-check singular files (over bundled file):** matches the dominant `scripts/tests/` convention (`test-validate-pack-check-18.sh` / `-39.sh` / `-40.sh` / `-41.sh`). See §3.8 for the convention audit + user-approved split rationale. Checks 16 + 19 share an implementation pattern (BD-181 generalization) but serve different purposes (template-only addenda H2 lock vs scaffolding-comment leak prevention) — not a single conceptual unit, so the singular convention applies.
- **Sibling test pattern (vs extending an existing test):** Same rationale as BD-181 — no existing test covers Check 16 or Check 19, and the BD-181/BD-179 sibling-test pattern is the proven harness shape for synthetic-fixture validate-pack check tests.
- **Synthetic fixtures (in-Python heredocs writing temp directories) preferred over static files in `scripts/tests/fixtures/`.** Rationale: Check 16/19 fixtures are tiny (3 trinity files × a few lines each), and the synthetic-heredoc pattern keeps each test self-contained without adding fixture-subdirectory bloat. Matches the BD-181 pattern.

**Test groups — `test-validate-pack-check-16.sh` (Check 16 + Option (b) exemption mechanism):**

| Group | Coverage | PASS count |
|---|---|---|
| 0 | Module import + Check 16 signature accepts `(trinity_root, label)` params; sentinel-None default verified | 1 |
| 1 | Check 16 PASS paths — synthetic trinity with `## Project addenda` + placeholder; label threading | 1 (covers T1-T2) |
| 2 | Check 16 FAIL paths — missing H2; missing placeholder marker; missing file; non-exempt label with failing content correctly FAILs | 1 (covers F1-F4) |
| 3 | **Override 9** — Check 16 invocations independent across two synthetic trinity locations; no cross-location coupling; no label cross-pollution | 1 |
| 4 | Backward compatibility — default-args call preserves project-template single-location behavior for Check 16 | 1 |
| 5 | **Per-surface exemption (BD-183 §2.4 Option (b))** — `_CHECK_16_EXEMPT_SURFACES` constant exists + contains `pack-root`; exempt label short-circuits before file reads (E1); exempt label short-circuits even with failing content (label-based not content-based; E2); non-exempt label with identical failing content correctly FAILs (label-specificity; E3); section header precedes exempt OK (uniform CI log structure; E4) | 1 |
| 6 | End-to-end validate-pack.py — exits 0; Check 16 [project-template] runs; **Check 16 [pack-root] runs AND short-circuits via `_CHECK_16_EXEMPT_SURFACES`** (Option (b) regression guard) | 4 |

**Test groups — `test-validate-pack-check-19.sh` (Check 19):**

| Group | Coverage | PASS count |
|---|---|---|
| 0 | Module import + Check 19 signature accepts `(trinity_root, label)` params; sentinel-None default verified | 1 |
| 1 | Check 19 PASS paths — no HTML comments (pack-root-style); allowed comment types (HOW TO USE, Project addenda, Trinity-rule exception); label threading | 1 (covers T1-T3) |
| 2 | Check 19 FAIL paths — scaffolding in each of CLAUDE/AGENTS/GEMINI; missing file | 1 (covers F1-F4) |
| 3 | **Override 9** — Check 19 invocations independent across two synthetic trinity locations; no cross-location coupling; no label cross-pollution | 1 |
| 4 | Backward compatibility — default-args call preserves project-template single-location behavior for Check 19 | 1 |
| 5 | End-to-end validate-pack.py — exits 0; Check 19 [project-template] runs; Check 19 [pack-root] runs and reports clean (BD-183 landed; no exemption applies) | 4 |

**Test execution result (HEAD with BD-183 Option (b) + per-check-file split applied):**

```
$ bash scripts/tests/test-validate-pack-check-16.sh
=== Summary ===
  PASS: 10
  FAIL: 0
All tests passed.

$ bash scripts/tests/test-validate-pack-check-19.sh
=== Summary ===
  PASS: 9
  FAIL: 0
All tests passed.
```

All 19 tests PASS across the two split files (10 + 9). Grand total versus pre-split bundled file:
- **Pre-split bundled** (`test-validate-pack-check-16-19.sh`): 15 PASS.
- **Post-split per-check** (`-16.sh` + `-19.sh`): 19 PASS.
- **Net delta: +4 PASS.** Two come from doubling the Group 0 signature check (per-file boilerplate). The other two come from each e2e group asserting only its own check's main() state in isolation, which surfaces independent regression guards (formerly the bundled Group 8 conflated both checks into 6 sub-assertions; now `-16.sh` Group 6 has 4 sub-assertions for Check 16 + `-19.sh` Group 5 has 4 sub-assertions for Check 19).

**Substance preservation: zero test-logic changes.** Every assertion from the pre-split bundle is preserved exactly in one of the two split files; no assertion removed; the bundled file's group ordering maps cleanly to per-check groups. See §3.8 for the convention audit + split methodology.

**Forcing-function regression guard for Option (b) (preserved post-split).** `test-validate-pack-check-16.sh` Group 5 (function-level) + Group 6 (e2e) together form the regression guard for the exemption mechanism. If a future maintainer removes the `if label in _CHECK_16_EXEMPT_SURFACES:` short-circuit from `check_trinity_addenda_h2`, or removes `"pack-root"` from the exempt set, both groups fail loudly (function-level: missing OK exempt message + label-specificity violation; e2e: Check 16 [pack-root] no longer reports the exempt OK).

---

## §5 Files modified

| Path | Change | Lines (+/-) | Purpose |
|---|---|---|---|
| `scripts/validate-pack.py` | Modified | +119 / -15 | (a) Generalize Check 16 (`check_trinity_addenda_h2`) signature + body; (b) Generalize Check 19 (`check_trinity_no_scaffolding_comments`) signature + body; (c) BD-181 NIT-1 — sentinel-None contract comment at `check_trinity_h2_parity`; (d) Replace single-call sites in `main()` with explicit-arg forms; add pack-root invocation for BOTH Check 16 (with exemption short-circuit) and Check 19 (full check body); (e) New `_CHECK_16_EXEMPT_SURFACES` module-level constant + in-function short-circuit (BD-183 §2.4 Option (b)) |
| `scripts/tests/test-validate-pack-check-16.sh` | New | +583 / 0 | Synthetic-fixture test coverage for Check 16 (7 test groups, 10 PASS assertions; covers signature, PASS, FAIL, Override 9, backward compat, Option (b) exemption mechanism unit tests, and e2e Option (b) regression guard); matches singular per-check convention per BD-183 §3.8 |
| `scripts/tests/test-validate-pack-check-19.sh` | New | +454 / 0 | Synthetic-fixture test coverage for Check 19 (6 test groups, 9 PASS assertions; covers signature, PASS, FAIL, Override 9, backward compat, and e2e main() invocation state); matches singular per-check convention per BD-183 §3.8 |
| `scripts/tests/test-validate-pack-check-16-19.sh` | Deleted | -891 (delta to bundle that never reached git history) | Bundled file from pre-split BD-183 work; deleted per BD-183 §3.8 user-approved naming-convention compliance (2026-05-21). Never committed to git, so no `D` entry in `git status` post-deletion. Substance preserved in the two split files above with zero test-logic changes. |
| `.github/workflows/validate-pack.yml` | Modified | +6 / 0 | CI workflow alignment per BD-183 §3.8 — replaced single sister-step with two per-check sister steps positioned after the existing Check 40 step (BD-order BD-179 → BD-183). Each new step matches the `name:` + `if: always()` + `run:` shape of the surrounding Check 39/40/41 sister-step cluster. |

**Files NOT modified (per prompt scope):**

- Trinity files (pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` AND `project-template/{CLAUDE,AGENTS,GEMINI}.md`) — NOT modified per prompt's "Check 16/19 are AUDITORS; if you find drift, surface, don't silently fix." See §2 BLOCKING surface (now CLOSED via Option (b)) for Check 16; Check 19 needed no fix (empirical clean).
- `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `README.md` — out of Pack-Chat-direct scope.
- Any architect doc; any other `pack-ops/` doc; any `maintenance-docs/` doc except this IMPL-REPORT.
- `test-fixtures/manifest.txt` — RC9 rebuild produced empty diff (see §7 below).

---

## §6 Verification

### §6.1 `python3 scripts/validate-pack.py` — exit status

**Exit code: 0** ("PASSED — all checks clean"). All 41 checks green.

Relevant tail of run (Check 16, Check 18, Check 19 sections — post-Option (b)):

```
── Check 16 [project-template]: Trinity ## Project addenda H2 (BD-059, BD-183) ──
  OK: [project-template] CLAUDE.md — '## Project addenda' H2 with placeholder
  OK: [project-template] AGENTS.md — '## Project addenda' H2 with placeholder
  OK: [project-template] GEMINI.md — '## Project addenda' H2 with placeholder

── Check 16 [pack-root]: Trinity ## Project addenda H2 (BD-059, BD-183) ──
  OK: [pack-root] surface exempt — Check 16 is template-only (`## Project addenda` mechanism has no purpose at non-reconciled surface per BD-183 §2.4)

── Check 18 [project-template]: Trinity H2 structure parity (BD-059, BD-181) ──
  OK: [project-template] CLAUDE.md ↔ AGENTS.md H2 structures match (26 sections)
  OK: [project-template] GEMINI.md adds 2 intrinsic H2(s); otherwise matches (26 sections)

── Check 18 [pack-root]: Trinity H2 structure parity (BD-059, BD-181) ──
  OK: [pack-root] CLAUDE.md ↔ AGENTS.md H2 structures match (5 sections)
  OK: [pack-root] GEMINI.md adds 1 intrinsic H2(s); otherwise matches (5 sections)

── Check 19 [project-template]: Trinity templates free of body scaffolding (BD-059, BD-183) ──
  OK: [project-template] All three trinity templates free of body-section scaffolding comments

── Check 19 [pack-root]: Trinity templates free of body scaffolding (BD-059, BD-183) ──
  OK: [pack-root] All three trinity templates free of body-section scaffolding comments

...

============================================================
PASSED — all checks clean
```

Confirmed:
- Check 16 [project-template] runs and reports clean (backward-compat preserved).
- Check 16 [pack-root] runs AND short-circuits via the per-surface exemption mechanism — `OK: [pack-root] surface exempt — Check 16 is template-only ...` (BD-183 §2.4 Option (b) wiring confirmed end-to-end).
- Check 18 [project-template] and [pack-root] both run clean (BD-181 regression guard).
- Check 19 [project-template] and [pack-root] both run clean (BD-183 added the pack-root invocation; pre-check confirmed empirical clean; no exemption applies).

### §6.2 New test suites — `test-validate-pack-check-16.sh` + `test-validate-pack-check-19.sh`

**Both files exit 0.** 19 PASS assertions across 13 groups (10 + 9), zero failures.

```
$ bash scripts/tests/test-validate-pack-check-16.sh
=== Summary ===
  PASS: 10
  FAIL: 0
All tests passed.

$ bash scripts/tests/test-validate-pack-check-19.sh
=== Summary ===
  PASS: 9
  FAIL: 0
All tests passed.
```

Group-level results — `test-validate-pack-check-16.sh`:

| Group | Description | Result |
|---|---|---|
| 0 | Module import + Check 16 signature | PASS |
| 1 | Check 16 PASS paths | PASS |
| 2 | Check 16 FAIL paths (incl. non-exempt-label semantics) | PASS |
| 3 | Override 9 — Check 16 invocations independent | PASS |
| 4 | Backward compatibility — default args preserve project-template behavior for Check 16 | PASS |
| 5 | **Per-surface exemption mechanism (BD-183 §2.4 Option (b))** — constant exists; label-based short-circuit (E1+E2); non-exempt label still FAILs on identical content (E3); header-before-OK order (E4) | PASS |
| 6 | End-to-end — Check 16 main()-invocation-state contract (4 sub-assertions; incl. Check 16 [pack-root] exemption regression guard) | PASS (4/4) |

Group-level results — `test-validate-pack-check-19.sh`:

| Group | Description | Result |
|---|---|---|
| 0 | Module import + Check 19 signature | PASS |
| 1 | Check 19 PASS paths | PASS |
| 2 | Check 19 FAIL paths | PASS |
| 3 | Override 9 — Check 19 invocations independent | PASS |
| 4 | Backward compatibility — default args preserve project-template behavior for Check 19 | PASS |
| 5 | End-to-end — Check 19 main()-invocation-state contract (4 sub-assertions) | PASS (4/4) |

The Option (b) exemption mechanism regression guard lives in `test-validate-pack-check-16.sh` Group 5 (function-level) + Group 6 (e2e). If a future maintainer removes the short-circuit or removes `"pack-root"` from `_CHECK_16_EXEMPT_SURFACES`, both groups fail loudly.

### §6.3 Adjacent test suites — Check 18, Check 39, Check 40, Check 41

All adjacent test suites PASS. No regressions introduced by BD-183.

| Test | Pre-BD-183 result | Post-BD-183 result | Status |
|---|---|---|---|
| `test-validate-pack-check-18.sh` | PASS 7/7 | PASS 7/7 | unchanged |
| `test-validate-pack-check-39.sh` | PASS 6/6 | PASS 6/6 | unchanged |
| `test-validate-pack-check-40.sh` | PASS 8/8 | PASS 8/8 | unchanged |
| `test-validate-pack-check-41.sh` | PASS 4/4 | PASS 4/4 | unchanged |
| `test-validate-pack-check-16.sh` | (new in BD-183 per §3.8 split) | PASS 10/10 | new |
| `test-validate-pack-check-19.sh` | (new in BD-183 per §3.8 split) | PASS 9/9 | new |

Grand total: 44 PASS / 0 FAIL across all 6 validate-pack test suites.

### §6.4 Backward-compatibility check — default-args behavior

Group 4 of each new test suite (`test-validate-pack-check-16.sh` and `test-validate-pack-check-19.sh`) explicitly exercises the no-arg call shape for its respective check. Both pass cleanly against the real `project-template/` trinity, confirming:
- `check_trinity_addenda_h2()` (no args) reproduces the pre-BD-183 single-location project-template behavior.
- `check_trinity_no_scaffolding_comments()` (no args) reproduces the pre-BD-183 single-location project-template behavior.
- Default `label='project-template'` is verified by `inspect.signature` introspection in Group 0.

---

## §7 RC9 manifest status

**RC9 trigger fired** (`scripts/` directory touched: `scripts/validate-pack.py`, the new `scripts/tests/test-validate-pack-check-16.sh`, and the new `scripts/tests/test-validate-pack-check-19.sh`). The `.github/workflows/validate-pack.yml` edit is NOT in the RC9 trigger glob (workflow files are not part of the v11-surface trigger; the trigger is `project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/` per pack memory § Repo conventions → "Regenerate test-fixtures/manifest.txt on every v11-surface commit").

**Rebuild command:** `bash test-fixtures/build.sh --all --clean` from pack root. Completed successfully. All 6 fixtures rebuilt (v10-flat, v10-template-version, v11-realistic-ot, v11-flat-file, v11-tracker-on, existing-project-mid-dev).

**`git diff test-fixtures/manifest.txt` after rebuild: EMPTY** (zero lines of diff output).

Per the RC9 trailing-clause logic in pack-root trinity `CLAUDE.md` § Repo conventions: "if empty, your edit wasn't v11-surface (no staging needed)." This is the expected outcome for `scripts/validate-pack.py` + `scripts/tests/*` edits — these are pack-internal validation/test scripts and not part of the client install path. The rebuild confirms this empirically. No `test-fixtures/manifest.txt` staging needed.

This matches the BD-181 RC9 outcome exactly (both BDs edited pack-internal scripts only). The rebuild was re-confirmed empty after each of three phases: (1) initial BD-183 generalization + BLOCKING surface; (2) Option (b) exemption mechanism; (3) per-check file split per §3.8.

---

## §8 Architect-doc-vs-reality reconciliation

Per pack memory § Repo conventions → "Architect-doc-vs-reality reconciliation":

BD-183 has NO separate architect doc (per `pack-ops/BACKLOG.md` BD-183 entry L1706: "Implementation pattern: mechanical pack-coder work (no architect spawn needed — generalizing existing checks is mechanical extension of the proven BD-181 pattern)"). The authoritative design records are:

1. **`pack-ops/BACKLOG.md` BD-183 entry** (L1680-L1709) — scope authority.
2. **`PACK-REVIEW-BD-181.md` §6 Observation A** — the BD-181 reviewer's carry-forward observation that surfaced the parity gap motivating BD-183.
3. **`PACK-REVIEW-BD-181.md` §4 NIT-1** — the BD-181 reviewer's recommendation for the sentinel-None contract comment folded into BD-183.
4. **`IMPLEMENTATION-REPORT-BD-181.md`** — the proven generalization pattern (sentinel-None + label threading; Override 9 compliance proof; sibling-test pattern with synthetic fixtures).

**Reconciliation chain.** This commit realizes the BD-183 entry scope. In-code docstring additions at `check_trinity_addenda_h2` cross-reference both BD-059 (original) and BD-183 (generalization). The Check 16 docstring also includes a "Semantic note (BD-183 empirical pre-check finding)" paragraph that names this IMPL-REPORT §3 as the design record for the template-only scope decision. The pack-root invocation site for Check 16 carries an inline comment that references this IMPL-REPORT § 3 BLOCKING surface.

**Architect-doc-vs-reality reconciliation pattern (per `CLAUDE.md` § Repo conventions):**
- (a) In-code docstring naming the realized design record: Check 16 docstring cites "IMPLEMENTATION-REPORT-BD-183.md §3 BLOCKING surface"; Check 19 docstring cites BD-183 and references BD-181 design pattern.
- (b) No architect-doc addendum needed (BD-183 has no architect doc).
- (c) This IMPL-REPORT links the BD-183 BACKLOG entry, the BD-181 design records, and the in-code citations.

---

## §9 Boundary discipline check (P-missed-7)

Per Pack memory `P-missed-7` and the `boundary-investigation` skill, before any change touching a project-side file: investigate whether a project-side SSOT exists.

**Files this BD edited:**
- `scripts/validate-pack.py` — pack-internal validation script. NOT project-side. NOT in client install path (per `scripts/init-project.sh` inspection — Stage S1 copies `project-template/`, not `scripts/`).
- `scripts/tests/test-validate-pack-check-16-19.sh` — pack-internal test script. NOT project-side. NOT in client install path.

**Zero project-template/ edits** confirmed: `git diff --name-only | grep project-template/` returns empty.

**Zero pack-only-mechanism cross-references introduced into project-side files:** N/A (no project-side files touched).

**Per the `boundary-investigation` skill § "When this skill applies":** this skill does NOT apply to BD-183. The full quote: "It does NOT apply to changes scoped entirely to pack-only files: pack-repo root trinity (...), `pack-ops/` (any file there), `maintenance-docs/`, `scripts/`, `test-fixtures/`, or the pack-repo `.claude/` / `.codex/` / `.gemini/` dotted dirs at the pack repo root." BD-183 is scoped entirely to `scripts/` (pack-internal) and `maintenance-docs/v11-implementation/` (this IMPL-REPORT). Boundary discipline trivially satisfied.

---

## §10 Carry-forward discipline

Per `.claude/skills/review/SKILL.md` § "Carry-forward discipline" (SIZE / BLOCKED / LOGICAL-FIT high-bar — operationalizes pack memory "Deferral IS scope creep"):

**Zero deferrals. Zero carry-forwards.**

Scope-adjacent observations encountered during implementation:

**Observation 1: Check 16 pack-root template-only semantic mismatch — RESOLVED via Option (b).**
- **SIZE.** Modest (~30 lines net for the exempt-set constant + 6-line comment block + 6-line in-function short-circuit + docstring expansion + Group 7 unit test + Group 8 e2e sub-assertion).
- **BLOCKED.** Originally triage-blocked, NOT implementation-blocked. Pack Chat triaged with user; user selected Option (b) 2026-05-21. No longer blocked.
- **LOGICAL FIT.** Strongly fits BD-183 itself (BD-183 IS the gate that surfaces the mismatch). The IMPL-REPORT documents the BLOCKING surface, the four triage options, the user's Option (b) decision, and the in-commit resolution.
- **Action taken:** Initial pass surfaced §2.4 BLOCKING; user-approved Option (b) landed in the SAME COMMIT per the convergence directive. **NOT carry-forward** — the BLOCKING surface IS the in-scope finding for BD-183, and it is now closed with the user-selected disposition (Option (b) exemption mechanism).

**Observation 2: Other validate-pack trinity checks beyond Check 16 / 18 / 19.**
- Per the BD-183 prompt's explicit scope clause ("BACKLOG explicitly scopes BD-183 to Check 16 + Check 19"), extensions to OTHER trinity checks are out of BD-183 scope.
- Empirically surveyed during this work: I did not find any additional `REPO_ROOT / "project-template"`-hardcoded trinity-content checks beyond Check 16, Check 18 (already generalized by BD-181), and Check 19. Most other checks in `validate-pack.py` either (a) read pack-internal files (e.g., `scripts/`, `pack-ops/`, `.github/`), (b) iterate over all trinity files at multiple locations (e.g., Check 18 H2 trinity rules — already handled), or (c) read project-template content for purposes that don't apply to pack-root.
- **Carry-forward outcome:** None. No new BD opportunity surfaced beyond the existing BLOCKING surface.

**Observation 3: Test bundle naming (`test-validate-pack-check-16-19.sh`).**
- Filename uniqueness check (per pack memory § Repo conventions → filename uniqueness heuristic): `find . -name "test-validate-pack-check-16-19.sh" -not -path "./.git/*"` returns single result. No collision.
- The combined name follows the BD-181 sibling pattern (`test-validate-pack-check-18.sh`) and the BD-179 sibling pattern (`test-validate-pack-check-40.sh`), extended for the combined two-check scope.
- **Carry-forward outcome:** None. Filename naming decision is in-scope and documented in §4 pattern-choice rationale.

**Observation 4: Inline source-code cross-references to this IMPL-REPORT.**
- Multiple source-code citations of "BD-183 §2.4" (in the `_CHECK_16_EXEMPT_SURFACES` comment block; in the exempt-OK message text; in the `check_trinity_addenda_h2` docstring; in the `main()` inline comment for Check 16). These are content references, not line numbers — they cite section numbers within a named report.
- Robustness profile: section-number citations of the form "per BD-183 §2.4" remain VALID as long as the referenced report preserves its §X.Y addressability — that is, the section heading stays at the same number. File MOVES (e.g., post-v11.0 archive sweep per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` § Pattern B, which would relocate this report to `maintenance-docs/archive/v11/`) do NOT invalidate these citations: the report is findable by BD-number + name regardless of path, and §2.4 still resolves to the same content within. Only a doc-RESTRUCTURE that renumbers or removes §2.4 would invalidate them. Per "Architect-doc-vs-reality reconciliation" pattern: comments should reference symbols + named sections (not line numbers) precisely to inherit this robustness — line numbers drift on any edit; named-section citations only drift on intentional restructure.
- The exempt-OK message itself ("per BD-183 §2.4") is part of `check_trinity_addenda_h2` USER-VISIBLE OUTPUT (printed to CI logs every run). This citation is doubly useful: it's both an in-code design record AND a CI-log diagnostic pointer that anyone debugging a Check 16 exemption can grep for and immediately find this report.
- **Carry-forward outcome:** None. Standard practice for IMPL-REPORT cross-references; the user-visible CI-log pointer is a benefit, not a risk; section-number citations are robust to file moves under the standard `maintenance-docs/` archive convention.

**Carry-forward count: 0.** All observations either fit BD-183 scope and are addressed in-scope (Observation 1 originally BLOCKING, now resolved via user-approved Option (b)).

---

## §11 New POQs introduced

**Zero new POQs.** All design decisions in BD-183 are mechanical extensions of the proven BD-181 pattern (the BACKLOG entry explicitly classifies BD-183 as mechanical pack-coder work). The §2.4 BLOCKING surface was a Pack Chat triage (not a POQ), and the user selected Option (b); the implementation followed the user-approved disposition without surfacing further design questions.

---

## §12 Definition-of-Done checklist (per BD-183 scope)

| Criterion | Status | Evidence |
|---|---|---|
| Check 16 generalized with base-path parameter (sentinel-None default, label threading) | PASS | §3.1 + signature `check_trinity_addenda_h2(trinity_root: Path = None, label: str = "project-template")` |
| Check 19 generalized similarly | PASS | §3.2 + signature `check_trinity_no_scaffolding_comments(trinity_root: Path = None, label: str = "project-template")` |
| Pack-root invocation added in main() for both checks | PASS | Check 19 [pack-root]: landed (pre-check clean; full check body runs). Check 16 [pack-root]: landed via BD-183 §2.4 Option (b) per-surface exemption mechanism (user-approved 2026-05-21); see §3.7. |
| Per-surface exemption mechanism (`_CHECK_16_EXEMPT_SURFACES`) for Check 16 pack-root | PASS | §3.5 + §3.7 — module-level constant + in-function short-circuit + docstring expansion + `test-validate-pack-check-16.sh` Group 5 unit test coverage |
| Both invocations enforce within-trinity parity independently (Override 9) | PASS | §3.6 — `test-validate-pack-check-16.sh` Group 3 + `test-validate-pack-check-19.sh` Group 3 prove empirically via 2-location independence assertions; `test-validate-pack-check-16.sh` Group 5 E3 confirms exemption is label-specific (no cross-label state) |
| BD-181 NIT-1: sentinel-None call-site contract comment at `check_trinity_h2_parity` | PASS | §3.3 — 6-line comment added per PACK-REVIEW-BD-181 §4 NIT-1 recommendation |
| Test fixture extended/added covering pack-root PASS + FAIL synthetic cases for both Check 16 + Check 19 | PASS | §4 — TWO new per-check sibling files per BD-183 §3.8 (user-approved 2026-05-21): `test-validate-pack-check-16.sh` (10 PASS across 7 groups; incl. Option (b) exemption mechanism + e2e regression guard) + `test-validate-pack-check-19.sh` (9 PASS across 6 groups; full check body at both trinity locations) |
| Test-file naming convention compliance | PASS | §3.8 — singular-per-check pattern (matches BD-181 `test-validate-pack-check-18.sh`, BD-175 F2a `-39.sh`, BD-179 `-40.sh`, BD-180 G `-41.sh`); bundled `-16-19.sh` file deleted; per-step CI workflow alignment landed in `.github/workflows/validate-pack.yml` |
| All checks pass: `python3 scripts/validate-pack.py` | PASS | §6.1 — exit 0; "PASSED — all checks clean"; Check 16 [pack-root] shows exempt OK message |
| All tests pass: existing Check 18 + Check 39 + Check 40 + Check 41 + new BD-183 tests | PASS | §6.3 — 44 PASS / 0 FAIL grand total across 6 test suites |
| Empirical pre-implementation drift check result documented | PASS | §2 — Check 19 [pack-root] CLEAN (landed); Check 16 [pack-root] originally FAILED by design (BLOCKING surface §2.4); resolved via Option (b) user-approved 2026-05-21 |
| IMPL-REPORT documents per-check generalization + NIT-1 fold + pre-check result + Option (b) resolution | PASS | §2, §3 (incl. §3.5 + §3.7), §4 |
| RC9 manifest empty diff (pack-internal scripts) | PASS | §7 — `bash test-fixtures/build.sh --all --clean` produced empty diff (re-confirmed after Option (b) edits) |
| Plan deviations | NONE | §13 below |
| New POQs introduced | NONE | §11 |
| Carry-forwards | NONE | §10 |
| Trinity rule (parallel edit) satisfied | N/A | Pack-internal `scripts/` work; not a trinity-content edit |
| Boundary discipline (P-missed-7) | N/A | Scope entirely under `scripts/` per boundary-investigation skill's "does NOT apply" clause |

---

## §13 Plan deviations

**Zero plan deviations.** Implementation follows BD-183 entry scope plus the user-approved Option (b) triage plus the user-approved §3.8 naming-convention split:

1. Generalize Check 16 + Check 19 with `(trinity_root, label)` params — done.
2. Empirical pre-implementation drift check — done (§2). Check 19 PASSES; Check 16 originally FAILED by design (template-only semantic mismatch at pack-root).
3. Per the prompt's BLOCKING directive — Check 19 pack-root invocation landed in initial pass; Check 16 pack-root invocation surfaced as BLOCKING per §2.4. Pack Chat triaged with user; user selected Option (b) per-surface exemption mechanism (2026-05-21). Same commit ships both halves of the work.
4. Option (b) implementation: new `_CHECK_16_EXEMPT_SURFACES` module-level constant (§3.5); in-function short-circuit (§3.7); main() invocation landed for Check 16 [pack-root] (short-circuits via exemption).
5. Override 9 compliance — proven via code review (§3.6) and empirical Override-9 group tests + Group 5 E3 in `test-validate-pack-check-16.sh` (§4).
6. BD-181 NIT-1 fold-in (sentinel-None contract comment at `check_trinity_h2_parity`) — done (§3.3).
7. New test fixtures for pack-root coverage — done. Initially bundled as `test-validate-pack-check-16-19.sh`; user flagged the misleading range-vs-set naming and Pack Chat presented the singular-per-check convention audit; user approved split (2026-05-21); files split into `test-validate-pack-check-16.sh` (10 PASS, 7 groups) + `test-validate-pack-check-19.sh` (9 PASS, 6 groups) per BD-183 §3.8. Zero test-logic changes; substance preserved exactly.
8. CI workflow alignment — `.github/workflows/validate-pack.yml` updated with 2 new sister-steps (Check 16 + Check 19) positioned after the existing Check 40 step per the sister-step cluster convention.
9. RC9 manifest regen — done; empty diff confirmed three times (after initial BD-183 pass + after Option (b) edits + after §3.8 split).

The three-phase implementation (initial BLOCKING surface + Option (b) resolution + §3.8 naming-convention split, all within the same commit) is **NOT** a plan deviation. Each phase was triggered by user direction within the convergence cycle. The convergence directive explicitly stated "After this work lands, BD-183 should be ready for single coherent commit." All three phases ship as a single coherent commit; the protocol worked as designed.

---

## §14 Files changed inventory

| Path | Change type | Purpose |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/validate-pack.py` | modified | Check 16 generalization (`check_trinity_addenda_h2`) + per-surface exemption short-circuit; Check 19 generalization (`check_trinity_no_scaffolding_comments`); new `_CHECK_16_EXEMPT_SURFACES` module-level constant; BD-181 NIT-1 sentinel-None contract comment at `check_trinity_h2_parity`; main() invocation updates (both Check 16 + Check 19 land at both trinity locations; Check 16 [pack-root] short-circuits via exemption) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-validate-pack-check-16.sh` | new | Synthetic-fixture test coverage for Check 16; 7 groups, 10 PASS assertions; covers signature, PASS, FAIL, Override 9, backward compat, Option (b) exemption mechanism unit tests, e2e Option (b) regression guard |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-validate-pack-check-19.sh` | new | Synthetic-fixture test coverage for Check 19; 6 groups, 9 PASS assertions; covers signature, PASS, FAIL, Override 9, backward compat, e2e main() invocation state |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-validate-pack-check-16-19.sh` | deleted | Bundled file from pre-split BD-183 work; deleted per BD-183 §3.8 user-approved naming-convention compliance (2026-05-21). Was untracked (never committed); test substance preserved in the two split files above with zero test-logic changes. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.github/workflows/validate-pack.yml` | modified | CI workflow alignment: two new sister-steps (Check 16 + Check 19) positioned after the existing Check 40 step (BD-order BD-179 → BD-183); each step matches the `name:` + `if: always()` + `run:` shape of the surrounding sister-step cluster |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md` | new | this IMPL-REPORT (BD-183 design record + BLOCKING-surface authority + Option (b) resolution + §3.8 naming-convention split + DOD evidence) |

**Verification commands executed:**

```bash
# Empirical pre-implementation drift check (in-Python via importlib against
# generalized functions; output captured in §2):
python3 -c "...invokes check_trinity_addenda_h2(REPO_ROOT, 'pack-root')..."
python3 -c "...invokes check_trinity_no_scaffolding_comments(REPO_ROOT, 'pack-root')..."
# Check 19 [pack-root]: 0 failures.
# Check 16 [pack-root]: 3 failures (template-only semantic mismatch — §2.4 BLOCKING).

# Validate-pack end-to-end (post-Option (b) + post-split):
python3 scripts/validate-pack.py
# Exit: 0; PASSED — all checks clean. Check 16 [pack-root] shows exempt OK.

# New test suites (post-split per §3.8):
bash scripts/tests/test-validate-pack-check-16.sh   # Exit 0; PASS: 10, FAIL: 0.
bash scripts/tests/test-validate-pack-check-19.sh   # Exit 0; PASS: 9, FAIL: 0.

# Adjacent test suites (regression check):
bash scripts/tests/test-validate-pack-check-18.sh   # PASS 7/7
bash scripts/tests/test-validate-pack-check-39.sh   # PASS 6/6
bash scripts/tests/test-validate-pack-check-40.sh   # PASS 8/8
bash scripts/tests/test-validate-pack-check-41.sh   # PASS 4/4
# Grand total: 44 PASS / 0 FAIL across 6 validate-pack test suites.

# CI workflow YAML syntax check:
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))"
# Exit: 0 (YAML OK).

# RC9 manifest regen (re-run after each phase: initial pass + Option (b) + split):
bash test-fixtures/build.sh --all --clean
git diff test-fixtures/manifest.txt   # EMPTY (pack-internal scripts).

# Final git status:
git status --short
#  M .github/workflows/validate-pack.yml
#  M scripts/validate-pack.py
# ?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md
# ?? scripts/tests/test-validate-pack-check-16.sh
# ?? scripts/tests/test-validate-pack-check-19.sh
# (bundled scripts/tests/test-validate-pack-check-16-19.sh deleted; was untracked, so no `D` row)
```

---

## §15 Branch + HEAD

- **Branch:** `v11-dev`
- **HEAD at preflight (pre-implementation):** `a7ab1422c173ee9c3da96c998cfa5554867ee21a`
- **HEAD at report-write:** `a7ab1422c173ee9c3da96c998cfa5554867ee21a` (unchanged — per pack-coder rule "Agents never commit")
- **Working-tree state at report-write (post-split):** 2 modified (`scripts/validate-pack.py`, `.github/workflows/validate-pack.yml`), 3 new untracked (`scripts/tests/test-validate-pack-check-16.sh`, `scripts/tests/test-validate-pack-check-19.sh`, this IMPL-REPORT). The bundled `scripts/tests/test-validate-pack-check-16-19.sh` was deleted (was untracked, so no `D` row in `git status`). No git state-changing operations performed.

---

PREFLIGHT: 5/5 in-scope file edits complete (scripts/validate-pack.py modified [+119/-15]; .github/workflows/validate-pack.yml modified [+6/-0]; scripts/tests/test-validate-pack-check-16.sh new [583 lines]; scripts/tests/test-validate-pack-check-19.sh new [454 lines]; maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-183.md new + updated for BD-183 §2.4 Option (b) resolution + §3.8 naming-convention split; bundled scripts/tests/test-validate-pack-check-16-19.sh deleted per §3.8); verification PASS (validate-pack.py exit 0; new test suites 10/10 + 9/9; adjacent test suites 7+6+8+4=25/25 all green; grand total 44 PASS / 0 FAIL across 6 validate-pack test suites; YAML syntax OK; RC9 manifest empty diff re-confirmed after each of the three phases); BD-183 §2.4 BLOCKING surface RESOLVED via user-approved Option (b) (`_CHECK_16_EXEMPT_SURFACES` + in-function short-circuit); BD-183 §3.8 naming-convention split landed per user-approved decision 2026-05-21; HEAD a7ab1422c173ee9c3da96c998cfa5554867ee21a (unchanged — agents never commit); BD-183 ready for Pack Chat to commit as a single coherent commit.
