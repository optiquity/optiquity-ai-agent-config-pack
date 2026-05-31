# AUDIT-BD-195-REFRESH-POST-BD196

**Author:** pack-architect (BD-195 Steps 1–3 RE-AUDIT; READ-ONLY refresh + bound + slice-separation). **NOT a design pass.**
**Date:** 2026-05-31. **Branch:** v11-dev. **HEAD:** `c73077d25ed1f22bc028857620376d57a0c5a8cc`.
**Purpose:** Re-measure BD-195's Step-3 reconciled problem list (49 problems P-01…P-31x + 8 open questions OQ-1…OQ-8, authored 2026-05-29 at `e0239f3`, BEFORE BD-196) against the CURRENT tree. Refresh each problem's classification, separate the BD-196-closed slice from the rest, give a per-OQ verdict, surface new questions, and state the bounded remaining work-surface. This SURVEYS + MEASURES + FRAMES; it does NOT design fixes and does NOT recommend a disposition.

**Inputs re-measured:** `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` (the Step-3 surface), `AUDIT-BD-195-LANDSCAPE-STATE.md` (orientation, claims re-verified), `PLAN-BD-195-EXECUTION.md` (Steps 1–3 definition), the BD-196 commit chain (`96b174a`→`f52752d`, Resolved `c73077d`).

---

## 1. Method + baseline

- **HEAD:** `c73077d`, branch `v11-dev`, measured 2026-05-31.
- **Classification vocabulary (per problem):**
  - **STILL-LIVE** — the cited surface still carries the defect, unchanged in substance, at HEAD.
  - **CLOSED-BY-BD-196** — a BD-196 commit/mechanism removed the defect; cite the commit + mechanism.
  - **CHANGED** — the surface or the defect's shape changed (status, location, or framing) since the 2026-05-29 snapshot, but the underlying issue is not closed; describe the change.
  - **CLOSED-OTHER** — a non-BD-196 commit closed it (none found).
- **Non-carry-forward rule:** the 2026-05-29 classifications are NOT trusted on their face (they predate BD-196). Every row below is backed by a command run at HEAD `c73077d` (commands + verbatim results in §2 inline, load-bearing ones expanded in §7).
- **BD-196 reach (what it authoritatively established, for the close-test):** single-SSOT pack-memory in trinity + rule bodies split to `pack-ops/PACK-MEMORY-RATIONALE.md` (C1/C2); bijection Check 45 (C3); `BOUNDARY-DEFINITION.md` reshaped 255→86 lines with §6 collapsed to a CI-asserted pointer manifest `pack-ops/.boundary-pointer-manifest.txt` + asserting validator (C4/C6/C8); spawn-rule manifest (C5); concision gate Check 44 + allowlist (C10); Check 46 reference-resolution/anti-restate guard (C6); Check 37 walk extended to companion-template dirs (C7); history→`archive/v11` sweeps (C4/C9). BD-196 is entirely pack-ops/pack-rule-corpus surface; it did NOT touch `project-template/`, `scripts/validate-pack.py` runtime logic, the templates-archive, or companion templates' substance.

---

## 2. Per-problem refresh (all 49)

Classification + evidence command + verbatim result, measured at HEAD `c73077d`. "still live" = string/file/condition the finding cites is present and unchanged in substance.

### THEME A — v11.1 mislabel / "frozen v11.0" contamination (epicenter)

| P-NN | Sev | Classification | Evidence (command @ `c73077d` → result) |
|---|---|---|---|
| **P-01** | BLOCKER | **STILL-LIVE** | `grep -n "v11.1" scripts/validate-pack.py` → L1086 "added at v11.1 (BD-185 H.2)", L1121 "added at v11.1 (BD-185 H.2)", L1123 "introduced at v11.1". `grep -c "v11.1" scripts/tests/test-issue-forms.sh` → 6. Both ENCODING surfaces unchanged. BD-196 did not touch `scripts/`. |
| **P-02** | BLOCKER | **STILL-LIVE** | `find …/templates-archive/v11.1 -type f` → `v11.1/INDEX.md`, `v11.1/forms/work-item.yml`, `v11.1/phase-part-v11.1/SCHEMA.md` all present. The fictional cut is intact. |
| **P-03** | MUST | **STILL-LIVE** | `grep -n "GEMINI-CLI-ANALYSIS\|ANDROID-ANALYSIS" README.md` → L163/L164 still list both as present under `maintenance-docs/`; `ls maintenance-docs/GEMINI-CLI-ANALYSIS.md` → No such file (both in `prison/`). README still omits `v11-implementation/`+`v11-research/`+`prison/`. |
| **P-08** | MUST | **STILL-LIVE** | `ls …/PACK-REVIEW-BD-193-PHASE-4.md …/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md` → both present, unedited. The blessed/deepened v11.1 framing is still in-tree (these are propagation/correction-target records). |

