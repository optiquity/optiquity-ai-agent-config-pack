# PACK-REVIEW-CUMULATIVE-V11-POSTSWEEP — bias-free re-derivation review of v11.0 surface

## Header

- HEAD reviewed: `27e08d9`.
- Scope: BD-060 through BD-071 (v11.0 in-scope surface). Extension-point soundness for BD-072 / BD-073 / BD-074 / BD-089 / BD-106 / BD-108 / BD-111.
- Cross-references consulted: `ARCHITECTURE.md` (V1), `ARCHITECTURE-V2.md` (V2), `ARCHITECTURE-V3.md` (V3), `ARCHITECTURE-V3.1-DELTA.md`, `ARCHITECTURE-V3.2-DELTA.md`, `ARCHITECTURE-V3.3-DELTA.md`, `IMPLEMENTATION-PLAN.md`, `IMPLEMENTATION-PLAN-ADDENDUM.md`, `IMPLEMENTATION-PLAN-ADDENDUM-2.md`, `IMPLEMENTATION-PLAN-ADDENDUM-3.md`, `IMPLEMENTATION-PLAN-ADDENDUM-4.md`, `supporting-docs/METHODOLOGY.md` (v10 grammar reference).
- Strict exclusion honored: no `PACK-REVIEW-*.md` file was read during this pass.

### Test totals (verified at HEAD `27e08d9`)

- `python3 scripts/validate-pack.py` → rc=0 (clean — every check OK).
- `bash scripts/tests/template-translations-test.sh` → 44 / 0
- `bash scripts/tests/template-version-test.sh` → 36 / 0
- `bash scripts/tests/test-issue-forms.sh` → 78 / 0
- `bash scripts/tests/tracker-agent-read-test.sh` → 31 / 0
- `bash scripts/tests/tracker-config-test.sh` → 32 / 0
- `bash scripts/tests/tracker-errors-test.sh` → 60 / 0
- `bash scripts/tests/tracker-init-test.sh` → 95 / 0
- `bash scripts/tests/tracker-migrate-forward-test.sh` → 111 / 0
- `bash scripts/tests/tracker-migrate-reverse-test.sh` → 93 / 0
- `bash scripts/tests/tracker-migrate-roundtrip-test.sh` → 39 / 0
- `bash scripts/tests/tracker-provider-test.sh` → 65 / 0
- **Aggregate: 684 PASS / 0 FAIL across 11 suites.** Matches the success-criteria target.

---

## Verdict

**GO-WITH-FIXES.**

---

## Net assessment

The v11.0 surface (BD-060 through BD-071) lands the contract specified in V1 §1–§9, V2 §4 / §16 / §19 / §22, and V3 §27.1 / §28: a 18-operation TrackerProvider abstraction with GH backend (BD-060), tracker.toml schema + auto-detect (BD-061), trinity Document-locations Source column (BD-062), V3.3 §6.1 4-option `wi-type` issue forms (BD-063), v11.0 templates-archive bootstrap (BD-064), 11-step forward orchestrator with mapping + checkpoint + read-only mirror header (BD-065), `pack tracker init` flag-driven orchestrator + label set + verb dispatcher (BD-066), 9-step reverse orchestrator + sidecar (BD-067), stateful round-trip fixture covering F→R and F→R→F properties (BD-068), D-18 dual-carrier template_version + V2 §19 update-templates infra (BD-069), 10-code typed-error formatter + V3 §27.1 Layer-2 verb table (BD-070), and V1 §8.4/§8.5 narrow prompt-language change (BD-071).

The post-sweep fix commits between `f9da4d1` and `27e08d9` close the seven specific items the prior sweep targeted: forward_complete=true is now flipped on a successful forward run; reverse Type decoding takes the actual scope/severity label value (with the literal placeholder fallback that preserves byte-equivalent round-trip on `TODO(scope)` v10 fixtures); reverse entry discovery now unions `provider_list` results with `bd-entry`/`td-entry`/`phase-epic` label filters before falling back to mapping recovery; coder/auditor/reviewer prompts gained tracker-aware framing (the reviewer hygiene check is the lone read-context line that was a true V1 §8.5 violation; coder/auditor extensions are write-prohibition tracker-mode clarifications, not V1 §8.5 rewrites); the Layer-2 verb table covers all 11 codes with `pack tracker doctor` as the destination for `not-implemented`; the doctor verb gained a capability-cache refresh sub-surface (V2 §22.1) that diffs against `.pack-tracker/capabilities.json`; init grew a prior-state safety rail requiring `--force` when an `id-map.json` already exists; the additive 11th typed code is now documented in V1 §2.5 as additive (not a contract violation); BD-073's BACKLOG entry now documents the v11.0 stub posture.

