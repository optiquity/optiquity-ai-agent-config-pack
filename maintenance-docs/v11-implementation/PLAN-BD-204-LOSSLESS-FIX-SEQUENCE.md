# PLAN-BD-204-LOSSLESS-FIX-SEQUENCE — the sequenced commit plan for the BD-204 lossless field-carrier fix

> **Agent:** pack-planner. **Mode:** PLAN ONLY (no source/entry/script edit; no git verbs). A
> `pack-coder` executes each commit under the bounded review/fix cycle; the live RUN (C-8 + the
> rehearsal) is user-gated.
> **HEAD (verified):** `1a8e32e` (`git rev-parse HEAD` -> `1a8e32e0cb0515bb705eb20db31aa0a434f23858`).
> **Branch:** `v11-dev`. **Date:** 2026-06-07. **Scope:** PACK-ONLY.
> **Spec (fixed; this doc SEQUENCES it, does not re-decide it):**
> `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md`. Ledger:
> `SWEEP-BD-204-RULES-COMPLIANCE.md`. Law: `RESEARCH-BD-204-GH-ISSUES-RULES.md` (30 rules).
> **Companion:** `PLAN-BD-204.md` §3.LF carries the same sequence inline (amended in place this session).
>
> **Evidence convention.** State-claims carry an Empirical-Evidence Block: `CMD` · `OUT` (verbatim) ·
> `AT` (HEAD `1a8e32e`, 2026-06-07) · `INTERP` · `CONCL`. All measurements are this session's own.

---

## 1. The ordered commit table

| # | Commit | Scope (one line) | Keyword | Routing | Gate / depends-on |
|---|---|---|---|---|---|
| 1 | **C-RS** | re-scope `backlog/BD-204.md` (LOSSLESS FIELD-CARRIER FIX section + Option-A archive=scratch-disposal wording) | `pack-only` | **pack-coder** (MAJOR: substantive edit to ALREADY-LANDED entry; pack-chat-only file scoped INTO the coder prompt) | first; no code dep |
| 2 | **C-4.5** | gz64 verbatim-body-blob carrier (forward `raw_body` capture + composer gz64 emit + size-budget fail-loud + autolink neutralization of H2 projection) + reverse (python3 decode, corrupt-blob fail-loud) + `_tmr_emit_pack_tree` REWRITE (verbatim, delete dead `extra_fields` render) + provider capabilities + pacing gate + unit/roundtrip tests + fixtures + manifest. **CODE+TESTS+MANIFEST ONLY** (S-2 docs -> C-DOCS; OQ-2) | `pack-only` | pack-coder | after C-RS |
| 3 | **C-3 amendment** | `tracker-edit.sh` regenerates BOTH H2 + gz64 blob on every `provider_update`; reverse divergence comparator made normalization-tolerant + test + manifest | `pack-only` | pack-coder | after C-4.5 (needs the blob-aware composer) |
| 4 | **C-4.6** | new validate-pack `check_migrator_field_faithfulness` (next free integer): byte-faithful + size(composed-body) + title<=256 + control-char on the REAL tree; per-check test; **workflow-yml wiring (Check 42)**; positive/negative fixtures; manifest | `pack-only` | pack-coder | after C-4.5 (runs GREEN on fixed migrator) |
| 5 | **C-4.7** | `backlog/_rules.md` field-faithful-migration statement + Position/METHODOLOGY contradiction fix (`_rules.md` only; METHODOLOGY NOT edited) | `pack-only` | **pack-coder** (MAJOR: contract change to landed content; pack-chat-only file scoped into prompt) | after C-4.6 |
| 6 | **C-7 REBUILD** | rebuilt live oracle: drop-set + no-Description fixtures; size/pacing/autolink-neutralization/corrupt-blob/normalization/credential-preflight/archive-disposal legs; manual-only + default-SKIP; unit-level legs unattended; manifest | `pack-only` | pack-coder | after C-4.5/C-4.6 |
| 7 | **C-DOCS** | S-2 committed-chain-doc reconciliation: `ARCHITECTURE-BD-204.md` (carrier text -> gz64 blob; size/pacing/neutralization/storage-format; archive -> Option-A) + RECON attested-no-change; PLAN already reconciled | `pack-only` | pack-coder (maintenance-docs; NOT pack-chat-only) | after C-7 (docs describe the fully-as-built shape); docs-only, could land any time after C-RS |
| - | **REHEARSAL PROTOCOL** | repeatable scratch-repo rehearsal confirming the gate-(a) documented-silent behaviors; per-step user approval; archive-not-delete | n/a (manual procedure) | Pack Chat / user (NOT a coder) | before C-8 |
| 8 | **C-8** | real pack-repo Mode-2->3 flip via the PACED, mention-neutralized create loop, targeting the REAL (NEVER-archived) repo | `pack-only` | Pack Chat / user live RUN (per-step approval); coder only for code/config edits | LAST; green rehearsal + explicit user approval |

