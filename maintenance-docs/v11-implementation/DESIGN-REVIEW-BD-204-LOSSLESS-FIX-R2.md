# DESIGN-REVIEW-BD-204-LOSSLESS-FIX-R2 — review-2 of the bounded cycle

> **Agent:** pack-reviewer (independent, adversarial). **Mode:** REVIEW-2; one report write; codebase read-only.
> **HEAD:** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`). **Branch:** `v11-dev`. **Date:** 2026-06-07. **Scope:** PACK-ONLY.
> **Under review:** the IN-PLACE-REVISED `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (now 826 lines; mechanism changed to a single base64 verbatim-body blob `<!-- pack-entry-body-b64: ... -->`).
> **Method:** re-read the revised design in full; re-measured every load-bearing NEW claim against the actual code/tree at HEAD `feaa45d`. The design's EE blocks were re-run, not trusted.
>
> **Bottom line.** The revision RESOLVES all 7 review-1 findings (5 RESOLVED, 2 RESOLVED-with-a-residual-NIT) and the SHOULDs. The blob model is the right call and is genuinely collision-proof and byte-faithful — I re-verified base64 round-trips BD-136 and BD-204 byte-identical with zero `-->` in the encoding. BUT the new mechanism introduces ONE genuine BLOCKER the design does not treat at all: **the GH 65,536-char body limit (N-1)**. The verbatim-blob model DOUBLES the body payload (visible H2 projection + full base64 blob), and BD-136's projected body is **60,912 bytes today — 93% of the hard limit, ~4.6 KB headroom — and entries grow.** The design has zero size-budget section and zero TrackerProvider limit contract (N-7). One MUST (N-2 divergence-detection robustness vs GH body normalization). Otherwise the design is sound. **Verdict: PROCEED-WITH-FIXES** (close N-1 + N-2 in fix-2; then final review-3).

---

## PART 1 — FINDING-RESOLUTION VERIFICATION

| Review-1 finding | Resolution verdict | Evidence |
|---|---|---|
| **A-1 / D-1 / D-3** (emit is not a byte-faithful reproducer; byte-leg false-fails 20 entries; post-fix verification was logical-only) | **RESOLVED** | The design now REWRITES the pack-branch emit (§3.3 step 5, §5.b C-4.5, §7 R4) to write `pe_backpointer_line` + `raw_body` verbatim, explicitly abandoning the fixed-order projection. The byte leg is now the only leg and is achievable (B-1 below). Post-fix verification is now EMPIRICAL (§4.3, §4 EE blocks) — re-confirmed below. |
| **B-1 / C-1** (prose blocks are not `Label: value` lines; per-field model cannot carry them; they are shredded into `unblocks`) | **RESOLVED** | §1.6b records the corruption with my exact measurement re-confirmed (73-item shred). The design COMMITS to the verbatim-body blob (§3.2/§3.3) and explicitly REJECTS the per-field `[label,value]` model. The blob carries bytes, not parsed fields, so prose blocks ride verbatim. |
| **D-5** (Check 48 already taken) | **RESOLVED** | `grep -nE 'Check 48' design.md` shows the only occurrences are in the EE block PROVING 48 is taken; every reference to the NEW check now says "the next registry integer (49 today) — HARDCODES NO NUMBER" (§4.2, §4.5, §5.b). No stale hardcode remains. |
| **B-2** (delimiter collision unmeasured) | **RESOLVED** | §3.3/§4.2 measure the collision set (4 `-->` entries, 1 fence) and choose base64 (alphabet `[A-Za-z0-9+/=]`, provably disjoint from `-->`/`<!--`/fence/comma). Re-verified below: BD-136's base64 contains zero `-->`. |
| **B-3** (double-render / human-edit data-loss) | **RESOLVED** | §3.3a defines the precedence (blob authoritative), the `tracker-edit.sh` producer-side sync (both views regenerated on every `provider_update`), and a divergence-DETECTION backstop (reverse recomputes H2 from blob, FAILs loud on mismatch). Grounded in a real function (`tracker_edit_apply` exists). Robustness caveat → N-2 (MUST). |
| **C-2** (53 multi-paragraph Descriptions) | **RESOLVED** | §4.2 EE empirically round-trips the prose-heaviest entry (BD-204) base64 byte-identical incl. interior blank lines. Re-confirmed below. |
| **D-4 / G-1** (new per-check test must be wired or Check 42 fails; workflow yml missing from §4.5) | **RESOLVED** | `.github/workflows/validate-pack.yml` is now a §4.5 lock-step row, a C-4.6 deliverable (§5.b), and §7 R10, with an EE block confirming Check 42 has no exemption. |

