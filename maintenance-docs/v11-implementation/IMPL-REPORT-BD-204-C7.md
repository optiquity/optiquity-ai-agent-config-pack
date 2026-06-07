# IMPL-REPORT — BD-204 C-7 (Part 7a: author the lossless oracle test + fixture)

- **BD:** BD-204 — Pack self-migration Phase 2 (tracker Mode-2↔3). Commit C-7 (7 of 8).
- **Scope:** PACK-ONLY. Part 7a only — AUTHOR the §3.2 lossless oracle test + the 3-case
  suffix-free fixture, committed. The MANUAL live round-trip run (7b) is SEPARATE and
  user-gated; it was NOT run here.
- **Branch:** v11-dev
- **Pre-flight HEAD / Final HEAD:** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (unchanged —
  agents-never-commit; edits left in the working tree).
- **PREFLIGHT line emitted:** `PREFLIGHT: 2/2 in-scope edits complete; verification PASS;
  HEAD feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53; about to Write IMPL-REPORT to
  maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C7.md`.

---

## 1. Live round-trip NOT run — deferred to 7b

**The live GH round-trip proof was NOT performed in this task.** No `gh repo create`,
`gh issue create`, `gh repo delete`, and no `PACK_TRACKER_LIVE_GH=1` invocation were run.
The live scratch-repo round-trip is Part 7b — a separate, user-gated MANUAL run with
per-step `gh` approval (`test-infra-self-provisioned`). 7a's verification is bounded to:
syntax, the default-SKIP path, fixture well-formedness, `validate-pack.py`, and the existing
unattended mock battery — all reported below.

---

## 2. What was built

### 2.1 New test — `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`

The §3.2 lossless oracle as a runnable scratch-repo test. Flow (manual/gated path only):
provision a personal-account scratch repo via `gh repo create` → install the form family
(copy `.github/ISSUE_TEMPLATE/{work-item,inbound,config}.yml` into the working copy) → seed
the fixture per-entry tree (BD-only pre-filter + `per_entry_decompose "pack-backlog"`) →
run `tree → Issues → tree` (`tracker_migrate_forward_run` then `tracker_migrate_reverse_run`)
→ assert the six §3.2 oracle legs → `gh repo delete` (trap-on-exit cleanup + explicit delete
+ a gone-assertion).

The six oracle legs implemented (§3.2 / RECON §3):

| Leg | Assertion |
|---|---|
| 1 Count | `count(BEFORE BD-*.md, ^BD-\d+\.md$)` == `count(AFTER)` == `count(pack-owned Issues)` — pack-owned lane = the `bd-entry` label only; inbound excluded. DYNAMIC (measured live, never hard-coded). |
| 2 Identity | SET of pack-ids BEFORE == AFTER == SET of `pack-id` markers across pack-owned Issues (read from each Issue body comment). |
| 3 Content-faithfulness | per entry, `diff` of original span vs reconstructed span (both back-pointer-stripped via `pe_strip_backpointer_stdin`) is EMPTY. The large multi-block entry (BD-903) diffs clean. |
| 4 Status | status distribution BEFORE == AFTER; explicit Deferred canary (BD-902 must stay `Deferred`, not `Open`). |
| 5 No-monolith / no-sidecar | `! -f pack-ops/BACKLOG.md` throughout; no `.pack-tracker/reverse.sidecar.*`; `_toc.md` regenerated (DP-4). |
| 6 Repeated-cycle + interleaved CRUD | on/off/on/off converges to original; then `provider_create` a new BD-904 + `provider_update` BD-901 status→resolved → reverse → assert BD-904 appears + BD-901 round-trips to `Resolved`. |

**MANUAL-ONLY + default-SKIP guard is the test's FIRST action** (RECON §3.3/§E): if
`PACK_TRACKER_LIVE_GH` is unset/empty OR `gh` is absent OR `gh auth status` is not OK →
print exactly `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` and
`exit 0`. The guard reuses the suite's existing `command -v gh` / `gh auth status` preflight
idiom (property-fit, not invented). The library `source` block and ALL `gh repo create`
code sit BELOW the guard — an unattended invocation can never reach `gh repo create`.

**Not wired into CI** (the PRIMARY control): the test is NOT added to
`.github/workflows/validate-pack.yml` or any unattended run-all list. Verified clean
(`grep -rn "tracker-bd204-lossless" .github/workflows/` → no match).

### 2.2 New fixture — `scripts/tests/fixtures/tracker-bd204-lossless/`

