#!/usr/bin/env bash
# Pack python formatter.
set -euo pipefail
ruff format .
# project-python-format-step: also format proto-generated python.
ruff format generated_pb2/
