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
#   build.sh --for-contract <persona>    BD-116. Materialize a per-contract
#                                        sandbox (fresh tmp clone of the
#                                        relevant committed fixture) and
#                                        print its absolute path on stdout.
#                                        Persona ∈ {greenfield, mid-dev,
#                                        migration, existing-collision}. The
#                                        sandbox is the caller's to mutate /
#                                        drive scripts against / clean up after.
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
#   existing-project-collision  Existing-source Swift project that already
#                             OWNS a non-trinity file the pack also ships
#                             (scripts/test.sh, distinct content). Input for
#                             the BD-285 C1 collision-sidecar persona test:
#                             a fresh install leaves the user file live and
#                             writes the pack version to scripts/test.sh.pack-template.
#
# Reference: BACKLOG.md BD-113, BD-115, BD-116, BD-285.

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
    "v11-realistic-ot"
    "v11-flat-file"
    "v11-tracker-on"
    "existing-project-mid-dev"
    "existing-project-collision"
)

# ── Helpers ────────────────────────────────────────────────────────────────

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$1" >&2; exit "${2:-1}"; }

usage() {
    cat <<EOF
Usage: build.sh [--all | --name <fixture> | --for-contract <persona>] [--clean] [--verify]

Fixtures: ${FIXTURE_NAMES[*]}

  --all                       Rebuild every fixture.
  --name <fixture>            Rebuild only the named fixture.
  --clean                     Wipe target before building (ensures from-scratch).
  --verify                    Compare HEAD SHA of each existing fixture against
                              manifest.txt; non-zero exit on mismatch.
  --for-contract <persona>    BD-116. Print to stdout the absolute path of a
                              freshly-materialized sandbox suitable for
                              persona-contract scripts. Persona ∈
                              {greenfield, mid-dev, migration,
                              existing-collision}. The caller owns the
                              sandbox (must clean up).

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
    PACK="$PACK_ROOT" bash "$PACK_ROOT/scripts/init-project.sh" --yes "$target" >/dev/null 2>&1
}