- `BACKLOG.md` — three suffix-free stress cases (collision-safe BD numbers, well above the
  live max of 211):
  - **BD-901** — parenthetical-TITLE entry: `**BD-901 — Parenthetical-title stress entry (Code Red 3)**`
    (post-em-dash parenthetical only — admissible title text; NOT a pre-em-dash qualifier and
    NOT a letter suffix, either of which would FAIL `_CANON_HEADER_RE` and the engine filename
    regex).
  - **BD-902** — `Status: Deferred` entry (the DP-3 round-trip canary).
  - **BD-903** — large multi-block entry whose `Description:` carries multi-line
    `Segments:`/`Steps:`/`State:`/`Goal:`/`Scope:` prose sub-blocks (see §4 POQ for why these
    ride INSIDE `Description` as continuation text — that is the form in which they round-trip
    verbatim through the current forward parser).
- `tracker.toml` — live tracker mode (`mode.state = "tracker"`, `forward_complete = true`),
  NO `[mirror]` table (no-monolith model). `backend.repo` is an `@@SCRATCH_REPO@@` placeholder
  the test binds to the live scratch slug at runtime.

### 2.3 No migrator/library change

Per RECON §A the migrator is ALREADY canonical (suffix-free). NO edit was made to any
`scripts/lib/tracker-*.sh`. C-7 is test + fixture only.

---

## 3. Bounded-verification evidence (the FULL applicable 7a battery)

### 3.1 Syntax + shellcheck

```
$ bash -n scripts/tests/tracker-bd204-lossless-roundtrip-test.sh
SYNTAX OK
$ shellcheck ... → not installed in this environment (skipped; repo CI does not run shellcheck on tests)
```

### 3.2 Default-SKIP path (the fail-safe), run UNATTENDED

```
$ unset PACK_TRACKER_LIVE_GH; bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh
OUTPUT: [SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)]
RC: 0
```
Exact SKIP line + `exit 0`. This is the ONLY way the test was executed in 7a.

### 3.3 Fixture well-formedness (real engine, not eyeballed)

```
$ per_entry_decompose "pack-backlog" <bd-only fixture> <tmp/backlog>
per-entry decompose: wrote 3 entry file(s)   →  BD-901.md  BD-902.md  BD-903.md
# each line-2 header vs _CANON_HEADER_RE (^\*\*(?:BD|TD)-\d+ — .+\*\*$):
OK **BD-901 — Parenthetical-title stress entry (Code Red 3)**
OK **BD-902 — Deferred-status round-trip canary**
OK **BD-903 — Large multi-block entry with rich body**
# forward parse (tmf_parse_backlog_tree "pack-backlog"):
BD-901 status=Open ; BD-902 status=Deferred ; BD-903 status=Open
# BD-903 Description captures Segments:/Steps:/State:/Goal:/Scope: as continuation text (verbatim)
```

### 3.4 `validate-pack.py`

```
$ python3 scripts/validate-pack.py   →   RC=0   →   "PASSED — all checks clean"
```
(Check 36 is post-commit / diff-based; the pre-commit checks pass. Check 32′ scans only the
STREAMS dirs e.g. `backlog/`, not `scripts/tests/fixtures/`, so the fixture is not subject to
`_CANON_HEADER_RE` by the validator — it is nonetheless well-formed per §3.3.)

### 3.5 Full unattended battery (enumerated from `.github/workflows/validate-pack.yml`, NOT a hand-picked subset)

All 51 enumerated `bash ...` test invocations were run; the new oracle is correctly NOT
among them and is not added.

- Batch 1 (22 tests): `passed=22 failed:[]`
- Batch 2 (29 tests): `passed=29 failed:[]`
- Total: **51/51 PASS** (incl. `test-v11-realistic-ot.sh` banner-pinning,
  `tracker-migrate-forward/reverse/roundtrip-test.sh`, and all `test-validate-pack-check-*`).

Enumerated set (sorted, deduped) — every entry ran green:
`scripts/test-detect.sh, test-migrator-capability-translation.sh, test-migrator-core.sh,
test-migrator-manifest.sh, test-migrator-skills.sh, test-persona-contracts.sh;
scripts/tests/{pack-help-test, recommendation-state-schema-test, recommendation-test,
template-translations-test, template-version-test, test-customization-preserve,
test-init-project, test-issue-forms, test-migrate-v10-to-v11-decompose,
test-migrate-v10-to-v11-dry-run, test-migrate-v10-to-v11-gates, test-migrate-v10-to-v11,
test-per-entry, test-tracker-cycle-check, test-tracker-links, test-tracker-phase-task,
test-v11-realistic-ot, test-validate-pack-check-16/18/19/39/40/41/42/43/44/45/46,
test-validate-pack-check-removed-doc-advisory, test-validate-pack-checks-32-33-34,
test-validate-pack-checks-36-37-38, tracker-agent-read-test, tracker-bd129-gh-repo-test,
tracker-bd130-doctor-wired-test, tracker-bd132-race-test, tracker-bd133-header-preservation-test,
tracker-bd134-close-retry-test, tracker-config-schema-test, tracker-config-test,
tracker-errors-test, tracker-init-test, tracker-migrate-forward-test,
tracker-migrate-reverse-test, tracker-migrate-roundtrip-test, tracker-provider-test}.sh`.

