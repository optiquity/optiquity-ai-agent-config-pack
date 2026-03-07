#!/usr/bin/env bash
set -euo pipefail

if command -v swift >/dev/null 2>&1; then
  echo "[agent-post-edit-check] swift found"
fi

if [ -f Package.swift ]; then
  echo "[agent-post-edit-check] package detected"
fi

echo "[agent-post-edit-check] customize this script for lint, tests, or fast validation"