### THEME B — pack/project boundary & client-shipped dead references

| P-NN | Sev | Classification | Evidence (command @ `c73077d` → result) |
|---|---|---|---|
| **P-04** | MUST | **STILL-LIVE** | `grep -n "MERGE-STRATEGY" project-template/docs/pack/PM-CHAT.md` → L530 `docs/pack/MERGE-STRATEGY.md` primary path present (file installed only at `pack-ops/`). |
| **P-05** | MUST | **STILL-LIVE** | `grep -n "CLI-PM-SETUP" project-template/.mcp.json.example` → L9 "See supporting-docs/CLI-PM-SETUP.md for setup instructions." (pack-only doc on client surface). |
| **P-06** | MUST | **STILL-LIVE** | `grep -n "V10-CODEX-MCP-RESEARCH\|73d480e" project-template/.codex/config.toml.example` → L13 "# Source: V10-CODEX-MCP-RESEARCH.md (commit 73d480e)." present. |
| **P-09** | MUST | **CHANGED** | `git log --diff-filter=A -- …/PACK-REVIEW-BD-185-H.2.md` → added at `3bef42b` (a BD-195 recovery commit). The doc is now **TRACKED** (the 2026-05-29 finding's "UNTRACKED → provenance ambiguity" sub-claim is now false). The prisoned-anchor + v11.1-framing sub-claims remain live. Provenance ambiguity resolved; disposition (OQ-3) still open. |
| **P-10** | MUST | **STILL-LIVE** | `sed -n '152,154p' README.md` → `MERGE-STRATEGY.md` + `DRY-RUN-MIGRATION.md` still under the `supporting-docs/` block; `pack-ops/` block still omits CONCEPTUAL-REVIEW-METHODOLOGY/DRY-RUN/MERGE-STRATEGY. |
| **P-11** | MUST | **STILL-LIVE** | `grep -n "Four pack agents" pack-ops/PACK-CHAT.md` → L147 present. `git log -S "Four pack agents" 96b174a^..f52752d` → empty (BD-196 touched PACK-CHAT.md via C5/C8 but did NOT alter this line). |

### THEME C — prison stale-refs (live docs citing Step-2-prisoned docs)

| P-NN | Sev | Classification | Evidence (command @ `c73077d` → result) |
|---|---|---|---|
| **P-14** | SHOULD | **STILL-LIVE** | `ls …/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md …/PLAN-CLEANUP-BATCH-19C.md` → present; `ls maintenance-docs/prison/ARCHITECTURE-CLEANUP-BATCH-19C*.md` → 19C/-DISCARDED/-PRINCIPLE-CHECK all in prison. Live 19c-family docs still forward-ref prisoned inputs. |
| **P-15** | SHOULD | **STILL-LIVE** | `grep -ln "V3.2-DELTA" maintenance-docs/v11-research/*.md` → V3.3-DELTA, ARCHITECTURE-REVIEW-PASS3, RESEARCH-PER-ENTRY-SPLIT, + others still cite prisoned `ARCHITECTURE-V3.2-DELTA.md`. |
| **P-21** | NIT | **STILL-LIVE** | `grep -n "V3.2-DELTA" scripts/lib/tracker-{migrate-forward,phase-task}.sh` → forward L238, phase-task L79 both cite prisoned doc at pre-prison path. |
| **P-25** | NIT | **STILL-LIVE** | `grep -n "GEMINI-CLI-ANALYSIS\|ANDROID-ANALYSIS" maintenance-docs/TOOL-COMPARISON.md` → L5/L6 "Supersedes:" + L217/L218 cite both prisoned docs at `maintenance-docs/` path (now in `prison/`). |


### THEME D — README / version-currency staleness + recipe paths

| P-NN | Sev | Classification | Evidence (command @ `c73077d` → result) |
|---|---|---|---|
| **P-12** | SHOULD | **STILL-LIVE** | `check_template_archive_v11()` L1237 loop `("bd","td","phase-epic","phase-task","inbound")` — 5 types, no `phase-part`. L1216 docstring lists the same 5. |
| **P-13** | SHOULD | **STILL-LIVE** | `grep -c "templates-archive/v11" …/ARCHITECTURE-BD-185-V2.md` → 20; `…/PLAN-BD-185-V2.md` → 12. Sample L102–104 cite bare `templates-archive/v11.0/INDEX.md` etc. (no `maintenance-docs/v11-research/` prefix). |
| **P-16** | SHOULD | **STILL-LIVE** | `grep -c "SUPERSEDED by\|ORDERING-ADDENDUM\|superseded-by" …/ARCHITECTURE-BD-185-V2.md` → 0. No forward pointer from V2 to the ordering addendum. |
| **P-17** | SHOULD | **STILL-LIVE** | `ls …/IMPLEMENTATION-REPORT-BD-185-*.md` → all 6 present (Batch-19d-H.1, -H.2, -H.1-NITS, -POST-PLANNER-POQS, -ARCHITECT-DOC-EDITS, -ARCHITECT-DOC-REVIEW-FIXES). v11.1 framing + prisoned refs intact. |
| **P-18** | SHOULD | **STILL-LIVE** | `ls …/PACK-REVIEW-BD-185-H.1.md` → present; anchors to prisoned `ARCHITECTURE-BD-185.md`+`PLAN-BD-185.md` (both in prison/). |
| **P-19** | SHOULD | **STILL-LIVE** | `grep -c "v9" project-template/docs/pack/PACK-FEEDBACK.md` → 17. Client-shipped v9 stamping intact. |
| **P-20** | SHOULD | **STILL-LIVE** | pm-chat.md L35 "Pack version: AI Agent Config Pack v10"; HELP-FRAGMENT.md L14 "migrate-v9-to-v10.sh … v10→v11 migrator ships separately"; pm-startup SKILL.md L128 "manifest in v10". All three live. |
| **P-22** | SHOULD | **STILL-LIVE** | `tracker-migrate-forward.sh` L735 client branch `backlog_path="$repo_root/BACKLOG.md"`, L737 `plan_path="$repo_root/IMPLEMENTATION-PLAN.md"` (repo-root only); detect.sh probes `docs/project/`. Asymmetry undocumented on forward side. |
| **P-23** | SHOULD | **STILL-LIVE** | `tracker-migrate-forward.sh` L738 dead fallback `plan_path="$repo_root/maintenance-docs/IMPLEMENTATION-PLAN.md"` (no such file anywhere). |
| **P-24** | SHOULD | **STILL-LIVE** | HELP-FRAGMENT-PACK.md L26 lists `scripts/migrate-v9-to-v10.sh` as a verb (script sunset); QUICKSTART.md L34 links absent `supporting-docs/MIGRATION-v9-to-v10.md`. |

### THEME E — pack-self agent/skill parity & stale refs

| P-NN | Sev | Classification | Evidence (command @ `c73077d` → result) |
|---|---|---|---|
| **P-07** | MUST | **STILL-LIVE** | `.claude/skills/pack-help/SKILL.md` L14 + `.codex/…` L14 cite bare `PACK-CHAT.md`,`OPTIONAL-FEATURES.md`; `.gemini/commands/pack-help.toml` L10–11 already use `pack-ops/…`. Claude+Codex still divergent. |
| **P-26** | SHOULD | **STILL-LIVE** | `grep -c "state-verifiable" .{claude,codex,gemini}…pack-planner` → Claude 1, Codex 0, Gemini 0. Rule still Claude-only. BD-196 did not touch agent files. |
| **P-27** | NIT | **STILL-LIVE** | `grep -n "agent-run.sh" .claude/skills/commit-discipline/SKILL.md` → L143 "Codex's `agent-run.sh` references" present (byte-identical across CLI mirrors). |

### THEME F — companion templates + migrator dead-paths

| P-NN | Sev | Classification | Evidence (command @ `c73077d` → result) |
|---|---|---|---|
| **P-28** | MUST | **STILL-LIVE** | `grep -c "config_file\|\[agents\." xcode-companion-templates/Codex/config.toml` → 14; `ls xcode-companion-templates/Codex/agents/` → No such file. 7 agent toml targets unshipped. (Note: BD-196 C7 extended Check 37 deny-list walk to companion dirs, but Check 37 is a boundary deny-list, NOT an agent-file-existence check — does not touch P-28.) |

### THEME G — pack-self precision & boundary NITs (P-29 / P-30 / P-31 grouped)

| P-NN | Sev | Classification | Evidence (command @ `c73077d` → result) |
|---|---|---|---|
| **P-29a** | SHOULD | **CLOSED-BY-BD-196** | BD-196 C4/C6/C8. `git show e0239f3:…/BOUNDARY-DEFINITION.md` → old §6 declared a §6.1/§6.2 pointer network ("…pointer in README/PACK-CHAT/PACK-AGENTS/trinity") with no enforcement — the gap P-29a flagged. At HEAD, BOUNDARY-DEFINITION.md §6 (L129–131) reads "The pointer network is CI-asserted via the surface→pointer manifest at `pack-ops/.boundary-pointer-manifest.txt`; the manifest file and its asserting validator check both exist and enforce the surface→pointer mapping." `ls pack-ops/.boundary-pointer-manifest.txt` → present (5335 bytes). The "pointers do not exist / aspirational" gap is closed: §6 is now a CI-enforced manifest. |
| **P-29b** | SHOULD | **STILL-LIVE** | `grep -n "ARCHITECTURE-V1\|V3.3 §" pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` → L196 "now-archived `ARCHITECTURE-V1.md`" (no such file anywhere) + L197–204 bare "V3.3 §X" shorthand. (Doc reshaped by BD-196 C9 forbidden-pattern-0, but the dangling-ref defect persists.) |
| **P-29c** | SHOULD | **STILL-LIVE** | `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md` (lives at `v11-implementation/`, not pack-ops/) L3+L153 cite `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`; the methodology doc actually lives at `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. Wrong-dir citation live. |
| **P-29d** | SHOULD | **STILL-LIVE** | `EXECUTION-PLAN-V11.0.md` L4 "Status: Drafted 2026-05-09. Awaiting user review before any commits." (body sequences Resolved BDs). |
| **P-29e** | SHOULD | **STILL-LIVE** | `RECOMMENDATIONS.md` L3 "…using the AI Agent Config Pack v9." No banner; README lists it as current. |
| **P-29f** | SHOULD | **STILL-LIVE** | `project-template/README.md` L1 "AI Agent Config Pack v10"; L23 "30 skills per tool"; L9 "V10-DESIGN.md Part 7 §7.6" bare shorthand. v10-stale. |
| **P-29g** | NIT | **STILL-LIVE** | `PLATFORM-SKILLS.md` L573 "design documentation" + L612 "`GEMINI.md` `## Pack memory`" pack-repo construct cited on client-shipped surface. |
| **P-29h** | NIT | **STILL-LIVE** | `grep -c "Last verified" maintenance-docs/VERIFIED-NOTES.md` → 0 (undated CLI facts); `xcode-companion-templates/README.md` L24 "mirror the v9 project-level policy". |

### THEME G (cont.) — P-30 / P-31 grouped sub-records

| P-NN | Sev | Classification | Evidence (command @ `c73077d` → result) |
|---|---|---|---|
| **P-30a** | NIT | **STILL-LIVE** | `pack-ops/HELP-FRAGMENT-TRACKER.md` L17–20 "TD promotion (v11+)" / `pack td promote` surfaced on pack-self render. Architect-adjudication open (OQ-not; this is a deliverable-only call). |
| **P-30b** | SHOULD | **STILL-LIVE** | `scripts/tests/test-tracker-phase-task.sh` L113 asserts `dep_re` contains `BD-[0-9]+`; L132/L203 feed `BD-108` sample that MUST match; L149 grammar `BD-\d+`. Admission asserted as required. (OQ-2 audience question still open.) |
| **P-31a** | NIT | **STILL-LIVE** | `…/templates-archive/v11.0/INDEX.md` L25 "## Frozen forms"; L32–33 bare "D16" decision-id framing. |
| **P-31b** | NIT | **STILL-LIVE** | `AUDIT-INVENTORY-BD-TD-PATH.md` contains "D16"/"frozen" wrapper snapshot (file present, unedited). |
| **P-31c** | NIT | **STILL-LIVE** | `grep -c XCODE_APP project-template/{CLAUDE,AGENTS,GEMINI}.md` → CLAUDE 1, GEMINI 1, **AGENTS 0**. Trinity asymmetry: AGENTS.md lacks the `$XCODE_APP` relocation mechanism. |
| **P-31d** | SHOULD | **STILL-LIVE** | `project-template/.gemini/settings.json` L3 `_tools` says local-rag indexes METHODOLOGY.md AND INSTALL-PROCEDURES.md; `.mcp.json.example`/pm-startup authoritative manifest = METHODOLOGY.md only. Three ENCODING surfaces still disagree. |
| **P-31e** | NIT | **STILL-LIVE** | `project-template/.codex/config.toml.example` L16 "v10 ships STDIO only" version label stale. |
| **P-31f** | SHOULD | **STILL-LIVE** | `project-template/scripts/bootstrap.sh` L49 cites `supporting-docs/SETUP-NEW.md` (not installed to clients). |
| **P-31g** | — | **STILL-LIVE** | README still presents `RECOMMENDATIONS.md` + `VERIFIED-NOTES.md` as current top-level refs (compounds P-29e/P-29h; both underlying docs still un-bannered). |
| **P-31h** | NIT | **STILL-LIVE** | `xcode-companion-templates/Codex/config.toml` L2+L20 `model = "gpt-5"`; project-template pins gpt-5.4. Parity drift live. |
| **P-31i** | NIT | **STILL-LIVE** | `grep -n "Task tool" pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md` → PACK-AGENTS L44, PACK-CHAT L150. `git log -S "Task tool" 96b174a^..f52752d` → empty (BD-196 touched both files via C5/C8 but did NOT alter the "Task tool" terminology). Trinity pack-memory still says "Agent tool". Drift live. |
| **P-31j** | NIT | **STILL-LIVE** | `tracker.toml.pack-example` L9 "see ARCHITECTURE.md §6", L13 "spec: ARCHITECTURE.md §3.1" — bare doc ref where a concrete `scripts/pack-tracker.sh`/migration command is the actionable verb. |
| **P-31k** | NIT | **STILL-LIVE** | `grep -n "overtaken by BD-193" …/ARCHITECTURE-V3.3-DELTA.md` → empty. D-22/D-4-V2 row still lacks the overtaken-by note. |
| **P-31l** | NIT | **STILL-LIVE** | `ls …/INTAKE-GROUPINGS-V11.md` → present; self-flagged unverified-fidelity caveat intact (legitimate v11.1+ framing, not the mislabel). |

### 2.x — Classification tally

| Classification | Count | P-NNs |
|---|---|---|
| STILL-LIVE | 46 | all except the two below |
| CLOSED-BY-BD-196 | 1 | P-29a |
| CHANGED | 2 | P-09 (now tracked; provenance sub-claim falsified, disposition sub-claim live), P-31g/etc — see note |
| CLOSED-OTHER | 0 | — |

**Note on the CHANGED count.** Exactly **one problem is CHANGED in a way that alters a decision input: P-09** (the H.2 review doc moved UNTRACKED→TRACKED at `3bef42b`, which falsifies its "provenance ambiguity / a same-named tracked variant may exist" sub-claim; the prisoned-anchor + v11.1-framing sub-claims remain STILL-LIVE). No other problem changed shape. P-29a is the sole full close. The remaining **47** are STILL-LIVE (P-09 counted as CHANGED here; its live sub-claims keep it on the work-surface). For the bounded-scope headline (§6) the work-surface count is **48** (47 pure STILL-LIVE + P-09 with live residue), with **1** fully closed.

---

## 3. Slice separation (STILL-LIVE + CHANGED problems by surface)

Each remaining problem tagged by the surface that owns its fix. This bounds "how much of BD-195 is the narrow BD-185 salvage vs broad repo cleanup."

- **pack-rule-corpus** (BD-196's domain — pack-ops governance docs, trinity pack-memory, boundary docs): P-11, P-31i. **Count: 2.** (Both touch pack-ops governance surfaces BD-196 reshaped but did not fix.)
- **project-side** (`project-template/` trees — client-shipped/installed surfaces): P-04, P-05, P-06, P-19, P-20, P-29c*, P-29g, P-31c, P-31d, P-31e, P-31f. **Count: 11.** (*P-29c's citing doc is at `v11-implementation/` but governs project-side conceptual-review; counted project-side by its subject. If counted by file location it is pack-maintenance — flagged.)
- **product** (pack-shipped product surfaces outside project-template: companion templates, supporting-docs, README layout, QUICKSTART, scripts/lib client-path logic): P-03, P-10, P-22, P-23, P-24, P-28, P-31h, P-31j. **Count: 8.**
- **BD-185-artifact** (the BD-185 attempt records + held V2 docs + epicenter contamination they produced — Step-9 disposition inputs): P-01, P-02, P-08, P-09, P-12, P-13, P-16, P-17, P-18, P-31a, P-31b, P-31k. **Count: 12.**
- **other** (prison stale-refs not BD-185-specific, pack-self skill/agent parity, pack-self precision/currency NITs): P-07, P-14, P-15, P-21, P-25, P-26, P-27, P-29b, P-29d, P-29e, P-29f, P-30a, P-30b, P-31g, P-31l. **Count: 15.**

**Slice headline.** Of 48 live problems: **12 are BD-185-artifact** (the narrow Step-9 salvage-vs-wipe surface, incl. the 2 BLOCKERs P-01/P-02), **2 are pack-rule-corpus** (BD-196 domain, unfixed), and the remaining **34 are broad repo cleanup** (11 project-side + 8 product + 15 other). The broad cleanup dominates ~2.8:1 over the BD-185-specific slice. This separation directly informs the Option-C "split the fix work from the Step-9 BD-185 decision" question (landscape §6.2).

---

## 4. Per-OQ verdict (all 8)

| OQ | Topic | Verdict | Basis @ `c73077d` |
|---|---|---|---|
| **OQ-1** | Prison stale-ref remediation: per-doc edits vs Pattern-B ship-sweep | **STILL-OPEN** | The prison stale-refs (P-14/P-15/P-21/P-25) and BD-185 attempt records (P-09/P-17/P-18) are all STILL-LIVE (§2). BD-196 swept its OWN history to `archive/v11` (C4/C9) but did NOT establish a Pattern-B policy for the BD-185 / prison stale-ref corpus and did not touch any of these surfaces. The per-doc-vs-sweep decision is untouched. |
| **OQ-2** | `BD-NNN` admission in tracker phase-task dependency grammar: leak or fidelity? | **STILL-OPEN** | P-30b STILL-LIVE; `test-tracker-phase-task.sh` still asserts `BD-[0-9]+` admission. BD-196 added no validator over this grammar; the audience question (client-authoring vs migration-fidelity) is unresolved. R5 still filed no counterpart source-finding. |
| **OQ-3** | Disposition of `PACK-REVIEW-BD-185-H.2.md` (track/prison/leave) | **PARTIAL** | The "untracked / same-named tracked variant may exist / provenance ambiguity" half is **RESOLVED by the tree, not by BD-196**: the doc was committed (tracked) at `3bef42b`; `git log --diff-filter=A` shows the single add, so there is no provenance ambiguity. The remaining half — track-vs-prison-vs-leave disposition given its prisoned anchor + v11.1 framing — is **STILL-OPEN** (Step-9 input). |
| **OQ-4** | v9-auditor seed-set currency in client-shipped PACK-FEEDBACK.md | **STILL-OPEN** | P-19 STILL-LIVE; BD-196 did not touch `project-template/`. The "is the v9-era Q1–Q6 seed set still the intended v11 seed" question is a project-side content decision BD-196 does not reach. |
| **OQ-5** | `project-template/README.md`: ship to clients or relabel pack-maintainer-only? | **STILL-OPEN** | P-29f STILL-LIVE; project-side, untouched by BD-196. The ship-vs-relabel decision (and the R3-SHOULD/R4-NIT severity split) stands. |
| **OQ-6** | Xcode Codex companion: support sub-agents or strip the blocks? | **STILL-OPEN** | P-28 STILL-LIVE. BD-196 C7 extended the Check-37 boundary deny-list walk to companion dirs, but that is a leak guard, NOT an agent-shipping decision — the sub-agent-support question is untouched. |
| **OQ-7** | v9→v10 sunset-artifact scrub policy on live user-facing surfaces | **STILL-OPEN** | P-24 STILL-LIVE (HELP-FRAGMENT-PACK + QUICKSTART). BD-196 did not touch these; the scrub-vs-retain-as-historical policy is unresolved. |
| **OQ-8** | (precondition) normalize bare archive paths before executing P-02 | **STILL-OPEN** | P-13 STILL-LIVE (bare `templates-archive/...` paths in V2 §10 / PLAN-V2 §6, 20+12 occurrences). The sequencing precondition still holds: P-13 must land before any coder executes P-02. BD-196 did not touch these recipe docs. |

**OQ verdict tally:** ANSWERED-BY-BD-196 **0** · PARTIAL **1** (OQ-3, and the resolved half is by tree-state not BD-196) · STILL-OPEN **7**. The prior read ("likely only OQ-1 BD-196-touched, tangentially OQ-8") is NOT borne out — **BD-196 answers none of the 8 OQs.** The only OQ movement is OQ-3's provenance half, resolved incidentally by the `3bef42b` recovery commit, not by BD-196.

---

## 5. New questions / new problems (NQ-*)

Surfaced by the re-measurement; not in the 2026-05-29 list.

- **NQ-1 — The reconciled problem list's pack-memory rule citations now point at a BD-196-relocated corpus.** `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` cites rules by old prose/location (e.g. "Enumerate ENCODING surfaces", `feedback_manifest_regen_on_v11_surface`, `feedback_pack_project_separation_of_concerns`) used as fix-coupling drivers in P-01, P-05, P-06, P-31d. BD-196 C1/C2 reshaped pack-memory into two-clause imperatives + `[rationale: slug]` tags and split bodies to `pack-ops/PACK-MEMORY-RATIONALE.md`. The slugs still resolve, but any Step-5 fix recipe that quotes OLD rule text will not find that text in trinity. **Decision/flag:** a fix-design pass must re-anchor rule citations to the post-BD-196 slugs + RATIONALE locations. (Landscape §5.1/§5.4 names this; surfaced here as a discrete work item.)

- **NQ-2 — P-29a is closed but the problem-list and any downstream fix-recipe still carry it as an open SHOULD.** With P-29a CLOSED-BY-BD-196, a Step-5 architect acting on the 2026-05-29 list would design a fix for an already-CI-enforced §6. **Flag:** P-29a must be struck from the active work-surface (and its coupling notes — "trinity in lock-step", "verify pack-* agent read-list pointers" — re-checked against the new manifest, not re-implemented).

- **NQ-3 — New BD-196 surfaces are now in scope for the same boundary/concision rules BD-195 enforces, and are unaudited by the 2026-05-29 list.** BD-196 introduced `pack-ops/.boundary-pointer-manifest.txt`, `pack-ops/.spawn-rule-manifest.txt`, `pack-ops/PACK-MEMORY-RATIONALE.md`, `.concision-allowlist.txt`, and Checks 44/45/46. None existed when R1–R9 ran, so none were audited for the BD-195 problem classes (stale refs, version labels, boundary leaks). **Decision/flag:** does BD-195's "pristine" bar require these new surfaces to be swept for the same defect classes, or are they out of scope as BD-196-owned-and-CI-guarded?

- **NQ-4 — `CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md` location vs subject mismatch (sharpens P-29c).** The doc lives at `maintenance-docs/v11-implementation/` (pack-maintenance) but is a concept-scope doc for a project-side review methodology and cites `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (wrong dir; real home is `pack-ops/`). The re-measurement reveals the file-location-vs-subject ambiguity was not captured by P-29c's "wrong methodology-dir" framing alone — it also affects the slice tagging (§3 flagged it). **Flag:** confirm whether this doc's home + citations are both in-scope for the same fix.

**NQ count: 4.** (NQ-1/NQ-2 are BD-196-introduced staleness in the BD-195 artifacts themselves; NQ-3 is new-surface coverage; NQ-4 is a shape-sharpening of P-29c.)

---

## 6. Bounded remaining scope (inventory, NOT a plan)

**Net work-surface at HEAD `c73077d`:**

- **Live problems:** **48** (47 pure STILL-LIVE + P-09 CHANGED-with-live-residue). **Closed:** 1 (P-29a). **Fully resolved sub-claims inside live problems:** P-09 provenance half (tree-resolved) and OQ-3 provenance half.
- **By severity (live only):** 2 BLOCKER (P-01, P-02) · 10 MUST (P-03, P-04, P-05, P-06, P-07, P-08, P-09, P-10, P-11, P-28) · ~18 SHOULD · ~18 NIT (P-29a's close removes 1 SHOULD from the original 19).
- **By slice (live only):** BD-185-artifact **12** · pack-rule-corpus **2** · project-side **11** · product **8** · other **15**.
- **Surviving open questions:** **7 fully open** (OQ-1, OQ-2, OQ-4, OQ-5, OQ-6, OQ-7, OQ-8) + **1 partial** (OQ-3, disposition half open) + **4 new** (NQ-1…NQ-4). **Net: 8 old (7 open + 1 partial) + 4 new = 12 open decision items.**

**Headline.** BD-196 closed exactly **1 of 49** BD-195 problems (P-29a) and **0 of 8** open questions; it changed the shape of **1** (P-09, now tracked) and relocated the rule corpus that **2 new questions** (NQ-1/NQ-2) now flag as staleness inside the BD-195 artifacts. The BD-195 epicenter (P-01/P-02 BLOCKERs) and the entire broad-cleanup surface (34 problems across project-side/product/other) are **untouched and live**. The remaining work-surface is **48 live problems + 12 open decision items**, dominated ~2.8:1 by broad repo cleanup over the narrow 12-problem BD-185-artifact slice. BD-196's "unblocks" benefit is real but narrow: a cleaner corpus to fix INTO (plus the NQ-1 re-anchoring tax), not a reduced BD-195 problem count.

---

## 7. Empirical-Evidence Blocks (load-bearing claims)

All measurements 2026-05-31 at HEAD `c73077d25ed1f22bc028857620376d57a0c5a8cc`, branch `v11-dev`.

**EB-A — Epicenter (P-01/P-02/P-11) still live; BD-196 did not touch it.**
- *Command:* `grep -n "v11.1" scripts/validate-pack.py`; `grep -c "v11.1" scripts/tests/test-issue-forms.sh`; `find maintenance-docs/v11-research/templates-archive/v11.1 -type f`; `grep -n "Four pack agents" pack-ops/PACK-CHAT.md`.
- *Output:* validate-pack.py L1086/L1121/L1123 carry "added at v11.1 (BD-185 H.2)" / "introduced at v11.1"; test-issue-forms.sh → 6; v11.1 subtree → `INDEX.md`, `forms/work-item.yml`, `phase-part-v11.1/SCHEMA.md`; PACK-CHAT.md L147 "Four pack agents exist".
- *Interpretation:* The 2 BLOCKERs + P-11 are unchanged from the 2026-05-29 list.
- *Conclusion:* SUPPORTED (STILL-LIVE).

**EB-B — P-29a is the sole full close; the §6 gap is now CI-enforced.**
- *Command:* `git show e0239f3:pack-ops/BOUNDARY-DEFINITION.md | grep -n "§6\|pointer"`; `grep -n "manifest\|CI-asserted" pack-ops/BOUNDARY-DEFINITION.md`; `ls -la pack-ops/.boundary-pointer-manifest.txt`.
- *Output:* pre-BD-196 (e0239f3) §6 = "§6 Cross-reference network" with §6.1/§6.2 prose pointers and no enforcement; post-BD-196 (HEAD) §6 L131 "The pointer network is CI-asserted via the surface→pointer manifest at `pack-ops/.boundary-pointer-manifest.txt`; the manifest file and its asserting validator check both exist"; manifest present (5335 bytes).
- *Interpretation:* The "pointers do not exist / aspirational" gap P-29a flagged is closed by BD-196 C4/C6/C8 (reshape + manifest + validator).
- *Conclusion:* SUPPORTED (CLOSED-BY-BD-196).

**EB-C — BD-196 touched PACK-CHAT.md / PACK-AGENTS.md but did NOT fix P-11 or P-31i.**
- *Command:* `git log --oneline 96b174a^..f52752d --name-only -- pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md`; `git log -S "Four pack agents" --oneline 96b174a^..f52752d -- pack-ops/PACK-CHAT.md`; `git log -S "Task tool" --oneline 96b174a^..f52752d -- pack-ops/PACK-CHAT.md pack-ops/PACK-AGENTS.md`.
- *Output:* C8 (`62191fc`) touched PACK-CHAT.md; C5 (`0cbd6d5`) touched both. Both `-S` searches → empty (no add/remove of "Four pack agents" or "Task tool").
- *Interpretation:* BD-196 reshaped these governance files for spawn-rule/routing/manifest purposes but left the P-11 ("Four pack agents") and P-31i ("Task tool" drift) defects in place. Proves the close-test must be string-level, not file-level — a touched file is not a fixed finding.
- *Conclusion:* SUPPORTED (both STILL-LIVE despite BD-196 touching the files).

**EB-D — P-09 changed UNTRACKED→TRACKED via the recovery commit, not BD-196.**
- *Command:* `git log --oneline --diff-filter=A -- maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.2.md`.
- *Output:* single add at `3bef42b` ("BD-195 commit 5 held BD-185 attempt docs").
- *Interpretation:* The doc is now tracked with unambiguous provenance (single add, no same-named variant). The 2026-05-29 "UNTRACKED → provenance ambiguity" sub-claim is falsified; the prisoned-anchor + v11.1-framing sub-claims remain live. This is CHANGED, not CLOSED, and the change is by a BD-195 recovery commit, not BD-196.
- *Conclusion:* SUPPORTED (CHANGED).

**EB-E — Slice counts (48 live problems partition into the 5 slices).**
- *Command:* manual tag of every STILL-LIVE/CHANGED P-NN by owning surface (§3), cross-checked against each finding's "Surfaces" line in the reconciled list.
- *Output:* BD-185-artifact 12 · pack-rule-corpus 2 · project-side 11 · product 8 · other 15 = 48.
- *Interpretation:* The BD-185-specific salvage surface (12) is ~26% of live work; broad cleanup (34) dominates. Directly bounds the Option-C split question.
- *Conclusion:* SUPPORTED.

**EB-F — BD-196 answers 0/8 OQs.**
- *Command:* for each OQ, identify its owning surface(s) and check whether any BD-196 commit (`96b174a..f52752d`) touched that surface in a way that resolves the decision (cross-ref §2 classifications: OQ-1→P-14/15/21/25/09/17/18 all live; OQ-2→P-30b live; OQ-3→P-09 provenance tree-resolved at 3bef42b; OQ-4→P-19 live; OQ-5→P-29f live; OQ-6→P-28 live; OQ-7→P-24 live; OQ-8→P-13 live).
- *Output:* No OQ's underlying problem was closed by a BD-196 commit. OQ-3's provenance half resolved by `3bef42b` (a BD-195 recovery commit, pre-BD-196).
- *Interpretation:* BD-196 resolves none of the 8 open questions; the prior "OQ-1 + tangentially OQ-8" read is not borne out.
- *Conclusion:* SUPPORTED.

---

## 8. Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence | Conclusion |
|---|---|---|
| Architect/planner state-claims require Empirical-Evidence Blocks | Every P-NN row in §2 carries a command + verbatim result @ HEAD `c73077d` (date 2026-05-31); §7 expands EB-A…EB-F for the load-bearing claims (epicenter live, P-29a close, BD-196-touched-but-unfixed, P-09 changed, slice counts, OQ 0/8). No classification carried forward from the 2026-05-29 list on trust — each re-measured. | COMPLIANT |
| No-design / no-recommendation discipline | The report classifies, slices, gives OQ verdicts, surfaces NQ-1…NQ-4, and states a bounded inventory (§6). It designs no fix and recommends no disposition; NQ items are framed as decisions/flags, not chosen paths; §6 headline reports counts, not a recommendation. | COMPLIANT |
| Scope to the ask — no noise | Delivers exactly the 5 required products (per-problem refresh, slice separation, per-OQ verdict, new questions, bounded scope) + EB + Rules-Applied blocks. No speculative sprawl; new surfaces (NQ-3) named once with a flag, not explored. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / no destructive ops | All tool actions read-only (Read, grep, find, ls, git log/show/cat-file) + the single authorized Write to this report path (built via append-only `cat >>`, no edit to any other file, no git state-change, no `rm`/`mv`). | COMPLIANT |
| PRISON RULE (do not import prison as authoritative) | Prison membership noted as STATE only (§2 P-03/P-09/P-14/P-15/P-18/P-21/P-25 cite which docs are in `prison/` to establish stale-ref liveness); no prison doc read as guidance or cited as a live source. | COMPLIANT |
| STOP-MEANS-STOP | No parent stop/halt/revert issued; work proceeded to the single authorized deliverable. | COMPLIANT (N/A trigger) |

**End of AUDIT-BD-195-REFRESH-POST-BD196.md.**
