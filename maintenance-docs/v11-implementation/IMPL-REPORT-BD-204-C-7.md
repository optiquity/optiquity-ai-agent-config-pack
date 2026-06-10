# IMPL-REPORT — BD-204 C-7 REBUILD: the live GH-Issues lossless oracle test

- **Commit-unit:** BD-204 C-7 REBUILD (PLAN-BD-204.md § "Commit C-7" base recipe + §3.LF.7 legs 1–10)
- **Branch:** v11-dev
- **HEAD at implementation (unchanged — no git state-change made):** `c30c8d56082a9466a1164c94925667592a5a31bf`
- **Coder:** pack-coder (fresh instance), 2026-06-10
- **Scope keyword eligibility:** pack-only (no `project-template/`, no `supporting-docs/` file touched)

## 1. What was built

`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` did NOT exist and had NO git
history (re-measured this session: `find` empty; `git log --all -- <path>` empty), so
"REBUILD the parked file" = BUILD FRESH per the spawn prompt's measured fact. Built:

| Path | Type | Lines | SHA-256 |
|---|---|---|---|
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | new | 782 | `114dbf7d93b13d8ad1dbf89a07df8c4b60dc835c2dc1b5d737dcfd29187e682c` |
| `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md` | new | 115 | `8087a068818449aa3a67d9bc9074c14f1923bbf549e44ee39d77fe9985d906da` |
| `scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml` | new | 22 | `a34f0c77b42700ca1c0f439b0466a9fc4317adf3fbfe882d98bf90b5786f8c23` |
| `test-fixtures/manifest.txt` | regenerated, **diff EMPTY** → not part of the change-set | — | — |

NOT touched: `scripts/lib/tracker-*.sh` (zero lib edits — C-7 is test + fixture only per
PLAN § C-7 "No migrator code change"), `.github/workflows/validate-pack.yml` (the test is
manual-only, NOT wired — `grep tracker-bd204-lossless .github/workflows/validate-pack.yml`
returns nothing), no `/backlog/`–`/changelog/` tree edits, no pack-chat-only files.

## 2. Leg map (success criterion 1)

Base § "Commit C-7" oracle legs — all implemented against the live scratch repo:
- **Count oracle** — `count(^BD-[0-9]+\.md$)` BEFORE == work-item-lane issue count
  (`--label bd-entry`; inbound + unlabeled size probes excluded) == AFTER. Dynamic, never
  hard-coded.
- **Identity oracle** — pack-id SET equality: baseline tree vs `pack-id` body markers vs
  reconstructed tree.
- **Content-faithfulness oracle** — per entry `cmp` of original vs reconstructed span,
  both through `pe_strip_backpointer_stdin` (`verify_tree_faithful`), run after cycle 1,
  cycle 2 (convergence), and post-CRUD for the unchanged set.
- **Status oracle** — full `Status:` distribution BEFORE == AFTER + an explicit
  `Deferred`-count canary assertion.
- **No-monolith / no-sidecar oracle** — `! -f pack-ops/BACKLOG.md` + no
  `.pack-tracker/reverse.sidecar.*` + `_toc.md` regenerated (DP-4).
- **Repeated-cycle + interleaved-CRUD** — forward 2 asserts `created: 0` / `skipped: N`
  (idempotent skip-all); reverse 2 re-converges to baseline; then `provider_create`
  BD-908 (real-composer body w/ blob), a blob-consistent status update on BD-904
  (recomposed body + `status:*` label swap in ONE `provider_update` — the §3.3a sync
  contract), reverse 3 asserts BD-908 appears byte-verbatim + the status round-trips +
  count == N+1, re-forward asserts `created: 0` / `entries: N+1`.

§3.LF.7 rebuilt legs 1–10:
1. **Drop-set + no-Description fixtures** — BD-901 (six drop-set fields interleaved with
   carried fields, order-faithful), BD-902 (no `Description:` at all), BD-903 (sub-blocks
   INSIDE Description — the kept case). Exercised by DS-1 + the content oracle.
2. **Size leg** — DS-3a composer fail-loud above `provider_body_limit − margin` on the
   ACTUAL composed body (asserts `size-budget: entry BD-999` + the never-truncates text);
   DS-3b within-budget near-budget body (incompressible, ~60.9 KB composed) accepted live;
   DS-3c >65,536 body draws the documented GH 422 (probes carry no `bd-entry` label).
3. **Pacing leg** — live: create-burst wall-clock ≥ (N−1)×1 s + no `rate-limit` / `abuse`
   classification anywhere in the forward output (KU-OPS-2/3). The fake-clock seam +
   simulated-429 retry-after unit variants are the wired-unattended home
   (`tracker-migrate-forward-test.sh` §2.8.7/2.8.8 — cited in the test header).
4. **Autolink-neutralization leg** — BD-904 carries all 4 trigger forms; live rendered
   `body_html` asserted free of `user-mention` / `issue-link` / `commit-link` /
   `href="https://example.invalid` and containing a `<code>` span; blob decodes the
   trigger tokens verbatim (covered by DS-1 on BD-904).
5. **Corrupt-blob leg** — live PATCH corrupts the gz64 payload (valid base64, invalid
   gzip); asserts reconstruct rc=1 + `corrupt-blob` + "NEVER emits an empty/partial entry
   body" AND the FULL reverse run aborts non-zero; body restored after. Unit home:
   `tracker-migrate-reverse-test.sh` §2.1b.
6. **Normalization-comparator leg (DS-2)** — live PATCH of a CRLF + trailing-space
   variant (markers untouched) → comparator rc=0 (no false-positive); a one-word
   visible-H2 edit → rc=1 `divergence: issue #N`; `--force` → rc=0 blob-wins; body
   restored. Unit home: `tracker-migrate-reverse-test.sh` §2.1d.
7. **Credential-capability preflight** — FIRST live action: gh ≥ 2.0 floor (the §11.3
   absorbed-with-flag item), token-scopes read (classic PATs; requires `repo`,
   records `delete_repo` NOT required), probe-verified create/issue-write/archive at
   their use sites, each failing loud with the pinned
   `credential-preflight: token missing <permission> required for <step>; aborting before any live write` shape.
8. **Archive-not-delete disposal** — `gh repo archive "$SCRATCH_REPO" --yes` +
   `gh repo view --json isArchived` == `true`; the EXIT trap archives on FAILURE too
   (never a writable orphan); `RECOMMEND: manually delete the scratch repo <slug> …`
   printed on every exit path after creation; a split-pattern grep self-guard asserts the
   source contains NO repo-delete invocation (verified: `grep -c "gh repo delete"` = 0).
9. **Repeatable multi-rehearsal** — `pack-bd204-oracle-$$-<unix-ts>` unique naming + a
   defense-in-depth refusal to mutate any slug not matching `pack-bd204-oracle-*`
   (the real pack repo can never match); no single-shot assumption.
10. **CI-execution model** — default-SKIP guard is the literal FIRST action (only
    `set -u` precedes it); prints exactly
    `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` and `exit 0`;
    NOT wired into any workflow/run-all list; the unit-level legs run unattended via
    their already-wired homes (enumerated in the test header and §2 above: forward-test
    §2.8.x/2.9.x, reverse-test §2.1b/§2.1d, check-49 deep guard + its per-check test).

§11.2 known-unknown coverage: DS-1 (stored byte-verbatim read-back + decode + `cmp`),
DS-2 (leg 6), DS-3 (leg 2), KU-OPS-2/3 (leg 3), KU-OPS-6 (leg 4), KU-CRED (legs 7+8).
DS-4/DS-5 are MOOT per the architecture (no leg needed).

## 3. Fixture-shape reconciliation (success criterion 5)

PLAN §3.LF.7 names `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md`
(+ `tracker.toml`); the base recipe says "a small FIXTURE tree under
`scripts/tests/fixtures/`". The as-built pack-surface entry points consume a per-entry
TREE, not a monolith (`tracker_migrate_forward_run` → `tmf_parse_backlog_tree
"pack-backlog" "$repo_root/backlog"` at `scripts/lib/tracker-migrate-forward.sh`
(pack branch of step 1+2); `tracker_migrate_reverse_run` → `_tmr_emit_pack_tree` into
`$repo_root/backlog`). **No genuine contradiction once the suite's established idiom is
applied:** `tracker-migrate-roundtrip-test.sh` `_setup_test_repo` already keeps its
fixture as a `BACKLOG.md` monolith and decomposes it into the `/backlog/` tree at runtime
via `per_entry_decompose "pack-backlog" …` + a `pack-ops/` marker dir. The new oracle
does the same: fixture stays plan-literal (`BACKLOG.md` + `tracker.toml`), the /tmp work
root gets the decomposed tree the migrator actually reads, and the byte-faithfulness
baseline is the DECOMPOSED tree snapshot (so monolith-vs-tree formatting is out of the
comparison entirely). Offline evidence: decompose produced exactly 7 canonical files;
`raw_body` for every entry compared byte-identical (`cmp`) to its stripped tree file.

## 4. Verification (Run 1 ONLY — unattended; PACK_TRACKER_LIVE_GH never set, no gh mutation, no live GH touched)

All measured with `/usr/bin/time -p` at HEAD `c30c8d5`, 2026-06-10. Run 2 (the manual
live rehearsal, PLAN §3.LF.10) is NOT run by the coder — user-gated, per-step approval.

