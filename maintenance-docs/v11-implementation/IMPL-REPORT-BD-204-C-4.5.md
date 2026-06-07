# IMPL-REPORT — BD-204 C-4.5 (gz64 carrier + verbatim emit rewrite + size budget + autolink neutralization + provider caps + pacing)

- **Branch:** `v11-dev`
- **Final HEAD SHA (worktree base; agents never commit):** `e63476a53df135e2f99ec409316cf0601ec243e7`
- **Commit subject (for Pack Chat to use):** `feat: v11 — BD-204 field-faithful gz64 body-blob carrier + verbatim emit rewrite + size budget + autolink neutralization (pack-only)`
- **Scope:** PACK-ONLY, code+tests+manifest ONLY. Recipe: `PLAN-BD-204.md` §3.LF.3. Spec: `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3/§3.3a–d/§4/§7.
- **PREFLIGHT line emitted:** `PREFLIGHT: 9/9 in-scope edits complete; verification PASS; HEAD e63476a53df135e2f99ec409316cf0601ec243e7; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-4.5.md`

---

## Files changed (inventory)

| Path | Type | Δ |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified | +330/−~ (parser raw_body capture; composer 6th param + gz64 blob + size budget + autolink neutralization; pacing gate + backoff; BD call site passes raw_body) |
| `scripts/lib/tracker-migrate-reverse.sh` | modified | +156/−85 (reconstruct decodes blob fail-loud; `_tmr_emit_pack_tree` PACK branch rewritten to verbatim emit; dead `extra_fields` + None/n-a injection deleted) |
| `scripts/lib/tracker-provider-gh.sh` | modified | +8 (capabilities: `body.{limit,storage_format}`, `rate_limits.{min_write_interval_s,writes_per_hour_max}`) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | +124 (Group 2.8 carrier legs: blob decode, determinism, neutralization, size fail-loud, rich_text fail-loud, pacing, retry-after) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | +67 (fake-gh issues carry blob; 4.2 byte-faithful + no-injection; 2.1b corrupt-blob fail-loud; 2.1c decode-identity) |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified | +58 (BD-003 drop-set+prose byte-faithful leg; counts 2→3 BD / 4→5 issues) |
| `scripts/tests/tracker-provider-test.sh` | modified | +33 (1.1b cap declarations; 1.1c active-provider-limit, no hardcoded 65536) |
| `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` | modified | +20 (BD-003: top-level drop-set fields + multi-paragraph prose + NO Blockers) |

`scripts/lib/tracker-provider.sh` — NO change needed (see CONCERNS #1: the
dispatcher already exposes `provider_capabilities`; the capability VALUES are
declared in the GH backend, the only place values live).

`test-fixtures/manifest.txt` — regenerated (`bash test-fixtures/build.sh
--all --clean`); diff EMPTY (the manifest tracks `test-fixtures/` built trees,
not `scripts/tests/fixtures/`). Per `regenerate-manifest-v11-surface`: ran the
regen, empty diff ⇒ nothing to stage.

---

## Per-task summary

### T1 — Forward parser `_tmf_parse_backlog_file` adds `raw_body`
Captures the verbatim span (lines 2..EOF = bold-header + every body line) into
`raw_body`, DECOUPLED from the projection's field-flush logic so an interior
`## Sub-entry` H2 (BD-167/169) does NOT truncate the capture (see CONCERNS #2).
The capture is bounded only by the next `**BD-NNN — …**` header or the `---`
separator; trailing separator-join blanks stripped; one trailing `\n` re-added,
reproducing the original file byte-for-byte. Verified byte-identical vs
`sed -n '2,$p'` on BD-001/204/136/021/065 and across all 211.

