# PACK-REVIEW — BD-219 C4 (`project-only`)

**Reviewer:** pack-reviewer (fresh instance)
**Date:** 2026-06-15
**Branch:** v11-dev
**HEAD SHA:** 26a0179ecc8e00761c53c80e0f60bf0752a58b48
**Regime:** IN-PLACE; reviewed via `git diff` (change applied, NOT committed)

---

## VERDICT: APPROVE-WITH-FIXES

Boundary discipline, scope, manifest carve-out, and the full CI suite are
all CLEAN. One SHOULD-level technical defect: the `plan`-job `echo`
example in the "How to enable" block produces **invalid JSON** if
copy-pasted (bare double-quotes nested inside a double-quoted shell
string), which `fromJSON()` would reject — the section's enabling example
does not actually work as written.

---

## Findings

### F-1 (SHOULD) — broken `plan`-job example: nested double-quotes yield invalid JSON

The "How to enable" → step 1 (`plan` job) snippet:

```
$ git diff -- project-template/docs/pack/OPTIONAL-FEATURES.md | grep -n GITHUB_OUTPUT
48:+         run: echo "matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}" >> "$GITHUB_OUTPUT"
```

The literal JSON `{"include":[...]}` is embedded inside a **double-quoted**
`echo "matrix=...">>"$GITHUB_OUTPUT"`. In POSIX shell, each inner `"`
closes/reopens the quoted region, so the shell strips the quotes around
`include` / `suite` / `unit` / `integration`. The value actually written
to `$GITHUB_OUTPUT` is `matrix={include:[{suite:unit},{suite:integration}]}`
— **not valid JSON** — and the downstream `tests` job
(`matrix: ${{ fromJSON(needs.plan.outputs.matrix) }}`) fails to parse it.
The example, copy-pasted, does not work.

**Attribution (not inherited from spec):** the architecture spec's own
pack-side `plan` job is correct because the JSON comes from a command
substitution, not a literal:

```
$ grep -n 'GITHUB_OUTPUT' maintenance-docs/v11-implementation/ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md
125:        run: echo "matrix=$(python3 scripts/lib/ci-shard-plan.py --emit-matrix)" >> "$GITHUB_OUTPUT"
```

With `$(...)`, the double-quoted string contains no literal inner quotes,
so double-quoting is correct. The C4 coder adapted that command-sub form
into a **static literal** without switching to single-quotes — introducing
the bug. Spec §7.3 only prescribes the prose ("dynamic matrix +
aggregation job"), not this exact broken snippet, so this is a C4-coder
defect.

**Fix (trivial; one line):** single-quote the static JSON so the shell
does not strip the inner quotes, e.g.
`run: echo 'matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}' >> "$GITHUB_OUTPUT"`
(or use a heredoc). The prompt asked to verify "the content is correct,
generic GitHub-Actions advice (no factual errors)"; this example is
factually broken as written, hence SHOULD not NIT.

> Note: the rest of the GHA advice is sound — `fail-fast: false` to
> surface all suite failures, an `if: always()` aggregation job as the
> single stable required status check, the required-status-check rename
> consideration, and the four caveats (suite independence, per-shard
> fixture-build cost, slow-single-test floor, mandatory `fail-fast:
> false`) are all correct.

---

## Boundary-compliance confirmation (THE #1 check — P-missed-7) — CLEAN

The added section is PROJECT-NATIVE with ZERO pack-self leakage.

**Added-lines grep (forbidden tokens):**

```
$ git diff -- project-template/docs/pack/OPTIONAL-FEATURES.md | grep '^+' | grep -v '^+++' \
    | grep -nE 'BD-|pack-ops|maintenance-docs|ci-shard-plan|validate-pack|pack-coder|pack-architect|pack-reviewer|pack-planner|pack-docs-researcher|Pack Chat|PACK-AGENTS|PACK-CHAT|pack-only|pack-chat-only'
EXIT=1        # zero matches
```

**Full-file grep (no leak anywhere in the file):**

```
$ grep -nE 'BD-[0-9]|validate-pack|pack-ops|maintenance-docs|ci-shard-plan|pack-coder|pack-architect|pack-reviewer|pack-planner|Pack Chat|PACK-AGENTS|PACK-CHAT' project-template/docs/pack/OPTIONAL-FEATURES.md
===FULLFILE_EXIT=1===     # zero matches
```

**Bare `pack-` token — one BENIGN hit (not a leak):**

```
$ git diff -- ...OPTIONAL-FEATURES.md | grep '^+' | grep -v '^+++' | grep -nE 'pack-'
80:+**No pack-specific setup needed.** Your project's existing test scripts
```

`"pack-specific"` is the adjective for the AI Agent Config Pack product —
the established CLIENT-FACING name used throughout this same file (lines
6, 84, 101, 179, 216, 256, 269, 423, 426-427: "the pack ships NO settings
file", "the pack does not ship...", "pack-controlled directories"). It is
NOT a `pack-*` agent name, `pack-ops/` path, or `maintenance-docs/`
reference. Benign and convention-consistent.

**`tests` / `tests-result` job names are CLIENT-CI generic, not the pack's
own `tests` job:** the section's example runs `bash scripts/test-${{
matrix.suite }}.sh` and names the CLIENT's own scripts (`scripts/test.sh`,
`scripts/test-swift.sh`, `scripts/test-python.sh` — per
`project-template/CLAUDE.md` § Scripts). No reference to the pack's
internal sharding work or `validate-pack` battery.

**Leak-scanner test (Check 43, the project-side leak guard):**

```
$ bash scripts/tests/test-validate-pack-check-43.sh ; echo exit=$?
  PASS: 9   FAIL: 0   All tests passed.
