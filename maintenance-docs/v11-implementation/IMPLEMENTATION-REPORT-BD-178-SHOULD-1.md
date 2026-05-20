# IMPLEMENTATION-REPORT BD-178 SHOULD-1 — Close UNRESOLVED-DRIFT between project-template CLAUDE.md and GEMINI.md (4 sections)

**Branch:** `v11-dev`
**Pre-edit HEAD:** `0484a72df7fd55f3d440cb5a301ec33237b954e0`
**Post-edit HEAD:** `0484a72df7fd55f3d440cb5a301ec33237b954e0` (no commits made — pack-coder is read-only on git state)
**Coder:** pack-coder (Claude Code v11-dev session, 2026-05-20)
**Spawn context:** background-concurrent with BD-177 fix-pass-2 reviewer; file-disjoint scope.

---

## §1 Summary

BD-178 commit `3dbfbdb` aligned 3 known trinity-asymmetric loci + 2 fresh-sweep finds + added POQ-F4-3 Tier 0 note, but the per-commit reviewer (`PACK-REVIEW-BD-178.md`) caught that the IMPL-REPORT §5 invoked the "AGENTS-conciseness style principle" to justify leaving **GEMINI.md** body text asymmetric from **CLAUDE.md** in 4 sections (iOS 26 / Architecture / Security / Scripts). The AGENTS-conciseness contract IS documented at `project-template/AGENTS.md:13-17`, authorizing AGENTS divergence — but **no equivalent contract exists in GEMINI.md**, and archived `maintenance-docs/v11-implementation/ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md §D.4 L432-436` explicitly classifies similar GEMINI body divergences as **UNRESOLVED-DRIFT**, not authorized exception.

User-approved fix Option 1A (2026-05-20): align GEMINI body text to CLAUDE form byte-identically for the 4 affected sections. This commit closes the UNRESOLVED-DRIFT and achieves BD-178's stated "fully-symmetric baseline" goal that was partially missed in commit `3dbfbdb`. AGENTS.md is intentionally untouched — its body conciseness divergence remains authorized per the L13-17 contract.

---

## §2 Files changed

| Path | Change type | Lines | Verification |
|---|---|---|---|
| `project-template/GEMINI.md` | modified | +19 / -18 (37 lines changed) | within-trinity diff EMPTY for 4 sections; validate-pack.py exit 0 |
| `test-fixtures/manifest.txt` | modified | +3 / -3 | v11-* SHA rows drift (expected per RC9); v10-* + existing-* unchanged |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md` | new (this file) | n/a | n/a |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-178.md` | untracked (pre-existing) | n/a (pre-existed session start) | NOT staged by coder per absolute git-state-change ban; Pack Chat stages alongside this commit per task instruction "Stage it; Pack Chat will commit it alongside your edits" |

