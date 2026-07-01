# ARCHITECTURE-BD-256 — Modularize `scripts/validate-pack.py`

**Author:** pack-architect / pack-planner (reconciled), realized by pack-coder
**Date:** 2026-06-30
**Status:** Realized (W0 scaffold + W1 core.py landed; W2–W15 extract the
category modules + registry/main).
**Scope:** BD-256. Splits the ~14.5k-line monolith
`scripts/validate-pack.py` (80 checks) into a `scripts/lib/validate_checks/`
package + a thin re-exporting facade kept at the frozen path
`scripts/validate-pack.py`.
**Inputs reviewed:** `scripts/validate-pack.py`, the full git-tracked test
universe (`scripts/tests/*.sh`, `scripts/test*.sh`), `scripts/lib/ci-shard-plan.py`,
`.github/workflows/validate-pack.yml`, `scripts/lib/manifest-inputs.sh`,
`scripts/manifest-sync.sh`, `scripts/lib/migrate-v10-to-v11/checkpoint.sh`.

---

## 1. Problem

`scripts/validate-pack.py` is the pack's monolithic CI structural validator: one
~14.5k-line module holding 80 check bodies, a shared spine (`REPO_ROOT`,
`failures`, `fail`/`ok`/`warn`, `run_check`, the budget constants,
`CHECK_REGISTRY_EXPECTED_COUNT`), and a registry assembler. Every check-adding
BD edits the same file → a persistent edit-collision surface. BD-256
modularizes it into a package of category modules + a thin facade, WITHOUT
changing behavior (the facade path is frozen for CI + the migrator) and WITHOUT
changing which tests run.

## 2. The seam analysis

A naive split breaks two coupling seams:

- **The shared SPINE.** Every check references `REPO_ROOT`, appends to
  `failures` via `fail()`, and is dispatched through `run_check`. These cannot
  be duplicated per module (a forked `failures` list decouples the exit-code
  accounting). They live ONCE in `core.py`; every module does
  `from .core import …`; the facade re-imports them so the still-inline code
  resolves.

- **The cross-MODULE constants (the "seams").** Most check constants are private
  to one check's cluster, but a measured set is read by checks in DIFFERENT
  connected components. Those 8 cross-module seams are promoted to `core.py`:
  `STREAMS` (per-entry checks 32/33/34), `README` (Check 4 + the
  `_immutable_readme_version` discipline check; also load-time-derived from
  `REPO_ROOT`), `_session_state_load` + the `_SESSION_STATE_*` constants
  (Checks 77/78/79), `_PACK_CHAT_ONLY_PERMITTED_PATHS` +
  `_PACK_CHAT_ONLY_PERMITTED_PREFIXES` (Check 36 + the Check 80 twin-registry),
  `_TRACKER_BACKENDS` (Check 29 + the Check 80 twin), `_CHECK_54_REQUIRED_TOKENS`
  (Check 54), and `_CHECK_56_CANONICAL_VERBS` (Check 56). No seam is duplicated
  — each lives once in `core` and every consuming check imports it.

A symbol that is private to a single cluster stays in that cluster's module; a
genuinely-isolated check's constants stay with the check in `singletons.py`.

## 3. Mechanism (b) — verbatim bodies + facade re-import

Three candidate mechanisms were evaluated on measured cost. The chosen
**Mechanism (b)** moves check bodies VERBATIM into category modules and
re-points the seam-reassignment test sites to monkeypatch the OWNING module
instead of the facade. (b) is the only mechanism that is simultaneously
(1) behavior-preserving — bodies move byte-for-byte, so a full-run stdout-diff
stays the dispositive *behavior*-equivalence proof; (2) reviewable — no
`__setattr__` magic, the change is "patch the owning module, not the facade";
(3) single-SSOT — `REPO_ROOT`/`failures`/the seams live once in `core`, every
module does `from .core import …`, no forked copy; (4) exactly bounded — the
test-rework site count is measured, with no unmeasured residue.

A "zero-test-edit" propagating-`__setattr__` facade (Mechanism Z) was prototyped
and REJECTED: the tests load the facade via `spec_from_file_location` +
`exec_module` and never register it in `sys.modules`, so the facade cannot flip
its own `__class__` to install the propagating setter (proven by prototype). A
qualified-shared-namespace rewrite (Mechanism a/Y) was REJECTED as strictly more
expensive (it rewrites hundreds of source reads AND still needs the same
per-file test rework).