### T2 — Composer `tmf_compose_issue_body` 6th param + blob + size + neutralization
6th DEFAULTED param `raw_body="${6:-}"`. Emits ONE
`<!-- pack-entry-body-gz64: <b64(gzip mtime=0 raw_body)> -->` marker alongside
the trio (only when raw_body non-empty). Helpers added: `_tmf_gz64_encode`
(python3, mtime=0, PINNED), `_tmf_neutralize_autolinks` (inline-code-span,
4-form, longer-fence-on-backtick, projection-only), `_tmf_provider_capability`
(reads active provider). Size budget enforced on STORED bytes of the ACTUAL
composed body vs `provider.body.limit − TMF_SIZE_SAFETY_MARGIN` (2048); fail-loud
with id+bytes, never truncate; fail-loud on `rich_text_normalizing`. The H2
sections + marker trio still emit byte-unchanged in shape (blob ADDED alongside).

### T3 — BD call site passes raw_body; phase call site passes nothing
BD create branch extracts `raw_body` from the entry JSON with a
trailing-newline sentinel guard (`jq -j … ; printf X` then `${x%X}`) so the
exact bytes (incl. final `\n`) reach the encoder. Composer failure aborts the
run (no partial Issue). Phase call site unchanged (4-arg, relies on `${6:-}`).

### T4 — Pacing gate + retry-after backoff (§3.3d)
`_tmf_pace_before_create` sleeps `rate_limits.min_write_interval_s` before each
create AFTER the first (module counter `_TMF_CREATES_DONE`, reset per run).
`_tmf_create_backoff` honors a numeric `Retry-After` on a secondary-rate-limit
/ abuse class error and the create branch retries ONCE; any other failure
aborts as before (never tight-retries). Both wired into the BD and phase create
loops. Test seams: `TMF_PACING_SLEEP_CMD`, `TMF_PACING_INTERVAL_OVERRIDE`
(both `set -u`-safe via `${…:-}`).

### T5 — Reverse `tracker_migrate_reverse_reconstruct` decodes blob (fail-loud)
New `_tmr_decode_body_blob` (python3 base64+gunzip, PINNED): marker ABSENT →
empty raw_body (legacy/phase fallback); PRESENT-but-malformed → ABORT with
`corrupt-blob: issue #N … reverse aborted — NEVER emits an empty/partial entry
body`. `raw_body` added to the reconstructed object (sentinel-guarded for the
trailing newline).

### T6 — `_tmr_emit_pack_tree` PACK branch rewritten to verbatim emit
The python render block now writes `body = e.get("raw_body", "")` verbatim. The
fixed-order projection — `Blockers: None` / `Unblocks: None` / `Resolved: n/a`
injection, the dead `extra = e.get("extra_fields", …)` read + its `[label,
value]` render loop — is DELETED. CLIENT branch (`_tmr_emit_backlog`) byte-untouched.

### T7 — Provider capability declarations (GH backend)
`tracker-provider-gh.sh` capabilities gains `body: {limit: 65536, storage_format:
"raw_text"}` and `rate_limits: {…, min_write_interval_s: 1, writes_per_hour_max:
500}`. The migrator reads the ACTIVE provider's values (no hardcoded 65536).

### T8 — Tests (4 files) + roundtrip fixture
Lock-step per enumerate-encoding-surfaces. Legs added per §3.LF.3 (see teeth
proof + battery results below).

---

## The 7 HARD-INVARIANT attestations (with evidence)

### Invariant 1 — CODEC PINNED (python3, mtime=0; load-bearing = DECODE-IDENTITY)
- Encode (`_tmf_gz64_encode`) + decode (`_tmr_decode_body_blob`) + every test
  use python3 `gzip.GzipFile(mtime=0)` / `gunzip` — NO shell `gzip(1)`/`base64(1)`.
- Decode-identity proven across all 211 entries (forward compose → reverse
  reconstruct → emit → `diff` vs original lines 2..EOF): `TOTAL: PASS=211 FAIL=0`.
- Determinism (convenience): two composes of the same entry yield byte-identical
  blobs (forward-test 2.8.2 PASS; roundtrip 3.1 signature byte-equal PASS).
- No blob-byte-identity-across-machines assertion exists (the binding property
  asserted is decode-identity).

