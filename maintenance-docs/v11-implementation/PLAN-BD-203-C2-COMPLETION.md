# PLAN-BD-203-C2-COMPLETION — close the Commit-2 gaps to a clean PREFLIGHT (then Pack Chat `git rm` + commit)

**Agent:** pack-planner · **Date:** 2026-06-05 · **Branch:** v11-dev · **HEAD (measured):** `4c370da`
**Mode:** PLANNING ONLY — no source edits, no git verb. This plan COMPLETES the atomic Commit-2 edits
of `PLAN-BD-203.md` (which it cross-references, does not duplicate). It does NOT restart the conversion:
the coder's landed work (trees built; **211/211 backlog + 11/11 changelog byte-faithful**, oracle GREEN;
C1–C6; B8/B9; D4 A13-INVERSE; the FLAG-b `vN.M`→`vN` resolution + cross-stream `TD-` tolerance) is correct
and load-bearing and is PRESERVED. This plan adds exactly the five user-decided dispositions (D1–D5) needed
to make the next coder reach a clean PREFLIGHT, after which Pack Chat does the `git rm` + final
validate-pack + commit.

**Single-BD batch; one completion commit (the atomic Commit 2).** Every edit is `pack-only` (CI Check 36).
Agents never commit; only Pack Chat stages/commits with explicit per-commit user approval, and only Pack
Chat runs the destructive `git rm` (`agents-never-commit`, `per-action-approval-sub-agents`).

---

## 0. GOAL + SCOPE (lead)

**Goal.** Take the working tree from the coder's STOP-and-report state (`IMPL-BD-203-Commit2.md`) to a state
where a fresh completion coder reaches a clean PREFLIGHT — validate-pack GREEN on EVERY check EXCEPT the
expected-RED Check 32′ (and the benign Check-36 HEAD transient, §6) — by closing the two non-transient gap
classes (POQ-1 Check-34, POQ-2 Check-40) the coder surfaced, finishing C7, and re-auditing every validator.

**In scope (the five user-decided dispositions + the re-audit):**
- **D1** — Check 34 tolerate genuine `vN.M` forward-refs by RULE (major > highest-defined major). [validator + test]
- **D2** — one-token content fix of the stray `BD-19b` in `backlog/BD-173.md` (the SOLE byte-faithfulness departure).
- **D3** — repoint the 4 missed Check-40 files' bare monolith refs to the tree (+ a grep-zero completeness gate).
- **D4** — finish the C7 sweep across all remaining pack-copied skill/agent/command files ×3 CLIs (+ G-4 recommendation).
- **D5** — full validator-impact re-audit (every check in `scripts/validate-pack.py`), measured.

**Out of scope (unchanged from `PLAN-BD-203.md`):** project-side surfaces (BD-206); tracker-lib runtime
repoints (BD-204); the BD-203 status flip lands in `/backlog/BD-203.md` (G-7, §7). No new BD scope is invented
(`fail-loud` §54 "do not invent scope").

---

## 1. EMPIRICAL-EVIDENCE BLOCKS (every state-claim, measured at HEAD `4c370da`, 2026-06-05)

cwd `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`.

### EE-1 — working-tree state: trees present (untracked), monoliths present, counts match
```
$ git rev-parse HEAD                               → 4c370dac0963dfbea9f358535811a7c86aa2cfb9
$ ls -d backlog changelog                          → backlog  changelog   (present, untracked: `?? backlog/` `?? changelog/`)
$ ls -l pack-ops/BACKLOG.md pack-ops/CHANGELOG.md  → both present (592252 / 46177 bytes)
$ ls backlog | grep -cE '^BD-[0-9]+[a-z]*\.md$'    → 211
$ grep -cE '^\*\*BD-' pack-ops/BACKLOG.md          → 211      (count oracle MATCH)
$ ls changelog | grep -cE '^v[0-9]+\.md$'          → 11
$ grep -cE '^## v' pack-ops/CHANGELOG.md           → 11       (count oracle MATCH)
```
Conclusion: **SUPPORTED** — the conversion EDITS landed; trees byte-faithful (211/11); monoliths await the
Pack-Chat `git rm`. The completion builds on this tree; it does not rebuild it.

### EE-2 — the COMPLETE Check-34 dangling set on the live tree is EXACTLY 3 (current working tree)
```
$ python3 scripts/validate-pack.py 2>&1 | grep -E 'references (BD-|v[0-9]|TD-|phase-)'
FAIL: backlog/BD-069.md:13 references v12.0 — no matching entry file ...
FAIL: backlog/BD-114.md:48 references v12.0 — no matching entry file ...
FAIL: backlog/BD-173.md:35 references BD-19b — no matching entry file ...
```
Conclusion: **SUPPORTED** — exactly 3 dangling Check-34 refs: `v12.0`×2 (POQ-1/D1) + `BD-19b`×1 (POQ-1/D2).
No other dangling BD/TD/phase/version ref exists. (Re-confirmed identical in the post-`git rm` simulation, EE-3.)

