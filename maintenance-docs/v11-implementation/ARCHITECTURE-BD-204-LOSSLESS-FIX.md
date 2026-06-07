# ARCHITECTURE-BD-204-LOSSLESS-FIX — the lossless fix for the silent field-drop gap

> **Agent:** pack-architect (FRESH, ADVERSARIAL — adversarial-architect-on-major-gap).
> **Mode:** DESIGN ONLY. No code/entry/committed-doc edit; this doc is the sole write and stays
> UNCOMMITTED (proposal). A planner sequences and a coder applies AFTER user approval.
> **HEAD (verified):** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`).
> **Branch:** `v11-dev`. **Date:** 2026-06-06. **Scope:** PACK-ONLY.
>
> **What this doc is.** The clean go-forward fix for the CRITICAL gap BD-204 C-1..C-6 shipped
> CI-green: the forward migrator carries a 9-field whitelist and SILENTLY DROPS 19 other top-level
> field classes, so real entry content is lost on Mode-2→3 migration while full CI passes. This
> design (a) makes forward→reverse lossless for EVERY field an entry can legitimately carry, with
> NO per-legacy-field carve-outs; (b) closes the green-CI cause with a concrete CI guard that would
> have caught THIS gap; (c) re-scopes BD-204 and sequences the fix into v11.0 (launch gate — no
> deferral).
>
> **Evidence convention.** Every state-claim carries an Empirical-Evidence Block:
> `CMD` · `OUT` (verbatim) · `AT` (HEAD `feaa45d`, 2026-06-06) · `INTERP` · `CONCL`
> (SUPPORTED / NOT-SUPPORTED / PARTIAL). All measurements are my own, run this session.

---

## §1 — INDEPENDENT CONFIRMATION (re-measured; the census challenged, not trusted)

I treated `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md` and `ARCHITECTURE-BD-204.md` as UNTRUSTED and
re-ran the load-bearing measurements myself.

### 1.1 The parser whitelist is exactly 9 keys; unknown labels are silently discarded — CONFIRMED

> **Empirical-Evidence Block (forward parser `mapping` dict + the drop branch).**
> `CMD`: `sed -n '465,483p' scripts/lib/tracker-migrate-forward.sh`
> `OUT` (the `mapping` dict keys): `type, status, blockers, unblocks, file/symbol, file-symbol,
> description, context, resolution, resolved`; the drop branch `key = mapping.get(field_name_raw);
> if key is None: field_being_collected = None; continue` (`:477-480`).
> `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`: the whitelist is the METHODOLOGY Part-7 template set
> (Type/Status/Blockers/Unblocks/File-Symbol/Description/Context/Resolution) + the `resolved` alias.
> Any line whose label is not in the dict yields `key=None` → `field_being_collected=None` → the
> line AND its continuation lines are discarded with no error. `CONCL`: SUPPORTED.

### 1.2 `tmf_compose_issue_body` emits only 4 body sections; the call site passes only 5 args — CONFIRMED

> **Empirical-Evidence Block (composer signature + emit + call site).**
> `CMD`: `sed -n '601,630p' scripts/lib/tracker-migrate-forward.sh` ; `grep -n 'tmf_compose_issue_body' scripts/lib/tracker-migrate-forward.sh`
> `OUT`: `tmf_compose_issue_body(pack_id, description, context, resolution, file_symbol)` emits the
> 3 markers + `## Description` (always) + `## File / Symbol`/`## Context`/`## Resolution`
> (if non-empty). The production BD call site (`:901`) is
> `tmf_compose_issue_body "$pack_id" "$description" "$context" "$resolution" "$file_symbol"` — it
> passes NO `Target`/`Position`/`Scope`/etc. `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`: there is no
> code path by which any drop-set field reaches the Issue body. `CONCL`: SUPPORTED.

### 1.3 The `pack-extra-fields` carrier is DEAD from BOTH ends — CONFIRMED (stronger than the census)

The census called it "defensive dead code." I confirmed it is dead from BOTH the write side and the
read side — there is no producer ANYWHERE.

> **Empirical-Evidence Block (no forward producer; reverse read always `None`).**
> `CMD`: `grep -nE 'pack-extra-fields|Target|Position|extra_fields' scripts/lib/tracker-migrate-forward.sh` ; `grep -nE 'extra_fields\s*=|"extra_fields"\s*:|\.extra_fields' scripts/lib/tracker-migrate-reverse.sh` ; `grep -nE 'pack-extra-fields|extra_fields' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: forward → `ZERO` matches. reverse assignment grep → `ZERO` matches. reverse mention grep →
> only `:706,:707` (comments), `:753` (comment), `:758 extra = e.get("extra_fields", None)`.
> `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`: forward NEVER writes a `pack-extra-fields` block;
> `tracker_migrate_reverse_reconstruct`'s final `jq -n` object (`:574-599`) has 12 keys, NONE named
> `extra_fields`; therefore `e.get("extra_fields", None)` at `:758` ALWAYS returns `None`, `pairs=[]`,
> and the inline render loop (`:778-785`) never executes. The carrier is unreachable in both
> directions. `CONCL`: SUPPORTED. (Stronger than the census: not merely "never fed" — there is no
> producer to feed it, and the consumer's default branch is the only branch ever taken.)

### 1.4 Live tree: 211 entries, 28 distinct labels, 9 carried / 19 dropped — CONFIRMED

> **Empirical-Evidence Block (label census re-run independently).**
> `CMD`: `for f in backlog/BD-*.md; do tail -n +2 "$f"; done | grep -oE '^[A-Z][A-Za-z/ -]+:' | sort | uniq -c | sort -rn` ; `ls backlog/BD-*.md | wc -l`
> `OUT`: 28 distinct labels; entry count `211`. Carried (9): Type 213, Status 213, Resolved 210,
> Description 202, Unblocks 193, Blockers 193, File/Symbol 180, Context 41, Resolution 4. Dropped
> (19): Position 14, Target 11, Scope 11, References 10, Out of scope 10, Encapsulation 4,
> Acceptance criteria 4, Surfaced 2, Problem 2, Goal 2, Steps 1, Risk note 1, Quality bar 1,
> Pipeline 1, Paused 1, Note 1, Disposition 1, Alias 1. `AT`: HEAD `feaa45d`, 2026-06-06.
> `INTERP`: my independent count matches the census exactly. The carry set == the METHODOLOGY
> Part-7 template (the `Resolution`/`Resolved` alias collapses to one). `CONCL`: SUPPORTED.

### 1.5 Challenge: is anything "dropped" actually recovered elsewhere? — NO (one PARTIAL nuance)

I challenged the census's "dropped" verdict for each class.

> **Empirical-Evidence Block (the only label-decoded fields are Scope/Severity, and they do NOT
> recover the dropped LINE value).**
> `CMD`: `sed -n '305,320p' scripts/lib/tracker-migrate-reverse.sh` (the `_tmr_decode_scope` /
> `_tmr_decode_severity` defs) ; `grep -n '_tmr_decode_scope\|_tmr_decode_severity' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: `_tmr_decode_scope`/`_tmr_decode_severity` read a `scope:*`/`severity:*` LABEL (set by
> forward `_tmf_labels_for_entry`), NOT a `Scope:`/`Severity:` body line. The live pack tree has 11
> `Scope:` lines but forward maps NONE of them to a `scope:*` label (the parser dropped the line
> before label-mapping). `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`: reverse can EMIT a `Scope:`
> line ONLY if a `scope:*` label exists — but for these 11 entries no such label is ever set, so the
> live `Scope:` text is lost. `CONCL`: PARTIAL — `Scope` has a label decode path on reverse, but it
> never carries the live `Scope:` LINE value; net the value is dropped. All other 18 classes have
> ZERO recovery path. The census's "dropped" verdict holds.

### 1.6 Worst case: 11 no-Description entries migrate to an essentially empty Issue body — CONFIRMED

