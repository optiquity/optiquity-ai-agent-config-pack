"""validate_checks — pack structural-validation check package.

This package holds the modularized bodies of the pack structural validator.
``scripts/validate-pack.py`` is the frozen CI entrypoint and now acts as a
thin facade that imports this package; the check bodies, the shared spine
(``core``), and the per-category check modules land here across later
BD-256 extraction waves (W1+). At W0 this package is a scaffold only — it
exists so the facade's import glue resolves under both invocation paths
(``python3 scripts/validate-pack.py`` and ``spec_from_file_location``).
"""