### EE-3 — post-`git rm` SIMULATION (non-destructive `mv` aside + restore byte-identical): the FULL residual FAIL set
```
$ mv pack-ops/BACKLOG.md /tmp/…; mv pack-ops/CHANGELOG.md /tmp/…    (aside)
$ python3 scripts/validate-pack.py 2>&1 | grep '^FAIL:'            ; echo EXIT=$?  → EXIT=1
  FAIL: backlog/BD-069.md:13 references v12.0                                  (Check 34 — D1)
  FAIL: backlog/BD-114.md:48 references v12.0                                  (Check 34 — D1)
  FAIL: backlog/BD-173.md:35 references BD-19b                                 (Check 34 — D2)
  FAIL: Commit 4c370da subject claims `pack-chat-only` but touches … BACKLOG.md (Check 36 — HEAD transient, §6)
  FAIL: pack-ops/BOUNDARY-DEFINITION.md:43 — bare `BACKLOG.md` … broken ref     (Check 40 — D3)
  FAIL: pack-ops/BOUNDARY-DEFINITION.md:43 — bare `CHANGELOG.md` … broken ref   (Check 40 — D3)
  FAIL: pack-ops/DRY-RUN-MIGRATION.md:199 — bare `BACKLOG.md` … broken ref      (Check 40 — D3)
  FAIL: pack-ops/OPTIONAL-FEATURES.md:133 — bare `BACKLOG.md` … broken ref      (Check 40 — D3)
  FAIL: pack-ops/OPTIONAL-FEATURES.md:203 — bare `BACKLOG.md` … broken ref      (Check 40 — D3)
  FAIL: pack-ops/PACK-MEMORY-RATIONALE.md:361 — bare `BACKLOG.md` … broken ref  (Check 40 — D3)
$ mv …/BACKLOG.md.bak pack-ops/BACKLOG.md; mv …/CHANGELOG.md.bak pack-ops/CHANGELOG.md   (restored; ls confirms present)
```
Also observed PASS in the sim (the conversion's correctness, confirming zero-regression):
`Check 32′ → PASS both streams (no monolith; _rules.md + _toc.md present; filenames conform)`;
`Check 33 → PASS (both _toc.md byte-identical)`; `Check 3 → /backlog/ scanned`; `Check 40 → walked 10 pack-ops/*.md`.
Conclusion: **SUPPORTED** — the residual post-delete FAILs are EXACTLY {3× Check 34 (D1+D2), 6× Check 40 across 4
files (D3), 1× Check 36 HEAD transient (benign, §6)}. Closing D1+D2+D3 clears every non-transient FAIL; the
`git rm` clears Check 32′; the Check-36 transient clears when Commit 2 (subject `pack-only`) becomes HEAD.

### EE-4 — D1 boundary is precise: a "major > highest-defined" rule tolerates EXACTLY `v12.0`
```
$ defined majors (ls changelog | v\d+\.md) = [1..11]   highest = 11    (contiguous; no gap)
$ (python harness over every vN.M token in backlog/+changelog/):
   D1 TOLERATE (forward-ref, major>highest): ['v12.0']
   D1 STILL FAIL (major<=highest but undefined = typo class): []
```
Interpretation: today the only `vN.M` whose major exceeds the highest defined release is `v12.0`. The rule
tolerates exactly the genuine forward-ref and nothing else; because defined majors are contiguous 1–11, there
is no in-range gap-typo token today, but the rule STILL FAILs any future `vN.M` with `vN ≤ 11` that is
undefined (a typo to an existing/in-range major resolves via the landed FLAG-b `vN.M`→`vN`; a true gap would
fail). Conclusion: **SUPPORTED** — D1 sized to the forward-ref set (measure-then-bound), never wider.

### EE-5 — bare `vN` (no minor) is NOT a CROSS_REF_RE token → D1's "tolerate bare vN" clause is already satisfied
```
$ python3 -c "import re; r=re.compile(r'\b(BD-\d+[a-z]*|TD-\d+[a-z]*|phase-\d+(?:\.\d+)?|v\d+\.\d+(?:-[a-z0-9-]+)?)\b'); print(r.findall('see v12 and v12.0'))"
   → ['v12.0']      (bare 'v12' produces NO token; only 'v12.0' matches)
```
Conclusion: **SUPPORTED** — only `vN.M` forms reach Check 34; a bare `vN` forward-ref is invisible to the
check and needs no tolerance. D1's implementation is confined to the `_VERSION_POINT_RE` / `_resolves_to_defined_id`
path. No regex widening is required (do NOT widen CROSS_REF_RE to admit bare `vN` — that would scope-creep).

### EE-6 — the D2 token: `BD-19b` is a stray error inside "Batch 19b" prose (no BD-19b entry exists)
```
$ sed -n '34,35p' backlog/BD-173.md
  - Per-CLI memory-cache (only Claude has it; project-side may have
    none per Batch 19b BD-19b research; architect determines)
```
Interpretation: the `b` belongs to "Batch 19b"; `BD-19b` is a redundant duplicate token with no entry. Per
`no-bd-letter-suffix` (§35-37: "fixed by a one-token prose correction … `BD-19b` dropped → `per Batch 19b
research` … Not allowlisted") this is a content correction, not an allowlist. Conclusion: **SUPPORTED**.

### EE-7 — D3 Check-40 mechanism: the exclusion skips the monolith AS A WALKED FILE, not as a REFERENCE
```
$ validate-pack.py:5148-5150   for md_path in sorted(pack_ops_dir.glob("*.md")):  if md_path.name in excluded_basenames: continue
$ excluded_basenames = {"BACKLOG.md","CHANGELOG.md"}   (:5139)
```
Interpretation: `excluded_basenames` exempts the monolith FILES from being walked; it does NOT exempt a bare
`` `BACKLOG.md` `` REFERENCE that appears INSIDE another `pack-ops/*.md` file. Pre-delete those bare refs
resolve to a same-dir candidate (the monolith in `pack-ops/`) → accepted; post-delete the candidate vanishes
→ "broken ref" FAIL (EE-3). This is exactly why deletion surfaces them, and confirms the plan's A11 "moot
post-deletion" claim was wrong for refs in OTHER files. Conclusion: **SUPPORTED**.

### EE-8 — the 4 D3 files' exact bare-ref lines (the repoint targets)
```
$ pack-ops/BOUNDARY-DEFINITION.md:43   | C2 | PACK × OPERATIONS | … `BACKLOG.md`, `CHANGELOG.md`, `maintenance-docs/**`, … |
$ pack-ops/DRY-RUN-MIGRATION.md:199    - `BACKLOG.md` — BD-114 (harness implementation), BD-125 (this doc).
$ pack-ops/OPTIONAL-FEATURES.md:133    **What it is** — moves issue tracking out of `BACKLOG.md` flat-file
$ pack-ops/OPTIONAL-FEATURES.md:203    state, writes a sidecar `BACKLOG.md` from current issues, and flips
$ pack-ops/PACK-MEMORY-RATIONALE.md:361 operationally (pack-ops uses BDs in `BACKLOG.md` and batch labels in
```
Conclusion: **SUPPORTED** — 5 reference-lines (6 ref-tokens: BOUNDARY-DEFINITION carries both BACKLOG.md +
CHANGELOG.md) across 4 files; their semantics differ (§D3 classifies each).

### EE-9 — C7 exhaustive enumeration: 21 pack-copied files reference the monoliths/mirror-model; 1 already done
```
$ grep -rlnE 'BACKLOG\.md|CHANGELOG\.md|regenerated mirror|per-entry source|monolithic mirror' .claude .codex .gemini
   → 21 files (full list in §D4 table)
$ git status --short | grep '.claude/skills/pack-startup/SKILL.md'  → ' M' (already corrected to no-mirror model — the coder's 1-of-21)
```
Conclusion: **SUPPORTED** — 21 files total; `.claude/skills/pack-startup/SKILL.md` is the landed 1; **20
remain**. NONE of these is in Check-40 scope (Check 40 walks `pack-ops/*.md` only) and their refs carry the
`pack-ops/` qualifier (not bare) → C7 is a DOC-MODEL/READ-INSTRUCTION correctness gap, **not a CI-blocking
gap** (it does not contribute to the EE-3 residual FAIL set). Verified: `.claude/agents/pack-architect.md`
ref = `pack-ops/BACKLOG.md` (qualified, not bare).

### EE-10 — validator-check inventory + every monolith/tree touch-point (D5 measure)
```
$ grep -cE 'print\("\\n── Check ' scripts/validate-pack.py   → 39 checks
$ grep -nE 'BACKLOG\.md|CHANGELOG\.md|"backlog"|"changelog"|/backlog/|/changelog/|STREAMS' validate-pack.py
   STREAMS (:304-305) pack-backlog→backlog tree + pack-ops/BACKLOG.md mirror-rel; pack-changelog→changelog + CHANGELOG.md
   Check 3   (:476-498)  scans /backlog/ tree (A10 repoint — DONE)
   Check 32′ (:3201)     walks STREAMS; asserts monolith ABSENT + tree present (A9 — DONE)
   Check 33  (:3278)     walks STREAMS tree _toc.md (KEEP)
   Check 34  (:3546-3629) walks STREAMS tree; CROSS_REF / _resolves_to_defined_id (D1 target)
   Check 40  (:5139,5148) excludes monolith basenames from walk (A11/D3 region)
   Check 43  (:5283-5284,5368,5476) BACKLOG.md/CHANGELOG.md = PROJECT-SIDE mirror skips (BD-206 — NOT pack-affected)
   Check 48  (:7177)     scans _REMOVED_DOC_SCAN_DIRS = /backlog/+/changelog/ trees (A12 repoint — DONE)
   _PACK_CHAT_ONLY_PERMITTED_PATHS (:3800) monoliths re-removed (D4 A13-INVERSE — DONE)
```
Conclusion: **SUPPORTED** — the conversion-sensitive checks are exactly {3, 32′, 33, 34, 36, 40, 48} + the
permitted-paths set; Check 43's monolith basenames are PROJECT-SIDE (unaffected). Full per-check verdict in §D5.

---

## 2. CROSS-REFERENCE TO PLAN-BD-203.md (do not duplicate)

This plan inherits unchanged from `PLAN-BD-203.md`: the atomic 2-commit structure (§4/§5), the
coder-builds / Pack-Chat-deletes verification split (§6), the §7 oracle suite, the manifest discipline,
and the actor model (pack-coder does ALL edits scoped-in; Pack Chat does the `git rm` + commits). The
present plan REVISES only: (a) `PLAN-BD-203.md` A11 ("Check-40 exclusion moot post-deletion") — WRONG for
refs in OTHER files (D3); (b) `PLAN-BD-203.md` §7 oracle item-7 "Check 34 active+passing" — under-measured
the forward-ref + stray-token classes (D1/D2); (c) the C7 enumeration — completed here exhaustively (D4).

---

## 3. THE FIVE DISPOSITIONS — exact mechanism, files, edits, encoding surfaces, gates

### D1 — Check 34 tolerates genuine `vN.M` forward-refs BY RULE (major > highest-defined major)

**Mechanism (measure-then-bound).** Extend `_resolves_to_defined_id` (`validate-pack.py:3436`) with ONE
additional resolution path: a `vN.M` point-release whose MAJOR `vN` is GREATER than the highest defined
changelog major resolves as a genuine forward-reference. This is sized EXACTLY to the forward-ref set
(EE-4: tolerates only `v12.0` today) and STILL FAILs a `vN.M` whose `vN ≤ highest` but undefined (the
typo/gap class) and any non-version dangling token (`BD-19b` still fails → D2 fixes it, not D1).

**Why this is fix-not-suppress (`fail-loud`).** A reference to a version that does not exist YET is not a
dangling entry-ref — it is a legitimate forward-looking statement ("required before tagging v12.0"). The
rule admits the forward-ref CATEGORY, never a specific token list, and never widens to swallow a typo to an
existing version. (Contrast D2: `BD-19b` is an ERROR, fixed in content, not tolerated.)

**Exact code change** — `scripts/validate-pack.py`:
- Add a helper computing the highest defined changelog major from `defined_all` (the loaded pack-changelog
  IDs are `vN`; parse the integer N from each `^v\d+$` member; `max(...)`, or `None`/`-inf` if none loaded).
  Compute it ONCE in `check_cross_reference_integrity` after `defined_all` is built (`:3562-3564`) and pass
  it into `_resolves_to_defined_id` (extend the signature, or close over it).
- In `_resolves_to_defined_id`, AFTER the existing `_VERSION_POINT_RE` "major is defined" branch (`:3459-3461`)
  and BEFORE the cross-stream `TD-` branch, add: if `m` matched (it is a `vN.M`) AND `int(m.group(1))` >
  `highest_defined_major` (when a highest exists) → `return True` (genuine forward-ref). Comment it as the
  measure-then-bound forward-ref tolerance, sized to `major > highest-defined`, NOT a token allowlist.
- Do NOT touch `CROSS_REF_RE` (EE-5: bare `vN` is not a token; only `vN.M` reaches here). Do NOT add a
  `_CHECK_40_ALLOWLIST`-style literal list. The docstring of `_resolves_to_defined_id` gains the new bullet.

**Encoding surfaces (lock-step — `enumerate-encoding-surfaces`):**
| Surface | Edit |
|---|---|
| `scripts/validate-pack.py` `_resolves_to_defined_id` + docstring | the forward-ref branch above |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` Group C (Check 34; cases at `:506-600`) and/or Group F (pack-changelog, `:627-715`) | ADD: (a) a GREEN case — a `vN.M` whose major > highest defined (e.g. `v12.0` in an entry body) RESOLVES (no FAIL); (b) a RED case — a `vN.M` whose major ≤ highest but undefined (a true gap, e.g. construct a fixture defining majors {v9,v11} and reference `v10.0`) STILL FAILs; (c) keep an existing in-range `vN.M`→`vN` GREEN case (FLAG-b regression guard). Mirror the Group-C fixture-builder pattern; do not hand-edit live tree fixtures. |
| `scripts/tests/test-v11-realistic-ot.sh` C.1 + C.9 (`:332`,`:356`) | NO new assertion needed — these already assert "validate-pack exits 0" + "Check 34 PASS"; they flip GREEN automatically once D1 (+D2) clear the live `v12.0`/`BD-19b` FAILs and the monolith is deleted. They ARE the integration encoding surface per `verify-full-ci-suite` — the completion coder MUST RUN this integration test, not only validate-pack. |
| CI workflow `validate-pack.yml:159` | runs `test-validate-pack-checks-32-33-34.sh` — unchanged (already wired). |

**Completeness gate (D1):** after the edit, the post-delete-sim Check 34 over the live tree returns ZERO
`v12.0` FAILs (the 2 EE-3 `v12.0` lines clear). Run in coder PREFLIGHT + reviewer.

### D2 — one-token content fix of the stray `BD-19b` in `backlog/BD-173.md` (the SOLE byte-faithfulness departure)

**Mechanism (fix-not-suppress; `no-bd-letter-suffix`).** Drop the redundant `BD-19b` token so the prose
reads "per Batch 19b research". This is a deliberate, user-approved CONTENT correction of an error — NOT an
allowlist (do not teach Check 34 to ignore a bad token).

**Exact edit** — `backlog/BD-173.md` (the tree copy; the monolith is being deleted, so the fix lands ONLY in
the tree SSOT — there is no parallel monolith edit):
```
old_string:   none per Batch 19b BD-19b research; architect determines)
new_string:   none per Batch 19b research; architect determines)
```
(Line 35; the surrounding lines 34-36 are EE-6.)

**Byte-faithfulness call-out (REQUIRED).** This is the ONE sanctioned departure from the content-faithfulness
oracle (every other entry body stays byte-faithful to the pre-conversion monolith). The completion coder MUST
record it explicitly in (a) its deviation log and (b) its IMPL-REPORT, naming it as the single user-approved
content edit. The §7 content-faithfulness oracle is re-run with `backlog/BD-173.md` EXEMPTED from the
byte-identity diff (its one-token delta is expected); all other entries remain byte-identical.

**Encoding surfaces:** none beyond the file itself — `BD-173.md` is entry content, not a validator/test
surface. Manifest: `backlog/` is not a v11-surface dir, but the commit also edits `scripts/`+`pack-ops/`
(D1/D3) → manifest regen is already triggered (§5).

**Completeness gate (D2):** post-delete-sim Check 34 returns ZERO `BD-19b` FAIL; `grep -rn 'BD-19b'
backlog/ changelog/` returns ZERO. Run in coder PREFLIGHT + reviewer.

### D3 — repoint the 4 missed Check-40 files' bare monolith refs to the tree (+ grep-zero completeness gate)

**Mechanism (fix-not-suppress; `fail-loud` + `client-ref-delete-or-forward-look`).** Each bare
`` `BACKLOG.md` `` / `` `CHANGELOG.md` `` reference to a deleted monolith is repointed to the per-entry tree
(`/backlog/`, `/changelog/`) using a qualified path — matching the C3–C6 repoint pattern already landed.
Repoint (not `_CHECK_40_ALLOWLIST`) is the disposition: these are real references to a real (relocated) asset,
so they FORWARD-LOOK to the landed tree, not get suppressed. **Per-ref semantics differ (classify each):**

| File:line | Bare ref(s) | Nature (EE-8) | Repoint |
|---|---|---|---|
| `pack-ops/BOUNDARY-DEFINITION.md:43` | `BACKLOG.md`, `CHANGELOG.md` | C2 category list of pack-only ops files | replace the two bare tokens with the tree dirs `/backlog/` + `/changelog/` (the pack-only SSOT for pack BD/changelog entries). Confirm grammar of the list cell. |
| `pack-ops/DRY-RUN-MIGRATION.md:199` | `BACKLOG.md` | harness-doc prose ("`BACKLOG.md` — BD-114 …") | repoint to `/backlog/` (the entries it lists live in the tree). If the surrounding prose is purely HISTORICAL (describing a past harness run), the coder MAY instead qualify to `pack-ops/BACKLOG.md` ONLY IF the sentence is explicitly past-tense history per `fail-loud` principle-2 — but DEFAULT is repoint to `/backlog/`; surface any history judgment in the IMPL-REPORT, do not silently allowlist. |
| `pack-ops/OPTIONAL-FEATURES.md:133` | `BACKLOG.md` | tracker-behavior prose ("moves issue tracking out of `BACKLOG.md` flat-file") | this describes the PROJECT/client tracker model (sidecar). The correct repoint is the audience-correct value: this prose is about the per-entry FLAT-FILE model, so repoint to `/backlog/` (the flat-file SSOT). If the sentence is specifically about the CLIENT sidecar, the audience-correct ref is `docs/project/backlog/` — coder applies `cross-cli-reference-normalization` judgment and surfaces the pick. |
| `pack-ops/OPTIONAL-FEATURES.md:203` | `BACKLOG.md` | tracker-behavior prose ("writes a sidecar `BACKLOG.md` from current issues") | this is CLIENT tracker-reverse behavior (writes a project-side sidecar) → the audience-correct ref is the client tree `docs/project/backlog/` (NOT the pack `/backlog/`). Surface this client-vs-pack distinction in the IMPL-REPORT. |
| `pack-ops/PACK-MEMORY-RATIONALE.md:361` | `BACKLOG.md` | prose example ("pack-ops uses BDs in `BACKLOG.md`") | repoint to `/backlog/` (the pack-ops BD SSOT). **Propagation flag:** `PACK-MEMORY-RATIONALE.md` is a pack-chat-only / rule↔rationale-bijection surface (BD-198, CI Check 45). This edit is PROSE in an example sentence, NOT a `## <slug>` rationale entry, so it does NOT alter the bijection — but the coder MUST verify Check 45 stays GREEN after the edit (no slug added/removed) and note it. |

**Boundary discipline (D3).** `OPTIONAL-FEATURES.md:203` (and possibly `:133`) describe CLIENT tracker
behavior; their audience-correct repoint is the project-side tree path `docs/project/backlog/` (a STRING in a
pack-ops doc describing client behavior — NOT a project-side FILE edit, so still `pack-only`). The coder must
NOT repoint client-behavior prose to the pack `/backlog/` (that would misdescribe client behavior). This is a
`cross-cli-reference-normalization` / audience-correctness call — surface each pick in the IMPL-REPORT.

**Completeness gate (D3 — the CONTRACT, per `rename-plans-measure-then-bound`).** The 4-file list above is a
CONVENIENCE for the coder, NOT the completeness contract. The CONTRACT is the post-`git rm` simulation gate:
```
GATE-D3:  (monoliths mv aside) python3 scripts/validate-pack.py 2>&1 | grep -c 'Check 40.*broken ref\|bare cross-reference `BACKLOG.md`\|bare cross-reference `CHANGELOG.md`'  →  MUST be 0
          (then mv monoliths back, byte-identical)
```
i.e., the post-delete-sim Check 40 returns ZERO broken-ref FAILs for `BACKLOG.md`/`CHANGELOG.md` anywhere it
scans (`pack-ops/*.md`). If ANY file beyond these 4 surfaces a bare monolith ref, the coder repoints it too
(the gate, not the list, is the contract) and reports the addition. Run in coder PREFLIGHT + reviewer.

**Encoding surfaces (D3):** the Check-40 validator logic is UNCHANGED (the `excluded_basenames` exemption +
the A11 comment already reflect the no-mirror model — EE-7/§D5); D3 fixes the DATA (the referencing files),
not the check. `scripts/tests/test-validate-pack-check-40.sh` needs no change (it asserts the mechanism, which
is unchanged) — the completion coder CONFIRMS it stays GREEN, and adds a case ONLY if the reviewer finds the
broken-ref-after-delete behavior is unencoded. Manifest: `pack-ops/` edits → v11-surface → regen (§5).

### D4 — finish the C7 sweep (the 20 remaining pack-copied skill/agent/command files ×3 CLIs) + G-4 recommendation

**Mechanism (`skill-agent-maintenance-mechanical`).** Mechanically correct every remaining pack-copied
reference so it reflects the no-mirror model + the live tree, in lock-step ×3 CLIs. Two reference classes:
(a) **read-instructions / path refs** (`Read pack-ops/BACKLOG.md`, "open BD items in `pack-ops/BACKLOG.md`")
→ repoint to the `/backlog/` tree (or `/backlog/_toc.md` for "read the index"); (b) **"regenerated mirror"
model statements** (the pack-startup Codex/Gemini copies) → rewrite to the no-mirror statement already landed
in the Claude pack-startup copy (the 1-of-21 done; use it as the parity template). Preserve the client `x-`
contract and per-skill `SKILL.md` structure.

**EXHAUSTIVE file list (EE-9; 21 total, 1 done, 20 remain) — with the exact ref on each line:**

*Claude (`.claude/`):*
| File | Line(s) → ref |
|---|---|
| `.claude/skills/pack-startup/SKILL.md` | **DONE** (`:36-37` no-mirror model — the landed 1) — coder VERIFIES, no re-edit |
| `.claude/agents/pack-architect.md` | `:27` `pack-ops/BACKLOG.md` (open BD items) |
| `.claude/agents/pack-coder.md` | `:47` `pack-ops/BACKLOG.md`,`pack-ops/CHANGELOG.md` (no-edit list); `:51` `pack-ops/BACKLOG.md` (status flips) |
| `.claude/agents/pack-planner.md` | `:32` `pack-ops/BACKLOG.md` (BD items in scope) |
| `.claude/skills/boundary-investigation/SKILL.md` | `:106-107` `pack-ops/BACKLOG.md`,`pack-ops/CHANGELOG.md` (deny-list pack-only example) — **G-4, see below** |
| `.claude/skills/commit-discipline/SKILL.md` | `:112` `pack-ops/BACKLOG.md`; `:113` `pack-ops/CHANGELOG.md`; `:167` `pack-ops/BACKLOG.md` (status-flip example) |
| `.claude/skills/implementation-report/SKILL.md` | `:29` `grep -c "BD-NNN" pack-ops/BACKLOG.md` (example grep); `:62` `pack-ops/BACKLOG.md` (changed-files list) |

*Codex (`.codex/`):*
| File | Line(s) → ref |
|---|---|
| `.codex/agents/pack-architect.toml` | `:18` `pack-ops/BACKLOG.md` (read list) |
| `.codex/agents/pack-coder.toml` | `:25` `pack-ops/BACKLOG.md`,`pack-ops/CHANGELOG.md` (no-edit list); `:27` `pack-ops/BACKLOG.md` (status flips) |
| `.codex/agents/pack-planner.toml` | `:18` `pack-ops/BACKLOG.md` (read list) |
| `.codex/skills/boundary-investigation/SKILL.md` | `:106-107` (deny-list) — **G-4** |
| `.codex/skills/commit-discipline/SKILL.md` | `:112`,`:113`,`:167` |
| `.codex/skills/implementation-report/SKILL.md` | `:29`,`:62` |
| `.codex/skills/pack-startup/SKILL.md` | `:19` `Read pack-ops/BACKLOG.md in full`; `:21` `most recent dated entry from pack-ops/CHANGELOG.md`; `:32-33` "**regenerated mirrors**" MODEL statement → no-mirror rewrite |

*Gemini (`.gemini/`):*
| File | Line(s) → ref |
|---|---|
| `.gemini/agents/pack-architect.md` | `:29` `pack-ops/BACKLOG.md` |
| `.gemini/agents/pack-coder.md` | `:49` `pack-ops/BACKLOG.md`,`pack-ops/CHANGELOG.md`; `:53` `pack-ops/BACKLOG.md` |
| `.gemini/agents/pack-planner.md` | `:25` `pack-ops/BACKLOG.md` |
| `.gemini/commands/pack-startup.toml` | `:16` `Read pack-ops/BACKLOG.md in full`; `:18` `pack-ops/CHANGELOG.md`; `:29-30` "**regenerated mirrors**" MODEL statement → no-mirror rewrite |
| `.gemini/skills/boundary-investigation/SKILL.md` | `:106-107` (deny-list) — **G-4** |
| `.gemini/skills/commit-discipline/SKILL.md` | `:112`,`:113`,`:167` |
| `.gemini/skills/implementation-report/SKILL.md` | `:62` (note: `.gemini` implementation-report has the `:62` ref; the `:29` example-grep line is present in `.claude`/`.codex`; coder greps each file to confirm its own line set) |

**Repoint conventions (apply per `cross-cli-reference-normalization` — audience-correct, not byte-copy):**
- "Read `pack-ops/BACKLOG.md` in full" (pack-startup read-instruction) → "Read the `/backlog/` per-entry tree
  (start at `/backlog/_toc.md`) in full" — matching the model the trinity/README/PACK-AGENTS now state.
- "open BD items in `pack-ops/BACKLOG.md`" (architect/planner read list) → "open BD items in the `/backlog/`
  per-entry tree (`/backlog/_toc.md` index)".
- "`pack-ops/BACKLOG.md` `Status:` flips" (coder/commit-discipline) → "`/backlog/BD-NNN.md` `Status:` flips"
  (status now flips in the per-entry file — consistent with G-7).
- the no-edit / pack-chat-only lists (`pack-coder` files) → repoint the monolith entries to the `/backlog/`+
  `/changelog/` trees (these ARE pack-chat-only; the trees are already in the permitted-PREFIXES set).
- the two "**regenerated mirrors**" MODEL statements (Codex/Gemini pack-startup) → the no-mirror sentence
  already in `.claude/skills/pack-startup/SKILL.md:36-37` (use it verbatim as the parity template, adjusted
  to each CLI's prose form).

**G-4 — pack-vs-project boundary-investigation master divergence (ANALYZE + RECOMMEND; user decides at gate).**
Empirical (EE — measured `4c370da`): the boundary-investigation deny-list (`:104-118` in all 3 pack copies)
lists `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md` (`:106-107`) as EXAMPLES of pack-only `pack-ops/` files,
under "Path prefixes: `pack-ops/` (any file there …)". The MASTER is project-side
(`project-template/skills/boundary-investigation/SKILL.md:112`, same ref), DENIED by a `pack-only` scope →
owned by BD-206 (confirmed: the master and pack copies share the `:106-112` ref region; the pack copies carry
additional pack-audience prose, so they are SEPARATE artifacts per `pack-project-separation`).

- **Recommendation: option (a) — correct the 3 pack copies now; accept the BD-206-scheduled divergence.**
  Concrete evidence: (1) the ref is an ILLUSTRATIVE example inside a broader rule ("`pack-ops/` (any file
  there)"), so the deletion does not break the RULE — the prefix `pack-ops/` is still correct; only the two
  named example files are now stale. The minimal, correct fix is to drop the two deleted-file example tokens
  from the pack copies' example list (the rule "`pack-ops/` — any file there" already covers the surviving
  pack-ops files), leaving the example as `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, etc. (2) The
  divergence this creates (pack copies drop the 2 tokens; master still lists them) is a KNOWN, scheduled gap
  the V3 architect already flagged (`ARCHITECTURE-BD-203-V3` §3.3.2 / R5) and BD-206 closes before launch
  (launch-coherence). (3) `P-missed-7` is SATISFIED: the project-side SSOT (the master) is investigated and
  explicitly LEFT to BD-206; no pack-style mechanism is imported into a project file; the pack copies are
  pack-audience artifacts correctly edited pack-only. The cost of option (b) — deferring ONLY the 3
  boundary-investigation pack copies to BD-206 — is an INCOMPLETE C7 sweep (3 of 21 files carry stale refs
  until BD-206), which contradicts the "finish the full sweep" directive and leaves the pack agents reading a
  stale deny-list example. **Recommend (a).** Surface BOTH options as a clean user-decision at the
  planner→coder gate (the user decides; the coder applies whichever is chosen).

**Encoding surfaces (D4):** none in the validator (C7 files are not validator-scanned for this). Manifest:
`.claude/.codex/.gemini` are NOT among the four v11-surface dirs (`project-template/`, `scripts/`, `pack-ops/`,
`supporting-docs/`) — BUT the completion commit ALSO edits `scripts/` (D1) + `pack-ops/` (D3), so the commit
IS v11-surface and the manifest regen runs once for the whole commit (§5). Confirm the C7 edits do not change
any tracked fixture SHA (the coder's prior C7-partial run produced an empty manifest diff — IMPL §9).

**Completeness gate (D4 — `rename-plans-measure-then-bound`):** after the sweep,
```
GATE-D4:  grep -rnE 'pack-ops/BACKLOG\.md|pack-ops/CHANGELOG\.md|regenerated mirror|monolithic mirror|per-entry source' .claude .codex .gemini
          →  MUST return EXACTLY the documented allowlist: ZERO (every ref repointed/rewritten),
             UNLESS the user picks G-4 option (b), in which case EXACTLY the 6 boundary-investigation
             `:106-107` lines (2 per CLI ×3) remain, documented as the BD-206-deferred set.
```
Run in coder PREFLIGHT + reviewer. The file list above is the convenience; this gate is the contract.

### D5 — FULL validator-impact re-audit (every check in `scripts/validate-pack.py`)

**Method.** Enumerate all 39 checks (EE-10). For each, determine whether the post-conversion state (tree
present; `pack-ops/BACKLOG.md`+`CHANGELOG.md` ABSENT; Check 32′ satisfied) changes its result vs the
pre-conversion state, SUPPORTED by the EE-3 post-delete simulation (which the completion coder RE-RUNS as a
fresh non-destructive `mv`-aside/validate/restore before PREFLIGHT). The audit is the load-bearing safety
deliverable — it proves no check beyond the known set is silently affected.

**Per-check verdict (measured; UNAFFECTED unless noted):**

| Check | Reads monolith? Reads tree? | Post-conversion delta | Disposition |
|---|---|---|---|
| 1 SKILL frontmatter | no / no | none | UNAFFECTED |
| 2 Codex TOML | no / no | none | UNAFFECTED (D4 edits `.codex/*.toml` content but not the frontmatter Check 2 validates — coder confirms Check 2 GREEN post-edit) |
| 3 TD-TBD sentinels | tree `/backlog/` (A10 DONE) | scans tree; SKIP-on-absent | UNAFFECTED — already repointed; GREEN in sim |
| 4 README version table | no / no | none | UNAFFECTED |
| 5 Agent file count | no / no | none | UNAFFECTED |
| 6 Prompts-dir format | no / no | none | UNAFFECTED |
| 7 Pack agent roster | no / no | none | UNAFFECTED (D4 edits agent BODIES, not roster membership) |
| 8 Reserved `x-` | no / no | none | UNAFFECTED |
| 9 Init-project structure | no / no | none | UNAFFECTED |
| 10 Prompt triad | no / no | none | UNAFFECTED |
| 11 Trinity-rule symmetry (informational) | no / no | none | UNAFFECTED |
| 17 AGENT_CAPABILITIES parity | no / no | none | UNAFFECTED |
| 20 .gitignore exception | no / no | none | UNAFFECTED |
| 27 Agent canonical-phrase | no / no | none | UNAFFECTED |
| 21 Pack-help parity | no / no | none | UNAFFECTED |
| 22 Help-fragment freshness | no / no | none | UNAFFECTED |
| 23 Help-fragment completeness | no / no | none | UNAFFECTED |
| 25 Customization-detection | no / no | none | UNAFFECTED |
| 26 Migrator-framework | no / no | none | UNAFFECTED |
| 28 PM-startup parity | no / no | none | UNAFFECTED (D4 edits pack-startup copies; Check 28 validates per-CLI PARITY — coder confirms parity preserved ×3 after the C7 rewrite) |
| 29 Tracker-config schema | no / no | none | UNAFFECTED |
| 30 Recommendation-state schema | no / no | none | UNAFFECTED |
| 31 Skill-cell consistency | no / no | none | UNAFFECTED |
| **32′ no pack monolith** | monolith (asserts ABSENT) + tree | EXPECTED-RED until `git rm`; PASS post-delete | EXPECTED — the coder's one allowed RED; Pack Chat's `git rm` clears it |
| **33 _toc.md in-sync** | tree | ACTIVE; PASS (sim) | UNAFFECTED beyond going ACTIVE (B5 TOCs byte-identical) |
| **34 cross-ref** | tree | 3 dangling (D1+D2) until fixed | D1 + D2 clear it |
| 35 Phase-task lib | no / no | none | UNAFFECTED |
| **36 commit-scope honesty** | walks HEAD diff | HEAD-relative transient (§6) | BENIGN — clears when Commit 2 becomes HEAD; no code change |
| 37 deny-list | project-side walk | none (pack deletion is not project-side) | UNAFFECTED |
| 38 pack-only-file siting | no / no | none | UNAFFECTED |
| 39 cmd_update mapping | no / no | none | UNAFFECTED |
| **40 pack-ops bare-ref** | walks `pack-ops/*.md`; excludes monolith basenames (A11) | 6 broken-refs across 4 files (D3) post-delete | D3 repoints clear it; the `excluded_basenames` + A11 comment are correct (EE-7) and need NO change |
| 43 project-side bare-ref | project-side walk; `BACKLOG.md`/`CHANGELOG.md` = PROJECT-SIDE mirror skips (`:5283-5284,5368,5476`) | none — those basenames are the CLIENT mirrors (BD-206), still present | UNAFFECTED — **do NOT remove the Check-43 mirror-skip basenames** (they refer to project-side files, not the deleted pack monoliths) |
| 41 _CLIENT_INSTALLED_FILES | no / no | none | UNAFFECTED |
| 42 CI wires test files | reads `.github/workflows` | none (no test file added/removed) | UNAFFECTED |
| 45 rule↔rationale bijection | `PACK-MEMORY-RATIONALE.md` | none — D3's `:361` edit is PROSE, not a `## slug` entry | UNAFFECTED — coder CONFIRMS Check 45 GREEN after the D3 RATIONALE edit (no slug delta) |
| 44 durable-doc concision | doc-size gate | none | UNAFFECTED (verify D3/D4 edits don't push a scanned doc over the concision threshold — coder confirms) |
| 47 sanctioned pack-side-shipped | `detect.sh`/`pack-help.sh` constant | none | UNAFFECTED (no install-map/constant change) |
| 48 removed-doc advisory | tree `/backlog/`+`/changelog/` (A12 DONE) | scans tree; SKIP-on-absent | UNAFFECTED — already repointed; GREEN in sim |

**Re-audit conclusion (SUPPORTED by EE-3 + EE-10).** The conversion (tree present + monoliths absent + 32′
satisfied) affects EXACTLY the checks already known: **{32′ (expected-RED→PASS on `git rm`), 34 (D1+D2),
40 (D3)}** as the actionable set; **{3, 33, 48}** flip ACTIVE/repointed but are GREEN in the sim (already
landed at C-1/Commit-2); **36** is a benign HEAD transient (§6); **Check 43's** monolith basenames are
PROJECT-SIDE and unaffected. **No additional check is affected beyond 32′/34/36/40 + the already-handled
3/33/48.** Three checks (2, 28, 45/44) are flagged for a CONFIRM-GREEN-after-edit (their inputs are touched by
D3/D4 content edits, though their validated invariant is unchanged) — the coder confirms each post-edit; none
requires a fix-recipe. This satisfies the user's explicit "do not just patch 34/40 — re-audit every check"
directive: every check enumerated, every verdict SUPPORTED by the simulation.

---

## 4. AFFECTED FILES (complete; builds on the coder's landed working tree)

**Validator (`scripts/`):** `validate-pack.py` (D1 `_resolves_to_defined_id` + docstring only).
**Tests (`scripts/tests/`):** `test-validate-pack-checks-32-33-34.sh` (D1 Group C/F cases);
`test-v11-realistic-ot.sh` C.1/C.9 (NO edit — auto-green encoding surface, RUN it);
`test-validate-pack-check-40.sh` (CONFIRM-GREEN, no edit unless reviewer finds a gap).
**Tree entry (D2):** `backlog/BD-173.md` (one-token fix — the SOLE byte-faithfulness departure).
**Pack-ops docs (D3, pack-chat-only scoped-in):** `pack-ops/BOUNDARY-DEFINITION.md`,
`pack-ops/DRY-RUN-MIGRATION.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/PACK-MEMORY-RATIONALE.md`.
**Pack-copied prompts/skills/commands ×3 CLIs (D4, pack-product):** the 20 remaining files in §D4
(`.claude/.codex/.gemini` agents pack-architect/coder/planner + skills boundary-investigation/commit-discipline/
implementation-report + the Codex/Gemini pack-startup copies). `.claude/skills/pack-startup/SKILL.md` already
done (verify only).
**Fixtures:** `test-fixtures/manifest.txt` (regen; stage iff non-empty — likely empty per IMPL §9, but RUN it).
**Status flip (G-7, §7):** `/backlog/BD-203.md` — `Status: Open → Resolved` (post-`git rm`, by Pack Chat or
scoped-in coder per batch-close shape).

**NOT touched:** `_resolves_to_defined_id` callers beyond Check 34; `CROSS_REF_RE` (EE-5); the Check-40
`excluded_basenames` + A11 comment (correct, EE-7); the Check-43 mirror-skip basenames (project-side);
`project-template/skills/boundary-investigation/SKILL.md` master (BD-206 — G-4); the tracker libs (BD-204).

---

## 5. ORDERED TASK LIST FOR ONE COMPLETION CODER (scoped-in; bounded review/fix cycle)

Fresh pack-coder, scoped IN: `scripts/validate-pack.py`, `scripts/tests/*`, `backlog/BD-173.md`, the 4
D3 `pack-ops/*.md` files, the 20 D4 `.claude/.codex/.gemini` files, `test-fixtures/manifest.txt`. Pack Chat
enumerates ALL applicable rules inline in the spawn prompt (`enumerate-rules-inline`) and names this plan +
`PLAN-BD-203.md` + the design pair as required reads (NOT `IMPL-BD-203-Commit2.md` as a "prior review" —
it is the predecessor coder's STOP-report, cited as the gap source; no `PACK-REVIEW-*` is included per
`no-prior-reviews-to-reviewer`).

1. **D1** — edit `_resolves_to_defined_id` + docstring (forward-ref tolerance, `major > highest-defined`).
2. **D1 tests** — add the Group C/F GREEN (forward-ref resolves) + RED (in-range gap still fails) + FLAG-b
   regression cases to `test-validate-pack-checks-32-33-34.sh`.
3. **D2** — the one-token `BD-19b` fix in `backlog/BD-173.md` (record as the SOLE byte-faithfulness departure).
4. **D3** — repoint the 6 bare refs across the 4 `pack-ops/*.md` files (audience-correct per the §D3 table);
   confirm Check 45 GREEN after the `PACK-MEMORY-RATIONALE.md` edit.
5. **D4** — the C7 sweep across the 20 remaining files ×3 CLIs (read-instructions → tree; model statements →
   no-mirror parity template); apply the user's G-4 choice (default: option (a), drop the 2 stale example
   tokens from the 3 boundary-investigation pack copies).
6. **Manifest** — `bash test-fixtures/build.sh --all --clean`; stage iff non-empty.
7. **VERIFY (the gates):** run the §D3/§D4 grep-zero gates; re-run the non-destructive post-`git rm`
   simulation (`mv` aside → `validate-pack` → `mv` back, byte-identical restore confirmed via `diff -q`);
   re-run the §7 oracle (count 211/11; content-faithfulness with `backlog/BD-173.md` EXEMPTED; status; TOC);
   run the FULL CI test battery INCLUDING the integration tests (`test-v11-realistic-ot.sh`,
   `test-validate-pack-checks-32-33-34.sh`, `test-per-entry.sh`, `test-validate-pack-checks-36-37-38.sh`,
   `test-validate-pack-check-40.sh`) per `verify-full-ci-suite` — NOT only `validate-pack.py`.

### Coder PREFLIGHT contract (the clean-PREFLIGHT target)
Emit the clean PREFLIGHT line ONLY when ALL hold:
- §7 ORACLE GREEN: count 211/11; content-faithfulness GREEN (every entry byte-faithful EXCEPT the one
  user-approved `backlog/BD-173.md` token delta); status distribution preserved; TOC in-sync.
- **GATE-D1**: post-delete-sim Check 34 returns ZERO `v12.0` FAILs.
- **GATE-D2**: post-delete-sim Check 34 returns ZERO `BD-19b` FAIL; `grep -rn 'BD-19b' backlog changelog` → 0.
- **GATE-D3**: post-delete-sim Check 40 returns ZERO `BACKLOG.md`/`CHANGELOG.md` broken-ref FAILs.
- **GATE-D4**: the §D4 grep over `.claude/.codex/.gemini` returns the documented allowlist (ZERO, or the 6
  G-4-deferred lines if the user picked option (b)).
- `validate-pack.py` on the working tree (monoliths PRESENT) is GREEN on EVERY check EXCEPT: Check 32′
  (the 2 "monolith still present while tree exists" FAILs — EXPECTED-RED until Pack Chat `git rm`) AND the
  benign Check-36 HEAD transient (§6). The coder asserts these are the ONLY remaining FAILs and that the
  post-`git rm` simulation is FULLY GREEN (32′ + 34 + 40 all PASS) — that is the clean-PREFLIGHT condition.
- FULL CI battery GREEN locally (per `verify-full-ci-suite`), with `test-v11-realistic-ot.sh` C.1/C.9 GREEN
  in the post-delete sim (they assert exit-0 + Check-34-PASS — green once D1/D2 land + monolith gone).
If ANY gate fails or ANY non-{32′, Check-36-transient} check is RED on the working tree, the coder
STOPS-and-reports (`preflight-stop-means-stop`) INSTEAD of a partial IMPL-REPORT.

### Bounded review/fix cycle (per `bounded-review-fix-cycle`)
Fresh coder → review-1 → [clean ⇒ proceed to hand-off | findings ⇒ triage (Pack Chat presents to user) →
fix-1 → review-2 → [clean | fix-2 → review-3 → architect-escalate if dirty]]; max 3 reviewer / 2 fix-coder.
The reviewer independently re-runs GATE-D1..D4 + the post-delete sim + the FULL CI battery before any CLEAN
verdict (`verify-full-ci-suite`).

---

## 6. THE CHECK-36 HEAD TRANSIENT (benign — no action)

Check 36 default-walks ONLY HEAD (`_commits_to_walk` → `HEAD~0..HEAD`; the per-push CI-gate pattern,
`validate-pack.py:3860`). HEAD is `4c370da` (BD-209 Resolved, subject `pack-chat-only`), which touched only
`pack-ops/BACKLOG.md`. The landed D4 A13-INVERSE removed `pack-ops/BACKLOG.md` from the permitted-paths set,
so `4c370da` retroactively trips Check 36 in any run at that HEAD. This is structurally identical to the
Check-32′ expected-RED: HEAD-relative, and it CLEARS the instant Pack Chat commits the completion (Commit 2,
subject `pack-only`, which denies only project-side paths; the conversion touches ZERO project-side paths →
Commit 2 passes Check 36). NO code change; the coder reports it as the known benign transient, not a defect.

---

## 7. HAND-OFF TO PACK CHAT (the destructive step + final verify + commit + status flip)

After the coder reaches clean PREFLIGHT, Pack Chat (the ONLY non-coder actor; `per-action-approval-sub-agents`):
1. **`git rm pack-ops/BACKLOG.md pack-ops/CHANGELOG.md`** — the single destructive step; explicit user
   approval required (`feedback-no-destructive-without-approval`).
2. **Final reference sweep** — `grep -rn "pack-ops/BACKLOG.md\|pack-ops/CHANGELOG.md"` returns only
   `maintenance-docs/` historical prose (LEAVE — `fail-loud` principle-2) + the deliberate BD-209
   restore-comment removal; ZERO actionable hits elsewhere.
3. **Regenerate `test-fixtures/manifest.txt`** (the `git rm` touches `pack-ops/` — v11-surface); stage iff
   non-empty.
4. **FULL `validate-pack.py` — NOW GREEN incl. Check 32′** (tree present + monolith ABSENT) AND Check 34
   (D1/D2 cleared) AND Check 40 (D3 cleared) AND Check 36 (Commit-2 subject `pack-only`). Only this
   FULL-green run authorizes the commit.
5. **Commit** the atomic Commit 2 (`feat: v11 — BD-203 convert to per-entry sole-SSOT; delete monolith
   (pack-only)`), staging the coder's edits + the `git rm` + the manifest together (one atomic commit;
   `PLAN-BD-203.md` §5).
6. **G-7 status flip** — `/backlog/BD-203.md` `Status: Open → Resolved` + fill `Resolved:`. The monolith it
   would normally flip in is deleted, so the flip lands in the per-entry file (Pack-Chat-direct bookkeeping
   token per `pack-chat-minor-edits-only`, or folded into the implicit batch-completion flip). Sequence it
   in or immediately after Commit 2 per the batch-close shape (`PLAN-BD-203.md` G-7).

---

## 8. RISKS / OPEN ITEMS (surfaced, not resolved)

- **R-A — D3 audience-correctness judgment** (OPTIONAL-FEATURES `:133/:203` pack `/backlog/` vs client
  `docs/project/backlog/`). The coder applies `cross-cli-reference-normalization` and SURFACES each pick in
  the IMPL-REPORT; the reviewer confirms. NOT a planner invention — flagged for review attention.
- **R-B — G-4 user decision** (correct the 3 boundary-investigation pack copies now [recommended (a)] vs
  defer to BD-206 [(b)]). Presented as a clean user-decision at the planner→coder gate; the GATE-D4 allowlist
  is parameterized on the choice.
- **R-C — count drift** (`PLAN-BD-203.md` R1). The oracle is a live grep at completion time (211 today); if
  the BACKLOG grew, the count re-measures — never hard-coded.
- **R-D — `verify-full-ci-suite` backstop** (`feedback_verify_full_ci_suite`). A green `validate-pack` alone
  is NOT a green commit; the coder AND reviewer run `test-v11-realistic-ot.sh` (the exact integration test
  whose C.1/C.9 pin Check-34/exit-0 and would catch a missed forward-ref) before any clean verdict.
- **R-E — no new BD scope invented** (`fail-loud` §54). D1–D5 are the complete completion set; any NEW issue
  the re-audit or review surfaces is SURFACED with evidence + a recommended disposition, not silently folded
  in (per the GOALS "surface, don't silently fix or ignore").

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (QUOTED command/output/path, not summarized) | Conclusion |
|---|---|---|
| **empirical-evidence-blocks** | §1 EE-1..EE-10: every state-claim carries the actual command + verbatim output + HEAD `4c370da` + 2026-06-05 + interpretation + SUPPORTED. E.g. EE-2 `python3 scripts/validate-pack.py … grep 'references' → 3 FAIL lines` (the complete dangling set); EE-3 the full post-`git rm` simulation FAIL set (`mv` aside → validate → `mv` back, restore confirmed); EE-4 the python harness proving `D1 TOLERATE: ['v12.0']`, `STILL FAIL: []`; EE-10 the 39-check inventory + every monolith/tree touch-point grepped. | COMPLIANT |
| **ci-guard-measure-then-bound (D1)** | §D1 + EE-4: MEASURED every `vN.M` token in `backlog/+changelog/`; CATEGORIZED each KEEP (major>highest → forward-ref, only `v12.0`) vs STRIP (none today; gap-class still FAILs); SIZED the tolerance to `major > highest-defined` (never a token list); EE-4 VERIFIES post-design the rule tolerates exactly `v12.0` and still fails an in-range gap. Did NOT widen `CROSS_REF_RE` (EE-5: bare `vN` is not a token). | COMPLIANT |
| **rename-plans / mass-edit = measure-then-bound (D3/D4/D5)** | §D3 GATE-D3 + §D4 GATE-D4: each disposition's CONTRACT is a grep/post-delete-sim GATE (post-delete Check-40 broken-refs = 0; `.claude/.codex/.gemini` monolith-ref grep = documented allowlist), run in coder PREFLIGHT + reviewer; the file lists (4 D3 + 20 D4) are explicitly "a CONVENIENCE … the gate is the contract." §D5 re-audit is the post-delete-sim over EVERY check, not an anchor list. | COMPLIANT |
| **enumerate-encoding-surfaces** | §D1 table enumerates validator + `test-validate-pack-checks-32-33-34.sh` Group C/F + `test-v11-realistic-ot.sh` C.1/C.9 + `validate-pack.yml:159` in lock-step; §D3/D4 name the test surfaces (Check-40 test CONFIRM-GREEN; Check 45/28/2 CONFIRM-GREEN post-edit); §D5 names Check 43's project-side mirror-skip basenames as a "do NOT remove" encoding distinction. | COMPLIANT |
| **fail-loud / delete-the-old-source** | §D1 (tolerate forward-ref CATEGORY, never a token list) + §D2 (FIX the `BD-19b` error in content, not allowlist — `no-bd-letter-suffix` §35-37) + §D3 (REPOINT refs to the tree, not `_CHECK_40_ALLOWLIST` suppress) + §7 (Pack Chat `git rm` deletes the monolith; `maintenance-docs/` history LEFT). Every disposition confirmed fix/forward-look-not-suppress. | COMPLIANT |
| **no-bd-letter-suffix** | §D2 + EE-6: `BD-19b` is a stray error inside "Batch 19b" (no BD-19b entry); fixed by the one-token prose correction `… per Batch 19b research …`, NOT allowlisted — verbatim per the memory file `:35-37`. | COMPLIANT |
| **rules-applied-verification-block (+ read-in-full)** | This block; every row QUOTED evidence (none empty); READ-IN-FULL row below with per-file direct-read proof (line count + first + last line) for docs #1–#8. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof — docs #1–#8)
| # | Document | Direct Read? | Proof (line count · first line · last line) |
|---|---|---|---|
| 1 | `CLAUDE.md` | YES | 576 lines · L1 "# CLAUDE.md — AI Agent Config Pack (Pack Repo)" · L576 "- OT-style v10→v11 migration is automated; OT itself is read-only for / testing (use `/tmp` clones or scratch fixtures, never write to real OT)." (read in full incl. `## Pack memory`). |
| 2 | `PLAN-BD-203.md` | YES | 799 lines · L1 "# PLAN-BD-203 — Implementation plan: pack self-migration Phase 1 (monolith → per-entry sole-SSOT)" · L799 "**End of PLAN-BD-203.md**" (read across 2 pages: 1-487 + 488-799). |
| 3a | `ARCHITECTURE-BD-203-V3.md` | YES | 413 lines · L1 "# ARCHITECTURE-BD-203-V3 — Shared per-entry engine co-design + the PACK conversion (no-mirror, preserve-all, reversible)" · L413 "**End of ARCHITECTURE-BD-203-V3.md**". |
| 3b | `ARCHITECTURE-BD-203-V3-AMENDMENT.md` | YES | 244 lines · L1 "# ARCHITECTURE-BD-203-V3-AMENDMENT — pre-normalize the monolith; convert BD-001..019; flatten the version-grouping scaffolding" · L244 "**End of ARCHITECTURE-BD-203-V3-AMENDMENT.md**". |
| 4 | `IMPL-BD-203-Commit2.md` | YES | 431 lines · L1 "# IMPL-BD-203 Commit 2 — ATOMIC conversion EDITS (Phase B + C + D4 A13-INVERSE)" · L431 "**End of IMPL-BD-203-Commit2.md**" (§5 POQ-1/POQ-2, §6 C7-partial+G-4, §3 validate-pack state, §8 deviations, §12 next steps read directly). |
| 5 | `feedback_rename_plans_measure_then_bound.md` | YES | 44 lines · L1 "---" · L44 "blast-radius map feeds the gate's in-scope file set + allowlist)." |
| 6 | `feedback_fail_loud_delete_old_source.md` | YES | 55 lines · L1 "---" · L55 "caught by the architect; do not invent scope." |
| 7 | `feedback_no_bd_letter_suffix.md` | YES | 44 lines · L1 "---" · L44 "the trinity `## Pack memory` BD-NNN numbering rule." |
| 8 | `feedback_verify_full_ci_suite.md` | YES | 43 lines · L1 "---" · L43 "`enumerate-encoding-surfaces` (CLAUDE.md), [[feedback_manifest_regen_on_v11_surface]]." |

**No named document was derived rather than read.** All EE numbers (211/11 counts; the 3-ref Check-34 set; the
full post-`git rm` simulation FAIL set; the D1 forward-ref boundary `['v12.0']`; bare-`vN` non-tokenization;
the 21-file C7 enumeration with per-line refs; the 39-check inventory + touch-points) were independently
measured this session at HEAD `4c370da` via Bash/Read.

**End of PLAN-BD-203-C2-COMPLETION.md**
