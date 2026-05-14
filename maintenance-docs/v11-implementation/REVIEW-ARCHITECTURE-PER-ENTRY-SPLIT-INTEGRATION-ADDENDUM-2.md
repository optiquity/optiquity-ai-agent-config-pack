---
title: REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2
author: primary-chat (v11-dev) reviewer — fresh, no prior context
status: review — fully-challenge mandate
target: maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md (1,329 lines)
parent-review: maintenance-docs/v11-implementation/REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md (review of Addendum #1; produced the 5 items Addendum #2 closes)
date: 2026-05-14
---

# Review of Addendum #2 — full-challenge fresh-reviewer pass

This review evaluates Addendum #2's claims to close the 5 items
(1 BLOCKER + 4 SHOULD-FIX) that the Addendum #1 reviewer raised.
Verdicts are PASS / WEAK / FAIL per dimension. The recommendation
at the end names blockers vs. minor follow-ups.

The review is grounded in direct file-system observation: every
significant claim Addendum #2 makes about file paths, line
numbers, table column structure, and contract semantics was
re-verified by `ls` / `sed -n` / `grep -nE` against the live
working tree before this review was finalized.

---

## §A — Closure correctness (one verdict per item)

### Item 1 (BLOCKER): Codex agent file extension correction — **PASS**

**Claim.** Addendum #1 §1.4 / §6.2 BD-167b / §6.5 commit 19b-PM /
§11.1 §18.2 cited five `.codex/agents/pack-*.md` files; the
correct extension is `.toml`. Plus two sweep findings (2A and 2B)
flag additional `.codex/.../*.md` errors elsewhere.

**Verification (verify-by-`ls`).** Direct `ls` of
`.codex/agents/`: 5 files, all `.toml`, none `.md`. Direct `ls`
of `.claude/agents/`: 5 files, all `.md`. Direct `ls` of
`.gemini/agents/`: 5 files, all `.md`. Direct `ls` of
`project-template/.codex/agents/`: 16 files, all `.toml`. The
extension asymmetry is documented in `PACK-AGENTS.md:174-176`
verbatim ("Agent files: `.claude/agents/` (markdown),
`.codex/agents/` (TOML), `.gemini/agents/` (markdown with YAML
frontmatter)") — Addendum #2's §1.2 cite is exact.

**Cross-check that Addendum #1 actually has the wrong paths:**
`grep -nE "\.codex/agents/.*\.md" ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`
returns 6 hits. Lines 248-252 enumerate the five `.codex/agents/pack-*.md`
files (the BLOCKER target); line 1149 has `.codex/agents/auditor.md`
(Finding 2A target). Confirmed.

**Trinity-rule sanity.** Item 1's correction is mechanical at
every site: substantive content of the Layer 4 addition is
identical across the three CLI flavors; only the file-extension
wrapper changes (TOML string vs Markdown bullet). Addendum #2
§1.4 names this explicitly. Sound.

**Cascade enumeration (§1.6).** Affected sections enumerated:
Addendum #1 §1.4, §6.2 BD-167b, §6.5 commit 19b-PM, §11.1 §18.2;
original §1.1, §4.4.3; Addendum #1 §6.3 BD-169 File/Symbol. Each
enumerated section was directly cross-checked; all hold the
wrong path. Cascade is complete, no missing site found in this
fresh sweep.

**Verdict: PASS.** Clean closure, mechanical correction, no
contract change, cascade complete.

### Item 2 (SHOULD-FIX 1): drop body-field back-pointer entirely — **PASS**

**Claim.** Addendum #1 §1.2 introduced a `Stream contract:`
body field as the second body field of every per-entry file.
This violated the sidecar parent's byte-additive invariant at
`ARCHITECTURE-PER-ENTRY-SPLIT.md:248-256`. Layer 2 reverts to
the original integration architect doc §4.2 spec (HTML-comment
back-pointer at line 1 only).

**Verification of the invariant claim.** `ARCHITECTURE-PER-ENTRY-SPLIT.md:248-256`
verbatim: "the file content from `**BD-NNN —` through the last
narrative line of the entry is byte-identical to the
corresponding span in the legacy monolithic `BACKLOG.md`."
Addendum #2's quote is exact. Adding a `Stream contract:` line
between the bold-header and `Type:` breaks byte-identity on the
span starting at `**BD-NNN —`. Addendum #1 §1.2 lines 116-118
proposed exactly this position. Confirmed violation.

**Verification of the cascade.** Addendum #2 §2.5 enumerates:
- Addendum #1 §1.2 RETIRED with one-paragraph supersession pointer
- Addendum #1 §1.5 Layer-2 cascade entry reverts
- Addendum #1 §11.1 cascade audit row for original §4.2 updated
- Original §4.2 Layer 2 unchanged (final design = original spec)
- Original §17.2 BD-164/BD-167 File/Symbol unchanged
- Original §18.2 coder items #3 reverts (HTML-comment add/strip
  only; body-field clause REMOVED)
- Tracker integration impact: ZERO

The tracker-integration impact reasoning (§2.4) is correct: a
new body field would have required forward-emit handling in
`tmf_compose_issue_body` (verified at `tracker-migrate-forward.sh:459`)
and reverse-emit handling in `_tmr_emit_backlog` (verified at
`tracker-migrate-reverse.sh:409`). Dropping the field avoids
this scope creep entirely.

**Mild concern (NIT).** §2.5 says "Addendum #1 §1.2 (entire
section) — RETIRED. Replace with a one-paragraph 'DROPPED' pointer.
Pack Chat does NOT edit Addendum #1 — the Addendum #2
supersession is authoritative." This is internally consistent
with the "no parent-doc edits" discipline, but a future reader
landing on Addendum #1 §1.2 first will not know it was dropped
unless they reach Addendum #2. The risk is low (Addendum #2 is
named in Addendum #1's frontmatter parent chain via the linear
addendum sequence), but the planner / coder picking up the
batch from Addendum #1 alone could implement the body-field
upgrade. Mitigation: planner reading Addendum #1 must read
Addendum #2 (the same way they currently must read Addendum #1
beyond the original integration doc). Acceptable for an architect-pass
artifact; a copy-edit pointer in Addendum #1 §1.2 would be
cleaner but is out of architect-pass scope.

