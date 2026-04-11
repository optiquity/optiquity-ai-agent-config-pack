#!/usr/bin/env bash
# validate-proto.sh — Lint proto files and detect breaking changes against a baseline.
# Called by scripts/validate.sh when proto/ directory is detected.
# Safe to run directly for proto-only work.
#
# Set PROTO_BASELINE to override the baseline git ref (default: main).
# Example: PROTO_BASELINE=release-branch ./scripts/validate-proto.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

if [[ ! -d "proto" ]]; then
  echo "[validate-proto] proto/ directory not found"
  exit 1
fi

if ! command -v buf >/dev/null 2>&1; then
  echo "[validate-proto] WARNING: buf is not installed. Skipping proto validation."
  echo "[validate-proto] Install buf: https://buf.build/docs/installation"
  exit 0
fi

echo "[validate-proto] running buf lint"
buf lint proto/ || status=$?

# buf breaking — compare against a baseline git ref.
# Default baseline is main; override via PROTO_BASELINE env var.
BASELINE="${PROTO_BASELINE:-main}"
if git rev-parse --verify "$BASELINE" >/dev/null 2>&1; then
  echo "[validate-proto] running buf breaking against $BASELINE"
  buf breaking proto/ --against ".git#branch=$BASELINE,subdir=proto" || status=$?
else
  echo "[validate-proto] baseline ref '$BASELINE' not found — skipping buf breaking check"
  echo "[validate-proto] Set PROTO_BASELINE to a valid git ref to enable breaking-change detection."
fi

exit "$status"
