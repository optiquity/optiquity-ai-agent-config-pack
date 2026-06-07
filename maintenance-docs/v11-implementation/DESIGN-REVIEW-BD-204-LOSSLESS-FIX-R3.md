# DESIGN-REVIEW-BD-204-LOSSLESS-FIX-R3 — FINAL pass of the bounded cycle

> **Agent:** pack-reviewer (independent, adversarial). **Mode:** REVIEW-3 (FINAL — no fix-3 exists; a dirty verdict goes to the user). One report write; codebase read-only.
> **HEAD:** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`). **Branch:** `v11-dev`. **Date:** 2026-06-07. **Scope:** PACK-ONLY.
> **Under review:** the fix-2-revised `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (now 969 lines; carrier = gzip+base64 `pack-entry-body-gz64`, new §3.3c SIZE BUDGET, normalization-tolerant §3.3a(ii) comparator, `provider_body_limit`).
> **Method:** re-read the revised design in full; independently re-ran every fix-2 measurement and the gzip-switch surfaces at HEAD `feaa45d`. Design EE blocks re-executed, not trusted.
>
> **Bottom line.** The 3 review-2 findings (N-1 size, N-2 comparator, N-7 provider contract) are all RESOLVED, each verified by re-measurement — I independently reproduced the §3.3c distribution EXACTLY (BD-136 raw 99.7% → gz64 62.2%; all 211 under 63%; 0 over 80%). The size budget is genuine measure-then-bound with a fail-loud, never-truncate overflow contract and a CI size leg. The gzip switch introduces ONE real, bounded issue worth surfacing: **gzip OUTPUT BYTES are NOT portable across implementations** (I measured python3 gzip ≠ Apple CLI gzip at the header), and the design states a "same body → same blob" determinism claim it does not pin to one implementation. BUT that claim is **not load-bearing** — every comparison in the design is on DECODED bodies / H2 projections, never blob bytes — so the residual risk is a doc-correctness overclaim, not a functional defect. **Verdict: PROCEED** with two non-blocking notes for the planner/coder to fold in (G-A pin + G-B decode-fail-loud). No DIRTY items.

---

## PART 1 — the 3 fix-2 closures (re-measured, not trusted)

### N-1 — size budget: measure-then-bound, fail-loud, guard-enforced. **RESOLVED.**

> **Empirical-Evidence Block (independent reproduction of the §3.3c all-211 distribution).**
> `CMD`: per entry, `body = lines 2..EOF`; raw-blob projection = `len(body)+80 + 29 + len(base64(body))`; gz-blob projection = `len(body)+80 + 29 + len(base64(gzip_mtime0(body)))`; sort + bucket vs LIMIT=65536.
> `OUT`: RAW worst = **BD-136 65,335 (99.7%)**; raw entries over 80% = **1**. GZ64: BD-136 = **40,771 (62.2%)**; BD-191 = 29,866 (45.6%); BD-203 = 17,683 (27.0%); ALL 211 under 63%; gz entries over 80% = **0**. BD-136 body 27,954 → rawb64 37,272 → gzb64 12,708 (≈3:1).
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: my figures match the design's §3.3c EE to the byte (BD-136 65,335→40,771; 99.7%→62.2%; 0 over 80% under gz). The distribution is correct and complete (all 211, not a sample). `CONCL`: SUPPORTED — the size analysis is genuine measure-then-bound, independently confirmed.

- **Overflow contract is fail-loud with NO truncation path.** §3.3c: "the forward composer computes the projected body size and, if it exceeds `provider_body_limit − SAFETY_MARGIN`, FAILs loud … the migrator NEVER truncates … aborts atomically." There is no truncation branch anywhere in the design (grep for `truncat` returns only the prohibition). RESOLVED.
- **The §4 guard now asserts size.** §4.4 "What the guard asserts about SIZE": the unattended check computes the projected body per entry and FAILs any breaching `provider_body_limit − SAFETY_MARGIN`. So a grown/new entry that would breach is caught in CI before C-8, not at migration time. RESOLVED.

### N-2 — normalization-tolerant divergence comparator: precisely defined, matched to GH munging, no broader. **RESOLVED.**

§3.3a(ii) specifies EXACTLY two transforms applied identically to both sides before comparing: (1) line-ending canonicalization (`\r\n`/`\r` → `\n`); (2) per-line trailing-whitespace strip + single trailing-newline normalization (`rstrip('\n')+'\n'`). It explicitly states "NO BROADER than GH's actual normalization — it does NOT touch interior whitespace, case, Unicode form, or content bytes, so a REAL human edit still mismatches (no false-negative)."