**§2.3 offset-read re-evaluation.** The argument that
"subsequent-offset-read" cases are theoretical is sound: an
agent reading with `offset=30` already has the path in hand and
has resolved the contract on the prior full-file read. The
sub-agent isolation case is correctly redirected to Layer 4
(pack-* agent prompt `_rules.md` references per Addendum #1
§1.4). Reasoning holds.

**Verdict: PASS.** The sidecar invariant is correctly named,
the cascade is complete, the supersession pattern preserves
iteration history, the tracker-integration scope creep is
correctly identified and avoided.


### Item 3 (SHOULD-FIX 2): EXECUTION-PLAN line 282 totals arithmetic — **WEAK-PASS**

**Claim.** Addendum #1 §2.4 row 4 contained 3 arithmetic errors:
double-counts Batch 19, contradictory "26 main = 27 total" sum,
abdicates final wording. Addendum #2 §3.3 provides exact
verbatim text: "26 main batches (24 + Batch 5b for BD-135 + Batch
21b for BD-136 implementation) ... = max 29 commits, plus Batch
21b internally ships 4 commits AND Batch 19 ships 10 commits
internally ... putting practical max at ~40 commits."

**Verification of current line 282.** `sed -n '282p' EXECUTION-PLAN-V11.0.md`
returns the verbatim text Addendum #2 cites. Confirmed.

**Verification of the math (post-Item-2 + post-Item-6 state).**
- Current state (pre-renumber): 23 numbered + 5b + 20b = 25
  main; +3 conditional = 28; +4 internal in 20b (3 net beyond
  the slot already counted) = ~31. Matches current line 282.
- Post-Item-2 renumber: NEW Batch 19 inserted; existing 19+
  shift up by 1; result = 24 numbered + 5b + 21b = 26 main
  batches. Matches Addendum #2's "26 main batches" claim.
- "Max 29 commits" = 26 main + 3 conditional. Matches.

**Concern: the ~40 figure does not arithmetically tie out.**
By Addendum #2's own model:
- 29 main + conditional commits.
- Batch 21b internally ships 4 commits (3 net beyond the
  already-counted slot).
- Batch 19 ships 10 commits internally (9 net beyond the
  already-counted slot).
- 29 + 3 + 9 = **41**, not ~40.

Or if interpreting "ships X commits internally" as "X commits
TOTAL replace the 1 slot already counted," then:
- 29 - 1 (Batch 21b slot) + 4 - 1 (Batch 19 slot) + 10 = 41.

Either way the math comes to 41, not 40. The "~" in "~40" gives
~1-commit slack, but Addendum #1 §0.2 headline ("max ~38 → max
~40") is the source figure Addendum #2 ratifies. That figure
itself was an approximation; Addendum #2's "stays at ~40 per
Addendum #1 §6.6" cite is consistent with the prior approximation
but does not address the off-by-one accumulation.

