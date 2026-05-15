#!/usr/bin/env bash
# Pack swift formatter.
set -euo pipefail
swift-format format -i Sources/**/*.swift
# project-swift-format-step: also lint generated proto stubs separately.
swift-format lint Generated/**/*.swift
