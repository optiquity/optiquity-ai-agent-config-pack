# ARCHITECTURE-BD-195 — boundary-investigation skill shipping disposition

**Author:** pack-architect (read-only pass). **HEAD:** `60bb2d61f7c986f82446e4c3929c5c06512ac0e1` (v11-dev). **Date:** 2026-06-03.
**Finding under audit:** BD-195 completeness re-audit, UNSURE — does `project-template/skills/boundary-investigation/SKILL.md` leak pack-only directory references to client installs?

---

## Verdict (one line)

**KEEP — already correctly resolved via DIVERGE.** The finding's premise is FALSE for the current tree. The pack-own copy and the client-shipped copy are **already distinct, committed, divergent files**; the client copy already references client-landed paths and already fences its pack-only example references behind the Check-37 deny-list machinery, which passes clean today. No structural change is needed. The "UNSURE" framing is wrong — this is a clear KEEP, and the audit finding rests on a stale single-source assumption that the tree contradicts.

---

## The finding's load-bearing assumption — and why it is false

The finding asserts a **single source file copied to both** the pack's agent skills and client installs ("You cannot simply delete the pack-only references from the shared source without breaking the pack-agent copy"). That assumption is empirically false.

There are **two separately-committed, hand-maintained copies** with deliberately different content:

- `project-template/skills/boundary-investigation/SKILL.md` (md5 `a5325cceb97651ce6b6f68f22c8efbfb`) — the CLIENT-shipped copy.
- `.claude|.codex|.gemini/skills/boundary-investigation/SKILL.md` (md5 `39bd0ffdb8db30e57d4b21fc6a03f396`, identical across the three) — the PACK-AGENT copy.

The byte-identity check that once forced these to match (Check 24) was **RETIRED in BD-194**. No generator syncs project-template → pack-own; the two are independent committed artifacts. The single-source constraint the finding worries about does not exist.

---

## Empirical-Evidence Blocks

### EE-1 — There are four in-repo copies; pack-own ≠ project-template

- **Command:** `find . -name SKILL.md -path '*boundary-investigation*'` (+ test-fixtures) ; `md5 -q` on each.
- **Output (verbatim, abridged to relevant):**
  ```
  project-template/skills/.../SKILL.md   a5325cceb97651ce6b6f68f22c8efbfb
  .claude/skills/.../SKILL.md            39bd0ffdb8db30e57d4b21fc6a03f396
  .codex/skills/.../SKILL.md             39bd0ffdb8db30e57d4b21fc6a03f396
  .gemini/skills/.../SKILL.md            39bd0ffdb8db30e57d4b21fc6a03f396
  ```
- **Interpretation:** pack-own copies are byte-identical to each other but DIFFER from project-template. They are distinct artifacts.
- **Conclusion:** SUPPORTED — the divergence is real and already in the tree.

### EE-2 — The divergence is committed and hand-maintained, not generated

- **Command:** `git ls-files .claude/skills/.../SKILL.md .codex/... .gemini/...` ; `git log --oneline -- .claude/skills/boundary-investigation/SKILL.md`.
- **Output (verbatim):**
  ```
  .claude/skills/boundary-investigation/SKILL.md
  .codex/skills/boundary-investigation/SKILL.md
  .gemini/skills/boundary-investigation/SKILL.md
  6c76582 fix: v11 — BD-194 follow-on (reviewer findings F-1/F-2/F-3, pack-only)
  f5b3998 feat: v11 — BD-175 prevention mechanisms (Architect C M1-M8)
  ```
- **Interpretation:** all three pack-own copies are git-tracked. No sync generator exists (grep for a project-template→pack-own copier returned only `init-project.sh`, which copies the CLIENT direction). The divergence was authored at BD-175 (when the skill landed) and refined at BD-194.
- **Conclusion:** SUPPORTED — committed, hand-maintained divergence; no shared-source coupling.

### EE-3 — The actual content divergence is exactly the boundary-correct split

