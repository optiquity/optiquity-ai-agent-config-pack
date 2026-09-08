# ARCHITECTURE-BD-294 — the trinity graft engine: the template instructs an edit the engine forbids (D3), and the engine's seed slot silently swallows whole sections (D5)

**Pass type:** DESIGN. Nothing in the pack was modified. Every candidate fix was
built and measured in a throwaway scratch clone.
**Pack under design:** `/Users/david/Developer/optiquity-ai-agent-config-pack` @ `91712431ad4b566cff2d3f7717ce70d4d1e0abbf`
**Measured from:** worktree `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a0861cc63578c268f`, HEAD `91712431ad…`, clean, `.git` = **101-byte pointer FILE** (trap #1 is live in this environment)
**Scratch root:** `…/03f94d7a-811d-445e-9727-7c003d6a116b/scratchpad` — `pack/` (pristine clone), `eng-d5/`, `eng-noseed/`, `eng-d5d3a/`, `eng-optB/` (candidate overlays, each committed inside its own clone before measurement per trap #2)
**Date:** 2026-09-03
**Tracked entry:** `/Users/david/Developer/optiquity-ai-agent-config-pack/backlog/BD-294.md` (Status: Open, Target: v11.0)
**Reconciled:** the plan's adversarial re-verification at `b40f111` (2026-09-07) re-ran every load-bearing measurement in this document; §9 records the five items it did not leave standing as written — four carrying a superseded claim or inference, and one (§3.1 / EEB-8) **EXTENDED**, its two recorded outcomes still reproducing with a third found alongside them. One claim inside item 5 re-measured **accurate** and is restated durably rather than corrected. **Read §9 before acting on §2.5, §3.1 (EEB-8), §3.2 (EEB-11), §3.6, §5 (EEB-16), §7 (the rules rows quoting EEB-16 and OI-5), OI-3, or OI-5** — eight sites, each carrying its own inline marker. The original analysis is left exactly as written; §9 records what changed, what re-measured accurate, where the corrected measurement lives, and which shipped symbol realises it.

---

## 0. What a client experiences today, and what changes

Today a client installs the trinity, reads the block the pack itself put at the
top of the file — *"Fill in placeholders and remove this block"* — and does
exactly that. On their next update or migration the graft engine rejects the
file, writes the pack's placeholder-bearing canonical back over their live
context file, and parks their filled-in copy in a sidecar; the live `CLAUDE.md`
that every agent reads at session start once again says the project is called
`[PROJECT_NAME]`. If instead they wrap their filled-in text in the pack's own
project-owned marker pair, the engine rejects that too, because the preamble
sits above the first H2 and no marker is admissible there. The same trap is set
seven more times per file in the section bodies, and five more times by
`<!-- OPTIONAL: … delete the entire section if not applicable -->` comments
whose deletions the engine silently undoes without telling anyone. Separately,
a client who folds their own sections into markers and appends them at the end
of the file — under a section the pack literally named `## Project addenda` —
has every one of those blocks silently reclassified, their `renamed-from`
annotation discarded unread, their content dropped from the graft, and receives
an error naming their own new heading as a *pack* section that has gone missing.
After this work: the shipped template carries its editable content inside
shipped marker pairs, so filling it in place is a clean graft; the two blocks
the template told clients to delete are simply not shipped, so there is nothing
left to delete; the five "delete the entire section" instructions are replaced
by the suppression form the engine actually honours; and the engine classifies a
marker pair that opens with its own `##` heading as the owned section it is,
wherever in the file it sits. Already-migrated clients are not repaired
automatically by any option — a one-time in-place remediation recipe ships with
the fix, and is proven below to reach a clean graft with no re-migration and no
loss of filled-in content.

---

## 1. Regime and fixture validity (traps #1–#5)

Every behavioural number below comes from a harness with a control that **must
fail** and a control that **must pass**. A run whose controls did not behave is
marked VOID and its numbers are not used. No run in this document is VOID.

| Trap | How it was handled here |
|---|---|
| **#1** worktree `.git` is a pointer FILE | Verified live: `file …/agent-a0861cc63578c268f/.git` → `ASCII text`, 101 bytes; the main checkout's is a `directory`. No `rsync`/`cp -R` of a linked worktree was used; every engine copy is a `cp -R` of a **real `git clone`**, whose `.git` was re-verified as a directory. |
| **#2** `git clone` carries committed state only | Every candidate overlay was **committed inside its own scratch clone** (`h/commit_overlay.sh`) before `validate-pack.py` — which draws its candidate set from `git ls-files` — was run against it. Commit SHAs recorded per EEB. |
| **#3** a mutation can silently fail to apply | No Perl. All mutations are Python `str.replace` wrapped in an assert that the anchor occurs **exactly once before** and is **absent after**, and that the replacement text **is present after**. Every patch run printed `anchor present-before OK` / `anchor gone-after OK`; a miss exits non-zero. Placement fixtures additionally carry **identical sorted line multisets**, so placement is provably the only variable. |
| **#4** a measurement in the wrong regime | Every disposition is labelled with its BASE regime. Regime B (`BASE=""`) is the gate on the install fold, the migration reconciliation fold, and `init --update` (the empty first argument is literal in `resolve-merge-conflicts/SKILL.md` Case 2 and Case 3). Regime A results are reported separately and never substituted for Regime B. The v10 leg used the **real** `v10` tag (`git rev-parse v10^{commit}` → `fa817044…` resolves in the scratch clone), not a synthesised baseline. |
| **#5** a fixture in the wrong shape never reaches the code under test | Every harness ran three controls: `CTRL-identical` (must return `unchanged-pack`), `CTRL-mustfail-outofmarker` (must return `customization-detected-needs-reconciliation`), `CTRL-mustpass-seed` (must return `merged-with-customization`). All harnesses printed `CONTROL-RESULT: PASS`. |

**Two claims I inherited and had to correct.** Both are recorded here because an
implementer acting on either would have shipped a wrong fix:

1. The incoming census warns that *"simply testing `sawheading` before the
   seed-slot exception would break `vC`, the sanctioned case, because
   `isheading()` also matches `^### `."* **Measured: the close-time reorder
   alone is a complete NO-OP** — every disposition and every region
   classification is byte-identical to the unpatched engine (EEB-3). It cannot
   break `vC` because `sawheading` is never set inside a seed-slot region: the
   *open-time* branch short-circuits every heading to `sawbody=1` before
   `sawheading` can be assigned. The hazard is real only if the open-time branch
   is *also* changed — and the danger of the census's framing is the opposite of
   what it says: an implementer who applies the "naive fix", sees 419 assertions
   and `validate-pack.py` stay green, and ships, has shipped **nothing**.
2. The incoming census reports the second D5 signature's message as the L-2
   *"pack-owned body outside your markers under '## Project addenda' diverges"*
   form. On fixtures derived from the **real shipped canonical** I could not
   reproduce that message; both signatures produce the L-8 *"pack section
   '<your own heading>' … is absent from the new canonical"* form (EEB-2). I
   report the message I measured and do not carry the one I could not. The
   underlying mechanism, the content loss, and the misdiagnosis are identical
   either way.

---

## 2. D5 — the seed-slot exception over-captures whole sections

### 2.1 Mechanism, verified by execution

`_mp_regions` in `scripts/lib/marker-preserve.sh` decides a marker region's
shape at the END marker with this test order:

```awk
if (beginh2 ~ /^## Project addenda/){ …Shape A… }
else if (sawheading){ …Shape B… }
```

and, at the *open* side, suppresses `sawheading` entirely inside a seed-slot
region:

```awk
if (isheading(raw)){
  if (beginh2 ~ /^## Project addenda/){ sawbody=1 }        # seed: headings allowed
  else if (!sawheading && !sawbody){ sawheading=1; ownh=raw }
```

So any marker region whose enclosing out-of-marker H2 is `## Project addenda` is
forced to Shape A regardless of what it contains. Three measured consequences:

1. Its `renamed-from` annotation is never read (Shape A has no override key), so
   Step 5's rename validation and the Step-6 suppression pass both skip it.
2. Its owned `##` heading still reaches `_mp_h2_list` (that function is not
   marker-aware), is not filtered by the Shape-B skip in Step 6, and is
   therefore adjudicated as an **OURS pack section** — firing the L-8
   *"absent from the new canonical"* branch on the client's own new heading.
3. `## Project addenda` is the **last** H2 in all three shipped files
   (`CLAUDE.md` L511 of 522, `AGENTS.md` L488 of 499, `GEMINI.md` L545 of 556),
   so "append at end of file" always lands inside the trap.

Section order is **not** otherwise enforced; the skill's contract at
`project-template/skills/resolve-merge-conflicts/SKILL.md:129` is correct as
written. A mid-file relocation with an identical sorted line multiset passes
cleanly (EEB-2, `s1-mid-file`). This is a code defect in one region, not a doc
defect.

> **EEB-1 — the trap region is the last section in every shipped trinity file.**
> Command: `grep -n '^## ' project-template/{CLAUDE,AGENTS,GEMINI}.md` and
> `grep -n 'BEGIN project-owned\|END project-owned' …`, at HEAD `91712431ad…`, 2026-09-03.
> Output (last H2 / marker lines / file length):
> `CLAUDE.md 511:## Project addenda`, markers at `521`,`522`, file 522 lines;
> `AGENTS.md 488:## Project addenda`, markers at `498`,`499`, file 499 lines;
> `GEMINI.md 545:## Project addenda`, markers at `555`,`556`, file 556 lines.
> Interpretation: in all three files the seed pair occupies the final two lines,
> so an append-at-EOF marker pair is necessarily enclosed by `## Project addenda`.
> **SUPPORTED.**

> **EEB-2 — both D5 signatures reproduced, Regime B, controls PASS.**
> Command: `bash scratchpad/h/run_d5.sh` against a `cp -R` of the pristine clone
> (`marker-preserve.sh` sha `ee492a9b96f24f113549ae3a354dfa603e2a2338`), 2026-09-03.
> Controls: `CTRL-mustfail-outofmarker → customization-detected-needs-reconciliation`;
> `CTRL-mustpass-seed → merged-with-customization`;
> `CTRL-identical → unchanged-pack`; `CONTROL-RESULT: PASS -> run is VALID`.
> Fixture fingerprints (sorted-line multiset, sha1[:12]): `s1-at-position`,
> `s1-at-eof`, `s1-mid-file` all `77032faaa403`, 520 lines each — `GROUP-IDENTICAL: True`;
> `s2-at-eof`, `s2-mid-file` both `e878293956b4`, 528 lines — `GROUP-IDENTICAL: True`.
> Output:
> ```
> s1-at-position   merged-with-customization                     override body in DEST: 1
> s1-mid-file      merged-with-customization                     override body in DEST: 1
> s1-at-eof        customization-detected-needs-reconciliation   override body in DEST: 0
>    notes=pack section '## Xcode 26.4 platform features' present in your copy is absent
>          from the new canonical — it may have been renamed or retired; reconcile (L-8)
> s2-mid-file      merged-with-customization    content in DEST: 1; heading in DEST: 1
> s2-at-eof        customization-detected-needs-reconciliation   content in DEST: 0; heading in DEST: 0
>    notes=pack section '## Release checklist' present in your copy is absent from the
>          new canonical — it may have been renamed or retired; reconcile (L-8)
> vC-seed-h3       merged-with-customization                     seed body in DEST: 1
> ```
> Region dumps: `s1-at-eof` → `REGION A ## Project addenda 513 514` **and**
> `REGION A ## Project addenda 515 520`; `s1-mid-file` → `REGION B ## Xcode 26.4 platform features 493 498`.
> Interpretation: placement is the sole variable; the EOF placement is reclassified
> A, the `renamed-from` is discarded, the content is absent from DEST, and the
> message names the client's own heading a pack section. Signature 2 (a brand-new
> section with no `renamed-from`) behaves identically and is unreported.
> **SUPPORTED.**

> **EEB-3 — the "naive" close-time reorder is inert, not dangerous.**
> Command: patch only the close-time test order (`h/patch_engine.py … naive-close-reorder`;
> anchors asserted present-before/gone-after; result **31730 bytes, identical to the
> 31730-byte source** — a pure reorder), then `bash h/run_naive.sh`, 2026-09-03,
> engine sha `f300f57ee66f473512a3af77d9cb3afb69ac47e0`.
> Output: every disposition and every `REGION` line identical to EEB-2 —
> `s1-at-eof` still `customization-detected-needs-reconciliation`,
> `vC-seed-h3` still `merged-with-customization`, regions still
> `A/## Project addenda` ×2 for `s1-at-eof`.
> Interpretation: the census's stated hazard does not fire, and the plausible
> one-line fix changes nothing while leaving the whole battery green.
> **NOT-SUPPORTED** (the inherited claim); the corrected mechanism is SUPPORTED.

### 2.2 Options, each measured on existing installs

The recommended shape is: at the *open* side, inside a seed-slot region, promote
a `^## ` heading that is the region's first content to the owned Shape-B heading
(`### ` subsections and any later heading remain seed body); at the *close* side,
test `sawheading` before the seed-slot branch. Measured as `eng-d5`
(`marker-preserve.sh` +10/−4).

| Option | What it does | Effect on a client who already folded at EOF | Effect on a client who folded mid-file (working today) | Effect on the sanctioned seed slot | Existing battery |
|---|---|---|---|---|---|
| **D5-1 — fix the engine (seed-slot `##` promotion)** *(recommended)* | one classification changes: a seed-slot region opening with `## ` becomes Shape B | **repaired on the next run, no client edit** — `s1-at-eof`/`s2-at-eof` → `merged-with-customization`, content preserved, graft **byte-identical** to the mid-file graft | unchanged (`merged-with-customization`, same sha) | unchanged: `###`-first, prose-then-`###`, prose-only all still Shape A and clean | 419 assertions + `validate-pack.py` green (EEB-4) |
| **D5-2 — fix the doc instead** (state a placement rule) | skill/pre-reconcile say "never place a marker pair after `## Project addenda`" | **not repaired**; every existing EOF fold keeps sidecarring, and the operator must re-edit three files | unchanged | unchanged | green (no code change) |
| **D5-3 — delete the seed-slot exception** | seed regions classify by the ordinary rule | repaired (`s1-at-eof`/`s2-at-eof` clean) | unchanged | **REGRESSION**: prose-then-`###` (`sd2`) becomes an L-1 partial-wrap **sidecar**; `###`-first (`sd1`) is silently reclassified Shape A → Shape B | green — the battery cannot see either change (EEB-5) |
| **D5-4 — move `## Project addenda` off the end** | the EOF append lands under a different H2 | repaired only for EOF; a fold placed *inside or after* the addenda section still traps | unchanged | unchanged | not measured — rejected on mechanism: it relocates the trap rather than removing it, and it changes the shipped file shape for a code defect |

> **EEB-4 — the recommended D5 fix repairs both signatures, preserves the
> sanctioned slot, and regresses nothing.**
> Commands, 2026-09-03: `h/patch_engine.py … d5-fix` (4 anchor assertions passed);
> committed inside the scratch clone as `7b92f1c` (`scripts/lib/marker-preserve.sh | 14 ++++++++++----`,
> 10 insertions / 4 deletions); `bash h/run_d5fix.sh`; `bash h/run_grafteq.sh`;
> `bash h/run_regress.sh …/eng-d5`.
> Output — dispositions (`CONTROL-RESULT: PASS -> run is VALID`):
> `s1-at-position`, `s1-mid-file`, `s1-at-eof`, `s2-mid-file`, `s2-at-eof`,
> `vC-seed-h3` → **all `merged-with-customization`**, override/new-section body
> present in DEST for each.
> Graft equality: `dest-s1-at-position.md`, `dest-s1-mid-file.md`,
> `dest-s1-at-eof.md` all sha `499fbf436485be81915482ed8eea173820feef26`, 520
> lines — `at-position vs at-eof identical: YES`; the s2 pair both
> `ccf6b44abd955d0b88b290e54e5533539b8ab912`. Idempotence: re-feeding each graft
> returns `merged-with-customization`.
> Regression battery: `test-marker-preserve-bd136.sh 68 passed 0 failed`,
> `test-customization-preserve.sh Passed: 310 Failed: 0`,
> `test-install-trinity-fold-gate.sh 19 passed 0 failed`,
> `test-resolve-merge-conflicts-skill.sh 22 passed 0 failed`,
> `test-validate-pack-check-91.sh` pass, `test-validate-pack-check-19.sh` pass,
> `test-migrate-v10-to-v11-pre-reconcile.sh 13 passed 0 failed`,
> `validate-pack.py exit=0 PASSED — all checks clean`.
> Interpretation: the fix delivers the skill's documented order-independence
> literally (identical bytes for all three placements), is idempotent, and no
> existing assertion moves. **SUPPORTED.**

> **EEB-5 — D5-3 (delete the exception) fixes the defect and breaks two
> legitimate seed shapes, invisibly.**
> Command: `bash h/run_seedshapes.sh`, 2026-09-03 — four seed-slot shapes run on
> three engines with `CONTROL-RESULT: PASS` on each.
> Output:
> ```
>                      pack(current)      eng-d5(recommended)   eng-noseed(option 3)
> sd1 ###-first        clean  A/addenda   clean  A/addenda      clean  B/### Repository overview
> sd2 prose-then-###   clean  A/addenda   clean  A/addenda      SIDECAR (L-1 partial wrap)
> sd3 prose-only       clean  A/addenda   clean  A/addenda      clean  A/addenda
> sd4 ##-first (D5)    SIDECAR            clean  B/## Release…  clean  B/## Release checklist
> ```
> and the full battery under `eng-noseed`: 68/310/19/22 passed, `validate-pack.py exit=0`.
> Interpretation: the recommended fix changes exactly ONE classification (the
> defect, `sd4`); option 3 additionally sidecars a previously-clean shape (`sd2`)
> and reclassifies `sd1` — which is the exact shape the pack's own
> `test-fixtures/v11-trinity-marker-prepped/` golden uses (`### Repository
> overview` at the head of the addenda seed, per its README). Neither change is
> visible to the battery. **SUPPORTED.**

### 2.3 Recommendation — D5

**Adopt D5-1: fix the engine, and mirror the fix into Check 91's Python parser.**

Evidence: D5-1 is the only option that repairs already-folded clients with no
client edit (EEB-4), leaves every other classification byte-identical (EEB-5),
and makes the engine deliver the contract the skill already publishes. D5-2 is
rejected because it cannot cure signature 2 — a brand-new project section that
carries no `renamed-from` is told *"fold your edit into a marker"* by an engine
that already has it in one, and its content is dropped from the graft silently
enough that the operator's only clue is a wrong error string. D5-3 is rejected
on measured regression (EEB-5). D5-4 is rejected on mechanism.

The Python mirror is not optional. `scripts/lib/validate_checks/trinity_markers.py`
`_scan_markers` is a line-for-line reimplementation of `_mp_regions` with the
same test order, and the two parsers are a stated invariant of the design.

> **EEB-6 — the two parsers disagree until the mirror lands, and agree after.**
> Command: `bash h/run_parity.sh …/eng-d5`, before and after
> `h/patch_py_mirror.py` (4 anchor assertions passed), 2026-09-03.
> Before (bash sha `e8ade78c…`, py sha `93a44cfa…`):
> `s1-at-eof PARITY-MISMATCH  bash: A:## Project addenda;B:## Xcode 26.4 platform features;  py: A:## Project addenda;A:## Project addenda;`
> and the same mismatch on `s2-at-eof`; four other fixtures `PARITY-OK`.
> After (py sha `cc6a0cccfe17d067fed824447addd697511e0828`, committed `c3a8c05`,
> `trinity_markers.py | 17 ++++++++++++-----`, 12 insertions / 5 deletions):
> **all six fixtures `PARITY-OK`**, and the battery re-run is 68/310/19/22
> passed with `validate-pack.py exit=0 PASSED — all checks clean`.
> Interpretation: shipping the bash fix alone leaves the pack's own
> well-formedness validator classifying the shipped shapes differently from the
> engine that consumes them. **SUPPORTED.**

### 2.4 The coverage that would have caught D5

The existing legs are M-17 (empty seed pair both sides), M-18 (plain text inside
the seed markers), M-19 (a marker region above the first H2). **No test places a
whole-section `##` marker pair after `## Project addenda`.** Concretely, add to
`scripts/tests/test-marker-preserve-bd136.sh` (669 lines today):

**M-20 — placement invariance of a Shape B override (Regime B).** Build three
OURS from the real `project-template/CLAUDE.md` with the same override block
(`renamed-from="## iOS 26 / Xcode 26.3 platform features"`, owned heading
`## Xcode 26.4 platform features`) at three positions: at the suppressed
section's slot, mid-file, and appended after the seed pair at EOF. Assert
(a) each fixture's **sorted line multiset is identical** to the others (the
guard that keeps the test honest about what varies), (b) all three dispositions
are `merged-with-customization`, (c) the three DEST files are **byte-identical
to one another**, and (d) the override body string is present in each DEST.

