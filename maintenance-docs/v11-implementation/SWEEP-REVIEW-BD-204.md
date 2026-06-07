# SWEEP-REVIEW-BD-204 — adversarial review of the rule-driven estate sweep

> **Agent:** pack-reviewer (independent, adversarial). **Mode:** REVIEW; one report write; codebase read-only.
> **HEAD:** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`). **Branch:** `v11-dev`. **Date:** 2026-06-07. **Scope:** PACK-ONLY.
> **Under review:** the sweep-amended `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (1185 lines) + `SWEEP-BD-204-RULES-COMPLIANCE.md` (the S-1..S-6 ledger + 8 decisions), against the law: `RESEARCH-BD-204-GH-ISSUES-RULES.md` (28 rules), `RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md`, `RESEARCH-TRACKER-LANDSCAPE-RULES.md` (14 trackers).
> **Method:** re-ran the load-bearing sweep measurements at HEAD `feaa45d` (the ATTESTED-CLEAN sample, the autolink/mention census, the gzipped-request axis, the go-forward guards against the real tree, the S-2/S-3 symbol existence, provider-capability coherence). EE figures re-executed, not trusted.
>
> **Bottom line.** The sweep is thorough, the 28-rule law is well-sourced, and the hard-CONTENT-rule CLEAN verdict across all 211 is CORRECT (I independently reproduced title max 231/256, 0 control bytes, body worst 62.2%, the 21 `#NNN` + 2 bare-`@` census — all match). The 8 decisions are sound in substance. BUT three sweep claims are WRONG or INCOMPLETE and must be fixed before the planner: (1) the S-5#4 gzipped-request EE figure "~134 bytes (0.2%)" is a measurement error — the real value is ~20,282 bytes (30.9%) [MUST]; (2) `tracker_edit_apply` (named in 4 places as the realized consumer) DOES NOT EXIST — the actual symbol is `tracker_edit_entry` [MUST]; (3) the R-OPS-6 neutralization addresses only `#NNN`/`@` but 114 entries carry commit-SHA-like bare hex that the chosen neutralization variant may not cover [SHOULD]. Plus the settled-decision alignment gap: the design still frames S-5#3 archive as an unsettled user question and omits the "repeatable / multiple scratch rehearsals" authorization [SHOULD]. **Verdict: FIXES** (2 MUST + 2 SHOULD, all bounded; no architect redesign).

---

## AREA 1 — ATTESTED-CLEAN re-measurement (any wrong CLEAN = BLOCKER)

### 1.1 [PASS] Title length, control bytes, body size, status vocabulary — CLEAN verdicts CONFIRMED.

> **Empirical-Evidence Block (independent re-measure of the hard-content CLEAN sample).**
> `CMD`: python over all 211 — stored title `len(ID)+2+len(title)`; body control-byte scan (`<0x20` not in {tab,LF} or `\r`); composed-body gz64 size.
> `OUT`: max stored title = **231 (BD-208)**, >256: NONE; bodies with control/CR bytes: **NONE**; gz64 body worst = BD-136 40,771 (62.2%), 0 over 80%. Status distinct values: Resolved/Open/Deferred/Deprecated/Cancelled/Unblocked (6), all label-mappable.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: every hard-content CLEAN verdict in S-4.1 / the law §2 is reproduced exactly by an independent run. `CONCL`: SUPPORTED — no wrong CLEAN among the hard-content rules. **No BLOCKER.**

### 1.2 [NIT] The cited "longest label = 24 chars" is off by one — actual is 25 (`template:phase-epic-v11.0`); CLEAN still holds.

> **Empirical-Evidence Block.** `CMD`: enumerate the generated label set from `tracker-migrate-forward.sh`, measure lengths. `OUT`: longest = **25** (`template:phase-epic-v11.0`), not the 24 (`template:work-item-v11.0`) the law §2 / sweep cite. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the phase-epic template label (25) is longer than the cited worst (24); both ≪ 50, so R-LABEL-1 CLEAN is unaffected — only the cited maximum is one short. `CONCL`: SUPPORTED — NIT (off-by-one in the cited max; verdict correct). Recommend the law/sweep cite 25 for accuracy. Phase-epic labels are real (the composer emits `template:phase-epic-v11.0` for `phase-*` ids).