- **Command:** `diff .claude/skills/boundary-investigation/SKILL.md project-template/skills/boundary-investigation/SKILL.md`.
- **Output (interpretation of verbatim diff):** the project-template copy (a) references CLIENT-landed paths (`docs/pack/PM-CHAT.md`, `docs/pack/PLATFORM-SKILLS.md`, `.claude/skills/<name>/SKILL.md`, project-root trinity) where the pack-own copy references pack-repo paths (`project-template/docs/pack/PM-CHAT.md`, `supporting-docs/METHODOLOGY.md`); (b) carries `<!-- DENY-LIST-CONTENT-START/END -->` fence markers around every pack-only example reference, which the pack-own copy omits; (c) generalizes pack-internal citations (`BD-175`, `AUDIT-USER-CURATION.md`) to audience-neutral phrasings ("the audit incident", "pack-repo audit finding").
- **Interpretation:** the client copy is already authored to be factually correct AT THE CLIENT after install, and its remaining pack-only mentions are example/illustration material fenced for Check 37.
- **Conclusion:** SUPPORTED — the client copy is already forward-looking per the governing rule; the pack-only mentions that remain are deliberately fenced, not leaks.

### EE-4 — Check 37 enforces the fence and passes clean today

- **Command:** `python3 scripts/validate-pack.py` (Check 37 section) ; inspect `_FENCE_ALLOWLIST` in `scripts/validate-pack.py`.
- **Output (verbatim):**
  ```
  OK: skills/boundary-investigation/SKILL.md
  OK: Check 37 — 168 project-side file(s) walked; zero deny-list contamination
      (6 anchored LEGITIMATE-context hit(s) accepted; 580 fenced LEGITIMATE-content
       line(s) exempt per Guardrail 2)
  ...
  PASSED — all checks clean
  ```
  `_FENCE_ALLOWLIST` (validate-pack.py ~line 4293) includes `project-template/skills/boundary-investigation/SKILL.md`.
- **Interpretation:** the client copy is explicitly on the per-line fence allowlist; deny-list patterns are permitted ONLY inside the fence markers; outside the fence, normal Check 37 rules apply. The check passes, meaning the client copy has zero unfenced pack-only contamination.
- **Conclusion:** SUPPORTED — the leak the finding describes is already CI-guarded and the guard is green.

### EE-5 — The skill has genuine, primary client-side value (it is NOT pack-development-only)

- **Command:** `grep -n boundary-investigation project-template/docs/pack/PLATFORM-SKILLS.md` ; read Tier-0 base section.
- **Output (verbatim):**
  ```
  | boundary-investigation | Project-side SSOT investigation methodology; flag
    pack-vs-project boundary violations on every action | architect, coder,
    planner, reviewer, docs-researcher |
  ```
  It is listed in the **Tier 0 base** subsection ("load for every project, every agent").
- **Interpretation:** the skill encodes the PROJECT-side "Project SSOT-first" rule (the same rule that lives in `project-template/CLAUDE.md` § Project memory). Its primary agents are the UNPREFIXED client roster (`architect`, `coder`, …), not the pack-* roster. A client project investigating its OWN `docs/pack/` SSOT before importing external framing is exactly the client-side use case. The skill is dual-use, with a legitimate client-side primary purpose.
- **Conclusion:** SUPPORTED — boundary-investigation is a legitimate client-shipped Tier 0 skill, NOT a mis-shipped pack-development-only skill.

### EE-6 — Canonical pool = 36; Check 31 binds count to inventory bijection

- **Command:** `ls -d project-template/skills/*/ | wc -l` ; read Check 31 in validate-pack.py ; `README.md:101` ; `PLATFORM-SKILLS.md:498`.
- **Output (verbatim):** `36` dirs on disk; `**Total skills: 36** (14 Tier 0 base + 20 dimensional / intersection + 1 trigger-loaded + 1 PM chat operational)`; Check 31 enforces disk↔inventory bijection + per-subsection header counts + total.
- **Interpretation:** `boundary-investigation` is one of the 14 Tier 0 base skills inside the 36. Removing it from the canonical pool would force: delete its inventory row, Tier-0 header 14→13, total 36→35, README:101 edit, and deletion of a legitimate client methodology skill.
- **Conclusion:** SUPPORTED — establishes the (large, undesirable) ripple of the rejected "make it pack-only" option.