> **Empirical-Evidence Block (the chosen normalization set matches the codebase's own whitespace-tolerant precedent).**
> `CMD`: `grep -nE 'rstrip|trailing|whitespace-tolerant|CRLF' scripts/lib/tracker-mirror.sh scripts/tests/tracker-migrate-roundtrip-test.sh` (the precedent the design cites).
> `OUT`: the design cites `tracker-mirror.sh:67/:101` (trailing-newline normalization) + `tracker-migrate-roundtrip-test.sh:9` ("Zero diff (whitespace-tolerant)") — both real codebase idioms.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the comparator's transform set is property-fit (it reuses the existing whitespace-tolerant discipline) and is bounded to GH's documented body munging (CRLF + trailing whitespace). It catches a real content edit (any interior/word/structural byte change survives normalization → mismatch) and tolerates an untouched-but-GH-renormalized issue. `CONCL`: SUPPORTED — precisely defined, matched, no broader; both false-positive and false-negative classes are closed. The blob leg correctly needs no tolerance (base64-in-comment survives GH normalization).

### N-7 — `provider_body_limit` provider-layer contract: real capability, active-provider read, surfaces in §4.5. **RESOLVED.**

§3.3c declares ONE additive capability `provider_body_limit` (bytes); the migrator reads it from the ACTIVE provider (no hard-coded 65,536 in the migrator); the carrier requirement is stated once ("requires `provider_body_limit ≥ worst_case + margin`; FAILs loud on any provider that cannot meet it").

> **Empirical-Evidence Block (the additive-capability model fits the real provider abstraction; the N-7 surfaces are in the lock-step table + already CI-wired).**
> `CMD`: `sed -n '12,30p' scripts/lib/tracker-provider.sh` ; `grep -n 'tracker-provider' .github/workflows/validate-pack.yml` ; grep the design §4.5 for `tracker-provider`.
> `OUT`: the provider is a 19-op dispatch with "capability flags" (`:19`), already including a `capabilities` op (`provider_capabilities`, `:141`) — `provider_body_limit` slots in as another declared capability with no signature change to existing ops. §4.5 lock-step table includes `scripts/lib/tracker-provider.sh` + `tracker-provider-gh.sh` (NEW `provider_body_limit`, line 671) AND `scripts/tests/tracker-provider-test.sh` (assert GH=65,536 + a smaller-limit mock fails loud, line 672). `tracker-provider-test.sh` is ALREADY wired in CI (`.github/workflows/validate-pack.yml:117`), so the N-7 test runs unattended.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the contract is a real provider-layer declaration (not a tacit GH constant), its encoding surfaces (provider lib + GH backend + provider test) are in the §4.5 lock-step set, and the test is already CI-wired. `CONCL`: SUPPORTED — N-7 closed at the abstraction layer with its surfaces enumerated.

**Part-1 conclusion:** all 3 review-2 findings RESOLVED, each independently re-measured. The review-2 NITs (P1-NIT-1 §5.a "parses it back"; P1-NIT-2 `--force` citation) are addressed (the `--force` citation is now hedged with `~:985`/`~:1014`/`~:1042` approximate-line form; §5.a per-field residue — see G-D NIT below).

---

## PART 2 — NEW surface from the gzip switch

### G-A [SHOULD] gzip output bytes are NOT portable across implementations; the design's "same body → same blob" determinism claim is true only within one implementation and is not pinned — BUT it is not load-bearing.

> **Empirical-Evidence Block (python3 gzip ≠ Apple CLI gzip at the header, even with mtime zeroed; both decode identically).**
> `CMD`: `python3 -c "import gzip,io; ... GzipFile(mtime=0).write(body)" > /tmp/py.gz` ; `tail -n +2 backlog/BD-001.md | gzip -n -c > /tmp/cli.gz` ; `cmp /tmp/py.gz /tmp/cli.gz` ; `xxd | head -1` each ; `gunzip -c each | cmp - <original>`.
> `OUT`: both 154 bytes but `differ: char 9`. python header bytes 8-9 = `02 ff` (XFL=2 best-compression, OS=255 unknown); Apple-gzip = `00 03` (XFL=0, OS=3 Unix). BOTH `gunzip -c` decode byte-identical to the original. This box: Apple gzip 479; python zlib 1.2.12.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: `mtime=0` zeroes the timestamp but the XFL/OS header bytes (and potentially level-dependent body bytes) still differ across gzip implementations. So the design's R-GZIP / §3.3c claim "the same body always yields the same blob" and "cycle-2 blob == cycle-1 blob" is TRUE only if the SAME implementation runs every forward path; it is FALSE across python3-vs-CLI gzip. `CONCL`: SUPPORTED — the determinism claim is implementation-scoped, and the design does not explicitly pin the implementation.

**Adjudication: SHOULD, not DIRTY.** I traced every place blob output could matter:
- **§3.3b idempotency** compares `reverse(forward(x))` vs `x` on the **decoded body** ("reverse writes `raw_body` verbatim and forward re-captures `raw_body` verbatim") — the reconstructed tree file holds the decoded body, not the blob. Blob-byte differences are invisible to it.
- **The §4 guard** asserts "RECONSTRUCTED body span == ORIGINAL body span" — **decoded** bodies, not blobs.
- **The §3.3a comparator** compares the **H2 projection**, not the blob.
- Nothing in the design does a blob-to-blob comparison.

So blob-byte determinism is **not load-bearing**; only blob DECODE-identity is, and that holds across any conformant gzip (decode is standard). The practical risk is nil TODAY. The residual is a doc-correctness overclaim: the design asserts blob-byte determinism as a SUPPORTED conclusion when it only holds within one implementation. **Recommended fold-in (planner/coder, non-blocking):** (a) state explicitly that the gzip impl is **python3 `gzip.GzipFile(mtime=0)` on ALL forward paths** (the migrator, `tracker-edit.sh`, and the guard all run python via the bash-lib heredocs, so this is already de-facto true — just make it explicit so no one swaps in CLI `gzip`); (b) re-scope the §3.3b/R-GZIP claim to "**decode-identity** is load-bearing; blob-byte stability holds within the pinned python3 impl and is not relied upon cross-impl." This converts a latent trap (a future coder writing a blob-stability optimization or a cross-runner blob-equality test) into a documented invariant.

### G-B [SHOULD] Tool availability is fine (python3 zlib, bundled, both OSes); the decode FAILURE mode (corrupt blob → fail-loud vs silent empty body) is not explicitly stated.

> **Empirical-Evidence Block (python3 zlib is bundled + present; the harness is python3, not CLI gzip).**
> `CMD`: `python3 -c "import zlib; print(zlib.ZLIB_VERSION, zlib.ZLIB_RUNTIME_VERSION)"` ; design EE blocks' gzip calls.
> `OUT`: `zlib 1.2.12 / runtime 1.2.12`; every design gzip EE uses `gzip.GzipFile(mtime=0)` (python3). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: python3's `gzip`/`zlib` is bundled with the interpreter (no external `gzip` binary dependency) and is present on macOS dev + Ubuntu CI (the harness already runs python3). The chosen path is portable and consistent — pinning to python3 (G-A) also resolves the BSD-vs-GNU `gzip` CLI portability worry entirely (no CLI gzip is needed). `CONCL`: SUPPORTED — availability/consistency is fine once G-A pins python3.

The unaddressed sliver: the design specifies reverse does "base64-decode then gunzip" but does not state the failure mode if the blob is corrupt/truncated (e.g. a hand-mangled Issue). Given the design's pervasive fail-loud posture and that python's `gzip.decompress` RAISES on a bad stream (it does not return an empty body), the natural implementation is fail-loud — but the design should state it: **a non-decodable `pack-entry-body-gz64` blob MUST fail the reverse loud (named entry + "corrupt blob"), never fall through to an empty/partial body.** Non-blocking coder note; consistent with the existing posture.

### G-C [NIT] SAFETY_MARGIN (2,048) is reasonable, not load-bearing today.

§3.3c calls it "a small fixed reserve (e.g. 2,048 bytes) for the marker wrapper + provider-side rendering overhead." With BD-136 at 40,771 / 65,536 (24.7 KB headroom), the margin is non-binding by a wide margin. It is a sane reserve, not arbitrary in a harmful way; the "e.g." signals it is tunable. No risk hidden. NIT only — the coder may refine it, but nothing depends on the exact value at current scale.

### G-D [NIT] Two minor consistency items — neither blocks.

1. **Projection-basis consistency.** §3.3c's DISTRIBUTION measurement uses "H2 upper-bounded by raw body bytes" as a proxy, while the composer/§4.4 guard enforce on "the projected body (H2 + blob + markers)." The coder must ensure the composer's size check and the guard's size leg both compute the **same actual composed-body length** (not the distribution's upper-bound proxy), so the guard and the runtime check agree exactly at the margin. Implementation-consistency note; the upper-bound proxy is conservative (only over-counts), so it cannot cause a silent over-limit pass — at worst a slightly-early false-fail, which the coder avoids by measuring the actual body. NIT.
2. **§5.a re-scope residual.** The proposed BD-204 re-scope text still says the migrator "serializes the entry's COMPLETE ordered field set verbatim … reverse parses it back" (per-field-model wording inconsistent with the committed blob model). Pack Chat applies this text pack-chat-only; trivially corrected at apply time. Flagged in review-2 (P1-NIT-1); still present. NIT, non-blocking.

