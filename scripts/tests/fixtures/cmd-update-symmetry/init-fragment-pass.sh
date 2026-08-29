#!/usr/bin/env bash
# Synthetic init-project.sh fragment — PASS-path fixture for Check 39.
#
# Models the install map, the ONE declaration Check 39 derives the
# `cmd_update` axis from. Every file in the associated synthetic docs/pack/
# inventory (FOO.md, BAR.md, BAZ.md) has an explicit row tagged `cmd_update`,
# and the prompts family is declared as a GLOB row. Check 39 must report zero
# asymmetric coverage.

# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/BAR.md  ->  docs/pack/BAR.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/BAZ.md  ->  docs/pack/BAZ.md  [stage:S6,cmd_update,migrate]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/docs/pack/prompts/*.md  ->  docs/pack/prompts/*.md  [stage:S6,cmd_update,migrate]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END

main() { :; }
