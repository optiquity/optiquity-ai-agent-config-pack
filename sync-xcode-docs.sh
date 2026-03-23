#!/usr/bin/env bash
# sync-xcode-docs.sh — Sync iOS AI documentation from installed Xcode into shared-docs/ios26/
#
# Run this after any Xcode update that touches the IDEIntelligenceChat framework.
# Typically: after each Xcode 26.x point release.
#
# Source: Xcode app bundle — no GitHub dependency needed.
# Output: shared-docs/ios26/ alongside this script.

set -euo pipefail

XCODE_APP="${XCODE_APP:-/Applications/Xcode.app}"
SRC="$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/shared-docs/ios26"

if [[ ! -d "$SRC" ]]; then
  echo "ERROR: AdditionalDocumentation not found at:"
  echo "  $SRC"
  echo ""
  echo "Possible causes:"
  echo "  - Xcode is not installed at $XCODE_APP"
  echo "  - This Xcode version does not include AI documentation"
  echo "  - The framework path changed in a newer Xcode version"
  echo ""
  echo "Override Xcode path: XCODE_APP=/path/to/Xcode.app $0"
  exit 1
fi

mkdir -p "$DEST"

echo "[sync-xcode-docs] Syncing from: $SRC"
echo "[sync-xcode-docs] Destination:  $DEST"
echo ""

rsync -av --delete --include="*.md" --exclude="*" "$SRC/" "$DEST/"

XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 || echo "unknown")
echo ""
echo "[sync-xcode-docs] Done. Synced from $XCODE_VERSION"
echo "[sync-xcode-docs] File count: $(find "$DEST" -name "*.md" | wc -l | tr -d ' ') markdown files"
echo "[sync-xcode-docs] Run again after each Xcode update."