# Set up a temp clone of the pack at the v10 tag for fixture builds
# that need v10 source files. Sets V10_PACK_SRC_DIR globally.
#
# BD-128 work-around: the v10 tag (v10 → v10.1) ships an
# init-project.sh whose blast_radius_sweep does NOT exclude
# PM-CHAT.md, but v10.1's PM-CHAT.md does name PROMPT-TEMPLATES.md in
# the RAG orphan-files table — so a fresh `init-project.sh` against
# the v10 tag exits 31 (EXIT_SWEEP) on every install. The fix in the
# current pack adds PM-CHAT.md to the sweep's exclude list; we cannot
# patch the v10 tag, so we apply the same one-line exclude to the
# CLONED v10 init-project.sh after clone. The patch is surgical
# (adds a single --exclude='PM-CHAT.md' to the `grep -rn` line) — it
# does not relax sweep semantics for any other file. Without this, the
# v10 fixture builds would CI-block on a v10-side bug we cannot fix
# in-tag.
_setup_v10_pack_src() {
    if [[ -n "${V10_PACK_SRC_DIR:-}" && -d "$V10_PACK_SRC_DIR" ]]; then
        return 0
    fi
    V10_PACK_SRC_DIR=$(mktemp -d "${TMPDIR:-/tmp}/v10-pack-src.XXXXXX")
    trap '[[ -n "${V10_PACK_SRC_DIR:-}" ]] && rm -rf "$V10_PACK_SRC_DIR"' EXIT
    git clone --depth 1 --branch v10 "$PACK_ROOT" "$V10_PACK_SRC_DIR" \
        >/dev/null 2>&1
    # BD-128 work-around (see function comment).
    local v10_init="$V10_PACK_SRC_DIR/scripts/init-project.sh"
    if [[ -f "$v10_init" ]] \
        && grep -q "exclude='INSTALL-PROCEDURES.md'" "$v10_init" \
        && ! grep -q "exclude='PM-CHAT.md'" "$v10_init"; then
        sed -i.bak \
            "s/--exclude='INSTALL-PROCEDURES.md'/--exclude='INSTALL-PROCEDURES.md' --exclude='PM-CHAT.md'/" \
            "$v10_init"
        rm -f "$v10_init.bak"
    fi
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

# Fake-OT realistic fixture, parameterized by pack version (BD-120).
#
# Builds a `vN-realistic-ot` fixture by:
#   1. Running the vN pack's init-project.sh into the target.
#   2. Applying the canonical OT-style customization patterns:
#        - Trinity project-name fills (CLAUDE/AGENTS/GEMINI).
#        - `model_providers.ollama` removed from .codex/config.toml.
#        - `x-`-prefixed custom agent on all 3 CLIs.
#        - TD-NNN BACKLOG.md.
#
# The four patterns are version-agnostic: they target the customization
# surface that every vN install shares. The per-version
# customization-surface ground truth lives in
# `scripts/lib/migrator-core.sh::migrator_target_surface_for_version <vN>`
# (BD-119 helper). This builder does NOT consume the helper at runtime
# — the C1–C4 paths are hardcoded inline below — so a future vN whose
# surface differs from v10/v11 (e.g., `.codex/config.toml` moves) MUST
# have the corresponding customization step updated by hand. The
# `[[ -f ]]` guard at the C2 step is a defensive no-op on missing
# files; do not rely on it to catch surface drift silently — pair any
# surface change with a re-verification of every C-step's path list
# against the helper's vN case.
#
# Per-version dispatch sites inside this function (search for
# `case "$ver" in` and `[[ "$ver" == ` to enumerate mechanically):
#   1. Source-clone setup case — only v10 needs the cloned-tag
#      work-around; v11 runs against the current pack HEAD.
#   2. Init-runner dispatch case — picks `_run_vN_init`.
#   3. C4 (TD-NNN BACKLOG.md) per-version target-path + intro-shape
#      case (added BD-160). v10 writes a root-level BACKLOG.md;
#      v11 appends the TD-NNN block to the pre-existing per-entry
#      empty-seed mirror at `docs/project/BACKLOG.md`.
#   4. Per-entry decompose / regenerate / round-trip block (added
#      BD-170), currently gated `if [[ "$ver" == "v11" ]]`.
#      Future vN whose surface includes a project-side per-entry
#      tree must extend this gate.
#
# Per-version source-pin semantics (invariant for BD-160 / BD-170 +
# future vN extension):
#   v10: source pinned to the v10 git tag via `_setup_v10_pack_src`
#        (byte-identity stable across rebuilds; same model as
#        `v10-minimal`).
#   v11: source tracks current pack HEAD via `_run_v11_init`
#        (SHA drifts with every pack-product change to v11 surface;
#        same model as `v11-flat-file` / `v11-tracker-on` — see
#        README.md "Determinism" §). When a future version freezes
#        v11 (e.g., when v12 ships and v11 becomes a frozen tag),
#        add a v11-tag-cloned source path mirroring
#        `_setup_v10_pack_src`.
#
# Add a new vN by extending EACH of the four per-version dispatch
# sites listed above, adding a `_run_vN_init` helper if the new
# version needs source-isolation different from the current pack
# HEAD, and wiring the dispatcher per the README "Realistic-OT
# fixtures: per-version pattern" subsection. The BD-120-retro F2
# die-sentinel pattern (unsupported `vN` falls through to `die 4`)
# is the safety net that catches a partial extension.
_build_realistic_for_version() {
    local ver="${1:?_build_realistic_for_version requires <vN>}"
    local target="$THIS_DIR/${ver}-realistic-ot"

    # Per-version source setup + init dispatch.
    case "$ver" in
        v10)
            info "  source: pack v10 tag + FakeOT customizations"
            _setup_v10_pack_src
            ;;
        v11)
            # BD-160 (Batch 19 commit 19f): v11 case wired against current
            # pack HEAD per the v11 source-pin semantics documented in this
            # function's header comment ("v11: source tracks current pack
            # HEAD via `_run_v11_init`"). No tag-clone setup step needed —
            # `_run_v11_init` invokes `$PACK_ROOT/scripts/init-project.sh`
            # directly. When v11.0 is tagged at Batch 24 a follow-up may
            # switch this to a v11-tag-cloned source path mirroring
            # `_setup_v10_pack_src`; that swap is tracked alongside the
            # tag-create commit, not here.
            info "  source: pack current HEAD + FakeOT customizations (v11 surface)"
            ;;
        *)
            die "_build_realistic_for_version: unsupported version: $ver" 4
            ;;
    esac

    _fixture_git_init "$target"
    _fixture_commit_all "$target" "initial empty repo"

    case "$ver" in
        v10) _run_v10_init "$target" ;;
        v11) _run_v11_init "$target" ;;
    esac
    _fixture_commit_all "$target" "${ver} install"

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
    #
    # The Claude/Codex loose per-CLI agent dirs are version-agnostic — both
    # v10 and v11 carry `.claude/agents/` + `.codex/agents/`, so the custom
    # agent always lands there. The THIRD-CLI surface is version-branched
    # (BD-221 EB-21 fix):
    #   v10 → `.gemini/agents/x-fakeot-domain.md` (carve-out i — v10 source
    #         fixtures stay Gemini-shaped as migration inputs).
    #   v11 → the Antigravity client plugin bundle
    #         `.agents-plugin/optiquity-agents/agents/x-fakeot-domain.md`.
    #         In v11 Antigravity agents ship as a plugin BUNDLE (not a loose
    #         per-CLI dir) per scripts/init-project.sh stage_s2_agents; the
    #         install stages `.agents-plugin/optiquity-agents/`, and a
    #         project-owned `x-` custom agent for the third CLI lives in that
    #         bundle's `agents/` roster (the only v11 Antigravity agent
    #         surface — detect.sh:detect_improperly_added_files documents that
    #         only the Claude/Codex loose dirs are scanned; there is no loose
    #         `.agents/agents/`).
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
    case "$ver" in
        v10)
            # carve-out (i): v10 third-CLI custom agent stays Gemini-shaped.
            cp "$target/.claude/agents/x-fakeot-domain.md" \
                "$target/.gemini/agents/x-fakeot-domain.md"
            ;;
        v11)
            # v11 Antigravity third-CLI custom agent → client plugin bundle.
            mkdir -p "$target/.agents-plugin/optiquity-agents/agents"
            cp "$target/.claude/agents/x-fakeot-domain.md" \
                "$target/.agents-plugin/optiquity-agents/agents/x-fakeot-domain.md"
            ;;
    esac
    cat > "$target/.codex/agents/x-fakeot-domain.toml" <<'EOF'
