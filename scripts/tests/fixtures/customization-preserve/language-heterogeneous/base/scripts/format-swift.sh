#!/usr/bin/env bash
# Pack swift formatter.
set -euo pipefail
swift-format format -i Sources/**/*.swift