| Check | Command | Result |
|---|---|---|
| Syntax | `bash -n scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | OK |
| Unattended SKIP path | `env -u PACK_TRACKER_LIVE_GH /usr/bin/time -p bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | prints exactly the pinned SKIP line; `rc=0`; **real 0.00 s** (gh never invoked — the env check short-circuits first) |
| No-delete grep-guard | `grep -c "gh repo delete" <test>` | **0** |
| Not wired into CI | `grep tracker-bd204-lossless .github/workflows/validate-pack.yml` | no match |
| Fixture offline integrity | decompose → parse → raw_body `cmp` → encode/decode `cmp` → compose-has-blob, per entry | 7/7 entries: ALL OK (statuses Open×4, Unblocked, Resolved, Deferred) |
| Size-gate offline | github-backend caps + incompressible 50 KB probe | `limit=65536`; over-budget rc=1 + `size-budget: entry BD-999` + `NEVER truncates`; near-budget composes 60,876 B < 63,488 budget |
| validate-pack (general) | `/usr/bin/time -p python3 scripts/validate-pack.py` | PASSED — all checks clean; **real 1.46 s** (~baseline 1.3–1.4 s; deep leg SKIPs without `PACK_VALIDATE_DEEP`) |
| validate-pack (deep) | `PACK_VALIDATE_DEEP=1 …` | PASSED; **real 3.10 s** |
| FULL unattended battery (§3.LF.9 — every workflow `run:` line) | 59 run-lines from `.github/workflows/validate-pack.yml`, workflow order | **56 PASS / 0 FAIL / 3 documented skips; real 478.61 s (~8.0 min — COMPLETES, the runtime gate)** |
| Manifest regen (rule RC9) | `bash test-fixtures/build.sh --all --clean` (battery item 51) + `--verify` (item 53) | both PASS; `git diff test-fixtures/manifest.txt` **EMPTY** → per the rule ("stage … when the manifest diff is non-empty") nothing to stage |

Battery skips (3 of 59, each with reason, none a test): 2× `pip install pyyaml`
(environment-provision step, pyyaml already present — validate-pack ran green) and 1×
`git checkout HEAD -- test-fixtures/manifest.txt` (a CI-only revert step that is a git
state-change on my worktree AND would clobber the uncommitted regen; its purpose —
manifest-vs-fresh-build equality — was verified by running `--verify` against the
freshly regenerated manifest, which PASSED).

Unit-level legs "pass via their mock/in-process path" (criterion 7): battery items
`tracker-migrate-forward-test.sh` (size §2.8.5, pacing §2.8.7/2.8.8, neutralizer
§2.8.x/2.9.2), `tracker-migrate-reverse-test.sh` (corrupt-blob §2.1b, normalization
comparator §2.1d), `test-validate-pack-check-49-field-faithfulness.sh` (byte
faithfulness deep guard) — all PASS in the run above.

ci-check-runtime-compounding statement: the new test's unattended cost is the SKIP path —
**measured 0.00 s** — and it is invoked by NOTHING in the battery (not wired), so its
contribution to the 56-test battery is exactly zero.

## 5. Plan deviations

Zero scope deviations. Four implementation-level resolutions, each grounded:

1. **Fixture shape** — see §3 (plan-literal monolith + runtime decompose; matches the
   roundtrip-test idiom and the as-built tree consumers; not a silent guess).
2. **DS-3a over-budget probe is an incompressible random payload.** Measured: a
   repeated-char 66,000-byte body gzips to a tiny blob and the composed-body gate does
   NOT fire (rc=0); 50,000 random bytes → ~67 KB blob → rc=1 with the pinned error. The
   leg's intent ("the overflow fail-loud fires … on the ACTUAL composed body") requires
   the incompressible form.
