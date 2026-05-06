# Pack Review — BD-062 / BD-069 / BD-071 + Fix Commit `5854021`

**Reviewer:** pack-reviewer agent
**Date:** 2026-05-05
**Window:** commits `5854021` (BD-066/067/068 review fixes), `ecf3c34` (BD-069), `d836f01` (BD-062), `09b31c2` (BD-071) at HEAD `09b31c2`.
**Predecessor:** `PACK-REVIEW-BD066-068.md` (commit `3470e89`).

---

## Verdict

**GO** — proceed to BD-072.

The four landed commits implement the V1 §3.3 trinity Source column (D-6), the V3.3 §6.5 D-18 dual-carrier read/reconcile + V2 §19 `update-templates` verb, and the V1 §8.1 / §8.4 LCD agent read path with the prompt-language change scoped per V1 §8.5. The fix commit closes BLOCKER #6 cleanly, closes WARNING #2 (surface auto-detect) cleanly, and closes WARNING #4 (state-aware decode) cleanly. No new blockers found. Findings are advisory or carried forward from the predecessor review's deferred set; none gate BD-072.

---

## Findings

### Finding #1 — Production translations manifest file does not exist on disk; verb tolerates this by file-missing → empty array
**Severity:** NIT
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/template-translations.sh:template_translations_load`; `scripts/pack-tracker.sh:template_update_run` (manifest path resolution)
**Contract source:** ARCHITECTURE-V2.md §19.4 ("`maintenance-docs/v11-templates-archive/translations.yaml`: ... The translation manifest is the single source of truth for `pack tracker update-templates`.").
**Observation:** `template_translations_load` treats missing-file the same as empty-list (`[]`), so the verb reports "no upgrades available" gracefully. The spec describes the manifest as a present file with an empty list of transitions, not an absent file. This is a documentation-vs-implementation question — the implementation is harmless either way (the test fixture for "production manifest absent" at template-translations-test.sh 4.2 explicitly asserts the absent-file path emits "no upgrades available"). Spec says the manifest *is* a file; implementation says its absence is equivalent to its emptiness.

---

### Finding #2 — `update-templates` `--apply` exit-without-prompt path bypasses V2 §19.2 step 4 user approval
**Severity:** NIT
**Category:** contract-divergence
**File:Symbol:** `scripts/pack-tracker.sh:template_update_run` (the `if [[ "$apply" != "1" ]]` block is the only approval gate; non-`--apply` non-`--dry-run` invocations stop with the "Re-run with --apply" message).
**Contract source:** ARCHITECTURE-V2.md §19.2 step 4: "Show plan to user. Print the upgrade plan; **prompt for approval** unless `--apply`. With `--dry-run`, exit after printing." V2 §19.5: "Opt-in. `pack tracker update-templates` shows the plan; user approves."
**Observation:** Spec calls for an interactive approval prompt in the default (no-flag) path; implementation prints the plan, then prints "Re-run with --apply" and exits rc=0 without prompting. At v11.0 the manifest is empty so the apply path is no-op, and BD-066 has already established the "interactive dialogue" pattern (commit `c57a249`) for `init` — but `update-templates` does not adopt it. When v11.1 ships and the manifest gains transitions, the default-path UX is "print plan and stop" rather than "print plan and prompt". A future BD will need to add the prompt; flagging now so it doesn't get lost.

---

### Finding #3 — Body-marker reader regex permits a trailing-slash terminator in the captured value
**Severity:** NIT
**Category:** round-trip
**File:Symbol:** `scripts/lib/template-version.sh:template_version_read_body`; mirrored regex at `scripts/pack-tracker.sh:_template_update_read_form_version` and `scripts/lib/tracker-sidecar.sh:_tmsc_emit_entry_section` (template_version body extraction)
**Contract source:** ARCHITECTURE-V3.3-DELTA.md §6.5 D-18 carrier matrix: body marker shape is `<!-- template_version: <entry-type>-v<X.Y> -->`.
**Observation:** The regex in `template_version_read_body` is `<!--\s*template_version:\s*([^\s-]+(?:-[^\s]*)?)\s*-->`. The capture group is "non-space-non-dash followed by optional dash-then-non-space". This works for `bd-v11.0`, `td-v11.0`, `phase-task-v11.2` but accepts only one dash transition; `phase-task-v11.2` is captured as `phase` then `-task-v11.2` because `[^\s]*` is greedy and dash-tolerant. The companion regex in `tracker-sidecar.sh:_tmsc_emit_entry_section` (line 91) uses a simpler `[^\s]+` capture and is more permissive. The sidecar regex matches `phase-task-v11.2` cleanly; the template-version.sh regex also matches but the structural asymmetry between the two extractors is a code-smell. Tests at template-version-test.sh 1.1 cover `phase-task-v11.2` and pass, so observable behavior is identical. Two regexes for the same marker risk drift on future template-version shapes.

---

### Finding #4 — `template_translations_resolve_chain` BFS uses node-level `seen` set; cannot represent two parallel paths to the same target
**Severity:** NIT
**Category:** extension-point-soundness
**File:Symbol:** `scripts/lib/template-translations.sh:template_translations_resolve_chain`
**Contract source:** ARCHITECTURE-V2.md §19.4: "a 2-version-skip (v11.0 → v12.0) chains v11.0→v11.1→v12.0 sequentially."
**Observation:** The BFS marks `seen.add(nxt)` when enqueuing, so the first path that reaches a node wins. For a v11.0 → v12.0 chain that has both `v11.0 → v11.1 → v12.0` and `v11.0 → v11.5 → v12.0` available in the manifest (a hypothetical multi-branch family), the BFS would commit to the first-seen branch. The spec's "sequentially" wording does not address branch-tie-breaking. For v11.0 the manifest has zero transitions; for v11.1+ one transition per pair is the only realistic shape, so this is effectively dead code. Cycle handling is correct: re-encountering an enqueued node skips it, so a manifest cycle does not infinite-loop. Empty-manifest identity (`from==to`) returns `[]` early before the BFS runs. The BFS is correct for the realistic manifest shapes; the branch-tie-breaking observation is theoretical.

---

### Finding #5 — Body-patch `field-renamed` followed by re-applying the same `field-renamed` rule does not roundtrip cleanly
**Severity:** NIT
**Category:** idempotency
**File:Symbol:** `scripts/lib/template-translations.sh:template_translations_apply_rules` (Python block, `field-renamed` branch)
**Contract source:** ARCHITECTURE-V2.md §19.3: "User content is preserved verbatim by section. ... A body patch operates only on the pack-controlled scaffolding."
**Observation:** Apply `{kind: field-renamed, from: Description, to: Summary}` once → heading becomes `## Summary`. Re-apply the same rule on the result → `find_section(body, "Description")` returns `(None, None)` and the rule no-ops. So sequential re-apply is safely idempotent. But: apply the inverse rule `{from: Summary, to: Description}` and you recover the original. The `field-removed` rule is *not* round-trip-recoverable — once the heading becomes `Context (legacy Description)`, no rule reverses it (the chain is forward-only). V2 §19.3 does not require reversibility, so this is observation-only: the system is forward-walking, not bidirectional, by design. Flagging because the V1 §6.0 bidirectionality contract applies to *forward/reverse migration* (flat-file ↔ tracker), not to *template upgrades* (older-template tracker entry → newer-template tracker entry). The two surfaces use the same word "migration" with different semantics; future BDs touching both should keep them distinct.