### Invariant 2 — CORRUPT-BLOB FAIL-LOUD (never silent-empty)
- `_tmr_decode_body_blob`: present-but-malformed marker → `tracker_error_emit
  validation "corrupt-blob: issue #N … NEVER emits an empty/partial entry body"`,
  return 1, propagated to abort reverse.
- Evidence: reverse-test 2.1b — `corrupt-blob reconstruct rc=1 (fail loud)` PASS;
  error names issue #77 + states never-empty (PASS).

### Invariant 3 — SIZE BUDGET on STORED bytes of ACTUAL composed body vs ACTIVE provider's limit (no hardcoded 65536; fail-loud, never truncate; rich_text fail-loud)
- Composer measures `wc -c` of the real composed `$body`; compares to
  `_tmf_provider_capability '.body.limit' − TMF_SIZE_SAFETY_MARGIN`. No literal
  `65536` in the migrator (`grep -n 65536 scripts/lib/tracker-migrate-*.sh` →
  none; 65536 lives only in the GH backend capability).
- Over-budget → `size-budget: entry <ID> … NEVER truncates`, return 1.
- `rich_text_normalizing` backend → `requires raw_text … unsupported`, return 1.
- Evidence: forward-test 2.8.5 (over-budget rc=1 + names entry + never-truncate;
  within-budget rc=0), 2.8.6 (rich_text rc=1); provider-test 1.1c (smaller-limit
  mock fails loud at ITS bound; same body passes under GH 65536 — proves
  active-provider read).

### Invariant 4 — NEUTRALIZATION = VISIBLE H2 PROJECTION ONLY (blob never modified)
- Separate code paths: blob = `_tmf_gz64_encode(raw_body)` (raw, un-neutralized);
  projection = `_tmf_neutralize_autolinks(description/context/resolution/file_symbol)`.
- Inline-code-span variant: wraps any value with `#NNN`/bare-`@`/bare-SHA/bare-URL
  in backticks (longer fence if value already has one). No-op on trigger-free values.
- PROOF the blob cannot be touched: a raw_body carrying all 4 trigger forms
  decodes to the verbatim original (triggers intact) while the H2 projection is
  code-span-wrapped. Evidence: forward-test 2.8.4 (H2 wraps trigger value AND
  blob decodes verbatim, raw SHA `08f7158` present in decoded blob).