### 3.6 Manifest (regenerate-manifest-v11-surface)

`scripts/` is a v11-surface dir, so I ran `bash test-fixtures/build.sh --all --clean` (RC=0).
The resulting `git status --short test-fixtures/manifest.txt` / `git diff --stat` are EMPTY —
the manifest tracks shipped surfaces, not `scripts/tests/` test/fixture files, so the new
files produce no manifest delta. Nothing to stage. (Working tree after build shows only the
two new deliverables untracked — the build dirtied nothing else.)

---

## 4. New POQ introduced (surfaced, not silently fixed)

**POQ-C7-1 — "ride the Issue body verbatim" for arbitrary named sub-blocks.** PLAN §C-7
and ARCHITECTURE §3.2 describe the large-entry stress case as `Segments:`/`Steps:`/`State:`/
`Goal:`/`Scope:` blocks that "ride the Issue body verbatim" / via the in-body
`pack-extra-fields` carrier. **Measured reality:** the forward parser
(`_tmf_parse_backlog_file`, `FIELD_LINE` + a FIXED `mapping` dict) recognizes ONLY
`type/status/blockers/unblocks/file-symbol/description/context/resolution/resolved`; an
UNRECOGNIZED top-level field label (`Segments:`, `Steps:`, `State:`, `Goal:`) sets
`field_being_collected = None` and is DROPPED at parse — it does NOT survive forward. The
reverse `extra_fields` carrier is documented "absent today until the reverse decode populates
it" (`tracker-migrate-reverse.sh _tmr_emit_pack_tree`), i.e. not yet wired for arbitrary
named blocks. **Disposition (per plan's recommended default + boundary discipline — no
architecture change):** the fixture places the `Segments:/Steps:/State:/Goal:/Scope:` prose
INSIDE `Description:` as continuation lines, which DOES round-trip verbatim through the
current machinery (confirmed in §3.3 — the parser captures them as Description continuation
text, and `_tmr_emit_pack_tree` re-emits Description verbatim). The fixture therefore still
exercises a large multi-block body that diffs clean. If a future BD wants TOP-LEVEL
`Segments:`-style fields to be first-class round-trip carriers, that is a forward-parser +
`extra_fields` carrier change requiring an architect pass — surfaced here, not designed.
This is consistent with the plan's content-faithfulness oracle (the body diffs clean) and
does not weaken the oracle.

No other POQs. No deviations from the §C-7 recipe otherwise.

---

## 5. Plan deviations

**Zero recipe deviations.** Every §C-7 / RECON §3 requirement implemented as specified:
filename verified unique; three suffix-free stress cases (no suffix case); post-em-dash
parenthetical only; default-SKIP guard as first action with the exact SKIP string; not wired
into CI; live-scratch self-provisioning with trap cleanup; six oracle legs; no migrator/lib
edit. The only design-judgment call (POQ-C7-1) is documented above and follows the plan's
"diff clean" intent.

---

## 6. Boundary discipline check

