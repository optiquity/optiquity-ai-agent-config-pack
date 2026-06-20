# PLAN (RECONCILED) — BD-240: Re-frame `graph-first-context` so DISCOVERY/RECALL is genuinely graph-first

**Agent:** FRESH, INDEPENDENT `pack-planner` (READ-ONLY) — reconciliation pass (neither the original planner nor the adversarial planner; empty-context own judgment).
**Repo / branch / HEAD (verified at runtime):** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` / `v11-dev` / `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3`.
**Placement:** MAIN checkout (work on HEAD; `git status --short` shows only two untracked v11-impl planning docs — clean for BD-240 surfaces).
**Date:** 2026-06-20.
**Supersedes:** `/tmp/pack-handoff-bd240-plan/PLAN-BD-240.md` (original) — this is the plan-ready document.
**Inputs read in full:** original `PLAN-BD-240.md`; `ADVERSARIAL-PLAN-REVIEW-BD-240.md`; `DESIGN-BD-240-RECONCILED.md` (M-1 = (c) BOTH); `backlog/BD-240.md`; live trinity `graph-first-context` rule (CLAUDE.md L637-684 + AGENTS/GEMINI parallels); `pack-ops/OPTIONAL-FEATURES.md` L565-573; `pack-ops/PACK-MEMORY-RATIONALE.md` `## graph-first-context` L638-682 (incl. the L652 "How to apply" opener — the B-1/BLOCKER-1 surface); `pack-ops/PACK-CHAT.md` L295-305; `pack-ops/PACK-AGENTS.md` L62-71; `.claude/agents/pack-docs-researcher.md`; `scripts/validate-pack.py` Checks 18/44/45/46; `backlog/BD-238.md`; `backlog/BD-241.md`.
**Authority:** This plan executes `DESIGN-BD-240-RECONCILED.md` (settled — this plan does NOT redesign). M-1 is DECIDED as mechanic **(c) BOTH** (structural re-bind + the anti-rationalization sentence); the §2.2 text is the decided text, landed verbatim.
**Scope keyword:** `pack-only` (verified: `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` → 0 hits, exit 1, at HEAD af73ffb).

---

## 0. Reconciliation summary

I re-measured every adversarial-plan finding independently against HEAD `af73ffb`
and re-examined the whole plan with fresh eyes. Disposition:

| Finding | Adversarial severity | My re-measurement | Disposition |
|---|---|---|---|
| **B-1 / BLOCKER-1** Surface-4 REPLACE-run produces a double-"When … exists" stutter | BLOCKER | CONFIRMED — the live L652 opener `**How to apply.** When $(git rev-parse …)/graphify-out/graph.json exists,` survives the original §3.2 run-scope, and the replacement text re-opens with `When the graph exists,` | **FIX** — re-scope the REPLACE-run leftward to the opener (option (a)); §3.2 below |
| **MAJOR-1** anti-restate analysis mis-models Check 46 (scans the wrong target text) | MAJOR | CONFIRMED — Check 46 scans the first-120-char OPENER of each `## Pack memory` bullet (`[:120]`, validate-pack.py L7553), which BD-240 does NOT touch; the §2.2 text is never a candidate. GREEN verdict holds; reasoning model is wrong | **FIX** — restate the model to the opener candidate; lean on gate-10's direct Check 46 run as the binding net; §3.4/§3.5/§5.1/gate 5 |
| **MINOR-1** PREFLIGHT gate 9 grep malformed (matches PRE-edit state) | MINOR | CONFIRMED — the literal `grep -c "skip Graphify … not the graph\|not the graph\."` returns `1` NOW (pre-edit), the opposite of a grep-zero | **FIX** — replace with a clean grep-zero/grep-confirm pair; §5.2 gate 9 |
| **MINOR-2** PACK-AGENTS.md target is a bold-headed PARAGRAPH, not a `- ` list bullet | MINOR | CONFIRMED — PACK-AGENTS.md L62-71 is `**bold-lead.**` prose (no `- ` marker); PACK-CHAT.md L295-305 IS a `- ` bullet | **FIX** — name the structure; §3.5 + §2 table |
| **MINOR-3** the shared-core REPLACE target shares a PHYSICAL LINE with the per-CLI tail | MINOR | CONFIRMED — CLAUDE.md L650 / AGENTS.md L568 / GEMINI.md L545 all carry `deliberately not in the graph). <tail-first-chars>` on one line | **FIX** — name the in-line string boundary; §3.1 + R-3 |
| **MINOR-4** Surface-4 line citations drift | MINOR | CONFIRMED — heading at L638 (not L652); citations at L669/L672 (not L667-672) | **FIX** — refresh citations; §3.2 |

**Push-backs:** NONE on the adversarial findings. Every one survived independent
re-measurement; I apply all six.

**One CITATION correction I make (not a push-back — a precision fix to a kept-clean
claim):** the adversarial review and the original plan both cite Check 45 as
"23↔23." I did NOT reproduce that exact count with a crude grep proxy (raw
`grep -c "^## "` over the rationale file counts 25 headings; raw
`grep -c "[rationale: "` over CLAUDE.md counts 23 — but neither is the check's
actual logic, which is a deduplicated SET over the `## Pack memory` section vs
kebab-case `## <slug>` headings, validate-pack.py L7376-7389). The adversarial's
"23↔23" came from its baseline `validate-pack.py` run (exit 0), which I did not
re-run (RO; no post-edit tree). I therefore assert only the load-bearing
INVARIANT, which IS reproducible and is what matters for BD-240: the slug SET is
UNCHANGED — BD-240 adds/removes ZERO `[rationale: graph-first-context]` tag
(`grep -c` → 1 each in CLAUDE/AGENTS/GEMINI, unchanged) and ZERO `## graph-first-context`
heading (`grep -c "^## graph-first-context$"` → 1, unchanged), so set-equality is
undisturbed and Check 45 stays GREEN. I do NOT re-open the bijection (kept-clean per
the mandate); I only correct the citation from an unverified absolute count to the
verified invariant. The absolute-count verdict is the coder's `validate-pack.py`
run to confirm.

**Verified-clean parts KEPT INTACT (NOT re-opened, per mandate point 4):** the
8-surface census (EE-R8); the trinity byte-identity boundary (only the shared-core
fall-through sentence is byte-identical; openers + tails diverge per-CLI); the
Check 45 bijection (slug-set unchanged → equal); the single atomic `pack-only`
commit; the BD-238/BD-241 serialization; the `test-fixtures/manifest.txt` +
`.spawn-rule-manifest.txt` exclusions.

**NEW gap I found independently (neither author NOR adversarial flagged):**
- **G-NEW (same-stutter-class sweep — CLEARED, documented for the coder).** My
  mandate (point 2) is to find any OTHER REPLACE-run carrying the same boundary
  defect as B-1. I swept all five non-trivial edits. The stutter is UNIQUE to
  Surface 4 because its run is scoped to start MID-sentence (`query the graph
  FIRST…`, leaving the `**How to apply.** When …exists,` opener live) while the
  replacement self-supplies a second "When the graph exists." Every OTHER edit is
  boundary-safe: the trinity §2.2 run starts at a CLEAN SENTENCE boundary
  (`Fall through to grep/Read for:` is its own sentence; the preceding sentence
  ends `…never block on the graph (the G2 fallback). `, and §2.2 begins
  `**Two phases…**` — no clause collision); OPTIONAL-FEATURES §3.3 replaces a
  WHOLE `- ` bullet (clean item boundary); PACK-CHAT §3.4 + PACK-AGENTS §3.5 are
  pure APPENDS after `…full contract.`/`…(BD-225)".`; pack-docs-researcher §3.6 is
  a pure ADD of a new bullet. So B-1's "other replace-runs for the same class"
  concern resolves to: exactly one such run exists, and §3.2 below fixes its
  boundary. I add a PREFLIGHT gate (§5.2 gate 11) that greps the landed rationale
  for the double-"When" stutter to grep-zero — the measure-then-bound backstop.

