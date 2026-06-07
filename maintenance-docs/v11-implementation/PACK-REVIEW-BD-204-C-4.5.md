# PACK-REVIEW — BD-204 C-4.5 (field-faithful gz64 body-blob carrier)

- **Reviewer:** pack-reviewer (adversarial; re-measured every IMPL-REPORT claim)
- **Branch:** `v11-dev` · **HEAD SHA:** `e63476a53df135e2f99ec409316cf0601ec243e7`
- **Date:** 2026-06-07
- **Scope reviewed:** working-tree change for C-4.5 — `scripts/lib/tracker-migrate-forward.sh`,
  `tracker-migrate-reverse.sh`, `tracker-provider-gh.sh`; `scripts/tests/tracker-migrate-forward-test.sh`,
  `-reverse-test.sh`, `-roundtrip-test.sh`, `tracker-provider-test.sh`;
  `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` + the IMPL-REPORT (verified, not trusted).
- **Spec:** `PLAN-BD-204.md` §3.LF.3 / §3.LF.9; `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3/§3.3a–d/§4/§7.

## VERDICT: PROCEED (clean)

All 7 hard invariants hold against the actual code. Both coder CONCERNS adjudicated
**FAITHFUL** (neither a deviation-needing-architect nor an overstep). New test legs
have real teeth (verified by running the new tests against the pre-fix lib). Full
unattended battery (51 scripts) + `validate-pack.py` GREEN. Scope is exactly the 8
files + IMPL-REPORT; pack-only clean; no fenced-out target touched. No overstep
found. No new POQ beyond the 4 the coder surfaced (all benign / out-of-scope).

BLOCKER: none. MUST: none. SHOULD: none. NIT: 2 (advisory only — see below).

---

## The 7 hard invariants

### Invariant 1 — CODEC (python3 gzip mtime=0; decode-identity, no blob-byte assertion) — HELD
- `_tmf_gz64_encode` uses `gzip.GzipFile(..., mode="wb", mtime=0)` + base64; reverse
  `_tmr_decode_body_blob` uses python3 `base64.b64decode(validate=True)` + `gzip.GzipFile`.
  No shell `gzip(1)`/`base64(1)` on any path.
- **Decode-identity re-measured independently across ALL 211 entries** (I drove the real
  `_tmf_parse_backlog_file` → `tmf_compose_issue_body` → `_tmr_decode_body_blob` and
  `cmp`'d the decoded raw_body to `pe_strip_backpointer_stdin < backlog/BD-*.md`):
  `PASS=211 FAIL=0`. Hazard entries individually byte-identical: BD-136 (27954 B, `-->`+fence),
  BD-204 (12827 B, no-Description/shred), BD-001 (190 B), BD-021/BD-023 (multi-paragraph),
  BD-167/BD-169 (interior-H2 — see C2).
- The binding assertion in code/tests is **decode-identity**; the only encode-stability
  assertion (forward-test 2.8.2) is scoped as `mtime=0` determinism within one machine,
  not a cross-env blob-byte-identity claim. No impl-specific byte assertion exists.

### Invariant 2 — CORRUPT-BLOB FAIL-LOUD (never silent-empty) — HELD
- Independently exercised `_tmr_decode_body_blob`: malformed base64 → `corrupt-blob:
  issue #1 ... (no base64 payload); reverse aborted` rc=1; valid-base64-not-gzip →
  `... (invalid base64/gzip/CRC) ...` rc=1; truncated/CRC-fail → same rc=1; ABSENT
  marker (legacy/phase) → rc=0, empty body (1-byte sentinel only). No silent-empty path
  on a present-but-bad blob. `tracker_migrate_reverse_reconstruct` propagates the rc=1
  (`if ! raw_body=$(... _tmr_decode_body_blob ...); then return 1`).

### Invariant 3 — SIZE BUDGET on STORED bytes of ACTUAL composed body vs ACTIVE provider limit — HELD
- `grep 65536 scripts/lib/tracker-migrate-*.sh` → exactly ONE hit, the comment
  "(NO hardcoded 65536)" at `tracker-migrate-forward.sh:861`. No literal in any branch.
