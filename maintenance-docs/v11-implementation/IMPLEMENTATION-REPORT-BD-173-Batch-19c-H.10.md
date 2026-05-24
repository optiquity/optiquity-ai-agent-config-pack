# IMPLEMENTATION REPORT — BD-173 Batch 19c.H.10 (Leak sweep Cat D + E + F + audit-gap absorption)

**Branch:** v11-dev
**HEAD at start:** `1121b3d37be6eec888d40fca2c15558810859767`
**HEAD at PREFLIGHT:** `1121b3d37be6eec888d40fca2c15558810859767` (no commits made; agent never commits)
**Author:** pack-coder (sub-agent spawn — initial 8-leak pass + audit-gap fix-coder follow-up absorption + 19th-leak small fix-coder absorption pass)
**Date:** 2026-05-23
**Commit subject (proposed):** `feat: v11 — BD-173 leak sweep Categories D + E + F + bare-version audit-gap sweep — mechanical cite cleanup + BD-175 self-leak fix (Batch 19c.10)`

---

## §1 — Scope

- **Files modified:** 7 (audit-spec in-scope files)
- **Categories applied:** D (3 leaks), E (4 leaks), F (1 leak) + audit-vocabulary-gap Cat A drops (19 leaks)
- **Total leaks closed:** 27 (8 audit-specified + 19 audit-gap)
- **Manifest:** `test-fixtures/manifest.txt` rebuilt (3 v11-* row drift; rebuilt three times — once after H.10 8-leak pass, once after audit-gap 18-leak absorption, once after 19th-leak small fix-coder absorption); staged-by-Pack-Chat-not-by-coder per pack memory `feedback_manifest_regen_on_v11_surface`
- **Out-of-scope file edits:** none
- **New POQs / audit-vocabulary-gap discoveries:** 18 closed by Pack Chat (A) triage decision via audit-gap fix-coder pass; 1 additional NEW discovery (19th audit-gap leak in `scripts/lib/detect.sh:22`) closed by Pack Chat (A) triage decision via small fix-coder absorption pass (§7.4 disposition: CLOSED — absorbed into H.10 commit)
- **Pack Chat (A) triage rationale:** the 18 audit-gap leaks live in the same 5 files H.10 already touched, share the same fix-shape (Cat A drop), and the trinity Filename uniqueness rule update at commit `1121b3d` (2026-05-22) formally classifies bare-version shorthand (`V3.3 §X.Y` / `V3 §28.1.X`) as a leak under the rule's spirit. Strong logical-fit per `feedback-deferral-is-scope-creep` "concrete same-file/same-contract fit." Same absorption pattern as the H.9 audit-gap absorption that landed at `3a3de64`. The 19th audit-gap leak (detect.sh L22, `V3 §28.2.3`) shares the same audit-gap class, lives in a file H.10 already touches, and follows the same Cat A drop pattern — Pack Chat (A) chose Option A (absorb into this commit) per the implementer-side recommendation in original §7.4.

### 1.1 Files-touched inventory

| File | Cat | Leaks closed | Change |
|---|---|---|---|
| `scripts/lib/detect.sh` | D + audit-gap A | 2 (D; L334-335, L677-678 pre-edit) + 1 (audit-gap; L22 pre-edit, `V3 §28.2.3`) | modified |
| `project-template/docs/pack/PM-CHAT.md` | D + audit-gap A | 1 (D) + 10 (audit-gap; L544, L552, L569, L579, L601-602, L615 [dual cite], L634, L639 pre-edit) | modified |
| `project-template/skills/pm-startup/SKILL.md` | E + audit-gap A | 1 (E) + 2 (audit-gap; L214, L249 pre-edit) | modified |
| `project-template/.claude/skills/pm-startup/SKILL.md` | E + audit-gap A | 1 (E) + 2 (audit-gap; L214, L249 pre-edit) | modified |
| `project-template/.codex/skills/pm-startup/SKILL.md` | E + audit-gap A | 1 (E) + 2 (audit-gap; L214, L249 pre-edit) | modified |
| `project-template/.gemini/commands/pm-startup.toml` | E + audit-gap A | 1 (E) + 2 (audit-gap; L211, L246 pre-edit, inside TOML triple-quoted string) | modified |
| `project-template/skills/boundary-investigation/SKILL.md` | F | 1 (L124 pre-edit) | modified |
| `test-fixtures/manifest.txt` | — | — | modified (regen post-19th-leak absorption; 3 v11-* row drift; NOT staged — agent never stages) |

**27-site total:**
- 8 audit-specified (Cat D × 3 + Cat E × 4 + Cat F × 1)
- 19 audit-gap Cat A drops:
  - PM-CHAT.md: 9 bare-version `V3.3 §X.Y` cites + 1 `IMPLEMENTATION-PLAN-ADDENDUM-4 §6.P` cite = 10
  - pm-startup cluster (4 files × 2 sites): 8 bare-version `V3 §28.1.X` cites
  - detect.sh L22: 1 bare-version `V3 §28.2.3` cite (absorbed via 19th-leak small fix-coder pass)

### 1.2 `git diff --stat` summary (full 27-site sweep)

```
 project-template/.claude/skills/pm-startup/SKILL.md     | 10 +++------
 project-template/.codex/skills/pm-startup/SKILL.md      | 10 +++------
 project-template/.gemini/commands/pm-startup.toml       | 10 +++------
 project-template/docs/pack/PM-CHAT.md                   | 26 ++++++++++------------
 project-template/skills/boundary-investigation/SKILL.md |  2 +-
 project-template/skills/pm-startup/SKILL.md             | 10 +++------
 scripts/lib/detect.sh                                   |  8 +++----
 test-fixtures/manifest.txt                              |  6 ++---
 8 files changed, 31 insertions(+), 51 deletions(-)
```

Line-delta growth (51 deletions; 31 insertions) reflects the 19 audit-gap Cat A drops + 8 audit-specified D/E/F edits (mostly inline cite excisions; a few rewrites preserve sentence flow; detect.sh now 8 +/-- after the 19th-leak L22 absorption adds +1 line to the original 6 +/-- from the H.10 8-leak pass).

---

## §2 — Edits applied

### 2.1 Cat D — Drop cite entirely (3 leaks)

#### 2.1.1 `scripts/lib/detect.sh` (Cat D leak 1 — L334-335 pre-edit)

**BEFORE:**

```
# Markers (any one true → yes), per architecture §7.5
# (maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md):
#   (a) requirements.txt OR pyproject.toml OR setup.py OR setup.cfg
```

**AFTER:**

```
# Markers (any one true → yes):
#   (a) requirements.txt OR pyproject.toml OR setup.py OR setup.cfg
```

**Rationale:** Per PLAN H.10 step 1 + leak-sweep-strategy §1.4 ("drop the cite entirely; bare prose stands"). The reference to "per architecture §7.5" was footnote-style provenance — a client agent inspecting `detect.sh` cannot resolve the `maintenance-docs/` cite. Deletion preserves the `# Markers (any one true → yes):` header introducing the markers (a)/(b)/(c) below — the comment is self-sufficient.

#### 2.1.2 `scripts/lib/detect.sh` (Cat D leak 2 — L677-678 pre-edit)

**BEFORE:**

```
# Markers (any one true → yes), per architecture §4.2 of
# maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md:
#   (a) Dependency manifests (requirements.txt OR pyproject.toml OR
```

**AFTER:**

```
# Markers (any one true → yes):
#   (a) Dependency manifests (requirements.txt OR pyproject.toml OR
```

**Rationale:** Same fix-shape as 2.1.1; same rationale.

#### 2.1.3 `project-template/docs/pack/PM-CHAT.md` (Cat D leak 3 — L535-537 pre-edit; audit cited L410)

**BEFORE:**

```
When a TD-NNN becomes Unblocked (per METHODOLOGY § Part 7 Procedure 1
step 3), the PM Chat advises one of three outcomes per
ARCHITECTURE-V3.3-DELTA.md §3.1:
```

**AFTER:**

```
When a TD-NNN becomes Unblocked (per METHODOLOGY § Part 7 Procedure 1
step 3), the PM Chat advises one of three outcomes:
```

**Rationale:** Per PLAN H.10 step 3 — delete the cite phrase. The surrounding prose reads cleanly: "the PM Chat advises one of three outcomes:" → table below enumerates the outcomes inline. No descriptive replacement needed; the table is the SSOT for the three outcomes at client install.