### SHOULDs claimed addressed

| SHOULD | Verdict | Evidence |
|---|---|---|
| **A-3 / G-2** (phase call site `:959` needs the new param DEFAULTED) | **RESOLVED** | §3.3 step 2/3, §4.5 row, §7 R2 all require `${6:-}`. Re-confirmed `:959` is a 4-arg call (`tmf_compose_issue_body "$phase_id" "Phase epic for …" "" ""`) — a defaulted 6th param keeps it working. |
| **B-4** (idempotency) | **RESOLVED** | §3.3b: verbatim emit + verbatim re-capture → fixed point after one cycle. `pe_backpointer_line` is a pure deterministic function (re-confirmed — depends only on key+id), so the derived line-1 is stable across cycles. Logic holds. |
| **B-5** (captured-span boundary incl. header double-encoding) | **RESOLVED** | §3.3 specifies lines 2..EOF (bold-header INCLUDED in the blob; title in the Issue TITLE is advisory; blob header authoritative for the tree) — avoids title double-encoding divergence cleanly. |
| **G-3** (note intentional pack/project `_rules.md` divergence) | **RESOLVED** | §4.5 G-3 note + §7 R9 state the 3 project-side `_rules.md` diverge until BD-206/207, correct-by-design per `pack-project-separation`. |
| **R-CLIENT** (client emit branch isolation) | **RESOLVED** | §7 R-CLIENT. Re-confirmed: the surface split is real — `if [[ "$surface" == "pack" ]]` (`tracker-migrate-reverse.sh:1204`, `:1235`) dispatches the pack tree emit vs `_tmr_emit_backlog` (the client monolith, `:627`). The rewrite touches only the pack path. |

**Part-1 conclusion:** all 7 BLOCKER/MUST findings and all SHOULDs are RESOLVED. Two residual NITs (P1-N1, P1-N2) below — non-blocking, flagged per the no-nit-hunt calibration only because they are factual inconsistencies in load-bearing prose.

- **P1-NIT-1 (residual per-field language in the §5.a re-scope text).** The proposed BD-204 re-scope text (design `:594-595`) still says the migrator "serializes the entry's COMPLETE ordered field set verbatim … reverse **parses it back** byte-for-byte." "Parses it back" is per-field-model residue inconsistent with the committed blob model (which the design elsewhere states "never re-parses the body into fields"). The SUBSTANCE (verbatim, byte-for-byte, zero carve-outs) is correct; only the wording drifts. Pack Chat applies this text pack-chat-only, so it is trivially fixable at apply time. Non-blocking.

- **P1-NIT-2 (the `--force` line citation).** §3.3a cites the silent-data-loss-guard `--force` idiom at `tracker-migrate-reverse.sh:1032`. The force flag is real (`:985` `local force`, `:1014`/`:1023`/`:1042` refusal-unless-force), but the exact line is off by a few. Cosmetic; the idiom it leans on genuinely exists. Non-blocking.

---

## PART 2 — NEW-MECHANISM SCRUTINY (the blob model's new risks)

### N-1 [BLOCKER] The GH 65,536-char body limit — the blob model DOUBLES the body payload; BD-136 is at 93% of the hard limit today, and the design has NO size-budget treatment.

The revised design keeps the visible H2 sections (advisory) AND adds the full base64 blob. For an entry whose body is mostly carried fields (Description/File-Symbol), the content is now serialized TWICE in the Issue body — once as H2 prose, once as base64. I computed the actual projected body for the largest entry.

