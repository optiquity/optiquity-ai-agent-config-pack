#!/usr/bin/env bash
# test-fixtures/build.sh — (re)build persistent test fixtures.
#
# Each fixture is a git repo with deterministic content (pinned
# author, email, commit dates, source-pack version SHA) so that two
# runs from the same pack state produce byte-identical fixtures.
#
# Usage:
#   build.sh --all                       Rebuild every fixture
#   build.sh --name <fixture>            Rebuild one fixture
#   build.sh --all --clean               Wipe + rebuild
#   build.sh --verify                    Compare current builds against
#                                        manifest.txt
#
# Fixtures (see README.md for the full description):
#   v10-minimal               Bare v10 install via init-project.sh
#   v10-realistic-ot          Fake-OT shape (project-name, x-agent, ollama
#                             removed, TD BACKLOG)
#   v11-flat-file             v11 install via current init-project.sh; no
#                             tracker.toml
#   v11-tracker-on            v11 install + tracker.toml mode=tracker (no
#                             live GH; for code-path tests)
#   existing-project-mid-dev  Realistic Swift+Python+gRPC in-progress
#                             project with pre-existing git history and
#                             NO pack files; input for "init --update on
#                             top of an existing project" persona test
#                             (BD-115).
#
# Reference: BACKLOG.md BD-113, BD-115.

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$THIS_DIR/.." && pwd)"

# Determinism pins. DO NOT change without bumping manifest expectations.
readonly FIXTURE_EPOCH="2026-01-01T00:00:00Z"
readonly FIXTURE_AUTHOR_NAME="Test Fixture"
readonly FIXTURE_AUTHOR_EMAIL="test@fixture"

readonly FIXTURE_NAMES=(
    "v10-minimal"
    "v10-realistic-ot"
    "v11-flat-file"
    "v11-tracker-on"
    "existing-project-mid-dev"
)

# ── Helpers ────────────────────────────────────────────────────────────────

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$1" >&2; exit "${2:-1}"; }

usage() {
    cat <<EOF
Usage: build.sh [--all | --name <fixture>] [--clean] [--verify]

Fixtures: ${FIXTURE_NAMES[*]}

  --all                Rebuild every fixture.
  --name <fixture>     Rebuild only the named fixture.
  --clean              Wipe target before building (ensures from-scratch).
  --verify             Compare HEAD SHA of each existing fixture against
                       manifest.txt; non-zero exit on mismatch.

Without --clean, a build refuses to overwrite an existing fixture
(safety; rebuild takes ~30s — surprises are bad). Combine with
--clean to force.
EOF
}

# Initialize a fresh fixture git repo at the given path. Pins the
# author / email / dates so commits are byte-identical across rebuilds.
_fixture_git_init() {
    local target="$1"
    rm -rf "$target"
    mkdir -p "$target"
    git -C "$target" init -q
    git -C "$target" config user.name  "$FIXTURE_AUTHOR_NAME"
    git -C "$target" config user.email "$FIXTURE_AUTHOR_EMAIL"
}

# Commit everything in the fixture with deterministic env. Uses
# --allow-empty so the "initial empty repo" seed commit succeeds before
# any content has been added.
_fixture_commit_all() {
    local target="$1" msg="$2"
    git -C "$target" add -A
    GIT_AUTHOR_DATE="$FIXTURE_EPOCH" \
    GIT_COMMITTER_DATE="$FIXTURE_EPOCH" \
    GIT_AUTHOR_NAME="$FIXTURE_AUTHOR_NAME" \
    GIT_AUTHOR_EMAIL="$FIXTURE_AUTHOR_EMAIL" \
    GIT_COMMITTER_NAME="$FIXTURE_AUTHOR_NAME" \
    GIT_COMMITTER_EMAIL="$FIXTURE_AUTHOR_EMAIL" \
    git -C "$target" commit -q --allow-empty -m "$msg"
}

# Run the v10-tag's init-project.sh against $target. Uses a tmp clone
# of the pack repo at v10 so we don't disturb $PACK_ROOT.
_run_v10_init() {
    local target="$1"
    local v10_src="${V10_PACK_SRC_DIR:?_run_v10_init requires V10_PACK_SRC_DIR}"
    PACK="$v10_src" bash "$v10_src/scripts/init-project.sh" "$target" <<<"y" \
        >/dev/null 2>&1
}

# Run the current pack's init-project.sh against $target.
_run_v11_init() {
    local target="$1"
    PACK="$PACK_ROOT" bash "$PACK_ROOT/scripts/init-project.sh" "$target" \
        <<<"y" >/dev/null 2>&1
}

