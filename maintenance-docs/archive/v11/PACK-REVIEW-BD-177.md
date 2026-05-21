# PACK-REVIEW-BD-177

**BD:** BD-177 — Coordinate `scripts/pack-help.sh:86` sentinel-regex with `pack-ops/HELP-FRAGMENT-PACK.md:37` prose post-BD-175 Commit 2 relocation
**Branch:** `v11-dev`
**HEAD reviewed:** `3870f1cbbec61652cd7dc809b366dd8e22c21ad2`
**Reviewer:** pack-reviewer (background sub-agent)
**Date:** 2026-05-20
**Mode:** Per-commit review (BD-177 only)

---

## §1 Verdict + summary

**VERDICT: BLOCKER — CHANGES REQUIRED**

The coordinated 2-locus edit for the **pack-side** sentinel + regex is correctly
implemented and self-consistent. However, the new awk regex at
`scripts/pack-help.sh:86` is **load-bearing for BOTH pack-side AND client-side**
rendering (the `emit_fragment()` function is called from BOTH surface branches
at L127 and L130-131). The new regex anchors on `pack-ops\/HELP-FRAGMENT-TRACKER\.md`,
which matches the pack-side sentinel at `pack-ops/HELP-FRAGMENT-PACK.md:37` but
does **NOT** match the project-template/client-side sentinel at
`project-template/docs/pack/HELP-FRAGMENT.md:26` (which uses the form
`[Included from \`HELP-FRAGMENT-TRACKER.md\` in this directory via \`pack-help.sh\`.]`).

**End-user-visible effect on the client surface:** the literal sentinel line
now appears in `pack help` output to end users in client (project) repos, where
previously the awk substitution replaced it with the inlined tracker fragment
body. I reproduced this regression below (§2.9) against both an ad-hoc fixture
and the built `test-fixtures/v11-flat-file` artifact.

The IMPL-REPORT's claim of "User-impact severity: ZERO" is correct for the
pack-side surface (which the BD scope was framed around) but incorrect for the
client-side surface, which the scoped fix silently breaks.

Test 2.2 ("client tracker section inlined") passes by false-positive: its
substring check matches the parent `## Tracker commands (v11+)` H2 in the
client placeholder, not content from the inlined tracker fragment body. The
test does not actually verify substitution fired on the client surface — it
only verifies that the H2 header appears in output (which it does, regardless
of whether substitution fires). Pre-existing test gap; BD-177 exposes it but
did not create it.

Recommended fix: broaden the awk regex to match BOTH sentinel forms, OR also
update the client-side sentinel + regenerate manifest as part of the BD-177
coordinated fix. The coder's plan deviation framing ("test infrastructure was
meant for harness machinery, not in-test sentinel reference strings") was
sound for the test 2.1/2.5 edits, but the same coordinated-edit logic now
applies to the client-side sentinel at `project-template/docs/pack/HELP-FRAGMENT.md:26`.

Other scope items are clean: 4 modified files match expected delta;
PREFLIGHT emitted; validate-pack.py 39/39 green; 3 persona contracts 253/0
combined; manifest regen produced expected 3-row v11-* drift; v10-* and
existing-* rows unchanged; trinity rule N/A (no trinity edits).

---

## §2 Independent findings (per-scope-area assessment per the 10 review items)

### §2.1 Sentinel-regex coordination correctness (PASS for pack-side; BLOCKER for client-side coverage gap)

**Pack-side sentinel at `pack-ops/HELP-FRAGMENT-PACK.md:37`** (post-fix):

```
[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]
```

**Awk regex at `scripts/pack-help.sh:86`** (post-fix):

```bash
/^\[Included from `pack-ops\/HELP-FRAGMENT-TRACKER\.md`/ {
```

I verified the regex matches the pack-side sentinel exactly (the backtick-quoted
`pack-ops/HELP-FRAGMENT-TRACKER.md` substring is anchored at the start of the line
after the literal `[Included from ` prefix; `/` correctly escaped as `\/`).

**Client-side sentinel at `project-template/docs/pack/HELP-FRAGMENT.md:26`** (unchanged by BD-177):