---

## 1. Goal and BD items addressed

**Goal.** The `graph-first-context` rule is graph-first in name but grep-first in
practice: its flat fall-through list lets a P2 (verification/precision) need veto
the P1 (discovery/recall) phase entirely. Re-frame the rule to a two-phase model —
DISCOVERY/RECALL is graph-FIRST and mandatory when the graph exists; grep/Read is
the VERIFICATION/precision layer — and propagate that re-framing across ALL
surfaces that carry the escape-hatch framing, in ONE atomic commit.

**BD addressed:** BD-240 (sole). Acceptance criteria (BD-240 L18) fully covered:
- Rule re-framed to two-phase, discovery graph-first → §3.1 (trinity ×3).
- Fall-throughs no longer swallow recall → §3.1 items (i)-(v) bound to P2/out-of-graph.
- docs-researcher recall emphasis explicit → §3.6.
- Spawn-prompt-direction + Rules-Applied-attestation DECIDED + documented → §3.4/§3.5 (DIRECT use, BOTH surfaces) + design §4.3 (attest rides existing `rules-applied-verification-block`, no new CI check).
- Propagated to trinity ×3 with the BD-226 Claude-only path-injection caveat intact → §3.1 preserve-tails.
- `[rationale: graph-first-context]` bijection + reference surfaces updated lock-step → §3.2/§3.4/§3.5; `.spawn-rule-manifest.txt` measured-out (§3.7, design §3.7 overrides the BD-240 entry premise).
- `validate-pack` green → §5.

---

## 2. Affected surfaces (complete list — 8 EDIT + measured exclusions)

The complete live edit-surface census is design EE-R8 (independently re-verified at
HEAD af73ffb). **8 EDIT surfaces, ONE atomic commit.**

| # | Surface | Edit kind | Section |
|---|---|---|---|
| 1 | `CLAUDE.md` `## Pack memory` graph-first-context bullet | REPLACE shared-core fall-through sentence | §3.1 |
| 2 | `AGENTS.md` `## Pack memory` graph-first-context bullet | REPLACE shared-core fall-through sentence (byte-identical to #1) | §3.1 |
| 3 | `GEMINI.md` `## Pack memory` graph-first-context bullet | REPLACE shared-core fall-through sentence (byte-identical to #1) | §3.1 |
| 4 | `pack-ops/PACK-MEMORY-RATIONALE.md` `## graph-first-context` "How to apply" para | RE-SCOPE to phase model (opener-INCLUSIVE replace — B-1 fix) | §3.2 |
| 5 | `pack-ops/OPTIONAL-FEATURES.md` "When to skip Graphify" | RE-SCOPE escape-hatch bullet to phase model | §3.3 |
| 6 | `pack-ops/PACK-CHAT.md` graph-injection spawn **bullet** | EXTEND with DIRECT-use sentence (paraphrase + name pointer) | §3.4 |
| 7 | `pack-ops/PACK-AGENTS.md` graph-injection **bold-headed PARAGRAPH** (NOT a `- ` list item) | EXTEND with DIRECT-use sentence (paraphrase + name pointer) | §3.5 |
| 8 | `.claude/agents/pack-docs-researcher.md` Responsibilities | ADD one INTERNAL-recall bullet | §3.6 |

**Measured exclusions (NOT touched — confirmed at HEAD af73ffb):**
- `pack-ops/.spawn-rule-manifest.txt` — graph-first-context is NOT a manifest record (`grep -c graph-first` → 0); adding one forces a non-existent ref + is scope creep. Design §3.7 OVERRIDES the BD-240 entry's "+ `.spawn-rule-manifest.txt`" premise (L12/L18) measure-then-bound.
- `pack-ops/OPTIONAL-FEATURES.md` §Graphify pointer (L354-376) — VERIFY-only; the "governs WHEN to prefer the graph / when to fall through" pointer stays true post-edit. No edit.
- `test-fixtures/manifest.txt` — push-time (BD-228); reconciled by `scripts/manifest-sync.sh` at push iff a fixture INPUT changed. Coder does NOT regen per-commit.
- Out-of-repo memory cache (`MEMORY.md` thin pointer) — Pack-Chat upkeep (procedure step 3), not a coder edit.
- BD-240 `Status:` flip → Resolved — Pack-Chat bookkeeping after the batch is clean, not a coder edit.

---

## 3. The exact edit to each surface

> **Locate-by-content, not by line number.** Line numbers below are values MEASURED
> at HEAD af73ffb (for orientation), but they DRIFT. The coder RE-LOCATES every
> edit by the quoted content/anchor strings, never by a bare line number. A
> grep-zero completeness gate (§5 PREFLIGHT) is the measure-then-bound backstop.

### 3.0 Critical byte-identity fact (verified)

The three trinity files are **NOT** byte-identical across the WHOLE bullet — the
OPENER and the TAILS differ per-CLI:
- **CLAUDE.md opener (L637-638):** "When a knowledge graph exists, prefer the graph for orientation…"
- **AGENTS.md / GEMINI.md opener:** "If `$(git rev-parse --show-toplevel)/graphify-out/graph.json` exists, prefer the graph for orientation…"

BUT the **shared-core fall-through sentence is byte-identical across all three**
(verified `diff` of `sed`-extracts: CLAUDE↔AGENTS differ ONLY at the in-line tail
that begins after `graph). `; the sentence itself is identical; AGENTS↔GEMINI
identical including tail): it begins `Fall through to grep/Read for:` and runs
through `deliberately not in the graph).` —

```
Fall through to grep/Read for: exact-string / token
search (use grep — exact + complete); authoritative SSOT fields (a BD
`Status`, the README version table, a `_rules.md` contract — Read the
source); freshly-changed / uncommitted files (`git diff`/Read); whole-file
exact content (Read); archive-dir / excluded-category content (Read/grep —
deliberately not in the graph).
```

**This sentence — and ONLY this sentence — is the trinity REPLACE target.** It is
what is byte-identical; it becomes the §2.2 two-phase text (also byte-identical
across the three). The coder does NOT touch the per-CLI opener and does NOT touch
the per-CLI tail.

### 3.1 Surfaces 1-3 — trinity ×3 (CLAUDE.md / AGENTS.md / GEMINI.md) — REPLACE shared-core sentence

**Anchor (locate by content):** in each file's `## Pack memory` → `### Repo
conventions` → the bullet beginning `**Graph-first context when the knowledge graph
exists (BD-225).**`, find the sentence starting `Fall through to grep/Read for:`
and ending `deliberately not in the graph).` (the exact text quoted in §3.0).

**Edit:** REPLACE that one sentence (the flat 5-item fall-through) with the design
§2.2 two-phase text below — **byte-identical in all three files**, applied
lock-step in the same commit. The text is the DECIDED M-1 = (c) BOTH (structural
re-bind + anti-rationalization sentence):

> **Two phases — the second never vetoes the first.** **(1) DISCOVERY / RECALL** — "what are ALL the surfaces related to X / where does Y live / blast radius of Z / what depends on W" — is **graph-FIRST and mandatory when the graph exists**: run a `graphify query`/`path`/`affected` to establish the candidate surface set BEFORE broad tree reads. grep/Read is NOT a substitute for the graph in this phase — an a-priori grep pattern bounds recall to what you already thought to search for, which is exactly the recall the graph exists to widen. **(2) VERIFICATION / PRECISION** — the exact bytes, line counts, or authoritative SSOT VALUE at an ALREADY-IDENTIFIED surface — is grep/Read's job; use it to confirm what discovery surfaced. Fall through to grep/Read (skipping the graph) ONLY for these — each a P2 or out-of-graph need, none a license to skip P1: **(i)** a VERIFICATION read of a named surface (exact bytes/counts — Read/grep AFTER discovery named it); **(ii)** an authoritative SSOT field VALUE (a BD `Status`, the README version table, a `_rules.md` contract — Read the source); **(iii)** freshly-changed / uncommitted files (`git diff`/Read — not yet in the graph); **(iv)** whole-file exact content of a named file (Read — after discovery named it); **(v)** content the graph deliberately does NOT index (archive-dir / excluded-category — Read/grep). A completeness census that must enumerate every literal occurrence (e.g. a rename completeness gate that greps every literal hit to grep-zero) RUNS the grep as its VERIFICATION gate but does NOT replace discovery: when the graph exists, the census runs the graph FIRST to find the candidate surfaces, THEN greps each to grep-zero — "my task is exhaustive enumeration, so I'll grep the whole tree" is the prohibited move, because the graph exists precisely to widen enumeration beyond your a-priori pattern.

**IN-LINE REPLACE BOUNDARY (MINOR-3 — name it so the coder edits at the STRING
boundary, not the line boundary):** the replace boundary is the literal string
`deliberately not in the graph).` — the per-CLI tail begins IMMEDIATELY AFTER, on
the SAME physical line (verified): CLAUDE.md L650 continues `… not in the graph). **Path-injection under worktree isolation`;
AGENTS.md L568 + GEMINI.md L545 continue `… not in the graph). The \`--graph\` path is ALWAYS absolute`.
The coder REPLACES up to and INCLUDING `not in the graph).` and PRESERVES
everything from the following space onward VERBATIM. A line-oriented replace keyed
on the whole L645-650 block risks truncating or duplicating the tail's opening
words — edit at the sentence-STRING boundary.