---

### Finding #6 — `_tmsc_extra_fields_for_entry` extension hook is defined at module bottom; sourced-later libs override correctly, but the hook itself emits the empty-state notice and the sidecar test still asserts it as a literal string
**Severity:** NIT
**Category:** extension-point-soundness / fix-verification
**File:Symbol:** `scripts/lib/tracker-sidecar.sh:_tmsc_extra_fields_for_entry`; `scripts/tests/tracker-migrate-reverse-test.sh` (asserting "empty at v11.0")
**Contract source:** PACK-REVIEW-BD066-068 Finding #7 ride-along expectation.
**Observation:** Finding #7 from the predecessor review is closed: the sidecar's `_tmsc_emit_entry_section` now calls `_tmsc_extra_fields_for_entry "$pack_id" "$issue"` instead of inlining the literal. BD-106 phase-task fields can override by redefining the function after sourcing tracker-sidecar.sh (last definition wins in Bash; this is the correct extension pattern). The hook signature `<pack_id> <issue-json>` is well-shaped for future field-extraction. Two minor sub-observations: (a) the predecessor review's note that "any seam refactor will need a parallel test update" — the test still asserts on the literal `(empty at v11.0; v11.x-only fields populate this section)` per test 4.4, so a BD-106 override would also need a test fixture seam (set the function to emit a phase-task-specific block); (b) the function returns text that the caller then `echo`s a blank line after — the contract is "emit text", not "emit text then newline", which leaves blank-line spacing to the caller. Both BD-106 and any other override BD must understand the caller-side blank-line convention.

---