- `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (NEW) — pack-side test infra.
  No project-side SSOT applies (pack test runner). No reference added to any project-side
  surface; no pack-only concept leaked to a project surface (the file IS pack-only). No
  `project-template/` / `supporting-docs/` touched.
- `scripts/tests/fixtures/tracker-bd204-lossless/*` (NEW) — pack-side test fixture; same
  disposition. No SSOT exists for an ad-hoc test fixture — implemented per the prompt with
  no SSOT augmentation.
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C7.md` (NEW) — pack-side
  maintenance doc (the deliverable report). Pack-only.

No project-side file was edited. No boundary-discipline STOP condition arose (no edit added a
reference to a pack-only file on a project surface — all edits are pack-side).

---

## 7. Definition-of-Done checklist

| Item | Result |
|---|---|
| Filename uniqueness verified before naming | PASS (`find` → empty before write) |
| New test authored with the 6 §3.2 oracle legs | PASS |
| Default-SKIP guard is the test's FIRST action; exact SKIP string + exit 0 | PASS (§3.2) |
| Test NOT in any `.github/workflows/` or unattended run-all list | PASS (grep clean) |
| 3-case suffix-free fixture (parenthetical-title / Deferred / large multi-block) | PASS |
| Fixture suffix-free + post-em-dash parenthetical only; headers pass `_CANON_HEADER_RE` | PASS (§3.3) |
| Collision-safe fixture BD numbers (901/902/903 vs live max 211) | PASS |
| NO migrator/lib change (`scripts/lib/tracker-*.sh` untouched) | PASS |
| `bash -n` clean | PASS |
| SKIP path run unattended → exact line, exit 0 | PASS |
| `validate-pack.py` green | PASS |
| FULL enumerated unattended battery green (51/51); oracle SKIPs / is absent | PASS |
| Manifest regenerated; staged IF non-empty | PASS (regen RC=0; diff empty → nothing to stage) |
| Live round-trip NOT run (deferred to 7b) | PASS (no `gh repo`/issue ops, no LIVE env) |
| No git state change | PASS (HEAD unchanged) |
| PREFLIGHT emitted only after all verification PASS | PASS |

---

## 8. Files changed inventory

| Path | Change type |
|---|---|
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | new |
| `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md` | new |
| `scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml` | new |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C7.md` | new (this report) |

`test-fixtures/manifest.txt` — regenerated (RC=0) but NO diff → NOT a changed file.

Full new-file contents are reproduced in §9 so Pack Chat can re-apply without re-deriving.

---

## 9. Full contents of new files

### 9.1 `scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml`

```toml
schema_version = 1

[backend]
name = "github"
repo = "@@SCRATCH_REPO@@"

[mode]
state = "tracker"

[id_namespace]
prefix = "BD"

[migration]
forward_complete = true
mapping_file = ".pack-tracker/id-map.json"
```

### 9.2 `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md`

```
**BD-901 — Parenthetical-title stress entry (Code Red 3)**
Type: feat
Status: Open
Blockers: None
Unblocks: None
File/Symbol: scripts/lib/tracker-migrate-forward.sh
Description: Exercises the round-trip of a post-em-dash parenthetical
  TITLE qualifier. The parenthetical `(Code Red 3)` is admissible title
  text AFTER the em-dash (the live exemplar is BD-195), NOT a pre-em-dash
  qualifier — a pre-em-dash parenthetical or a letter suffix would FAIL
  validate-pack's _CANON_HEADER_RE and the shared engine filename regex.
Resolved: n/a

---

**BD-902 — Deferred-status round-trip canary**
Type: feat
Status: Deferred
Blockers: None
Unblocks: None
File/Symbol: scripts/lib/tracker-migrate-reverse.sh
Description: The Deferred status is the round-trip canary for the DP-3
  gap-fix. Forward encodes Deferred as open + status:deferred (C-5); reverse
  decodes status:deferred back to Deferred (C-1). A Deferred entry that
  round-trips to Open FAILS this oracle and blocks the C-8 flip.
Resolved: n/a

---

**BD-903 — Large multi-block entry with rich body**
Type: feat
Status: Open
Blockers: BD-901, BD-902
Unblocks: None
File/Symbol: scripts/lib/tracker-migrate-forward.sh
Description: A large multi-block entry whose body carries several
  structured prose sub-blocks that must ride the Issue body verbatim and
  diff clean after the tree to Issues to tree round-trip.
  Segments: forward read enumerates the per-entry tree; reverse emit writes
    the per-entry tree; both directions are monolith-free.
  Steps: 1 provision scratch repo; 2 install the form family; 3 seed the
    fixture tree; 4 run forward then reverse; 5 assert the six oracle legs;
    6 delete the scratch repo.
  State: this entry exercises the content-faithfulness leg — its
    multi-line body must reconstruct byte-identical (back-pointer stripped).
  Goal: prove the large-entry body survives the carrier (the form family
    plus the Issue body) without a sidecar file.
  Scope: pack backlog tree to GH Issues and back; no project-side surface.
Resolved: n/a

---
```

### 9.3 `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`

```bash
#!/usr/bin/env bash
# pack-internal: true  (manual/gated live-GH oracle; not a CI test runner)
# scripts/tests/tracker-bd204-lossless-roundtrip-test.sh — BD-204 C-7.
#
# The §3.2 lossless round-trip ORACLE as a runnable scratch-repo test:
# proves that `per-entry tree → GH Issues → per-entry tree` is LOSSLESS
# on the three post-BD-211 stress cases (parenthetical-title entry, a
# Deferred entry, a large multi-block entry). This is the C-8 dress
# rehearsal — it self-provisions a LIVE personal-account scratch repo via
# `gh`, runs forward then reverse against it, asserts the six §3.2 oracle
# legs, then deletes the scratch repo.
#
# CI-EXECUTION MODEL — MANUAL-ONLY + default-SKIP guard (ARCHITECTURE
# §3.4 / RECON §E):
#   - This test is the FIRST and ONLY live-repo test in the pack. Every
#     OTHER tracker test mocks `gh` (no live GitHub state). It is NOT
#     wired into any .github/workflows/ file or any unattended run-all
#     test list — that is the PRIMARY control.
#   - The default-SKIP guard below is the fail-safe: if PACK_TRACKER_LIVE_GH
#     is unset/empty OR `gh auth status` is not OK, the test prints
#     `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`
#     and exits 0. So even if a generic sweep invokes it unattended, it
#     can NEVER reach `gh repo create`.
#
# USAGE (manual, gated):
#   PACK_TRACKER_LIVE_GH=1 bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh
# with `gh` authenticated. The scratch repo is created + deleted in the
# same run (trap-on-exit + explicit `gh repo delete`); never touches the
# real pack repo (test-infra-self-provisioned).

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURE_DIR="$REPO_ROOT/scripts/tests/fixtures/tracker-bd204-lossless"

# ─────────────────────────────────────────────────────────────────
# Default-SKIP guard — the test's FIRST action (RECON §3.3 / §E).
# Require BOTH the explicit opt-in env var AND authenticated gh.
# ─────────────────────────────────────────────────────────────────
if [[ -z "${PACK_TRACKER_LIVE_GH:-}" ]] || ! command -v gh >/dev/null 2>&1 \
   || ! gh auth status >/dev/null 2>&1; then
    echo "SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)"
    exit 0
fi

# ─────────────────────────────────────────────────────────────────
# Below this line runs ONLY in the manual/gated path (7b). The
# unattended battery never reaches it (it SKIPs above).
# ─────────────────────────────────────────────────────────────────

PASS=0
FAIL=0
t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }
assert_eq() { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }

# Source the libs (same load order as the round-trip orchestrators use).
# shellcheck disable=SC1091
source "$LIB_DIR/per-entry/_lib.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/per-entry/decompose.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-errors.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-config.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-provider-gh.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-labels.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-mirror.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"

# ─────────────────────────────────────────────────────────────────
# Scratch-repo provisioning + cleanup contract (test-infra-self-
# provisioned). The scratch repo is created in the user's personal
# account and DELETED in the same run via the EXIT trap + an explicit
# delete at the end; the test asserts it is gone.
# ─────────────────────────────────────────────────────────────────
GH_USER=$(gh api user --jq .login 2>/dev/null) || { echo "FATAL: cannot read gh user"; exit 2; }
SCRATCH_NAME="pack-bd204-oracle-$$-$(date +%s)"
SCRATCH_REPO="$GH_USER/$SCRATCH_NAME"
WORKDIR=$(mktemp -d -t bd204-oracle.XXXXXX)
SCRATCH_CREATED=0

_cleanup() {
    if [[ "$SCRATCH_CREATED" -eq 1 ]]; then
        gh repo delete "$SCRATCH_REPO" --yes >/dev/null 2>&1 || true
    fi
    rm -rf "$WORKDIR"
}
trap _cleanup EXIT

printf "\n=== Provision scratch repo %s ===\n" "$SCRATCH_REPO"
# Local working copy that becomes the scratch repo (private).
LOCAL_WC="$WORKDIR/wc"
mkdir -p "$LOCAL_WC/pack-ops" "$LOCAL_WC/backlog" "$LOCAL_WC/.pack-tracker" \
         "$LOCAL_WC/.github/ISSUE_TEMPLATE"

# Install the form family (the LOCKED GH structured-intake realization).
cp "$REPO_ROOT/.github/ISSUE_TEMPLATE/work-item.yml" "$LOCAL_WC/.github/ISSUE_TEMPLATE/"
cp "$REPO_ROOT/.github/ISSUE_TEMPLATE/inbound.yml"   "$LOCAL_WC/.github/ISSUE_TEMPLATE/"
cp "$REPO_ROOT/.github/ISSUE_TEMPLATE/config.yml"    "$LOCAL_WC/.github/ISSUE_TEMPLATE/"

# Seed the fixture per-entry tree (decompose the BD-only fixture monolith;
# the `pack-backlog` regex filters to BD-* — the SAME pre-filter the
# round-trip integration test uses so non-BD blocks never glom onto a BD
# file). The pack-ops/ marker makes tracker_config_auto_surface return
# "pack"; under the no-monolith model NO pack-ops/BACKLOG.md is written.
BD_ONLY="$WORKDIR/bdonly.md"
python3 - "$FIXTURE_DIR/BACKLOG.md" > "$BD_ONLY" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
blocks = re.split(r'\n---\n', text)
out = [b.strip() for b in blocks if re.search(r'^\*\*BD-\d{3}', b.strip(), re.M)]
sys.stdout.write('\n\n---\n\n'.join(out) + '\n\n---\n')
PY
per_entry_decompose "pack-backlog" "$BD_ONLY" "$LOCAL_WC/backlog" >/dev/null

# Live tracker.toml (no [mirror] table — the no-monolith model). The
# fixture toml carries an @@SCRATCH_REPO@@ placeholder; bind it to the
# live scratch slug.
sed "s|@@SCRATCH_REPO@@|$SCRATCH_REPO|g" "$FIXTURE_DIR/tracker.toml" \
    > "$LOCAL_WC/tracker.toml"

# Snapshot the ORIGINAL tree (back-pointer stripped) for the content-
# faithfulness oracle and the canonical BEFORE count/identity/status.
ORIG_DIR="$WORKDIR/orig"
mkdir -p "$ORIG_DIR"
cp "$LOCAL_WC"/backlog/BD-*.md "$ORIG_DIR/"

# Canonical count regex (BD-211 suffix-free; measured live, never hard-coded).
_canon_count() { ls "$1" 2>/dev/null | grep -cE '^BD-[0-9]+\.md$'; }
_canon_ids()   { ls "$1" 2>/dev/null | grep -E '^BD-[0-9]+\.md$' | sed 's/\.md$//' | sort; }
_status_dist() {
    # status distribution across BD-*.md files: "<Status>\t<count>" sorted.
    grep -hE '^Status: ' "$1"/BD-*.md 2>/dev/null \
        | sed 's/^Status: //' | sort | uniq -c \
        | awk '{print $2"\t"$1}' | sort
}

COUNT_BEFORE=$(_canon_count "$ORIG_DIR")
IDS_BEFORE=$(_canon_ids "$ORIG_DIR")
STATUS_BEFORE=$(_status_dist "$ORIG_DIR")

# Create the live scratch repo from the local working copy (per-step gh).
( cd "$LOCAL_WC" \
  && git init -q . \
  && git add -A \
  && git -c user.email=oracle@example.com -c user.name=oracle commit -q -m "seed" \
  && gh repo create "$SCRATCH_REPO" --private --source=. --push ) \
  || { echo "FATAL: gh repo create failed"; exit 2; }
SCRATCH_CREATED=1
export GH_REPO="$SCRATCH_REPO"
t_pass "0.1 scratch repo provisioned ($SCRATCH_REPO)"

# ─────────────────────────────────────────────────────────────────
# Run: tree → Issues (forward) → tree (reverse).
# ─────────────────────────────────────────────────────────────────
printf "\n=== Run forward (tree → Issues) ===\n"
fwd_out=$(tracker_migrate_forward_run "$LOCAL_WC" 0 0 0 2>&1); fwd_rc=$?
assert_eq "1.1 forward rc=0" "0" "$fwd_rc"
[[ "$fwd_rc" -ne 0 ]] && { printf "%s\n" "$fwd_out"; }

printf "\n=== Run reverse (Issues → tree) ===\n"
rev_out=$(tracker_migrate_reverse_run "$LOCAL_WC" 0 0 0 0 2>&1); rev_rc=$?
assert_eq "1.2 reverse rc=0" "0" "$rev_rc"
[[ "$rev_rc" -ne 0 ]] && { printf "%s\n" "$rev_out"; }

AFTER_DIR="$LOCAL_WC/backlog"

# ─────────────────────────────────────────────────────────────────
# §3.2 oracle leg 1 — COUNT oracle.
# count(BEFORE) == count(AFTER) == count(pack-owned Issues).
# Pack-owned lane = the `bd-entry` label (the migrated work-item lane);
# inbound/needs-triage issues are excluded.
# ─────────────────────────────────────────────────────────────────
printf "\n=== Oracle leg 1: count ===\n"
COUNT_AFTER=$(_canon_count "$AFTER_DIR")
ISSUES_JSON=$(provider_list "$(jq -nc '{label:"bd-entry", state:"all"}')" 200 2>/dev/null)
ISSUE_COUNT=$(printf '%s' "$ISSUES_JSON" | jq -r '.items | length')
assert_eq "2.1 count BEFORE == AFTER"            "$COUNT_BEFORE" "$COUNT_AFTER"
assert_eq "2.2 count AFTER == pack-owned Issues" "$COUNT_AFTER"  "$ISSUE_COUNT"

# ─────────────────────────────────────────────────────────────────
# §3.2 oracle leg 2 — IDENTITY oracle.
# SET of pack-ids BEFORE == AFTER == SET of pack-id markers on Issues.
# ─────────────────────────────────────────────────────────────────
printf "\n=== Oracle leg 2: identity ===\n"
IDS_AFTER=$(_canon_ids "$AFTER_DIR")
assert_eq "3.1 id-set BEFORE == AFTER" "$IDS_BEFORE" "$IDS_AFTER"
# pack-id markers across pack-owned Issues, via the issue body.
ISSUE_IDS=""
for num in $(printf '%s' "$ISSUES_JSON" | jq -r '.items[].number'); do
    body=$(tracker_provider_gh_get "$num" 2>/dev/null | jq -r '.body // ""')
    pid=$(printf '%s' "$body" | sed -nE 's/.*<!--[[:space:]]*pack-id:[[:space:]]*([A-Za-z]+-[0-9]+(\.[0-9]+)?)[[:space:]]*-->.*/\1/p')
    [[ -n "$pid" ]] && ISSUE_IDS="$ISSUE_IDS$pid"$'\n'