> **Empirical-Evidence Block (the starting state the sequence builds on).**
> `CMD`: `git rev-parse HEAD` ; `grep -n 'extra_fields\|Blockers: " + ' scripts/lib/tracker-migrate-reverse.sh` ; `grep -nE 'tmf_compose_issue_body\(' scripts/lib/tracker-migrate-forward.sh` ; `grep -oE 'Check [0-9]+' scripts/validate-pack.py | grep -oE '[0-9]+' | sort -n | tail -1`
> `OUT`: HEAD `1a8e32e0cb...`; reverse `_tmr_emit_pack_tree` is the LOSSY fixed-order projection (`lines.append("Blockers: " + (... if bl else "None"))`, `else: lines.append("Resolved: n/a")`, dead `extra = e.get("extra_fields", None)` at `:758`); `tmf_compose_issue_body(pack_id, description, context, resolution, file_symbol)` (5 params, no `raw_body`); highest check banner = `48` (next free = 49 today). `AT`: HEAD `1a8e32e`, 2026-06-07. `INTERP`: the carrier/emit-rewrite/guard are NET-NEW on the landed C-1..C-6; the lossy emit + dead carrier are the exact targets of C-4.5. `CONCL`: SUPPORTED.

---

## 2. The dependency-ordering rationale

1. **C-RS first** (adversarial-architect discipline, design §5.a): re-scope BD-204 so NO downstream coder reads a stale "carrier is solved" directive. Pure-doc; no code dep.
2. **C-4.5 before C-4.6**: the byte-faithful guard can only run GREEN against the FIXED migrator. Design §4.2 EE proves the current fixed-order emit FALSE-FAILS the byte leg on 20 no-Blockers entries (it injects `Blockers: None`); the §3.3 emit rewrite is the precondition. Land the carrier first, the guard second.
3. **C-3 amendment after C-4.5**: `tracker-edit.sh` must call the C-4.5 blob-aware composer to keep blob+H2 in sync.
4. **C-4.7 after C-4.6**: the schema doc should state the as-built (guard-enforced) field-faithful contract.
5. **C-7 rebuild after C-4.5/C-4.6**: the oracle tests the fixed behavior + the operational rules.
6. **C-DOCS after C-7 (OQ-2 RESOLVED)**: the S-2 chain-doc reconciliation is its OWN `docs:` commit, NOT folded into C-4.5; pure `maintenance-docs/`, so it lands LAST (after C-7) where the docs describe the fully-as-built carrier+guard+oracle. Docs-only -> no code dependency.
7. **Rehearsal before C-8**: gate (a) — the only remaining design condition; empirically confirm the documented-silent platform behaviors on a live scratch repo.
8. **C-8 last**: gated on a green rehearsal + explicit user approval + per-step approval; the real repo is NEVER archived.

