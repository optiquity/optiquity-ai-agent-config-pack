# DESIGN — BD-243 DURABLE-ENFORCEMENT GATES (the four gates that stop the cleanup rotting)

Architect: FRESH architect instance (pack-architect, RO). I did NOT author `DESIGN-BD-243-FINAL.md`, `DESIGN-BD-243-FINAL-V2.md`, `DESIGN-BD-243-BLOAT-METHOD.md`, the `CENSUS-DEFERRED-FEATURE-MENTIONS.md`, `PLAN-BD-243-BLOAT-PHASE-V2.md`, or any prior BD-243 artifact; conclusions are my own (reconciliation-instance-independence). I re-measured the tree independently and reached my own gate designs.
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`, canonical HEAD **`103cca8`** (verified at runtime: `git rev-parse HEAD` = `103cca8e51feef9c80e4e76be17bd0dd274d3a6b`), clean working tree (untracked plan docs only), 2026-06-22. READ-ONLY; no edits, no patch, no state-changing git.
Status: ARCHITECT-READY — goes to the user, then the planner sequences the gate implementations into the bloat-phase commit structure. I define the gate designs + the dependency-correct insertion recommendation; I do NOT re-sequence the bloat commits.

This design closes the enforcement gap the user identified: BD-243's strip phase installed the `operating-docs-no-history-no-bloat` RULE and ONE hard gate (Check 65, HISTORY axis only, over a FROZEN frozen doc set), but the BLOAT axis, the DEFERRED-FEATURE axis, the DANGLING-REFERENCE axis, and NEW-DOC auto-coverage are all unguarded. The user's ruling: **design durable-enforcement gates so the cleanup cannot silently rot.** Four gates follow.

---

## 0. EXECUTIVE ANSWER (decision-ready)

| Gate | Identity | Catches | FAIL/WARN | Scope model | Allowlist (measured KEEP) | Runtime cost |
|---|---|---|---|---|---|---|
| **Gate 1 — BLOAT** | Check 44 HARDENED (per-doc ceiling → FAIL on a small fixed M4 set) + NEW **Check 66** (per-rule/per-bullet char-cap, FAIL) | mega-bullets (B1) + doc-length regression | **FAIL** both, parameterized AFTER bloat-reduction | Gate-1a: the existing frozen 6-doc `_CHECK_44_DURABLE_DOCS`; Gate-1b: auto-discovered trinity + RATIONALE bullets (the B1 surface) | char-cap allowlist sized to the post-reduction load-bearing maxima (derive AFTER CB-06/CB-02 land) | cheap — reads the same ≤9 docs Check 44 already reads + the 4 trinity/RATIONALE files; no whole-tree scan |
| **Gate 2 — DEFERRED-FEATURE** | NEW **Check 67** (recall gate) | un-stripped "feature X is deferred/coming/future" mentions | **FAIL with allowlist** (modeled on Check 65) | auto-discovered operating-doc IN set (family glob minus EXEMPT) | sized to the CENSUS §5 KEEP set (rule self-reference + generic client-product advice + operative current-state caveats + the live TD-deferral feature) — measured below | cheap — one compiled-alternation scan per IN line; reuses Check 65's read |
| **Gate 3 — DANGLING-REFERENCE** | NEW **Check 68** (referential-integrity gate, generalizes Check 64's pattern) | a backtick/hyperlink/qualified-path file ref whose target does not exist | **FAIL with allowlist** | the operating-doc IN set + the Check-64 deliverable surface | sized to the measured intentional-placeholder set (grammar examples, archived/retired self-flagged refs, runtime-generated outputs, `x-`/`vN` framework patterns) | cheap — reuses Check 40/43's bare-ref + hyperlink regex + a basename-existence index built once |
| **Gate 4 — NEW-DOC AUTO-COVERAGE** | a **meta-check** folded into Check 59-style bookkeeping (the scope-completeness assertion), applied to Checks 65/67/68 | a NEW operating doc in a scanned family silently escaping the gate | **FAIL** | meta: globs the families, asserts every family member is in (scope-constant ∪ EXEMPT-constant) | the explicit EXEMPT constant (the `_intro`/`_toc`/HELP-FRAGMENT/reference set) | cheap — one directory glob per family, set arithmetic, no content scan |

**Central recommendation on the scope model (Gate 4's question, applied to Gates 1-3):** use **auto-discovery for the SCAN (recall) with a frozen EXEMPT constant + a meta-check completeness assertion**, NOT a frozen IN constant. Rationale and the determinism trade-off are in §5. The frozen-IN constant `_CHECK_65_OPERATING_DOCS` is the current design's silent-rot hole; a frozen EXEMPT list (small, rarely-changing, auditable) plus glob-the-rest gives both coverage AND auditability.

**R2 incident tightening (user-decided, folded):** `("incident", re.compile(r"incident"))` → `("incident", re.compile(r"\bincident\b"))` in `_CHECK_65_FORBIDDEN_PATTERNS`. Measured: the substring form matches "coincidental" + "incidents" (2 false-positives); the whole-word form drops both and retains the 7 genuine whole-word hits (6 rule-self-reference + 1 KEEP). Detail §6.

**Insertion (the planner sequences; I propose the dependency-correct order):** Gates 2, 3, 4 + the R2 tightening land at **CG-14-prep / CG-14** (they are calibration-of-the-final-tree work, identical in nature to the plan's existing CG-14-prep). Gate 1's PARAMETERS (the char-cap + the FAIL ceilings) MUST be derived AFTER the bloat reduction lands (CB-01..CB-09) — so Gate 1's check BODY can be authored anytime but its CONSTANTS are filled at CG-14-prep from the measured reduced tree. Full rationale §7.

---

## 1. RUNTIME STATE BASELINE (measured @ `103cca8`)

The strip phase (CG-01..CG-13) is landed, pushed, CI-green. The enforcement surface today:
- `CHECK_REGISTRY_EXPECTED_COUNT = 63` (validate-pack.py:496); registry holds 63 entries (Check 59 asserts `len == 63`). Next free check NUMBER = **66** (highest registered = 65).
- `_CHECK_65_OPERATING_DOCS = ()` (validate-pack.py:7926) — Check 65 inert (vacuous pass); activates at CG-14.
- Check 44 (`check_durable_doc_concision`) — 6 durable docs, `will ` teeth (FAIL) + per-doc length ceiling (**ADVISORY only, never fails** — validate-pack.py:7864-7872).
- Check 64 (`check_dangling_example_deliverable_refs`) — the referential-integrity PRECEDENT: a bounded family matcher, deliverable-surface walk, target-existence check, EXCLUDE-prefix bound, NO basename allowlist (existence IS the gate). This is the template for Gate 3.
- Check 43 (`check_project_side_bare_internal_refs`) + Check 40 — the bare-ref + hyperlink extraction machinery (`_CHECK_40_BARE_REF_PATTERN`, `_CHECK_40_HYPERLINK_PATTERN`, `_strip_code_blocks`, `_CHECK_40_ANCHOR_PHRASES`). Gate 3 REUSES these.
- Full `validate-pack.py` GREEN (exit 0, "PASSED — all checks clean").

**EE-BASE — enforcement-surface baseline @ `103cca8`.**
- Cmd: `grep -nE "CHECK_REGISTRY_EXPECTED_COUNT = [0-9]|_CHECK_65_OPERATING_DOCS = \(\)" scripts/validate-pack.py; grep -oE "^\s+\([0-9]+, \"check_" scripts/validate-pack.py | grep -oE "[0-9]+" | sort -n | tail -1; python3 scripts/validate-pack.py | tail -2`
- Output (verbatim): `496:CHECK_REGISTRY_EXPECTED_COUNT = 63`; `7926:_CHECK_65_OPERATING_DOCS = ()`; highest registered number `65`; `PASSED — all checks clean` (exit 0).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: registry count 63; next free check number 66; Check 65 inert; tree green. The four new gates add at most 3 registry entries (Gate 1b Check 66 + Gate 2 Check 67 + Gate 3 Check 68; Gate 1a is an in-place Check-44 hardening = +0 entry; Gate 4 is a meta-assertion that can fold into Check 59 = +0, or a standalone +1 — §4.4).
- Conclusion: **SUPPORTED.**

**EE-INSET — the operating-doc IN set = 135 files @ `103cca8`.**
- Cmd: assembled the IN set per the prior design's taxonomy (DESIGN-FINAL-V2 §A: trinity ×2, pack-ops live minus HELP-FRAGMENT-PACK, pack skills 11, pack agents 5, pack stream-meta `_rules` ×2, project trinity, project docs/pack minus HELP-FRAGMENT, project prompts 10, project skills 37, project agent-defs 16×3, RUNTIME-SUBAGENT, project stream-meta `_rules` ×3 + `_format`) into `/tmp/bd243-in.txt`; `wc -l < /tmp/bd243-in.txt`.
- Output (verbatim): `135`. Total content: 20,752 lines / 1,201,222 bytes.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: matches the design's "corrected ≈136" IN scope (the 1-file delta is whether RUNTIME-SUBAGENT-PATTERN.md and the precise `_rules`/`_format` membership are counted; immaterial to the gate designs). This 135-file / ~20.7k-line / ~1.2 MB set is the cost basis for the per-invocation read of Gates 2/3 over the IN set.
- Conclusion: **SUPPORTED.**

---

## 2. SHARED INFRASTRUCTURE (the auto-discovery + EXEMPT model all four gates use)

Three of the four gates scan "the operating-doc IN set." Rather than each freezing its own IN constant (the silent-rot hole Gate 4 closes), they share ONE discovery helper + ONE EXEMPT constant.

### 2.1 `_operating_doc_families()` — the family globs (auto-discovery source)

A single helper returns the operating-doc IN set by GLOBBING the families, then SUBTRACTING the EXEMPT set. The families (measured @ `103cca8`, EE-FAM):

| Family | Glob (relative to REPO_ROOT) | Members @ `103cca8` |
|---|---|---|
| pack trinity | `{CLAUDE,AGENTS,GEMINI}.md` | 3 |
| pack-ops operating docs | `pack-ops/*.md` | 9 (minus HELP-FRAGMENT-PACK = 8 IN) |
| pack skills | `.claude/skills/*/SKILL.md` | 11 |
| pack agents | `.claude/agents/pack-*.md` | 5 |
| pack stream-meta | `backlog/_rules.md`, `changelog/_rules.md` | 2 |
| project trinity | `project-template/{CLAUDE,AGENTS,GEMINI}.md` | 3 |
| project docs/pack | `project-template/docs/pack/*.md` | 5 (minus HELP-FRAGMENT = 4 IN) + RUNTIME-SUBAGENT-PATTERN.md |
| project prompts | `project-template/docs/pack/prompts/*.md` | 10 |
| project skills | `project-template/skills/*/SKILL.md` | 37 |
| project agent-defs | `project-template/.claude/agents/*.md`, `.agents-plugin/optiquity-agents/agents/*.md`, `.codex/agents/*.toml` | 48 |
| project stream-meta | `project-template/docs/project/*/_rules.md`, `.../changelog/_format.md` | 4 |

### 2.2 `_CHECK_OPERATING_DOC_EXEMPT` — the FROZEN EXEMPT constant (the auditable bound)

The EXEMPT set is what a family glob picks up that must NOT be gate-scanned. From DESIGN-FINAL-V2 §A taxonomy (D1 human-orientation / D3 deliverable-record / D4 history-home), measured @ `103cca8`:

```
# Globbed-but-EXEMPT (orientation / output / generated / reference):
_intro.md          (pack backlog/_intro, changelog/_intro; project 3× _intro)  — human orientation, ZERO rules
_toc.md            (pack backlog/_toc, changelog/_toc)                          — generated index
HELP-FRAGMENT*.md  (pack HELP-FRAGMENT-PACK; project HELP-FRAGMENT)            — help OUTPUT, not executed
# (HELP-FRAGMENT-TRACKER already deleted by the strip phase / nuclear D1)
```

The EXEMPT constant is a small (≈3-pattern), rarely-changing, fully-rationale'd list. THIS is the frozen auditable surface — far smaller and more stable than freezing the entire 135-member IN set. Adding an operating doc to a family auto-includes it in the scan; the only way to EXCLUDE a new doc is to add it to EXEMPT WITH A RATIONALE (a reviewable governance act).

### 2.3 The shared `_iter_operating_docs()` discovery function

```
def _iter_operating_docs() -> list[Path]:
    """The operating-doc IN set, auto-discovered by family glob minus EXEMPT.
    Single source of truth for Checks 65 (history), 67 (deferred-feature),
    68 (dangling-ref over operating docs). Gate 4's meta-check asserts
    this set == the union it expects (no family member silently escaped)."""
    # glob each family pattern; collect; subtract any path whose name/suffix
    # matches _CHECK_OPERATING_DOC_EXEMPT; return sorted unique list.