**Line-drift note:** audit `9da98a4` cited L410; cite drifted to L537 at HEAD `1121b3d` (intervening commits added Profile-assignment table at L407-462 etc.). The cite is unambiguous (one match in the file). Verified via `grep -n "ARCHITECTURE-V3.3-DELTA"` — 1 hit on L537.

### 2.2 Cat E — pm-startup cluster sibling sweep (4 leaks)

The 4 cluster files share a 3-line `Reference: ARCHITECTURE-V3.md §28.1.5 ...` tail at the end of the recommendation-routing prose. Per leak-sweep-strategy §1.5 recommendation (Cat D shape applied to a cluster), drop the cite tail across all 4 files byte-identically. The .toml file has the cite inside a TOML triple-quoted string; deletion leaves the closing `"""` on its own line — TOML still parses (`python3 -c "import tomllib; tomllib.load(...)"` verified PASS).

#### 2.2.1 `project-template/skills/pm-startup/SKILL.md` (canonical, L258-260 pre-edit)

**BEFORE (lines 257-260):**

```
  and acknowledge.

Reference: ARCHITECTURE-V3.md §28.1.5 (should-recommend test),
§28.1.6 (refusal-respecting state machine), §28.1.7 (prompt shape
and routing), §28.1.9 (implementation surfaces).
```

**AFTER (lines 257-256 → file ends after `acknowledge.`):**

```
  and acknowledge.
```

Lines 258-260 deleted. The preceding blank line L257 was also deleted (4 lines removed total; aligned with the `git diff --stat` 4-line removal). EOF after `acknowledge.`.

#### 2.2.2 `project-template/.claude/skills/pm-startup/SKILL.md` (L258-260 pre-edit)

Same BEFORE/AFTER as 2.2.1 (byte-identical to canonical). Mirror cluster file.

#### 2.2.3 `project-template/.codex/skills/pm-startup/SKILL.md` (L258-260 pre-edit)

Same BEFORE/AFTER as 2.2.1 (byte-identical to canonical). Mirror cluster file.

#### 2.2.4 `project-template/.gemini/commands/pm-startup.toml` (L255-257 pre-edit)

**BEFORE (lines 253-258):**

```
  and acknowledge.

Reference: ARCHITECTURE-V3.md §28.1.5 (should-recommend test),
§28.1.6 (refusal-respecting state machine), §28.1.7 (prompt shape
and routing), §28.1.9 (implementation surfaces).
"""
```

**AFTER (lines 253-254):**

```
  and acknowledge.
"""
```

Lines 255-257 deleted (3 cite-content lines) AND the preceding blank L254 deleted (4 lines total — matches .md cluster sibling deletion). The closing `"""` on L258 remained.

**TOML parse verified post-edit:** `python3 -c "import tomllib; tomllib.load(open('.../pm-startup.toml', 'rb'))"` → "TOML parse OK".

#### 2.2.5 Cluster sync verification

- `diff <(grep -v "ARCHITECTURE" canonical SKILL.md) <(grep -v "ARCHITECTURE" .claude SKILL.md)` → no diff. PASS.
- `diff canonical-SKILL.md .codex-SKILL.md` → byte-identical (full file). PASS.
- The .gemini TOML is structurally byte-equivalent to .md siblings at the cite-removed site (content surrounding the cite identical; only the wrapping TOML syntax differs at file head + tail per pack-shipped distribution pattern).

### 2.3 Cat F — BD-175 self-leak (1 leak)

#### 2.3.1 `project-template/skills/boundary-investigation/SKILL.md` (L124 pre-edit)

**BEFORE:**

```
- **Files exempt at pack root:** `tracker.toml.pack-example` (STAYS at
  pack root per AUDIT-USER-CURATION.md Override 1; not installed at
  client; bare-filename refs from project-side qualified by "in the
  pack repo" are LEGITIMATE distinction-callouts)
```

**AFTER:**

```
- **Files exempt at pack root:** `tracker.toml.pack-example` (STAYS at
  pack root per pack-repo audit finding; not installed at
  client; bare-filename refs from project-side qualified by "in the
  pack repo" are LEGITIMATE distinction-callouts)
```

**Substitution prose:** `AUDIT-USER-CURATION.md Override 1` → `pack-repo audit finding`.

**Substitution rationale:** Per V2 §B.2 Cat F + PLAN H.10 step 5: replace `AUDIT-USER-CURATION.md Override 1` (pack-internal doc + cite) with descriptive prose that conveys the SAME meaning — that `tracker.toml.pack-example` STAYS at pack root because a pack-repo audit determined it should — without naming a specific pack-internal doc.

The new prose is intentionally minimal:
- Preserves "STAYS at pack root" (the rule statement).
- Preserves "not installed at client" (the operative client-facing fact).
- Replaces the pack-internal cite with "pack-repo audit finding" — a class-name reference that resolves to "there exists an authoritative finding in the pack repo; if you (a client team) need to know more, this is a pack-repo concern, not a client concern."
- The original cite served instructional provenance for pack maintainers reading the skill at pack root; the replacement is honest about the rationale's provenance without naming a specific pack-internal target.

This is the SAME pattern the audit's §4.3 cross-cutting recommendation suggested for the per-entry skeleton ARCHITECTURE-* cites: "a generic, non-resolvable cite is honest about its non-resolvability without naming specific files."

**No new leak introduced:** the replacement prose does NOT name any pack-internal file (`maintenance-docs/`, `pack-ops/`, other audit doc, etc.). Verified via targeted boundary grep — no matches for `AUDIT-*`, `ARCHITECTURE-*.md`, `maintenance-docs/` resolution in the new prose.

### 2.4 Audit-gap Cat A drops — bare-version shorthand (18 leaks)

Per Pack Chat (A) triage decision (2026-05-23): absorb the 18 audit-vocabulary-gap leaks discovered during the H.10 initial pass into the same commit. Rationale per pack memory `feedback-deferral-is-scope-creep` "concrete same-file/same-contract fit" — the 18 leaks live in the same 5 files H.10 already touched, share the same fix-shape (Cat A drop), and the trinity Filename uniqueness rule update (commit `1121b3d`, 2026-05-22) formally classifies bare-version shorthand (`V3.3 §X.Y` / `V3 §28.1.X`) as a leak under the rule's spirit. Same absorption pattern as the H.9 audit-gap absorption that landed at `3a3de64`.

#### 2.4.1 `project-template/docs/pack/PM-CHAT.md` (10 leaks)

**Leak 1 — L544 (pre-edit):**

BEFORE:
```
**Path 3 is forbidden** per V3.3 §1 supersession + §3 line 27. There
is no `--fold-into` verb and no `folded-into:` label.
```

AFTER:
```
**Path 3 is forbidden.** There
is no `--fold-into` verb and no `folded-into:` label.
```

Rationale: drop bare-version cite phrase; surrounding rule prose stands. The rule "Path 3 is forbidden" is self-stating; the prior cite "per V3.3 §1 supersession + §3 line 27" was footnote-style provenance unresolvable at client install.

**Leak 2 — L552 (pre-edit):**

BEFORE: `### Advisory heuristic (V3.3 §7.1)`
AFTER:  `### Advisory heuristic`

Rationale: drop section-header parenthetical version tag; bare heading stands.

**Leak 3 — L569 (pre-edit):**

BEFORE:
```
PM Chat **advises**; the user can confirm or override. Presentation
shape (V3.3 §7.1):
```

AFTER:
```
PM Chat **advises**; the user can confirm or override. Presentation
shape:
```

Rationale: drop parenthetical cite; the colon-terminated phrase still introduces the example block below.

**Leak 4 — L579 (pre-edit):**

BEFORE: `### Execution workflow (V3.3 §7.2)`
AFTER:  `### Execution workflow`

Rationale: same as Leak 2 (section-header version tag drop).

**Leaks 5-6 — L601-602 (pre-edit; two adjacent V3.3 §3.4 refs):**

BEFORE:
```
6. On user approval, writes IMPLEMENTATION-PLAN.md and (in tracker
   mode) creates the tracker entity per V3.3 §3.4. Re-keys the TD
   per V3.3 §3.4. For each `Dependencies` bullet entry on the new
   task, calls `tracker_links_create_blocked_by` (BD-108) to wire
   the cross-entity dependency edge.
```