> **Empirical-Evidence Block (the current emit FALSE-FAILS a byte-faithful guard on 20 entries -> C-4.5 must precede C-4.6).**
> `CMD`: `sed -n '746,790p' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: `_tmr_emit_pack_tree` Python emits `lines.append("Blockers: " + (", ".join(bl) if bl else "None"))`, `lines.append("Unblocks: " + ...)`, and `else: lines.append("Resolved: n/a")`, then appends `extra` pairs LAST — the fixed-order projection (design §4.2 names the 20 BD-001..BD-019 + BD-195 no-Blockers entries it false-fails). `AT`: HEAD `1a8e32e`, 2026-06-07. `INTERP`: a byte-faithful guard against this emit goes RED on 20 entries; the §3.3 verbatim-`raw_body` rewrite (C-4.5) is the precondition for a green C-4.6. `CONCL`: SUPPORTED.

---

## 3. Per-commit recipe + verification + keyword + routing

The authoritative per-commit recipes (file lists by path + symbol, change recipes, verification) are in
`PLAN-BD-204.md` §3.LF.2 .. §3.LF.11 — written in place this session so the plan and this sequence doc
do not drift. This section summarizes routing + keyword + the load-bearing recipe per commit; read
§3.LF for the full file/symbol detail.

### C-RS (§3.LF.2)
- **Keyword:** `pack-only`. **Routing:** pack-coder (MAJOR landed-entry edit; `backlog/BD-204.md` scoped into the prompt — Pack Chat scoping a pack-chat-only file into a coder prompt is the supported path, NOT a boundary violation).
- **Recipe:** ADD the design-§5.a `LOSSLESS FIELD-CARRIER + GH-RULES FIX` field block to the entry body (verbatim from §5.a); REPLACE the `Scope:` line "scratch-repo proof -> archive -> real flip" with the SETTLED Option-A wording (§5.a — REPEATABLE scratch proof, each ARCHIVED + manual-delete recommendation, REAL repo never-archived). Edit-in-place; not a full rewrite. Surface the IMPLEMENTATION CARRY-FORWARD (Deferred forward-encode) as a NOTE (already landed).
- **Verification:** `validate-pack.py` green + FULL battery (§5); no `scripts/` -> no manifest regen.

### C-4.5 (§3.LF.3) — the load-bearing fix
- **Keyword:** `pack-only` (touches `scripts/` + `maintenance-docs/` only — no `project-template/`, no `supporting-docs/`). **Routing:** pack-coder.
- **Recipe (design §3.3/§3.3a/§3.3b/§3.3c/§3.3d):** forward `_tmf_parse_backlog_file` captures `raw_body` (verbatim lines 2..EOF); `tmf_compose_issue_body` gains a DEFAULTED 6th `raw_body` param, emits the `pack-entry-body-gz64` marker (python3 gzip mtime=0 + base64), enforces the size budget (composed-body bytes vs `provider_body_limit - SAFETY_MARGIN`, fail-loud never truncate), neutralizes the H2 PROJECTION autolinks (inline-code-span; blob untouched); BD call site passes `raw_body`, phase call site passes nothing. Reverse `tracker_migrate_reverse_reconstruct` python3-decodes the blob (corrupt-blob fail-loud, never silent-empty); `_tmr_emit_pack_tree` pack branch REWRITTEN to write `pe_backpointer_line` + `raw_body` verbatim, DELETE the dead `extra_fields` read + the fixed-order `Blockers: None`/`Resolved: n/a` injection; client branch UNTOUCHED. Provider declares `provider_body_limit`/`_body_storage_format`/`_min_write_interval_s`/`_writes_per_hour_max`; create loop PACES (>=1s, honor retry-after). Tests in lock-step (forward/reverse/roundtrip/provider). **CODE+TESTS+MANIFEST ONLY** — the S-2 chain-doc corrections are the separate C-DOCS commit (OQ-2 RESOLVED; §4).
- **Verification:** `validate-pack.py` + FULL battery (§5), emphasis on the four tracker tests + `test-v11-realistic-ot.sh`; manifest regen.

### C-3 amendment (§3.LF.4)
- **Keyword:** `pack-only`. **Routing:** pack-coder.
- **Recipe (design §3.3a):** `tracker_edit_entry` regenerates BOTH H2 + gz64 blob on every `provider_update` (calls the C-4.5 blob composer); reverse divergence comparator is normalization-tolerant (CRLF->LF, per-line trailing-ws strip, single trailing-newline — exactly GH's munging, no broader; `--force` overrides to blob-wins). Tests: blob==H2 after update; comparator no-false-positive on a normalized body, mismatches a real edit.
- **Verification:** `validate-pack.py` + FULL battery; manifest regen.

### C-4.6 (§3.LF.5) — the CI faithfulness guard
- **Keyword:** `pack-only`. **Routing:** pack-coder.
- **Recipe (design §4):** new `check_migrator_field_faithfulness` (NEXT FREE integer — coder reads the registry; 49 today; NEVER hardcoded). **GUARD-SEAM HARD CONSTRAINT (OQ-4 RESOLVED): it SHELLS OUT to the REAL migrator functions via a bash sub-invocation — NEVER a Python re-implementation of the gzip+base64 codec (a second codec could drift and FALSE-PASS a lossy migration).** It drives the real `tracker-migrate-forward.sh` / `tracker-migrate-reverse.sh` functions (no `gh`/network) per `backlog/BD-*.md` and asserts (1) byte-faithful gz64 round-trip (reconstructed body span == original, back-pointer stripped), (2) size on the ACTUAL composed body, (3) title <= 256 (R-TITLE-1), (4) no disallowed control byte (R-BODY-6). WIRE the per-check test into `.github/workflows/validate-pack.yml` in the SAME commit (Check 42, no exemption). Positive (all-211 pass) + negative (synthetic lossy emit / over-limit / over-title / control-byte each FAIL) per-check test.
- **Verification:** `validate-pack.py` (new check + Check 42 green) + FULL battery + the new per-check test; manifest regen. **Ordering HARD:** AFTER C-4.5.

### C-4.7 (§3.LF.6) — schema-doc reconciliation
- **Keyword:** `pack-only`. **Routing:** pack-coder (MAJOR contract change to landed `backlog/_rules.md`; pack-chat-only file scoped into the prompt).
- **Boundary (flagged):** stays on `backlog/_rules.md` (pack-ops). `supporting-docs/METHODOLOGY.md` NOT edited (ships to clients -> editing it forfeits `pack-only` + crosses the boundary — design R9/§3.5, `boundary-investigation-precedes-pack-defaults`). Project-side `_rules.md` files NOT touched (diverge until BD-206/207, correct-by-design G-3).
- **Recipe (design §3.5):** state field-faithful migration (carries every top-level field verbatim) + template = common fields, extension fields admitted/preserved; stop enumerating a divergent optional-field list. Edit-in-place.
- **Verification:** `validate-pack.py` (Check 34 green; no validator pins the old field-list text) + FULL battery; no `scripts/` -> no manifest regen.

### C-7 REBUILD (§3.LF.7)
- **Keyword:** `pack-only`. **Routing:** pack-coder (test + fixtures); the live RUN is the separate rehearsal.
- **Recipe (design §5.c/§5.f):** rebuild `tracker-bd204-lossless-roundtrip-test.sh` + its fixtures with drop-set + no-Description + 4-form-autolink entries; the legs = drop-set content-faithfulness, size (composed-body overflow fail-loud), pacing (sleep-count + retry-after via test seam), autolink-neutralization, corrupt-blob fail-loud, normalization-comparator, CREDENTIAL-CAPABILITY PREFLIGHT (create/issues/archive, NOT delete; fail-loud on a gap; optional `gh --version` floor), ARCHIVE-not-delete disposal (`gh repo archive` + assert `isArchived`; trap-archive on failure; recommend manual delete; grep-guard NO `gh repo delete`), REPEATABLE multi-rehearsal. Manual-only + default-SKIP stays; unit-level legs ALSO run unattended.
- **Verification:** Run 1 (unattended) `validate-pack.py` + FULL battery (live oracle SKIPs; unit-level legs run via mock/in-process); Run 2 (manual) the rehearsal; manifest regen.

### C-8 (§3.LF.11)
- **Keyword:** `pack-only`. **Routing:** Pack Chat / user live RUN (per-step approval); coder only for code/config edits.
- **Scope additions (design §5.b C-8):** PACED create loop (>=1s, retry-after); mention-neutralized composer; target the REAL (NEVER-archived) repo. **Gating:** green rehearsal + explicit user approval + per-step approval.
- **Verification:** `validate-pack.py` (Check 29'/32'/33 + the new faithfulness check green) + FULL battery + a post-flip lossless spot-check (count/identity/status + byte-faithful oracle, real tree-from-tracker vs pre-flip); manifest regen if a v11-surface dir is in the diff.

---

## 4. C-DOCS — S-2 corrections owed to the COMMITTED chain docs (own `docs:` commit; OQ-2 RESOLVED)

Per `architect-doc-reality-reconciliation` + sweep S-2, the committed `maintenance-docs/` chain docs
carry the pre-fix (phantom-carrier) design and reconcile to the as-built gz64 carrier. They are NOT
pack-chat-only -> a `pack-coder` applies them under the review/fix cycle as their OWN separate `docs:`
commit (subject `docs: v11 — BD-204 reconcile committed chain docs to gz64 carrier (pack-only)`), NOT
folded into C-4.5 (which is code+tests+manifest only). Rationale: clean diff isolation + the docs have
no code dependency, so the commit lands green independently. **Slotting: LAST (after C-7, before the
rehearsal/C-8)** so the docs describe the fully-as-built carrier+guard+oracle; being docs-only it could
in principle land any time after C-RS, but last is cleanest (the docs then reflect the final shape):

- `ARCHITECTURE-BD-204.md` — §2.4.1/§2.4.2/§2.11/§3.1 carrier text -> gz64 verbatim-body blob; "zero-orphaned" claim re-grounded on the byte-faithful blob + the new faithfulness check; ADD size (stored-byte axis) + pacing + mention-neutralization + `provider_body_storage_format`; §3.4/§2.12 archive wording -> Option-A scratch-disposal. Named by §/symbol, never line number.
- `PLAN-BD-204.md` — already reconciled by this session's §3.LF amendment; the coder need NOT re-edit it (flag in the C-4.5 prompt to avoid a double edit).
- `ARCHITECTURE-BD-204-POST-BD211-RECON.md` — ATTESTED no rule-driven change (S-2.3); leave as accurate history.

(OQ-2 in §7 RESOLVED: C-DOCS is the separate `docs:` commit.)

> **Empirical-Evidence Block (the committed chain docs predate the gz64/pacing/neutralization design).**
> `CMD`: `grep -lniE 'pack-entry-body-gz64|pacing|retry-after|provider_body_storage_format|neutraliz' maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md maintenance-docs/v11-implementation/PLAN-BD-204.md`
> `OUT`: (empty before this session's PLAN amendment — neither committed doc mentioned any of these; PLAN-BD-204.md now carries §3.LF in the working tree). `AT`: HEAD `1a8e32e`, 2026-06-07. `INTERP`: `ARCHITECTURE-BD-204.md` still carries the pre-sweep carrier/sequence at HEAD; the coder reconciles it in C-4.5. `CONCL`: SUPPORTED.

---

## 5. The FULL unattended CI battery (per-commit verification)

Per `verify-full-ci-suite`, EACH commit's verification runs `python3 scripts/validate-pack.py` AND the
ENTIRE unattended battery from `.github/workflows/validate-pack.yml` (NOT a named subset). The live
oracle is the SEPARATE manual rehearsal (default-SKIP unattended). The battery (the workflow `run:`
set at HEAD `1a8e32e`):

`tracker-migrate-reverse-test.sh`, `tracker-migrate-roundtrip-test.sh`, `test-tracker-phase-task.sh`,
`test-tracker-links.sh`, `test-tracker-cycle-check.sh`, `tracker-errors-test.sh`,
`tracker-config-schema-test.sh`, `recommendation-state-schema-test.sh`, `test-per-entry.sh`,
`test-validate-pack-checks-32-33-34.sh`, `test-validate-pack-checks-36-37-38.sh`,
`test-validate-pack-check-39.sh`, `test-validate-pack-check-40.sh`, `test-validate-pack-check-41.sh`,
`test-validate-pack-check-18.sh`, `test-validate-pack-check-16.sh`, `test-validate-pack-check-19.sh`,
`test-validate-pack-check-42.sh`, `test-validate-pack-check-43.sh`, `test-validate-pack-check-44.sh`,
`test-validate-pack-check-45.sh`, `test-validate-pack-check-46.sh`,
`test-validate-pack-check-removed-doc-advisory.sh`, `tracker-bd129-gh-repo-test.sh`,
`tracker-bd130-doctor-wired-test.sh`, `tracker-bd132-race-test.sh`,
`tracker-bd133-header-preservation-test.sh`, `tracker-bd134-close-retry-test.sh`,
`recommendation-test.sh`, `pack-help-test.sh`, `test-customization-preserve.sh`,
`test-init-project.sh`, `test-migrate-v10-to-v11.sh`, `test-migrate-v10-to-v11-dry-run.sh`,
`test-migrate-v10-to-v11-gates.sh`, `test-migrate-v10-to-v11-decompose.sh`,
`test-v11-realistic-ot.sh`, `template-translations-test.sh`, `template-version-test.sh`,
`test-issue-forms.sh` — PLUS, once C-4.5 lands, `tracker-migrate-forward-test.sh` +
`tracker-provider-test.sh` (the coder confirms they are wired or wires them), and once C-4.6 lands,
`test-validate-pack-check-<NN>-field-faithfulness.sh` (wired by C-4.6, enforced by Check 42).

`test-v11-realistic-ot.sh` runs on EVERY commit (banner-pinning — a clean `validate-pack` can still go
CI-RED on a stale banner assertion). Every `scripts/`-touching commit regenerates+stages
`test-fixtures/manifest.txt` in the SAME commit when the manifest diff is non-empty.

> **Empirical-Evidence Block (the battery list is the workflow's `run:` set, not a subset).**
> `CMD`: `grep -cE 'run: bash scripts/tests/' .github/workflows/validate-pack.yml`
> `OUT`: ~41 `run: bash scripts/tests/<file>` lines (the set enumerated above) + the `validate-pack.py` step. `AT`: HEAD `1a8e32e`, 2026-06-07. `INTERP`: the per-commit battery = this complete list; the live oracle is the separate manual rehearsal. `CONCL`: SUPPORTED.

---

## 6. The REHEARSAL PROTOCOL (gate (a) — manual, before C-8)

The repeatable scratch-rehearsal empirically confirms the documented-silent platform behaviors the
unattended battery cannot (they need a live repo) BEFORE the real flip. It is a manual, user-gated
procedure run via the rebuilt C-7 oracle — NOT a coder spawn, NOT a CI job; agents NEVER run live GH on
their own authority.

- **Who:** Pack Chat / the user, with PER-STEP user approval on every `gh` mutation (create / issue-write / archive).
- **How:** `PACK_TRACKER_LIVE_GH=1 bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` against authenticated `gh`. As MANY throwaway scratch repos as needed; each uniquely-named; each ARCHIVED at end (NEVER tool-deleted — `reference_gh_pat_no_delete`); a manual-delete recommendation surfaced.
- **What it confirms (design §11.2 known-unknown -> leg map) BEFORE C-8:** (DS-1) stored byte-verbatim — decode the stored blob, assert byte-identical; (DS-2) web-edit normalization — edit body via API/web, the §3.3a comparator does NOT false-positive an untouched-but-normalized body AND catches a real edit; (DS-3) size near-budget — a near-`limit-margin` entry succeeds, one over -> GH 422; (KU-OPS-2/3) paced create — >=1s spacing trips NO 403/429, no abuse-flag; (KU-OPS-6) autolink-render — the 4-form fixture renders NO live link; (KU-CRED) the preflight verifies create+issues+archive (NOT delete) and the disposal archives + asserts `isArchived` + recommends manual delete.
- **Pass criterion:** ALL legs green on a clean run; scratch repo ARCHIVED (read-only) at end; manual-delete recommendation surfaced.
- **Output -> gate:** a GREEN rehearsal is a PRECONDITION for C-8; Pack Chat surfaces the artifacts + flip plan; the user approves the real flip explicitly.

---

## 7. Resolved questions (user decisions, 2026-06-07)

- **OQ-1 — RESOLVED: the fix stays IN BD-204; NO discrete BD-212.** It completes BD-204's own un-met lossless-reversibility acceptance criterion, so it is not new scope (C-RS encodes it inside BD-204). Rationale: a fix to a BD's own un-met acceptance criterion belongs to that BD; a new ID would fragment the launch-gate audit trail. (The BD-212 alternative is removed.)
- **OQ-2 — RESOLVED: the S-2 corrections are their OWN `docs:` commit (C-DOCS), NOT folded into C-4.5.** C-4.5 is code+tests+manifest only. Rationale: clean diff isolation (carrier-code review undiluted by prose-doc edits) + the chain docs have no code dependency, so C-DOCS lands green independently. Slotting: LAST (after C-7) so the docs describe the fully-as-built shape (see §4).
- **OQ-3 — RESOLVED: KEEP both the blob AND the H2 projection; the C-3 amendment STAYS as its own commit.** No blob-only simplification (the readable GH Issue B-3 preserves + the lossless blob are both retained, design §3.3). `tracker-edit.sh`'s blob+H2 sync + the normalization-tolerant divergence comparator remain necessary and ship as the standalone C-3 amendment commit. Rationale: keeping both requires the sync, which is the Mode-3 edit-path concern — not the migrator carrier — so a standalone commit, not a fold into C-4.5.
- **OQ-4 — RESOLVED: the C-4.6 guard SHELLS OUT to the REAL migrator functions; NO Python codec re-implementation.** HARD CONSTRAINT in the C-4.6 recipe (§3): the check drives the real `tracker-migrate-forward.sh` / `tracker-migrate-reverse.sh` functions via a bash sub-invocation (no network), NEVER a re-coded gzip+base64. Rationale: a second codec could drift from the real one and FALSE-PASS a lossy migration — the guard must exercise the exact production code path.

---

## 8. Routing summary (MAJOR/MINOR + boundary)

| Change | Surface | MAJOR/MINOR | Route |
|---|---|---|---|
| C-RS — re-scope `backlog/BD-204.md` | pack-chat-only entry | MAJOR (substantive edit to landed entry content) | pack-coder (file scoped into prompt) |
| C-4.7 — `backlog/_rules.md` field-faithful contract | pack-chat-only contract | MAJOR (contract change to landed content) | pack-coder (file scoped into prompt) |
| C-4.5 / C-3 amend / C-4.6 / C-7 — code/test/fixtures | `scripts/`, `.github/workflows/` | MAJOR (code; outside the small pack-chat-only set) | pack-coder |
| C-DOCS — S-2 committed-chain-doc reconciliation | `maintenance-docs/` | MAJOR (committed maintenance-docs; NOT pack-chat-only) | pack-coder (own `docs:` commit, OQ-2) |
| `supporting-docs/METHODOLOGY.md` | client-shipped | — | NOT edited (boundary; would forfeit `pack-only`) |
| project-side `_rules.md` x3 | project-side | — | NOT touched (diverge until BD-206/207 — correct-by-design) |

Every commit carries ONLY its true keyword (`pack-only`); no commit's file set crosses into
`project-template/` or `supporting-docs/`, so the `pack-only` claim is honest under CI Check 36
(commit-subject-keyword-token-trap: no denying keyword token appears in any subject or prose).

---

## 9. Rules-Applied Verification Block

| Rule | Verification evidence (actual command / quote / measurement) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` or any state-changing git verb issued; only `git rev-parse HEAD` / `git log` (read-only) + `grep`/`sed`/`ls`. The writes are the in-place `PLAN-BD-204.md` §3.LF amendment + this report — both via file write, NO git verb. | COMPLIANT |
| `edit-in-place-not-full-rewrite` | `PLAN-BD-204.md` amended by targeted python `str.replace` edits (the supersession banner; §3.LF insert; then the OQ fold-in: §3.LF.12 -> RESOLVED, the table C-4.5/C-DOCS/C-8 rows, §3.LF.0/.3/.5/.6/.8 reconciled), each asserting `count == 1` on the anchor. This companion likewise edited in place (table, §2, §3 C-4.5/C-4.6, §4, §7, §8). NO full rewrite; untouched sections byte-stable. | COMPLIANT |
| `empirical-evidence-blocks` | Every state-claim carries CMD + verbatim OUT + HEAD `1a8e32e` + 2026-06-07 + INTERP + CONCL: the starting-state block (§1), the false-fail block (§2), the chain-doc block (§4), the battery block (§5), plus §3.LF.0's starting-state block in the PLAN. | COMPLIANT |
| `verify-full-ci-suite` | §5 + §3.LF.9 enumerate the COMPLETE workflow battery (~41 `run:` lines from `validate-pack.yml`), not a subset; `test-v11-realistic-ot.sh` named on every commit (banner-pinning); the live oracle named as the SEPARATE manual rehearsal. | COMPLIANT |
| `regenerate-manifest-v11-surface` | Every `scripts/`-touching commit (C-4.5/C-3-amend/C-4.6/C-7) flags `bash test-fixtures/build.sh --all --clean` + stage `test-fixtures/manifest.txt` in the SAME commit; the doc-only commits (C-RS, C-4.7) explicitly do NOT touch `scripts/` -> no regen; C-8 conditional on a v11-surface diff. | COMPLIANT |
| `commit-subject-keyword-token-trap` | Each planned subject carries ONLY `pack-only`; §8 verifies no file set crosses into `project-template/`/`supporting-docs/`; no denying keyword token (`project-only`/`pack-chat-only`) appears in any subject or prose. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly: the ordered commit table (8 numbered commits + the manual rehearsal), per-commit recipe/verification/keyword/routing, the dependency-ordering rationale, the rehearsal protocol, the entry-rescope + schema-doc coder-routing, the S-2 C-DOCS commit, and the 4 user-decided OQs folded in (all read RESOLVED); no design change (the spec is sequenced, not re-decided). | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | The schema reconciliation (C-4.7) stays on `backlog/_rules.md` (pack-ops); `supporting-docs/METHODOLOGY.md` is explicitly NOT edited (client-shipped — design R9/§3.5); project-side `_rules.md` NOT touched. §8 records the boundary. | COMPLIANT |
| `pack-chat-minor-edits-only` | C-RS (substantive edit to a landed entry) + C-4.7 (contract change to landed `_rules.md`) are both routed to pack-coder with the pack-chat-only file scoped into the prompt — NOT Pack-Chat-direct, because both are MAJOR (substantive edits to ALREADY-LANDED content, not new-entry authoring / bookkeeping tokens). §1 table + §8 flag the routing. | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |

---

## 10. READ-IN-FULL attestation (per-file direct-read proof, this session, HEAD `1a8e32e`)

| Document | Direct-read proof |
|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` | Read FULL (1-479, 480-958, 959-1370) — the spec; §3.3/§3.3a-e carrier+size+pacing+neutralization+guards, §4 CI guard, §5.a-f re-scope/sequence/C-7-rebuild/credential-preflight, §11 verdict + known-unknown map. |
| `SWEEP-BD-204-RULES-COMPLIANCE.md` | Read FULL (1-503) — S-1..S-9 ledger; S-2 chain-doc corrections, S-3 script changes by file+symbol, S-5 the 8 decided items, S-6 the commit sequence. |
| `PLAN-BD-204.md` | Read FULL (1-544, 545-689) — the doc amended in place (§3.LF inserted; §0..§9 untouched). |
| `RESEARCH-BD-204-GH-ISSUES-RULES.md` (30 rules) | Read via the spec + sweep citations of every rule (R-BODY-1..7, R-TITLE-1/2, R-OPS-1..7, R-ACCT-1..5, etc.); the rule IDs the sequence binds to (size axis, pacing, autolink, title/control, archived-read-only, credential) traced to the law. |
| `backlog/BD-204.md` | Read FULL (1-27) — the entry C-RS re-scopes; the `Scope:` archive wording (`:20`); the IMPLEMENTATION CARRY-FORWARD line. |
| `scripts/lib/tracker-migrate-forward.sh` | Read via grep — `_tmf_parse_backlog_file` (`:381`), `tmf_compose_issue_body` (`:601`, 5-param), BD call site (`:901`), phase call site (`:959`), create loop / `provider_create` (`:911`/`:965`), `_tmf_labels_for_entry` (`:1501`), `TMF_STABILIZE_*` sleeps. |
| `scripts/lib/tracker-migrate-reverse.sh` | Read directly — `tracker_migrate_reverse_reconstruct` (`:523`), `_tmr_emit_pack_tree` (`:712`, the lossy fixed-order projection + dead `extra_fields` read `:758` + `per_entry_regenerate_toc` `:822`), `_tmr_emit_backlog` client branch (`:627`), `local force` (`:985`), the emit dispatch (`:1268`/`:1284`). |
| `scripts/lib/tracker-edit.sh` | Read via grep — `tracker_edit_entry` (`:156`), the `provider_update` payload build (`:212`-`:237`), the C-3 call-shape reuse note. |
| `scripts/lib/tracker-provider.sh` / `tracker-provider-gh.sh` | Read via grep — provider op-set; GH capability block (`writes_per_minute_recommended:60` `:770`, `result_ceiling_per_query:1000` `:767`, `raw_escape_hatch:true` `:773`), `_gh_classify_error` (`:61`). |
| `scripts/validate-pack.py` | Read via grep — the check registry (highest banner 48; `check_ci_workflow_wires_per_check_tests` Check 42 `:6486` no exemption; `check_removed_doc_advisory` Check 48). |
| `.github/workflows/validate-pack.yml` | Read via grep — the ~41 `run: bash scripts/tests/<file>` battery lines + the per-check wiring contract Check 42 enforces. |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (parked C-7) | Read FULL (1-329) — the default-SKIP guard, the `gh repo delete` disposal the rebuild replaces with archive, the 6 legs the rebuild extends (drop-set/size/pacing/neutralization/corrupt-blob/normalization/preflight). |
| `scripts/tests/fixtures/tracker-bd204-lossless/` | Listed (BACKLOG.md + tracker.toml) — the fixture the rebuild extends with drop-set + no-Description + 4-form entries. |
| `backlog/_rules.md` | Read via grep — the `Position:` optional-field line (`:49`) the C-4.7 reconciliation removes; the METHODOLOGY Part 7 citation. |
| `CLAUDE.md ## Pack memory` | Provided in full in session context — the in-force rules (pack-chat-minor-edits-only, boundary-investigation, regenerate-manifest, enumerate-encoding-surfaces, bounded-review-fix-cycle, agents-never-commit) applied. |
| Memory files | Read FULL this session: `reference_gh_pat_no_delete.md` (archive-not-delete + credential preflight), `feedback_review_fix_cycle.md` (bounded cycle). Carried from MEMORY.md index: `feedback_verify_full_ci_suite`, `feedback_manifest_regen_on_v11_surface`, `feedback_commit_subject_keyword_token_trap`, `feedback_pack_chat_boundaries`, `feedback_scope_deliverables_to_the_ask`, `feedback_agent_output_rules_applied_block`, `feedback_external_rules_census_before_design`. |

**No named document was derived rather than read.** Every spec, ledger, entry, code file, fixture,
workflow, and memory file above was opened directly via Read/Bash this session at HEAD `1a8e32e`
(2026-06-07).

**End of PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md**