The surface is releasable for the in-scope BDs. The findings below are non-blocking — they fall into doc/comment drift (stale "BD-067 — pending" placeholders that should now read "live", a self-referential BD-073 description, a comment-vs-code mismatch on the typed-code count), a narrow V1 §8.5 application gap on `pm-startup` Step 2 (the BD-071 sweep limited the rewrite to prompt files; the SKILL.md still names `BACKLOG.md` and `STATUS.md` literally), and PM-CHAT.md tool-specific sections that retain the v10 "Read BACKLOG.md" phrasing. None of the prior sweep fixes regressed; the test surface grew from 645 (post-BD-071) through the post-sweep additions to 684 with zero failures. Extension points for BD-072 / BD-074 / BD-089 / BD-106 / BD-108 / BD-111 remain clean. BD-073 ships as a typed `not-implemented` stub per V2 §22.1.


---

## Findings

### F1 — NIT — Stale "BD-067 — pending" placeholders in dispatcher docstring + init epilogue

- **File / symbol.**
  - `scripts/pack-tracker.sh` lines 11, 14 (header docstring for `disable` and `doctor`).
  - `scripts/tracker-migrate.sh` lines 6, 8 (header docstring for `reverse` and `doctor`).
  - `scripts/lib/tracker-init.sh` line 236 (init success epilogue: `Run \`pack tracker disable\` to revert (BD-067 — pending).`).
- **Contract source.** V2 §22.1 verb table; BD-067 BACKLOG entry status is `Resolved` at line 135 (`pack tracker disable` and `pack tracker doctor` verbs wired). The dispatcher cases at `scripts/pack-tracker.sh:359-361` route `disable | doctor | update-templates` to live `cmd_*` functions.
- **Observation.** The verbs are live (`cmd_disable` calls `tracker_migrate_reverse_run` with `flip_mode=1`; `cmd_doctor` calls `tracker_doctor_run`); the docstring text `(BD-067 — pending; placeholder.)` is stale. The init epilogue prints "BD-067 — pending" to the user even though `pack tracker disable` is now a live verb. User-visible drift.
- **Recommended action.** Update dispatcher docstrings to drop the "pending; placeholder" suffix; replace the init-epilogue line with `Run \`pack tracker disable\` to revert.` (no parenthetical).

### F2 — NIT — Header comment in `tracker-errors.sh` says "10 typed error codes" but the function emits 11

- **File / symbol.** `scripts/lib/tracker-errors.sh` line 9 (`# - V1 §2.5: 10 typed error codes (...)`); the function `tracker_error_codes` lines 83-97 emits 11 codes including `not-implemented`; the verb-table case statement lines 109-121 covers `not-implemented`.
- **Contract source.** V1 §2.5 specifies a minimum surface of 10 typed codes; ARCHITECTURE.md §2.5 (post-sweep) explicitly documents the additive 11th code (`not-implemented`) with the framing that "the ten typed codes are a minimum surface, not an exhaustive list." The header comment in `tracker-errors.sh` therefore undercounts and contradicts the architecture doc the file cites.
- **Observation.** The comment block at the top of the file references V1 §2.5 with a "10 typed error codes" count; the file actually carries 11 (intentionally additive per the architecture). Internal doc inconsistency.
- **Recommended action.** Edit the header comment to read "10 typed error codes from V1 §2.5 plus the additive `not-implemented` code documented in ARCHITECTURE §2.5 (eleven total)."

### F3 — NIT — BD-073 BACKLOG entry description is self-referential

