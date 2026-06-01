# ARCHITECTURE-BD-195-REMEDIATION-STRATEGY

**Status:** Step-7 remediation strategy (fresh pack-architect). Design-only;
no edits to source, no git state changes.
**Branch:** `v11-dev`. **HEAD:** `3178fa4` (`3178fa4f666326ac3eac26238b6e96ad25b60f71`).
**Trusted basis:** `BD-195-CLEAN-FOUNDATION.md` (K1–K7, principles, JC-1..JC-7)
+ `AUDIT-BD-195-VERIFIED-FINDINGS.md` (67 confirmed, 1 FP).
**Grounding:** every finding re-read at `file:line` at HEAD `3178fa4`
(distrust-derived-claims). The per-finding mapping below records the
ground-truth confirmation inline; the Empirical-Evidence Blocks at the end
carry the verbatim command output for the load-bearing state-claims.

**Bounded revision (2026-06-01, fresh pack-architect, HEAD `3178fa4`):** applied
exactly the defects the adversarial review
(`ARCHITECTURE-BD-195-REMEDIATION-STRATEGY-CHALLENGE.md`) identified; the spine
(67-finding mapping, JC-rulings consistency, the new `.mcp.json.example` leak,
the 9-commit DAG, the Check-36 keyword assignments) was CONFIRMED sound and is
untouched. Changes: (1) §2.2 JC-2 allowlist RE-MEASURED — the genuine KEEP set
is the two proto self-imports only; the `README.md:13/38/44` lines were
re-measured to `project-template/README.md` and are NOT a standalone allowlist
KEEP (they fold into the C3 JC-3 README rework) — see EEB-8; (2) NUD-1 RE-FRAMED
from the false A-vs-B dichotomy to the real decision (reclassify K1.11–K1.14
NOT-A-DEFECT vs retain-as-contamination), with the strip locus stated as settled
(§2.1 + §4 NUD-1); (3) four minors folded — C7 manifest verdict, C2/C3 red-CI
window, JC-1 error-guard target-position binding, K4.4 recipe pin.

## 0 — How to read this doc

- **§1** maps all 67 findings → fix approach. Each is flagged
  `RULING-BACKED` (JC-disposition applies), `CLEAR-FIX` (fix follows
  unambiguously from the foundation kind/principle), or
  `NEEDS-USER-DISPOSITION` (more than one defensible disposition / a
  boundary call — framed, not decided).
- **§2** designs the guards via the 5-step measure-then-bound contract
  (JC-1 phase-task `BD-` strip + error-guard; JC-2 client-surface leak-guard
  broadening; JC-5 soft-advisory removed-doc guard).
- **§3** segments the fixes into a commit sequence (scope, files,
  scope-keyword, verification, manifest-regen, per-commit gate).
- **§4** consolidates the NEEDS-USER-DISPOSITION items for the user to rule.
- **§5/§6** Empirical-Evidence Blocks + Rules-Applied Verification Block.

**Tally (per-finding, one disposition each, sums to 67):** RULING-BACKED
**20** · CLEAR-FIX **24** · NEEDS-USER-DISPOSITION **23**. The 23
NEEDS-USER-DISPOSITION *findings* collapse into **9 decision-groups**
(NUD-1..NUD-9 in §4) — most are clusters that share one ruling (e.g. the
6 per-entry-path findings B.5-B.10 = NUD-8; the 4 shared-link-validator
findings K1.11-K1.14 = NUD-1; the 5 PM-only README-layout findings = NUD-4).
So the user faces **9 decisions**, not 23. (Per-kind disposition in the §1
tables.)

**Source-of-truth note (load-bearing for the K3 BACKLOG findings):** the
pack-self per-entry trees `/backlog/` and `/changelog/` do NOT exist at HEAD
`3178fa4` (they are created at Batch 23 / BD-102 dog-food — confirmed
`ls backlog/ → No such file or directory`). Therefore at HEAD the mirrors
`pack-ops/BACKLOG.md` and `pack-ops/CHANGELOG.md` ARE the current edit
target for those surfaces; there is no per-entry source to edit instead.

---

## 1 — Per-finding fix mapping (all 67)

### K1 — pack-self-token-in-project-entity-grammar (14) — ALL ruling JC-1

The 14 K1 findings + the 1 K7 finding form ONE contamination cluster (the
`BD-` admission into the project phase-task dependency grammar and its
encoding surfaces). JC-1 governs all of them. The fix is the JC-1 guard
design in §2.1 — applied in lock-step across all encoding surfaces
(enumerate-encoding-surfaces). Per-finding disposition:

| ID | file:line | Surface role | Disposition (JC-1) |
|---|---|---|---|
| K1.1 | `scripts/lib/tracker-phase-task.sh:132` | bash dep-grammar ERE (`tracker_phase_task_dependency_re`) | RULING-BACKED — strip `BD-[0-9]+` alternation arm; §2.1 |
| K1.2 | `scripts/lib/tracker-phase-task.sh:208` | internal Python `DEP_ENTRY` regex | RULING-BACKED — strip `BD-\d+` arm in lock-step with K1.1; §2.1 |
| K1.3 | `scripts/lib/tracker-phase-task.sh:75` | public-API docstring | RULING-BACKED — drop `BD-\d+` from the documented grammar |
| K1.4 | `scripts/lib/tracker-phase-task.sh:113` | capture-group docstring | RULING-BACKED — drop `BD-N` from group-1 doc |
| K1.5 | `scripts/lib/tracker-promote.sh:1155` | Path-2 phase-task promotion dispatch-guard | RULING-BACKED — strip `BD-[0-9]+` from the phase-task dispatch regex so a TD-blocker `BD-` never flows INTO a phase-task Dependencies edge; §2.1 (see §4 NUD-1 for the shared-validator boundary the guard must NOT cross) |
| K1.6 | `scripts/lib/tracker-promote.sh:390` | emit-comment documenting `BD-NNN` in emitted phase-task Dependencies | RULING-BACKED — rewrite comment: phase-task Dependencies emit `phase-N(.M)`/`TD-NNN` only; `BD-` blockers are dropped at the phase-task seam (deliverable-only cleanliness corollary) |
| K1.7 | `scripts/tests/fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md:26` | fixture input (`- BD-108` dep bullet) | RULING-BACKED — remove the `BD-108` Dependencies bullet from the fixture; the fixture is a project IMPLEMENTATION-PLAN, which must be clean |
| K1.8 | `scripts/tests/test-tracker-phase-task.sh:113` | test asserting grammar names `BD-[0-9]+` | RULING-BACKED — flip to assert the grammar does NOT name `BD-` (and asserts the error-guard fires); §2.1 |
| K1.9 | `scripts/tests/test-tracker-phase-task.sh:132` | parser-input sample `- BD-108 ...` | RULING-BACKED — replace with a `TD-`/`phase-` sample; add a `BD-` sample to a NEW error-guard rejection test |
| K1.10 | `scripts/tests/test-tracker-phase-task.sh:204-205` | test asserting parser captures `BD-108` as dep target | RULING-BACKED — flip to assert `BD-` is rejected at parse (error-guard), not captured |
| K1.11 | `scripts/tests/test-tracker-links.sh:106` | test asserting `validate_id_shapes` accepts `BD-108` | NEEDS-USER-DISPOSITION — asserts the SHARED link-shape validator, which the fixed strip locus leaves intact; the user decision is reclassify NOT-A-DEFECT vs retain-as-contamination (§4 NUD-1) |
| K1.12 | `scripts/tests/test-tracker-links.sh:169` | test creating `blocked-by` with `BD-108` target | NEEDS-USER-DISPOSITION — same shared LINK layer (intact under the fixed strip locus); reclassify-vs-retain decision (§4 NUD-1) |
| K1.13 | `scripts/tests/test-tracker-cycle-check.sh:168` | cycle-check store seeded with `BD-110,BD-108` | NEEDS-USER-DISPOSITION — same shared LINK/cycle layer (intact); reclassify-vs-retain decision (§4 NUD-1) |
| K1.14 | `scripts/tests/fixtures/tracker-links/id-map.json:5-6` | id-map fixture with `BD-108`/`BD-110` nodes | NEEDS-USER-DISPOSITION — fixture for the shared LINK layer (intact); reclassify-vs-retain decision (§4 NUD-1) |