**M-21 — a brand-new project section appended at EOF (Regime B, no
`renamed-from`).** Same construction with a plain `<!-- BEGIN project-owned -->`
/ `## Release checklist` / body pair at EOF vs mid-file. Assert both
`merged-with-customization`, both DESTs byte-identical, and the section heading
and body present in both.

**M-22 — the seed slot keeps its exception.** Four shapes inside the shipped
seed pair: `###`-first, prose-then-`###`, prose-only, and `##`-first. Assert the
first three classify **Shape A** with host `## Project addenda` and return
`merged-with-customization`, and the fourth classifies **Shape B** with owned
head `## Release checklist` and returns `merged-with-customization`. Assert the
classification via `_mp_regions` directly, not only via the disposition —
EEB-5 shows a shape can be reclassified while the disposition stays clean.

**M-23 — bash↔python classification parity.** Extend the existing fence
cross-check to classification: for each of the M-20/M-21/M-22 fixtures, assert
`_mp_regions`' `shape:head` sequence equals `_scan_markers`' `shape:head`
sequence. This is the leg that would have caught the mirror drift in EEB-6.

**The mutations that must red.** A coverage spec is only credible if it names
the mutant it kills:

| Mutation | Must red |
|---|---|
| Revert `marker-preserve.sh` to HEAD (no fix) | M-20 (`at-eof` disposition), M-21, M-22 (`##`-first) |
| Apply **only** the close-time reorder (the naive fix, EEB-3) | M-20, M-21, M-22 — this is the load-bearing mutant: it is a no-op that a weaker test suite would call green |
| Delete the seed-slot exception entirely (EEB-5) | M-22 (`prose-then-###` → sidecar; `###`-first → Shape B) |
| Fix the bash engine but not the Python mirror | M-23 |
| Change the fixtures so the three placements no longer share a line multiset | M-20 (a) |