# Set up a temp clone of the pack at the v10 tag for fixture builds
# that need v10 source files. Sets V10_PACK_SRC_DIR globally.
_setup_v10_pack_src() {
    if [[ -n "${V10_PACK_SRC_DIR:-}" && -d "$V10_PACK_SRC_DIR" ]]; then
        return 0
    fi
    V10_PACK_SRC_DIR=$(mktemp -d -t v10-pack-src.XXXXXX)
    trap '[[ -n "${V10_PACK_SRC_DIR:-}" ]] && rm -rf "$V10_PACK_SRC_DIR"' EXIT
    git clone --depth 1 --branch v10 "$PACK_ROOT" "$V10_PACK_SRC_DIR" \
        >/dev/null 2>&1
}

# ── Per-fixture builders ───────────────────────────────────────────────────

# Bare v10 install, no customizations.
_build_v10_minimal() {
    local target="$THIS_DIR/v10-minimal"
    info "  source: pack v10 tag"
    _setup_v10_pack_src
    _fixture_git_init "$target"
    _fixture_commit_all "$target" "initial empty repo"
    _run_v10_init "$target"
    _fixture_commit_all "$target" "v10 install (no customizations)"
}

# Fake-OT v10 with realistic customizations.
_build_v10_realistic_ot() {
    local target="$THIS_DIR/v10-realistic-ot"
    info "  source: pack v10 tag + FakeOT customizations"
    _setup_v10_pack_src
    _fixture_git_init "$target"
    _fixture_commit_all "$target" "initial empty repo"
    _run_v10_init "$target"
    _fixture_commit_all "$target" "v10 install"

    # Customization 1: trinity project-name fills.
    local f
    for f in CLAUDE.md AGENTS.md GEMINI.md; do
        sed -i.bak \
            -e 's/\[PROJECT_NAME\]/FakeOT/g' \
            -e 's/\[PLATFORM_TARGETS\]/iOS 17, macOS 14/g' \
            -e 's/\[TRANSPORT\]/gRPC + Proto3/g' \
            "$target/$f"
        rm -f "$target/$f.bak"
    done

    # Customization 2: remove model_providers.ollama from .codex/config.toml
    # (canonical OT case). lmstudio kept.
    if [[ -f "$target/.codex/config.toml" ]]; then
        python3 - "$target/.codex/config.toml" <<'PY'
import sys, re
p = sys.argv[1]
text = open(p).read()
text = re.sub(
    r'\n\[model_providers\.ollama\][^\[]*?(?=\n\[)',
    '\n',
    text,
    count=1,
    flags=re.DOTALL,
)
open(p, 'w').write(text)
PY
    fi

    # Customization 3: x-prefixed custom agent on all 3 CLIs.
    cat > "$target/.claude/agents/x-fakeot-domain.md" <<'EOF'
---
description: Project-specific FakeOT domain expert. Read-only review of domain models against the OT product spec.
allowed-tools: Read, Grep
---

# x-fakeot-domain agent

Project-specific custom agent for FakeOT. Reviews domain entity model
changes against the OT v0 product spec at `docs/project/SPEC.md`.

This is a custom agent — `x-` prefix means project-owned, not pack-shipped.
The pack will never overwrite this file.
EOF
    cp "$target/.claude/agents/x-fakeot-domain.md" \
        "$target/.gemini/agents/x-fakeot-domain.md"
    cat > "$target/.codex/agents/x-fakeot-domain.toml" <<'EOF'
[agents.x-fakeot-domain]
description = "Project-specific FakeOT domain expert. Read-only."
allowed_tools = ["Read", "Grep"]
prompt_file = "docs/pack/prompts/x-fakeot-domain.md"
EOF

    # Customization 4: TD-NNN BACKLOG.md.
    cat > "$target/BACKLOG.md" <<'EOF'
# FakeOT Backlog

Internal task backlog for FakeOT. TD entries (project-scoped task
definitions). Pack rule: project surface uses `TD-NNN`, pack surface
uses `BD-NNN`.

---

**TD-001 — Onboarding flow review**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: app/Sources/Onboarding/
Description: Review the onboarding flow against the OT v0 product spec.
Resolved: n/a

---

**TD-002 — gRPC connection retry policy**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: app/Sources/Network/GrpcClient.swift
Description: Today the client retries indefinitely with no backoff.
  Add jittered exponential backoff capped at 30s.
Resolved: n/a

---

**TD-003 — Settings screen empty-state copy**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: app/Sources/Settings/SettingsView.swift
Description: Empty settings screen needs an explanatory empty-state
  message instead of a blank pane.
Resolved: 2026-04-15 — empty-state copy added per design review.

---

**TD-004 — Crash on startup when network is offline**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: app/Sources/App/AppDelegate.swift
Description: The app crashes during launch when offline. Wrap the
  initial gRPC handshake in a Result and surface an offline UI.
Resolved: n/a

---

**TD-005 — Test coverage for offline mode**
Type: TODO(version)
Status: Open
Blockers: TD-004
Unblocks: None
File/Symbol: app/Tests/AppDelegateTests.swift
Description: After TD-004 lands, add a unit test that exercises the
  offline-launch path and verifies the offline UI surface.
Resolved: n/a
EOF

    _fixture_commit_all "$target" \
        "FakeOT customizations: project-name, ollama removed, x-agent, BACKLOG"
}