```

All three content gates iterate `_iter_operating_docs()`; Check 65 is REPOINTED from its frozen `_CHECK_65_OPERATING_DOCS` tuple to this helper at CG-14 activation (or retains the constant but POPULATES it from the helper at module load — §5.3 weighs both).

**EE-FAM — operating-doc family member counts @ `103cca8`.**
- Cmd: `ls` over each family glob (pack trinity / pack-ops / .claude/skills / .claude/agents/pack-* / backlog+changelog _rules / project trinity / project docs/pack / prompts / project skills / 3 agent-def families / project stream-meta).
- Output (verbatim, key): pack trinity 3; `pack-ops/*.md` 9; `.claude/skills/*/SKILL.md` 11; `.claude/agents/pack-*.md` 5; project trinity 3; `project-template/docs/pack/*.md` 5; prompts 10; `project-template/skills/*/SKILL.md` 37; each agent-def family 16; project `_rules.md` ×3 + `_format.md` ×1.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the families glob deterministically; the IN set = (glob union) − EXEMPT = 135 (EE-INSET). A glob-based discovery reconstructs the exact IN set without a hand-frozen 135-member list.
- Conclusion: **SUPPORTED.**

### 2.4 Why a SHARED helper (not 3 copies of the family list)

`enumerate-encoding-surfaces`: a single `_iter_operating_docs()` + a single `_CHECK_OPERATING_DOC_EXEMPT` means a family/EXEMPT change touches ONE surface, and Gate 4's meta-check verifies that one surface against the live tree. Three independent frozen lists would drift apart silently — exactly the failure mode this BD closes.

---

## 3. GATE-BY-GATE DESIGN

### GATE 1 — BLOAT / VOLUME ENFORCEMENT (Check 44 hardened + new Check 66)

**What it catches.** (a) An operating doc whose line count regresses past its post-reduction ceiling (whole-doc bloat creep); (b) a single rule/bullet whose char-length exceeds a per-bullet cap (the B1 mega-bullet pattern — e.g. `graph-first-context` at 5024 chars, EE-2C in PLAN-V2). It enforces VOLUME ONLY, never meaning.

**Why a HYBRID (the prompt's options (a)/(b)/(c)).** I recommend **(c) hybrid**, split into two enforcement surfaces:
- **Gate 1a — Check 44 ceiling HARDENED to FAIL**, but ONLY over the small fixed `_CHECK_44_DURABLE_DOCS` set (the 6 pack-ops M4 docs). These already carry measured per-doc ceilings; flipping the advisory to a FAIL is a one-line change in `check_durable_doc_concision` (the `ok(... ADVISORY ...)` branch becomes `fail(...)`).
- **Gate 1b — NEW Check 66 per-bullet/per-rule char-cap (FAIL)** over the B1 surface: the trinity (`## Pack memory` bullets) + RATIONALE (`## <slug>` blocks). This is where the mega-bullet bloat actually lives (EE-2C: the 5024-char `graph-first-context` bullet, 5 rules >1200c). A whole-DOC ceiling cannot catch a mega-bullet inside an otherwise-reasonable doc; a per-bullet cap does.

**Why not (a) alone (doc-ceiling only):** a doc can stay under its line ceiling while one bullet balloons (the B1 failure mode). EE-2C proves B1 is the dominant pack-CLAUDE bloat. Doc-ceiling-only misses it.
**Why not (b) alone (char-cap only):** the project docs (PM-CHAT 1109, PLATFORM-SKILLS 616) bloat as whole-doc length, not as a single mega-bullet; and the pack-ops M4 docs already have a ceiling mechanism worth promoting to teeth. Char-cap-only leaves those unguarded.

**SCOPE.**
- Gate 1a: the FROZEN `_CHECK_44_DURABLE_DOCS` 6-doc set (unchanged scope; the ceilings become teeth). Auto-discovery is NOT applied here — this is a deliberately small, individually-calibrated set (each ceiling is `ceil(measured×1.15)`), and the prompt's measure-then-bound contract requires per-doc derivation that a glob cannot supply.
- Gate 1b: AUTO-DISCOVERED over the trinity (pack + project) + RATIONALE — the files that carry `## Pack memory` / `## <slug>` bullet structure. A helper enumerates each bullet/block; the cap applies per bullet.

**ALLOWLIST (measure-then-bound, derived AFTER reduction).**
- Gate 1a ceilings: re-derive each as `ceil(measured_reduced_lines × 1.15)` from the CB-01/CB-02-reduced docs (the plan's §5 recipe already does this for OPTIONAL-FEATURES; extend the same derivation to all 6 and FLIP advisory→FAIL). The 1.15 headroom IS the "sane headroom" the prompt requires.
- Gate 1b char-cap: a SINGLE numeric cap (one constant, e.g. `_CHECK_66_BULLET_CHAR_CAP`) derived from the POST-REDUCTION maximum legitimate bullet length × headroom. PLUS a snippet-anchored allowlist (modeled on Check 44/65) for any bullet that is legitimately over the cap because it is irreducibly load-bearing (an enumeration that cannot shrink — e.g. the denied-git-verb list). The allowlist is sized to the measured post-reduction over-cap set, which is derived AFTER CB-06/CB-02 land (the dependency the planner must respect).

**FAIL-vs-WARN.** Both **FAIL**. The user's ruling is that the cleanup must not silently rot; an advisory that "never fails the build" (today's Check 44 length behavior) is exactly the silent-rot mechanism. Volume is now a hard gate. (Contrast: the `will ` teeth in Check 44 are already FAIL — Gate 1a brings the length axis up to parity.)

**FALSE-POSITIVE STRATEGY (the "volume only, never meaning" guarantee).** This is the load-bearing constraint (user: "meaning and functionality must not change; only the amount of text"). A volume gate CANNOT false-positive on load-bearing content IF:
1. Its parameters are derived from the POST-REDUCTION reality + headroom — so legitimate content is below the cap BY CONSTRUCTION (measure-then-bound). A cap set to today's bloated numbers would be meaningless; a cap set to the reduced reality + 15% admits all legitimate content and rejects regression.
2. The snippet-anchored allowlist admits any genuinely-irreducible over-cap bullet (the enumeration class), with a `reason:` a reviewer re-verifies — so a load-bearing long bullet is KEPT explicitly, never silently truncated by a coder chasing the gate.
3. The cap is a CHARACTER count, a pure volume measure — it asserts nothing about meaning. A bullet under the cap passes regardless of content; a bullet over the cap is either reducible (fix) or allowlisted (KEEP). There is no content-semantics judgment in the gate.

