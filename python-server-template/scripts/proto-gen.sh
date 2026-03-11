#!/usr/bin/env bash
# proto-gen.sh — Generate Python gRPC code from .proto files using buf (remote plugins)
# Requires: buf CLI, grpcio-tools in the active Python environment
#
# Install buf: brew install bufbuild/buf/buf
# Install Python deps: uv add grpcio-tools (in server/ environment)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_DIR="$ROOT_DIR/proto"
OUT_DIR="$ROOT_DIR/server/src/generated"

echo "[proto-gen] Checking prerequisites..."
command -v buf >/dev/null 2>&1 || { echo "ERROR: buf not found. Install: brew install bufbuild/buf/buf"; exit 1; }

mkdir -p "$OUT_DIR"
# Ensure the generated directory is a Python package
touch "$OUT_DIR/__init__.py"

echo "[proto-gen] Running buf lint..."
(cd "$PROTO_DIR" && buf lint)

echo "[proto-gen] Generating Python code (buf remote plugins)..."
(cd "$PROTO_DIR" && buf generate)

echo "[proto-gen] Done. Generated files in: $OUT_DIR"
echo "[proto-gen] REMINDER: Add server/src/generated/ to .gitignore. Never hand-edit generated files."