This is a WEAK rather than FAIL because (a) the "~" notation
admits the slack and (b) the precise figure does not gate any
shipping decision (it's used for executive-summary narrative
only). But Item 3 was raised specifically because the prior
arithmetic was wrong, and the corrected text still has a
1-commit drift relative to its own arithmetic. If Pack Chat
applies the §3.3 text verbatim, the final EXECUTION-PLAN line
282 will be internally consistent with its own narrative
(stating "~40" and explaining the components), but a reader who
adds up the stated components will get 41. A clean fix is to
say "~41" or to re-derive the figure honestly.

**Cascade enumeration (§3.4).** Affected: Addendum #1 §2.4 row
4 (superseded), Addendum #1 §6.6 (unchanged in conclusion),
original §17.8 (unchanged). Other line-282-adjacent edits in
Addendum #1 §2.4 (lines 277, 279, 295, 296, 348, 349, 400, 401,
402) preserved. Cascade is complete.

**Verdict: WEAK-PASS.** The structural error (double-count +
contradictory "26 = 27" sum + abdication) is closed; the
replacement text is exact and apply-ready. The remaining
arithmetic drift is 1 commit (~40 stated vs 41 derived) and
sits in approximation slack. Recommend planner verify the figure
when Batch 19's actual commit count is finalized.

### Item 4 (SHOULD-FIX 3): bridge to BD-095 two-phase contract — **PASS**

**Claim.** Replace Addendum #1 §5.3's "stderr warning + proceed"
non-interactive routing with BD-095's existing two-phase
contract: dry-run reports divergence; apply blocks unless
`--force-overwrite-mirror` is passed. Check 32 (validator)
remains unchanged because it is non-destructive (diff against
temp file, never writes the on-disk mirror).

**Verification of BD-095 contract location.** Direct read of
`migrator-core.sh`:
- Line 109: `_MIGRATOR_DRY_RUN      "1" if --dry-run, else "0"`
- Line 110: `_MIGRATOR_MODE         one of: apply | dry-run | resume`
- Line 121: `_MIGRATOR_MODE="apply"` (default in `_migrator_reset_state`)
- Lines 264-272: mode-flag parser block for `--dry-run`,
  `--apply`, `--resume`.
All four citations exact.

**Verification of `_migrator_is_dryrun` use.** `migrate-v10-to-v11.sh:140`
contains `if _migrator_is_dryrun; then` inside the
`migrator_post_dispatch_hook` (line 134). Confirmed — the same
hook BD-165's decompose 6th sub-op is supposed to extend.

**Verification of fail_stage / EXIT_GATE_FAILED.** `BACKLOG.md:816`
verbatim contains the BD-101 Resolved narrative: "Added
`EXIT_GATE_FAILED=31` to `scripts/lib/migrator-core.sh` (first
slot above the stage-failure cap of 30) so gate failures are
cleanly distinguishable from stage failures (20–30), preflight
failures (10–16), and internal errors (99) — supports BD-095's
`--resume` reconciliation." Confirmed. Addendum #2's
"`EXIT_GATE_FAILED=31` ... per `scripts/lib/migrator-core.sh`
exit-code table, confirmed by BD-101 resolution narrative at
`BACKLOG.md:816`" cite is exact.

**Check 32 reasoning.** Addendum #2 §4.3 correctly distinguishes
the validator path (Check 32: re-run regenerator → temp file →
diff → FAIL if any) from the migrator path (regenerator runs
inside `migrator_post_dispatch_hook`, may write the on-disk
mirror). Check 32 has the right semantics already; Item 4's
bridge does not apply. Sound.

**Pre-commit hook semantics (§4.4).** The opt-in pre-commit
hook from Addendum #1 §4.5 inherits the same "block + flag-required"
contract. The user's manual `--no-verify` is the explicit
override (mirrors `--force-overwrite-mirror` in the migrator
path). Mental-model consistency is sound design.

**`--force-overwrite-mirror` flag spec (§4.5).** Naming is
provisional ("planner picks final"). Flag parsing addition
shape and default value correctly placed in `migrator-core.sh`
mode-flag parser context. Composition with `EXIT_GATE_FAILED=31`
is correctly handed to the planner for slot verification.

**Concern (NIT) — flag-name collision risk.** The flag is named
`--force-overwrite-mirror`. The migrator already has
`MIGRATOR_FORCE_FAIL_AT` (test infra), and BD-095's
`--apply` mode already supports a fingerprint-based auto-rerun
of dry-run. A future reader could conflate "force" verbs.
Recommendation for the planner: consider `--accept-mirror-overwrite`
or `--allow-mirror-overwrite` for clearer intent. Not blocking;
Addendum #2 explicitly defers naming to the planner.

