# IMPL-REPORT-BD-204-C-DOCS — committed-chain-doc reconciliation to the gz64 carrier

> **Agent:** pack-coder. **Commit:** C-DOCS (the BD-204 lossless-fix sequence, sweep S-2 /
> OQ-2-resolved own `docs:` commit). **Scope:** docs-only, pack-only — the ONLY content file
> edited is `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`; this report is the
> second write. No git state changes were made (read-only git verbs only).

## 1. Branch + final HEAD SHA

- Branch: `v11-dev`
- HEAD (unchanged — coder does not commit): `c7f9af6a575af00baaea0cb6e02261e141be5bfe`
- Matches the caller-stated base (`c7f9af6`). All diffs in §4 apply against this SHA.

## 2. Pre-flight check output

```
$ git rev-parse HEAD
c7f9af6a575af00baaea0cb6e02261e141be5bfe
$ git status --short
(clean)
$ git log --oneline -8
c7f9af6 feat: v11 — BD-204 rebuild lossless oracle: drop-set fixtures + operational-rule legs + archive-disposal + credential preflight (pack-only)
c30c8d5 docs: v11 — BD-204 backlog/_rules.md field-faithful migration + Position/template contradiction fix (pack-only)
40eaa85 fix: align test-tracker-promote-path1.sh 8.3 to current METHODOLOGY (...)
df77032 feat: v11 — BD-204 C-4.6 field-faithfulness guard (...) (pack-only)
f89ade5 feat: v11 — BD-204 C-4.5-addendum: single-source batch mode for the gz64 codec (...) (pack-only)
cadfc23 docs: v11 — BD-204 C-4.6 re-sequenced for Option B (...) (pack-only)
5ed89b3 docs: v11 — BD-204 C-4.6 §4.6 finalized (...) (pack-only)
ab56c9c docs: v11 — BD-204 C-4.6 recipe redone for runtime (...) (pack-only)
$ git rev-parse --abbrev-ref HEAD
v11-dev
```

`ls maintenance-docs/v11-implementation/` confirmed all named inputs present
(`PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md`, `ARCHITECTURE-BD-204-LOSSLESS-FIX.md`,
`ARCHITECTURE-BD-204.md`, `ARCHITECTURE-BD-204-POST-BD211-RECON.md`, `PLAN-BD-204.md`, the
C-4.5/C-4.5-addendum/C-4.6/C-7 IMPL reports). Read in full this session:
`PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md` (242 lines), `ARCHITECTURE-BD-204-LOSSLESS-FIX.md`
(1707 lines), `ARCHITECTURE-BD-204.md` (1044 lines pre-edit), plus CLAUDE.md (session context),
`pack-ops/PACK-AGENTS.md`, `backlog/_rules.md`, and the `implementation-report` /
`verification-harness` / `commit-discipline` / `boundary-investigation` skills. As-built code
claims were cross-checked read-only against `scripts/lib/tracker-migrate-forward.sh`,
`scripts/lib/tracker-migrate-reverse.sh`, `scripts/lib/tracker-provider-gh.sh`,
`scripts/lib/tracker-edit.sh`, `scripts/validate-pack.py`,
`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`, and
`.github/workflows/validate-pack.yml`.

Note on environment: this session runs in-place against the parent chat's working tree
(per CLAUDE.md "Spawn all sub-agents with no worktree isolation"), so `pwd` is the main v11-dev
checkout, not a `worktree-agent-*` path — consistent with the caller's spawn mode.

## 2a. Gap-still-exists verification (per the prompt: do not blindly re-apply)

The plan was written at HEAD `1a8e32e`; several commits landed after it. Verified at HEAD
`c7f9af6` that EVERY §4-named gap still existed (nothing was already reconciled):

```
$ grep -niE 'pack-entry-body-gz64|pacing|retry-after|provider_body_storage_format|neutraliz|provider_body_limit|gz64|isArchived|gh repo archive|gh repo delete' \
    maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md
853:   `tree → Issues → tree` against it, run the §3.2 oracle, then `gh repo delete` (cleanup). NEVER
865:explicit `gh repo delete`); a scratch repo is never left dangling. The test asserts the scratch
```

