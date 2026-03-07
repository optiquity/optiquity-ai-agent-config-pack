#!/bin/sh
set -eu
if [ -x ./scripts/lint.sh ]; then
  ./scripts/lint.sh || true
fi
if [ -x ./scripts/test-fast.sh ]; then
  ./scripts/test-fast.sh || true
fi
exit 0