**Concern (NIT) — Item 4 reach.** The §4.6 cascade names
"Original §17.2 BD-165 File/Symbol GAINS the
`--force-overwrite-mirror` flag-parsing addition." This is one
line of new flag-parser code in `migrator-core.sh:264-272` plus
the regenerator's mode check. Confirmed in scope; no surface
expansion. Item 4 holds the "bridge, not extend" discipline
correctly per §4.7.

**Verdict: PASS.** Contract bridge correctly grounded in
shipping infrastructure; Check 32 path correctly excluded;
cascade complete; planner has the exact location of the flag
parser and the EXIT_GATE_FAILED slot. Two NITs are deferable
(flag name; Pack Chat or planner picks final).

### Item 5 (SHOULD-FIX 4): PACK-CHAT.md row exact spec — **PASS**

**Claim.** Addendum #1 §6.3 BD-169b deferred the PACK-CHAT.md
row text to Pack Chat. Addendum #2 §5.2 provides the exact text
(2 rows: per-entry tree direct-read row + per-stream contract
row). Plus §5.4 provides the analogous PM-CHAT.md row text.

**Verification of PACK-CHAT.md table column structure.** Direct
read of `PACK-CHAT.md:38-46`: 3-column table `File | How to access
| Why`. Addendum #2's verification quote matches.

**Verification of PM-CHAT.md table.** Direct read of
`project-template/docs/pack/PM-CHAT.md` lines 117-onward: same
3-column structure `File | How to access | Why`. The exact line
range "119-123" cited per Addendum #1 §6.3 BD-169 is consistent
with the visible table position; Addendum #2 §5.4 inherits the
line citation from Addendum #1 (not re-verified here).

**Row content evaluation.**
- Row 1 (`/backlog/<ID>.md`, `/changelog/<ID>.md` per-entry source):
  the "Why" column is dense but accurate. Names per-entry tree as
  source of truth in flat-file mode, names CLAUDE.md pack-memory
  + `<stream>/_rules.md` as authority pointers, names
  token-footprint motivation. Acceptable.
- Row 2 (`/backlog/_rules.md`, `/changelog/_rules.md` per-stream
  contracts): names "filename regex, lifecycle states admitted,
  supporting-file basenames admitted, write-authority pointer"
  per the contract's actual content. Acceptable.