```
[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]
```

This sentinel uses NO `pack-ops/` prefix. The new regex does NOT match it. The
pre-BD-177 regex `/^\[Included from \`HELP-FRAGMENT-TRACKER\.md\`/` matched
BOTH sentinel forms (because both started with the bare `HELP-FRAGMENT-TRACKER.md`
filename). The BD-177 regex tightens the anchor to the `pack-ops/`-prefixed
form, which silently un-matches the client sentinel.

### §2.2 L83 comment in pack-help.sh (PASS)

The inline comment at `scripts/pack-help.sh:83` was updated in sync with the
regex:

```bash
# The placeholder line is `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` ...]`.
```

The comment matches the new pack-side sentinel form and is consistent with
the regex. However, the comment describes only the pack-side case — given
the function is also called from the client branch, a more accurate comment
would document both forms (or note that the regex is pack-side-only post-BD-177).
Caveat: this is a documentation NIT downstream of the BLOCKER in §2.1.

### §2.3 Test 2.1 + test 2.5 alignment (PASS for what they assert; SHOULD-level gap on what test 2.2 fails to assert)

**Test 2.1 line 107 (placeholder-replaced assertion):**

```bash
[[ "$output" != *"[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\`"* ]] \
    && t_pass "2.1 placeholder line replaced" \
    || t_fail "2.1 placeholder line still present"
```

This correctly checks the new pack-side sentinel substring is absent from
rendered output. PASS.

**Test 2.5 (lines 156-169 fixture + assertion):**

The ad-hoc fixture at line 159 now writes the new pack-side sentinel form. The
test invokes `pack-help.sh --root "$TR_VER" --surface pack` and asserts the
output contains `# header`, `TRACKER-CONTENT-MARKER`, `# footer` in order. PASS.

I ran `bash scripts/tests/pack-help-test.sh` and observed 17/17 PASS, matching
the coder's claim.

**SHOULD-level gap on test 2.2 (pre-existing; surfaced by BD-177 regression):**

Test 2.2 at line 124-126 asserts:

```bash
[[ "$output" == *"# Tracker commands (v11+)"* ]] \
    && t_pass "2.2 client tracker section inlined" \
```

The substring `# Tracker commands (v11+)` is contained in BOTH:
1. The H2 parent heading in `project-template/docs/pack/HELP-FRAGMENT.md:24`:
   `## Tracker commands (v11+)` (matches as substring under `==*…*` glob).
2. The H1 inside `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:1`:
   `# Tracker commands (v11+)`.

The test "passes" because the H2 is present in any rendered output, regardless
of whether substitution fires. There is no positive assertion against
inlined-fragment content (e.g., `"set up the tracker"` which only appears
post-substitution). Test 2.1 has this stronger check on the pack-side (line
103-104), but test 2.2 does not have an analogous strong check on the client
side. This pre-dates BD-177, but BD-177's regression should have been caught
by test 2.2 and is not.

### §2.4 Manifest regen correctness (PASS)

`test-fixtures/manifest.txt` shows 3 v11-* row SHA drifts:

| Fixture | Old SHA | New SHA |
|---|---|---|
| v11-realistic-ot | `50940281…` | `e7ddf081…` |
| v11-flat-file | `8a6a2d05…` | `c7a5bc9d…` |
| v11-tracker-on | `11bc0a3a…` | `544b8ebc…` |

v10-* rows (tag-pinned) and `existing-project-mid-dev` row (pre-pack-install
input shape) are unchanged. I ran `bash test-fixtures/build.sh --verify` and
all 6 rows verified OK. PASS.

Drift makes sense: each v11-* fixture captures the updated
`scripts/pack-help.sh` and `pack-ops/HELP-FRAGMENT-PACK.md` content.

### §2.5 Scope discipline (PASS — 5 files modified as expected)

