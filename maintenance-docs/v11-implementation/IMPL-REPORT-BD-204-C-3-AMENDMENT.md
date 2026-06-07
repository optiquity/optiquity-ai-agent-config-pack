# IMPL-REPORT — BD-204 C-3 amendment (tracker-edit blob+H2 sync + normalization-tolerant divergence comparator)

- **Branch:** `v11-dev`
- **Final HEAD SHA (worktree base; agents never commit):** `d5786267f4cb980dd8184db4416286b6fd6dac96` (the committed C-4.5)
- **Commit subject (for Pack Chat to use):** `feat: v11 — BD-204 tracker-edit syncs gz64 blob + H2 on every update; normalization-tolerant divergence comparator (pack-only)`
- **Scope:** PACK-ONLY, code+tests+manifest ONLY. Recipe: `PLAN-BD-204.md` §3.LF.4. Spec: `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3a + §3.3a(ii) + §3.3 (composer reused) + §7 (R-EDIT / R-NORM / R-CLIENT). Law: `RESEARCH-BD-204-GH-ISSUES-RULES.md` (the GH body-normalization rule the comparator tolerates).
- **PREFLIGHT line emitted:** `PREFLIGHT: 4/4 in-scope edits complete; verification PASS; HEAD d5786267f4cb980dd8184db4416286b6fd6dac96; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-3-AMENDMENT.md`
- **DEPENDS-ON:** C-4.5 (committed `d578626`) — the blob-aware composer `tmf_compose_issue_body` (6-param, emits BOTH H2 + gz64 blob). This commit CALLS it; it does not re-implement it.

---

## Files changed (inventory)

| Path | Type | Δ |
|---|---|---|
| `scripts/lib/tracker-edit.sh` | modified | +69/−~ (idempotent forward source; `tracker_edit_entry` recomposes the body via `tmf_compose_issue_body` on any content-bearing patch → BOTH H2 + blob regenerated atomically; docstring) |
| `scripts/lib/tracker-migrate-reverse.sh` | modified | +172/−~ (idempotent forward source; the §3.3a(ii) `_tmr_check_blob_h2_divergence` comparator; `force` 3rd param on reconstruct + comparator hook; run-loop rc-propagation so divergence/corrupt-blob FAIL LOUD) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | +52 (2.1d comparator teeth: no-false-positive on CRLF+trailing-space; mismatch caught on a one-word edit; --force blob-wins; BD-002 fixture made blob↔H2 consistent) |
| `scripts/tests/tracker-provider-test.sh` | modified | +46 (4.7 content-edit recompose carries BOTH blob + H2; 4.7b blob↔H2 sync proof via the comparator; 4.6→4.8 renumber) |

`test-fixtures/manifest.txt` — regenerated (`bash test-fixtures/build.sh --all --clean`, rc=0); diff EMPTY (the manifest tracks built trees under `test-fixtures/`, not `scripts/tests/fixtures/`). Per `regenerate-manifest-v11-surface`: ran the regen, empty diff ⇒ nothing to stage.

No new files. No `project-template/` / `supporting-docs/` / `maintenance-docs/` (beyond this IMPL-REPORT) / `backlog/` touched.

---

## Per-task summary

### T1 — `tracker-edit.sh`: blob+H2 sync on every `provider_update` (§3.3a(i))
The Mode-3 edit path previously passed a pre-composed `body` straight into the `provider_update` payload (line 257 `+ (if (.body...) then {body: .body}`), which could update the visible H2 without the hidden blob — exactly the divergence the design forbids. Now: when the patch carries ANY entry-content key (`description` / `context` / `resolution` / `file_symbol` / `raw_body`), `tracker_edit_entry` RECOMPOSES the body by calling `tmf_compose_issue_body "$pack_id" "$description" "$context" "$resolution" "$file_symbol" "$raw_body"` (the C-4.5 composer, which emits BOTH the H2 sections AND the `pack-entry-body-gz64` blob from the SAME object) and injects the composed body into the patch (overriding any literal `body`). A composer failure (size-budget / rich_text) aborts with a typed error BEFORE any `provider_update` (so the blob+H2 sync is never partial). The `raw_body` is extracted trailing-newline-faithfully (`jq -j` + sentinel `X` guard, matching the forward BD call-site idiom). Forward lib sourced idempotently (`declare -f tmf_compose_issue_body`). A label/status-only or legacy pre-composed-`body` edit is unchanged (no content key → pass-through), so existing callers/tests keep working.

### T2 — `tracker-migrate-reverse.sh`: the §3.3a(ii) normalization-tolerant divergence comparator
New `_tmr_check_blob_h2_divergence(raw_body, issue_body, issue_num, pack_id, force)`:
1. **Recompute the H2 projection from the blob** — write `raw_body` to a temp file, parse via the REAL forward `_tmf_parse_backlog_file`, project each of the 4 fields through the REAL `_tmf_neutralize_autolinks` (exactly as the composer does). No second H2 emit is implemented here — the real projection codec is reused.
2. **Extract the Issue's ACTUAL stored H2** via the same `_tmr_extract_section` reconstruct already uses.
3. **Normalize BOTH sides identically** in one `python3` pass and compare per-section.
4. On mismatch → FAIL LOUD `divergence: issue #N (pack-id) ... reconcile before reverse` (return 1) unless `force=1`, which surfaces a `blob wins` WARN and proceeds (the blob is authoritative; the comparator NEVER mutates the blob).

Wired into `tracker_migrate_reverse_reconstruct` (new optional 3rd `force` param; comparator called right after the blob decode) and into `tracker_migrate_reverse_run` (the per-issue reconstruct call now passes `force` and a non-zero rc is a HARD fail-loud abort of the run — surfacing divergence / corrupt-blob, never silently appending an empty/partial entry). Runs only when a blob is present (no-op for legacy/phase issues with no carrier).

### T3 — comparator teeth tests (`tracker-migrate-reverse-test.sh` 2.1d)
False-positive and false-negative are both asserted (see teeth-proof). BD-002 fake-gh fixture body gained `## File / Symbol\n\nscripts/bar.sh` so it is blob↔H2 consistent (a real forward migration always produces consistent pairs; the prior fixture omitted the section the blob carried — the comparator correctly caught it, and the fixture was made consistent in lock-step).

### T4 — sync tests (`tracker-provider-test.sh` Group 4)
4.7 asserts a content-bearing edit's `provider_update` payload carries BOTH the gz64 blob AND the H2 sections (the edited value). 4.7b is a direct SYNC proof: the payload's blob is decoded and fed back through `_tmr_check_blob_h2_divergence` against the payload body — a synced pair MATCHES (rc=0).

---

## The 4 HARD-INVARIANT attestations (with evidence)

### Invariant 1 — The sync CALLS the C-4.5 composer; NO second gz64/H2 implementation in `tracker-edit.sh`
- `tracker-edit.sh:264` calls `tmf_compose_issue_body "$pack_id" "$ed_description" "$ed_context" "$ed_resolution" "$ed_file_symbol" "$ed_raw_body"`.
- `grep -n "gzip\|base64\|GzipFile\|## Description"` in `tracker-edit.sh` → the only matches are COMMENTS (lines 58/60/140/148/241/244); ZERO emit code. No `_tmf_gz64_encode` re-implementation, no H2 `printf '## ...'`.
- The comparator's "recompute H2 from blob" reuses the REAL `_tmf_parse_backlog_file` (reverse.sh:759) + `_tmf_neutralize_autolinks` (reverse.sh:773–776), not a re-coded projection.

### Invariant 2 — Comparator normalization set = EXACTLY {CRLF/CR→LF; per-line trailing-ws strip; single trailing-newline}; no broader, no narrower
- The one normalization function (reverse.sh, inside `_tmr_check_blob_h2_divergence`):
  - `s.replace("\r\n", "\n").replace("\r", "\n")` (1) line-ending canonicalization;
  - `"\n".join(line.rstrip(" \t") for line in s.split("\n"))` (2) per-line trailing-ws strip;
  - `s.rstrip("\n") + "\n"` (3) single trailing-newline.
- NO interior-whitespace collapse, NO case fold, NO Unicode normalization, NO content change. Both failure modes proven absent below (no false-positive AND no false-negative).

### Invariant 3 — BLOB IS AUTHORITATIVE; comparator never mutates the blob; `--force` = blob-wins (existing refusal-unless-force idiom)
- The comparator reads `raw_body` (already decoded) and the issue body; it returns 0/1 only — it does not write or re-encode the blob anywhere.
- `force` is the existing `tracker_migrate_reverse_run` `local force="${5:-0}"` flag, threaded through reconstruct (`"${3:-0}"`) into the comparator (`"${5:-0}"`); no new flag invented.
- `force=1` path: WARN `... blob wins, the GH-side H2 edit is discarded` + return 0 (reverse proceeds with the authoritative blob). Test 2.1d-iii: rc=0 + WARN asserted.

### Invariant 4 — C-4.5 carrier/emit/composer behavior unchanged beyond ADDING the comparator call; client branch / `_tmr_emit_backlog` byte-untouched
- `_tmr_emit_backlog` (CLIENT branch) extracted from HEAD vs worktree and `diff`-ed → **BYTE-IDENTICAL** (R-CLIENT).
- `_tmr_emit_pack_tree` (the C-4.5 verbatim pack emit) has ZERO diff hunk in its range; the forward composer/parser/encoder are unmodified (this commit only SOURCES forward.sh idempotently and CALLS its symbols).
- `git diff --stat`: 4 files, +330/−9; reverse.sh hunks are exactly source-block / reconstruct-force-param / comparator-hook / comparator-helper / run-loop-rc.

---

## Comparator teeth-proof (the exact false-positive + false-negative cases + results)

Test `scripts/tests/tracker-migrate-reverse-test.sh` 2.1d, blob built from
`**BD-079 — Divergence probe**\n...\nFile/Symbol: scripts/probe.sh\nDescription: The quick brown fox.\n` via the PRODUCTION `_tmf_gz64_encode`.

- **2.1d-i NO-FALSE-POSITIVE** — issue H2 with REAL `\r\n` line endings + per-line trailing spaces (`## Description\r\n\r\nThe quick brown fox.   \r\n\r\n## File / Symbol  \r\n\r\nscripts/probe.sh  `), content UNCHANGED → comparator MATCHES → **rc=0 (PASS)**. (Proves the normalization set neutralizes GH's documented munging; an untouched-but-GH-normalized body is NOT flagged.)
- **2.1d-ii FALSE-NEGATIVE GUARD** — a real one-word content edit `fox → cat` (`## Description\n\nThe quick brown cat.\n\n...`) → comparator MISMATCHES → **rc=1 (PASS)**; error `divergence: issue #79 (BD-079) body H2 sections disagree with the pack-entry-body-gz64 blob (Description) ...` (asserts `divergence: issue #79` + names section `Description`). (Proves the set is no broader than GH's munging — a real word change still mismatches.)
- **2.1d-iii FORCE override** — the SAME edited body with `force=1` → **rc=0 (PASS)** + WARN containing `blob wins` (blob-wins, blob never mutated).

Group results: `tracker-migrate-reverse-test.sh` **Passed: 125, Failed: 0**.

Cross-test (sync↔comparator consistency): `tracker-provider-test.sh` 4.7b feeds the tracker-edit recomposed payload's blob back through `_tmr_check_blob_h2_divergence` against the payload body → MATCH (rc=0) → **PASS** (Passed: 127, Failed: 0).

---

## "Composer reused, not re-implemented" proof

- `grep -n "tmf_compose_issue_body" scripts/lib/tracker-edit.sh` → source guard (line 64) + the call (line 264). No `_tmf_gz64_encode` / `gzip` / `base64` / `printf '## Description'` emit code in `tracker-edit.sh` (all such tokens are in comments).
- Comparator's expected-H2 = `_tmf_parse_backlog_file` (reverse.sh:759) → `_tmf_neutralize_autolinks` per field (reverse.sh:773–776) — the same projection transforms the composer applies; no parallel H2 emit.
- `grep "65536"` on the `+` lines of both libs → **none** (no hardcoded provider limit introduced; the composer reads the active provider).

---

## Client-branch-untouched proof (R-CLIENT)

```
$ awk '/^_tmr_emit_backlog\(\)/{...}' (HEAD vs worktree) | diff
→ _tmr_emit_backlog BYTE-IDENTICAL to HEAD (CLIENT branch UNTOUCHED)
```
`git diff` of `scripts/lib/tracker-migrate-reverse.sh` shows hunks only at the source block (`@@ -93`), reconstruct-force-param (`@@ -523`), comparator hook (`@@ -577`), comparator helper (`@@ -674`), and run-loop rc (`@@ -1161`). No hunk lands in the `_tmr_emit_backlog` range (client `# BACKLOG` monolith path) nor the `_tmr_emit_pack_tree` C-4.5 emit body.

---

## Full-battery results (verify-full-ci-suite)

- `python3 scripts/validate-pack.py` → **PASSED — all checks clean** (Check 48 advisory WARNs only; exit code unaffected).
- The ENTIRE unattended workflow battery — all 45 `run: bash scripts/tests/<file>` scripts enumerated from `.github/workflows/validate-pack.yml` — run with rc + internal `Failed: [1-9]` detection → **ALL GREEN** (`nonzero-rc count: 0`; `internal-fail count: 0`). Emphasized:
  - `tracker-migrate-forward-test.sh` → Passed: 168, Failed: 0
  - `tracker-migrate-reverse-test.sh` → Passed: 125, Failed: 0
  - `tracker-migrate-roundtrip-test.sh` → Passed: 51, Failed: 0
  - `tracker-provider-test.sh` → Passed: 127, Failed: 0
  - `test-v11-realistic-ot.sh` → rc=0 (banner-pinning unaffected)
- `bash -n` clean on all 4 edited files.
- `bash test-fixtures/build.sh --all --clean` → rc=0; `git status --short test-fixtures/manifest.txt` → empty (no diff to stage).

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| `tracker_edit_entry` recomposes body via `tmf_compose_issue_body` on a content-bearing patch (BOTH H2 + blob, atomically) | PASS |
| The sync CALLS the C-4.5 composer; NO second gz64/H2 impl in `tracker-edit.sh` | PASS |
| Composer failure aborts BEFORE `provider_update` (no partial sync) | PASS |
| Legacy/label-only/status-only edit unchanged (no content key → pass-through) | PASS |
| Reverse §3.3a(ii) comparator recomputes H2 from blob; compares to issue H2 | PASS |
| Comparator normalization set EXACTLY {CRLF/CR→LF; per-line trailing-ws strip; single trailing-newline}; no broader/narrower | PASS |
| No false-positive on CRLF + trailing-space normalized body | PASS |
| Mismatch caught on a one-word content edit (`divergence:` + issue # + section) | PASS |
| `--force` overrides to blob-wins (existing flag; WARN; blob never mutated) | PASS |
| Divergence/corrupt-blob propagate as a HARD fail-loud run abort (no silent empty/partial) | PASS |
| Blob authoritative; comparator never mutates the blob | PASS |
| C-4.5 carrier/emit/composer byte-unchanged beyond the comparator call | PASS |
| CLIENT branch / `_tmr_emit_backlog` byte-untouched (R-CLIENT) | PASS |
| Sync test: blob ↔ H2 agree after `provider_update` | PASS |
| Tests in lock-step (comparator + sync + fixture consistency) | PASS |
| FULL CI battery green (45 scripts) + validate-pack green | PASS |
| Manifest regen (empty diff) | PASS |
| pack-only; no `project-template/` / `supporting-docs/` touched | PASS |
| No fenced-out scope (no validate-pack check / `_rules.md` / METHODOLOGY / C-7 / `backlog/BD-*.md` / maintenance-docs beyond this report / live GH) | PASS |

---

## Plan deviations

**One lock-step encoding-surface update, faithful to the recipe + `enumerate-encoding-surfaces` (NOT a redesign).** Adding the comparator (which runs on every reconstruct when a blob is present) surfaced that the BD-002 fake-gh fixture in `tracker-migrate-reverse-test.sh` was blob↔H2 INCONSISTENT — its blob carried `File/Symbol: scripts/bar.sh` but its stored issue body omitted the `## File / Symbol` H2 section. A real forward migration ALWAYS emits a consistent pair (the composer projects every non-empty field), so the inconsistent fixture was an artificial pre-comparator artifact. The comparator correctly FLAGGED it (proving its teeth), and I made the fixture consistent by adding `## File / Symbol\n\nscripts/bar.sh` to #43's stored body — the correct invariant, in lock-step with the new check. No production code logic changed for this; no architecture change.

---

## New POQs introduced

None.

---

## CONCERNS (surfaced, NOT acted on)

1. **Three pre-existing UNTRACKED files vanished from the working tree between the session-start git-status snapshot and this session — NOT caused by this commit.** The opening snapshot listed `??` for `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C7.md`, `scripts/tests/fixtures/tracker-bd204-lossless/`, and `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (plus HEAD `feaa45d`). At this session's actual HEAD (`d578626`, two commits later: C-RS `e63476a` + BD-207 `2064372` + C-4.5 `d578626`), those three are GONE while `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` + `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md` survive. `test-fixtures/build.sh --clean` only wipes targets UNDER `test-fixtures/` (`grep "rm -rf" test-fixtures/build.sh` → no `scripts/` target), so the manifest regen did NOT delete them. They were removed by the parent/concurrent process between the snapshot and my work — surfaced because the C-7 oracle (`tracker-bd204-lossless-roundtrip-test.sh` / its fixture) is the §3.LF.7 rebuild target, and the C7 IMPL-REPORT is now absent. NOT in this commit's scope to recreate; flagging so Pack Chat can confirm the C-7 parked-file state before the C-7 REBUILD commit fires.

2. **`tracker_migrate_reverse_reconstruct` rc was previously IGNORED at the run-loop call site.** Before this commit, line ~1321 did `rec=$(tracker_migrate_reverse_reconstruct ...)` with NO rc check — so even the EXISTING C-4.5 corrupt-blob fail-loud (which returns 1) did not actually abort the run; a corrupt blob would have appended an empty `$rec` and surfaced only as a downstream `jq` error. The divergence comparator REQUIRES the rc to propagate (per §3.3a "FAILs the reverse"), so I added the rc check, which ALSO makes the corrupt-blob abort effective. This is the minimal wiring §3.LF.4 needs (divergence + corrupt-blob share the return-1 channel); it tightens a pre-existing latent gap rather than introducing new behavior. Surfaced because it touches the corrupt-blob path (C-4.5 territory) — confirm this is acceptable; if Pack Chat prefers the corrupt-blob abort wiring isolated to a separate commit, the divergence rc check still must stay here.

3. **The comparator reuses the forward parser, which the C-4.5 IMPL-REPORT (CONCERNS #2) DECOUPLED from interior-H2 truncation.** The comparator parses the blob's `raw_body` via `_tmf_parse_backlog_file` to recompute the projection. For a BD-167/169-style entry with an interior `## Sub-entry` H2, the forward PROJECTION fields (description/etc.) close at the interior H2 (unchanged C-4.5 behavior), and the issue's stored H2 was emitted from those same projection fields — so recompute == stored and the comparator does not false-flag. Verified indirectly (the full forward/reverse/roundtrip battery is green incl. the 211-entry round-trip in the forward/faithfulness paths). No action needed; surfaced for completeness given the comparator now exercises the parser on every reverse.

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` run; only read-only `git rev-parse/status/diff/show/log`. Worktree HEAD unchanged at `d578626`. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op beyond in-scope edits; no live `gh`/network; `rm` limited to `mktemp` temp files inside the comparator/tests. | COMPLIANT |
| `preflight-stop-means-stop` | PREFLIGHT line emitted only after all 4 edits + validate-pack + the full 45-script battery PASS (nonzero-rc 0, internal-fail 0); no parent stop received. | COMPLIANT |
| `verify-full-ci-suite` | Ran ALL 45 workflow `run:` scripts (enumerated via `grep 'run: bash scripts/tests/' .github/workflows/validate-pack.yml`) + `validate-pack.py`, not a subset; `test-v11-realistic-ot.sh` included → ALL GREEN. | COMPLIANT |
| `regenerate-manifest-v11-surface` | `bash test-fixtures/build.sh --all --clean` run (scripts/ touched), rc=0; `git status --short test-fixtures/manifest.txt` → empty (no diff to stage). | COMPLIANT |
| `enumerate-encoding-surfaces` | Updated the comparator + the sync + ALL tests that encode their contract in lock-step: reverse-test (comparator teeth + the now-consistent BD-002 fixture), provider-test (sync + sync-proof). | COMPLIANT |
| `edit-in-place-not-full-rewrite` | All changes via targeted `Edit` calls (source block, reconstruct param/hook, run-loop call, payload build, docstring, test inserts); no full-file `Write` of any source/test; re-verified each via test runs + `bash -n`. | COMPLIANT |
| `pack-repo-code-comment-deferrals` | No deferral comments introduced (no `# TODO`/`# FIXME`/`# fix later`); zero deferrals in this commit. | N/A: no deferrals introduced |
| `filename-uniqueness-heuristic` | No NEW files (only edits + this IMPL-REPORT). `find . -name 'IMPL-REPORT-BD-204-C-3-AMENDMENT.md'` (pre-write) → empty (unique). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly §3.LF.4: tracker-edit blob+H2 sync + reverse comparator + tests + manifest. NO C-4.6 validate-pack check, NO `_rules.md`/METHODOLOGY (C-4.7), NO C-7 rebuild, NO `backlog/BD-*.md`, NO maintenance-docs beyond this report, NO live GH. `git status --short` shows only the 4 in-scope paths. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | All edits pack-side (`scripts/`); no `project-template/`/`supporting-docs/` touched (`git diff --name-only` confirms). No project-side SSOT applies (pack-only tracker-migrator/edit libs + their tests). | COMPLIANT |
| `rules-applied-verification-block` | This table (per-rule name + quoted evidence + conclusion; no empty rows). | COMPLIANT |

### Boundary discipline check
No project-side file edited. All 4 changed paths are pack-side under `scripts/`. No reference to any pack-only file added to a client-shipped surface (no client surface touched). No boundary-discipline stop required.