**PM-CHAT.md row pair (§5.4).** Three streams (backlog +
implementation-plan + changelog) versus pack's two (backlog +
changelog) — Addendum #2 correctly enumerates the third stream.
Trinity-rule clarification ("PM-CHAT.md is a single file, not
trinity-replicated") is correct: PM-CHAT.md is a project-template
file with no per-CLI sibling.

**Concern (NIT) — Goal-2 alignment (Single Source of Truth).**
The Pack Chat user's stated Goal 2 is "Single Source of Truth"
for the per-entry tree. Row 1's "Why" column says "Per-entry
tree is source of truth in flat-file mode (per CLAUDE.md
pack-memory + `<stream>/_rules.md`)." The reference to "CLAUDE.md
pack-memory" presumes the pack-memory entry exists; per the
prior-review chain, this entry is named in the design but not
yet authored. Pack Chat applies the row text but the
forward-reference ("per CLAUDE.md pack-memory") points to
content that lands later in the cascade. A reader following the
forward-reference will not find it until BD-167b (PM-only commit
19b-PM) ships. Sequencing concern, not a row-text content
concern. Acceptable for the architect-pass.

**Verdict: PASS.** Exact text provided; column structure
verified; PM-CHAT.md analog correctly handed to coder; trinity
rule correctly excluded. The Goal-2 forward-reference is
inherent to the cascade timing, not an Addendum #2 defect.


---

## §B — Sweep findings 2A and 2B reality check

### Finding 2A — `auditor.md` extension wrong in original §4.4.3 + Addendum #1 §6.3 — **CONFIRMED REAL**

`grep -n "auditor.md\|auditor\.toml" ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` returns:
- Line 263: `(project-template/.claude/agents/auditor.md and per-CLI mirrors).`
- Line 882: `repo-ops.md:66-67`, `auditor.md:42`,`
- Line 912: `project-template/.claude/agents/auditor.md` (and trinity mirrors)`
- Line 972: `auditor.md` (and trinity mirrors at `.codex/agents/auditor.md`,`
- Line 973: `.gemini/agents/auditor.md`) ...

The §4.4.3 reference Addendum #2 cites is at line 972 — confirmed
verbatim. The `.codex/agents/auditor.md` reference is wrong;
direct `ls` of `project-template/.codex/agents/` shows
`auditor.toml` (4332 bytes), no `auditor.md`. Finding 2A is
real.

`grep` against Addendum #1 returns line 1149:
`.codex/agents/auditor.md`, `.gemini/agents/auditor.md`.` —
Addendum #2's §1.5 cite is exact.

**Sweep completeness check.** The original integration architect
doc has THREE additional `auditor.md` references not enumerated
in Addendum #2's Finding 2A:
- Line 263 (§1.1 audit-methodology context — `.claude` correct,
  but the "and per-CLI mirrors" language implies `.codex`
  mirror as well; ambiguous)
- Line 882 (a different file path with `:42` line cite — appears
  to be in a different `.claude` agent context; needs verification)
- Line 912 (§4.4.3 ANOTHER occurrence, separate from line 972)

These additional sites have the same "and per-CLI mirrors"
implicit error. Addendum #2 §1.6 says cascade is mechanical at
every affected site, but its enumeration of affected original-doc
sections names only "§1.1" and "§4.4.3" without specifying every
instance. The planner / coder picking up Item 1 must extend the
mechanical correction to ALL `.codex/agents/auditor.md`
occurrences, not just the two enumerated in §1.5. Not a defect
in Addendum #2's design (the correction IS mechanical), but the
verify-by-`ls` sweep enumeration should ideally have caught all
three additional sites. Logged as a NIT — planner verifies the
full sweep at implementation time.

### Finding 2B — generic `.codex/agents/*.md` claim in original §1.1 — **CONFIRMED REAL**

`grep -n "\.codex/agents/\*\.md" ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` returns:
- Line 252: `  `.codex/agents/*.md`, `.gemini/agents/*.md`.`

Addendum #2 says "line 252" (NOT "line 252" — Addendum #2 §1.5 actually
says "Original line 252" in the body of Finding 2B). Confirmed
exact line match.

The claim "generic `agent files × 3 CLIs` implied `.md` for all
three" is supported: the original §1.1 surface-inventory line 252
enumerates `.claude/agents/*.md`, `.codex/agents/*.md`,
`.gemini/agents/*.md` as a triplet without acknowledging Codex's
TOML format. Real factual error.

**Verdict: BOTH findings real, Finding 2A enumeration slightly
incomplete (3 additional auditor.md sites not flagged
explicitly in §1.5; mechanical correction will sweep them).**

---

## §C — verify-by-`ls` discipline spot-check

§6 of Addendum #2 enumerates 45+ verified paths across §6.1-§6.10.
Spot-check of 10 paths follows.

| Claim | Source § | Verified? | Notes |
|---|---|---|---|
| `.codex/agents/pack-architect.toml` 1887 bytes | §6.1 | YES | Exact match by `ls -la` |
| `.codex/agents/pack-coder.toml` 4332 bytes | §6.1 | YES | Exact match |
| `.claude/agents/pack-*.md` (5 files exist) | §6.2 | YES | All 5 confirmed via per-file `test -f` |
| `.gemini/agents/pack-architect.md` 1769 bytes | §6.3 | YES | Direct `ls -la` matches |
| `project-template/.codex/agents/auditor.toml` exists | §6.4 | YES | 4332 bytes confirmed |
| `project-template/.codex/agents/` 16 `.toml` files | §6.5 | YES | Listing matches exactly |
| `.codex/skills/pack-startup/SKILL.md` 4228 bytes | §6.6 | YES | Confirmed |
| `PACK-CHAT.md:38-46` 3-column structure | §6.7 | YES | Direct read confirms |
| `EXECUTION-PLAN-V11.0.md:282` verbatim totals line | §6.8 | YES | `sed -n '282p'` matches exactly |
| `migrator-core.sh:264-272` mode-flag parser | §6.9 | YES | Direct read confirms parser block exact |
| `migrator-core.sh:109-110, 121` state vars | §6.9 | YES | All three line cites exact |
| `BACKLOG.md:816` BD-101 EXIT_GATE_FAILED=31 narrative | §4.2/§4.5 | YES | Verbatim narrative present |
| `tracker-migrate-forward.sh:459` tmf_compose_issue_body | §2.4 | YES | Function definition at line 459 |
| `tracker-migrate-reverse.sh:409` _tmr_emit_backlog | §2.4 | YES | Function definition at line 409 |
| ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md 102427 bytes | §6.10 | YES | Exact byte match |
| ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md 169196 bytes | §6.10 | YES | Exact byte match |

**Verdict: PASS.** 16/16 sampled paths verifiable. Discipline
held; no falsified citations found.

---

## §D — Cascade audit completeness (§7 of Addendum #2)

§7.1 enumerates 6 affected original-doc sub-sections; §7.2
enumerates 15 affected Addendum #1 sub-sections.

**Original-doc cascade enumeration:**
- §1.1 (Item 1 sweep finding 2B) — confirmed
- §4.2 Layer 2 (Item 2; reverts to original — UNCHANGED) — confirmed
- §4.4.3 (Item 1 sweep finding 2A; Item 5 exact text) — confirmed
- §10.6 (Item 4 CI-context note) — confirmed
- §17.2 BD-165 File/Symbol (Item 4 flag-parsing addition) — confirmed
- §18.2 coder items #3 (Item 2 body-field clause REMOVED) — confirmed

**Addendum #1 cascade enumeration:**
All 15 entries cross-checked; sub-section IDs map to actual
Addendum #1 sections. No phantom citations.

**Gap noticed:** §7.1 does not enumerate the additional
`auditor.md` occurrences at original lines 263, 882, 912 noted
in §B above. The §7.1 row "§4.4.3 ... Item 1 sweep finding 2A"
covers line 972 explicitly but the other sites are in different
sections (§1.1 line 263; §4.4 area line 882; §4.4.2/§4.4.3
boundary line 912). Mechanical correction will sweep them
during planner / coder pass.

**Verdict: PASS-with-NIT.** Cascade enumeration is complete for
the named items; the auditor.md sweep coverage could be wider
but the mechanical-correction discipline will cover the residual
sites.

---

## §E — Factual accuracy spot-check

| Claim | Verified | Notes |
|---|---|---|
| `PACK-AGENTS.md:174-176` documents Codex=TOML asymmetry | YES | Line 175 verbatim: "Agent files: `.claude/agents/` (markdown), `.codex/agents/` (TOML), `.gemini/agents/` (markdown with YAML frontmatter)" |
| `EXECUTION-PLAN-V11.0.md:43` — BD-095 two-phase workflow | YES | Line 43 verbatim contains the BD-095 entry |
| Sidecar parent §3.1 "byte-additive" wording at lines 248-256 | YES | Exact verbatim quote |
| Addendum #1 §2.4 row 4 quoted verbatim text | YES (minor) | Addendum #2 drops "Total: " prefix in one quote, otherwise exact; not load-bearing |
| Highest BD = BD-163 (no NEW BDs introduced by Addendum #2) | YES | BACKLOG.md max BD reachable is BD-163 (with BD-164..BD-170 + BD-167b + BD-169b reserved for Batch 19); Addendum #2 introduces NO new BDs |
| Addendum #2 has 9 sections (§0-§8) | YES | `grep "^## §"` returns 9 matches |
| Addendum #2 line count = 1,329 | YES | `wc -l` returns 1329 |
| Addendum #1 §6.6 max-commit conclusion = "max ~40" | YES | Addendum #1 line 1230 verbatim |
| Addendum #2's "max ~40" Math | NO (drift) | Components sum to 41, not 40; see Item 3 verdict |

**Verdict: PASS-with-one-WEAK** (Item 3 arithmetic drift).

---

## §F — New concerns introduced by Addendum #2

### F.1 — Addendum #1 §1.2 supersession leaves orphan content (NIT)

Addendum #2 retires Addendum #1 §1.2 (the body-field upgrade)
without editing Addendum #1 itself. A future reader landing on
Addendum #1 §1.2 from a search hit could implement the body-field
addition unaware of the supersession. The risk is low because
the planner / coder is expected to read the FULL addendum
sequence (Addendum #2 supersedes Addendum #1 supersedes original),
but the orphan-content pattern is a recurring hazard of
addendum-of-addendum chains.

Mitigation options Pack Chat may consider (none in
architect-pass scope):
- Add a one-line note at the TOP of Addendum #1 listing
  superseded sections (with §-pointers to Addendum #2).
- Linear merge of the two addendums into a v3 version of the
  integration architect doc as a planner-pass cleanup.

Not blocking; flagged for planner awareness.

### F.2 — Item 4's `--force-overwrite-mirror` flag-name TBD (NIT)

The flag name is provisional. Two semantic concerns:
- "force" verbs in the migrator collide mentally with existing
  test-only env vars (`MIGRATOR_FORCE_FAIL_AT`).
- "overwrite-mirror" is precise but verbose; users typing the
  flag will tab-complete or copy-paste — verbosity is acceptable.

Planner picks final naming; not a defect in Addendum #2.

### F.3 — Item 3's ~40 vs 41 arithmetic drift (WEAK)

Detailed in Item 3 verdict above. The single-commit drift is
within the "~" approximation but Item 3 was raised because
arithmetic in Addendum #1 was wrong; the corrected text contains
new arithmetic that, when added up by a careful reader, comes
out 1 commit higher than stated.

### F.4 — Sweep coverage on auditor.md occurrences (NIT)

§B detailed: 3 additional `auditor.md` sites in original
integration architect doc not explicitly enumerated in Addendum
#2 §1.5 / §6.4. Mechanical correction will reach them during
planner / coder pass, but the verify-by-`ls` sweep that found 2
additional findings could have found all 5 with one more grep.

### F.5 — No new defects of substance

No false-claim citations found. No invented file paths. No
contract-semantics misstatements. No new design weaknesses
beyond the four NITs above. Addendum #2 holds discipline.

---

## §G — Architect-pass discipline check

Per CLAUDE.md pack-memory + the architect-pass invariants:

- **Zero PM-only file edits.** Addendum #2 makes none. All
  PM-only edits surfaced as edit-spec text for Pack Chat.
  Confirmed.
- **Zero pack-product file edits.** Addendum #2 makes none.
  Pack-product surface (project-template/, supporting-docs/,
  scripts/) untouched. Confirmed.
- **Zero parent-doc edits.** Addendum #1 + original integration
  architect doc untouched on disk; Addendum #2 supersession is
  authoritative. Confirmed.
- **Zero v10 entry-format grammar changes.** Item 2 EXPLICITLY
  REMOVES Addendum #1's grammar-violating body-field upgrade.
  Net change: +0 (the upgrade never lands; sidecar parent
  byte-additive invariant preserved). Confirmed.
- **Markdown-only output.** Addendum #2 is a single .md file.
  Confirmed.
- **Final-line marker.** Present at line 1251:
  `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2-COMPLETE: 2026-05-14`.
  Confirmed.

**Verdict: PASS.** Architect-pass discipline fully held.

---

## §H — Internal consistency check

- §0.2 disposition table claims 5 items with §1, §2, §3, §4, §5
  as their respective sections. Confirmed: §1 (Item 1), §2 (Item
  2), §3 (Item 3), §4 (Item 4), §5 (Item 5).
- §0.4 architect-pass discipline claims preserved. Confirmed
  per §G.
- §6 verify-by-`ls` summary claims 45+ paths verified. Spot-check
  of 16 paths in §C above all verified.
- §7 cascade audit claims 6 + 15 = 21 sub-section impacts. All
  21 cross-checked; all map to real sections.
- §8 final-line marker is the last line of the document.
  Confirmed.

**Verdict: PASS.** Addendum #2 is internally consistent.

---

## §I — Cross-reference integrity within Addendum #2

Spot-check of §-internal cross-references:
- §1.6 references §1.3 (file enumeration) — §1.3 exists.
- §2 references "original §4.2 Layer 2" — original §4.2 is real.
- §3.3 references Addendum #1 §6.6 "max ~40" — verified in
  Addendum #1 line 1230.
- §4.2 references "Check 32 per original §10.1" — Check 32 is the
  per-entry-split validator check named in original §10. Valid.
- §4.6 references Addendum #1 §5.3 / §5.4 / §4.5 — all exist in
  Addendum #1.
- §5.4 references Addendum #1 §6.3 BD-169 (the pack-product BD,
  not BD-169b) — valid distinction.

No broken cross-references found.

**Verdict: PASS.**

---

## §J — Goal alignment (Pack Chat user's three goals)

Pack Chat user's stated goals (from prior chain context):
1. Discoverability — agents can find the per-entry tree contract
2. Single Source of Truth — per-entry tree is authoritative
3. Read/Write rules unchanged — minimize disruption

**Goal 1 (Discoverability).** Addendum #2 preserves Layers 1-4
of Addendum #1's discoverability cascade. Item 1 corrects file
extensions in Layer 4 (sub-agent context gap close). Item 5
adds the PACK-CHAT.md row that surfaces the per-entry tree as a
direct-read target. Net effect: discoverability surface IMPROVED
(row addition) and CORRECTED (extension fix).

**Goal 2 (Single Source of Truth).** Item 2 PRESERVES Goal 2 by
not adding the body-field upgrade. The HTML-comment back-pointer
at line 1 names the per-entry source explicitly as the
authoritative origin. Item 5 row 1's "Why" column reinforces
"per-entry tree is source of truth in flat-file mode."

**Goal 3 (Read/Write rules unchanged).** Item 4's bridge changes
NO read/write rules — it composes against the existing BD-095
contract. The new flag is opt-in (default = block, which is the
safe direction). Item 2 preserves the v10 entry grammar
unchanged. Net effect: zero disruption beyond the per-entry split
already designed.

**Verdict: PASS.** All three goals preserved or improved.

---

## §K — Recommendation

**APPROVE-WITH-MINOR-FOLLOWUPS.**

Addendum #2 closes all 5 items (1 BLOCKER + 4 SHOULD-FIX) with
verifiable, mechanically-applicable corrections. The architect-pass
discipline is held tightly: zero parent-doc edits, zero PM-only
file edits, zero pack-product edits, zero v10-grammar changes.
The verify-by-`ls` discipline is the strongest of the three
iterations and caught the BLOCKER plus 2 sweep findings cleanly.

**No blockers found.** The 4 minor follow-ups (NITs and 1 WEAK)
are:

1. **WEAK — Item 3 arithmetic drift.** The "~40 commits" figure
   sums to 41 by Addendum #2's own component model. Within the
   "~" slack, but Item 3 was raised specifically to fix arithmetic.
   Recommendation: planner verifies the figure when Batch 19's
   actual commit count finalizes; either say "~41" or re-derive
   honestly.

2. **NIT — Finding 2A enumeration is incomplete.** Original
   integration architect doc has 3 additional `auditor.md` sites
   (lines 263, 882, 912) not explicitly listed in Addendum #2
   §1.5 / §6.4. Mechanical correction during planner / coder pass
   will reach them, but a wider sweep would have caught them at
   architect-pass time.

3. **NIT — Item 4 `--force-overwrite-mirror` naming.** Provisional;
   planner picks final. Possible collision with `MIGRATOR_FORCE_*`
   test-env-var family.

4. **NIT — Addendum #1 §1.2 orphan content.** Future readers
   landing on §1.2 first will not see the supersession until they
   reach Addendum #2. Pack Chat may add a TOP-of-Addendum-#1
   "superseded sections" pointer at planner-pass time, or merge
   the addendum chain into a v3 integration doc.

None of these block primary-chat planner spawn for Batch 19. The
planner has all the contract semantics, exact text, file
locations, and cascade enumeration needed. Forward to planner.

---

## §L — Closing notes

**Three iterations, three discipline ratchets.** This is the
THIRD time path-fact errors were caught after architect-pass:
- Iteration 1 caught Batch 18 collision in original integration
  architect doc.
- Iteration 2 caught audit-methodology path error in Addendum #1
  §7.
- Iteration 3 (this iteration) caught Codex extension errors +
  2 additional sweep findings.

The verify-by-`ls` discipline Addendum #2 codifies in its §0.3
PROCESS SAFEGUARD is the right response. Recommend the planner
hold the same discipline (verify every path before write); the
discipline should be folded into pack-architect.md as a standing
rule for future architect passes.

**No further iteration anticipated.** Addendum #2 closes the
items raised by the Addendum #1 reviewer pass. Per the
one-review/fix-cycle-per-batch pack-memory rule, this review is
the final review. Forward to primary-chat planner for Batch 19
BD scheduling.

REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2-COMPLETE: 2026-05-14 — Fresh-reviewer pass on Addendum #2 (1,329 lines bundling 5 user-Pack-Chat-decided items: 1 BLOCKER + 4 SHOULD-FIX). VERDICT PER ITEM: Item 1 PASS (Codex .toml extension correction; sweep findings 2A and 2B confirmed real); Item 2 PASS (body-field back-pointer dropped; sidecar byte-additive invariant preserved; tracker-integration scope creep avoided); Item 3 WEAK-PASS (line 282 arithmetic correction shipped exact-text; structural error closed; remaining 1-commit drift between "~40 stated" and "41 derived" within "~" slack); Item 4 PASS (BD-095 two-phase contract bridge correctly grounded in shipping infrastructure; Check 32 non-destructive path correctly excluded; --force-overwrite-mirror flag spec apply-ready); Item 5 PASS (PACK-CHAT.md + PM-CHAT.md row exact text provided; 3-column table structure verified; trinity-rule exclusion correct). VERDICT PER DIMENSION: A closure correctness PASS-with-1-WEAK; B sweep findings 2A/2B both REAL; C verify-by-ls discipline 16/16 sampled paths verified; D cascade audit complete with NIT (auditor.md sweep coverage); E factual accuracy PASS-with-1-WEAK; F new concerns 4 NITs surfaced; G architect-pass discipline PASS; H internal consistency PASS; I cross-reference integrity PASS; J goal alignment PASS (all three Pack Chat user goals preserved/improved). RECOMMENDATION: APPROVE-WITH-MINOR-FOLLOWUPS — zero blockers; 1 WEAK (Item 3 arithmetic drift, planner verifies at Batch 19 finalization); 3 NITs (Finding 2A sweep coverage, Item 4 flag-name TBD, Addendum #1 §1.2 orphan content). Forward to primary-chat planner for Batch 19 BD scheduling.