[agents.x-fakeot-domain]
description = "Project-specific FakeOT domain expert. Read-only."
allowed_tools = ["Read", "Grep"]
prompt_file = "docs/pack/prompts/x-fakeot-domain.md"
EOF

    # Customization 4: TD-NNN BACKLOG.md.
    #
    # Per-version target path:
    #   v10: $target/BACKLOG.md (root; v10 had no per-entry tree and the
    #        project backlog convention lived at the repo root).
    #   v11: $target/docs/project/BACKLOG.md (the project-side per-entry
    #        split moves project backlog under docs/project/ per
    #        ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §3.3). The v11
    #        target file already exists as the BD-166 empty-seed mirror
    #        (intro-only, produced by init-project.sh's S11 sub-step 7).
    #        We APPEND the TD-NNN block AFTER the intro so the resulting
    #        monolithic shape is identical to what the per-entry mirror
    #        generator emits from intro + per-entry tree. The BD-170
    #        decompose+regenerate step below then round-trips the file
    #        byte-identically per integration parent §12.1 + §8.7.
    #
    # The TD-NNN entry payload (intro line + 5 TD entries) is identical
    # across versions; only the target file path and the leading prose
    # differ. v10 ships its own "# FakeOT Backlog" header + paragraph.
    # v11 reuses the pack's intro (DO NOT EDIT preamble + how-to-use
    # prose from project-template/docs/project/backlog/_intro.md) and
    # appends entries after a `\n---\n\n` inter-section separator.
    local td_entries
    td_entries=$(cat <<'EOF'
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
)

    case "$ver" in
        v10)
            # v10 monolithic-at-root pattern (no per-entry tree).
            {
                cat <<'EOF'
# FakeOT Backlog

Internal task backlog for FakeOT. TD entries (project-scoped task
definitions). Pack rule: project surface uses `TD-NNN`, pack surface
uses `BD-NNN`.

---

EOF
                printf '%s\n' "$td_entries"
            } > "$target/BACKLOG.md"
            ;;
        v11)
            # v11 per-entry-split pattern (no-mirror, BD-206): build a
            # transient v10-shape monolith INPUT carrying the TD entries
            # and stash it for the per-entry decompose step below. The
            # init greenfield path ships an empty per-entry tree (no
            # monolithic mirror under the no-mirror model); the decompose
            # populates the tree from this INPUT.
            local v11_backlog_input="$target/docs/project/backlog/.bd206-fixture-input.md"
            [[ -d "$target/docs/project/backlog" ]] \
                || die "v11-realistic-ot: docs/project/backlog/ absent after init (init-project.sh S11 sub-step 6 regression?)" 4
            {
                printf '# FakeOT Backlog\n\n'
                printf 'Internal task backlog for FakeOT.\n\n---\n\n'
                printf '%s\n' "$td_entries"
            } > "$v11_backlog_input"
            ;;
    esac

    _fixture_commit_all "$target" \
        "FakeOT customizations: project-name, ollama removed, x-agent, BACKLOG"

    # ── BD-206: per-entry tree integrity (v11 only, no-mirror) ───────────
    #
    # Decompose the transient v10-shape monolith INPUT (the backlog INPUT
    # the v11 C4 step stashed) into the per-entry tree, then regenerate
    # `_toc.md`, and assert the per-entry tree + `_toc.md` are present and
    # well-formed. Under the no-mirror model there is NO monolithic mirror
    # to regenerate or byte-compare — the per-entry tree + `_toc.md` is the
    # sole SSOT and readable form (BD-206 abolishes the round-trip subject).
    #
    # Helper reuse pattern: this fixture builder shares the BD-164
    # per-entry helpers with (a) the v10→v11 migrator's
    # `_v10_to_v11_decompose_streams` adapter and (b) init-project.sh's
    # S11 greenfield-install path — no duplicated decompose / TOC logic.
    if [[ "$ver" == "v11" ]]; then
        info "  BD-206: per-entry decompose + TOC regenerate + tree integrity (no-mirror)"
        local _pe_lib_dir="$PACK_ROOT/scripts/lib/per-entry"
        [[ -d "$_pe_lib_dir" ]] \
            || die "BD-206: per-entry helpers missing at $_pe_lib_dir (BD-164 install incomplete)" 4
        # Source guard mirrors scripts/init-project.sh and
        # scripts/lib/migrate-v10-to-v11/decompose.sh's source-then-verify
        # pattern; re-sourcing is a no-op via the `type` checks inside
        # each helper file. No monolith-mirror generator sourcing (no mirror).
        # shellcheck disable=SC1091
        . "$_pe_lib_dir/_lib.sh"
        # shellcheck disable=SC1091
        . "$_pe_lib_dir/decompose.sh"
        # shellcheck disable=SC1091
        . "$_pe_lib_dir/toc-regenerate.sh"

        # Decompose the transient backlog INPUT (stashed by the v11 C4
        # step) into the per-entry tree, then drop the INPUT so it is not
        # left in the fixture.
        local _pe_backlog_dir="$target/docs/project/backlog"
        local _pe_backlog_input="$_pe_backlog_dir/.bd206-fixture-input.md"
        [[ -d "$_pe_backlog_dir" ]] \
            || die "BD-206: per-entry stream dir missing at docs/project/backlog (init S11 regression?)" 4
        if [[ -f "$_pe_backlog_input" ]]; then
            per_entry_decompose "project-backlog" "$_pe_backlog_input" "$_pe_backlog_dir" \
                || die "BD-206: per_entry_decompose failed for project-backlog" 4
            rm -f "$_pe_backlog_input"
        fi

        # Regenerate `_toc.md` for each project-side stream and assert the
        # tree + `_toc.md` are present (the no-mirror integrity property:
        # tree + TOC present + well-formed, NO mirror to diff).
        local _pe_spec _pe_key _pe_dir_rel _pe_dir
        for _pe_spec in \
            "project-backlog|docs/project/backlog" \
            "project-implementation-plan|docs/project/implementation-plan" \
            "project-changelog|docs/project/changelog"; do
            _pe_key="${_pe_spec%%|*}"
            _pe_dir_rel="${_pe_spec##*|}"
            _pe_dir="$target/$_pe_dir_rel"

            [[ -d "$_pe_dir" ]] \
                || die "BD-206: per-entry stream dir missing at $_pe_dir_rel (init S11 regression?)" 4

            per_entry_regenerate_toc "$_pe_key" "$_pe_dir" \
                || die "BD-206: per_entry_regenerate_toc failed for $_pe_key" 4

            [[ -f "$_pe_dir/_toc.md" ]] \
                || die "BD-206: _toc.md missing at $_pe_dir_rel after regenerate (no-mirror tree integrity)" 4

            info "    $_pe_key: decomposed + _toc.md present (no-mirror)"
        done

        # No-mirror invariant: the three monolithic mirrors MUST be ABSENT
        # at docs/project/ (BD-206 inversion of the BD-170 round-trip).
        local _pe_mono
        for _pe_mono in BACKLOG.md IMPLEMENTATION-PLAN.md CHANGELOG.md; do
            [[ ! -f "$target/docs/project/$_pe_mono" ]] \
                || die "BD-206: monolithic mirror docs/project/$_pe_mono present (no-mirror model forbids it)" 4
        done

        _fixture_commit_all "$target" \
            "BD-206 per-entry decomposition + TOC regenerate verified (no-mirror; project-side x3 streams)"
    fi
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
# but with zero pack-shipped files (no .claude/, .codex/, .agents/,
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

