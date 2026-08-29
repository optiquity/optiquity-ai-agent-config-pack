#!/usr/bin/env bash
# Synthetic init-project.sh fragment — operand-degradation fixture for
# Check 39 / Check 41.
#
# Models an install map whose rows carry BROKEN operands: an empty
# `[class:]` and an empty `[stage:]`. A row with an empty stage operand
# contributes to NO axis, so the derived `cmd_update` set is empty and the
# check must FAIL defensively rather than PASS by vacuity.
#
# This fixture exists to lock in the defensive-failure contract: a map that
# yields no parseable axis MUST surface a FAIL, never a clean PASS. A silent
# skip here is exactly how a guard stops guarding without anyone noticing.

# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:]  [class:]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/docs/pack/prompts/*.md  ->  docs/pack/prompts/*.md  [stage:]  [class:]
# _CLIENT_INSTALLED_GLOBS_END

main() { :; }