3. **RECOMMEND-line wording** — prefix `RECOMMEND: manually delete the scratch repo
   <slug>` kept exactly per §3.LF.7 leg 8; the parenthetical reason is paraphrased
   ("repo deletion needs a permission this token deliberately lacks; tooling never
   deletes") because the architecture's example parenthetical contains the contiguous
   forbidden literal, which would self-trip the same leg's grep-guard.
4. **Interleaved-CRUD `provider_create` registers BD-908 in the id-map** immediately
   (mirroring the forward loop's per-create `tmf_mapping_set` + save) instead of relying
   on the title-marker SEARCH recovery path for the re-forward skip — GH's search index
   lags new issues by minutes, which would make the re-forward leg a flake generator,
   not an oracle. Documented in-code.

## 6. New POQs

None.

## 7. Out-of-scope observations (surfaced, not fixed — no lib edits permitted in C-7)

- **Repeat-forward over Resolved entries re-attempts `provider_close` and re-posts the
  Resolution comment** (`tracker_migrate_forward_run` steps 8+9 do not check current
  issue state). Expected live behavior is that `gh issue close` on an already-closed
  issue is a warn-and-succeed no-op, but that is empirically confirmed only at rehearsal
  time; duplicate Resolution comments on re-runs are a cosmetic side effect either way.
  The oracle's forward-2/forward-3 assertions print the run tail on a non-zero rc so the
  rehearsal surfaces it cleanly if gh's behavior differs. If the rehearsal trips this,
  it is an as-built forward-idempotency finding for Pack Chat to triage (not a test bug).

## 8. Boundary discipline check (P-missed-7)

No project-side file was touched (diff = `scripts/tests/` only — pack-side test infra).
No edit adds a project-side reference to a pack-only file. Fixture entry text is
self-contained (no repo paths, no pack-ops/maintenance-docs references). No SSOT
investigation owed beyond this attestation; no boundary stop triggered.

## 9. Filename-uniqueness (success criterion 6)

- `find . -name "tracker-bd204-lossless-roundtrip-test.sh" -not -path "./.git/*"` →
  empty before creation; `git log --all -- <path>` → empty (no history).
- `find . -name "tracker-bd204-lossless" -not -path "./.git/*"` → empty before creation.
- `BACKLOG.md` / `tracker.toml` inside the fixture dir are STRUCTURALLY REQUIRED
  collisions (the suite's fixture convention — same names exist under
  `fixtures/tracker-migrate/` and `fixtures/roundtrip/bd-v11.0/`); all prose references
  in the test and this report carry the full path.

## 10. Definition of Done

| Item | Status |
|---|---|
| All §3.LF.7 legs 1–10 + base C-7 oracle legs implemented | PASS (§2 map) |
| Default-SKIP guard first action; exact SKIP line; exit 0; not wired into CI | PASS (measured: 0.00 s, rc=0, no workflow ref) |
| Credential preflight first live action; archive-not-delete + trap + RECOMMEND + grep-guard | PASS (grep = 0; trap archives on failure) |
| Fixtures: drop-set, no-Description, 4-form autolink, BD-903 sub-blocks, parenthetical-title, Deferred, large multi-block — all suffix-free, post-em-dash parenthetical only | PASS (BD-901..907; offline check 7/7 OK) |
| Fixture-path reconciliation surfaced with evidence | PASS (§3) |
| Filename uniqueness verified | PASS (§9) |
| validate-pack green at ~baseline; SKIP path + unit legs green; FULL battery COMPLETES, wall-clock measured | PASS (1.46 s / 3.10 s deep / 478.61 s battery, 0 FAIL) |
| Manifest regen run; staged only if diff non-empty | PASS (regen + verify PASS; diff empty → nothing to stage) |
| No live GH touched; PACK_TRACKER_LIVE_GH never set; no gh mutation | PASS |
| No lib edits; no out-of-scope file edits; no git state-change | PASS (`git status`: only the 3 new paths untracked) |
| IMPL-REPORT at the specified path | PASS (this file) |

## 11. Files changed

| Path | Change |
|---|---|
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | NEW (782 lines) |
| `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md` | NEW (115 lines) |
| `scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml` | NEW (22 lines) |

(`test-fixtures/manifest.txt`: regenerated, byte-identical to HEAD — not in the change-set.)

Full contents of all three new files follow in the Appendix (so Pack Chat can re-apply
without re-deriving); SHA-256 hashes in §1 pin the worktree copies.

## Appendix A — full contents of the new files (verbatim)

### A.1 `scripts/tests/fixtures/tracker-bd204-lossless/tracker.toml`

````toml
# Fixture tracker.toml for the BD-204 live lossless-round-trip oracle
# (scripts/tests/tracker-bd204-lossless-roundtrip-test.sh). The repo slug
# is a placeholder: the oracle copies this file into its /tmp work root
# and substitutes the uniquely-named scratch repo slug at runtime. The
# placeholder is never used live (tracker_gh_repo_setup would reject it
# only after a substitution bug — the oracle asserts the substitution).

schema_version = 1

[backend]
name = "github"
repo = "scratch-owner/__BD204_SCRATCH_SLUG__"

[mode]
state = "flat-file"

[id_namespace]
prefix = "BD"

[migration]
forward_complete = false
mapping_file = ".pack-tracker/id-map.json"
````

### A.2 `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md`

`````markdown
**BD-901 — Drop-set fields interleaved with carried fields**
Type: TODO(version)
Target: v11.0
Status: Open
Position: after BD-902
Blockers: None
Scope: Every top-level drop-set field must ride the gz64 blob verbatim,
  in original order, interleaved between carried fields.
Unblocks: BD-907
Problem: The pre-fix parser whitelist silently discarded the
  Target/Position/Scope/Problem/References/Out-of-scope lines on forward.
Description: Order-faithful drop-set stress entry; the carried and
  dropped fields alternate so a fixed-order re-projection cannot
  reproduce the original ordering.
References: BD-902; the gz64 verbatim-body carrier design (§3.3).
Out of scope: Entry rewrites; the project-side TD namespace.
Resolved: n/a

---

**BD-902 — No-Description worst case**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-901
File/Symbol: scripts/lib/tracker-migrate-reverse.sh
Resolved: Landed with the carrier; this entry deliberately carries no
  Description field at all (the worst-case cohort migrates to a
  near-empty projection but a complete blob).

---

**BD-903 — Sub-blocks inside Description**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
Description: The sub-blocks below live INSIDE the Description field as
  continuation lines (the BD-903 case the original C-7 fixture carried).
  Segments:
  - segment one (parse-order)
  - segment two (verbatim ride)
  Steps:
  1. forward composes the blob
  2. reverse decodes it byte-identical
Resolved: n/a

---

**BD-904 — Autolink trigger forms (all four)**
Type: TODO(version)
Status: Unblocked
Blockers: None
Unblocks: None
Description: Triggers: issue ref #123, mention @pack-bd204-nobody,
  commit deadbeefcafe1234567890abcdef12345678dead, and
  https://example.invalid/bd204 — the composed H2 must neutralize all
  four forms (inline-code span, no live link); the blob must decode
  every trigger token verbatim.
Resolved: n/a

---

**BD-905 — Parenthetical title stress (Qualifier Three)**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
Description: The parenthetical is admissible TITLE TEXT after the
  em-dash (the BD-195 exemplar shape). Post-BD-211 there is no suffix
  case — a BD-NNNb filename/header or a pre-em-dash parenthetical is a
  validator failure, not a fixture.
Resolved: n/a

---

**BD-906 — Deferred status canary**
Type: TODO(version)
Status: Deferred
Blockers: None
Unblocks: None
Description: The Deferred count is the round-trip canary — forward maps
  Status to the status:deferred label, reverse decodes it back, and the
  blob carries the verbatim Status line regardless.
Resolved: n/a

---

**BD-907 — Large multi-block entry**
Type: TODO(version)
Status: Open
Blockers: BD-901
Unblocks: None
Goal: Round-trip a large multi-block body byte-identically.
Segments:
- A: the top-level Segments block is a drop-set field (not whitelisted)
- B: it rides the blob verbatim with its bullets intact
- C: ordering across blocks is load-bearing
Steps:
1. decompose the fixture monolith into the per-entry tree
2. forward-migrate the tree to the scratch repo
3. reverse-migrate and byte-compare against the baseline tree
State: authored for the rebuilt C-7 oracle; exercised on every rehearsal.
Scope: Top-level Segments/Steps/State/Goal/Scope blocks interleaved with
  carried fields; a fenced code span `like this` and the interior blank
  line below stress the verbatim capture.

  The interior blank line above and this trailing paragraph are part of
  the Scope continuation; the projection parser drops them, the blob
  carries them verbatim.
Description: The large multi-block exemplar (BD-195-shaped) for the
  content-faithfulness leg.
Resolved: n/a

---
`````

### A.3 `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`

`````bash
#!/usr/bin/env bash
# scripts/tests/tracker-bd204-lossless-roundtrip-test.sh — the BD-204
# live lossless round-trip oracle (PLAN-BD-204.md § "Commit C-7" base
# recipe + §3.LF.7 rebuilt legs 1–10; design intent
# ARCHITECTURE-BD-204-LOSSLESS-FIX.md §5.c / §5.f / §11.2).
#
# MANUAL-ONLY + DEFAULT-SKIP (PLAN § C-7 step 5 / §3.LF.7 leg 10; HARD):
#   - NOT wired into any CI workflow or unattended run-all list. This is
#     the first and only LIVE-repo test in the suite; it stays out of
#     the unattended battery per `test-infra-self-provisioned`.
#   - The FIRST action below is the default-SKIP guard: with
#     PACK_TRACKER_LIVE_GH unset/empty OR `gh auth status` not OK, the
#     test prints the pinned SKIP line and exits 0 — it can NEVER reach
#     `gh repo create` unattended.
#   - Run manually (the C-8 dress rehearsal, PLAN §3.LF.10) as:
#       PACK_TRACKER_LIVE_GH=1 bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh
#     by Pack Chat / the user with per-step approval on every gh
#     mutation. Agents NEVER run the live path on their own authority.
#
# UNATTENDED HOMES for the unit-level legs (§3.LF.7 leg 10 — "the
# in-process check or a mock-based unit test"): the no-live-GH variants
# of legs 2–6 ALREADY run in the wired unattended battery —
#   - size leg (composer overflow fail-loud + within-budget pass):
#     tracker-migrate-forward-test.sh § 2.8.5
#   - pacing leg (fake-clock sleep seam + retry-after backoff):
#     tracker-migrate-forward-test.sh § 2.8.7 / 2.8.8
#   - autolink-neutralization leg (4 trigger forms, fence widening):
#     tracker-migrate-forward-test.sh § 2.8.x / 2.9.2
#   - corrupt-blob leg (reverse fails loud, never emits empty/partial):
#     tracker-migrate-reverse-test.sh § 2.1b
#   - normalization-comparator leg (no false-positive on CRLF/trailing-
#     ws; real edit caught; --force blob-wins):
#     tracker-migrate-reverse-test.sh § 2.1d
#   - byte-faithfulness (decode∘encode identity over the whole tree):
#     validate-pack.py check_migrator_field_faithfulness (deep,
#     PACK_VALIDATE_DEEP=1) + test-validate-pack-check-49-field-faithfulness.sh
# This file re-runs those behaviors AGAINST LIVE GH (the
# documented-silent platform behaviors no mock can confirm — §11.2
# DS-1/DS-2/DS-3/KU-OPS-2/3/KU-OPS-6/KU-CRED).
#
# SCRATCH-DISPOSAL CONTRACT (§5.c / reference_gh_pat_no_delete; HARD):
#   archive-not-delete. The credential's PAT deliberately has NO
#   repo-delete permission. The tool-performed end-state is
#   `gh repo archive` (read-only); the trap archives on FAILURE too
#   (never leave a writable orphan); the run RECOMMENDS manual deletion
#   to the user; a grep self-guard asserts this source contains no
#   repo-delete invocation. The REAL pack repo is never a target and
#   never archived.
#
# Usage:
#   bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh   # SKIPs
#   PACK_TRACKER_LIVE_GH=1 bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh

set -u

# ─────────────────────────────────────────────────────────────────
# DEFAULT-SKIP GUARD — the FIRST action (PLAN § C-7 step 5; HARD).
# Reuses the suite's `command -v gh` + `gh auth status` preflight idiom.
# ─────────────────────────────────────────────────────────────────
if [[ -z "${PACK_TRACKER_LIVE_GH:-}" ]] \
   || ! command -v gh >/dev/null 2>&1 \
   || ! gh auth status >/dev/null 2>&1; then
    echo "SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)"
    exit 0
fi

# ─────────────────────────────────────────────────────────────────
# Harness (suite idiom)
# ─────────────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"
FIXTURE_DIR="$REPO_ROOT/scripts/tests/fixtures/tracker-bd204-lossless"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m %s\n" "$1"; [[ -n "${2:-}" ]] && printf "       %s\n" "$2"; }

assert_eq()           { if [[ "$2" == "$3" ]]; then t_pass "$1"; else t_fail "$1" "expected='$2' actual='$3'"; fi; }
assert_contains()     { if [[ "$2" == *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' missing"; fi; }
assert_not_contains() { if [[ "$2" != *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' unexpectedly present"; fi; }

# Hard abort: a failed live-infrastructure step makes every later leg
# meaningless — surface, archive (via trap), exit non-zero.
die() {
    printf "  \033[31mABORT\033[0m %s\n" "$1" >&2
    exit 1
}

# Per-step transparency: every gh MUTATION is announced before it runs
# (the rehearsal protocol's per-step approval rides on the operator
# watching these lines — PLAN §3.LF.10).
live_step() { printf "LIVE: about to run: %s\n" "$*"; }

# ─────────────────────────────────────────────────────────────────
# STATIC SELF-GUARD (§3.LF.7 leg 8): this source contains NO
# repo-delete invocation on any path. The pattern is split so the
# guard does not match itself.
# ─────────────────────────────────────────────────────────────────
_FORBIDDEN="gh repo de""lete"
if grep -q "$_FORBIDDEN" "${BASH_SOURCE[0]}"; then
    die "self-guard: the test source contains a forbidden repo-delete invocation (archive-not-delete contract, reference_gh_pat_no_delete)"
fi
t_pass "self-guard: no repo-delete invocation anywhere in the test source"

# ─────────────────────────────────────────────────────────────────
# Library sourcing (suite idiom — same order as the roundtrip test)
# ─────────────────────────────────────────────────────────────────
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
source "$LIB_DIR/tracker-sidecar.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-forward.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/tracker-migrate-reverse.sh"

# ─────────────────────────────────────────────────────────────────
# CREDENTIAL-CAPABILITY PREFLIGHT (§3.LF.7 leg 7 / design §5.f) —
# the FIRST live action, BEFORE any `gh repo create`.
#
# Required-permission set (design §5.f table): repo CREATE, issue
# WRITE, repo ARCHIVE, issue READ. Repo DELETE is explicitly NOT
# required and never attempted (archive-only disposal).
#
# Verification model: the cheap token-scopes read (classic PATs print
# "Token scopes: ..."); each capability is then probe-verified at its
# first use site, failing loud with the pinned
# `credential-preflight: token missing <permission> required for
# <step>; aborting before any live write` message BEFORE any bulk work.
# ─────────────────────────────────────────────────────────────────
echo "── credential-capability preflight (design §5.f) ──"

# Optional gh version floor (design §11.3 absorbed-with-flag): the JSON
# / --jq / `gh repo archive` surface is stable in gh >= 2.0.
GH_VERSION_RAW=$(gh --version 2>/dev/null | head -1)
GH_VERSION_MAJOR=$(printf '%s' "$GH_VERSION_RAW" | sed -nE 's/.*version ([0-9]+)\..*/\1/p')
if [[ -z "$GH_VERSION_MAJOR" || "$GH_VERSION_MAJOR" -lt 2 ]]; then
    die "credential-preflight: gh version '$GH_VERSION_RAW' is below the 2.0 floor required for repo archive + --json/--jq; aborting before any live write"
fi
t_pass "preflight: gh version floor (>= 2.0): $GH_VERSION_RAW"

# Token scopes (best-effort: classic PATs print the line; fine-grained
# tokens do not — those fall through to the per-step probes).
TOKEN_SCOPES=$(gh auth status 2>&1 | grep -i "token scopes" || true)
if [[ -n "$TOKEN_SCOPES" ]]; then
    if printf '%s' "$TOKEN_SCOPES" | grep -q "repo"; then
        t_pass "preflight: token scopes include 'repo' (create + issue write + read)"
    else
        die "credential-preflight: token missing repo scope required for issue writes; aborting before any live write ($TOKEN_SCOPES)"
    fi
    if printf '%s' "$TOKEN_SCOPES" | grep -q "delete_repo"; then
        echo "  NOTE: token carries delete_repo — NOT required; this oracle never deletes (archive-only disposal)."
    else
        t_pass "preflight: delete_repo absent from token scopes — NOT required (archive-only disposal; reference_gh_pat_no_delete)"
    fi
else
    echo "  NOTE: no 'Token scopes:' line (fine-grained token / keyring auth) — capabilities are probe-verified at first use: create (the repo create), issue write (the first provider_create), archive (the disposal). Each probe fails loud before bulk work."
fi
echo "  preflight: required set = {repo-create, issue-write, repo-archive, issue-read}; repo-delete = NOT required, never attempted."

GH_LOGIN=$(gh api user --jq .login 2>/dev/null)
[[ -n "$GH_LOGIN" ]] || die "credential-preflight: token missing user-read required for scratch-repo addressing; aborting before any live write"

# ─────────────────────────────────────────────────────────────────
# Scratch provisioning (§3.LF.7 leg 9: REPEATABLE multi-rehearsal —
# each run provisions a UNIQUELY-named throwaway scratch repo).
# test-infra-self-provisioned: NEVER a real repo as a test target.
# ─────────────────────────────────────────────────────────────────
SCRATCH_NAME="pack-bd204-oracle-$$-$(date +%s)"
SCRATCH_REPO="$GH_LOGIN/$SCRATCH_NAME"

# Defense in depth: refuse to mutate anything not matching the
# throwaway-name pattern (a real repo can never match it).
case "$SCRATCH_NAME" in
    pack-bd204-oracle-*) : ;;
    *) die "safety: scratch name '$SCRATCH_NAME' does not match the pack-bd204-oracle-* throwaway pattern" ;;