Commit `3870f1c` shows 5 files in the diff:
- `pack-ops/HELP-FRAGMENT-PACK.md` (+1/-1)
- `scripts/pack-help.sh` (+2/-2)
- `scripts/tests/pack-help-test.sh` (+2/-2)
- `test-fixtures/manifest.txt` (+3/-3)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177.md` (+484 new)

No trinity edits (CLAUDE.md / AGENTS.md / GEMINI.md untouched at pack root and
project-template). No out-of-scope refactoring. PASS for what was modified;
see §2.10 for what should ALSO have been touched but was not.

### §2.6 Coder's plan-deviation justification (PASS, well-reasoned)

The coder's §9 rationale for updating test 2.1 line 107 substring + test 2.5
fixture string is sound: changing the sentinel form necessarily breaks any
test that asserts against the sentinel string itself, so the test changes are
not test-infrastructure-modifications (in the sense of harness machinery) —
they are reference-string updates required by the coordinated edit. I agree
with the coder's distinction between "harness machinery" (out of scope) and
"in-test reference strings" (in scope as natural extension).

However, the SAME coordinated-edit logic that justified the test 2.1/2.5
updates should have surfaced the client-side sentinel as another required
coordinated update — see §2.10. The coder's scope discipline was internally
consistent within the framing "pack-side only" but missed the cross-surface
coupling.

### §2.7 validate-pack.py + 3 persona contracts (PASS — 39 + 253)

I ran each independently:

- `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (39/39, exit 0)
- `bash scripts/persona-contracts/contract-greenfield.sh` → `191 passed, 0 failed`
- `bash scripts/persona-contracts/contract-mid-dev.sh` → `25 passed, 0 failed`
- `bash scripts/persona-contracts/contract-migration.sh` → `37 passed, 0 failed`

Combined: 253/0. Matches the coder's claim. PASS.

Worth noting: none of these checks exercise actual `pack help` rendering on the
client surface. The validate-pack.py Check 24 verifies byte-identity of the
shared HELP-FRAGMENT-TRACKER.md mirror (still passes — both files are
byte-identical) but does NOT exercise the awk substitution end-to-end.

### §2.8 HELP-FRAGMENT-TRACKER.md location (PASS)

```
$ ls pack-ops/HELP-FRAGMENT-TRACKER.md
pack-ops/HELP-FRAGMENT-TRACKER.md  (present)

$ ls HELP-FRAGMENT-TRACKER.md
ls: HELP-FRAGMENT-TRACKER.md: No such file or directory  (expected — relocated)
```

Confirms tracker fragment lives only at `pack-ops/` post-BD-175 Commit 2.
The new sentinel form is path-accurate.

### §2.9 `pack help` output unchanged (PASS for pack surface; FAIL for client surface)

**Pack surface (PASS):**

```
$ bash scripts/pack-help.sh --root . --surface pack 2>&1 | sed -n '/Tracker commands/,/See also/p'
## Tracker commands (v11+)

# Tracker commands (v11+)

Tracker mode opts the surface into GH Issues as the source of truth.

[…inlined tracker fragment body…]
```

Substitution fires; output identical (structurally) to pre-BD-177.

**Client surface (FAIL — regression):**

Built a fixture matching `project-template/docs/pack/` layout:

```
$ rm -rf /tmp/ph-test-client && mkdir -p /tmp/ph-test-client/docs/{pack,project}
$ cp project-template/docs/pack/HELP-FRAGMENT.md /tmp/ph-test-client/docs/pack/
$ cp project-template/docs/pack/HELP-FRAGMENT-TRACKER.md /tmp/ph-test-client/docs/pack/
$ echo -e "**TD-001**\nStatus: Open" > /tmp/ph-test-client/docs/project/BACKLOG.md
$ bash scripts/pack-help.sh --root /tmp/ph-test-client 2>&1 | sed -n '/Tracker commands/,/See also/p'
## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]   <— LITERAL SENTINEL VISIBLE TO USER

## See also
```

Reproduced the same regression against the built `test-fixtures/v11-flat-file`
artifact (post-rebuild):

```
$ bash scripts/pack-help.sh --root test-fixtures/v11-flat-file 2>&1 | sed -n '/Tracker commands/,/See also/p'
## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]   <— SAME REGRESSION
```