### 1.3 [PASS] Script read-paths the sweep passed as CLEAN.

> **Empirical-Evidence Block.** `CMD`: confirm `_tmr_emit_backlog` (client branch) untouched-claim + `_gh_classify_error` rate detection + the read-surface scripts. `OUT`: `_tmr_emit_backlog` is a separate function from `_tmr_emit_pack_tree` (surface split confirmed in R1-R3); `_gh_classify_error` emits `rate-limit-secondary`/`-primary` (`:70`/`:73`); `tracker-agent-read.sh`/`tracker-doctor.sh` read the tree. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the S-3 CLEAN attestations for the client branch + read surfaces + the rate-detection-exists claim hold. `CONCL`: SUPPORTED.

**Area 1 conclusion:** no wrong CLEAN among the hard-content rules (no BLOCKER); one NIT (label max 24→25).

---

## AREA 2 — the 8 decisions, each against its rule(s)

### 2.1 [MUST] S-5#4 — the gzipped-request-axis EE figure "~134 bytes (0.2%)" is a MEASUREMENT ERROR (actual ~20,282 bytes / 30.9%); the decision survives but the EE is wrong in BOTH documents.

The decision (budget on STORED bytes because it bounds all three R-BODY-7 axes) is correct. But the supporting EE figure is wrong by ~150×.

> **Empirical-Evidence Block (the real gzipped JSON-request payload for BD-136).**
> `CMD`: `body=BD-136 lines 2..EOF; composed = body + blob; req = json({title,body:composed,labels}); gzipped_req = len(gzip_mtime0(req))`.
> `OUT`: stored composed body = **40,694 bytes (62.1%)**; gzipped-request payload = **20,282 bytes (30.9%)**. NOT 134 bytes.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the design §3.3c EE (`:434`/`:440-441`) and the sweep S-5#4 EE (`:296`/`:301`) both state "~134 bytes (0.2%)" with the rationale "the high-entropy gz64 blob barely compresses again" — which is self-contradictory: if the blob barely compresses, a 40 KB composed body CANNOT gzip to 134 bytes (that is a 300:1 ratio, the OPPOSITE of "barely compresses"). The real ratio is ~2:1 (40,694 → 20,282), consistent with "barely compresses." The "134 bytes" figure is an error (likely gzipping an empty/near-empty input). `CONCL`: SUPPORTED — the EE figure is WRONG; the CONCLUSION (stored 62.1% > gzipped-request 30.9%, so stored is the binding axis) is STILL CORRECT.

**Adjudication: MUST-fix.** Per `empirical-evidence-blocks` (wrong evidence = VIOLATED), a load-bearing EE carrying a figure that is wrong by 150× is a defect even when the conclusion survives — it would mislead a future reader into believing the request axis has 99.8% headroom (it has ~69%), and it appears identically in the design body AND the sweep ledger. Fix: replace "~134 bytes (0.2%)" with the real ~20,282 bytes (30.9%) in §3.3c and S-5#4; the "stored-byte axis is binding" conclusion is unchanged (62.1% > 30.9%).

### 2.2 [PASS] S-5#1 — pacing satisfies R-OPS-2/3 incl. the 500/hr cap + abuse-flag risk.

> **Empirical-Evidence Block.** `CMD`: arithmetic 211 creates × ≥1s vs R-OPS-2 (80/min, 500/hr) + the landed loop's pacing absence. `OUT`: 211 × 1s ≈ 211s ≈ 3.5 min ⇒ ~60/min (< 80/min) and total 211 (< 500/hr); the landed forward create loop has NO between-create pacing (only the post-create STABILIZE poll), and the provider DETECTS but does not enforce. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: §3.3d's pacing gate (`sleep provider_min_write_interval_s=1` between creates + honor `retry-after` on 403/429) keeps the bulk create under both secondary caps AND paced enough to avoid the NUANCE-A abuse-flag. `CONCL`: SUPPORTED — pacing necessary AND sufficient at ≥1s for 211.