All five mutants were built and run in scratch; each reds exactly the legs
listed and nothing else.

### 2.5 Implementation sizing — D5

| Surface | Change | Measured / estimated |
|---|---|---|
| `scripts/lib/marker-preserve.sh` | 2 edits (open-time promotion, close-time order) + the header comment's seed-slot sentence | **+10 / −4** (measured, scratch commit `7b92f1c`) |
| `scripts/lib/validate_checks/trinity_markers.py` | the same 2 edits in `_scan_markers` + its docstring's V-2 sentence | **+12 / −5** (measured, scratch commit `c3a8c05`) |
| `scripts/tests/test-marker-preserve-bd136.sh` | M-20 / M-21 / M-22 / M-23 | ~140–180 lines added (M-1…M-19 average ~35 lines/leg) |
| `project-template/skills/resolve-merge-conflicts/SKILL.md` (287 lines) | one sentence at the order-independence claim (`:129`) naming the seed slot as no longer special-cased | ~2 lines |
| `supporting-docs/PRE-RECONCILE-v10-to-v11.md` (298 lines) | §(d) pitfall list: the "heading inside a Shape A region" bullet needs the seed-slot carve-out stated | ~3 lines |
| `pack-ops/MERGE-STRATEGY.md` (680 lines) | Shape A/B description at `:200–:206` | ~2 lines |

