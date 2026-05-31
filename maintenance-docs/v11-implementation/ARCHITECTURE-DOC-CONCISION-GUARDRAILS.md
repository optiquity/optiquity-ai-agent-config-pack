# ARCHITECTURE — Document Concision + Boundary-Completeness Guardrails

**Type:** Read-only architecture design (pack-architect output). No BD number (explicit user direction). No implementation here.
**Status:** Draft (v9 — v8 + §8 stale-reference blast-radius sweep step + the subtractive-at-implementation clarifier) for user review → pack-planner sequencing.
**Filename note:** REVISED IN PLACE (same path throughout). v1 = concision design; v2 added boundary coverage + content rules; v3 folded the §4.2 researcher spike + D1/D2 corrections; v4 added the spawn-source consolidation (§9); v5 completed its measurement + SSOT principle; v6 added the discovery sweep (§10) + map + procedure; v7 redesigned §11 as single-SSOT design; v8 closes its post-ship gap — the per-actor routing is durably homed as one-line pointers in entry docs (one hop to the SSOT), B5-manifest-checked; the index stays DROPPED. One doc — honors filename-uniqueness + the "one doc" directive.
**Scope class:** STRUCTURAL (amends pack-memory rules, adds validator checks, reshapes durable docs, formalizes content rules). Planner sequences architect→planner→coder→reviewer.

---

## 0. Consistency-check verdict (gating, done first)