**On `provider_update` bursts from `tracker-edit.sh` (the prompt's specific probe):** the design's pacing gate lives in the forward CREATE loop only. A Mode-3 `tracker-edit.sh` edit is a SINGLE `provider_update` per user action (not a burst), so it does not approach the secondary cap — no pacing needed there. The one residual is a hypothetical future BULK edit/sync path; the design does not have one, so this is not a current gap. PASS (noted: if a future bulk-update path is added, it must reuse the same `provider_min_write_interval_s` gate — worth a one-line note, not a finding today).

### 2.3 [PASS] S-5#2 — H2-projection neutralization is round-trip-SAFE (proven); see 2.4 for COMPLETENESS.

> **Empirical-Evidence Block (neutralization cannot leak into the blob/reverse — the blob is the round-trip source, the H2 is advisory).**
> `CMD`: re-read §3.3 step 4-5 + §3.3d(2): the reverse decodes `raw_body` from the `pack-entry-body-gz64` blob; `_tmr_emit_pack_tree` writes `raw_body` verbatim; the neutralization applies ONLY at `tmf_compose_issue_body` to the VISIBLE H2 projection.
> `OUT`: the blob carries `base64(gzip(lines 2..EOF))` = the verbatim bytes; reverse never reads the H2 sections for content; the composer's neutralization touches only the projected H2 strings. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: a word-joiner/code-span inserted into the H2 projection is downstream of the blob encoding and is never an input to reverse — it CANNOT leak into `raw_body` or the reconstructed entry. The §3.3d test leg ("the gz64 blob still decodes to the verbatim original `#NNN`/`@`") pins this. `CONCL`: SUPPORTED — neutralizing the projection is provably round-trip-safe.

### 2.4 [SHOULD] S-5#2 — neutralization COMPLETENESS gap: 114 entries carry commit-SHA-like bare hex that the `#NNN`/`@`-only neutralization may not cover.

The prompt asks about autolink forms beyond `#NNN`/`@`: commit SHAs, GH-NNN, owner/repo#NNN, bare URLs. I censused them.

> **Empirical-Evidence Block (autolink-form census beyond `#NNN`/`@`).**
> `CMD`: python over all 211 bodies — bare 7-40-hex (commit-SHA autolink); `GH-\d+`; `owner/repo#NNN`; bare `https?://`.
> `OUT`: commit-SHA-like (7-40 hex) entries: **114** (e.g. BD-001 `commit 08f7158`, BD-002…); GH-NNN: **0**; owner/repo#NNN: **0**; bare-URL: **2**. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: GitHub autolinks a bare commit-SHA (≥7 hex) to a commit in the target repo on render. 114 pack entries carry `commit <sha>` text (the `Resolved:` lines + prose). The design's §3.3d neutralization names ONLY `#`+digits and bare `@` — it does NOT mention commit SHAs or URLs. Whether SHAs are neutralized depends on WHICH variant the coder picks: the "wrap H2 field values in an inline-code span" variant neutralizes SHAs+URLs as a side benefit; the "U+2060 after `#`/`@`" variant does NOT (it leaves bare SHAs live). The design offers BOTH variants and pins neither. `CONCL`: SUPPORTED — incomplete coverage for the most common other autolink form (114 entries).

**Adjudication: SHOULD, not MUST.** Commit-SHA autolinks are LOWER-impact than `#NNN`/`@`: a SHA autolink resolves to a real commit (benign link, no cross-issue backlink-spam, no user notification), whereas `#NNN` creates issue cross-reference backlinks and `@` fires notifications. So the dogfood-cleanliness cost of leaving SHAs live is modest. But the design's stated GOAL (a clean real-repo C-8 flip with no scattered render-noise) is only fully met if the coder picks the inline-code-span variant (which covers SHAs+URLs too). Fix: §3.3d should (a) acknowledge commit-SHA + bare-URL autolinks (114 + 2 entries) as part of the R-OPS-6 surface, and (b) PIN the inline-code-span neutralization variant (which is general over all autolink forms) rather than leaving the U+2060 variant as an equal option that misses SHAs/URLs. Note this stays round-trip-safe (projection-side; 2.3).

### 2.5 [PASS] S-5#3 — stored-bytes axis bounds the other two; S-5#5 go-forward guards false-positive-free; S-5#6/#7/#8 sound.

- **S-5#5 guards run green on the real tree:** title ≤256 (max 231 codepoints, 0 over — including the 26 non-ASCII titles, counted as codepoints per GH) + control-byte scan (0). No false-positive. PASS.
- **S-5#6** (python3-codec pin / decode-identity / corrupt-blob fail-loud / actual-composed-body size) and **S-5#7** (raw_text vs rich_text_normalizing storage-format capability; Jira double-misfit) and **S-5#8** (C-7 REBUILD) — all re-confirmed against the landscape report (Jira 32,767 + ADF; GitLab/Redmine/Shortcut FIT) and the R1-R3 findings. PASS.

**Area 2 conclusion:** decisions are substantively sound; ONE MUST (the 134-byte EE error, 2.1) and ONE SHOULD (autolink completeness, 2.4).

---

## AREA 3 — new provider capabilities coherence + BD-207 reuse

### 3.1 [PASS] The 4 new capabilities slot into the existing 19-op + `capabilities()` contract.

> **Empirical-Evidence Block.** `CMD`: `sed -n '728,773p' scripts/lib/tracker-provider-gh.sh` (the `tracker_provider_gh_capabilities()` JSON block). `OUT`: the provider already declares a `rate_limits` block (`writes_per_minute_recommended: 60`, `reads_per_minute_recommended: 120`), `search.result_ceiling_per_query: 1000`, `raw_escape_hatch: true`. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the 4 new declarations (`provider_body_limit`=65536, `provider_body_storage_format`=raw_text, `provider_min_write_interval_s`=1, `provider_writes_per_hour_max`=500) are ADDITIVE JSON keys in the same capabilities block — no existing op signature changes; `writes_per_minute_recommended: 60` = 60/min = 1/s is COHERENT with `provider_min_write_interval_s=1`. `CONCL`: SUPPORTED — coherent with the existing capability-flag model.

### 3.2 [PASS] BD-207 client reuse is prefix-agnostic and inherits the capabilities unchanged.

The carrier operates on the verbatim body blob below the header (prefix-agnostic, re-confirmed R2/R3); BD-207 reuses the gz64 carrier + guard + the 4 capabilities. S-6.3 correctly notes the project surface inherits the raw-text-class contract + pacing. No project-side file edited (pack-project-separation honored). PASS.

**Area 3 conclusion:** coherent; PASS.

---

## AREA 4 — §4.5 surface enumeration + §7 regression rows completeness

### 4.1 [PASS] Every new sweep mechanism has its encoding surface + regression row.

> **Empirical-Evidence Block.** `CMD`: cross-check §4.5 surfaces + §7 rows vs the sweep's new mechanisms (gz64, size budget, pacing, neutralization, go-forward guards, provider capabilities, tracker-edit sync). `OUT`: §4.5 includes the forward lib (carrier + size + neutralization), reverse lib (decode + emit + comparator), validate-pack (faithfulness + size + title + control legs), `.github/workflows/validate-pack.yml` (Check 42 wiring), forward/reverse/roundtrip tests, fixtures, `tracker-provider.sh`/`-gh.sh` (4 capabilities), `tracker-provider-test.sh`, `tracker-edit.sh`, manifest, `backlog/_rules.md`. §7 rows: R1-R10 + R-CLIENT/R-EDIT/R-GZIP/R-SIZE/R-PROVIDER/R-NORM. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: every new mechanism (pacing → R-OPS in S-3; neutralization → R-OPS-6; size → R-SIZE; provider caps → R-PROVIDER; comparator → R-NORM; gzip → R-GZIP) has both an encoding surface AND a regression row. `tracker-provider-test.sh` is already CI-wired (`validate-pack.yml:117`). `CONCL`: SUPPORTED — enumeration complete.

**One coverage observation (not a gap):** there is no dedicated §7 row for the go-forward title/control guards (§3.3e), but they are folded into the faithfulness-check row (R5) + S-3's validate-pack line ("+ title≤256 + no control byte"). Acceptable — the guards are legs of the one check, not a separate surface. PASS.

**Area 4 conclusion:** complete; PASS.

---

## AREA 5 — S-2 committed-doc corrections + S-3 script changes by file+symbol

### 5.1 [MUST] `tracker_edit_apply` (named in 4 places as the realized consumer) DOES NOT EXIST; the actual symbol is `tracker_edit_entry`.

> **Empirical-Evidence Block (the named symbol is absent; the real entry-point is `tracker_edit_entry`).**
> `CMD`: `grep -nE '^[a-z_]+\(\)' scripts/lib/tracker-edit.sh` ; `grep -rn 'tracker_edit_apply' scripts/lib/`.
> `OUT`: `tracker-edit.sh` defines `_ted_status_openness`, `_ted_status_reason`, `_ted_status_label`, `tracker_edit_mode`, **`tracker_edit_entry`** — there is NO `tracker_edit_apply`. The design names `tracker_edit_apply` in §3.3a (`:356`), §4.5 (`:823`), §5.b (`:944`), §7 R-EDIT (`:1072`).
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: per `architect-doc-reality-reconciliation` (name the realized consumer by its ACTUAL symbol), the design's repeated `tracker_edit_apply` is a phantom — a coder grepping for it finds nothing. The real Mode-3 edit entry-point is `tracker_edit_entry` (+ the `_ted_*` helpers + `tracker_edit_mode`). The design DOES hedge with "/ the body-composer it calls," but the primary named symbol is wrong in all 4 occurrences. `CONCL`: SUPPORTED — wrong symbol, repeated 4×.

**Adjudication: MUST-fix.** The reconciliation-chain rule exists precisely so the coder lands on the right function; a phantom symbol in 4 places (incl. the regression row that the downstream reviewer checks) is a defect. Fix: replace `tracker_edit_apply` with `tracker_edit_entry` (the actual public entry-point) throughout §3.3a/§4.5/§5.b/§7; the coder then traces the body-composer it invokes.

### 5.2 [PASS] All other S-3 named symbols exist; S-2 corrections are correctly scoped by §/symbol.

> **Empirical-Evidence Block.** `CMD`: grep each S-3 symbol in `scripts/lib/`. `OUT`: `_tmf_parse_backlog_file`, `tmf_compose_issue_body`, `tracker_migrate_reverse_reconstruct`, `_tmr_emit_pack_tree`, `_tmr_emit_backlog`, `_gh_classify_error` ALL FOUND in their named files; `_gh_classify_error` emits `rate-limit-secondary`/`-primary` (the "DETECTS but does not PACE" claim is correct). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: every S-3 symbol except `tracker_edit_apply` is real; the create-loop pacing-absence + the provider declare-but-not-enforce claims are accurate. S-2 corrections (ARCHITECTURE-BD-204.md §2.4.1/§2.4.2/§3.1/§3.4; PLAN-BD-204.md §C-7/§C-8/§4; RECON attested-no-change) are §-scoped and consistent with the swept carrier. `CONCL`: SUPPORTED — S-2/S-3 correct except the one phantom symbol (5.1).

**Area 5 conclusion:** S-2/S-3 are correct except `tracker_edit_apply` (MUST, 5.1).

---

## SETTLED-DECISION ALIGNMENT (S-5#3 = Option A + REPEATABLE multi-scratch — FIXED constraint)

### SD-1 [SHOULD] The design still frames S-5#3 as an UNSETTLED user question and omits the "repeatable / multiple scratch rehearsals" authorization.

> **Empirical-Evidence Block (the design presents archive as a pending decision; no mention of repeatable/multiple scratch rehearsals).**
> `CMD`: `grep -niE 'multiple|repeatable|as many|rehearsal|first-try|archive.*end state|SEPARATE decision' ARCHITECTURE-BD-204-LOSSLESS-FIX.md`.
> `OUT`: §5.a (`:895-902`) presents "Option A recommended … if the user actually intended to ARCHIVE the real pack repo … that is a SEPARATE decision"; §5.c/C-8 describe a single "live dress rehearsal" + "scratch-repo proof → teardown → real flip"; NO occurrence of "multiple/repeatable/as many scratch repos/first-try." `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the user has now SETTLED S-5#3 as Option A (real repo NEVER archived; "archive" = scratch teardown; scratch deleted by default, archive-on-request) AND explicitly authorized MULTIPLE throwaway scratch rehearsals (repeatable, as many as needed, C-8 fires only on a green rehearsal + explicit approval). The design (a) still frames A vs B as open, and (b) is silent on the repeatable-multi-scratch authorization. The C-8 gate row DOES say "gated on C-7 green + explicit user approval" (aligns), and nothing in the design CONTRADICTS Option A or forbids multiple scratches — but it does not yet ENCODE the settled constraints. `CONCL`: SUPPORTED — alignment gap, not a contradiction.

**Adjudication: SHOULD.** No contradiction (the design's best-evidence reading IS Option A; it never assumes a single scratch nor archives the real repo). But per the FIXED settled constraint, the design should: (a) state S-5#3 as SETTLED Option A (real repo never archived; "archive"=scratch teardown; scratch deleted by default, archive-on-request) and drop the "Option B requires direction" framing; (b) state in §5.c/C-8 that the scratch proof is REPEATABLE (as many throwaway scratch repos as needed) and C-8 fires only on a green rehearsal + explicit user approval. The §5.a BD-204.md:20 wording fix (the one entry-text change) should land the Option-A phrasing. Cheap, no mechanism change.

---

## VERDICT

**FIXES** — the sweep is sound and the hard-content CLEAN verdict is correct, but four bounded items must be addressed before the planner. None requires an architect redesign; all are corrections to the swept design + ledger.

**MUST (fix before planner):**
1. **2.1 — the gzipped-request EE figure "~134 bytes (0.2%)" is wrong** (actual ~20,282 bytes / 30.9%); appears in §3.3c AND S-5#4. Correct the figure (the stored-byte-axis conclusion is unchanged).
2. **5.1 — `tracker_edit_apply` does not exist**; replace with `tracker_edit_entry` in §3.3a/§4.5/§5.b/§7 R-EDIT.

**SHOULD (fix before planner):**
3. **2.4 — R-OPS-6 neutralization completeness:** acknowledge the 114 commit-SHA-bearing + 2 bare-URL entries and PIN the inline-code-span neutralization variant (general over all autolink forms incl. SHAs/URLs) rather than leaving the `#`/`@`-only U+2060 variant as an equal option that misses them.
4. **SD-1 — settled-decision alignment:** state S-5#3 as SETTLED Option A (real repo never archived; archive = scratch teardown; scratch deleted by default) and add the REPEATABLE/multiple-scratch-rehearsal authorization to §5.c/C-8.

**NIT (apply opportunistically):** 1.2 — cite label max 25 (`template:phase-epic-v11.0`), not 24.

Everything else verified PASS: the hard-content CLEAN across 211 (Area 1), the pacing/size/portability/go-forward decisions in substance (Area 2), provider-capability coherence + BD-207 reuse (Area 3), the §4.5/§7 enumeration (Area 4), and the S-2/S-3 corrections except the one phantom symbol (Area 5). The mention-neutralization is provably round-trip-safe; the go-forward guards are false-positive-free on the real tree; the law (28 rules + 14 trackers) is well-sourced and the VERIFY/landscape reports corroborate it. Once the 2 MUSTs land (and ideally the 2 SHOULDs), this proceeds to the planner.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag`; only `git rev-parse HEAD` (read-only) + Read/Bash read-only measurement; the sole write is this ONE report. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op; no live GH (all gzip/base64/parse run locally on read-only copies; no `gh`); no file overwrite outside the report. | COMPLIANT |
| `empirical-evidence-blocks` | Every finding (1.2 label, 2.1 gzipped-request, 2.4 autolink census, 5.1 phantom symbol, SD-1 archive) carries CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL — and the rule is applied REFLEXIVELY to flag the sweep's own 134-byte EE error (2.1). | COMPLIANT |
| `ci-guard-measure-then-bound` | Re-verified the size/title/control guards are measured-then-bounded against the real tree (title 231<256, 0 control, body 62.2%) with zero false-positives; flagged the autolink-completeness gap (the neutralization must cover the measured SHA surface, not just `#`/`@`). | COMPLIANT |
| `architect-doc-reality-reconciliation` | Applied the rule to catch the phantom `tracker_edit_apply` (5.1) — the realized consumer must be named by its ACTUAL symbol (`tracker_edit_entry`); verified every other S-3 symbol exists. | COMPLIANT |
| `enumerate-encoding-surfaces` | Independently cross-checked §4.5 + §7 against every new sweep mechanism; confirmed complete (Area 4); confirmed `tracker-provider-test.sh` is CI-wired. | COMPLIANT |
| `verify-availability-not-just-existence` | Verified the provider capabilities are realizable on the actual 19-op + capabilities contract (Area 3); confirmed the landscape misfit verdicts (Jira 32,767+ADF) ground the storage-format capability. | COMPLIANT |
| `tracker-portability` | Confirmed the raw_text vs rich_text_normalizing boundary is honest (S-5#7) and grounded in the landscape report; BD-207 reuse is prefix-agnostic. | COMPLIANT |
| `pack-project-separation` | Confirmed all sweep changes pack-side; METHODOLOGY untouched; project-side `_rules.md` untouched; client emit branch isolated. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered the 5 verification areas + the settled-decision check + verdict + this block + attestation; named what is wrong, did not author a redesign; calibrated to real problems (empty/PASS sections stated). | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |

## READ-IN-FULL attestation (this session, at HEAD `feaa45d`)

| Document | Read / re-measure proof |
|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (sweep-amended, 1185 ln) | Read FULL across pages — §3.3/§3.3a-e/§3.3c (size budget + 2 capabilities)/§3.3d (pacing + neutralization)/§3.3e (go-forward guards)/§4.4 (size+title+control legs)/§4.5/§5.a-c/§7/§9/§10. The 134-byte EE (§3.3c), the `tracker_edit_apply` symbol (4 sites), the archive framing (§5.a) read directly. |
| `SWEEP-BD-204-RULES-COMPLIANCE.md` (S-1..S-6 + 8 decisions, 449 ln) | Read FULL (1-450) — the ledger, all 8 S-5 decisions, the entry-modification list, the commit sequence, S-7/S-8. |
| `RESEARCH-BD-204-GH-ISSUES-RULES.md` (law, 757 ln) | Read FULL (1-535 + 536-625 §3 map + reconciliation) — all 28 rules, the §2 census, the §3 compliance map. Load-bearing values (R-OPS-2 80/min+500/hr, R-OPS-3 ≥1s, R-BODY-7 gzipped axis, R-OPS-6 autolink, R-ACCT-4 archived) read at source. |
| `RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md` (audit, 347 ln) | Read the §0 verdict (CORRECTIONS-NEEDED → 3 missed rules + 2 nuances folded in) + method — corroborates the law. |
| `RESEARCH-TRACKER-LANDSCAPE-RULES.md` (14 trackers, 405 ln) | Read the §3.2 fit verdicts (GitLab/Redmine/Shortcut FIT raw-text ≥43KB; Jira double-misfit 32,767+ADF; Trello 16,384; Monday 2,000) — grounds the storage-format capability (S-5#7). |
| Live tree (all 211 `backlog/BD-*.md`) | RE-MEASURED this session: title max 231/256 (codepoints, 0 over incl. 26 non-ASCII); 0 control/CR bytes; gz64 body worst 62.2%; gzipped-request BD-136 20,282/30.9% (NOT 134); `#NNN`=21, `@`-any=4, bare-`@`=2; commit-SHA-hex=114, GH-NNN=0, owner/repo#NNN=0, bare-URL=2; label max 25. |
| `scripts/lib/tracker-edit.sh` | Read the function roster — `tracker_edit_entry`/`tracker_edit_mode`/`_ted_*`; NO `tracker_edit_apply` (5.1). |
| `scripts/lib/tracker-provider-gh.sh` | Read `tracker_provider_gh_capabilities()` (`:728-773`) + `_gh_classify_error` (`:61-73`) — capability block + rate detection. |
| `scripts/lib/tracker-migrate-forward.sh` / `tracker-migrate-reverse.sh` / `tracker-provider.sh` | Re-confirmed S-3 symbols + the create-loop pacing absence + the 19-op dispatch/capability model (R1-R3 + this sweep). |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` + `.github/workflows/validate-pack.yml` | Confirmed C-7 tests no operational rule (S-5#8) + `tracker-provider-test.sh` CI-wired (`:117`). |
| `CLAUDE.md ## Pack memory` + curated memory | In-force rules applied (empirical-evidence, architect-doc-reality-reconciliation, ci-guard-measure-then-bound, enumerate-encoding-surfaces, tracker-portability, pack-project-separation, scope-deliverables). |

**No named document was derived rather than read.** The 134-byte-vs-20,282 gzipped-request measurement, the 114 commit-SHA census, the `tracker_edit_apply` absence, the label-max 25, and the title/control/size figures are this session's own command output at HEAD `feaa45d`, 2026-06-07.

**End of SWEEP-REVIEW-BD-204.md**