AFTER:
```
6. On user approval, writes IMPLEMENTATION-PLAN.md and (in tracker
   mode) creates the tracker entity. Re-keys the TD. For each
   `Dependencies` bullet entry on the new task, calls
   `tracker_links_create_blocked_by` (BD-108) to wire the
   cross-entity dependency edge.
```

Rationale: drop both bare-version cites; rewrite mid-sentence flow to preserve readability. The numbered step's instructions are self-stating; no client-resolvable target the cites pointed to.

**Leak 7 — L615 (pre-edit; dual cite — bare-version V3.3 §7.2 + explicit IMPLEMENTATION-PLAN-ADDENDUM-4 §6.P):**

BEFORE:
```
**Path 1 (`pack td promote --to=phase-N`).** PM Chat invokes the
**architect** (project-side `architect.md` agent) **by default** per
V3.3 §7.2 and IMPLEMENTATION-PLAN-ADDENDUM-4 §6.P resolution (a) for
two reasons:
```

AFTER:
```
**Path 1 (`pack td promote --to=phase-N`).** PM Chat invokes the
**architect** (project-side `architect.md` agent) **by default** for
two reasons:
```

Rationale: this is the explicit-doc-cite mentioned in the prompt's scope description. Drop both the bare-version `V3.3 §7.2` AND the explicit `IMPLEMENTATION-PLAN-ADDENDUM-4 §6.P resolution (a)` cite phrase entirely; the "two reasons" introduction still works without provenance, and the two reasons enumerated below stand on their own. NOTE: this fix closes the `IMPLEMENTATION-PLAN-ADDENDUM-4` audit-gap leak class — that file is a pack-internal architect doc; the cite was unresolvable at client install. Same Cat A drop pattern.

**Leak 8 — L634 (pre-edit):**

BEFORE: `### Verb shape (V3.3 §7.3)`
AFTER:  `### Verb shape`

Rationale: same as Leak 2 / Leak 4 (section-header version tag drop).

**Leak 9 — L639 (pre-edit):**

BEFORE: `pack td resolve <td-id> [--note "..."] # Direct close (V3.3 §3.2)`
AFTER:  `pack td resolve <td-id> [--note "..."] # Direct close`

Rationale: drop the inline-code-comment parenthetical version tag; the comment still names the verb's purpose ("Direct close"). Inside a bash code fence, so the edit preserves syntactic shape (still a comment).

**Leak 10 — counts as part of Leak 7 dual cite** — see L615 description above. Total: 10 leaks across PM-CHAT.md.

#### 2.4.2 pm-startup cluster (4 files × 2 sites = 8 leaks)

The 4 cluster files (canonical `.md` + `.claude/` mirror + `.codex/` mirror + `.gemini/.toml` mirror) share two identical bare-version cite sites:
- Site 1: HTML comment block "Step 7 is reserved..." (L211 of .md; L208 of .toml) — phrase `is fixed by V3 §28.1.9 to keep the recommendation check at the` reworded to `is fixed to keep the recommendation check at the`
- Site 2: Routing instruction "Then route the user's response per V3 §28.1.7:" (L249 of .md; L246 of .toml) — phrase `per V3 §28.1.7` dropped; colon retained

**Identical edit applied byte-identically across all 4 cluster files** to preserve the cluster-sync invariant (canonical SKILL.md == .claude SKILL.md == .codex SKILL.md byte-identical; .gemini .toml structurally equivalent inside the TOML triple-quoted string wrapping the prompt body).

##### 2.4.2.a Site 1 — Step 7 reserved comment (HTML block)

BEFORE (in all 4 cluster files):
```
<!--
Step 7 is reserved. The V1 §10.2 tracker-mode triage queue
(provider.list filter=label:'needs-triage') lands here in a later
BD when tracker mode is wired into pm-startup. The Step 8 numbering
is fixed by V3 §28.1.9 to keep the recommendation check at the
documented insertion point regardless of when Step 7 lands.
-->
```

AFTER (in all 4 cluster files):
```
<!--
Step 7 is reserved. The V1 §10.2 tracker-mode triage queue
(provider.list filter=label:'needs-triage') lands here in a later
BD when tracker mode is wired into pm-startup. The Step 8 numbering
is fixed to keep the recommendation check at the documented
insertion point regardless of when Step 7 lands.
-->
```

Rationale: drop bare-version `by V3 §28.1.9` phrase, contracting "is fixed by V3 §28.1.9 to keep ... at the documented insertion point" → "is fixed to keep ... at the documented insertion point". Surrounding HTML comment block preserved; rule meaning preserved. Note: the bare-version `V1 §10.2` reference also exists in this comment block but is LEGITIMATE (V1 references the project-side context file, not a pack-internal architect doc; per audit §1 vocabulary, V1 cites resolve to the project-template trinity file `# V1 §8.4` form documented in PLATFORM-SKILLS.md style — these are NOT in audit-gap leak class).

##### 2.4.2.b Site 2 — Recommendation routing instruction

BEFORE (in all 4 cluster files):
```
Then route the user's response per V3 §28.1.7:
```

AFTER (in all 4 cluster files):
```
Then route the user's response:
```

Rationale: drop parenthetical cite; colon preserved (introduces the bulleted response list below).

##### 2.4.2.c Cluster sync verification post-audit-gap pass

```
diff project-template/skills/pm-startup/SKILL.md project-template/.claude/skills/pm-startup/SKILL.md
diff project-template/skills/pm-startup/SKILL.md project-template/.codex/skills/pm-startup/SKILL.md
```

Result: BYTE-IDENTICAL across canonical / .claude / .codex `.md` siblings. The `.gemini/commands/pm-startup.toml` is byte-equivalent inside the TOML triple-quoted string wrapping the prompt body (only the wrapping TOML syntax differs at file head + tail per pack-shipped distribution pattern). TOML parse re-verified post-edit: PASS.

#### 2.4.3 `scripts/lib/detect.sh` L22 (19th audit-gap leak; absorbed via small fix-coder pass)

**BEFORE:**

```
# Per V3 §28.2.3 surface routing (post BD-175 directory reorganization):
```

**AFTER:**

```
# Surface routing (post BD-175 directory reorganization):
```

Rationale: drop the bare-version `Per V3 §28.2.3 ` prefix and capitalize the next word ("Surface"). Preserve the "(post BD-175 directory reorganization)" parenthetical and the trailing colon. Same Cat A drop pattern as the 18 audit-gap leaks in §2.4.1 / §2.4.2.

This 19th leak was discovered DURING the audit-gap fix-coder pass's extended boundary grep verification (§3.4.b) and flagged in original §7.4 for Pack Chat triage. Pack Chat (A) triage decision (2026-05-23): **Option A — absorb into the H.10 commit**. Rationale per the original §7.4 implementer-side recommendation: same audit-gap class, same fix-shape, same touched-file (detect.sh was already in-scope for Cat D fixes at L334-335 + L677-678). The cost is one Edit + one rebuild; the benefit is closing the audit-gap class completely in the touched-file scope.

#### 2.4.4 Audit-gap absorption rationale summary

Per Pack Chat (A) triage:
- **SIZE:** 19 cite drops across 6 files = small-to-medium mechanical sweep (not architect-pass material).
- **BLOCKED:** UNBLOCKED today (no dependency on later H.* commit).
- **LOGICAL FIT:** STRONG — same 6 files H.10 already touches; same fix-shape (Cat A drop or short rewrite); the trinity Filename uniqueness rule update at `1121b3d` formally classifies this class as leak under the rule's spirit.
- **Cluster-sync invariant preserved:** 4 cluster files byte-identical post-edit.
- **No new leak introduced:** boundary grep (extended vocabulary) clean in all 6 audit-gap files post-19th-leak absorption.

This absorption decision was Pack Chat's call (the implementer-side recommendation flagged in original §7.2 surfaced 3 options A/B/C for the 18; Pack Chat chose Option B + the audit-gap fix-coder pass; then the original §7.4 surfaced 3 options A/B/C for the 19th leak; Pack Chat chose Option A + the small fix-coder absorption pass). Documented per `feedback-user-prescriptive-authority` — Pack Chat orchestrates; the fix-coder agents execute.

---

## §3 — Verification

### 3.1 validate-pack.py

```
python3 scripts/validate-pack.py
```

**Result:** PASS — all checks clean.

