# CENSUS — BD-243 deferred-feature mentions across the operating-doc IN set (the non-BD-tagged axis §B.2 missed)

Architect: FRESH measure-then-bound census instance (pack-architect, RO). Did NOT author DESIGN-BD-243.md / -FINAL / -FINAL-V2; am NOT the adversarial reviewer; reached my own verdicts.
Runtime HEAD `0592a818bf1c0f84322e83dac5da2db48e3ab82e` (CG-01/02/03 LANDED; CG-04 patch PENDING, not committed), branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, clean tree.
Charge: produce the complete content-anchored, commit-group-mapped census of EVERY **deferred-feature mention** across the operating-doc IN set — the axis with NO Check-65 gate backstop (Check 65 catches only date/SHA/BD-tag/User-locked/incident/carry-over residue; it CANNOT regex "is this feature shipped?"). §B.2 was BD-token-indexed and structurally MISSED the non-BD-tagged deferred-feature prose. This census is that axis's measure-then-bound.

## RUNTIME NOTE — HEAD has advanced past the design's a847f12
The DESIGN/PLAN measured at `a847f12` (the BD-243 open commit). Since then CG-01 (`eec6727` gate code), CG-02 (`7de1fbc` nuclear pack-help strip), CG-03 (`0592a81` = HEAD, the new governance rule + Check-65 self-ref allowlist) have LANDED. CG-04 (pack-ops strips) is the PENDING patch in `/tmp/pack-handoff-bd243-impl/IMPL-CG-04.md` — NOT yet committed. Consequences for this census:
- Both `HELP-FRAGMENT-TRACKER.md` files are already DELETED (CG-02). Refs TO them in other docs are now DANGLING and are leak/scrub targets (ADDENDUM-A territory).
- The pack-root + project-template trinity ALREADY carry the new `operating-docs-no-history-no-bloat` rule (CG-03). This makes the surviving tracker passages in the SAME files (pack CLAUDE.md L597-610, project CLAUDE.md L222-243) **self-inconsistent** — they violate the rule sitting beside them. Higher-priority strip.
- The pack-ops files (RATIONALE / MERGE / CONCEPTUAL / DRY-RUN / etc.) at HEAD still carry pre-CG-04 content — the CG-04 patch has NOT landed, so this census reads their current (unstripped) state and is consistent with what CG-04 will consume.

---

## 1. TERM SET USED (exact grep vocabulary + commands)

IN file list built into `/tmp/bd243-in-files.txt` = **143 files** at HEAD (pack root trinity 3; pack-ops 9 live — HELP-FRAGMENT-TRACKER already deleted; pack skills 11; pack agents 5; pack stream-meta 4 [`_rules`×2 + `_intro`×2]; project trinity 3; project docs/pack 5 [incl. HELP-FRAGMENT.md]; project prompts 10; project skills 37; project agent-defs 16×3=48; RUNTIME-SUBAGENT-PATTERN 1; project stream-meta 7 [`_rules`×3 + `_format`×1 + `_intro`×3]).
NB: the design's "~145"/"~136" are nominal; the live IN set at HEAD is 143 files (HELP-FRAGMENT-TRACKER×2 gone; the 5 `_intro` + HELP-FRAGMENT family are gate-EXEMPT per design §A V2 but still grepped here for the LEAK axis).

Commands run (all read-only; full output captured in §7 Empirical-Evidence Blocks):
```
grep -ric "tracker"                        $(cat /tmp/bd243-in-files.txt)      # the big one — per-file count
grep -n  -i "tracker"          <each non-zero file>                            # line-anchored
grep -rni "phase b"                        $IN
grep -rni "grouping"                       $IN
grep -rni "product specialist|product-specialist" $IN
grep -rni "phase part|phase-part|sub-part|subpart" $IN
grep -rn  "v11\.1|v11\.x"                  $IN
grep -rn  "bgIsolation"                    $IN
grep -rni "auditor-issue-tracking|pack-auditor" $IN
grep -rniE "when .*lands|until .*ships|once .*(lands|ships)" $IN
grep -rni "roadmap"                        $IN
grep -rni "not yet"                        $IN
grep -rniE "slated|planned post|future pack version|future version|future resumption|future release" $IN
grep -rn  "BD-215|BD-185|BD-217|BD-218|BD-233|BD-109|BD-110|BD-234" $IN
```
Graph queried FIRST for discovery (`graphify query "tracker mode deferred feature mentions operating docs" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 2000`) → returned only `backlog/_toc.md` orientation nodes (STALE for BD-243-era surfaces) → G2 fallback to grep/Read IMMEDIATELY. The authoritative count is the grep over the named IN set (verification gate); the graph was used only to attempt recall-widening.

## Classification legend
- **STRIP** = describes a DEFERRED / unimplemented / off-by-default feature (even merely to say it is deferred/coming/roadmap). State only what currently exists and operates.
- **KEEP** = documents CURRENT operative behavior, even if it names a dormant mechanism (a Check-required token; what the CODE does today; a dormant-CODE guard; a live cross-ref to an existing doc).
- **JUDGMENT** = genuinely ambiguous; default recommended with reasoning.
- **LEAK?** = `Y` if the STRIP occurrence is on a CLIENT-FACING surface (`project-template/`) — higher priority (advertising a deferred feature to clients).
- **CG** = commit-group that owns the file (per PLAN §5 + ADDENDUM-A). Content-anchored quotes/headings, NOT line numbers (they drift under in-flight strips).

---

## 2. PER-FEATURE ENUMERATION (every occurrence; content-anchored; STRIP/KEEP/JUDGMENT)

### 2.1 — Tracker mode (BD-214) — THE big one (the dominant axis; client-facing rows flagged LEAK=Y are the highest-priority strips)