**Files explicitly NOT modified (out of scope confirmation):**
- `project-template/CLAUDE.md` — canonical source; UNCHANGED (verified `git diff --stat`: no output)
- `project-template/AGENTS.md` — AGENTS-conciseness divergence authorized per L13-17; UNCHANGED (verified `git diff --stat`: no output)
- Pack-root trinity files (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` at repo root) — UNCHANGED
- `scripts/`, `pack-ops/` — UNCHANGED

---

## §3 Per-section alignment evidence

### §3.1 — Section `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features`

**BEFORE (GEMINI.md body, divergent from CLAUDE.md):**
```
- **Liquid Glass** is the current iOS 26 / macOS 26 design language. Use `.glassEffect()` and related modifiers.
- **FoundationModels** is Apple's on-device LLM framework (iOS 26+). Evaluate before third-party ML inference.
- **Availability guards required.** Wrap in `#available(iOS 26, *)` / `#available(macOS 26, *)` if deployment target is below iOS 26.
- **Check Apple frameworks before third-party packages** for any new capability.
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `/Applications/Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/`. If Xcode is installed elsewhere, adjust the path. If the path does not exist, fall back to web search.
```

**AFTER (GEMINI.md body, byte-identical to CLAUDE.md L59-65):**
```
- **Liquid Glass** is the current iOS 26 / macOS 26 design language for materials and visual effects. Use `.glassEffect()` and related modifiers rather than custom `Material` or `UIVisualEffectView` implementations.
- **FoundationModels** is Apple's on-device LLM framework (iOS 26+). Evaluate before reaching for third-party ML inference.
- **Availability guards required.** Liquid Glass and FoundationModels require iOS 26+ / macOS 26+. Wrap in `#available(iOS 26, *)` / `#available(macOS 26, *)` guards if the deployment target is below iOS 26 / macOS 26.
- **Check Apple frameworks before third-party packages** for any new capability.
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.claude/settings.json` env block if Xcode is installed elsewhere). If the path does not exist, fall back to web search.
```

**Substantive deltas restored by adopting CLAUDE form:**
- "for materials and visual effects" + "rather than custom `Material` or `UIVisualEffectView` implementations" (Liquid Glass purpose + scope guard)
- "reaching for" (more precise framing for ML inference choice)
- "Liquid Glass and FoundationModels require iOS 26+ / macOS 26+." (preamble naming what the guards protect) + "macOS 26" added to deployment-target clause for parallel structure
- `$XCODE_APP` env-var indirection (operationally important — clients with Xcode in non-standard locations get an actual mechanism: override `$XCODE_APP` in their CLI settings)

**Note on `.claude/settings.json` reference:** the CLAUDE-canonical wording mentions `.claude/settings.json` as the override location. This is Claude-CLI-specific, but per the user-approved Option 1A and the BD-178 General canonicalization heuristic (prefer the CLAUDE form for stylistic equivalence), adopting byte-identically is the directed action. The cross-tool reference in GEMINI.md is a known artifact of CLAUDE-first canonicalization; raising it as a future-BD candidate would require a separate "tool-neutralize cross-CLI settings references in trinity" sweep, which is out of scope here.

### §3.2 — Section `## Architecture — universal layer discipline`

**BEFORE (GEMINI.md body, 8 bullets, divergent):**
```
- Choose one primary architecture pattern before writing production code. **Document in `ARCHITECTURE.md` before implementation begins.**
- Separate presentation, domain, and data/transport layers. No layer reaches past its immediate neighbor.
- Domain layer has zero framework imports (no UIKit, AppKit, SwiftUI, gRPC, grpcio).
- Generated Protobuf/gRPC types live in the data layer only — never in domain or presentation signatures.
- Cross-layer dependencies are expressed as interface or protocol abstractions. Concrete implementations are injected.
- Shared mutable state documents its owner, lifecycle, and mutation contract. Undocumented shared mutable state is a defect.
- Services are stateless by default. Stateful services document state, threading, and invalidation.
- Navigation logic lives outside view and view-model types.
```

**AFTER (GEMINI.md body, 9 bullets, byte-identical to CLAUDE.md L71-79):**
```
- Choose one primary architecture pattern per app target before writing production code. **Document the choice and rationale in `ARCHITECTURE.md` before implementation begins.**
- Once chosen, apply the pattern consistently within its target. Any seam between two different patterns must be documented and justified.
- Separate presentation, domain, and data/transport layers into distinct types, files, or modules. No layer may reach past its immediate neighbor (presentation → domain → data; never presentation → data directly).
- Domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, gRPC, grpcio, or any persistence or networking framework.
- Generated Protobuf and gRPC types are transport types. They live in the data layer only. They must never appear in domain-layer type signatures or in presentation/view-model types.
- Every cross-layer dependency is expressed as an interface or protocol abstraction. Concrete implementations are injected; they are never instantiated inline by the consuming layer.
- Shared mutable state declares its owner type, owning actor or thread, lifecycle (who creates it, who destroys it), and mutation contract at the definition site. Undocumented shared mutable state is a defect.
- Services are stateless by default. Stateful services explicitly document their state variables, threading guarantees, and invalidation policy.
- Navigation logic lives outside view and view-model types. Use Coordinator, NavigationStack with a typed path, or a Router depending on the chosen pattern.
```

**Substantive deltas restored:**
- "per app target" qualifier on architecture-pattern choice (load-bearing for multi-target Swift projects where iOS / macOS / watchOS targets may legitimately pick different patterns)
- New bullet: "Once chosen, apply the pattern consistently within its target. Any seam between two different patterns must be documented and justified." (the pattern-seam discipline — completely missing from GEMINI's prior form; this is a substantive rule, not a wording polish)
- "into distinct types, files, or modules" + parenthetical "(presentation → domain → data; never presentation → data directly)" (concrete layering examples — much more enforceable than "No layer reaches past its immediate neighbor")
- "CoreData, SwiftData" + "any persistence or networking framework" (broader domain-import blocklist — GEMINI form was incomplete)
- "transport types" framing for Protobuf/gRPC + "must never appear in domain-layer type signatures or in presentation/view-model types" (specific enumeration of where they can't appear)
- "they are never instantiated inline by the consuming layer" (concrete enforcement clause on injection)
- "owner TYPE, owning actor or thread" + "(who creates it, who destroys it)" + "at the definition site" (much tighter shared-state contract)
- "Use Coordinator, NavigationStack with a typed path, or a Router depending on the chosen pattern" (concrete navigation mechanism examples)

### §3.3 — Section `## Security`

**BEFORE (GEMINI.md body, divergent):**
```
- Never hardcode secrets, API keys, tokens, or certificates in source or committed config.
- Validate all data received from the network before use in domain logic or UI.
- TLS required for all gRPC connections. Do not disable certificate validation outside development.
```

**AFTER (GEMINI.md body, byte-identical to CLAUDE.md L95-97):**
```
- Never hardcode secrets, API keys, tokens, or certificates in source code or config files committed to git.
- Validate all data received from the network before using it in domain logic or UI.
- TLS required for all gRPC connections. Do not disable certificate validation outside development.
```

**Substantive deltas restored:**
- "source code or config files committed to git" — the more precise enumeration; "source or committed config" is ambiguous about whether docs/scripts count
- "before using it" — grammatically complete (the GEMINI form's "before use" was a minor compression that lost the verb form)

### §3.4 — Section `## Scripts`

**BEFORE (GEMINI.md, divergent in 3 places):**

Header paragraph:
```
The `scripts/` directory contains build, test, and validation scripts. Make everything
executable on first checkout: `chmod +x agent-run.sh scripts/*.sh`.
```

Table row `bootstrap.sh`:
```
| `bootstrap.sh` | `scripts/` | Once on first checkout or new machine — detects languages and calls bootstrap-\<lang\>.sh | Human |
```

Table row `agent-post-edit-check.sh`:
```
| `agent-post-edit-check.sh` | `scripts/` | **Never call manually** — fires via Codex post_edit_command and Claude Code PostToolUse hook | Automatic hook |
```

**AFTER (GEMINI.md, byte-identical to CLAUDE.md L246-269):**

Header paragraph:
```
The `scripts/` directory contains build, test, and validation scripts. **Copy both from the
pack template and make executable before first use** (`chmod +x agent-run.sh scripts/*.sh`).
```

Table row `bootstrap.sh`:
```
| `bootstrap.sh` | `scripts/` | Once on first checkout or new machine — detects languages and calls the right bootstrap-\<lang\>.sh | Human |
```

Table row `agent-post-edit-check.sh`:
```
| `agent-post-edit-check.sh` | `scripts/` | **Never call manually** — fires automatically via Claude Code PostToolUse hook and Codex post_edit_command after every agent file edit | Automatic hook |
```

**Substantive deltas restored:**
- Header paragraph now explicitly names the "Copy both from the pack template" install action (the GEMINI form said only "make executable" but skipped the COPY action, which is the actual first-time-setup step)
- `bootstrap.sh` row: "calls the right bootstrap-\<lang\>.sh" (the word "right" carries the "wrapper selects per detected language" semantics — GEMINI's "calls bootstrap-\<lang\>.sh" loses that and reads as a literal-string call)
- `agent-post-edit-check.sh` row: re-orders + expands to name CLAUDE FIRST (per trinity ordering convention), adds "automatically" + "after every agent file edit" (operationally important — explicitly states the firing trigger)

**Trinity-rule exception block in GEMINI.md preserved.** The `<!-- Trinity-rule exception: ... -->` comment block + `## Agent roster` H2 section at GEMINI L425-445 are Gemini-specific (Gemini CLI auto-discovers agents via `.gemini/agents/` filesystem scan, presented to the human reader as a roster). This block was untouched — it is the canonical documented trinity exception for GEMINI.md, distinct from the unauthorized body-text drift in the 4 sections this fix targets.

---

## §4 AGENTS-conciseness contract preserved

`project-template/AGENTS.md` was **NOT** touched. Verified with `git diff --stat project-template/AGENTS.md` (no output). The AGENTS-conciseness contract at L13-17 remains intact:

```
This file is the Codex equivalent of CLAUDE.md and GEMINI.md. All three files
should express the same project rules — only tool-specific operating notes differ.
The trinity rule applies: H2 names and order match CLAUDE.md / GEMINI.md;
bodies may be more concise here, since the loaded skills carry the full detail.
```

This contract authorizes AGENTS-side body conciseness. GEMINI.md has **no equivalent contract** in its preamble — per `project-template/GEMINI.md:11-14` the GEMINI preamble only says "Both files should express the same project rules — only tool-specific operating notes differ" with no conciseness clause. That asymmetry is what made the GEMINI body shortening UNRESOLVED-DRIFT (per archived `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md §D.4 L432-436`), and this commit closes it.

---

## §5 Within-trinity parity verification (4 sections, EMPTY diff)

Each command uses `awk` to extract section bodies bounded by the next `## ` heading, then `sed '$d'` to drop that boundary line. Empty output = byte-identical match.

### §5.1 iOS 26

```
$ diff <(awk '/^## \[CONDITIONAL\] iOS 26/,/^## /' project-template/CLAUDE.md | sed '$d') \
       <(awk '/^## \[CONDITIONAL\] iOS 26/,/^## /' project-template/GEMINI.md | sed '$d') \
  && echo "iOS 26 EMPTY DIFF"
iOS 26 EMPTY DIFF
```

### §5.2 Architecture

```
$ diff <(awk '/^## Architecture — universal/,/^## /' project-template/CLAUDE.md | sed '$d') \
       <(awk '/^## Architecture — universal/,/^## /' project-template/GEMINI.md | sed '$d') \
  && echo "Architecture EMPTY DIFF"
Architecture EMPTY DIFF
```

### §5.3 Security

```
$ diff <(awk '/^## Security/,/^## /' project-template/CLAUDE.md | sed '$d') \
       <(awk '/^## Security/,/^## /' project-template/GEMINI.md | sed '$d') \
  && echo "Security EMPTY DIFF"
Security EMPTY DIFF
```

### §5.4 Scripts

```
$ diff <(awk '/^## Scripts/,/^## /' project-template/CLAUDE.md | sed '$d') \
       <(awk '/^## Scripts/,/^## /' project-template/GEMINI.md | sed '$d') \
  && echo "Scripts EMPTY DIFF"
Scripts EMPTY DIFF
```

All 4 sections show EMPTY diff (no residual drift).

**Note on bounded extraction:** the verification command in the task spec used a regex with character class `/^## [^iOS]/` etc. for the end-of-section boundary. I substituted the simpler `/^## /` (any next H2) + `sed '$d'` (drop the captured boundary line) pattern because the character-class form has a subtle bug when the next H2 starts with a character in the class (e.g., the section after `## Security` is `## Liskov Substitution Principle` — `L` is not in `[^S]` so the boundary is correctly detected; but `## [CONDITIONAL] gRPC and Proto3 rules` after `## [CONDITIONAL] Language-specific coding rules` would not bound on `[^L]` since `[` matches). The simpler form is robust to all next-section names. Both patterns produce equivalent output on the current file shape; I used the robust form for verification reliability.

---

## §6 Manifest regen evidence

Per pack memory RC9 ("Regenerate manifest on v11-surface commits"): `project-template/GEMINI.md` is under `project-template/`, which is v11-surface, so manifest regen is mandatory.

```
$ bash test-fixtures/build.sh --all --clean
[... fixture build output ...]
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt
```

```
$ git diff test-fixtures/manifest.txt
diff --git a/test-fixtures/manifest.txt b/test-fixtures/manifest.txt
index 1bced12..f5ab6ab 100644
--- a/test-fixtures/manifest.txt
+++ b/test-fixtures/manifest.txt
@@ -4,7 +4,7 @@
 #
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  61ea55544de61481f0d77045fc443d3e0a15ab60
-v11-flat-file  5bebd44927a416ce8f62af25d367ca175767746e
-v11-tracker-on  2850764b72539a505ac76e353b5dcd3840c472b4
+v11-realistic-ot  01d6611e3756f4e4e79d3b3a4f4da16ea98d2a28
+v11-flat-file  7d197f5a0a5744b3bed7f5fff9bf9c3ba32df528
+v11-tracker-on  c6c8f42c04e5f39c2c53190595ca8eb30ce87bdf
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Drift pattern is correct:
- **v11-* rows (3) drift:** GEMINI.md is captured in all 3 v11 fixtures (v11-realistic-ot, v11-flat-file, v11-tracker-on) — expected per RC9.
- **v10-* rows (2) unchanged:** tag-pinned per `test-fixtures/README.md` § Determinism — only drift if v10 tag moves, which it didn't.
- **existing-project-mid-dev row unchanged:** that fixture is the pre-pack-install input synthetic; no GEMINI.md present, so no drift.

---

## §7 validate-pack.py + persona contract results

### §7.1 validate-pack.py — exit 0, all 39 checks PASS

```
$ python3 scripts/validate-pack.py 2>&1 | tail -10
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

============================================================
PASSED — all checks clean
```

Check 18 (within-trinity parity) implicitly cleaner — the 4-section divergence at `project-template/CLAUDE.md` vs `GEMINI.md` is now zero. (Check 18's exact reporting wasn't surfaced in the tail output because all checks PASS; the cleaner-state observation comes from the §5 diff verification above.)

### §7.2 Persona contracts — all 3 GREEN

```
$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -5
  PASS S6 docs/pack/PACK-FEEDBACK.md present
  PASS S6 docs/pack/prompts/ has 10 prompt files (>=10 expected)
  PASS S8 .gitignore installed

=== greenfield contract: 191 passed, 0 failed ===
```

```
$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -5
  PASS scripts/ created
  PASS docs/pack/ created
  PASS no spurious .pack-template sidecars

=== mid-dev contract: 25 passed, 0 failed ===
```

```
$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -5
  PASS v11 artifact docs/project/changelog/_intro.md installed by migrator
  PASS v11 artifact docs/project/changelog/_format.md installed by migrator
  PASS all .github/ISSUE_TEMPLATE/*.yml installed by migrator

=== migration contract: 37 passed, 0 failed ===
```

Totals: greenfield 191/191, mid-dev 25/25, migration 37/37 = **253 persona contract checks PASS**.

---

## §8 Working-tree scope at PREFLIGHT

```
$ git status --short
 M project-template/GEMINI.md
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-178.md
```

```
$ git diff --stat
 project-template/GEMINI.md | 37 +++++++++++++++++++------------------
 test-fixtures/manifest.txt |  6 +++---
 2 files changed, 22 insertions(+), 21 deletions(-)
```

- **2 modified files** within scope: `project-template/GEMINI.md` (the alignment), `test-fixtures/manifest.txt` (RC9 regen)
- **1 untracked file** pre-existing: `maintenance-docs/v11-implementation/PACK-REVIEW-BD-178.md` (pre-existed session start at 2026-05-20 12:01; Pack Chat stages it alongside this commit per task instruction "Stage it; Pack Chat will commit it alongside your edits" — pack-coder cannot run `git add` per absolute git-state-change ban)

After IMPL-REPORT write: 3 modified/untracked files total (the IMPL-REPORT itself adds a third untracked file under `maintenance-docs/v11-implementation/`).

**HEAD SHA unchanged:** `0484a72df7fd55f3d440cb5a301ec33237b954e0` (verified by `git rev-parse HEAD`; pack-coder never commits per pack memory `feedback_agents_never_commit`).

---

## §9 Plan deviations

**None.** The task instructions specified:
- Align 4 sections of GEMINI.md to CLAUDE.md body text — DONE (§3 + §5 verify EMPTY diff)
- Manifest regen per RC9 — DONE (§6)
- Stage PACK-REVIEW-BD-178.md — pack-coder cannot run `git add` per absolute ban; left as untracked in working tree per the task's "Pack Chat will commit it alongside your edits" instruction.

**No new POQs introduced.** The `.claude/settings.json` cross-tool reference in GEMINI.md (introduced as a side-effect of CLAUDE-first canonicalization in §3.1) is a known artifact noted in-line — raising it as a new POQ would require a "tool-neutralize cross-CLI settings references in trinity" sweep, which is out of scope for this fix and explicitly not directed by the user-approved Option 1A.

**Trinity rule status:** This change touches `project-template/GEMINI.md` only. Per the Trinity rule, modifying one of CLAUDE.md / AGENTS.md / GEMINI.md "applies to all three in the same set of edits" — but the GOAL of this commit is to align an existing trinity asymmetry, so per the rule's "asymmetry requires justification as provably tool-specific" clause, only GEMINI needs modification. CLAUDE.md is the canonical source (already correct); AGENTS.md's divergence is authorized per L13-17 conciseness contract. This is a SYMMETRY-RESTORING edit, not a trinity-content edit; the Trinity rule is satisfied by NOT propagating CLAUDE-form changes into AGENTS.md (which would violate the AGENTS-conciseness contract).

---

## §10 Definition-of-Done checklist

| Criterion | Status | Evidence |
|---|---|---|
| 4 sections in `project-template/GEMINI.md` (iOS 26, Architecture, Security, Scripts) have body text byte-identical to CLAUDE.md equivalents | **PASS** | §5 — all 4 `diff` commands produce EMPTY output |
| Within-trinity parity verification: diffs show EMPTY | **PASS** | §5 (4 EMPTY DIFF echoes) |
| AGENTS.md remains UNCHANGED (AGENTS-conciseness contract preserved) | **PASS** | §4; `git diff --stat project-template/AGENTS.md` no output |
| `python3 scripts/validate-pack.py` exit 0 — 39/39 checks PASS | **PASS** | §7.1 "PASSED — all checks clean" |
| 3 persona contracts STILL GREEN | **PASS** | §7.2 (191+25+37 = 253 PASS, 0 FAIL) |
| `test-fixtures/manifest.txt` regenerated; v11-* rows drift; v10-* + existing-* unchanged | **PASS** | §6 (3 v11-* lines changed, 2 v10-* + 1 existing-* lines unchanged) |
| Working tree at PREFLIGHT: 2 modified files + IMPL-REPORT; PACK-REVIEW-BD-178.md present as untracked | **PASS** | §8 (`git status --short` shows exactly the expected state) |
| No state-changing git verbs run | **PASS** | Only ran `git rev-parse`, `git status`, `git diff`, `git diff --stat`, `git rev-parse HEAD` (all read-only) |
| PREFLIGHT line emitted before IMPL-REPORT write | **PASS** | Emitted immediately before this Write call |

**All 9 success criteria PASS.**

---

## §11 PREFLIGHT line (verbatim)

```
PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD 0484a72; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md
```

Emitted in the parent-session chat immediately before this `Write` tool call.

---

## §12 Files changed inventory

| Path | Type | Pre-edit state | Post-edit state |
|---|---|---|---|
| `project-template/GEMINI.md` | modified | 475 lines | 476 lines (net +1 from adding 1 Architecture bullet + body expansions) |
| `test-fixtures/manifest.txt` | modified | 6 SHA rows | 6 SHA rows (3 v11-* SHAs changed) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md` | new | (did not exist) | this file |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-178.md` | untracked (pre-existing) | already in working tree at session start | unchanged by this session |

Pack Chat next steps (informational; not coder authority):
1. Read this IMPL-REPORT and verify §5 diff EMPTY claims independently
2. Stage 4 files: `project-template/GEMINI.md`, `test-fixtures/manifest.txt`, `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md`, `maintenance-docs/v11-implementation/PACK-REVIEW-BD-178.md`
3. Commit per pack memory commit-message convention (`fix: v11 — BD-178 align GEMINI body text to CLAUDE for 4 sections (Batch ...)` or similar — Pack Chat's call)
4. Flip BD-178 to `Status: Resolved` per implicit-flip-on-clean-batch rule once the per-commit reviewer is also green

---

End of IMPL-REPORT.