End-user impact: any user of `pack help` in a v11 client repo sees the literal
`[Included from ...]` sentinel line instead of the inlined tracker fragment
body (~13 lines of tracker command documentation + colloquial mappings table).
This is the substitution silently breaking — exactly the failure mode BD-177
was created to prevent on the pack side, now created on the client side.

### §2.10 Out-of-scope inline-prose refs to HELP-FRAGMENT-TRACKER.md (BLOCKER + observations)

Repo-wide grep for `HELP-FRAGMENT-TRACKER` references surfaces several loci.
Most are unaffected by BD-177; the critical one is:

**BLOCKER:** `project-template/docs/pack/HELP-FRAGMENT.md:26` — sentinel for
client-side rendering. The path-prefix form is intentional ("in this
directory" — because in a client install, the tracker fragment is a sibling
at `docs/pack/HELP-FRAGMENT-TRACKER.md`, not under `pack-ops/`). The new
regex does not match this sentinel. The coordinated fix needs to address
this — either by broadening the regex or by parallel-updating both
sentinels to a common form.

**Other refs (observations, not actionable for BD-177):**

| Locus | Content | Status |
|---|---|---|
| `README.md:107` | layout description "byte-identical to pack root, DELTA L1" | OK (descriptive prose) |
| `README.md:263` | layout description "canonical; mirrored to project-template/docs/pack/" | OK |
| `CLAUDE.md:525` `AGENTS.md:478` `GEMINI.md:447` | path refs in trinity prose | OK (path-accurate to `pack-ops/`) |
| `project-template/skills/boundary-investigation/SKILL.md:100-109` | trinity skill docs (3 copies via Claude/Codex/Gemini) | OK |

The trinity skill docs at `boundary-investigation/SKILL.md` correctly
describe the byte-identity contract between
`pack-ops/HELP-FRAGMENT-TRACKER.md` and
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`. No staleness in
those refs.

---

## §3 Compare-to-IMPL-REPORT

After forming the independent assessment above, I read the IMPL-REPORT at
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-177.md`.

**Agreements:**
- §3 edits match the diff exactly (3.1 prose, 3.2 regex + comment, 3.3/3.4
  test edits).
- §4 test 2.1 PASS claim verified (I observed 17/17 PASS).
- §5 manifest regen evidence accurate (3 v11-* row drift, v10-* unchanged).
- §6 validate-pack + persona contract results match my independent runs.
- §9 plan deviation rationale for in-test reference strings is sound.
- §10 "No new POQs" is correct given the framing ("pack-side only").

**Disagreements / gaps:**

- **§1 Summary claim "the staleness was never user-visible"** is true for
  the pre-fix pack-side, but the IMPL-REPORT does not consider that the
  post-fix state introduces user-visible staleness on the client side. The
  coder did not test the client-side rendering end-to-end against an actual
  client fixture (only against the test 2.2 fixture, which has the
  false-positive substring-check issue).

- **§4 "PASS confirms the coordinated fix preserved the substitution
  behavior"** is true only for the pack-side. The IMPL-REPORT incorrectly
  generalizes from "pack-side test passes" to "substitution behavior
  preserved" — the client-side substitution is silently broken.

- **§9 Plan-deviation analysis** correctly identifies test 2.1/2.5 as
  coupled to the regex change, but misses that the
  `project-template/docs/pack/HELP-FRAGMENT.md:26` sentinel is similarly
  coupled (the regex must match it for client-side substitution to fire).
  The same coordinated-edit logic that justified the test changes should
  have surfaced the project-template sentinel as a third required edit.

- **§7.6 End-to-end smoke test** only exercises the pack surface
  (`--surface pack`). A symmetric `--surface client` smoke test against a
  built client fixture would have surfaced the regression before commit.

- **§11 DoD checklist** is internally complete for the pack-side framing
  but does not include a "client-side `pack help` substitution fires" item,
  which is the missing verification.

**Verdict on the IMPL-REPORT:** Honest and well-organized within the
framing the coder adopted; the gap is in the framing itself, which
treated BD-177 as pack-side-only when in fact the regex modification
affects both surfaces because `emit_fragment()` is called from both
branches.

