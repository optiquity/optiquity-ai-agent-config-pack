#!/usr/bin/env bash
# capability-tables.sh — single authored source of the capability → (skills,
# files, install-checks) resolution tables.
#
# SOURCEABLE-ONLY: this file defines three functions and has NO top-level
# side effects. Sourcing it defines exactly capability_skills(),
# capability_files(), and capability_install_checks(); nothing executes on
# source. Its consumer is the sibling scripts/activate-capability.sh, which
# sources this file (`source "$(dirname "$0")/capability-tables.sh"`) to
# resolve a requested capability into its skill list, conditional files,
# and tool install-checks.
#
# Adding a new capability row: extend capability_skills() AND
# capability_files() AND capability_install_checks() — three parallel
# surfaces, one capability per case branch.

# ── Capability → (skills, files) resolution table ──────────────────────────
# Mirrors the conditional-removal table, inverted.

capability_skills() {
    local cap="$1"
    case "$cap" in
        # python-data-architecture and python-observability-patterns also
        # load via marker predicates at auto-detect time. Here they are
        # added unconditionally to the language:python skill set — declaring
        # the capability explicitly (coarser tool) pulls in the full
        # Python-skill family declaratively. The marker-gated intersection
        # load (PLATFORM-SKILLS.md Intersection table) still applies at
        # PM-chat skill-selection time.
        language:python)    echo "python-best-practices python-data-architecture python-observability-patterns dependency-python" ;;
        # swift-concurrency-patterns is D1-implied for D1 ∈
        # {ios, macos} alongside swift-best-practices — every Apple
        # project deals with concurrency, no marker predicate. Added
        # to the language:swift capability row so capability-addition
        # registers the skill on the same path as
        # swift-best-practices. The companion intersection-loaded
        # skill (apple-swiftdata-patterns) remains marker-gated and
        # is NOT added here — see the apple-swiftdata-patterns
        # comment under platform:macos / platform:ios.
        language:swift)     echo "swift-best-practices swift-concurrency-patterns apple-architecture-core dependency-swift" ;;
        language:cpp)       echo "cpp-language" ;;
        language:c)          echo "c-language" ;;
        language:objc)      echo "objc-language" ;;
        # platform:macos / platform:ios add the Apple-platform
        # skill set deterministically. The companion
        # `apple-swiftdata-patterns` skill is intersection-loaded by
        # marker (`scripts/lib/detect.sh::swiftdata_marker_detected()`),
        # not by capability — a project that uses SwiftData
        # (`import SwiftData` OR `@Model`) will have the marker
        # fire and the intersection-table loader pulls in
        # apple-swiftdata-patterns alongside the platform skills
        # listed here. See PLATFORM-SKILLS.md "Intersection table".
        platform:macos)     echo "macos-architecture apple-architecture-core" ;;
        platform:ios)       echo "ios-architecture apple-architecture-core" ;;
        # Forward-declared D1 platform rows. The SKILL.md targets ship in a
        # later phase (web-architecture / android-architecture /
        # embedded-mcu-architecture); until then warn_if_missing_skills() emits
        # a stderr warning when the resolved skill directory is absent, but the
        # operation still proceeds so PM-chat-driven projects can declare D1
        # ahead of skill ship.
        platform:android)      echo "android-architecture" ;;
        platform:web-browser)  echo "web-architecture" ;;
        platform:embedded-mcu) echo "embedded-mcu-architecture" ;;
        # protocol:grpc adds grpc-patterns only. The companion
        # `protobuf-patterns` skill is intersection-loaded by marker
        # (`scripts/lib/detect.sh::protobuf_marker_detected()`), not by
        # capability — the same `.proto` files that justify a `grpc`
        # capability also trigger the marker, so intersection loading
        # picks up protobuf-patterns automatically. Standalone-protobuf
        # projects (binary file format / IPC / Twirp / Connect) load
        # protobuf-patterns via the marker without ever declaring
        # protocol:grpc. See PLATFORM-SKILLS.md "Intersection table".
        protocol:grpc)      echo "grpc-patterns" ;;
        protocol:rest)      echo "rest-patterns" ;;
        protocol:graphql)   echo "graphql-patterns" ;;
        protocol:realtime)  echo "realtime-patterns" ;;
        protocol:messaging) echo "messaging-patterns" ;;
        protocol:soap)      echo "soap-patterns" ;;
        # D5 deployment surface. `deployment:apple` is the Apple-app
        # deployment surface (a D5 deployment surface, not a D3 architectural
        # role). `deployment:linux-container` carries `deployment-python`.
        deployment:apple)             echo "deployment-apple" ;;
        deployment:linux-container)   echo "deployment-python" ;;
        # role:python-server is a legitimate D3 role token. Resolved skill
        # list per the intersection table: D2=python ∩ D3=server →
        # python-server-architecture + python-data-architecture.
        # `deployment-python` is NOT in this row; it loads via the
        # `deployment:linux-container` D5 row.
        # python-observability-patterns: the D3=server branch loads
        # observability unconditionally (alongside the marker-gated load for
        # non-server Python processes). This row encodes the explicit-D3
        # declaration path; the marker-gated intersection-table load handles
        # the auto-detect path.
        role:python-server) echo "python-server-architecture python-data-architecture python-observability-patterns" ;;
        *) return 1 ;;
    esac
}