**ADDITIVE — no contradiction.** The expanded scope extends v1; it does not reverse any v1 conclusion. Verification: (a) the locked decisions C1/C2/C3/B5 are the v1 recommended resolutions ACCEPTED, with added constraints to *design more fully* — not to redesign; (b) complete-coverage and content-rules are NEW deliverables that compose with v1's M1–M4 (the concision gate is one of several boundary/content checks living in the same validator); (c) the one place that could contradict — C2-content dirs at repo root vs "C2 → pack-ops/" — resolves cleanly in §2.3 against the EXISTING rule (no reversal). **v3 fold:** the §4.2 researcher spike PROVED the proposed flag predicate storms 12/12 — a material change to §4.2's detection half (expected, not a contradiction); it forces NO reversal elsewhere (the structural-convention half, Bans A/B/C, B5, C1, C3, M1–M4 are untouched). **v4 fold:** §10 (spawn-source consolidation) acts on the SAME `## Pack memory` corpus as C1/M2 — it is additive (it makes `## Pack memory` the single spawn-source the other docs reference; C1/M2 already split each rule's Why to the rationale file). No prior conclusion reversed. Proceeding.

---

## 1. The design in brief

**Additive at the design-decision level; SUBTRACTIVE at implementation** — the reshape removes now-stale content (corpus Why bodies, BOUNDARY §5/§6/§7, the 6 restatements, cache bodies, a dropped check + index) AND repairs every orphaned inbound reference (§8 step 7b), not just adds.

Two problems, one validator family, four locked decisions:

- **Bloat** (v1): durable artifacts carry proof/rationale/history a forward-only rule does not need. Fix = separate the three jobs (rule / rationale / proof) onto three surfaces (M1–M4, §6).
- **Boundary** (new): the audience×function rule (BOUNDARY-DEFINITION §2) is sound but (a) coverage is example-only for several root surfaces, (b) the rule states WHERE but not HOW/WHEN, (c) two content rules (one-directional ban; separated-not-combined) are under-enforced. Fix = complete the verdict table (§2), add HOW/WHEN columns (§3), formalize + enforce the content rules (§4).

Locked-decision designs: **C1** imperative-line + reliable rationale fallback (§5.1); **C3** single `PACK-MEMORY-RATIONALE.md` with lock-step validator (§5.2); **B5** cross-ref-network → CI check (§4.3); **C2** confirmed (§6, EE in v1 retained).

---

## 2. Complete coverage — every root surface gets an audience×function verdict

> **Empirical-Evidence Block EE-1 — the complete root inventory.**
> Command: `git ls-files | sed 's#/.*##' | sort | uniq -c`. HEAD `3bef42b`, 2026-05-30.
> Output: 20 top-level entries — `maintenance-docs` (547), `scripts` (273), `project-template` (154), `.gemini`/`.codex`/`.claude` (16 each), `pack-ops` (12), `supporting-docs` (10), `test-fixtures` (8), `xcode-companion-templates` (6), `vscode-companion-templates` (4), `.github` (4), + 7 loose files (`README.md`, `QUICKSTART.md`, `LICENSE.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `tracker.toml.pack-example`) + `.gitignore`.
> Conclusion: **SUPPORTED.** The table below classifies all 20 — none by example.

### 2.1 The verdict table (every top-level entry)

| Entry | Audience | Function | Cat | Verdict / placement basis |
|---|---|---|---|---|
| `README.md` | PACK | PRODUCT+TOOL-CONFIG | C1 | Root (GitHub landing). |
| `QUICKSTART.md` | PACK | PRODUCT | C1 | Root (Override 7 — pre-install installer doc). |
| `LICENSE.md` | PACK | PRODUCT | C1 | Root. |
| `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (loose) | PACK | TOOL-CONFIG | C3 | Root (CLI-mandated; pack-memory home). |
| `.gitignore` (loose) | PACK | TOOL-CONFIG | C3 | Root (ecosystem-fixed). |
| `tracker.toml.pack-example` | PACK | OPERATIONS | C2 | Root — the SOLE `.boundary-exempt-root.txt` exemption. |
| `.claude/` `.codex/` `.gemini/` (root) | PACK | TOOL-CONFIG | C3 | Root dotted dirs (CLI-mandated; pack-self config). |
| `.github/` (root) | PACK | TOOL-CONFIG | C3 | Root (GitHub-mandated; pack CI + issue forms). |
| `pack-ops/` | PACK | OPERATIONS | C2 | The C2 home dir. |
| `scripts/` | PACK | OPERATIONS | C2 | Root — pack-operations by purpose; see §2.3. |
| `maintenance-docs/` | PACK | OPERATIONS | C2 | Root — see §2.3. Incl. `archive/` (frozen), `prison/` (superseded; ignored), `v11-implementation/` `v11-research/` (active design records), loose V10-* / TOOL-COMPARISON / RECOMMENDATIONS / VERIFIED-NOTES. |
| `test-fixtures/` | PACK | OPERATIONS | C2 | Root — see §2.3. Test-determinism infra (`build.sh`, `manifest.txt`, built-fixture trinity). |
| `supporting-docs/` | PROJECT | PRODUCT | C4 | Client-shipped (installed via `init-project.sh` S6) — post-F-1 it is unambiguously C4. |
| `project-template/` | PROJECT | PRODUCT(+OPS+TOOL-CONFIG inside) | C4 root | Client-shipped subtree; internal files split C4/C5/C6 per BOUNDARY §2. |
| `xcode-companion-templates/` | PROJECT-side-governed | PRODUCT | — | Dev-environment configs; project-side CONTENT rules apply; Check 37 walk extended to cover (§2.2). |
| `vscode-companion-templates/` | PROJECT-side-governed | PRODUCT | — | Dev-environment configs; project-side CONTENT rules apply; Check 37 walk extended to cover (§2.2). |

### 2.2 Companion-template surfaces — governed by project-side content rules (D1)

> **Empirical-Evidence Block EE-2 — companion-template contents.**
> Command: `git ls-files xcode-companion-templates/ vscode-companion-templates/`. HEAD `3bef42b`.
> Output: xcode = `ClaudeAgentConfig/{CLAUDE.md,settings.json}`, `Codex/{AGENTS.md,config.toml}`, `README.md`, `.gitignore` (6). vscode = `.vscode/{extensions.json,settings.json,tasks.json}`, `README.md` (4).
> Interpretation: these contents are project-related developer/IDE configs a developer applies to their machine or editor workspace — they are NOT pack internals.
> Conclusion: **SUPPORTED** as content; the audience framing is corrected below.

**Verdict (D1, user-corrected):** these are **governed by the SAME content rules as any project-side asset** — their contents are project-related dev configs and MUST NOT reference pack internals (pack-only docs, `pack-ops/` paths, pack-* agents, the `Pack Chat` role, BDs operationally). The earlier "PACK × PRODUCT / developer-environment" framing is REJECTED. **No new matrix category, no rename, no new audience.** Concretely: Bans A/B (§4.1) apply to these trees exactly as they apply to `project-template/`. **SETTLED (decision A):** the Check 37 deny-list walk (`_iter_client_installed_files()`, which today does NOT include the companion-template dirs) IS extended to cover `xcode-companion-templates/` and `vscode-companion-templates/`. Both dirs are grep-verified clean of pack-internal references today (HEAD `3bef42b`: zero deny-list-token hits) — so this is **forward protection only, zero cleanup cost**. Classification: project-side-governed content.

### 2.3 RESOLVED (D2): purpose classifies; location is convention

> **Empirical-Evidence Block EE-3 — the apparent contradiction.**
> Command: `grep -nE 'C2|pack-ops/|new top-level' pack-ops/BOUNDARY-DEFINITION.md`. HEAD `3bef42b`.
> Output: BOUNDARY §2 lists `maintenance-docs/**`, `scripts/validate-pack.py`, `scripts/pack-help.sh` as C2 examples (under root dirs `scripts/`, `maintenance-docs/`), while §3 step 3 says "C2 → `pack-ops/` (new top-level pack-only dir)".
> Conclusion: **NOT A DEFECT.**

**Governing principle (D2, user-set): PURPOSE classifies; LOCATION is convention.** An operations directory is correctly placed wherever it sits — `scripts/`, `maintenance-docs/`, `test-fixtures/` are PACK × OPERATIONS by PURPOSE, and root-vs-`pack-ops/` is irrelevant to their correctness. The only placement teeth that remain: **no NEW loose file is dumped at pack root** — a new loose file goes to its purpose-directory (a new pack-only prose doc → `pack-ops/`; a new script → `scripts/`; etc.), enforced by Check 38 + `.boundary-exempt-root.txt`. **Drop the stale "(new top-level pack-only dir)" wording** from BOUNDARY §3 — `pack-ops/` is established, not "new." **Recommendation:** BOUNDARY §3 states the purpose-classifies principle (one sentence) + the no-new-loose-root-file teeth; it does NOT state the Check-38 file-only-walk mechanism as if it were the rule (the mechanism implements the principle, it is not the principle).


---

## 3. HOW + WHEN, not just WHERE (the missing rule columns)

BOUNDARY-DEFINITION states placement (WHERE). Each rule needs two more columns. Design: BOUNDARY's §3 procedure gains a **HOW/WHEN** addendum (compact table, not prose):

| Rule | WHERE (placement) | HOW (applied) | WHEN (trigger/timing) |
|---|---|---|---|
| Audience×function verdict | per C1–C6 | run §3 four-step procedure on the artifact | at file CREATE or MOVE, before commit; CI Check 38 at PR-time (loose root files) |
| One-directional ban (§4.1) | n/a (content) | Check 37 deny-list grep | at every commit touching `project-template/` (CI) |
| Separated-not-combined (§4.2) | n/a (content) | opt-in labeled-block convention + EXISTING Check 37 (no new detection check) | enforced continuously by Check 37 (CI); convention applied at authoring (§4.2) |
| Cross-ref-network (B5, §4.3) | machine-readable | Check asserts pointer set | at commit touching a doc in the pointer set (CI) |
| Concision gate (M4, §6) | durable rule-doc class | pattern scan + per-doc advisory length | at commit touching a named durable rule doc (CI) |
| Rule↔rationale lock-step (C3, §5.2) | `PACK-MEMORY-RATIONALE.md` | 1:1 slug bijection check | at commit touching CLAUDE.md pack-memory or the rationale file (CI) |

The principle: **every boundary/content/concision rule is a CI check with a stated trigger**, so "when" is mechanical, not memory. This integrates v1's M4 gate into a uniform check family.

---

## 4. Content rules (formalized + enforcement designed)

### 4.1 The one-directional bans (unambiguous; already enforced — formalize)

These are absolute and mechanically checkable; Check 37 already implements the primary one:

- **Ban A — nothing under `project-template/` (and the client-installed set) may reference pack-side docs/paths/agent-names or the `Pack Chat` role.** Enforced by Check 37 (`check_project_side_deny_list`, walks `_iter_client_installed_files()`, deny-list grep with anchor-phrase + fenced-block exemptions). Status: SHIPPING. Formalize in BOUNDARY as a named rule, citing Check 37 as its teeth.
- **Ban B — client-facing surfaces never treat BDs operationally** (no BD dependency grammars / form admissions / parser regexes on client surfaces; explanatory mention with pack-only disclosure is allowed). Partially enforced; the BD-pack-only rule + Check family cover forms/configs. Formalize as the directional companion to Ban A.
- **Ban C (reverse direction) — pack-self-management surfaces never use project-side concepts (TD/phase/phase-part/phase-task) operationally** (deliverable-only rule). The construct-a-deliverable exception stands. Formalize; note the existing pack-side audit methodology (enumerate ENCODING surfaces) is the review-time teeth.

These are one-directional and absolute — no human judgment needed; the design is "name them in BOUNDARY + point at the existing checks." No new mechanism required for A/B/C beyond what ships.

### 4.2 Separated-not-combined — DECISION: drop the new detection check; convention + Check 37 suffice

**The rule (unchanged):** a client-installed doc MAY legitimately reference BOTH the pack-side and the project-side version of a concept; when it does, the two MUST be kept SEPARATED (clearly distinguished), never conflated into one claim that erases the boundary.

> **Empirical-Evidence Block EE-4 (CORRECTED by the `RESEARCH-SEPARATED-NOT-COMBINED-FEASIBILITY.md` spike — supersedes v2's 8-doc grep).**
> Command: the spike loaded `validate-pack.py`'s own `_iter_client_installed_files()` (161 files = the exact CI walk set) and measured docs co-referencing BOTH a Check-37 deny-list token (pack-side) AND a project-side SSOT token. HEAD `3bef42b`, 2026-05-30.
> Output — **12** candidate docs (the authoritative set; v2's "8" was a 2-directory prose-word grep and is WRONG):
> `project-template/{CLAUDE,AGENTS,GEMINI}.md`, `project-template/docs/pack/PACK-FEEDBACK.md`, `.../PM-CHAT.md`, `.../prompts/coder.md`, `.../prompts/reviewer.md`, `project-template/skills/boundary-investigation/SKILL.md`, `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `scripts/pack-help.sh`, `scripts/lib/detect.sh`.
> Scope correction: v2's EE-4 included `supporting-docs/MIGRATION-v10-to-v11.md` — it is **NOT in `_iter_client_installed_files()`** (pre-install reference, never copied to clients), so the §4.2 check could never see it; removed.
> Findings: **0/12 use labeled blocks**; **all 12 are legitimately-separated boundary-TEACHING content** (they name pack-side tokens precisely to FORBID them and point at the project-side SSOT); **0 conflations**; **Check 37 already PASSES on all 12** (6 anchor-legitimate + 584 fenced-exempt lines).
> Conclusion: **SUPPORTED.** Co-reference presence is satisfied by legitimate boundary-teaching at 12/12 — it is NOT a conflation signal. The proposed "references both + no labeled block ⇒ flag" predicate is a **12/12 false-positive storm**, not a detector.

**DECISION (core of v3): DROP the flag-for-review detection half. §4.2 reduces to: (1) an opt-in structural convention + (2) the EXISTING Check 37.** Rationale, measured:

1. **The detection half cannot work as proposed and there is nothing for it to catch.** 0 conflations exist; the signal it keys on (co-reference) fires on legitimate content at 100%. A narrower predicate would have to re-derive exactly the anchor-phrase / fenced-block distinction Check 37 ALREADY makes on this exact corpus — building a second, parallel detector for a problem Check 37 already covers is duplication, not coverage. Per the simplicity-where-data-supports directive: drop it.

2. **Check 37 IS the detection teeth.** Check 37 distinguishes legitimate boundary content (anchor-phrase + fenced-exempt) from contamination on the client-installed set, and it already passes on all 12. A genuine conflation (a pack-side token used as a live project instruction, outside an anchor/fence) is a Check-37 FAILURE today — that is exactly the separated-not-combined violation, and it is already caught. No new check needed.

3. **The structural convention stays as an OPT-IN authoring aid, not a mandate.** Authors MAY use `<!-- PACK-SIDE -->`/`<!-- PROJECT-SIDE -->` labeled blocks where explicit separation helps a reader; the convention is documented in BOUNDARY §5 as guidance. It is NOT enforced by a new check (forcing markers onto 12 already-correct docs is invasive churn with zero defect yield). IF a future doc adopts the labels, the spike found the host machinery (`_build_fence_skip_lineset`) HARDCODES the single `DENY-LIST-CONTENT-START/END` pair and would need a **small parameterization refactor** to accept a second marker pair — so adopting the labels as enforced is a deferred, optional, refactor-gated follow-up, NOT part of this work.

**What §4.2 reduces to:** the separated-not-combined RULE is real and stays named in BOUNDARY §5; its ENFORCEMENT is the already-shipping Check 37 (continuous, CI) plus the opt-in labeled-block convention as documented guidance. **No new validator check is added for §4.2.** This removes one check, one per-check test, and the marker-refactor from this work's scope.

### 4.3 B5 — cross-reference-network → CI check (locked = A)

BOUNDARY §6 (28 lines of "discoverability invariant" prose enumerating every surface that points at the doc) is replaced by a machine-readable pointer manifest + a check that asserts each named surface still carries its pointer. Pattern: follows the existing `check_cross_reference_integrity` (Check 34) + `.boundary-exempt-root.txt` allowlist-file model. The prose network → a `pack-ops/.boundary-pointer-manifest.txt` (surface → expected pointer); the check verifies presence; the durable doc keeps ONE line ("Pointer network is CI-asserted; see the manifest"). Removes the stale-by-construction §6 prose (which already encodes "post-Commit 2 location" drift, v1 EE-1).

---

## 5. Locked-decision designs (C1, C3 — the added constraints)

### 5.1 C1 — imperative line that stands alone for APPLICATION + reliable rationale fallback

**Locked:** "literal rule text" in agent prompts = imperative line + rationale-doc pointer. **Added constraints designed:**

**(i) Imperative lines must stand alone for correct APPLICATION, not just identification.** Design: the imperative line is authored to a **two-clause contract** — `<DIRECTIVE: what to do>` + `<TRIGGER: when/on-what-surface>`. Identification-only ("verify state-claims with evidence") is insufficient; application-grade is "Every state-claim in an architect/planner output carries an Empirical-Evidence Block (command + verbatim output + HEAD-SHA + conclusion) — applied to every assertion about repo/downstream state." The test an author applies: *can an agent that has NEVER read the rationale apply this correctly?* If no, the imperative is under-specified — the missing application detail moves UP into the imperative, not down into rationale. Rationale holds WHY + worked examples + rejected alternatives only — never load-bearing application detail. (This is also what bounds rationale-doc growth: nothing application-critical lives there.)

**(ii) Reliable "if ambiguous, read the rationale" mechanism — designed, not goodwill.** Three teeth, not exhortation:
- **Stable anchor per rule (when present).** A rule that carries a rationale ends its imperative line with a stable slug pointer `[rationale: <slug>]`; the slug resolves to a `## <slug>` heading in `PACK-MEMORY-RATIONALE.md`. The pointer is mechanical (a slug, not "see the rationale doc somewhere").
- **`[rationale: slug]` is OPTIONAL.** A rule carries `[rationale:]` only if it has a genuine rationale body (Why / How-to-apply / rejected-alternatives). A fully-application-grade, self-contained rule (whose two-clause imperative needs no further explanation) carries `[roles:]` but NO `[rationale:]` — authoring a filler rationale section for it is the duplication/bloat this design exists to prevent. Worked examples of the no-`[rationale:]` case (fully-application-grade, no rationale body): `per-entry-trees-vs-mirrors`, `separate-ops-from-product`, `test-infra-self-provisioned`.
- **Rules-Applied Block forces the resolution.** The existing per-rule Rules-Applied Verification Block (every agent output) is the choke point: a row whose Conclusion is `AMBIGUOUS` is INVALID — the agent must resolve ambiguity (by reading `[rationale: <slug>]`) and record either COMPLIANT/N-A/VIOLATED with evidence. "I wasn't sure" is not an allowed terminal state. This makes rationale-reading conditional-but-mandatory: triggered exactly when the agent cannot fill the block from the imperative alone.
- **Lock-step bijection (see C3) guarantees the pointer never dangles** — every PRESENT imperative slug has exactly one rationale entry, so any `[rationale: <slug>]` always resolves (rules without `[rationale:]` are simply outside the bijection set — see §5.2).

### 5.2 C3 — single `pack-ops/PACK-MEMORY-RATIONALE.md`, fully specified + lock-step enforced

**Surface specification:**
- **Path/audience:** `pack-ops/PACK-MEMORY-RATIONALE.md` — PACK × OPERATIONS (C2), pack-only, not installed to clients.
- **Read-trigger:** read ON-DEMAND only — when an agent hits an `AMBIGUOUS` Rules-Applied row (§5.1.ii) and follows `[rationale: <slug>]`. NOT loaded into every prompt (that is the bloat C1 removes). Pack Chat does NOT paste rationale into spawn prompts — only imperative lines + slugs.
- **Update-trigger:** edited in LOCK-STEP with `CLAUDE.md` `## Pack memory` — adding/removing/renaming a rule slug requires the matching rationale entry in the SAME commit. Trinity: the rationale file is pack-root-adjacent (`pack-ops/`), NOT a trinity file; CLAUDE/AGENTS/GEMINI pack-memory still move in lock-step among themselves (the imperative lines), and all three point at the one rationale file.
- **Structure:** one `## <slug>` section per rule = Why + How-to-apply-worked-example + rejected-alternatives. No SHAs/dates in the imperative; the rationale MAY carry a date/SHA only inside a clearly-marked historical-context note (it is a C2 ops doc, not the durable forward-only rule line — consistent with C2's surface-separation).

**Lock-step enforcement (new check) — the bijection (over the PRESENT `[rationale:]` set):** every corpus `[rationale: slug]` resolves to exactly one `## <slug>` heading in `PACK-MEMORY-RATIONALE.md`, AND every heading maps to exactly one live `[rationale: slug]`. Rules without `[rationale:]` are simply not in the set; the check does NOT require every spawn-rule to have a rationale.
- Parse rule slugs from `CLAUDE.md` `## Pack memory` (each imperative line that CARRIES a `[rationale: <slug>]`; lines with no `[rationale:]` are excluded from the set).
- Parse `## <slug>` headings from `PACK-MEMORY-RATIONALE.md`.
- **FAIL** if the two sets are not equal (every PRESENT `[rationale: slug]` has exactly one rationale entry; every rationale entry maps to exactly one live `[rationale: slug]` — no orphans either direction; rules carrying no `[rationale:]` are out of scope).
- Pattern: follows `check_mirror_in_sync` (Check 32) — a set-equality assertion between two surfaces. Trigger: any commit touching either file. This makes drift impossible: you cannot delete a rule and orphan its rationale, or add rationale for a rule that does not exist.

---

## 6. Concision mechanism (M1–M4) integrated (v1 retained, compressed)

Unchanged from v1; restated for the one-doc directive:

- **M1 — proof leaves the deliverable.** Evidence blocks + Rules-Applied tables live in the agent report (archived on ship); durable doc keeps a one-line attestation + report pointer.
- **M2 — rule corpus splits (not shrinks-in-place).** Imperative line stays in `CLAUDE.md`; Why/example → `PACK-MEMORY-RATIONALE.md` (§5.2). Realizes C1.
- **M3 — finding records hard-cap per field** (one-line evidence, rule-by-name). Collapses PLAN-BD-195 §3.2's 12-field record.
- **M4 — concision gate.** New `validate-pack.py` check over the named durable-rule-doc class (the 7 `pack-ops/` non-mirror docs): forbidden-pattern count = 0 outside allowlist (the teeth) + per-doc advisory length (derived, not round-number). **C2 confirmed:** SHAs/dates mandatory in reports, forbidden in durable docs — surface-separation, no rule change.

**SC1 limits (v1, retained):** enforcing limit = forbidden-pattern count 0 outside allowlist; length is per-doc advisory derived from measured legitimate content. **The post-fix 0-outside-allowlist proof is a CODER obligation** (v1 EE-5; cannot be discharged read-only).

---

## 7. Target shape — reshaped `BOUNDARY-DEFINITION.md` (design only)

> **Empirical-Evidence Block EE-5 — current vs target.**
> Current: 255 lines; rule body ~40 (§2 matrix + §3 four-step); ~215 lines history/worked-examples/cross-ref-network (v1 EE-1). HEAD `3bef42b`.
> Target: ~80–95 lines.
> Conclusion: SUPPORTED (current measured; target is the design goal the coder verifies).

Target structure (forward-only imperatives; everything else relocated):
- §1 Purpose — 4 lines (what + read-before-classifying).
- §2 The matrix — KEEP (the C1–C6 table + the developer-environment C1 sub-case note from §2.2). ~30 lines.
- §3 Verdict procedure — KEEP the four steps + the WHEN/HOW addendum table (§3 of this doc). + the §2.3 C2-DIR-vs-loose-file governing sentence. ~25 lines.
- §4 Root exemption — KEEP (1-entry list + "adding requires approval"). ~8 lines.
- §5 Content rules — NEW, compact: name Bans A/B/C (§4.1) + separated-not-combined (§4.2), each one line + its check name. ~10 lines.
- Cross-ref network (old §6) → DELETED, replaced by one line: "Pointer network is CI-asserted (`.boundary-pointer-manifest.txt`)." (B5).
- Worked examples (old §7, ~60 lines) + anti-pattern catalog history (old §5) → MOVE to a rationale sibling or `maintenance-docs/archive/` (the V1-failure worked example is history). The rule does not need them at read-time.
- Override-history / rejected-alternatives (old §4 "Why only 1 entry") → MOVE to rationale/archive.
- NO dates, NO `Commit N`/`Override N`, NO "will/post-Commit" temporal claims (the M4 forbidden set).

---

## 8. What a downstream planner sequences (not designed here)

1. Amend pack-memory rules per C1 (imperative-line two-clause contract + `[rationale: slug]`) — trinity lock-step. **SAME edit (§9.4/§9.5):** add the `[roles: …]` tag inline to each spawn-relevant imperative line (trinity'd).
2. Author `pack-ops/PACK-MEMORY-RATIONALE.md`; split Why/examples out of CLAUDE.md pack-memory.
3. Reshape `BOUNDARY-DEFINITION.md` to §7 target; relocate §5–§7 history; add the §2.3 purpose-classifies principle + the §2.2 companion-template content-rule note + WHEN/HOW table + the §4.2 separated-not-combined rule named in §5 with Check 37 as its teeth + opt-in label convention as guidance.
4. Add validator checks: M4 concision gate (+ per-doc allowlist + advisory length); C3 rule↔rationale bijection; B5 pointer-manifest. (NO §4.2 check — dropped; Check 37 + opt-in convention suffice.)
4b. (§9.6) Author `pack-ops/.spawn-rule-manifest.txt` (slug → canonical `## Pack memory` + reference surfaces); collapse the 6 EE-6 restatements in `PACK-AGENTS.md`/`PACK-CHAT.md` to one-line references; add the spawn-rule check (anti-restate substring scan + reference-resolution, mirrors B5/C3).
4c. Extend Check 37's file walk (`_iter_client_installed_files()` / the check's walk set) to include `xcode-companion-templates/` + `vscode-companion-templates/` (§2.2 decision A); update the Check-37 per-check test for the expanded walk set and confirm CI green (both dirs are clean today, so the extension is non-breaking).
4e. (§11) Index stays DROPPED (Decision B). Add the DURABLE one-line routing pointers (§11.3): PACK-CHAT.md § "File access strategy" gains 4 pointers (rules/placement/rationale/change-procedure → their SSOTs); the `review` skill's existing SSOT cites gain the `[roles: reviewer]`+universal pointer; BOUNDARY + agents need none (self-homed / inline-paste). Fold the PACK-CHAT/BOUNDARY routing pointers into `.boundary-pointer-manifest.txt` so the existing B5 reference-resolution check keeps them resolvable — no new check, no view.
4f. (§12) EXTEND `pack-ops/PACK-CHAT.md` § "Keeping … current" with the ordered rule-change propagation table (surfaces 1-6 + enforcing checks); add a one-line pointer from the CLAUDE.md `## Pack memory` stale-entry rule. Composes existing checks; no new check.
4d. (§9.7) Make the per-rule memory-cache files thin pointers (one-line imperative + `[rationale: slug]`; drop copied Why/How bodies). NO pack-repo generator — the cache is out-of-repo, maintained by Pack Chat as memory upkeep; trinity-wins is the only drift control. Not a script, not a commit touching `~/.claude/`.
5. Wire each new check's per-check test + CI (Check 43 enforces wiring).
6. Reshape the other 6 `pack-ops/` durable docs; collapse finding-record (M3).
7. Re-run pattern scan against reshaped tree; prove 0-outside-allowlist (v1 EE-5 coder obligation). Manifest regen check (pack-ops/ is fixture-affecting; expected-empty diff but mandated).
7b. **STALE-REFERENCE BLAST-RADIUS SWEEP (mandatory completion criterion of every reshape/removal step above — not an afterthought).** For EVERY surface this implementation moves / deletes / reshapes, grep the WHOLE repo for inbound references (arbitrary prose cites like "see `BOUNDARY-DEFINITION.md` §6", "per the rationale in `## Pack memory`", "`PACK-AGENTS.md` § x restates …", "the cache file's Why", "the separated-not-combined check", "the discoverability index", "new top-level pack-only dir") and FIX-OR-REMOVE each so nothing dangles. The reshaped/removed surfaces to sweep for:
   - BOUNDARY `§5` (anti-pattern catalog) + `§6` (cross-ref network, DELETED per B5) + `§7` (worked examples) — relocated/deleted (§7).
   - The corpus `## Pack memory` Why/How/example BODIES — moved to `PACK-MEMORY-RATIONALE.md` (M2/C3): any cite of "the Why in `## Pack memory`" must repoint to the `[rationale: slug]`.
   - The 6 collapsed `PACK-AGENTS.md`/`PACK-CHAT.md` restatements (§9.6) — any cite of "as restated in PACK-AGENTS" must repoint to the canonical corpus line.
   - The stripped memory-cache bodies (§9.7) — any cite expecting the full body in a cache file.
   - The DROPPED §4.2 separated-not-combined check — any cite of "the §4.2 check / the labeled-block check".
   - The WITHDRAWN discoverability index (§11.2) — any cite of "the rule×audience index".
   - The dropped `"(new top-level pack-only dir)"` wording in BOUNDARY §3/§4 (§2.3).
   Where the dangle is in a manifest-covered surface, extend the existing reference-resolution check (Check 34 / `.boundary-pointer-manifest.txt` / `.spawn-rule-manifest.txt`) to FAIL on it; but the sweep is planner-sequenced because arbitrary prose references are NOT all check-covered. This step is NOT a post-work final audit (that is planner+rule territory, out of scope) — it is the inbound-reference repair that COMPLETES each reshape.
8. (Optional, deferred) IF a future doc adopts `<!-- PACK-SIDE -->` labels as ENFORCED, parameterize `_build_fence_skip_lineset` for a second marker pair (spike SC3) — not in this work.

---

## 9. Spawn-source consolidation — single home for spawn-relevant agent rules

### 9.0 Governing principle (SSOT)

**Single source of truth by default; any RETAINED duplication MUST carry a documented legitimate reason.** A spawn-relevant rule is authored ONCE (its imperative in `## Pack memory`; its rationale in `PACK-MEMORY-RATIONALE.md`; its execution checklist in its skill — three different contents, not three copies). The anti-restate check (§9.6) enforces NO UNjustified duplication; every surviving duplication is enumerated with its justification in §9.8.

### 9.1 The duplication map (measured — complete)

> **Empirical-Evidence Block EE-6 — spawn-relevant rule inventory + duplication across the four surfaces.**
> Command: enumerated `## Pack memory` rule bullets (`awk` over `CLAUDE.md`), then `grep -n` the rule-bearing sections of `pack-ops/PACK-AGENTS.md` + `pack-ops/PACK-CHAT.md` + the 4 spawn-relevant skills (`commit-discipline`, `review`, `planning`, `implementation-report`). HEAD `3bef42b`, 2026-05-30.
> Output (counts): `## Pack memory` carries **45 rule bullets** across 5 subsections (Workflow / Agent-invocation / Sub-agent-behavior(Claude-only) / Pack-Chat-scope / Repo-conventions). Of these, **~22 are spawn-relevant** (apply to an agent at spawn time); the rest are Pack-Chat-orchestration or repo-maintenance rules. Duplication FOUND — but mostly already REFERENCE-style, not free restatement:
>
> | Rule | `## Pack memory` | PACK-AGENTS.md | PACK-CHAT.md | skills | Duplication kind |
> |---|---|---|---|---|---|
> | Agents never commit / git-state-change ban | canonical (L145) | RESTATED (L116-128 "also recorded under Pack memory") | "no commit without approval" (L7 — Pack-Chat-scoped) | commit-discipline operationalizes | RESTATE (PACK-AGENTS) |
> | PREFLIGHT + STOP-MEANS-STOP | canonical (L286) | REFERENCE w/ partial restate (L190-228; ends "Authoritative full text: trinity ## Pack memory") | — | — | PARTIAL restate |
> | Agent permission / role-write scope | canonical via "What Pack Chat CAN edit" + roster | RESTATED (L128-138) | — | — | RESTATE (PACK-AGENTS) |
> | Bounded review/fix cadence | canonical (L601) | — | RESTATED (triage-stop L63; cadence cited L76-77) | review skill operationalizes carry-forward | RESTATE (PACK-CHAT) |
> | Rules-Applied / Empirical-Evidence / enumerate-inline | canonical (L360/396/426) | — | — | — | SINGLE (no dup) |
> | Triage/fix-all/no-fixes | canonical (L212/221/539) | — | RESTATED (L63-70) | review operationalizes | RESTATE (PACK-CHAT) |
> | Skill/agent maintainability | canonical (L773) | REFERENCE (L229-232) | — | — | REFERENCE |
> **Skills — ALL 9 measured (v5 completion).** `grep -cnE` of signature spawn-rule imperatives (`never commit`/`git add`/`PREFLIGHT`/`STOP-MEANS`/`Rules-Applied Verification`/`Empirical-Evidence Block`/`bounded review/fix`/`enumerate ALL applicable`) across all 9 pack-loaded skills returned: `review` = operationalizes (carry-forward checklist, CITES pack memory, no imperative restate); the other 8 — `commit-discipline`, `planning`, `implementation-report`, `boundary-investigation`, `verification-harness`, `architecture-review`, `documentation`, `dependency-intake` — returned **0** restatements. Conclusion: NO skill restates a spawn-rule imperative; skills OPERATIONALIZE only.
> **5th surface — the Claude-Code memory cache (v5 completion; EE-6 previously OMITTED it).** Command: `ls /Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/` + sampled `feedback_agent_output_rules_applied_block.md`. Output: **27 files** = `MEMORY.md` (index) + **26 per-rule files** (`feedback_*`/`reference_*`/`project_*`), each carrying the rule's FULL body (name + Why + How-to-apply — the sample was 33 lines: imperative + "**Why:** User-locked …" + "**How to apply:** …"). This is a **full parallel duplication of the `## Pack memory` corpus** (index mirrors the bullet names; per-rule files mirror the bodies). The index already declares "TRINITY WINS" on conflict. It lives OUTSIDE the repo (`~/.claude/...`) → the pack validator CANNOT reach it.
> Conclusion: **SUPPORTED (complete).** Restatement duplication = **6 in PACK-AGENTS/PACK-CHAT** (3 each) + the **whole memory cache** (27 files mirroring the corpus). Skills do NOT restate. `## Pack memory` is the canonical home; the fix is reference-not-restate for the 6, and the §9.7 sync approach for the cache (un-enforceable by validator).
> **MEASURED CORRECTION (supersedes the cache claim above; see §9.7 "Realized scope").** Re-measurement of the memory dir found **27 per-rule files** (plus the `MEMORY.md` index — 28 entries total, not "27 files incl. index + 26 per-rule"), and the cache is NOT a full parallel duplication of the corpus: only **4** files were genuine trinity-rule-with-rationale duplicates (those 4 were thinned to one-line-imperative + `[rationale: slug]` pointers); the other **23** are standalone SSOT memory (project state / references / feedback) with no corpus counterpart and were left intact; and **14 of the 18** rationale slugs have NO cache file. The original observation above is retained as the as-recorded design-time measurement; §9.7 carries the realized scope the design was actually executed against.

### 9.2 Single spawn-source — `## Pack memory` confirmed (challenge resolved)

The user-endorsed direction (`## Pack memory` imperative corpus = single spawn-source) is **CONFIRMED on the evidence** — no better home exists: it is already canonical for all 22 spawn-relevant rules, it is trinity (every CLI loads it at session start), and C1/M2 already give each rule a stable imperative line + `[rationale: slug]`. Moving spawn rules to PACK-AGENTS instead would break the "loaded every session" property (PACK-AGENTS is read on-demand). **Design:** the 6 restatements in PACK-AGENTS/PACK-CHAT collapse to one-line REFERENCES of the form "X — see trinity `## Pack memory` `[rationale: <slug>]`" (the PREFLIGHT block already models this).

### 9.3 The rules-vs-content boundary (precise)

- **CONSOLIDATES (spawn-relevant RULE STATEMENT):** an imperative an AGENT must obey at spawn time, independent of which doc names it (git-ban, PREFLIGHT, permissions, review/fix cadence, Rules-Applied/Empirical-Evidence obligations, enumerate-inline). Test: *"would Pack Chat paste this into a spawn prompt?"* If yes → it consolidates to `## Pack memory`.
- **STAYS-AND-REFERENCES (non-rule doc content):** PACK-AGENTS' roster + how-to-invoke + the PM-only file LIST (data, not a spawn rule); PACK-CHAT's Role / startup / behavioral framing / session-naming; the skills' operational CHECKLISTS (the *how-to-execute* a rule, e.g. the review skill's carry-forward three-test procedure). Test: *"is this doc-structural or a how-to-execute, not an agent-must-obey imperative?"* If yes → stays where it lives, references the rule.

The line: `## Pack memory` owns the IMPERATIVE; the skills own the EXECUTION CHECKLIST; PACK-AGENTS/PACK-CHAT own the ROSTER/FRAMING/DATA. A rule is stated once (pack memory) and operationalized once (its skill) — never restated.

### 9.4 Role-tagging

Each spawn-relevant `## Pack memory` rule gains a role tag inline on its imperative line: `[roles: architect planner coder reviewer docs-researcher | universal]`. Spawn-assembly = "select rules tagged for THIS role + universal." Examples: PREFLIGHT `[roles: coder]`; Empirical-Evidence-Blocks `[roles: architect planner]`; git-ban + Rules-Applied-Block + STOP-MEANS-STOP + trinity + prison `[roles: universal]`. The tag is a controlled vocabulary (exactly the 5 role names + `universal`); a new tag value is a structural change.

### 9.5 Trinity interaction

Role-tags live INLINE in the imperative line, so they ARE trinity'd — all three of `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` carry the identical tagged line (trinity parity holds by construction; the tag is part of the rule text the trinity rule already governs). The `[rationale: slug]` pointer is ALSO trinity'd (same line); the single rationale FILE it resolves to is NOT trinity (one `pack-ops/PACK-MEMORY-RATIONALE.md`). So: imperative + role-tag + slug = trinity (×3, parity-checked); rationale body = single C2 file. No conflict — the "single source" claim is about the rationale BODY and the spawn-rule TEXT being authored once; trinity replication of the text is the existing parity mechanism, not duplication.

### 9.6 Dedup resolution + enforcement

- **Dedup:** for each of the 6 restated rules (EE-6), the ONE canonical home is `## Pack memory`; PACK-AGENTS/PACK-CHAT restatements become one-line references. Honors pack-ops C2 (all four surfaces are pack-ops/pack-root C2 — no pack/project boundary crossed).
- **Enforcement — ADD a check (accept).** A validator check (mirrors B5 pointer-manifest + C3 bijection) over a `pack-ops/.spawn-rule-manifest.txt` mapping `slug → {canonical: ## Pack memory, references: [PACK-AGENTS.md §x, PACK-CHAT.md §y]}`: (a) every referenced surface carries a resolving reference to the slug; (b) NO spawn-relevant rule's imperative TEXT appears verbatim in 2+ surfaces (anti-restate scan — a substring-match of the canonical imperative against the other three surfaces FAILS on a hit). This is the teeth that keeps the 6 restatements from silently returning. Trigger: commit touching any of the four surfaces. Reuses the Check-32 set-comparison + Check-34 cross-ref patterns.

### 9.7 Memory-cache resolution (out-of-repo; validator cannot reach it)

**Realized scope (measured at execution, supersedes the design-time premise).** The original premise — that the per-rule cache files all duplicate the content C3 splits — proved too broad on measurement. The out-of-repo memory dir holds **27** per-rule files (plus the `MEMORY.md` index). Only **4** were genuine trinity-rule-with-rationale duplicates (`agent-output-rules-applied-block`, `architect-planner-empirical-evidence`, `ci-guard-design-measure-then-bound`, `manifest-regen-on-v11-surface`); those 4 carried full Why/How-to-apply bodies that would TRIPLICATE the rationale (corpus line + `PACK-MEMORY-RATIONALE.md` + cache body) post-C3, so they were thinned to one-line-imperative + `[rationale: slug]` pointers (the cache-as-pointer model below). The other **23** are standalone SSOT memory (project state / references / feedback NOT in the trinity corpus) and were correctly left intact — they have no corpus counterpart to triplicate against. And **14 of the 18** rationale slugs have NO cache file at all, so the cache was never a full parallel mirror of the rationale set. No pack validator check can fire on `~/.claude/...` regardless. Design (applied to the 4 genuine duplicates; the 23 standalone files are untouched):

- **Cache files become THIN pointers, not body copies.** Each per-rule cache file's body is reduced to: the imperative line (one line, for in-session recall) + the `[rationale: slug]` pointer into `pack-ops/PACK-MEMORY-RATIONALE.md`. No Why/How-to-apply copied. This removes the triplication: the body lives once (rationale file); the cache holds a pointer + the one-line imperative the session needs for fast recall.
- **NOT regenerated by any pack-repo tool (option B).** There is NO pack-side generator. The pack does NOT write into `~/.claude/`. The cache stays the user's / Pack Chat's artifact, maintained as part of normal memory upkeep when the corpus changes. A pack-repo script writing into the user's home dir with a machine/clone-specific slug would be fragile over-reach. The existing "TRINITY WINS on conflict" disclaimer in `MEMORY.md` is the drift safety-net.
- **Drift control without a validator.** Because the validator cannot see `~/.claude/`, drift control is: (a) Pack Chat updates the thin cache files as normal memory upkeep when the corpus changes; (b) the cache holds only a one-line imperative + `[rationale: slug]`, so the load-bearing body lives once (in the rationale file) and cannot drift; (c) the trinity-wins disclaimer means any residual stale cache loses to the corpus by rule. The cache is JUSTIFIED-BUT-UNENFORCEABLE (§9.8) — the mitigation is thin-pointers + Pack-Chat upkeep + trinity-wins, not a CI gate and not a pack-repo generator.

### 9.8 Duplication-classification table

| Duplication | Verdict | Reason |
|---|---|---|
| Trinity replication (×3 `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`) | JUSTIFIED | Parity mechanism — each CLI loads its own file. |
| Imperative (corpus) vs execution-checklist (skill) | NOT DUPLICATION | Different content. |
| Imperative (corpus) vs rationale (rationale file) | NOT DUPLICATION | The C1/M2 split. |
| The 6 PACK-AGENTS/PACK-CHAT restatements (EE-6) | NOT JUSTIFIED → CLOSE | Collapse to references; anti-restate check (§9.6) enforces. |
| Claude-Code memory cache (27 files) | JUSTIFIED-BUT-UNENFORCEABLE | Out-of-repo session memory, trinity-wins; mitigation = §9.7 thin-pointers + Pack-Chat memory upkeep + trinity-wins (no pack generator). |

---

## 10. Discovery sweep (gating — measure-then-bound)

> **Empirical-Evidence Block EE-7 — whole-repo sweep for existing discoverability maps + rule-change procedures.**
> Command: whole-repo `grep -rilnE` (excluding `prison/`, `archive/`, `.git/`) for (i) audience/use-case rule maps (`which (actor|agent|audience).*(rule|applies)`, `discoverability (invariant|map|network)`, `who (reads|applies).*rule`) and (ii) rule-change/propagation procedures (`how to (add|change|remove).*rule`, `propagat`, `keeping .* current`, `surfaces to (touch|update)`). Then narrowed to the authoritative homes (pack-ops/ + trinity). HEAD `3bef42b`, 2026-05-30.
> Output, classified:
>
> | Finding | Where | Classification |
> |---|---|---|
> | File-discoverability cross-reference network (which entry point reaches the boundary rule) | `pack-ops/BOUNDARY-DEFINITION.md` §6 | EXISTS, CORRECTLY PLACED — but it maps DOCS→entry-points, not RULES→audiences; B5 (§4.3) already converts its prose to `.boundary-pointer-manifest.txt`. REUSE the pattern for the rule-map. |
> | Partial rule-change/maintenance procedure ("after any commit that changes … core operating rules: review all four files; update in same commit") | `pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current" | EXISTS, CORRECTLY PLACED — covers the 4 trinity/PACK-AGENTS surfaces but NOT the new corpus surfaces (`[roles:]` tag, `[rationale: slug]`, rationale file, thin cache, `.spawn-rule-manifest.txt`). EXTEND it. |
> | Stale-entry rule ("when a learning becomes stale, update or remove the entry in the same commit as the behavior change") | `CLAUDE.md` `## Pack memory` preamble | EXISTS, CORRECTLY PLACED — the per-rule lifecycle rule. EXTEND with the propagation ORDER. |
> | `PLAN-DOC-CONCISION-GUARDRAILS.md`, `PACK-REVIEW-PHASE-2-DESIGNS.md`, `AUDIT-BD-195-RECONCILED-PROBLEM-LIST.md` | `maintenance-docs/v11-implementation/` | DOWNSTREAM workflow artifacts OF this design (planner/review/audit), not competing designs — they cite this doc, do not predesign (a)/(b). No contradiction. |
> Conclusion: **SUPPORTED.** NO buried map, NO contradicting procedure. Both (a) and (b) are PARTIALLY present in the correct pack-ops homes (BOUNDARY §6 pattern; PACK-CHAT "Keeping current"; CLAUDE.md stale-entry rule) and ABSENT only in the new dimensions this design adds. Verdict: **EXTEND the existing correctly-placed surfaces; add NO new buried doc.** Nothing to relocate; nothing to reconcile.

## 11. Discoverability — single-SSOT design (REDESIGNED: decisions, not enumeration)

§9.4 tags spawn rules with roles; this section decides the AUTHORITATIVE discovery model for ALL rule classes. Four decisions:

### 11.1 Decision A — single-SSOT enumeration (one authority per concept)

> **Empirical-Evidence Block EE-8 — every governed concept resolves to exactly one SSOT.**
> Method: enumerated each concept the guardrails govern; for each, located its single authoritative home by reading the surface (not asserted). HEAD `3bef42b`, 2026-05-30.

| Concept | Single SSOT | Everything else |
|---|---|---|
| Which rules apply to agent role X | the `[roles:]` tag on each `## Pack memory` imperative (§9.4) | derived: a role-filtered selection, not a second list |
| Canonical imperative of rule Z | the rule's one imperative line in `CLAUDE.md ## Pack memory` (trinity-replicated, parity-checked) | PACK-AGENTS/PACK-CHAT carry one-line REFERENCES (§9.6 anti-restate forbids a second copy) |
| Rationale of rule Z (Why/How/example) | the `## <slug>` entry in `pack-ops/PACK-MEMORY-RATIONALE.md` (§5.2) | thin cache = `[rationale: slug]` pointer only (§9.7) |
| Where file type Y lives (placement) | the §2 audience×function matrix in `pack-ops/BOUNDARY-DEFINITION.md` | Check 38 + `.boundary-exempt-root.txt` enforce it; not a second authority |
| When/how a rule is applied (timing) | the §3 HOW/WHEN table in `BOUNDARY-DEFINITION.md` | — |
| Content bans A/B/C | named in BOUNDARY §5; ENFORCED by Check 37 | Check 37 is the teeth, not a rival statement |
| Separated-not-combined | BOUNDARY §5 rule; Check 37 enforces (§4.2) | opt-in label convention is guidance, not authority |
| Which surfaces reference rule Z / pointer network | `pack-ops/.spawn-rule-manifest.txt` (spawn refs, §9.6) + `.boundary-pointer-manifest.txt` (B5, §4.3) | the prose networks they replaced are DELETED |

**Every concept resolves to exactly one SSOT; there are no duplicate authorities.** The one concept that previously had two homes — rule rationale (corpus body + cache body) — is collapsed by C3/§9.7: corpus imperative + single rationale file + cache-as-pointer. No remaining concept is co-owned.

### 11.2 Decision B — discoverability mechanism: the SSOTs ARE the map; the index is DROPPED

The authoritative discovery mechanism is the SSOTs themselves: the `[roles:]` tags (spawn rules) + the §2 matrix (placement) + the §3 HOW/WHEN table (timing) + the two manifests (references). **Decision: DROP the unified index.** A hand-maintained "convenience view" is forbidden (it is exactly the drift-prone duplicate this effort kills); a GENERATED index is rejected too — it would add a generator + a source-of-truth question for zero benefit, because the SSOTs are already directly queryable (grep a `[roles:]` tag; read one matrix). The v6 "append an index table to PACK-CHAT" proposal is WITHDRAWN. Discovery = query the SSOT directly (§11.3 gives the exact query per actor). Nothing to keep current beyond the SSOTs themselves.

**Durable routing (closes the post-ship gap).** §11.3's routing must NOT live only in this design doc (it archives on ship). Each actor's STARTING doc carries a ONE-LINE POINTER to its rule-SSOT (a reference, not a view). This is NOT the dropped index: the index was a denormalized rule×audience table (one surface enumerating all rules per actor); these are one-line pointers in the docs an actor already reads at start, each saying only "for X, read SSOT Z" — one hop to the authority, zero enumeration. **One-hop guarantee:** agents = ZERO hops (Pack Chat pastes the `[roles:]`-tagged imperatives INLINE into the spawn prompt — no entry-doc lookup); every other actor = ONE hop (entry doc → SSOT). The `[rationale: slug]` follow is the only deeper hop, taken only on AMBIGUITY (C1-(ii)).

### 11.3 Decision C — per-audience deterministic discovery path

Each actor × use-case → the exact SSOT + filter it reads. No actor guesses:

| Actor | Use-case | Deterministic path |
|---|---|---|
| Any of the 5 agent roles | spawn | Pack Chat selects `## Pack memory` rules whose `[roles:]` tag contains THIS role OR `universal`; pastes imperative + `[rationale: slug]` |
| Pack-Chat | spawn / change a rule | reads `## Pack memory` (full corpus) + §12 procedure for changes |
| validator/CI | commit | runs the checks: Check 37 (bans), Check 38 (placement), C3 bijection, anti-restate, B5/spawn manifests |
| project-side-author | create/move file | reads BOUNDARY §2 matrix (audience=PROJECT rows) + §5 bans; resolves placement by §3 |
| file-mover (any) | create/move file | BOUNDARY §3 four-step verdict procedure → C1–C6 placement (same path as project-side-author for the matrix step; differs only in which rows apply) |
| reviewer | review | `review` skill checklist → the same SSOTs it operationalizes (bans, separated-not-combined, carry-forward); reads `[roles: reviewer]` + `universal` spawn rules |

Shared paths are explicit: project-side-author and file-mover share the BOUNDARY §2/§3 path (different applicable rows); every spawn actor shares the `[roles:]`-filter path (different tag value).

> **Empirical-Evidence Block EE-9 — each named entry doc can host its pointer (verified, not asserted).**
> `grep -nE` HEAD `3bef42b` 2026-05-30: `pack-ops/PACK-CHAT.md` is the startup doc (L3) with a `## File access strategy` section (L38) to host the 4 pointers; `pack-ops/BOUNDARY-DEFINITION.md` is self-homed (§2 matrix + §3 procedure in-doc) and reachable via its §6/B5 pointer network (L20); the `review` skill already routes to SSOTs (L9 cites P-missed-7 + boundary-investigation). Conclusion: **SUPPORTED** — all hosts exist; no new doc needed.

**Durable home per actor (one-line pointer in the actor's entry doc — verified each doc can host it):**

| Actor | Durable entry doc (read at start) | The one-line pointer it carries |
|---|---|---|
| 5 agent roles | (none needed) | ZERO hops — Pack Chat pastes `[roles:]`-tagged imperatives inline at spawn |
| Pack-Chat | `pack-ops/PACK-CHAT.md` § "File access strategy" (startup doc) | rules → `## Pack memory`; placement → BOUNDARY §2; rationale → `PACK-MEMORY-RATIONALE.md`; change-procedure → §12 |
| file-mover / project-side-author | `pack-ops/BOUNDARY-DEFINITION.md` (IS the placement entry; reachable via the B5 §4.3 pointer network from every entry point) | self-homed — §2 matrix + §3 procedure are in the doc the actor lands on |
| reviewer | the `review` skill (already routes to the SSOTs it operationalizes — bans/P-missed-7/carry-forward) | extend its existing SSOT cites with `[roles: reviewer]` + universal spawn rules |

**No-drift mechanism (no new check, no view).** These pointers are one-line REFERENCES (anti-restate forbids a copied view). They ride EXISTING reference-resolution: the PACK-CHAT/BOUNDARY routing-pointers fold into `.boundary-pointer-manifest.txt` (B5, §4.3) — the same check that already asserts every named pointer surface resolves — so a dangling or stale routing pointer FAILS the existing check. The agents' inline-paste path needs no pointer (zero hops). No hand-maintained index; Decision B (§11.2) stays — index DROPPED.

### 11.4 Decision D — inclusion + precedence: FLAT, no precedence (by design)

All rule classes are accounted for in EE-8 (placement, timing, bans, separated-not-combined, concision, spawn, B5, C1/C3). **Precedence: FLAT — no rule overrides another, by design.** The classes are ORTHOGONAL (placement governs WHERE; bans govern content DIRECTION; concision governs durable-doc SHAPE; spawn rules govern AGENT BEHAVIOR) — they never contend for the same decision, so no precedence order is needed. If a future rule pair genuinely contends, that conflict is surfaced to the user (never-silently-resolve), not resolved by an implicit precedence.

## 12. Rule-change propagation procedure (EXTENDS PACK-CHAT "Keeping current" + CLAUDE.md stale-entry rule)

The standing workflow for add / change / remove a spawn-relevant rule, composed from the enforcement checks the design already defines:

| # | Surface to touch | Enforcing check |
|---|---|---|
| 1 | Corpus imperative line ×3 trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` `## Pack memory`), incl. `[roles:]` tag + `[rationale: slug]` | trinity-parity (existing) + role-tag controlled-vocab |
| 2 | `pack-ops/PACK-MEMORY-RATIONALE.md` — add/edit/remove the `## <slug>` entry | C3 bijection (slug-set equality, §5.2) |
| 3 | Thin memory-cache pointer (out-of-repo) | §9.7 — Pack-Chat upkeep; trinity-wins (NO validator gate, NO pack generator) |
| 4 | Any reference surface (PACK-AGENTS.md / PACK-CHAT.md one-line refs) | anti-restate scan + reference-resolution (§9.6) |
| 5 | `pack-ops/.spawn-rule-manifest.txt` slug→canonical+references | reference-resolution (§9.6) |
| 6 | `test-fixtures/manifest.txt` regen if a v11-surface path changed | existing manifest CI gate |

- **Order:** corpus (1) → rationale (2) → references (4) + manifest (5) in the SAME commit (so C3 bijection + anti-restate never see a half-applied state) → cache (3) as Pack-Chat upkeep → manifest regen (6) last. Removing a rule reverses: drop references first, then rationale, then corpus.
- **WHERE documented (no new doc):** EXTEND the existing `pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current" with this ordered table (it already owns the "keep operating rules current" procedure; the new corpus surfaces are added to its scope). The CLAUDE.md stale-entry rule gains a one-line pointer to it.
- **HOW enforced:** every step's check already exists in this design (C3 bijection, anti-restate, trinity-parity, manifest reference-resolution, fixtures manifest gate) — the procedure COMPOSES them; it adds no new check.
- **Caveat — order is documented, not gate-sequenced.** The propagation ORDER is a documented procedure verified by END-STATE checks (bijection / anti-restate / trinity-parity / manifest), NOT a hard-enforced sequence: a commit is atomic; nothing gates "step 1 before step 4" beyond the end-state invariants holding at commit time.

## 13. Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1 Trinity | §5.1/§5.2 + §9.5: imperative line + `[roles:]` tag + `[rationale: slug]` are trinity'd (parity by construction); rationale BODY is a single C2 file; §2 notes project-template carries DIFFERENT rules (no byte-align) | COMPLIANT |
| 2 Agents never commit | Only `git ls-files`/`grep`/`sed`/`cat` (read) + heredoc Write to designated path | COMPLIANT |
| 3 No destructive op | Read-only; single in-place Write to the v1 path | COMPLIANT |
| 4 Separate pack ops/product | §11.3 routing pointers live in existing pack-ops C2 entry docs (PACK-CHAT, BOUNDARY, review skill) + ride the B5 C2 manifest; no new surface; index stays dropped | COMPLIANT |
| 5 BOUNDARY SSOT + exemplar | Analyzed (EE-1/EE-3/EE-4/EE-5, §2.3, §7); NOT edited | COMPLIANT |
| 6 No solutions handed | C1/C3/B5/C2/D1/D2 designed-to (not relitigated); §9 single-source direction CONFIRMED on evidence (§9.2 challenge resolved) not rubber-stamped; §4.2 drop reached from the spike data | COMPLIANT |
| 7 Preliminary triage/challenge | §0 consistency check ran first; §4.2 detection half challenged AND dropped on measured evidence rather than preserved | COMPLIANT |
| 8 Measure-then-bound | EE-7 sweep; EE-8 single-SSOT enumeration; EE-9 verifies each named entry doc can host its routing pointer (PACK-CHAT startup+section, BOUNDARY self-homed+B5, review skill SSOT-routing) — by reading the surface, not asserting | COMPLIANT |
| 9 Empirical-Evidence Blocks | EE-1…EE-9: command + output + HEAD `3bef42b` + 2026-05-30 + SUPPORTED; EE-9 is the §11.3 entry-doc-host verification | COMPLIANT |
| 10 Rules-Applied Block | This table | COMPLIANT |
| 11 Concision/dogfood | This pass = ONE §8 step (7b) + ONE §1 clarifier; no section expanded; the sweep is a completion criterion of existing reshape steps, not a new audit phase | COMPLIANT |
| 12 Never silently resolve conflict | §0 + §10 EE-7 (no contradicting doc); §11.4 precedence is FLAT by design — a future genuine rule contention is SURFACED to the user, never resolved by implicit precedence | COMPLIANT |
| 13 Structural scope | Top-matter STRUCTURAL; §8 adds steps 4e/4f for §11/§12 (extend existing surfaces, compose existing checks — no new check, no new doc) | COMPLIANT |
| 14 Chunk Writes >300 | Doc body under threshold; single Write | COMPLIANT |
| P-missed-7 boundary discipline | §2.2 (D1) corrected companion templates to project-side-governed via project-side SSOT reasoning; §4.2 keyed enforcement to the project-side Check 37 walk, not a pack mechanism | COMPLIANT |
| Separation of concerns / deliverable-only / BD-pack-only / token-economy | §4.1 Bans A/B/C formalize exactly these; §5.2 rationale file is pack-only C2 | COMPLIANT |
| Researcher-first pipeline | The §4.2 researcher spike (`RESEARCH-SEPARATED-NOT-COMBINED-FEASIBILITY.md`) ran BEFORE this §4.2 design; the design folds its measured facts (12 docs, 0 conflations, storm) — not assumption | COMPLIANT |

**End of ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md (v9).**