No §4.5 surface or §7 row is missing for the gzip/provider changes: R-GZIP, R-SIZE, R-PROVIDER, R-NORM are all present in §7; `tracker-provider.sh`/`-gh.sh`/`-test.sh` and the workflow yml are all in §4.5; `tracker-provider-test.sh` is already CI-wired. G-D surfaces nothing omitted.

---

## PART 3 — FINAL VERDICT

**PROCEED — the design is approved for the planner.**

Across three review passes the design has converged to a sound, evidence-backed solution:
- The core mechanism (verbatim-body blob, gzip+base64, emit rewrite) is property-fit and I independently verified it byte-faithful and collision-proof on the full hazard taxonomy (no-Description, 73-shred prose, `-->`, markdown fence, multi-paragraph, no-Blockers).
- All review-1 findings (7) and all review-2 findings (3) are RESOLVED, each re-measured this pass — the §3.3c size distribution reproduced to the byte, the N-2 comparator bounded exactly to GH's munging, the N-7 provider contract real and CI-wired.
- The constraint set holds: zero carve-outs, CI false-green closed by a strong byte-leg + a new size leg, zero entry rewrites, v11.0 launch gate, pack-only boundary honored (METHODOLOGY untouched; client emit branch isolated; project-side `_rules.md` correctly diverged).
- The size risk that was the review-2 BLOCKER is now bounded with margin (worst case 99.7% → 62.2%), made fail-loud-never-truncate, CI-enforced, and stated at the provider abstraction.