INTERP: zero as-built terms (gz64 blob / pacing / retry-after / neutralization / storage format
/ body limit / archive disposal) anywhere in the committed doc; the only matches were the two
pre-fix `gh repo delete` lines in §3.4. A `grep -n 'pack-extra-fields'` census found 24 phantom-
carrier sites. CONCL: the full §4 edit set applied; nothing attested-already-done. (Contrast:
`PLAN-BD-204.md` §3.LF and `backlog/_rules.md` were already reconciled by C-RS/C-4.7/earlier
commits — both verified present and NOT edited by this pass, per the prompt's do-not-touch list.)

Per the caller's instruction, the stale plan-§4 evidence-block INTERP line ("the coder
reconciles it in C-4.5") was ignored; the authoritative §1 table row C-DOCS + §7 OQ-2
resolution (own separate `docs:` commit) were followed.

## 3. Per-task summary

One file modified: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`
(+259 / −74; 1044 → 1228 lines). 15 targeted in-place edits; untouched sections byte-stable.

| # | Section | What changed |
|---|---|---|
| E1 | §1 DP-2 | As-built note (blockquote) added after the RESOLVED paragraph: in-body carrier realized as the gz64 blob; `pack-extra-fields` was a phantom; DP-2 substance unchanged; dated-record mentions marked superseded. |
| E2 | §2.1 step 2 | Regen-path object now described as carrying the verbatim `raw_body` decoded from the `pack-entry-body-gz64` blob. |
| E3 | §2.4 intro | Carrier restatement → gz64 blob; boundary framing → form projection vs body (blob). |
| E4 | §2.4 table | `Target:` / `Position:` / extension-field / structured-sub-block carrier cells → the gz64 blob (round-trip source) + H2 projection. |
| E5 | §2.4 boundary principle | Rewritten: form projection is advisory; the blob is the round-trip source, byte-faithful, no per-field capture; zero-orphaned by construction + guard-enforced. |
| E6 | §2.4.1 | Carrier statement REPLACED with the as-built gz64 verbatim-body blob (span lines 2..EOF, gzip `mtime=0` + base64, python3-pinned codec, corrupt-blob FAIL-LOUD, blob-authoritative with normalization-tolerant divergence backstop + `--force`); realized consumers named by file + symbol; ADDED the as-built operational contract block: stored-byte size budget (`provider_body_limit − TMF_SIZE_SAFETY_MARGIN`, fail-loud never truncate), ≥1s write pacing + retry-after (caps 80/min + 500/hr), inline-code-span autolink/mention neutralization of the projection only, and `provider_body_storage_format` (`raw_text` required; `rich_text_normalizing` fails loud). |
| E7 | §2.4.2 | EE INTERP reconciled (projection vs round-trip source) + a "Re-grounding (2026-06-10)" paragraph: zero-orphaned rests on the byte-faithful blob + `check_migrator_field_faithfulness` (Check 49, deep-gated, single-sourced batch codec, `PRE_PARSE_ORIGINAL_body == decode(encode(raw_body))` + size + title + control-char legs). |
| E8 | §2.4.1 mini-block | Three evidence cells updated to the blob carrier + raw-text-class portability boundary. |
| E9 | §2.10 | Structured-carrier phrase → the gz64 blob. |
| E10 | §2.11 | Lossless-contract pillars rebuilt: (a) pack-id identity, (b) the byte-faithful blob, (c) partial-write refusal + corrupt-blob fail-loud + divergence backstop (by symbol — the `:1032-1042` line ref removed), (d) status matrix, (e) the Check-49 CI guard. |
| E11 | §2.12 ON bullet | Create loop described as PACED (min-write-interval + retry-after) with neutralized H2 projection. |
| E12 | §2.12 repeated-cycle bullet | Entire body crosses the gap via the deterministic blob (fixed point after one cycle). |
| E13 | §3.1 | Item 4 → "Entire body recovered" via the blob, by construction; new enforcement paragraph naming Check 49's four legs. |
| E14 | §3.4 | Archive wording → Option-A scratch disposal: credential-capability preflight first (create/issues/archive, NOT delete; gh ≥ 2.0 floor); REPEATABLE uniquely-named scratch repos; ARCHIVE-only end-state (`isArchived == true` asserted; trap-archives on failure); tool NEVER deletes (`gh repo delete` grep-guarded out of the test source); manual delete = user-only RECOMMENDED step; REAL repo NEVER archived; real flip uses the paced, neutralized loop; rebuilt-oracle legs named; "Cleanup contract" → "Disposal contract (Option A, as-built)". Both `gh repo delete`-as-cleanup statements removed. |
| E15 | §4.3 + new §7 | §4.3 code note → blob emit/decode path by symbol; NEW §7 reconciliation addendum: per-section ledger, realized-consumer chain (file + symbol), explicit disposition of dated records left byte-stable (DP-2 wording, §2.4.2 EE CMD/OUT, §5, §6), do-not-touch attestations for `PLAN-BD-204.md` + `ARCHITECTURE-BD-204-POST-BD211-RECON.md`, and a Rules-Applied mini-block. |

All new references name realized consumers by file + §/symbol — no new line-number references
(one pre-existing line-number citation inside rewritten §2.11 text was converted to a symbol).

## 4. Unified diff (modified file, against base `c7f9af6`)

Produced via `git diff maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` at base
`c7f9af6` (449 lines, verbatim below):

`````diff
diff --git a/maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md b/maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md
index 2253574..7f9a662 100644
--- a/maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md
+++ b/maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md
@@ -110,6 +110,14 @@ solve (the adversarial case + its banner/doctor mitigation are kept above for th
 HTML-comment block)**. The separate `.pack-tracker/reverse.sidecar.*` FILE is **DROPPED ENTIRELY
 for BD-204 / v11.0.** NOTHING rides a sidecar file.
 
+> **As-built note (reconciled 2026-06-10 per `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §1.3/§3.3).**
+> DP-2's substance — form family + Issue body, NO sidecar — is unchanged, but the in-body
+> carrier is REALIZED as the `pack-entry-body-gz64` VERBATIM-BODY BLOB (§2.4.1 as-built), not
+> the `pack-extra-fields` named-scalar block this dated record names (that block was a phantom
+> — never produced by forward, never read by reverse — and is deleted from the design).
+> Mentions of `pack-extra-fields` in this §1 decision record describe the superseded pre-fix
+> realization; the as-built carrier is §2.4.1's gz64 blob. See §7 for the reconciliation ledger.
+
 **HARD INVARIANT (user-imposed):** ALL flat-file / entry content MUST be preserved using the form
 family + the entry body (including the in-body `pack-extra-fields` block for `Target:`/`Position:`/
 etc.). Nothing rides a sidecar.
@@ -263,7 +271,8 @@ BD, not BD-204.
    (filtered by the `work-item` label + `pack-id` marker — lane separation, §2.8).
 2. For each Issue, `_tmr_reverse_reconstruct` (`tracker-migrate-reverse.sh:506`) builds an
    in-memory entry object (`pack_id/title/status/type/blockers/unblocks/description/context/
-   resolution` + the in-body `pack-extra-fields` block overflow — no sidecar file).
+   resolution` + the verbatim `raw_body` decoded from the in-body `pack-entry-body-gz64` blob
+   (§2.4.1 as-built) — no sidecar file).
 3. The reverse emitter writes the per-entry tree DIRECTLY (one file per entry via
    `pe_write_atomic` + `pe_backpointer_line`, §2.2) — NOT a monolith.
 4. `per_entry_regenerate_toc pack-backlog /backlog` regenerates `_toc.md` (DP-4).
@@ -425,10 +434,11 @@ tracker floor (`DESIGN-BRIEF.md:252` status-taxonomy-is-backend-declared).
 
 ### 2.4 Overflow carrier — field-overflow boundary (carrier = form family + Issue body; NO sidecar file)
 
-The carrier is RESOLVED at DP-2 (user 2026-06-06): the **form family + the GH Issue BODY** (prose +
-the in-body `pack-extra-fields` HTML-comment block). The `.pack-tracker/reverse.sidecar.*` FILE is
+The carrier is RESOLVED at DP-2 (user 2026-06-06): the **form family + the GH Issue BODY** —
+as-built (reconciled 2026-06-10), the in-body carrier is the `pack-entry-body-gz64` verbatim-body
+blob (§2.4.1). The `.pack-tracker/reverse.sidecar.*` FILE is
 DROPPED for v11.0 — nothing rides a sidecar. The architect resolves the BOUNDARY: which fields ride
-a form field vs the Issue body vs the in-body `pack-extra-fields` block. There is NO "spill to a
+a form field (label/link/H2 projection) vs the Issue body (the blob). There is NO "spill to a
 sidecar file" option.
 
 > **Empirical-Evidence Block (the built reverse reconstruct field-set vs real pack-entry fields).**
@@ -450,20 +460,22 @@ sidecar file" option.
 | `Unblocks:` | `wi-unblocks` body (informational) | inverse of blockers; no link semantics |
 | `File/Symbol:` | `wi-file-symbol` input → body | free-form (D-17 textarea) |
 | `Description:`/`Context:`/`Resolution:` | `wi-description`/`wi-context`/`wi-resolution` body | free-text prose (D-17) |
-| **`Target:`** (e.g. "v11.0") | **in-body `pack-extra-fields` block** (Issue body) | pack-specific, no form field; lives IN the Issue (SSOT); rendered inline into the regenerated entry |
-| **`Position:`** | **in-body `pack-extra-fields` block** (Issue body) | pack-specific ordering hint, no form field; in-Issue, rendered inline |
-| **`Alias:`/`Surfaced:`/`Paused:`/`Problem:`/`Out of scope:`/`References:`/`Quality bar:`** (any other named entry field) | **Issue BODY** (free-text section) or in-body `pack-extra-fields` (named scalar) | every leading-label entry field maps to the body; none is orphaned (§2.4.1 census) |
-| **structured sub-blocks** (`Segments:`/`Steps:`/`State:`/`Goal:`/`Scope:`/`Quality bar:` in large entries) | **Issue BODY verbatim** (D-17 free-text); any NAMED scalar field needing parseable recovery → the in-body `pack-extra-fields` block | the body is the faithful free-text carrier; prose preserved verbatim; no sidecar |
+| **`Target:`** (e.g. "v11.0") | **the in-body verbatim-body blob** (`pack-entry-body-gz64`, §2.4.1 as-built) | pack-specific, no form field; lives IN the Issue (SSOT); recovered byte-faithfully from the blob on regen |
+| **`Position:`** | **the in-body verbatim-body blob** (`pack-entry-body-gz64`, §2.4.1 as-built) | pack-specific ordering hint, no form field; in-Issue, recovered from the blob |
+| **`Alias:`/`Surfaced:`/`Paused:`/`Problem:`/`Out of scope:`/`References:`/`Quality bar:`** (any other named entry field) | **Issue BODY** — the gz64 verbatim-body blob (round-trip source) + the visible H2 projection | every leading-label entry field rides the blob byte-verbatim; none is orphaned (§2.4.2 re-grounded) |
+| **structured sub-blocks** (`Segments:`/`Steps:`/`State:`/`Goal:`/`Scope:`/`Quality bar:` in large entries) | **Issue BODY verbatim** — the gz64 verbatim-body blob (no per-field capture, no re-parse on the carry path) | the blob is the faithful byte carrier; prose preserved verbatim; no sidecar |
 | parenthetical title (`(Code Red 3)`) | identity carrier (§2.7), NOT a field | title text, round-trips via the ID carrier |
 
-**Boundary principle (the locked model, property-fit-verified):** a field rides a FORM field iff
-a finite enum drives a label/link/state-transition (D-17, `ARCHITECTURE-V3.3-DELTA.md:312`);
-otherwise it rides the Issue BODY (free-text prose, byte-faithful) or, if it is a named pack field
-the form grammar cannot name, the in-body `pack-extra-fields` HTML-comment block (which lives IN
-the Issue body, the SSOT). There is NO sidecar file. No pack field has "nowhere to go" — every
-named entry field maps to a form field or the Issue body (§2.4.1 census proves zero orphaned
-fields). The large-entry stress case (BD-195's `Segments:`/`Steps:`/`Goal:`/`Scope:`) rides the
-Issue body verbatim — the body-faithfulness audit (§3) proves it.
+**Boundary principle (as-built, property-fit-verified):** a field rides a FORM field iff
+a finite enum drives a label/link/state-transition (D-17, `ARCHITECTURE-V3.3-DELTA.md:312`) —
+and that projection is ADVISORY. The round-trip source for the ENTIRE entry body is the
+`pack-entry-body-gz64` VERBATIM-BODY BLOB (§2.4.1), which lives IN the Issue body (the SSOT)
+and carries every field line and prose block byte-faithfully with NO per-field capture. There
+is NO sidecar file and NO named-scalar `pack-extra-fields` block (deleted — it was never
+implemented; see §2.4.1 as-built). No pack field has "nowhere to go" — every named entry field
+and prose block rides the blob BY CONSTRUCTION (§2.4.2 re-grounded). The large-entry stress
+case (BD-195's `Segments:`/`Steps:`/`Goal:`/`Scope:`) rides the blob verbatim — enforced by
+the unattended faithfulness guard (§2.4.2).
 
 ### 2.4.1 Overflow physical home — DROP the sidecar file; carrier = form family + Issue body (DP-2 RESOLVED)
 
@@ -482,23 +494,69 @@ HARD tracker-agnostic requirement (`backlog/BD-204.md:14`). So anything GH-Issue
 NOT part of the entry body is DROPPED for v11.0 (§2.4.2). A future, multi-tracker-agnostic
 preservation mechanism is a FUTURE BD, not v11.0.
 
-**The carrier, stated once.** Round-tripping NAMED pack fields (`Target:`/`Position:`/any future
-v11.x named field) live IN the GH Issue BODY as a hidden HTML-comment block, parallel to the
+**The carrier, stated once (AS-BUILT — reconciled 2026-06-10 per
+`ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3; supersedes the `pack-extra-fields` named-scalar
+block, which was a phantom — never produced by forward, never read by reverse — and is deleted).**
+The round-trip source for the ENTIRE entry body — named pack fields (`Target:`/`Position:`/any
+future named field), the common fields, AND every prose sub-block — is ONE hidden HTML-comment
+marker carrying the entry's verbatim captured span (lines 2..EOF: the bold-header line + every
+field/prose line), deterministic-gzip (`mtime=0`) + base64-encoded, emitted alongside the
 existing marker trio (`work-item.yml:103-105`):
 
 ```
-<!-- pack-extra-fields:
-Target: v11.0
-Position: v11.0 launch gate; after BD-203, before BD-197
--->
+<!-- pack-entry-body-gz64: H4sIAAAAAAAAA8tIzcnJVyjPL8pJUQQAlRmFGwwAAAA= -->
 ```
 
-This block IS in the Issue body — so the tracker is the SOLE SSOT for these fields (HARD true-SSOT,
-`backlog/BD-204.md:14`) and they cannot go missing independently of the Issue. On regen, the block
-is read back and rendered INLINE into `/backlog/BD-NNN.md` (one-file-read; §3.1 byte-faithful). The
-prose sub-blocks (`Description:`/`Context:`/`Resolution:`/`Goal:`/`Scope:`/`Steps:`/`Segments:`/
-`State:`/`Problem:`/`Out of scope:`/`References:`/`Quality bar:`) ride the visible Issue body
-verbatim (D-17 free-text). No sidecar file is written or read on the pack surface.
+This blob IS in the Issue body — so the tracker is the SOLE SSOT for every field (HARD true-SSOT,
+`backlog/BD-204.md:14`) and no field can go missing independently of the Issue. On regen, reverse
+base64-decodes + gunzips the blob (the codec is python3-pinned on both paths) and writes the body
+back BYTE-FOR-BYTE: the reconstructed `/backlog/BD-NNN.md` = the derived back-pointer line + the
+verbatim body. Decode is FAIL-LOUD on a corrupt/absent-payload blob (never silent-empty). The
+visible H2 sections (`## Description` / `## File / Symbol` / `## Context` / `## Resolution`)
+STILL emit as the human/GH-readable PROJECTION — they are NOT the round-trip source; the blob is
+authoritative, and a blob↔H2 divergence (e.g., a direct GH web edit not propagated to the blob)
+is DETECTED by a normalization-tolerant comparator and surfaced loudly, never silently resolved
+(`--force` = explicit operator blob-wins override). There is NO per-field capture, NO field
+re-parsing on the carry path, and NO sidecar file written or read on the pack surface.
+
+**Realized consumers (file + symbol — never line numbers):** forward —
+`scripts/lib/tracker-migrate-forward.sh` `_tmf_parse_backlog_file` (captures `raw_body`, the
+verbatim lines-2..EOF span, alongside the unchanged field extraction) and `tmf_compose_issue_body`
+(DEFAULTED 6th `raw_body` param so the 4-arg phase call site keeps working; emits the
+`pack-entry-body-gz64` marker via `_tmf_gz64_encode`); reverse —
+`scripts/lib/tracker-migrate-reverse.sh` `_tmr_decode_body_blob` (python3 decode; corrupt-blob
+FAIL-LOUD), `_tmr_check_blob_h2_divergence` (the normalization-tolerant comparator: CRLF→LF,
+per-line trailing-whitespace strip, single trailing newline — exactly GH's munging, no broader),
+and `_tmr_emit_pack_tree` (pack branch REWRITTEN to write `pe_backpointer_line` + `raw_body`
+verbatim; the dead `extra_fields` per-field render is DELETED); Mode-3 edits —
+`scripts/lib/tracker-edit.sh` `tracker_edit_entry` regenerates BOTH the H2 projection AND the
+blob on every `provider_update`.
+
+**As-built operational contract (size / pacing / neutralization / storage format —
+`ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3c/§3.3d):**
+
+- **Size budget (stored-byte axis).** The composed Issue body (H2 projection + blob + markers)
+  is measured in STORED BYTES against the ACTIVE provider's declared body limit — the GH backend
+  declares `body.limit: 65536` in its capability block (`scripts/lib/tracker-provider-gh.sh`).
+  `tmf_compose_issue_body` FAILs loud when the composed body exceeds
+  `provider_body_limit − TMF_SIZE_SAFETY_MARGIN` — it NEVER truncates (silent truncation would
+  re-open the lossy class this carrier kills). Worst entry today (BD-136) is ~62% of the GH
+  limit under gz64 (the gzip layer is what keeps the doubled H2+blob payload bounded).
+- **Write pacing.** The forward create loop sleeps ≥ the provider's declared
+  `rate_limits.min_write_interval_s` (GH: 1s) between successive `provider_create` calls and
+  honors retry-after backoff on a 403/429 (GH secondary caps: 80/min, `writes_per_hour_max:
+  500`) — realized in `scripts/lib/tracker-migrate-forward.sh` (the pacing gate;
+  `TMF_PACING_SLEEP_CMD` is the test seam so pacing assertions need no wall-clock wait).
+- **Autolink/mention neutralization (projection only).** `_tmf_neutralize_autolinks`
+  (`scripts/lib/tracker-migrate-forward.sh`) wraps any projected H2 value containing an
+  autolink trigger (`#NNN`, bare `@`, bare commit-SHA, bare URL) in an inline-code span, so the
+  real-repo create scatters no spurious backlinks / mention notifications. The blob is
+  UNTOUCHED — reverse recovers the verbatim original tokens; zero round-trip effect.
+- **`provider_body_storage_format`.** Each provider declares `body.storage_format`
+  (`raw_text` | `rich_text_normalizing`). The gz64 blob carrier REQUIRES `raw_text` (GH declares
+  it); the migrator FAILs loud on a `rich_text_normalizing` backend (which would rewrite/strip
+  the HTML comment) rather than silently corrupting — the carrier is the raw-text-body-class
+  realization; class-appropriate carriers for rich-text trackers are a future BD.
 
 **§2.4.2 — Zero-orphaned-fields verification (every entry field maps to a form field or the body).**
 
@@ -514,12 +572,30 @@ the Issue body — none may be orphaned by the sidecar drop.
 > `Description:`, `Resolved:` (BD-167, incl. the folded former-167b sub-entry section — same field
 > set, no suffix); `Type:`, `Status:`, `Paused:`, `Blockers:`,
 > `Unblocks:`, `File/Symbol:`, `Description:`, `Resolved:` (BD-185). `AT`: HEAD
-> `9fb29a5`, 2026-06-06. `INTERP`: mapping — `Type:`/`Status:`/`Blockers:`/`Unblocks:`/`File/Symbol:`/
-> `Description:`/`Context:`/`Resolution:` → form fields (`wi-*`, §2.4 table); `Resolved:` → form
-> `wi-resolution`/body; `Target:`/`Position:` → in-body `pack-extra-fields` block; `Alias:`/`Surfaced:`/
-> `Paused:`/`Goal:`/`Scope:`/`Quality bar:`/`Steps:`/`Problem:`/`Out of scope:`/`References:` → Issue
-> BODY (free-text sections, verbatim). EVERY field lands in a form field or the Issue body; NONE
-> requires a sidecar; ZERO orphaned. `CONCL`: SUPPORTED.
+> `9fb29a5`, 2026-06-06. `INTERP` (as-built, reconciled 2026-06-10): `Type:`/`Status:`/
+> `Blockers:`/`Unblocks:`/`File/Symbol:`/`Description:`/`Context:`/`Resolution:` ADDITIONALLY
+> project to form fields / labels / links (`wi-*`, §2.4 table) — but the ROUND-TRIP SOURCE for
+> every field above, common or extension (`Target:`/`Position:`/`Alias:`/`Surfaced:`/`Paused:`/
+> `Goal:`/`Scope:`/`Quality bar:`/`Steps:`/`Problem:`/`Out of scope:`/`References:`), is the
+> `pack-entry-body-gz64` blob carrying the entry body byte-verbatim. EVERY field lands in the
+> Issue body BY CONSTRUCTION (the carrier never enumerates fields); NONE requires a sidecar;
+> ZERO orphaned. `CONCL`: SUPPORTED.
+
+**Re-grounding (2026-06-10).** The census above measures the INPUT entries; the original INTERP
+asserted a prose mapping whose `pack-extra-fields` leg was never implemented (the lossless-fix
+audit, `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §2 claim A — the EE "measured the input, not the
+migrated output"). The zero-orphaned claim now rests on TWO as-built mechanisms, not a mapping
+table: (a) the **byte-faithful gz64 verbatim-body blob** (§2.4.1) — the carrier carries bytes,
+not fields, so no field (present or future) CAN be orphaned; and (b) the **unattended CI
+faithfulness guard** `check_migrator_field_faithfulness` (Check 49, `scripts/validate-pack.py`;
+deep-gated under `PACK_VALIDATE_DEEP=1` so the general battery path pays ~0; per-check test
+`scripts/tests/test-validate-pack-check-49-field-faithfulness.sh`, wired into
+`.github/workflows/validate-pack.yml` alongside a dedicated `PACK_VALIDATE_DEEP=1` workflow
+step), which asserts per entry on the REAL tree, via the single-sourced batch codec
+(`_tmf_gz64_encode_batch` / `_tmr_decode_body_blob_batch` — the SAME functions the production
+migration uses, so no second codec can drift and FALSE-PASS a lossy change): the byte-faithful
+contract `PRE_PARSE_ORIGINAL_body == decode(encode(raw_body))`, the composed-body size budget,
+title ≤ 256 (R-TITLE-1), and no disallowed control byte (R-BODY-6).
 
 **`template_version` + `template_archive_path` survive without a sidecar.** `template_version` is a
 DUAL carrier per D-18 — its in-body marker `<!-- template_version: work-item-v11.0 -->`
@@ -552,9 +628,9 @@ contract by decision (§2.4.3). No sidecar file participates in the round-trip.
 
 | Rule | Evidence | Conclusion |
 |---|---|---|
-| **Empirical-Evidence Blocks (zero-orphaned-fields claim)** | §2.4.2 block: the leading-label field census across BD-195 (large + parenthetical title) / BD-204 / BD-167 (incl. the folded former-167b section; post-BD-211 suffix-free) / BD-185 maps EVERY field to a form field or the Issue body — `Type/Status/Blockers/Unblocks/File-Symbol/Description/Context/Resolution`→form; `Target/Position`→in-body `pack-extra-fields`; `Alias/Surfaced/Paused/Goal/Scope/Quality bar/Steps/Problem/Out of scope/References`→Issue body. ZERO orphaned. Plus the `template_version` in-body marker + derivable `template_archive_path` block. All at HEAD `9fb29a5`, 2026-06-06, verbatim, SUPPORTED. | COMPLIANT |
-| **HARD invariant honored (form family + entry body; nothing on a sidecar)** | All content rides the form family + the Issue body (incl. the in-body `pack-extra-fields` block); the `.pack-tracker/reverse.sidecar.*` file is DROPPED; §2.4.3 explicitly drops GH-only non-entry artifacts (reactions/comments/attachments/audit log) with a future-BD deferral note. | COMPLIANT |
-| **Tracker-agnostic (the drop's own rationale)** | The dropped sidecar FORMAT was GH-specific and non-portable; the in-body `pack-extra-fields` block is a plain HTML comment in the issue body/description — a field every tracker has — so the carrier ports (Jira/Linear/etc.). No GH-specific non-entry format survives in the contract. | COMPLIANT |
+| **Empirical-Evidence Blocks (zero-orphaned-fields claim)** | §2.4.2 block (re-grounded 2026-06-10): the leading-label field census across BD-195 (large + parenthetical title) / BD-204 / BD-167 (incl. the folded former-167b section; post-BD-211 suffix-free) / BD-185 — `Type/Status/Blockers/Unblocks/File-Symbol/Description/Context/Resolution` additionally project to form fields; the ROUND-TRIP SOURCE for every field (incl. `Target/Position` and `Alias/Surfaced/Paused/Goal/Scope/Quality bar/Steps/Problem/Out of scope/References`) is the gz64 verbatim-body blob (as-built §2.4.1). ZERO orphaned BY CONSTRUCTION + the Check-49 faithfulness guard. Plus the `template_version` in-body marker + derivable `template_archive_path` block. Census at HEAD `9fb29a5`, 2026-06-06, verbatim, SUPPORTED. | COMPLIANT |
+| **HARD invariant honored (form family + entry body; nothing on a sidecar)** | All content rides the form family + the Issue body (incl. the in-body `pack-entry-body-gz64` verbatim-body blob, as-built §2.4.1); the `.pack-tracker/reverse.sidecar.*` file is DROPPED; §2.4.3 explicitly drops GH-only non-entry artifacts (reactions/comments/attachments/audit log) with a future-BD deferral note. | COMPLIANT |
+| **Tracker-agnostic (the drop's own rationale)** | The dropped sidecar FORMAT was GH-specific and non-portable; the in-body `pack-entry-body-gz64` blob is a plain HTML comment in the issue body/description — a field every tracker has — so the carrier ports across the RAW-TEXT-BODY class (`provider_body_storage_format == raw_text`; a `rich_text_normalizing` backend fails loud — §2.4.1 as-built contract). No GH-specific non-entry format survives in the contract. | COMPLIANT |
 | **Pattern-matching out of context** | Property-fit verified: the v10-monolith sidecar FILE's "flat grammar cannot hold it" rationale does NOT hold (the inline per-entry tree holds named scalars; flat mode has no comments/logs); the in-body HTML-comment carrier is reused because it MATCHES the sibling `pack-id`/`template_version` markers' property (`work-item.yml:103-105`). | COMPLIANT |
 | **Scope held** | DP-2 RESOLVED + every sidecar reference swept (§2.1/§2.4/§2.4.1/§2.10/§2.11/§2.12/§3.1/§3.2/§4.3/§5); DP-1/DP-3/DP-4/DP-5 untouched; code remove-vs-dormant flagged to planner/coder, not decided. | COMPLIANT |
 
@@ -730,8 +806,8 @@ account is personal (`DShaneNYC/optiquity-ai-agent-config-pack`).
 | GH custom Issue Types | partial | NO (org-only) | **EXCLUDED** | NOT used |
 
 **No design element needs a capability outside the verified set.** The structured carrier is the
-form-family body + labels + the in-body `pack-extra-fields` block (NOT custom Issue Fields, NOT a
-sidecar file). The status machine is labels + GH
+form-family body + labels + the in-body `pack-entry-body-gz64` verbatim-body blob (as-built
+§2.4.1; NOT custom Issue Fields, NOT a sidecar file). The status machine is labels + GH
 open/closed `state_reason` (all GA + personal). The identity carrier is a body HTML comment (no
 capability needed). If a future need for a typed field arises, it is a future-option-when-GA, not a
 BD-204 fork. **No researcher availability pass is triggered** — the design stays inside the
@@ -743,11 +819,19 @@ verified GA + personal set.
 
 The reversibility design + audit + test approach is §3 (full treatment). Summary of the guarantee:
 `per-entry tree → GH Issues → per-entry tree == original`, byte-faithful on entry spans, correct
-under repeated on/off/on/off with interleaved CRUD. The lossless contract rests on: (a) identity
-keyed on `pack-id` (§2.7, stable across delete/recreate); (b) the in-body `pack-extra-fields` block
-(in the Issue body, the SSOT) for any named field the form grammar cannot name — no sidecar file (§2.4.1); (c) the silent-data-loss guard that FAILs rather
-than drops (`tracker-migrate-reverse.sh:1032-1042`); (d) the complete status mapping incl. the
-`Deferred` row (§2.6, the round-trip-completeness fix).
+under repeated on/off/on/off with interleaved CRUD. The lossless contract rests on (as-built,
+reconciled 2026-06-10): (a) identity keyed on `pack-id` (§2.7, stable across delete/recreate);
+(b) the byte-faithful `pack-entry-body-gz64` VERBATIM-BODY BLOB (in the Issue body, the SSOT) —
+the ENTIRE entry body crosses the gap verbatim, with no field enumeration, so EVERY named field
+and prose block round-trips — no sidecar file (§2.4.1 as-built); (c) the silent-data-loss guard
+that FAILs rather than drops (`tracker-migrate-reverse.sh`, the `n_skipped` partial-write
+refusal) PLUS the corrupt-blob FAIL-LOUD decode (`_tmr_decode_body_blob` — never silent-empty)
+PLUS the blob↔H2 divergence backstop (`_tmr_check_blob_h2_divergence`, normalization-tolerant);
+(d) the complete status mapping incl. the `Deferred` row (§2.6, the round-trip-completeness
+fix); (e) the unattended CI faithfulness guard `check_migrator_field_faithfulness` (Check 49,
+`scripts/validate-pack.py`, deep-gated under `PACK_VALIDATE_DEEP=1`) asserting the byte-faithful
+round-trip + size + title + control-char legs per entry on the REAL tree, so a lossy regression
+is un-mergeable.
 
 ---
 
@@ -757,18 +841,24 @@ Mode transitions are heavyweight + infrequent + lossless by design (`backlog/BD-
 hot path:
 
 - **ON (forward, Mode 2 → 3):** `pack tracker init --forward` — reads the tree (C2a repoint),
-  creates an Issue per entry (`provider_create` via the form shape), writes the `pack-id` markers,
-  creates dependency links (BD-111), sets `tracker.toml` (`mode.state="tracker"`,
-  `forward_complete=true`), SKIPS the monolith mirror regen (C2b). One-shot, idempotent (existing
-  checkpoint markers, BD-065/131). The tree is then regenerated FROM the tracker (now SSOT).
+  creates an Issue per entry (`provider_create` via the form shape) in a PACED loop (as-built:
+  the create loop sleeps ≥ the provider's `rate_limits.min_write_interval_s` — GH: 1s — between
+  creates and honors retry-after backoff on a 403/429, staying under GH's 80/min + 500/hr
+  secondary caps; §2.4.1 as-built contract), with autolink/mention triggers in the visible H2
+  projection neutralized (`_tmf_neutralize_autolinks`; the blob is untouched), writes the
+  `pack-id` markers, creates dependency links (BD-111), sets `tracker.toml`
+  (`mode.state="tracker"`, `forward_complete=true`), SKIPS the monolith mirror regen (C2b).
+  One-shot, idempotent (existing checkpoint markers, BD-065/131). The tree is then regenerated
+  FROM the tracker (now SSOT).
 - **OFF (reverse, Mode 3 → 2):** `pack tracker disable` — reconstructs entries from Issues, emits
   the per-entry TREE directly (C3 repoint), regenerates `_toc.md` (DP-4), flips `tracker.toml` back
   to flat-file. The silent-data-loss guard + the atomic backup/restore loop
   (`tracker-migrate-reverse.sh:1085-1098`) make the flip atomic (no split state).
 - **Repeated on/off/on/off:** each ON re-creates Issues keyed on the SAME `pack-id` markers (not
-  issue numbers, §2.7); each OFF re-emits the SAME tree files (filename-is-ID). Named overflow
-  fields cross the gap IN the Issue body (the `pack-extra-fields` block + the `template_version`
-  marker) — no sidecar file. Idempotency + identity-stability
+  issue numbers, §2.7); each OFF re-emits the SAME tree files (filename-is-ID). The ENTIRE entry
+  body crosses the gap IN the Issue body (the `pack-entry-body-gz64` verbatim-body blob + the
+  `template_version` marker) — no sidecar file. The blob is deterministic (gzip `mtime=0`), so
+  the round-trip reaches a fixed point after one cycle; idempotency + identity-stability
   make repeated cycles converge to the original — proven by the §3 audit.
 
 ---
@@ -787,11 +877,21 @@ reconstructed `/backlog/BD-NNN.md`:
    supporting artifact per `_lib.sh:300`).
 3. **Status round-trips** — every `Status:` value decodes back to itself (the DP-3 matrix +
    the new `Deferred` branch close the one gap that breaks 11 entries).
-4. **Overflow recovered** — `Target:`/`Position:`/structured-sub-blocks recovered from the Issue
-   body (the visible sections + the in-body `pack-extra-fields` block; §2.4.1), byte-faithfully.
+4. **Entire body recovered (as-built, reconciled 2026-06-10)** — `Target:`/`Position:`/every
+   named field/structured sub-block recovered from the Issue body via the `pack-entry-body-gz64`
+   verbatim-body blob (§2.4.1 as-built), byte-faithfully — the blob carries the entry's lines
+   2..EOF verbatim, so recovery is BY CONSTRUCTION, not per-field mapping; the visible H2
+   sections are projection only. Decode is FAIL-LOUD on a corrupt blob (never silent-empty).
    NO sidecar file participates. GH-only non-entry artifacts (reactions/comments/attachments/audit
    log) are OUT of the contract by decision (§2.4.3).
 
+This contract is ENFORCED unattended: `check_migrator_field_faithfulness` (Check 49,
+`scripts/validate-pack.py`; deep-gated under `PACK_VALIDATE_DEEP=1`; per-check test wired into
+`.github/workflows/validate-pack.yml`) asserts, per entry against the REAL tree via the
+single-sourced batch codec, `PRE_PARSE_ORIGINAL_body == decode(encode(raw_body))` plus the
+composed-body size budget (stored bytes vs the provider's declared limit), title ≤ 256, and the
+control-char guard — so a regression of any contract item above fails CI before it can ship.
+
 "Lossless" applies to LIVE content only (`feedback_fail_loud_delete_old_source.md:35`); the
 back-pointer + `_toc.md` are derived, regenerated each cycle, not round-trip-compared.
 
@@ -845,25 +945,45 @@ tree set on the pack branch). This is the architect's lossless-audit coverage of
 ### 3.4 The test approach (live scratch repo, self-provisioned)
 
 Reversibility cannot be proven without a live GH repo (BD-111's "Live GH repo access" blocker;
-`test-infra-self-provisioned`). The dogfood test sequence (gated per `backlog/BD-204.md:20`,
-"scratch-repo proof → archive → real flip"):
-
-1. **Scratch-repo proof** — provision a personal-account scratch repo via `gh repo create`
-   (per-step user approval, `test-infra-self-provisioned`), install the form family, run
-   `tree → Issues → tree` against it, run the §3.2 oracle, then `gh repo delete` (cleanup). NEVER
-   touch the real pack repo as a test target. The scratch run uses a FIXTURE tree (a small
-   representative set incl. a parenthetical-title entry, a Deferred entry, and a large
-   multi-block entry — the three stress cases; post-BD-211 there is no suffix case) so the oracle is
-   fast + deterministic.
-2. **Archive** — after the scratch proof is green, the audit artifacts (the oracle diffs) are
-   recorded in the IMPL-REPORT (not committed as a kept mirror).
-3. **Real flip** — the actual pack-repo Mode-2→3 migration, gated on the scratch proof + explicit
-   user approval (heavyweight, infrequent, §2.12). This is the dogfood: the pack's OWN 211 entries
-   (post-BD-211; measured live at flip time, never hard-coded) move to the pack's real GH Issues.
-
-**Cleanup contract:** every scratch repo created is deleted in the same test run (trap-on-exit +
-explicit `gh repo delete`); a scratch repo is never left dangling. The test asserts the scratch
-repo is gone at the end.
+`test-infra-self-provisioned`). The dogfood test sequence (gated per the re-scoped
+`backlog/BD-204.md` `Scope:` line — Option A, SETTLED: a REPEATABLE scratch-repo proof, each
+scratch repo ARCHIVED at end + a manual-delete recommendation, then the REAL — never-archived —
+flip):
+
+1. **Scratch-repo proof (REPEATABLE)** — provision a personal-account, uniquely-named throwaway
+   scratch repo via `gh repo create` (per-step user approval, `test-infra-self-provisioned`),
+   preceded by the CREDENTIAL-CAPABILITY PREFLIGHT as the first live action (verify the token
+   can create repos, write issues, and ARCHIVE — and that repo-delete is NOT required and never
+   attempted; `gh` ≥ 2.0 floor; FAIL LOUD on any missing required permission before any bulk
+   write). Install the form family, run `tree → Issues → tree` against it, run the §3.2 oracle.
+   As many rehearsal runs as needed — there is no single-shot assumption. NEVER touch the real
+   pack repo as a test target. The scratch run uses a FIXTURE tree (a small representative set
+   incl. a parenthetical-title entry, a Deferred entry, and a large multi-block entry — plus,
+   as rebuilt, drop-set-field and no-Description entries and a 4-form autolink entry) so the
+   oracle is fast + deterministic.
+2. **Scratch disposal = ARCHIVE (Option A — the tool NEVER deletes)** — at end of each run the
+   scratch repo is ARCHIVED (`gh repo archive`, asserted read-only via `isArchived == true`);
+   the trap-on-exit ARCHIVES on failure too (never leave a WRITABLE orphan). Manual deletion is
+   a USER-ONLY recommended step the run prints (the credential deliberately lacks repo-delete; a
+   grep-guard asserts the test source contains no `gh repo delete`). The "archive" in the gate
+   wording is disposal of the THROWAWAY scratch repo — the REAL pack repo is NEVER archived (it
+   stays live and editable). The audit artifacts (the oracle diffs) are recorded in the
+   IMPL-REPORT (not committed as a kept mirror).
+3. **Real flip** — the actual pack-repo Mode-2→3 migration, gated on a green rehearsal + explicit
+   user approval (heavyweight, infrequent, §2.12), using the PACED, autolink-neutralized create
+   loop (§2.4.1 as-built contract) against the REAL (never-archived) repo. This is the dogfood:
+   the pack's OWN 211 entries (post-BD-211; measured live at flip time, never hard-coded) move
+   to the pack's real GH Issues.
+
+**Disposal contract (Option A, as-built — supersedes the pre-fix delete-cleanup):** every scratch
+repo created is ARCHIVED (read-only) in the same run — on success AND via trap-on-exit on failure;
+the tooling NEVER runs `gh repo delete` (deletion is a user-only manual step the run RECOMMENDS).
+The test asserts the scratch repo is ARCHIVED (`isArchived == true`) at the end — not gone.
+Realized in `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (the rebuilt C-7 oracle: the
+credential preflight, the archive-only disposal + trap, the manual-delete RECOMMEND line, and the
+no-`gh repo delete` grep-guard), alongside its drop-set / size / pacing / autolink-neutralization
+/ corrupt-blob / normalization-comparator legs — the unit-level legs also run unattended in the
+battery while the live round-trip stays manual.
 
 **C-7 CI-execution model — MANUAL-ONLY, gated, with a default-SKIP guard (the test never runs
 `gh repo create` unattended).** The C-7 lossless oracle is the ONE test in the pack that requires a
@@ -973,8 +1093,10 @@ no pack path reads a sidecar. Consequently the built `scripts/lib/tracker-sideca
 the pack surface for v11.0. Whether to DELETE `tracker-sidecar.sh` outright or leave it DORMANT (it
 may still serve the client surface / a future tracker-agnostic mechanism) is a remove-vs-dormant
 call left to the planner/coder — the architect flags it, does not decide it. The in-body
-`pack-extra-fields` block is emitted/parsed on the existing entry-body path (forward writes it into
-the Issue body; reverse renders it inline into `/backlog/BD-NNN.md`), needing no sidecar lib.
+`pack-entry-body-gz64` blob (as-built §2.4.1) is emitted/decoded on the entry-body path (forward
+`tmf_compose_issue_body` writes it into the Issue body; reverse `_tmr_decode_body_blob` +
+`_tmr_emit_pack_tree` write the body back verbatim into `/backlog/BD-NNN.md`), needing no sidecar
+lib.
 
 ---
 
@@ -1040,4 +1162,67 @@ sites re-anchored by SYMBOL (line numbers drift / were wrong at HEAD `e83aed7`).
 | **Empirical-Evidence Blocks** | SHOULD-2 carries an EE block (call-site census + dispatch-path proof + header-comment confirmation, HEAD `e83aed7`, 2026-06-06, SUPPORTED); NIT-3 EE re-measured the real fail-branches. | COMPLIANT |
 | **Scope held** | Only the 4 cited sites + their §5 summary echoes touched; DP-1..DP-5 resolutions byte-unchanged; no design substance altered. | COMPLIANT |
 
+---
+
+## 7. Lossless-fix as-built reconciliation (2026-06-10, BD-204 C-DOCS) — Rules-Applied mini-block
+
+Per `architect-doc-reality-reconciliation` + sweep finding S-2 (`SWEEP-BD-204-RULES-COMPLIANCE.md`)
+and `PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md` §4, this committed design doc is reconciled to the
+AS-BUILT lossless field-carrier fix. The governing spec for the as-built design is
+`ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (§3.3/§3.3a-e carrier + operational contract, §4 CI guard,
+§5.c rebuilt oracle, §5.f credential preflight); this section is the reconciliation ledger.
+
+**What changed in this doc (edited in place, by section):**
+
+| Section | Reconciliation |
+|---|---|
+| §1 DP-2 | As-built note added: the in-body carrier is realized as the gz64 verbatim-body blob; the `pack-extra-fields` named-scalar block was a phantom (never produced, never read) and is deleted. DP-2's substance (form family + Issue body, NO sidecar) unchanged. |
+| §2.1 step 2 | Regen path reads the verbatim `raw_body` decoded from the `pack-entry-body-gz64` blob. |
+| §2.4 table + boundary principle | `Target:`/`Position:`/extension-field/sub-block carrier cells → the gz64 blob; the form/label projection stated as advisory; round-trip source = the blob. |
+| §2.4.1 | Carrier statement REPLACED with the as-built gz64 verbatim-body blob (captured span lines 2..EOF; deterministic gzip `mtime=0` + base64; python3-pinned codec; corrupt-blob FAIL-LOUD; blob authoritative over the H2 projection with a normalization-tolerant divergence backstop). ADDED the as-built operational contract: stored-byte size budget vs the provider-declared body limit with fail-loud-never-truncate above `limit − margin`; ≥1s write pacing + retry-after; inline-code-span autolink/mention neutralization of the projection only; `provider_body_storage_format` (`raw_text` required, `rich_text_normalizing` fails loud). Realized consumers named by file + symbol. |
+| §2.4.2 | Zero-orphaned claim RE-GROUNDED on the byte-faithful blob (no field enumeration → no orphan possible) + the unattended faithfulness guard `check_migrator_field_faithfulness` (Check 49), replacing the input-census prose mapping the lossless-fix audit found unimplemented (claim A). |
+| §2.4.1 mini-block | Evidence cells updated to the blob carrier + the raw-text-class portability boundary. |
+| §2.10 | Structured-carrier phrase → the gz64 blob. |
+| §2.11 | Lossless-contract pillars rebuilt: blob carrier, partial-write + corrupt-blob + divergence guards (by symbol, not line), status matrix, and the Check-49 CI guard. |
+| §2.12 | ON-transition gains the paced + neutralized create loop; the repeated-cycle bullet crosses the gap via the deterministic blob (fixed point after one cycle). |
+| §3.1 | Contract item 4 → "entire body recovered" via the blob, by construction; added the unattended enforcement paragraph (Check 49: byte/size/title/control-char legs). |
+| §3.4 | Test-approach sequence + disposal contract → Option-A scratch disposal: credential-capability preflight first; REPEATABLE uniquely-named scratch repos; ARCHIVE-only end-state (`isArchived == true` asserted; trap-archives on failure); the tool NEVER deletes (`gh repo delete` grep-guarded out); manual delete is a USER-ONLY recommended step; the REAL pack repo is NEVER archived; real flip uses the paced, neutralized loop. Rebuilt-oracle legs named. |
+| §4.3 | Sidecar-drop code note → the blob emit/decode path by symbol. |
+
+**Realized consumers (file + symbol — the reconciliation chain):**
+`scripts/lib/tracker-migrate-forward.sh` — `_tmf_parse_backlog_file` (`raw_body` capture),
+`tmf_compose_issue_body` (defaulted 6th `raw_body` param; blob emit; size budget; storage-format
+refusal), `_tmf_gz64_encode` / `_tmf_gz64_encode_batch`, `_tmf_neutralize_autolinks` /
+`_tmf_neutralize_autolinks_batch`, the create-loop pacing gate (`TMF_PACING_SLEEP_CMD` seam).
+`scripts/lib/tracker-migrate-reverse.sh` — `_tmr_decode_body_blob` / `_tmr_decode_body_blob_batch`
+(corrupt-blob fail-loud), `_tmr_check_blob_h2_divergence` (normalization-tolerant comparator),
+`_tmr_emit_pack_tree` (verbatim `raw_body` emit; dead `extra_fields` render deleted).
+`scripts/lib/tracker-edit.sh` — `tracker_edit_entry` (blob + H2 regenerated together on every
+`provider_update`). `scripts/lib/tracker-provider-gh.sh` — the capability block (`body.limit:
+65536`, `body.storage_format: "raw_text"`, `rate_limits.min_write_interval_s: 1`,
+`rate_limits.writes_per_hour_max: 500`). `scripts/validate-pack.py` —
+`check_migrator_field_faithfulness` (Check 49, `PACK_VALIDATE_DEEP`-gated) + the `run_check`
+timing harness. `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` +
+`.github/workflows/validate-pack.yml` (the per-check wiring + the dedicated
+`PACK_VALIDATE_DEEP=1` step). `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (the
+rebuilt C-7 oracle).
+
+**Dated records intentionally left byte-stable:** the §1 DP-2 RESOLVED wording (user-decision
+record; the as-built note adjoins it), the §2.4.2 EE `CMD`/`OUT` (a real input census), the
+`template_version` EE `CMD` string, §5 (the 2026-06-05 Rules-Applied audit) and §6 (the
+2026-06-06 consistency pass) — where those dated records name the `pack-extra-fields` carrier
+they describe the superseded pre-fix design; the as-built carrier is §2.4.1's gz64 blob.
+`PLAN-BD-204.md` was already reconciled via its §3.LF amendment;
+`ARCHITECTURE-BD-204-POST-BD211-RECON.md` is attested accurate history (S-2.3) — neither is
+edited by this pass.
+
+| Rule | Evidence | Conclusion |
+|---|---|---|
+| **Architect-doc-vs-reality reconciliation** | Every reconciled claim names its realized consumer by file + symbol (never line numbers); the governing spec (`ARCHITECTURE-BD-204-LOSSLESS-FIX.md`) and the ledger (`SWEEP-BD-204-RULES-COMPLIANCE.md` S-2) are cross-referenced; the IMPL-REPORT (`IMPL-REPORT-BD-204-C-DOCS.md`) links both. | COMPLIANT |
+| **Edit-in-place, not full rewrite** | Targeted section edits only; DP-1/DP-3/DP-4/DP-5, §2.2/§2.3/§2.5–§2.9, §3.2/§3.3, §4.1/§4.2, §5, §6 byte-stable (dated records preserved with an explicit disposition above). | COMPLIANT |
+| **Fail-loud / delete the old source** | The phantom `pack-extra-fields` carrier is REMOVED from every live design statement (not left as a silent contradiction); dated records that mention it are explicitly marked superseded. | COMPLIANT |
+| **Scope held** | Only this file edited (C-DOCS is docs-only, pack-only); no entry, script, plan, or RECON edit. | COMPLIANT |
+
+---
+
 **End of ARCHITECTURE-BD-204.md**
`````

No new files. No deletions. `git status --short` at end of run:
`M maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` (+ this report once written).

## 5. Verification output

### 5.1 `python3 scripts/validate-pack.py` — general run

The system `python3` lacks PyYAML, which fails ONE check environmentally
(`FAIL: PyYAML not available — cannot validate issue templates`) — pre-existing, unrelated to
this docs-only change (CI installs PyYAML via `actions/setup-python`). Re-ran with a /tmp venv
providing PyYAML (`/tmp/vp-venv-bd204`, scratch-only, outside the repo):

```
$ /tmp/vp-venv-bd204/bin/python scripts/validate-pack.py | tail -2
============================================================
PASSED — all checks clean
```

### 5.2 Deep run (`PACK_VALIDATE_DEEP=1` — the workflow's dedicated step)

```
$ PACK_VALIDATE_DEEP=1 /tmp/vp-venv-bd204/bin/python scripts/validate-pack.py
── Check 49: migrator field/body faithfulness (BD-204, DEEP) ──
  OK: Check 49 — 211 entries byte-faithful (codec-lossless + parse-faithful), control-char-clean, title ≤ 256 codepoints, size leg vs provider body limit 65536 − margin 2048
── Check 50: OQ-4 single-source codec guard (BD-204 §4.5) ──
  OK: Check 50 — no reproduced gz64/base64 codec in validate-pack.py; Check 49 sub-invokes the shared batch codec (OQ-4 single-source)
============================================================
PASSED — all checks clean
```

Both runs repeated AFTER the final doc edit — both `PASSED — all checks clean`.

### 5.3 Full unattended battery (the `.github/workflows/validate-pack.yml` `run:` set)

The battery list was extracted from the workflow at HEAD `c7f9af6` (46 `run: bash
scripts/tests/...` lines — confirmed against the file, NOT the plan's older 41-line list; the
plan's §5 list predates the C-4.5/C-4.6 wiring of `tracker-migrate-forward-test.sh`,
`tracker-provider-test.sh`, `tracker-config-test.sh`, `tracker-init-test.sh`,
`tracker-agent-read-test.sh`, and `test-validate-pack-check-49-field-faithfulness.sh`). All 46
run with the venv `python3` on PATH. The live oracle
(`tracker-bd204-lossless-roundtrip-test.sh`) is NOT in the workflow and was NOT run live, per
the prompt (manual-only, default-SKIP).

Result: **46/46 PASS.** First pass was 45 PASS + 1 environmental FAIL —
`test-v11-realistic-ot.sh` exited rc=3 in 0s with:

```
ERROR: test-v11-realistic-ot.sh requires test-fixtures/v11-realistic-ot/ but it does not exist
       or is not a built fixture.
```

The fixture had never been built in this clone (fixture dirs are gitignored). Built it
(`bash test-fixtures/build.sh --name v11-realistic-ot`) and re-ran:

```
$ bash scripts/tests/test-v11-realistic-ot.sh | tail -4
PASS: 33
FAIL: 0
All v11-realistic-ot integration tests PASSED (33/33).
```

Representative per-script results (all 46 lines in `/tmp/bd204-cdocs-battery.log`, scratch):

```
PASS rc=0 tracker-provider-test.sh        :: Failed: 0 All tests passed.
PASS rc=0 tracker-migrate-forward-test.sh :: Failed: 0 All tests passed.
PASS rc=0 tracker-migrate-reverse-test.sh :: Failed: 0 All tests passed.
PASS rc=0 tracker-migrate-roundtrip-test.sh :: Failed: 0 All tests passed.
PASS rc=0 test-validate-pack-check-49-field-faithfulness.sh :: Failed: 0 All tests passed.
PASS rc=0 test-per-entry.sh / checks 16/18/19/32-34/36-46 / removed-doc-advisory :: all green
PASS rc=0 tracker-bd129/130/132/133/134 tests :: all green
PASS rc=0 recommendation-test.sh, pack-help-test.sh, test-customization-preserve.sh
PASS rc=0 test-init-project.sh, test-migrate-v10-to-v11{,-dry-run,-gates,-decompose}.sh
PASS rc=0 test-v11-realistic-ot.sh (33/33, after fixture build)
PASS rc=0 template-translations-test.sh, template-version-test.sh, test-issue-forms.sh
```

### 5.4 Manifest stability (docs-only commit ⇒ no manifest regen)

`maintenance-docs/` is not v11-surface (the trigger set is `project-template/`, `scripts/`,
`pack-ops/`, `supporting-docs/`), so no manifest regen is staged with this commit. Empirically
confirmed: the single-fixture rebuild produced `v11-realistic-ot
ae3fc6ff4956e365cba79699c724dce94559509c` — BYTE-IDENTICAL to the committed manifest row, i.e.
zero fixture drift from this change. The rebuild's side effect of marking the five locally-
unbuilt fixtures "(not built)" in `manifest.txt` was reverted by restoring the committed
content via read-only `git show HEAD:test-fixtures/manifest.txt` + a file write (no
state-changing git verb). Final state:

```
$ git status --short
 M maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md
$ git diff --stat
 .../v11-implementation/ARCHITECTURE-BD-204.md | 333 ++++++++++++++++-----
 1 file changed, 259 insertions(+), 74 deletions(-)
```

## 6. Plan deviations

Zero substantive deviations. Three transparency notes:

1. **Coherence extensions beyond the literal §4 section list.** Plan §4 names
   §2.4.1/§2.4.2/§2.11/§3.1 (carrier) and §3.4/§2.12 (archive/pacing). Five additional
   SMALL phantom-carrier sites were reconciled for internal coherence — §1 DP-2 (an adjoining
   as-built NOTE only; the dated user-decision wording is untouched), §2.1 step 2, the §2.4
   intro/table/boundary-principle (the parent unit of §2.4.1), §2.10 (one phrase), the §2.4.1
   mini-block cells, and §4.3 (one sentence) — because leaving them would have left the doc
   asserting the phantom carrier directly adjacent to the reconciled sections (the
   fail-loud/no-silent-contradiction rule). All are listed in the doc's new §7 ledger.
   Genuinely dated records (§1 DP-2 RESOLVED wording, §2.4.2 EE CMD/OUT, the `template_version`
   EE CMD string, §5, §6) were deliberately left byte-stable with an explicit disposition note.
2. **Battery list.** Ran the workflow's CURRENT 46-script `run:` set (per the prompt:
   "confirm the list against the workflow file at current HEAD"), not the plan §5's stale
   41-script enumeration.
3. **Environmental remediations during verification** (not repo changes): /tmp venv for PyYAML;
   one-time local build of the gitignored `v11-realistic-ot` fixture; committed `manifest.txt`
   content restored afterward (see §5.4).

## 7. POQs introduced

None blocking. One observation, disposition RESOLVED-no-action: the doc's dated §5
Rules-Applied row ("Pattern-matching out of context") still cites the `pack-extra-fields`
carrier — left as a 2026-06-05 audit record per the edit-in-place discipline; the new §7
ledger explicitly marks all such dated mentions superseded. No follow-up commit needed.

## 8. Boundary discipline check (P-missed-7)

No project-side file was touched. The single edited file lives under `maintenance-docs/`
(pack-internal design record), which the `boundary-investigation` skill explicitly lists as a
surface the skill does NOT apply to. No reference to any pack-only mechanism was added to any
client-shipped surface. `git diff --name-only` contains no `project-template/` or
`supporting-docs/` path — the `pack-only` commit keyword is honest under CI Check 36.

## 9. Definition-of-Done checklist

| Item (prompt success criteria) | Verdict | Evidence |
|---|---|---|
| Every §4-listed gap existing at HEAD reconciled; already-reconciled items attested with grep evidence | PASS | §2a (grep: zero as-built terms pre-edit; only the two `gh repo delete` lines); all gaps applied per §3 table; `PLAN-BD-204.md` / RECON attested untouched |
| §2.4.1/§2.4.2/§2.11/§3.1 carrier → gz64 blob; zero-orphaned re-grounded; size/pacing/neutralization/storage-format added | PASS | E4–E10, E13 (§3 table); diff §4 hunks |
| §3.4/§2.12 archive → Option-A scratch disposal (archive-only; tool never deletes; manual delete user-only) | PASS | E11, E12, E14; both `gh repo delete`-as-cleanup statements replaced |
| Realized consumers by file + §/symbol, never line numbers | PASS | E6 consumers block + §7 ledger; the one touched line-number cite converted to symbol (E10) |
| Doc describes the as-built carrier+guard+oracle accurately (cross-checked against the scripts) | PASS | §2 cross-check list; symbols verified by grep against `tracker-migrate-forward.sh` / `tracker-migrate-reverse.sh` / `tracker-provider-gh.sh` / `validate-pack.py` / the rebuilt oracle (e.g. `_tmf_gz64_encode_batch`, `_tmr_check_blob_h2_divergence`, `body.limit: 65536`, `TMF_SIZE_SAFETY_MARGIN`, the preflight + `gh repo archive` legs) |
| No edits outside `ARCHITECTURE-BD-204.md` + this report | PASS | §5.4 `git status --short` |
| `python3 scripts/validate-pack.py` passes | PASS | §5.1/§5.2 (general + deep both clean; PyYAML provided via scratch venv — environmental) |
| Full unattended battery green; live oracle NOT run | PASS | §5.3 — 46/46 PASS; `tracker-bd204-lossless-roundtrip-test.sh` not invoked live |
| No `test-fixtures/manifest.txt` regen staged (docs-only, not v11-surface) | PASS | §5.4 — manifest byte-identical to HEAD; fixture row SHA proved stable |

## 10. Proposed commit message

```
docs: v11 — BD-204 reconcile committed chain docs to gz64 carrier (pack-only)
```

Files to stage: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`,
`maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-DOCS.md`.

**End of IMPL-REPORT-BD-204-C-DOCS.md**