**PRESERVE VERBATIM (do NOT edit) — per-CLI material around the replaced sentence:**
- **The opener** in each file (CLAUDE: "When a knowledge graph exists, prefer…"; AGENTS/GEMINI: "If `$(git rev-parse…)/graphify-out/graph.json` exists, prefer…") — through `(the G2 fallback). ` immediately BEFORE the replaced sentence. UNCHANGED.
- **CLAUDE.md tail (from L650):** the `**Path-injection under worktree isolation (BD-226):**` sub-clause + the Claude-only worktree caveat ("Do NOT 'restore parity' by porting this injection contract") + `--budget`/backend + invocation note. UNCHANGED.
- **AGENTS.md tail (from L568):** the non-injection `The \`--graph\` path is ALWAYS absolute…` form + Codex invocation note + BD-233 cross-CLI note. UNCHANGED. Do NOT port the CLAUDE-only worktree injection contract here.
- **GEMINI.md tail (from L545):** the non-injection `--graph` form + Antigravity invocation note + BD-233 note. UNCHANGED. Do NOT port the injection contract here.
- **The `[roles: universal] [rationale: graph-first-context]` tag** terminating each bullet. UNCHANGED (preserves Check 45 bijection + role-tag vocab).
- **The G1 existence guard + G2 fallback** sentences (inside the opener). UNCHANGED.

**cross-cli-reference-normalization — N/A (design §2.5):** the §2.2 shared-core
text contains NO per-CLI path/command token (it cites generic `graphify
query`/`path`/`affected`), so byte-identical IS the correct parity target. The
coder must NOT "normalize" anything in the shared core. The per-CLI divergence
stays confined to the untouched opener + tails.

**Enforcing checks:** trinity parity (body byte-identity of the shared core) +
Check 18 (H2 parity — unaffected; the edit is inside an H3 `### Repo conventions`
bullet) + Check 45 (tag unchanged).

### 3.2 Surface 4 — `pack-ops/PACK-MEMORY-RATIONALE.md` `## graph-first-context` "How to apply" — RE-SCOPE (B-1 / BLOCKER-1 FIXED)

**Anchor (locate by content):** the `## graph-first-context` section heading
(measured **L638**) → the `**How to apply.**` paragraph. The paragraph CURRENTLY
opens (measured **L652-659**):

```
**How to apply.** When `$(git rev-parse --show-toplevel)/graphify-out/graph.json`
exists, query the graph FIRST for "what relates to X / where does Y live /
blast radius of Z" before broad tree reads; fall through to grep/Read for the
exceptions (exact-string/token search → grep; authoritative SSOT fields … → Read
the source; freshly-changed/uncommitted files → `git diff`/Read; whole-file exact
content → Read; archive-dir / excluded-category content → Read/grep, deliberately
not in the graph).
```

This para is the rationale-side carrier of the escape-hatch framing (the N-2 analog
of B-1) — it reproduces the SAME flat exception list as the trinity body.

**B-1 / BLOCKER-1 FIX — the REPLACE-run boundary (option (a), stated explicitly).**
The original plan §3.2 scoped the run to START at `query the graph FIRST for "what
relates to X…` — which LEAVES the opener clause `**How to apply.** When $(git
rev-parse …)/graphify-out/graph.json exists,` live; the replacement text then
RE-OPENS with `When the graph exists,` → a double-"When … exists, When the graph
exists" stutter / orphaned dependent clause in the SSOT rationale. This does NOT
trip a CI hard-fail (PACK-MEMORY-RATIONALE.md is NOT in `_CHECK_46_ANTI_RESTATE_SURFACES`
— verified validate-pack.py L7459-7466 — and Check 45 keys on the unchanged
heading), so it would ship a broken rationale. **FIX: extend the REPLACE-run
LEFTWARD to the existing opener.** REPLACE the run from (and INCLUDING) `When
\`$(git rev-parse --show-toplevel)/graphify-out/graph.json\` exists,` through
`…deliberately not in the graph).` with the replacement text below. **KEEP the
literal `**How to apply.** ` lead-in** (the bold label) immediately before the
replacement; the replacement self-supplies the single "When the graph exists, …"
clause. Net: ONE "When … exists" clause, no stutter.

**Replacement text (begins right after the preserved `**How to apply.** ` label):**

> When the graph exists, DISCOVERY/RECALL ("what relates to X / where does Y live / blast radius of Z") is graph-FIRST and mandatory: query the graph to establish the candidate surface set before broad tree reads. grep/Read is the VERIFICATION layer — exact bytes/counts at a named surface, an authoritative SSOT field VALUE (a BD `Status`, the README version table, a `_rules.md` contract), freshly-changed/uncommitted files (`git diff`/Read), whole-file content of a named file, and content the graph does not index (archive/excluded) — none of which licenses skipping graph-first discovery; a literal-occurrence census runs the graph FIRST to find candidates, THEN greps each to grep-zero.