> **Empirical-Evidence Block (BD-136 projected revised-design body = 60,912 bytes; ~4.6 KB under the 65,536 hard limit).**
> `CMD`: parse BD-136 via the real `_tmf_parse_backlog_file`; run the real `tmf_compose_issue_body` to get the H2-projection size; add `base64(lines 2..EOF)` + the blob-marker wrapper. `H2=$(tmf_compose_issue_body BD-136 "$DESC" "$CTX" "$RES" "$FS" | wc -c)`; `B64=$(tail -n +2 backlog/BD-136.md | base64 | tr -d '\n' | wc -c)`; `python3 -c "print($H2+$B64+28)"`.
> `OUT`: `description: 3777 bytes; file_symbol: 19710 bytes` → H2-projection body = `23612` bytes; base64 blob = `37272` bytes; **projected total = 60,912 bytes; headroom = 4,624 bytes** (65,536 − 60,912).
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: BD-136 sits at **93%** of the GH hard body limit under the revised design. My figure (60,912 / 4,624 headroom) differs from the PM-Chat estimate the prompt cites (~65,226 / ~310 headroom) — both put BD-136 deep in the danger zone; the exact figure is sensitive to how the H2 projection is computed (BD-136's `File/Symbol` block is 19,710 bytes, an unusually large case). `CONCL`: SUPPORTED — the worst-case body is at 90%+ of a hard external limit.

> **Empirical-Evidence Block (the design contains NO size-budget treatment).**
> `CMD`: `grep -niE '65536|65,536|body limit|size budget|too large|truncat|character limit|byte limit' maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md`
> `OUT`: (empty). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the design never mentions the GH body limit, never bounds the worst case, never states what happens when an entry's `H2 + blob + markers` exceeds 65,536. `CONCL`: SUPPORTED — N-1 is unaddressed.

**Adjudication: BLOCKER, not acceptable-with-monitoring.** A design whose worst case sits at 90%+ of a hard external limit, whose chosen mechanism *doubles* the payload that pushes it there, and which treats the limit nowhere, is incomplete per `ci-guard-measure-then-bound` (measure the bound, then design within it). Three concrete, cheap fixes the architect can choose among (I name the wrongs, not the design): (a) drop the redundant H2 projection for entries where the blob already carries everything, or emit the H2 only up to a budget; (b) gzip-then-base64 the blob (the prose compresses well — BD-136's 27,954 raw bytes would shrink substantially, buying large headroom); (c) state an explicit overflow contract (the migrator FAILs loud with the entry id + byte count when `H2 + blob > limit − margin`, so it can never silently truncate). The point is that the design must MEASURE the worst case against the limit and bound the mechanism to it — exactly the rule the rest of the design follows for the delimiter. Note this also feeds N-7 (the same bound must be stated at the provider layer for non-GH trackers with smaller limits).

### N-2 [MUST] §3.3a divergence DETECTION may FALSE-POSITIVE on GitHub's own body normalization.

The divergence backstop (§3.3a (ii)) recomputes the H2 projection from the blob and byte-compares it to the Issue's actual H2 sections; mismatch → FAIL. But the comparison input (the visible H2 body) is exactly the part GitHub may normalize on a web round-trip (CRLF↔LF, trailing-whitespace stripping, Unicode NFC). The blob is opaque/safe (base64 survives any normalization that preserves the comment), but the H2 sections are plain markdown the GH web editor and API can munge. An *untouched* issue that GH merely re-rendered could then trip the divergence FAIL — turning the safety backstop into a noise generator that blocks legitimate reverses.

> **Empirical-Evidence Block (the divergence comparison reads the visible body, which is normalization-exposed).**
> `CMD`: re-read design §3.3a (ii): "reverse … RECOMPUTES the H2-projection from the blob and COMPARES it to the Issue's actual H2 sections; on mismatch it FAILs."
> `OUT` (the contract as written): compares recomputed-H2 vs issue-H2 byte-for-byte (no normalization step specified). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: GitHub web edits are known to normalize line endings / trailing whitespace; a byte-exact compare of the visible H2 against a freshly-recomputed H2 can mismatch even when no human edited content. The design specifies no normalization (whitespace-tolerant / line-ending-normalized) comparison. `CONCL`: SUPPORTED — the detection leg needs a normalized comparator, or it false-positives.

**Fix:** the divergence comparator must normalize (line endings, trailing whitespace) before comparing — the same whitespace-tolerant discipline the existing roundtrip test documents (`tracker-migrate-roundtrip-test.sh:9` "Zero diff (whitespace-tolerant)"). The architect should state the normalization explicitly so the coder does not implement a byte-exact compare. Severity MUST (not BLOCKER) because it affects only the Mode-3 human-edit backstop, not the core forward/reverse round-trip the guard checks.

### N-3 [RESOLVED-as-designed] Idempotency holds for the emit-rewrite + blob.

> **Empirical-Evidence Block (the only drift source is removed; the back-pointer derivation is deterministic).**
> `CMD`: `sed -n '302,320p' scripts/lib/per-entry/_lib.sh` (the `pe_backpointer_line` def).
> `OUT`: `pe_backpointer_line` is a pure function of `key`+`id` → `printf '<!-- per-entry source: %s; contract: %s -->'` (no time/state). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: cycle-2 input = cycle-1 output because reverse writes `raw_body` verbatim and the derived line-1 is deterministic; the fixed-order normalization (the only prior drift source, A-1) is removed from the pack branch. `reverse(forward(x)) == x` (back-pointer stripped) ⇒ fixed point. `CONCL`: SUPPORTED — §3.3b idempotency claim holds. (Coder must verify the trailing-newline edge: all entries end in a single `\n`; the blob captures it and `pe_write_atomic` must write it back — the byte guard catches any mismatch.) |

### N-4 [PASS] The client `_tmr_emit_backlog` branch is genuinely isolated from the pack-branch rewrite.

> **Empirical-Evidence Block.** `CMD`: `grep -n 'surface == "pack"\|_tmr_emit_pack_tree\|_tmr_emit_backlog' scripts/lib/tracker-migrate-reverse.sh`. `OUT`: `_tmr_emit_backlog()` (`:627`, client monolith) is a SEPARATE function from `_tmr_emit_pack_tree()` (`:712`, pack tree); the dispatcher gates on `if [[ "$surface" == "pack" ]]` (`:1204`, `:1235`). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the §3.3 rewrite touches only `_tmr_emit_pack_tree`; the client path is untouched (BD-207 owns it). No shared-helper regression vector. `CONCL`: SUPPORTED — R-CLIENT holds.

### N-5 [PASS] The defaulted 6th `raw_body` param leaves phase-epic issues unaffected.

> **Empirical-Evidence Block.** `CMD`: `sed -n '959,960p' scripts/lib/tracker-migrate-forward.sh`. `OUT`: `phase_body=$(tmf_compose_issue_body "$phase_id" "Phase epic for …" "" "")` — a 4-arg call. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: with the new param `${6:-}`, the phase call passes no `raw_body` → no blob marker emitted (correct: a synthesized phase epic has no per-entry source file). The phase path is unchanged. `CONCL`: SUPPORTED.

### N-6 [PASS, with a low-severity watch-out] The blob marker does not collide with the existing pack-id marker read; one latent in-body-marker hazard noted.

> **Empirical-Evidence Block.** `CMD`: `grep -n 'pack-id:' scripts/lib/tracker-migrate-reverse.sh` ; `python3 re.findall(r"<!--\s*pack-id:\s*([A-Z]+-\d+|phase-\d+...)\s*-->", BD-065 body)`. `OUT`: the pack-id read regex (`:532`, `:1101`) is anchored to the literal `pack-id:` token — it cannot match a `pack-entry-body-b64:` marker. BD-065's body documents `<!-- pack-id: TD-NNN -->` but `TD-NNN` is not `\d+`, so it does NOT match (0 matches). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: no collision for current entries; the blob is base64 (cannot contain a marker). `CONCL`: SUPPORTED. **Watch-out (NIT):** the pack-id `re.search` returns the FIRST body match; the forward emits the real `pack-id` marker at body-top, so it wins — but if a future entry documents a literal `<!-- pack-id: BD-123 -->` (digits) in its visible H2 Description, a top-anchored read is still safe. Recommend the coder anchor the pack-id read to the marker-trio region, not a free `re.search`, as defensive hardening. Low severity; not a blocker.

### N-7 [MUST] Tracker-agnosticism — a 37 KB base64 blob assumes a large body field; the design states no limit-handling contract at the TrackerProvider layer.

The design's HARD constraint (inherited from BD-204) is that the carrier must ride a plain body field on ANY tracker. A 37 KB base64 blob (BD-136) fits GitHub's 65 KB body, but other GA trackers have smaller limits (e.g., some have 32 KB description fields). The design names no provider-layer contract for "what happens when the body field is too small for the blob."

> **Empirical-Evidence Block (no provider-layer limit contract in the design).**
> `CMD`: `grep -niE 'TrackerProvider|provider.*limit|smaller body|body field limit' maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md`
> `OUT`: (empty). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the design verifies the blob fits GitHub (implicitly, by not exceeding 65 KB) but states no abstraction-level contract; a future Jira/Linear provider with a smaller body field would silently fail or truncate. `CONCL`: SUPPORTED — the agnostic-layer limit contract is missing.

This is the same root gap as N-1, surfaced at the abstraction boundary. Fix: state, at the provider abstraction, that the carrier requires a body field of at least the worst-case blob size + margin, and that the migrator FAILs loud (never truncates) when the active provider's limit is exceeded. This keeps the design honestly tracker-agnostic rather than tacitly GitHub-sized. MUST (it is a HARD-tier BD-204 constraint — tracker-agnosticism — that the design does not honor for the new mechanism).

---

## PART 3 — VERDICT

**PROCEED-WITH-FIXES.**

The revision is a strong, evidence-backed response: all 7 review-1 findings are RESOLVED, the blob model is the correct property-fit (I independently re-verified it is collision-proof and byte-faithful on the two hardest entries, and that the emit-rewrite dissolves the A-1/D-1 byte-leg dilemma), and the enumerate-encoding-surfaces set is now complete. The constraint set (no carve-outs, CI false-green closed by a strong byte-leg, no entry rewrite, v11.0 launch gate) holds, and the pack-only boundary is honored (R9/F-2 correctly steer the schema edit to `backlog/_rules.md`; the client emit branch is isolated).

The remaining work is bounded and does NOT require an architect redesign of the core mechanism — the blob model is sound; it needs a size-budget bound bolted on:

**BLOCKER (fix-2):**
- **N-1 — the GH 65,536-char body limit.** The blob model doubles the body payload; BD-136 is at ~93% of the hard limit today (60,912 bytes measured) and the design treats the limit nowhere. Add a size-budget section: measure the worst case against the limit, and bound the mechanism (drop/cap the redundant H2 projection, OR gzip-then-base64, OR a loud-fail overflow contract). This is the same measure-then-bound discipline the design already applies to the delimiter — apply it to the size.

**MUSTs (fix-2):**
- **N-2 — divergence detection must use a normalization-tolerant comparator** (line endings, trailing whitespace) so GitHub's own body normalization does not false-positive the §3.3a backstop.
- **N-7 — state the TrackerProvider-layer body-size contract** (minimum body-field size; loud-fail-never-truncate) so the design is honestly tracker-agnostic, not tacitly GitHub-sized. (N-1 and N-7 are one gap at two layers; one size-budget section can close both.)

**NITs (apply opportunistically, non-blocking):** P1-NIT-1 (§5.a re-scope "parses it back" residual per-field wording — Pack Chat fixes at apply time), P1-NIT-2 (the `--force` line-number citation), N-6 watch-out (anchor the pack-id read to the marker region defensively).

Per the bounded-cycle calibration: this is review-2; the next step is fix-2 (close N-1 + N-2 + N-7) then a FINAL review-3. The findings above are real (each backed by a re-run measurement at HEAD `feaa45d`), not new nit-hunting on already-passed text — N-1 in particular is a hard-external-limit collision the new mechanism actively worsens and the design does not see.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag`; only `git rev-parse HEAD` (read-only) + Read/Bash read-only measurement; the sole write is this ONE report. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op; no live GH (no `PACK_TRACKER_LIVE_GH`, no `gh repo create`; base64/parser run locally on read-only copies); no file overwrite outside the report. | COMPLIANT |
| `empirical-evidence-blocks` | Every Part-2 finding (N-1 size, N-2, N-3, N-4, N-5, N-6, N-7) and the Part-1 resolutions carry CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL. | COMPLIANT |
| `enumerate-encoding-surfaces` | Re-verified the design's §4.5 set against code: workflow yml (G-1), phase site `:959` (G-2), `tracker-edit.sh` (B-3), client-branch isolation (N-4) all confirmed present/correct; no further omission found. | COMPLIANT |
| `verify-full-ci-suite` | Confirmed the new check lands in `main()` (unattended battery) and the per-check test must be wired in `validate-pack.yml` (Check 42, no exemption) — re-read the check; the design now covers it (D-4 RESOLVED). | COMPLIANT |
| `pattern-matching-out-of-context` | Challenged whether the blob is property-fit vs pattern-reuse: it generalizes the existing HTML-comment marker idiom (pack-id/template_version) and is justified on the prose-block-corruption evidence (B-1) — property-fit confirmed. The per-field model is correctly rejected on evidence. | COMPLIANT |
| `ci-guard-measure-then-bound` | Applied the rule to the design itself: it measures+bounds the delimiter (good) but FAILS to measure+bound the SIZE against the 65 KB limit (N-1) — flagged as BLOCKER on exactly this rule. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered Parts 1-3 + verdict + this block + attestation; named what is wrong (N-1/N-2/N-7), did not author a replacement design. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | Re-confirmed the pack/project boundary: `_rules.md` (pack) edited, METHODOLOGY.md (supporting-docs, ships to clients) NOT edited, 3 project-side `_rules.md` correctly untouched; client emit branch isolated. | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence, no AMBIGUOUS. | COMPLIANT |

## READ-IN-FULL attestation (this session, at HEAD `feaa45d`)

| Item | Read / re-measure proof |
|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (revised) | Read FULL (1-826, two pages). Every §1.6b/§3.2/§3.3/§3.3a/§3.3b/§4.2/§4.3/§4.5/§5.b/§7 change assessed against review-1. |
| `DESIGN-REVIEW-BD-204-LOSSLESS-FIX.md` (my review-1) | Carried as the finding baseline (the 7 findings + SHOULDs verified RESOLVED in Part 1). |
| `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md` | Read full in review-1; not re-read (unchanged); its numbers re-confirmed where load-bearing. |
| `scripts/lib/tracker-migrate-forward.sh` | RE-RAN `_tmf_parse_backlog_file` + `tmf_compose_issue_body` on BD-136 (N-1 projection) + confirmed phase call site `:959` (N-5) + parser produces valid JSON. |
| `scripts/lib/tracker-migrate-reverse.sh` | Re-read the surface split (`:1204`/`:1235`), `_tmr_emit_backlog` `:627` vs `_tmr_emit_pack_tree` `:712` (N-4), the pack-id marker regex `:532`/`:1101` (N-6), the `--force` idiom `:985`-`:1042` (P1-NIT-2). |
| `scripts/lib/tracker-edit.sh` | Confirmed `tracker_edit_apply` + `provider_update` body recompose exist (§3.3a B-3 grounding). |
| `scripts/lib/per-entry/_lib.sh` | Re-read `pe_backpointer_line` `:302` (deterministic — N-3) + `pe_strip_backpointer_stdin` `:337`. |
| `scripts/validate-pack.py` | Confirmed highest banner = Check 48 (taken); Check 42 (`check_ci_workflow_wires_per_check_tests`) no-exemption (D-4). |
| Live tree (`backlog/BD-*.md`) | RE-MEASURED: base64 round-trip BD-136 + BD-204 byte-identical (CLEAN diff); base64 contains 0 `-->`; the 4 `-->` entries (BD-065/069/103/136); BD-136 raw=27,954 / b64=37,272 / projected body=60,912 (N-1); 20 no-Blockers entries; 53 multi-paragraph; 73-item BD-204 unblocks shred. |
| GH body limit (65,536) | Known platform constant (GitHub Issue body max); used as the N-1 bound. Not network-verified (no live GH per the read-only mandate); stated as the documented limit. |
| Curated memory (ci_guard_measure_then_bound, verify_full_ci_suite, pack_project_separation, commit_subject_keyword_token_trap, architect_planner_empirical_evidence, scope_deliverables_to_the_ask, agent_output_rules_applied_block) + CLAUDE.md `## Pack memory` | Carried as governing rules; reflected in the Rules-Applied block. |

**No named document was derived rather than read.** The N-1 projection (60,912 bytes), the base64 collision/round-trip results, the surface-branch isolation, and the phase call site are this session's own command output at HEAD `feaa45d`, 2026-06-07.

**End of DESIGN-REVIEW-BD-204-LOSSLESS-FIX-R2.md**