### The 3-step facade-reimport ordered deliverable (per category wave)

Each W2–W14 extraction wave, in ONE commit: (1) move the check bodies + generate
the module's `__all__`; (2) add `from .<module> import *` to the facade ABOVE
`_build_check_registry()` so the assembler's bare names resolve; (3) remove the
now-duplicated bodies from the facade. W1 applies the same shape for the
spine + seams (`from validate_checks.core import *`).

### The one non-byte-identical relocation — `REPO_ROOT`

The facade computed `REPO_ROOT = Path(__file__).resolve().parent.parent` because
the facade sits at `scripts/validate-pack.py` (two levels above the repo root).
`core.py` sits one package deeper (`scripts/lib/validate_checks/core.py`), so
reaching the repo root requires FOUR `.parent`s. Behavior preservation requires
the resolved VALUE be the repo root — a byte-identical 2-parent copy would
resolve to `scripts/lib` and break every check. Only the `.parent` depth is
adjusted; the resolved value is identical to the facade's.

## 4. The `__all__` three-source union + MUST-3 load-time order

Each module's `__all__` is the UNION of (1) tested privates, (2)
registry-referenced `check_*`, and (3) cross-module helpers, intersected with
the module's owned symbols. `from <module> import *` skips underscore names
unless `__all__` lists them; once declared, `__all__` also gates non-underscore
names, so a module that omits its own `check_*` makes registry assembly raise
`NameError`. `core.py` lists every spine symbol AND every underscore seam.

The MUST-3 contract: a module with top-level executable code defines every
dependency before the dependent statement and imports any `core` symbol it
derives from at the top. `core.py` is definitions + literals only (NO load-time
function CALLS), so it imports standalone with no `NameError`. The sole
real load-time CALL in the monolith
(`_CHECK_65_OPERATING_DOCS = tuple(_iter_operating_docs())`) travels with its
cluster (`boundary_refs`, a later wave), where the intra-module order +
`from .core import REPO_ROOT` is verified by a standalone-import gate.

## 5. The V0–V7 verification regimen

| Leg | What it proves |
|---|---|
| **V0** | every module imports standalone, no `NameError`; `core` importable first. |
| **V1** | registry equivalence: the `(number, label)` 80-tuple list is identical, identical order, vs the pre-split baseline. |
| **V2** | symbol surface: every prefix-stripped tested name `hasattr`s the facade; `_build_check_registry()` assembles with no `NameError`. |
| **V3** | failures-identity: `core.failures is <module>.failures is <facade>.failures`. |
| **V4** | full pass/fail equivalence BOTH paths (plain + `PACK_VALIDATE_DEEP=1`): exit 0 + an OK/FAIL/WARN line set byte-identical to the pre-split baseline (the dispositive behavior-equivalence proof). |
| **V5** | the full wired per-check battery green in a CLEAN checkout (no dev-tree state masks a dead patch). |
| **V6** | each moved check `--only-check N` green (the late-binding catch for lambda-wrapped registry entries). |
| **V7** | monkeypatch-efficacy NEGATIVE CONTROL: a reassigned symbol set on the OWNING module to a tree CONSTRUCTED to FAIL the check asserts FAIL; restore asserts PASS. Catches the false-GREEN class V1–V6 cannot. |

W0/W1/W15/W16 are FULL-battery shipping-boundary commits (V0–V7 + the full
96-test wired battery); the intermediate category waves run a risk-targeted
reduced battery (the user-ruled option at the planner-to-coder gate).

## 6. Placement (dependency-direction)

`scripts/lib/validate_checks/` (underscore = importable identifier) is pack-side:
NOT under `project-template/`, NOT in the `_SANCTIONED_PACK_SIDE_SHIPPED`
allowlist, with no client runtime dependency. The facade path
`scripts/validate-pack.py` is frozen (CI workflow + `checkpoint.sh` build it
from the frozen filename). This `ARCHITECTURE-BD-256.md` is a pack-side
maintenance-doc.

## 7. Push-time manifest note

`scripts/validate-pack.py` + every new `scripts/lib/validate_checks/*.py` MATCH
the `scripts/*` manifest-input glob (and no deny glob), so `manifest-sync.sh`
WILL run `build.sh` at push (it does NOT skip). The EXPECTED outcome is
MANIFEST-NOOP — the modules are copied into no fixture, so the rebuilt fixture
SHAs are unchanged → exit 0, no manifest commit. The orchestrator MUST run
`scripts/manifest-sync.sh` before `git push` and act on its exit code (0
NOOP/SKIP vs 10 CHANGED → commit the regenerated `test-fixtures/manifest.txt`
with user approval), never assuming no regen.