done
ISSUE_IDS=$(printf '%s' "$ISSUE_IDS" | grep -E '^BD-[0-9]+$' | sort)
assert_eq "3.2 id-set AFTER == Issue pack-id markers" "$IDS_AFTER" "$ISSUE_IDS"

# ─────────────────────────────────────────────────────────────────
# §3.2 oracle leg 3 — CONTENT-FAITHFULNESS oracle.
# Per entry: diff <(orig span, back-pointer stripped) <(recon span,
# stripped) is EMPTY. The large multi-block entry (BD-903) must diff
# clean (its Segments:/Steps:/State:/Goal:/Scope: prose rides the
# Description field verbatim).
# ─────────────────────────────────────────────────────────────────
printf "\n=== Oracle leg 3: content-faithfulness ===\n"
for id in $IDS_BEFORE; do
    o=$(pe_strip_backpointer_stdin < "$ORIG_DIR/$id.md")
    r=$(pe_strip_backpointer_stdin < "$AFTER_DIR/$id.md")
    if [[ "$o" == "$r" ]]; then
        t_pass "4.$id content-faithful (back-pointer stripped)"
    else
        t_fail "4.$id content-faithful" "$(diff <(printf '%s' "$o") <(printf '%s' "$r") | head -20)"
    fi
done