esac

WORK_BASE=""
ARCHIVED=0
REPO_CREATED=0

# ARCHIVE-not-delete disposal trap (§3.LF.7 leg 8): archives on FAILURE
# too — never leave a WRITABLE orphan scratch repo. Tooling never
# deletes; the run recommends manual deletion at the end.
_cleanup() {
    local rc=$?
    if [[ "$REPO_CREATED" -eq 1 && "$ARCHIVED" -eq 0 ]]; then
        printf '\nTRAP: archiving scratch repo %s (failure-path disposal — never leave a writable orphan)\n' "$SCRATCH_REPO" >&2
        if gh repo archive "$SCRATCH_REPO" --yes >/dev/null 2>&1; then
            ARCHIVED=1
        else
            printf 'TRAP: ARCHIVE FAILED — manually archive %s NOW (writable orphan otherwise)\n' "$SCRATCH_REPO" >&2
        fi
    fi
    [[ -n "$WORK_BASE" && -d "$WORK_BASE" ]] && rm -rf "$WORK_BASE"
    if [[ "$REPO_CREATED" -eq 1 ]]; then
        printf '\nRECOMMEND: manually delete the scratch repo %s (repo deletion needs a permission this token deliberately lacks; tooling never deletes — reference_gh_pat_no_delete)\n' "$SCRATCH_REPO"
    fi
    exit "$rc"
}
trap _cleanup EXIT

live_step "gh repo create $SCRATCH_REPO --private (capability probe: repo-create)"
if ! gh repo create "$SCRATCH_REPO" --private >/dev/null 2>&1; then
    die "credential-preflight: token missing repo-create permission required for scratch provisioning; aborting before any live write"
fi
REPO_CREATED=1
t_pass "provision: scratch repo $SCRATCH_REPO created (uniquely named, throwaway)"

# Install the form family (base recipe step 1): push the pack's
# .github/ISSUE_TEMPLATE/*.yml to the scratch repo via the contents API
# (no git clone needed; 3 small writes).
for _form in "$REPO_ROOT/.github/ISSUE_TEMPLATE"/*.yml; do
    _form_base=$(basename "$_form")
    live_step "gh api PUT /repos/$SCRATCH_REPO/contents/.github/ISSUE_TEMPLATE/$_form_base"
    _form_b64=$(base64 < "$_form" | tr -d '\n')
    if ! gh api -X PUT "repos/$SCRATCH_REPO/contents/.github/ISSUE_TEMPLATE/$_form_base" \
        -f message="seed issue form $_form_base (BD-204 oracle)" \
        -f content="$_form_b64" >/dev/null 2>&1; then
        die "provision: failed to install issue form $_form_base on $SCRATCH_REPO"
    fi
done
t_pass "provision: issue-form family installed on the scratch repo"

# ─────────────────────────────────────────────────────────────────
# Seed the work root: decompose the fixture monolith into the
# per-entry tree (the as-built pack-surface read shape — the same
# `per_entry_decompose` idiom tracker-migrate-roundtrip-test.sh uses),
# substitute the scratch slug into tracker.toml, snapshot the baseline.
# ─────────────────────────────────────────────────────────────────
WORK_BASE=$(mktemp -d -t bd204-oracle.XXXXXX)
WORK_ROOT="$WORK_BASE/repo"
mkdir -p "$WORK_ROOT/pack-ops" "$WORK_ROOT/backlog" "$WORK_ROOT/.pack-tracker"
per_entry_decompose "pack-backlog" "$FIXTURE_DIR/BACKLOG.md" "$WORK_ROOT/backlog" >/dev/null \
    || die "seed: per_entry_decompose failed on the fixture monolith"
sed "s|scratch-owner/__BD204_SCRATCH_SLUG__|$SCRATCH_REPO|" \
    "$FIXTURE_DIR/tracker.toml" > "$WORK_ROOT/tracker.toml"
grep -q "$SCRATCH_REPO" "$WORK_ROOT/tracker.toml" \
    || die "seed: scratch-slug substitution failed in tracker.toml"
# Safety: the configured backend.repo must be the throwaway scratch.
case "$(tracker_repo_slug "$WORK_ROOT/tracker.toml")" in
    */pack-bd204-oracle-*) : ;;
    *) die "safety: tracker.toml backend.repo is not the throwaway scratch repo" ;;
esac

# Baseline snapshot: the decomposed tree BEFORE any migration. Every
# content-faithfulness comparison strips the line-1 back-pointer via
# pe_strip_backpointer_stdin (PLAN § C-7 oracle leg 3).
BASELINE_DIR="$WORK_BASE/baseline-backlog"
cp -R "$WORK_ROOT/backlog" "$BASELINE_DIR"

# DYNAMIC counts (measured, never hard-coded — BD-203 EE-1 discipline).
# Canonical, suffix-free filename shape per BD-211: ^BD-[0-9]+\.md$.
count_tree_entries() {
    ls "$1" | grep -E -c '^BD-[0-9]+\.md$'
}
tree_id_set() {
    ls "$1" | grep -E '^BD-[0-9]+\.md$' | sed 's/\.md$//' | LC_ALL=C sort
}
N_BASELINE=$(count_tree_entries "$BASELINE_DIR")
[[ "$N_BASELINE" -gt 0 ]] || die "seed: baseline tree is empty"
echo "── seeded: $N_BASELINE canonical entries in the baseline tree ──"

# Count of pack-owned Issues = the work-item lane only (bd-entry label;
# inbound + unlabeled size-leg probes excluded) — PLAN § C-7 count oracle.
count_scratch_issues() {
    gh issue list -R "$SCRATCH_REPO" --label bd-entry --state all \
        --json number --jq 'length' 2>/dev/null
}
issue_id_set() {
    gh issue list -R "$SCRATCH_REPO" --label bd-entry --state all \
        --json body --jq '.[].body' 2>/dev/null \
        | sed -nE 's/.*<!-- pack-id: (BD-[0-9]+) -->.*/\1/p' | LC_ALL=C sort
}

# Ensure the canonical label set exists on the scratch repo (the real
# flip's `pack tracker init` step 3; ~45 idempotent label creates).
export _TRACKER_PROVIDER_CONFIG_PATH="$WORK_ROOT/tracker.toml"
export GH_REPO="$SCRATCH_REPO"
live_step "gh label create x ~45 (tracker_labels_ensure on $SCRATCH_REPO)"
tracker_labels_ensure >/dev/null 2>&1 \
    || die "credential-preflight: token missing issue-write (label create) permission required for label seeding; aborting before any live write"