exit=0
```

Boundary verdict: project-native, zero pack-self leak. P-missed-7
SATISFIED.

---

## Scope confirmation (`project-only`) — CLEAN

```
$ git status --short
 M project-template/docs/pack/OPTIONAL-FEATURES.md
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C4.md
```

- `project-template/docs/pack/OPTIONAL-FEATURES.md` (M) — the project-side
  client deliverable. The only source change.
- `test-fixtures/manifest.txt` (M) — pack-side generated artifact, but
  permitted in a `project-only` commit by the Check-36 carve-out (see
  below). Not a scope offender.
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C4.md` (??) —
  untracked audit doc, NOT part of the C4 source change. Pack Chat does
  not stage it into the C4 commit.

NO pack-only source path touched: no `pack-ops/`, no `scripts/` source, no
`.github/workflows/`, no `maintenance-docs/` (except the separate
untracked IMPL-REPORT). `commit-subject-keyword-token-trap`: the
`project-only` keyword claim is genuine — the only non-project file is the
scope-neutral manifest.

---

## Manifest carve-out + determinism confirmation — CLEAN

**Carve-out constant (exact, sized to one path):**

```
$ sed -n '4149,4151p' scripts/validate-pack.py   # (read via Read tool)
_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({
    "test-fixtures/manifest.txt",
})
```

`_is_scope_neutral_generated()` (validate-pack.py ~L4281) docstring:
"Such paths are not offenders in either `project-only` or `pack-only`
commits." So Check 36 does NOT flag the manifest under the `project-only`
keyword.

**Manifest diff = the 3 v11 fixture rows only (v10 + existing-project
rows unchanged):**

```
$ git diff --numstat -- test-fixtures/manifest.txt
3	3	test-fixtures/manifest.txt
```

The 3 changed rows are `v11-realistic-ot`, `v11-flat-file`,
`v11-tracker-on` — expected, because v11 fixtures incorporate
`project-template/`, so the OPTIONAL-FEATURES.md edit re-hashes them.

**Reproduces byte-identically (deterministic; not stray noise):**

```
$ cp test-fixtures/manifest.txt /tmp/manifest-before.txt
$ bash test-fixtures/build.sh --all --clean   # build_exit=0
$ diff /tmp/manifest-before.txt test-fixtures/manifest.txt && echo MANIFEST_REPRODUCES_IDENTICAL
MANIFEST_REPRODUCES_IDENTICAL
```