# Vanilla v11 install (current pack HEAD).
_build_v11_flat_file() {
    local target="$THIS_DIR/v11-flat-file"
    info "  source: pack current HEAD"
    _fixture_git_init "$target"
    _fixture_commit_all "$target" "initial empty repo"
    _run_v11_init "$target"
    _fixture_commit_all "$target" "v11 install (flat-file mode, no tracker)"
}

# v11 install + tracker.toml mode=tracker (no live GH).
_build_v11_tracker_on() {
    local target="$THIS_DIR/v11-tracker-on"
    info "  source: pack current HEAD + tracker.toml mode=tracker"
    _fixture_git_init "$target"
    _fixture_commit_all "$target" "initial empty repo"
    _run_v11_init "$target"
    _fixture_commit_all "$target" "v11 install"

    # Synthesize a tracker.toml as if pack tracker init had run.
    cat > "$target/tracker.toml" <<EOF
schema_version = 1

[backend]
name = "github"
repo = "fixture-org/fixture-repo"

[mode]
state = "tracker"
opted_in_at = "$FIXTURE_EPOCH"
opted_in_by = "$FIXTURE_AUTHOR_EMAIL"

[id_namespace]
prefix = "TD"

[migration]
mapping_file = ".pack-tracker/id-map.json"
forward_complete = true

[mirror]
enabled = true
location_backlog   = "BACKLOG.md"
location_status    = "STATUS.md"
location_changelog = "CHANGELOG.md"
regenerate_on_write = true
EOF
    mkdir -p "$target/.pack-tracker"
    echo '{}' > "$target/.pack-tracker/id-map.json"

    _fixture_commit_all "$target" \
        "tracker.toml mode=tracker (synthesized; no live GH state)"
}

# Realistic in-progress Swift+Python+gRPC project with NO pack files.
# Used as input for the BD-116 "init --update on top of existing project"
# persona test. The fixture must look like a genuine project that the
# user has been working on for a while, with multiple commits of history,
# but with zero pack-shipped files (no .claude/, .codex/, .gemini/,
# CLAUDE.md / AGENTS.md / GEMINI.md, no pack scripts).
#
# Stack rationale: pack targets Swift / Python / gRPC. We include a
# Swift Package.swift (primary) plus a small Python tooling sidecar
# and a stubbed .proto file so the fixture exercises the full target
# stack the pack is designed for.
_build_existing_project_mid_dev() {
    local target="$THIS_DIR/existing-project-mid-dev"
    info "  source: synthesized in-progress Swift+Python+gRPC project"
    info "  pack files: none (this is the pre-pack-install input shape)"
    _fixture_git_init "$target"

    # ── Commit 1: initial scaffold ─────────────────────────────────────────
    cat > "$target/.gitignore" <<'EOF'
# Build output
.build/
DerivedData/
*.xcuserstate
xcuserdata/

# Python
__pycache__/
*.py[cod]
.venv/

# Generated proto code
generated/

# OS
.DS_Store
EOF

    cat > "$target/README.md" <<'EOF'
# AcmeWidget

AcmeWidget is an in-progress Swift + Python + gRPC sample project.
It models a small widget catalog backend (Python service) with a
SwiftUI client (Sources/) and a shared Proto3 contract.

This is a deterministic test fixture representing a real project at
mid-development — before the AI agent config pack has been added.
It is NOT itself a runnable application.

## Layout

- `Sources/AcmeWidget/` — Swift client sources
- `Tests/AcmeWidgetTests/` — Swift unit tests
- `service/` — Python gRPC service + tooling
- `proto/` — shared `.proto` contracts
- `Package.swift` — Swift Package manifest

## Status

Mid-development. Catalog list flow works end-to-end; detail view and
auth flows are stubs.
EOF

    cat > "$target/Package.swift" <<'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AcmeWidget",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AcmeWidget", targets: ["AcmeWidget"]),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.21.0"),
    ],
    targets: [
        .target(
            name: "AcmeWidget",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
            ],
            path: "Sources/AcmeWidget"
        ),
        .testTarget(
            name: "AcmeWidgetTests",
            dependencies: ["AcmeWidget"],
            path: "Tests/AcmeWidgetTests"
        ),
    ]
)
EOF

    mkdir -p "$target/Sources/AcmeWidget"
    cat > "$target/Sources/AcmeWidget/Catalog.swift" <<'EOF'