Final 9 checks summary:
- Check 35 OK: comment-only `folded-into` references allowed
- Check 36 OK: 1 scope-claiming commit verified clean; 0 implicit
- Check 37 OK: 146 project-side files walked; zero deny-list contamination
- Check 38 OK: 1 pack-root prose file checked; no mis-sited content
- Check 39 OK: 6 cmd_update mappings forward-verified; 35 reverse-resolved; no drift
- Check 40 OK: 9 pack-ops/*.md walked; zero unqualified bare cross-refs
- Check 41 OK: 38 `_CLIENT_INSTALLED_FILES` entries resolve; 35 cmd_update paths checked; 0 drift
- Check 42 OK: 9 per-check tests / 9 workflow invocations; zero unwired tests

### 3.2 Fixture build

```
bash test-fixtures/build.sh --all --clean
```

**Result:** PASS — all 6 fixtures rebuilt cleanly.

- v10-minimal `19558cbac58ed3e47642a6bbe64418a38c60bc16` (tag-pinned; unchanged)
- v10-realistic-ot `4c62945f72b037908b38967d5d8f019745263258` (tag-pinned; unchanged)
- v11-realistic-ot `73ddb5a1e24cbd3647ad33290fb6d3f056844561` (drift from `214a4d5...`)
- v11-flat-file `b8a0f00786e7e8f0660627887e4598b5d93cfd00` (drift from `2a9d538...`)
- v11-tracker-on `f53736cc98754c72e9c1dca96bb2f1fe3c76b18f` (drift from `ea6b5e6...`)
- existing-project-mid-dev `a54e081a9e1d04f293bfb38fa0af77fd9f7f8619` (synthesized; unchanged)

### 3.3 Manifest diff (post-19th-leak absorption pass)

```
git diff test-fixtures/manifest.txt
```

**Result:** 3 v11-* row drift, as expected (regenerated three times — once after the H.10 8-leak pass, once after the audit-gap 18-leak absorption, once after the 19th-leak small fix-coder absorption pass; the v11-* SHAs at the third regen reflect the combined 27-site sweep).

```
-v11-realistic-ot  214a4d5c5399943c2c6c563424f5be3c6b8a3e27
-v11-flat-file  2a9d5381b564cd067a8bb7d97d11f68ca5f99d08
-v11-tracker-on  ea6b5e68d0507ca10646e3a531040caeda791c65
+v11-realistic-ot  8595cea270e77ee68ec8ce4cf585c9004118d5c6
+v11-flat-file  1968349c22598ce11496b6f49c11e3c94238f7e1
+v11-tracker-on  88e8585d7e03bcd017baa2f8cc03c0f0f21f82db
```

Drift expected because H.10 (combined) touched both `scripts/lib/detect.sh` (v11-surface per pack memory `feedback_manifest_regen_on_v11_surface`) and `project-template/` content (v11-surface). The manifest is staged-and-committed by Pack Chat alongside the combined 27-site scope edits per the rule.

### 3.4 Boundary verification (extended vocabulary — Cat D/E/F + audit-gap bare-version)

#### 3.4.a Targeted Cat D/E/F grep (8 audit-specified leaks)

```
grep -nE "AUDIT-USER-CURATION|ARCHITECTURE-V3\.md|ARCHITECTURE-V3\.3-DELTA|maintenance-docs/v11-implementation/ARCHITECTURE" \
  scripts/lib/detect.sh \
  project-template/docs/pack/PM-CHAT.md \
  project-template/skills/pm-startup/SKILL.md \
  project-template/.claude/skills/pm-startup/SKILL.md \
  project-template/.codex/skills/pm-startup/SKILL.md \
  project-template/.gemini/commands/pm-startup.toml \
  project-template/skills/boundary-investigation/SKILL.md \
  || echo "BOUNDARY OK — all 8 Cat D/E/F leaks cleared"
```

**Result:** `BOUNDARY OK — all 8 Cat D/E/F leaks cleared`.

#### 3.4.b Extended audit-gap vocabulary grep (post-19th-leak absorption — 19 audit-gap leaks)

```
grep -nE "maintenance-docs/|ARCHITECTURE-V3\.md|ARCHITECTURE-V3\.3-DELTA|ARCHITECTURE-V11-|AUDIT-USER-CURATION|RESEARCH-|V3\.[0-9]+ §|V3 §28\.|IMPLEMENTATION-PLAN-ADDENDUM" \
  scripts/lib/detect.sh \
  project-template/docs/pack/PM-CHAT.md \
  project-template/skills/pm-startup/SKILL.md \
  project-template/.claude/skills/pm-startup/SKILL.md \
  project-template/.codex/skills/pm-startup/SKILL.md \
  project-template/.gemini/commands/pm-startup.toml \
  project-template/skills/boundary-investigation/SKILL.md \
  || echo "BOUNDARY OK — no pack-internal cites or bare-version shorthand remain in touched files"
```

**Result (post-19th-leak absorption):** 4 hits, ALL classified LEGITIMATE; ZERO audit-gap leaks remain in any of the 6 audit-gap files (PM-CHAT.md + pm-startup cluster × 4 + detect.sh):

```
project-template/skills/boundary-investigation/SKILL.md:19:root), `pack-ops/` (any file there), `maintenance-docs/`, `scripts/`,
project-template/skills/boundary-investigation/SKILL.md:27:/ etc. agent roster, `pack-ops/` operational docs, `maintenance-docs/`
project-template/skills/boundary-investigation/SKILL.md:105:- **Path prefixes:** `maintenance-docs/`, `pack-ops/` (any file there —
project-template/skills/boundary-investigation/SKILL.md:152:  `maintenance-docs/`).
```

Classification:
- **4 hits on `boundary-investigation/SKILL.md` (L19, L27, L105, L152):** PRE-EXISTING LEGITIMATE deny-list teaching content. Audit §1.7 classified these LEGITIMATE; Check 37's whole-file exemption permits them. Unchanged.
- **`scripts/lib/detect.sh:22` hit ELIMINATED:** the 19th audit-gap leak (`# Per V3 §28.2.3 surface routing ...`) was flagged in original §7.4 and absorbed via Pack Chat (A) triage Option A. The grep post-absorption returns ZERO audit-gap leaks anywhere in the 6 audit-gap files.

**All 19 audit-gap sites enumerated (18 original + 19th absorbed via small fix-coder pass) are CLEARED in the 6 audit-gap files.** No further audit-gap discoveries.

#### 3.4.c Targeted post-19th-leak boundary grep on `scripts/lib/detect.sh` only

Per 19th-leak small fix-coder prompt's extended boundary verification step:

```
grep -nE "maintenance-docs/|ARCHITECTURE-V3\.md|ARCHITECTURE-V3\.3-DELTA|ARCHITECTURE-V11-|AUDIT-USER-CURATION|RESEARCH-|V3\.[0-9]+ §|V3 §28\.|V3 §3 |IMPLEMENTATION-PLAN-ADDENDUM" scripts/lib/detect.sh || echo "BOUNDARY OK — detect.sh clean"
```

**Result:** `BOUNDARY OK — detect.sh clean`.

The detect.sh file is now clean of all pack-internal architect cites (Cat D L334-335 + L677-678 + 19th-leak Cat A L22 absorption combined) and bare-version shorthand. The script comment at L22 now reads as bare descriptive prose ("# Surface routing (post BD-175 directory reorganization):") — self-stating, no client-resolvable cite required.

### 3.5 pm-startup cluster sync check (post-audit-gap pass)

```
diff <(grep -v "V3 §28" project-template/skills/pm-startup/SKILL.md) \
     <(grep -v "V3 §28" project-template/.claude/skills/pm-startup/SKILL.md) \
  && echo "cluster sync OK (canonical == .claude with V3 §28 filtered)"
```

**Result:** `cluster sync OK (canonical == .claude with V3 §28 filtered)`.

Stronger byte-identity check (verifies the cluster sibling .md files are now BYTE-IDENTICAL post-audit-gap pass, since all `V3 §28.*` cites were dropped identically across all three .md files):

```
diff project-template/skills/pm-startup/SKILL.md project-template/.claude/skills/pm-startup/SKILL.md && echo "canonical == .claude: BYTE-IDENTICAL"
diff project-template/skills/pm-startup/SKILL.md project-template/.codex/skills/pm-startup/SKILL.md && echo "canonical == .codex: BYTE-IDENTICAL"
```

**Result:**
```
canonical == .claude: BYTE-IDENTICAL
canonical == .codex: BYTE-IDENTICAL
```

All three cluster .md siblings are byte-identical. The .gemini/commands/pm-startup.toml retains its TOML wrapping syntax at head + tail per pack-shipped distribution pattern; the content inside the triple-quoted string matches the .md siblings.

### 3.6 TOML parse verification

```
python3 -c "import tomllib; tomllib.load(open('.../pm-startup.toml', 'rb')); print('TOML parse OK')"
```

**Result:** `TOML parse OK`. The cite removal inside the TOML triple-quoted string did not break TOML syntax.

### 3.7 Verification summary (post-19th-leak absorption)

| Check | Result |
|---|---|
| validate-pack.py | PASS — all checks clean (43 checks; final 9 listed in §3.1) |
| Fixture build (`build.sh --all --clean`) | PASS — 6 fixtures rebuilt (manifest regenerated post-19th-leak absorption pass) |
| Manifest diff non-empty (v11-surface) | YES — 3 v11-* rows drifted (combined 27-site sweep) |
| Boundary grep targeted (Cat D/E/F) | OK — all 8 leaks cleared |
| Boundary grep extended (audit-gap vocabulary, 6 audit-gap files) | OK — 19 sites cleared (18 from audit-gap fix-coder pass + 1 from 19th-leak small fix-coder pass); 4 LEGITIMATE-classified hits on `boundary-investigation/SKILL.md` (deny-list teaching, Check 37 exempt); ZERO new audit-gap discoveries |
| Boundary grep targeted (`scripts/lib/detect.sh` post-19th-leak) | OK — `BOUNDARY OK — detect.sh clean` |
| Cluster sync (canonical vs .claude with `V3 §28` filtered) | OK |
| Cluster byte-identity (canonical vs .claude vs .codex post-audit-gap) | BYTE-IDENTICAL all three .md siblings |
| TOML parse (.gemini/commands/pm-startup.toml) | PASS (re-verified post-audit-gap pass) |
| H.10 8 fixes preserved | PASS — `grep -nE "AUDIT-USER-CURATION\|ARCHITECTURE-V3\.md\|ARCHITECTURE-V3\.3-DELTA"` returns no Cat D/E/F leak match in any of the 7 touched files |
| Audit-gap 18 fixes preserved (no regression by 19th-leak pass) | PASS — extended audit-gap grep in §3.4.b returns ZERO audit-gap-class hits in PM-CHAT.md + pm-startup cluster (all 5 audit-gap files still clean) |

---

## §4 — Cross-references

- **V2 architect doc §H.10:** `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` §H.10 (commit fence + per-commit reviewer scope; lines 1160-1175).
- **V2 architect doc §B.2:** same file §B.2 Cat D/E/F category table (lines 124-136 — specifies the Cat F substitution prose "STAYS at pack root per pack-repo audit finding; not installed at client").
- **PLAN H.10:** `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` §H.10 (lines 415-466 — step-by-step coder spec).
- **AUDIT-PRE-19C-BOUNDARY-LEAKS.md:**
  - §1.7 Cat F source (boundary-investigation skill L124) — line 215 of audit doc.
  - §1.10 Cat E source (pm-startup cluster at L258 / L255) — lines 253-279.
  - §1.2.a Cat D PM-CHAT.md (L410 / L537 post-drift) — line 152-153.
  - §2.5 Cat D detect.sh (L335, L678) — lines 489-504.
- **ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md:**
  - §1.4 Cat D categorization (drop cite entirely) — lines 67-78.
  - §1.5 Cat E categorization (pm-startup sibling sweep) — lines 80-93.
  - §1.6 Cat F categorization (BD-175 self-leak) — lines 95-105.
- **BD-175 (Cat F source incident):** prior commits established the `boundary-investigation` skill (commit `f5b3998` — "BD-175 prevention mechanisms"); the L124 self-leak shipped within that commit. Cat F closes the BD-175 self-leak the audit identified.
- **Filename uniqueness rule (audit-vocabulary-gap awareness):** pack-root `CLAUDE.md` § Repo conventions → "Filename uniqueness heuristic" — updated 2026-05-22 (commit `1121b3d`) to formally classify bare-version shorthand (`V3.3 §X.Y`, `V3 §28.1.X`) as a leak under the rule's spirit. This is the authoritative basis for the audit-gap fix-coder pass (Pack Chat (A) Option B triage decision) absorbing the 18 sites flagged in original §7.2 into the same commit as the H.10 8-leak pass.
- **H.9 audit-gap absorption precedent:** commit `3a3de64` (Batch 19c.H.9) followed the same pattern — per-entry skeleton audit-gap discoveries flagged during H.9 initial pass, then absorbed via Pack Chat triage into the same H.9 commit. The H.10 audit-gap absorption (this commit) follows the same precedent at the same batch level.

---

## §5 — Success criteria checklist (combined 26-site sweep)

### 5.1 Original H.10 success criteria

| # | Criterion | Status |
|---|---|---|
| 1 | All 8 Cat D + E + F leaks closed per `AUDIT-PRE-19C-BOUNDARY-LEAKS.md` spec | PASS |
| 2 | pm-startup cluster (4 files) post-edit byte-identical at the cite-removed sites (cluster sync preserved) | PASS (diff confirms canonical == .claude == .codex .md siblings; .toml structurally equivalent + TOML parses) |
| 3 | Cat F boundary-investigation/SKILL.md substitution prose conveys the rule's meaning without the pack-internal cite | PASS ("STAYS at pack root per pack-repo audit finding; not installed at client" preserves rule + drops cite + introduces no new leak) |
| 4 | No new leaks introduced (boundary grep returns OK on the 7 touched files) | PASS (targeted Cat D/E/F grep returns OK; broader grep's 4 hits on boundary-investigation skill are pre-existing LEGITIMATE deny-list teaching content per audit §1.7) |
| 5 | `python3 scripts/validate-pack.py` PASS | PASS |
| 6 | Manifest v11-* row drift | PASS (3 v11-* rows drifted; regenerated twice — once after H.10 8-leak pass, once after audit-gap 18-leak pass) |
| 7 | IMPL-REPORT at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.10.md` | PASS (this file, extended) |
| 8 | Any audit-vocabulary-gap discoveries flagged in IMPL-REPORT §7 | PASS — original 18 flagged in §7.2, then absorbed via Pack Chat (A) triage; 1 NEW discovery flagged in §7.4 |

### 5.2 Audit-gap fix-coder pass success criteria

| # | Criterion | Status |
|---|---|---|
| 1 | All 18 audit-gap sites closed (Cat A drops; preserve surrounding prose) | PASS — 10 in PM-CHAT.md + 2 × 4 = 8 in pm-startup cluster |
| 2 | H.10 coder's 8 fixes UNCHANGED (no Cat D/E/F regression) | PASS — targeted grep confirms zero regression |
| 3 | pm-startup cluster (4 files) byte-identical post-edit (cluster sync preserved) | PASS — canonical == .claude == .codex BYTE-IDENTICAL; .toml structurally equivalent |
| 4 | `python3 scripts/validate-pack.py` PASS | PASS |
| 5 | Boundary grep (extended audit-gap vocabulary) returns OK in 5 audit-gap files | PASS — zero pack-internal cites or bare-version shorthand in the 5 audit-gap files; 1 NEW discovery originally flagged in §7.4 for `scripts/lib/detect.sh:22` is now CLOSED via 19th-leak absorption pass (see §5.3) |
| 6 | Manifest v11-* row drift | PASS — 3 v11-* rows drifted (post-audit-gap regen, superseded by post-19th-leak regen) |
| 7 | Existing IMPL-REPORT updated to document the full 26-site sweep | PASS — §1 Scope updated, §2.4 added (18 new edit entries), §3 Verification refreshed (extended boundary grep added), §5 Success criteria extended, §7.2 closed (no longer "flagged for triage" — now "closed by Pack Chat (A) triage decision") |

### 5.3 19th-leak small fix-coder absorption pass success criteria

| # | Criterion | Status |
|---|---|---|
| 1 | `scripts/lib/detect.sh` L22 cite dropped (Cat A; comment preserves "(post BD-175...)" context) | PASS — `# Per V3 §28.2.3 surface routing (post BD-175 directory reorganization):` → `# Surface routing (post BD-175 directory reorganization):` |
| 2 | H.10 IMPL-REPORT §7.4 updated to "CLOSED" status | PASS — see §7.4 update |
| 3 | H.10 IMPL-REPORT §1 + §3 + §5 reflect 27 leaks total | PASS — §1 Scope counts updated 26 → 27 (8 audit-specified + 19 audit-gap); §3.3 manifest regen tally three; §3.4.b extended grep result; §3.7 verification summary table; §5.2 + §5.3 success criteria checklists |
| 4 | `python3 scripts/validate-pack.py` PASS | PASS (43 checks clean) |
| 5 | Boundary grep on `scripts/lib/detect.sh` returns "BOUNDARY OK" | PASS — extended-vocabulary grep returns `BOUNDARY OK — detect.sh clean` |
| 6 | Manifest v11-* row drift | PASS — 3 v11-* rows drifted post-19th-leak regen |
| 7 | All other working-tree modifications UNCHANGED | PASS — only `scripts/lib/detect.sh` (1 line edit), `test-fixtures/manifest.txt` (3 v11-* row drift), and this IMPL-REPORT were modified by the 19th-leak pass; H.10 8 fixes + audit-gap 18 fixes preserved byte-identical |

All 8 original + 7 audit-gap-pass + 7 19th-leak-pass criteria = 22 criteria PASS.

---

## §6 — Out-of-scope confirmations

- **Only the 7 named in-scope files touched** (plus `test-fixtures/manifest.txt` as the v11-surface manifest-regen rule mandates). Verified via `git diff --stat`.
- **H.9 per-entry skeleton files unchanged.** The 7 H.9 per-entry skeleton files cleared in the prior commit (`project-template/docs/project/{backlog,implementation-plan,changelog}/{_rules,_intro,_format}.md`) are NOT in this commit's diff.
- **Audit doc unchanged.** `maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md` is an immutable snapshot per prompt; not modified.
- **No pack-root trinity edits.** Pack-root `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` not modified.
- **No `pack-ops/` edits.** None of `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `pack-ops/HELP-FRAGMENT-TRACKER.md`, etc. modified.
- **No `supporting-docs/` edits.** None of `supporting-docs/METHODOLOGY.md`, `supporting-docs/INSTALL-PROCEDURES.md`, etc. modified.
- **No `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` edits.** Pack-side agent definitions not modified.
- **No `maintenance-docs/v11-research/` edits.** Research-doc tree not modified.
- **No git state changes.** Read-only git verbs only (`git status`, `git diff`, `git rev-parse`, `git diff --stat`). Coder never stages, commits, pushes, or tags.

---

## §7 — Open questions / deferrals (audit-vocabulary-gap discoveries)

Per prompt instruction (Approach step 4): "FLAG any audit-vocabulary-gap discoveries; do NOT silently absorb them — H.10 audit scope is Cat D/E/F only; new audit-gap discoveries need Pack Chat triage."

### 7.1 Cat F substitution prose rationale (no triage needed; documented for review)

The substitution `AUDIT-USER-CURATION.md Override 1` → `pack-repo audit finding` was chosen per V2 §B.2 Cat F spec literal recommendation. The replacement intentionally does NOT name a specific pack-internal file. The alternative considered ("STAYS at pack root per pack-repo curation policy; not installed at client") was rejected as more vague — "audit finding" is honest provenance ("there exists an authoritative finding"); "curation policy" generalized away from the audit class of authority. No triage needed; reviewer can override if a different replacement is preferred.

### 7.2 CLOSED — Bare-version `V3.3 §X.Y` / `V3 §28.1.X` audit-vocabulary-gap leaks (absorbed via audit-gap fix-coder pass)

**Status:** CLOSED by Pack Chat (A) triage decision (2026-05-23). All 18 audit-gap sites enumerated in original §7.2 have been swept in the audit-gap fix-coder pass. Edit detail documented in §2.4. Same absorption pattern as the H.9 audit-gap absorption that landed at `3a3de64`.

**Cross-reference:** The trinity Filename uniqueness rule update at commit `1121b3d` (2026-05-22) formally classifies bare-version shorthand (`V3.3 §X.Y` / `V3 §28.1.X` as references to pack-internal architect docs) as a leak under the rule's spirit. The audit-gap fix-coder pass closes the audit-gap class manually in the 5 audit-gap files before any future CI mechanical gate (Check 43-style) goes online to catch them automatically.

**Original audit-gap discovery (preserved for traceability):** While scanning the 7 H.10 in-scope files for the precise Cat D/E/F leaks, I observed additional bare-version shorthand citations that appear to be the audit-vocabulary-gap class the updated Filename uniqueness rule warns about (pack-root `CLAUDE.md` § Repo conventions, 2026-05-22 update: "bare-version shorthand like `V3.3 §3.X` as a reference to `ARCHITECTURE-V3.3-DELTA.md` sections is a leak under the rule's spirit"). These were NOT in the audit's Cat D/E/F inventory (audit ran 2026-05-21, before the trinity rule update; AUDIT-PRE-19C-BOUNDARY-LEAKS.md is an immutable snapshot per prompt).

**File: `project-template/docs/pack/PM-CHAT.md`** — 9 additional bare-version refs beyond the Cat D leak at L537:
- L545: `**Path 3 is forbidden** per V3.3 §1 supersession + §3 line 27.`
- L553: `### Advisory heuristic (V3.3 §7.1)`
- L570: `shape (V3.3 §7.1):`
- L580: `### Execution workflow (V3.3 §7.2)`
- L602-603: `... per V3.3 §3.4. ... per V3.3 §3.4.`
- L616: `V3.3 §7.2 and IMPLEMENTATION-PLAN-ADDENDUM-4 §6.P resolution`
- L635: `### Verb shape (V3.3 §7.3)`
- L640: `pack td resolve <td-id> [--note "..."] # Direct close (V3.3 §3.2)`

(Note: L616 also references `IMPLEMENTATION-PLAN-ADDENDUM-4 §6.P` — a pack-internal doc cite; same audit-gap class.)

**File: `project-template/skills/pm-startup/SKILL.md` (and the 3 cluster siblings .claude/.codex/.gemini)** — 2 additional bare-version refs per file beyond the Cat E sweep at L258-260:
- L214: `is fixed by V3 §28.1.9 to keep the recommendation check at the`
- L249: `Then route the user's response per V3 §28.1.7:`

That's 2 bare-version refs × 4 cluster files = **8 additional bare-version leaks in the cluster**.

**Total new audit-gap discoveries:** 9 (PM-CHAT.md) + 8 (pm-startup cluster) = **17 bare-version shorthand cites** + 1 `IMPLEMENTATION-PLAN-ADDENDUM-4 §6.P` cite in PM-CHAT.md L616 = **18 audit-gap leaks** in the same 5 files H.10 touched.

**Disposition (RESOLVED 2026-05-23):** Pack Chat (A) triage chose **Option B** (extend H.10 scope to include the 18 cites in the same commit). Pack Chat spawned an audit-gap fix-coder follow-up agent with the 18-site scope; that agent's edits are documented in §2.4 and verified clean in §3.4.b.

**Original options framing (preserved for traceability):**

1. **Option A:** Open a new BD (e.g., BD-187) to sweep all bare-version shorthand audit-gap leaks across the project-template/ + scripts/ + supporting-docs/ client-installed surface in the same fix-shape pattern as H.10 Cat D (drop the cite; bare prose stands).
2. **Option B (CHOSEN by Pack Chat):** Extend H.10 scope retroactively to include these 18 cites in the same commit, framing as "H.10 + audit-gap extension." Strong logical-fit (same 5 files, same fix-shape, trinity Filename uniqueness rule update at `1121b3d` formally classifies as leak class).
3. **Option C:** Defer to v11.0's H.14 (Check 43 new check) — Check 43 was specifically designed as a CLASS-test (bare-or-qualified reference resolution into `maintenance-docs/`) that would catch these at CI time, but landing them now closes the audit-gap class manually before Check 43's mechanical gate goes online.

Per pack memory `feedback-deferral-is-scope-creep` + `feedback-no-deferral-without-user-direction`: the leaks are LARGE and UNBLOCKED, so the default was to insert IMMEDIATELY (not defer to v11.1+). Per pack memory `feedback-user-prescriptive-authority`, Pack Chat had architect/lead/decision-maker authority for the triage call; Pack Chat chose Option B.

**SIZE/BLOCKED/LOGICAL-FIT analysis (post-decision retrospective):**
- **SIZE:** 18 cites across 5 files = small-to-medium mechanical sweep; not architect-pass material. PASS.
- **BLOCKED:** UNBLOCKED today; Check 43 lands at H.14 (later in Batch 19c) but is not a prerequisite. PASS.
- **LOGICAL FIT:** strong — same 5 files H.10 already touches, same fix-shape (drop cite or replace with bare prose); folded into this commit without scope drift. PASS.

All three legs of the absorption bar PASS; Pack Chat (A) Option B decision aligns with `feedback-deferral-is-scope-creep` defaults.

### 7.4 CLOSED — 19th audit-gap leak in `scripts/lib/detect.sh:22` (absorbed via 19th-leak small fix-coder pass)

**Status:** CLOSED via Pack Chat (A) triage decision (2026-05-23) — 19th audit-gap absorbed into H.10 commit as the same-audit-gap-class 19th catch (cite drop in `scripts/lib/detect.sh` L22). Edit detail in §2.4.3.

**Cross-reference:** Pack Chat (A) chose Option A (absorb) per the implementer-side recommendation. The cite drop in §2.4.3 closes the 19th leak in `scripts/lib/detect.sh:22` (the file is already touched by this commit for Cat D fixes at L334-335 + L677-678) with the same fix-shape (Cat A drop: bare-version cite prefix removed; surrounding prose preserved). Post-absorption verification in §3.4.b + §3.4.c confirms ZERO audit-gap leaks remain in the 6 touched-file audit-gap surface.

**Original discovery (preserved for traceability):** While running the extended boundary grep in §3.4.b during the audit-gap fix-coder pass, a 19th bare-version shorthand cite was discovered that was NOT in the prompt's enumerated 18-site scope:

**File:** `scripts/lib/detect.sh`
**Line:** L22
**Content (pre-edit):** `# Per V3 §28.2.3 surface routing (post BD-175 directory reorganization):`

**Classification:** Same audit-gap class as the 18 enumerated — bare-version `V3 §28.2.3` shorthand reference to a pack-internal architect doc section. Same fix-shape applied (Cat A drop: `# Per V3 §28.2.3 surface routing` → `# Surface routing`).

**Why the 19th was NOT absorbed in the original audit-gap fix-coder pass:**
- The audit-gap fix-coder prompt explicitly scoped to "18 audit-vocabulary-gap leaks in 5 of the 7 H.10 files," enumerating PM-CHAT.md + pm-startup cluster (4 files) as the 5 audit-gap files. `scripts/lib/detect.sh` was H.10 in-scope (for Cat D fixes) but NOT named as an audit-gap file in the prompt.
- Per audit-gap fix-coder scope discipline (mirrors the original H.10 coder's "FLAG; do NOT silently absorb" stance for the original 18), this 19th discovery was FLAGGED — not silently absorbed.
- The 18-site scope was Pack Chat (A)'s triage decision based on its visibility into the 5 audit-gap files; this 19th site was a new data point requiring fresh triage.

**Original options framing (preserved for traceability):**

1. **Option A (CHOSEN by Pack Chat):** Absorb into the H.10 commit (extend audit-gap absorption +1 site via small fix-coder pass). Strong logical-fit — same audit-gap class, same fix-shape, H.10 in-scope file (detect.sh was already touched for Cat D fixes at L334-335 + L677-678). Trinity Filename uniqueness rule update at `1121b3d` covers this class.
2. **Option B:** Defer to a later commit in Batch 19c (e.g., a single-site cleanup fix-coder pass before H.14). Marginal LOGICAL-FIT loss compared to Option A; small file count.
3. **Option C:** Defer to Check 43 / v11.0 H.14 mechanical gate. Same rationale as the original 18's Option C.

**Pack Chat (A) decision rationale:** Per the SIZE/BLOCKED/LOGICAL-FIT analysis below, all three legs PASS for Option A. Same absorption pattern as the original 18 (Pack Chat (A) Option B for the 18-site batch + this Option A for the 19th-leak single-site pass). Per pack memory `feedback-deferral-is-scope-creep` defaults + `feedback-user-prescriptive-authority` (Pack Chat orchestrates; fix-coder executes).

**SIZE/BLOCKED/LOGICAL-FIT bar (Option A absorption):**
- **SIZE:** 1 cite in 1 file = trivial. PASS.
- **BLOCKED:** UNBLOCKED. PASS.
- **LOGICAL FIT:** STRONG — same audit-gap class, same fix-shape, same touched-file, same commit. PASS.

All three legs PASS for Option A; Pack Chat (A) Option A decision aligns with `feedback-deferral-is-scope-creep` defaults.

### 7.3 PM-CHAT.md line-drift note (no triage needed; documented for review)

Audit at `9da98a4` cited PM-CHAT.md L410 for the `ARCHITECTURE-V3.3-DELTA.md §3.1` leak; at HEAD `1121b3d` (post-H.1 through H.9 commits) the cite is at L537. This is normal line drift; the audit's file:line precision is necessarily snapshot-bound. Future audit refreshes (e.g., before H.17 end-of-batch reviewer) should re-anchor to current HEAD line numbers if line:column precision matters for reviewer cross-checking.

---

## §8 — Boundary discipline check (P-missed-7)

Per pack-coder system prompt boundary discipline pre-flight: any edit to a file under `project-template/`, `supporting-docs/`, or another pack-shipped-to-client surface requires investigating the project-side SSOT first.

### 8.1 Edits touching `project-template/` (6 files) + `scripts/` (1 file; 3 edit sites including 19th-leak L22)

For each project-side file edit, the project-side SSOT investigated:

| File | Project-side SSOT for the change | SSOT investigation result |
|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` L535-537 | The cite was to `ARCHITECTURE-V3.3-DELTA.md §3.1`, a pack-internal doc. Project-side SSOT: the table immediately below the cite (L539-543) enumerates the three outcomes; no separate SSOT needed — the cite was redundant. | Drop cite; surrounding inline table is the SSOT at client install. |
| `project-template/skills/pm-startup/SKILL.md` L258-260 | The cite was footnote-style provenance to `ARCHITECTURE-V3.md §28.1.5`. Project-side SSOT: the routing prose itself (L242-256) IS the SSOT at client install; the cite added no client-resolvable navigation. | Drop cite; surrounding routing prose stands. |
| `project-template/.claude/skills/pm-startup/SKILL.md` L258-260 | Same as canonical SKILL.md (mirror cluster file per pack-shipped distribution pattern). | Drop cite mirror-identically. |
| `project-template/.codex/skills/pm-startup/SKILL.md` L258-260 | Same as canonical. | Drop cite mirror-identically. |
| `project-template/.gemini/commands/pm-startup.toml` L255-257 | Same as canonical, inside TOML triple-quoted string wrapping the prompt body. | Drop cite mirror-identically; TOML structure preserved. |
| `project-template/skills/boundary-investigation/SKILL.md` L124 | The cite was to `AUDIT-USER-CURATION.md Override 1`, a pack-internal audit doc. Project-side SSOT: NO project-side SSOT exists for the "tracker.toml.pack-example STAYS at pack root" rationale (the rationale itself is pack-side; the client doesn't NEED to know the audit detail). The substitution prose ("pack-repo audit finding") names a class-of-authority without resolving to a specific pack file. | Substitute with class-name prose; rule statement preserved. No project-side SSOT required because the rationale is pack-side; the rule manifestation at client install (the file isn't installed) is self-evident. |
| `scripts/lib/detect.sh` L334-335 + L677-678 | Cites to `ARCHITECTURE-SKILL-DIMENSIONS.md` and `ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (pack-internal). Project-side SSOT: the script comments below ("Markers (any one true → yes): (a) ... (b) ...") enumerate the markers — no separate project-side authority doc; the script IS the SSOT for its own behavior. | Drop cite; bare prose stands. |
| `scripts/lib/detect.sh` L22 (19th-leak absorption) | Bare-version cite `V3 §28.2.3` to a pack-internal architect doc section about surface routing. Project-side SSOT: the surface routing rules themselves are encoded in the function dispatching below (`detect_pack_surface`, the BACKLOG.md path discovery in stages following the comment) — the script IS the SSOT for its own dispatch behavior; the parenthetical "(post BD-175 directory reorganization)" provides the temporal context for the routing without needing a pack-internal cross-reference. | Drop bare-version prefix; capitalize first surviving word ("Surface"); preserve the "(post BD-175...)" parenthetical and trailing colon. |

**Boundary discipline disposition:** All 9 edits drop pack-only references with no project-side SSOT augmentation needed (the project-side SSOTs were already inline or implicit in the surrounding code/prose). One edit (Cat F) substitutes class-name prose for a pack-internal cite — no project-side replacement target exists, and none is needed.

### 8.2 No "Boundary discipline stop" triggered

None of the edits triggered a pack-only target acquisition during the edit (no `pack-ops/` / `PACK-AGENTS.md` / `Pack Chat` / pack-* agent name introduction). All edits move FROM pack-internal references TO either no reference or class-name prose — the correct direction per P-missed-7.

---

## §9 — PREFLIGHT trace

Per `pack-coder` agent prompt and pack memory `feedback-pack-coder-preflight-pattern`:

**Initial H.10 8-leak pass (first PREFLIGHT, emitted by H.10 coder):**
```
PREFLIGHT: 8/8 in-scope leak edits complete; verification PASS;
HEAD 1121b3d37be6eec888d40fca2c15558810859767;
about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.10.md
```

**Audit-gap fix-coder 18-leak absorption pass (second PREFLIGHT, emitted by audit-gap fix-coder):**
```
PREFLIGHT: 26/26 cite-drops complete (8 audit-specified + 18 audit-gap);
verification PASS; HEAD 1121b3d37be6eec888d40fca2c15558810859767;
IMPL-REPORT remains at maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.10.md
```

**19th-leak small fix-coder absorption pass (third PREFLIGHT, emitted by 19th-leak fix-coder):**
```
PREFLIGHT: 27/27 cite-drops complete (8 audit-specified + 19 audit-gap incl detect.sh L22);
verification PASS; HEAD 1121b3d37be6eec888d40fca2c15558810859767;
IMPL-REPORT remains at maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.10.md
```

All three emitted in chat before the corresponding write/extend operation began.

---

## §10 — Definition-of-Done checklist (combined 26-site sweep)

### 10.1 Original H.10 8-leak DoD

| Item | Status | Evidence |
|---|---|---|
| 8 Cat D + E + F leaks closed | PASS | §2 edits 1-8 + §3.4.a targeted boundary grep |
| pm-startup cluster sync preserved (4 files) | PASS | §3.5 cluster sync diff + .codex byte-identical check |
| Cat F substitution prose conveys rule without pack-internal cite | PASS | §2.3.1 BEFORE/AFTER + §7.1 rationale |
| No new boundary leaks introduced (8-leak scope) | PASS | §3.4.a targeted boundary grep + §8.1 SSOT investigation |
| `python3 scripts/validate-pack.py` PASS | PASS | §3.1 (43 checks clean) |
| Manifest v11-* row drift (regen post-8-leak) | PASS | §3.3 (3 v11-* rows drifted) |
| IMPL-REPORT at specified path | PASS | This file (path matches success criterion 7) |
| Audit-vocabulary-gap discoveries flagged in §7 | PASS | §7.2 originally flagged 18; resolved by Pack Chat (A) Option B |
| Boundary discipline check section completed | PASS | §8 per pack-coder boundary discipline pre-flight |
| No git state changes by coder | PASS | Read-only git verbs only (status, diff, rev-parse, diff --stat) |
| Out-of-scope files unchanged | PASS | §6 (audit doc, H.9 skeletons, pack-root trinity, pack-ops/, supporting-docs/, etc. all unchanged) |

### 10.2 Audit-gap fix-coder 18-leak absorption DoD

| Item | Status | Evidence |
|---|---|---|
| All 18 audit-gap sites closed (Cat A drops) | PASS | §2.4 edits (10 in PM-CHAT.md + 8 in pm-startup cluster) |
| H.10 coder's 8 fixes UNCHANGED | PASS | §3.4.a targeted grep confirms zero Cat D/E/F regression in the 7 H.10 files |
| pm-startup cluster byte-identical post-edit | PASS | §3.5 — canonical == .claude == .codex BYTE-IDENTICAL all three .md siblings; .toml structurally equivalent |
| Surrounding prose preserved (no semantic loss) | PASS | §2.4.1 / §2.4.2 BEFORE/AFTER pairs show clean prose flow post-edit |
| TOML parse preserved (.gemini/commands/pm-startup.toml) | PASS | §3.6 re-verified post-audit-gap pass |
| `python3 scripts/validate-pack.py` PASS | PASS | §3.1 (43 checks clean — post-audit-gap pass) |
| Boundary grep (extended audit-gap vocabulary) OK in 5 audit-gap files | PASS | §3.4.b — 18 sites cleared; 5 LEGITIMATE-classified hits on boundary-investigation skill (Check 37 exempt); 1 NEW discovery originally flagged in §7.4 on detect.sh:22 now CLOSED via 19th-leak absorption |
| Manifest v11-* row drift (regen post-audit-gap) | PASS | §3.3 (3 v11-* rows drifted) |
| IMPL-REPORT extended (not rewritten) to document full 26-site sweep | PASS | This file: §1 Scope updated; §2.4 added (18 new edit entries); §3 Verification refreshed (extended grep + post-audit-gap cluster sync); §5 Success criteria extended; §7.2 closed; §7.4 added |
| 19th NEW discovery flagged (NOT silently absorbed) | PASS | §7.4 (original) documented `scripts/lib/detect.sh:22` `V3 §28.2.3` — outside enumerated 18-site scope; Pack Chat triage performed (CLOSED via §10.3) |
| No git state changes by audit-gap fix-coder | PASS | Read-only git verbs only (status, diff, rev-parse, diff --stat) |

### 10.3 19th-leak small fix-coder absorption DoD

| Item | Status | Evidence |
|---|---|---|
| `scripts/lib/detect.sh` L22 cite dropped (Cat A; comment preserves "(post BD-175...)" context) | PASS | §2.4.3 BEFORE/AFTER — `# Per V3 §28.2.3 surface routing (post BD-175 directory reorganization):` → `# Surface routing (post BD-175 directory reorganization):` |
| H.10 8 fixes UNCHANGED (no Cat D/E/F regression) | PASS | §3.4.a + post-19th-leak status quo: targeted grep confirms zero regression in the 7 H.10 files |
| Audit-gap 18 fixes UNCHANGED (no audit-gap regression) | PASS | §3.4.b — 5 audit-gap files (PM-CHAT.md + pm-startup cluster × 4) still clean post-19th-leak pass |
| `python3 scripts/validate-pack.py` PASS | PASS | §3.1 (43 checks clean — post-19th-leak pass) |
| Boundary grep on `scripts/lib/detect.sh` returns "BOUNDARY OK" | PASS | §3.4.c — `BOUNDARY OK — detect.sh clean` |
| Manifest v11-* row drift (regen post-19th-leak) | PASS | §3.3 (3 v11-* rows drifted; new v11-* SHAs reflect the 27-site sweep) |
| IMPL-REPORT extended (not rewritten) to document 27-site sweep | PASS | This file: §1 Scope updated (26 → 27); §2.4.3 added (19th-leak edit entry); §3.3 manifest tally; §3.4.b updated (post-absorption result); §3.4.c added (targeted post-19th grep); §3.7 verification table; §5.3 success criteria added; §7.4 CLOSED |
| §7.4 status updated from "flagged" to "CLOSED" | PASS | §7.4 header rewritten ("CLOSED — 19th audit-gap leak in `scripts/lib/detect.sh:22` (absorbed via 19th-leak small fix-coder pass)") |
| No git state changes by 19th-leak fix-coder | PASS | Read-only git verbs only (status, diff, rev-parse, diff --stat) |
| Out-of-scope files unchanged | PASS | Only `scripts/lib/detect.sh`, `test-fixtures/manifest.txt`, and this IMPL-REPORT modified by 19th-leak pass |

All 11 original + 11 audit-gap-pass + 10 19th-leak-pass DoD items = 32 DoD items PASS.

---

**End of IMPL-REPORT BD-173 Batch 19c.H.10 (combined 27-site sweep: 8 audit-specified + 19 audit-gap absorbed; ZERO open new audit-gap discoveries in the touched-file scope).**