- **File / symbol.** `BACKLOG.md` lines 226-235 (BD-073 entry).
- **Contract source.** Pack BACKLOG entry convention: a BD's `Description:` field describes what the BD itself does; cross-references name *other* BDs.
- **Observation.** The entry reads `the surface is reachable; the body lands in BD-073 and depends on BD-072's threshold-driven Layer 3 state file`. BD-073 is the entry being described; "the body lands in BD-073" is circular. Likely intent: "the body lands in a follow-on cut" or "the body lands later." The 27e08d9 commit message states "full implementation depends on BD-072's threshold-driven Layer 3 state file"; that wording is correct and could replace the body-lands-in-BD-073 phrasing.
- **Recommended action.** Replace `the body lands in BD-073` with `the full body lands in a follow-on minor` (or similar non-self-referential wording).

### F4 — NIT — `pm-startup` skill Step 2 retains v10 "Read BACKLOG.md / STATUS.md" literal phrasing

- **File / symbol.** `project-template/skills/pm-startup/SKILL.md` lines 66-77 (Step 2 — "Read these files in full: `BACKLOG.md`, `STATUS.md`, ...").
- **Contract source.** V1 §8.4: `Today (v10), \`coder.md\` prompt line 17 reads (paraphrased): "Read BACKLOG.md (Phase N entries)." Tomorrow (v11), the same prompt reads: "Read BACKLOG entries..."`. V1 §8.5: `Replace "Read BACKLOG.md" with "Read BACKLOG entries (resolve via trinity Document locations)". Replace "Read STATUS.md" with "Read STATUS (resolve via trinity)".`
- **Observation.** The post-sweep BD-071 narrative deliberately limited rewrite scope to agent prompt files (it touched `prompts/tester.md` and `prompts/pm-chat.md`). The `pm-startup` SKILL.md is read by every PM Chat session and contains the literal Step 2 instruction `Read these files in full: BACKLOG.md, STATUS.md`. Step 2 line 81 says `Use the Document locations section in the project context file to resolve file paths` — but the listed file names are still hardcoded literals, not resolver calls, so the resolver instruction does not actually engage in Step 2's reads. V1 §8.5 names the broader "Read X.md" pattern and the SKILL.md falls under it.
- **Recommended action.** Update Step 2 to phrase reads as "BACKLOG entries / STATUS entries (resolve location via the trinity `## Document locations` table — flat-file mode reads BACKLOG.md / STATUS.md; tracker mode reads the tracker mirror)." This matches the pm-chat.md prompt body's framing applied during the BD-071 sweep.

### F5 — NIT — Tool-specific sections of `project-template/docs/pack/PM-CHAT.md` retain v10 phrasing

- **File / symbol.** `project-template/docs/pack/PM-CHAT.md` lines 275, 319, 395 (Claude Project / Claude Web / Gemini CLI startup procedure sections — each says `Read BACKLOG.md, STATUS.md, ...`).
- **Contract source.** V1 §8.4 / §8.5 prompt-language change.
- **Observation.** PM-CHAT.md is a chat-tool-specific operating guide for the human + chat session. It is technically not an agent-prompt file (the BD-071 sweep targeted `prompts/`), so the sweep's narrowness defensibly excluded it. However, the document is the canonical PM Chat startup reference and these three lines instruct the chat to read BACKLOG/STATUS literally. In tracker mode the literal mirror is read-only and the data the chat needs lives in the tracker; the resolver framing is what V1 §8.5 prescribes for this read pattern.
- **Recommended action.** Either bring PM-CHAT.md into the V1 §8.5 rewrite (recommended — same one-line edit pattern applied during the BD-071 sweep) or document explicitly in the BD-071 narrative that PM-CHAT.md is intentionally out of scope at v11.0 and queue it as a follow-on minor.

### F6 — NIT — `_tmr_emit_backlog` collapses multi-line BACKLOG fields into single lines

