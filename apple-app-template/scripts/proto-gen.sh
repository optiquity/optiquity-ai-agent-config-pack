#!/usr/bin/env bash
# proto-gen.sh — Generate Swift gRPC code from .proto files using buf
# Requires: buf CLI, protoc-gen-swift, protoc-gen-grpc-swift (grpc-swift-2)
#
# Install buf:       brew install bufbuild/buf/buf
# Install plugins:   brew install swift-protobuf grpc-swift
#                    (or build grpc-swift-2 from https://github.com/grpc/grpc-swift-2)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_DIR="$ROOT_DIR/proto"
OUT_DIR="$ROOT_DIR/generated/swift"

echo "[proto-gen] Checking prerequisites..."
command -v buf >/dev/null 2>&1 || { echo "ERROR: buf not found. Install: brew install bufbuild/buf/buf"; exit 1; }
command -v protoc-gen-swift >/dev/null 2>&1 || { echo "ERROR: protoc-gen-swift not found. Install: brew install swift-protobuf"; exit 1; }
command -v protoc-gen-grpc-swift >/dev/null 2>&1 || { echo "ERROR: protoc-gen-grpc-swift not found. See https://github.com/grpc/grpc-swift-2"; exit 1; }

mkdir -p "$OUT_DIR"

echo "[proto-gen] Running buf lint..."
(cd "$PROTO_DIR" && buf lint)

echo "[proto-gen] Generating Swift code..."
(cd "$PROTO_DIR" && buf generate)

echo "[proto-gen] Done. Generated files in: $OUT_DIR"
echo "[proto-gen] REMINDER: Add generated/ to .gitignore. Never hand-edit generated files."