t_pass "provision: canonical label set ensured on the scratch repo"

# ─────────────────────────────────────────────────────────────────
# FORWARD run 1 (tree → Issues) — the paced bulk create (§3.3d).
# KU-OPS-2/3 live confirmation: the ≥1s-paced burst trips no 403/429
# and no abuse flag (the provider declares min_write_interval_s=1).
# ─────────────────────────────────────────────────────────────────
echo "── forward run 1 (tree → Issues; paced) ──"
live_step "tracker_migrate_forward_run (provider_create x $N_BASELINE on $SCRATCH_REPO)"
_fwd_t0=$SECONDS
FWD1_OUT=$(tracker_migrate_forward_run "$WORK_ROOT" 0 0 2>&1)
FWD1_RC=$?
_fwd_elapsed=$((SECONDS - _fwd_t0))
if [[ "$FWD1_RC" -ne 0 ]]; then
    printf '%s\n' "$FWD1_OUT" >&2
    die "forward run 1 failed (rc=$FWD1_RC) — see diagnostics above"
fi
assert_contains "forward 1: completed" "$FWD1_OUT" "forward: complete."
assert_contains "forward 1: created every baseline entry" "$FWD1_OUT" "created:    $N_BASELINE"
# KU-OPS-2/3: no rate-limit / abuse classification anywhere in the run.
assert_not_contains "forward 1: no secondary-rate-limit / abuse error (KU-OPS-2/3)" "$FWD1_OUT" "rate-limit"
assert_not_contains "forward 1: no abuse flag (KU-OPS-2/3)" "$FWD1_OUT" "abuse"
# Pacing leg, live evidence: N creates at >=1s spacing need >= N-1 secs.
if [[ "$_fwd_elapsed" -ge $((N_BASELINE - 1)) ]]; then
    t_pass "pacing leg (live): create burst took ${_fwd_elapsed}s >= $((N_BASELINE - 1))s (>=1s min-write interval honored)"
else
    t_fail "pacing leg (live): create burst took ${_fwd_elapsed}s" "expected >= $((N_BASELINE - 1))s for $N_BASELINE paced creates"
fi
# (The fake-clock pacing seam + retry-after backoff unit variants run
# unattended in tracker-migrate-forward-test.sh § 2.8.7/2.8.8.)

MAPPING_FILE="$WORK_ROOT/.pack-tracker/id-map.json"
[[ -f "$MAPPING_FILE" ]] || die "forward run 1 left no id-map.json"
MAPPING_JSON=$(cat "$MAPPING_FILE")

# Count oracle (PLAN § C-7): tree BEFORE == pack-owned Issues.
N_ISSUES=$(count_scratch_issues)
assert_eq "count oracle: baseline tree ($N_BASELINE) == work-item-lane issues" "$N_BASELINE" "$N_ISSUES"

# Identity oracle: the SET of pack-ids, tree vs Issue body markers.
assert_eq "identity oracle: tree id-set == issue pack-id marker set" \
    "$(tree_id_set "$BASELINE_DIR" | tr '\n' ' ')" "$(issue_id_set | tr '\n' ' ')"

# Helper: gh issue number for a pack-id (via the id-map).
gh_id_for() {
    printf '%s' "$MAPPING_JSON" | jq -r --arg k "$1" '.[$k].id // empty'
}

# ─────────────────────────────────────────────────────────────────
# DS-1 — stored byte-verbatim (§11.2): read each STORED Issue body
# back from GH, decode the gz64 blob, assert byte-identical to the
# baseline file's span (back-pointer stripped). Confirms GH stores the
# HTML comment + blob with no rewrite.
# ─────────────────────────────────────────────────────────────────
echo "── DS-1 stored byte-verbatim (content-faithfulness, live) ──"
_ds1_fail=0
for _f in "$BASELINE_DIR"/BD-*.md; do
    _pid=$(pe_id_from_filename "$_f")
    _gid=$(gh_id_for "$_pid")
    [[ -n "$_gid" ]] || { t_fail "DS-1: $_pid has no id-map entry"; _ds1_fail=1; continue; }
    _stored_body=$(gh api "repos/$SCRATCH_REPO/issues/$_gid" --jq .body 2>/dev/null)
    _decoded_file="$WORK_BASE/ds1-decoded-$_pid"
    if ! printf '%s' "$_stored_body" | _tmr_decode_body_blob "$_gid" > "$_decoded_file" 2>/dev/null; then
        t_fail "DS-1: $_pid blob failed to decode from the STORED body"; _ds1_fail=1; continue
    fi
    # Strip the decoder's trailing sentinel X (the $(...)-capture guard).
    python3 - "$_decoded_file" <<'PYEOF'
import sys
p = sys.argv[1]
data = open(p, "rb").read()
if data.endswith(b"X"):
    data = data[:-1]
open(p, "wb").write(data)
PYEOF
    _orig_file="$WORK_BASE/ds1-orig-$_pid"
    pe_strip_backpointer_stdin < "$_f" > "$_orig_file"
    if cmp -s "$_orig_file" "$_decoded_file"; then
        t_pass "DS-1: $_pid stored blob decodes byte-identical to the original span"
    else
        t_fail "DS-1: $_pid stored blob differs from the original span" "$(cmp "$_orig_file" "$_decoded_file" 2>&1 | head -1)"
        _ds1_fail=1
    fi
done
[[ "$_ds1_fail" -eq 0 ]] || die "DS-1 failed — the stored-byte-verbatim assumption does not hold; do NOT proceed to C-8"

# ─────────────────────────────────────────────────────────────────
# KU-OPS-6 — autolink-neutralization leg (live render check): the
# 4-form fixture (BD-904) renders NO live link of ANY form; the blob
# already decoded verbatim in DS-1.
# ─────────────────────────────────────────────────────────────────
echo "── KU-OPS-6 autolink render (live) ──"
_904_gid=$(gh_id_for "BD-904")
_904_html=$(gh api "repos/$SCRATCH_REPO/issues/$_904_gid" \
    -H "Accept: application/vnd.github.html+json" --jq .body_html 2>/dev/null)
assert_not_contains "KU-OPS-6: rendered body has no user-mention link" "$_904_html" "user-mention"
assert_not_contains "KU-OPS-6: rendered body has no issue-link autolink" "$_904_html" "issue-link"
assert_not_contains "KU-OPS-6: rendered body has no commit-link autolink" "$_904_html" "commit-link"
assert_not_contains "KU-OPS-6: rendered body has no live URL anchor" "$_904_html" 'href="https://example.invalid'
assert_contains "KU-OPS-6: triggers render inside a code span" "$_904_html" "<code>"

# ─────────────────────────────────────────────────────────────────
# DS-3 — size leg (§3.LF.7 leg 2): the composer's overflow fail-loud
# fires above provider_body_limit − margin on the ACTUAL composed body
# (same measurement as the C-4.6 guard); a within-budget entry passes
# LIVE; an over-limit body draws the documented GH 422.
# The probe issues carry NO bd-entry label (excluded from the
# work-item-lane count oracle). Near-budget bodies are GENERATED here,
# never committed as fixtures.
# ─────────────────────────────────────────────────────────────────
echo "── DS-3 size budget (composer fail-loud + live near-budget + 422) ──"
_limit=$(_tmf_provider_capability '.body.limit')
assert_eq "DS-3: provider declares body limit" "65536" "$_limit"

# (a) Composer fail-loud OVER budget (unit variant of the same gate
#     that runs unattended in tracker-migrate-forward-test.sh § 2.8.5).
#     The payload must be INCOMPRESSIBLE (random) — a repeated-char body
#     gzips to a tiny blob and never trips the composed-body gate.
_over_raw_file="$WORK_BASE/over-budget-raw"
python3 - "$_over_raw_file" <<'PYEOF'
import base64, os, sys
# ~50000 random bytes -> a ~67k-char gz64 blob, over the 63,488 budget.
payload = base64.b64encode(os.urandom(50000)).decode("ascii")
body = "**BD-999 — over-budget probe**\nDescription: over-budget probe.\nPayload: " + payload + "\n"
open(sys.argv[1], "w").write(body)
PYEOF
_over_raw=$(cat "$_over_raw_file")
_size_err=$(tmf_compose_issue_body "BD-999" "over-budget probe." "" "" "" "$_over_raw" 2>&1)
_size_rc=$?
assert_eq "DS-3a: composer FAILS LOUD over budget (rc=1, never truncates)" "1" "$_size_rc"
assert_contains "DS-3a: overflow error names the entry + size-budget" "$_size_err" "size-budget: entry BD-999"

# (b) LIVE near-budget create succeeds (composed body just under
#     provider_body_limit − margin; the gz64 blob of an incompressible
#     random payload dominates the composed size).
_near_raw_file="$WORK_BASE/near-budget-raw"
python3 - "$_near_raw_file" <<'PYEOF'
import base64, os, sys
# ~45000 random bytes -> ~60000 base64 chars in the gz64 blob (random
# data does not compress), keeping the composed body just under the
# 65536-2048 budget.
payload = base64.b64encode(os.urandom(45000)).decode("ascii")
body = "**BD-998 — near-budget probe**\nDescription: near-budget live probe.\nPayload: " + payload + "\n"
open(sys.argv[1], "w").write(body)
PYEOF
_near_raw=$(cat "$_near_raw_file")
if ! _near_body=$(tmf_compose_issue_body "BD-998" "near-budget live probe." "" "" "" "$_near_raw"); then
    die "DS-3b: composer rejected the near-budget probe (expected within budget)"