- Independently drove the composer with a stub backend: tiny limit (500) + big body →
  `size-budget: entry BD-999 projected body 5193 bytes exceeds provider body limit 500
  (margin 2048); forward aborted ... the migrator NEVER truncates` rc=1. The 5193-byte
  figure is the COMPOSED body (H2+markers+blob), not the 5000-byte raw input — confirming
  the STORED-bytes-of-composed-body axis (`body_bytes=$(printf '%s' "$body" | wc -c ...)`).
- `rich_text_normalizing` backend → `requires raw_text — unsupported backend for v11.x`
  rc=1. Within-budget (65536, normal body) → rc=0. Never truncates on any path.

### Invariant 4 — NEUTRALIZATION = VISIBLE H2 PROJECTION ONLY (blob never modified) — HELD
- Code-path proof: in `tmf_compose_issue_body`, `blob=$(printf '%s' "$raw_body" |
  _tmf_gz64_encode)` — raw_body goes straight to the encoder. Only `description/context/
  resolution/file_symbol` are routed through `_tmf_neutralize_autolinks`. raw_body never
  touches the neutralizer. The 211/211 byte-identical decode (Invariant 1) is the empirical
  proof the blob is unmodified — a 4-form trigger entry decodes to the verbatim original
  tokens while its H2 projection is code-span-wrapped (forward-test 2.8.4, re-confirmed).

### Invariant 5 — EMIT REWRITE = PACK branch ONLY; `_tmr_emit_backlog` byte-untouched — HELD
- `git diff` hunks in reverse.sh land only at: `tracker_migrate_reverse_reconstruct`
  (555–617), the new `_tmr_decode_body_blob` helper, and `_tmr_emit_pack_tree` (comment
  block + the python render at 739–823). Every `_tmr_emit_backlog` token in the diff is a
  COMMENT line; the function BODY carries zero diff hunks. Surface split intact:
  `[[ "$surface" == "pack" ]]` → `_tmr_emit_pack_tree` (1312), `else` →
  `_tmr_emit_backlog` (1328). The deleted lossy projection (`Blockers: None`/`Unblocks:
  None`/`Resolved: n/a` injection + dead `extra_fields` read) is gone from the PACK
  branch only.

### Invariant 6 — H2 sections + pack-id/template_version/pack-version trio still emit; blob ADDED alongside — HELD
- Composer emits trio (pack-id/template_version/pack-version), THEN the blob marker as an
  added line, THEN `## Description`/`## File / Symbol`/`## Context`/`## Resolution`
  unchanged in shape. forward-test 2.5 substring asserts (unchanged) PASS; the 168/0
  forward-test run confirms the existing shape asserts hold with the blob added.

### Invariant 7 — 20 no-Blockers entries: no injected `Blockers: None`/`Resolved: n/a`; reverse-test asserts it — HELD
- `assert_not_contains` is a real helper (reverse-test.sh:27, roundtrip-test.sh:44 — not a
  no-op). Reverse-test 4.2 asserts the reconstructed BD-001 (a no-Blockers entry) is
  byte-identical to source AND `assert_not_contains` for `Blockers: None` / `Unblocks:
  None` / `Resolved: n/a`. Roundtrip 2.2d asserts the same on BD-003. The all-211
  byte-identical round-trip (Invariant 1) covers all 20 no-Blockers entries empirically.

---

## CONCERN adjudications (the overstep check)

### C1 — `tracker-provider.sh` has NO diff (recipe names it) → **FAITHFUL**
- (a) The migrator reads the limit THROUGH the abstraction: `_tmf_provider_capability` →
  `provider_capabilities` → `_tracker_provider_dispatch capabilities` →
  `tracker_provider_gh_capabilities`. It never reaches into `tracker-provider-gh.sh`
  directly. Confirmed `provider_capabilities()` is the generic dispatch (tracker-provider.sh:141).