capability_files() {
    local cap="$1"
    case "$cap" in
        language:python)
            echo "pyproject.toml pyrightconfig.json server scripts/bootstrap-python.sh scripts/format-python.sh scripts/validate-python.sh scripts/test-python.sh" ;;
        language:swift)
            echo "scripts/bootstrap-swift.sh scripts/format-swift.sh scripts/validate-swift.sh scripts/test-swift.sh" ;;
        protocol:grpc)
            echo "proto scripts/proto-gen.sh scripts/validate-proto.sh" ;;
        *) echo "" ;;
    esac
}

# ── Capability → install-check rows ────────────────────────────────────────
# Each capability emits zero or more rows of the shape:
#     <tool>:::<install-command>:::<purpose>
# where <tool> is the binary or package name probed by the discovery stage,
# and <install-command> is the concrete command the developer runs if the
# probe reports missing. Rows are newline-separated; fields are `:::`-
# delimited (not pipe — install commands themselves often contain `|` as
# an "or" separator between platform alternatives, which would break
# pipe-based parsing). Mirrors the kickoff Form-I shape
# (INSTALL-PROCEDURES.md § 7.2.3 / 7.3.1 / 7.3.2) applied at
# capability-addition time.
#
# Discovery is read-only: `command -v <tool>` for binaries; `python3 -c
# 'import <pkg>'` may be added by future rows for Python-package probes.
# The consuming script never installs anything — discovery reports status;
# the emitted PM-chat prompt repeats the install commands so Procedure 6 can
# drive Form I follow-ups under developer approval.
capability_install_checks() {
    local cap="$1"
    case "$cap" in
        language:python)
            cat <<'EOF'
python3:::see https://www.python.org/downloads/ (Python 3.12+ recommended):::Python interpreter required by scripts/bootstrap-python.sh and scripts/test-python.sh
uv:::brew install uv  (macOS) | curl -LsSf https://astral.sh/uv/install.sh | sh  (Linux):::Project-standard Python package manager (pyproject.toml workflow)
EOF
            ;;
        language:swift)
            cat <<'EOF'
swift:::install Xcode 26.3+ from the App Store, or swift.org/install for Linux:::Swift toolchain required by scripts/bootstrap-swift.sh / validate-swift.sh
swift-format:::brew install swift-format  (macOS) | swift package update + use SPM plugin (Linux):::Formatter invoked by scripts/format-swift.sh
EOF
            ;;
        platform:macos|platform:ios)
            cat <<'EOF'