| File | Content anchor (quote/section) | CG | Verdict | Rationale | LEAK? |
|---|---|---|---|---|---|
| `CLAUDE.md` (pack) | "Tracker (GH Issues) integration is DEFERRED indefinitely … tracker mode is BLOCKED on both surfaces and the tracker code is retained DORMANT…" (Project goals / Repo-conventions passage) | CG-08 | **STRIP** | Deferred-feature description. State only "Flat-file per-entry is the sole supported mode." NB this sits BESIDE the new no-deferred-feature rule (CG-03 landed) → self-inconsistent. | N |
| `CLAUDE.md` (pack) | "flat-file is the sole supported mode; tracker mode is deferred — BD-214)" (PACK-CHAT-table-style line / repo conventions) | CG-08 | **STRIP** | Deferred-feature mention + BD provenance (covered §B.2 BD-214 row; the non-BD prose "tracker mode is deferred" is the NEW part). | N |
| `CLAUDE.md` (pack) | "Flat-file per-entry is the sole supported mode; tracker integration is deferred…" (Project goals (v11) bullet) | CG-08 | **STRIP** | Deferred-feature mention; no BD token → §B.2 MISSED it. | N |
| `AGENTS.md` / `GEMINI.md` (pack) | parallel sites (trinity-locked ×3) | CG-08 | **STRIP** | Trinity parity — same 3 passages each. | N |
| `pack-ops/OPTIONAL-FEATURES.md` | whole "## Tracker integration (deferred)" section + "Why it is deferred — the ability to flip to tracker mode is BLOCKED…" + "No surface opts any repo into tracker mode…" | CG-04 (WU-OPTFEAT-PACK) | **STRIP** | Operating IN doc; §0 unconditional. Whole deferred-feature section. (Design §B.2/V2 already names this — covered, not new.) | N |
| `pack-ops/MERGE-STRATEGY.md` | "client-installed tracker.toml.example (sourced from `project-template/tracker.toml.project-example`)" (the Phase-A file-set prose) | CG-04 (WU-MERGE) | **JUDGMENT → STRIP** | Describes a tracker artifact the migrator would install in tracker mode — a deferred-feature mechanism. NOT in §B.2 (BD provenance + BD-109/110 only). NEW. See §3 adjudication of the CG-04 surfaced item. | N |
| `pack-ops/MERGE-STRATEGY.md` | "Gate 3 — post-Phase-B verification … **conditionally** on tracker mode being active … When tracker mode is active it checks: id-map.json integrity, BACKLOG.md mirror freshness, and `pack tracker doctor` exit-status." | CG-04 (WU-MERGE) | **JUDGMENT → SPLIT** | The flat-file half ("In flat-file mode it prints `[INFO] tracker: skipped` and returns 0") is CURRENT CODE behavior = **KEEP**. The "When tracker mode is active it checks…" half is the deferred-feature branch = **STRIP**. Reduce to: "Gate 3 runs only in tracker mode; in flat-file mode it prints `[INFO] tracker: skipped` and returns 0." NEW (not in §B.2). | N |
| `pack-ops/MERGE-STRATEGY.md` | "Gate 3 FAIL … Run `pack tracker doctor` … `pack tracker reset` + `pack tracker init` from a clean state." (recovery verbs) | CG-04 (WU-MERGE) | **STRIP** | Recovery verbs for the deferred tracker mode (an unreachable Gate 3 path in flat-file). NEW. | N |
| `pack-ops/MERGE-STRATEGY.md` | See-also: "`docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough (post-install client path…)" | CG-04 (WU-MERGE) | **STRIP** | Cross-ref to a deferred-tracker walkthrough whose target section is itself being stripped (project OPTIONAL-FEATURES tracker section, CG-10). Dangling-after-strip. NEW. | N |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | race-heuristic examples "Tracker init + customization preserve…", "Forward migrate + cycle-check store … `tracker_links_create_blocked_by`…" | CG-04 (WU-CONCEPTUAL) | **JUDGMENT → STRIP** | Worked examples illustrating methodology USING dormant-tracker mechanics — they describe deferred-feature internals. Replace with a non-tracker race example (the methodology survives; the tracker illustration is a deferred-feature mention). NEW (not in §B.2's BD-110/136 rows). | N |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | design-principle table rows "every tracker forward must have a reverse…", "`tracker_error_emit` envelope", "flat-file and tracker mode share the same logic", "`pack tracker init`, `pack td promote`" | CG-04 (WU-CONCEPTUAL) | **JUDGMENT → STRIP (tracker clauses only)** | These are best-practice PRINCIPLES illustrated with deferred-tracker examples. KEEP the principle (bidirectionality / typed-errors / idempotency); STRIP the tracker-specific illustration. (`pack td promote` is a LIVE verb → may stay as the idempotency example.) NEW. | N |
| `pack-ops/PACK-CHAT.md` | "(flat-file is the sole supported mode; tracker is deferred — BD-214)" (per-entry-source table cell) | CG-04 (WU-PACKCHAT) | **STRIP** | Deferred-feature parenthetical; keep "flat-file is the sole supported mode". (§B.2 BD-214 row covers the BD token; the prose is the NEW axis.) | N |
| `pack-ops/PACK-CHAT.md` | "Flat-file is the sole supported mode. Tracker (GH Issues) integration … surfaces and the tracker code is retained dormant for a future resumption." | CG-04 (WU-PACKCHAT) | **STRIP** | Deferred-feature description block. | N |
| `pack-ops/PACK-CHAT.md` | "(`scripts/lib/recommendation.sh`) surfaced a tracker opt-in recommendation during `/pack-startup`. Tracker (GH Issues) integration … retained dormant…" | CG-04 (WU-PACKCHAT) | **STRIP** | Deferred-feature narration (the recommendation that "surfaces nothing" today). | N |
| `pack-ops/DRY-RUN-MIGRATION.md` | "**Tracker opt-in (Phase B).** Not part of the v10->v11 migrator; not exercised by the dry-run." (Limitations list) | CG-04 (WU-DRYRUN) | **STRIP** | Deferred-feature ("Tracker opt-in", "Phase B") in a Limitations list. NOT in §B.2 (DRY-RUN row = BD-125/114/088/042 only). NEW — the CG-04 coder flagged this; verdict = STRIP (§3). | N |
| `pack-ops/DRY-RUN-MIGRATION.md` | "…`HELP-FRAGMENT*.md`, `tracker.toml.example`, …" (a copied-files enumeration) | CG-04 (WU-DRYRUN) | **JUDGMENT → KEEP** | Lists files the dry-run COPIES TODAY; `tracker.toml.example` is a dormant artifact the migrator copy logic still names. If the copy still happens it is current behavior = KEEP; if the file no longer copies post-CG-02, STRIP the token. Coder VERIFIES against the live copy list. Default KEEP pending verify. | N |
| `backlog/_rules.md` (pack) | "**Tracker mode (deferred).** Tracker (GH Issues) integration is … flip to tracker mode is BLOCKED … `tracker_mode()` clamps to flat-file and the `pack tracker` flip verbs refuse with a deferred message. The tracker code is retained DORMANT…" | CG-05 (WU-BACKLOG-RULES) | **STRIP** | OQ-FINAL-3: rewrite to operative-only "This stream is flat-file per-entry." The whole "Tracker mode (deferred)" block is a deferred-feature description. (§B.2 names BD-214/215/060 tokens; the non-BD prose block is the bulk.) | N |
| `backlog/_rules.md` (pack) | "Flat-file is the sole supported mode (tracker mode is …" (later operative line) | CG-05 | **STRIP** | Deferred-feature contrast; keep "Flat-file is the sole supported mode." | N |
| `changelog/_rules.md` (pack) | "unconditionally: tracker (GH Issues) integration is deferred (BD-214), … tracker migration never reads or writes `/changelog/`." | CG-05 (WU-CHANGELOG-RULES) | **STRIP** | Deferred-feature mention; the operative fact ("the changelog stream is flat-file") survives. | N |
| `backlog/_intro.md` (pack) | "Tracker (GH Issues) integration is deferred (BD-214); see `_rules.md`" | CG-05 (WU-PACK-INTRO) | **STRIP** | G1 user ruling (gate-EXEMPT → reviewer leak-check, not Check 65). Self-inconsistent orientation. | N |
| `project-template/CLAUDE.md` | "Document locations" preamble: "tracker mode is deferred indefinitely (no release version — tracker code is retained dormant for a future resumption), so all rows read `flat`." | CG-09 (WU-PROJ-TRINITY) | **STRIP** | CLIENT-FACING. Reduce to "all rows read `flat` (flat-file per-entry is the sole supported mode)." NB sits BESIDE the new rule (CG-03 landed in this file) → self-inconsistent. (§B.3 covers — confirmed, not new.) | **Y** |
| `project-template/CLAUDE.md` | "Per-entry source-of-truth trees (v11.0)" para: "tracker integration is deferred indefinitely (no release version) with the tracker code retained dormant for a future resumption." | CG-09 | **STRIP** | CLIENT-FACING. (§B.3 covers.) | **Y** |
| `project-template/AGENTS.md` / `GEMINI.md` | parallel sites ×2 each (trinity-locked) | CG-09 | **STRIP** | CLIENT-FACING trinity parity (§B.3's "6 sites"). | **Y** |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | whole "## Tracker integration (deferred)" section ("Status — DEFERRED…", "What it was…", "Current state — tracker integration is deferred…") | CG-10 (WU-OPTFEAT-PROJ) | **STRIP** | CLIENT-FACING deferred-feature section (leak L-6). | **Y** |
| `project-template/docs/pack/PM-CHAT.md` | "The D-19 tracker opt-in recommendation is DEFERRED to a future release: tracker …" | CG-10 (WU-PMCHAT-PROJ) | **STRIP** | CLIENT-FACING (leak L-7). | **Y** |
| `project-template/docs/pack/PM-CHAT.md` | "(… sole supported mode; tracker integration is deferred to a future release)." + "(The tracker-entity / `tracker_links_create_blocked_by` orchestration is retained dormant for a future tracker resumption.)" | CG-10 | **STRIP** | CLIENT-FACING (leak L-7); keep the live flat-file directive. | **Y** |
| `project-template/docs/pack/prompts/auditor.md` | "(… mode; tracker integration is deferred to a future release.)" | CG-10 (WU-PROMPT-auditor) | **STRIP** | CLIENT-FACING parenthetical (leak L-8); keep flat-file statement. | **Y** |
| `project-template/docs/pack/prompts/coder.md` | "(Flat-file per-entry is the sole supported mode; tracker integration is deferred to a future release.)" | CG-10 (WU-PROMPT-coder) | **STRIP** | CLIENT-FACING deferred clause (leak L-9); keep "flat-file is the sole supported mode". | **Y** |
| `project-template/skills/pm-startup/SKILL.md` | "Flat-file per-entry is the sole supported mode; tracker integration is deferred to a future release." + "Step 7 is reserved. The tracker-mode triage queue … would land here if tracker integration resumes (it is DEFERRED…)." + "The D-19 tracker opt-in recommendation is DEFERRED to a future release…" (Step 8 deferred) | CG-10 (WU-SKILL-pm-startup) | **STRIP** | CLIENT-FACING (leak L-10): strip the deferred clause + the Step-7 reserved comment + the deferred Step 8; keep the live step flow. | **Y** |
| `project-template/docs/project/{backlog,changelog,implementation-plan}/_intro.md` | "Tracker mode is deferred indefinitely (no release version); the ability to flip to a tracker (e.g., GH Issues) is blocked and the tracker code is retained dormant for a future resumption." (3-line block ×3) | CG-10 (WU-PROJ-INTRO) | **STRIP** | CLIENT-FACING (leak L-11): gate-EXEMPT but client-shipped → reviewer leak-check. Keep "flat-file is the sole supported mode." | **Y** |

### 2.2 — Tracker DANGLING refs to the deleted `HELP-FRAGMENT-TRACKER.md` (CG-02 already deleted the files; these now dangle)

These are NOT "deferred-feature" per se — they reference a now-DELETED operating artifact. They are ADDENDUM-A (a)-ruling scrubs (user: "The name shouldn't exist anywhere … especially not in a way that classifies it as a current document that's in use"). Listed here for completeness because they co-locate with tracker prose and a deferred-feature reviewer will hit them.

| File | Content anchor | CG | Verdict | Rationale |
|---|---|---|---|---|
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | boundary-note list "…`pack-ops/HELP-FRAGMENT-TRACKER.md`, `supporting-docs/METHODOLOGY.md`…" | CG-04 (WU-CONCEPTUAL) | **STRIP** (ADDENDUM-A) | Names a deleted file in a project-side-surface review list. Already in ADDENDUM-A. |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | "`pack-ops/HELP-FRAGMENT-TRACKER.md` from the inventory but didn't update" + "`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` ships to clients here — the `pack-ops/HELP-FRAGMENT-TRACKER.md` copy is NOT a fixture input" | CG-04 (WU-RATIONALE) | **STRIP** (ADDENDUM-A) | Already in ADDENDUM-A (L173 inventory note; L524-525 fixture prose). |
| `pack-ops/BOUNDARY-DEFINITION.md` | C2 inventory "…`HELP-FRAGMENT-PACK.md`, `pack-ops/HELP-FRAGMENT-TRACKER.md`, `pack-ops/OPTIONAL-FEATURES.md`…" | CG-04 (WU-BOUNDARYDEF) | **STRIP** (ADDENDUM-A) | Classifies a deleted file as a current pack-ops operating doc. Already in ADDENDUM-A. |
| `.claude/skills/boundary-investigation/SKILL.md` (PACK ×3 tracked copies) | bare-filename refs "`HELP-FRAGMENT-TRACKER.md` … pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md`" + the boundary example set | CG-06 (WU-SKILL-boundary-investigation PACK) | **REWRITE** (ADDENDUM-A) | Example set references the deleted fragment. Already in ADDENDUM-A. |
| `project-template/skills/boundary-investigation/SKILL.md` | same bare-filename refs (client copy) | CG-10 (WU-SKILL-boundary-investigation PROJECT) | **REWRITE** (leak L-14) | Already planned (PLAN line 178). |

### 2.3 — Codex/Antigravity worktree (BD-217) + bgIsolation background-session (BD-218) — v11.1 forward-looks

| File | Content anchor | CG | Verdict | Rationale | LEAK? |
|---|---|---|---|---|---|
| `CLAUDE.md` (pack) | "`worktree.bgIsolation` governs background SESSIONS only (not sub-agents) — BD-218. Trinity-exempt (Claude-only; Codex/Antigravity = BD-217)." | CG-08 | **STRIP (forward-look only)** | KEEP "bgIsolation governs background sessions only" (current operative fact — the `bgIsolation` token is Check-54-required). STRIP "— BD-218" + "Codex/Antigravity = BD-217" (deferred cross-CLI forward-look). §B.2 BD-218/217 rows cover the tokens; verdict consistent. | N |
| `CLAUDE.md` (pack) | "Codex/Antigravity = BD-217" / "coordinate BD-217" / "cross-CLI mapping is BD-217" (×5 across the sub-agent section) | CG-08 | **STRIP** | Deferred cross-CLI worktree/peer-messaging mapping. §B.2 BD-217 ×5 row covers. | N |
| `CLAUDE.md` (pack) | "their worktree story is a future pack version. Do NOT 'restore parity' by porting…" | CG-08 | **JUDGMENT → KEEP** | This is an OPERATIVE INSTRUCTION (do-not-port) about CURRENT asymmetry, not an advertisement of a deferred feature. The "future pack version" clause is incidental to a live anti-action directive. Default KEEP; if reviewer judges the "future pack version" phrase itself is the deferred-feature mention, trim that 4-word clause only, keeping the do-not-port directive. NEW (no BD token). | N |
| `AGENTS.md` / `GEMINI.md` (pack) | "cross-CLI EFFECTIVENESS — is verified separately under BD-233; the rule…" | CG-08 | **STRIP** | Deferred cross-CLI-effectiveness verification. §B.2 BD-233 row covers (AGENTS/GEMINI only). | N |
| `pack-ops/OPTIONAL-FEATURES.md` | "The background-session isolation story is tracked under BD-218 (v11.1); do not set `bgIsolation` expecting it" | CG-04 (WU-OPTFEAT-PACK) | **STRIP (forward-look)** | KEEP the `bgIsolation` enum/default operative spec (Check-54-required token). STRIP the "tracked under BD-218 (v11.1); do not set … expecting it" deferred-feature forward-look. §B.2 BD-218 row covers. | N |
| `pack-ops/OPTIONAL-FEATURES.md` | "tracked under BD-217 (v11.1). There is no cross-CLI parity claim here." | CG-04 (WU-OPTFEAT-PACK) | **STRIP (forward-look)** | STRIP the "tracked under BD-217 (v11.1)" deferred ref; the "no cross-CLI parity claim" operative fact may stay reworded. §B.2 BD-217 row covers. | N |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | "Cross-CLI coordination = BD-217." / "`agy` analogs exist but need their own verification + mapping (BD-217)." / "Codex/Antigravity is BD-233." | CG-04 (WU-RATIONALE) | **STRIP** | Deferred cross-CLI forward-looks. §B.2 RATIONALE BD-217/233 rows cover. | N |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | "The background-session isolation story is a separate concern slated for a future pack version; do not set `bgIsolation` expecting it" | CG-10 (WU-OPTFEAT-PROJ) | **STRIP (forward-look)** | CLIENT-FACING. KEEP the `bgIsolation` operative spec; STRIP the "slated for a future pack version; do not set … expecting it" deferred forward-look. NEW (no BD token client-side) — §B.3 said project history-provenance ≈ 0 and only covered tracker; this bgIsolation forward-look was MISSED. | **Y** |
| `project-template/docs/pack/PM-CHAT.md` | "Codex / Antigravity equivalents are a future pack version." (worktree-reuse note) + "Codex / Antigravity equivalents are a future pack version." (rule-9 note L564) | CG-10 (WU-PMCHAT-PROJ) | **STRIP (forward-look)** | CLIENT-FACING deferred cross-CLI forward-look. NEW — not in §B.3 (tracker-only). Keep the Claude-only operative rule; drop the "future pack version" promise. | **Y** |

### 2.4 — Auditor-issue-tracking / pack-auditor agent (BD-109/110) — unbuilt agent + future migration

| File | Content anchor | CG | Verdict | Rationale | LEAK? |
|---|---|---|---|---|---|
| `pack-ops/MERGE-STRATEGY.md` | "`auditor-issue-tracking` agent (BD-109 / BD-110) is on the v11.x roadmap and routes through the same class once it ships." | CG-04 (WU-MERGE) | **STRIP** | Roadmap mention of an unbuilt agent. §B.2 MERGE BD-110/109 row covers (verdict consistent). The non-BD "is on the v11.x roadmap … once it ships" prose is the deferred-feature axis. | N |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | "**Status:** v11.0 working methodology. Folds into the `audit-methodology` SKILL when BD-110 lands. Until then, this doc is the canonical source." | CG-04 (WU-CONCEPTUAL) | **STRIP (rewrite)** | The "Folds … when BD-110 lands. Until then…" future-migration scaffolding is a deferred-feature mention. Rewrite to "This doc is the canonical conceptual-review methodology." §B.2 BD-110 row covers; the non-BD scaffolding prose is the bulk. | N |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | "**Preferred (when available):** `pack-auditor` agent (BD-110, lands in Batch 21). … **Fallback before BD-110 lands:** `pack-architect` invoked with explicit conceptual-review prompt…" | CG-04 (WU-CONCEPTUAL) | **STRIP (rewrite to current path)** | Describes an unbuilt agent's future preference. The OPERATIVE instruction TODAY is the architect-with-conceptual-prompt path → rewrite to name ONLY that; drop the unbuilt-agent preference + the "when BD-110 lands" scaffolding. §B.2 BD-110×5 row covers. | N |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | "## Future integration — When BD-110 (Batch 21) lands the `pack-auditor` agent + `audit-methodology` SKILL: 1. Fold this … 2. … 3. … 4. …" | CG-04 (WU-CONCEPTUAL) | **STRIP (whole section)** | The whole "## Future integration" section describes a future migration of an unbuilt agent. §0 maximal removal: delete the section. NEW (the section is non-BD-headed; §B.2 named only the BD-110 token inside it). | N |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | "changing the `derived-from:TD-NNN` label format breaks BD-106 + BD-107 + future BD-110 auditor." | CG-04 (WU-CONCEPTUAL) | **STRIP ("future BD-110 auditor" clause)** | "future BD-110 auditor" is a deferred-feature ref inside a worked example. Keep the contract-touch-point example; drop the unbuilt-auditor reference. §B.2 covers BD-106/107/110 as provenance. | N |

### 2.5 — Entry-format redesign (BD-215) — deferred dependency of the deferred tracker

| File | Content anchor | CG | Verdict | Rationale | LEAK? |
|---|---|---|---|---|---|
| `pack-ops/OPTIONAL-FEATURES.md` | "…on the entry-format redesign (BD-215) landing first." | CG-04 (WU-OPTFEAT-PACK) | **STRIP** | Deferred-dependency-of-a-deferred-feature. §B.2/OPTIONAL BD-215 row covers. | N |
| `backlog/_rules.md` (pack) | "redesign (BD-215) landing first. Until then this stream is flat-file in…" | CG-05 (WU-BACKLOG-RULES) | **STRIP** | OQ-FINAL-3: rewrite to "This stream is flat-file per-entry." §B.2 BD-215 row covers; the "Until then…" prose is the deferred-feature axis. | N |

### 2.6 — BD-234 graph-cost re-tune (Open; future re-tuning)

| File | Content anchor | CG | Verdict | Rationale | LEAK? |
|---|---|---|---|---|---|
| `pack-ops/OPTIONAL-FEATURES.md` | "That file is the input **BD-234** consumes to confirm or re-tune cadence… Cadence direction is LOCKED for now; do NOT change cadence here — BD-234 re-tunes with measured numbers." | CG-04 (WU-OPTFEAT-PACK) | **STRIP (forward-promise)** | KEEP "Cadence direction is LOCKED for now; do NOT change cadence here" (operative directive). STRIP "the input BD-234 consumes to confirm or re-tune … BD-234 re-tunes with measured numbers" (deferred re-tuning forward-promise). §B.2 OPTIONAL BD-234 row covers. | N |

### 2.7 — Phase-parts hierarchy (BD-185) + Groupings (BD-186/189) + Product Specialist (BD-191/192)

- **Phase-parts (BD-185):** grep found NO deferred-feature MENTION of a phase-parts HIERARCHY as a coming feature. The "sub-part" hits (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` "A sub-part of an existing BD lives as a SECTION"; `backlog/_rules.md` "sub-part is an in-body section, not a suffixed entry"; `pack-ops/BOUNDARY-DEFINITION.md` "phase / phase-part / phase-task … operationally") are all **KEEP** — they document the CURRENT no-suffix entry rule + the current ban on project-side concepts on pack surfaces (operative). The BD-185 hits in RATIONALE/`review`-skill are P4 incident provenance (`User-locked 2026-05-27 during BD-185 reconciliation`) → STRIP as HISTORY (Check-65 axis, already in §B.2/EE-8), NOT as deferred-feature. **No deferred phase-parts feature is advertised anywhere in the IN set.** SUPPORTED by EE-PP below.
- **Groupings (BD-186/189):** grep `grouping` found ZERO references to the pack GROUPINGS feature. All hits are accessibility "grouping/traits" (auditor-ui agent defs + audit-methodology skill) = generic UI vocabulary = **KEEP** (not the pack groupings feature). **No groupings feature is mentioned in the IN set.** SUPPORTED by EE-GRP.
- **Product Specialist (BD-191/192):** grep `product specialist|product-specialist` = ZERO hits across the IN set. **No mention.** SUPPORTED by EE-PS.

### 2.8 — Platform-architecture future skills (web / Android / embedded / CoreData / SQLite) — NEW deferred-feature axis §B.3 MISSED entirely

This is a deferred-feature axis the design never censused (it focused on tracker + the BD-tagged set). These are CLIENT-FACING skill bodies advertising skills that do not exist yet.

| File | Content anchor | CG | Verdict | Rationale | LEAK? |
|---|---|---|---|---|---|
| `project-template/skills/audit-methodology/SKILL.md` | "Cross-platform UI checklist (… web / Android / embedded-MCU once those skills land, deferred to a future version, currently planned post-v11.0):" (rule 20) | CG-12 (WU-SKILL audit-methodology) | **JUDGMENT → STRIP (forward-look)** | KEEP the operative "applies whenever any UI platform skill is loaded — Apple today". STRIP the "web / Android / embedded-MCU once those skills land, deferred to a future version, currently planned post-v11.0" deferred-feature forward-look. NEW (not in §B.3). | **Y** |
| `project-template/skills/audit-methodology/SKILL.md` | "Non-Apple UI detection markers (web, Android, embedded) are added by the corresponding platform-architecture skills, deferred to a future version (currently planned post-v11.0); once those skills land, this detection list extends…" (rule 44) | CG-12 | **STRIP (forward-look)** | KEEP "the current detection list is Apple-centric"; STRIP the deferred future-skill promise. NEW. | **Y** |
| `project-template/skills/apple-swiftdata-patterns/SKILL.md` | "companion rules for CoreData (predecessor) and direct SQLite (GRDB / sqlite3) are out of scope for this skill and may ship as separate `apple-coredata-patterns` / `apple-sqlite-patterns` skills in a future release." | CG-12 | **JUDGMENT → STRIP (forward-look)** | KEEP "companion rules for CoreData and direct SQLite are out of scope for this skill." STRIP "and may ship as separate … skills in a future release" (deferred-feature advertisement). NEW. | **Y** |
| `project-template/docs/pack/PACK-FEEDBACK.md` | "Android, Windows, embedded, and web platforms have deferred skills (not yet created). If the project targets a platform without dedicated skills, note what rules…" | CG-13 (WU-DOCSPACK PACK-FEEDBACK) | **JUDGMENT → STRIP (deferred clause)** | KEEP the operative "If the project targets a platform without dedicated skills, note what rules or patterns were missing." STRIP "have deferred skills (not yet created)" — it advertises deferred skills. JUDGMENT: borderline because the surrounding instruction is the operative feedback-capture mechanism; default STRIP the "deferred skills (not yet created)" phrase, keep the capture instruction. NEW. | **Y** |

### 2.9 — Codex/Antigravity peer-messaging + agent-team analogs (NOT deferred-feature — current-state caveats) — KEEP set

| File | Content anchor | Verdict | Rationale |
|---|---|---|---|
| `project-template/GEMINI.md` | "`agy` version does not yet accept the plugin `agents/` template schema, fall…" | **KEEP** | Documents a CURRENT-STATE fallback (what to do TODAY when a real, shipping `agy` version lacks the schema) — operative degradation instruction, not a deferred-feature advertisement. |
| `project-template/skills/audit-methodology/SKILL.md` (rule 58) | "where the plugin `agents/` template schema is not yet accepted, from the runtime `define_subagent` / `invoke_subagent` pattern…" | **KEEP** | Operative CURRENT fallback path. |
| `project-template/.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` | "path is not yet available on your `agy` version." / "If your `agy` version does not yet accept the plugin `agents/` template schema…" | **KEEP** | This whole doc IS the operative current-fallback mechanism. |
| `.claude/skills/verification-harness/SKILL.md` | "a single shared lib is a future optimization, not a [requirement]" | **KEEP** | An operative design-rationale ("don't build the shared lib now") — explains a CURRENT choice; not advertising a deferred pack feature the reader must know about. JUDGMENT-leaning-KEEP; if a reviewer reads "future optimization" as a roadmap mention, the 6-word clause may trim, but the directive (single shared lib not required) is operative. |

---

## 3. RECONCILIATION with §B.2 / §B.3 + verdicts on the 4 CG-04 surfaced items

### 3.1 — Already-covered vs NEW (so coders do not re-list)

**ALREADY covered by §B.2/§B.3 (BD-token rows — do NOT re-open as new; this census confirms the verdict):**
- Pack trinity BD-214 (tracker passage ×3), BD-217 ×5, BD-218, BD-233 (AGENTS/GEMINI) — §B.2 CLAUDE row.
- `pack-ops/OPTIONAL-FEATURES.md` BD-234/218/217/215/214 + the "## Tracker integration (deferred)" section — §B.2 OPTIONAL row + V2 W2.
- `pack-ops/MERGE-STRATEGY.md` BD-110/109 roadmap mention — §B.2 MERGE row.
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` BD-110 ×5 future-migration scaffolding — §B.2 CONCEPTUAL row.
- `pack-ops/PACK-CHAT.md` BD-214 ×3 — §B.2 PACK-CHAT row.
- `backlog/_rules.md` BD-215/214/060 + OQ-FINAL-3 rewrite — §B.2 backlog/_rules row.
- `changelog/_rules.md` BD-214 + `backlog/_intro.md` BD-214 — §B.2 / G1.
- Project trinity tracker passage (6 sites) — §B.3 / leak L-1/2/3.
- Project OPTIONAL-FEATURES / PM-CHAT / auditor / coder / pm-startup / `_intro`×3 tracker — §B.3 V2 leak L-6..L-11.

**NEW — NOT in §B.2/§B.3 (the non-BD-tagged deferred-feature prose this census ADDS):**
1. `pack-ops/MERGE-STRATEGY.md` — the `tracker.toml.example` install prose; **Gate 3** tracker-active branch (the deferred half); the `pack tracker doctor/reset/init` recovery verbs; the "tracker opt-in walkthrough" See-also cross-ref. (4 NEW MERGE sites — none carry a BD token.)
2. `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` — the tracker WORKED EXAMPLES (race-heuristic "Tracker init…", "`tracker_links_create_blocked_by`…") + the design-principle table tracker illustrations + the whole "## Future integration" section. (Non-BD-headed prose §B.2's BD-110 token-rows did not enumerate.)
3. `pack-ops/DRY-RUN-MIGRATION.md` — "**Tracker opt-in (Phase B).**" Limitations bullet. (NEW — DRY-RUN's §B.2 row was BD-125/114/088/042 only.)
4. `pack-ops/PACK-CHAT.md` — the two non-BD tracker prose blocks (the recommendation-narration + the "Flat-file is the sole supported mode. Tracker (GH Issues) integration … dormant" block). (§B.2 named the BD-214 ×3 tokens; the surrounding non-BD prose is the bulk to remove.)
5. **bgIsolation forward-look on CLIENT side** — `project-template/docs/pack/OPTIONAL-FEATURES.md` "slated for a future pack version; do not set `bgIsolation` expecting it" + `project-template/docs/pack/PM-CHAT.md` "Codex / Antigravity equivalents are a future pack version" ×2. (NEW client-side deferred forward-looks; §B.3 declared project history-provenance ≈ 0 and censused only tracker — these were MISSED.)
6. **Platform-architecture future-skills axis (§2.8)** — `audit-methodology/SKILL.md` (rules 20+44 web/Android/embedded "deferred to a future version, planned post-v11.0"); `apple-swiftdata-patterns/SKILL.md` ("may ship as separate … skills in a future release"); `PACK-FEEDBACK.md` ("deferred skills (not yet created)"). **An entirely NEW deferred-feature axis the design never identified.** 3 of 4 are CLIENT-FACING LEAKS.
7. **CONCEPTUAL "Status" line** — "Folds into the `audit-methodology` SKILL when BD-110 lands. Until then, this doc is the canonical source." (the non-BD scaffolding wrapped around the BD-110 token).

### 3.2 — Verdicts on the 4 CG-04-coder surfaced items (from IMPL-CG-04.md "Out-of-scope observations")

| # | Item (CG-04 coder flag) | Verdict | Rationale |
|---|---|---|---|
| 1 | **DRY-RUN-MIGRATION.md L161 "Tracker opt-in (Phase B). Not part of the v10->v11 migrator; not exercised by the dry-run."** | **STRIP** | Pure deferred-feature mention ("Tracker opt-in", "Phase B") in a Limitations list. It instructs nothing today (the dry-run never exercises it because the feature does not exist). Remove the bullet. Rides WU-DRYRUN / CG-04. |
| 2 | **PACK-CHAT.md L153-159 "Push to v11-dev only during the v11-dev phase" — refs "Batch 24 (the release-pin batch)" + "short-lived (resolves when v11.0 ships)"** | **JUDGMENT → STRIP the temporal/provenance scaffolding; KEEP the operative push rule** | The DIRECTIVE ("push to v11-dev only during the v11-dev phase") is operative TODAY. But "Batch 24 (the release-pin batch)" is HISTORY provenance and "short-lived (resolves when v11.0 ships)" is a roadmap/temporal forward-look. STRIP both wrappers; keep the bare directive. This is BOTH a history-axis (Batch-N) and a deferred-feature-axis (roadmap) strip. NOT a leak (pack-internal). NB Check-65 WILL catch "Batch 24" via the `Commit [0-9]`/history patterns? — NO: "Batch 24" is not in the Check-65 pattern set (it matches `Commit N`/`Override N`, not `Batch N`); so this strip depends on this census + the reviewer, NOT the gate. Surfaced for the WU-PACKCHAT coder scope (currently CG-04 PACK-CHAT row does not name it). |
| 3a | **MERGE-STRATEGY.md L265-266 `tracker.toml.example` install refs** | **STRIP** | Describes installing a tracker artifact = deferred-feature mechanism. |
| 3b | **MERGE-STRATEGY.md L428-433 Gate 3 conditional-on-tracker-mode** | **SPLIT: KEEP the flat-file half, STRIP the tracker-active half** | ADJUDICATION of the design's open question: the coder claimed L428-433 "documents CURRENT flat-file Gate behavior." PARTIALLY true. The CURRENT behavior IS "Gate 3 runs only in tracker mode; in flat-file mode it prints `[INFO] tracker: skipped` and returns 0" — that half is **KEEP** (it documents what the migrator code does TODAY in the only reachable mode). BUT "When tracker mode is active it checks: id-map.json integrity, BACKLOG.md mirror freshness, and `pack tracker doctor` exit-status" describes an UNREACHABLE branch (tracker mode is blocked) = a deferred-feature description = **STRIP**. Net rewrite: "Gate 3 (post-Phase-B) runs only in tracker mode; in flat-file mode it prints `[INFO] tracker: skipped` and returns 0." — drop the tracker-active checklist. |
| 3c | **MERGE-STRATEGY.md L460-462 `pack tracker doctor`/reset/init recovery verbs** | **STRIP** | Recovery verbs for the unreachable Gate-3-FAIL-in-tracker-mode path. Deferred-feature mechanism. Rewrite the "Gate 3 FAIL" bullet to note Gate 3 cannot fail in flat-file mode (it is skipped), or drop the bullet. |
| 3d | **MERGE-STRATEGY.md L487 See-also "tracker opt-in walkthrough" cross-ref** | **STRIP** | Cross-ref to the deferred-tracker walkthrough section (project OPTIONAL-FEATURES tracker section, itself stripped at CG-10). Dangling-after-strip. |
| 4 | **CONCEPTUAL-REVIEW-METHODOLOGY.md tracker worked-examples (race-heuristic + design-principle illustrations)** | **STRIP the tracker illustrations; KEEP the principles** | The methodology PRINCIPLES (bidirectionality, typed-errors, idempotency, mode-agnostic logic) are operative review criteria = KEEP. The tracker-mechanic ILLUSTRATIONS of them are deferred-feature descriptions = STRIP/replace with non-tracker examples. (`pack td promote` is a LIVE verb → may remain as the idempotency example.) |

**Net:** all 4 CG-04 surfaced items resolve to STRIP (3b SPLIT — keep the flat-file half). Items 2, 3a-d are NEW scope the current CG-04 WU rows (PACK-CHAT, MERGE) do not enumerate → the coders need this census's recipe addendum (§4) to cover them.

---

## 4. PER-COMMIT-GROUP ROLLUP (the recipe addendum the coders consume)

Each row = the ADDITIONAL deferred-feature strips that wave must apply BEYOND the §B.2/§B.3 BD-token rows already in the PLAN WU. Content-anchored. (CG-01/02/03 already landed; CG-02 already deleted the fragments — its dangling-ref scrubs are ADDENDUM-A, owned by later CGs.)

### CG-04 (pack-ops operating-doc strips) — the heaviest deferred-feature wave
- **WU-RATIONALE** (`PACK-MEMORY-RATIONALE.md`): + the HELP-FRAGMENT-TRACKER dangling refs (ADDENDUM-A) + the BD-217/233 cross-CLI forward-looks ("Cross-CLI coordination = BD-217", "`agy` analogs … (BD-217)", "Codex/Antigravity is BD-233"). (History/incident strips are §B.2.)
- **WU-MERGE** (`MERGE-STRATEGY.md`): + **NEW** — the `tracker.toml.example` install prose; **Gate 3 SPLIT** (keep flat-file half "prints `[INFO] tracker: skipped` and returns 0"; strip the tracker-active checklist); the `pack tracker doctor/reset/init` recovery verbs (Gate-3-FAIL bullet); the See-also "tracker opt-in walkthrough" cross-ref; the "`auditor-issue-tracking` agent … on the v11.x roadmap … once it ships" sentence.
- **WU-OPTFEAT-PACK** (`OPTIONAL-FEATURES.md`): + the whole "## Tracker integration (deferred)" section (§B.2); the bgIsolation "tracked under BD-218 (v11.1); do not set … expecting it" forward-look (KEEP the enum/default); the BD-217 "(v11.1)" forward-look; the BD-215 "entry-format redesign … landing first"; the BD-234 "re-tunes with measured numbers" forward-promise (KEEP "Cadence direction is LOCKED for now").
- **WU-CONCEPTUAL** (`CONCEPTUAL-REVIEW-METHODOLOGY.md`): + the "Status:" line rewrite (drop "Folds … when BD-110 lands. Until then…"); the "Preferred (when available): `pack-auditor` … Fallback before BD-110 lands" rewrite to the current architect-path only; the whole "## Future integration" section delete; the "future BD-110 auditor" clause in the contract-touch-point example; the tracker worked-examples (race-heuristic + design-principle illustrations — keep the principles, strip the tracker illustrations); the HELP-FRAGMENT-TRACKER dangling ref (ADDENDUM-A).
- **WU-PACKCHAT** (`PACK-CHAT.md`): + **NEW** — the two non-BD tracker prose blocks ("Flat-file is the sole supported mode. Tracker (GH Issues) integration … dormant"; the recommendation-narration block); the "(flat-file … ; tracker is deferred — BD-214)" table cell; **NEW** — the L153-159 "Push to v11-dev only" temporal scaffolding ("Batch 24 (the release-pin batch)" + "short-lived (resolves when v11.0 ships)") — keep the bare push directive.
- **WU-DRYRUN** (`DRY-RUN-MIGRATION.md`): + **NEW** — the "**Tracker opt-in (Phase B).**" Limitations bullet (delete). VERIFY the `tracker.toml.example` token in the copied-files list (KEEP if still copied today; STRIP if not).
- **WU-BOUNDARYDEF** (`BOUNDARY-DEFINITION.md`): + the HELP-FRAGMENT-TRACKER C2-inventory ref (ADDENDUM-A). (No tracker-FEATURE prose otherwise; the "phase-part/phase-task" Ban-C line is KEEP.)
- **WU-PACKAGENTS** (`PACK-AGENTS.md`): no deferred-feature mention found (BD provenance only — §B.2).

### CG-05 (pack stream-meta `_rules` + pack `_intro`)
- **WU-BACKLOG-RULES** (`backlog/_rules.md`): + the whole "**Tracker mode (deferred).**" block (OQ-FINAL-3 rewrite to "This stream is flat-file per-entry."); the "Flat-file is the sole supported mode (tracker mode is …" contrast; the BD-215 "Until then this stream is flat-file" dependency.
- **WU-CHANGELOG-RULES** (`changelog/_rules.md`): + the "tracker (GH Issues) integration is deferred (BD-214) … tracker migration never reads or writes `/changelog/`" block.
- **WU-PACK-INTRO** (`backlog/_intro.md`): + the "Tracker (GH Issues) integration is deferred (BD-214)" line (G1).

### CG-06 (pack skills)
- **WU-SKILL-boundary-investigation (PACK)** (all 3 tracked copies — `.claude/`, `.agents-plugin/`, `.codex/`): + the HELP-FRAGMENT-TRACKER example-set refs (ADDENDUM-A rewrite). (The `tracker.toml.pack-example` "exempt at pack root" note is KEEP — it is a dormant-config exempt-file fact, not an advertisement.)
- **WU-SKILL-pack-startup (PACK)**: the "local tracker opt-in changes the write channel" parenthetical — **JUDGMENT → STRIP the parenthetical**: it advertises a deferred opt-in. KEEP the surrounding read instruction. (Step-8 deferred strip already in WU-NUCLEAR/CG-02; the L38/L107/L115 history is §B.2.)
- **WU-SKILL-pack-help (PACK)**: the frontmatter `description:` lists "`pack tracker *`" as an example verb. **JUDGMENT → STRIP** "`pack tracker *`" from the description (the verbs are dormant/unadvertised post-CG-02). Keep the other example verbs. NEW (not in any WU row). NB Check 1 frontmatter must stay valid — this edits the `description` value only.

### CG-08 (pack-root trinity strip)
- **WU-ROOT-TRINITY**: + the bgIsolation "— BD-218 … Codex/Antigravity = BD-217" forward-look (keep "governs background sessions only"); the BD-217 ×5 cross-CLI mapping refs; the BD-233 cross-CLI-effectiveness ref (AGENTS/GEMINI); the tracker passages (§B.2 BD-214). JUDGMENT-KEEP: "their worktree story is a future pack version. Do NOT 'restore parity'…" (operative do-not-port directive; trim only the 4-word "future pack version" clause if the reviewer insists).

### CG-09 (project trinity strip) — CLIENT-FACING
- **WU-PROJ-TRINITY**: + the 6-site tracker passages (§B.3) — reduce to "Flat-file per-entry is the sole supported mode." (LEAK; also self-inconsistent with the CG-03 rule now in these files.)

### CG-10 (project client-leak strips) — CLIENT-FACING
- **WU-OPTFEAT-PROJ**: + the "## Tracker integration (deferred)" section (L-6); + **NEW** the bgIsolation "slated for a future pack version; do not set … expecting it" forward-look (keep the enum/default spec).
- **WU-PMCHAT-PROJ**: + the tracker deferred mentions (L-7); + **NEW** the two "Codex / Antigravity equivalents are a future pack version" forward-looks (keep the Claude-only operative rules).
- **WU-PROMPT-auditor / -coder**: + the deferred-tracker parentheticals (L-8/L-9).
- **WU-SKILL-pm-startup (PROJECT)**: + the deferred clause + Step-7 reserved comment + deferred Step 8 (L-10).
- **WU-SKILL-boundary-investigation (PROJECT)**: + the HELP-FRAGMENT-TRACKER example rewrite (L-14).
- **WU-PROJ-INTRO ×3**: + the 3-line deferred-tracker block each (L-11).

### CG-12 (project skills bloat) — CLIENT-FACING NEW axis
- **WU-SKILL-audit-methodology**: + **NEW** rule-20 "web / Android / embedded-MCU once those skills land, deferred to a future version, currently planned post-v11.0" forward-look (keep "Apple today"); + rule-44 "deferred to a future version (currently planned post-v11.0); once those skills land…" forward-look (keep "the current detection list is Apple-centric"). (The OQ-B `_v8-resolved-archive.md` ref fix is already in the WU.)
- **WU-SKILL-apple-swiftdata-patterns**: + **NEW** "and may ship as separate `apple-coredata-patterns` / `apple-sqlite-patterns` skills in a future release" forward-look (keep "companion rules … are out of scope for this skill").

### CG-13 (project docs/pack + prompts + stream-meta bloat) — CLIENT-FACING NEW axis
- **WU-DOCSPACK-PACK-FEEDBACK**: + **NEW** "Android, Windows, embedded, and web platforms have deferred skills (not yet created)" — strip "have deferred skills (not yet created)"; keep the operative capture instruction. (JUDGMENT — default STRIP.)
- (PLATFORM-SKILLS.md: no deferred-feature mention found beyond what PACK-FEEDBACK carries — coder VERIFIES.)

---

## 5. THE KEEP SET (current-operative references that look deferred-ish but STAY — so coders/reviewers do NOT over-strip)

The measure-then-bound LOWER bound: every occurrence here passes the "current-OPERATIVE" test (documents what exists/operates today) and must NOT be stripped.

**USER RULING (2026-06-21) — an "out of scope for this skill" / no-coverage statement is an OPERATIVE GUARDRAIL → KEEP; strip ONLY the forward-look promise.** An out-of-scope statement bounds what the skill supports so the agent does not overstep into unsupported territory — it is current operative instruction, not a deferred-feature advertisement. For the §2.8 platform-future-skills axis, split EVERY occurrence this way (KEEP the guardrail, STRIP the promise):
- `apple-swiftdata-patterns/SKILL.md` — KEEP "companion rules for CoreData and direct SQLite are **out of scope for this skill**"; STRIP "and may ship as separate `apple-coredata-patterns` / `apple-sqlite-patterns` skills **in a future release**".
- `audit-methodology/SKILL.md` rule 20 — KEEP "applies whenever any UI platform skill is loaded — **Apple today**"; STRIP "web / Android / embedded-MCU **once those skills land, deferred to a future version, currently planned post-v11.0**".
- `audit-methodology/SKILL.md` rule 44 — KEEP "the current detection list is **Apple-centric**"; STRIP "Non-Apple UI detection markers … are added by the corresponding platform-architecture skills, **deferred to a future version … once those skills land, this detection list extends**".
- `PACK-FEEDBACK.md` — KEEP the operative no-coverage guardrail "**If the project targets a platform without dedicated skills, note what rules or patterns were missing**" (rephrase the lead-in to a current-state fact, e.g. "Android, Windows, embedded, and web platforms have **no dedicated skills**"); STRIP the "**have deferred skills (not yet created)**" promise that implies planned creation.
The same KEEP-the-guardrail / STRIP-the-promise split applies to any other out-of-scope-with-forward-look construction a coder encounters.

| File | Anchor | Why KEEP |
|---|---|---|
| `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (pack) | "`worktree.bgIsolation` governs background SESSIONS only (not sub-agents)" | `bgIsolation` is a CURRENT setting token (Check-54-required). KEEP the operative fact; strip only the "— BD-218 … = BD-217" forward-look. |
| `pack-ops/OPTIONAL-FEATURES.md` + project copy | the `bgIsolation` enum/default spec ("`worktree.bgIsolation` (enum `["worktree","none"]`, default `"worktree"`)"); the `baseRef`/`bgIsolation` SETTINGS-vs-parameter clarification | CURRENT operative settings spec (Check-54-required). Strip only the v11.1/future-version forward-look clause. |
| `pack-ops/MERGE-STRATEGY.md` | "In flat-file mode it prints `[INFO] tracker: skipped` and returns 0." | CURRENT migrator CODE behavior in the only reachable mode (BD-214 dormant-code is real and runs). KEEP. |
| `pack-ops/DRY-RUN-MIGRATION.md` | the `will` allowlisted entries (Check-44 advisory) | Check-44 `will` allowlist — not deferred-feature; operative. |
| `backlog/_rules.md` (pack) | "Flat-file is the sole supported mode." (the operative half) | The operative mode statement survives every strip — keep it, drop only the tracker contrast. |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | the methodology PRINCIPLES (bidirectionality / typed-errors / idempotency / mode-agnostic logic) | Operative review criteria. Strip only the tracker ILLUSTRATIONS, keep the principles. |
| `pack-ops/BOUNDARY-DEFINITION.md` | "Ban C … project-side concepts (TD / phase / phase-part / phase-task) operationally" + "`tracker.toml.pack-example`" exempt-file row | Operative ban + dormant-config exempt-file fact (BD-214 retains the example; declaring it exempt is current hygiene, not advertising). KEEP. |
| `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` + `backlog/_rules.md` | "A sub-part of an existing BD lives as a SECTION" / "sub-part is an in-body section, not a suffixed entry" | CURRENT no-suffix entry rule. KEEP (NOT a phase-parts deferred feature). |
| `project-template/skills/documentation/SKILL.md` (pack copy too) | "its public issue tracker for known limitations" | Generic 3rd-party-dependency advice ("issue tracker"), NOT the pack's deferred tracker feature. KEEP. |
| `project-template/.claude\|.codex\|.agents-plugin coder agent defs` | "Deferred items" report-section instruction (TD-TBD workflow) | LIVE TD-deferral feature, not the tracker feature. KEEP ×3 (tri-family). |
| `project-template/skills/review/SKILL.md` + pack `review/SKILL.md` | "BLOCKED. Real dependency on a not-yet-landed artifact — a sibling TD's implementation, a tool/framework version not yet adopted…" | Operative review-triage rubric (a definition of the BLOCKED category), not an advertisement of a specific deferred pack feature. KEEP. |
| `project-template/skills/documentation/SKILL.md` + pack copy | "commits with no corresponding CHANGELOG entry at a phase boundary" | "phase boundary" = the project's CURRENT phase concept (client-side, operative). KEEP. |
| `project-template/GEMINI.md` + `audit-methodology` rule-58 + `RUNTIME-SUBAGENT-PATTERN.md` | "where the plugin `agents/` template schema is not yet accepted … runtime `define_subagent` pattern" | CURRENT-STATE fallback instruction (what to do TODAY on an `agy` version lacking the schema) — operative degradation path, not a deferred-feature advertisement. KEEP. |
| `project-template/skills/api-design/SKILL.md` | "Mark as deprecated first, then remove in a future version." | Generic API-evolution PRINCIPLE for the CLIENT's own product, not a pack deferred feature. KEEP. |
| `project-template/skills/macos-/ios-architecture/SKILL.md` | "design … for at least 30% expansion" (localization) | Generic platform guidance; "future" not present in the deferred-feature sense. KEEP. |
| `.github/ISSUE_TEMPLATE/work-item.yml` (out-of-IN-set but adjacent) | "deferred" as a work-item STATE | Live project-workflow state, not the tracker feature. KEEP. |
| `project-template/tracker.toml.project-example` + `.gitignore` tracker line (out-of-IN-set configs) | the dormant config record / gitignore hygiene | BD-214 dormant-config retention; config files, not docs. KEEP (strip only PROSE refs to them). |

**JUDGMENT items where the default is KEEP-but-trimmable** (reviewer adjudicates per-occurrence):
- `CLAUDE.md` "their worktree story is a future pack version. Do NOT 'restore parity'…" — operative do-not-port directive; trim only the "future pack version" 4-word clause if the reviewer reads it as a roadmap mention.
- `.claude/skills/verification-harness/SKILL.md` "a single shared lib is a future optimization, not a [requirement]" — operative design-rationale; the directive (no shared lib now) is KEEP; "future optimization" is incidental.

---

## 6. CG-14 VERIFICATION RECOMMENDATION (the completeness backstop Check 65 cannot provide)

Check 65 does NOT cover the deferred-feature axis (it matches date/SHA/BD-tag/User-locked/incident/carry-over residue only — it will NOT catch "pack tracker init", "Tracker opt-in (Phase B)", "slated for a future pack version", "deferred to a future version"). So completeness depends ENTIRELY on this census + a manual re-grep gate. Recommendation for CG-14 (the gate-activation wave) OR a new CG-14b verification step:

1. **Re-grep the deferred-feature term set** (the §1 vocabulary) over the full IN set on the post-strip tree.
2. **Expect ZERO hits outside the §5 KEEP set.** Concretely, after all strip waves land, these patterns should return ONLY KEEP-set occurrences:
   - `grep -rniE "tracker (mode|integration|opt-in)|pack tracker|tracker\.toml\.example|TrackerProvider|GH Issues" $IN` → expect only: the `documentation/SKILL.md` "issue tracker" generic line; the MERGE flat-file "tracker: skipped" current-behavior line; any KEEP-set dormant-config exempt note. NO "deferred"/"DORMANT"/"Phase B"/"opt-in" tracker prose.
   - `grep -rniE "deferred to a future|future pack version|future release|future version|not yet created|once those skills land|v11\.1|v11\.x|when BD-[0-9]+ lands|on the .*roadmap|Phase B" $IN` → expect ZERO (every match is a deferred-feature forward-look this census strips).
   - `grep -rni "pack-auditor|auditor-issue-tracking|Future integration|tracker opt-in walkthrough" $IN` → expect ZERO.
3. **Treat any hit not in the §5 KEEP set as a BLOCKER** (an un-stripped deferred-feature mention). The reviewer at each WU already does this per-file (per PLAN §7 step 2 "each deferred-feature mention confirmed gone — P-DEF reviewer-enforced"); CG-14 makes it a tree-wide completeness gate.
4. **Optional hardening (out of BD-243 scope; surface only):** a future Check could add a curated deferred-feature term allowlist (modeled on `.operating-doc-history-allowlist.txt`) so the axis gains a permanent gate. NOT proposed for BD-243 (would need its own architect+user sign-off per ci-guard-measure-then-bound + the §5 KEEP set as the allowlist seed). Recorded as the natural future backstop; this census's §5 KEEP set IS the measured allowlist seed if/when that check is built.

**Why a re-grep, not a regex gate, now:** the deferred-feature axis is a content judgment ("is this feature shipped?") that no regex decides — the same reason the design routed P-DEF to the reviewer, not Check 65. The CG-14 re-grep is a RECALL gate (did we miss a mention?), adjudicated against the §5 KEEP set; it is the completeness backstop, not an enforcement regex.

---

## 7. EMPIRICAL-EVIDENCE BLOCKS

Runtime: HEAD `0592a818bf1c0f84322e83dac5da2db48e3ab82e`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, clean tree. Graph queried FIRST for discovery → STALE (returned only `backlog/_toc.md` orientation nodes) → G2 fallback to grep/Read for every state-claim. The authoritative deferred-feature count is the grep over the 143-file IN set (`/tmp/bd243-in-files.txt`).

**EE-HEAD — runtime HEAD = CG-03 (3 CGs past the design's a847f12); clean tree.** Cmd: `git rev-parse HEAD; git branch --show-current; git status --short; git log --oneline -4`. Output: `0592a818…` ; `v11-dev` ; (empty) ; `0592a81 …CG-03`, `7de1fbc …CG-02`, `eec6727 …CG-01`, `a847f12 …BD-243 open`. Interpretation: CG-01/02/03 landed; CG-04 is the pending patch. Conclusion: **SUPPORTED.**

**EE-IN — IN set = 143 files at HEAD.** Cmd: `wc -l < /tmp/bd243-in-files.txt` (list built from the §A families, HELP-FRAGMENT-TRACKER excluded as already-deleted). Output: `143`. Interpretation: live IN set; design's ~145/~136 are nominal pre-deletion counts. Conclusion: **SUPPORTED.**

**EE-TRK-COUNT — tracker is mentioned in 30 IN files.** Cmd: `grep -ric "tracker" $(cat /tmp/bd243-in-files.txt) | grep -v ':0$' | sort -t: -k2 -rn`. Output (verbatim, top): `pack-ops/OPTIONAL-FEATURES.md:12`, `pack-ops/MERGE-STRATEGY.md:10`, `project-template/docs/pack/PM-CHAT.md:7`, `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md:7`, `backlog/_rules.md:6`, `project-template/docs/pack/OPTIONAL-FEATURES.md:5`, `pack-ops/PACK-CHAT.md:5`, `project-template/skills/pm-startup/SKILL.md:4`, `project-template/skills/boundary-investigation/SKILL.md:4`, `project-template/{CLAUDE,AGENTS,GEMINI}.md:4` each, `pack-ops/PACK-MEMORY-RATIONALE.md:4`, `{CLAUDE,AGENTS,GEMINI}.md:4` each, `.claude/skills/boundary-investigation/SKILL.md:4`, project `_intro`×3 `:3` each, `pack-ops/DRY-RUN-MIGRATION.md:2`, `pack-ops/BOUNDARY-DEFINITION.md:2`, `changelog/_rules.md:2`, + 6 files at `:1`. Interpretation: 30 files carry the word "tracker"; classified per §2.1 (STRIP feature-prose) vs §5 (KEEP generic/current-behavior/dormant-config). Conclusion: **SUPPORTED — PARTIAL on raw-count→strip mapping** (raw "tracker" count includes KEEP-set generic uses; the STRIP set is the §2.1 + §3.2 occurrences, not every raw hit). 

**EE-TRK-LINES — tracker line anchors captured per file.** Cmd: `grep -n -i "tracker" <each non-zero file>`. Output captured verbatim in the working log (the §2.1/§2.2/§2.3 anchors are quoted from it — e.g. pack `CLAUDE.md:597` "Tracker (GH Issues) integration is DEFERRED", `:610` "tracker mode is deferred — BD-214", `:780` "tracker integration is deferred"; `MERGE-STRATEGY.md:435-440` Gate 3 conditional; `MERGE-STRATEGY.md:467-469` recovery verbs; `MERGE-STRATEGY.md:495` See-also walkthrough; `DRY-RUN-MIGRATION.md:161` "Tracker opt-in (Phase B)"; project `CLAUDE.md:222-243` Document-locations passage). Interpretation: every quoted anchor in §2 is a verbatim grep hit. Conclusion: **SUPPORTED.**

**EE-MERGE-GATE3 — Gate 3 has BOTH a current-behavior half and a deferred-feature half.** Cmd: `sed -n '425,445p' pack-ops/MERGE-STRATEGY.md`. Output (verbatim): "Gate 3 — post-Phase-B verification fires inside `--apply` after Gate 2 passes, **conditionally** on tracker mode being active … In flat-file mode it prints `[INFO] tracker: skipped` and returns 0. When tracker mode is active it checks: `id-map.json` integrity, BACKLOG.md mirror freshness, and `pack tracker doctor` exit-status." Interpretation: the "In flat-file mode … skipped … returns 0" half = CURRENT behavior (KEEP); the "When tracker mode is active it checks…" half = deferred-feature branch (STRIP). Adjudicates the CG-04 coder's "L428-433 is current behavior" claim as PARTIAL. Conclusion: **SUPPORTED.**

**EE-BGISO — bgIsolation forward-look on CLIENT side (NEW, §B.3 missed).** Cmd: `grep -rn "bgIsolation" $(cat /tmp/bd243-in-files.txt)`. Output (verbatim, client): `project-template/docs/pack/OPTIONAL-FEATURES.md:184:separate concern slated for a future pack version; do not set \`bgIsolation\`` ; `project-template/docs/pack/PM-CHAT.md:564:> WHEN to reuse). Codex / Antigravity equivalents are a future pack version.` Interpretation: client-side deferred forward-looks not in §B.3 (which declared project history-provenance ≈ 0, censusing tracker only). Conclusion: **SUPPORTED — these are NEW client-facing LEAKs.**

**EE-AUDITOR — BD-109/110 unbuilt-agent mentions.** Cmd: `grep -rni "auditor-issue-tracking|pack-auditor" + "when .*lands|once .*ships"`. Output (verbatim): `MERGE-STRATEGY.md:218:\`auditor-issue-tracking\` agent (BD-109 / BD-110) is on the v11.x` / `:219:roadmap and routes … once it ships.` ; `CONCEPTUAL-REVIEW-METHODOLOGY.md:5:Folds into the \`audit-methodology\` SKILL when BD-110 lands. Until then…` ; `:224:Preferred (when available): \`pack-auditor\` agent (BD-110, lands in Batch 21)` ; `:226:Fallback before BD-110 lands` ; `:273:When BD-110 (Batch 21) lands…`. Interpretation: an unbuilt agent + future-migration scaffolding across MERGE + CONCEPTUAL. The non-BD scaffolding ("on the v11.x roadmap … once it ships", "Folds … Until then", "## Future integration") is the deferred-feature axis §B.2's BD-token rows did not enumerate. Conclusion: **SUPPORTED.**

**EE-PLATSKILLS — platform future-skills axis (NEW, design never censused).** Cmd: `grep -rniE "slated|planned post|future version|future release|not yet created" $(cat /tmp/bd243-in-files.txt)`. Output (verbatim, the deferred-skill hits): `audit-methodology/SKILL.md:51 … web / Android / embedded-MCU once those skills land, deferred to a future version, currently planned post-v11.0` ; `audit-methodology/SKILL.md:106 … deferred to a future version (currently planned post-v11.0); once those skills land…` ; `apple-swiftdata-patterns/SKILL.md:22 … may ship as separate \`apple-coredata-patterns\` / \`apple-sqlite-patterns\` skills in a future release.` ; `PACK-FEEDBACK.md:75 … web platforms have deferred skills (not yet created).` Interpretation: a distinct deferred-feature axis (future platform skills) advertised on CLIENT-FACING surfaces — entirely absent from §B.2/§B.3. Conclusion: **SUPPORTED — NEW axis, 3 of 4 are client LEAKs.**

**EE-PP — NO phase-parts deferred-feature mention.** Cmd: `grep -rni "phase part|phase-part|sub-part|subpart" $(cat /tmp/bd243-in-files.txt)`. Output (verbatim): `BOUNDARY-DEFINITION.md:124 … (TD / phase / phase-part / phase-task) operationally` ; `AGENTS.md:101`/`CLAUDE.md:99 … sub-part of an existing BD lives as a SECTION` ; `GEMINI.md:75 … a sub-part is a SECTION in the parent BD's body` ; `backlog/_rules.md:40 … sub-part is an in-body section`. Interpretation: all are CURRENT operative rules (no-suffix entry rule; project-concept ban) — none advertises a coming phase-parts hierarchy. BD-185 hits elsewhere are P4 incident history (Check-65 axis). Conclusion: **SUPPORTED — phase-parts feature is NOT mentioned (KEEP set).**

**EE-GRP — NO groupings feature mention.** Cmd: `grep -rni "grouping" $(cat /tmp/bd243-in-files.txt)`. Output (verbatim): only accessibility "grouping/traits" in `audit-methodology/SKILL.md:51` + auditor-ui agent defs ×3. Interpretation: zero references to the pack GROUPINGS feature; all hits are generic UI vocabulary (KEEP). Conclusion: **SUPPORTED — no groupings mention.**

**EE-PS — NO Product Specialist mention.** Cmd: `grep -rni "product specialist|product-specialist" $(cat /tmp/bd243-in-files.txt)`. Output: (empty). Interpretation: zero hits. Conclusion: **SUPPORTED — no Product Specialist mention.**

**EE-V111 — v11.1/v11.x deferred forward-looks enumerated.** Cmd: `grep -rn "v11\.1|v11\.x" $(cat /tmp/bd243-in-files.txt)`. Output (verbatim, deferred-feature ones): `MERGE-STRATEGY.md:218` v11.x roadmap (auditor); `OPTIONAL-FEATURES.md:204` BD-218 (v11.1) bgIsolation; `OPTIONAL-FEATURES.md:285` BD-217 (v11.1) cross-CLI. The `CLAUDE/AGENTS/GEMINI.md` "No deferral to v11.1+ without explicit user direction" hits are an OPERATIVE RULE (KEEP — a directive, not a feature advertisement); the RATIONALE `v11.1`-string hits are the rule's own rationale + a history state-claim (Check-65/history axis). Interpretation: 3 deferred forward-looks (all in pack-ops, classified STRIP-forward-look in §2.3/§2.4); the rule-text v11.1 mentions are KEEP. Conclusion: **SUPPORTED.**

**EE-SELFINCONSIST — the surviving trinity tracker passages now sit beside the CG-03 rule (self-inconsistent).** Cmd: `sed -n '218,245p' project-template/CLAUDE.md`. Output (verbatim): the "tracker mode is deferred indefinitely … so all rows read `flat`" passage at L222-223, the "tracker integration is deferred indefinitely … dormant" para at L241-243, immediately followed at L245 by "**Operating docs carry NO history, NO deferred-feature mentions; stay…**" (the new CG-03 rule). Interpretation: the deferred-tracker passage violates the new rule in the same file → higher-priority strip (CG-09). Conclusion: **SUPPORTED.**

**EE-GRAPH — graph STALE; G2 fallback exercised.** Cmd: `graphify query "tracker mode deferred feature mentions operating docs" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 2000`. Output (verbatim, first nodes): `NODE Table of contents — pack-backlog [src=backlog/_toc.md]`, `NODE Deferred [src=backlog/_toc.md loc=L36]`, `NODE Cancelled`, `NODE Open`, `NODE Resolved` — all `_toc.md` orientation, none a deferred-feature doc mention. Interpretation: graph stale/unhelpful for BD-243-era deferred-feature discovery → fell through to grep/Read IMMEDIATELY (no block). Authoritative count = grep over the IN set. Conclusion: **SUPPORTED (graph-first attempted, G2 fallback correct).**

---

## 8. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only git verbs run: `git rev-parse HEAD`, `git branch --show-current`, `git status --short`, `git log --oneline` (all read-only). One `graphify query` (read-only). Sole write = this census via `cat >>` to `/tmp/pack-handoff-bd243-arch/CENSUS-DEFERRED-FEATURE-MENTIONS.md` (the caller-specified report path). No repo-file edit; no patch; no state-changing git verb; no OptiquityTrader write. | COMPLIANT |
| **reconciliation-instance-independence** | FRESH census instance; did NOT author DESIGN-BD-243.md / -FINAL / -FINAL-V2, NOT the adversarial reviewer. Reached own verdicts: ADJUDICATED the CG-04 coder's "Gate 3 L428-433 is current behavior" claim as PARTIAL (SPLIT: keep flat-file half, strip tracker-active half, EE-MERGE-GATE3); surfaced NEW axes (platform future-skills, client bgIsolation forward-looks) the design missed; classified rather than adopting §B.2 wholesale. | COMPLIANT |
| **ci-guard-measure-then-bound** | (1) MEASURED first: grepped the complete §1 term set over the 143-file IN set (EE-TRK-COUNT/EE-BGISO/EE-AUDITOR/EE-PLATSKILLS/EE-PP/EE-GRP/EE-PS/EE-V111). (2) Categorized EVERY occurrence STRIP (§2 / §3.2) vs KEEP (§5) by the deferred-MENTION-vs-current-OPERATIVE test. (3) Sized the KEEP set EXACTLY to current-operative refs (dormant-config exempt notes, Check-required `bgIsolation` token, flat-file "tracker: skipped" current behavior, generic "issue tracker", live TD "Deferred items", current `agy` fallback) — neither over (no current-operative content marked STRIP) nor under (NEW non-BD axes added). (4) CG-14 re-grep recommendation (§6) verifies the post-strip tree returns zero deferred-feature hits outside the §5 KEEP set — the completeness backstop for the axis with no Check-65 gate. | COMPLIANT |
| **empirical-evidence-blocks** | §7 EE-HEAD..EE-GRAPH: each = command + verbatim output (counts/paths/quotes) + HEAD `0592a81` + 2026-06-21 + interpretation + SUPPORTED/PARTIAL. State-claims backed: "tracker mentioned in 30 files" (EE-TRK-COUNT, PARTIAL on raw→strip mapping); "platform future-skills is a NEW axis" (EE-PLATSKILLS); "no phase-parts/groupings/PS mention" (EE-PP/GRP/PS); "Gate 3 has two halves" (EE-MERGE-GATE3). | COMPLIANT |
| **external-rules-census-before-design** | Enumerated the COMPLETE deferred-feature reference set BEFORE classifying — every term in the §1 vocabulary grepped exhaustively over the named IN set (not sampled); the §2 tables list every hit; §3.1 separates already-covered (§B.2/§B.3) from NEW; nothing classified without a measured occurrence. | COMPLIANT |
| **pack-side-project-concepts-deliverable-only / client-ref discipline** | Every STRIP occurrence on a `project-template/` surface flagged `LEAK? = Y` (the highest-priority strips): project trinity (CG-09), project OPTIONAL-FEATURES/PM-CHAT/prompts/pm-startup/`_intro`×3 (CG-10), and the NEW client LEAKs — bgIsolation forward-looks (CG-10) + the platform future-skills axis (CG-12/CG-13). Generic project-product uses ("issue tracker", "deferred items", API "future version") kept (§5) — not advertised pack features. | COMPLIANT |
| **graph-first-context** | Discovery query attempted FIRST via the INJECTED absolute `--graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json` path verbatim (never recomputed from own toplevel), `--backend claude-cli`, `--budget 2000`, QUERY-only (never built); graph STALE (EE-GRAPH, only `_toc.md` nodes) → G2 fallback to grep/Read IMMEDIATELY; the authoritative census count is the grep over the named IN set (the exhaustive-enumeration verification gate). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered exactly the census: term set (§1), per-feature enumeration (§2), reconciliation + 4 CG-04 verdicts (§3), per-CG rollup recipe (§4), KEEP set (§5), CG-14 verification recommendation (§6). No unrelated redesign proposed (the optional future deferred-feature Check is surfaced as out-of-scope-for-BD-243, not proposed). | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |

**END — CENSUS-DEFERRED-FEATURE-MENTIONS.md**
