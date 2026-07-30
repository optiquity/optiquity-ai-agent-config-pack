# `validate_checks` — pack structural-validator check package

This package holds the modularized bodies of the pack structural validator.
`scripts/validate-pack.py` is the **frozen CI entrypoint** and acts as a thin
**facade** that re-imports this package; CI invokes the facade at that exact
path (the path is frozen — `.github/workflows/validate-pack.yml` and
`scripts/lib/migrate-v10-to-v11/checkpoint.sh` build it from the frozen
filename). This README is the package's layout + convention contract; the
design rationale lives in
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.

## Package layout

| File | Owns |
|---|---|
| `core.py` | The shared SPINE + the 8 cross-module SEAM symbols + the `_parse_manifest_records` cross-module helper (below). |
| `<category>.py` (16 modules) | The check bodies of one connected component — either a cluster of checks that share a non-`core` symbol (plus that cluster's private helpers + constants), OR a single genuinely-isolated check that gets its OWN module per the FIRM own-module-per-new-isolated-check convention (below). |
| `singletons.py` | The 17 genuinely-isolated checks that share no non-`core` symbol with any other check (the FROZEN split-time set — see the convention). |
| `__init__.py` | Package marker (docstring only). |
| `scripts/validate-pack.py` (the facade, NOT in this dir) | `from <module> import *` re-exports of every moved symbol, the registry assembler `_build_check_registry()`, `_resolve_only_check()`, `main()`, and `__main__`. |

`core.py` owns:

- **Spine:** `REPO_ROOT`, `failures`, `fail`/`ok`/`warn`, `run_check`,
  `_check_timings`, the `RUN_CHECK_*` budget constants, and
  `CHECK_REGISTRY_EXPECTED_COUNT`.
- **8 cross-module seams** (each read by a check in some category module via
  `from .core import …`): `STREAMS`, `README`, `_session_state_load` +
  the `_SESSION_STATE_*` constants, `_PACK_CHAT_ONLY_PERMITTED_PATHS`,
  `_PACK_CHAT_ONLY_PERMITTED_PREFIXES`, `_TRACKER_BACKENDS`,
  `_CHECK_54_REQUIRED_TOKENS`, `_CHECK_56_CANONICAL_VERBS`.
- **Cross-module helper** (promoted BD-256 W2 — its consumers span ≥2 modules,
  the same ≥2-module promotion rule the 8 seams obey): `_parse_manifest_records`
  — the `key: value` manifest parser the Check 65/67/68 allowlist loaders
  (`boundary_refs`), the Check 44/66 loaders (`doc_concision`), and Check 46
  (its owning cluster) all reuse. A single SSOT in `core` keeps every consumer
  reading one copy.

The facade imports the spine + seams with `from validate_checks.core import *`
placed ABOVE the first use, so a bare reference to `REPO_ROOT`/`failures`/
`run_check`/a seam in the still-inline check bodies (and in
`_build_check_registry()` / `main()`) resolves from the single `core` SSOT — no
forked copy.

## The FIRM CONVENTION (own-module-per-new-check)

> A NEW genuinely-isolated check (one binding no module-level symbol shared with
> another check except the `core` spine) gets its OWN module file
> `scripts/lib/validate_checks/<name>.py` by default. Do NOT add new isolated
> checks to `singletons.py` — that file is the FROZEN home of the 17 checks
> isolated at the BD-256 split; growing it re-creates the edit-collision BD-256
> dissolved. A new check that SHARES a non-core symbol with an existing check
> joins that check's module.

This convention governs FUTURE checks. The 17 existing isolated checks stay
pooled in `singletons.py` (the split-time set); do NOT split them into 17 files.

## The `__all__` three-source-union rule

Each module declares an `__all__` that is the UNION of three MEASURED sources,
intersected with the module's OWNED symbols:

1. **Tested privates** — the underscore symbols any wired test monkeypatches on
   this module (`mod._SYM`).
2. **Registry-referenced `check_*`** — every `check_*` the facade's
   `_build_check_registry()` references that this module owns.
3. **Cross-module helpers** — any helper another module or the facade resolves
   FROM this module.

Why a declared `__all__` is mandatory: `from <module> import *` skips underscore
names UNLESS they are listed in `__all__`. Once `__all__` is declared, it ALSO
gates non-underscore names — so a module declaring `__all__ = [<privates>]` but
omitting its own `check_*` makes the facade's registry assembly raise
`NameError`. `core.py` therefore lists every spine symbol AND every underscore
seam in its `__all__`.

## The MUST-3 load-time-order contract

A module with top-level executable code (a load-time derivation or a load-time
function CALL) MUST define every symbol it depends on BEFORE the dependent
statement, and MUST import any `core` symbol it derives from at the top of the
module. Concretely:

- A symbol derived at load time from another (`README = REPO_ROOT /
  "README.md"`, `STREAMS`, the `_SESSION_STATE_*` block) is defined AFTER what
  it derives from.
- `core.py` is **definitions + literals only** — it has NO load-time function
  CALLS, so it imports standalone with no `NameError`.
- A category module with a load-time CALL (e.g. `boundary_refs.py`'s
  `_CHECK_65_OPERATING_DOCS = tuple(_iter_operating_docs())`) places that call
  AFTER its helper defs + its `from .core import REPO_ROOT`, and is verified by
  a standalone-import gate (`python3 -c "import validate_checks.<module>"` with
  no `NameError`).

## Further reading

Design rationale (the seam analysis, the verbatim-bodies mechanism, the V0–V7
verification regimen, the placement/dependency-direction analysis):
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-256.md`.