**Why K1.11–K1.14 are NUD, not RULING-BACKED:** grounded at HEAD,
`tracker_links_validate_id_shapes` / `_tlk_is_valid_pack_id`
(`scripts/lib/tracker-links.sh:148` / `:285`) is a SHARED link-orchestration
vocabulary validator (V3.3 §5.1) that explicitly accepts `TD-NNN ←→ BD-NNN`
cross-namespace links. It is called by BOTH the phase-task promotion path
(`tracker-promote.sh:1155`, JC-1 target) AND the entry-level Blockers path
(`tracker-migrate-forward.sh:990`, `BD-*|TD-*` arm) that JC-1 EXPLICITLY
leaves untouched. K1.11–K1.14 test the SHARED validator and the LINK grammar,
not the phase-task `DEP_ENTRY` grammar. Per §2.1, the strip locus is fixed
(strip the phase-task grammar + dispatch-guard; leave the shared validator
intact — JC-1's own-backlog clause forbids touching it). So K1.11–K1.14 test a
LEGITIMATE own-backlog/cross-namespace feature under the only JC-1-consistent
fix. The open question is NOT "where to strip" (settled) but whether these four
findings are formally RECLASSIFIED NOT-A-DEFECT (they exercise the intact link
layer) or RETAINED as contamination → §4 NUD-1.

### K7 — surface-blind-union-grammar-in-dual-surface-validator (1) — ruling JC-1

| ID | file:line | Disposition |
|---|---|---|
| K7.1 | `scripts/tests/test-tracker-phase-task.sh:149` | RULING-BACKED — inline Python `DEP` regex in the bash-vs-Python parity test; strip `BD-\d+` arm in lock-step with K1.1/K1.2 so the parity test compares the corrected grammar; §2.1 |

### K2 — pack-self-ref-on-client-shipped-surface (2)

| ID | file:line | Disposition |
|---|---|---|
| K2.1 | `project-template/skills/pm-startup/SKILL.md:174` (+ identical `.claude/`/`.codex/` copies) | CLEAR-FIX — the cite `supporting-docs/METHODOLOGY.md` on a client-shipped skill names a pack-only dir absent at client. METHODOLOGY ships to `docs/pack/METHODOLOGY.md` (init-project.sh `_CLIENT_INSTALLED_FILES` line 1186). Fix: rewrite to the client-resolvable path `docs/pack/METHODOLOGY.md`. Apply identically across all three copies (trinity-of-copies). Caught by the JC-2 broadened guard (§2.2) — `supporting-docs/` prefix flagged even when the basename happens to be installed elsewhere. |
| K2.2 | `project-template/scripts/bootstrap.sh:46-49` (primary), `:51` | NEEDS-USER-DISPOSITION — a client-gated comment names multiple pack-internal artifacts (`in the pack repo`, `supporting-docs/SETUP-NEW.md`, `init-project.sh`, `migration guide`). The leak is categorical (directory-based). But the correct REWRITE is a judgment call: (a) strip the whole skills-distribution explainer (the client does not re-run init-project.sh), or (b) re-point to the client-resolvable migration surface (`docs/pack/` migration note). Framed in §4 NUD-2. |

### K3 — dangling-reference-to-removed-or-superseded-doc (13)

| ID | file:line | Disposition |
|---|---|---|
| K3.1 | `scripts/lib/tracker-migrate-forward.sh:238` | CLEAR-FIX — cites `ARCHITECTURE-V3.2-DELTA.md` (ABSENT at HEAD; confirmed). The co-cited `ARCHITECTURE-V3.3-DELTA.md` EXISTS and carries the content forward. Fix: drop the dangling V3.2-DELTA basename; keep the V3.3-DELTA cite. |
| K3.2 | `scripts/lib/tracker-phase-task.sh:78-79` | CLEAR-FIX — same dangling `ARCHITECTURE-V3.2-DELTA.md` basename in the Reference comment; V3.3-DELTA resolves. Fix: drop the V3.2-DELTA basename + its `§4.1, §4.2, §4.3` clause. |
| K3.3 | `pack-ops/BACKLOG.md:3135` | NEEDS-USER-DISPOSITION — the LIVE BD-195 entry (Status: Open) cites three DELETED-set docs (`AUDIT-BD-195-REFRESH-POST-BD196.md`, `ARCHITECTURE-BD-195-SEGMENTATION.md`, `ARCHITECTURE-BD-195-RESCOPE.md`) as authoritative inputs to in-progress work. This is PM-only content and it is the BD-195 entry itself — editing it mid-remediation must be a Pack-Chat/user decision (what replaces the superseded segmentation narrative). §4 NUD-3. |
| K3.4 | `pack-ops/BACKLOG.md:3137` | NEEDS-USER-DISPOSITION — same BD-195 entry "Segments" subsection attributes its S0–S4 structure to the deleted `ARCHITECTURE-BD-195-SEGMENTATION.md`. PM-only; bundle with NUD-3. |
| K3.5 | `pack-ops/BACKLOG.md:3168` | NEEDS-USER-DISPOSITION — same BD-195 entry Step 9 cites deleted `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md`. PM-only; bundle with NUD-3. |
| K3.6 | `supporting-docs/SETUP-EXISTING.md:12, 18` | CLEAR-FIX — twice routes the reader to `MIGRATION-v9-to-v10.md` (ABSENT at HEAD; sunset in v11 per BD-121) with NO historical framing, AND is stale (v9.3→v10 routing on a v11 pack). Fix: re-point to `MIGRATION-v10-to-v11.md` + the `git checkout v10 -- ...` recovery framing used correctly by INSTALL-PROCEDURES.md; de-version v9.3→v10 to the v11 baseline. (K5 currency component folds in.) |
| K3.7 | `QUICKSTART.md:34` | CLEAR-FIX — live hyperlink to `supporting-docs/MIGRATION-v9-to-v10.md` (ABSENT). README:156 already states the v9→v10 guide was sunset. Fix: replace the dead hyperlink with the README sunset note + `git checkout v10` recovery recipe (no live link to a deleted file). |
| K3.8 | `README.md:163` | NEEDS-USER-DISPOSITION — Repository-Layout map lists `maintenance-docs/GEMINI-CLI-ANALYSIS.md` as present (ABSENT). README version table is PM-only AND the layout map is the pack's authoritative structure reference. Removing the row vs. relocating-note is a PM call. §4 NUD-4. |
| K3.9 | `README.md:164` | NEEDS-USER-DISPOSITION — same map lists `maintenance-docs/ANDROID-ANALYSIS.md` (ABSENT). PM-only; bundle with NUD-4. |
| K3.10 | `README.md:170` | NEEDS-USER-DISPOSITION — archive listing names `V10-PREDESIGN.md` (ABSENT); sibling `V10-DESIGN-PROCESS-PLAN.md` EXISTS. PM-only; bundle with NUD-4 (strip only the dangling token). |
| K3.11 | `maintenance-docs/TOOL-COMPARISON.md:5-6, 217-218, 220-221` | CLEAR-FIX — a self-declared "living/authoritative reference" asserts `GEMINI-CLI-ANALYSIS.md`/`ANDROID-ANALYSIS.md` "remain in the repo" (both ABSENT) via a LIVE present-tense directive (JC-5's history carve-out does NOT cover live directives). Fix: remove the L217-221 "Deprecated analysis documents" block + the L5-6 supersession banner (the content was absorbed here; the source files are gone). Secondary L6 `V9-DESIGN.md` now at `maintenance-docs/archive/` — re-point. |
| K3.12 | `pack-ops/CHANGELOG.md:451, 481-482, 562, 564` | RULING-BACKED (JC-5) — accurate v8/v9 history; lines 562/564 explicitly ruled NOT hand-corrected. NO content edit. The ONLY output is the §2.3 soft-advisory guard. |
| K3.13 | `pack-ops/BACKLOG.md:3061, 3690, 4169, 4284, 4300, 4302, 4304` | RULING-BACKED (JC-5-class) — historical/process narrative within BD entries (`ARCHITECTURE-BD-185.md`/`PLAN-BD-185.md`, `GEMINI-CLI-ANALYSIS.md`/`ANDROID-ANALYSIS.md`, `V10-PREDESIGN.md`). Treated as JC-5-class accurate history; NO hand-correction; covered by the §2.3 soft-advisory guard. (Foundation flags deep FIX-vs-history disposition as a separate deep-scan; not re-opened here.) |

### K4 — client-shipped-dead-pack-doc-reference (5)

| ID | file:line | Disposition |
|---|---|---|
| K4.1 | `project-template/README.md:9` | RULING-BACKED (JC-3) — client-shipped README cites `V10-DESIGN.md` (pack-only at `maintenance-docs/archive/`). JC-3: strip the V10-DESIGN.md ref. Fix: state METHODOLOGY ships to `docs/pack/` without citing the pack-only design record. |
| K4.2 | `project-template/.codex/config.toml.example:13` | RULING-BACKED (JC-2) — `.example` client-gated file cites `V10-CODEX-MCP-RESEARCH.md` (pack-only) AND `commit 73d480e` (SHA-as-provenance). JC-2 names both shapes + scanning `.example`. Fix: drop the pack-only research-doc + SHA provenance; keep the factual MCP-config prose. Caught by the JC-2 broadened guard (§2.2: `.example` ext + bare-prose). |
| K4.3 | `project-template/.gemini/commands/pm-startup.toml:171` | CLEAR-FIX — same `supporting-docs/METHODOLOGY.md` leak as K2.1, Gemini command surface. Fix: re-point to `docs/pack/METHODOLOGY.md`. (Parallels K2.1 across the pm-startup family; mind cross-CLI reference normalization.) |
| K4.4 | `project-template/docs/pack/PM-CHAT.md:530` | CLEAR-FIX — the UN-gated PRIMARY path `docs/pack/MERGE-STRATEGY.md` does not resolve at client (MERGE-STRATEGY exists only at `pack-ops/`; confirmed at HEAD `3178fa4` — PM-CHAT.md:526-534 shows the primary cite at :528-530 and a correctly DENY-LIST-fenced `(or pack-ops/MERGE-STRATEGY.md in the pack repo)` fallback at :531-534). **Pinned recipe (one, not two):** there is NO project-side SSOT doc for the forward-migration customization-preservation behavior (the behavior lives in the migrator + the pack-ops MERGE-STRATEGY.md), so DROP the dead primary `docs/pack/MERGE-STRATEGY.md` cite and KEEP the existing fenced `pack-ops/MERGE-STRATEGY.md` fallback as the sole, correctly-anchored reference. (The "point at a project-side SSOT" sub-option is foreclosed — no such SSOT exists.) |
| K4.5 | `project-template/docs/pack/OPTIONAL-FEATURES.md:174` | CLEAR-FIX — bare `MERGE-STRATEGY.md` "in the pack repo" (currently anchor-EXEMPT in Check 43, but still a dead pointer for a client who has no pack repo). Fix: keep the "in the pack repo" framing only if the cite is genuinely a pack-as-product pointer; else drop. Recommend: retain with explicit "(pack maintainers only)" qualifier so the client reader is not sent to a doc they cannot open. See §2.2 for why anchor-exempt ≠ clean. |

### K5 — version-currency-staleness (15)

| ID | file:line | Disposition |
|---|---|---|
| K5.1 | `project-template/README.md:1` | RULING-BACKED (JC-3) — title "v10". JC-3: de-version v10→v11. |
| K5.2 | `project-template/.codex/config.toml.example:16` | CLEAR-FIX — "v10 ships STDIO only". Fix: "v11" (or version-neutral "the pack ships STDIO only"); prefer version-neutral to avoid recurring currency churn. |
| K5.3 | `project-template/.gemini/commands/pm-startup.toml:125` | RULING-BACKED (JC-6) — "manifest in v10". JC-6: version-neutral the RAG-manifest label across the pm-startup triad (Gemini variant). |
| K5.4 | `project-template/skills/pm-startup/SKILL.md:128` (+ `.claude/`/`.codex/` copies) | RULING-BACKED (JC-6) — same "in v10" RAG-manifest label. JC-6: version-neutral across the triad; apply identically to all three copies. |
| K5.5 | `project-template/docs/pack/HELP-FRAGMENT.md:14` | CLEAR-FIX — verb manifest headlines `migrate-v9-to-v10.sh`; current migrator is `migrate-v10-to-v11.sh`. Fix: headline the v10→v11 migrator; note v9→v10 sunset. |
| K5.6 | `project-template/docs/pack/prompts/pm-chat.md:35` | CLEAR-FIX — kickoff template seeds "Pack version: v10". Fix: "v11". |
| K5.7 | `project-template/docs/pack/PACK-FEEDBACK.md:40,163,297,313,331,337,352,358,359,372,378,389,395,414,420,436,439` | NEEDS-USER-DISPOSITION — pervasive `v9` seed content in a FRESH v11 template. Distinct from JC-5 history. But the correct fix is a judgment call: blanket v9→v11 token swap risks corrupting example narrative ("after the v9 split, auditor-ui covers only ..." is illustrative prose, not a version label). §4 NUD-5. |
| K5.8 | `xcode-companion-templates/README.md:24` | CLEAR-FIX — "mirror the v9 project-level policy" is a LIVE parity claim (not history). Fix: "v11" (or version-neutral "the current project-level policy"). |
| K5.9 | `supporting-docs/SETUP-EXISTING.md:3` | CLEAR-FIX — doc-identity header "v10.0". Fix: v11.0. (NOT the accurate `git checkout v10.0` / backup-path refs — only the identity header.) |
| K5.10 | `supporting-docs/SETUP-NEW.md:3-4` | CLEAR-FIX — doc-identity header "v10.0". Fix: v11.0. |
| K5.11 | `supporting-docs/METHODOLOGY.md:3-4, 1732` | NEEDS-USER-DISPOSITION — version/identity block says "Version 2.1 (v10.0, April 2026)". This is a deliverable copied to clients. The correct value depends on whether METHODOLOGY's internal doc-version (2.1) should bump to a v11 line and whether the April-2026 date should move — a content-versioning policy call. §4 NUD-6. |
| K5.12 | `supporting-docs/DEPENDENCIES.md:3` | CLEAR-FIX — "Pack v10". Fix: v11. |
| K5.13 | `supporting-docs/SETUP_TEMPLATE.md:18, 35` | CLEAR-FIX — template self-labels + prescribes generated output as "v10". Fix: v11 (deliverable-cleanliness corollary — the generated SETUP.md must be clean). |
| K5.14 | `supporting-docs/AGENT_KICKOFF_TEMPLATE.md:21` | CLEAR-FIX — generated-output provenance "Pack v10". Fix: v11. |
| K5.15 | `README.md:60, 195` | NEEDS-USER-DISPOSITION — README states checks top out at 43; HEAD has Check 44/45/46 (BD-196; confirmed). README version table + layout are PM-only. Fix is mechanical (43→46, 40→43 invoked) but the line 60 v11.0 cell is part of the PM-only version table, and the count phrasing ("40 invoked / 38 numbered") must be recomputed against the real check set. §4 NUD-7. |

### B — non-contamination correctness defect (17)

| ID | file:line | Disposition |
|---|---|---|
| B.1 | `project-template/README.md:5-7` | RULING-BACKED (JC-3) — bare `cp -r` whole-template install. JC-3: redirect to `init-project.sh`/QUICKSTART. |
| B.2 | `project-template/skills/boundary-investigation/SKILL.md:67-76` (esp. :76) | RULING-BACKED (JC-4) — SSOT table uses pack-repo-relative `project-template/...` prefixes that resolve to nothing at client. JC-4: malformed-path correctness fix (NOT a K4 leak). Fix: rewrite the table paths to client-resolvable forms (`docs/pack/...`, `.claude/skills/<name>/SKILL.md`, etc.) per the client install layout. |
| B.3 | `project-template/docs/pack/PM-CHAT.md:930` | CLEAR-FIX — documents `.v9-customized` sidecar; the migrator emits `v10-customized` (`MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`, confirmed migrate-v10-to-v11.sh:76). Fix: `.v9-customized` → `.v10-customized`. |
| B.4 | `project-template/docs/pack/OPTIONAL-FEATURES.md:132-135, 164` | CLEAR-FIX — uses `bash scripts/pack-tracker.sh <verb>` (doesn't resolve at client; the surface convention elsewhere is the `pack tracker <verb>` shell-verb). Fix: switch to `pack tracker <verb>`. |
| B.5 | `project-template/docs/project/backlog/_intro.md:12` | NEEDS-USER-DISPOSITION — cites `scripts/lib/per-entry/`; at client the helpers run from `$PACK/scripts/lib/per-entry` (not staged; fixture `scripts/lib/` has only `detect.sh`, confirmed). Defensible fixes diverge: (a) mark the path pack-side-only ("in the pack repo"), or (b) drop the path and describe the mechanism abstractly. Both are correct; pick one and apply uniformly across B.5–B.10. §4 NUD-8. |
| B.6 | `project-template/docs/project/backlog/_rules.md:38` | NEEDS-USER-DISPOSITION — same `scripts/lib/per-entry/` non-resolving project path; bundle with NUD-8. |
| B.7 | `project-template/docs/project/changelog/_intro.md:15` | NEEDS-USER-DISPOSITION — same; bundle with NUD-8. |
| B.8 | `project-template/docs/project/changelog/_rules.md:40` | NEEDS-USER-DISPOSITION — same; bundle with NUD-8. |
| B.9 | `project-template/docs/project/implementation-plan/_intro.md:14` | NEEDS-USER-DISPOSITION — same; bundle with NUD-8. |
| B.10 | `project-template/docs/project/implementation-plan/_rules.md:39` | NEEDS-USER-DISPOSITION — same; bundle with NUD-8. |
| B.11 | `xcode-companion-templates/Codex/config.toml:52,56,60,64,69,73,77` | CLEAR-FIX — declares 7 sub-agents `config_file = "agents/<name>.toml"`; no `agents/` dir exists (confirmed: `Codex/` has only AGENTS.md + config.toml; README install copies only those two). Fix: remove the 7 `[agents.*]` blocks' `config_file` lines (or the blocks) so the installed config references no undelivered file. (Cross-check whether Codex requires inline agent defs vs. external files — see §4 note; mechanical removal of dangling `config_file` is the floor.) |
| B.12 | `scripts/lib/tracker-cycle-check.sh:93` | CLEAR-FIX — cites `ARCHITECTURE-V1.md` (ABSENT; not in BD-195 deleted set — pre-existing). V2/V3 exist. Fix: re-point to the resolving doc (`ARCHITECTURE-V3.3-DELTA.md` or the current ARCHITECTURE-V*.md that carries §9/§27.1) or drop the dangling basename. |
| B.13 | `scripts/lib/tracker-links.sh:96-97` | CLEAR-FIX — two `ARCHITECTURE-V1.md` cites (ABSENT). Fix: same as B.12 — re-point or drop. |
| B.14 | `scripts/validate-pack.py:4241` | CLEAR-FIX — cites `IMPL-REPORT-BD-173-Batch-19c-H.13.md`; actual file is `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md` (full prefix; confirmed). Sibling line 4220 uses the correct full prefix. Fix: correct the abbreviated basename. |
| B.15 | `README.md:152` | NEEDS-USER-DISPOSITION — layout map sites `MERGE-STRATEGY.md` under `supporting-docs/`; actual is `pack-ops/MERGE-STRATEGY.md` (confirmed). PM-only layout map; bundle with NUD-4. |
| B.16 | `README.md:154` | NEEDS-USER-DISPOSITION — layout map sites `DRY-RUN-MIGRATION.md` under `supporting-docs/`; actual is `pack-ops/DRY-RUN-MIGRATION.md` (confirmed). PM-only; bundle with NUD-4. |
| B.17 | `README.md:101` | NEEDS-USER-DISPOSITION — layout map says "34 skills"; tree has 36 (confirmed `ls -d project-template/skills/*/ | wc -l` = 36). PM-only; count SSOT is PLATFORM-SKILLS.md; reconciliation (34 vs 36 incl. the 13+19+1+1 breakdown) is a count-policy call. §4 NUD-9. |

---

## 2 — Guard designs (measure-then-bound)

Three guards: §2.1 JC-1 phase-task `BD-` strip + error-guard; §2.2 JC-2
client-surface leak-guard broadening; §2.3 JC-5 soft-advisory removed-doc
guard. Each follows the 5-step contract (measure → categorize KEEP/STRIP →
fix-recipe per STRIP → size allowlist to KEEP → verify clean post-fix).

### 2.1 — JC-1: strip `BD-` from the project phase-task dependency grammar + error-guard

**Step 1 — Measure (the `BD-` occurrences in the phase-task dependency
grammar surfaces).** Verbatim grep at HEAD `3178fa4` (full output in EEB-1):

| Occurrence | Surface | Class |
|---|---|---|
| `tracker-phase-task.sh:75` | dep-grammar docstring | STRIP |
| `tracker-phase-task.sh:113` | capture-group docstring | STRIP |
| `tracker-phase-task.sh:132` | bash ERE `tracker_phase_task_dependency_re` | STRIP |
| `tracker-phase-task.sh:208` | Python `DEP_ENTRY` regex | STRIP |
| `tracker-promote.sh:390` | phase-task emit-comment | STRIP |
| `tracker-promote.sh:1151` | phase-task dispatch comment | STRIP |
| `tracker-promote.sh:1155` | phase-task dispatch-guard ERE | STRIP |
| `test-tracker-phase-task.sh:113,132,149,204-205` | grammar-asserting tests + parity DEP regex | STRIP (flip to rejection) |
| `fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md:26` | `- BD-108` dep bullet | STRIP |
| `tracker-links.sh:12,71,132 + validate_id_shapes/_tlk_is_valid_pack_id` | SHARED link-shape vocabulary | **KEEP** (boundary — §4 NUD-1) |
| `tracker-migrate-forward.sh:990` (`BD-*|TD-*` entry-Blockers arm) | entry-level Blockers grammar | **KEEP** (JC-1 explicitly leaves untouched) |
| `test-tracker-links.sh:106,169 · test-tracker-cycle-check.sh:168 · fixtures/tracker-links/id-map.json:5-6` | SHARED link/cycle tests + fixtures (the intact LINK layer) | **KEEP** (the fixed strip locus leaves the shared validator intact; NUD-1 only formalizes their reclassification — see §4) |

**Step 2 — Categorize.** STRIP = the phase-task `Dependencies:` bullet
grammar (`DEP_ENTRY` / `tracker_phase_task_dependency_re`), the Path-2
phase-task promotion dispatch-guard that emits phase-task edges, their
docstrings/comments, the grammar-asserting tests, and the fixture
IMPLEMENTATION-PLAN dep bullet. KEEP = the SHARED link-orchestration
vocabulary (`tracker_links_validate_id_shapes`) and the entry-level
Blockers grammar (`tracker-migrate-forward.sh:990`) — JC-1 explicitly
preserves the pack's own-backlog `BD-` handling, and the entry-Blockers
path routes `BD-*|TD-*` through that shared validator for legitimate
`TD↔BD` cross-namespace links (V3.3 §5.1).

**Strip locus (load-bearing, CONFIRMED — not a choice):** JC-1 says
"phase-task dependency grammar" AND expressly preserves the pack's own-backlog
`BD-` handling. Those two clauses TOGETHER fix the strip locus mechanically:
strip `BD-` ONLY at the phase-task dispatch-guard regex (`tracker-promote.sh:1155`)
and the `DEP_ENTRY`/`tracker_phase_task_dependency_re` grammar — NOT from the
SHARED `tracker_links_validate_id_shapes` / `_tlk_is_valid_pack_id`. Stripping
the shared validator would break the entry-Blockers path
(`tracker-migrate-forward.sh:990` `BD-*|TD-*` arm → `validate_id_shapes`) that
JC-1 EXPLICITLY leaves untouched, so it is self-evidently forbidden by JC-1's
own-backlog clause — not a live design alternative. With the strip locus thus
fixed, the SHARED link validator stays intact and the four findings K1.11–K1.14
(which test that shared LINK layer, not the phase-task `DEP_ENTRY` grammar)
test a LEGITIMATE own-backlog/cross-namespace feature. The remaining open
question is therefore NOT "where to strip" (settled) but "are K1.11–K1.14
contamination at all?" → §4 NUD-1.

**Step 3 — Fix-recipe (per STRIP).**
  - Grammar regexes (K1.1/K1.2/K7.1): change
    `(phase-\d+(?:\.\d+)?|TD-\d+|BD-\d+)` → `(phase-\d+(?:\.\d+)?|TD-\d+)`
    in all three encoding copies (bash ERE, Python `DEP_ENTRY`, the test's
    inline parity `DEP`).
  - Dispatch-guard (K1.5): change the :1155 alternation to drop `|BD-[0-9]+`;
    a `BD-` blocker on a promoted TD is then passed through to flat-file
    (warning path) but NOT linked as a phase-task dependency edge.
  - Docstrings/comments (K1.3/K1.4/K1.6, :1151): drop `BD-` from the
    documented grammar; K1.6 comment states phase-task Dependencies emit
    `phase-N(.M)`/`TD-NNN` only.
  - Fixture (K1.7): delete the `- BD-108` bullet from the phase-task
    `Dependencies:` block.
  - Tests (K1.8/K1.9/K1.10): flip `assert_contains "...BD-[0-9]+"` →
    `assert_not_contains`; replace the `- BD-108` parser-input sample with a
    `TD-`/`phase-` sample; flip the "captures BD-108 as dep target" assertion
    to assert the **error-guard** rejects `BD-` (next item).
  - **Error-guard (the NEW JC-1 mandate):** add a typed-error check at the
    phase-task dependency parse boundary in `tracker-phase-task.sh` —
    after the line matches the (now BD-free) `DEP_ENTRY`, if the **dependency
    TARGET token (capture-group-1 of the dep bullet)** is a `BD-[0-9]+`, emit a
    typed `tracker_error_emit "validation"` ("`BD-` is not a valid phase-task
    dependency target; phase-task Dependencies accept `phase-N(.M)` and
    `TD-NNN` only"). **Binding (pinned recipe):** the guard MUST test the
    captured TARGET position ONLY — never grep the raw bullet text — so a
    legitimate free-text annotation that mentions `BD-NNN` (e.g.
    `- TD-031  (see BD-108 for context)`) does NOT false-positive. JC-1 scopes
    the rejection to "`BD-` as a project phase-task dependency *target*"; the
    recipe quotes that scoping. This converts silent admission into a loud
    failure. New tests assert: (i) the guard FIRES on `- BD-NNN` in target
    position; (ii) the guard does NOT fire on `BD-NNN` appearing only in
    annotation free-text after a valid `TD-`/`phase-` target.

**Step 4 — Size the allowlist.** This guard is an in-grammar error-guard,
not an allowlist-style scanner — its "allowlist" is the accepted target
vocabulary `{phase-N, phase-N.M, TD-NNN}` sized exactly to the KEEP set
(the pack's own-backlog `BD-` handling lives entirely in the link/Blockers
layer, untouched).

**Step 5 — Verify clean post-fix.** After the STRIP recipe: (a) the
phase-task parser rejects a `BD-` dep bullet with the typed error (new test
PASSES); (b) `test-tracker-phase-task.sh` group-1 bash-vs-Python parity
still holds on the BD-free grammar; (c) the entry-Blockers path
(`test-tracker-links.sh` BD↔ cases) still PASSES — proving the own-backlog
`BD-` handling is untouched by the fixed strip locus. Run: `bash
scripts/tests/test-tracker-phase-task.sh && bash
scripts/tests/test-tracker-links.sh && bash
scripts/tests/test-tracker-cycle-check.sh && bash
scripts/tests/test-tracker-promote-path2.sh`. With the strip locus fixed
(shared validator intact), K1.11–K1.14 stay green as-is; NUD-1's resolution is
only whether those four findings are formally reclassified NOT-A-DEFECT
(recommended) or retained as contamination — see §4 NUD-1.

### 2.2 — JC-2: broaden the client-surface leak-guard (Check 43 / Check 37)

JC-2 broadens the existing client-surface leak guard along four axes:
(i) bare pack-doc basenames, (ii) commit-SHA-as-provenance, (iii) scan
`.example`/`.proto`/`.env.example`, (iv) bare-prose (non-backtick) refs.
Measure-then-bound governs what actually lands.

**Step 1 — Measure (every occurrence the broadening would newly match).**
Verbatim greps at HEAD `3178fa4` (full output in EEB-2):

| Axis | Occurrence | Currently | Class |
|---|---|---|---|
| (iii) ext-scan | `.codex/config.toml.example`, `.mcp.json.example`, `.gemini/.env.example`, `proto/example/v1/example_service.proto`, `proto/common/v1/common.proto` | NOT walked (`example`/`proto` not in `_CHECK_40_FILE_EXTS`) | walk-set add |
| (iii)+(i)+(ii) | `.codex/config.toml.example:13` — `V10-CODEX-MCP-RESEARCH.md (commit 73d480e)` | bypasses (unwalked + bare-prose + SHA) | **STRIP** (K4.2) |
| (iii)+(i) | `.mcp.json.example:9` — `supporting-docs/CLI-PM-SETUP.md` | bypasses (unwalked); CLI-PM-SETUP NOT client-installed (only METHODOLOGY + INSTALL-PROCEDURES are) | **STRIP — NEW LEAK not in the 67** (see §4 note) |
| (iii) | proto self-imports — `example/v1/example_service.proto:7` `import "common/v1/common.proto";` + `common/v1/common.proto:5` self-ref (re-measured: `grep -rn` over `project-template/proto/`, HEAD `3178fa4` — full output EEB-5) | would newly match the basename regex if `.proto` is walked | **KEEP** (resolve WITHIN the shipped `proto/` tree → legitimate self-import; the sole genuine JC-2 allowlist) |
| (i)+(iv) | `README.md:9` — bare-prose `V10-DESIGN.md` | bypasses (no backticks) | **STRIP** (K4.1 / JC-3) |
| (i) | `OPTIONAL-FEATURES.md:174` — bare `MERGE-STRATEGY.md` "in the pack repo" | anchor-EXEMPT | KEEP-or-qualify (K4.5; §4) |
| (i) | `PM-CHAT.md:530` — `docs/pack/MERGE-STRATEGY.md` primary | passes (resolves syntactically) but dead at client | **STRIP** (K4.4) |
| supporting-docs prefix | pm-startup family `supporting-docs/METHODOLOGY.md` ×4 copies | passes (METHODOLOGY in installed-set) but `supporting-docs/` dir absent at client | **STRIP** (K2.1/K4.3) |
| (supporting-docs prefix) | `project-template/README.md:13/38/44` — `supporting-docs/...` refs (re-measured at HEAD `3178fa4` via `grep -rn "supporting-docs/" project-template/`: `:13` = the `cp ... supporting-docs/METHODOLOGY.md ... docs/pack/METHODOLOGY.md` line; `:38`/`:44` = the "Directory boundary rule" prose describing the pack's two-dir layout) | walked by Check 43 (`_iter_client_installed_files()` does `(a) all regular files under project-template/ recursive` — validate-pack.py:4116-4140) | **NOT a standalone KEEP — STRIP-or-rework folded into the C3 JC-3 README rework** (this README is the v10-titled client README whose `cp -r` (B.1), `V10-DESIGN.md` cite (K4.1), and v10 title (K5.1) are all reworked in C3; lines 13/38/44 are resolved by that rework, not by a permanent allowlist entry) |

**Step 2 — Categorize.** STRIP = K4.2 (research-doc + SHA), the NEW
`.mcp.json.example:9` CLI-PM-SETUP leak, K4.1 bare-prose V10-DESIGN.md, K4.4
dead primary MERGE-STRATEGY path, the pm-startup `supporting-docs/METHODOLOGY.md`
family (K2.1/K4.3). KEEP (the ALLOWLIST set, re-measured) = the two proto
self-imports ONLY (`example/v1/example_service.proto` → `common/v1/common.proto`,
and `common/v1/common.proto`'s self-ref) — they resolve within the shipped
`proto/` tree. The `project-template/README.md:13/38/44` `supporting-docs/`
refs are NOT an allowlist KEEP: they are STRIP-or-rework lines folded into the
C3 JC-3 README rework (the same v10 client README B.1/K4.1/K5.1 touch), so they
leave the allowlist sized to the proto pair alone. Separately, the correctly-
anchored "in the pack repo" pack-as-product pointers (K4.5 + the 6 anchored
hits) stay exempt via the EXISTING anchor mechanism — no allowlist growth.

**Critical refinement (the `supporting-docs/` prefix gap):** the current
Check 43 CLASS-C test FAILs a `supporting-docs/<X>` cite only when `<X>` is
NOT in the client-installed set. But the LEAK is the `supporting-docs/`
DIRECTORY reference itself — at a client there is no `supporting-docs/`
directory, so even `supporting-docs/METHODOLOGY.md` (content installed at
`docs/pack/`) is a dead PATH. JC-2 broadening: a qualified `supporting-docs/`
path on a client surface FAILs regardless of whether the basename is
installed elsewhere — the remediation is to cite the client-resolvable
`docs/pack/<X>` path, not the pre-install pack path. Note on
`project-template/README.md:13/38/44`: these `supporting-docs/` refs are NOT
carved out by a standalone allowlist exception — they are resolved by the C3
JC-3 README rework (which re-frames the pre-install copy step and the
two-directory boundary prose for the v11 client README). Verify post-rework
(Step 5) that the broadened guard runs clean on the reworked README rather
than admitting the un-reworked lines via an allowlist (admitting them would
treat contamination as legitimate by default).

**Step 3 — Fix-recipe (per STRIP).** Each STRIP is fixed by its §1 finding
recipe (K4.2 drop research-doc+SHA; new `.mcp.json.example:9` → drop the
`supporting-docs/CLI-PM-SETUP.md` cite or re-point to a client-resolvable
setup note; K4.1 drop V10-DESIGN.md; K4.4 re-point primary to project SSOT;
K2.1/K4.3 → `docs/pack/METHODOLOGY.md`). The GUARD change: (a) add
`example|proto` to the walked-extension set for Check 43 (and the `.env.example`
double-extension); (b) add a bare-prose (non-backtick) pack-doc-basename
class-test for the `_DENY_LIST_FILENAMES`-style basenames (`V10-*.md`,
`MERGE-STRATEGY.md`, etc. — sourced from the pack-only doc inventory, NOT a
hand-list); (c) add a commit-SHA-as-provenance class-test (`commit [0-9a-f]{7,40}`
in a `Source:`/provenance context on a client surface); (d) tighten the
`supporting-docs/` CLASS-C test to FAIL on the directory prefix regardless of
installed-basename status.

**Step 4 — Size the allowlist EXACTLY to KEEP.** The KEEP set re-measured at
HEAD `3178fa4` (`grep -rn` over `project-template/proto/` + the
`supporting-docs/` walk in EEB-5) is the **two proto self-imports ONLY**. New
allowlist entries (and ONLY these):
  - proto self-imports: `common/v1/common.proto`, `example/v1/example_service.proto`
    (and the bare `common.proto` / `example_service.proto` basenames) — these
    resolve WITHIN the shipped `proto/` tree, so they are legitimate. (The
    `google/protobuf/*` / `google/rpc/*` imports are external well-known protos,
    not pack-doc-basename matches — out of scope for this guard.)
  The allowlist gets NO other new entries. Specifically:
  - `project-template/README.md:13/38/44` are NOT added to the allowlist —
    they are STRIP-or-rework lines resolved by the C3 JC-3 README rework; if
    the rework leaves any `supporting-docs/` ref, it must be re-pointed to the
    client-resolvable `docs/pack/` form, not allowlisted. (The earlier draft
    cited these as a KEEP allowlist entry; re-measurement shows they belong to
    the C3 rework set, not the permanent allowlist — measure-then-bound: do not
    size an allowlist against lines that are themselves remediation targets.)
  - the 6 correctly-anchored "in the pack repo" pack-as-product pointers stay
    exempt via the EXISTING anchor mechanism (no allowlist growth needed).
  - Fence interaction (NIT): the tightened `supporting-docs/` prefix rule must
    NOT double-flag the per-line-fenced supporting-docs SOURCE files
    (`supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`
    at validate-pack.py:4236-4237) — those fence entries cover legitimate
    pack-internal references inside the supporting-docs source files themselves,
    NOT a client surface citing the `supporting-docs/` prefix. The two are
    disjoint (the fenced files are not "client surfaces citing the prefix"), but
    the planner MUST assert this disjointness in the Step-5 verification rather
    than leaving it implicit.
  The allowlist is NOT widened to admit any STRIP-classified or
  unclassified hit.

**Step 5 — Verify clean post-fix.** After STRIP recipes + guard change +
KEEP allowlist: run `python3 scripts/validate-pack.py` — Check 43 + Check 37
PASS with the broadened walk (the 5 newly-walked files: 2 fixed, 1
proto-allowlisted ×2, all clean). Two re-measure-driven verification adds:
(a) confirm the broadened guard runs CLEAN on the C3-reworked
`project-template/README.md` (its 13/38/44 `supporting-docs/` refs resolved by
the rework, NOT admitted via allowlist); (b) confirm the tightened
`supporting-docs/` prefix rule does NOT double-flag the per-line-fenced
supporting-docs source files (validate-pack.py:4236-4237) — assert the fence
set and the client-surface prefix-hit set are disjoint. Add/extend
`scripts/tests/test-validate-pack-check-43.sh` with: a `.example` file
carrying a pack-only basename FAILs; a proto self-import PASSES (allowlist);
a commit-SHA provenance FAILs; a `supporting-docs/<installed-basename>` cite
on a client surface FAILs (prefix rule); a fenced supporting-docs source file
does NOT trip the prefix rule (disjointness). Confirm no regression on the 6
anchored KEEP hits.

### 2.3 — JC-5: soft-advisory removed-doc guard (cited-path-resolves-to-a-removed-doc)

**Step 1 — Measure.** The K3.12 CHANGELOG lines (451, 481-482, 562, 564) and
K3.13 BACKLOG lines (3061, 3690, 4169, 4284, 4300/4302/4304) cite removed
docs within accurate historical narrative (verified ABSENT: GEMINI-CLI-ANALYSIS.md,
ANDROID-ANALYSIS.md, V10-PREDESIGN.md, ARCHITECTURE-BD-185.md, PLAN-BD-185.md).

**Step 2 — Categorize.** ALL KEEP-as-history (JC-5: leave accurate v8/v9 +
process narrative; do NOT hand-correct). There are NO STRIP items — JC-5's
sole output is a NON-blocking advisory.

**Step 3 — Fix-recipe.** None (no content edit per JC-5).

**Step 4 — Size.** The guard is informational/SOFT — it WARNs (never
hard-fails) when a backtick-cited basename resolves to a removed doc. Its
"allowlist" is implicit: every hit is a warning, none is a gate failure, so
accurate-history citations never break CI. It must NOT be wired as a `fail()`.

**Step 5 — Verify.** Run `python3 scripts/validate-pack.py`; confirm the new
soft-advisory emits WARN lines for the K3.12/K3.13 citations and the overall
exit code stays 0 (PASS). A test asserts the advisory is non-fatal (exit 0
with WARNs present).

---

## 3 — Commit sequence

Grouped by kind/surface/dependency. Every commit touching `project-template/`,
`scripts/`, `pack-ops/`, or `supporting-docs/` regenerates
`test-fixtures/manifest.txt` (`bash test-fixtures/build.sh --all --clean`) and
stages it in the SAME commit when the manifest diff is non-empty
(regenerate-manifest-v11-surface). Per-commit gate = bounded review/fix cycle
(max 2 review/fix pairs + 1 final reviewer) + user commit approval; agents
never commit. NUD-gated commits do NOT fire until the user rules the relevant
NUD (§4).

NOTE on ordering: the JC-1 guard cluster (C1) lands first because it changes
shipped library grammar + tests and is the BD-185-restart hard prerequisite.
Client-surface (C2–C4) and pack-internal (C5–C7) follow. PM-only README/BACKLOG
(C8) lands last and only after NUD-3/NUD-4/NUD-7/NUD-9 are ruled.

| # | Scope | Files | Keyword | Verification | Manifest? | Gate |
|---|---|---|---|---|---|---|
| C1 | JC-1 phase-task `BD-` strip + error-guard (K1.1-K1.10, K7.1; K1.5/K1.6) | `scripts/lib/tracker-phase-task.sh`, `scripts/lib/tracker-promote.sh`, `scripts/tests/test-tracker-phase-task.sh`, `scripts/tests/fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md`, NEW error-guard test | `pack-only` (all paths outside project-template/ + supporting-docs/) | `bash scripts/tests/test-tracker-phase-task.sh` + `test-tracker-promote-path2.sh` + `validate-pack.py` (Check 43 unaffected; full PASS) | YES (`scripts/`) | planner pass FIRST (grammar+guard recipe), then bounded review/fix |
| C1b | NUD-1-gated: K1.11-K1.14 link/cycle tests + fixture (fires ONLY if the user RETAINS them as contamination rather than reclassifying NOT-A-DEFECT; the recommended reclassification leaves these green and C1b does NOT fire) | `scripts/tests/test-tracker-links.sh`, `test-tracker-cycle-check.sh`, `scripts/tests/fixtures/tracker-links/id-map.json` | `pack-only` | link/cycle test suites PASS | YES | NUD-1 ruling required before spawn |
| C2 | JC-2 guard broadening (Check 43/37: ext-scan, bare-prose, SHA, supporting-docs prefix) + test | `scripts/validate-pack.py`, `scripts/tests/test-validate-pack-check-43.sh` | `pack-only` | `validate-pack.py` full PASS on the broadened walk; per-check test green | YES (`scripts/`) | measure-then-bound allowlist sized to §2.2 KEEP; bounded review/fix |
| C3 | Client-surface leak + currency fixes caught by C2 (K2.1, K4.1-K4.5, K5.1-K5.6, K5.8, B.1-B.4, B.11 + the NEW `.mcp.json.example:9` CLI-PM-SETUP leak) | `project-template/README.md`, `project-template/.codex/config.toml.example`, `.mcp.json.example`, pm-startup triad (`skills/pm-startup/SKILL.md` + `.claude/`+`.codex/` copies + `.gemini/commands/pm-startup.toml`), `docs/pack/{PM-CHAT,OPTIONAL-FEATURES,HELP-FRAGMENT}.md`, `docs/pack/prompts/pm-chat.md`, `boundary-investigation/SKILL.md` (JC-4/B.2), `xcode-companion-templates/README.md` + `Codex/config.toml` | `project-only` (all paths under project-template/ + supporting-docs/) — EXCEPT xcode-companion-templates/ (not project-template/) → split C3 into C3a `project-only` + C3b no-keyword for xcode | C2 broadened `validate-pack.py` PASS (these were the STRIP targets); cross-CLI normalization verified | YES (`project-template/`) | trinity-of-copies parity for pm-startup; cross-CLI reference normalization (§ARCHITECTURE-BD-182 canonical table); bounded review/fix |
| C4 | supporting-docs currency (K5.9-K5.14, K3.6) | `supporting-docs/{SETUP-EXISTING,SETUP-NEW,DEPENDENCIES,SETUP_TEMPLATE,AGENT_KICKOFF_TEMPLATE}.md` | `project-only` (supporting-docs/ is project-side per Check 36) | C2 `validate-pack.py` PASS; K3.6 re-points to MIGRATION-v10-to-v11.md | YES (`supporting-docs/`) | NUD-6-gated for K5.11 METHODOLOGY (split METHODOLOGY into C4b if NUD-6 deferred) |
| C5 | Pack-internal dangling-doc fixes (K3.1, K3.2, K3.11, B.12, B.13, B.14) | `scripts/lib/tracker-migrate-forward.sh`, `tracker-phase-task.sh`, `tracker-cycle-check.sh`, `tracker-links.sh`, `scripts/validate-pack.py`, `maintenance-docs/TOOL-COMPARISON.md` | no-keyword (mixed: scripts/ + maintenance-docs/) OR split scripts/ `pack-only` + maintenance-docs/ neutral | `validate-pack.py` full PASS; resolving-doc cites verified | YES (`scripts/`) | bounded review/fix |
| C6 | JC-5 soft-advisory removed-doc guard (K3.12, K3.13 — guard ONLY, no content edit) | `scripts/validate-pack.py`, `scripts/tests/<new-check-test>.sh` | `pack-only` | advisory WARNs on K3.12/K3.13 cites; exit 0 (non-fatal); test green | YES (`scripts/`) | bounded review/fix |
| C7 | PM-only BACKLOG BD-195-entry de-citation (K3.3, K3.4, K3.5) | `pack-ops/BACKLOG.md` | `PM-only` | N/A (PM-only narrative); no validator gate | RUN regen (`pack-ops/` IS a named v11 surface per `regenerate-manifest-v11-surface`); stage manifest.txt only if the diff is non-empty — expected EMPTY (manifest captures per-fixture init-project.sh SHAs, which BACKLOG.md does not feed) | NUD-3 ruling required; Pack-Chat-direct edit |
| C8 | PM-only README layout/version-table currency (K3.8, K3.9, K3.10, K5.15, B.15, B.16, B.17) | `README.md` | `PM-only` | `validate-pack.py` PASS (any check asserting README layout/counts) | YES if build flags README | NUD-4/NUD-7/NUD-9 rulings required; Pack-Chat-direct edit |
| C9 | NUD-gated cleanup commits (K2.2 bootstrap, K5.7 PACK-FEEDBACK, B.5-B.10 per-entry path) | `project-template/scripts/bootstrap.sh`, `docs/pack/PACK-FEEDBACK.md`, `docs/project/{backlog,changelog,implementation-plan}/{_intro,_rules}.md` | `project-only` | C2 `validate-pack.py` PASS | YES (`project-template/`) | NUD-2/NUD-5/NUD-8 rulings required; bounded review/fix |

Dependency notes: C1 before C1b (same grammar cluster). C2 before C3/C4
(the broadened guard must exist to verify the client-surface fixes land
clean; measure-then-bound means C2's allowlist is sized against C3/C4's
projected post-fix tree). C6 independent. C7/C8/C9 gated on §4 rulings.

**Red-CI window (load-bearing — pack rule "CI must pass on every push"):**
landing C2 (the broadened guard) BEFORE C3/C4 leaves CI RED in the interval,
because the broadened guard FIRES on the still-unfixed client-surface STRIP set
(K4.2, the `.mcp.json.example:9` leak, the pm-startup `supporting-docs/` family,
etc.). C2 must therefore NOT be pushed as a standalone green commit ahead of
C3/C4. Two compliant shapes (planner picks one): (a) collapse C2+C3 (and the
supporting-docs slice of C4) into a SINGLE commit so the guard and its STRIP
fixes land atomically; or (b) sequence C2 → C3 → C4 with NO intervening push
between C2 and the commit that clears the last STRIP it fires on. The
measure-then-bound ordering (guard sized against the projected post-fix tree)
is preserved either way; only the push boundary changes.

---

## 4 — NEEDS-USER-DISPOSITION items (framed for the user)

Nine items. Each: the finding(s), the options, foundation-grounded
considerations, repo evidence. Not decided here.

**NUD-1 — Are K1.11–K1.14 contamination at all, or did the findings doc mis-classify them? (K1.11-K1.14; gates C1b)**

*Settled fact (NOT the decision — established in §2.1, restated so the user is
not asked to re-litigate it):* the JC-1 strip locus is FIXED, not a choice.
`tracker_links_validate_id_shapes` / `_tlk_is_valid_pack_id`
(tracker-links.sh:148/:285) is a V3.3 §5.1 link-orchestration validator accepting
`TD↔BD`, and it is DUAL-CONSUMER — called by both the phase-task promotion path
(`tracker-promote.sh:1155`) AND the entry-Blockers path
(`tracker-migrate-forward.sh:990`, `BD-*|TD-*` arm) that JC-1 EXPLICITLY leaves
untouched. Stripping the shared validator would break the own-backlog `BD↔`
links JC-1 preserves, so the only JC-1-consistent fix strips `BD-` ONLY at the
phase-task grammar + dispatch-guard and leaves the shared validator intact.
There is no live alternative here.

*The actual decision (this is what the user rules):* under that fixed strip
locus, K1.11–K1.14 test the SHARED LINK layer — `validate_id_shapes` accepting
`BD-108`, a `blocked-by` link with a `BD-108` target, a cycle-check store
seeded with `BD-`, the link-fixture id-map — which is a LEGITIMATE own-backlog /
cross-namespace feature, NOT the project phase-task `DEP_ENTRY` grammar JC-1
targets. So the question is whether the AUDIT mis-classified these four as K1
contamination:
- **Disposition 1 (recommended): RECLASSIFY K1.11–K1.14 as NOT-A-DEFECT.** They
  exercise the intact, legitimate shared link layer; the JC-1 fix does not (and
  must not) touch them. They stay GREEN as-is. C1b does NOT fire. This treats
  the four as a findings-doc mis-classification (K1-tagged but testing the link
  layer, not the phase-task grammar).
- **Disposition 2: RETAIN K1.11–K1.14 as contamination.** This would require a
  strip the foundation does NOT authorize (it would have to reach the shared
  validator JC-1 preserves), flipping the four tests to rejection and breaking
  the entry-Blockers `BD↔` path. C1b fires. This contradicts JC-1's own-backlog
  clause and is not recommended.
- Consideration: JC-1 scopes to the "project phase-task dependency grammar" and
  expressly preserves own-backlog `BD-`. The four findings sit on the preserved
  side of that line. Recommending Disposition 1 is therefore not steering toward
  a convenient answer — it is reporting that, under the only JC-1-consistent
  fix, these four are not defects. The user's call is whether to FORMALLY record
  that reclassification (closing the four as not-a-defect in the audit ledger)
  or to over-ride JC-1 and treat them as contamination anyway.

**NUD-2 — How to rewrite the bootstrap.sh pack-internal comment? (K2.2; gates C9)**
- Evidence: `project-template/scripts/bootstrap.sh:46-51` — client-gated
  comment names `in the pack repo`, `supporting-docs/SETUP-NEW.md`,
  `init-project.sh`, `migration guide`. The client never re-runs
  init-project.sh from this file.
- Option A: strip the skills-distribution explainer entirely (the comment
  is pack-maintainer context with no client value).
- Option B: re-point to a client-resolvable surface (a `docs/pack/`
  migration note) without naming pack-only artifacts.
- Consideration: categorical-principle-first says the leak goes by default;
  the question is only what (if anything) replaces it. Option A is the
  smaller, cleaner change (delete-by-default for the pack-only explainer).

**NUD-3 — Editing the LIVE BD-195 BACKLOG entry mid-remediation (K3.3/K3.4/K3.5; gates C7)**
- Evidence: `pack-ops/BACKLOG.md:3135/3137/3168` — the open BD-195 entry
  cites three DELETED-set docs (REFRESH-POST-BD196, SEGMENTATION, RESCOPE,
  RECONCILED-PROBLEM-LIST) as authoritative inputs to the work IN PROGRESS.
- Option A: re-cite the live trusted basis (this strategy doc +
  BD-195-CLEAN-FOUNDATION.md + AUDIT-BD-195-VERIFIED-FINDINGS.md), replacing
  the deleted-doc segmentation narrative.
- Option B: collapse the State/Segments/Step-9 narrative to a short pointer
  to the live docs (delete the superseded detail).
- Consideration: PM-only + it is the BD's own tracking record. The
  never-read-contaminated principle says an agent must not be sent to a
  deleted doc; but WHAT replaces the narrative is a PM editorial call. Must
  be Pack-Chat-direct, user-approved.

**NUD-4 — README Repository-Layout map: removed/relocated docs (K3.8/K3.9/K3.10, B.15, B.16; gates C8)**
- Evidence: README layout lists GEMINI-CLI-ANALYSIS.md / ANDROID-ANALYSIS.md
  / V10-PREDESIGN.md as present (all ABSENT); sites MERGE-STRATEGY.md +
  DRY-RUN-MIGRATION.md under supporting-docs/ (actual: pack-ops/).
- Option A: strip the removed-doc rows; correct the two mis-sited rows to
  pack-ops/.
- Option B: strip removed rows + add a one-line "(removed in v11 cleanup;
  see CHANGELOG)" note where useful.
- Consideration: PM-only (README is the authoritative layout reference).
  The map asserts present-tense presence, so the deleted rows mislead — fix
  is mechanical; the only call is whether to annotate removals.

**NUD-5 — PACK-FEEDBACK.md pervasive v9 seed content (K5.7; gates C9)**
- Evidence: 17 lines carry `v9` in a FRESH v11 template; some are version
  labels (L40 "Pack version in use | v9.[N]") and some are illustrative prose
  ("after the v9 split, auditor-ui covers only ...").
- Option A: swap only the version-LABEL fields to v11; leave illustrative
  prose (it is example narrative, not a current-version claim).
- Option B: blanket v9→v11 across all 17 (risks corrupting the example
  narrative's meaning).
- Consideration: deliverable-cleanliness corollary wants the shipped template
  clean, but a blanket swap can introduce factual errors into illustrative
  text. Recommend Option A (label-only).

**NUD-6 — METHODOLOGY.md doc-version + date policy (K5.11; gates C4b)**
- Evidence: METHODOLOGY.md:3-4/1732 — "Version 2.1 (v10.0, April 2026)".
  Shipped to clients at docs/pack/.
- Option A: bump the pack-version token to v11.0 + move the date to the
  v11.0 release (May 2026); keep internal doc-version 2.1.
- Option B: bump internal doc-version (2.1→2.2) AND the pack-version + date.
- Consideration: the pack-version label is clearly stale (K5). Whether the
  internal methodology-doc semantic version (2.1) should bump is a
  content-change-vs-relabel policy call the user owns.

**NUD-7 — README check-count currency (K5.15; gates C8)**
- Evidence: README:60/195 say checks span "Check 1-11, 16-23, 25-43" (top 43);
  HEAD defines Check 44/45/46 (BD-196; confirmed `grep Check 4[0-6]`).
- Option A: recompute the counts (43→46 numbered ceiling; "40 invoked"→ the
  real invoked total) and update both line 60 (version-table cell) and 195.
- Consideration: mechanical, but line 60 is inside the PM-only version table.
  The only judgment is whether the v11.0 cell narrative should also mention
  BD-196's checks — a version-history editorial call.

**NUD-8 — project-side `scripts/lib/per-entry/` path on client surface (B.5-B.10; gates C9)**
- Evidence: 6 project-side per-entry `_intro`/`_rules` files cite
  `scripts/lib/per-entry/`; at client the helpers run from
  `$PACK/scripts/lib/per-entry` (NOT staged — fixture `scripts/lib/` has only
  `detect.sh`, confirmed).
- Option A: annotate the path as pack-side-only ("the pack repo's
  `scripts/lib/per-entry/`").
- Option B: drop the concrete path; describe the mechanism abstractly ("the
  pack's per-entry mirror generator").
- Consideration: directory-based principle — the path does not resolve on
  the surface it ships to. Either fix is correct; pick one and apply
  uniformly across all 6. (The audit itself flagged "UNCERTAINTY: may be
  intentional-descriptive but unmarked.")

**NUD-9 — README skill count 34 vs 36 (B.17; gates C8)**
- Evidence: README:101 "34 skills (13+19+1+1)"; tree has 36 dirs (confirmed).
- Option A: update README to 36 + reconcile the breakdown against the tree.
- Option B: defer to the skills-inventory cross-surface audit (the count SSOT
  is PLATFORM-SKILLS.md) and fix only after that reconciliation.
- Consideration: PM-only. The +2 delta is real, but the authoritative count
  lives in PLATFORM-SKILLS.md; a README-only bump risks re-drifting if the
  SSOT says otherwise. Recommend confirming against PLATFORM-SKILLS.md first.

**Cross-cutting note (NEW leak surfaced by the JC-2 measure step):** the
broadened walk catches `project-template/.mcp.json.example:9` →
`supporting-docs/CLI-PM-SETUP.md`, a dead client path (CLI-PM-SETUP.md is NOT
client-installed — only METHODOLOGY.md + INSTALL-PROCEDURES.md are). This is a
REAL leak NOT among the 67 (the audit's `.example` files were unwalked). Per
deferral-is-scope-creep + no-deferral-without-user-direction, it lands in
v11.0 (folded into C3). Surfaced here as the blast-radius of the JC-2 guard.

---

## 5 — Empirical-Evidence Blocks

All measurements taken at HEAD `3178fa4f666326ac3eac26238b6e96ad25b60f71`,
branch `v11-dev`, on 2026-06-01.

**EEB-0 — Per-entry trees absent; mirrors are current edit target.**
- Command: `ls backlog/ ; ls changelog/`
- Output (verbatim): `ls: backlog/: No such file or directory` /
  `ls: changelog/: No such file or directory`
- Interpretation: the pack-self `/backlog/` `/changelog/` per-entry trees do
  not exist at HEAD (created at Batch 23). So `pack-ops/BACKLOG.md` /
  `CHANGELOG.md` are the current source-of-truth edit target for the K3
  BACKLOG/CHANGELOG findings; there is no per-entry source to edit instead.
- Conclusion: SUPPORTED.

**EEB-1 — JC-1 `BD-` occurrences in the phase-task grammar surfaces.**
- Command: `grep -n 'BD-' scripts/lib/tracker-phase-task.sh
  scripts/lib/tracker-promote.sh`
- Output (verbatim, abridged to load-bearing lines): `tracker-phase-task.sh:75:#
  Dependencies entry: ...|TD-\d+|BD-\d+`; `:132: ...|TD-[0-9]+|BD-[0-9]+)...`;
  `:208: ...|TD-\d+|BD-\d+)...`; `tracker-promote.sh:390:# list of v10 grammar
  tokens (BD-NNN, TD-NNN, ...)`; `:1151:# pack-id shapes (... TD-NNN, BD-NNN).`;
  `:1155: if [[ "$b_raw_id" =~ ^(...|TD-[0-9]+|BD-[0-9]+)$ ]]; then`.
- Interpretation: the phase-task dep grammar (re + DEP_ENTRY), its docstrings,
  and the Path-2 promotion dispatch-guard all admit `BD-`. These are the STRIP
  set; the SHARED `validate_id_shapes` and entry-Blockers
  (migrate-forward.sh:990) are the KEEP set.
- Conclusion: SUPPORTED.

**EEB-2 — Shared link-shape validator is dual-consumer (the NUD-1 boundary).**
- Commands: `sed -n '148,169p' scripts/lib/tracker-links.sh` (def);
  `sed -n '1155,1157p' scripts/lib/tracker-promote.sh` (phase-task caller);
  `sed -n '990,999p' scripts/lib/tracker-migrate-forward.sh` (entry-Blockers
  caller).
- Output (verbatim, key lines): `tracker_links_validate_id_shapes() { ...
  (expected phase-N, phase-N.M, TD-NNN, or BD-NNN) ...}`;
  promote.sh `if [[ ... ]]; then ... tracker_links_create_blocked_by ...`;
  migrate-forward.sh `BD-*|TD-*) ... tracker_links_create_blocked_by "$pack_id"
  "$raw" ...`.
- Interpretation: `validate_id_shapes` is called by BOTH the phase-task
  promotion path and the entry-Blockers path. Stripping `BD-` from it would
  break the entry-Blockers `BD↔` links JC-1 leaves untouched → the strip locus
  is FIXED (not a choice): strip only at the phase-task grammar + dispatch-guard,
  leave the shared validator intact. The consequent decision (NOT the locus) is
  whether K1.11–K1.14 are reclassified NOT-A-DEFECT or retained as contamination.
- Conclusion: SUPPORTED (drives NUD-1's reclassification decision).

**EEB-3 — Removed-doc existence checks (K3/K4/B dangling targets).**
- Command: `for f in <list>; do [ -e "$f" ] && echo EXISTS || echo ABSENT; done`
- Output (verbatim, key): ABSENT `ARCHITECTURE-V3.2-DELTA.md`,
  `GEMINI-CLI-ANALYSIS.md`, `ANDROID-ANALYSIS.md`, `archive/V10-PREDESIGN.md`,
  `supporting-docs/MIGRATION-v9-to-v10.md`, `supporting-docs/MERGE-STRATEGY.md`,
  `supporting-docs/DRY-RUN-MIGRATION.md`, `ARCHITECTURE-V1.md`. EXISTS
  `ARCHITECTURE-V3.3-DELTA.md`, `archive/V10-DESIGN.md`,
  `archive/V10-DESIGN-PROCESS-PLAN.md`, `pack-ops/MERGE-STRATEGY.md`,
  `pack-ops/DRY-RUN-MIGRATION.md`, `ARCHITECTURE-V2.md`, `scripts/lib/per-entry`.
- Interpretation: confirms the dangling targets for K3.1/3.2/3.6/3.7/3.8-3.10/
  3.11, K4.1, B.12/B.13/B.15/B.16; confirms the resolving co-cites and the
  pack-repo-present-but-client-absent `scripts/lib/per-entry`.
- Conclusion: SUPPORTED.

**EEB-4 — Check counts, skill count, sidecar suffix (K5.15/B.17/B.3/K5.5).**
- Commands: `grep -oE 'Check 4[0-6]' scripts/validate-pack.py | sort -u`;
  `ls -d project-template/skills/*/ | wc -l`; `grep -n 'OWN_SIDECAR_SUFFIX'
  scripts/migrate-v10-to-v11.sh`.
- Output (verbatim): `Check 40 / 41 / 42 / 43 / 44 / 45 / 46`; `36`;
  `76:MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`.
- Interpretation: README's "top 43 / 34 skills" is stale (Check 44-46 exist;
  36 skill dirs); PM-CHAT.md's `.v9-customized` is wrong (migrator emits
  `v10-customized`).
- Conclusion: SUPPORTED (K5.15, B.17, B.3; K5.5 migrator-headline corroborated).

**EEB-5 — JC-2 broadening: unwalked extensions + the NEW leak.**
- Commands: `find project-template -name '*.example' -o -name '*.proto'`;
  `grep '_CHECK_40_FILE_EXTS' scripts/validate-pack.py`; `grep -n 'CLI-PM-SETUP'
  scripts/init-project.sh`; `_CLIENT_INSTALLED_FILES` supporting-docs grep.
- Output (verbatim): files `.mcp.json.example`, `.gemini/.env.example`,
  `.codex/config.toml.example`, `proto/.../example_service.proto`,
  `proto/.../common.proto`; `_CHECK_40_FILE_EXTS = "md|sh|py|toml|yml|yaml|json|txt"`
  (no `example`/`proto`); CLI-PM-SETUP.md NOT in `_CLIENT_INSTALLED_FILES`
  (only `METHODOLOGY.md` + `INSTALL-PROCEDURES.md` listed).
- Interpretation: `.example`/`.proto` are unwalked, so K4.2 + the
  `.mcp.json.example:9 → supporting-docs/CLI-PM-SETUP.md` leak bypass the
  current guard; CLI-PM-SETUP is not client-installed → that cite is a dead
  client path → a REAL leak not among the 67.
- Conclusion: SUPPORTED (drives §2.2 + the §4 cross-cutting note).

**EEB-6 — CI is green at HEAD despite the 67 leaks.**
- Command: `python3 scripts/validate-pack.py; echo EXIT=$?`
- Output (verbatim, tail): `Check 37 ... zero deny-list contamination`;
  `Check 43 ... zero pack-internal bare cross-references`; `PASSED — all
  checks clean`; `EXIT=0`.
- Interpretation: the leaks slip through existing guards via the bypass
  mechanisms in §2.2 (unwalked exts, backtick-only regex, installed-basename
  CLASS-C exemption, anchor-phrase). This is precisely why JC-2 broadens the
  guard; the broadening must be sized so it FAILs on the STRIP set and PASSes
  on the KEEP set post-fix.
- Conclusion: SUPPORTED.

**EEB-7 — xcode Codex config dangling agent files (B.11).**
- Commands: `ls xcode-companion-templates/Codex/`; `sed -n '14,17p'
  xcode-companion-templates/README.md`.
- Output (verbatim): `AGENTS.md / config.toml` (no `agents/` dir); README
  install copies only `Codex/AGENTS.md` + `Codex/config.toml`.
- Interpretation: the 7 `config_file = "agents/<name>.toml"` declarations in
  config.toml reference files that neither exist in the template nor are
  installed. Confirmed dangling.
- Conclusion: SUPPORTED.

**EEB-8 — Bounded-revision RE-MEASURE of the §2.2 JC-2 allowlist KEEP set
(2026-06-01, HEAD `3178fa4`).** Replaces the prior draft's `README:13/38/44`
KEEP-allowlist citation (the adversarial review flagged it as sized against
non-existent occurrences).
- Command 1: `grep -rn "supporting-docs/" project-template/README.md`
- Output 1 (verbatim):
  `project-template/README.md:13:cp /path/to/pack/supporting-docs/METHODOLOGY.md /path/to/your-project/docs/pack/METHODOLOGY.md`
  `project-template/README.md:38:- **\`supporting-docs/\`** — docs copied individually during setup (METHODOLOGY.md`
  `project-template/README.md:44:in \`supporting-docs/\`.`
- Command 2: `grep -rn 'common/v1/common.proto' project-template/proto/ | grep -v google`
- Output 2 (verbatim): `example/v1/example_service.proto:4` (comment ref) +
  `:7 import "common/v1/common.proto";` + `common/v1/common.proto:5` (self-ref
  comment). These are the only pack-internal proto basename references; the
  rest are `google/protobuf/*` / `google/rpc/*` external well-known protos.
- Command 3: `sed -n '4136,4140p' scripts/validate-pack.py`
- Output 3 (verbatim): `# (a) project-template/ recursive walk (existing
  behavior).` / `root = REPO_ROOT / "project-template"` / `if root.is_dir():` /
  `for path in sorted(root.rglob("*")):` / `if not path.is_file():`
- Interpretation: (i) The prior draft cited `README:13/38/44` as the KEEP set;
  the review measured the PACK-ROOT `README.md` (those lines = blank / heading /
  feature-text, no `supporting-docs/` ref) and concluded the citation was
  fabricated. RE-MEASURE: the strategy's lines resolve at
  `project-template/README.md:13/38/44`, which DO carry `supporting-docs/` refs
  — but `_iter_client_installed_files()` does a recursive walk of
  `project-template/` (Output 3), so this README IS Check-43-walked, and these
  three lines are part of the v10-titled client README the C3 JC-3 rework
  already touches (B.1 `cp -r`, K4.1 `V10-DESIGN.md`, K5.1 v10 title). They are
  therefore STRIP-or-rework targets folded into C3, NOT a standalone allowlist
  KEEP. (ii) The genuine permanent KEEP allowlist is the two proto self-imports
  ONLY (`example/v1/example_service.proto` → `common/v1/common.proto`, and
  `common/v1/common.proto`'s self-ref), which resolve within the shipped
  `proto/` tree. The earlier draft's broader/mis-cited KEEP entry is dropped.
- Conclusion: SUPPORTED — KEEP set re-bounded to the two proto self-imports;
  the README lines re-routed to the C3 rework (measure-then-bound: an allowlist
  is not sized against lines that are themselves remediation targets).

---

## 6 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| empirical-evidence-blocks [architect] | §5 EEB-0..EEB-8 each carry command + verbatim output + HEAD `3178fa4` + interpretation + SUPPORTED; the bounded-revision re-measure is EEB-8 (`grep -rn "supporting-docs/" project-template/README.md` → :13/:38/:44 verbatim; proto self-import grep; `_iter_client_installed_files` recursive-walk body sed) | COMPLIANT |
| ci-guard-design-measure-then-bound [architect] | §2.2 allowlist RE-MEASURED in this bounded revision (the defect the review flagged): the genuine KEEP set is the two proto self-imports ONLY (`common/v1/common.proto`, `example/v1/example_service.proto`); the `project-template/README.md:13/38/44` `supporting-docs/` refs are re-routed to the C3 JC-3 README rework, NOT allowlisted (EEB-8) — an allowlist is not sized against lines that are themselves remediation targets. §2.1/§2.3 measure-steps unchanged (spine, confirmed sound) | COMPLIANT |
| architect-doc-reality-reconciliation [architect] | Realized consumers named by file + symbol, never line-as-identity: `tracker_links_validate_id_shapes`/`_tlk_is_valid_pack_id` (tracker-links.sh), `tracker_phase_task_dependency_re`/`DEP_ENTRY` (tracker-phase-task.sh), `tracker_promote_compose_phase_task_block` (tracker-promote.sh), `_CHECK_40_FILE_EXTS`/`_DENY_LIST_FILENAMES`/`check_project_side_bare_internal_refs` (validate-pack.py); line numbers used only as grep coordinates, paired with the symbol | COMPLIANT |
| Foundation principles binding | categorical-principle-first (K2.2/leaks default to contamination), directory-based-not-ship-based (K4 by location; `supporting-docs/` prefix rule §2.2), deliverable-only+cleanliness (K1.6/K5.13/K5.14), never-read-contaminated (NUD-3), delete-by-default (NUD-2 Option A, K3.11), distrust-derived-claims (every finding re-read at file:line — §5) — all applied explicitly | COMPLIANT |
| deferral-is-scope-creep / no-deferral-without-user-direction [universal] | All 67 land in v11.0 across C1-C9; the NEW `.mcp.json.example:9` leak is folded into C3 (v11.0), not deferred; NUD items are user-decision gates within v11.0, NOT deferrals; blast radius of JC-2 (the NEW leak) surfaced in §4 | COMPLIANT |
| no-false-dichotomy (NUD-1) [foundation] | §2.1 + §4 NUD-1 RE-FRAMED: the prior A-vs-B dichotomy (B = strip the shared validator) was a strawman violating JC-1's own-backlog clause; removed. The strip locus is stated as SETTLED (strip phase-task grammar + dispatch-guard only) and the real decision surfaced honestly — reclassify K1.11–K1.14 NOT-A-DEFECT (recommended) vs retain-as-contamination | COMPLIANT |
| edit-in-place-not-full-rewrite [universal] | Targeted edits to the named sections only (§2.2 measure table/Step2/Step4/Step5; §2.1 boundary-call/Step3/Step5; §1 K1.11-K1.14 + K4.4 rows; §3 C1b/C7/dependency-notes; §4 NUD-1; header note; EEB-8). Spine re-read post-edit and confirmed intact: 67-finding mapping (`grep -c '^| [KB]' §1` rows unchanged in count), JC-rulings columns, the 9-commit DAG (C1-C9 rows present), Check-36 keywords (pack-only/project-only/PM-only/no-keyword assignments unchanged), the new `.mcp.json.example` leak (still in C3 + §4 note) | COMPLIANT |
| rules-applied-verification-block [universal] | This table | COMPLIANT |
| agents-never-commit [universal] | No `git add/commit/push/tag` issued; only Read + read-only Bash (grep/find/sed/ls/cat-heredoc-to-own-output) + Write to the single output doc; `git status --short` at start showed pre-existing deletes (prison) untouched by me | COMPLIANT |
| preflight-stop-means-stop [universal] | No parent stop/halt issued during the task; design-only doc; PREFLIGHT line emitted before final report | COMPLIANT |
