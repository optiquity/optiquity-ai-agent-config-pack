#!/usr/bin/env bash
# proto-gen.sh — Generate Swift (grpc-swift-2) and Python (grpc.aio) code from .proto files
# Requires: buf CLI, protoc-gen-swift, protoc-gen-grpc-swift (grpc-swift-2), grpcio-tools
#
# Install buf:          brew install bufbuild/buf/buf
# Install Swift plugins: brew install swift-protobuf grpc-swift
#                        (or build grpc-swift-2 from https://github.com/grpc/grpc-swift-2)
# Install Python deps:  uv add grpcio-tools (in server/ environment)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_DIR="$ROOT_DIR/proto"
SWIFT_OUT="$ROOT_DIR/generated/swift"
PYTHON_OUT="$ROOT_DIR/server/src/generated"

[[ -d "$PROTO_DIR" ]] || { echo "ERROR: proto directory not found at $PROTO_DIR"; exit 1; }

echo "[proto-gen] Checking prerequisites..."
command -v buf >/dev/null 2>&1 || { echo "ERROR: buf not found. Install: brew install bufbuild/buf/buf"; exit 1; }

SWIFT_AVAILABLE=true
command -v protoc-gen-swift >/dev/null 2>&1 || { echo "WARN: protoc-gen-swift not found — Swift generation will fail."; SWIFT_AVAILABLE=false; }
command -v protoc-gen-grpc-swift >/dev/null 2>&1 || { echo "WARN: protoc-gen-grpc-swift not found — Swift generation will fail. See https://github.com/grpc/grpc-swift-2"; SWIFT_AVAILABLE=false; }

mkdir -p "$SWIFT_OUT" "$PYTHON_OUT"
touch "$PYTHON_OUT/__init__.py"

echo "[proto-gen] Running buf lint..."
(cd "$PROTO_DIR" && buf lint)

echo "[proto-gen] Generating code..."
(cd "$PROTO_DIR" && buf generate)

echo "[proto-gen] Done."
echo "  Swift output:  $SWIFT_OUT"
echo "  Python output: $PYTHON_OUT"
echo "[proto-gen] REMINDER: Both output directories are in .gitignore. Never hand-edit generated files."
