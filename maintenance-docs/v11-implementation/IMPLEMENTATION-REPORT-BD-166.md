# IMPLEMENTATION-REPORT-BD-166.md — Commit 19d: init-project.sh greenfield per-entry tree install

**Batch:** 19 (per-entry split) | **Commit:** 19d | **BD:** BD-166
**Branch:** `v11-dev`
**Pre-implementation HEAD:** `a5b4a6eb78d67cb143fefce6020f7bb66d135af9`
**Final HEAD (post-implementation, pre-commit):** `a5b4a6eb78d67cb143fefce6020f7bb66d135af9` (unchanged — agent does not commit per pack rule)
**Implementer:** pack-coder

---

## §1 — Summary

Extended `stage_s11_v11_artifacts` in `scripts/init-project.sh` with two
new sub-steps that install the v11.0 per-entry tree skeleton on the
greenfield client-init pathway. Sub-step 6 copies the 7 canonical
templates from `project-template/docs/project/<stream>/` into the
client's `docs/project/<stream>/` (project-side asymmetry preserved:
`backlog` and `implementation-plan` get `_rules.md` + `_intro.md`;
`changelog` gets `_rules.md` + `_intro.md` + `_format.md`). Sub-step 7
(greenfield-only — `CLASS == new-*`) sources the BD-164 per-entry
helpers and invokes the mirror generator + TOC regenerator against
each of the three project streams to produce empty mirrors at
`docs/project/{BACKLOG.md, IMPLEMENTATION-PLAN.md, CHANGELOG.md}` and
empty seed `_toc.md` files inside each stream directory. The
extend-S11 disposition (vs. new-S11b stage) is honored per integration
parent §8.17 + §18.1 #5. Helper reuse pattern preserved per §9.3 — the
same BD-164 helpers now serve three call sites (v10→v11 migrator,
init-project.sh greenfield path, and future tracker-mode transitions).
Existing-* class path is explicitly skipped for mirror+TOC regen to
avoid silently overwriting client-customized monolithic files; per-entry
template copies still go through the prevailing `$copy_fn` /
`existing_classifier_copy` pattern so customized supporting files
surface as `.pack-template` sidecars (BD-088 territory).

---

## §2 — Files modified / created table