---

## §4 Severity-classified findings table

| # | Severity | Finding | Locus | Recommended action |
|---|---|---|---|---|
| F1 | **BLOCKER** | New awk regex at `scripts/pack-help.sh:86` does not match the client-side sentinel at `project-template/docs/pack/HELP-FRAGMENT.md:26`. Substitution silently fails; literal sentinel becomes user-visible in `pack help` output on client surface. Reproduced against ad-hoc fixture AND built `test-fixtures/v11-flat-file`. | `scripts/pack-help.sh:86` regex + `project-template/docs/pack/HELP-FRAGMENT.md:26` sentinel | Fix in two steps: (a) broaden regex to match both sentinel forms (e.g., `^\[Included from \`(pack-ops\/)?HELP-FRAGMENT-TRACKER\.md\``), OR (b) parallel-update client sentinel and adopt a common form. If (b), also regenerate manifest. See §5 below for proposed regex options. |
| F2 | **MUST** | Test 2.2 ("client tracker section inlined") substring check `*"# Tracker commands (v11+)"*` matches the parent H2 in the placeholder, not the inlined fragment body. Test passes by false-positive; would NOT catch a client-side substitution regression. Pre-existing gap, but BD-177 exposed it. | `scripts/tests/pack-help-test.sh:124-126` | Tighten test 2.2 to assert against fragment-body content (e.g., `*"set up the tracker"*` from `HELP-FRAGMENT-TRACKER.md:38`) — analogous to test 2.1 line 104. Either as part of BD-177 fix or as a new defect entry. |
| F3 | **SHOULD** | IMPL-REPORT §1, §4, §11 generalize "pack-side test passes" to "substitution behavior preserved" without testing client-side. The pack-coder's framing missed the cross-surface coupling. | IMPL-REPORT framing | If F1 is fixed in a follow-up commit, update IMPL-REPORT to acknowledge the framing miss and add a client-side smoke-test step to §7. |
| F4 | **NIT** | L83 comment in `scripts/pack-help.sh` describes the pack-side sentinel form only; given `emit_fragment()` is called from both surfaces, the comment is incomplete. | `scripts/pack-help.sh:83` | Expand the comment to document both sentinel forms (or, if F1 is fixed by broadening the regex, document the broadened pattern). |

---

## §5 Recommended fix shapes for F1 (BLOCKER)

Two viable approaches; both retain the BD-177 path-accuracy goal:

### Option A: broaden the regex to accept optional `pack-ops/` prefix

```bash
/^\[Included from `(pack-ops\/)?HELP-FRAGMENT-TRACKER\.md`/ {
```

Pros: Single source-of-truth regex; matches both sentinels; minimal
edit footprint (1 line in pack-help.sh).

Cons: BSD awk regex grouping syntax (`(…)?` for optional non-capturing
group) may have portability concerns across awk implementations — needs
testing on the macOS BSD awk and GNU awk that CI uses. (BSD awk does
support extended regex via the `-E` flag or POSIX `awk -e`; the current
awk pattern uses BRE which doesn't support `?` for optional groups — F1A
needs verification.)

### Option B: update client sentinel + regenerate manifest

Update `project-template/docs/pack/HELP-FRAGMENT.md:26` to:

```
[Included from `HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]
```

(Or any form that matches the bare-filename pattern, since "in this directory"
was descriptive flavor.) Adjust regex to match the bare-filename form (which
is what the pre-BD-177 regex did). Then the regex matches both surfaces
again, just by dropping the path qualifier.

OR: parallel-update client sentinel to `pack-ops/HELP-FRAGMENT-TRACKER.md`
form — but this is path-INACCURATE for the client install (tracker file lives
at `docs/pack/HELP-FRAGMENT-TRACKER.md`, not `pack-ops/`).

Pros: Restores symmetry; simple regex; portable.

Cons: Requires regen of manifest (project-template touched); broader edit
footprint.

### Option C: keep pack-side regex; carve out client-side branch

Make `emit_fragment()` take a third argument (the expected sentinel prefix)
and pass `pack-ops/` for pack surface, bare for client surface.

Pros: Cleanly separates the two surface concerns; precise about which
sentinel is matched where.

Cons: Larger refactor than appropriate for a ~10-minute coordinated-fix BD.

**Reviewer recommendation:** Option B is the cleanest minimal fix — preserves
the BD-177 path-accuracy goal for the pack-side, restores client-side
substitution, and keeps regex portable. Option A is also viable if BSD/GNU
awk both support the regex; needs a portability check before adoption.

---

## §6 Verification commands run + output

### §6.1 pack-help-test.sh

```
$ bash scripts/tests/pack-help-test.sh
=== Group 1: detect_pack_surface ===
  PASS 1.1 pack repo → pack-surface: pack
  PASS 1.2 client repo (docs/project/) → pack-surface: client
  PASS 1.3 client repo (root BACKLOG.md, TD entries) → client
  PASS 1.4 mixed BD + TD → ambiguous
  PASS 1.5 no BACKLOG.md → ambiguous

=== Group 2: pack-help.sh end-to-end ===
  PASS 2.1 pack-side header present
  PASS 2.1 pack commands section present
  PASS 2.1 tracker section inlined
  PASS 2.1 colloquial mapping inlined
  PASS 2.1 placeholder line replaced
  PASS 2.2 client-side header present
  PASS 2.2 client tracker section inlined          <-- FALSE POSITIVE per F2
  PASS 2.2 client-only verb (agent-run) listed
  PASS 2.3 --surface pack override prints pack fragment
  PASS 2.4 missing fragments → helpful stderr
  PASS 2.5 inline preserves surrounding lines + replaces placeholder
  PASS 2.6 unknown flag → typed error

Passed: 17  Failed: 0
```

### §6.2 validate-pack.py

```
$ python3 scripts/validate-pack.py 2>&1 | tail -5
============================================================
PASSED — all checks clean
```

Exit 0.

### §6.3 Persona contracts

```
$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -1
=== greenfield contract: 191 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -1
=== mid-dev contract: 25 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -1
=== migration contract: 37 passed, 0 failed ===
```

Combined 253/0.

### §6.4 Manifest verify

```
$ bash test-fixtures/build.sh --verify 2>&1 | tail -7
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: e7ddf08128edc087ea827d6724965dde6ff42d20
  v11-flat-file OK: c7a5bc9d9815671c0ecfdaf0a8f5dbcbc7542095
  v11-tracker-on OK: 544b8ebc24e8a701b2786b656a0d878aff1573ae
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

### §6.5 Client-surface regression reproduction (proves F1)

Method 1 — ad-hoc client fixture:

```
$ rm -rf /tmp/ph-test-client
$ mkdir -p /tmp/ph-test-client/docs/pack /tmp/ph-test-client/docs/project
$ cp project-template/docs/pack/HELP-FRAGMENT.md /tmp/ph-test-client/docs/pack/
$ cp project-template/docs/pack/HELP-FRAGMENT-TRACKER.md /tmp/ph-test-client/docs/pack/
$ printf '**TD-001**\nStatus: Open\n' > /tmp/ph-test-client/docs/project/BACKLOG.md
$ bash scripts/pack-help.sh --root /tmp/ph-test-client 2>&1 | sed -n '/Tracker commands/,/See also/p'

## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]    <-- REGRESSION

## See also
```

Method 2 — built fixture (proves regression survives `build.sh --all --clean`):

```
$ bash scripts/pack-help.sh --root test-fixtures/v11-flat-file 2>&1 | sed -n '/Tracker commands/,/See also/p'

## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]    <-- REGRESSION

## See also
```

Pre-BD-177 baseline (verified via `git show HEAD~1:scripts/pack-help.sh`):
the prior regex `/^\[Included from \`HELP-FRAGMENT-TRACKER\.md\`/` matched
the bare-filename prefix that BOTH sentinels share, so substitution fired
on both surfaces.

### §6.6 Cross-reference grep for sentinel forms in source