The staged manifest is exactly what `build.sh --all --clean` emits against
the current tree. `regenerate-manifest-v11-surface` SATISFIED.

---

## CI-green confirmation (verify-full-ci-suite) — CLEAN

| Check | Command | Exit / result |
|---|---|---|
| validate-pack general | `python3 scripts/validate-pack.py` | exit 0 — "PASSED — all checks clean" |
| validate-pack deep | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | exit 0 — "PASSED — all checks clean" |
| Check 54 (OPTIONAL-FEATURES presence) | `bash scripts/tests/test-validate-pack-check-54.sh` | exit 0 — PASS 3 / FAIL 0 |
| Check 43 (project-side leak scanner) | `bash scripts/tests/test-validate-pack-check-43.sh` | exit 0 — PASS 9 / FAIL 0 |

All four green. (F-1 is a content correctness issue inside the prose
example — no validator asserts the snippet's runnability, so CI is green
despite the broken example.)

---

## Convention confirmation — CLEAN

The file's "Adding new entries" convention (line 421-428) prescribes:
*Status, What it is, When it matters, How to enable, How to use the pack's
pieces with it, Caveats, When to skip.*

The new section provides: **Status**, **What it is**, **When this matters
for your project**, **How to enable**, *(Required-status-check rename
consideration)*, *(No pack-specific setup needed)*, **Caveats**, **When to
skip**. The "How to use the pack's pieces with it" slot is correctly
adapted to "No pack-specific setup needed" — because this is a generic
GitHub-Actions technique, not a pack-shipped feature with pieces to wire.
Architecture §7.3 explicitly anticipated this adaptation. Shape is
faithful and matches the §7.3 project-side spec (content, vocabulary,
exclusions).

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **boundary-investigation / P-missed-7** | Added-lines forbidden-token grep `EXIT=1` (zero); full-file grep `FULLFILE_EXIT=1` (zero); only `pack-` hit = benign client adjective "pack-specific" (file uses "the pack" client-facing at lines 6/84/101/179/216/256/269/423-427); leak scanner Check 43 exit 0 (9/9). `tests` job names are CLIENT-CI generic (`scripts/test-*.sh`), not the pack's own. | COMPLIANT |
| **pack-project-separation-of-concerns** | Section authored in client vocabulary ("your project's CI", "your workflow", "your branch protection"); matches §7.3 project-side spec; no copy from pack-side artifact; manifest carve-out keeps the pack-side generated file out of scope. | COMPLIANT |
| **empirical-evidence-blocks** | Every finding carries the command + verbatim output + HEAD-SHA (26a0179) + date (2026-06-15); reproduced manifest via `build.sh` + `diff` (MANIFEST_REPRODUCES_IDENTICAL). | COMPLIANT |
| **commit-subject-keyword-token-trap** | `git status --short` → only `OPTIONAL-FEATURES.md` (project) + `manifest.txt` (carve-out, scope-neutral). No pack-only source path. `project-only` keyword claim genuine. | COMPLIANT |
| **verify-full-ci-suite** | validate-pack general exit 0; deep exit 0; Check 54 exit 0 (3/3); Check 43 exit 0 (9/9) — all quoted above. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Exactly one `##` section added (`git diff --numstat` OPTIONAL-FEATURES = single contiguous block); no unrelated edits; no scope creep. | COMPLIANT |
| **agents-never-commit** | Read-only git only: `git rev-parse`, `git status`, `git diff`, `git diff --numstat`. No state-changing verb. `build.sh` is a build script (regenerated the already-staged manifest, tree byte-identical after). Sole write = this review doc. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal conclusion; no empty evidence; no AMBIGUOUS state. | COMPLIANT |

---

## Recommendation to Pack Chat

APPROVE-WITH-FIXES. Route **F-1** (single-quote the static `plan`-job JSON
so the enabling example actually parses) to a fix-coder before the C4
commit lands. Triviality: one-line edit to one fenced code block in
`OPTIONAL-FEATURES.md`; will re-touch the manifest (carve-out still
applies). Boundary, scope, and CI are otherwise clean.