# Existing-source Swift project that already OWNS a non-trinity file the
# pack ALSO ships — a committed, executable scripts/test.sh with distinct
# (user-authored) content. Input for the BD-285 C1 collision-sidecar
# persona test.
#
# Why this shape:
#   - A language marker (Package.swift) makes classify_project_state()
#     return `existing-source`, so init-project.sh stage S5 routes every
#     project-template/scripts/* file through existing_classifier_copy()
#     (the four-case classifier, BASE absent).
#   - NO trinity files and NO AI-config dirs (.claude/.codex/.agents),
#     so classify does NOT short-circuit to `already-configured`.
#   - The pack ships project-template/scripts/test.sh; this fixture owns a
#     DIFFERENT scripts/test.sh. On install, existing_classifier_copy sees
#     dst present + differing → three_way_classify "" ours theirs →
#     `project-shadows-new-pack` → writes the pack version to
#     scripts/test.sh.pack-template and leaves the user's file byte-identical
#     (BD-285 FOLD F-1: the user file is never overwritten on a fresh
#     install collision). test.sh is committed executable so stage S5's
#     `chmod +x scripts/*.sh` is a no-op against the user's file.
#
# test.sh is the ONLY collision: the fixture ships no other pack-shipped
# path (no docs/pack, no agent-run.sh, no trinity), so a clean install
# yields exactly one `.pack-template` sidecar — the contract asserts that.
_build_existing_project_collision() {
    local target="$THIS_DIR/existing-project-collision"
    info "  source: synthesized existing-source Swift project owning a colliding scripts/test.sh"
    info "  pack files: none (pre-pack-install input shape; one shipped-path collision)"
    _fixture_git_init "$target"

    # ── Commit 1: initial scaffold ─────────────────────────────────────────
    cat > "$target/.gitignore" <<'EOF'
# Build output
.build/
DerivedData/
*.xcuserstate
xcuserdata/

# OS
.DS_Store
EOF

    cat > "$target/README.md" <<'EOF'
# AcmeTool

AcmeTool is an in-progress Swift command-line utility. This is a
deterministic test fixture representing a real project at mid-development,
before the AI agent config pack has been added. It is NOT itself a
runnable application.

The project already owns its own `scripts/test.sh` test runner (committed
long before the pack was added). The pack ships its own `scripts/test.sh`,
so this fixture exercises the fresh-install collision path: the user's
runner must be preserved and the pack version parked in a
`scripts/test.sh.pack-template` sidecar.
EOF

    cat > "$target/Package.swift" <<'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AcmeTool",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "acmetool", targets: ["AcmeTool"]),
    ],
    targets: [
        .executableTarget(
            name: "AcmeTool",
            path: "Sources/AcmeTool"
        ),
    ]
)
EOF

    mkdir -p "$target/Sources/AcmeTool"
    cat > "$target/Sources/AcmeTool/main.swift" <<'EOF'