**No DIRTY items.** The two SHOULDs (G-A, G-B) are non-blocking doc/implementation clarifications the planner folds into the C-4.5 coder prompt — they do not change the design's correctness because blob-byte determinism is not load-bearing and the decode-fail-loud behavior is the natural implementation of the design's existing posture. The NITs (G-C margin, G-D projection-basis + §5.a wording) are coder/Pack-Chat hygiene. None rises to a flaw requiring an architect redesign.

**For the planner — fold these into the C-4.5/C-4.6 coder scope (non-blocking, do-at-implementation):**
1. **G-A:** pin the gzip implementation to python3 `gzip.GzipFile(mtime=0)` on ALL forward paths (migrator, `tracker-edit.sh`, guard); document that decode-identity (not blob-byte identity) is the load-bearing invariant.
2. **G-B:** state the corrupt-blob reverse failure mode as fail-loud (named entry + "corrupt blob"), never silent-empty.
3. **G-D:** compute the size check and the guard size leg on the actual composed-body length (not the distribution upper-bound proxy); correct the §5.a re-scope wording ("parses it back" → blob-model phrasing) when Pack Chat applies it.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag`; only `git rev-parse HEAD` (read-only) + Read/Bash read-only measurement; the sole write is this ONE report. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op; no live GH (gzip/base64/parser run locally on read-only copies; no `gh`); no file overwrite outside the report. | COMPLIANT |
| `empirical-evidence-blocks` | Every Part-1/Part-2 finding (N-1 distribution, N-2 precedent, N-7 surfaces, G-A determinism, G-B availability) carries CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL. | COMPLIANT |
| `ci-guard-measure-then-bound` | Re-verified the design applies it to SIZE: full all-211 distribution measured (reproduced to the byte), categorized, bounded by gzip + a loud-fail overflow contract, post-fix verified empirically. The guard now has a size leg. | COMPLIANT |
| `verify-full-ci-suite` | Confirmed the new check lands in `main()` (unattended) and `tracker-provider-test.sh` (N-7) is already wired in `validate-pack.yml:117`; the new per-check test wiring obligation (Check 42) is in §4.5/§5.b/R10. | COMPLIANT |
| `verify-availability-not-just-existence` | G-B verified python3 zlib is BUNDLED + present (not merely "gzip exists"); G-A verified the CLI-gzip alternative is NON-portable, so the python3 path is the usable one on both target OSes. | COMPLIANT |
| `pattern-matching-out-of-context` | Challenged the gzip switch as property-fit vs reflex: it solves the measured size bound (99.7%→62.2%) and `mtime=0` is the determinism idiom; the N-2 comparator reuses the existing whitespace-tolerant precedent. Property-fit confirmed. | COMPLIANT |
| `tracker-portability` | N-7 verified: the size contract lives at the TrackerProvider abstraction (`provider_body_limit`), read from the active provider, no hard-coded GH constant in the migrator; agnostic layer intact. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered Parts 1-3 + verdict + this block + attestation; named what is wrong (G-A/G-B SHOULDs), did not author a redesign; final-pass calibration honored (no re-opening passed text; no nit-hunting beyond two genuine doc/impl items). | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | Re-confirmed pack-only: METHODOLOGY (supporting-docs) untouched, `_rules.md` (pack) edited, project-side `_rules.md` correctly diverged, client emit branch isolated. | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence, no AMBIGUOUS. | COMPLIANT |

## READ-IN-FULL attestation (this session, at HEAD `feaa45d`)

| Item | Read / re-measure proof |
|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (fix-2-revised) | Read FULL (1-969, all pages). Every fix-2 change assessed: §3.2/§3.3 gz64 carrier, §3.3a(ii) normalization-tolerant comparator, §3.3b idempotency, §3.3c SIZE BUDGET (distribution + overflow contract + `provider_body_limit`), §4.2-4.4 guard (byte + size legs), §4.5 surfaces, §5.b commits, §7 R-GZIP/R-SIZE/R-PROVIDER/R-NORM rows, §9 rules block. |
| `DESIGN-REVIEW-BD-204-LOSSLESS-FIX-R2.md` (my review-2) | Carried as the finding baseline (N-1/N-2/N-7 verified RESOLVED in Part 1; N-3..N-6 already PASS). |
| Live tree (`backlog/BD-*.md`) | RE-MEASURED: gz64 vs raw projection across all 211 (BD-136 65,335→40,771; BD-191; BD-203; 0 over 80% gz vs 1 raw); gzb64=12,708 (3:1). |
| `scripts/lib/tracker-provider.sh` / `tracker-provider-gh.sh` | Re-read the 19-op dispatch + capability-flag model (`:12-30`, `provider_capabilities` `:141`) — confirms `provider_body_limit` slots in additively (N-7). |
| `scripts/lib/tracker-migrate-forward.sh` / `-reverse.sh` / `tracker-edit.sh` | Re-confirmed the gzip paths run via python heredocs (the harness language); the surface split (`surface == "pack"`); `tracker_edit_apply` exists (B-3/N-2 grounding). |
| gzip implementations (python3 vs Apple CLI) | RE-MEASURED: python `gzip.GzipFile(mtime=0)` vs `gzip -n` differ at header bytes 8-9 (XFL/OS) but decode byte-identical (G-A). python zlib 1.2.12 bundled (G-B). |
| `.github/workflows/validate-pack.yml` | Confirmed `tracker-provider-test.sh` wired (`:117`); Check 42 wiring obligation for the new per-check test stands. |
| `scripts/validate-pack.py` | Confirmed highest banner = Check 48 (taken; new check = next integer, D-5 closed). |
| GitHub body-field behavior | 65,536-byte hard limit = documented platform constant (used as the `provider_body_limit` GH value; not network-verified per the read-only mandate). GH web-edit normalization (CRLF→LF, trailing-whitespace) = the documented munging the N-2 comparator is sized to; cross-checked vs `tracker-mirror.sh`/roundtrip-test precedent. |
| Curated memory (ci_guard_measure_then_bound, verify_full_ci_suite, verify_availability_not_just_existence, tracker_portability, pack_project_separation, scope_deliverables_to_the_ask, agent_output_rules_applied_block) + CLAUDE.md `## Pack memory` | Carried as governing rules; reflected in the Rules-Applied block. |

**No named document was derived rather than read.** The gz64 distribution, the python-vs-CLI gzip header divergence, the provider capability model, and the CI wiring are this session's own command output at HEAD `feaa45d`, 2026-06-07.

**End of DESIGN-REVIEW-BD-204-LOSSLESS-FIX-R3.md**