import Foundation

/// In-memory catalog of widgets fetched from the gRPC service.
public struct Widget: Equatable, Sendable {
    public let id: String
    public let name: String
    public let priceCents: Int

    public init(id: String, name: String, priceCents: Int) {
        self.id = id
        self.name = name
        self.priceCents = priceCents
    }
}

public actor Catalog {
    private var widgets: [Widget] = []

    public init() {}

    public func add(_ w: Widget) {
        widgets.append(w)
    }

    public func all() -> [Widget] {
        widgets
    }
}
EOF

    mkdir -p "$target/Tests/AcmeWidgetTests"
    cat > "$target/Tests/AcmeWidgetTests/CatalogTests.swift" <<'EOF'
import XCTest
@testable import AcmeWidget

final class CatalogTests: XCTestCase {
    func testAddAndList() async {
        let c = Catalog()
        await c.add(Widget(id: "w1", name: "Sprocket", priceCents: 199))
        let all = await c.all()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, "w1")
    }
}
EOF

    _fixture_commit_all "$target" \
        "scaffold: Package.swift, README, Catalog actor + first test"

    # ── Commit 2: add Python service + proto contract ──────────────────────
    mkdir -p "$target/proto"
    cat > "$target/proto/catalog.proto" <<'EOF'
syntax = "proto3";

package acmewidget.v1;

service Catalog {
  rpc ListWidgets(ListWidgetsRequest) returns (ListWidgetsResponse);
}

message Widget {
  string id = 1;
  string name = 2;
  int32 price_cents = 3;
}

message ListWidgetsRequest {}

message ListWidgetsResponse {
  repeated Widget widgets = 1;
}
EOF

    mkdir -p "$target/service"
    cat > "$target/service/pyproject.toml" <<'EOF'
[project]
name = "acmewidget-service"
version = "0.1.0"
description = "AcmeWidget catalog gRPC service (in-progress)."
requires-python = ">=3.11"
dependencies = [
    "grpcio>=1.60",
    "grpcio-tools>=1.60",
]

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"
EOF

    cat > "$target/service/server.py" <<'EOF'
