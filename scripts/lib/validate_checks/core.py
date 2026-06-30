"""validate_checks.core — shared validator spine (scaffold at W0).

This module will own the cross-module spine and seam symbols
(``REPO_ROOT``, ``failures``, ``fail``/``ok``/``warn``, ``run_check``,
``CHECK_REGISTRY_EXPECTED_COUNT``, the budget constants, and the 8
cross-module seams) once the spine is extracted in BD-256 wave W1. At W0
it is intentionally EMPTY of checks and spine — it exists only so the
package and the facade import glue resolve. No check bodies move here
until W1.
"""