**DEPENDENCY (flagged for the planner).** Gate 1's PARAMETERS (Gate-1a ceilings, Gate-1b cap + over-cap allowlist) are DERIVED FROM the bloat-reduced tree and therefore CANNOT be finalized until CB-01..CB-09 land. The check BODIES (the Check-44 advisory→FAIL flip; the Check-66 per-bullet scanner) can be authored at any point, but their CONSTANTS are filled at CG-14-prep from the measured reduced tree. Authoring the body with placeholder constants before reduction, then filling constants at CG-14-prep, is the clean split.

**ENCODING SURFACES (enumerate-encoding-surfaces).**
- Gate 1a: `check_durable_doc_concision` body (advisory→FAIL branch) + the 6 `_CHECK_44_DURABLE_DOCS` ceiling values (re-derived) + the comment block (validate-pack.py:7750-7756, the recorded baselines) + `scripts/tests/test-validate-pack-check-44.sh` (the mock uses a parameterized `advisory_ceiling` — add a FAIL-path case; the test is value-agnostic so the ceiling values themselves need no test edit, EE-TEST-MOCK in DESIGN-METHOD). NO registry/count change (in-place hardening, +0 entry).
- Gate 1b: NEW `check_operating_doc_bullet_concision` (Check 66) + `_CHECK_66_BULLET_CHAR_CAP` + `_CHECK_66_BULLET_ALLOWLIST` (or a `pack-ops/.bullet-concision-allowlist.txt` snippet file reusing `_parse_manifest_records`) + NEW `scripts/tests/test-validate-pack-check-66.sh` + `CHECK_REGISTRY` entry `(66, "check_operating_doc_bullet_concision", ..., W)` + `CHECK_REGISTRY_EXPECTED_COUNT` 63→+1 + the EXPECTED_COUNT comment block (validate-pack.py:464-496, add the "+1 net-new BD-243 Check 66" line) + Check 59 (auto-asserts the new count). The CI shard partition (Check 60) picks it up via the registry.

**RUNTIME COST (ci-check-runtime-compounding).** Gate 1a reads the same ≤6 docs Check 44 already reads (no new I/O). Gate 1b reads the 4 trinity files + RATIONALE (5 files, ~3.3k lines total) once, splits on bullet markers, measures each bullet's length — O(lines), no subprocess, no whole-tree scan. Trivial added cost per the ~155 battery invocations. Both stay well inside the per-check budget.

---

### GATE 2 — DEFERRED-FEATURE RECALL GATE (new Check 67)

**What it catches.** An operating-doc line that ADVERTISES a deferred / unimplemented / future-version feature ("tracker integration is deferred", "deferred to a future release", "once those skills land", "v11.1 work", "in a future pack version"). It is a RECALL gate, NOT a precision gate: it cannot decide "is this feature shipped?" — that is the content judgment the prompt acknowledges no regex makes. Instead it flags every marker-bearing line, and an allowlist sized to the genuine operative KEEPs clears the legitimate ones; anything else FAILS.

**MARKER SET (the forbidden-pattern tuple, modeled on `_CHECK_65_FORBIDDEN_PATTERNS`).** A compiled-alternation of deferral markers (case-insensitive where prose, case-sensitive for version tokens):
```
_CHECK_67_DEFERRED_PATTERNS = (
    ("deferred",        re.compile(r"\bdeferred\b", re.I)),
    ("future-version",  re.compile(r"future (pack )?version|future release|in a future", re.I)),
    ("coming",          re.compile(r"\bcoming soon\b", re.I)),
    ("not-yet",         re.compile(r"\bnot yet (created|implemented|built|shipped)\b", re.I)),
    ("lands-ships",     re.compile(r"once .{0,40}\b(land|lands|ship|ships)\b", re.I)),
    ("roadmap",         re.compile(r"\broadmap\b", re.I)),
    ("planned-post",    re.compile(r"\bplanned post\b|currently planned post", re.I)),
    ("will-ship",       re.compile(r"\bwill ship\b", re.I)),
    ("vnext",           re.compile(r"v11\.1|v11\.x")),
    ("slated",          re.compile(r"\bslated\b", re.I)),
    ("expected-offer",  re.compile(r"\bexpected to offer\b", re.I)),
)
```
Note the markers are TIGHTENED from the raw prompt vocabulary using the measure-then-bound data below: bare `deferred` is kept whole-word (`\bdeferred\b`) but the allowlist absorbs the operative-rule uses; `not yet` is bounded to `not yet (created|...)` so it does not fire on "not yet committed" workflow prose; `planned` is bounded to `planned post` so it does not fire on "as planned" etc.

**SCOPE (auto-discovered).** `_iter_operating_docs()` (§2.3) — the 135-file IN set, family-globbed minus EXEMPT. Auto-discovery here is essential: a NEW operating doc that advertises a deferred feature is exactly the silent-rot case the gate exists to catch.