# ─────────────────────────────────────────────────────────────────
# §3.2 oracle leg 4 — STATUS oracle.
# Status distribution BEFORE == AFTER (Deferred count is the canary).
# ─────────────────────────────────────────────────────────────────
printf "\n=== Oracle leg 4: status distribution ===\n"
STATUS_AFTER=$(_status_dist "$AFTER_DIR")
assert_eq "5.1 status distribution BEFORE == AFTER" "$STATUS_BEFORE" "$STATUS_AFTER"
# Explicit Deferred canary: BD-902 must still be Deferred (not Open).
bd902_status=$(grep -E '^Status: ' "$AFTER_DIR/BD-902.md" | sed 's/^Status: //')
assert_eq "5.2 Deferred canary (BD-902) round-trips" "Deferred" "$bd902_status"

# ─────────────────────────────────────────────────────────────────
# §3.2 oracle leg 5 — NO-MONOLITH / NO-SIDECAR oracle.
# No pack-ops/BACKLOG.md throughout; no .pack-tracker/reverse.sidecar.*.
# ─────────────────────────────────────────────────────────────────
printf "\n=== Oracle leg 5: no-monolith / no-sidecar ===\n"
[[ ! -f "$LOCAL_WC/pack-ops/BACKLOG.md" ]] \
    && t_pass "6.1 NO pack-ops/BACKLOG.md monolith (Check 32′ green)" \
    || t_fail "6.1 NO pack-ops/BACKLOG.md monolith"