"""AcmeWidget catalog gRPC service — in-progress stub.

Real implementation will plug in the SQL store; for now we return a
hard-coded list so the Swift client has something to render during
catalog-list integration testing.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Widget:
    id: str
    name: str
    price_cents: int


SAMPLE_WIDGETS: list[Widget] = [
    Widget(id="w1", name="Sprocket", price_cents=199),
    Widget(id="w2", name="Gasket", price_cents=349),
]


def list_widgets() -> list[Widget]:
    """Return the current widget catalog. Stub — replace with SQL."""
    return list(SAMPLE_WIDGETS)


if __name__ == "__main__":
    for w in list_widgets():
        print(f"{w.id}\t{w.name}\t${w.price_cents / 100:.2f}")
EOF

    cat > "$target/service/test_server.py" <<'EOF'
"""Unit test for the catalog service stub."""
from server import list_widgets


def test_list_widgets_returns_samples() -> None:
    items = list_widgets()
    assert len(items) == 2
    assert items[0].id == "w1"
EOF

    _fixture_commit_all "$target" \
        "feat: add proto contract + Python catalog service stub"

    # ── Commit 3: in-progress detail-view work (genuine WIP shape) ─────────
    cat > "$target/Sources/AcmeWidget/DetailView.swift" <<'EOF'
import Foundation

/// Detail view for a single widget. WIP — image loading + price
/// formatting still TODO.
public struct DetailViewModel: Sendable {
    public let widget: Widget

    public init(widget: Widget) {
        self.widget = widget
    }

    public var displayPrice: String {
        // TODO: locale-aware formatting once Pricing module lands.
        "$\(Double(widget.priceCents) / 100.0)"
    }
}
EOF

    # Append a TODO note to README to make WIP shape obvious.
    cat >> "$target/README.md" <<'EOF'

## TODO (in flight)

- Detail view image loading
- Locale-aware price formatting
- Auth flow (login + session refresh)
EOF

    _fixture_commit_all "$target" \
        "wip: detail view model stub + TODO list in README"
}

# ── Dispatch ───────────────────────────────────────────────────────────────

# Run the per-fixture builder. Fail loud if name unknown.
_build_one() {
    local name="$1"
    say "── building $name ──"
    local target="$THIS_DIR/$name"
    if [[ -d "$target" && "$CLEAN" != "1" ]]; then
        die "$name already exists at $target — pass --clean to wipe + rebuild" 2
    fi
    case "$name" in
        v10-minimal)               _build_v10_minimal ;;
        v10-realistic-ot)          _build_v10_realistic_ot ;;
        v11-flat-file)             _build_v11_flat_file ;;
        v11-tracker-on)            _build_v11_tracker_on ;;
        existing-project-mid-dev)  _build_existing_project_mid_dev ;;
        *) die "unknown fixture: $name (known: ${FIXTURE_NAMES[*]})" ;;
    esac
    info "built: $target"
    info "HEAD:  $(git -C "$target" rev-parse HEAD)"
}

# Write or update manifest.txt with current SHAs.
_update_manifest() {
    local manifest="$THIS_DIR/manifest.txt"
    {
        echo "# test-fixtures/manifest.txt — expected git SHA per fixture"
        echo "# Generated by build.sh; do not hand-edit. See README.md."
        echo "# Format: <fixture-name>  <sha>"
        echo "#"
        local name target sha
        for name in "${FIXTURE_NAMES[@]}"; do
            target="$THIS_DIR/$name"
            if [[ -d "$target/.git" ]]; then
                sha=$(git -C "$target" rev-parse HEAD 2>/dev/null || echo "(missing)")
            else
                sha="(not built)"
            fi
            printf '%s  %s\n' "$name" "$sha"
        done
    } > "$manifest"
    say ""
    say "manifest written: $manifest"
}

# Verify built fixtures match manifest.
_verify() {
    local manifest="$THIS_DIR/manifest.txt"
    if [[ ! -f "$manifest" ]]; then
        die "manifest.txt missing — run build.sh --all first" 3
    fi
    local mismatch=0
    local name target expected actual
    for name in "${FIXTURE_NAMES[@]}"; do
        target="$THIS_DIR/$name"
        expected=$(awk -v n="$name" '$1 == n {print $2}' "$manifest")
        if [[ -z "$expected" || "$expected" == "(not built)" ]]; then
            warn "$name: not in manifest"
            continue
        fi
        if [[ ! -d "$target/.git" ]]; then
            warn "$name: built fixture not present locally (run --all to build)"
            mismatch=1
            continue
        fi
        actual=$(git -C "$target" rev-parse HEAD)
        if [[ "$expected" == "$actual" ]]; then
            info "$name OK: $actual"
        else
            warn "$name MISMATCH: expected=$expected actual=$actual"
            mismatch=1
        fi
    done
    return "$mismatch"
}

# ── Main ──────────────────────────────────────────────────────────────────

main() {
    local mode="" only="" CLEAN=0 VERIFY=0
    while (( $# > 0 )); do
        case "$1" in
            --all)        mode="all" ;;
            --name)       mode="one"; shift; only="${1:-}" ;;
            --clean)      CLEAN=1 ;;
            --verify)     VERIFY=1 ;;
            --help | -h)  usage; exit 0 ;;
            --*)          die "unknown option: $1 (try --help)" ;;
            *)            die "unexpected positional arg: $1 (try --help)" ;;
        esac
        shift
    done

    if (( VERIFY == 1 )); then
        _verify
        exit $?
    fi
    if [[ -z "$mode" ]]; then
        die "specify --all, --name <fixture>, or --verify (try --help)"
    fi

    if [[ "$mode" == "one" ]]; then
        [[ -z "$only" ]] && die "--name requires a fixture name"
        if (( CLEAN == 1 )); then
            CLEAN=1 _build_one "$only"
        else
            CLEAN=0 _build_one "$only"
        fi
    else
        local n
        for n in "${FIXTURE_NAMES[@]}"; do
            CLEAN="$CLEAN" _build_one "$n"
        done
    fi
    _update_manifest
}

main "$@"
