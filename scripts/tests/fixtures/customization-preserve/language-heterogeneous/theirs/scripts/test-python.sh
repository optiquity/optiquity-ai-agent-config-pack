#!/usr/bin/env bash
# Pack python test runner (v11).
set -euo pipefail
python3 -m pytest -q