sidecar=$(ls "$LOCAL_WC/.pack-tracker/reverse.sidecar."* 2>/dev/null | head -n 1)
[[ -z "$sidecar" ]] \
    && t_pass "6.2 NO reverse sidecar on pack surface (DP-2 dropped)" \
    || t_fail "6.2 NO reverse sidecar" "unexpected: $sidecar"
[[ -f "$AFTER_DIR/_toc.md" ]] \
    && t_pass "6.3 _toc.md regenerated (DP-4)" \
    || t_fail "6.3 _toc.md regenerated"

# ─────────────────────────────────────────────────────────────────
# §3.2 oracle leg 6 — REPEATED-CYCLE + interleaved CRUD oracle.
# (a) tree → Issues → tree → Issues → tree converges to the original.
# (b) interleaved CRUD: provider_create a new BD, provider_update a
#     status, reverse — assert the new BD appears + the status
#     round-trips + re-forward re-creates the state.
# ─────────────────────────────────────────────────────────────────
printf "\n=== Oracle leg 6: repeated-cycle + interleaved CRUD ===\n"

# (a) Second on/off cycle: forward again from the regenerated tree,
#     then reverse again; the final tree must equal the original
#     (back-pointer stripped), per entry.
rm -f "$LOCAL_WC/.pack-tracker/id-map.json"
tracker_migrate_forward_run "$LOCAL_WC" 0 0 0 >/dev/null 2>&1
tracker_migrate_reverse_run "$LOCAL_WC" 0 0 0 0 >/dev/null 2>&1
converged=1
for id in $IDS_BEFORE; do
    o=$(pe_strip_backpointer_stdin < "$ORIG_DIR/$id.md")
    r=$(pe_strip_backpointer_stdin < "$AFTER_DIR/$id.md")
    [[ "$o" == "$r" ]] || converged=0
done
[[ "$converged" -eq 1 ]] \
    && t_pass "7.1 repeated on/off/on/off converges to original" \
    || t_fail "7.1 repeated on/off/on/off converges to original"

# (b) Interleaved CRUD: create a new pack-owned Issue (BD-904) directly
#     via provider_create with the canonical body marker + bd-entry +
#     status:open labels, then provider_update one issue's status label
#     (BD-901 → status:resolved), reverse, and assert.
CRUD_BODY=$(printf '<!-- pack-id: BD-904 -->\n<!-- template_version: bd-v11.0 -->\n<!-- pack-version: v11 -->\n\n## Description\n\nInterleaved-CRUD new entry.\n')
CRUD_PAYLOAD=$(jq -n --arg t "BD-904: Interleaved-CRUD new entry" --arg b "$CRUD_BODY" \
    '{title:$t, body:$b, labels:["bd-entry","template:bd-v11.0","status:open"]}')