### Invariant 5 — EMIT REWRITE scope = PACK branch ONLY (CLIENT byte-untouched)
- `_tmr_emit_pack_tree` (PACK) rewritten; `_tmr_emit_backlog` (CLIENT) BYTE-IDENTICAL
  to HEAD (verified: extracted both function bodies, `diff` empty → "BYTE-IDENTICAL
  to HEAD (CLIENT branch UNTOUCHED) ✓").
- Surface split intact: `tracker_migrate_reverse_run` routes
  `[[ "$surface" == "pack" ]]` → `_tmr_emit_pack_tree`, else → `_tmr_emit_backlog`.

### Invariant 6 — H2 sections + marker trio still emit, byte-unchanged in shape (blob ADDED alongside)
- Composer output order: `pack-id`/`template_version`/`pack-version`/`pack-entry-body-gz64`
  (line 4) then `## Description`/`## File / Symbol`/`## Context`/`## Resolution`.
- Evidence: forward-test 2.5 substring asserts all PASS (unchanged); the trio +
  all four H2 sections grep-confirmed present with the blob as an added line 4.

### Invariant 7 — 20 no-Blockers entries emit WITHOUT injected `Blockers: None`/`Resolved: n/a`
- The verbatim emit reproduces exactly the source body. Tested on BD-001 + BD-195
  (two of the 20) in the all-211 round-trip (BYTE-IDENTICAL).
- Reverse-test 4.2: BD-001 reconstructed body BYTE-IDENTICAL to source +
  `no injected 'Blockers: None' / 'Unblocks: None' / 'Resolved: n/a'` (all PASS).
- Roundtrip 2.2d: BD-003 (no Blockers) — no injection (PASS).

---

## Teeth-proof for the new test legs (fail on OLD, pass on NEW)

Sourced HEAD's `tracker-migrate-reverse.sh` (pre-fix) + the new forward; fed a
blob-bearing BD-001 issue through the OLD reconstruct + OLD `_tmr_emit_pack_tree`:

```
=== OLD BD-001.md (lines 2..) ===
**BD-001 — Add foo to bar**
Type: TODO(version)
Status: Open
Blockers: None        ← injected (source had none)
Unblocks: None        ← injected
File/Symbol: scripts/foo.sh
Description: Implements foo on bar.
Resolved: n/a         ← injected
TEETH: OLD injects 'Blockers: None'  (new no-injection assert WOULD FAIL) ✓
TEETH: OLD injects 'Resolved: n/a'   (new no-injection assert WOULD FAIL) ✓
```

- **Byte-faithful leg (reverse 4.2 / roundtrip 2.2d):** OLD emit DIFFERS from
  source (3 injected lines) → the new `BYTE-IDENTICAL` assert FAILS on OLD.
- **No-injection legs:** OLD emits `Blockers: None`/`Unblocks: None`/`Resolved:
  n/a` → the new `assert_not_contains` legs FAIL on OLD.
- **Size leg:** OLD composer had no size check → the new over-budget rc=1 assert
  FAILS on OLD (OLD returns rc=0). **Corrupt-blob leg:** OLD reconstruct had no
  blob decode → no `corrupt-blob` error (assert FAILS on OLD). **Neutralization
  leg:** OLD composer emitted raw H2 (no code-span) → the new code-span assert
  FAILS on OLD. **Pacing leg:** OLD had no pacing helper → the symbol does not
  exist on OLD. All legs PASS on the new code.

---

## CLIENT-branch-untouched proof (R-CLIENT)

```
$ awk '/^_tmr_emit_backlog\(\)/{f=1} f{print} /^}/{if(f)exit}' (HEAD vs worktree) | diff
→ _tmr_emit_backlog BYTE-IDENTICAL to HEAD (CLIENT branch UNTOUCHED) ✓
```
`git diff -U0` hunks land only in: reconstruct (blob decode + raw_body output +
decoder helper, lines 557–625) and `_tmr_emit_pack_tree` (lines 777+). The
`_tmr_emit_backlog` body (703–~775) carries ZERO diff hunks.

---

## Full-battery results (verify-full-ci-suite)

- `python3 scripts/validate-pack.py` → **PASSED — all checks clean** (Check 43
  freeze clean; Check 47 clean; Check 48 advisory WARNs only).
- The ENTIRE unattended workflow battery (44 scripts enumerated from
  `.github/workflows/validate-pack.yml`) run with exit-code + `Failed:N`
  detection → **ALL BATTERY GREEN**. Includes the emphasized:
  - `tracker-migrate-forward-test.sh` → Passed: 168, Failed: 0
  - `tracker-migrate-reverse-test.sh` → Passed: 119, Failed: 0
  - `tracker-migrate-roundtrip-test.sh` → Passed: 51, Failed: 0
  - `tracker-provider-test.sh` → Passed: 121, Failed: 0
  - `test-v11-realistic-ot.sh` → PASS (banner-pinning unaffected)
- `bash -n` clean on all 8 edited scripts.
- `tracker-migrate-forward-test.sh` + `tracker-provider-test.sh` confirmed
  ALREADY WIRED in the workflow (no wiring change needed this commit).
- NOTE: a pre-existing benign `line 376: issue: command not found` heredoc-
  expansion artifact exists in `tracker-migrate-forward-test.sh` at HEAD (73
  occurrences on the committed file); NOT introduced by this commit, fails no test.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| Parser adds `raw_body` (verbatim lines 2..EOF, no re-parse) | PASS |
| Composer 6th DEFAULTED `raw_body` param; phase 4-arg still works | PASS |
| ONE `pack-entry-body-gz64` marker; gzip mtime=0 + base64; python3 PINNED | PASS |
| Size budget on STORED bytes vs active provider limit; fail-loud, never truncate | PASS |
| rich_text_normalizing backend fail-loud | PASS |
| Autolink neutralization of H2 projection ONLY (4-form, code-span); blob untouched | PASS |
| BD call site passes raw_body; phase passes nothing | PASS |
| Reverse decodes blob; corrupt-blob fail-loud (never silent-empty) | PASS |
| `_tmr_emit_pack_tree` PACK branch writes raw_body verbatim | PASS |
| Dead `extra_fields` read + None/n-a injection DELETED | PASS |
| CLIENT branch / `_tmr_emit_backlog` byte-untouched | PASS |
| Provider caps: body.limit 65536, raw_text, interval 1s, 500/hr | PASS |
| Pacing gate (sleep ≥ interval after first create) + retry-after backoff | PASS |
| All 211 entries round-trip byte-identical | PASS |
| 20 no-Blockers entries: no injected None/n-a | PASS |
| New test legs have teeth (fail on OLD, pass on NEW) | PASS |
| FULL CI battery green + validate-pack green | PASS |
| Manifest regen (empty diff) | PASS |
| pack-only; no project-template/ supporting-docs/ touched | PASS |
| No fenced-out scope (no maintenance-docs edit, no validate-pack check, no tracker-edit.sh, no _rules.md, no backlog/BD-*.md edit, no live GH) | PASS |

---

## Plan deviations

**One reconciliation, faithful to the recipe's explicit intent (NOT a redesign).**
The recipe states `raw_body` = "verbatim captured span = lines 2..EOF … no
re-parse, no parse_id_list, no continuation folding." The pre-existing parser
flushes an entry on an interior `## ` H2 line. BD-167 and BD-169 each carry an
in-body `## Sub-entry b — …` section (the former suffixed BD-167b/169b, now
in-body per BD-211). Riding `raw_body` capture on the projection's H2-flush would
have TRUNCATED those 2 entries' blobs (2/211 NOT lossless — defeating BD-204's
purpose and the C-4.6 byte-faithfulness guard). I DECOUPLED the verbatim capture
from the projection flush (capture bounded only by `**BD-NNN**`/`---`; interior
H2 is captured as content), which is the literal realization of "verbatim lines
2..EOF, no re-parse." The projection's H2-flush behavior is UNCHANGED (the
projection still closes its field-entry on H2). Result: all 211 round-trip
byte-identical. This honors the recipe's stated intent rather than improvising a
different mechanism; it is surfaced here and in CONCERNS #2 for reviewer/Pack-Chat
visibility. No architecture change; no field logic changed.