```
$ grep -rn "Included from" --include="*.md" --include="*.sh" . 2>/dev/null \
    | grep -v ".git/" | grep -v "maintenance-docs/" | grep -v "pack-ops/BACKLOG"

project-template/docs/pack/HELP-FRAGMENT.md:26:[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]
pack-ops/HELP-FRAGMENT-PACK.md:37:[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]
scripts/pack-help.sh:83:    # The placeholder line is `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` ...]`.
scripts/pack-help.sh:86:        /^\[Included from `pack-ops\/HELP-FRAGMENT-TRACKER\.md`/ {
scripts/tests/pack-help-test.sh:107:[[ "$output" != *"[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\`"* ]] \
scripts/tests/pack-help-test.sh:159:[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `pack-help.sh`.]
```

Two sentinel forms in the source tree:
- `pack-ops/HELP-FRAGMENT-TRACKER.md` form (pack-side; matches new regex)
- `HELP-FRAGMENT-TRACKER.md` (no prefix) form (client-side; does NOT match new regex)

### §6.7 HELP-FRAGMENT-TRACKER.md location

```
$ ls pack-ops/HELP-FRAGMENT-TRACKER.md
pack-ops/HELP-FRAGMENT-TRACKER.md

$ ls HELP-FRAGMENT-TRACKER.md 2>&1
ls: HELP-FRAGMENT-TRACKER.md: No such file or directory
```

---

## §7 Out-of-scope observations

### §7.1 Test 2.2 weakness (pre-existing; should be fixed regardless of BD-177 outcome)

Test 2.2 should adopt the same strong-check pattern as test 2.1:

```bash
[[ "$output" == *"set up the tracker"* ]] \
    && t_pass "2.2 client tracker section inlined" \
    || t_fail "2.2 client tracker section inlined"
```

Either as part of BD-177's BLOCKER fix or as a follow-up BD. (Recommend
folding into BD-177 fix since it would have caught F1 if it had been
present.)

### §7.2 No analogous client-side `--surface client` test using built/canonical project-template fixture

Test 2.2 uses a `mktemp -d` fixture and `cp`-copies the project-template
files at test time, which means any drift in the `cp`'d copies would also
be silently masked. A counterpart to test 2.3 (`--surface pack override`
against `test-fixtures/v11-flat-file`) on the client side would be a
stronger regression guard.

### §7.3 IMPL-REPORT length (~484 lines)

Per pack memory "Chunk long agent-output writes" the IMPL-REPORT exceeds
the ~300-line threshold and should have been written in chunked Edit calls
rather than a single Write. Operational nit, not a defect.

### §7.4 Trinity exemption N/A

No trinity-file edits (CLAUDE.md / AGENTS.md / GEMINI.md at pack root or
project-template). No trinity-rule concerns. PASS.

### §7.5 BACKLOG entry

BD-177's BACKLOG entry at `pack-ops/BACKLOG.md:1453-1475` is well-scoped
for the framing the coder adopted. The entry itself does not flag the
client-side coupling — recommend a one-line update on resolution to note
that "coordinated edit also requires updating client sentinel at
`project-template/docs/pack/HELP-FRAGMENT.md:26` and/or broadening the
regex" so future readers see why the BD-177 fix needed a follow-up.

---

## §8 Summary verdict

**BLOCKER.** Do NOT flip BD-177 to Resolved until F1 is addressed. The
coordinated fix correctly closes the pack-side staleness but silently
opens a client-side regression of the same shape (and worse — the
client regression IS user-visible per §6.5 reproductions). Recommended
fix is Option B in §5 (parallel-update client sentinel to a common
bare-filename form + adjust regex) or Option A pending awk-portability
check.

**MUST.** Fix test 2.2 false-positive (F2) so the test suite would catch
this class of regression in future. Recommend folding into the F1 fix
commit.

**SHOULD.** Update IMPL-REPORT framing after F1 fix to acknowledge the
two-surface coupling.

**NIT.** Update L83 comment to reflect whichever regex shape lands.

All other checks GREEN. Manifest correct. Scope discipline correct.
PREFLIGHT line emitted. Persona contracts + validate-pack.py independently
verified.