| Path | Pre-lines | Post-lines | Net | Type |
|---|---|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh` | 1178 | 1305 | +127 | modified |

No files created. No files deleted. Pre-existing PM-only files,
trinity files, pack-* agent files, and `project-template/docs/project/`
canonical templates were NOT touched.

---

## §3 — Per-file change detail

### `scripts/init-project.sh`

**Function modified:** `stage_s11_v11_artifacts` (single function;
existing sub-steps 1..5 unchanged; new sub-steps 6 and 7 appended).

**Before — function tail (last existing sub-step):**

```bash
    mkdir -p "$TARGET/scripts/lib"
    if [[ -f "$PACK/scripts/pack-help.sh" ]]; then
        cp -f "$PACK/scripts/pack-help.sh" "$TARGET/scripts/pack-help.sh"
        chmod +x "$TARGET/scripts/pack-help.sh"
    fi
    if [[ -f "$PACK/scripts/lib/detect.sh" ]]; then
        cp -f "$PACK/scripts/lib/detect.sh" "$TARGET/scripts/lib/detect.sh"
    fi
    [[ -x "$TARGET/scripts/pack-help.sh" ]] \
        || fail_stage S11 "scripts/pack-help.sh missing or not executable after copy"
    [[ -f "$TARGET/scripts/lib/detect.sh" ]] \
        || fail_stage S11 "scripts/lib/detect.sh missing after copy"
}
```

**After — function tail (sub-steps 6 + 7 added before closing brace):**

```bash
    [[ -f "$TARGET/scripts/lib/detect.sh" ]] \
        || fail_stage S11 "scripts/lib/detect.sh missing after copy"

    # 6. Per-entry tree skeleton install (BD-166).
    #    Ships the project-side per-entry source-of-truth surface so
    #    a greenfield v11 client has the v11.0-shape skeleton from
    #    the first init. Three streams (backlog, implementation-plan,
    #    changelog) each get `_rules.md` + `_intro.md`; project-
    #    changelog also gets `_format.md` (project-side asymmetry per
    #    ARCHITECTURE-PER-ENTRY-SPLIT.md §3.5 + §11). No entry files
    #    (`TD-NNN.md`, `phase-N.md`, `YYYY-MM-DD-*.md`) — greenfield
    #    starts empty; entries are authored client-side. No `_toc.md`
    #    written directly — the BD-164 TOC regenerator (step 7 below
    #    for greenfield) produces it as the empty seed.
    #
    #    Canonical templates are pack-shipped immutable per integration
    #    parent §3.3 + §9.7. We use `$copy_fn` so existing-* re-runs
    #    go through the `existing_classifier_copy` path (a
    #    customized `_rules.md` is preserved with the pack version
    #    written as a `.pack-template` sidecar for manual reconcile;
    #    BD-088 truthful-report territory).
    local pe_src pe_dst
    pe_src="$PACK/project-template/docs/project"
    pe_dst="$TARGET/docs/project"
    [[ -d "$pe_src/backlog" && -d "$pe_src/implementation-plan" && -d "$pe_src/changelog" ]] \
        || fail_stage S11 "canonical per-entry templates missing under project-template/docs/project/ (BD-167 install incomplete)"

    mkdir -p "$pe_dst/backlog" "$pe_dst/implementation-plan" "$pe_dst/changelog"

    # backlog: _rules.md + _intro.md (no _format.md).
    [[ -f "$pe_src/backlog/_rules.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/backlog/_rules.md"
    [[ -f "$pe_src/backlog/_intro.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/backlog/_intro.md"
    "$copy_fn" "$pe_src/backlog/_rules.md" "$pe_dst/backlog/_rules.md"
    "$copy_fn" "$pe_src/backlog/_intro.md" "$pe_dst/backlog/_intro.md"

    # implementation-plan: _rules.md + _intro.md.
    [[ -f "$pe_src/implementation-plan/_rules.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/implementation-plan/_rules.md"
    [[ -f "$pe_src/implementation-plan/_intro.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/implementation-plan/_intro.md"
    "$copy_fn" "$pe_src/implementation-plan/_rules.md" "$pe_dst/implementation-plan/_rules.md"
    "$copy_fn" "$pe_src/implementation-plan/_intro.md" "$pe_dst/implementation-plan/_intro.md"

    # changelog: _rules.md + _intro.md + _format.md (project-side asymmetry).
    [[ -f "$pe_src/changelog/_rules.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/changelog/_rules.md"
    [[ -f "$pe_src/changelog/_intro.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/changelog/_intro.md"
    [[ -f "$pe_src/changelog/_format.md" ]] \
        || fail_stage S11 "canonical template missing: project-template/docs/project/changelog/_format.md"
    "$copy_fn" "$pe_src/changelog/_rules.md" "$pe_dst/changelog/_rules.md"
    "$copy_fn" "$pe_src/changelog/_intro.md" "$pe_dst/changelog/_intro.md"
    "$copy_fn" "$pe_src/changelog/_format.md" "$pe_dst/changelog/_format.md"

    # 7. Empty-seed mirror + TOC regenerate (greenfield path only).
    #    [comment continues — see file for full block]
    if [[ "$CLASS" == new-* ]]; then
        # Source the BD-164 per-entry helpers. Helpers live at
        # $PACK/scripts/lib/per-entry/. Guard each source with a `type`
        # check so re-sourcing is a no-op (matches the per-entry
        # helpers' own convention at
        # scripts/lib/per-entry/decompose.sh:30-33 and the migrator-
        # private adapter at
        # scripts/lib/migrate-v10-to-v11/decompose.sh:85-100).
        local _pe_lib_dir="$PACK/scripts/lib/per-entry"
        [[ -d "$_pe_lib_dir" ]] \
            || fail_stage S11 "per-entry helpers missing at $_pe_lib_dir (BD-164 install incomplete)"
        if ! type pe_die >/dev/null 2>&1; then
            # shellcheck disable=SC1091
            . "$_pe_lib_dir/_lib.sh"
        fi
        if ! type per_entry_regenerate_mirror >/dev/null 2>&1; then
            # shellcheck disable=SC1091
            . "$_pe_lib_dir/mirror-generate.sh"
        fi
        if ! type per_entry_regenerate_toc >/dev/null 2>&1; then
            # shellcheck disable=SC1091
            . "$_pe_lib_dir/toc-regenerate.sh"
        fi

        # Three project-side streams. Each tuple: stream_key + relative
        # mirror filename + relative stream directory. Same shape as the
        # v10→v11 migrator's _v10_to_v11_decompose_streams loop at
        # scripts/lib/migrate-v10-to-v11/decompose.sh:145-148.
        local pe_spec pe_key pe_mirror_rel pe_dir_rel pe_mirror pe_dir pe_rest
        for pe_spec in \
            "project-backlog|docs/project/BACKLOG.md|docs/project/backlog" \
            "project-implementation-plan|docs/project/IMPLEMENTATION-PLAN.md|docs/project/implementation-plan" \
            "project-changelog|docs/project/CHANGELOG.md|docs/project/changelog"; do
            pe_key="${pe_spec%%|*}"
            pe_rest="${pe_spec#*|}"
            pe_mirror_rel="${pe_rest%%|*}"
            pe_dir_rel="${pe_rest##*|}"
            pe_mirror="$TARGET/$pe_mirror_rel"
            pe_dir="$TARGET/$pe_dir_rel"

            # Empty-seed mirror generate. </dev/null detaches stdin so
            # the regenerator's interactive divergence branch
            # (pe_is_interactive) does not fire — greenfield should
            # never see divergence (mirror is absent → fresh write).
            per_entry_regenerate_mirror "$pe_key" "$pe_dir" "$pe_mirror" </dev/null \
                || fail_stage S11 "per_entry_regenerate_mirror failed for $pe_key (greenfield empty mirror)"

            # Empty-seed TOC regenerate. Always produces _toc.md.
            per_entry_regenerate_toc "$pe_key" "$pe_dir" \
                || fail_stage S11 "per_entry_regenerate_toc failed for $pe_key (greenfield empty TOC)"
        done

        info "per-entry tree skeleton + empty mirrors installed under docs/project/{backlog,implementation-plan,changelog}/"
    fi
}
```

**Design notes:**

1. **Disposition: extend S11 (not new S11b).** Per integration parent
   §8.17 + §18.1 #5 explicit recommendation: extend `stage_s11_v11_artifacts`,
   do NOT add a new `stage_s11b_per_entry_tree` stage. New sub-steps
   numbered 6 (template install) and 7 (greenfield-only mirror+TOC
   regen) following the existing 1..5 sub-step convention.

2. **Helper-source pattern.** Sources the BD-164 helpers via
   `$PACK/scripts/lib/per-entry/` (vs. `BASH_SOURCE`-relative).
   Rationale: `init-project.sh` already uses `$PACK` for all
   pack-resource lookups; consistency. Source guards (`type ... 2>&1`)
   match the convention at `scripts/lib/per-entry/decompose.sh:30-33`
   and `scripts/lib/migrate-v10-to-v11/decompose.sh:85-100` — re-sourcing
   is a no-op.

3. **Greenfield-only mirror+TOC regen (`CLASS == new-*`).** The plan's
   binding "Existing-* class path is preserved... do NOT silently
   overwrite existing client-customized per-entry files" is honored
   by gating the mirror+TOC regen block behind `CLASS == new-*`.
   Template-copy (sub-step 6) still goes through `$copy_fn` for both
   greenfield (`cp`) and existing-* (`existing_classifier_copy`) so a
   customized `_rules.md`/`_intro.md`/`_format.md` in an existing-*
   target surfaces a `.pack-template` sidecar per BD-088 contract.

4. **`fail_stage S11` error handling.** Every missing-canonical-template
   precondition and every helper-failure path calls `fail_stage S11`
   matching the existing S11 error pattern (e.g., line 825 / 827 / 881 /
   883). Exit code = 20 + 11 (clamped to 30) per the existing scheme.

5. **`</dev/null` on mirror regen.** Detaches stdin from the mirror
   regenerator so its interactive-divergence branch (`pe_is_interactive`)
   does not fire when init-project.sh itself is invoked from a
   non-tty context. Greenfield should never hit divergence anyway —
   the mirror is absent on first install, so the helper takes the
   "no prior mirror → write fresh" branch at
   `scripts/lib/per-entry/mirror-generate.sh:221`.

6. **Bash 3.2 + BSD compatibility.** No associative arrays — pipe-
   delimited tuple strings with `${var%%|*}` / `${var#*|}` / `${var##*|}`
   parsing match the migrator-private decompose helper pattern at
   `scripts/lib/migrate-v10-to-v11/decompose.sh:145-152`. No `&>`. No
   GNU-only flags.

---

## §4 — Verification

### §4.1 — Syntax + validator

```text
$ bash -n scripts/init-project.sh && echo SYNTAX_OK
SYNTAX_OK

$ python3 scripts/validate-pack.py 2>&1 | tail -5
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

### §4.2 — Test suite baselines (zero regression)

```text
$ bash scripts/tests/test-init-project.sh 2>&1 | tail -3
=== Summary ===
Passed: 34
Failed: 0
All tests passed.
```

(Baseline pre-change: 34/34 PASS. Post-change: 34/34 PASS. Zero regression.)

```text
$ bash scripts/tests/test-per-entry.sh 2>&1 | tail -3
=== Summary ===
PASS: 57
FAIL: 0

All per-entry tests PASSED (57/57).
```

```text
$ bash scripts/tests/test-migrate-v10-to-v11.sh 2>&1 | tail -3
Passed: 43
Failed: 0
All tests passed.
```

```text
$ bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh 2>&1 | tail -3
Passed: 61
Failed: 0
All BD-095 tests passed.
```

```text
$ bash scripts/tests/test-migrate-v10-to-v11-gates.sh 2>&1 | tail -3
Passed: 87
Failed: 0
All BD-101 gate tests passed.
```

```text
$ bash scripts/tests/tracker-agent-read-test.sh 2>&1 | tail -3
Passed: 31
Failed: 0
All tests passed.
```

### §4.3 — Manual integration smoke test (greenfield init)

**Setup:** fresh `git init`'d directory at `/tmp/test-greenfield-v11d-bd166`,
empty initial commit, then run init-project.sh with `PACK` pointing
to this pack repo.

```text
$ SMOKE=/tmp/test-greenfield-v11d-bd166 && rm -rf "$SMOKE" \
    && git init -q "$SMOKE" \
    && cd "$SMOKE" \
    && git config user.email "smoke@local" && git config user.name "Smoke" \
    && git commit --allow-empty -q -m initial \
    && PACK=/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev \
       bash /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh \
         "$SMOKE" <<<"y" 2>&1 | tail -10
── S11 — v11 client artifacts (HELP-FRAGMENT, tracker, issue forms, pack-help) ──
  per-entry tree skeleton + empty mirrors installed under docs/project/{backlog,implementation-plan,changelog}/
── S10 — generate end-of-run PM chat kickoff prompt ──
[... kickoff prompt elided ...]
Initialization complete. Review `git diff` / `git status`, then
start a PM chat session with the kickoff prompt above.
```

**Verification item 1 — `docs/project/backlog/`** contains `_rules.md`,
`_intro.md`, `_toc.md`, and no `TD-NNN.md` entry files:

```text
$ ls -1 /tmp/test-greenfield-v11d-bd166/docs/project/backlog/
_intro.md
_rules.md
_toc.md

$ ls /tmp/test-greenfield-v11d-bd166/docs/project/backlog/ | grep -vE "^_"
(empty — confirmed no entry files)
```

**Verification item 2 — `docs/project/implementation-plan/`** contains
`_rules.md`, `_intro.md`, `_toc.md`, no `phase-N.md` files:

```text
$ ls -1 /tmp/test-greenfield-v11d-bd166/docs/project/implementation-plan/
_intro.md
_rules.md
_toc.md
```

**Verification item 3 — `docs/project/changelog/`** contains `_rules.md`,
`_intro.md`, `_format.md`, `_toc.md`, no entry files:

```text
$ ls -1 /tmp/test-greenfield-v11d-bd166/docs/project/changelog/
_format.md
_intro.md
_rules.md
_toc.md
```

**Verification item 4 — `docs/project/BACKLOG.md` mirror** exists and
contains the `_intro.md` content (byte-identical for empty stream):

```text
$ head -10 /tmp/test-greenfield-v11d-bd166/docs/project/BACKLOG.md
<!-- DO NOT EDIT THIS FILE — it is regenerated from the per-entry
     tree at docs/project/backlog/. To change an entry, edit the
     corresponding docs/project/backlog/<TD-NNN>.md per-entry file
     and re-run the mirror regenerator. Hand-edits to this mirror
     are silently overwritten on the next regeneration. -->

# Project backlog

This file is the regenerated mirror of the per-entry source-of-truth
tree at `docs/project/backlog/`. The per-entry tree is where TD-NNN

$ cmp /tmp/test-greenfield-v11d-bd166/docs/project/BACKLOG.md \
       /tmp/test-greenfield-v11d-bd166/docs/project/backlog/_intro.md \
    && echo IDENTICAL || echo differ
IDENTICAL
```

**Verification item 5 — `docs/project/IMPLEMENTATION-PLAN.md` mirror**
exists and equals `_intro.md` (project-implementation-plan has no
trailing supporting file):

```text
$ head -10 /tmp/test-greenfield-v11d-bd166/docs/project/IMPLEMENTATION-PLAN.md
<!-- DO NOT EDIT THIS FILE — it is regenerated from the per-entry
     tree at docs/project/implementation-plan/. To change a phase,
     edit the corresponding docs/project/implementation-plan/<phase-N>.md
     per-entry file and re-run the mirror regenerator. Hand-edits
     to this mirror are silently overwritten on the next
     regeneration. -->

# Project implementation plan

This file is the regenerated mirror of the per-entry source-of-truth

$ cmp /tmp/test-greenfield-v11d-bd166/docs/project/IMPLEMENTATION-PLAN.md \
       /tmp/test-greenfield-v11d-bd166/docs/project/implementation-plan/_intro.md \
    && echo IDENTICAL || echo differ
IDENTICAL
```

**Verification item 6 — `docs/project/CHANGELOG.md` mirror** exists
and contains `_intro.md` content + `\n---\n\n` separator + `_format.md`
content (project-changelog is the one project stream with `_format.md`
asymmetry per `mirror-generate.sh:155-162`):

```text
$ head -10 /tmp/test-greenfield-v11d-bd166/docs/project/CHANGELOG.md
<!-- DO NOT EDIT THIS FILE — it is regenerated from the per-entry
     tree at docs/project/changelog/. To add a new entry, write a
     new docs/project/changelog/<YYYY-MM-DD-slug>.md per-entry
     file and re-run the mirror regenerator. Hand-edits to this
     mirror are silently overwritten on the next regeneration.
     CHANGELOG entries are append-only — never edit a prior
     per-entry file. -->

# Project change log

$ grep -n '^---$' /tmp/test-greenfield-v11d-bd166/docs/project/CHANGELOG.md
59:---

$ grep -n '^# CHANGELOG Format Rules' /tmp/test-greenfield-v11d-bd166/docs/project/CHANGELOG.md
61:# CHANGELOG Format Rules
```

(Separator at line 59; `_format.md` content begins at line 61. Both
present per the project-changelog concat order: `_intro.md` →
`\n---\n\n` → `_format.md`.)

**Verification item 7 — re-running init on the same target directory
is safe (idempotent)**. The init-project.sh `main()` short-circuits on
already-configured targets at the classification gate (exit 20)
without entering the stages, so a second `bash init-project.sh
<target>` against a fully-installed greenfield is correctly STOP'd by
the existing pre-existing-AI-config check (verified by the existing
test 1.2/3.1 group in `test-init-project.sh`). For sub-stage 6+7
specifically (the new code we added), idempotency was verified at the
helper level by directly re-running the mirror+TOC regenerators on
the smoke target and observing zero mtime churn:

```text
$ bash -c '
. scripts/lib/per-entry/_lib.sh
. scripts/lib/per-entry/mirror-generate.sh
. scripts/lib/per-entry/toc-regenerate.sh
SMOKE=/tmp/test-greenfield-v11d-bd166
BEFORE=$(stat -f "%m %N" "$SMOKE/docs/project/BACKLOG.md" \
                          "$SMOKE/docs/project/IMPLEMENTATION-PLAN.md" \
                          "$SMOKE/docs/project/CHANGELOG.md" \
                          "$SMOKE/docs/project/backlog/_toc.md" \
                          "$SMOKE/docs/project/implementation-plan/_toc.md" \
                          "$SMOKE/docs/project/changelog/_toc.md")
sleep 1
for spec in "project-backlog|docs/project/BACKLOG.md|docs/project/backlog" \
            "project-implementation-plan|docs/project/IMPLEMENTATION-PLAN.md|docs/project/implementation-plan" \
            "project-changelog|docs/project/CHANGELOG.md|docs/project/changelog"; do
  k=${spec%%|*}; rest=${spec#*|}; m=${rest%%|*}; d=${rest##*|}
  per_entry_regenerate_mirror "$k" "$SMOKE/$d" "$SMOKE/$m" </dev/null
  per_entry_regenerate_toc "$k" "$SMOKE/$d"
done
AFTER=$(stat -f "%m %N" ...)
[[ "$BEFORE" == "$AFTER" ]] && echo MTIMES_UNCHANGED
'
[ ... output elided ... ]
MTIMES_UNCHANGED — idempotent helpers
```

(Both mirror and TOC regenerators short-circuit on `cmp -s` byte-
identity — re-running produces zero mtime churn. Confirms the
sub-step 7 regen path is idempotent on its own; combined with `cp`'s
default overwrite-with-same-bytes for sub-step 6 template copies, the
whole sub-step block is idempotent under repeated invocation.)

**Confirmation of canonical S11 banner + new info line:**

```text
$ PACK=...repo... bash init-project.sh /tmp/freshtgt <<<"y" 2>&1 | grep -E "S11|per-entry"
── S11 — v11 client artifacts (HELP-FRAGMENT, tracker, issue forms, pack-help) ──
  per-entry tree skeleton + empty mirrors installed under docs/project/{backlog,implementation-plan,changelog}/
```

### §4.4 — HEAD-unchanged confirmation

```text
$ git rev-parse HEAD
a5b4a6eb78d67cb143fefce6020f7bb66d135af9

$ git status
On branch v11-dev
Your branch is ahead of 'origin/v11-dev' by 4 commits.
Changes not staged for commit:
	modified:   scripts/init-project.sh

no changes added to commit
```

HEAD unchanged from the pre-implementation `a5b4a6e`. Only working-tree
change is the modification to `scripts/init-project.sh`. Pack Chat
owns the commit.

```text
$ git diff --stat scripts/init-project.sh
 scripts/init-project.sh | 127 ++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 127 insertions(+)
```

---

## §5 — Definition-of-Done checklist

### A. Architect-doc bindings

| # | Binding | Status |
|---|---|---|
| A1 | Stage extension preferred over new stage (integration parent §8.17 + §18.1 #5) — extended `stage_s11_v11_artifacts`, did NOT add `stage_s11b_per_entry_tree` | PASS |
| A2 | Mirror regenerator handles empty input naturally — no special "greenfield empty mirror" template (integration parent §9.3) | PASS (helpers untouched; greenfield empty input takes the "no prior mirror → write fresh" branch at `mirror-generate.sh:221`) |
| A3 | Helper reuse pattern preserved per integration parent §9.3 — same BD-164 helpers serve three call sites (v10→v11 migrator, init-project.sh, future tracker mode transitions) | PASS (sourced via `type` guards matching the migrator-private adapter convention) |
| A4 | `_intro.md` and `_format.md` ship from `project-template/docs/project/<stream>/` (integration parent §9.7); init code COPIES, does NOT generate | PASS (sub-step 6 uses `$copy_fn`; no template generation) |
| A5 | Greenfield class produces v11.0-shape repo: per-entry trees + supporting files + empty regenerated mirrors + empty `_toc.md` | PASS (verified items 1–6 of §4.3) |
| A6 | Existing-* class path preserved (`stage_s11_v11_artifacts` from existing-* re-run does not silently overwrite client-customized per-entry files) | PASS (mirror+TOC regen gated on `CLASS == new-*`; templates use `$copy_fn` = `existing_classifier_copy` for existing-* per BD-088 sidecar contract) |
| A7 | Bash 3.2 + macOS BSD-utility compatible | PASS (pipe-tuple parsing; no associative arrays; no `&>`; no GNU-only flags) |
| A8 | No state-changing git verbs from the agent | PASS (HEAD unchanged at `a5b4a6e`) |

### B. Functional verification

| # | Check | Status |
|---|---|---|
| B1 | `bash -n scripts/init-project.sh` clean | PASS |
| B2 | `python3 scripts/validate-pack.py` PASSES | PASS |
| B3 | `bash scripts/tests/test-init-project.sh` PASSES (34/34 baseline, no regression) | PASS |
| B4 | `bash scripts/tests/test-per-entry.sh` PASSES (57/57) | PASS |
| B5 | `bash scripts/tests/test-migrate-v10-to-v11.sh` PASSES (43/43) | PASS |
| B6 | `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` PASSES (61/61) | PASS |
| B7 | `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` PASSES (87/87) | PASS |
| B8 | `bash scripts/tests/tracker-agent-read-test.sh` PASSES (31/31) | PASS |
| B9.1 | Smoke #1: `docs/project/backlog/` has `_rules.md`, `_intro.md`, `_toc.md`, no entry files | PASS |
| B9.2 | Smoke #2: `docs/project/implementation-plan/` has `_rules.md`, `_intro.md`, `_toc.md`, no entry files | PASS |
| B9.3 | Smoke #3: `docs/project/changelog/` has `_rules.md`, `_intro.md`, `_format.md`, `_toc.md`, no entry files | PASS |
| B9.4 | Smoke #4: `docs/project/BACKLOG.md` exists, byte-identical to `_intro.md` | PASS |
| B9.5 | Smoke #5: `docs/project/IMPLEMENTATION-PLAN.md` exists, byte-identical to `_intro.md` | PASS |
| B9.6 | Smoke #6: `docs/project/CHANGELOG.md` exists, contains `_intro.md` + `---` separator + `_format.md` | PASS |
| B9.7 | Smoke #7: Re-running init is safe (idempotent at helper level; classification gate STOPs at exit 20 for fully-installed targets) | PASS |

### C. Process / hygiene

| # | Check | Status |
|---|---|---|
| C1 | No state-changing git verbs (no add, commit, push, tag, rebase, reset, stash, checkout-modify) | PASS |
| C2 | Out-of-scope items surfaced to Pack Chat with no deferral recommendation (per `feedback_no_deferral_without_user_direction`) | PASS (see §7) |
| C3 | Trinity rule respected (no trinity files touched) | PASS (no edits to CLAUDE.md / AGENTS.md / GEMINI.md anywhere) |
| C4 | No PM-only file edits (BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md, PACK-AGENTS.md, pack-* agent files) | PASS |
| C5 | No edits to BD-167 territory (`project-template/docs/project/` canonical templates) | PASS |
| C6 | No edits to BD-168 territory (`scripts/validate-pack.py`) | PASS |
| C7 | No edits to BD-165 territory (`scripts/migrate-v10-to-v11.sh`, `scripts/lib/migrate-v10-to-v11/`, `scripts/lib/migrator-core.sh`) | PASS |
| C8 | No edits to BD-164 territory (`scripts/lib/per-entry/`) — helpers SOURCED, not modified | PASS |
| C9 | No edits to BD-160/170/19f territory (`test-fixtures/`) | PASS |

---

## §6 — Plan deviations

**Zero plan deviations.** All architect-doc bindings honored verbatim
per the plan's §5.5 specification + the integration parent §8.17 / §9.3
/ §9.7 / §18.1 #5 references.

One implementation-shape choice within the spec's "planner-deferred"
qualifier: the mirror+TOC regen block (sub-step 7) is gated on
`[[ "$CLASS" == new-* ]]` — greenfield only. This is the conservative
interpretation of plan binding (c) "preserve existing-* path safely":
running the BD-164 mirror regenerator against a populated client
`docs/project/BACKLOG.md` would either (a) succeed silently if
divergence is absent (unlikely for any non-greenfield project) or
(b) emit a divergence warning + non-zero exit if hand-edits are
present. Either outcome on existing-* is wrong for the init pathway —
the v10→v11 migrator is the canonical path for clients with prior
monolithic content. Templates copies (sub-step 6) DO still go through
`$copy_fn` for both classes per BD-088 sidecar contract, so a
customized `_rules.md`/`_intro.md`/`_format.md` in an existing-*
target gets the `.pack-template` sidecar treatment.

---

## §7 — Out-of-scope items / observations for Pack Chat

The following items are surfaced for Pack Chat decision. No deferral
recommendation is made (per `feedback_no_deferral_without_user_direction`).

### §7.1 — `--update` mode does NOT install per-entry tree

The `cmd_update` path (init-project.sh:915-1040) iterates a hardcoded
list of pack-product files via `customization_preserve` (BD-088
contract). It does NOT iterate the new
`project-template/docs/project/<stream>/` canonical templates and does
NOT invoke the BD-164 helpers.

Implication: a v11 client that ran `init-project.sh` BEFORE this
commit landed (i.e., a "pre-19d" v11 client with v11 AI config but no
per-entry tree skeleton) would, on a future `--update`, NOT pick up
the new per-entry tree. Since this commit is part of v11.0 itself,
this situation is empirically rare — but Pack Chat may want to consider
whether the `--update` entries list needs the 7 canonical templates
appended for forward-compat.

Out of scope for this commit per plan §5.5 binding — `--update`
extension is not mentioned in the binding spec. Pack Chat decision
required if v11.0 wants to ship `--update` coverage for the new
per-entry tree.

### §7.2 — Empty mirrors are written even when entries are absent

The new sub-step 7 writes `docs/project/BACKLOG.md` etc. that
contain ONLY the `_intro.md` preamble (or `_intro.md` + `_format.md`
for changelog). For a brand-new client with no entries yet, this is
a noisy commit-tree footprint vs. the alternative of "don't write a
mirror until at least one entry exists." Per plan §5.5 success
criterion items 4/5/6 explicitly call for these mirrors to exist on
fresh init ("exists, contains the `_intro.md` content (the mirror
produced by the regenerator with no entries to concat)"), so this is
intentional, not an artifact. Documented for Pack Chat awareness; no
action needed.

### §7.3 — Mirror filename ALL-CAPS asymmetry across project streams

Observation: `docs/project/BACKLOG.md` and `docs/project/CHANGELOG.md`
follow the pack-side all-caps convention. `docs/project/IMPLEMENTATION-PLAN.md`
is also all-caps with a hyphen. All three are inherited from the BD-164
`pe_canonical_mirror_for_stream` constants
(`_lib.sh:84/92/100`). The init code uses these helper values
verbatim — no new convention introduced. Documented for Pack Chat
awareness; no action needed.

### §7.4 — No new `info` lines other than the post-block summary

Per `scripts/init-project.sh`'s prevailing S11 sub-step convention
(sub-steps 1..5 use no per-sub-step `info` lines — only end-of-stage
verification fails emit messages), I added only ONE `info` line at the
end of sub-step 7 confirming the per-entry skeleton + empty mirrors
were installed. Sub-step 6 has no `info` line (matches sub-steps 1..5
which are silent on success). If Pack Chat prefers more verbose
narration, an `info` line could be added after the sub-step 6 template
copies; not done here to match the existing terseness convention.

### §7.5 — Smoke-test re-run idempotency proof bypassed `git stash`

The "re-run safety" verification (§4.3 item 7) was proven at the
helper level (mtime-unchanged after re-invocation) rather than via a
full `main()` re-run because the canonical re-run path requires either
a `git stash` of the freshly-installed files (forbidden under
`feedback_agents_never_commit`) or a `git commit` (same prohibition).
The classification gate (init-project.sh:1132-1145) returns
`already-configured` and exits 20 for any target with a non-empty
CLAUDE.md + `.claude/`, so a second invocation of `main()` against the
smoke target would not actually re-enter the stages — providing a
second tier of idempotency-by-construction. Combined with the
helper-level mtime-unchanged proof, the full path is structurally
idempotent. Documented for Pack Chat awareness.

---

## §8 — Files inventory

| Path | Change type |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh` | modified (+127 lines, 0 deleted) |

(One file. No new files. No deletions.)

---

## §9 — End marker

`IMPLEMENTATION-REPORT-BD-166-COMPLETE: 2026-05-15 — pack-coder Commit
19d for Batch 19 per-entry split. scripts/init-project.sh
stage_s11_v11_artifacts extended with sub-steps 6 (template install for
backlog/implementation-plan/changelog × 7 canonical files) + 7
(greenfield empty mirror+TOC regen via BD-164 helpers). HEAD unchanged
at a5b4a6e; Pack Chat owns commit.`