## 8. Realized-consumer cross-reference

This design is realized by the `validate_checks` package
(`scripts/lib/validate_checks/`):

- **`scripts/lib/validate_checks/core.py`** — the realized spine + 8 cross-module
  seams (`REPO_ROOT`, `failures`, `fail`/`ok`/`warn`, `run_check`,
  `_check_timings`, the `RUN_CHECK_*` budgets, `CHECK_REGISTRY_EXPECTED_COUNT`,
  `STREAMS`, `README`, `_session_state_load` + `_SESSION_STATE_*`,
  `_PACK_CHAT_ONLY_PERMITTED_PATHS`/`_PREFIXES`, `_TRACKER_BACKENDS`,
  `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`), with a declared
  `__all__` exporting every moved symbol including the underscore seams.
- **`scripts/validate-pack.py`** — the realized facade: re-export glue only —
  `from validate_checks.core import *` (the facade's first unguarded package
  consumer) plus the 12 cluster `import *` lines and the `singletons import *`
  line — with `_build_check_registry()`, the singletons `_build_check_registry`
  injection (`validate_checks.singletons._build_check_registry =
  _build_check_registry`, the Check-59 circular-import break), `_resolve_only_check()`,
  `main()`, and `__main__`. **Zero inline check bodies remain**: every `check_*`
  body was extracted to a module across W2–W14 (verify: `grep -nE '^def check_'
  scripts/validate-pack.py` is empty).
- **`scripts/lib/validate_checks/README.md`** — the package layout + FIRM
  CONVENTION + `__all__` rule + MUST-3 contract.
- **`scripts/lib/validate_checks/__init__.py`** — the package marker.
- **`scripts/tests/test-validate-pack-check-49-field-faithfulness.sh`** — the
  realized SHOULD-1 fix: its standalone-copy idiom (Group 3 / 3b) now writes the
  copied facade beside a real `lib/` so the facade's unguarded
  `from validate_checks.core import *` resolves.
- **The 7 W1 test-rework files** — the realized W1 symbol-move re-partition:
  after the check bodies moved to their owning modules, these tests' monkeypatch
  sites now patch the OWNING module (via the `_patch_root` helper) rather than
  the facade:
  - `scripts/tests/recommendation-state-schema-test.sh`
  - `scripts/tests/tracker-config-schema-test.sh`
  - `scripts/tests/test-validate-pack-check-77.sh`
  - `scripts/tests/test-validate-pack-check-78.sh`
  - `scripts/tests/test-validate-pack-check-79.sh`
  - `scripts/tests/test-validate-pack-check-81.sh`
  - `scripts/tests/test-validate-pack-checks-32-33-34.sh`
- **The 12 cluster modules + `scripts/lib/validate_checks/singletons.py`** — the
  realized extracted check bodies. The `check_*` bodies (extracted across
  W2–W14) live in the 12 cluster modules (`boundary_refs`, `discipline_parity`,
  `agents_skills`, `doc_concision`, `help_fragments`, `per_entry_sync`,
  `cross_bd`, `session_state`, `prompts`, `fixtures`, `examples`,
  `migrator_docs`) plus `singletons.py`. See
  `scripts/lib/validate_checks/README.md` for the authoritative cluster→check
  map (do not re-enumerate per-check here — the README is the SSOT).
- **`scripts/lib/validate_checks/wired_test_fragility.py`** (BD-222) — the first
  post-split realized consumer of the FIRM own-module-per-new-isolated-check
  convention this design established (`scripts/lib/validate_checks/README.md`
  § "The FIRM CONVENTION"). Its `check_wired_test_ci_fragility` (Check 83, the
  BD-222 wired-test CI-environment fragility guard) is a NEW genuinely-isolated
  check — it binds no non-`core` module-level symbol shared with any other check
  (its candidate set, the CI-wired `.sh` set, differs from every cluster's set),
  so it gets its OWN module rather than joining `singletons.py` (the frozen
  split-time home). This closes the reconciliation chain: the module docstring
  names the convention it realizes, and this bullet cross-references the realized
  consumer.