fi
_near_bytes=$(printf '%s' "$_near_body" | wc -c | tr -d ' ')
echo "  DS-3b: composed near-budget body = $_near_bytes bytes (budget $((_limit - 2048)))"
live_step "gh api POST /repos/$SCRATCH_REPO/issues (near-budget probe, $_near_bytes bytes, NO bd-entry label)"
_near_payload="$WORK_BASE/near-budget-payload.json"
printf '%s' "$_near_body" > "$WORK_BASE/near-budget-body"
jq -n --rawfile b "$WORK_BASE/near-budget-body" '{title: "size-probe: near-budget", body: $b}' > "$_near_payload"
if gh api -X POST "repos/$SCRATCH_REPO/issues" --input "$_near_payload" --jq .number >/dev/null 2>&1; then
    t_pass "DS-3b: near-budget body accepted live (under the 65,536 stored axis)"
else
    t_fail "DS-3b: near-budget body REJECTED live" "the margin assumption needs re-measurement before C-8"
fi

# (c) LIVE over-limit body draws a 422 (the documented enforcement).
_over_payload="$WORK_BASE/over-limit-payload.json"
python3 - "$WORK_BASE/over-limit-body" <<'PYEOF'
import sys
open(sys.argv[1], "w").write("a" * 66000)
PYEOF
jq -n --rawfile b "$WORK_BASE/over-limit-body" '{title: "size-probe: over-limit", body: $b}' > "$_over_payload"
live_step "gh api POST /repos/$SCRATCH_REPO/issues (over-limit probe, 66000 bytes — expected 422)"
_422_out=$(gh api -X POST "repos/$SCRATCH_REPO/issues" --input "$_over_payload" 2>&1)
_422_rc=$?
if [[ "$_422_rc" -ne 0 ]] && printf '%s' "$_422_out" | grep -q "422"; then
    t_pass "DS-3c: over-limit body drew HTTP 422 (stored-axis enforcement confirmed)"
else
    t_fail "DS-3c: over-limit body did not draw 422" "rc=$_422_rc out=$(printf '%s' "$_422_out" | head -1)"
fi