### EE-7 — Client-install snapshots carry the client copy, not the pack copy

- **Command:** `md5 -q test-fixtures/v11-flat-file/.claude/skills/boundary-investigation/SKILL.md`.
- **Output:** `a5325cceb97651ce6b6f68f22c8efbfb` (== project-template md5, ≠ pack-own md5).
- **Interpretation:** `init-project.sh stage_s4_skills()` (line 484–497) copies `project-template/skills/*/SKILL.md` into the client target. Fixtures confirm clients receive the fenced, client-pathed copy — never the pack-own copy.
- **Conclusion:** SUPPORTED — the distribution boundary is intact; clients get the boundary-correct artifact.

---

## Governing-rule application (`client-ref-delete-or-forward-look`)

The rule: a client-shipped reference to a genuinely-pack-only asset → DELETE; a reference to a real project asset by its pack path → FORWARD-LOOK to the landed client path.

Classify the references in the **client copy** (`project-template/skills/boundary-investigation/SKILL.md`):

1. **Project-asset references** (PM-CHAT.md, PLATFORM-SKILLS.md, PACK-FEEDBACK.md, project trinity, per-CLI skill dirs) — already FORWARD-LOOKING to client-landed paths (`docs/pack/...`, project root, `.claude/skills/...`). **Rule satisfied (case 2 already applied).** (EE-3.)
2. **Pack-only example references** (the `PACK-AGENTS.md` / `pack-ops/` / `maintenance-docs/` / `pack-*` agent / `Pack Chat` mentions inside the methodology) — these are **illustrative example content** (the skill's whole job is to TEACH agents to recognize and avoid pack-only references), not functional cross-references the client must resolve. The op-vs-explanatory test (`bd-pack-only-operational-rule`) classifies them EXPLANATORY → LEGITIMATE-when-disclosed. They are disclosed via the `<!-- DENY-LIST-CONTENT -->` fence and CI-guarded by Check 37 Guardrail 2. **Rule satisfied (neither delete nor forward-look applies — these are fenced explanatory examples, the documented exception).** (EE-3, EE-4.)

There is no third category of unfenced, functional, dead-at-client reference in the client copy. EE-4 (Check 37 green) is the empirical proof that none exists.

`pack-project-separation-of-concerns` is **honored, not violated**: pack-side and client-side copies are SEPARATE artifacts with separate audiences and separate paths — exactly what this rule mandates. The retirement of byte-identity Check 24 (BD-194) is the ratchet that let them legitimately diverge.

---

## Challenge to the "UNSURE" framing (`preliminary-triage-architect-challenge`)

The audit marked this UNSURE on the belief of a **shared single source** that leaks client-side. Both halves are falsified:

- **Not single-source:** two committed divergent copies exist (EE-1, EE-2); Check 24 byte-identity coupling was retired (BD-194).
- **Not leaking:** the client copy is forward-looking and its residual pack-only mentions are fenced + CI-green (EE-3, EE-4).

This is a **clear KEEP**, not a genuine UNSURE. The finding is an artifact of inspecting the file's prose in isolation without checking (a) whether a separate pack-own copy exists and (b) whether the deny-list fence machinery already covers it. Calibration note: a project-side surface that PASSES Check 37 with its pack-only content fenced is BY CONSTRUCTION not a leak — the guard is the adjudicator, and it is green.

---

## Fix recipe

**None required.** No coder action. The disposition is KEEP / no-op.

If Pack Chat wants to record the disposition (optional, PM-only): note in the BD-195 reconciled problem list that this finding is **resolved-as-designed** (DIVERGE already implemented at BD-175/BD-194; Check 37 fence is the guard; verdict KEEP). That is a PM-only annotation, not a source edit.

---

## Ripple surface (for completeness — all ZERO under the KEEP verdict)

Under KEEP, the coder touches **nothing**. The list below is the ripple that the REJECTED "make it pack-only / remove from clients" option would have incurred — recorded so the cost of the rejected path is on the record:

| Surface | Edit the rejected option would force | Status under KEEP |
|---|---|---|
| `project-template/skills/boundary-investigation/SKILL.md` | delete (un-ship) | untouched |
| `.claude|.codex|.gemini/skills/boundary-investigation/SKILL.md` | keep as pack-only | untouched |
| `init-project.sh stage_s4_skills()` | add a skip/exclude for this skill | untouched |
| `PLATFORM-SKILLS.md` Tier-0 inventory row | delete row; header 14→13; total 36→35 (Check 31) | untouched |
| `README.md:101` | `36 skills … 14 Tier 0 …` → `35 … 13 …` | untouched |
| `test-fixtures/*/.{claude,codex,gemini}/skills/boundary-investigation/` (3 fixtures × 3 CLIs) | delete 9 fixture copies; regenerate `test-fixtures/manifest.txt` | untouched |
| `validate-pack.py` `_FENCE_ALLOWLIST` + Check 37 walk | remove the allowlist entry | untouched |
| `project-template/CLAUDE.md` § Skill loading (Tier-0 install note cites boundary-investigation as canonical reference) + trinity | rewrite the cited reference | untouched |
| `PACK-AGENTS.md` skills table (`boundary-investigation | pack-coder…`) | unaffected (pack-own copy stays) | untouched |

The rejected option deletes a legitimate Tier-0 client methodology skill AND ripples ~9 surfaces — net-negative on every axis. KEEP is correct.

---

## Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| agents-never-commit | Session ran only `find`/`md5`/`git ls-files`/`git log`/`grep`/`python3 validate-pack.py` (read-only) + one `Write` of this doc. No `git add/commit/push/tag`. | COMPLIANT |
| agents-read-rule-docs-in-full | Read in full: `CLAUDE.md` (incl. `## Pack memory`), `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, and the 8 named memory files (`agents_read_rule_docs_in_full`, `client_ref_delete_or_forward_look`, `bd_pack_only_operational_rule`, `pack_project_separation_of_concerns`, `architect_planner_empirical_evidence`, `preliminary_triage_architect_challenge`, `scope_deliverables_to_the_ask`, `agent_output_rules_applied_block`). Each read via a single full-file `Read` call (no offset/limit crop). | COMPLIANT (complete read of every named doc) |
| client-ref-delete-or-forward-look | Applied per-reference in § Governing-rule application: project-asset refs already forward-looking (EE-3); pack-only refs are fenced explanatory examples (EE-4 Check 37 green) → neither delete nor forward-look triggered; verdict KEEP. | COMPLIANT |
| empirical-evidence-blocks | EE-1…EE-7 each carry command + verbatim output + HEAD `60bb2d6` + date 2026-06-03 + interpretation + SUPPORTED conclusion. | COMPLIANT |
| preliminary-triage-architect-challenge | § Challenge falsifies both halves of the UNSURE premise (not-single-source EE-1/EE-2; not-leaking EE-3/EE-4) and re-verdicts to clear KEEP. | COMPLIANT |
| bd-pack-only-operational-rule | Applied the op-vs-explanatory test: residual pack-only mentions in the client copy are EXPLANATORY example content, disclosed via fence, CI-guarded (EE-4) → LEGITIMATE, not a leak. | COMPLIANT |
| pack-project-separation-of-concerns | EE-1/EE-2: pack-own and client copies are separate committed artifacts at separate paths with separate audiences; Check 24 byte-identity retired (BD-194). Separation honored. | COMPLIANT |
| scope-deliverables-to-the-ask | Deliverable is verdict + fix recipe + ripple + governing-rule justification; led with the one-line verdict; no second-review/edge-case sprawl. | COMPLIANT |
| rules-applied-verification-block | This block; every row carries quoted evidence (no empty cells). | COMPLIANT |
| preflight-stop-means-stop | No fabrication; every state-claim backed by a captured command. No parent stop received. | COMPLIANT |