xcodebuild:::install Xcode 26.3+ from the App Store:::Apple platform builds (xcodebuild + Simulator) require Xcode
xcrun:::installed alongside Xcode (no separate install):::simctl device discovery during validate-swift.sh / kickoff Procedure 7
EOF
            ;;
        platform:android)
            cat <<'EOF'
adb:::install Android Studio (https://developer.android.com/studio) which bundles platform-tools:::Android device + emulator interaction
java:::brew install --cask temurin@17  (macOS) | apt install openjdk-17-jdk  (Debian/Ubuntu):::JDK 17+ required by Android Gradle Plugin
EOF
            ;;
        platform:web-browser)
            cat <<'EOF'
node:::brew install node  (macOS) | nvm install --lts  (any platform):::Node.js runtime for web tooling and bundlers
EOF
            ;;
        platform:embedded-mcu)
            cat <<'EOF'
cmake:::brew install cmake  (macOS) | apt install cmake  (Debian/Ubuntu):::Cross-compile build orchestration for MCU targets
arm-none-eabi-gcc:::brew install --cask gcc-arm-embedded  (macOS) | apt install gcc-arm-none-eabi  (Debian/Ubuntu):::ARM Cortex-M cross compiler (adjust per MCU family)
EOF
            ;;
        language:cpp|language:c)
            cat <<'EOF'
clang:::install Xcode Command Line Tools: xcode-select --install  (macOS) | apt install clang  (Debian/Ubuntu):::C/C++ compiler
cmake:::brew install cmake  (macOS) | apt install cmake  (Debian/Ubuntu):::Build orchestration (project-typical)
EOF
            ;;
        language:objc)
            cat <<'EOF'
clang:::install Xcode 26.3+ from the App Store:::Objective-C is built by clang shipped with Xcode
EOF
            ;;
        protocol:grpc)
            # Apple-side gRPC tooling rows mirror Procedure 7 §7.3.1.
            # Python rows mirror §7.3.2 — they're emitted unconditionally
            # here because protocol:grpc is dimension-only (the table doesn't
            # know whether the project also has language:python). The
            # discovery stage probes each tool independently; missing
            # Python tools on a Swift-only project show as "skip if
            # not adding Python" in the install-hint output.
            cat <<'EOF'
buf:::brew install bufbuild/buf/buf  (macOS) | go install github.com/bufbuild/buf/cmd/buf@latest  (any platform):::Proto lint + breaking-change detection (scripts/validate-proto.sh)
protoc-gen-swift:::brew install swift-protobuf:::Swift code generator for .proto files (Apple-side; skip if no Apple target)
protoc-gen-grpc-swift:::brew install grpc-swift:::Swift gRPC code generator (Apple-side; skip if no Apple target)
grpcio-tools:::uv add grpcio-tools  (in project root) | pip install grpcio-tools:::Python proto/gRPC code generator (skip if no Python target)
grpcio:::uv add grpcio  (in project root) | pip install grpcio:::Python gRPC runtime (skip if no Python target)
EOF
            ;;
        protocol:rest|protocol:graphql|protocol:realtime|protocol:messaging|protocol:soap)
            # No machine-level installs implied; tooling is library-level
            # and lands via language-package-manager rows on the language
            # capability the project already has.
            : ;;
        deployment:apple)
            cat <<'EOF'
xcodebuild:::install Xcode 26.3+ from the App Store:::Apple-app deployment surface requires the full Xcode toolchain (archive + notarize)
EOF
            ;;
        deployment:linux-container)
            cat <<'EOF'
docker:::install Docker Desktop (https://docs.docker.com/get-docker/) or use Colima (brew install colima):::Container build + run for linux-container deployment
EOF
            ;;
        role:python-server)
            cat <<'EOF'
uv:::brew install uv  (macOS) | curl -LsSf https://astral.sh/uv/install.sh | sh  (Linux):::Project-standard Python package manager (pyproject.toml workflow)
EOF
            ;;
        *) : ;;
    esac
}