# Helper: PATCH an issue body from a file (used by DS-2 + corrupt-blob,
# and to RESTORE the original body afterwards).
patch_issue_body() {
    local gid="$1" body_file="$2"
    local payload="$WORK_BASE/patch-payload.json"
    jq -n --rawfile b "$body_file" '{body: $b}' > "$payload"
    gh api -X PATCH "repos/$SCRATCH_REPO/issues/$gid" --input "$payload" >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────
# DS-2 — normalization-comparator leg (§3.LF.7 leg 6, live): an
# untouched-but-GH-normalized body (CRLF + trailing spaces) must NOT
# false-positive the §3.3a comparator; a one-word REAL edit MUST be
# caught; --force overrides to blob-wins. The body is RESTORED after.
# (Mock variant runs unattended in tracker-migrate-reverse-test.sh § 2.1d.)
# ─────────────────────────────────────────────────────────────────
echo "── DS-2 normalization comparator (live web-edit munging) ──"
_903_gid=$(gh_id_for "BD-903")
_903_orig="$WORK_BASE/ds2-orig-body"
gh api "repos/$SCRATCH_REPO/issues/$_903_gid" --jq .body > "$_903_orig" 2>/dev/null

# (a) Normalization-only variant: CRLF line endings + per-line trailing
#     spaces on the VISIBLE lines; marker/comment lines left untouched.
_903_norm="$WORK_BASE/ds2-norm-body"
python3 - "$_903_orig" "$_903_norm" <<'PYEOF'
import sys
body = open(sys.argv[1]).read()
out = []
for line in body.split("\n"):
    if line.startswith("<!--"):
        out.append(line)          # markers untouched (blob safety)
    elif line:
        out.append(line + "  ")   # trailing spaces (web-edit munging)
    else:
        out.append(line)
open(sys.argv[2], "w").write("\r\n".join(out))
PYEOF
live_step "gh api PATCH /repos/$SCRATCH_REPO/issues/$_903_gid (DS-2 normalization-only edit)"
patch_issue_body "$_903_gid" "$_903_norm" || die "DS-2: normalization PATCH failed"
_903_issue=$(provider_get "$_903_gid")
_ds2_out=$(tracker_migrate_reverse_reconstruct "$_903_issue" "$MAPPING_JSON" 0 2>&1)
_ds2_rc=$?
assert_eq "DS-2a: comparator does NOT false-positive an untouched-but-normalized body (rc=0)" "0" "$_ds2_rc"
[[ "$_ds2_rc" -eq 0 ]] || printf '%s\n' "$_ds2_out" | head -3 >&2

# (b) Real one-word edit in the VISIBLE Description H2 only → caught.
_903_edit="$WORK_BASE/ds2-edit-body"
python3 - "$_903_orig" "$_903_edit" <<'PYEOF'
import sys
body = open(sys.argv[1]).read()
# Edit the VISIBLE H2 section only (the marker lines, incl. the blob,
# are untouched) — simulating a direct GH web edit.
head_end = body.find("## Description")
edited = body[:head_end] + body[head_end:].replace("sub-blocks", "EDITED-blocks", 1)
open(sys.argv[2], "w").write(edited)
PYEOF
live_step "gh api PATCH /repos/$SCRATCH_REPO/issues/$_903_gid (DS-2 real one-word edit)"
patch_issue_body "$_903_gid" "$_903_edit" || die "DS-2: real-edit PATCH failed"
_903_issue=$(provider_get "$_903_gid")
_ds2b_out=$(tracker_migrate_reverse_reconstruct "$_903_issue" "$MAPPING_JSON" 0 2>&1)
_ds2b_rc=$?
assert_eq "DS-2b: a REAL visible-H2 edit MISMATCHES (rc=1, fail loud)" "1" "$_ds2b_rc"
assert_contains "DS-2b: divergence error names the issue" "$_ds2b_out" "divergence: issue #$_903_gid"
_ds2c_out=$(tracker_migrate_reverse_reconstruct "$_903_issue" "$MAPPING_JSON" 1 2>&1)
assert_eq "DS-2c: --force overrides to blob-wins (rc=0, WARN surfaced)" "0" "$?"
: "$_ds2c_out"

# Restore the original stored body before the reverse legs.
live_step "gh api PATCH /repos/$SCRATCH_REPO/issues/$_903_gid (DS-2 restore original body)"
patch_issue_body "$_903_gid" "$_903_orig" || die "DS-2: body restore failed"

# ─────────────────────────────────────────────────────────────────
# Corrupt-blob leg (§3.LF.7 leg 5, live): a deliberately corrupted
# pack-entry-body-gz64 marker makes BOTH the reconstruct AND the full
# reverse run FAIL LOUD (never an empty/partial body). Restored after.
# (Mock variant runs unattended in tracker-migrate-reverse-test.sh § 2.1b.)
# ─────────────────────────────────────────────────────────────────
echo "── corrupt-blob fail-loud (live) ──"
_905_gid=$(gh_id_for "BD-905")
_905_orig="$WORK_BASE/corrupt-orig-body"
gh api "repos/$SCRATCH_REPO/issues/$_905_gid" --jq .body > "$_905_orig" 2>/dev/null
_905_corrupt="$WORK_BASE/corrupt-body"
python3 - "$_905_orig" "$_905_corrupt" <<'PYEOF'
import re, sys
body = open(sys.argv[1]).read()
# Replace the blob payload with valid-base64-but-not-gzip garbage.
corrupted = re.sub(
    r"(<!-- pack-entry-body-gz64: )[A-Za-z0-9+/=]+( -->)",
    r"\1Tk9UVkFMSURnemlw\2", body, count=1)
open(sys.argv[2], "w").write(corrupted)
PYEOF
live_step "gh api PATCH /repos/$SCRATCH_REPO/issues/$_905_gid (corrupt the gz64 blob)"
patch_issue_body "$_905_gid" "$_905_corrupt" || die "corrupt-blob: PATCH failed"
_905_issue=$(provider_get "$_905_gid")
_cb_out=$(tracker_migrate_reverse_reconstruct "$_905_issue" "$MAPPING_JSON" 0 2>&1)
_cb_rc=$?
assert_eq "corrupt-blob: reconstruct FAILS LOUD (rc=1)" "1" "$_cb_rc"
assert_contains "corrupt-blob: error names the corrupt-blob class" "$_cb_out" "corrupt-blob"
assert_contains "corrupt-blob: error states never-empty contract" "$_cb_out" "NEVER emits an empty/partial entry body"
_cb_run_out=$(tracker_migrate_reverse_run "$WORK_ROOT" 0 0 0 0 2>&1)
_cb_run_rc=$?
assert_eq "corrupt-blob: the FULL reverse run aborts (rc!=0)" "1" "$([[ $_cb_run_rc -ne 0 ]] && echo 1 || echo 0)"
assert_contains "corrupt-blob: the full-run abort is loud" "$_cb_run_out" "corrupt-blob"
live_step "gh api PATCH /repos/$SCRATCH_REPO/issues/$_905_gid (restore original body)"
patch_issue_body "$_905_gid" "$_905_orig" || die "corrupt-blob: body restore failed"

# ─────────────────────────────────────────────────────────────────
# REVERSE run 1 (Issues → tree) + the §3.2 round-trip oracles.
# ─────────────────────────────────────────────────────────────────
echo "── reverse run 1 (Issues → tree) + round-trip oracles ──"
live_step "tracker_migrate_reverse_run (reads $SCRATCH_REPO; rewrites the /tmp work tree)"
REV1_OUT=$(tracker_migrate_reverse_run "$WORK_ROOT" 0 0 0 0 2>&1)
REV1_RC=$?
if [[ "$REV1_RC" -ne 0 ]]; then
    printf '%s\n' "$REV1_OUT" >&2
    die "reverse run 1 failed (rc=$REV1_RC)"
fi
assert_contains "reverse 1: completed" "$REV1_OUT" "reverse: complete."

# Content-faithfulness oracle: per entry, the reconstructed span equals
# the original span, back-pointer stripped (PLAN § C-7 oracle leg 3).
verify_tree_faithful() {
    local label="$1" base_dir="$2" after_dir="$3"
    local f pid a b clean=0
    for f in "$base_dir"/BD-*.md; do
        pid=$(pe_id_from_filename "$f")
        if [[ ! -f "$after_dir/$pid.md" ]]; then
            t_fail "$label: $pid.md missing from the reconstructed tree"
            clean=1
            continue
        fi
        a="$WORK_BASE/cmp-a"; b="$WORK_BASE/cmp-b"
        pe_strip_backpointer_stdin < "$f" > "$a"
        pe_strip_backpointer_stdin < "$after_dir/$pid.md" > "$b"
        if ! cmp -s "$a" "$b"; then
            t_fail "$label: $pid reconstructed span differs from the original" \
                "$(diff "$a" "$b" | head -3 | tr '\n' ' ')"
            clean=1
        fi
    done
    [[ "$clean" -eq 0 ]] && t_pass "$label: every entry byte-faithful (back-pointer stripped)"
    return "$clean"
}
verify_tree_faithful "content oracle (cycle 1)" "$BASELINE_DIR" "$WORK_ROOT/backlog" || true

# Count + identity oracles AFTER reverse.
N_AFTER=$(count_tree_entries "$WORK_ROOT/backlog")
assert_eq "count oracle: tree AFTER ($N_AFTER) == BEFORE ($N_BASELINE)" "$N_BASELINE" "$N_AFTER"
assert_eq "identity oracle: id-set AFTER == BEFORE" \
    "$(tree_id_set "$BASELINE_DIR" | tr '\n' ' ')" "$(tree_id_set "$WORK_ROOT/backlog" | tr '\n' ' ')"

# Status oracle: the status DISTRIBUTION before == after; the Deferred
# count is the canary (PLAN § C-7 oracle leg 4).
status_dist() { grep -h '^Status:' "$1"/BD-*.md | LC_ALL=C sort | uniq -c | sed 's/^ *//' | tr '\n' ';'; }
assert_eq "status oracle: distribution BEFORE == AFTER" \
    "$(status_dist "$BASELINE_DIR")" "$(status_dist "$WORK_ROOT/backlog")"
_def_before=$(grep -hc '^Status: Deferred$' "$BASELINE_DIR"/BD-*.md | awk '{s+=$1} END {print s}')
_def_after=$(grep -hc '^Status: Deferred$' "$WORK_ROOT/backlog"/BD-*.md | awk '{s+=$1} END {print s}')
assert_eq "status oracle: Deferred canary count round-trips" "$_def_before" "$_def_after"

# No-monolith / no-sidecar oracle (PLAN § C-7 oracle leg 5).
if [[ ! -f "$WORK_ROOT/pack-ops/BACKLOG.md" ]]; then
    t_pass "no-monolith oracle: pack-ops/BACKLOG.md never written"
else
    t_fail "no-monolith oracle: pack-ops/BACKLOG.md EXISTS (Check 32′ violation)"
fi
if ! ls "$WORK_ROOT/.pack-tracker"/reverse.sidecar.* >/dev/null 2>&1; then
    t_pass "no-sidecar oracle: no reverse.sidecar.* written on the pack surface"
else
    t_fail "no-sidecar oracle: a reverse sidecar file was written"
fi
[[ -f "$WORK_ROOT/backlog/_toc.md" ]] \
    && t_pass "tree regen: _toc.md regenerated (DP-4)" \
    || t_fail "tree regen: _toc.md missing after reverse"

# ─────────────────────────────────────────────────────────────────
# Repeated-cycle oracle (PLAN § C-7 oracle leg 6): on/off/on/off
# converges — the second forward is a no-op skip-all; the second
# reverse reproduces the baseline again.
# ─────────────────────────────────────────────────────────────────
echo "── repeated cycle (forward 2 / reverse 2) ──"
live_step "tracker_migrate_forward_run (cycle 2 — expected skip-all, 0 creates)"
FWD2_OUT=$(tracker_migrate_forward_run "$WORK_ROOT" 0 0 2>&1)
FWD2_RC=$?
[[ "$FWD2_RC" -eq 0 ]] || printf '%s\n' "$FWD2_OUT" | tail -10 >&2
assert_eq "repeated-cycle: forward 2 rc=0" "0" "$FWD2_RC"
assert_contains "repeated-cycle: forward 2 created NOTHING (idempotent)" "$FWD2_OUT" "created:    0"
assert_contains "repeated-cycle: forward 2 skipped every entry" "$FWD2_OUT" "skipped:    $N_BASELINE"
N_ISSUES_2=$(count_scratch_issues)
assert_eq "repeated-cycle: issue count unchanged after forward 2" "$N_BASELINE" "$N_ISSUES_2"
live_step "tracker_migrate_reverse_run (cycle 2)"
REV2_OUT=$(tracker_migrate_reverse_run "$WORK_ROOT" 0 0 0 0 2>&1)
REV2_RC=$?
[[ "$REV2_RC" -eq 0 ]] || printf '%s\n' "$REV2_OUT" | tail -10 >&2
assert_eq "repeated-cycle: reverse 2 rc=0" "0" "$REV2_RC"
verify_tree_faithful "content oracle (cycle 2 converges)" "$BASELINE_DIR" "$WORK_ROOT/backlog" || true

# ─────────────────────────────────────────────────────────────────
# Interleaved-CRUD oracle (PLAN § C-7 oracle leg 6, second half):
# provider_create a NEW BD + a blob-consistent status update, reverse,
# assert the new BD appears + the status round-trips + re-forward
# re-creates (i.e. already-has) the state.
# ─────────────────────────────────────────────────────────────────
echo "── interleaved CRUD (create BD-908 + status update BD-904) ──"
_908_raw="**BD-908 — Interleaved-CRUD create**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
Description: Created via provider_create mid-cycle; must appear in the
  tree after the next reverse with this body verbatim.
Resolved: n/a
"
_908_raw_file="$WORK_BASE/bd908-raw"
printf '%s' "$_908_raw" > "$_908_raw_file"
_908_parsed=$(_tmf_parse_backlog_file "$_908_raw_file")
_908_desc=$(printf '%s' "$_908_parsed" | jq -r '.[0].description // ""')
_908_body=$(tmf_compose_issue_body "BD-908" "$_908_desc" "" "" "" "$_908_raw") \
    || die "CRUD: composer failed for BD-908"
_908_payload=$(jq -n --arg t "BD-908: Interleaved-CRUD create" --arg b "$_908_body" \
    '{title: $t, body: $b, labels: ["bd-entry", "template:bd-v11.0", "status:open"]}')
live_step "provider_create (BD-908) on $SCRATCH_REPO"
_tmf_pace_before_create
_908_result=$(provider_create "$_908_payload") || die "CRUD: provider_create BD-908 failed"
_908_gid=$(printf '%s' "$_908_result" | jq -r '.id')
# Register the create in the id-map exactly as the forward loop does
# after each create (mapping persist per create). This also keeps the
# re-forward skip deterministic — GH's SEARCH index lags new issues by
# minutes, so relying on the title-marker search recovery path here
# would be a flake generator, not an oracle.
MAPPING_JSON=$(tmf_mapping_set "$MAPPING_JSON" "BD-908" "$_908_gid" "")
tmf_mapping_save "$MAPPING_FILE" "$MAPPING_JSON"
t_pass "CRUD: BD-908 created (gh #$_908_gid) + id-map updated"

# Blob-consistent status update (the §3.3a contract: a tracker-side
# edit regenerates the H2 AND the blob from the SAME entry atomically;
# the status label swap rides the same provider_update).
_904_after_raw="$WORK_BASE/bd904-deferred-raw"
pe_strip_backpointer_stdin < "$WORK_ROOT/backlog/BD-904.md" \
    | sed 's/^Status: Unblocked$/Status: Deferred/' > "$_904_after_raw"
_904_new_raw=$(cat "$_904_after_raw"; printf X); _904_new_raw="${_904_new_raw%X}"
_904_parsed=$(_tmf_parse_backlog_file "$_904_after_raw")
_904_desc=$(printf '%s' "$_904_parsed" | jq -r '.[0].description // ""')
_904_new_body=$(tmf_compose_issue_body "BD-904" "$_904_desc" "" "" "" "$_904_new_raw") \
    || die "CRUD: composer failed for the BD-904 status update"
_904_update=$(jq -n --arg b "$_904_new_body" \
    '{body: $b, add_labels: ["status:deferred"], remove_labels: ["status:unblocked"]}')
live_step "provider_update (BD-904 status Unblocked → Deferred, blob+H2 synced)"
provider_update "$(gh_id_for "BD-904")" "$_904_update" >/dev/null \
    || die "CRUD: provider_update BD-904 failed"
t_pass "CRUD: BD-904 status updated (blob + H2 + label in one write)"

live_step "tracker_migrate_reverse_run (cycle 3 — post-CRUD)"
REV3_OUT=$(tracker_migrate_reverse_run "$WORK_ROOT" 0 0 0 0 2>&1)
REV3_RC=$?
[[ "$REV3_RC" -eq 0 ]] || printf '%s\n' "$REV3_OUT" | tail -10 >&2
assert_eq "CRUD: reverse 3 rc=0" "0" "$REV3_RC"
# The new BD appears, verbatim.
if [[ -f "$WORK_ROOT/backlog/BD-908.md" ]]; then
    _a="$WORK_BASE/cmp-a"; _b="$WORK_BASE/cmp-b"
    printf '%s' "$_908_raw" > "$_a"
    pe_strip_backpointer_stdin < "$WORK_ROOT/backlog/BD-908.md" > "$_b"
    cmp -s "$_a" "$_b" \
        && t_pass "CRUD: BD-908 appears in the tree byte-verbatim" \
        || t_fail "CRUD: BD-908 tree body differs from the created raw span"
else
    t_fail "CRUD: BD-908.md missing from the reconstructed tree"
fi
# The status round-trips (body line + the distribution shift).
grep -q '^Status: Deferred$' "$WORK_ROOT/backlog/BD-904.md" \
    && t_pass "CRUD: BD-904 status round-trips as Deferred" \
    || t_fail "CRUD: BD-904 status did not round-trip (expected Deferred)"
N_AFTER_CRUD=$(count_tree_entries "$WORK_ROOT/backlog")
assert_eq "CRUD: count oracle after create" "$((N_BASELINE + 1))" "$N_AFTER_CRUD"
# Re-forward re-creates (already has) the state: 0 creates, all skips.
live_step "tracker_migrate_forward_run (cycle 3 — post-CRUD, expected skip-all)"
FWD3_OUT=$(tracker_migrate_forward_run "$WORK_ROOT" 0 0 2>&1)
FWD3_RC=$?
[[ "$FWD3_RC" -eq 0 ]] || printf '%s\n' "$FWD3_OUT" | tail -10 >&2
assert_eq "CRUD: re-forward rc=0" "0" "$FWD3_RC"
assert_contains "CRUD: re-forward created NOTHING (state already on the tracker)" "$FWD3_OUT" "created:    0"
assert_contains "CRUD: re-forward sees all $((N_BASELINE + 1)) entries" "$FWD3_OUT" "entries:    $((N_BASELINE + 1))"

# ─────────────────────────────────────────────────────────────────
# DISPOSAL (§3.LF.7 leg 8): ARCHIVE the scratch repo (tool-performed
# end-state; read-only), assert isArchived, recommend manual delete
# (the trap prints the RECOMMEND line on exit).
# ─────────────────────────────────────────────────────────────────
echo "── disposal: archive-not-delete ──"
live_step "gh repo archive $SCRATCH_REPO --yes (capability probe: repo-archive)"
if gh repo archive "$SCRATCH_REPO" --yes >/dev/null 2>&1; then
    ARCHIVED=1
else
    die "credential-preflight: token missing repo-archive permission required for scratch disposal; the scratch repo is a WRITABLE ORPHAN — archive it manually NOW"
fi
_is_archived=$(gh repo view "$SCRATCH_REPO" --json isArchived --jq .isArchived 2>/dev/null)
assert_eq "disposal: scratch repo isArchived == true (read-only end-state)" "true" "$_is_archived"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
echo ""
echo "── BD-204 live lossless oracle: $PASS passed, $FAIL failed ──"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
`````

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Only read-only git verbs issued this session: `git rev-parse HEAD` → `c30c8d56082a9466a1164c94925667592a5a31bf`; `git status --short` → `?? scripts/tests/fixtures/tracker-bd204-lossless/` + `?? scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (nothing staged); `git log --all -- <test path>` (empty); `git diff --stat test-fixtures/manifest.txt` (empty). No `git add/commit/push/tag/checkout` run. The battery's CI-only `git checkout HEAD -- test-fixtures/manifest.txt` line was SKIPPED with that reason logged (`[52/59] SKIP (CI-only revert; … git state-change)`). | COMPLIANT |
| 2 | per-action-approval-sub-agents | `PACK_TRACKER_LIVE_GH` never set (verification used `env -u PACK_TRACKER_LIVE_GH`); SKIP-path run measured `real 0.00` — gh never invoked; no `gh repo create` / issue write / archive executed; no `rm -rf` outside self-created mktemp dirs; no trusted file overwritten (all three deliverables are NEW paths, find-verified empty before write). | COMPLIANT |
| 3 | preflight-stop-means-stop | The single line `PREFLIGHT: 3/3 in-scope edits complete; verification PASS; HEAD c30c8d56082a9466a1164c94925667592a5a31bf; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-7.md` was emitted AFTER all verification rows in §4 passed (validate-pack 1.46 s green; battery `BATTERY-RESULT: fails=0 skipped=3 of 59`, real 478.61 s) and BEFORE this report was written. No stop/halt message was received at any point. | COMPLIANT |
| 4 | rules-applied-verification-block | This table — per-rule quoted evidence, terminal conclusions only (no AMBIGUOUS, no empty evidence). | COMPLIANT |
| 5 | test-infra-self-provisioned | The BUILT test encodes the contract (never executed live by me): unique scratch name `SCRATCH_NAME="pack-bd204-oracle-$$-$(date +%s)"`; defense-in-depth `case "$SCRATCH_NAME" in pack-bd204-oracle-*)` refusal + `case "$(tracker_repo_slug …)" in */pack-bd204-oracle-*)` on the configured slug; disposal `gh repo archive "$SCRATCH_REPO" --yes` + `isArchived == true` assert + trap-archive-on-failure + RECOMMEND line; verified via the SKIP path only (`SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0). | COMPLIANT |
| 6 | regenerate-manifest-v11-surface | Diff includes `scripts/` → `bash test-fixtures/build.sh --all --clean` run (battery item `[51/59] PASS`) + `[53/59] PASS: bash test-fixtures/build.sh --verify`; `git diff --stat test-fixtures/manifest.txt` → EMPTY output; `grep -c "tracker-bd204-lossless" test-fixtures/manifest.txt` → `0` (the manifest tracks built `test-fixtures/*` outputs, which the new `scripts/tests/` files do not feed). Rule requires staging only "when the manifest diff is non-empty" → nothing owed. | COMPLIANT |
| 7 | filename-uniqueness-heuristic | Pre-creation: `find . -name "tracker-bd204-lossless-roundtrip-test.sh" -not -path "./.git/*"` → no output; `find . -name "tracker-bd204-lossless" …` → no output; `git log --all --oneline -- scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` → no output. Fixture-internal `BACKLOG.md`/`tracker.toml` collisions: `find . -name "BACKLOG.md" -path "*/fixtures/*"` shows the pre-existing `fixtures/tracker-migrate/BACKLOG.md` + `fixtures/roundtrip/bd-v11.0/BACKLOG.md` convention (structural exemption); all prose refs in test + report carry full paths. | COMPLIANT |
| 8 | pack-repo-code-comment-deferrals | `grep -nE "TODO|FIXME|fix later" <new files>` → every hit is a `Type: TODO(version)` line, i.e. the canonical BD entry-grammar FIELD VALUE inside fixture DATA (the BACKLOG.md entries + the BD-908 raw-body heredoc at test line 681), not a code comment. Zero `#`-comment deferral markers (untyped or typed) exist in the new files — nothing is deferred in code. | COMPLIANT |
| 9 | deferral-is-scope-creep + no-deferral-without-user-direction | Full §3.LF.7 scope (legs 1–10 + base oracle legs) implemented now — §2 maps every leg to its implementation. Nothing deferred; §7 surfaces one as-built OBSERVATION (forward re-close idempotency, confirmable only at the user-gated live rehearsal) for Pack Chat triage rather than self-authorizing any deferral. | COMPLIANT |
| 10 | verify-full-ci-suite | The ENTIRE workflow `run:` set executed in order (59 lines enumerated from `.github/workflows/validate-pack.yml`; `grep -c "run:"` → 59): `BATTERY-RESULT: fails=0 skipped=3 of 59`, including the integration tests (`[54/59] PASS: bash scripts/tests/test-v11-realistic-ot.sh`, all `test-migrate-v10-to-v11*` PASS) — not validate-pack alone. The 3 skips are non-test lines (2× `pip install pyyaml`, 1× CI-only git revert), each logged with reason and the revert's assertion covered by `--verify` PASS. | COMPLIANT |
| 11 | ci-check-runtime-compounding | New test's unattended cost MEASURED, not estimated: `/usr/bin/time -p` on the SKIP path → `real 0.00`; it is invoked by zero battery files (`grep tracker-bd204-lossless .github/workflows/validate-pack.yml` → no match), so battery contribution = 0. General validate-pack stayed baseline (`real 1.46`); deep run `real 3.10`; full battery COMPLETED at `real 478.61` (~8 min — the completion gate the prior 1.5 h+ hang failed). | COMPLIANT |
| 12 | enumerate-encoding-surfaces | The change introduces no new validator-pinned output and alters none: the new test prints its own lines only and is referenced by no workflow/validator/test (grep above). Surfaces that ENCODE the unit-leg expectations were enumerated and left consistent — `tracker-migrate-forward-test.sh` §2.8/2.9, `tracker-migrate-reverse-test.sh` §2.1b/2.1d, `test-validate-pack-check-49-field-faithfulness.sh`, `.github/workflows/validate-pack.yml` — all UNTOUCHED and all PASS in the battery; the new test's header cross-references them as the unattended homes (lock-step by citation, no assertion drift introduced). | COMPLIANT |