- **File / symbol.** `scripts/lib/tracker-migrate-reverse.sh` lines 405-421 (`_tmr_emit_backlog` Python emit block — emits `Description:` / `Context:` / `Resolution:` as `f"Description: {desc}"` single-line f-strings).
- **Contract source.** V1 §6.7 round-trip safety: "byte-equivalent on tracker side; whitespace-tolerant on flat-file side." The pack BACKLOG.md convention (every existing BD entry, e.g. BD-060 lines 39-44) writes `Description:` as a multi-line indented continuation block; the forward parser at `tracker-migrate-forward.sh:200-207` documents this shape (`Description: <multi-line until next field>`).
- **Observation.** The reverse emitter writes one literal line per field. Round-trip is nominally satisfied because V1 §6.7 admits whitespace-tolerant flat-file diffs, but the emitted BACKLOG entry is no longer formatting-equivalent to a hand-authored entry — Description / Context / Resolution become one long line each. Over a real reverse against the pack BACKLOG (60+ entries), the resulting file is structurally legal but visually different from every entry the maintainer wrote by hand. This is acceptable per the contract; flagging because the formatting drift may cause merge-conflict noise on the next forward pass and may be visually disruptive on a `pack tracker disable` flow.
- **Recommended action.** Optional v11.x improvement: emit Description / Context / Resolution with a leading newline + indented continuation per the parser's documented input shape, restoring round-trip-formatting parity. Not a v11.0 blocker.

### F7 — NIT — Audit-log walking for CHANGELOG.md (V1 §6.5 step 7) is a documented stub

- **File / symbol.** `scripts/lib/tracker-migrate-reverse.sh` `_tmr_emit_changelog` lines 504-525.
- **Contract source.** V1 §6.5 algorithm step 7: `Emit CHANGELOG.md by walking closed-issue audit log per phase.`
- **Observation.** The implementation emits a stub with a `<!-- ... provider_events op is not yet implemented ... -->` comment block. BD-067 BACKLOG entry explicitly documents this deferral: `Audit-log walking for CHANGELOG.md step 7 deferred (provider_events op not in BD-060)`. The deferral is acknowledged and the stub does not lose data (skips emit if file already exists).
- **Recommended action.** No action at v11.0 — surface is correctly stubbed and gap is tracked. Confirm in v11.x backlog that a BD owns adding `provider_events` and re-engaging step 7.

### F8 — NIT — Sidecar reactions / attachments / audit_log placeholders

- **File / symbol.** `scripts/lib/tracker-sidecar.sh` (BD-067 surface).
- **Contract source.** V1 §6.6 + §6.6.1 (sidecar captures reactions, attachments, comment thread, audit log).
- **Observation.** The sidecar emits the `extra_fields` / `template_version` / `template_archive_path` shape. Reactions, attachments, and audit_log fields are placeholders per the BD-067 BACKLOG resolution narrative ("Reactions/attachments fetch deferred for sidecar (placeholders ship; ride-along to future BD)"). This is consistent with V1 §6.6 — the contract names what the sidecar "captures"; it does not require every field to be populated at v11.0 ship.
- **Recommended action.** No action at v11.0. Track in a future BD that wires up the fetches.

### F9 — NIT — Capability re-probing in `doctor` is implemented as a cache-refresh, not a deep schema diff

- **File / symbol.** `scripts/tracker-migrate.sh` `tracker_doctor_run` lines 291-325.
- **Contract source.** V1 §9.5 (schema reshape): `pack tracker doctor ... refreshes the capability cache and reports any backend changes`.
- **Observation.** The post-sweep doctor sub-surface re-probes `provider_capabilities`, compares to `.pack-tracker/capabilities.json`, and writes-back. A diff produces a `[WARN] capability cache differs from re-probe (schema-reshape)` line with the V3 §27.1 Layer-2 verb. This satisfies the contract: the cache is refreshed and a delta is surfaced. The "deep diff" (per-capability change reporting) is not implemented — the WARN line just says "differs". V1 §9.5's example schema-reshape message says "GraphQL field 'addSubIssue' not found on type 'Mutation'." That precise field-level diagnostic only appears when the underlying gh CLI itself emits the field-not-found error during a real call; doctor cannot synthesize it from a capability snapshot alone.
- **Recommended action.** No action — surface is consistent with V1 §9.5 at the available abstraction layer. A field-level diff would require a richer capability schema; that's beyond v11.0 scope.

### F10 — NIT — `init-project.sh` does not yet install tracker artifacts

- **File / symbol.** `scripts/init-project.sh`.
- **Contract source.** BD-080 (deferred, not in v11.0 surface): install per-CLI `pack-help/`, `HELP-FRAGMENT.md`, `tracker.toml.example`, issue forms.
- **Observation.** `init-project.sh` does not reference `tracker.toml` or the issue forms. New v11 client projects initialized today will not get the tracker artifacts. This is BD-080 scope, not a BD-060..BD-071 surface item, and BD-080 is correctly Open.
- **Recommended action.** No action at v11.0. Surfaced here because it interacts with the v11.0 release-readiness checklist (§7) at BD-093 ship time.