- (b) The capability mechanism is generic pass-through: `grep` for any capability-key
  registration/validation/schema in `tracker-provider.sh` → NONE. A non-GH backend declares
  its caps freely — proven by the stub backend (`tracker_provider_stub_capabilities` echoes
  arbitrary JSON) and by provider-test 1.1c, which overrides the stub to declare `body.limit`
  with ZERO change to `tracker-provider.sh` and the migrator reads it correctly (smaller-limit
  mock fails loud at its own bound; same body passes under GH's 65536). The 4 new caps need
  no registration.
- (c) The recipe's naming of `tracker-provider.sh` is SATISFIED: that file is the abstraction
  the migrator reads through, and the design's intent ("each provider DECLARES ... the
  migrator reads the ACTIVE provider's limit ... not tacitly GH-sized") is exactly realized
  by declaring values in the GH backend and reading via the generic dispatcher. Adding a
  hardcoded value to `tracker-provider.sh` would VIOLATE the tracker-agnosticism the same
  §3.3c demands. Faithful, not an overstep.

### C2 — raw_body capture DECOUPLED from the projection's H2-flush (BD-167/BD-169) → **FAITHFUL**
- (a) This is the literal realization of the recipe's "verbatim lines 2..EOF, no re-parse,
  no parse_id_list, no continuation folding." The pre-existing parser flushes the projection
  entry on an interior `## ` H2 line; riding raw_body on that flush would truncate BD-167/
  BD-169 (which carry in-body `## Sub-entry b — ...` sections per BD-211). The capture is
  bounded only by `**BD-NNN — ...**`/`---`; the interior H2 is appended to raw_lines as
  content. This honors the recipe's stated intent, not a different mechanism.
- (b) It changes NO field-logic / carried-field parse / H2 projection for other entries. I
  re-parsed BD-167 with the worktree lib: description/blockers/unblocks/file_symbol/status/
  type all populate correctly and the interior `## Sub-entry` content is correctly EXCLUDED
  from the projected description (the projection still closes on H2). raw_body capture is
  purely additive (`if raw_lines is not None: raw_lines.append(line)`), running before the
  `current is None` guard so post-H2 content is captured for the blob only.
- (c) BD-167 AND BD-169 round-trip BYTE-IDENTICAL — re-measured myself via the real forward/
  reverse functions: BD-167 (4879 B) cmp-clean; BD-169 (4373 B) cmp-clean; both inside the
  211/211 PASS. No architecture change; no field logic changed. Faithful.

---

## Also-verified

- **TEETH (verified by running the NEW tests against the PRE-FIX lib):** I `git stash`'d
  the worktree `tracker-migrate-reverse.sh`, ran the NEW reverse-test against HEAD's lib:
  `Failed: 8` — exactly the new legs fail: 2.1b corrupt-blob (no decode existed), 2.1c
  decode-identity, 4.2 byte-faithful, and the `Blockers: None`/`Unblocks: None`/`Resolved:
  n/a` no-injection legs (the pre-fix emit literally injects `Blockers: None`). Restored the
  worktree lib cleanly (`cmp` confirmed). The byte-faithful + no-Blockers-None legs have real
  teeth. (Size/neutralization/pacing legs likewise reference symbols absent on the pre-fix
  forward.)
- **FULL BATTERY (verify-full-ci-suite):** ran the ENTIRE unattended battery enumerated from
  `.github/workflows/validate-pack.yml` (`run: bash scripts/...` lines): 51 scripts →
  PASS=51 FAIL=0. `validate-pack.py` → `PASSED — all checks clean` (Check 47 clean; Check 48
  advisory WARNs only). The 4 emphasized: forward 168/0, reverse 119/0, roundtrip 51/0,
  provider 121/0; `test-v11-realistic-ot.sh` PASS (banner-pinning unaffected).
- **MANIFEST:** the coder's empty-diff claim is CORRECT. The fixtures embed `scripts/lib/`
  ONLY for `detect.sh` (the sanctioned-shipped file); the edited migrator libs
  (`tracker-migrate-*.sh`, `tracker-provider-gh.sh`) are absent from every fixture
  (`find test-fixtures -name 'tracker-migrate-*.sh' -o -name 'tracker-provider-gh.sh'` →
  empty). I ran `bash test-fixtures/build.sh --all --clean` and `cmp`'d manifest.txt
  before/after → IDENTICAL. Empty diff ⇒ nothing to stage; the regenerate-manifest rule is
  satisfied (regen run, non-empty-only staging requirement not triggered).
- **SCOPE/FENCE:** `git status --short` = exactly the 8 in-scope files + the untracked
  IMPL-REPORT. No `project-template/`/`supporting-docs/` (pack-only clean). No
  `validate-pack.py` (C-4.6), no `tracker-edit.sh` (C-3), no `_rules.md` (C-4.7), no
  `backlog/BD-*.md`, no live GH. No new POQ beyond the coder's 4 surfaced concerns.
- **OVERSTEP SWEEP:** added gh.sh keys = exactly `body.{limit,storage_format}` +
  `rate_limits.{min_write_interval_s,writes_per_hour_max}` (nested under the existing
  capabilities JSON — a faithful adaptation to the existing `rate_limits` structure, not the
  flat `provider_*` names; conceptually identical). New functions = exactly
  `_tmf_gz64_encode`, `_tmf_neutralize_autolinks`, `_tmf_provider_capability`,
  `_tmf_pace_before_create`, `_tmf_create_backoff`, `_tmr_decode_body_blob` — all named in
  §3.LF.3 / §3.3a–d. No extra helpers, no adjacent refactor, no "while I'm here" cleanup.

## NITs (advisory only — no fix required this commit; surfaced for record)

- **NIT-1 (coder CONCERN #3, agreed):** `TMF_SIZE_SAFETY_MARGIN` default 2048 makes a
  hypothetical sub-2KB-limit `raw_text` provider compute a negative budget and fail every
  entry. No live risk (GH 65536; Trello 16384; Jira 32767 all clear it; design floor ~43 KB).
  Not in C-4.5 scope; a future BD could clamp the margin to `min(margin, limit//2)` or warn.
- **NIT-2:** the benign `line 376: issue: command not found` heredoc-expansion artifact
  emitted once to stderr by `tracker-migrate-forward-test.sh` is PRE-EXISTING (not introduced
  by this commit) and fails no assertion (168/0). Cosmetic; out of scope.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No git state-changing verb run. Used read-only `git rev-parse/status/diff/show/stash` — the one `stash push`+`stash pop` (teeth test) restored the worktree to identical bytes (`cmp` clean); HEAD unchanged at `e63476a5…` start and end. | COMPLIANT |
| `empirical-evidence-blocks` (findings backed by measurement) | Every invariant + concern carries the actual command/output: 211/211 `cmp` round-trip, `grep 65536` (1 comment hit), stub-backend size-fail rc=1 with quoted message, corrupt-blob rc=1 messages, `git stash` teeth run `Failed: 8`, battery `PASS=51 FAIL=0`, manifest `cmp` identical — all at HEAD `e63476a5`, 2026-06-07. | COMPLIANT |
| `verify-full-ci-suite` | Ran the ENTIRE workflow battery (51 `run: bash scripts/...` scripts) + `validate-pack.py`, not a subset; `test-v11-realistic-ot.sh` included → all green. | COMPLIANT |
| `enumerate-encoding-surfaces` | Confirmed lock-step movement: carrier libs (forward/reverse) + GH backend + all 4 named test files + the roundtrip fixture all changed together; the fake-gh fixtures carry the blob; entry counts updated (2→3 BD, 4→5 issues). No asymmetric coverage found. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered the 7-invariant + 2-concern + also-verify + verdict report; no redesign authored; empty severity sections stated. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | Verified pack-only boundary: `git diff --name-only` shows only `scripts/` paths; no `project-template/`/`supporting-docs/`. Read-only on the codebase except the single report write. | COMPLIANT |
| `rules-applied-verification-block` | This table (per-rule name + quoted evidence + conclusion; no empty rows). | COMPLIANT |

## READ-IN-FULL attestation

Read in full for this review: `PLAN-BD-204.md` §3.LF.3 + §3.LF.9 (+ surrounding §3.LF
table); `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3/§3.3a/§3.3b/§3.3c/§3.3d/§4 (4.1–4.5)/§7
(regression table R1–R-DISPOSAL); all 8 changed files via `git diff`; the abstraction
`scripts/lib/tracker-provider.sh` (dispatch) + the GH backend capabilities; the roundtrip
fixture; `backlog/BD-167.md` + `backlog/BD-169.md` (C2 stress entries) — and round-tripped
them through the real code. Drove the real migrator functions independently (not trusting
the IMPL-REPORT) for all 211 entries, the corrupt-blob classes, the size/rich_text fails,
and the teeth check. The IMPL-REPORT (`IMPL-REPORT-BD-204-C-4.5.md`) was read and every
load-bearing claim re-measured; no claim found false. Pack memory (`feedback_verify_full_ci_suite`,
`feedback_manifest_regen_on_v11_surface`, `feedback_scope_deliverables_to_the_ask`,
`enumerate-encoding-surfaces`, `rules-applied-verification-block`) + CLAUDE.md `## Pack
memory` consulted and applied.