> **SUPERSEDED (length only) — see §9 item 5.** At `b40f111`
> `pack-ops/MERGE-STRATEGY.md` is **689** lines, not 680. The `:200–:206`
> anchor beside it did **not** move: re-measured at `b40f111`, the
> `**Shape A**` bullet begins at `:200` and the `**Shape B**` bullet at
> `:204`, so the citation still lands on the Shape A / Shape B prose —
> `PLAN-BD-294.md` §1.1 row 20 verdicts exactly that (*"**MOVED** (length),
> **CONFIRMED** (anchor)"*). A line range is a fragile citation STYLE, not a
> wrong claim; the durable form is § "The 11 file classes" →
> `### 1. trinity`.

**Verdict: coder-level.** The change is two matched edits in two parsers plus
tests; the design decision (which classification changes, and that exactly one
does) is settled by EEB-4/EEB-5 and needs no further design pass.

---

## 3. D3 — the template instructs an edit the engine forbids

### 3.1 Mechanism, verified by execution

The engine's Step 6 reconciles the preamble before any section:

```bash
_mp_extract_preamble "$ours"   | _mp_strip_marker_blocks > "$work/o_pre"
_mp_extract_preamble "$theirs" | _mp_strip_marker_blocks > "$work/t_pre"
… Regime A: cmp -s b_pre o_pre     … Regime B: cmp -s o_pre t_pre
```

and `_mp_regions` refuses a marker region with no enclosing H2:

```awk
} else if (trim(curh2)==""){
  print "ERR\tnohost\tproject-owned marker region beginning at line " beginln " has no enclosing H2 heading…"
```

and Step 7 grafts `_mp_extract_preamble "$theirs"` **verbatim** — which is why
the `nohost` gate exists: a preamble region would otherwise be dropped silently.

So filling the placeholders in place diverges the preamble (L-8); wrapping them
in a marker pair trips `nohost` (L-6/L-1). Both routes end at
`_mp_sidecar_conflict`, which does `cp "$theirs" "$dest"` — the live trinity is
overwritten with the pack canonical and the client's filled copy is parked in a
sidecar.

**D3 is a family of four legs, not one.** The reported leg is (a); (b), (c) and
(d) were measured here, and (d) is unreported and is the only one that fails
*silently*:

| Leg | The shipped instruction | Where it lives | What the engine does |
|---|---|---|---|
| **(a)** identity placeholders | `**[PROJECT_NAME]** targets [PLATFORM_TARGETS].` / `Transport: [TRANSPORT]` | preamble, `CLAUDE.md:26–27`, `AGENTS.md:24–25`, `GEMINI.md:22–23` | L-8 preamble divergence; live file reset to placeholders |
| **(b)** removable preamble blocks | *"Remove this comment block after filling in the placeholders."* + *"Fill in placeholders and remove this block."*; and `INSTALL-PROCEDURES.md:484` / `:631` repeat the first as a migration step | preamble | L-8 preamble divergence (identical message) |
| **(c)** in-section placeholders | `[PLATFORM_DEFAULTS — fill in per project type]` and 6 more | section bodies | L-2 out-of-marker body divergence |
| **(d)** optional-section deletion | 5 × `<!-- OPTIONAL: … delete the entire section if not applicable -->` plus `[GRPC_RULES — … or delete section]` | section bodies | **the deletion is silently reverted** — disposition `merged-with-customization`, the section restored from the THEIRS spine, no message |

A fifth, shipped contradiction: `supporting-docs/PRE-RECONCILE-v10-to-v11.md`
§(c) tells the client the preamble *"must be byte-for-byte your v10 baseline
(including the preamble — the text above the first `## ` heading)"* — the exact
opposite of what the template and `INSTALL-PROCEDURES.md` 5-C.2 instruct. Three
shipped documents give three incompatible instructions about the same bytes.

> **EEB-7 — both ways of obeying the shipped template fail, in both regimes;
> the live file loses the client's identity.**
> Command: `bash h/run_d3.sh` on the pristine clone (engine sha `ee492a9b…`),
> Regime B and Regime A, 2026-09-03. Controls `unchanged-pack` /
> `customization-detected-needs-reconciliation` / `merged-with-customization` →
> `CONTROL-RESULT: PASS -> VALID`.
> Output (Regime B, the `--update` / fold gate):
> ```
> d3-fill-only        customization-detected-needs-reconciliation
>    notes=pack-owned preamble diverges (out-of-marker) — review before adopting the new canonical (L-8)
>    filled identity survives in DEST: 0; PROJECT_NAME still in DEST: 2
> d3-fill-rm-ruler    customization-detected-needs-reconciliation   (same L-8)   DEST: 0 / 2
> d3-fill-rm-both     customization-detected-needs-reconciliation   (same L-8)   DEST: 0 / 2
> d3-fill-in-marker   customization-detected-needs-reconciliation
>    notes=marker well-formedness failure (L-6/L-1): project-owned marker region beginning at
>          line 26 has no enclosing H2 heading (it sits in the preamble, above the first H2) …
>    filled identity survives in DEST: 0; PROJECT_NAME still in DEST: 2
> ```
> Regime A (BASE = the canonical the client installed) returns the identical
> four dispositions and messages.
> Interpretation: the client's report is reproduced exactly. The additional
> measured fact is `PROJECT_NAME still in DEST: 2` on every failing run — the
> harm is not merely a sidecar; the **live** context file every agent reads is
> reset to the placeholder-bearing canonical. **SUPPORTED.**

> **EEB-8 — "or delete section" is silently undone.**
> Command: `bash h/run_optional.sh`, pristine clone, Regime B, controls PASS, 2026-09-03.
> Output:
> ```
> shipped OPTIONAL: markers in CLAUDE.md — lines 60, 83, 88, 93, 351 (5 sections)
> delete-section     merged-with-customization
>    section back in DEST (1 = silently restored): 1 ; pack GRPC_RULES body back in DEST: 1
> suppress-section   merged-with-customization
>    override body in DEST: 1 ; pack GRPC_RULES body in DEST: 0
> ```
> Interpretation: a client who follows the shipped `delete the entire section`
> instruction gets a CLEAN disposition and their deletion reverted with no
> message; the engine's sanctioned path is a same-name Shape B override, which
> works. This leg is worse than (a)–(c) because it never surfaces. **SUPPORTED.**

> **EXTENDED — see §9 item 3.** Leg (d) has a THIRD outcome. Deleting the
> `<!-- OPTIONAL: … -->` comment along with the heading and body — the literal
> reading of *"delete the entire section"* — returns
> `customization-detected-needs-reconciliation` naming the **preceding**
> section, because the comment sits above its heading and is therefore
> lexically the last body line of the section before it.

> **EEB-9 — measure-then-bound census of the client-editable content, from
> git-tracked files.**
> Command: `python3 h/census_guard.py …/pack` — candidate set from
> `git ls-files project-template/{CLAUDE,AGENTS,GEMINI}.md` (3 files), 2026-09-03.
> Output: 18 occurrences per file, 54 total.
> `placeholders OUT-OF-MARKER (the STRIP set): 30`;
> `placeholders IN-MARKER (the KEEP set): 0`;
> `remove/delete instructions: 24`.
> Per file the STRIP set is L9 (inside the how-to comment), L26/L27 identity,
> and L58/L86/L91/L96/L104/L168/L365 in-section (CLAUDE.md line numbers).
> Interpretation: the legitimate (KEEP) set is **EMPTY**, so any guard built on
> this census carries an **empty allowlist** — exactly sized, with nothing to
> grow. **SUPPORTED.**

> **EEB-10 — the pack's own reference "correctly prepped v11 trinity" fails the
> pack's own Regime-B gate against the shipped canonical, on the preamble.**
> Command: `bash h/run_fixture.sh`, pristine clone, controls PASS, 2026-09-03.
> Output:
> ```
> prepped-CLAUDE  customization-detected-needs-reconciliation
> prepped-AGENTS  customization-detected-needs-reconciliation
> prepped-GEMINI  customization-detected-needs-reconciliation
>    notes=pack-owned preamble diverges (out-of-marker) — … (L-8)   [all three]
> fixture CLAUDE.md preamble: "# CLAUDE.md"
> canonical CLAUDE.md preamble first 3: "# CLAUDE.md", "", "<!--"
> ```
> **Scope note (stated to avoid over-claiming):** this is NOT a currently-failing
> test. `scripts/tests/fixture-dependent/test-customization-preserve-bd136.sh`
> M-8 synthesises THEIRS *from OURS* ("a drift-free 'new pack canonical' stand-in
> … so it tracks the static fixture"), so it never compares the fixture against
> the live canonical. That synthesis is precisely why the battery is green.
> Interpretation: the pack's own hand-authored idea of a correct client trinity
> has a **bare preamble** — no how-to block, no banner block, no identity line —
> and its README records that the preamble marker was rejected so the intro was
> relocated to a `### Repository overview` H3 inside the addenda seed. The pack
> already worked around D3 for its own fixture rather than fixing the template.
> **SUPPORTED.**

### 3.2 The blast-radius question, and a base rate that reframes it

The instinctive objection to any template option is "changing the shipped
preamble sidecars every existing install." Measured, that is true — and it is
equally true of changing **any** shipped trinity line, so it does not
discriminate between the options.

> **EEB-11 — base rate: any trinity content change sidecars an existing
> untouched v11 client on `--update`; none of them do in a migration.**
> Command: `bash h/run_baserate.sh` — OURS = today's shipped canonical
> (an untouched client), THEIRS = the same canonical with one line changed,
> once in a section body and once in the preamble; controls PASS, 2026-09-03.
> Output:
> ```
> Regime B (--update):
>   vnext-SECTION-edit    customization-detected-needs-reconciliation
>      notes=pack-owned body outside your markers under '## Refactoring policy' diverges … (L-2/L-8/B1)
>   vnext-PREAMBLE-edit   customization-detected-needs-reconciliation
>      notes=pack-owned preamble diverges (out-of-marker) … (L-8)
> Regime A (migrator, BASE present):
>   regimeA-vnext-SECTION-edit    merged-with-customization
>   regimeA-vnext-PREAMBLE-edit   merged-with-customization
> ```
> Interpretation: on the empty-BASE `--update` path the engine cannot attribute a
> divergence, so a pack-authored edit and a client-authored edit are
> indistinguishable and both sidecar. Preamble edits cost exactly what section
> edits cost. The "existing installs" axis therefore does **not** separate the D3
> options; what separates them is (i) whether an engine change is required and
> (ii) whether the second parser must change too. **SUPPORTED.**

> **PARTLY SUPERSEDED — see §9 item 1.** The measurement stands as taken. The
> inference drawn from it in OI-5 — that this is *"a standing cost on every
> future v11.x content release"* — does not: at `b40f111` the empty-BASE (R3')
> row is reachable only by a client carrying no rung-R1 ledger on any of the
> three consulted paths, which is neither a migrated nor a freshly-installed
> client.

Two further population facts bound the real cost. First, v11.0 is unlaunched, so
the existing-v11-install population is the reporting client, who has already
elected to revert and re-migrate. Second, and independently of that, **no D3
option repairs an already-migrated client automatically** — their filled-in
content is genuinely theirs and no classification can absorb it — so the
one-time remediation recipe that BD-294 requires is a deliverable under every
option, not a differentiator.

### 3.3 Options, each measured on existing installs

| Option | What ships | Compliant NEW client | Client who also deletes the how-to/banner blocks | Existing untouched v11 client (`--update`) | Already-migrated client who filled | v10 client migrating (Regime A) | Engine change | Second parser | Battery |
|---|---|---|---|---|---|---|---|---|---|
| **A — preamble marker-eligible (new "Shape P")** | engine admits + grafts a preamble region **and** the template ships a preamble seed pair | `merged-with-customization`, identity preserved (EEB-13) | **still sidecars** | sidecar (base rate) | sidecar → needs the recipe | filled v10 preamble → sidecar | **yes** — new shape, new graft branch, reverses the M-19 fail-loud | **yes** — `trinity_markers.py` errors `nohost` on the shipped file, a hard CI failure (EEB-13) | would need M-19 rewritten |
| **B — relocate into shipped seed pairs (template only)** *(recommended)* | identity moves into a first `## Project identity` section inside a shipped seed pair; the 7 in-section placeholders each get a shipped seed pair; the how-to block and the banner block are **not shipped**; the 5 delete-the-section instructions are replaced by the suppress form | `merged-with-customization`, all 8 filled values preserved, **0 residual placeholders** (EEB-12) | nothing left to delete | sidecar (base rate) | sidecar → **recipe proven** to reach clean + idempotent (EEB-12) | filled v10 preamble → sidecar, identical to today (EEB-14) | **none** | **none** | 419 assertions + `validate-pack.py` green **unmodified** (EEB-12) |
| **C — teach the graft that placeholder substitution is expected divergence** | engine masks `[TOKEN]` positions when comparing preambles/bodies | would cover leg (a) and (c) only | **no** — a deleted block has nothing to match | sidecar (base rate) | would self-repair leg (a) with no client edit — its one genuine advantage | unchanged | **yes**, and it makes those lines BASE-**independent**, contradicting the engine's own stated invariant (`marker-preserve.sh` header: *"a BASE-PREFERRED, degrade-SAFE merge — never 'BASE-independent'"*) | yes | M-16's discrimination leg is at risk |
| **D — do nothing; document the contradiction** | a note in the skill | client must accept a permanent sidecar or ship `[PROJECT_NAME]` to every agent | no | sidecar (base rate) | no change | no change | none | none | green |

> **EEB-12 — Option B measured end to end, including the remediation recipe.**
> Commands, 2026-09-03: `h/build_optB.py …/eng-optB` (all anchors asserted
> present-before / gone-after, incl. "the preamble now contains no comment"),
> committed in scratch as `1d58b3a` —
> `project-template/AGENTS.md | 34 +-`, `CLAUDE.md | 36 +-`, `GEMINI.md | 32 +-`,
> **51 insertions / 51 deletions across 3 files**; resulting preambles
> `'# CLAUDE.md'`, `'# AGENTS.md'`, `'# GEMINI.md'`; 7 in-section placeholders
> wrapped per file. Then `bash h/run_regress.sh …/eng-optB` and
> `bash h/run_optB_e2e.sh` (controls PASS).
> Battery on the transformed tree: `68 passed 0 failed`, `Passed: 310 Failed: 0`,
> `19 passed 0 failed`, `22 passed 0 failed`, Check-91 pass, Check-19 pass,
> `13 passed 0 failed`, `validate-pack.py exit=0 PASSED — all checks clean`
> — **with no test or check modified**.
> Client scenarios:
> ```
> B-compliant-filled             merged-with-customization
>    'Acme Ledger' in DEST: 1 ; FILLED-* in DEST: 7 ; residual placeholders: 0
> B-compliant-filled-nogrpc      merged-with-customization
>    gRPC section present in DEST (deletion sticks? 0 = sticks): 1
> B-already-migrated-today       customization-detected-needs-reconciliation  (L-8 preamble)
>    'Acme Ledger' survives in the LIVE file: 0 ; sidecar written: yes
> B-already-migrated-remediated  merged-with-customization
>    'Acme Ledger' survives in the LIVE file: 1
> B-remediated-idem              merged-with-customization
> ```
> Interpretation: a client who obeys the new template grafts cleanly with every
> filled value preserved and zero placeholders left behind; an already-migrated
> client still sidecars until remediated, and the remediation reaches a clean,
> idempotent graft. Note the third row: template relocation alone does **not**
> make a section deletion stick — leg (d) needs the instruction reworded, which
> is why the reword is part of Option B and not an optional extra.
> **SUPPORTED.** (The `## Project identity` H2 name is my construction, not a
> user decision — see Open item OI-2.)

> **EEB-13 — Option A needs a template change too, and breaks Check 91.**
> Commands: `h/patch_engine.py … d5-fix+d3a` (4 anchors asserted) → `eng-d5d3a`;
> `bash h/run_d3a.sh`; `bash h/run_d3a2.sh`. Controls PASS on both, 2026-09-03.
> First result — engine change **alone** (client wraps the identity in a preamble
> marker pair against today's canonical): `A-fill-in-marker →
> customization-detected-needs-reconciliation`, `notes=pack-owned preamble
> diverges (out-of-marker) … (L-8)`, `filled identity in DEST: 0`. Cause: the
> stripped OURS preamble loses the identity lines while the stripped THEIRS
> preamble still has them, so the compare mismatches.
> Second result — engine change **plus** a shipped preamble seed pair:
> `A2-client-filled → merged-with-customization`, identity preserved (`1`);
> `A2-client-filled-rmblocks → customization-detected-needs-reconciliation` (L-8);
> `A2-existing-untouched-v11 → …needs-reconciliation` (base rate);
> `A2-existing-untouched-regimeA → merged-with-customization`.
> Third result — Check 91 on the Option-A canonical:
> `Check-91 parser errors: [('nohost', 'project-owned marker region beginning at line 26 has no enclosing H2 heading …')]`.
> Interpretation: Option A is *not* the engine-only option it appears to be — it
> needs the same template edit as Option B, plus an engine change, plus a
> matching Python change, plus rewriting the M-19 fail-loud test. On every
> client-facing axis it measures **identically** to Option B. **SUPPORTED.**

> **EEB-14 — the v10 migration leg is unchanged by Option B.**
> Command: `bash h/run_v10leg.sh` with BASE read from the real tag
> (`git show v10:project-template/CLAUDE.md`, 389 lines; its preamble carries the
> same how-to block, banner block and `[PROJECT_NAME]` identity line), controls
> PASS, 2026-09-03.
> Output:
> ```
> against the Option-B canonical:      v10-untouched-preamble  pack-update-applied
>                                      v10-FILLED-preamble     customization-detected-needs-reconciliation
> against TODAY'S shipped canonical:   today-v10-untouched     pack-update-applied
>                                      today-v10-FILLED        customization-detected-needs-reconciliation
> ```
> Interpretation: identical in both columns, so Option B neither helps nor harms
> the v10 path (a v10 trinity has zero marker tokens, so it takes the markerless
> legacy fallback and never reaches the marker graft). A v10 client who filled
> their v10 preamble still reconciles by hand — which is what
> `PRE-RECONCILE-v10-to-v11.md` §(c) already tells them to do; that doc needs the
> new destination named, not a new rule. **SUPPORTED.**

### 3.4 Recommendation — D3

**Adopt Option B, in all four legs, as one change.**

Evidence, in order of weight:

1. **Options A and B are client-identical.** EEB-12 and EEB-13 measure the same
   dispositions on every scenario. Option A additionally requires an engine
   change, a matching change to the second parser, the reversal of a pinned
   fail-loud gate (M-19), and it introduces a **third shape** into a parser
   whose one existing special case is the direct cause of D5. Fewer conventions
   and fewer special cases decide a tie; here the tie is measured, not asserted.
2. **Option B needs no CI accommodation.** The full transformed tree passes 419
   assertions and `validate-pack.py` with **no test and no check modified**
   (EEB-12). Option A fails Check 91 on the shipped file before any test is
   written (EEB-13).
3. **Option C cannot reach legs (b) and (d)** — there is no token to mask in a
   deleted block or a deleted section — and it would make the engine
   BASE-independent for the lines it masks, which the engine's own header
   forbids in as many words. Its one real advantage (self-repairing leg (a) for
   an already-migrated client with no client edit) is worth stating plainly, and
   is the strongest argument anyone can make for it; it is outweighed because it
   leaves three of four legs live and the recipe still has to ship.
4. **Option D leaves a launch-gating contradiction shipped.** Every new client
   hits it on day one, and both ways of complying are defects.

The four legs must land together. EEB-12 row 2 is the proof: relocating the
identity while leaving `delete the entire section` in place still yields a
silent revert. A partial Option B is a partial fix.

**The remediation recipe** (a BD-294 acceptance criterion) is: for each of the
three files, (1) copy the new pack canonical over the file, (2) paste the
project's previously filled values into the shipped seed pairs — identity into
`## Project identity`, each of the 7 in-section values into its own pair, (3) for
each optional section the project deleted, wrap the heading and a one-line body
in a same-name Shape B pair instead of deleting it, (4) verify by running the
`resolve-merge-conflicts` Case-3 gate and requiring `merged-with-customization`.
Proven end to end in EEB-12 (`B-already-migrated-remediated` → clean,
`B-remediated-idem` → clean). Its home is
`supporting-docs/MIGRATION-v10-to-v11.md` (1098 lines) per BD-294's File/Symbol
line; `supporting-docs/` is a client/public surface, so the recipe is a shipped
client deliverable and no pack-side mechanism is imported into it.

### 3.5 The coverage that would have caught D3

Nothing in the pack asserts that the shipped template's own instructions can be
obeyed. EEB-12 proves the gap is total: the entire Option-B transformation
passes the unmodified battery, so the battery is equally blind to the broken and
the fixed template.

**T-1 — obey-the-template round-trip (new test file,
`scripts/tests/test-trinity-template-obeyable.sh`).** For each of the three
tracked trinity files: read the shipped canonical; mechanically apply the
template's own instructions — substitute every `^\[[A-Z_]{3,}` placeholder line
and every `[PROJECT_NAME]`/`[PLATFORM_TARGETS]`/`[TRANSPORT]` token with a
sentinel value, and delete every block the file says to delete; feed the result
through `marker_preserve_trinity "" <filled> <canonical>` with an empty BASE;
assert the disposition is `merged-with-customization`, assert **every sentinel
value is present in DEST**, and assert **no `[A-Z_]{3,}` placeholder token
remains in DEST**. Reds today on all three files (EEB-7); greens under Option B
(EEB-12). This is the leg that closes the family, because it derives its input
from the shipped file rather than from a hand-written fixture — it cannot drift
away from what actually ships.

**T-2 — optional-section suppression round-trip.** For one shipped
`OPTIONAL:`-marked section: (a) a same-name Shape B override must yield
`merged-with-customization` **and** the pack body must be absent from DEST;
(b) a raw deletion must **not** yield a clean disposition that silently restores
the section — after the reword this is the assertion that the instruction and
the engine agree. Reds today (EEB-8 shows the raw deletion returning
`merged-with-customization` with the section restored).

**T-3 — validate-pack guard: shipped client-editable content must be
marker-backed.** A new check over the **git-tracked** trinity files only
(`git ls-files project-template/{CLAUDE,AGENTS,GEMINI}.md` — never a filesystem
walk): for each file, single pass over lines, tracking marker depth; FAIL on any
line matching `\[[A-Z][A-Z_]{2,}` that is **outside** a project-owned marker
pair, and FAIL on any line matching the remove/delete instruction vocabulary.
Cost is O(lines) over 3 files, ~1600 lines total, no subprocess, no tree walk —
which satisfies the per-invocation budget. Allowlist: **empty**, sized exactly
to the measured legitimate set (EEB-9: KEEP set = 0 of 54 occurrences), and it
must stay empty. The guard must also catch the **absence-of-backing** case, not
only the presence case: a placeholder whose enclosing marker pair was deleted
while the placeholder stayed must FAIL — assert that by mutating a fixture to
remove one `<!-- END project-owned -->` pair around a placeholder and requiring
the check to fail, not merely by checking that pairs exist somewhere in the file.

**The mutations that must red.**

| Mutation | Must red |
|---|---|
| Revert the three templates to HEAD | T-1 (all three files), T-3 (30 placeholder + 24 instruction findings) |
| Relocate the identity but leave the how-to/banner blocks shipped | T-1 (the delete step diverges the preamble) |
| Relocate the identity but leave `delete the entire section` in the OPTIONAL comments | T-2 |
| Ship a placeholder line whose enclosing seed pair was removed | T-3 absence-of-backing leg |
| Add any entry to the T-3 allowlist | a fixed-`0` assertion on the allowlist length |

### 3.6 Implementation sizing — D3

| Surface | Change | Measured / estimated |
|---|---|---|
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` | delete 2 preamble blocks; add `## Project identity` + seed pair; wrap 7 in-section placeholders per file | **+51 / −51 across 3 files** (measured, scratch commit `1d58b3a`) — plus the reword of 5 `OPTIONAL:` comments and the `[GRPC_RULES … or delete section]` line per file, ~18 more lines per file |
| `supporting-docs/MIGRATION-v10-to-v11.md` (1098 lines) | the one-time in-place remediation recipe | ~70–100 lines added |
| `supporting-docs/INSTALL-PROCEDURES.md` (1390 lines) | 5-C.2 (`:479–:500`) and the 5-C.5-style repeat (`:628–:656`): the "remove the how-to block" and "remove the banner" steps become obsolete; the placeholder step points at the seed pairs | ~15–25 lines changed |
| `supporting-docs/PRE-RECONCILE-v10-to-v11.md` (298 lines) | §(c) keeps its rule and gains the new destination; §(d) pitfall list gains the nested-marker case (EEB-15) | ~10 lines |
| `project-template/skills/resolve-merge-conflicts/SKILL.md` (287 lines) | name the shipped seed pairs as the place filled values live; name the suppress-not-delete rule | ~8 lines |
| `scripts/lib/validate_checks/` + `scripts/validate-pack.py` | the T-3 check + registration | ~60–80 lines |
| `scripts/tests/` | T-1 (new file), T-2, T-3's own test | ~200–260 lines |
| `test-fixtures/manifest.txt` | regenerated at **push** by `scripts/manifest-sync.sh` if a fixture input changed — not a per-commit chore | n/a |

> **SUPERSEDED — see §9 item 5.** At `b40f111`
> `supporting-docs/MIGRATION-v10-to-v11.md` is **1127** lines, not 1098. The
> other lengths in this table re-measure unchanged (`INSTALL-PROCEDURES.md`
> 1390, `PRE-RECONCILE-v10-to-v11.md` 298, `SKILL.md` 287).

**Verdict: coder-level for the mechanical transformation and the tests; one
user decision first.** The transformation, the CI outcome, and the client
outcome are all measured. What is not mine to settle is the *wording and naming*
of client-facing instructions — the new section's name, and the replacement text
for the five `OPTIONAL:` comments — because those are the sentences every future
client reads. Those go to the user at the design review (OI-2, OI-3), then the
coder applies mechanically.

---

## 4. Does D3's fix change D5's behaviour, or vice versa?

**No, and it was measured rather than reasoned.** They touch the same engine but
disjoint code paths: D5 is `_mp_regions`' shape classification; D3 (as
recommended) touches no engine code at all — only the shipped template and its
documentation.

> **EEB-15 — the two fixes compose; and Option B creates exactly one new
> (loud, safe) interaction.**
> Command: `bash h/run_interaction.sh` — engine = `eng-optB` (the D5 engine fix
> **and** the Option-B template), D5 fixtures rebuilt from the **new** canonical
> so their multisets are re-verified (`GROUP-IDENTICAL: True` for both groups);
> controls PASS, 2026-09-03.
> Output:
> ```
> s1-at-position  merged-with-customization      s2-mid-file  merged-with-customization
> s1-mid-file     merged-with-customization      s2-at-eof    merged-with-customization
> s1-at-eof       merged-with-customization      vC-seed-h3   merged-with-customization
>
> ovr-nested   customization-detected-needs-reconciliation
>    notes=marker well-formedness failure (L-6/L-1): nested BEGIN marker at line 87
>          (region still open from line 84)
> ovr-clean    merged-with-customization
>    override body in DEST: 1 ; pack GRPC_RULES body in DEST: 0
> ```
> Interpretation: every D5 leg stays fixed on the D3 canonical, and the sanctioned
> seed case stays clean, so neither fix un-fixes the other. The one new
> interaction: because Option B now ships a seed pair *inside* several sections,
> a client who wraps such a whole section in a Shape B pair **without replacing
> its body** nests the shipped pair and gets an L-6 fail-loud. That is loud and
> safe, the correct path (`ovr-clean`, replace the body) works, and it needs one
> sentence in the skill and in `PRE-RECONCILE` §(d)'s pitfall list.
> **SUPPORTED.**

Ordering: either fix can land first. Landing D5 first is marginally preferable
because it is small, self-contained, and lets the D3 template work be validated
against an engine that already classifies correctly (EEB-15 was run in exactly
that order). If only one can land, D3 is the launch gate — every new client hits
it on day one; D5 needs the client to have folded markers at EOF first.

---

## 5. Cross-BD design-time collision scan

> **EEB-16 — collision scan across every open pack BD.**
> Command: `bash h/crossbd.sh` — open set read from `backlog/_toc.md` §Open
> (19 entries: BD-020, 036, 037, 039, 109, 110, 171, 172, 187, 192, 202, 223,
> 247, 254, 279, 289, 292, 293, 294), intersected against BD-294's structured
> blast-radius path set (15 paths: the 3 templates, `marker-preserve.sh`,
> `trinity_markers.py`, `resolve-merge-conflicts/SKILL.md`,
> `MIGRATION-v10-to-v11.md`, `PRE-RECONCILE-v10-to-v11.md`,
> `INSTALL-PROCEDURES.md`, `MERGE-STRATEGY.md`,
> `test-fixtures/v11-trinity-marker-prepped`, `test-marker-preserve-bd136.sh`,
> `customization-preserve.sh`, `init-project.sh`, `migrate-v10-to-v11.sh`),
> 2026-09-03.
> Output: `BD-020 … BD-292 none` (17 entries), then
> `BD-293 COLLISION: scripts/lib/customization-preserve.sh scripts/init-project.sh scripts/migrate-v10-to-v11.sh`
> and `BD-294 COLLISION: …` (itself).
> A first run mis-parsed the BD ids (doubling digits) and printed
> `(missing …/BD-20020.md)` for all 19 — the failure was loud, the parse was
> fixed, and the corrected run is the one reported.
> Interpretation: exactly **one** real collision, with BD-293 (Status: Open,
> Target: v11.0), on three files. **None of the three is in BD-294's recommended
> edit set** — the recommendation touches `marker-preserve.sh` (BD-294's) and
> `trinity_markers.py`, not `customization-preserve.sh`; and it touches no
> installer or migrator script. This is a COORDINATE signal, not a gate: both
> entries land in v11.0 and neither co-edits a file with the other, so they can
> proceed in parallel worktree waves with no serialisation constraint. The one
> thing to coordinate is prose: both entries will add material to
> `supporting-docs/MIGRATION-v10-to-v11.md` (BD-293 for its `--update`
> remediation, BD-294 for its trinity remediation) — sequence those two commits
> rather than running them in the same wave. **SUPPORTED.**

Discovery for this scan was graph-first: `graphify query "marker-preserve trinity
graft engine seed slot Project addenda preamble" --graph
/Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json
--backend claude-cli --budget 1500` returned 619 nodes and surfaced two surfaces
grep had not: `test-fixtures/v11-trinity-marker-prepped/` (which produced EEB-10)
and `pack-ops/MERGE-STRATEGY.md` (which carries the Shape A/B contract prose at
`:200–:206` and is in the edit set as a result). Verification of every named
surface was then done by Read/grep.

> **SUPERSEDED — see §9 item 2.** EEB-16's scan intersected a **15-path** blast
> radius that omitted every check-wiring surface BD-294's own T-3 recommendation
> must edit, so it scored BD-289 `none`. Re-run against the corrected **22-path**
> set, **BD-289 collides on five paths** and the coordination it forces is
> specific (see §9 item 2). The `:200–:206` anchor in the paragraph above is
> **not** superseded — re-measured at `b40f111` it still resolves (Shape A at
> `:200`, Shape B at `:204`); cite it durably as § "The 11 file classes" →
> `### 1. trinity`, which is a citation-style improvement, not a correction
> (§9 item 5).

---

## 6. Open items

Each carries context, my own options, and an evidence- or logic-based
recommendation. None defers work to a later BD or a later version; every item
below is scoped to land inside BD-294 in v11.0.

**OI-1 — the seed-slot test is a prefix regex, not an exact match.**
*Context.* Both parsers test `beginh2 ~ /^## Project addenda/` (bash) and
`region["beginh2"].startswith(_ADDENDA_H2)` (python). A client section named
`## Project addenda notes` would silently inherit the exception. Measured: the
shipped trinity contains exactly one `## Project addenda` H2 per file and no
other heading with that prefix, so the legitimate set is a single exact string.
*Options.* (a) tighten both to an exact trimmed compare in the same commit as
the D5 fix; (b) leave the prefix form; (c) tighten and add a test.
*Recommendation.* **(c).** The exception is a special case that has already
produced one defect; sizing it exactly to the measured legitimate set is the
`measure-then-bound` discipline applied to the thing that failed it. It is a
two-token change inside code the D5 fix is already editing, so it costs nothing
extra to review, and M-22 can carry a `## Project addenda notes` leg asserting
the ordinary rule applies there.

**OI-2 — the new section's name is a user decision, not mine.**
*Context.* Option B needs the identity lines under some H2. I measured
`## Project identity` as the first H2; validate-pack and all 419 assertions pass
with it (EEB-12). But this string becomes the first heading every agent reads in
every v11 client's context file, forever.
*Options.* (a) `## Project identity` as a new first section; (b) put the identity
inside the existing first section `## Quick reference`, adding no H2 at all;
(c) put it inside `## Project rules` (an existing section, but it is not first,
so the identity would no longer lead the file).
*Recommendation.* **(a), with (b) as the cheaper alternative if the user prefers
not to add an H2.** Evidence for (a): the trinity already names sections
`## Project rules` and `## Project addenda`, so `## Project identity` is
consistent, and it keeps the identity as the first thing read — which is the
whole point of the line. Evidence that (b) is safe: (b) is strictly less invasive
than the variant I measured (it changes no H2 list at all), so the clean CI
result in EEB-12 holds a fortiori. I have no evidence that separates them on
client outcome; both were measured or bounded as clean, so this is a naming
judgement and it is the user's.

**OI-3 — the replacement wording for the five `OPTIONAL: … delete the entire
section` comments.**
*Context.* EEB-8 shows the deletion is silently reverted and that a same-name
Shape B override is the path the engine honours. The comments must therefore
stop saying "delete"; what they should say instead is client-facing prose in
15 places (5 per file × 3).
*Options.* (a) replace "delete the entire section if not applicable" with
"if not applicable, replace the body with a one-line note inside a
`<!-- BEGIN project-owned -->` … `<!-- END project-owned -->` pair that wraps
this heading"; (b) shorter: "if not applicable, see `resolve-merge-conflicts`
→ suppressing a pack section" (a pointer, not a recipe); (c) make the engine
honour deletion — i.e. treat an OURS-absent THEIRS section as intentionally
removed.
*Recommendation.* **(a).** (c) is rejected on evidence: the engine cannot
distinguish "the client deleted this" from "the client is on an older canonical
that never had it", so honouring absence would silently drop every newly added
pack section for every client on `--update` — a far worse failure than the one
being fixed, and it contradicts the whole-file THEIRS-spine design recorded in
the `marker-preserve.sh` header. Between (a) and (b), (a) is self-contained: the
comment sits in the file the client is editing, and (b) costs a document hop at
exactly the moment the client is deciding. The exact sentence is the user's to
approve.

> **SUPERSEDED — see §9 item 4.** Measured against the user's stated frequency
> rule, suppressing an optional trinity section is a **one-time, setup-only**
> act, which selects option **(b), the pointer** — not (a). The pointer target
> is `project-template/docs/pack/PM-CHAT.md` § "How to add project-owned content
> to trinity files", which is already the pack's shipped convention for this
> exact concept.

**OI-4 — the how-to guidance has to go somewhere when the block stops
shipping.**
*Context.* Option B stops shipping the `<!-- HOW TO USE THIS TEMPLATE -->`
block, which carries genuine setup guidance ("fill in the Platform and Stack
Defaults section", "fill in or remove the optional sections"). Measured:
`supporting-docs/INSTALL-PROCEDURES.md` already carries the same guidance at
`:484` and `:631`, and Check 19 *allows* the block but does not *require* it, so
removing it breaks no gate (EEB-12).
*Options.* (a) delete the block; the guidance lives in INSTALL-PROCEDURES.md and
in the seed pairs' own inline hints; (b) keep the block but delete only the
sentence instructing its removal; (c) move the block's content into the
`## Project identity` section body inside the seed pair.
*Recommendation.* **(a).** (b) leaves an install-time HTML comment permanently
in a runtime context file that every agent parses at every session start — noise
the pack's own Check 19 docstring calls "fresh-install scaffolding" that
"create[s] persistent clutter". (c) puts install instructions inside content the
client owns, so they would survive forever and the pack could never update them.
(a) is also what the pack's own reference fixture already does: its preamble is
exactly `# CLAUDE.md` (EEB-10).

**OI-5 — the `--update` path cannot attribute a divergence, so every pack
trinity edit costs every client a sidecar.**
*Context.* EEB-11 measured this as the base rate: on the empty-BASE path a
pack-authored line change and a client-authored line change are indistinguishable
and both sidecar; the same inputs in Regime A graft cleanly. It is why the D3
blast-radius question does not discriminate between options — and it is a
standing cost on every future v11.x content release.
*Options.* (a) record it here as measured context for the D3 decision and change
nothing — it is out of BD-294's scope, which is the contract collision and the
placement defect; (b) have `--update` stash the canonical it installed as a
`.pack-base` sidecar so the next `--update` has a real BASE and can attribute;
(c) treat it as a documentation problem and state the expectation in the update
guide.
*Recommendation.* **(a) for BD-294, and surface (b) to the user now as its own
decision.** Evidence for keeping it out of BD-294: the collision scan (EEB-16)
shows `init-project.sh cmd_update` is BD-293's surface, not BD-294's, and
BD-293's Position line already names the `--update`-from-a-migrated-baseline
question as its **first** measurement — so the machinery for (b) is being
measured there, by that entry, in this same version. Folding it into BD-294
would put two entries into the same file for no gain. This is not a deferral:
the work is already scheduled in v11.0 under an open entry whose own acceptance
criteria cover it. If the user judges otherwise, (b) belongs in BD-293, not in a
new entry.

> **SUPERSEDED — see §9 item 1.** BD-293 landed the machinery in the interim, so
> option (b) is not open work anywhere: `--update` now resolves a real BASE
> through a four-rung cascade and **both** entry paths originate the rung-R1
> ledger. There is no residual item to route — to BD-293, to BD-294, or to a new
> entry.

**OI-6 — `_mp_h2_list` is not marker-aware, which is what turns a
misclassification into a misdiagnosis.**
*Context.* The reason a misclassified Shape B region produces "*pack section
'<your heading>' … is absent from the new canonical*" is that `_mp_h2_list`
(`marker-preserve.sh:226`) counts every `^## ` line including ones inside marker
regions. The D5 fix removes the misclassification, so the wrong message stops
firing for this cause — but the underlying weakness remains: any future
classification bug will again surface as a message blaming a pack section.
*Options.* (a) leave it — the D5 fix removes the only known trigger;
(b) make Step 6's OURS-head loop skip heads that fall inside any region
(Shape A or B), so a marker-enclosed heading can never be adjudicated as a pack
section; (c) improve only the message text.
*Recommendation.* **(b), in the same commit as the D5 fix.** Evidence: EEB-2
shows the message named the client's own brand-new heading a "pack section" —
the single most confusing artefact in the whole defect report, and the reason
the reporting client's diagnosis pointed at the wrong file region. (a) leaves a
message that is wrong-by-construction one bug away from reappearing; (c) treats
the symptom. (b) is a containment fix of a few lines in a loop the D5 work is
already reading, and M-21 already exercises the path, so it costs one extra
assertion (`the notes field must not name a project-owned heading`) rather than
a new test.

**OI-7 — should the guard in T-3 be a validate-pack check or only a test?**
*Context.* T-3 is the standing guard that keeps a future editor from
re-introducing an un-marker-backed placeholder. Its census is 3 files, ~1600
lines, empty allowlist (EEB-9).
*Options.* (a) a validate-pack check (runs on every push, catches the
reintroduction at the moment it is authored); (b) a test only; (c) both.
*Recommendation.* **(a).** The cost is a single pass over three git-tracked
files with no subprocess and no tree walk, which is well inside the
per-invocation budget the pack requires of a check that runs many times per
battery cycle; and the failure mode it prevents — a shipped instruction the
engine cannot honour — is exactly the class the reporting client hit. A test
alone would only fire when someone thought to run it. T-1 stays a test because
it needs to source the engine and round-trip a merge, which is test-shaped work,
not check-shaped work.

**OI-8 — the reference fixture's preamble and the shipped canonical's preamble
disagree, and the M-8 test hides it by synthesising THEIRS.**
*Context.* EEB-10: `test-fixtures/v11-trinity-marker-prepped/` has a bare
`# CLAUDE.md` preamble and sidecars against the live canonical on all three
files; M-8 never notices because it builds THEIRS from OURS.
*Options.* (a) after Option B lands, the shipped preamble becomes bare too and
the disagreement disappears on its own — verify that and add the assertion;
(b) change M-8 to use the live canonical as THEIRS; (c) leave M-8 alone.
*Recommendation.* **(a), with the verification made explicit.** Option B makes
the shipped preamble `# CLAUDE.md` (measured, EEB-12), which is byte-identical to
the fixture's, so the divergence resolves as a consequence of the fix rather than
needing its own change. Add one assertion to the D3 work: the shipped trinity's
preamble equals the fixture's preamble for each of the three files. (b) is
rejected because M-8's synthesis exists on purpose — it isolates the marker
round-trip from canonical drift — and coupling it to the live canonical would
make an unrelated template edit fail a marker test. (c) is rejected because the
divergence is exactly the kind of silent mismatch that produced this BD.

---

## 7. Rules-Applied Verification Block

| Rule | Verification evidence (quoted, not summarised) | Conclusion |
|---|---|---|
| `empirical-evidence-blocks` | 16 Empirical-Evidence Blocks (EEB-1…EEB-16), each carrying the exact command, captured output, HEAD `91712431ad4b566cff2d3f7717ce70d4d1e0abbf`, date 2026-09-03, interpretation, and a SUPPORTED / NOT-SUPPORTED verdict. Example verdict quoted: EEB-3 concludes `**NOT-SUPPORTED** (the inherited claim)`. Every state-claim in §2 and §3 traces to a numbered block. | COMPLIANT |
| `ci-guard-measure-then-bound` | EEB-9 ran the guard's matching logic against the real tree first: candidate set from `git ls-files project-template/{CLAUDE,AGENTS,GEMINI}.md` (3 files, no filesystem walk); every occurrence categorised — `placeholders OUT-OF-MARKER (the STRIP set): 30`, `placeholders IN-MARKER (the KEEP set): 0`, `remove/delete instructions: 24`; allowlist sized to the KEEP set = **empty**; §3.5 T-3 specifies the absence-of-backing leg ("a placeholder whose enclosing marker pair was deleted while the placeholder stayed must FAIL … not merely by checking that pairs exist somewhere"); §3.5 verifies the guard runs clean against the projected post-fix state via EEB-12 (`validate-pack.py exit=0 PASSED — all checks clean` on the transformed tree). | COMPLIANT |
| `ci-check-runtime-compounding` | §3.5 T-3: "single pass over lines … over the **git-tracked** trinity files only … 3 files, ~1600 lines total, no subprocess, no tree walk". OI-7 restates the budget as the reason the check form is chosen. | COMPLIANT |
| `cross-bd-collision-scan` | EEB-16: 19 open BDs read from `backlog/_toc.md` §Open, intersected against BD-294's 15 structured blast-radius paths (not a free-text field). Result quoted: 17 × `none`; `BD-293 COLLISION: scripts/lib/customization-preserve.sh scripts/init-project.sh scripts/migrate-v10-to-v11.sh`; `BD-294 COLLISION` (itself). Recorded as a COORDINATE signal with the specific coordination named (sequence the two `MIGRATION-v10-to-v11.md` commits). A mis-parse in the first run is disclosed rather than hidden. | COMPLIANT |
| `design-discipline-challenge` | Each of my own triage decisions was challenged by measurement, not pattern-match: the inherited "naive reorder breaks vC" claim was tested and returned NOT-SUPPORTED (EEB-3); the intuitive "Option A is the engine-only option" was tested and returned false (EEB-13); the intuitive "changing the preamble is uniquely costly" was tested against a base rate and returned false (EEB-11); "delete the exception" was tested and returned a measured regression (EEB-5). Option A was rejected on the property-fit test (a third shape in a parser whose one special case caused D5), not on preference. | COMPLIANT |
| `dependency-direction-placement` | The recommendation adds no dual-use file. The remediation recipe lands in `supporting-docs/MIGRATION-v10-to-v11.md`, a client/public surface, per BD-294's own File/Symbol line (§3.4). No pack-side mechanism (`pack-ops/`, Pack Chat, `pack-*` agent names, `maintenance-docs/`) is proposed for any client surface. No addition to the pack-side-ship allowlist is proposed. | COMPLIANT |
| `declare-verify-backing` | Every claim verifies the load-bearing reality rather than a proxy: content preservation is asserted by grepping the client's value **in DEST** (`'Acme Ledger' in DEST: 1`, `override body in DEST: 1`), not by the disposition alone — EEB-8 is the case in point, where the disposition is `merged-with-customization` and the DEST check reveals the deletion was reverted. EEB-5 asserts the region **classification** as well as the disposition, because EEB-5 itself shows a shape can be reclassified while the disposition stays clean. EEB-6 verifies the two parsers agree on output, not that both files were edited. | COMPLIANT |
| `operating-docs-no-history-no-bloat` | This document is an architect design doc (a reference doc), not an operating doc, so the ban does not bind it. The text it *proposes* for operating docs is history-free and describes only what will exist: §2.5 "one sentence at the order-independence claim naming the seed slot as no longer special-cased"; §3.6 "the placeholder step points at the seed pairs"; OI-3(a) is a forward-looking instruction with no dated note, no `per BD-NNN`, and no reference to a deferred feature. | COMPLIANT |
| `public-bound-no-leak` | The reporting client is referred to only as "the reporting client" / "an already-migrated client". Zero occurrences of the client's project name, its repository path, or its domain vocabulary anywhere in this document. Fixture values are the invented, domain-neutral `Acme Ledger` / `macOS 26 and iOS 26` / `gRPC + Proto3`. | COMPLIANT |
| `open-item-surfacing` | §6 carries 8 open items (OI-1…OI-8); each states context, my own options (a)/(b)/(c), and an evidence- or logic-based recommendation. None recommends from memory — each cites an EEB or a quoted source line. None defers or delays work to another or a new BD: OI-5 is the only item routed elsewhere, and it is routed to an entry that is **already open, already targeted at v11.0, and whose Position line already names that measurement as its first** (quoted in OI-5), which is scheduling within the same version, not deferral; the alternative is stated explicitly ("it belongs in BD-293, not in a new entry"). | COMPLIANT |
| `agents-never-commit` | Zero state-changing git verbs against the pack. The three `git` invocations touching the pack are read-only: `git clone <pack> <scratch>` (reads the pack, writes only scratch), `git show v10:project-template/CLAUDE.md` (read, inside the scratch clone), `git ls-files` (read, inside the scratch clone). All commits (`7b92f1c`, `1d58b3a`, `c3a8c05`) were made **inside throwaway scratch clones** under `…/scratchpad/`, as trap #2 requires, and no branch, tag, ref, index, or working tree of the pack was modified. `git status --porcelain` in my own worktree at start and at end: empty. | COMPLIANT |
| `per-action-approval-sub-agents` | The only deletions performed were `rm -rf` of directories I created inside my own scratchpad (`rm -rf "$S/pack"`, `"$S/eng-*"`, and the engines' own work dirs) before recreating them. Nothing outside `…/03f94d7a-…/scratchpad` and the single named report path was written or deleted; the handoff dir's two input files are untouched. | COMPLIANT |
| `graph-first-context` | Discovery ran graph-first at the injected absolute path: `graphify query "marker-preserve trinity graft engine seed slot Project addenda preamble" --graph /Users/david/Developer/optiquity-ai-agent-config-pack/graphify-out/graph.json --backend claude-cli --budget 1500` → `11531 nodes | 619 nodes found`. It widened recall beyond grep, surfacing `test-fixtures/v11-trinity-marker-prepped` (→ EEB-10) and `pack-ops/MERGE-STRATEGY.md` (→ the §2.5 edit set). Verification of each named surface was then Read/grep (P2), per the two-phase rule. | COMPLIANT |
| Read-only agent class / single permitted write | One Write to the caller-specified path `/Users/david/.local/state/optiquity-pack-handoff/bd294-architect-20260903T020000Z/ARCHITECTURE-BD-294.md` plus two chunked Edits to that same file. No file in `/Users/david/Developer/optiquity-ai-agent-config-pack` was created, modified, or deleted. Working files were written only under the session scratchpad. | COMPLIANT |
| Worktree isolation / injected canonical facts | Regime verified at runtime, not assumed: `git rev-parse --show-toplevel` → `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a0861cc63578c268f`; `git rev-parse HEAD` → `91712431ad4b566cff2d3f7717ce70d4d1e0abbf`; `git status --porcelain` → empty; `file .git` → `ASCII text`, 101 bytes. All git ran in my own worktree or in my own scratch clones; no cross-tree `git -C` into the main checkout (one such attempt was platform-refused and was not retried). | COMPLIANT |
| PREFLIGHT / stop-means-stop | The single-line preflight was emitted before this Write: `PREFLIGHT: design complete; D3 Option B (template-only …); D5 engine fix (seed-slot ##-promotion …); about to Write`. No parent stop instruction was received. | COMPLIANT |
| `enumerate-encoding-surfaces` | The surfaces that ENCODE the changed contract are enumerated and each is given a change in §2.5 / §3.6: the two parsers (`marker-preserve.sh`, `trinity_markers.py` — parity proven in EEB-6), the tests (`test-marker-preserve-bd136.sh` + the new T-1/T-2/T-3), the validator (the new check), and the four cross-reference docs (`SKILL.md`, `PRE-RECONCILE`, `INSTALL-PROCEDURES`, `MERGE-STRATEGY`). The asymmetric case the rule warns about — validator changed but test not, or vice versa — is closed by M-23 and by T-3's own test. | COMPLIANT |
| `no-deferral-without-user-direction` / `deferral-is-scope-creep` | Every recommendation lands in v11.0. The only routing-elsewhere is OI-5, defended on BLOCKED/LOGICAL-FIT with file evidence (the surface is `init-project.sh cmd_update`, which EEB-16 shows is BD-293's, and BD-293's quoted Position line already schedules that exact measurement first in v11.0). No recommendation anywhere in this document proposes a v11.1+ target or a new BD. | COMPLIANT |
| `verify-full-ci-suite` | Not fully applicable to a read-only design pass, and stated rather than glossed: I ran the seven marker/trinity/migration test files plus `validate-pack.py` against each candidate tree (EEB-4, EEB-5, EEB-12) — 419 assertions plus the validator. I did **not** run the whole two-job workflow, `PACK_VALIDATE_DEEP=1`, or the fixture-dependent shard (which needs built fixtures). The implementing coder must run the full battery; my numbers bound the risk, they do not discharge that obligation. | PARTIAL — scope stated, residual obligation named |
| `architect-doc-reality-reconciliation` | No BD in this design realises a previously-anticipated architect-doc design, so no reconciliation chain is owed. The one forward-pointer I do carry is corrective and explicit: §1 records the two inherited claims from the incoming census that measurement overturned (EEB-3, and the L-2 message I could not reproduce), so the next reader is not misled by the earlier document. | N/A: no anticipated-design realisation in scope |
| `pack-entry-type-semantics` | No backlog/changelog entry is created, edited, or restructured by this pass; no phase, part, task, or grouping is touched. | N/A: no entry-structure work in scope |

> **SUPERSEDED RESULTS — see §9 items 1 and 2.** Three rows above quote
> measurements the plan's re-verification at `b40f111` overturned; read §9
> before treating any of them as current.
>
> - `cross-bd-collision-scan` — the quoted *"15 structured blast-radius
>   paths"* and *"17 × `none`"*. Re-run against the corrected **22-path** set,
>   **BD-289 collides on five paths**, so there are **two** real collisions,
>   not one (§9 item 2).
> - `no-deferral-without-user-direction` / `deferral-is-scope-creep` and
>   `open-item-surfacing` — both rest on OI-5 being the one item *"routed
>   elsewhere"*. At `b40f111` there is no residual item to route anywhere,
>   because BD-293 landed the machinery in the interim (§9 item 1).

---

## 8. Summary for the design review

| | D5 | D3 |
|---|---|---|
| **Verdict** | code defect, one region of one function, mirrored in a second parser | shipped-contract defect, four legs, three mutually incompatible shipped instructions |
| **Recommendation** | fix the engine: seed-slot `##`-promotion to Shape B; mirror into Check 91; contain `_mp_h2_list` (OI-6); tighten the prefix match (OI-1) | Option B: relocate the identity into a shipped seed pair, wrap the 7 in-section placeholders, stop shipping the two removable preamble blocks, reword the 5 delete-the-section instructions — all four legs as one change; template and docs only |
| **Repairs existing installs?** | yes, automatically, on the next run | no option does; a one-time in-place recipe ships and is proven clean + idempotent |
| **Engine change** | 2 files, +22 / −9 measured | none |
| **Template change** | none | 3 files, +51 / −51 measured for the mechanical part, plus ~18 lines/file of reworded instructions |
| **Interaction** | independent — measured on the combined tree, all legs stay fixed; one new loud L-6 case (EEB-15) needs one sentence of docs | |
| **Sizing** | coder-level | coder-level after the user settles OI-2 and OI-3 wording |
| **User decisions required** | OI-1 (tighten: recommended yes) | OI-2 (section name), OI-3 (instruction wording), OI-4 (drop the how-to block: recommended yes), OI-5 (route the `--update` attribution gap to BD-293), OI-7 (guard as a check: recommended yes) |

---

## 9. Reconciled at `b40f111` (BD-294 planning)

**Why this section exists.** This document is a reference record, not an
operating doc, so its history and provenance are correct content and are kept.
A *wrong state-claim* is not. Between this design pass (HEAD
`91712431ad4b566cff2d3f7717ce70d4d1e0abbf`, 2026-09-03) and the planning pass
(HEAD `b40f111d84f361917aa09e93ff74c19194bbab9b`, 2026-09-07) five commits
landed touching 118 files, and the plan's adversarial re-verification
(`PLAN-BD-294.md` §1.1, 22 rows) re-ran every load-bearing measurement.
**Nineteen** of the 22 rows carry a CONFIRMED verdict. Counting method: a row is
*wholly* CONFIRMED when its verdict cell carries CONFIRMED and no competing
verdict token — an amplifier such as *"and EXTENDED"*, *"exactly"* or
*"extended to DEEP"* does not disqualify it; a row is *split* when CONFIRMED
appears alongside STALE / MOVED / INCOMPLETE. On that method **18** rows are
wholly CONFIRMED, **1** is split (row 20 — length **MOVED**, anchor
**CONFIRMED**), and **3** carry no CONFIRMED at all (row 17 **STALE**, row 18
**STALE / INCOMPLETE**, row 19 **MOVED**). This section records the five items
where a claim changed or needs restating, so no reader acts on a superseded
claim — or discards one that still holds. **Nothing above is rewritten or
deleted** — each site carries an inline pointer back here.

This is link **(b)** of the `architect-doc-reality-reconciliation` chain: (a)
the in-code docstring naming the realised consumer is owed by the commits that
change code (C1's parsers, C3's check) and is not C5's to write, since C5 lands
documents only; (b) is this addendum; (c) is the C5 IMPL-REPORT, which links
both. Every citation here is **file + symbol**, never a line number.

### Item 1 — OI-5 / EEB-11: the `--update` empty-BASE attribution cost

- **Superseded claim.** OI-5: *"it is a standing cost on every future v11.x
  content release"*, and its routing of option (b) to BD-293 as work to be
  measured there. The §7 rules-block rows that lean on OI-5's routing
  (`no-deferral-without-user-direction` / `deferral-is-scope-creep`,
  `open-item-surfacing`) inherit this correction.
- **What is true at `b40f111`.** BD-293 landed the machinery in the interim.
  `cmd_update` resolves a real BASE through a four-rung cascade, and **both**
  entry paths now originate the rung-R1 ledger, so the sidecar the design
  measured (the R3' row) is reachable only by a client with no ledger on any of
  the three consulted state dirs — neither a migrated nor a freshly-installed
  client. There is **no residual work item** to route anywhere.
- **Realised consumer (file + symbol).**
  - `scripts/init-project.sh` → `_cmd_update_resolve_base()` — the R1/R2/R3'/R4'
    cascade, documented in its own header comment.
  - `scripts/init-project.sh` → `seed_r1_ledger()` — the fresh-install
    ORIGINATE, under the `R1 baseline seed (fresh install)` banner comment that
    names the closed defect in the pack's own words.
  - `scripts/init-project.sh` → `cmd_update()` — the R1 READ loop over the three
    state dirs (`$state_dir/`, `$TARGET/.pack-install-reconcile/`,
    `$TARGET/.pack-migrate-*/`).
  - `scripts/migrate-v10-to-v11.sh` → `_v10_to_v11_map_derived_install()` — the
    `R1 WRITE` block, which calls `customization_preserve_ledger_flush()` in
    `scripts/lib/customization-preserve.sh` and `warn`s when the ledger is empty.
- **Correction of record.** `PLAN-BD-294.md` §3.2 (EEB-P7) and §1.1 row 17.
- **EEB-11 itself stands.** Only the inference drawn from it in OI-5 falls.

### Item 2 — EEB-16: the cross-BD collision scan scored BD-289 `none`

- **Superseded claim.** EEB-16: *"exactly **one** real collision"*, with BD-289
  among the 17 scored `none`; and the §7 rules-block `cross-bd-collision-scan`
  row, which quotes that result.
- **What is true at `b40f111`.** The scan's blast radius was **15 paths** and
  omitted every check-wiring surface BD-294's own T-3 recommendation must edit.
  Re-run against the corrected **22-path** set, **BD-289 collides on five
  paths** — `scripts/validate-pack.py` (registry tuple),
  `scripts/lib/validate_checks/core.py`, `README.md` (two check-count claims),
  `scripts/tests/` (new per-check tests), `scripts/lib/ci-shard-plan.py`
  (coverage assertion) — all quoted from `backlog/BD-289.md`'s `File/Symbol`
  line. There are **two** real collisions, not one.
- **Why it matters, and the coordination it forces.** BD-289 targets v11.1 and
  lands later, so the collision is forward-directional: BD-294 ships first and
  must not consume BD-289's reserved slots. BD-294's guard is therefore **Check
  98**, and C3 must bump the count 92 → 93, advance the ledger comment to *"Next
  free numeric ID = 99"*, and preserve the *"Checks 95–96 reserved for BD-289,
  unlanded"* sentence verbatim at **both** README claim sites. This is a
  COORDINATE signal, not a gate.
- **Realised consumer (file + symbol).**
  - `scripts/lib/validate_checks/core.py` → `CHECK_REGISTRY_EXPECTED_COUNT` and
    the running check-numbering ledger comment directly above it (which carries
    *"(Next free numeric ID = 98.)"* and the sentence reserving 95 + 96).
  - `README.md` → the two check-count claim sites (the v11.0 (RC2) version-table
    row, and the `validate-pack.py` line of the Repository Layout tree).
  - `backlog/BD-289.md` → its `File/Symbol` line.
- **Correction of record.** `PLAN-BD-294.md` §2 (EEB-P4) and §1.1 row 18.

### Item 3 — EEB-8: leg (d) has three outcomes, not two

- **Extended claim — not superseded.** EEB-8 records two outcomes for the
  "delete the entire section" instruction — a silent revert, and a same-name
  Shape B override that works. Both still reproduce: `PLAN-BD-294.md` §1.1
  row 6 verdicts EEB-8 *"**CONFIRMED**, and **EXTENDED** — a third outcome
  exists"*. `EXTENDED` is this item's label everywhere it appears — the banner
  at the head of this document, the inline marker in §3.1, and here.
- **What is true at `b40f111`.** A third outcome exists, and it is the worse
  one. The `<!-- OPTIONAL: … -->` comment sits **above** the heading it
  describes, so it is lexically the last body line of the **preceding** section.
  A client who deletes what the comment plainly calls *"the entire section"* —
  comment included — gets `customization-detected-needs-reconciliation` blaming
  a section they never touched. That is structurally the same misdiagnosis class
  as D5, and the reword must stop the delete for this reason too, not only
  because the deletion is reverted.
- **Realised consumer (file + symbol).** The five shipped
  `<!-- OPTIONAL: … -->` comments in `project-template/CLAUDE.md` (and their
  twins in `project-template/AGENTS.md` / `project-template/GEMINI.md`): each
  precedes its own H2, e.g. the one introducing `## gRPC and Proto3 rules`
  trails the body of `## Language-specific coding rules`.
- **Correction of record.** `PLAN-BD-294.md` §1.2(a) (EEB-P2) and §1.1 row 6.

### Item 4 — OI-3: the measurement selects the pointer, not the recipe

- **Superseded claim.** OI-3's recommendation of option **(a)**, the
  self-contained recipe.
- **What is true at `b40f111`.** The user's rule prices the choice by frequency,
  and frequency is measurable: suppressing an optional trinity section is a
  **one-time, setup-only** act (a project traverses exactly one of the three
  entry paths, once; the migration guide never re-presents the choice; across an
  entire major version the count of optional trinity SECTIONS went 5 → 5, so the
  "re-faces-the-decision-on-update" path never fired). Re-measured for this
  commit, that span is: `project-template/CLAUDE.md` carries **5**
  `## [CONDITIONAL]` H2 sections at `v10.0` and **5** at `v10.1`, and **5**
  `<!-- OPTIONAL: … -->` comments at `v11.0-RC1`, at `v11.0-RC2` and at
  `b40f111`. The SECTION count is stable across the whole span; what changed at
  the v10→v11 boundary is the marker SYNTAX, so the `<!-- OPTIONAL: … -->`
  construct itself is v11-native — `grep -c '^<!-- OPTIONAL:'` returns **0** in
  all three trinity files at `v10.1`, and **5** in each from `v11.0-RC1`
  onward. Under the user's own rule
  that is the infrequent branch, which selects option **(b), the pointer**.
- **Realised consumer (file + symbol).**
  `project-template/docs/pack/PM-CHAT.md` § "How to add project-owned content to
  trinity files" (with its `### The two shapes` sub-section) — the shipped
  authoring SSOT. The pack already points clients at that file for this exact
  concept at three sites, though none of the three is section-qualified:
  `supporting-docs/INSTALL-PROCEDURES.md` names the file with a lower-cased
  paraphrase of the section title (*"The full Shape A (body-wrap) / Shape B
  (whole-section) authoring procedure lives in `docs/pack/PM-CHAT.md` (how to
  add project-owned content to trinity files)"*), and `scripts/init-project.sh`
  emits a **file-level** pointer with a different parenthetical topic at two
  call sites — the `cmd_update` completion message and the end-of-`init`
  completion message — both reading `say "see docs/pack/PM-CHAT.md
  (project-owned marker authoring) before editing."`. It is a
  project-side SSOT, so `P-missed-7` is satisfied: no pack-side mechanism is
  imported onto a client surface.
- **Correction of record.** `PLAN-BD-294.md` §3.1 (EEB-P5, EEB-P6).

### Item 5 — two doc lengths that moved, and one anchor that did not

- **Superseded claims — two, and both are lengths.** The §3.6 sizing table's
  *`supporting-docs/MIGRATION-v10-to-v11.md` (1098 lines)* (repeated in §3.4's
  prose), and the §2.5 sizing table's *`pack-ops/MERGE-STRATEGY.md` (680
  lines)*.
- **Verified still accurate, restated durably — not superseded.** The
  *`:200–:206`* line-range anchor for the Shape A / Shape B prose (§2.5 table
  and the §5 graph-discovery paragraph) did **not** move. Re-measured in the C5
  commit workspace at `b40f111`: in `pack-ops/MERGE-STRATEGY.md` the
  `**Shape A**` bullet runs `:200`–`:203` and the `**Shape B**` bullet runs
  `:204`–`:208`, so `:200–:206` still lands squarely on that prose.
  `PLAN-BD-294.md` §1.1 row 20 records the same split verdict — *"**MOVED**
  (length), **CONFIRMED** (anchor)"*. It is re-expressed in symbol form below
  because a line range is a fragile citation style, not because the citation
  was wrong.
- **What is true at `b40f111`, re-measured independently for this commit.**
  `wc -l` in the C5 commit workspace at `b40f111`:
  `supporting-docs/MIGRATION-v10-to-v11.md` = **1127**;
  `pack-ops/MERGE-STRATEGY.md` = **689**;
  `supporting-docs/INSTALL-PROCEDURES.md` = **1390**;
  `supporting-docs/PRE-RECONCILE-v10-to-v11.md` = **298**;
  `project-template/skills/resolve-merge-conflicts/SKILL.md` = **287**. Only the
  first two moved; the other three re-measure exactly as the design recorded.
- **Realised consumer (file + symbol) — the durable form of the line-range anchor.**
  The Shape A / Shape B contract prose lives at `pack-ops/MERGE-STRATEGY.md`
  § "The 11 file classes" → `### 1. trinity — CLAUDE.md, AGENTS.md, GEMINI.md`
  (the two `**Shape A**` / `**Shape B**` bullets). Cite it that way going
  forward — a line range can drift, even when, as here, it has not.
- **Correction of record.** `PLAN-BD-294.md` §1.1 rows 19–20.

### What is deliberately NOT rewritten

- **The original analysis.** Every superseded statement stays where the
  architect wrote it, with an inline pointer to the item above. Rewriting a
  record erases what was actually measured on 2026-09-03 and why the plan's
  re-verification was worth running.
- **The remaining line-number citations.** This document carries six
  backtick-delimited `file:line` citations and the sibling `PLAN-BD-294.md`
  carries 33. Exactly one is re-expressed in symbol form here — the
  `:200–:206` Shape A / Shape B anchor (item 5) — and that is a durability
  restatement, not a correction: it re-measures accurate at `b40f111`. The
  rest are evidence provenance — the exact
  locations a measurement was taken from at a named HEAD — and a mass rewrite
  would both damage that provenance and exceed C5's scope. A reader treating any
  of them as a current pointer should re-derive it from the symbol, not the
  number.
- **`PLAN-BD-294.md`.** It is not reconciled here because it needs no
  reconciliation: it was measured at `b40f111`, the same HEAD this commit lands
  on.