---

## Per-BD verification matrix

| BD | Status | Verification of contract |
|---|---|---|
| BD-060 — TrackerProvider abstraction + GH backend | GREEN | 18 ops + raw + capabilities are present in `scripts/lib/tracker-provider.sh` (dispatcher) + `tracker-provider-gh.sh` (GH backend); 65/65 tests; supports `provider_list` filter `{label, state}` per V1 §6.5 step 1; comment-fallback for `blocks`/`blocked-by` (BD-111 deferral) is documented. |
| BD-061 — `tracker.toml` schema + detection helper + gitignore | GREEN | `scripts/lib/tracker-config.sh` + `tracker.toml.example` (root + project-template); 32/32 tests; `tracker_mode()` resolves `flat-file` ↔ `tracker` per `[mode]` + `[migration].forward_complete`. |
| BD-062 — Trinity `## Document locations` Source column | GREEN | Source column present in all three project-template trinity files (verified via `validate-pack.py` Check 18 trinity H2 structure parity = 24 sections matched); explainer paragraph above the table; values per V3.3 §6.3. |
| BD-063 — Issue forms `work-item.yml` + `inbound.yml` (D-4-V2) | GREEN | 4-option `wi-type` dropdown (V3.3 §6.1: bd / td / phase-epic-skeleton / phase-task-skeleton); 7-option `in-category` dropdown (V2 §4.3); pack-root + project-template forms present; 78/78 tests; `validate-pack` Check passes. |
| BD-064 — Template-archive directory bootstrap + bd-v11.0 schemas | GREEN | `maintenance-docs/v11-research/templates-archive/v11.0/` carries INDEX.md + 5 entry-type SCHEMAs (bd, td, phase-epic, phase-task, inbound); forms are byte-equal to pack `.github/ISSUE_TEMPLATE/` (informational); CI green. |
| BD-065 — `tracker-migrate.sh forward` + idempotency + checkpoint | GREEN | V1 §6.2 11-step orchestrator in `scripts/lib/tracker-migrate-forward.sh`; three-marker idempotency probe (title prefix + `pack-id:` body marker + body footer marker via `provider_get`); per-entry mapping save; partial-write surfacing per V1 §9.6; **post-sweep fix:** `_tmf_update_tracker_toml` now writes `forward_complete = true` (lines 1048-1071) so subsequent invocations resolve `tracker_mode = "tracker"`. 111/111 tests. |
| BD-066 — `pack tracker init` + label/template ensure | GREEN | `scripts/lib/tracker-init.sh` + `tracker-labels.sh` + `pack-tracker.sh` dispatcher (init / status / mirror-rebuild / disable / doctor / update-templates / enable-recommendations); 45-label canonical set; surface auto-detection (PACK-CHAT.md vs docs/pack/); `opted_in_at` preservation across re-runs; **post-sweep fix:** prior-state safety rail (lines 65-82) — re-running init with an existing `id-map.json` requires `--force`. 95/95 tests. |
| BD-067 — `tracker-migrate.sh reverse` + sidecar | GREEN | V1 §6.5 9-step reverse orchestrator in `scripts/lib/tracker-migrate-reverse.sh`; per-entry reconstruction (status/type/scope/severity from labels; sections from H2; Blockers from sub-issue parent + comment markers); V1 §6.6 + §6.6.1 sidecar; mirror-header strip via shared `tracker-mirror.sh`; `disable` and `doctor` verbs live; **post-sweep fix #1:** `_tmr_decode_type` (lines 156-174) substitutes the actual `scope:*` / `severity:*` label value into `TODO(<scope>)` / `KNOWN GAP(<severity>)` per v10 grammar with literal-placeholder fallback; **post-sweep fix #2:** `tracker_migrate_reverse_run` (lines 616-628) discovers entries via three `provider_list` label filters (`bd-entry`, `td-entry`, `phase-epic`) before unioning the mapping for recovery. 93/93 tests. |
| BD-068 — Round-trip test fixture + multi-template-version coverage | GREEN | Stateful fake-gh harness (next-id counter + issues map + create-call signature log); bd-v11.0 / bd-v11.1 / bd-v11.2 fixture set; F→R reconstructs entries with status/title/file-symbol/description preserved; F→R→F produces byte-equivalent tracker create-call signature; documented gap on comment-fallback Blockers (BD-111) auto-flips when BD-111 closes; 39/39 tests. |
| BD-069 — `template_version` HTML-comment + label dual carrier (D-18) | GREEN | `scripts/lib/template-version.sh` + `template-translations.sh` lib pair (read body, read label, reconcile, extract-version-dir, archive-path); V2 §19 update-templates verb in `pack-tracker.sh` cmd_update_templates with --dry-run / --apply / --scope / --manifest flags; production manifest empty at v11.0 (no v11.x cuts); synthetic v11.0→v11.1→v12.0 fixture exercises the chain resolver and apply_rules end-to-end; 36+44=80 tests. |
| BD-070 — Typed error surfacing + diagnostic helper | GREEN | `scripts/lib/tracker-errors.sh` formatter covering all 10 V1 §2.5 codes + the additive `not-implemented` code (V3 §27.1 Layer-2 verb table); `tracker_error_emit` produces `ERROR: <code>\nMESSAGE: ...\n<extra>\n→ Run: <verb>` shape with single unambiguous verb per code (V3 §27.1 conformance); back-compat with BD-060/BD-061 first-line ERROR/MESSAGE preserved; 60/60 tests. **F2 (NIT) on header-comment count.** |
| BD-071 — Agent read-pattern adaptation (D-9, V1 §8) | GREEN with **F4 / F5 (NITs)** | V1 §8.4/§8.5 prompt-language change applied to `prompts/tester.md` and `prompts/pm-chat.md` (2 places); 8 other prompt files audited and excluded per the V1 §8.5 narrow rule; `scripts/lib/tracker-agent-read.sh` provides the LCD agent read path (mode-agnostic); **post-sweep:** reviewer.md hygiene check + Required reading line updated to resolver framing; coder.md + auditor.md gained tracker-mode write-prohibition clarifications (consistent with V1 §8.5's "narrow read-context only" framing). **Gaps surfaced:** F4 (pm-startup SKILL.md Step 2) and F5 (PM-CHAT.md tool-specific sections) retain v10 literal phrasing; the BD-071 sweep limited rewrite scope to `prompts/`. 31/31 tests. |

---

## Extension-point soundness

### BD-072 — `scripts/lib/recommendation.sh` + state-file schema (D-19)

- **Extension surface.** Recommendation state file path `.pack-tracker/recommendation-state.json` per V3 §27.3 / §28.1.6.
- **Soundness.** The `.pack-tracker/` directory is reserved (already holds `id-map.json`, `forward.checkpoint.json`, `disable-backup/`, `reverse.sidecar.<date>.md`, `capabilities.json`). The recommendation state file slots in cleanly; its lazy-create path is per-design. `tracker.toml` already has fields for tracker-state coordination.
- **Verdict.** Sound. No regression risk introduced by post-sweep changes.

### BD-073 — `pack tracker enable-recommendations` subcommand

- **Extension surface.** `cmd_enable_recommendations` at `scripts/pack-tracker.sh:337-341` emits `not-implemented` typed error.
- **Soundness.** The verb is reachable via the dispatcher (line 364); the typed error references BD-073 for the body. The full implementation extends the existing function. Layer-2 verb maps `not-implemented` to `pack tracker doctor` (per `tracker-errors.sh:119`).
- **Verdict.** Sound. **F3 (NIT)** on the BACKLOG description self-reference does not affect implementation soundness.

### BD-074 — `pack-startup` Step 8 + `pm-startup` Step 8

- **Extension surface.** `.claude/skills/pack-startup/SKILL.md` exists at pack root (Claude only); `.codex/` and `.gemini/` pack-root skill directories will be introduced for the first time per IMPLEMENTATION-PLAN-ADDENDUM-4 §6.F. Project-template `pm-startup` skill exists.
- **Soundness.** The Step-8 hook layers cleanly atop the existing Step 7 triage queue. Trinity replication × 2 surfaces is a known shape; no architectural conflict surfaced. **F4 (NIT)** notes the existing Step 2 phrasing — separate from BD-074's Step-8 addition.
- **Verdict.** Sound.

### BD-089 — validate-pack.py Check (customization-detection regression guard)

- **Extension surface.** `scripts/validate-pack.py` `check_*` function pattern. Existing checks 1–20 + BD-063 / BD-064 informational checks compose linearly.
- **Soundness.** Adding a new `check_customization_detection_regression_guard` follows the existing pattern. BD-088 (the migrate-v10-to-v11 driver) is the prerequisite; the fixture-driven check will run in CI.
- **Verdict.** Sound.

### BD-106 — Phase task entity model + parser/emitter

- **Extension surface.** Forward step 5 (`tracker-migrate-forward.sh tmf_parse_backlog`) and reverse step 5 (`tracker-migrate-reverse.sh tracker_migrate_reverse_run`) currently parse/emit BD/TD only; phase-task `### Tasks` blocks are not yet handled. The label families `derived-from:` / `promoted-to:` are reserved (V1 §5.3 open-string `link.kind` allows them at provider level; sidecar's `extra_fields` shape accommodates new entry-type fields). The `pack-id` body-marker regex at `tracker-migrate-reverse.sh:644` already recognizes `phase-N` and `phase-N.M` shapes (the regex captures `[A-Za-z]+-\d+(?:\.\d+)?`).
- **Soundness.** Sidecar `phase_tasks` block + per-task `dependency_edges` field per V3.3 §4.3 layer cleanly atop the existing sidecar surface. The reverse roster discovery loop (lines 618-624) iterates over `bd-entry`, `td-entry`, `phase-epic` labels — adding `phase-task` is a one-line extension. No architectural conflict.
- **Verdict.** Sound.

### BD-108 — Cross-entity dependency link orchestration + cycle check

- **Extension surface.** `_tmr_decode_blockers` at `tracker-migrate-reverse.sh:227-259` currently captures `Blocked by #NNN` markers + sub-issue parent. The regex at line 251 (`(?:Blocked by|blocked-by|blocks)[\s:]*#(\d+)`) is `phase-N`-aware via mapping resolution. Phase task `Dependencies` bullet parsing (V3.3 §5.3) is not yet present and lands in BD-108. Forward step 7 (V1 §6.2) creates `blocked-by` links via `provider_link()` (BD-060's API); the additive cases per V3.3 §5.2 use the same call. Cycle check is new but layers atop the existing PM Chat orchestration.
- **Soundness.** No new provider operation needed — V1 §5.3's open-string `link.kind` family already admits the V3.3 §5.2 cross-entity pairs. Bidirectionality contract honored: every legal v10 Blockers form continues to parse.
- **Verdict.** Sound.

### BD-111 — Switch blocks/blocked-by from comment-marker to first-class GH dependency API

- **Extension surface.** `tracker_provider_gh_link()` (in `scripts/lib/tracker-provider-gh.sh`) currently emits comment-based blockers. The public `provider_link()` shape is unchanged; the swap is internal to the GH backend.
- **Soundness.** BD-068 round-trip test (lines 302-322 of `tracker-migrate-roundtrip-test.sh`) is structured to auto-flip from "gap documented" to "BD-001 preserved" when BD-111 lands. The pivot is a fixture path, not an API change. Comment-based markers remain available via `provider_raw()` for callers that want the V3 §28 fallback.
- **Verdict.** Sound. Live-GH-access dependency is correctly captured in BD-111's Blockers field.

---

## Closing line

GO-WITH-FIXES. The post-sweep v11.0 surface (BD-060..BD-071) lands all contracts the architecture and plan documents prescribe: forward + reverse + round-trip + sidecar + dual-carrier + typed errors + agent read path + tracker init + doctor with capability-cache refresh, with 684/684 tests green and validate-pack rc=0. The findings above (F1–F10) are doc / comment / phrasing drift only; none of them block the v11.0 surface from shipping. Extension points for BD-072 / BD-073 / BD-074 / BD-089 / BD-106 / BD-108 / BD-111 remain clean. The fix sweep introduced no regressions (test count grew without failures from pre-sweep through HEAD `27e08d9`). Recommend: address F1 (stale "pending" dispatcher comments), F2 (typed-code count comment), F3 (BD-073 self-reference), and one of F4 or F5 (the V1 §8.5 application gap — pick the canonical scope policy and apply it consistently) before tagging v11.0.