// AcmeTool entry point — in-progress CLI stub.
import Foundation

@main
struct AcmeTool {
    static func main() {
        print("AcmeTool: nothing to do yet")
    }
}
EOF

    # The colliding file: the developer's OWN scripts/test.sh, committed
    # executable, with content that DIFFERS from the pack's shipped
    # project-template/scripts/test.sh (guaranteeing the classifier reaches
    # the project-shadows-new-pack sidecar branch rather than the
    # identical-content no-op).
    mkdir -p "$target/scripts"
    cat > "$target/scripts/test.sh" <<'EOF'
#!/usr/bin/env bash
# scripts/test.sh — AcmeTool project test runner (USER-OWNED).
#
# This is the developer's own pre-existing test script, committed before
# the AI Agent Config Pack was ever added. It intentionally differs from
# the pack's shipped scripts/test.sh so a fresh install preserves this
# file verbatim and parks the pack version at scripts/test.sh.pack-template.
set -euo pipefail

echo "AcmeTool: running project test suite"
swift test
EOF
    chmod +x "$target/scripts/test.sh"

    _fixture_commit_all "$target" \
        "scaffold: Package.swift, README, CLI stub + user-owned scripts/test.sh"
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
        v10-realistic-ot)          _build_realistic_for_version v10 ;;
        v11-realistic-ot)          _build_realistic_for_version v11 ;;
        v11-flat-file)             _build_v11_flat_file ;;
        v11-tracker-on)            _build_v11_tracker_on ;;
        existing-project-mid-dev)  _build_existing_project_mid_dev ;;
        existing-project-collision) _build_existing_project_collision ;;
        *) die "unknown fixture: $name (known: ${FIXTURE_NAMES[*]})" ;;
    esac
    info "built: $target"
    info "HEAD:  $(git -C "$target" rev-parse HEAD)"
}