**ALLOWLIST (measure-then-bound, CENSUS §5 is the seed — sized to the CURRENT post-strip KEEP set).** I MEASURED the marker set over the live IN set @ `103cca8` (EE-G2 below). The genuine-operative KEEP categories, each an allowlist `(doc, snippet)` record:
1. **The rule's OWN self-referential text** — the `operating-docs-no-history-no-bloat` rule names "deferred-feature mentions" / "No deferral to v11.1+" / "History and roadmap belong in…". These are the rule describing what it forbids. KEEP (measured: trinity ×6 sites + RATIONALE ×3).
2. **Generic client-PRODUCT advice** — `api-design/SKILL.md` "remove in a future version" (the CLIENT's own API evolution, not a pack feature). KEEP.
3. **Operative current-state caveats** — `OPTIONAL-FEATURES.md` "added here once they ship and prove useful" (a generic extension caveat, not a specific feature promise); the `agy` `define_subagent` current-state fallback. KEEP (CENSUS §5).
4. **The LIVE TD-deferral feature** — the coder agent-defs' "Deferred items" report section + the BLOCKED-triage rubric ("not-yet-landed artifact") + the deferral-discipline rules ("Deferral IS scope creep"). These document a LIVE workflow, not a deferred pack feature. KEEP (CENSUS §5; measured: the 100 `deferred` hits cluster here).

**THE CRITICAL MEASURED FINDING — PLATFORM-SKILLS.md is a census MISS (the recall gate's reason to exist).** The prior CENSUS §3 recorded "PLATFORM-SKILLS.md: no deferred-feature mention found beyond what PACK-FEEDBACK carries — coder VERIFIES." My direct measurement contradicts that: `project-template/docs/pack/PLATFORM-SKILLS.md` carries **22 `deferred` + 7 `future`** hits — an entire `### Deferred skills` section, 14 `*(deferred)*`-tagged catalog rows, and `*(future)*` placeholder rows (EE-G2-PLAT). This is a CLIENT-FACING doc that the strip phase did NOT clean for the deferred axis (CB-08 is bloat-only). This is precisely the "silent rot" the user is closing — a deferred-feature census MISS that no current gate catches. **The gate design must surface this as a JUDGMENT the user adjudicates** (strip the catalog to current-state-only, or rule it a legitimate forward-catalog and allowlist it). It is the single largest determinant of whether Gate 2 is workable as FAIL.

**FAIL-vs-WARN — RECOMMEND FAIL-with-allowlist (like Check 65), CONTINGENT on the PLATFORM-SKILLS adjudication.**
- The FAIL-with-allowlist model is the right shape: it is identical to Check 65, the allowlist is content-anchored (`(doc, snippet)`), and it forces every deferral mention to be either stripped or explicitly justified — the strongest anti-rot posture.
- BUT measure-then-bound forbids shipping a FAIL gate until the tree is CLEAN-or-allowlisted. Today the IN set has ~150+ marker hits (EE-G2), of which the vast majority are the four KEEP categories — but PLATFORM-SKILLS's 22+7 are UNADJUDICATED. A FAIL gate cannot activate while an unclassified cluster exists (it would either fail the build or force a too-broad allowlist that admits contamination by default — the prohibited move).
- **Therefore:** the gate is designed as FAIL-with-allowlist, but its ACTIVATION is gated on (1) the PLATFORM-SKILLS adjudication (strip or allowlist, user-decided), and (2) the allowlist sized EXACTLY to the post-adjudication KEEP set. Until then it can be staged as a WARN (recall report, never fails) — but WARN is a fallback, not the design intent; the user's anti-rot ruling points at FAIL. **Surface the PLATFORM-SKILLS adjudication to the user as the activation precondition.**

**FALSE-POSITIVE STRATEGY.** (1) Markers are bounded (whole-word + context-bounded alternations, not bare substrings) — measured to not fire on workflow prose ("not yet committed", "as planned"). (2) The allowlist is content-anchored to the four measured KEEP categories, sized EXACTLY (no category widened to admit an unclassified hit). (3) The recall nature is acknowledged: the gate's REMEDIATION message says "STRIP the deferred-feature mention OR, if this documents a LIVE feature / generic advice / the rule itself, add an allowlist record with a `reason:` a reviewer re-verifies" — the human adjudicates the recall, the gate enforces the adjudication.

**ENCODING SURFACES.** NEW `check_operating_doc_no_deferred_feature` (Check 67) + `_CHECK_67_DEFERRED_PATTERNS` + the allowlist file `pack-ops/.operating-doc-deferred-feature-allowlist.txt` (new; same `_parse_manifest_records` format as Check 65's) + a `_check_67_load_allowlist()` (clone of `_check_65_load_allowlist`) + NEW `scripts/tests/test-validate-pack-check-67.sh` + `CHECK_REGISTRY` entry `(67, ...)` + `CHECK_REGISTRY_EXPECTED_COUNT` +1 + the EXPECTED_COUNT comment + Check 59 (auto-asserts) + Check 60 (registry-derived shard coverage). The shared `_iter_operating_docs()` (§2.3) is the scope source (reused, not duplicated).

**RUNTIME COST.** One compiled-alternation scan per line over the 135-file / 20.7k-line IN set, plus the allowlist parse (one small file). This is the SAME read Check 65 performs (both iterate the IN set) — if co-located, the IN-set read could be shared, but even independently it is one pass over ~1.2 MB with ~11 compiled patterns = milliseconds. No subprocess, no whole-tree scan. Bounded to the IN set, not the tree.

**EE-G2 — deferred-feature marker counts over the 135-file IN set @ `103cca8`.**
- Cmd: `grep -niE "<marker>" $(cat /tmp/bd243-in.txt)` per marker (inline command-substitution form; the `-r` flag corrupts file-list grep — verified).
- Output (verbatim, per marker): `deferred` = **100**; `\bfuture\b` = **41**; `not yet` = **16**; `\bplanned\b` = **35**; `roadmap` = **8**; `v11.1` = **6**; `future version` = **1**; `once .*(land|ship)` = **3**; `will ship` = **0**; `coming soon` = 0; `slated` = 0; `not yet created` = 0; `expected to offer` = 0.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the NARROW forward-look markers are near-zero post-strip (`will ship`/`coming soon`/`slated`/`not yet created` = 0), confirming the strip phase cleaned the explicit promises. The HIGH counts (`deferred` 100, `planned` 35, `future` 41) are dominated by the four KEEP categories (rule self-reference, TD-deferral feature, generic advice, deferral-discipline rules) — verified by distribution (EE-G2-DIST). The allowlist sizes to those categories; the gate FAILS only on the residue.
- Conclusion: **SUPPORTED.**

**EE-G2-DIST — the `deferred` hits cluster in KEEP categories @ `103cca8`.**
- Cmd: `grep -niE 'deferred' $(cat /tmp/bd243-in.txt) | cut -d: -f1 | sort | uniq -c | sort -rn`.
- Output (verbatim, top): `PLATFORM-SKILLS.md 22`, pack trinity `GEMINI/CLAUDE/AGENTS 8` each, `prompts/coder.md 7`, `RATIONALE 6`, project trinity 4 each, `implementation-report/SKILL.md 4`, project coder agent-defs 3 each (tri-family), `review/SKILL.md 2`, `backlog/_rules.md 2`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the trinity/RATIONALE hits (≈30) are the rule's self-reference (KEEP category 1); the coder-agent-def + implementation-report + review hits (≈20) are the LIVE TD-deferral feature (KEEP category 4); PLATFORM-SKILLS's 22 are the UNADJUDICATED catalog (the JUDGMENT site). The allowlist absorbs categories 1+4 by content-anchor; PLATFORM-SKILLS is the activation precondition.
- Conclusion: **SUPPORTED.**

**EE-G2-PLAT — PLATFORM-SKILLS.md carries 22 deferred + 7 future (a census MISS) @ `103cca8`.**
- Cmd: `grep -niE 'deferred' project-template/docs/pack/PLATFORM-SKILLS.md` (22 lines) + `grep -niE '\bfuture\b' …` (7 lines); cross-check `grep -in "PLATFORM-SKILLS" CENSUS-DEFERRED-FEATURE-MENTIONS.md`.
- Output (verbatim, key): catalog rows `| \`android\` *(deferred)* | …`, `| \`web-browser\` *(deferred)* | …`, …, a `### Deferred skills (create when project need arises)` section header, `**D1-implied languages (deferred with their D1 value):**`, `| *(future)* \`swift-server-architecture\` | … | Deferred; placeholder for Vapor / Hummingbird |`; CENSUS §3 line `(PLATFORM-SKILLS.md: no deferred-feature mention found beyond what PACK-FEEDBACK carries — coder VERIFIES.)`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the prior census MISSED a 22+7-hit client-facing deferred-feature cluster (it deferred verification to "coder VERIFIES" and the bloat plan's CB-08 is bloat-only, never re-censused it). This is the recall-gap that justifies a durable gate over a one-time census; it is also a live JUDGMENT the user must adjudicate before Gate 2 can FAIL-activate.
- Conclusion: **SUPPORTED — a real, un-stripped, client-facing deferred-feature cluster + a census miss.**

---

### GATE 3 — DANGLING-REFERENCE GATE (new Check 68, generalizes Check 64)

**What it catches.** A file/path reference in an operating doc (and the deliverable surface) whose target does NOT exist — a dead pointer. This is the axis that let the HELP-FRAGMENT-TRACKER refs, the `_v8-resolved-archive.md` ref, and the `feedback_review_fix_one_cycle.md` ref (EE-G3-BARE) slip past CI and get caught only by reviewers. Check 64 already does this for the 3-member MCP/config `.example` family; Gate 3 generalizes the same pattern to the full file-reference surface.

**REF-EXTRACTION (which reference shapes — reuse the Check 40/43 machinery).** Three shapes, all using the EXISTING compiled patterns so no new regex risk:
1. **Backtick bare-ref** — `` `FILENAME.ext` `` via `_CHECK_40_BARE_REF_PATTERN` (first char `[A-Za-z]`, ext in `md|sh|py|toml|yml|yaml|json|txt`). This is the dominant citation shape (EE-G3-BARE: 82 distinct basenames over the IN set).
2. **Markdown hyperlink** — `[label](FILENAME.ext)` via `_CHECK_40_HYPERLINK_PATTERN`.
3. **Qualified-path backtick ref** — `` `dir/sub/FILE.ext` `` (the shape Check 40/43's `[A-Za-z]`-first / `/`-exclusion DELIBERATELY misses — and exactly where HELP-FRAGMENT-TRACKER + `_v8-resolved-archive.md` hid). Add ONE new bounded pattern: `` `([A-Za-z][\w./-]*/[\w.-]+\.(ext))` `` (qualified path, ≥1 slash). Measured: 104 distinct qualified-path refs over the IN set (EE-G3-QUAL).
All three run AFTER `_strip_code_blocks()` (fenced/indented code is not prose citation) — reusing Check 40's preprocessor verbatim.

**EXISTENCE CHECK.** For a bare-ref basename: resolve via the basename index (does ANY file with that basename exist in the tree, minus archive/test-fixtures — the Check-40 `_CHECK_40_EXCLUDE_PARTS` set) OR a curated allowlist entry. For a qualified-path ref: resolve `REPO_ROOT/<path>` directly; if absent, fall back to basename-resolution (a `docs/pack/X.md` ref from a pack doc may legitimately resolve to the client-install location). A ref that resolves to NO file AND is not allowlisted → FAIL with `file:line` + the dangling token + a restore-or-drop remediation (the Check-64 message shape).

**SCOPE.** The operating-doc IN set (`_iter_operating_docs()`) UNION the Check-64 deliverable surface (README layout block + `project-template/**` + `supporting-docs/**`), minus the Check-64 EXCLUDE prefixes (`changelog/`, `backlog/`, `pack-ops/` history... — actually pack-ops IS in the operating-doc IN set for Gate 3, so the EXCLUDE set differs: Gate 3 excludes only `maintenance-docs/`, `test-fixtures/`, `scripts/tests/fixtures/`, `.git/`, and the per-entry stores `backlog/BD-*.md`/`changelog/*.md` content bodies which are history-home). Auto-discovered for the operating-doc half.

**RECONCILE WITH CHECK 43/64 (extend vs new — RECOMMEND NEW Check 68, do NOT extend).**
- **Check 43** is a project-side LEAK scanner: it flags a client-surface ref whose basename resolves into PACK-ONLY territory (`maintenance-docs/`/`pack-ops/`). Its job is boundary-leak detection, not general existence. Folding general dangling-ref detection into it would conflate two different verdicts (leak vs dead-pointer) and broaden its allowlist semantics. Keep Check 43 as-is.
- **Check 64** is the existence-precedent but bounded to ONE 3-member family by design (`ci-guard-measure-then-bound`). Generalizing its matcher in-place would blow its bound. Keep Check 64 as-is.
- **Check 40** is the bare-ref EXTRACTOR (pack-side, BOUNDARY-DEFINITION-anchored); Gate 3 REUSES its patterns + `_strip_code_blocks` + `_CHECK_40_ANCHOR_PHRASES` (the "archived"/"does not exist" self-flagging anchors are exactly Gate 3's intentional-non-existence allowlist mechanism).
- **NEW Check 68** is the general existence gate over the operating-doc + deliverable surface, reusing Check 40's extraction and Check 64's existence/remediation shape. It is the correct home: a distinct verdict (dead pointer), a distinct scope (operating docs, which Check 64 excludes via `pack-ops/`), a distinct allowlist (intentional placeholders).

**ALLOWLIST (measure-then-bound — MEASURED the current dangling set).** I ran the extraction + existence check over the IN set @ `103cca8`. Of 82 bare-ref basenames + 104 qualified-path refs, the dangling set is 6 bare + 8 qualified = 14, classified KEEP/STRIP (EE-G3-BARE, EE-G3-QUAL):

| Dangling ref | Class | Disposition | Allowlist mechanism |
|---|---|---|---|
| `BD-NNN.md`, `TD-NNN.md`, `phase-N.md` | filename-grammar example | KEEP | per-entry skeleton pattern (already on Check-43 allowlist; mirror the rationale) |
| `migrate-vN-to-vM.sh` | framework filename pattern | KEEP | the BD-119 migrator-framework grammar (already Check-43 allowlisted) |
| `AGENT_KICKOFF.md`, `FEATURES.md`, `SETUP.md` | template placeholder (pm-chat self-prompt generated) | KEEP | Check-43-allowlisted template placeholders |
| `ARCHITECTURE-V1.md`, `IMPLEMENTATION-PLAN-V11.0.md`, `docs/pack/PROMPT-TEMPLATES.md` | self-flagged non-existence ("now-archived", "(does not exist)", "Retired in v10.0") | KEEP | the `_CHECK_40_ANCHOR_PHRASES` window ("archived"/"does not exist") clears these automatically — NO allowlist record needed |
| `graphify-out/cost.json` | runtime-generated gitignored output | KEEP | allowlist record (the build produces it at runtime; not in tree) |
| `server/src/observability/setup.py`, `scripts/lib/test-helpers.sh`, `scripts/x-tool.sh` | teaching/`x-`-pattern/declined-example path | KEEP | `x-` custom pattern + illustrative-path allowlist (self-flagged "not present in the pack repo" / "DECLINED for now") |
| **`feedback_review_fix_one_cycle.md`** | **GENUINE DANGLING** (real file is `feedback_review_fix_cycle.md` — no "one"; the memory index has no such file) | **STRIP/FIX** | NOT allowlisted — this is a real dead pointer in `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md:186` to fix |

So the allowlist sizes to exactly the 13 KEEP refs (most absorbed by the existing anchor-phrase mechanism or mirroring Check-43 rationales), and the gate FAILS on the 1 genuine dangling ref — which a fix-coder strips/corrects so the gate runs clean at activation (measure-then-bound: verify clean against projected post-fix state).

**FAIL-vs-WARN.** **FAIL with allowlist.** Existence is objective (the file is there or not), so a FAIL gate has no meaning-judgment risk; the only false-positive source is an intentional placeholder, which the allowlist + anchor-phrase mechanism covers exactly.

**FALSE-POSITIVE STRATEGY.** (1) Reuse `_strip_code_blocks` — fenced code (example commands, JSON) is never treated as a citation. (2) Reuse `_CHECK_40_ANCHOR_PHRASES` — a ref within 2 lines of "archived"/"does not exist"/"post-install" is intentional non-existence, auto-cleared (this single mechanism covers the largest KEEP class). (3) A snippet/basename allowlist for grammar patterns + runtime outputs + `x-` examples, sized to the measured KEEP set, each with a `reason:`. (4) Qualified-path refs fall back to basename resolution so a pack-doc citing a client-install path is not a false dangling.

**ENCODING SURFACES.** NEW `check_dangling_file_refs` (Check 68) + `_CHECK_68_QUALIFIED_PATH_PATTERN` (the one new bounded regex) + `_CHECK_68_ALLOWLIST` (or `pack-ops/.dangling-ref-allowlist.txt`) + a basename-index reuse of Check 40's index builder + NEW `scripts/tests/test-validate-pack-check-68.sh` + `CHECK_REGISTRY` entry `(68, ...)` + `CHECK_REGISTRY_EXPECTED_COUNT` +1 + the comment + Check 59 + Check 60. The shared `_iter_operating_docs()` is the operating-doc scope source.

**RUNTIME COST.** One pass over the IN set + the Check-64 deliverable trees (162 files), extracting refs (3 compiled patterns) and resolving each against a basename index BUILT ONCE (Check 40 already builds this index — reuse it, do not rebuild per-file). No per-ref subprocess, no per-entry storm. The index build is the only non-trivial cost and it is already paid by Check 40 in the same run; sharing it makes Gate 3 nearly free. Bounded; cheap.

**EE-G3-BARE — bare-ref dangling set over the IN set @ `103cca8`.**
- Cmd: extract `` `BASENAME.ext` `` tokens over `/tmp/bd243-in.txt`; for each unique basename, `find . -name <basename> -not -path './.git/*'`; report those with no match.
- Output (verbatim): 82 distinct backtick basenames; dangling (no file anywhere) = `AGENT_KICKOFF.md`, `ARCHITECTURE-V1.md`, `BD-NNN.md`, `FEATURES.md`, `feedback_review_fix_one_cycle.md`, `IMPLEMENTATION-PLAN-V11.0.md` (6). Context: `AGENT_KICKOFF`/`FEATURES`/`BD-NNN` = template/grammar placeholders; `ARCHITECTURE-V1` = "now-archived `ARCHITECTURE-V1.md`"; `IMPLEMENTATION-PLAN-V11.0` = "cited … (does not exist)"; `feedback_review_fix_one_cycle.md` = `CONCEPTUAL-REVIEW-METHODOLOGY.md:186` "(per `feedback_review_fix_one_cycle.md`)" with NO such file (the memory index name is `feedback_review_fix_cycle.md`).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: 5 of 6 are KEEP (4 anchor-phrase/placeholder-covered; 1 grammar); 1 (`feedback_review_fix_one_cycle.md`) is a GENUINE residual dangling ref a gate would catch and a fix-coder strips. Allowlist sizes to the 5 KEEP exactly.
- Conclusion: **SUPPORTED — 1 real dangling ref found; allowlist bounded to the 5 measured placeholders.**

**EE-G3-QUAL — qualified-path dangling set over the IN set @ `103cca8`.**
- Cmd: extract `` `dir/.../FILE.ext` `` tokens; for each, test `REPO_ROOT/<path>` existence then basename fallback; report unresolved.
- Output (verbatim): 104 distinct qualified-path refs; dangling = `docs/pack/PROMPT-TEMPLATES.md` ("Retired in v10.0"), `docs/project/backlog/TD-NNN.md` (grammar), `docs/project/implementation-plan/phase-N.md` (grammar), `graphify-out/cost.json` (runtime-generated), `scripts/lib/test-helpers.sh` ("DECLINED for now"), `scripts/migrate-vN-to-vM.sh` (framework pattern), `scripts/x-tool.sh` ("not present in the pack repo"), `server/src/observability/setup.py` (client teaching example) (8).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: all 8 qualified-path dangles are KEEP — grammar patterns (`TD-NNN`/`phase-N`/`migrate-vN-to-vM`), self-flagged retired/declined/external (`PROMPT-TEMPLATES`/`test-helpers`/`x-tool`/`setup.py`), or runtime-generated (`cost.json`). Allowlist absorbs them via anchor-phrase + grammar-pattern records. The qualified-path axis adds NO new STRIP over bare-ref, but it is the axis that WOULD have caught HELP-FRAGMENT-TRACKER (a qualified `pack-ops/HELP-FRAGMENT-TRACKER.md` ref the bare-ref pattern's `/`-exclusion misses) — its value is forward (catching the next deleted-doc ref), not residual.
- Conclusion: **SUPPORTED — 0 residual qualified-path STRIP; allowlist bounded to 8 measured placeholders; the axis closes the deleted-doc blind spot.**

---

### GATE 4 — NEW-DOC AUTO-COVERAGE (the scope-completeness meta-check)

**The hole.** `_CHECK_65_OPERATING_DOCS` is a FROZEN tuple. A NEW operating doc — a new pack-ops/ doc, a new skill, a new prompt — is NOT added to the tuple automatically, so it silently escapes Check 65 (and would escape Gates 2/3 too if they froze their own IN lists). The cleanup rots the moment someone adds an operating doc without remembering to extend the scan list.

**The two options (the prompt's (a)/(b)) — I recommend a COMBINATION: (a) auto-discover the SCAN + (b) a meta-check that asserts the discovery is complete.**

- **(a) Auto-discovery for the SCAN.** Gates 65/67/68 iterate `_iter_operating_docs()` (§2.3) — the family glob minus EXEMPT — NOT a frozen IN tuple. A new family member is scanned automatically. This is the coverage win.
- **(b) A meta-check for the BOUND.** Auto-discovery alone has a subtle risk: a glob is only as good as its family patterns + EXEMPT list. If someone adds a doc in a NEW location (a family the glob does not cover), it still escapes. The meta-check (Check 4-style bookkeeping, or folded into Check 59) asserts: **every file under the operating-doc top-level trees is either (i) matched by a family glob, (ii) on the EXEMPT constant, or (iii) on a frozen OUT-OF-FAMILY list.** A doc that is none of these FAILS the meta-check with "new operating-doc location `<path>` is neither family-globbed nor EXEMPT — add it to a family glob or EXEMPT it with a rationale." This converts "silently escapes" into "loud build failure."

**Why BOTH (not auto-discover alone, not meta-check-over-frozen-constant alone):**
- Auto-discover alone: covered by glob, but a doc in an un-globbed location escapes silently. The meta-check is the backstop for the glob's own completeness.
- Meta-check over a frozen IN constant (the pure-(b) reading): forces a human to extend the constant per new doc — better than today (it FAILS loudly) but still a manual lock-step edit per doc. Auto-discovery removes the per-doc chore; the meta-check guards the glob.
- The combination gives: zero per-doc chore (glob) + zero silent escape (meta-check) + a small auditable frozen surface (the EXEMPT constant + the family-pattern list, both rarely-changing).

**DETERMINISM / AUDITABILITY vs COVERAGE (the prompt's explicit trade-off).** A frozen constant is maximally deterministic/auditable (you read the tuple, you know exactly what is scanned) but rots (the silent-escape hole). A pure glob is maximally covering but the scanned set is implicit (you must run the glob to know it). The COMBINATION resolves the tension: the EXEMPT constant + family-pattern list ARE the frozen auditable surface (small, stable, rationale'd), and the meta-check makes the glob's coverage an ASSERTED invariant rather than an implicit one — so the scanned set is both auto-complete AND provably bounded. This is strictly better than the current frozen-IN constant on coverage, and strictly better than a pure glob on auditability.

**APPLY THE SAME DECISION TO GATES 1-3 (the prompt's instruction).**
- **Gate 1a (Check 44 ceiling):** KEEP the frozen 6-doc `_CHECK_44_DURABLE_DOCS` — auto-discovery does NOT apply, because each ceiling is an individually-derived per-doc number (`ceil(measured×1.15)`); a glob cannot supply per-doc calibrated ceilings. This is the one deliberate frozen-constant exception, and it is auditable (6 rows, each a measured number). The meta-check does NOT police this set (it is intentionally narrow, not "all operating docs").
- **Gate 1b (Check 66 bullet-cap):** AUTO-DISCOVER over the trinity + RATIONALE (the bullet-bearing files), single cap constant. The meta-check is N/A (the bullet surface is the 4 trinity + RATIONALE files, a structural family, not the full IN set).
- **Gate 2 (Check 67) + Gate 3 (Check 68):** AUTO-DISCOVER via `_iter_operating_docs()` + governed by the SAME meta-check (they share the IN set, so the meta-check that validates `_iter_operating_docs()` covers them all at once).

**ENCODING SURFACES.** The meta-check: either FOLD into Check 59 (the existing registry-completeness check — add an "operating-doc scope completeness" assertion clause, +0 registry entry) OR a NEW standalone Check 69 (`check_operating_doc_scope_completeness`, +1 entry). RECOMMEND a NEW standalone Check 69 — Check 59 is about the CHECK registry, not the DOC scope; conflating them muddies two distinct invariants (`enumerate-encoding-surfaces` favors one-concern-per-check). Surfaces: NEW `check_operating_doc_scope_completeness` (Check 69) + `_CHECK_OPERATING_DOC_FAMILIES` (the glob-pattern list) + `_CHECK_OPERATING_DOC_EXEMPT` (§2.2, shared) + `_CHECK_OPERATING_DOC_OUT_OF_FAMILY` (frozen, the explicit non-operating docs under the trees that are neither family nor EXEMPT — sized by measuring the trees) + NEW `scripts/tests/test-validate-pack-check-69.sh` + registry `(69, ...)` + count +1 + comment + Check 59 + Check 60.

**RUNTIME COST.** One directory glob per family + set arithmetic against the EXEMPT/OUT-OF-FAMILY constants. No content read at all (Gate 4 reads NO file bodies — it only enumerates paths). The cheapest of the four gates. Bounded; trivial.

**EE-G4 — the frozen-constant silent-escape hole is real @ `103cca8`.**
- Cmd: `grep -n "_CHECK_65_OPERATING_DOCS = " scripts/validate-pack.py` + inspect the constant's population mechanism.
- Output (verbatim): `7926:_CHECK_65_OPERATING_DOCS = ()` — a hand-frozen tuple, populated only at CG-14 activation, with NO discovery mechanism; the comment (validate-pack.py:7920-7925) says "FROZEN constant, sized to the corrected IN set … populated at gate ACTIVATION."
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: once populated, the tuple is a static literal; adding a new skill/prompt/pack-ops doc does NOT extend it — the new doc escapes Check 65 silently. Gate 4 (auto-discover + meta-check) closes this. The EXEMPT set is the small frozen auditable surface that replaces freezing the whole IN set.
- Conclusion: **SUPPORTED — the frozen-IN constant is the silent-rot hole; auto-discover-minus-EXEMPT + a completeness meta-check is the durable fix.**

---

## 4. THE R2 INCIDENT-REGEX TIGHTENING (Check-65 calibration, user-decided — folded)

The user decided: `("incident", re.compile(r"incident"))` → `("incident", re.compile(r"\bincident\b"))` in `_CHECK_65_FORBIDDEN_PATTERNS` (validate-pack.py:7915). I fold it into the Check-65 calibration here (it is a Check-65 pattern edit, naturally landing with the gate-hardening work).

**Measure-then-bound confirmation (EE-R2).** The substring `incident` over the IN set matches 9 lines; the whole-word `\bincident\b` matches 7. The 2-line delta is exactly the false-positives: `project-template/docs/pack/prompts/reviewer.md:128` "...not **coincidental**" and `project-template/docs/pack/PACK-FEEDBACK.md:59` "...individual **incidents**". The 7 whole-word hits are 6 rule-self-reference ("incident/SHA refs" / "incident or commit-SHA refs" across the 6 trinity files) + 1 legitimate KEEP (`project-template/skills/boundary-investigation/SKILL.md:33` "The audit **incident** (P-missed-7)" — a live operative rule rationale). So the tightening eliminates 2 substring false-positives with zero loss of genuine recall — the canonical measure-then-bound narrowing (the legitimate forbidden hit is the standalone word, not the substring).

**Calibration consequence for Check-65 ACTIVATION.** After the tightening, the 7 whole-word `incident` hits are all KEEP and need allowlist coverage at activation: the 6 rule-self-reference lines + the 1 boundary-investigation rule-rationale line. This is GC-3 in the bloat plan (the boundary-investigation record) — the trinity self-reference lines are cleared because they are the rule's own forbidden-list text (a `(doc, snippet)` record per trinity file, or the rule-self-reference snippet already in the K12 allowlist family). The bloat plan §6.2 already schedules GC-1/GC-2 (killed by the tightening) and GC-3 (the boundary-investigation KEEP record); this design CONFIRMS that calibration and ties it to the gate-activation step.

**ENCODING SURFACES (R2).** `_CHECK_65_FORBIDDEN_PATTERNS` tuple (the one regex literal) + `scripts/tests/test-validate-pack-check-65.sh` (add a case asserting "incidents"/"coincidental" do NOT match and standalone "incident" DOES). NO registry/count change (it edits an existing pattern). The bloat plan §8 already specifies this test addition.

**EE-R2 — incident substring vs whole-word over the IN set @ `103cca8`.**
- Cmd: `grep -niE "incident" $(cat /tmp/bd243-in.txt)` (9 hits) vs `grep -nE "\bincident\b" $(cat /tmp/bd243-in.txt)` (7 hits).
- Output (verbatim): substring-only extras = `prompts/reviewer.md:128` "not coincidental", `PACK-FEEDBACK.md:59` "individual incidents"; whole-word 7 = pack `{CLAUDE,AGENTS,GEMINI}.md` "incident/SHA refs" (3) + project `{CLAUDE,AGENTS,GEMINI}.md` "incident or commit-SHA refs" (3) + `boundary-investigation/SKILL.md:33` "The audit incident (P-missed-7)" (1).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the tightening drops exactly the 2 substring false-positives; the 7 whole-word hits are 6 rule-self-reference + 1 KEEP, all allowlist-covered at activation. Net recall on genuine history-narrative "incident" is unchanged.
- Conclusion: **SUPPORTED — measure-then-bound clean; the tightening is the correct one-move fix.**

---

## 5. THE SCOPE-MODEL DECISION (consolidated — auto-discover + EXEMPT + meta-check)

The single most important cross-gate decision. Three candidate models:

| Model | Coverage | Auditability | Rot risk | Verdict |
|---|---|---|---|---|
| Frozen IN constant (today's Check 65) | a NEW doc escapes silently | high (read the tuple) | HIGH — the hole this BD closes | REJECT |
| Pure glob (no frozen surface) | complete | low (scanned set is implicit; a wrong glob is invisible) | medium (glob gaps) | REJECT |
| **Auto-discover (glob) − frozen EXEMPT + meta-check** | complete + glob-gaps caught | high (EXEMPT + family list are small frozen rationale'd surfaces; meta-check makes coverage an asserted invariant) | LOW | **ADOPT** |

The adopted model's frozen surface is the EXEMPT constant (≈3 patterns) + the family-pattern list (≈11 globs), both small/stable/rationale'd — far more auditable than a frozen 135-member IN tuple, and it does not rot. The meta-check (Gate 4 / Check 69) is what makes the glob trustworthy.

**Per-gate application (the §3 + §4 decisions, summarized):**
- Check 65 (history): REPOINT from `_CHECK_65_OPERATING_DOCS` tuple to `_iter_operating_docs()` at CG-14 activation (or populate the tuple FROM the helper at module load). Governed by the meta-check.
- Check 67 (deferred): auto-discover via `_iter_operating_docs()`. Governed by the meta-check.
- Check 68 (dangling): auto-discover (operating-doc half) via `_iter_operating_docs()` ∪ Check-64 deliverable surface. Governed by the meta-check (operating-doc half).
- Check 44 ceiling (Gate 1a): the ONE deliberate frozen exception (6 per-doc-calibrated ceilings) — NOT meta-check-policed, intentionally narrow.
- Check 66 bullet-cap (Gate 1b): auto-discover the bullet surface (trinity + RATIONALE), single cap.

### 5.1 The Check-65 repoint vs populate-from-helper micro-decision
Two clean ways to give Check 65 the auto-discovered scope without a behavior surprise: (A) replace `for doc_rel in _CHECK_65_OPERATING_DOCS:` with `for doc_path in _iter_operating_docs():`; or (B) keep the constant name but set `_CHECK_65_OPERATING_DOCS = tuple(_iter_operating_docs())` at module load. (A) is cleaner (one scope source); (B) preserves the constant for the test's monkeypatch (`test-validate-pack-check-65.sh` saves/restores `mod._CHECK_65_OPERATING_DOCS`). RECOMMEND (B) — it keeps the existing test's monkeypatch seam intact (the test sets the constant to `(SYNTH_DOC,)`), so the test surface is unchanged while the production scope auto-discovers. The planner/coder picks; both are correct.

---

## 6. CONSOLIDATED ENCODING-SURFACE ROLLUP (enumerate-encoding-surfaces — the lock-step the coder/planner move together)

| Gate | New check # | Check body | Constant(s) | Allowlist file | Test file | Registry entry | EXPECTED_COUNT | Comment block | Check 59/60 |
|---|---|---|---|---|---|---|---|---|---|
| **G1a** | (Check 44, in-place) | flip advisory→FAIL branch in `check_durable_doc_concision` | re-derive 6 `_CHECK_44_DURABLE_DOCS` ceilings + comment 7750-7756 | — | edit `test-validate-pack-check-44.sh` (add FAIL-path case; value-agnostic mock) | +0 | +0 | (note the ceiling re-derivation) | auto |
| **G1b** | **66** | `check_operating_doc_bullet_concision` | `_CHECK_66_BULLET_CHAR_CAP` | `pack-ops/.bullet-concision-allowlist.txt` (optional) | NEW `test-validate-pack-check-66.sh` | `(66, ...)` | +1 | add "+1 BD-243 Check 66" line | auto |
| **G2** | **67** | `check_operating_doc_no_deferred_feature` | `_CHECK_67_DEFERRED_PATTERNS` | `pack-ops/.operating-doc-deferred-feature-allowlist.txt` | NEW `test-validate-pack-check-67.sh` | `(67, ...)` | +1 | add "+1 BD-243 Check 67" line | auto |
| **G3** | **68** | `check_dangling_file_refs` | `_CHECK_68_QUALIFIED_PATH_PATTERN` + reuse Check-40 index/patterns/anchors | `pack-ops/.dangling-ref-allowlist.txt` | NEW `test-validate-pack-check-68.sh` | `(68, ...)` | +1 | add "+1 BD-243 Check 68" line | auto |
| **G4** | **69** | `check_operating_doc_scope_completeness` | `_CHECK_OPERATING_DOC_FAMILIES` + `_CHECK_OPERATING_DOC_EXEMPT` + `_CHECK_OPERATING_DOC_OUT_OF_FAMILY` | — | NEW `test-validate-pack-check-69.sh` | `(69, ...)` | +1 | add "+1 BD-243 Check 69" line | auto |
| **R2** | (Check 65, in-place) | tighten `incident` regex | `_CHECK_65_FORBIDDEN_PATTERNS` | — | edit `test-validate-pack-check-65.sh` (incident whole-word case) | +0 | +0 | — | auto |
| **shared** | — | `_iter_operating_docs()` | `_CHECK_OPERATING_DOC_FAMILIES` + `_CHECK_OPERATING_DOC_EXEMPT` | — | (covered by G4 test) | +0 | +0 | — | — |

**Net registry impact:** +4 entries (Checks 66, 67, 68, 69) → `CHECK_REGISTRY_EXPECTED_COUNT` 63 → **67**. (Gate 1a + R2 are in-place, +0.) Check 59 auto-asserts the new count; Check 60 auto-derives the shard partition. The EXPECTED_COUNT comment block (validate-pack.py:464-496) gets 4 new "+1 net-new BD-243 Check NN" lines — the comment is the lock-step documentation surface the prior checks all maintained.

**CAUTION (from the existing comment, validate-pack.py:489-491):** check NUMBER ≠ entry COUNT. The new numbers are 66/67/68/69 but the COUNT goes 63→67 (+4), not to 69. Bump `CHECK_REGISTRY_EXPECTED_COUNT` by the net-new entry count.

---

## 7. INSERTION / PLAN-IMPACT RECOMMENDATION (the dependency-correct ordering — the planner sequences)

The user delegated WHERE each gate lands to me + the planner. I propose the dependency-correct order; the planner schedules the worktree waves.

### 7.1 The hard dependency: Gate 1 parameters come AFTER bloat reduction
Gate 1 (Check 44 FAIL ceilings + Check 66 bullet-cap) MEASURES the reduced tree. Its PARAMETERS (the 6 re-derived ceilings, the bullet char-cap, the over-cap allowlist) CANNOT be derived until CB-01..CB-09 land. Therefore:
- **Gate 1 check BODIES** (the advisory→FAIL flip; the Check-66 scanner skeleton with a placeholder cap) — author at **CG-14-prep** (after all CB commits land), NOT before. Authoring earlier risks parameters drifting against in-flight reductions.
- **Gate 1 PARAMETERS** — derive at **CG-14-prep** from the measured reduced tree (`wc -l` each of the 6 docs → `ceil(×1.15)`; measure the max legitimate bullet → cap × headroom; measure the over-cap residue → allowlist). This is identical in nature to the plan's existing CB-01 OPTIONAL-FEATURES ceiling re-derivation (§5 of PLAN-V2) — extend that recipe to all 6 docs + the bullet surface.

### 7.2 Gates 2, 3, 4 + R2: land at CG-14-prep / CG-14 (calibration-of-final-tree work)
Gates 2/3/4 are NEW CI checks whose ALLOWLISTS are sized against the FINAL tree (post-bloat, post-strip). They are the same KIND of work as the plan's CG-14-prep (which already does the two-axis sweep + the gate-completeness records + the R2 tightening). The dependency-correct placement:
- **CG-14-prep gains:** author Checks 66/67/68/69 bodies + constants; build the 3 new allowlist files sized to the measured KEEP sets (§3 tables); fold the R2 tightening (already planned); fix the 1 genuine dangling ref (`feedback_review_fix_one_cycle.md`, EE-G3-BARE) so Gate 3 runs clean; ADJUDICATE PLATFORM-SKILLS (the Gate-2 activation precondition, EE-G2-PLAT — user decides strip-vs-allowlist).
- **CG-14 activation gains:** wire all four new checks into `CHECK_REGISTRY`; bump `CHECK_REGISTRY_EXPECTED_COUNT` 63→67; repoint Check 65 scope to `_iter_operating_docs()`; run the full battery green (every new gate clean against the final tree — the measure-then-bound verification); then push.

### 7.3 Proposed dependency-correct ordering (the planner schedules waves)
```
CB-01 .. CB-09         (bloat reduction — UNCHANGED by this design; Gate 1 measures THIS output)
   │
CG-14-prep  ──┬── existing: 2-axis sweep + R2 tighten + GC-1..GC-4 records (PLAN-V2 §6)
              ├── NEW: author Checks 66/67/68/69 bodies + _iter_operating_docs() helper + EXEMPT constant
              ├── NEW: derive Gate-1 parameters from the measured reduced tree (6 ceilings + bullet cap)
              ├── NEW: size the 3 new allowlists to the measured KEEP sets (§3)
              ├── NEW: fix the 1 genuine dangling ref (feedback_review_fix_one_cycle.md)
              └── NEW: ADJUDICATE PLATFORM-SKILLS deferred catalog (user; Gate-2 activation precondition)
   │
CG-14 activation ─── wire 4 checks into registry; count 63→67; repoint Check 65 to _iter_operating_docs();
                     flip Check 44 advisory→FAIL; full battery green; then push.
```

### 7.4 Splitability note for the planner
CG-14-prep is now substantial (4 new checks + their tests + 3 allowlists + Gate-1 derivation). The planner MAY split it into CG-14-prep-a (the helper + Gate 4 meta-check + the Check-65 repoint + R2 — the scope infrastructure) and CG-14-prep-b (Gates 1/2/3 bodies + allowlists + the dangling-ref fix + the PLATFORM-SKILLS adjudication — the content gates). This is a reviewability split, not a scope change; the dependency is CG-14-prep-a before CG-14-prep-b (the content gates use the shared `_iter_operating_docs()` from -a). The bounded review/fix cycle (≤2 review/fix + 1 final) applies per commit.

### 7.5 What I do NOT change (scope-deliverables-to-the-ask)
I do NOT re-sequence CB-01..CB-09 (the planner's bloat partition stands). I do NOT redesign the bloat METHOD (DESIGN-BD-243-BLOAT-METHOD.md is approved). I add the four gates + the dependency-correct insertion; the planner owns the final worktree-wave schedule.

---

## 8. OPEN RISKS / DECISIONS FOR THE USER

- **D-1 (Gate 2 activation precondition) — PLATFORM-SKILLS.md deferred catalog.** 22 `deferred` + 7 `future` hits, a census MISS (EE-G2-PLAT). The user must adjudicate: (i) STRIP the catalog to current-state-only (the deferred rows become a flat "skills created on demand" statement) — then Gate 2 FAIL-activates clean; or (ii) rule the forward-catalog a legitimate client reference and allowlist it — then Gate 2's allowlist carries a 29-record PLATFORM-SKILLS block. RECOMMENDATION: lean (i) (it is a client-facing deferred-feature advertisement, the exact axis BD-243 strips), but this is the user's call and it gates Gate 2 activation.
- **D-2 (Gate 2 FAIL vs WARN).** RECOMMEND FAIL-with-allowlist (anti-rot, matches Check 65), CONTINGENT on D-1. WARN is the degraded fallback if the user wants the recall report without a hard gate. The user's anti-rot ruling points at FAIL.
- **D-3 (Gate 4 home).** RECOMMEND a standalone Check 69 (one-concern-per-check) over folding into Check 59. Minor; the planner can fold if the user prefers fewer checks.
- **D-4 (Gate 1 parameter timing).** Gate 1's ceilings/cap are derived at CG-14-prep from the reduced tree — confirmed dependency. If the user wants Gate 1 to land EARLIER (before bloat reduction), it cannot be a FAIL gate (it would fail on today's bloated numbers); it could only be the existing advisory until the reduction lands. RECOMMEND keeping it FAIL at CG-14-prep.
- **R-1 (residual deferred residue).** The 100 `deferred` / 35 `planned` / 41 `future` hits are dominated by the four KEEP categories, but a few may need per-line adjudication during allowlist authoring (the JUDGMENT items in CENSUS §5). The coder sizes the allowlist EXACTLY at CG-14-prep; any unclassified hit is a BLOCKER surfaced to the user (never auto-allowlisted — the prohibited widen-to-admit move).

---

## 9. EMPIRICAL-EVIDENCE BLOCK (consolidated)

All measurements @ HEAD `103cca8` (`103cca8e51feef9c80e4e76be17bd0dd274d3a6b`), branch `v11-dev`, 2026-06-22, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, clean tree. Graph queried FIRST for discovery (`graphify query "validate-pack checks operating-doc enforcement gates" --graph .../graphify-out/graph.json --backend claude-cli --budget 2000`) → returned only test-script/IMPL-report orientation nodes (STALE for the BD-243-era enforcement surfaces, consistent with DESIGN/CENSUS EE-GRAPH) → G2 fallback to grep / `wc -l` / file read / `python3 validate-pack.py` IMMEDIATELY. The authoritative gate for every exact-state claim is the grep/read over the named surfaces. NOTE: `grep -r` with an explicit file-list argument silently under-counts; all counts use the `grep <flags> $(cat /tmp/bd243-in.txt)` inline-substitution form (verified against direct single-file greps).

- **EE-BASE** (§1) — registry count 63; next free check number 66; `_CHECK_65_OPERATING_DOCS = ()` (inert); full validate-pack green (exit 0). SUPPORTED.
- **EE-INSET** (§1) — operating-doc IN set = 135 files / 20,752 lines / 1,201,222 bytes (matches the design's ≈136). SUPPORTED.
- **EE-FAM** (§2) — family member counts (pack trinity 3, pack-ops 9, pack skills 11, pack agents 5, project trinity 3, project docs/pack 5, prompts 10, project skills 37, agent-def families 16×3, project stream-meta 4). SUPPORTED.
- **EE-G2** (§3 Gate 2) — deferred-marker counts over IN set: `deferred` 100, `future` 41, `planned` 35, `not yet` 16, `roadmap` 8, `v11.1` 6, `future version` 1, `once land/ship` 3; narrow promises (`will ship`/`coming soon`/`slated`/`not yet created`) = 0. SUPPORTED.
- **EE-G2-DIST** (§3 Gate 2) — `deferred` hits cluster: PLATFORM-SKILLS 22, trinity ×6 ≈30 (rule self-ref), coder-agent-def/impl-report/review ≈20 (live TD feature), the rest scattered KEEP. SUPPORTED.
- **EE-G2-PLAT** (§3 Gate 2) — PLATFORM-SKILLS.md 22 `deferred` + 7 `future` (a `### Deferred skills` section + `*(deferred)*`/`*(future)*` catalog rows); CENSUS §3 recorded "no deferred-feature mention found … coder VERIFIES" → a census MISS. SUPPORTED.
- **EE-G3-BARE** (§3 Gate 3) — 82 backtick basenames; 6 dangling, 5 KEEP (anchor-phrase/placeholder/grammar), 1 genuine STRIP (`feedback_review_fix_one_cycle.md` at CONCEPTUAL-REVIEW:186). SUPPORTED.
- **EE-G3-QUAL** (§3 Gate 3) — 104 qualified-path refs; 8 dangling, all KEEP (grammar/self-flagged/runtime-generated); the axis closes the deleted-doc (`pack-ops/HELP-FRAGMENT-TRACKER.md`-shape) blind spot the bare-ref `/`-exclusion misses. SUPPORTED.
- **EE-G4** (§3 Gate 4) — `_CHECK_65_OPERATING_DOCS = ()` is a hand-frozen tuple with no discovery; a new doc escapes silently. SUPPORTED.
- **EE-R2** (§4) — `incident` substring 9 hits vs `\bincident\b` 7; the 2-line delta = "coincidental" + "incidents" false-positives; the 7 whole-word = 6 rule-self-ref + 1 KEEP. SUPPORTED.
- **EE-TEST-CONV** (§6) — per-check tests follow `test-validate-pack-check-NN.sh`, monkeypatch `mod.REPO_ROOT` to a /tmp tree + the scope constant, 3 groups (constant / synthetic PASS-FAIL / e2e `--only-check NN`). Cmd: `grep -nE "REPO_ROOT|_CHECK_65_OPERATING_DOCS|--only-check" scripts/tests/test-validate-pack-check-65.sh`. Output: `saved_scope = mod._CHECK_65_OPERATING_DOCS`, `mod.REPO_ROOT = root`, `mod._CHECK_65_OPERATING_DOCS = (SYNTH_DOC,)`. SUPPORTED.
- **EE-COUNT-COMMENT** (§6) — the EXPECTED_COUNT comment block (validate-pack.py:464-496) documents per-BD +1 lock-step lines + the "number ≠ count" CAUTION. Cmd: `sed -n '464,496p' scripts/validate-pack.py`. Output: "+1 net-new BD-231 check (64 …)", "+1 net-new BD-243 check (65 …)", "CAUTION: a new check's NUMBER is the next free integer … this constant is the registry ENTRY COUNT — bump it +1 per net-new entry". SUPPORTED.

---

## 10. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only verbs run: `git rev-parse HEAD`/`git branch`/`git status --short` (snapshot), `wc`, `grep`, `sed`, `ls`, `find`, `cat`, `python3 scripts/validate-pack.py` (read-only validation), `graphify query` (read-only). Sole write = this design doc via `cat >>`/`cat >` to the caller-specified `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-DURABLE-GATES.md`. No repo-file edit; no patch; no `git add`/`commit`/`apply`/state-changing verb. | COMPLIANT |
| **reconciliation-instance-independence** | FRESH architect; did NOT author any prior BD-243 artifact (DESIGN-FINAL/-V2/-METHOD, CENSUS, PLAN-V1/-V2). Reached own conclusions: the auto-discover-minus-EXEMPT + meta-check scope model (§2/§5, my synthesis); the hybrid Gate-1 (1a ceiling-FAIL + 1b bullet-cap, §3); INDEPENDENTLY re-measured every gate's flag set and FOUND the PLATFORM-SKILLS census MISS (EE-G2-PLAT, contradicting CENSUS §3) and the genuine `feedback_review_fix_one_cycle.md` dangling ref (EE-G3-BARE). Folded the user-decided R2 tightening without relitigating. | COMPLIANT |
| **ci-guard design — measure-then-bound** | EVERY gate measured-then-bound: Gate 1 parameters DERIVED FROM the post-reduction tree (deferred to CG-14-prep, the dependency flagged); Gate 2 allowlist sized to the 4 measured KEEP categories (EE-G2/DIST/PLAT) with PLATFORM-SKILLS surfaced as unclassified-not-auto-admitted; Gate 3 allowlist sized to the 13 measured KEEP refs with the 1 genuine STRIP fixed (EE-G3-BARE/QUAL); Gate 4 EXEMPT sized to the measured orientation/output set. NO allowlist widened to admit an unclassified hit — PLATFORM-SKILLS + the dangling ref are surfaced as adjudication/fix, not admitted by default. Each gate's clean-against-projected-post-fix-state is stated. | COMPLIANT |
| **empirical-evidence-blocks** | Every state-claim backed by EE-BASE/INSET/FAM/G2/G2-DIST/G2-PLAT/G3-BARE/G3-QUAL/G4/R2/TEST-CONV/COUNT-COMMENT: command + verbatim output (counts/paths/quotes) + HEAD `103cca8` + 2026-06-22 + interpretation + SUPPORTED. Counts via the verified `grep $(cat …)` inline form; constants via `sed`/`grep` of validate-pack.py; structure via `ls`/`wc`. | COMPLIANT |
| **ci-check-runtime-compounding** | Each gate's cost stated: G1a reuses Check-44's read (+0 I/O); G1b reads 5 bullet files once; G2 one alternation-scan per IN line (shares Check-65's read); G3 reuses Check-40's once-built basename index (near-free); G4 reads NO file bodies (path glob + set arithmetic). NO whole-tree-scan-per-entry; NO subprocess storm. All bounded to the IN set / a small fixed file set, ×~155 invocations safe. | COMPLIANT |
| **enumerate-encoding-surfaces** | §6 rollup enumerates per gate: check body + constants + allowlist file + test file + registry entry + EXPECTED_COUNT bump + comment-block line + Check 59/60 auto-assertion; net registry impact +4 (63→67) with the number-vs-count CAUTION quoted (EE-COUNT-COMMENT). The shared `_iter_operating_docs()` + EXEMPT constant are called out as single-surface to prevent drift. | COMPLIANT |
| **user prescriptive authority** | The user mandated the 4 gates + durable enforcement of the BD-243 axes + the R2 tightening (decided). Encoded, not relitigated: R2 folded as a confirmed calibration (§4); the gates designed to the user's "cannot silently rot" + "volume only, never meaning" constraints. Open user decisions surfaced (§8 D-1..D-4) rather than self-decided. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered exactly the 4 gates (identity / catches / scope / allowlist / FAIL-vs-WARN / false-positive strategy / encoding surfaces / runtime cost each) + the R2 fold + the insertion recommendation (§7). Did NOT re-sequence CB-01..CB-09 (named the dependency-correct order; left wave-scheduling to the planner) nor redesign the bloat method (approved). | COMPLIANT |
| **graph-first-context** | Discovery: graph queried FIRST via the injected absolute path (`--graph /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json --backend claude-cli --budget 2000`); returned STALE orientation nodes for BD-243-era surfaces → G2 fallback to grep/Read IMMEDIATELY (no block). Authoritative measurements via grep/`wc`/read over the named surfaces. Did not recompute the graph path from own toplevel. | COMPLIANT |
| **rules-applied-verification-block** | This table — every rule in the prompt's Rules-in-force block has measured/quoted evidence + a terminal COMPLIANT conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

**END — DESIGN-BD-243-DURABLE-GATES.md**
