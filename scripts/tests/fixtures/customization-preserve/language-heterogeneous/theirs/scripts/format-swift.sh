#!/usr/bin/env bash
# Pack swift formatter (v11).
set -euo pipefail
swift-format format -i --recursive Sources/