> **Empirical-Evidence Block (BD-204's own field lines + the no-Description cohort).**
> `CMD`: `tail -n +2 backlog/BD-204.md | grep -nE '^[A-Z][A-Za-z/ -]+:'` ; `for f in backlog/BD-*.md; do c=$(tail -n +2 "$f" | grep -cE '^Description:'); [ "$c" = 0 ] && basename "$f" .md; done`
> `OUT`: BD-204 carries `Type, Status, Target, Blockers, Unblocks, Problem, Scope, Out of scope,
> References, Resolved, Position` (+ ~9 uncarried multi-line prose blocks: HARD CONSTRAINT / DESIGN
> BASELINE / REVERSIBILITY / SSOT-MIRROR / GENERALIZABLE / DECISION TIERS / PACK FEEDBACK /
> CAPABILITY-INFORMED / IMPLEMENTATION CARRY-FORWARD). No-Description cohort (11):
> `BD-195 BD-202 BD-203 BD-204 BD-205 BD-206 BD-207 BD-208 BD-209 BD-210 BD-211`.
> `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`: BD-204 has NO `Description:` to even partially carry
> content; through the current forward it composes to `## Description` (empty) + `## Resolution: n/a`.
> Its Problem/Scope/Out-of-scope/References/Target/Position lines AND every prose block are gone.
> The 11-entry cohort shares this worst case. `CONCL`: SUPPORTED.

### 1.6b The loss is CORRUPTION, not merely a clean drop — prose blocks are shredded into `unblocks` (review-2 A-1/B-1, re-verified)

The original report framed the 19 classes as "silently dropped." The independent review proved (and
I re-confirmed) that the loss is WORSE than a clean drop: the multi-line prose blocks (BD-204's
`HARD CONSTRAINT (...):`, `DESIGN BASELINE (...):`, `DECISION TIERS (...):`, etc.) do NOT match the
parser's `FIELD_LINE` regex (it forbids parentheses/digits before the colon), so they are absorbed
as CONTINUATION lines of the preceding field — which for BD-204 is `Unblocks:` — and then
COMMA-SHREDDED by `parse_id_list` into dozens of garbage list items. This is active corruption of a
carried field, not just omission of an uncarried one.

> **Empirical-Evidence Block (BD-204's prose blocks shred its `unblocks` from 4 real items to 73).**
> `CMD`: `source scripts/lib/tracker-migrate-forward.sh; tail -n +2 backlog/BD-204.md > /tmp/t204.md; printf '\n---\n' >> /tmp/t204.md; _tmf_parse_backlog_file /tmp/t204.md | jq '.[0].unblocks | length'`
> `OUT`: `73` (the 4 real unblocks PLUS the entire prose-block region split on every comma — e.g.
> `"HARD CONSTRAINT (user 2026-06-04): **pack-only ... If it affects the project side at all"`,
> `"that is a VIOLATION.** CI Check 36 ..."`, `"DESIGN BASELINE (named inputs - ADAPT"`, ...).
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: a per-field-line carrier (capture every `Label: value`
> line) would NOT recover the prose blocks - they are not field lines; and the existing `unblocks`
> value is already corrupt before any carrier runs. Only a VERBATIM-BODY carrier (§3.3) preserves
> them, because it never re-parses the body into fields at all. `CONCL`: SUPPORTED - this is the crux
> that forces the verbatim-body-blob mechanism (§3.3) and rules out the per-field `[label,value]`
> model entirely.

> **Empirical-Evidence Block (FIELD_LINE rejects the prose-block headers; accepts the structured scalars).**
> `CMD`: `python3` test of `FIELD_LINE = ^([A-Z][A-Za-z/ -]+):` against the BD-204 label set.
> `OUT`: `MATCH` for `Target:`, `Position:`, `Scope:`, `Out of scope:`, `Problem:`, `References:`;
> `NO-MATCH` for `HARD CONSTRAINT (user 2026-06-04):`, `DECISION TIERS (calibration):`,
> `DESIGN BASELINE (named inputs):`. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: Target/Position are
> the EASY case (recoverable by any line-level rule); the prose blocks are the HARD, uncovered case
> that only the verbatim-body blob handles. `CONCL`: SUPPORTED.

### 1.7 Is the "carry-set == template" claim EXACTLY true? — YES, with a contradiction to surface

The carry set exactly equals the METHODOLOGY Part-7 template. BUT `backlog/_rules.md:49` names
`Position:` as a valid optional entry field — and `Position:` is NOT in the template and is NOT
carried. This is a live schema contradiction (the contract admits a field the migrator drops).

> **Empirical-Evidence Block (the `_rules.md` entry contract names `Position:`; the template + migrator do not).**
> `CMD`: `sed -n '43,50p' backlog/_rules.md` ; `sed -n '1199,1216p' supporting-docs/METHODOLOGY.md`
> `OUT`: `_rules.md:48-49` "... (and optional `Blockers:` / `Unblocks:` / `File/Symbol:` /
> `Resolved:` / `Position:`) fields per the standard BACKLOG item format (METHODOLOGY.md Part 7)";
> METHODOLOGY Part 7 field block names Type/Status/Blockers/Unblocks/File/Symbol/Description/Context/
> Resolution — NO `Position:`. `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`: `_rules.md` lists
> `Position:` as a sanctioned optional field while the canonical template it cites does NOT, and the
> migrator drops it. The schema's own two SSOTs (the contract + the template) disagree. `CONCL`:
> SUPPORTED — material to §3 (the field schema must be reconciled, not just the migrator).

### 1.8 §1 bottom line

Every census key claim is independently CONFIRMED at HEAD `feaa45d`. The gap is real: 19 top-level
field classes are dropped — and (review-2 §1.6b) the multi-line prose blocks are not merely dropped
but CORRUPTED (shredded into a 73-item `unblocks` list for BD-204). The `pack-extra-fields` carrier
the prior architecture relies on is dead from both ends; the worst case (BD-204 + 10 siblings) loses
nearly all substance. Two added findings: (a) the field SCHEMA is internally inconsistent
(`_rules.md` names `Position:`; the template does not); (b) the loss includes active corruption of a
carried field, which forces the verbatim-body-blob carrier (§3.3) — a per-field line model cannot
recover a continuation-shredded prose block.

---

## §2 — C-1..C-6 LOSSLESS-CLAIM AUDIT (every losslessness / zero-orphaned claim, verdict + evidence)

Verdicts: **PROVEN** (the doc/code substantiates it), **NEVER-PROVEN** (claimed but no test/code ever
exercised it), **FALSE** (the code contradicts the claim).

| # | Source (file · anchor) | The claim | Verdict | Evidence |
|---|---|---|---|---|
| A | ARCHITECTURE-BD-204 §2.4.2 "Zero-orphaned-fields verification" + the §2.4.1 Rules-Applied mini-block ("ZERO orphaned") | every leading-label field maps to a form field or the Issue body; Target/Position ride the in-body `pack-extra-fields` block | **FALSE** | §1.2/§1.3: forward never writes a `pack-extra-fields` block and never passes Target/Position to the composer; the §2.4.2 EE block enumerated the field LABELS in the source entries and asserted a MAPPING that the code does not implement. It measured the input, not the migrated output. |
| B | ARCHITECTURE-BD-204 §2.4.1 "The carrier, stated once … On regen, the block is read back and rendered INLINE" | the in-body block round-trips Target/Position byte-faithfully | **FALSE** | §1.3: the reverse read `e.get("extra_fields", None)` is always `None`; the inline-render loop is unreachable; nothing is read back. |
| C | ARCHITECTURE-BD-204 §3.1 item 4 "Overflow recovered — Target/Position/structured-sub-blocks recovered from the Issue body … byte-faithfully" | the lossless contract's overflow leg holds | **NEVER-PROVEN → FALSE for top-level fields** | Structured sub-blocks ride the Description body IF they were authored inside Description (true for the C-7 fixture); but a TOP-LEVEL `Target:`/`Position:`/`Scope:` line is dropped by the parser (§1.1) and never enters the body. The contract's item 4 is false for every real entry carrying a top-level drop-set field. |
| D | ARCHITECTURE-BD-204 §2.11 "(b) the in-body `pack-extra-fields` block … for any named field the form grammar cannot name" as a pillar of the lossless guarantee | reversibility rests partly on the in-body carrier | **FALSE** | The named pillar does not exist in code (§1.3). The reversibility guarantee has no carrier for the 19 dropped classes. |
| E | ARCHITECTURE-BD-204 §3.2 "Content-faithfulness oracle … diff … is EMPTY. The large-entry stress case (BD-195's Segments:/Steps:/State:) is in scope — its body must diff clean" | the oracle proves content faithfulness incl. the large entry | **NEVER-PROVEN** | The oracle is real (C-7) but its FIXTURE (BD-901/902/903) carries ONLY the 9 carry-set top-level fields; BD-903's sub-blocks are authored INSIDE Description (indented continuation), so they ride Description verbatim and diff clean. No fixture entry carries a top-level drop-set field, so the diff is structurally guaranteed empty regardless of the bug. The oracle cannot exercise the drop. |
| F | C-7 oracle header (`tracker-bd204-lossless-roundtrip-test.sh:13-23`) + the default-SKIP guard (`:41-45`) | a lossless round-trip oracle gates the work | **NEVER-PROVEN in CI** | The oracle is manual-only + default-SKIP (`PACK_TRACKER_LIVE_GH` unset ⇒ `exit 0` before any assertion) and is not wired into any workflow. In CI it runs zero assertions. Even run manually, see (E): its fixture cannot catch the drop. |
| G | PLAN-BD-204 §C-4 step 1 "The in-body `pack-extra-fields` block … is rendered INLINE into the entry on regen" | the plan's no-monolith reverse preserves overflow fields | **FALSE (inherited)** | The plan inherits the architecture's phantom carrier; C-4 as written emits a tree whose entries lose every top-level drop-set field. |
| H | ARCHITECTURE-BD-204 §3.4 / RECON §E "C-7's FULL CI battery verification" | C-7 is verified per-commit | **NEVER-PROVEN** | C-7 is explicitly OUT of the unattended battery; the "battery" is `validate-pack.py` + the mock battery, NONE of which asserts field-faithfulness (§2.F census in RESEARCH; re-confirmed §4 below). |

> **Empirical-Evidence Block (the §2.4.2 "zero-orphaned" EE measured the INPUT entries, not the migrated output).**
> `CMD`: re-read ARCHITECTURE-BD-204 §2.4.2 EE `CMD`: `for f in backlog/BD-195.md ... ; do grep -nE '^[A-Z][A-Za-z/ -]*:' "$f"; done`
> `OUT`: the EE block's command greps the SOURCE entry files for leading-label fields, then asserts a
> prose mapping table; it NEVER runs forward+reverse and diffs the result. `AT`: HEAD `feaa45d`,
> 2026-06-06. `INTERP`: the "zero-orphaned" conclusion is a DESIGN assertion about where fields
> SHOULD go, not a measurement of where they DO go. The actual migrated body (§1.2/1.6) drops them.
> `CONCL`: SUPPORTED (the claim is FALSE; its EE proved the wrong thing).

**§2 bottom line.** Eight distinct losslessness / zero-orphaned / overflow-recovered claims across
ARCHITECTURE-BD-204 (§2.4.1/§2.4.2/§2.11/§3.1/§3.2), the C-7 oracle, and PLAN-BD-204 §C-4 are
either FALSE (the carrier they name does not exist) or NEVER-PROVEN (no test exercises the drop).
The root error is uniform: the design DESCRIBED a `pack-extra-fields` carrier as if implemented,
the plan inherited it, and the oracle's fixture was built around the carry set so the gap was
invisible to every gate.

---

## §3 — THE LOSSLESS FIX DESIGN (clean, go-forward, zero carve-outs)

### 3.1 The design space (three options, judged on property-fit)

The drop set has two structurally distinct classes (the prompt permits treating classes
differently IF justified — but with NO per-legacy-field carve-out):

- **Class P — freeform prose fields:** `Problem, Goal, Scope, Out of scope, References,
  Acceptance criteria, Encapsulation, Surfaced, Steps, Risk note, Quality bar, Pipeline, Paused,
  Note, Disposition, Alias` (and the uncarried multi-line design blocks). These are body prose; a
  human reads them as narrative.
- **Class S — structured tracker-metadata fields:** `Target, Position`. These are named scalars the
  prior design intended to carry as machine-parseable values.

Three options:

- **(A) Rewrite the offending entries** so every drop-set field is folded into a carried field
  (Description/Context) — schema-compliant by editing the 211-entry tree.
- **(B) Carry the fields** — extend the migrator so every top-level entry field round-trips
  (forward writes it into the Issue body; reverse reads it back).
- **(C) Hybrid** — carry some classes, rewrite others.

### 3.2 Property-fit analysis (the decision, not a pattern)

**Option (A) rewrite FAILS criterion C and the design-elegance bar.**

> **Empirical-Evidence Block (rewrite cannot be proven lossless across 211 entries; it CHANGES the readable form).**
> `CMD`: `for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -cE '^(Target|Position|Scope|Problem|Goal|Out of scope|References|Acceptance criteria|Encapsulation|Surfaced|Steps|Risk note|Quality bar|Pipeline|Paused|Note|Disposition|Alias):'; done | awk '{s+=$1} END{print s}'`
> `OUT`: `97` drop-set field lines across the tree (plus uncarried multi-line prose blocks not
> counted by a leading-label grep). `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`: a rewrite would have
> to fold 97+ distinct field lines (many multi-line, e.g. BD-204's 9 design blocks) into
> Description/Context across ~20 entries WITHOUT losing content or changing meaning, then prove it
> per-entry. Folding a named scalar (`Target: v11.0`) into prose DESTROYS its structure (it stops
> being a queryable field); folding 9 design blocks into one Description CHANGES the entry's readable
> shape. The flat-file tree IS the human-readable SSOT (`backlog/_rules.md:20-26`) — rewriting it to
> survive a migrator is the tail wagging the dog. `CONCL`: SUPPORTED — (A) cannot satisfy "zero
> content lost AND no meaning changed" for the structured fields, and it degrades the readable SSOT.
> REJECTED as the primary fix.

**Option (B) carry-the-fields is the property-fit winner — but only with the RIGHT carrier shape.**
The migration's job is to be a faithful transport. A faithful transport carries what it is given; it
does not require the payload to be reshaped to fit a narrow whitelist. The entry's flat form is the
SSOT; the migrator must preserve it, not constrain it.

**The carrier shape — ONE mechanism: the verbatim-body blob (decided; the per-field model is rejected).**
The prior design split the carrier (prose→visible body; named scalars→`pack-extra-fields` block).
That split is the source of the dead code AND a carve-out generator. The original version of this
doc oscillated between two incompatible shapes (a per-field `[label,value]` list vs a verbatim body
blob); review-2 (§1.6b) proved the per-field model CANNOT work — BD-204's prose blocks are not
`Label: value` lines, do not match `FIELD_LINE`, and are already comma-shredded into `unblocks`. A
per-field carrier would re-emit them as a mangled `Unblocks:` list. **This design therefore COMMITS
to a single mechanism end-to-end: the migrator carries the entry's VERBATIM BODY as an opaque,
base64-encoded blob; reverse decodes it and writes it back byte-for-byte. There is no per-field
capture, no field re-parsing on the carry path, and no `extra_fields` `[label,value]` list anywhere
in the design.**

### 3.3 THE VERBATIM-BODY-BLOB CARRIER (the single committed mechanism, end-to-end)

**The captured span (B-5, exact).** The per-entry file `/backlog/BD-NNN.md` is: line 1 = the
HTML-comment back-pointer; line 2 = the bold-header `**BD-NNN — <Title>**`; lines 3..EOF = the field
body. The CARRIED SPAN is **lines 2..EOF inclusive** — the bold-header line AND every field/prose
line below it, verbatim (the line-1 back-pointer is DERIVED, regenerated each cycle, never carried;
this is what `pe_strip_backpointer_stdin` already strips). Capturing the bold-header inside the blob
makes the blob self-sufficient for the entry's complete flat representation, and means reverse does
NOT reconstruct the header from the title + marker (avoiding the B-5 title-double-encoding divergence
— the title in the Issue TITLE field is advisory; the blob's header line is authoritative for the
tree).

**The carrier token (B-2 collision-proof + N-1 size-bounded by measurement).** The blob is
**deterministic-gzip-then-base64** of the captured span (gzip with `mtime=0` so the encoding is a
pure function of the body — §3.3b idempotency), stored in ONE body marker alongside the existing trio:
```
<!-- pack-entry-body-gz64: H4sIAAAAAAAAA8tIzcnJVyjPL8pJUQQAlRmFGwwAAAA= -->
```
Two properties, each measured (not assumed):
- **Collision-proof:** base64's alphabet `[A-Za-z0-9+/=]` CANNOT contain `-->`, `<!--`, a markdown
  fence, a comma, or an em-dash, so the HTML-comment marker can never terminate early and
  `parse_id_list` can never shred it (gzip output is itself binary, but base64 wraps it into the safe
  alphabet). No escaping is needed.
- **Size-bounded:** gzip compresses the prose-heavy bodies ~3:1, which is what keeps the
  DOUBLED-payload design (visible H2 + blob) under the GH 65,536-byte hard body limit. With a RAW
  base64 blob the worst entry (BD-136) projected to 65,336 bytes — 99.7% of the limit, ~200 bytes of
  headroom (N-1). With the gzip+base64 blob it projects to 40,771 bytes — 62.2%. The full
  measure-then-bound size analysis (distribution across all 211 + the overflow contract + the
  provider-layer contract) is §3.3c.

> **Empirical-Evidence Block (gzip+base64 round-trips both worst-case bodies byte-faithfully, is deterministic, and is collision-proof).**
> `CMD`: deterministic gzip (`gzip.GzipFile(..., mtime=0)`) of `tail -n +2 backlog/BD-136.md`, then base64; decode (`base64 -d | gunzip`) and `diff` vs original; check the blob for `-->`; encode twice and compare. Same for BD-204.
> `OUT`: BD-136 (`-->` + fence + 19.7 KB File/Symbol, the largest entry): decode `diff` EMPTY
> (byte-identical); blob contains ZERO `-->`; two encodings IDENTICAL (mtime field bytes 4-7 = `0 0 0 0`).
> BD-204 (73-shred / no-Description): decode `diff` EMPTY; ZERO `-->`. `AT`: HEAD `feaa45d`,
> 2026-06-07. `INTERP`: the gzip+base64 blob preserves the exact bytes (interior blank lines, parens,
> commas, fences, em-dashes), is collision-proof, AND is deterministic (so the §3.3b fixed point
> holds — the same body always yields the same blob). `CONCL`: SUPPORTED — byte-faithful +
> collision-proof + deterministic on the two hardest entries.

**Forward (`scripts/lib/tracker-migrate-forward.sh`):**

1. **Parser (`_tmf_parse_backlog_file`):** UNCHANGED for the carried fields it already extracts
   (Type/Status/Blockers/Unblocks/File-Symbol/Description/Context/Resolution drive labels/links/H2
   sections). ADD one field to the entry object: `raw_body` = the verbatim captured span (lines
   2..EOF), preserved exactly as read (no re-parse, no `parse_id_list`, no continuation folding).
   The carrier never depends on field parsing, so the existing `unblocks` shredding (§1.6b) is
   IRRELEVANT to round-trip fidelity — the blob carries the truth; the parsed fields are only the
   label/link/H2 projection.
2. **Composer (`tmf_compose_issue_body`):** add a 6th parameter `raw_body` (DEFAULTED `${6:-}` —
   A-3/G-2: the phase call site at `:959` is a 4-arg call relying on defaults; the new param MUST be
   optional or the phase path breaks). Emit ONE marker
   `<!-- pack-entry-body-gz64: <base64(gzip_mtime0(raw_body))> -->` in the body, alongside the
   pack-id/template_version/pack-version trio. BEFORE emitting, enforce the size budget (§3.3c): if
   the projected body (H2 + blob + markers) would exceed the provider's body-field limit minus the
   safety margin, the composer FAILs loud with the entry id + byte count — it never truncates. The
   visible `## Description` / `## File / Symbol` / `## Context` / `## Resolution` H2 sections STILL
   emit (advisory human/GH rendering, B-3) — but they are NOT the round-trip source.
3. **Call sites:** the BD call site (`:901`) passes the entry's `raw_body`; the phase call site
   (`:959`) passes nothing (default empty → no blob marker for a synthesized phase epic, which has
   no per-entry source file — harmless).

**Reverse (`scripts/lib/tracker-migrate-reverse.sh`):**

4. **`tracker_migrate_reverse_reconstruct`:** read the `pack-entry-body-gz64` marker from the Issue
   body, base64-decode then gunzip it to `raw_body` via **`python3` (the gzip/base64 codec is pinned to
   `python3` on EVERY path — forward encode AND reverse decode — matching the existing all-`python3`
   tracker-lib idiom; NO shell `gzip(1)`/`base64(1)` whose flags/availability vary by platform; review-3
   item)**, and put `raw_body` on the reconstructed object. **Corrupt-blob handling is FAIL-LOUD, never
   silent-empty (review-3 item):** if the marker is absent, malformed base64, not valid gzip, or the
   gunzip CRC fails, reverse ABORTS with `corrupt-blob: issue #N pack-entry-body-gz64 failed to
   decode (<reason>); reverse aborted — NEVER emits an empty/partial entry body` (it does NOT fall
   back to an empty body or the H2 projection — a silent-empty would be the lossy class this design
   kills). (The dead `extra_fields` read at `:758` and its `[label,value]` render loop are REMOVED — the
   abandoned per-field model; the blob replaces them. Per fail-loud, the dead per-field render is
   deleted, not left as a silent contradiction.)
5. **`_tmr_emit_pack_tree`:** REWRITE the pack-surface emit (A-1). Instead of the fixed-order
   template projection (which unconditionally injects `Blockers: None` / `Unblocks: None` /
   `Resolved: n/a` and appends extras last — false-failing 20 entries, §4 / A-1), the pack branch
   writes `pe_backpointer_line` (line 1, derived) + `raw_body` (lines 2..EOF, verbatim from the
   blob). The reconstructed `/backlog/BD-NNN.md` is therefore byte-identical to the original
   (back-pointer stripped). The fixed-order template projection is RETAINED ONLY on the CLIENT
   (`surface != "pack"`) branch and ONLY until BD-207 — it is untouched (pack/client split, §7 R-CLIENT).

**Why the H2 sections stay (B-3 precedence — a design decision, not a footnote).** The H2 sections +
labels are the GH-human-readable + state-machine projection; the **blob is AUTHORITATIVE for reverse
into the tree.** This raises a real Mode-3 question: if a human (or `tracker-edit.sh`, the C-3 CRUD
writer) edits the visible body on GH but not the blob, a silent blob-wins reverse would DISCARD the
human's edit. The design resolves this in §3.3a below rather than ignoring it. (Keeping H2 is also
what makes the size budget non-trivial — H2 + blob doubles the payload — so §3.3c bounds it.)

### 3.3a Blob ↔ H2 consistency on Mode-3 writes (B-3, the human-edit data-loss story)

In Mode 3 the Issue is the SSOT and is edited two ways: (i) by `tracker-edit.sh` (the C-3
`provider_update` writer) and (ii) by a human directly on GitHub. Both must keep the blob and the H2
sections consistent, else reverse silently drops one.

- **(i) `tracker-edit.sh` (named symbol):** the C-3 Mode-3 edit path (`tracker-edit.sh`, the function
  that builds the `provider_update` payload — `tracker_edit_entry` / the body-composer it calls)
  MUST regenerate BOTH the H2 sections AND the `pack-entry-body-gz64` blob from the SAME in-memory
  entry object on every write, so a tracker-side edit updates both representations atomically. This
  is a C-3 scope addition (§5.b): the edit path is the producer; it owns keeping the two views in
  sync. It already round-trips through the same compose code — it must call the blob-aware composer.
- **(ii) direct human GH edit (divergence DETECTION via a NORMALIZATION-TOLERANT comparator —
  N-2):** a human editing the visible `## Description` without touching the hidden blob creates
  divergence. The design makes this LOUD, not silent (per fail-loud): reverse, on reading an Issue,
  RECOMPUTES the H2-projection from the blob and COMPARES it to the Issue's actual H2 sections; on
  mismatch it FAILs the reverse with `divergence: issue #N body H2 sections disagree with the
  pack-entry-body-gz64 blob — a direct GH edit was not propagated to the blob; reconcile before
  reverse` (it does NOT silently pick a winner).
  - **The comparator MUST be normalization-tolerant, NOT byte-exact (N-2).** GitHub normalizes a
    body on a web round-trip even when no human changed content: it canonicalizes line endings
    (CRLF→LF) and strips per-line trailing whitespace. A byte-exact compare of the recomputed H2
    against the issue's H2 would then FALSE-POSITIVE on an untouched issue (turning the backstop into
    a noise generator that blocks legitimate reverses). The comparator therefore normalizes BOTH
    sides identically before comparing, applying EXACTLY these two transforms and no broader:
    (1) **line-ending canonicalization** — translate `\r\n` and bare `\r` to `\n`;
    (2) **per-line trailing-whitespace strip** — remove trailing spaces/tabs from each line; and a
    single trailing-newline normalization (`rstrip('\n') + '\n'`, the existing `tracker-mirror.sh`
    idiom). This set is SUFFICIENT (it covers GitHub's documented body munging) and NO BROADER than
    GH's actual normalization — it does NOT touch interior whitespace, case, Unicode form, or content
    bytes, so a REAL human edit (any content/word/structural change) still mismatches and is caught
    (no false-negative). It is the same whitespace-tolerant discipline the existing roundtrip test
    documents (`tracker-migrate-roundtrip-test.sh:9` "Zero diff (whitespace-tolerant)") and the
    `tracker-mirror.sh` trailing-newline normalization (`:67`,`:101`) — property-fit, not invented.
  - The blob ITSELF needs no normalization tolerance: it rides inside an HTML comment in the safe
    base64 alphabet; GH's body normalization preserves the comment and the alphabet, so the blob
    decodes byte-identically regardless (the carrier's collision-proof property, §3.3, also makes it
    normalization-proof). Only the VISIBLE H2 (plain markdown) is normalization-exposed — hence the
    comparator covers exactly the H2 leg.
  This converts the new data-loss path into a detected, surfaced error. (Mode transitions are
  heavyweight + infrequent, §2.12 of ARCHITECTURE-BD-204 — a reconcile prompt at reverse is
  acceptable; silent loss is not.) The `--force` flag (existing silent-data-loss-guard refusal idiom,
  `tracker-migrate-reverse.sh` `local force` ~`:985`, refusal-unless-force ~`:1014`/`:1042`) may
  override to blob-wins with an explicit operator decision.

This is the B-3 contract: blob authoritative; `tracker-edit.sh` keeps both views synced on every
write; a stray human GH edit is DETECTED and surfaced, never silently discarded.

### 3.3b Idempotency across repeated on/off (B-4) — the invariant is DECODE-IDENTITY, not encode-byte-stability (review-3 item)

Because reverse writes `raw_body` verbatim and forward re-captures `raw_body` verbatim, the round-trip
reaches a FIXED POINT after one cycle: `reverse(forward(x))` byte-equals `x` (back-pointer stripped),
so `reverse(forward(reverse(forward(x)))) == reverse(forward(x))` trivially. There is no normalization
step that could drift on a second pass (the fixed-order template projection — the only drift source,
A-1 — is removed from the pack branch).

**The load-bearing invariant is DECODE-IDENTITY, stated precisely (review-3 item).** The thing the
round-trip depends on is `gunzip(base64_decode(blob)) == raw_body` — decode recovers the exact bytes.
It does NOT depend on the *encoder* producing a byte-identical blob across runs/machines. `mtime=0`
(§3.3c) makes the encoder ALSO deterministic, which is a CONVENIENCE (it stabilizes the projected size
for the §4 size leg and makes a re-forwarded Issue body byte-identical, avoiding a spurious "changed"
diff on re-create), but losslessness rests ONLY on decode-identity: even if two gzip implementations
emitted different valid blobs for the same input, BOTH decode to the same `raw_body`, so the tree is
reproduced byte-identically either way. The §4 guard asserts decode-identity (the binding property);
`mtime=0` determinism is the secondary convenience the size leg + re-create-stability lean on.
The §4 guard asserts the one-cycle fixed point; the C-7 live oracle (§5.c) additionally runs the
two-cycle on/off/on/off convergence leg.

### 3.3c SIZE BUDGET — the body-field limit, bounded by measurement (N-1 + N-7, one gap at two layers)

The blob model DOUBLES the body payload (visible H2 projection + the blob), so it pushes against the
tracker's body-field byte limit. GitHub's hard Issue-body limit is **65,536** (the error string says
"characters"). Per `ci-guard-measure-then-bound`, this section MEASURES the worst case + the full
distribution, then BOUNDS the mechanism — the same discipline §3.3 applies to the delimiter, now
applied to SIZE. N-1 (the pack/GH instance bound) and N-7 (the provider-layer contract) are ONE gap at
two layers; this section closes both.

**The enforcement AXIS this budget targets (R-BODY-7, the GH-rules census).** GitHub's 65,536 limit is
asserted on THREE possible axes across sources: (a) stored CODEPOINTS (github-limits "65536 codepoints"
for the description); (b) stored BYTES (the underlying mediumblob); (c) the GZIPPED API-REQUEST payload
size (multiple authoritative practitioner reports: a 231k-char comment posted as a ~55K gzipped call
succeeded). Official docs name no authoritative axis. **This budget targets the most conservative axis
— stored BYTES — because a stored-byte bound is ≤ all three** (a byte bound also bounds stored
codepoints for any encoding, and the gzipped REQUEST is far smaller than the stored bytes for the
pack's high-entropy base64+gzip blob). Empirically re-verified this sweep: the worst entry's stored
composed body is 40,695 bytes (62.1%) while its gzipped-request payload is ~20,321 bytes (31.0%) — the
stored-byte axis is the BINDING (largest) of the three, so budgeting against it is safe under every
enforcement model. `provider_body_limit` (below) is declared in STORED BYTES.

> **Empirical-Evidence Block (the stored-byte axis is the binding one; the gzipped-request axis is far smaller — R-BODY-7).**
> `CMD`: for the worst entry, compute the stored composed-body bytes AND the gzip(JSON-request) bytes; compare both to 65,536.
> `OUT`: BD-136 stored composed body = **40,695 bytes (62.1%)**; its gzipped-request payload = **~20,321
> bytes (31.0%)** (the JSON request gzips the already-gz64 blob only ~2:1 — it barely compresses again,
> consistent with high-entropy content). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: of the three
> R-BODY-7 axes, STORED BYTES is the largest for pack content (62.1% > the 31.0% gzipped-request),
> so budgeting against 65,536 stored bytes bounds the codepoint axis AND the gzipped-request axis. (An
> earlier draft stated "~134 bytes / 0.2%" — a measurement error from gzipping a near-empty input;
> corrected here and in the sweep S-5#4.) `CONCL`: SUPPORTED — naming the axis (stored bytes) makes the
> budget honest and provably-safe under all three enforcement models.

**The measured distribution (all 211 entries, projected revised-design body).** The "projected body"
= the visible H2 projection (upper-bounded by the raw body bytes — the H2 re-emits the field values)
+ the blob + the marker wrapper. Measured under BOTH blob encodings:

> **Empirical-Evidence Block (size distribution across all 211 entries; the raw-base64 worst case is 99.7% — the gzip blob brings it to 62.2%).**
> `CMD`: per entry, `body=lines 2..EOF`; raw-blob projection = `len(body)+80 + 29+len(base64(body))`;
> gzip-blob projection = `len(body)+80 + 29+len(base64(gzip_mtime0(body)))`; sort + bucket.
> `OUT` (RAW-base64 blob — the pre-fix mechanism): max = **BD-136 65,336 bytes (99.7%)**; p99 =
> BD-203 26,156 (39.9%); median 5,225; min 474. Entries over 80% of the limit: **1 (BD-136)**; over
> 100%: 0. (GZIP+base64 blob — the §3.3 fix): max = **BD-136 40,771 bytes (62.2%)**; next = BD-191
> 30 KB-class; ALL 211 under 63%; entries over 80%: **0**. BD-136 raw body 27,954 → raw-b64 37,272 →
> gzip-b64 12,708 (≈3:1). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: under the raw-base64 blob the
> worst entry sat ~200 bytes under a HARD external limit and a single edit would breach it; gzipping
> the blob (the prose compresses ~3:1) drops the worst case to 62.2% and leaves ~24.7 KB headroom on
> the worst entry. `CONCL`: SUPPORTED — gzip+base64 is the size-bounding decision, measured against
> the limit, not assumed.

**The DESIGN decision (gzip the blob; KEEP the H2; ADD a loud-fail overflow contract).** The
trade-space (each option measured above):
- (a) *drop the redundant H2* → worst case 57.0% — but loses the GH-human-readable rendering that
  B-3 deliberately preserves (the H2 is WHY a maintainer can read an Issue on github.com);
- (b) *gzip the blob, KEEP the H2* → worst case 62.2%, full headroom, H2 readability PRESERVED;
- (c) *gzip AND drop H2* → 19.6% — maximal headroom but sacrifices readability for headroom the tree
  does not need.
**Chosen: (b)** — gzip the blob (already specified in §3.3 as the `pack-entry-body-gz64` carrier) and
KEEP the H2. It is the property-fit choice: it preserves the human-readability rationale B-3 settled,
while bringing the doubled payload comfortably under the limit. (a)/(c) trade away readability for
headroom that (b) already provides; they are rejected on that basis, not on size.

**The OVERFLOW CONTRACT (fail-loud, never truncate — the HARD invariant).** Even with gzip, a future
entry could in principle exceed any tracker's body limit. Silent truncation would be a NEW lossy path
— the exact class this design exists to kill. So the contract is: **the forward composer computes the
projected body size and, if it exceeds `provider_body_limit − SAFETY_MARGIN`, FAILs loud** with
`size-budget: entry <ID> projected body <N> bytes exceeds provider body limit <L> (margin <M>);
forward aborted — split the entry or raise the limit; the migrator NEVER truncates`. The migration
aborts atomically (no partial Issue is created), exactly like the existing silent-data-loss guard
(§3.3a). `SAFETY_MARGIN` is a small fixed reserve (e.g. 2,048 bytes) for the marker wrapper +
provider-side rendering overhead. This makes size a BOUNDED, ENFORCED property, not a latent failure.

**The PROVIDER-LAYER contract (N-7 — tracker-agnosticism honored).** The 65,536 figure is
GitHub-specific; the carrier contract must live at the TrackerProvider abstraction, not be tacitly
GH-sized. So the abstraction gains TWO declared capabilities (S-5#7 — the honest portability boundary):

- **`provider_body_limit`** (bytes) — each provider DECLARES its body/description-field byte capacity
  (GitHub: 65,536; a Jira/Linear/Redmine provider declares its own; an unbounded provider declares a
  sentinel meaning "no limit"). This sits alongside the existing capability-flag floor the design
  already uses (labels, open/closed, body field) per the BD-060/DESIGN-BRIEF capability model.
- **`provider_body_storage_format`** (enum: `raw_text` | `rich_text_normalizing`) — each provider
  DECLARES whether its body field stores opaque text byte-verbatim (`raw_text` — GitHub, GitLab,
  Redmine, Shortcut) or normalizes through a rich-text representation that rewrites arbitrary bytes
  (`rich_text_normalizing` — Jira ADF, Linear ProseMirror, Azure DevOps HTML-sanitized, Asana/Basecamp
  restricted-HTML, Notion blocks). **The gz64-blob-in-an-HTML-comment carrier is the `raw_text`-class
  realization** and REQUIRES `provider_body_storage_format == raw_text`. A `rich_text_normalizing`
  provider MISFITS the blob carrier (it would rewrite/strip the comment) and needs a class-appropriate
  carrier (an attachment, a sanitizer-safe encoding, or entry-splitting) — a FUTURE BD's design, not
  this one. The migrator FAILs loud (`provider <X> declares rich_text_normalizing storage; the gz64
  body-blob carrier requires raw_text — unsupported backend for v11.x`) rather than silently corrupting.
- **The migrator reads both capabilities from the ACTIVE provider** and enforces the overflow contract
  above against `provider_body_limit` (not a hard-coded 65,536), and refuses a `rich_text_normalizing`
  backend. On GitHub the bound is 65,536 stored bytes and the format is `raw_text`; on a smaller
  `raw_text` field (e.g. Trello 16,384, Jira 32,767 — both below ~43 KB) the SAME loud-fail fires at
  the smaller bound. A smaller-limit OR rich-text tracker never silently truncates/corrupts; it fails
  loud and the operator splits the entry or chooses a fitting provider.
- **Carrier requirement, stated once:** the gz64 carrier REQUIRES `provider_body_storage_format ==
  raw_text` AND `provider_body_limit ≥ worst_case_projected_body + SAFETY_MARGIN`. Today the worst case
  is BD-136 at 40,771 bytes, so any `raw_text` provider declaring ≥ ~43 KB is sufficient; GitHub
  (65,536) clears it with ~24.7 KB to spare. This is the honest tracker-agnostic statement (S-5#7 / the
  landscape census): the design does NOT over-claim "works on any tracker" — it works on the
  **raw-text-body class** (GitLab/Redmine/Shortcut FIT; Jira Cloud is a DOUBLE misfit — 32,767 cap AND
  ADF rewriting), declares the minimum it needs, and FAILs loud on any provider that cannot meet it.
  Same provider contract, class-appropriate carriers.

> **Empirical-Evidence Block (gzip is deterministic, so the size bound + the §3.3b fixed point both hold).**
> `CMD`: deterministic gzip (`GzipFile(mtime=0)`) of BD-136 body, encoded twice; compare; inspect the
> gzip mtime header field (bytes 4-7).
> `OUT`: the two encodings are byte-IDENTICAL; mtime field = `0 0 0 0`. `AT`: HEAD `feaa45d`,
> 2026-06-07. `INTERP`: `mtime=0` makes the gzip blob a pure function of the body (no wall-clock
> drift), so (a) the projected size is stable + measurable at design/guard time, and (b) the §3.3b
> idempotency fixed point survives gzip (cycle-2 blob == cycle-1 blob). `CONCL`: SUPPORTED.

### 3.3d OPERATIONAL RULES for the C-8 bulk create (R-OPS-2/3 pacing + R-OPS-6 mention/autolink)

The size budget (§3.3c) closes the CONTENT-limit gaps; the GH-rules census surfaces two OPERATIONAL
rules that the content-faithful round-trip does NOT cover but the real-repo C-8 flip must honor. Neither
is a losslessness break (the blob decodes byte-identically); both are real-create hygiene.

**(1) Bulk-create pacing (R-OPS-2/3 — the most material operational gap; S-5#1).** GitHub's SECONDARY
rate limit is ≤ 80 content-generating requests/minute AND ≤ 500/hour, and the documented mitigation is
"wait ≥ 1 second between mutative requests, serial, not concurrent." **Creating the pack's 211 issues
in one burst EXCEEDS the 500/hour secondary cap** and — worse (NUANCE-A) — can trip GitHub's ABUSE
detection and flag the PERSONAL pack account as spammy/invisible. Nothing currently paces this: the
forward create loop's only `sleep` is the post-create STABILIZE poll (`TMF_STABILIZE_SLEEP_SECS`), not
write pacing (re-verified this sweep — §S-3). The design:

- **Where it lives:** a PACING GATE in the forward create loop (`tracker-migrate-forward.sh`, between
  successive `provider_create` calls at `:911`/`:965`) — a `sleep` of `provider_min_write_interval_s`
  before each create after the first. It is in the migration LOOP (the thing doing the bulk writes),
  not the provider (the provider declares the rate; the loop enforces the gap), consistent with the
  existing capability/enforcement split.
- **What the provider DECLARES (new/!existing capability):** the GH provider already declares
  `rate_limits.writes_per_minute_recommended: 60` (`tracker-provider-gh.sh`). Add the explicit
  derived contract the loop reads: **`provider_min_write_interval_s`** (GitHub: 1, from R-OPS-3's
  "≥ 1 second") and **`provider_writes_per_hour_max`** (GitHub: 500, from R-OPS-2's secondary cap). The
  loop sleeps `provider_min_write_interval_s` between creates AND, if a run would exceed
  `provider_writes_per_hour_max`, it spreads/pauses (or, minimally for 211 ≤ 500/hr at ≥1s spacing =
  ~3.5 min wall-clock, the 1s gap alone keeps a 211-create run UNDER both caps: 211 creates × 1s ≈
  211s ≈ 3.5 min, well under the 80/min and 500/hr ceilings). 
- **Over-limit handling:** the provider ALREADY classifies `rate-limit-secondary` errors; the loop must
  HONOR `retry-after` (back off, never tight-retry) on a 403/429 — pacing PREVENTS it, retry-after is
  the backstop. This is fail-safe, not silent.
- **What C-7 tests of it (S-8):** the C-7 oracle asserts (a) the loop sleeps ≥
  `provider_min_write_interval_s` between creates (inject a fake clock / count the pacing sleeps — a
  unit-level assertion, no live wait needed in CI), and (b) on a simulated 429 the loop honors
  retry-after rather than tight-looping. The live scratch-repo leg (manual) confirms a real paced run
  does not trip the secondary limit.

**(2) Autolink / @mention side-effects on the real-repo create (R-OPS-6; S-5#2).** The VISIBLE H2
projection carries raw autolink/mention tokens (the blob is opaque base64 — round-trip SAFE; the
side-effect surface is the RENDERED H2 body). GitHub autolinks SEVERAL forms; I censused ALL of them
this sweep (the review's SHOULD-3): **`#NNN`** issue/PR refs — **21 entries**
(BD-065/066/069/114/128/138/161/164/165/166/167/168/169/170/173/179/186/188/189/191/192; Actions-step/
footnote refs, NOT GH issue numbers → spurious MIS-LINKED backlinks); **bare `@token`** mentions
OUTSIDE inline-code — **2 entries** (BD-023 `@objc`, BD-157 `@ModelAttribute`; fire a notification if
the token resolves to a real GH user); **bare commit-SHA hex (7-40)** OUTSIDE inline-code — **97
entries** (e.g. BD-001 `commit 08f7158`; 128 anywhere; GitHub autolinks a bare SHA to a commit in the
target repo); **bare URLs** (`https?://`) — **2 entries** (BD-043, BD-114; GitHub auto-links them).
**`GH-NNN`** and **`owner/repo#NNN`** forms — **0 entries**. So the real autolink surface is FOUR forms
(`#NNN`, `@`, commit-SHA, URL), not two.

- **The decision (carrier-side neutralization of the PROJECTION only — the INLINE-CODE-SPAN variant is
  PINNED; review SHOULD-3):** neutralize autolink/mention triggers IN THE VISIBLE H2 PROJECTION ONLY,
  at the COMPOSER (carrier-side). **PINNED MECHANISM: wrap each projected H2 field VALUE that contains
  ANY autolink trigger in an inline-code span (backticks); where the value already contains a backtick,
  use a longer backtick fence (n+1 backticks) so the span is well-formed.** GitHub renders NO autolink
  form inside an inline-code span — not `#NNN`, not `@`, not a commit-SHA, not a URL — so ONE general
  transform covers ALL FOUR measured forms. **The earlier-offered U+2060-word-joiner variant is
  REJECTED** because it only addresses `#`/`@` (insert after the sigil) and leaves bare commit-SHAs (97
  entries) and bare URLs (2) LIVE — it does not generalize over the full autolink surface. The
  inline-code-span variant is the property-fit choice: it is form-AGNOSTIC (it suppresses rendering of
  the whole value, regardless of which trigger it contains), so it needs no per-form enumeration and
  cannot miss a future autolink form. **The blob is UNTOUCHED** (it carries the verbatim bytes; reverse
  decodes the original tokens exactly), so this is purely a render-noise fix with ZERO round-trip effect
  and ZERO entry edits. It is a GENERAL transform of the projection, not a per-entry exception (no
  carve-out): it runs on all 211, is a no-op on values with no trigger, and neutralizes the
  `#NNN`/`@`/SHA/URL surface uniformly.
  - **Why projection-side, not entry edits:** every trigger is real authored text — Actions-step
    `#NNN` refs, `@objc`/`@ModelAttribute` Swift/Java annotations, real commit SHAs in `Resolved:`
    lines, real URLs — so editing the entries would CHANGE meaning (forbidden). The blob must carry
    them verbatim. So neutralization MUST be projection-side. (Accept-with-evidence was the alternative;
    rejected because a real-account spam/notification/mis-backlink risk on the C-8 dogfood is avoidable
    cheaply and cleanly. NOTE on severity: `#NNN` (cross-issue backlinks) and `@` (notifications) are
    the high-impact forms; bare-SHA autolinks resolve to benign commit links and URLs to plain links —
    lower impact — but the PINNED inline-code-span variant covers all four at no extra cost, so there is
    no reason to leave any live.)
- **What C-7 tests of it:** seed a fixture entry carrying ALL FOUR trigger forms (`#NNN`, a bare `@`,
  a bare commit-SHA, a bare URL); assert the composed H2 wraps each triggering value in an inline-code
  span (NO live autolink/mention of any form) AND the gz64 blob still decodes to the verbatim original
  tokens (round-trip unaffected).

### 3.3e GO-FORWARD ENTRY GUARDS (R-TITLE-1 title length + R-BODY-6 control chars; S-5#5)

The §2 census is CLEAN today (no entry violates any hard content rule), but two axes are UNGUARDED for
FUTURE entries — a new BD could silently introduce a violation that only surfaces at migration time.
Per `ci-guard-measure-then-bound`, guard them now with a GENERAL rule (no per-entry exception):

- **Title length (R-TITLE-1):** the stored title `BD-NNN: <title>` must be ≤ 256 chars. BD-208 is the
  worst today at 231 stored (25 headroom). Add a validate-pack assertion: for every entry, the
  ID-prefixed bold-header title ≤ 256. FAILs loud naming an over-length entry. (This lives in the new
  faithfulness check or the existing per-entry-tree structural check — the coder picks; it is a cheap
  per-entry length test.)
- **Control chars (R-BODY-6):** no entry body may contain a NUL, CR, or C0 control char other than tab
  / LF. Clean across all 211 today (measured this sweep — zero). Add a validate-pack assertion scanning
  each entry body for disallowed control bytes; FAILs loud naming the entry + the offending byte. This
  prevents a future entry from introducing a byte GitHub's body field handles undefined-ly.
- **Both are GENERAL go-forward guards** sized to the measured-clean tree (the bound is "zero
  violations"); they add NO allowlist and NO per-entry carve-out. They run in the unattended CI guard
  alongside the byte-faithfulness + size legs (§4.4).

### 3.4 Why this has ZERO carve-outs (criterion A)

- No field is named in the carrier logic. The serializer captures the entry's verbatim BODY as an
  opaque blob; the emit writes the blob back verbatim. The carrier does not know what fields exist —
  it carries BYTES. A new field (or a new prose block) added to any future BD is carried with no code
  change, because the carrier never enumerates fields at all.
- The 19 dropped classes are not enumerated anywhere in the fix — they live inside the verbatim blob
  exactly as authored. There is no "resolved-offender" list and no per-class branch.
- The `_rules.md`-vs-template `Position:` contradiction (§1.7) is resolved by making the carrier
  byte-faithful: the schema no longer needs to enumerate optional fields for migration purposes,
  because the migrator carries whatever bytes the entry body has. (The schema docs are reconciled in
  §3.5 so the contract and template agree, but that is a doc-correctness fix, not a migrator carve-out.)

### 3.5 The field-schema reconciliation (the §1.7 contradiction)

`backlog/_rules.md:49` names `Position:` as optional; METHODOLOGY Part 7 does not. With a
field-faithful carrier the migrator no longer cares, but the two schema SSOTs should still agree.
The minimal clean reconciliation (a doc edit, pack-chat-only surfaces — see §5 routing): make
`backlog/_rules.md`'s entry contract reference the template as the field SSOT and stop enumerating a
divergent optional-field list, OR add the extension fields to the template. **Architect
recommendation:** state in `_rules.md` that the migrator is field-faithful (carries every top-level
field verbatim) and that the template enumerates the COMMON fields — extension fields (Target,
Position, etc.) are admitted and preserved. This removes the contradiction without forcing every BD
into a fixed field list. (This is a recommendation; the schema-doc edit is a separate, smaller
change the planner sequences — see §5.)

### 3.6 Entry-rewrite is NOT part of the fix (criterion C is satisfied vacuously)

Because the fix is carry-fields (B), NO entry is rewritten; the per-entry lossless proof criterion C
demands is moot — zero entries change. The 211 entries are byte-untouched by this design; only the
migrator code + tests + the schema doc change.

---

## §4 — THE CI GUARD (close the green CI — criterion B; measure-then-bound)

The fix in §3 makes the migrator faithful. But a faithful migrator that later regresses must be
UN-MERGEABLE. The guard below would have FAILED the C-1..C-6 commits.

### 4.1 The exact green-CI cause (restated, then closed)

The conjunction of four gaps (RESEARCH §4, re-confirmed §1/§2): (1) the only content-faithfulness
oracle is manual-only + default-SKIP; (2) every fixture carries only the 9 carry-set fields; (3) the
CI round-trip test asserts structure, not field-completeness; (4) no validate-pack check measures
field faithfulness. The single missing assertion: **a forward→reverse field-faithfulness check that
runs UNATTENDED in CI against the REAL 211-entry tree.**

The C-7 oracle cannot BE that check — it requires a live GH repo (per-step approval; impossible
unattended) and its fixture can't carry the drop. So the guard must be a MOCK-FREE, NO-NETWORK check
that exercises the lossy code paths directly. This is achievable because the drop happens in the
PURE-PYTHON parse/compose/reconstruct functions (§1.1/1.2/1.3) — no `gh` needed.

### 4.2 The guard: a new validate-pack check — `check_migrator_field_faithfulness` (the next registry integer; 49 today)

**Check number (D-5 fixed).** The new check is the NEXT INTEGER in the validate-pack registry. The
highest existing banner is Check 48 (`check_removed_doc_advisory`, BD-195 C6), so the new check is
**49 today** — but THIS DESIGN HARDCODES NO NUMBER: the coder reads the registry at implementation
time and assigns the next free integer. (The original doc said "Check 48" in three places; all are
corrected to "the next registry integer.")

> **Empirical-Evidence Block (highest existing check banner = 48; the new check is the next integer = 49 today).**
> `CMD`: `grep -oE 'Check [0-9]+' scripts/validate-pack.py | grep -oE '[0-9]+' | sort -n | tail -1` ; `grep -nE '# .. Check 48' scripts/validate-pack.py`
> `OUT`: `48` ; `315:# ── Check 48 (BD-195 C6): JC-5 soft-advisory removed-doc guard ──`. `AT`: HEAD
> `feaa45d`, 2026-06-07. `INTERP`: 48 is taken; the next integer is 49 today, but the coder reads the
> live registry (a future BD may take 49 first). `CONCL`: SUPPORTED.

**Mechanism (no live GH; runs in CI on every push):** a new `def check_*` in `scripts/validate-pack.py`
that, for the REAL `/backlog/` tree, drives the migrator's pure functions in-process and asserts a
BYTE-FAITHFUL round-trip via the verbatim-blob carrier (§3.3):

1. For each `backlog/BD-*.md`, snapshot the ORIGINAL body span (lines 2..EOF, back-pointer stripped
   via `pe_strip_backpointer_stdin`).
2. Drive the pure path in-process (a bash sub-invocation of the libs, no network): forward
   `_tmf_parse_backlog_file` → `tmf_compose_issue_body` (emits the `pack-entry-body-gz64` blob) →
   feed the composed Issue body through `tracker_migrate_reverse_reconstruct` → `_tmr_emit_pack_tree`
   (pack branch — the §3.3 verbatim-blob emit), producing the reconstructed body span.
3. **Assert RECONSTRUCTED body span == ORIGINAL body span, BYTE-FOR-BYTE** (back-pointer stripped).
   This is now ACHIEVABLE green (review-2 A-1/D-1/D-3): because the pack emit writes the verbatim
   blob back (not the fixed-order template projection), the 20 no-Blockers/Unblocks entries no longer
   get injected `Blockers: None` / `Unblocks: None` lines, and field order is preserved. The byte leg
   is the ONLY leg — it is strong enough to catch the prose-block corruption (B-1: a shredded
   `unblocks` would make the reconstructed body differ) AND order corruption AND value corruption.
   There is NO weak "label-set ⊆" leg (review-2 D-1 proved a label-set leg FALSE-PASSES the
   prose-block loss — it is removed).
4. FAIL naming the entry + a unified diff of the first differing lines.

**Why the byte-leg is now both achievable AND strong (review-2 A-1 + D-1 reconciled).** The original
design had a dilemma: the byte leg false-failed 20 entries (against the fixed-order emit), and the
label-set leg false-passed the prose-block loss. The §3.3 emit rewrite DISSOLVES the dilemma — once
the pack emit reproduces the verbatim body, byte-equality is the correct, achievable, and strong
assertion. The dilemma existed only because the original design tried to keep the fixed-order emit.

> **Empirical-Evidence Block (the existing fixed-order emit would FALSE-FAIL the byte leg on 20 entries — why the emit rewrite is mandatory).**
> `CMD`: `c=0; for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -qE '^Blockers:' || c=$((c+1)); done; echo $c` (and same for `Unblocks:`) ; `sed -n '760,790p' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: `20` entries lack a `Blockers:` line (same 20 lack `Unblocks:`): BD-001..BD-019 + BD-195.
> The emit render loop unconditionally does `lines.append("Blockers: " + (... if bl else "None"))`,
> `... "Unblocks: " ...`, and `else: lines.append("Resolved: n/a")`, then appends extras LAST.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: against the CURRENT emit a byte-faithful round-trip of
> BD-001 injects `Blockers: None` + `Unblocks: None` lines the original lacks → byte leg FALSE-FAILS.
> The §3.3 verbatim-blob emit (write `raw_body` back) suppresses this — it emits exactly what the
> original had. `CONCL`: SUPPORTED — the byte leg requires the §3.3 emit rewrite (folded into C-4.5,
> §5.b); without it the guard is unshippable.

> **Empirical-Evidence Block (delimiter-collision measure-then-bound: 4 entries carry `-->`, 1 carries a fence — base64 avoids both).**
> `CMD`: `c=0; for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -qF -- '-->' && c=$((c+1)); done; echo $c` ; `for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -qF -- '-->' && basename "$f" .md; done` ; `c=0; for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -qF '```' && c=$((c+1)); done; echo $c`
> `OUT`: `-->` in body: `4` → `BD-065 BD-069 BD-103 BD-136` (entries that DOCUMENT the HTML-comment
> marker mechanism, e.g. BD-065 `<!-- pack-id: TD-NNN -->`, BD-136 `<!-- BEGIN project-owned -->`);
> triple-backtick fence in body: `1` → `BD-136`. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: a naive
> `<!-- pack-fields ... -->` (raw text) carrier would be CORRUPTED by these 4 entries (the comment
> terminates at the embedded `-->`); a markdown-fence carrier would collide with BD-136. The base64
> blob (§3.3) is collision-proof — its alphabet cannot contain `-->`, `<!--`, a fence, or a comma —
> verified byte-faithful on BD-204 + BD-136 (§3.3 EE). `CONCL`: SUPPORTED — the delimiter is bounded
> by measurement, not assumption.

> **Empirical-Evidence Block (53 multi-paragraph Description entries — the blob preserves interior blank lines; empirically verified on a worst case).**
> `CMD`: a python scan counting entries whose Description value contains an internal blank line ;
> AND the base64 round-trip of BD-204 (a no-Description, prose-heavy worst case): `tail -n +2 backlog/BD-204.md | base64 | base64 -d | diff - <(tail -n +2 backlog/BD-204.md)`
> `OUT`: multi-paragraph-Description entries: `53` (BD-021/022/023/024/038/039/040/041, ...); the
> base64 round-trip diff on BD-204 is EMPTY (byte-identical, interior blank lines preserved).
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the blob carries raw bytes, so interior blank lines and
> multi-paragraph values survive by construction — verified empirically (not asserted) on the prose-
> heaviest entry. A per-field "Label: value" emit would re-flatten these; the blob does not.
> `CONCL`: SUPPORTED (review-2 C-2 closed empirically).

**Why this catches THIS gap.** Run today (pre-fix) against BD-204, step 3 byte-compares the original
body (with Target/Problem/Scope/Out-of-scope/References/Position + the prose blocks) against the
reconstructed body (which has none of them, and a shredded `unblocks`). The diff is large and
non-empty → FAIL. The guard goes RED on the exact gap that shipped green — and, unlike a label-set
leg, it ALSO catches the prose-block corruption a label-set leg would miss.

### 4.3 Measure-then-bound: the guard is sized to the REAL tree, with NO allowlist of "OK to drop"

Per `ci-guard-measure-then-bound`: I MEASURED the complete field set (§1.4: 28 labels) AND the
delimiter-collision set (§4.2 EE: 4 `-->` entries + 1 fence) AND the multi-paragraph set (53). Categorize:

- **KEEP/CARRY (all bytes of every body):** with the §3.3 verbatim-blob carrier, EVERY byte of the
  entry body round-trips. There is NO "STRIP" category and NO drop-allowlist — a drop-allowlist would
  re-admit the bug. The guard asserts byte-equality, full stop.
- **The legitimate non-carried tokens** (Type/Status→labels; Blockers/Unblocks→links) are the H2/
  label PROJECTION, not the round-trip source; the byte leg compares the blob-emitted body, so they
  are covered without an exception.
- **Post-fix verification (review-2 D-3 — EMPIRICAL, not logical).** The original doc said "verified
  logically; coder confirms empirically" — review-2 rejected that. I replaced it with measurement:
  the base64 blob round-trips the two hardest entries (BD-204 73-shred/no-Description; BD-136 -->/fence)
  byte-identical (§3.3 EE), and the byte-faithful emit reproduces the 20 no-Blockers entries without
  injected lines (§4.2 EE). The remaining 209 entries are strictly easier (they carry fewer hazards).
  The projected post-fix guard runs CLEAN on the measured worst cases; the coder runs it across all
  211 at implementation as the final confirmation, but the LOAD-BEARING worst cases are verified HERE.

> **Empirical-Evidence Block (the hardest hazard classes are each verified byte-faithful under the gz64 blob carrier).**
> `CMD`: per-hazard gzip+base64 round-trip `diff` (the §3.3 carrier): BD-204 (no-Description + 73-shred
> prose blocks); BD-136 (`-->` + markdown fence + 19.7 KB File/Symbol); BD-021 (multi-paragraph
> Description); each `tail -n +2 $f | python3 -c 'import sys,gzip,io; b=sys.stdin.buffer.read(); buf=io.BytesIO(); gzip.GzipFile(fileobj=buf,mode="wb",mtime=0).write(b)... ; print(base64)' | base64 -d | gunzip | diff - <(tail -n +2 $f)`
> `OUT`: every diff EMPTY (byte-identical, gzip+base64). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`:
> the gz64 carrier is byte-faithful on the no-Description, the prose-shred, the delimiter-collision,
> the fence, and the multi-paragraph hazard — the complete hazard taxonomy. (Raw-base64 also
> round-trips identically; the gzip layer changes only SIZE, not fidelity — §3.3c.) The post-fix guard
> is verified against the projected state on the measured worst cases, not asserted logically.
> `CONCL`: SUPPORTED.

### 4.4 Go-forward schema enforcement + the SIZE assertion (a new entry that drops content OR breaches the body limit cannot merge)

The guard runs the migrator and asserts BYTE-faithfulness — so a NEW BD with ANY new field OR prose
block is automatically covered (the blob carries the bytes; the guard confirms byte-equality). There
is no field-whitelist to maintain (a carve-out generator). The schema-enforcement IS the byte-faithful
guard: if a future change makes the migrator alter any byte of any entry on round-trip, the guard
FAILs on the first affected entry. This verifies BEHAVIOR (byte round-trip), not DECLARATION.

**What the guard asserts about SIZE (N-1) — on the ACTUAL composed body, not a proxy (review-3 item).**
The same unattended check measures size on the **byte length of the ACTUAL composed Issue body the
check already built in step 2** (`len(tmf_compose_issue_body(...))` — the real H2 + the real gz64 blob
+ the real marker wrapper) and asserts it is within `provider_body_limit − SAFETY_MARGIN` (§3.3c). It
does NOT use the `len(raw_body)+80+29+len(blob)` distribution PROXY the §3.3c measurement used for the
census — the proxy upper-bounds the H2 by the raw body and is fine for ranking entries, but the GUARD
and the forward composer's overflow check (§3.3 step 2) both compute on the byte length of the
genuinely composed body so the enforced number is the real wire size, never an estimate. It FAILs
naming any entry whose composed body breaches the budget — so a new or grown entry that would exceed
the body limit is caught UNATTENDED in CI, BEFORE the C-8 flip. (Today the worst composed body, BD-136,
is 40,771 bytes / 62.2% — the guard runs green; a future entry that grew past the budget goes RED.)
The same identical measurement (composed-body byte length) is used in THREE places — the forward
composer's pre-create overflow check, this CI guard's size leg, and the C-7 oracle's size assertion
(§5.c) — so all three enforce the identical number. The guard uses the GitHub `provider_body_limit`
(65,536) for the pack instance; the provider-layer contract (§3.3c) generalizes the bound to any
tracker.

**Two more go-forward legs the same guard runs (§3.3e / S-5#5).** (a) **Title length (R-TITLE-1):**
for every entry, assert the ID-prefixed bold-header title ≤ 256 chars (BD-208 worst at 231 today; a
future 248+ title goes RED before it can break a create). (b) **Control chars (R-BODY-6):** scan each
entry body for a NUL/CR/C0 control byte other than tab/LF, FAIL naming the entry + byte (clean across
all 211 today). Both are GENERAL per-entry assertions sized to the measured-clean tree (bound = zero
violations); no allowlist, no per-entry carve-out. With the byte-faithfulness leg + the size leg + the
mention-neutralization assertion (§3.3d), the one unattended check enforces every TESTABLE rule the
GH-rules census surfaces.

### 4.5 ENUMERATE-ENCODING-SURFACES (every surface that encodes the guard's expected state)

The fix + guard touch these surfaces; ALL update in lock-step (asymmetric coverage = audit gap).
Reconciled to the verbatim-blob model + the review-2 omissions (G-1 workflow, G-2 phase site, G-3 note):

| Surface | Change | Why it encodes the state |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` — `_tmf_parse_backlog_file` (add `raw_body`), `tmf_compose_issue_body` (6th DEFAULTED `raw_body` param → emit `pack-entry-body-gz64` blob = base64(gzip-mtime0(raw_body)); + the §3.3c size-budget overflow fail-loud check), BD call site `:901` | capture + gzip-emit the verbatim blob + enforce the size budget | the producer of the round-trip truth + the size guard |
| `scripts/lib/tracker-migrate-forward.sh` — **phase call site `:959`** (G-2) | ensure the new 6th param is OPTIONAL (`${6:-}`) so the 4-arg phase call still works | a missed surface in v1; a mandatory param breaks the phase path |
| `scripts/lib/tracker-migrate-reverse.sh` — `tracker_migrate_reverse_reconstruct` (read the gz64 marker → base64-decode + gunzip → `raw_body`), `_tmr_emit_pack_tree` (REWRITE pack branch to emit `raw_body` verbatim; DELETE the dead `extra_fields` per-field render at `:758`), the §3.3a NORMALIZATION-TOLERANT divergence comparator (N-2) | the consumer; the emit REWRITE; the human-edit backstop | makes the round-trip byte-faithful; removes the abandoned per-field model; detects GH-side divergence without false-positives |
| `scripts/validate-pack.py` — NEW `check_migrator_field_faithfulness` (the next registry integer, 49 today) + registration in `main()`; asserts BOTH byte-faithfulness AND the §3.3c size budget per entry | the unattended CI guard | the CI gate that fails a lossy/corrupting migration OR a body-limit breach |
| **`.github/workflows/validate-pack.yml`** (G-1 — was MISSING in v1) | wire the new per-check test (`bash scripts/tests/<new-check-test>.sh`) | Check 42 (`check_ci_workflow_wires_per_check_tests`, no exemption) FAILS if a `test-validate-pack-check*.sh` is on disk but not wired here |
| `scripts/tests/tracker-migrate-forward-test.sh` | add a fixture entry carrying top-level drop-set fields + a prose block; assert the `pack-entry-body-gz64` blob appears + decodes; assert the size-overflow path FAILs loud on a synthetic over-limit entry | unit-level encode of the carry + size contract |
| `scripts/tests/tracker-migrate-reverse-test.sh` | assert the blob decodes and the pack emit writes it back verbatim (incl. an entry with NO Blockers — no injected `None`) | unit-level encode of the reverse/emit contract |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` + `fixtures/roundtrip/bd-v11.0/BACKLOG.md` | add an entry with top-level drop-set fields + a prose block + no Blockers; assert byte-faithful round-trip | the mock round-trip now exercises the drop + the emit rewrite |
| `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md` + the C-7 test (§5.c rebuild) | add top-level drop-set fields + a no-Description entry | the live oracle's fixture must carry what the guard checks |
| the NEW per-check test for the faithfulness check (e.g. `scripts/tests/test-validate-pack-check-<NN>-field-faithfulness.sh`) | positive (all-bytes round-trip PASSES) + negative (a synthetic lossy/injecting emit FAILS) | pins the new check's banner/output; MUST be wired into the workflow (row above) |
| `test-fixtures/manifest.txt` | regen `bash test-fixtures/build.sh --all --clean` (scripts/ touched) | the manifest invariant (`regenerate-manifest-v11-surface`) |
| `backlog/_rules.md` (§3.5 reconciliation) | state byte-faithful migration; remove the divergent optional-field enumeration | the schema-contract SSOT |
| `scripts/lib/tracker-edit.sh` — the Mode-3 CRUD writer (`tracker_edit_entry` / its body composer) (§3.3a / B-3) | regenerate BOTH the H2 sections AND the blob from the same entry object on every `provider_update` | keeps the two body representations consistent on tracker-side writes (C-3 scope addition) |
| `scripts/lib/tracker-provider.sh` (+ the GH backend `tracker-provider-gh.sh`) — NEW declared capability `provider_body_limit` (§3.3c / N-7) | each provider DECLARES its body-field byte capacity (GH: 65,536); the migrator reads the ACTIVE provider's limit and enforces the overflow contract against IT | the tracker-agnostic size contract — keeps the design honestly portable, not tacitly GH-sized |
| `scripts/tests/tracker-provider-test.sh` (or the capability test) | assert the GH provider declares `provider_body_limit=65536`; assert a smaller-limit mock provider triggers the loud-fail at its bound | encodes the provider-layer size contract (N-7) |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (C-7) — CREDENTIAL PREFLIGHT (§5.f / constraint B): verify create+issues+archive, NOT delete, fail-loud on a gap; FIRST live action | enforce the required-permission set before any live write | a missing permission fails before a partial 211-create run |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (C-7) — SCRATCH DISPOSAL REWORK (§5.c / constraint B): replace `gh repo delete` + assert-gone with `gh repo archive` + assert-`isArchived`; trap-archives on failure; recommend manual delete; grep-guard asserts NO `gh repo delete` in the test source | archive-not-delete teardown | the no-delete credential cannot leave a writable orphan; tooling never deletes |
| `scripts/lib/tracker-provider.sh` / `tracker-provider-gh.sh` — NEW `provider_body_storage_format` capability (`raw_text` for GH; §3.3c / S-5#7) + `provider_min_write_interval_s`=1 + `provider_writes_per_hour_max`=500 (§3.3d / S-5#1) | declare storage class + pacing contract | the honest portability boundary + the pacing the loop enforces |
| `scripts/lib/tracker-migrate-forward.sh` — PACING GATE in the create loop (`:911`/`:965`): `sleep provider_min_write_interval_s` between creates; honor `retry-after` on 403/429 (§3.3d / R-OPS-2/3 / S-5#1) | enforce bulk-create pacing | prevents the 211-create burst from tripping the 500/hr secondary cap + abuse detection |
| `scripts/lib/tracker-migrate-forward.sh` — `tmf_compose_issue_body` AUTOLINK NEUTRALIZATION of the H2 PROJECTION (PINNED inline-code-span variant — wraps any projected value containing a `#NNN`/`@`/commit-SHA/URL trigger in backticks; covers ALL FOUR forms; blob untouched) (§3.3d / R-OPS-6 / S-5#2 / review SHOULD-3) | neutralize render-side autolink/mention/SHA/URL triggers | clean C-8 real-repo create (no spurious backlinks / notifications / SHA-or-URL links); ZERO round-trip effect |
| `scripts/validate-pack.py` — the same check ALSO asserts title ≤ 256 (R-TITLE-1) + no disallowed control byte (R-BODY-6) (§3.3e / S-5#5) | go-forward entry guards | a future over-length-title or control-char entry fails CI before it can break a create |
| `scripts/tests/tracker-migrate-forward-test.sh` — pacing assertion (sleeps ≥ interval between creates; honors retry-after on a simulated 429) + mention-neutralization assertion (composed H2 has no live `#NNN`/`@` trigger; blob still decodes verbatim) | unit-level encode of the pacing + neutralization contracts | the operational rules are TESTED, not just declared |

**G-3 note (intentional pack/project divergence).** The 3 project-side `_rules.md` files under
`project-template/docs/project/` encode the SAME schema but are PROJECT-side (pack-only-denied). This
design correctly does NOT touch them; the pack and project schema docs will diverge until BD-206/207
apply the same fix project-side. Per `pack-project-separation` (separate artifacts) this asymmetry is
correct-by-design, not a defect — flagged so review-2 does not mis-flag it.

> **Empirical-Evidence Block (Check 42 has no exemption and FAILs an unwired per-check test — the workflow yml is a required lock-step surface).**
> `CMD`: `grep -n 'check_ci_workflow_wires_per_check_tests' scripts/validate-pack.py` ; `sed -n '6486,6500p' scripts/validate-pack.py`
> `OUT`: `6486:def check_ci_workflow_wires_per_check_tests` — enumerates `scripts/tests/test-validate-pack-check*.sh`
> on disk and FAILs any lacking a `bash scripts/tests/<file>` line in `.github/workflows/validate-pack.yml`;
> "intentionally has no exemption mechanism." `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the new
> per-check test MUST be added to the workflow in the SAME commit as the test file, or Check 42 goes
> RED. `.github/workflows/validate-pack.yml` is in the lock-step set (it was MISSING in v1 §4.5).
> `CONCL`: SUPPORTED.

> **Empirical-Evidence Block (no existing validate-pack check covers tracker field/body faithfulness — the new check is net-new).**
> `CMD`: `grep -niE 'def check_.*(field|label|whitelist|migrat|faithful|carry|lossless)' scripts/validate-pack.py`
> `OUT`: only `check_migrator_framework_inventory` matches (the vN→vM VERSION migrator, not tracker).
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: no check asserts tracker forward→reverse body
> faithfulness; the new check is net-new and takes the next registry integer (49 today). `CONCL`:
> SUPPORTED.

---

## §5 — RE-SCOPE & SEQUENCING

### 5.a Proposed RE-SCOPED `backlog/BD-204.md` (re-scope FIRST per adversarial discipline; supersedes the fix-2 §5.a text)

The entry carries stale DESIGN BASELINE / IMPLEMENTATION CARRY-FORWARD directives that read as if the
carrier is solved. Add ONE authoritative section recording the gap + the full rule-swept fix; correct
the ambiguous archive wording. The proposed text (a NEW section + the one BD-204.md:20 wording fix —
Pack Chat applies, pack-chat-only; pack-coder does NOT touch entries):

```
LOSSLESS FIELD-CARRIER + GH-RULES FIX (user 2026-06-06/07 — CRITICAL, supersedes the prior carrier
language; grounded in the 28-rule GH-Issues census + the tracker-landscape census):
  The C-1..C-6 forward migrator carried a 9-field whitelist and SILENTLY DROPPED 19 other top-level
  field classes (Target/Position/Scope/Problem/Goal/Out of scope/References/Acceptance criteria/
  Encapsulation/Surfaced/Steps/Risk note/Quality bar/Pipeline/Paused/Note/Disposition/Alias) — and
  CORRUPTED prose blocks into the `unblocks` list — while full CI passed green. The `pack-extra-fields`
  carrier the prior design named is DEAD code. THE FIX (ARCHITECTURE-BD-204-LOSSLESS-FIX.md): make the
  migrator FIELD-FAITHFUL via a VERBATIM-BODY BLOB — forward gzip(mtime=0)+base64-encodes each entry's
  complete body verbatim (lines 2..EOF) into one Issue-body marker `<!-- pack-entry-body-gz64: ... -->`;
  reverse base64-decodes+gunzips it back byte-for-byte (NO field re-parse). Decode is FAIL-LOUD on a
  corrupt blob (never silent-empty). ZERO per-field carve-outs; NO entry is rewritten.
  SIZE: budgeted on STORED BYTES against the provider's declared `provider_body_limit` (GH 65,536);
  worst entry BD-136 = 40,771 bytes (62.2%) under gz64; the forward composer FAILs loud (never
  truncates) above `limit − margin`.
  PORTABILITY: the blob is the RAW-TEXT-BODY-CLASS carrier; the provider declares
  `provider_body_storage_format` (raw_text vs rich_text_normalizing) — GitLab/Redmine/Shortcut FIT,
  Jira Cloud MISFITS (32,767 cap + ADF rewriting). Same provider contract, class-appropriate carriers.
  OPERATIONAL (real-repo C-8): the create loop PACES writes (≥1s between creates, honor retry-after) to
  stay under GH's 80/min + 500/hr secondary cap and avoid abuse-flagging; the composer NEUTRALIZES
  `#NNN`/`@` autolink/mention triggers in the VISIBLE H2 PROJECTION ONLY (blob untouched) so the
  211-issue create scatters no spurious backlinks / mention notifications (21 `#NNN` + 2 bare-`@`
  entries).
  GO-FORWARD GUARDS: the CI guard also enforces title ≤ 256 (R-TITLE-1; BD-208 worst at 231) and
  no NUL/CR/control byte in a body (R-BODY-6), so a future entry cannot silently introduce a violation.
  CI: validate-pack `check_migrator_field_faithfulness` (next registry integer) asserts byte-faithful
  round-trip + size + title + control-char on the REAL tree every push (un-mergeable on regression);
  wired into validate-pack.yml (Check 42). v11.0 launch-gate (no deferral); lands BEFORE the C-8 flip.
```

DISAMBIGUATION of BD-204.md:20 "scratch-repo proof → archive → real flip" (S-5#3 / R-ACCT-4 — the ONE
entry-WORDING change). **SETTLED (user, Option A — no longer an open A-vs-B question).** An archived GH
repo is fully READ-ONLY, so "operate on an archived repo" is impossible; the settled reading is:
"archive" refers to disposal of the THROWAWAY SCRATCH proof repo, NOT the real repo. **The REAL pack
repo is NEVER archived** — it stays live and editable (future BDs, reverse flips, ongoing pack work all
require it writable). **Scratch disposal end-state = ARCHIVE** (the credential can archive but NOT
delete — see §5.f); the run additionally RECOMMENDS a manual delete to the user (tooling never deletes).
The proof is REPEATABLE: as many throwaway scratch repos as needed, and C-8 fires ONLY on a green
rehearsal + explicit user approval. Settled wording fix for BD-204.md:20:
`Dogfood-sequence gated (REPEATABLE scratch-repo proof — as many throwaway scratch repos as needed,
each ARCHIVED at end + a manual-delete recommendation to the user — then, on a green rehearsal +
explicit user approval, flip the REAL (never-archived, stays-editable) pack repo) per user direction.`
The IMPLEMENTATION CARRY-FORWARD line (Deferred forward-encode) is already landed
(`_tmf_labels_for_entry` `Deferred → status:deferred`) — surface as a NOTE, do not re-open.

### 5.b Which NEW commits own the fix, and where they slot

The fix slots BEFORE the parked C-7 (the oracle must test the fixed behavior) and BEFORE C-8 (the
flip must not lose data). Proposed new commits, inserted as **C-4.5 .. C-4.7** (after the landed
C-1..C-6, before the parked C-7/C-8 — keeping the existing numbering stable):

- **C-4.5 — gz64 verbatim-body-blob carrier + EMIT REWRITE + SIZE BUDGET + MENTION-NEUTRALIZATION
  (review-2 A-1/N-1/N-7 + sweep S-5#2/#4/#6/#7).** `tracker-migrate-forward.sh` (parser adds
  `raw_body`; composer adds the DEFAULTED 6th `raw_body` param → `pack-entry-body-gz64` blob =
  base64(**python3** gzip-mtime0(raw_body)); + the §3.3c size-budget overflow fail-loud check on the
  ACTUAL composed-body byte length vs the active provider's `provider_body_limit` (STORED-BYTE axis);
  + the §3.3d AUTOLINK NEUTRALIZATION of the H2 PROJECTION ONLY (PINNED inline-code-span
  variant — covers `#NNN`/`@`/commit-SHA/URL; blob untouched); BD call site `:901`; phase call site `:959` param-default check),
  `tracker-migrate-reverse.sh` (reconstruct reads the gz64 marker → **python3** base64-decode + gunzip
  → `raw_body`, **FAIL-LOUD on a corrupt blob, never silent-empty**; **`_tmr_emit_pack_tree` pack
  branch REWRITTEN to emit `raw_body` verbatim** — DELETE the dead `extra_fields` per-field render at
  `:758`), **`tracker-provider.sh` + `tracker-provider-gh.sh` declare `provider_body_limit` (GH 65,536)
  + `provider_body_storage_format` (`raw_text`) + `provider_min_write_interval_s` (1) +
  `provider_writes_per_hour_max` (500)**, their unit tests, the roundtrip test + fixtures, manifest.
  Pack-only. The CLIENT (`surface != "pack"`) emit branch is UNTOUCHED (BD-207). (Supersedes the
  phantom `pack-extra-fields` language; the C-4 design REALIZED correctly, with the emit rewrite, gzip
  size-bound, python3-codec pin, corrupt-blob fail-loud, mention-neutralization, and storage-format
  capability the reviews + the rules sweep surfaced.)
- **C-4.6 — the CI guard (byte-faithfulness + SIZE + TITLE + CONTROL-CHAR; sweep S-5#5).**
  `validate-pack.py` new `check_migrator_field_faithfulness` (the next registry integer, 49 today —
  NOT hardcoded) asserting, per entry against the REAL tree: (1) byte-faithful gz64 round-trip; (2) the
  §3.3c size budget on the ACTUAL composed body; (3) title ≤ 256 (R-TITLE-1); (4) no NUL/CR/disallowed
  control byte (R-BODY-6) + its per-check test + **its workflow-yml wiring
  (`.github/workflows/validate-pack.yml`, mandatory or Check 42 fails — D-4/G-1)** + positive/negative
  fixtures (a synthetic over-limit body, an over-length title, and a control-byte body each FAIL their
  leg), manifest. Pack-only. (Lands AFTER C-4.5 so the guard runs green on the fixed migrator.)
- **C-4.7 — schema-doc reconciliation.** `backlog/_rules.md` byte-faithful-migration statement
  (§3.5). Pack-only. (`_rules.md` is pack-chat-only — but a contract change is MAJOR → coder per the
  MAJOR/MINOR rule. METHODOLOGY Part-7 is NOT edited: it is `supporting-docs/` (ships to clients), so
  editing it forfeits the `pack-only` keyword — review-2 F-2; reconcile via `_rules.md` only.)
- **C-3 AMENDMENT (review-2 B-3 + N-2 — folded into the existing C-3 CRUD commit, not a new commit).**
  `tracker-edit.sh` (`tracker_edit_entry` / its body composer) MUST, on every Mode-3
  `provider_update`, regenerate BOTH the H2 sections AND the `pack-entry-body-gz64` blob from the same
  entry object, so a tracker-side edit keeps both body views consistent (§3.3a). The reverse-path
  divergence comparator (§3.3a (ii)) MUST be the NORMALIZATION-TOLERANT comparator (line-ending +
  per-line trailing-whitespace canonicalization, N-2) so GitHub's own body normalization does not
  false-positive an untouched issue. Without the sync a `tracker-edit.sh` write leaves a stale blob;
  without the tolerant comparator the backstop becomes a noise generator.
- **C-8 SCOPE ADDITION (the real-repo dogfood flip — sweep S-5#1/#2/#3).** The C-8 forward run MUST use
  the §3.3d PACED create loop (≥1s between creates; honor retry-after) so the 211-issue create stays
  under GH's 80/min + 500/hr secondary cap and never trips abuse-flagging on the personal account; it
  MUST use the §3.3d mention-neutralized composer so no spurious `#NNN` backlinks / `@` notifications
  scatter on the live repo; and it MUST target the REAL (NON-ARCHIVED) pack repo — the BD-204.md:20
  "archive" step is teardown of the THROWAWAY scratch repo, not an operate-on-archived step (S-5#3;
  archived repos are read-only — any create/write fails outright). C-8 is the existing PLAN-BD-204 §C-8
  commit; these are scope ADDITIONS to it, gated on C-7 green + explicit user approval (the live RUN is
  user-gated, agents never run it).

> **Empirical-Evidence Block (the landed C-1..C-6 are in the tree; C-7/C-8 are not yet — the fix slots between).**
> `CMD`: `git log --oneline -8` (the commit history) ; the task brief states "C-1..C-6 landed
> CI-green; C-7 (a lossless oracle) and C-8 (the real flip) remain."
> `OUT`: HEAD `feaa45d`; the C-7 oracle EXISTS as a parked test file
> (`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`, read in full this session) but is
> manual-only/default-SKIP and not the dogfood flip. `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`:
> C-4.5/4.6/4.7 land after the committed C-6 and before the parked C-7 is rebuilt + C-8 fires.
> `CONCL`: SUPPORTED.

### 5.c C-7 disposition (REBUILD, not discard) + the updated rebuild spec (sweep S-8)

**Disposition verdict: REBUILD.** The parked `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
is the ONLY surface that can empirically confirm the DOCUMENTED-SILENT platform behaviors (DS-1 stored
byte-verbatim, DS-2 web-edit normalization) on the real target repo, and it is the C-8 dress rehearsal.
Discarding it would leave the live-GH round-trip unproven before the flip. So it is REBUILT, not
discarded — its current fixture (carry-set-only; BD-903 sub-blocks INSIDE Description) cannot catch the
drop OR the new operational rules, so the rebuild is substantial.

The rebuilt oracle MUST exercise BOTH the content carrier AND the now-testable operational rules:

- **Drop-set + no-Description fixtures (the carrier):** add a fixture entry with TOP-LEVEL drop-set
  fields (`Target:`/`Position:`/`Scope:`/`Problem:`/`References:`/`Out of scope:`) interleaved with
  carried fields (order-faithful stress), and a NO-`Description:` entry (worst-case cohort). The
  content-faithfulness leg then truly exercises the drop (pre-fix FAIL, post-fix clean). Keep the
  BD-903 sub-blocks-inside-Description case.
- **Size leg (S-5#4/#6):** add a fixture entry near the budget and assert the composer's overflow
  fail-loud fires above `provider_body_limit − margin` (using the SAME composed-body-byte measurement
  as the CI guard + the forward composer); assert a within-budget entry passes. Assert the size is
  computed on the ACTUAL composed body.
- **Pacing leg (S-5#1 / R-OPS-2/3):** assert the create loop sleeps ≥ `provider_min_write_interval_s`
  between creates (count the pacing sleeps via a test seam / fake clock — no real wall-clock wait in
  CI) and honors `retry-after` on a simulated 429 (no tight-retry).
- **Autolink-neutralization leg (S-5#2 / R-OPS-6; review SHOULD-3):** seed a fixture entry carrying ALL
  FOUR trigger forms (`#NNN`, bare `@`, bare commit-SHA, bare URL); assert the composed H2 wraps each
  triggering value in an inline-code span (NO live autolink/mention of ANY form) AND the gz64 blob still
  decodes to the verbatim original tokens (round-trip unaffected).
- **Corrupt-blob leg (S-5#6):** feed a deliberately corrupted `pack-entry-body-gz64` marker; assert
  reverse FAILS LOUD (never emits an empty/partial body).
- **Credential-capability preflight leg (NEW — constraint B):** the FIRST live action (before any
  `gh repo create`) runs the §5.f preflight — verify the credential can create repos, write issues, and
  ARCHIVE, and explicitly CANNOT (need not) delete; FAIL LOUD on any MISSING required permission. The
  default-SKIP guard (env-var + `gh auth status`) stays; the preflight is the capability check beyond
  mere auth.
- **Scratch DISPOSAL contract — REWORKED for the no-delete credential (constraint B; supersedes the
  parked test's `gh repo delete` + assert-gone).** The credential's PAT has NO repo-delete permission
  (deliberate — prevents accidental real-repo deletion); deletion is a MANUAL user-only step. So:
  - **Tool-performed end-state = ARCHIVE** (`gh repo archive "$SCRATCH_REPO" --yes` — the PAT CAN
    archive), making the scratch repo READ-ONLY. The trap-on-exit ARCHIVES on FAILURE too (never leave
    a WRITABLE orphan scratch repo), surfaced LOUDLY.
  - **The run RECOMMENDS manual deletion** to the user as its final output (`RECOMMEND: manually delete
    the scratch repo <slug> (gh repo delete requires a permission this token deliberately lacks)`) —
    tooling NEVER deletes.
  - **The oracle asserts the scratch repo is ARCHIVED (read-only), NOT gone** (`gh repo view --json
    isArchived` → true), replacing the old "assert it is gone." A `gh repo view` that still shows a
    WRITABLE scratch repo at end is a FAIL.
- **REPEATABLE multi-rehearsal (constraint B / SHOULD-4):** the oracle is designed to be RUN MANY TIMES
  — each run provisions a UNIQUELY-named throwaway scratch repo (the existing `pack-bd204-oracle-$$-<ts>`
  name pattern already guarantees uniqueness), archives it at end, and recommends manual delete. There
  is no single-shot assumption; as many rehearsals as needed precede C-8. Archived scratch repos
  accumulate until the user manually deletes them (a known, surfaced consequence of the no-delete
  credential — not a defect, and MEASURED benign per R-ACCT-5 / §11.3: personal repos are unlimited
  below a 100,000 cap and issues are DB-stored — an accumulating archived-scratch campaign stays orders
  of magnitude under both quota axes, so the cadence has no repo-count or on-disk wall; manual delete is
  optional housekeeping).
- **CI-execution model:** keep the manual-only + default-SKIP guard (test-infra-self-provisioned). C-7
  stays the live dress rehearsal; the C-4.6 faithfulness check is the UNATTENDED gate — and the
  pacing/neutralization/size/corrupt-blob/preflight assertions that DON'T need live GH (the unit-level
  legs) ALSO run in the unattended battery (the in-process check or a mock-based unit test), so CI
  tests them even though the full live round-trip stays manual.

### 5.d Corrections owed to ARCHITECTURE-BD-204.md + the dead carrier's disposition

ARCHITECTURE-BD-204.md is the committed design doc; it contains the FALSE/NEVER-PROVEN claims (§2).
Per `architect-doc-reality-reconciliation` + `fail-loud-delete-old-source`, the corrections owed
(named by file + symbol, never line number):

- **§2.4.1 / §2.4.2 / §2.11 / §3.1:** replace the `pack-extra-fields`-block carrier description with
  the verbatim-body-blob carrier (§3.3). The "zero-orphaned-fields" claim must be re-grounded on the
  byte-faithful blob + the unattended faithfulness check (the next registry integer), not the phantom
  block.
- **The dead code (review-2-corrected disposition):** the reverse `_tmr_emit_pack_tree`
  `e.get("extra_fields", None)` read + its `[label,value]` render loop are the abandoned PER-FIELD
  model; the v1 doc said "activate" them, but review-2 (B-1) proved the per-field model cannot carry
  prose blocks. So these are **DELETED** (fail-loud: remove the dead per-field render rather than wire
  it to a model that can't work), and the pack emit is REWRITTEN to write `raw_body` verbatim (§3.3).
  The forward composer's absent emit IS the gap; C-4.5 adds the blob emit. (This corrects the v1
  "activate the existing correct loop" premise the review found false.)
- These ARCHITECTURE-BD-204.md edits are maintenance-docs (pack-side); a pack-coder applies them
  under the review/fix cycle (NOT Pack Chat — maintenance-docs are not pack-chat-only).

### 5.e Impact on BD-206 / BD-207 (downstream; user will rewrite them after BD-204)

- BD-206 (project per-entry no-mirror) does NOT touch the migrator field set — no direct impact; the
  field-faithful carrier is inherited when BD-207 reuses the machinery.
- BD-207 (project tracker reuse) explicitly reuses the BD-204 machinery unchanged and already
  scopes the DELETION of `tracker-sidecar.sh` + `tracker-header-snapshot.sh` (BD-207 entry `:7`).
  The field-faithful carrier is prefix-agnostic (§6), so BD-207's TD entries get faithful migration
  for free. The user's planned BD-206/207 rewrite should reference the field-faithful carrier as the
  as-built contract (the POST-BD-204 REFRESH anchors in both entries already call for this).
- No new BD is needed: the fix lands inside BD-204 (launch gate, no deferral). If the user prefers a
  discrete tracking ID for the fix, the next integer is **BD-212** (highest is BD-211) — but the
  default is to keep it in BD-204 per the re-scope (§5.a).

### 5.f CREDENTIAL-CAPABILITY PREFLIGHT + the required-permission set (constraint B — a NEW external constraint class)

The live runs (C-7 rehearsals + C-8) assume specific GitHub credential permissions. The user's PAT is
deliberately scoped: it CAN create repos, write issues, and ARCHIVE repos, but has **NO repo-delete
permission** (to prevent accidental deletion of real repos). The design must assume NOTHING about the
credential — it ENUMERATES and VERIFIES the required permissions before any live action, and fails loud
on a mismatch.

**The required-permission set (stated explicitly; the design depends on exactly these):**

| Capability | Required by | gh/scope basis | Required? |
|---|---|---|---|
| Create a repo | C-7 scratch provision; (C-8 targets an existing repo) | `repo` scope / `gh repo create` | YES |
| Write issues (create/update/label/close) | forward create + Mode-3 CRUD + reverse | `repo` (issues) / `gh issue *`, `gh api` | YES |
| Archive a repo | scratch disposal end-state (§5.c) | `gh repo archive` (admin on the repo; the PAT has it) | YES |
| **Delete a repo** | NOTHING (scratch is archived, not deleted) | `delete_repo` scope — the PAT DELIBERATELY LACKS it | **NO — explicitly NOT required; tooling must never call `gh repo delete`** |
| Read issues / list (paginate) | reverse lister | `repo` (read) | YES |

**The preflight (the FIRST action of any live run — C-7 + C-8):**
1. `gh auth status` OK (existing default-SKIP guard).
2. **Enumerate + verify the required set:** confirm the token can create a repo, write issues, and
   archive — and record that delete is NOT required. The cheap check is `gh auth status` token-scopes
   (it prints "Token scopes: ...") plus a capability probe on the scratch repo (the create itself
   proves create; an `gh api -X PATCH .../issues/N` dry probe or the first real issue write proves
   issues; `gh repo archive` at teardown proves archive). FAIL LOUD on any MISSING required permission
   BEFORE doing bulk work: `credential-preflight: token missing <permission> required for <step>;
   aborting before any live write` — never start a 211-create run that will fail partway.
3. **Explicitly assert delete is NOT attempted:** the run carries no `gh repo delete` call on any path
   (the disposal is archive-only, §5.c); a grep-guard in the test asserts the test source contains no
   `gh repo delete`.

**Generalize honestly — the credential permission set is part of the EXTERNAL constraint set.** Just as
the 28 GH-Issues rules and the tracker-landscape are FIXED external constraints the design is bounded
by, the CREDENTIAL'S PERMISSION SET is a third external-constraint class (it arrived late, like the
platform rules and then the credential limit did — see the §11 COMPLETENESS VERDICT's census-gap hunt).
It is recorded as such: a future provider/credential declares its permission set; the migrator's
preflight verifies the required subset and fails loud on a gap; the design NEVER assumes a permission.
The provider abstraction gains, alongside `provider_body_limit`/`provider_body_storage_format`, the
notion that destructive teardown is **archive-or-recommend-delete, never tool-delete** — portable to
any backend whose credential model restricts deletion.

---

## §6 — GENERALIZABILITY (prefix-agnostic; BD-207 TD reuse)

> **Empirical-Evidence Block (the migrator admits BD and TD identically; the fix is prefix-agnostic).**
> `CMD`: `grep -n 'ENTRY_HEADER' scripts/lib/tracker-migrate-forward.sh` ; `grep -n "pe_entry_regex_for_stream\|PE_STREAM_KEYS" scripts/lib/per-entry/_lib.sh`
> `OUT`: `ENTRY_HEADER = re.compile(r'^\*\*((?:BD|TD)-\d{3})\s*[—-]\s*(.+?)\*\*\s*$')` (`:387`) —
> matches BD and TD; the stream registry parameterizes `pack-backlog` (`^BD-\d+\.md$`) vs
> `project-backlog` (`^TD-\d+\.md$`). `AT`: HEAD `feaa45d`, 2026-06-06. `INTERP`: the field-faithful
> carrier operates on the verbatim BODY BLOB below the header — it does not depend on the BD/TD
> prefix or on field parsing. A TD entry carrying `Target:`/`Scope:`/a prose block round-trips by the
> SAME byte-faithful rule. The §4 guard,
> when BD-207 wires the project surface, applies to the `project-backlog` stream unchanged (the check
> iterates the stream's entry files via the same regex registry). `CONCL`: SUPPORTED — the fix and
> the guard are prefix-agnostic; BD-207 reuses both with no field-logic change.

The current project TD fixtures stay within the carry set (RESEARCH §5.3), so the gap is not
triggered TODAY on the project side — but it is STRUCTURALLY identical, and the field-faithful
carrier closes it for project TD the same way. No project-side file is edited by this design (the
generalizability is a property of the shared pack-side libs; pack-project-separation honored).

---

## §7 — REGRESSION-IMPACT ANALYSIS (the basis for the downstream regression review)

For every proposed change: what could regress, and why it will not (evidence or a concrete
verification step).

| # | Change | Could regress | Why it will NOT / verification |
|---|---|---|---|
| R1 | Parser: ADD `raw_body` (verbatim lines 2..EOF) to the entry object | the 8 carried fields' parsing (labels/links/H2 sections) | the existing field extraction is UNCHANGED; `raw_body` is a NEW field captured alongside it (no re-parse of the carried path). The blob carrier is independent of field parsing, so even the existing `unblocks` shred (§1.6b) does not affect round-trip fidelity. VERIFY: `tracker-migrate-forward-test.sh` carried-field asserts stay green; add a `raw_body`-captured assert. |
| R2 | Composer: add DEFAULTED 6th `raw_body` param → `pack-entry-body-gz64` blob (gzip mtime0 + base64) | the existing H2 sections + the 3 markers; the phase call site | the blob marker is ADDED alongside the marker trio; the H2 sections are byte-unchanged (substring asserts hold — review-2 A-4). The phase call site (`:959`, 4-arg) relies on defaults; the new param MUST be `${6:-}` (review-2 A-3/G-2). VERIFY: forward-test substring asserts; a phase compose still works with no blob; a no-`raw_body` compose omits the blob marker. |
| R3 | Reverse reconstruct: read the `pack-entry-body-gz64` marker → base64-decode + gunzip → `raw_body` | the 12-key object consumers | `raw_body` is ADDED; the 12 existing keys are unchanged. The DEAD `extra_fields` read + per-field render are DELETED (not relied on). VERIFY: `tracker-migrate-reverse-test.sh` Group-1 decoder asserts unchanged; add a blob-decode assert. |
| R4 | **Reverse emit REWRITE (pack branch):** write `pe_backpointer_line` + `raw_body` verbatim, instead of the fixed-order template projection | the byte layout of EVERY reconstructed entry; the 20 no-Blockers entries; field order | this is the CENTRAL change (review-2 A-1). The verbatim emit reproduces the original body exactly — no injected `Blockers/Unblocks: None`, no `Resolved: n/a` injection, no reordering, no appended-extras. VERIFY (EMPIRICAL, not logical): the §4.2/§4.3 byte-faithful guard against all 211 entries; the worst cases (BD-204 no-Description/shred; BD-136 `-->`/fence; BD-001 no-Blockers; BD-021 multi-paragraph) verified byte-identical in §3.3/§4 EE blocks. |
| R-CLIENT | **Reverse emit: the CLIENT (`surface != "pack"`) branch** | the client monolith emit (BD-207's, still live) | the rewrite touches ONLY the `surface == "pack"` branch; `_tmr_emit_backlog` (the client `# BACKLOG` monolith path) is UNTOUCHED. VERIFY: the surface-branch split (`grep 'surface == "pack"'`); `git diff` shows no change to the client `else` branch; the client-branch tests stay green. (pack/project-separation; BD-207 owns the client emit.) |
| R-EDIT | **`tracker-edit.sh` blob+H2 sync (§3.3a / C-3 amendment)** | the Mode-3 CRUD write path | `tracker_edit_entry` must regenerate BOTH views on `provider_update`; if it updated only H2, reverse would discard the edit. VERIFY: a Mode-3 edit test asserts the blob and H2 agree after `provider_update`; the divergence-detection leg (§3.3a) FAILs on a stale blob. |
| R5 | NEW faithfulness check (the next registry integer, 49 today) | CI runtime; false positives | the check drives pure functions (no `gh`, no network) — per-entry parse/compose/emit, sub-second × 211. The byte leg has NO false-positive class: the H2/label projection is NOT compared (only the blob-emitted body is), so first-class projections are not a false-fail source. VERIFY: run the check across all 211 post-fix → green (the §4.3 worst-case empirical verification + the coder's full-tree confirmation). |
| R6 | Roundtrip + C-7 fixtures gain top-level drop-set fields + a no-Description + a no-Blockers entry | the existing fixture assertions (count, identity, status, no-sidecar) | new content is ADDED to fixture entries; count/identity/status legs unaffected (same IDs/statuses); the content-faithfulness leg now exercises the drop + the emit rewrite. VERIFY: post-fix the content leg diffs clean; pre-fix it FAILs (the fixture now has teeth). |
| R7 | `backlog/_rules.md` schema reconciliation | the per-entry contract readers | the edit states byte-faithful migration + removes the divergent optional-field list; it does NOT change which fields an entry MAY carry. VERIFY: grep-confirm no validator pins `_rules.md` field-list text (Check 34 cross-reference-integrity); trinity/`_rules.md` parity check by the coder. |
| R8 | The 211 entries | byte-untouched | the fix is carry-fields, NOT rewrite — ZERO entry edits (§3.6). VERIFY: the C-4.5/4.6/4.7 commits' `git diff --name-only` show NO `backlog/BD-*.md` (only `backlog/_rules.md` in C-4.7). |
| R9 | Project-side TD / project-example / METHODOLOGY | untouched | pack-only; the carrier is in shared pack-side libs (dependency-direction OK). METHODOLOGY.md is `supporting-docs/` (ships to clients) → NOT edited (review-2 F-2); reconcile via `backlog/_rules.md` only (pack-only-clean). The 3 project-side `_rules.md` diverge until BD-206/207 — correct-by-design (G-3). VERIFY: Check 36 `pack-only` clean on every commit; `git diff --name-only` shows no `project-template/`/`supporting-docs/`. |
| R10 | `.github/workflows/validate-pack.yml` wiring of the new per-check test (review-2 D-4/G-1) | Check 42 (no exemption) | the new per-check test MUST be wired in the SAME commit as the test file, or Check 42 goes RED. VERIFY: the C-4.6 commit adds both the test file AND its `bash scripts/tests/<file>` workflow line; run `validate-pack.py` (Check 42 green). |
| R-GZIP | **gzip layer on the blob (raw-base64 → gz64), `mtime=0`** (§3.3c / N-1) | byte-fidelity; determinism / idempotency (§3.3b) | gzip is lossless; the round-trip is base64→gunzip; `mtime=0` zeroes the only nondeterministic header field, so the same body always yields the same blob. VERIFY (EMPIRICAL): the §3.3/§3.3c EE — BD-136 + BD-204 gz64 round-trip byte-identical; two encodings of BD-136 byte-identical (mtime field `0 0 0 0`). The §4 byte guard re-confirms fidelity across all 211; the §3.3b fixed point holds because the blob is deterministic. |
| R-SIZE | **size-budget overflow check + the `provider_body_limit` enforcement** (§3.3c / N-1+N-7) | a legitimate in-budget entry FALSE-failing; an over-budget entry silently passing | the check FAILs loud ONLY when projected body > `provider_body_limit − margin`; today the worst entry (BD-136) is at 62.2% so ALL 211 pass (no false-fail). It NEVER truncates (fail-loud, not lossy). VERIFY: §3.3c EE (distribution: max 62.2% under gz64, 0 entries over 80%); a synthetic over-limit fixture FAILs the size leg (C-4.6 negative test). |
| R-PROVIDER | **NEW `provider_body_limit` capability on `tracker-provider.sh`** (§3.3c / N-7) | the existing provider op-set / the GH backend; non-GH providers | it is an ADDITIVE declared capability (like the existing label/open-closed floors); no existing op changes signature. The GH backend declares 65,536; the migrator reads the ACTIVE provider's value (no hard-coded constant in the migrator). VERIFY: `tracker-provider-test.sh` asserts GH declares 65,536 + a smaller-limit mock provider triggers the loud-fail at its own bound (tracker-agnostic). The migration machinery still calls only `provider_*` (no raw `gh`) — agnostic layer intact. |
| R-NORM | **normalization-tolerant divergence comparator** (§3.3a (ii) / N-2) | false-positives on GH body normalization; false-NEGATIVES masking real edits | the comparator normalizes EXACTLY line-endings + per-line trailing whitespace + the single trailing newline — matching GH's documented munging and the existing `tracker-mirror.sh`/roundtrip-test whitespace-tolerant precedent. It does NOT touch interior whitespace/case/Unicode/content, so a REAL human edit still mismatches (no false-negative). VERIFY: a test feeds an untouched-but-GH-normalized body (CRLF + trailing spaces) → comparator MATCHES (no false-positive); a one-word content edit → comparator MISMATCHES (caught). The blob leg needs no tolerance (base64 in an HTML comment survives GH normalization). |
| R-AUTOLINK | **inline-code-span autolink neutralization of the H2 projection** (§3.3d / R-OPS-6 / SHOULD-3) | a real human edit lost; round-trip corruption; a missed autolink form | the transform touches ONLY the visible H2 projection (advisory), NEVER the blob (the round-trip source) — so it cannot corrupt reverse (proven: the §3.3d test asserts the blob still decodes verbatim). It is form-AGNOSTIC (wraps the value), so it cannot miss `#NNN`/`@`/SHA/URL or a future form. VERIFY: a 4-form fixture entry composes with every trigger inside a code span AND its blob decodes byte-identical; the 188 trigger-free values are unchanged. |
| R-PREFLIGHT | **credential-capability preflight** (§5.f / constraint B) | a live run starting then failing partway on a missing permission | the preflight is the FIRST live action; it verifies create+issues+archive (NOT delete) and FAILs loud BEFORE any bulk write, so a permission gap aborts cleanly (no partial 211-create). VERIFY: a mock-credential test with a missing required scope aborts at preflight; the grep-guard asserts no `gh repo delete` anywhere in the test source. |
| R-DISPOSAL | **archive-not-delete scratch disposal** (§5.c / constraint B) | a writable orphan scratch repo; an accidental real-repo write | the disposal ARCHIVES the scratch (read-only) on success AND on trap-failure — never leaves a writable orphan, never deletes (the credential can't, and tooling must not). The REAL repo is never archived (§5.a Option A). VERIFY: the oracle asserts the scratch `isArchived==true` at end (replacing assert-gone); the trap archives on a forced mid-run failure; the run prints the manual-delete recommendation. |


**Critical regression watch (flagged for review-3):** R4 (emit rewrite), R-SIZE/R-PROVIDER (the
size budget + provider limit), R-NORM (the tolerant comparator), R-EDIT (`tracker-edit.sh` sync), and
R10 (workflow wiring) are the highest-risk items. R4 — the pack emit must reproduce the verbatim body;
the §4 byte guard on all 211 is the net (hazard taxonomy verified byte-identical, §3.3/§4 EE).
R-SIZE/R-PROVIDER — the gz64 blob brings the worst case from 99.7% to 62.2% of the GH limit (§3.3c
EE); the loud-fail overflow contract (never truncate) + the `provider_body_limit` capability make
size a CI-enforced, tracker-agnostic bound, not a latent failure. R-NORM — the comparator normalizes
exactly GH's munging (line-endings + trailing whitespace) so it neither false-positives an untouched
issue nor false-negatives a real edit. R-EDIT — without the blob+H2 sync a tracker-side edit silently
desyncs; §3.3a defines the producer-side sync + the tolerant divergence backstop. R10 — Check 42 has
no exemption, so the workflow wiring is mandatory in C-4.6. R9 stays correctly handled: reconcile via
`backlog/_rules.md` only; METHODOLOGY.md (`supporting-docs/`, ships to clients) is NOT edited (F-2).

---

## §8 — Empirical-Evidence summary (every state-claim is backed above)

All state-claims in §1-§7 carry an inline Empirical-Evidence Block at the point of claim (CMD +
verbatim OUT + HEAD `feaa45d` + INTERP + CONCL; v1 blocks 2026-06-06, review-2 re-measurements
2026-06-07). The load-bearing measurements: the 9-key whitelist (§1.1), the 5-arg composer (§1.2),
the dead carrier from both ends (§1.3), the 28-label census (§1.4), the no-recovery challenge (§1.5),
the worst case (§1.6), the 73-item unblocks-shred CORRUPTION (§1.6b), the schema contradiction
(§1.7), the base64 blob byte-faithful round-trip on the hazard taxonomy (§3.3/§4), the 20 no-Blockers
entries that force the emit rewrite (§4.2), the delimiter-collision set (4 `-->` + 1 fence, §4.2),
the 53 multi-paragraph entries (§4.2), the taken check-number (§4.2), Check 42's no-exemption wiring
obligation (§4.5), the no-existing-check (§4.5), the prefix-agnostic generalization (§6), and
(fix-2) the SIZE distribution across all 211 (raw-base64 worst 99.7% → gz64 worst 62.2%, §3.3c EE),
the gzip determinism (`mtime=0`, §3.3c EE), and the GH body-limit bound (65,536) generalized to the
provider-layer `provider_body_limit` contract (§3.3c). Each is SUPPORTED or PARTIAL-with-reason; none
NOT-SUPPORTED remains as a design dependency.

---

## §11 — COMPLETENESS VERDICT (read end-to-end as ONE artifact, against ALL fixed constraints)

I re-read the entire amended design as one artifact against ALL fixed constraints: the 28-rule
GH-Issues set, the 14-tracker landscape, every settled user decision (no carve-outs; 0 entry content
rewrites; Option A — real repo never archived; repeatable multi-rehearsal; archive-not-delete;
fail-loud everywhere), and the credential permission contract (§5.f). Below: the verdict, the
known-unknown → rehearsal-leg map (a known-unknown without a confirming leg is a finding), and an
active census-gap hunt for any constraint class not yet enumerated.

### 11.1 VERDICT: COHESIVE-AND-COMPLETE for the as-designed v11.0 scope, CONDITIONAL on (a) ONLY — the
irreducible live-rehearsal gate: the C-7 rehearsal confirming the platform-behavior known-unknowns
BEFORE C-8. **Gate (b) (the 2 census gaps) is now CLOSED** — R-OPS-7 + R-ACCT-5 (GATE-(B) close-out,
VERIFY-2 = VERIFIED) MEASURED both: no repo-creation-specific limit (the §3.3d issue-pacing gate bounds
the cadence) and unlimited personal repos below a 100,000 cap with issues DB-stored (archived
accumulation benign). No researcher pass remains.

The CONTENT design is cohesive and complete: every hard rule is CLEAN across 211 (0 rewrites); the
carrier is byte-faithful + collision-proof + size-bounded + decode-identity-pinned + corrupt-blob
fail-loud; the operational rules (pacing, autolink neutralization) are designed + tested; the
portability boundary is honest (raw-text class); the credential contract is preflighted + archive-only.
The SOLE remaining condition is the irreducible DOCUMENTED-SILENT platform behaviors that ONLY a live
repo can confirm — the gate-(a) C-7 rehearsal contract (§11.2). The two census gaps the late-settled
multi-scratch + no-delete decisions exposed are now MEASURED and closed, not assumed away — per the
user's own lesson that two constraint classes already arrived late, this pass researched them to
ground rather than carry them.

### 11.2 KNOWN-UNKNOWN → C-7 REHEARSAL-LEG MAP (each must be confirmed BEFORE C-8)

Every remaining known-unknown (the DOCUMENTED-SILENT register + the credential/operational live
behaviors) is mapped to the EXACT C-7 rehearsal leg that empirically confirms it. A known-unknown with
NO leg = a completeness finding; there are none unmapped.

| # | Known-unknown | Source | C-7 rehearsal leg that confirms it BEFORE C-8 |
|---|---|---|---|
| DS-1 | Issue-body STORAGE is byte-verbatim (HTML comment + blob preserved; no autolink/mention STORED rewrite) | R-BODY-4 | **Content-faithfulness leg:** create the 4-form + drop-set + no-Description fixtures on the live scratch repo, read the stored body back, base64-decode+gunzip the `pack-entry-body-gz64` blob → assert byte-identical to the original. Confirms no stored rewrite. |
| DS-2 | Issue-body web-edit normalization (CRLF→LF / trailing-ws) | R-BODY-5 | **Normalization-comparator leg:** after the create, edit the visible body via the API/web on the scratch repo, re-read, run the §3.3a normalization-tolerant comparator → assert it does NOT false-positive an untouched-but-GH-normalized body AND DOES catch a real edit. Confirms the comparator's normalization set matches GH's actual munging. |
| DS-3 | The 65,536 ENFORCEMENT AXIS (stored codepoints vs bytes vs gzipped-request) | R-BODY-7 | **Size leg + the near-budget fixture:** create an entry near `provider_body_limit−margin` on the scratch repo → it succeeds; push one over → GH 422. Confirms which axis binds in practice (the stored-byte budget at 62.1% clears all three regardless — this leg verifies the margin empirically). |
| DS-4 | Accepted control-char set in bodies | R-BODY-6 | MOOT for current data (0 entries); the go-forward guard (§3.3e) blocks a future control byte at CI BEFORE a create — no live leg needed unless a future entry introduces one (then a one-off probe). |
| DS-5 | Title newline handling | R-TITLE-2 | MOOT (title is single-line by grammar); no leg needed. |
| KU-OPS-2/3 | Pacing actually avoids the secondary cap + abuse-flag on a real burst | R-OPS-2/3 + NUANCE-A | **Live paced-create leg:** run the paced forward create against the scratch repo at ≥1s spacing → assert no 403/429 and no abuse-flag; this is exactly the C-8 rehearsal at scale. |
| KU-OPS-6 | The inline-code-span neutralization actually suppresses ALL 4 autolink forms on GH render | R-OPS-6 | **Autolink-neutralization leg:** create the 4-form fixture on the scratch repo → assert the rendered body shows NO live `#NNN`/`@`/SHA/URL link (and the blob still decodes verbatim). Confirms GH renders nothing inside the code span. |
| KU-CRED | The credential can create+issues+archive but NOT delete; the preflight + archive-disposal behave | constraint B / §5.f | **Credential-preflight leg + disposal leg:** the preflight verifies the permission set before any write; the disposal archives the scratch (assert `isArchived==true`) and recommends manual delete. The very fact a rehearsal runs end-to-end confirms the permission set on the real credential. |

**No known-unknown is unmapped.** DS-4/DS-5 are MOOT (guarded/structural); all others have a concrete
leg in the rebuilt C-7 oracle (§5.c), which is the gate before C-8.

### 11.3 ACTIVE CENSUS-GAP HUNT (what OTHER constraint class could surface?)

Two constraint classes already arrived late (the 28 platform rules, then the credential permissions).
I hunted for more. Each is either ABSORBED with evidence or named as a CENSUS GAP needing a researcher
— none is silently assumed away.

| Candidate class | Status | Evidence / disposition |
|---|---|---|
| **Repo-CREATION rate limit** (distinct from the issue-create secondary limit) | **RESOLVED-BY-MEASUREMENT (R-OPS-7; VERIFY-2 = VERIFIED)** | The GAP-1 researcher pass (R-OPS-7) returned a VERIFIED NEGATIVE: GitHub has NO repo-creation-specific rate limit; a repo create is an ordinary content-generating request riding the GENERAL secondary caps (R-OPS-2/3). So the binding multi-rehearsal constraint is each rehearsal's 211 ISSUE creates — which the §3.3d pacing gate (≥1s/create + retry-after) ALREADY bounds; the single repo-create per rehearsal (1 mutation ≪ 500/hr) needs no separate gate. **No new gate needed; §3.3d already honors it.** |
| **Account / private-repo quota** | **RESOLVED-BY-MEASUREMENT (R-ACCT-5; VERIFY-2 = VERIFIED)** | The GAP-2 researcher pass (R-ACCT-5) found: a personal account owns UNLIMITED public + private repos below a 100,000 hard cap (50,000 banner); accumulated archived scratch repos stay orders of magnitude under it. The 10 GB on-disk figure is a RECOMMENDATION for `.git`; issues are DB-stored, NOT in `.git`, so 211 issues per scratch consume ~0 of both axes. (Conservative framing per VERIFY-2: docs are SILENT on an archived-repo quota EXEMPTION rather than affirmatively excluding archived repos — so I read them as COUNTING toward the cap; even so a campaign is negligible vs 100,000.) **Accumulation is benign; the §11.3 mitigations (public scratch / prompted manual delete) are optional housekeeping, not a quota necessity; §5.c archive-not-delete already honors it.** |
| **`gh` CLI version behavior** | **ABSORBED (mitigation stated) + minor gap** | The design assumes `gh repo create/archive`, `gh repo view --json isArchived`, `--jq`, `gh issue` — all GA in modern `gh`, but version-dependent. No version pin exists (verified: no `gh --version` check). **Disposition: §5.f preflight should ALSO assert a minimum `gh` version (a one-line `gh --version` check); the JSON/`--jq` surface is stable in `gh` ≥ 2.0. Low risk; folded into the preflight as a cheap add — flagged here so the coder includes it.** |
| **CI-environment difference** (gz64 codec on the runner vs local) | **ABSORBED — no gap** | The codec is pinned to `python3` (§3.3, S-5#6), and CI uses `actions/setup-python@v5` python 3.12 on `ubuntu-latest` (verified `.github/workflows/validate-pack.yml:91-93`). `gzip.GzipFile(mtime=0)` is python-stdlib (platform-independent), and the invariant is DECODE-IDENTITY (§3.3b) — even a different gzip impl decodes identically. So the unattended guard's gz64 round-trip is environment-independent. No gap. |
| **Token rate-limit TIER** (PAT primary 5,000/hr vs lower tiers) | **ABSORBED — no gap** | R-OPS-1 (5,000/hr primary, personal PAT) covers it; 211 issue creates + a few repo ops ≪ 5,000/hr; the binding limit is the SECONDARY cap (R-OPS-2), already paced. No new gap. |
| **Issue-DEPENDENCY / sub-issue caps** (Blockers→links) | **ABSORBED — no gap** | The carrier rides the body blob; Blockers/Unblocks project to first-class links, but the lossless round-trip does NOT depend on the link projection (the blob carries the verbatim `Blockers:`/`Unblocks:` lines). A link-cap failure degrades the projection, not the round-trip. Noted, not a completeness gap. |
| **GH Issue Forms / template caps** | **ABSORBED — no gap** | R-ACCT-1 (forms GA personal) + the form family is already in use; no per-form cap is approached. |

**Net census-gap finding: 2 gaps RESEARCHED + RESOLVED-BY-MEASUREMENT** (repo-creation rate limit →
R-OPS-7 verified-negative, the §3.3d issue-pacing gate already bounds the cadence; account/private-repo
quota → R-ACCT-5 unlimited-below-100,000 + issues DB-stored, archived accumulation benign) +
**1 minor absorbed-with-flag** (gh version pin → fold into the §5.f preflight). The 2 gaps were NEWLY
relevant because of the late-settled multi-scratch + no-delete decisions; the GATE-(B) close-out pass
(R-OPS-7 + R-ACCT-5, both VERIFY-2 = VERIFIED) MEASURED both and closed them. **They do not block the
DESIGN and — now measured — impose NO new gate on the multi-rehearsal cadence: §3.3d (issue pacing)
and §5.c (archive-not-delete) already honor the measured answers. No researcher pass remains.**

### 11.4 What "complete" rests on (evidence, not attestation)

- 0 entry content rewrites — every hard rule CLEAN across 211 (§S-4 EE, re-measured).
- gzipped-request axis corrected to 31.0% (re-measured this pass; stored 62.1% binds — §3.3c EE).
- every named symbol verified to EXIST (`tracker_edit_entry` etc. — grep, not memory).
- autolink surface censused to 4 forms (21 `#NNN` + 2 `@` + 97 SHA-outside-code + 2 URL) and covered by
  ONE pinned form-agnostic transform.
- credential contract preflighted; disposal archive-only; real repo never archived.
- 7 known-unknowns mapped to confirming C-7 legs; 2 MOOT.
- 2 census gaps RESEARCHED + RESOLVED-BY-MEASUREMENT (R-OPS-7 verified-negative; R-ACCT-5 unlimited-below-cap); 5 other candidate classes absorbed with evidence; gate (b) CLOSED.

**The verdict is COHESIVE-AND-COMPLETE for design, with the SOLE remaining condition the irreducible
gate-(a) C-7 live-rehearsal confirmation of the DOCUMENTED-SILENT platform behaviors before C-8; gate
(b) (the 2 census gaps) is CLOSED by measurement (R-OPS-7 + R-ACCT-5, VERIFY-2 = VERIFIED) — surfaced
and resolved, not silently closed.**

---

## §9 — RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (actual command / quote / measurement) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` or any state-changing verb issued; `git rev-parse HEAD` (read-only) is the only git call; the sole write is this ONE design doc. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op; no live GH (the C-7 oracle was READ, never executed — no `PACK_TRACKER_LIVE_GH`, no `gh repo create`); no `rm`/overwrite of a trusted file. | COMPLIANT |
| `adversarial-architect-review-on-major-gap` | Treated the census + ARCHITECTURE-BD-204 as UNTRUSTED; re-measured every load-bearing claim independently (§1.1-§1.7); challenged the "dropped" verdict (§1.5 found one PARTIAL nuance) and the "carry-set==template" claim (§1.7 found the `_rules.md` `Position:` contradiction the census missed); re-scoped the BD-204 entry FIRST (§5.a); design stays UNCOMMITTED. User constraints (5) treated as FIXED; none unrealizable (surfaced none). | COMPLIANT |
| `ci-guard-measure-then-bound` | MEASURED first: the field set (§1.4: 28 labels, all 211); the DELIMITER-collision set (§4.2: 4 `-->` + 1 fence); the multi-paragraph set (53); the no-Blockers set (20); AND (fix-2 N-1) the SIZE distribution across ALL 211 against the 65,536 limit (§3.3c EE: raw-base64 worst 99.7% → gz64 worst 62.2%; 0 entries over 80% under gz64). Categorized every body byte CARRY (no drop-allowlist). Sized the guard to byte-equality AND the size budget. **Post-fix verification EMPIRICAL (D-3)**: gz64 round-trips the hazard taxonomy byte-identical (§3.3/§4 EE); the emit reproduces the 20 no-Blockers entries without injected lines (§4.2 EE); the size bound is measured (not assumed) and the overflow contract fails loud (never truncates). FAILs against the current lossy code (§4.2 EE). | COMPLIANT |
| `empirical-evidence-blocks` | Every state-claim carries CMD + verbatim OUT + HEAD `feaa45d` + INTERP + CONCL. v1 blocks dated 2026-06-06; review-2 re-measurements (§1.6b shred=73, §3.3 base64 round-trip, §4.2 20-entry + delimiter + multi-paragraph, §4.2 check-number) dated 2026-06-07. | COMPLIANT |
| `architect-doc-reality-reconciliation` | §5.d names the corrections owed to ARCHITECTURE-BD-204.md by file + SYMBOL (§2.4.1/§2.4.2/§2.11/§3.1; `_tmr_emit_pack_tree` per-field render DELETED + pack-branch emit REWRITTEN; `tmf_compose_issue_body` blob emit added; `tracker-edit.sh` blob+H2 sync) — never line numbers. | COMPLIANT |
| `enumerate-encoding-surfaces` | §4.5 enumerates, in lock-step, the migrator libs + the new validator check (next registry integer) + `.github/workflows/validate-pack.yml` (review-2 G-1) + the phase call site `:959` (G-2) + every test (forward/reverse/roundtrip/per-check) + every fixture + `tracker-edit.sh` (B-3) + manifest + `backlog/_rules.md` + the G-3 pack/project-divergence note. | COMPLIANT |
| `pattern-matching-out-of-context` | The carrier is justified on PROPERTY-FIT (a migration is a faithful transport; the `pack-entry-body-gz64` blob generalizes the EXISTING `pack-id`/`template_version` body-marker idiom — same HTML-comment-marker property, §3.3). The per-field `[label,value]` model is REJECTED on evidence (review-2 B-1: it cannot carry prose blocks); the prior split-carrier is REJECTED as a carve-out generator; rewrite-entries rejected on property-fit (§3.2 EE). | COMPLIANT |
| `preliminary-triage-architect-challenge` | All categorizations are challengeable; tiered the bar — LOW for internal mechanism (carrier shape), HIGH where the design meets landed C-1..C-6 (§2 audit re-verifies each claim in code) and project reuse (§6 re-measures the prefix-agnostic claim). | COMPLIANT |
| `fail-loud-delete-old-source` | The dead per-field carrier (`extra_fields` read + `[label,value]` render) is surfaced for DELETION (review-2 B-1 proved it cannot work — fail-loud: delete, do not wire a broken model), replaced by the verbatim-blob emit (§5.d); the FALSE design claims are surfaced for correction (§2, §5.d); the human-GH-edit divergence is DETECTED + surfaced, never silently resolved (§3.3a). No silent contradiction left. | COMPLIANT |
| `deferral-is-scope-creep` / `no-deferral-without-user-direction` | The fix lands in v11.0 (§5.a/§5.b); BD-204 is a launch gate; no deferral recommended; the only "defer" instinct (a separate BD-212) is surfaced as a non-default option, not a recommendation. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly the 7 deliverables (§1-§7) + the required EE blocks + this block + the attestation; no extra design surface. | COMPLIANT |
| `pack-project-separation` | Pack-only; no `project-template/` edit; the TD generalizability (§6) is a design PROPERTY of shared pack-side libs, not a project-file edit; R9 flags the METHODOLOGY/`supporting-docs` boundary explicitly. | COMPLIANT |
| `review-2-fix-all` (revision mandate) | All 7 review findings FIXED: A-1/D-1/D-3 (emit rewrite + empirical post-fix verification, §3.3/§4.2-4.3); B-1/C-1 (committed to the verbatim-body blob; §1.6b records the shred-corruption); D-5 (Check number → next registry integer, all hardcoded "48" removed); B-2 (delimiter measured + base64 collision-proof carrier, §3.3/§4.2 EE); B-3 (H2-vs-blob precedence + `tracker-edit.sh` sync + human-edit divergence detection, §3.3a); C-2 (53 multi-paragraph entries verified empirically, §4.2 EE); D-4/G-1 (workflow yml added to §4.5 + C-4.6 + §7 R10). §7 updated (R4 emit, R-CLIENT, R-EDIT rows); B-4 idempotency (§3.3b); B-5 captured-span (§3.3); A-3/G-2 phase param; G-3 pack/project-divergence note. | COMPLIANT |
| `tracker-portability` (BD-060) | The carrier contract lives at the TrackerProvider ABSTRACTION: `provider_body_limit` (bytes) + `provider_body_storage_format` (`raw_text`/`rich_text_normalizing`) + the pacing capabilities (`provider_min_write_interval_s`/`provider_writes_per_hour_max`). The blob is the RAW-TEXT-BODY-CLASS carrier (sweep S-5#7 / the landscape census: GitLab/Redmine/Shortcut FIT, Jira Cloud MISFITS — 32,767 cap + ADF); the migrator FAILs loud on a too-small-body OR rich-text-normalizing backend (never truncates/corrupts). No raw `gh`; no GitHub-sized over-claim survives — same provider contract, class-appropriate carriers (§3.3c). | COMPLIANT |
| `review-3-fix-2` (this revision) | The 3 review-2 findings CLOSED: N-1 (size budget — §3.3c gz64 carrier brings worst case 99.7%→62.2%, distribution measured across all 211, loud-fail overflow contract, §4.4 guard size leg); N-2 (normalization-tolerant divergence comparator — §3.3a (ii), line-ending + trailing-whitespace, matched to GH munging + the existing whitespace-tolerant precedent, no false-pos/false-neg); N-7 (provider-layer `provider_body_limit` contract — §3.3c, folded into the ONE size-budget section per review-2). §4/§4.5/§5.b/§7 updated; gzip determinism verified; P1-NIT-1 (§5.a "parses it back") + P1-NIT-2 (`--force` citation) fixed. | COMPLIANT |
| `external-rules-census-before-design` (FULL-SWEEP) | The 28-rule GH-Issues census + the 14-tracker landscape are FIXED constraints; every design section re-validated against them (sweep S-1). All hard CONTENT limits are CLEAN across 211 (re-measured this sweep: title max 231/256; body worst 62.1%; 0 control bytes; longest label 25 (template:phase-epic-v11.0)/≤6). The OPERATIONAL gaps the census surfaced are now DESIGNED, not silently relaxed: pacing (§3.3d / S-5#1), mention-neutralization (§3.3d / S-5#2), enforcement-axis named (§3.3c / S-5#4), go-forward title/control guards (§3.3e / S-5#5), python3-codec pin + corrupt-blob fail-loud + composed-body size (§3.3/§3.3b/§4.4 / S-5#6), storage-format portability capability (§3.3c / S-5#7), C-7 rebuild verdict (§5.c / S-8). The archive ambiguity (S-5#3) is SURFACED as a user decision, not guessed. | COMPLIANT |
| `full-sweep` (this revision) | S-1 design re-validated + amended in place; S-2 committed-doc corrections specified (not edited); S-3 script changes specified by file+symbol; S-4 entry-modification list = the 1 BD-204.md:20 wording disambiguation (a re-scope text item, Pack-Chat pack-chat-only), ALL 211 content-clean (no rewrites); S-5 all 8 named items decided/surfaced; S-6 re-sequenced commits. The full ledger is `SWEEP-BD-204-RULES-COMPLIANCE.md`. | COMPLIANT |
| `gate-(b)-close-out` (this revision) | The 2 §11.3 census gaps RESEARCHED + RESOLVED-BY-MEASUREMENT (read both deltas + VERIFY-2 = VERIFIED): R-OPS-7 (no repo-creation-specific limit → §3.3d issue-pacing gate bounds the multi-rehearsal cadence; verified-negative) + R-ACCT-5 (personal repos unlimited below 100,000, issues DB-stored → archived accumulation benign; conservative archived-counts-toward-cap framing adopted). §11.1/§11.3/§11.4 flipped to RESOLVED; the §11 verdict flipped to CONDITIONAL on gate (a) ONLY; §5.c cadence note reconciled to the measured-benign answer. No new gate; no re-design. | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence, no AMBIGUOUS. | COMPLIANT |
| `filename-uniqueness-heuristic` | `find . -name "ARCHITECTURE-BD-204-LOSSLESS-FIX.md" -not -path "./.git/*"` returned empty before write (Bash call, this session). | COMPLIANT |

## §10 — READ-IN-FULL attestation (per-file direct-read proof, this session, at HEAD `feaa45d`)

| Document | Direct-read proof |
|---|---|
| `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md` | Read full (1-436). The factual basis; every key number re-measured independently (§1). |
| `ARCHITECTURE-BD-204.md` | Read full (1-588 page 1, 589-1044 page 2). The §2.4/§2.11/§3 carrier claims audited (§2). |
| `ARCHITECTURE-BD-204-POST-BD211-RECON.md` | Read full (1-344). The suffix-free reconciliation + the C-7 model decisions. |
| `PLAN-BD-204.md` | Read full (1-544 page 1, 545-689 via the C-4/C-7/C-8 spans). The §C-4 phantom-carrier inheritance flagged (§2.G). |
| `backlog/BD-204.md` | Read full (1-27). Re-scoped (§5.a). |
| `backlog/BD-206.md` / `backlog/BD-207.md` | Read full (206: 1-15; 207: 1-16). Downstream impact (§5.e); BD-207's sidecar/header-snapshot deletion scope noted. |
| `backlog/_rules.md` | Read full (1-84). The `Position:` contradiction found (§1.7). |
| `scripts/lib/tracker-migrate-forward.sh` | Read directly — parser `_tmf_parse_backlog_file` (375-496), composer `tmf_compose_issue_body` (595-630), call sites (901, 959), `_tmf_labels_for_entry` (1501-1529 via grep). |
| `scripts/lib/tracker-migrate-reverse.sh` | Read directly — `_tmr_extract_section` (323-345), reconstruct (506-599), `_tmr_emit_pack_tree` dead carrier (700-790 region), decode-scope/severity (290-320). |
| `scripts/validate-pack.py` | Read via grep — all 45 `def check_` names, `_CANON_HEADER_RE`/`_stream_is_id_shaped` (3194-3323), no field-faithfulness check (§4.5 EE). |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | Read full (1-329). The default-SKIP + fixture-can't-catch-the-drop analysis (§2.E/§2.F, §5.c). |
| `scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md` | Read full. Confirmed BD-901/902/903 carry only carry-set top-level fields; BD-903 sub-blocks inside Description (§2.E). |
| `.github/ISSUE_TEMPLATE/work-item.yml` | Read via the prior census + the marker-trio reference (`:103-105`) — the form family field set (no Scope/Target field). |
| `supporting-docs/METHODOLOGY.md` Part 7 | Read directly (1190-1233). The canonical template field set (§1.7 / R9). |
| `CLAUDE.md ## Pack memory` | Provided in full in session context; the in-force rules (boundary, dependency-direction, enumerate-encoding-surfaces, ci-guard-measure-then-bound, pack-project-separation, etc.) applied. |
| `DESIGN-REVIEW-BD-204-LOSSLESS-FIX.md` (review-1) | Read FULL (1-245) — findings A-1..G-3; A-1 (20 no-Blockers) + B-1 (73-item shred) RE-VERIFIED against live code in fix-1 (§1.6b, §4.2 EE). |
| `DESIGN-REVIEW-BD-204-LOSSLESS-FIX-R2.md` (review-2 input — THIS fix-2) | Read FULL (1-154) this session — N-1 (size, BD-136 60,912/93%), N-2 (divergence false-positive), N-7 (provider limit), plus the Part-1 resolution verification + Part-2 PASS findings. N-1/N-2/N-7 independently RE-MEASURED before revising (§3.3c distribution EE; gzip determinism EE). |
| `scripts/lib/tracker-edit.sh` (B-3 + N-2) | The Mode-3 CRUD writer that must keep blob + H2 in sync AND use the normalization-tolerant comparator (§3.3a); a lock-step surface (§4.5). |
| `scripts/lib/tracker-provider.sh` / `tracker-provider-gh.sh` (N-7) | The TrackerProvider abstraction that gains the `provider_body_limit` declared capability (§3.3c); the GH backend declares 65,536; a lock-step surface (§4.5). |
| `.github/workflows/validate-pack.yml` + Check 42 (D-4/G-1) | `check_ci_workflow_wires_per_check_tests` confirmed (no exemption); the workflow in the lock-step set (§4.5, §7 R10). |
| GitHub body-field behavior (size + normalization) | GH Issue-body hard limit 65,536 bytes (documented platform constant; used as the N-1/`provider_body_limit` GH value — not network-verified per the read-only mandate). GH web-edit body normalization (CRLF→LF, trailing-whitespace strip) is the documented munging the N-2 comparator is sized to; cross-checked against the codebase's own whitespace-tolerant precedent (`tracker-mirror.sh` `:67`/`:101`, roundtrip-test `:9`). |
| `RESEARCH-BD-204-GH-ISSUES-RULES.md` (FULL-SWEEP law) | Read FULL (1-535 page 1, 536-758 page 2) this session — all 28 rules / 8 categories + the §2 entry census + the §3 compliance map. The fixed constraint set for S-1..S-6; testable rules (R-OPS-2/3/6, R-BODY-6/7, R-TITLE-1) re-measured this sweep. |
| `RESEARCH-TRACKER-LANDSCAPE-RULES.md` (FULL-SWEEP law) | Read FULL (1-406) this session — 14 trackers, carrier-fit verdicts (3 FITS / 5 FITS-WITH-ADAPTATION / 6 MISFIT). Grounds the §3.3c `provider_body_storage_format` capability + the honest portability boundary (S-5#7). |
| `RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md` (audit trail) | Read (1-60 + verdict) — confirms the rules doc's values + census numbers; CORRECTIONS-NEEDED resolved by the fold-in (3 missed rules + 2 nuances already in the 28-rule set). |
| `RESEARCH-BD-204-GH-ISSUES-RULES.md` (GATE-(B) deltas: R-OPS-7 + R-ACCT-5) | Read the two new rule rows + §3 map rows + the §0/§8 second-fold-in ledger this session — R-OPS-7 (repo-creation: no repo-specific limit; rides the general secondary caps) + R-ACCT-5 (personal repos unlimited < 100,000; 10 GB on-disk `.git` recommendation; issues DB-stored). Grounds the §11.3 RESOLVED-BY-MEASUREMENT flips. |
| `RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY-2.md` (GATE-(B) verification) | Read the verdict = VERIFIED + the archived-quota framing NIT (docs SILENT on an archived-repo exemption → conservative "archived counts toward the cap" reading adopted in §11.3). |
| Curated memory files (11 named in the prompt) | Carried as governing rules: adversarial-architect-on-major-gap, ci-guard-measure-then-bound, architect-planner-empirical-evidence, fail-loud-delete-old-source, preliminary-triage-architect-challenge, pattern-matching-out-of-context, pack-project-separation, scope-deliverables-to-the-ask, agent-output-rules-applied-block, verify-full-ci-suite, researcher-maps-blast-radius, external-rules-census-before-design, tracker-portability — reflected in §9. |

**No named document was derived rather than read.** Every doc, code file, fixture, and contract
above was opened directly via Read/Bash; v1 measurements at HEAD `feaa45d` (2026-06-06); fix-1 and
fix-2 + full-sweep re-measurements at the SAME HEAD `feaa45d` (2026-06-07). The full-sweep measurements
— the R-OPS-6 token census (21 `#NNN` + 2 bare-`@`), the R-TITLE-1 headroom (BD-208 231/256), the
R-BODY-6 control-char scan (0 entries), the gzipped-request axis (BD-136 20,321 / 31.0% gzipped-request vs 40,695 / 62.1% stored — corrected from a wrong ~134/0.2%), the 4-form autolink census (21 `#NNN` + 2 `@` + 97 SHA-outside-code + 2 URL), the `tracker_edit_entry` symbol verification, the label-max 25,
and the C-7 operational-coverage grep (none today) — are this session's own command output. The fix-2
measurements — the SIZE
distribution across all 211 (raw-base64 worst BD-136 65,336/99.7% → gz64 40,771/62.2%; 0 entries
over 80% under gz64), the gzip+base64 byte-faithful round-trip on BD-136/BD-204, and the gzip
determinism (mtime field `0 0 0 0`, two encodings identical) — are this session's own command output
at HEAD `feaa45d`.

**End of ARCHITECTURE-BD-204-LOSSLESS-FIX.md**