crud_res=$(provider_create "$CRUD_PAYLOAD" 2>/dev/null)
crud_num=$(printf '%s' "$crud_res" | jq -r '.number // .id // ""')
[[ -n "$crud_num" ]] \
    && t_pass "7.2 provider_create new BD-904 issue" \
    || t_fail "7.2 provider_create new BD-904 issue" "$crud_res"

# Flip BD-901's status label to resolved (status update via provider_update).
bd901_num=$(printf '%s' "$ISSUES_JSON" | jq -r '.items[] | select(.title|startswith("BD-901")) | .number' | head -1)
if [[ -n "$bd901_num" ]]; then
    provider_update "$bd901_num" \
        "$(jq -nc '{add_labels:["status:resolved"], remove_labels:["status:open"]}')" \
        >/dev/null 2>&1
fi

# Reverse and assert the CRUD landed in the tree.
rm -f "$LOCAL_WC/.pack-tracker/id-map.json"
tracker_migrate_reverse_run "$LOCAL_WC" 0 0 0 0 >/dev/null 2>&1
[[ -f "$AFTER_DIR/BD-904.md" ]] \
    && t_pass "7.3 interleaved create (BD-904) appears in the tree" \
    || t_fail "7.3 interleaved create (BD-904) appears in the tree"
bd901_status_after=$(grep -E '^Status: ' "$AFTER_DIR/BD-901.md" 2>/dev/null | sed 's/^Status: //')
assert_eq "7.4 interleaved status update (BD-901 → Resolved) round-trips" \
    "Resolved" "$bd901_status_after"

# ─────────────────────────────────────────────────────────────────
# Cleanup contract: delete the scratch repo + assert it is gone.
# ─────────────────────────────────────────────────────────────────
printf "\n=== Cleanup: delete scratch repo ===\n"
gh repo delete "$SCRATCH_REPO" --yes >/dev/null 2>&1
SCRATCH_CREATED=0
if gh repo view "$SCRATCH_REPO" >/dev/null 2>&1; then
    t_fail "8.1 scratch repo deleted" "$SCRATCH_REPO still exists"
else
    t_pass "8.1 scratch repo deleted (no dangling repo)"
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "Passed: %d\n" "$PASS"
printf "Failed: %d\n" "$FAIL"
[[ "$FAIL" -gt 0 ]] && exit 1
printf "All BD-204 lossless oracle legs passed.\n"
exit 0
```

---

## 10. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | No git add/commit/push/tag run. `git rev-parse HEAD` = `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (pre = post). `git status --short` shows only `??` untracked deliverables. | COMPLIANT |
| per-action-approval-sub-agents | No `rm -rf`/`git rm`/trusted-file overwrite on my authority; NO live outward op run — `gh repo create`/`delete` exist only inside the new test (guarded), never invoked by me. SKIP path only. | COMPLIANT |
| preflight-stop-means-stop | PREFLIGHT line emitted AFTER all verification PASS (syntax + SKIP + validate-pack + 51/51 battery). No parent stop/halt message received. | COMPLIANT |
| verify-full-ci-suite | Ran the ENTIRE battery enumerated from `.github/workflows/validate-pack.yml` (51 `bash` invocations, incl. `test-v11-realistic-ot.sh` banner-pinning), not a subset: batch1 `passed=22 failed:[]`, batch2 `passed=29 failed:[]`. Live oracle = SEPARATE 7b. | COMPLIANT |
| regenerate-manifest-v11-surface | `bash test-fixtures/build.sh --all --clean` RC=0; `git status --short test-fixtures/manifest.txt` + `git diff --stat` EMPTY → no manifest delta → nothing to stage. | COMPLIANT |
| filename-uniqueness-heuristic | `find . -name "tracker-bd204-lossless-roundtrip-test.sh" -not -path "./.git/*"` → empty before naming. | COMPLIANT |
| test-infra-self-provisioned | The test self-provisions a scratch repo via `gh` with trap-on-exit + explicit `gh repo delete` + gone-assertion; targets `$GH_USER/pack-bd204-oracle-...`, never the real pack repo. I did NOT run it live. | COMPLIANT |
| pack-repo-code-comment-deferrals | No deferral comments added to source. No `# TODO`/`# FIXME` introduced (grep of new test → none). | N/A: no deferral comment authored |
| scope-deliverables-to-the-ask | Exactly the test + 3-case fixture (+ report); migrator untouched; no extra files. `git status` = 2 deliverables. | COMPLIANT |
| boundary-investigation-precedes-pack-defaults | All edits pack-side (test/fixture/maintenance-doc). No `project-template/`/`supporting-docs/` touched; no pack-only concept leaked to a project surface. §6 boundary check recorded. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule name + actual command/quote evidence + conclusion. | COMPLIANT |