### Finding #7 — Forward composer (BD-065) writes `template:bd-v11.0` label at create-time; doctor does not yet *compare* the live form's template_version against the entry's label
**Severity:** WARNING
**Category:** BD-072-readiness-gap / contract-divergence (deferred from PACK-REVIEW-BD066-068 Finding #5)
**File:Symbol:** `scripts/tracker-migrate.sh:tracker_doctor_run` (template freshness check)
**Contract source:** ARCHITECTURE-V2.md §22.1 (doctor: "validates template freshness"); §19.6 ("`pack tracker doctor`. Validates the full surface (config, capabilities, mirror freshness, mapping integrity, **template freshness**)").
**Observation:** Doctor's template-freshness check is `[ -d "$repo_root/.github/ISSUE_TEMPLATE" ]` and reports the count of `*.yml` files. It does not call `template_version_read_body` / `template_version_read_label` / `_template_update_read_form_version` against actual entries to compare. BD-069 lands the building blocks (the form-level reader and the label reader), so the wiring exists; the doctor verb just does not consume them yet. BD-069's commit message explicitly defers this as the predecessor's Finding #5: "needs capability-cache freshness + freshness-comparison baselines." This is a known carry-forward; flagging here so it does not silently slip past BD-072 (which lands the recommendation system that may want to read the template-freshness signal).

---

### Finding #8 — Sidecar `reactions`, `attachments`, `audit_log` sections still emit placeholder strings; no extension hook added
**Severity:** WARNING
**Category:** contract-divergence (deferred from PACK-REVIEW-BD066-068 Finding #8)
**File:Symbol:** `scripts/lib/tracker-sidecar.sh:_tmsc_emit_entry_section`
**Contract source:** ARCHITECTURE.md §6.6, §6.6.1.
**Observation:** Where Finding #7 from the predecessor review was closed via the `_tmsc_extra_fields_for_entry` hook, Finding #8 was not. The three sections still emit hard-coded literal strings: `(reactions fetch not implemented at v11.0; future BD-067 ride-along)`, `(attachments fetch not implemented at v11.0; future BD-067 ride-along)`, `(events fetch not implemented at v11.0; the provider_events op is not yet defined)`. BD-069's commit message defers this: "needs real provider_events op + reaction-fetch via gh api." The sidecar architecture has now been opened for one extension point (extra_fields) but not the other three. A future BD that needs all four hooks will need to refactor the sidecar a second time — predictable design debt. The "future BD-067 ride-along" reference in the literal strings is now stale: BD-067 already shipped and BD-069 inherited the comments. This is a documentation drift, not a contract divergence.

---

### Finding #9 — `update-templates` plan output does not annotate which entries are stale relative to which target; user has no per-entry decision basis
**Severity:** NIT
**Category:** contract-divergence
**File:Symbol:** `scripts/pack-tracker.sh:template_update_run` (the plan-output block between lines 289–297)
**Contract source:** ARCHITECTURE-V2.md §19.2 step 3: "Produces a list of `(id, current_template, target_template, body_patch, label_patch)` records." §19.7 step 4: "Pack Chat reports: 1 entry on bd-v11.0, 0 entries on bd-v11.1 (current). Run pack tracker update-templates --dry-run to see plan."
**Observation:** Current plan output names the surface, scope, manifest path, current form versions, and the transitions present in the manifest. It does not yet enumerate per-entry `(id, current_template, target_template)` records. At v11.0 the manifest is empty, so this is structural — the verb correctly returns early on empty-manifest. But when v11.1 ships, the dry-run output will need to walk the mapping file, fetch each entry's template_version (via `template_version_read_body` / `read_label` / `reconcile`), match against the manifest's `from` versions, and emit a per-entry record. The wiring is not there. The verb's --dry-run text says: "When real translation chains exist (v11.1+), this section will name each entry whose template_version is stale and the rule chain that will be applied." That sets the expectation but does not implement it. Acceptable for v11.0; flagging so v11.1 work plans the per-entry walk.

---

### Finding #10 — `tracker_agent_read_entry` flat-file reader bounds entry block by `next ---` *or* `next **X-NNN —` header — but the regex for the next-header bound only matches `**[A-Z]+-[0-9]+`, missing phase-N entries
**Severity:** WARNING
**Category:** BD-072-readiness-gap / contract-divergence
**File:Symbol:** `scripts/lib/tracker-agent-read.sh:_tar_read_entry_flat` (the Python block; the `nxt_hdr` regex `^\*\*[A-Z]+-[0-9]+`)
**Contract source:** V1 §8.1 LCD agent read path; V3.3 §6 phase-task identifiers (`phase-N.M`); ARCHITECTURE.md §3.3 trinity Document locations applies to phase entries too.
**Observation:** The next-header regex `r'^\*\*[A-Z]+-[0-9]+'` matches `**BD-001`, `**TD-010`, but does NOT match `**phase-3` or `**phase-3.2`. If an agent-read flat-file BACKLOG.md has phase-N or phase-N.M entries (which BD-106 will introduce), and the entry block of an immediately-preceding BD entry is bounded only by `**phase-3 —`, the bound is missed and the BD entry's block leaks downward until either `---` or the literal end-of-file. BD-106 lands the phase-task entity model; BD-071's reader would then mis-bound. Now: the entry header regex ALSO assumes `**[A-Z]+-[0-9]+` shape (line 168: `r'^\*\*' + re.escape(pack_id) + r'\s*[—-]\s*.+?\*\*\s*$'`); when called with `pack_id="phase-3.2"`, the `re.escape` handles the literal `.` correctly, so reading a phase entry by id works, but reading a BD/TD entry that is followed by a phase entry will not bound on the phase header. This is a forward gap, not a current-window bug — flat-file mode at v11.0 has no phase-N entries. BD-106 will need to extend this regex.

---

### Finding #11 — `tracker_agent_read_entry` direct-execution exit code does not bubble up the function's typed-error rc
**Severity:** NIT
**Category:** contract-divergence
**File:Symbol:** `scripts/lib/tracker-agent-read.sh` (the trailing direct-exec block at line 190 onward)
**Contract source:** V1 §2.5 typed error model (rc=1 on validation/not-found errors).
**Observation:** The script's direct-exec entrypoint calls `tracker_agent_read_entry "$@"` as the final statement. Bash inherits the function's rc as the script's rc, so missing-pack-id and not-found errors propagate correctly (the test at tracker-agent-read-test.sh 4.3 confirms `rc=1` on missing). The Python heredoc inside `_tar_read_entry_flat` exits with `sys.exit(1)` on not-found and the heredoc is followed by `|| return 1`, so the function returns 1, the script exits 1. Verified. No defect — including this finding to confirm I checked.

---

### Finding #12 — `_template_update_read_form_version` regex is identical to the body-marker regex but without the trailing `-->` requirement on the YAML form file
**Severity:** NIT
**Category:** cross-BD-inconsistency
**File:Symbol:** `scripts/pack-tracker.sh:_template_update_read_form_version` (line 352)
**Contract source:** ARCHITECTURE-V2.md §19.2 step 1: "Read pack version. Look up the pack's current advertised template versions from `project-template/.github/ISSUE_TEMPLATE/`."
**Observation:** The regex `r'<!--\s*template_version:\s*([^\s-]+(?:-[^\s]*)?)\s*-->'` is the same as `template_version_read_body`. But the form YAML embeds the marker inside a `markdown:` block whose `value:` field is YAML-multiline-prefixed (`|`). The regex still matches because YAML multiline-string content preserves the literal `<!-- ... -->` text. Confirmed by test 4.3 in template-translations-test.sh which asserts `work-item=work-item-v11.0`. Cross-BD-inconsistency note: this is the *third* place the same regex pattern lives (here, template-version.sh, and tracker-sidecar.sh inline). The DRY violation is small but BD-069 added the `template_version.sh` library; the verb could call `template_version_read_body` against the form file's text content rather than re-implementing the regex. Library re-use was missed.

---

### Finding #13 — Trinity `## Document locations` Source-column rows are byte-identical across the three files; pack-repo trinity exemption holds
**Severity:** NIT (verification confirmation)
**Category:** fix-verification
**File:Symbol:** `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` (`## Document locations` section); `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at the repo root (no Document locations section)
**Contract source:** ARCHITECTURE.md §3.3; ARCHITECTURE-V3.md D-6 row footnote ("Source column applies to project-template trinity only; pack-repo trinity has no `## Document locations` section.")
**Observation:** Verified the three project-template trinity files contain a byte-identical Source-column explainer paragraph (lines 195–201 / 179–185 / 190–196 respectively, after offset alignment), a byte-identical 4-column header `| Directory | Contents | Updated by | Source |`, and byte-identical row contents for the three rows (`flat`, `flat (or mixed in tracker mode)`, `flat`). Verified the pack-repo trinity files have no `## Document locations` section (grep returned no matches). Trinity rule satisfied. D-6 footnote exemption satisfied.

---

### Finding #14 — BD-071 audit conclusion confirmed: 8 of 10 prompts have no "Read BACKLOG.md" / "Read STATUS.md" pattern
**Severity:** NIT (verification confirmation)
**Category:** fix-verification
**File:Symbol:** `project-template/docs/pack/prompts/{architect,auditor,coder,docs-researcher,grpc-schema,planner,repo-ops,reviewer}.md`
**Contract source:** ARCHITECTURE.md §8.5 (V1): "Replace 'Read BACKLOG.md' with 'Read BACKLOG entries (resolve via trinity Document locations)'."
**Observation:** Re-audited the 8 prompts BD-071 left unmodified. Patterns found: (a) `auditor.md:48` — write-prohibition: "Do not write to BACKLOG.md, STATUS.md"; (b) `coder.md:52,62-63,77,165-166` — write-prohibition + IMPLEMENTATION_PLAN.md mention. None of the 8 has a `Read BACKLOG.md` / `Read STATUS.md` / `Required reading: BACKLOG.md` pattern. The required-reading lines for these 8 prompts reference `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `CHANGELOG.md`, or skill names — never BACKLOG/STATUS. Audit conclusion validated. The IMPLEMENTATION-PLAN.md BD-071 entry (lines 256–278) listed all 10 files as "modified", but the actual landed change scope is correct per V1 §8.5 ("only Read X.md patterns where X ∈ {BACKLOG, STATUS} change") — the plan was over-specified relative to the spec. Worth updating the plan entry's Files list to reflect the 2-of-10 scope, or adding a note that the audit determined 8 needed no edit.

---

### Finding #15 — `template_translations_apply_rules` `field-added` rule appends to body unconditionally; multiple chain hops adding the same field would emit duplicate sections
**Severity:** NIT
**Category:** idempotency
**File:Symbol:** `scripts/lib/template-translations.sh:template_translations_apply_rules` (`field-added` branch)
**Contract source:** ARCHITECTURE-V2.md §19.3.
**Observation:** The `field-added` branch checks `find_section(body, new)` first; if the section already exists, it skips. So idempotent re-apply of the same `field-added` rule is safe. But: if the chain has two `field-added` rules with the same `to` (e.g. v11.0→v11.1 adds `wi-priority`, v11.1→v11.2 also adds `wi-priority` due to a manifest typo or a re-add after an intermediate `field-removed`), the second addition would no-op because the section is already there. The order matters when a chain mixes `field-removed` and `field-added` for the same field name: a v11.0→v11.1 rule chain that does `field-removed wi-priority` then `field-added wi-priority` would (a) rewrite the section heading to `## Context (legacy wi-priority)`, then (b) check `find_section(body, "wi-priority")` and not find it (the heading is now `Context (legacy wi-priority)`), so it would re-add an empty `## wi-priority` section with the TODO marker. The body would then have BOTH `## Context (legacy wi-priority)` (with the user's content) AND `## wi-priority` (empty + TODO). Per §19.3 this is correct — "user content is preserved" means the legacy block is preserved; the new empty block represents the new field. Verified by walking the test fixture's chain (v11.0→v11.1 adds wi-priority; v11.1→v12.0 removes wi-priority + adds wi-impact). The behavior is intentional. Including this finding to document the analysis — no defect.

---

### Finding #16 — Fix commit `5854021` Finding #6 (BLOCKER) is closed correctly: `template_archive_path` derives version_dir per template_version
**Severity:** NIT (verification confirmation)
**Category:** fix-verification
**File:Symbol:** `scripts/lib/tracker-sidecar.sh:_tmsc_emit_entry_section` (lines 99–105); `scripts/lib/template-version.sh:template_version_extract_version_dir` / `template_version_archive_path`
**Contract source:** PACK-REVIEW-BD066-068 Finding #6 BLOCKER.
**Observation:** Walked the path-emission code. The sidecar now uses `version_dir=$(printf '%s' "$template_version" | sed -nE 's/^.*-(v[0-9]+\.[0-9]+)$/\1/p')` to extract the version directory dynamically. For `bd-v11.0` → `v11.0` → `templates-archive/v11.0/bd-v11.0/SCHEMA.md` (existing). For `phase-task-v11.2` → `v11.2` → `templates-archive/v11.2/phase-task-v11.2/SCHEMA.md` (correct future shape). For `inbound-v11.0` → `v11.0` → `templates-archive/v11.0/inbound-v11.0/SCHEMA.md` (existing). The malformed-input path (no `-vX.Y` suffix) emits empty path, sidecar emits `(none)`. Verified test 4.3 in template-version-test.sh checks 5 v11.0 paths against actual files in `maintenance-docs/v11-research/templates-archive/v11.0/`. The fix also extracts the same logic into `template_version.sh` library functions (`extract_version_dir`, `archive_path`) but the sidecar duplicates the regex inline rather than calling the library. DRY violation acknowledged in the inline comment ("addresses Finding #6 from PACK-REVIEW-BD066-068"). Two regex copies for the same operation is mild design debt; behavior is correct. Finding #6 closed.

---

### Finding #17 — Fix commit `5854021` Finding #2 (WARNING) is closed correctly: surface auto-detect with pack fallback in all four orchestrators
**Severity:** NIT (verification confirmation)
**Category:** fix-verification
**File:Symbol:** `scripts/tracker-migrate.sh:tracker_doctor_run` (line 160); `scripts/lib/tracker-migrate-forward.sh:tracker_migrate_forward_run` (line 546); `scripts/lib/tracker-migrate-forward.sh:tracker_migrate_status_report` (line 876); `scripts/lib/tracker-migrate-reverse.sh:tracker_migrate_reverse_run` (line 561); `scripts/lib/tracker-config.sh:tracker_config_auto_surface`
**Contract source:** PACK-REVIEW-BD066-068 Finding #2 WARNING.
**Observation:** Verified the four orchestrators (forward, reverse, status, doctor) call `tracker_config_auto_surface "$repo_root" 2>/dev/null` and fall back to `surface="pack"` when the helper rc=1 (neither PACK-CHAT.md nor docs/pack/ present). The helper itself returns "pack" when `PACK-CHAT.md` exists, "client" when `docs/pack/` exists, validation error when neither. The pack-fallback path preserves test-fixture compatibility (existing fixtures use pack-style root layout without the marker file). Client-side tracker.toml resolution at `<root>/docs/pack/tracker.toml` now works for all V2 §22.1 verbs when run from a working copy with `docs/pack/` present. Finding #2 closed.

---

### Finding #18 — Fix commit `5854021` Finding #4 (WARNING) is closed correctly: `_tmr_decode_status` accepts canonical Issue object and routes by state + state_reason + label
**Severity:** NIT (verification confirmation)
**Category:** fix-verification
**File:Symbol:** `scripts/lib/tracker-migrate-reverse.sh:_tmr_decode_status` (lines 86–143)
**Contract source:** PACK-REVIEW-BD066-068 Finding #4 WARNING.
**Observation:** Walked the function. Input-shape detection: first non-whitespace char `[` → array shape (legacy labels-only); otherwise → object shape (canonical Issue). For object shape: reads `.state`, `.state_reason`, and the first `status:*` label. Decode table: `closed + completed → Resolved`; `closed + not_planned/duplicate → Cancelled` (or `Deprecated` if `status:deprecated` label present); `closed + unknown reason → Resolved` (safe default); `open + status:unblocked → Unblocked`; `open + (other/none) → Open`. The classification matches V3.3 §6.3 mapping. Test fixture test-suite Group 1.1b covers the canonical-state path with 5 tests; total tracker-migrate-reverse goes from 65 → 70. The legacy array-shape path is preserved for existing labels-only fixtures (Group 1). Finding #4 closed. Note: `state_reason=duplicate` is mapped to `Cancelled`. V3.3 §6.3 lists `not_planned` → Cancelled but does not enumerate `duplicate` separately; the implementation treats them equivalently. Spec is silent on `duplicate`; the implementation choice is reasonable but undocumented in V3.3.

---

### Finding #19 — `tracker-agent-read.sh` `Source: tracker (gh #N, state=...)` annotation uses raw GH state casing (`OPEN`/`CLOSED`); flat-file annotation uses lowercase `flat-file`; cross-mode annotation casing is inconsistent
**Severity:** NIT
**Category:** cross-BD-inconsistency
**File:Symbol:** `scripts/lib/tracker-agent-read.sh:_tar_read_entry_tracker` (line 138 `state=$status`); `_tar_read_entry_flat` (line 179 `Source: flat-file`)
**Contract source:** ARCHITECTURE.md §8.1.
**Observation:** Tracker-mode emits `Source: tracker (gh #42, state=OPEN)` because gh API returns state in upper-case (`OPEN` / `CLOSED`); the canonical Issue shape per V1 §2.2 specifies lowercase per provider-normalization, but the test fake gh in tracker-agent-read-test.sh emits `"state":"OPEN"` and the function reads it as-is via `jq -r '.state // "open"'`. The flat-file mode emits `Source: flat-file (BACKLOG.md)`. Two annotations, two casing conventions for the state field. Agents reading the output would see different state casings depending on mode. Minor — the annotation is human-readable rather than parsed downstream — but worth aligning to lowercase per the canonical-Issue contract.

---

### Finding #20 — `BACKLOG.md` BD-069 entry references "BD-067 ride-along" placeholder strings in sidecar comments — but the placeholders still say "BD-067 ride-along"
**Severity:** NIT
**Category:** cross-BD-inconsistency
**File:Symbol:** `scripts/lib/tracker-sidecar.sh` lines 135 and 142 (the placeholder strings reference "future BD-067 ride-along"); `BACKLOG.md` BD-069 Resolved line
**Contract source:** N/A (consistency between code comments and BACKLOG history).
**Observation:** BD-067 has shipped (commit `9328d0d`), BD-069 has shipped (commit `ecf3c34`), and the sidecar's reactions/attachments placeholder strings still say "future BD-067 ride-along." The intended ride-along did not happen in BD-067 or BD-069. The comments are now historical-stale: there is no future BD-067; the work is now an unscheduled gap (covered by Finding #8). Recommend updating the placeholder strings in a future commit to point at the next-BD-that-implements-them, or flatly to "TBD." Including for completeness; not a defect.

---

## Verification matrix

| Item | Sections checked | Outcome |
|---|---|---|
| BD-062 trinity Source column | V1 §3.3 (table shape); V3 D-6 row + footnote (project-template-only) | Trinity-replicated byte-identically across CLAUDE.md / AGENTS.md / GEMINI.md; pack-repo trinity exempt; explainer paragraph above table; "flat (or mixed in tracker mode)" wording for docs/project/ row aligns with §3.3. PASS. |
| BD-069 D-18 dual-carrier reader | V3.3 §6.5 D-18 carrier matrix; V2 §26 reconcile policy | `template_version_read_body` + `template_version_read_label` + `template_version_reconcile` cover all four combinations (both agree / both empty / body-only / label-only / mismatch). Mismatch error names both versions and points at `update-templates`. Label reader handles both string-array and object-array shapes. PASS. |
| BD-069 V2 §19.4 chain resolver | V2 §19.4 "2-version-skip chains sequentially" | BFS handles identity / single-hop / multi-hop / no-chain / empty-manifest. Cycle-safe via `seen` set. Ordering: first-path-wins on multi-branch (Finding #4 — theoretical only). PASS for realistic shapes. |
| BD-069 V2 §19.3 patch semantics | V2 §19.3 (field-renamed / field-added / field-removed / label-renamed) | All four kinds implemented; user content preserved; `re.escape` handles regex metacharacters in heading names. `field-renamed` re-apply is idempotent; `field-removed` is forward-only by design. PASS. |
| BD-069 `pack tracker update-templates` verb | V2 §19.2 5-step; flag set `--apply` / `--dry-run` / `--scope` / `--manifest` | Flags match spec; scope filter validates `all\|bd\|td\|inbound`; manifest path is the test seam; production manifest absent → "no upgrades available." Plan output is informative for the v11.0 case but lacks per-entry `(id, current, target)` enumeration spec'd in §19.2 step 3 (Finding #9 — deferred to v11.1 work). PASS for v11.0; PARTIAL for v11.1+ readiness. |
| BD-071 prompt-language change | V1 §8.4 / §8.5 (resolver-aware language; only "Read X.md" patterns where X ∈ {BACKLOG, STATUS}) | tester.md and pm-chat.md (×2 places) updated; 8 other prompts re-audited with no `Read BACKLOG.md` / `Read STATUS.md` / `Required reading: BACKLOG.md` patterns. Audit conclusion confirmed (Finding #14). PASS. |
| BD-071 LCD agent read path | V1 §8.1 (mode-agnostic surface; flat-file or tracker); D-9 | `tracker-agent-read.sh` is sourceable + direct-executable; mode-detection via `tracker_config_auto_surface` + `tracker_mode`; flat-file reader bounds entry block by `next ---` or `next **X-NNN —` header (Finding #10 — phase-N forward gap). Both surfaces emit `Source: <mode>` annotation (Finding #19 — casing inconsistency). PASS for v11.0; gap for BD-106 phase entries. |
| Fix commit Finding #6 (BLOCKER) | V1 §6.6.1 (DELTA A2 — `template_archive_path` deterministic re-hydrate); V3.3 §6.5 archive layout | `template_version_extract_version_dir` correctly maps `bd-v11.0`→`v11.0`, `phase-task-v11.2`→`v11.2`. Sidecar uses inline regex (DRY violation, behavior identical). Test 4.3 in template-version-test.sh asserts the path resolves to existing files for all 5 v11.0 entry-types. CLOSED. |
| Fix commit Finding #2 (WARNING) | V1 §3.4 independence axes (surface = pack vs client) | Forward / reverse / status / doctor all call `tracker_config_auto_surface` with pack-fallback; helper auto-detects via PACK-CHAT.md (pack) / docs/pack/ (client) / validation error (neither). CLOSED. |
| Fix commit Finding #4 (WARNING) | V3.3 §6.3 mapping (state + state_reason → status); manual-close issues | `_tmr_decode_status` accepts both array (legacy) and object (canonical Issue) input shapes. Closed-with-completed → Resolved; closed-with-not_planned/duplicate → Cancelled (or Deprecated with status:deprecated label); open paths preserved. CLOSED. |

---

## Closing summary

### (i) BD-072 readiness

BD-072 will land `scripts/lib/recommendation.sh` + state-file schema for V3 §28.1 inflection-point recommendation. **Inherited cleanly:**

- Typed-error formatter (`tracker_error_emit`) — BD-070, ready.
- `tracker_config_*` helpers including auto-surface — BD-061 + fix-commit `5854021` Finding #2, ready.
- Mapping-file reader / pack-id resolution — BD-065 / BD-067, ready.
- Mode detection (`tracker_mode` + `tracker_agent_read_mode`) — BD-061 + BD-071, ready.
- Template-version reader (entry counts by template_version) — BD-069, ready.
- Entry-block reader for flat-file mode (`tracker_agent_read_entry`) — BD-071, ready.

**Gaps that BD-072 will need to fill itself:**

- A "freshness" baseline for mirror staleness comparison (Finding #7 — predecessor's #5 still deferred). Doctor's mirror check is presence-based, not mtime-based; the recommendation system may need its own mtime probe.
- Template-freshness comparison (compare in-tree form's template_version against entry-label set). The pieces exist (`template_version_read_label` + `_template_update_read_form_version`); they just need to be composed.
- Per-entry walk against the mapping file. Pattern is established in BD-067's reverse migration (`while IFS= read -r pack_id; do ... done < <(printf '%s' "$mapping" | jq -r 'keys[]')`); BD-072 can copy.

No blocker. **GO** for BD-072.

### (ii) Cumulative state of deferred findings from PACK-REVIEW-BD066-068

Tracking the 20 findings by current status:

| # | Severity | Status |
|---|---|---|
| 1 | WARNING | DEFERRED — interpretation question (BD-063 ships templates with the pack; init verify-only is reasonable) |
| 2 | WARNING | **CLOSED** in fix commit `5854021` (Finding #17 verifies) |
| 3 | WARNING | DEFERRED — design needed; dedicated commit later |
| 4 | WARNING | **CLOSED** in fix commit `5854021` (Finding #18 verifies) |
| 5 | WARNING | DEFERRED to BD-069; **deferred again** in BD-069 (still open per current Finding #7) |
| 6 | BLOCKER | **CLOSED** in fix commit `5854021` (Finding #16 verifies) |
| 7 | WARNING | **CLOSED** in BD-069 (Finding #6 verifies) |
| 8 | WARNING | DEFERRED to BD-069; **deferred again** in BD-069 (still open per current Finding #8) |
| 9 | NIT | DEFERRED — V3 §27.1 verb-naming; informal track |
| 10 | NIT | DEFERRED — informal track |
| 11 | NIT | DEFERRED — informal track |
| 12 | NIT | DEFERRED — sidecar date stability; informal track |
| 13 | NIT | DEFERRED — informal track |
| 14 | NIT | DEFERRED — informal track |
| 15 | NIT | DEFERRED — informal track |
| 16 | NIT | DEFERRED — mirror header strip; informal track |
| 17 | NIT | DEFERRED — pack/client template dir; informal track |
| 18 | NIT | DEFERRED — STATUS.md reverse-overwrite; informal track |
| 19 | NIT | DEFERRED — labels summary; informal track |
| 20 | NIT | DEFERRED — verb-table not-implemented surface; informal track |

**Net state:** 1 BLOCKER closed (#6); 2 WARNINGs closed (#2, #4); 1 WARNING closed (#7 in BD-069); 2 WARNINGs explicitly deferred again in BD-069 commit (#5, #8); 13 NITs and 1 WARNING (#3) and 1 WARNING (#1) accumulating as informal technical debt. Of these, #5 (doctor capability/freshness) is mentioned as a BD-072-relevant gap; #8 (sidecar reactions/attachments/audit_log) is a future provider-ops issue. Both are visible in the present review (Findings #7, #8). The cumulative deferred-finding burden is moderate but trending up — recommend BD-080 or BD-089 sweep these as a focused commit before v11.0 ships.

### (iii) Extension-point soundness for BD-074 / BD-106 / BD-089

- **BD-074** (`pack-startup` / `pm-startup` Step 8 reads trinity Source column + `tracker-agent-read.sh`): **READY**. Trinity Source column is byte-identical and well-formed across the three project-template trinity files; the explainer paragraph names `pm-startup Step 2` as the consumer. `tracker-agent-read.sh` exposes both a sourceable function (`tracker_agent_read_entry`) and a direct-execution surface (`bash scripts/lib/tracker-agent-read.sh BD-001`). The skill files just need to wire the read; the building blocks are in place.

- **BD-106** (phase-task fields populate sidecar's new `extra_fields` hook): **READY** with one caveat. The `_tmsc_extra_fields_for_entry` extension hook accepts `<pack_id> <issue-json>` and emits text; BD-106 redefines the function after sourcing `tracker-sidecar.sh`. Caveat: Finding #10 — the flat-file reader's next-header bounding regex `^\*\*[A-Z]+-[0-9]+` does not match `phase-N` / `phase-N.M` headers, so when BD-106 introduces phase entries to flat-file BACKLOG.md, BD entries adjacent to phase entries will not bound correctly. BD-106 must extend the regex.

- **BD-089** (validate-pack regression guard for customization detection): **NOT YET TOUCHED** by this review window. BD-089 is the final pre-release validation; the building blocks it will need (typed errors, mode detection, mapping integrity) are all in place from BD-060 through BD-071. No specific gaps observed.

---

## Closing line

**GO — proceed to BD-072.**