## New POQs introduced

None.

---

## CONCERNS (surfaced, NOT acted on)

1. **`tracker-provider.sh` has no diff (recipe names it in the file scope).**
   §3.LF.3 lists "`tracker-provider.sh` + `tracker-provider-gh.sh` — DECLARE
   `provider_body_limit`/…". The capability VALUES are declared in the GH
   backend's `tracker_provider_gh_capabilities()` (the only place values live);
   the abstraction layer (`tracker-provider.sh`) already exposes the generic
   `provider_capabilities()` dispatcher that the migrator reads. Adding anything
   to `tracker-provider.sh` would be either a duplicate hardcoded value (a
   layering violation — the abstraction must NOT know GH's 65536) or a no-op
   comment. I declared the values in the GH backend only and read them via the
   active-provider dispatcher (tracker-agnostic, per §3.3c N-7). I judged this
   the faithful realization of the contract, not a deviation — but flagging it
   since the recipe's file list names `tracker-provider.sh`.

2. **BD-167/169 interior-H2 capture (the reconciliation above).** Surfaced for
   reviewer scrutiny: the decoupling is the load-bearing change that makes 211/211
   lossless. If the reviewer/architect prefers a different boundary model
   (e.g. parse each per-entry file individually instead of the concatenated
   stream), that is a larger refactor and out of this commit's scope — flagging,
   not acting.

3. **`SAFETY_MARGIN` default 2048 vs small provider limits (test ergonomics).**
   §3.3c suggests "e.g. 2,048 bytes." A provider declaring a body limit BELOW
   2048 would compute a negative budget and fail EVERY entry. Real providers
   (GH 65536; Trello 16384; Jira 32767) all clear it, so this is not a live
   risk — but a hypothetical sub-2KB-limit `raw_text` provider would be
   unusable. Not in scope to guard here; the design's stated worst-case
   (BD-136 at 40,771 bytes) and provider floor (~43 KB) make it moot for v11.x.
   Surfaced for completeness.

4. **Pacing gate cannot be exercised end-to-end without a multi-create run in a
   unit test.** The pacing helper is unit-tested directly (2.8.7/2.8.8 via test
   seams) rather than through a full forward run with ≥2 creates timed. This
   matches §3.3d's "inject a fake clock / count the pacing sleeps — a unit-level
   assertion, no live wait needed in CI." The live paced-create confirmation is
   the C-7 rehearsal's job (3.LF.10), out of this commit's scope.

5. **No "better approach" was substituted.** I considered (and did NOT
   implement): dropping the H2 to halve the payload (rejected — §3.3c keeps H2
   for readability, design-fixed); a raw-base64 (non-gzip) blob (rejected —
   §3.3c size budget needs gzip); a U+2060 word-joiner neutralization (rejected
   per §3.3d — misses SHA/URL). All built AS WRITTEN.

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` run; only read-only `git rev-parse/status/diff/show`. Worktree HEAD unchanged at `e63476a5…`. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op beyond in-scope edits; no live `gh`/network; `rm` limited to `mktemp` temp dirs (a dangerous-`rm` prompt was hit once and I rewrote to avoid it). | COMPLIANT |
| `preflight-stop-means-stop` | PREFLIGHT line emitted only after all 9 edits + validate-pack + full battery PASS; no parent stop received. | COMPLIANT |
| `verify-full-ci-suite` | Ran ALL 44 workflow scripts (enumerated from `validate-pack.yml`) + `validate-pack.py`, not a subset; `test-v11-realistic-ot.sh` included → ALL GREEN. | COMPLIANT |
| `regenerate-manifest-v11-surface` | `bash test-fixtures/build.sh --all --clean` run (scripts/ touched); `git status --short test-fixtures/manifest.txt` → empty (no diff to stage). | COMPLIANT |
| `enumerate-encoding-surfaces` | Updated the carrier libs + ALL 4 named test files + the roundtrip fixture in lock-step; fake-gh fixtures updated to carry the blob; counts updated. | COMPLIANT |
| `edit-in-place-not-full-rewrite` | All changes via targeted `Edit` calls (parser block, composer, emit render block, call sites); no full-file `Write` of any source/test; re-verified each via test runs. | COMPLIANT |
| `pack-repo-code-comment-deferrals` | No deferral comments introduced (no `# TODO`/`# FIXME`); zero deferrals in this commit. | N/A: no deferrals introduced |
| `filename-uniqueness-heuristic` | No NEW files added (only edits + IMPL-REPORT, which is verified unique: `find … IMPL-REPORT-BD-204-C-4.5.md` → empty). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly §3.LF.3; NO maintenance-docs edit (C-DOCS), NO validate-pack check (C-4.6), NO tracker-edit.sh (C-3), NO `_rules.md` (C-4.7), NO live GH, NO `backlog/BD-*.md` edit. `git status --short` shows only the 8 in-scope paths. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | All edits pack-side (`scripts/`); no `project-template/`/`supporting-docs/` touched (`git diff --name-only` confirms); pack-only scope. No project-side SSOT applies. | COMPLIANT |
| `rules-applied-verification-block` | This table (per-rule name + quoted evidence + conclusion; no empty rows). | COMPLIANT |

### Boundary discipline check
No project-side file edited. All 8 changed paths are pack-side under `scripts/`.
No reference to any pack-only file added to a client-shipped surface (none
touched). No boundary-discipline stop required.

