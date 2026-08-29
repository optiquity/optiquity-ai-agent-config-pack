#!/usr/bin/env bash
# Synthetic init-project.sh fragment — FAIL-path fixture for Check 39.
#
# Models an install map that OMITS BAZ.md (compared to the PASS fixture): the
# file installs at fresh init but no map row covers it on the `cmd_update`
# axis, so existing clients running `pack update` would silently skip it.
# Check 39 must FAIL with BAZ.md named and a `cmd_update` reference in the
# remediation.

# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/pack/FOO.md  ->  docs/pack/FOO.md  [stage:S6,cmd_update,migrate]  [class:generic]
#   project-template/docs/pack/BAR.md  ->  docs/pack/BAR.md  [stage:S6,cmd_update,migrate]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/docs/pack/prompts/*.md  ->  docs/pack/prompts/*.md  [stage:S6,cmd_update,migrate]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END

main() { :; }