# Write or update manifest.txt with current SHAs.
#
# v11-* row SHAs drift naturally with any pack-product change to v11
# surface (template files, scripts, skills, agents, etc.) — see README
# "Determinism" §. Result: a `git blame` on a v11-* manifest row often
# points at an unrelated BD that happened to run `--all` and stage the
# regenerated row. v10-* row SHAs are tag-pinned and only drift if the
# v10 tag itself moves. When committing manifest changes for a BD whose
# scope does NOT include the v11 surface, prefer staging only the
# in-scope rows to keep the BD commit's diff faithful.
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

# ── BD-116 — per-contract sandbox materialization ─────────────────────────
#
# Persona contracts (see scripts/persona-contracts/) need a fresh, writable
# starting state that mirrors the persona's input shape but does NOT mutate
# the committed test-fixtures/ tree. This helper materializes such a
# sandbox under a tmp dir and prints its absolute path on stdout.
#
# Persona → source fixture mapping:
#   greenfield  →  fresh empty git repo (no fixture; the contract drives
#                  init-project.sh against an empty, just-initialized repo
#                  to assert greenfield install correctness).
#   mid-dev     →  copy of `existing-project-mid-dev` (BD-115 fixture):
#                  realistic Swift+Python+gRPC project with pre-existing
#                  history and zero pack files. Contract asserts that
#                  running init on top preserves user files.
#   migration   →  copy of `v10-realistic-ot` (BD-120 fixture): v10 install
#                  plus the four canonical OT customizations (project-name
#                  fills, ollama removal, x-fakeot-domain agent, TD-NNN
#                  BACKLOG). Contract asserts that running the v10→v11
#                  migrator produces the expected v11 shape with all four
#                  customizations preserved (BD-088 invariants).
#   existing-collision → copy of `existing-project-collision` (BD-285
#                  fixture): existing-source Swift project that owns a
#                  colliding scripts/test.sh. Contract asserts that a fresh
#                  init preserves the user file and writes the pack version
#                  to scripts/test.sh.pack-template (C1 collision sidecar).
#
# The sandbox is a top-level git repo with deterministic identity pins
# (same env as the committed fixtures). Caller is responsible for
# `rm -rf` after use.
_materialize_for_contract() {
    local persona="${1:?_materialize_for_contract requires <persona>}"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/pack-contract-$persona.XXXXXX")
    case "$persona" in
        greenfield)
            # Fresh empty git repo; deterministic identity. The contract
            # itself runs init-project.sh against this dir.
            _fixture_git_init "$sandbox"
            _fixture_commit_all "$sandbox" "initial empty repo"
            ;;
        mid-dev)
            local src="$THIS_DIR/existing-project-mid-dev"
            [[ -d "$src/.git" ]] \
                || die "mid-dev source fixture not built; run build.sh --name existing-project-mid-dev first" 5
            # Copy the entire fixture (including .git history) so the
            # sandbox is a real git repo at the fixture's HEAD. Use cp -R
            # for BSD-compat (no GNU --preserve flags).
            rm -rf "$sandbox"
            cp -R "$src" "$sandbox"
            # Re-pin identity in the cloned repo (cp preserves config but
            # be defensive in case the source ever drifts).
            git -C "$sandbox" config user.name  "$FIXTURE_AUTHOR_NAME"
            git -C "$sandbox" config user.email "$FIXTURE_AUTHOR_EMAIL"
            ;;
        migration)
            local src="$THIS_DIR/v10-realistic-ot"
            [[ -d "$src/.git" ]] \
                || die "migration source fixture not built; run build.sh --name v10-realistic-ot first" 5
            rm -rf "$sandbox"
            cp -R "$src" "$sandbox"
            git -C "$sandbox" config user.name  "$FIXTURE_AUTHOR_NAME"
            git -C "$sandbox" config user.email "$FIXTURE_AUTHOR_EMAIL"
            ;;
        existing-collision)
            local src="$THIS_DIR/existing-project-collision"
            [[ -d "$src/.git" ]] \
                || die "existing-collision source fixture not built; run build.sh --name existing-project-collision first" 5
            rm -rf "$sandbox"
            cp -R "$src" "$sandbox"
            git -C "$sandbox" config user.name  "$FIXTURE_AUTHOR_NAME"
            git -C "$sandbox" config user.email "$FIXTURE_AUTHOR_EMAIL"
            ;;
        *)
            die "unknown contract persona: $persona (known: greenfield, mid-dev, migration, existing-collision)" 6
            ;;
    esac
    printf '%s\n' "$sandbox"
}

# ── Main ──────────────────────────────────────────────────────────────────

main() {
    local mode="" only="" persona="" CLEAN=0 VERIFY=0
    while (( $# > 0 )); do
        case "$1" in
            --all)            mode="all" ;;
            --name)           mode="one"; shift; only="${1:-}" ;;
            --for-contract)   mode="contract"; shift; persona="${1:-}" ;;
            --clean)          CLEAN=1 ;;
            --verify)         VERIFY=1 ;;
            --help | -h)      usage; exit 0 ;;
            --*)              die "unknown option: $1 (try --help)" ;;
            *)                die "unexpected positional arg: $1 (try --help)" ;;
        esac
        shift
    done

    if (( VERIFY == 1 )); then
        _verify
        exit $?
    fi
    if [[ -z "$mode" ]]; then
        die "specify --all, --name <fixture>, --for-contract <persona>, or --verify (try --help)"
    fi

    if [[ "$mode" == "contract" ]]; then
        [[ -z "$persona" ]] && die "--for-contract requires a persona name"
        _materialize_for_contract "$persona"
        return 0
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