**Result (landed prose, for the coder's mental model):**
`**How to apply.** When the graph exists, DISCOVERY/RECALL ("what relates to X …") is graph-FIRST and mandatory: … THEN greps each to grep-zero. If the graph is absent or a query fails or returns nothing useful, use normal tools (G1 + G2). …`
— i.e. the preserved `**How to apply.** ` label, then ONE "When the graph exists,"
clause, dovetailing into the preserved G1/G2 sentence that follows. No double-"When".

**PRESERVE (do NOT edit):**
- The `## graph-first-context` HEADING at L638 (bijection slug — Check 45). UNCHANGED.
- The `**How to apply.** ` BOLD LABEL itself (only the clause AFTER it is replaced). UNCHANGED.
- The `**Why.**` paragraph, the worked example, the boundary note, the `--budget`/backend lines, and the `**Rejected alternatives.**` paragraph. UNCHANGED.
- The G1/G2 sentence (`If the graph is absent or a query fails…`) that immediately FOLLOWS the replaced run. UNCHANGED.
- The PRE-EXISTING `cross-cli-reference-normalization` (measured **L669**) + `bd-pack-only` (measured **L672**) slug citations in this section — those slugs DO exist in the corpus and are CORRECT. Leave them.

**Do NOT add the `rename-plans-measure-then-bound` slug here** (M-3 applies to the
rationale too — plain language only; verified the slug is 0-hits in all six
corpus/rationale/reference files).

**MINOR-4 (line-citation refresh):** heading **L638**; "How to apply" para **L652**;
pre-existing slug citations **L669 / L672** (the original plan's "L652-659" for the
para and "L667-672" for the citations drift 1-2 lines; absorbed by
content-anchoring, refreshed here for accuracy).

**Enforcing check:** Check 45 bijection — slug set unchanged (exactly one
`## graph-first-context` ↔ one `[rationale: graph-first-context]` per trinity file).
The body edit does not add/remove a heading.

### 3.3 Surface 5 — `pack-ops/OPTIONAL-FEATURES.md` "When to skip Graphify" — RE-SCOPE

**Anchor (locate by content):** the `**When to skip Graphify.**` heading (measured
L565) → the SECOND bullet (measured L567-571) beginning `The task is an exact-string
/ token search, an authoritative SSOT-field read…` and ending `…not the graph.`

**Edit:** REPLACE that one whole `- ` bullet with a bullet that re-frames those
items as VERIFICATION/precision or out-of-graph reads — NOT a license to skip
graph-first DISCOVERY when the graph exists (design §3.3). (Whole-bullet replace =
clean item boundary, no opener-stutter risk — confirmed by the G-NEW sweep.)

> - The work is purely a VERIFICATION read at a surface you have already identified — exact bytes/counts, an authoritative SSOT-field VALUE (a BD `Status`, the README version table, a `_rules.md` contract), a freshly-changed/uncommitted file, whole-file content of a named file, or content the graph does not index — which falls through to grep / Read / `git diff`. (This is precision AFTER discovery, not a reason to skip graph-first DISCOVERY when the graph exists — see the graph-first rule's two-phase model.)

**PRESERVE (do NOT edit):**
- The first bullet (measured L566): "You are doing a one-off task and do not want to run the one-time build." — a legitimate NO-GRAPH case. UNCHANGED.
- The third bullet (measured L572-573): "You are on a fresh clone with no graph built — the graph-first rule degrades to ordinary grep/Read with zero friction." — legitimate G1 case. UNCHANGED.
- The `**When to skip Graphify.**` heading. UNCHANGED.

**CI safety (design EE-R2 / N-1):** OPTIONAL-FEATURES.md is NOT in
`_CHECK_46_ANTI_RESTATE_SURFACES` (verified — the set is exactly PACK-AGENTS.md,
PACK-CHAT.md, + 4 skill SKILL.md files, validate-pack.py L7459-7466), so this edit
cannot trip Check 46. Check 44's ceiling for this file is 271 and ADVISORY ONLY
("never fails", validate-pack.py L7796); the file is already 573 lines and the
re-scope is length-neutral. Zero CI risk. (Do not mistake the Check-44 WARN for a
failure.)

**Enforcing check:** none gating (prose runbook). The coder VERIFIES coherence with
the re-framed trinity rule (no contradiction).

### 3.4 Surface 6 — `pack-ops/PACK-CHAT.md` graph-injection spawn bullet — EXTEND (DIRECT-use)

**Anchor (locate by content):** the `- ` LIST BULLET beginning `**Inject the graph
path into the prompt (BD-226, Claude-only).**` (measured L295-305), ending `See
trinity \`## Pack memory\` § "Graph-first context (BD-225)".` (This IS a `- ` list
item — contrast PACK-AGENTS.md §3.5.)

**Edit:** APPEND one sentence to the END of that bullet (after the existing "See
trinity…" pointer), DIRECTING graph use for recall-heavy spawns (design §3.4):

> For a recall-heavy / blast-radius / inventory spawn (notably a docs-researcher INTERNAL pass), the prompt MUST also DIRECT the agent to run the graph for the DISCOVERY phase — not merely make the path available — and the spawn's "Rules in force" block carries `graph-first-context` so the agent's Rules-Applied block must attest how discovery was performed.

**ANTI-RESTATE CONSTRAINT (Check 46 — PACK-CHAT.md IS scanned) — CORRECTED MODEL
(MAJOR-1 FIXED):** Check 46 does NOT scan the appended sentence against "the §2.2
two-phase body." It extracts each `## Pack memory` bullet's BODY (text AFTER the
bold rule name), whitespace-normalizes, and **TRUNCATES to the first 120 chars**
(`normalized = re.sub(r"\s+"," ",body).strip()[:120]`, validate-pack.py L7553),
keeping it iff ≥60 chars (`_CHECK_46_ANTI_RESTATE_MIN_LEN = 60`, L7484). For the
graph-first-context bullet the candidate is therefore the FIRST 120 chars of the
body — i.e. the per-CLI **OPENER**, which BD-240 does NOT touch. The EXACT candidate
(computed empirically at HEAD af73ffb):

```
'When a knowledge graph exists, prefer the graph for orientation / relationship / blast-radius / "what relates to X" / "w'  (len 120)
```

The §2.2 two-phase replacement text sits DEEP in the bullet body (well past char
120) and is **never a Check 46 candidate at all.** The append MUST NOT reproduce
≥60 contiguous whitespace-normalized chars of THAT opener candidate. The sentence
above names the rule (`graph-first-context`) and paraphrases the phase concept — it
does not copy the opener. **Binding net:** PREFLIGHT gate 10 runs `validate-pack.py`
Check 46 DIRECTLY and confirms PASS — that is the gate that actually holds; the
hand-check (gate 5) targets the OPENER (the real candidate), not the §2.2 body.
Fallback if it ever trips: shorten to a pure name pointer ("see trinity §
'Graph-first context'").

**PRESERVE:** the entire existing bullet body (the BD-226 path-injection mechanics)
UNCHANGED — this is a pure APPEND.

**Enforcing check:** Check 46 anti-restate + reference-resolution.

### 3.5 Surface 7 — `pack-ops/PACK-AGENTS.md` graph-injection paragraph — EXTEND (DECIDED edit-for-parity)

**Anchor (locate by content) — MINOR-2 FIXED:** the **bold-headed PARAGRAPH** at
PACK-AGENTS.md **L62-71** beginning `**Inject the graph path into every spawn prompt
(BD-226, Claude-only).**` on its OWN line, with prose continuing L63-71, ending
`See trinity \`## Pack memory\` § "Graph-first context (BD-225)" for the full
contract.` **This is NOT a `- ` list item** (unlike PACK-CHAT.md §3.4) — it is a
`**bold-lead.**` paragraph. APPEND the sentence at the END of the PARAGRAPH BODY,
after `…for the full contract.`. A coder pattern-matching "bullet" must NOT hunt for
a `- ` marker that isn't there.

**Decision (design §3.5):** EDIT this paragraph too — do NOT leave it diverged from
PACK-CHAT.md. The propagation procedure surface table (PACK-CHAT.md L504) names BOTH
"`PACK-AGENTS.md` / `PACK-CHAT.md` one-line refs" as the reference-surface PAIR;
both are byte-parallel BD-226 injection directives; both are in
`_CHECK_46_ANTI_RESTATE_SURFACES`. Editing only PACK-CHAT.md diverges two
orchestrator-guidance surfaces — the exact drift the procedure prevents.

**Edit:** APPEND the SAME DIRECT-use sentence as §3.4 (the recall-heavy
DISCOVERY-direction sentence) to the END of this paragraph, as a paraphrase + name
pointer.

**ANTI-RESTATE CONSTRAINT (Check 46 — PACK-AGENTS.md IS scanned) — CORRECTED MODEL:**
identical to §3.4 — Check 46 scans the first-120-char OPENER candidate (above),
which BD-240 does NOT touch; the append must not reproduce ≥60 contiguous chars of
THAT opener. Name reference + paraphrase; the coder runs `validate-pack.py` Check 46
directly (gate 10) as the binding net.

**PRESERVE:** the entire existing paragraph body UNCHANGED — pure APPEND.

**Enforcing check:** Check 46 anti-restate + reference-resolution.

### 3.6 Surface 8 — `.claude/agents/pack-docs-researcher.md` — ADD one Responsibilities bullet

**Anchor (locate by content):** the `Responsibilities:` list; add the new bullet
AFTER the existing final SUBSTANTIVE Responsibilities bullet (measured: after
"Return concise answers with exact sources (URLs, doc section names, or file
references)." at L23-24) and BEFORE the closer "Do not make file edits unless
explicitly asked." (L25) — i.e. at the END of the substantive Responsibilities,
immediately before the "Do not make file edits" closer. (Pure ADD — no stutter.)

**Edit:** ADD this one bullet (design §3.6):

> - For an INTERNAL repo recall / blast-radius / "find every surface that relates to X" pass (as opposed to EXTERNAL CLI-doc verification), the knowledge graph is the PRIMARY discovery tool when it exists (per trinity `## Pack memory` § "Graph-first context"): run a `graphify query` against the orchestrator-injected `--graph` path FIRST and use grep/Read to verify what it surfaces. Doing the whole recall in grep is a recall defect, not a tool choice.

**PRESERVE:** the YAML frontmatter (the agent already carries `Bash` in `tools:` at
L4 — verified `tools: Read, Grep, Glob, WebSearch, Bash`; NO frontmatter change
needed) and all other Responsibilities bullets UNCHANGED. No `x-` client contract
exists on this pack agent def, so `skill-agent-maintenance-mechanical` is satisfied
by the one-bullet add (no structural change).

**Enforcing check:** mechanical (`skill-agent-maintenance-mechanical`). Keep it a
NAME reference to the trinity rule — not a verbatim body copy (this file is NOT in
the Check 46 scan set, but keep it a name pointer for consistency).

### 3.7 VERIFY-only (no edit) — `pack-ops/OPTIONAL-FEATURES.md` §Graphify pointer

**Anchor:** `## Graphify — knowledge-graph context (pack-dev)` → `**What it is.**`
para → the sentence (measured ~L372-376): "The graph-first rule in the pack-root
trinity (`### Repo conventions`, tagged `[rationale: graph-first-context]`) governs
WHEN to prefer the graph and when to fall through to grep/Read…"

**Action:** VERIFY this reads true post-edit. It does — the re-framed rule STILL
"governs WHEN to prefer the graph and when to fall through" (the two-phase model is
a sharper statement of WHEN, not a change to the pointer's claim). **No edit
expected.** If the coder judges any word now inaccurate, surface it (do NOT silently
edit — it is out of the design's scoped edit set).

---

## 4. Commit sequencing — ONE atomic commit

**The design mandates a SINGLE atomic commit** (design §3 / §6 / §8). All 8
surfaces land together because a half-applied state — e.g. trinity says "DISCOVERY
is P1-mandatory" while OPTIONAL-FEATURES still says "skip Graphify for
exact-string" — is exactly the incoherence the rule-change propagation procedure
forbids (PACK-CHAT.md: corpus + rationale + references in the SAME commit so
bijection / anti-restate / parity never see a half-applied state).

**Why not split:** Check 45 (bijection), Check 46 (anti-restate), and trinity
parity are END-STATE checks. A split that lands the trinity edit without the
rationale re-scope would leave the rationale's flat-list framing live against a
re-framed corpus — a coherence defect even if no validator hard-fails on the
intermediate. The propagation procedure's "documented, not gate-sequenced" order
resolves to a single atomic commit here.

**Commit:**
- **Count:** 1.
- **Scope keyword:** `pack-only` (verified §0 — no `project-template/` or `supporting-docs/` touched; all 8 surfaces are pack-ops: pack-root trinity, `pack-ops/*`, `.claude/agents/*`).
- **Subject shape:** `fix: v11 — BD-240 re-frame graph-first-context (two-phase: discovery graph-first, grep/Read verification) (pack-only)` — or the batch-appropriate `fix:` suffix Pack Chat selects. (The keyword token `pack-only` anywhere in the subject is a Check 36 claim; the diff must touch only pack-only paths — it does.)
- **Paths in the commit (exactly 8 files):** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `pack-ops/PACK-MEMORY-RATIONALE.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `.claude/agents/pack-docs-researcher.md`. No `test-fixtures/manifest.txt`, no `.spawn-rule-manifest.txt`, no backlog/changelog.

---

## 5. Verification strategy

### 5.1 validate-pack checks (post-edit projection)

| Check | Verdict | Why |
|---|---|---|
| **Check 45** — rule↔rationale bijection (slug-set equality) | GREEN | Slug SET UNCHANGED: BD-240 adds/removes ZERO `[rationale: graph-first-context]` tag (verified `grep -c` → 1 each in CLAUDE/AGENTS/GEMINI) and ZERO `## graph-first-context` heading (verified → 1). Bodies edited; no slug added/removed; M-3 removes a NON-slug body-prose citation only. Check 45 builds deduplicated SETS over the `## Pack memory` `[rationale:]` slugs vs kebab-case `## <slug>` headings and requires set-equality (validate-pack.py L7376-7421). The absolute count is the coder's `validate-pack.py` run to confirm; the INVARIANT (set undisturbed) is what BD-240 guarantees. |
| **Check 46** — anti-restate (≥60-char body match against the first-120-char OPENER) | GREEN, GATED ON PREFLIGHT | PACK-CHAT.md + PACK-AGENTS.md are the ONLY edited surfaces in `_CHECK_46_ANTI_RESTATE_SURFACES` (verified set = PACK-AGENTS.md, PACK-CHAT.md, commit-discipline/review/planning/implementation-report SKILL.md). Check 46 scans the first-120-char whitespace-normalized OPENER of each `## Pack memory` bullet (`[:120]`, validate-pack.py L7553), NOT the §2.2 body. For graph-first-context that opener is UNCHANGED by BD-240 (`When a knowledge graph exists, prefer the graph for orientation / relationship / blast-radius / "what relates to X" / "w`). The appends are NAME + paraphrase and reproduce < 60 contiguous chars of THAT opener. OPTIONAL-FEATURES.md + PACK-MEMORY-RATIONALE.md + pack-docs-researcher.md are NOT in the scan set. Binding net = PREFLIGHT gate 10 (direct Check 46 run). |
| **Check 46** — reference-resolution | GREEN | `.spawn-rule-manifest.txt` UNTOUCHED — its 7 records are unaffected. |
| **Check 18** — trinity H2 structure parity | GREEN | Keys on H2 heading names + order within a trinity location. The edit is inside an existing H3 `### Repo conventions` bullet body — no H2 heading changes. |
| **Trinity parity (body)** | GREEN | §2.2 shared-core text byte-identical across CLAUDE/AGENTS/GEMINI; per-CLI opener + tails preserved. |
| **Check 44** — durable-doc concision | GREEN (ADVISORY) | OPTIONAL-FEATURES.md ceiling = 271, ADVISORY only ("never fails", validate-pack.py L7796); file already 573 lines; the length-neutral re-scope does NOT change the (non-gating) verdict. **Informational — never a gate. Do not mistake the WARN for a failure.** |
| **Check 36** — commit-subject scope keyword | GREEN | `pack-only` claim matches the diff (8 pack-ops files; no `project-template/` / `supporting-docs/`). |
| **Check 62 / manifest** | GREEN | Push-time (BD-228); no fixture input changed; coder does NOT regen. |
| **Check 63** — graphify-out never-tracked | GREEN | No `graphify-out/` change. |

**No new CI check** (design §5 measure-then-bound: the "graph-queries-ran" check is
unbuildable — no committed telemetry, gitignored graph, no-graph clone false-fires;
the manifest record forces a non-existent ref). Enforcement teeth ride existing
checks + the human-triaged `rules-applied-verification-block`.

### 5.2 Coder PREFLIGHT grep gates (run BEFORE the IMPL-REPORT; ALL must pass)

The PREFLIGHT line is emitted ONLY after all 8 edits + verification PASS. The
measure-then-bound completeness backstop is the grep-zero / grep-confirm set below
(anchored on content, not hand-enumerated line numbers):

1. **Trinity shared-core byte-identity (parity gate).** Extract the §2.2 two-phase block from each of CLAUDE.md / AGENTS.md / GEMINI.md and confirm byte-identical across the three — e.g. `diff <(sed -n '/Two phases — the second never vetoes/,/prohibited move, because the graph exists/p' CLAUDE.md) <(sed -n '...same...' AGENTS.md)` → empty diff; repeat AGENTS↔GEMINI. EXPECT: zero diff.
2. **Rename-slug grep-ZERO (M-3 completeness gate).** `grep -rln "rename-plans-measure-then-bound" CLAUDE.md AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md` → EXPECT zero hits (the slug must NOT have been introduced into any corpus/rationale/reference file).
3. **Tag survival.** `grep -c "\[rationale: graph-first-context\]" CLAUDE.md AGENTS.md GEMINI.md` → EXPECT 1 each; `grep -c "\[roles: universal\] \[rationale: graph-first-context\]" CLAUDE.md AGENTS.md GEMINI.md` → EXPECT 1 each.
4. **Bijection slug survival.** `grep -c "^## graph-first-context$" pack-ops/PACK-MEMORY-RATIONALE.md` → EXPECT 1 (heading untouched).
5. **Anti-restate paraphrase HAND-CHECK (PACK-CHAT.md + PACK-AGENTS.md) — TARGETS THE OPENER (MAJOR-1 corrected).** Confirm the appended DIRECT-use sentence does NOT contain a ≥60-char contiguous whitespace-normalized substring of the first-120-char trinity OPENER candidate `When a knowledge graph exists, prefer the graph for orientation / relationship / blast-radius / "what relates to X" / "w` (NOT the §2.2 body — the §2.2 body is never a Check 46 candidate). The appended sentence's longest verbatim overlap with that opener is the rule NAME + short generic tokens — well under 60. This hand-check is advisory; gate 10 is the binding net.
6. **Per-CLI tail preservation.** `grep -c "Path-injection under worktree isolation" CLAUDE.md` → EXPECT 1 (CLAUDE tail intact); `grep -c "Path-injection under worktree isolation" AGENTS.md GEMINI.md` → EXPECT 0 each (the Claude-only injection contract was NOT ported). `grep -c "The \`--graph\` path is ALWAYS absolute" AGENTS.md GEMINI.md` → EXPECT 1 each (non-injection tails intact).
7. **Pre-existing rationale citations preserved.** `grep -c "cross-cli-reference-normalization\|bd-pack-only" pack-ops/PACK-MEMORY-RATIONALE.md` → EXPECT ≥1 each (those legit slugs in this section were NOT removed).
8. **Product-clean (scope gate).** `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` → EXPECT zero hits (pack-only claim holds).
9. **OPTIONAL-FEATURES skip-list re-scoped (MINOR-1 corrected — clean grep-zero + grep-confirm pair).** Three checks:
   (a) `grep -c "exceptions, not the graph\." pack-ops/OPTIONAL-FEATURES.md` → EXPECT **0** (old escape-hatch phrasing GONE — it returns 1 PRE-edit, verified);
   (b) `grep -c "precision AFTER discovery, not a reason to skip graph-first DISCOVERY" pack-ops/OPTIONAL-FEATURES.md` → EXPECT **1** (new wording present);
   (c) `grep -c "one-off task\|fresh clone with no graph" pack-ops/OPTIONAL-FEATURES.md` → EXPECT **2** (legitimate NO-GRAPH bullets retained).
10. **validate-pack full PREFLIGHT (BINDING net for Check 46 / 45 / parity).** Run `python3 scripts/validate-pack.py` — Check 43 + 45 + 46 + 18 + trinity parity PASS; full battery green. If any paraphrase trips Check 46, SHORTEN it to a pure name pointer ("see trinity § 'Graph-first context'") and re-run.
11. **Rationale double-"When" stutter grep-ZERO (B-1 / G-NEW completeness gate).** After the §3.2 edit, confirm the landed "How to apply" para does NOT carry the double-clause: `grep -c "graph.json\` exists, *When the graph exists" pack-ops/PACK-MEMORY-RATIONALE.md` (or `grep -Pzo "exists,\s*\n?\s*When the graph exists" …`) → EXPECT **0**; and `grep -c "^\*\*How to apply\.\*\* When the graph exists" pack-ops/PACK-MEMORY-RATIONALE.md` → EXPECT **1** (the corrected single-"When" opener present). EXPECT exactly ONE "When … exists" clause in the para.

### 5.3 Reviewer manual checks

- Grep-diff the §2.2 shared core across the three trinity files (byte-identity).
- READ the PACK-MEMORY-RATIONALE.md "How to apply" para top-to-bottom and confirm NO double-"When … exists" stutter — the single corrected clause dovetails into the preserved G1/G2 sentence (B-1).
- Read the OPTIONAL-FEATURES.md skip-list + §Graphify pointer for COHERENCE with the re-framed trinity rule (no surviving contradiction; the §Graphify pointer still reads true).
- Confirm the PACK-CHAT.md + PACK-AGENTS.md DIRECT-use sentences are paraphrase + name pointer (not body copy); independently re-run Check 46. Confirm the PACK-AGENTS.md append landed at the END of the bold-headed PARAGRAPH (not mis-placed at a non-existent list boundary).
- Confirm the docs-researcher bullet names the trinity rule (not a verbatim body restatement) and frontmatter is unchanged.
- Confirm BD-240 acceptance criteria (BD-240 L18) are each satisfied by the landed edits.

---

## 6. Rule-10 parallelization / dependency map (for Pack Chat scheduling)

**BD-240 internal:** a SINGLE-coder atomic effort — one logical re-framing across 8
surfaces in ONE commit. It does NOT internally parallelize (the surfaces are one
coherent edit that must land together).

**Cross-BD serialization (HARD same-file collisions — verified open-BD census at HEAD af73ffb):**

| BD | Status | Files overlapping BD-240 | Schedule |
|---|---|---|---|
| **BD-240** (this) | Open | — | one atomic commit |
| **BD-238** | Open | trinity ×3 `## Pack memory` (new rule) + PACK-MEMORY-RATIONALE.md (new slug bijection) + PACK-CHAT.md / PACK-AGENTS.md lifecycle section (verified BD-238 L27) | **SERIALIZE** |
| **BD-241** | Open | trinity ×3 `## Pack memory` (Claude-only sub-section) + PACK-MEMORY-RATIONALE.md (new slug) (verified BD-241 L3/L12) | **SERIALIZE** |

**Non-colliding open BDs (do NOT serialize on trinity):** BD-202/205/210/222/223/224/232/234/236/239 — none edits the live pack trinity `## Pack memory` + PACK-MEMORY-RATIONALE.md (BD-210 excludes the live trinity + pack-ops governance docs; BD-232 is out-of-repo memory only; BD-239 edits PROJECT trinity, not pack trinity; the rest edit scripts/validators/fixtures).

**Directive to Pack Chat:** BD-238 / BD-240 / BD-241 coders **MUST NOT run as
concurrent worktree waves** — they edit the same trinity ×3 + PACK-MEMORY-RATIONALE.md
(and BD-238 also PACK-CHAT.md / PACK-AGENTS.md, both BD-240-edited). Run them as
**serial commits**: land one (reviewed clean, patch applied, commit exit 0), THEN
spawn the next coder against the resulting HEAD with `worktree.baseRef:"head"` so it
sees the prior edit. The user noted 2026-06-20 that BD-240 runs NEXT (it GATES
BD-206); confirm the BD-238 / BD-241 ordering relative to BD-240 at scheduling.
Hand-merging two concurrent trinity patches is the conflict the worktree-isolation
protocol forbids (STOP + re-spawn fresh, never hand-merge).

**General rule (stated for Pack Chat):** any open BD whose Type names "trinity" or a
new `## Pack memory` rule/slug serializes with BD-240 on trinity ×3 +
PACK-MEMORY-RATIONALE.md. The census proves the CURRENT collision set is exactly
{BD-238, BD-241}.

---

## 7. Worktree / coder execution note (BD-226 model)

- **Single coder, isolated worktree.** This commit's first (and only) coder runs in an ISOLATED worktree (Agent-tool `isolation:"worktree"` — the trigger; `worktree.baseRef:"head"` so it bases at local HEAD af73ffb, not origin/main). It is one coder — the 8-surface edit is one atomic unit.
- **Bounded review/fix cycle IN-WORKTREE.** The whole review/fix cycle runs INSIDE that one worktree: coder → reviewer (RO, runs in the worktree where the uncommitted work lives — cd in + verify pwd/HEAD) → triage → fix-coder (REUSES the same worktree, never a new one) → final reviewer. Bound: ≤2 review/fix pairs + 1 final reviewer pass. Nothing reaches the canonical tree mid-cycle.
- **No up-front patch.** The coder produces NO patch on return. The patch is produced ONLY after a reviewer confirms CLEAN — Pack Chat SendMessage-s the most-recent read-write agent to run `git diff > <handoff>/changes.patch` at that point; Pack Chat applies the reviewed-clean patch and commits with user approval. Agents never commit.
- **Worktree teardown gate.** Remove the worktree ONLY after the commit is CONFIRMED landed (exit 0). A failed/aborted commit KEEPS the worktree as the recovery fallback.
- **No regen of `test-fixtures/manifest.txt`** in-cycle (push-time, BD-228).

---

## 8. Open risks / unknowns

- **R-1 (anti-restate trip risk — LOW, mitigated).** If the §3.4/§3.5 DIRECT-use sentence is phrased too close to the trinity OPENER candidate, Check 46 could fire on PACK-CHAT.md / PACK-AGENTS.md. Mitigation: the sentence is a paraphrase + name pointer; PREFLIGHT gate 5 (against the OPENER, the real candidate) + gate 10's direct Check 46 run catch it; the fallback is to shorten to a pure name pointer. Not a blocker.
- **R-2 (trinity body parity drift — LOW, mitigated).** The §2.2 block must be byte-identical across three files; a stray character diverges parity. Mitigation: PREFLIGHT gate 1 (diff the extracted blocks). The coder edits all three lock-step in one cycle.
- **R-3 (per-CLI tail contamination — LOW, mitigated).** The coder must REPLACE only the shared-core sentence up to and INCLUDING `not in the graph).` and not bleed into the per-CLI opener/tail (which begins on the SAME physical line — §3.1 in-line boundary; especially NOT port the CLAUDE-only BD-226 injection contract into AGENTS/GEMINI). Mitigation: §3.1 string-boundary instruction + PREFLIGHT gate 6.
- **R-4 (rationale double-"When" stutter — LOW, FIXED + gated).** The B-1 defect (a mid-sentence replace-run leaving the opener live) is closed by §3.2's opener-INCLUSIVE replace boundary. Mitigation: PREFLIGHT gate 11 (stutter grep-zero) + reviewer manual read (§5.3).
- **R-5 (serialization collision — MEDIUM, scheduling-owned).** If BD-238 or BD-241 runs concurrently, two trinity patches collide. Mitigation: §6 directive — serial commits, base each on the prior's landed HEAD; never hand-merge.
- **R-6 (M-1 mechanic is DECIDED — no open question).** The calling prompt fixes M-1 = (c) BOTH; the §2.2 text already encodes it. No user decision remains for the coder. (Design §9's "open decisions" 2 and 3 — BD-238/241 ordering and the DIRECT-use trigger phrasing — are Pack-Chat scheduling / already-encoded-as-written; neither blocks the coder.)
- **No unknowns block the coder.** Every state-claim is measured at HEAD af73ffb; the text is decided; the surface set is closed (design EE-R8 + this plan's re-verification).

---

## 9. Findings-closure ledger (every adversarial-plan finding → disposition)

| Finding | Severity | Disposition | Where closed |
|---|---|---|---|
| B-1 / BLOCKER-1 (Surface-4 double-"When" stutter) | BLOCKER | FIXED — REPLACE-run extended LEFTWARD to the opener (option (a)); `**How to apply.** ` label kept; replacement self-supplies ONE "When the graph exists" clause; PREFLIGHT gate 11 grep-zeros the stutter | §3.2, §5.2 gate 11, §5.3 |
| MAJOR-1 (anti-restate model targets the wrong text) | MAJOR | FIXED — model restated: Check 46 scans the first-120-char OPENER (`[:120]`), which BD-240 does NOT touch; the §2.2 body is never a candidate; the append must not reproduce ≥60 chars of the OPENER; gate 10's direct Check 46 run is the binding net; GREEN verdict preserved | §3.4, §3.5, §5.1 Check-46 row, §5.2 gate 5/10 |
| MINOR-1 (gate-9 grep malformed) | MINOR | FIXED — replaced with a clean grep-zero (old phrase gone) + grep-confirm (new phrase) + retained-bullets pair | §5.2 gate 9 |
| MINOR-2 (PACK-AGENTS.md is a paragraph, not a list bullet) | MINOR | FIXED — named the bold-headed PARAGRAPH (L62-71, no `- ` marker); append lands at end of paragraph body | §3.5, §2 table row 7 |
| MINOR-3 (in-line shared-core/tail boundary) | MINOR | FIXED — named the string boundary `deliberately not in the graph).` with the per-CLI tail on the SAME line; replace up to and including `not in the graph).` | §3.1, R-3 |
| MINOR-4 (Surface-4 line-citation drift) | MINOR | FIXED — refreshed to heading L638 / "How to apply" L652 / citations L669-L672 | §3.2 |
| (citation correction, not a push-back) Check-45 "23↔23" | — | Corrected to the verified INVARIANT (slug-set unchanged) rather than an unreproduced absolute count; bijection NOT re-opened (kept-clean) | §0, §5.1 Check-45 row |
| G-NEW (same-stutter-class sweep) | — | NEW (independent) — swept all 5 non-trivial edits; stutter is UNIQUE to Surface 4 (mid-sentence run-scope); all others boundary-safe; added gate 11 backstop | §0, §5.2 gate 11 |

**Push-backs on adversarial findings:** NONE — all six survived independent
re-measurement; all applied.

**Verified-clean parts kept intact (NOT re-opened):** 8-surface census; trinity
byte-identity boundary; Check 45 bijection (slug-set unchanged → equal); single
atomic `pack-only` commit; BD-238/BD-241 serialization; `test-fixtures/manifest.txt`
+ `.spawn-rule-manifest.txt` exclusions.

---

## 10. Rules-Applied Verification Block

| # | Rule (Rules-in-force) | Verification evidence (quoted/measured at HEAD af73ffb) | Conclusion |
|---|---|---|---|
| 1 | empirical-evidence-blocks [planner] | Every finding + claim measured at HEAD `af73ffb` (`git rev-parse HEAD` → `af73ffb5fd088b17ef7996af8db0b8f7d6d9dfc3`): B-1 — read PACK-MEMORY-RATIONALE.md L652 verbatim (`**How to apply.** When $(git rev-parse …)/graphify-out/graph.json` + L653 `exists, query the graph FIRST…`) → confirms the opener survives a mid-sentence run-scope. MAJOR-1 — read validate-pack.py L7521-7556 extractor (`re.sub(r"\s+"," ",body).strip()[:120]`, L7553) + computed the EXACT 120-char candidate via python (`'When a knowledge graph exists, prefer the graph for orientation / relationship / blast-radius / "what relates to X" / "w'` len 120). MINOR-1 — ran the gate-9 literal `grep -c "skip Graphify … not the graph\|not the graph\."` → `1` (PRE-edit). MINOR-2 — read PACK-AGENTS.md L62-71 (`**Inject…**` bold-lead paragraph, no `- `) vs PACK-CHAT.md L295-305 (`- **Inject…**` list bullet). MINOR-3 — `grep -n "deliberately not in the graph)"` → CLAUDE L650 / AGENTS L568 / GEMINI L545, each with the tail's first chars on the same line. MINOR-4 — `grep -n "^## graph-first-context$"` → L638; citations at L669/L672. Check 45 — read logic L7376-7421 (deduplicated SET equality); tag/heading invariant `grep -c "[rationale: graph-first-context]"` → 1/1/1, `grep -c "^## graph-first-context$"` → 1. Trinity byte-identity — `diff` of `sed`-extracts: CLAUDE↔AGENTS differ ONLY at the in-line tail; AGENTS↔GEMINI identical. `.spawn-rule-manifest.txt` `grep -c graph-first` → 0. Product-clean `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` → 0 (exit 1). BD-238/BD-241 both `Status: Open`, trinity-touching (BD-238 L27, BD-241 L3/L12). | COMPLIANT |
| 2 | adversarial-planner-review (independent challenge) | Did not transcribe: independently re-executed the literal Surface-4 replace mentally and confirmed the double-"When" (B-1); read the Check 46 extractor in source and computed the real candidate empirically (not from the plan's prose); ran the gate-9 grep against the live tree to confirm it matches the PRE-edit state; swept ALL 5 non-trivial edits for the same stutter class (G-NEW) and proved it unique to Surface 4 via sentence-boundary analysis; corrected an unreproduced Check-45 "23↔23" citation to the verified invariant. No rubber-stamp. | COMPLIANT |
| 3 | rename-plans-measure-then-bound / measure-then-bound | Plan anchors every edit on grep-derived CONTENT strings (§3 "locate by content"); §5.2 specifies grep-zero / grep-confirm completeness gates incl. the CORRECTED gate 9 (clean grep-zero + grep-confirm pair) and the NEW gate 11 (stutter grep-zero) + gate 2 (slug grep-zero) + gate 1 (parity diff) + gate 6 (tail preservation) + gate 8 (product-clean). Measure-then-bound, not a hand-enumerated anchor list. | COMPLIANT |
| 4 | edit-in-place-not-full-rewrite | Every surface spec is a targeted in-place REPLACE/EXTEND/ADD of a named sentence/bullet/paragraph with explicit PRESERVE lists (§3.1 replace one sentence at the string boundary; §3.2 re-scope one clause keeping the bold label + G1/G2 sentence; §3.3 replace one bullet; §3.4/§3.5 APPEND one sentence; §3.6 ADD one bullet) — no file rewrite directed. | COMPLIANT |
| 5 | graph-first-context (dogfooded) | Ran the graph FIRST for surface re-discovery: `graphify query "graph-first-context rule propagation surfaces PACK-MEMORY-RATIONALE How to apply OPTIONAL-FEATURES skip Graphify trinity" --graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 1500` → "BFS depth=2 | 27 nodes found" (coarse docs-researcher / BD-185 / IMPL-REPORT cluster). G1 satisfied (graph present at INJECTED path — not recomputed). The graph was COARSE for exact text/counts (G2), so fell through to grep/Read to VERIFY every state-claim — discovery-then-verify, the exact split this BD designs. | COMPLIANT |
| 6 | separate-pack-ops-from-product | `grep -rln "graph-first\|graphify" project-template/ supporting-docs/` → 0 hits (exit 1). All 8 edit surfaces are pack-ops (pack-root trinity, `pack-ops/*`, `.claude/agents/*`); §2 measured-exclusions confirm no product surface. Scope keyword `pack-only` justified. | COMPLIANT |
| 7 | agents-never-commit / per-action-approval-sub-agents | Commands run: `git rev-parse`/`git status --short`/`git branch` (RO), `grep`/`sed`/`awk`/`wc`/`diff`/`find`, `python3` (RO candidate computation + extractor sim), `graphify query` (RO), Read, one `mkdir -p /tmp/...`, heredoc appends to the `/tmp` plan doc. No state-changing git verb; no destructive op; sole filesystem write = this plan at `/tmp/pack-handoff-bd240-plan/PLAN-BD-240-RECONCILED.md`. | COMPLIANT |
| 8 | rules-applied-verification-block | This block present; one row per Rules-in-force rule with quoted/measured evidence + terminal conclusion (no AMBIGUOUS); includes the graph-query-ran row (rule 5). | COMPLIANT |

---
*End of PLAN-BD-240-RECONCILED.md — coder-ready (→ user planner-to-coder gate). Supersedes PLAN-BD-240.md. Executes DESIGN-BD-240-RECONCILED.md; M-1 = (c) BOTH decided; one atomic `pack-only` commit across 8 surfaces. All 6 adversarial findings closed (0 push-backs); B-1 opener-re-scope + MAJOR-1 corrected model + 4 minors fixed; G-NEW same-stutter-class sweep cleared; PREFLIGHT gates corrected (9) + extended (11).*
