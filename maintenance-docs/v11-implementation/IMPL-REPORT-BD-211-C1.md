# IMPL-REPORT-BD-211-C1 — pack-side data fix (canonicalize 3 backlog entries)

**Author:** pack-coder
**Branch / HEAD (pre-flight):** `v11-dev` / `7bdb33f671b56e9e804bf17e0b85dda94b9d78b8`
**HEAD unchanged (no git state changes by coder):** `7bdb33f671b56e9e804bf17e0b85dda94b9d78b8`
**Commit:** C1 of BD-211 (`pack-only`, `backlog/` only)
**Executes:** `PLAN-BD-211.md` §3 C1 items 1–4 (tokenless fold recipe) + `ARCHITECTURE-BD-211.md` §2.1/§2.2/§2.2.1/§2.3.

---

## Files changed inventory

| Path | Change type |
|---|---|
| `backlog/BD-167.md` | modified (append tokenless `## Sub-entry b` fold) |
| `backlog/BD-169.md` | modified (append tokenless `## Sub-entry b` fold + repoint line-14 cross-ref) |
| `backlog/BD-195.md` | modified (normalize line-2 header only) |

NOT touched (correctly out of scope): `backlog/_rules.md` (= C2), `backlog/_toc.md`
(Pack-Chat regen post-deletion), `backlog/BD-167b.md` / `BD-169b.md` (Pack-Chat
`git rm`), `scripts/`, `project-template/`, `supporting-docs/`. `git status --short`
confirms exactly 3 modified files (the 3 `??` untracked are pre-existing BD-211
design docs, not coder edits).

---

## Task 1 — Fold BD-167b → BD-167 (tokenless)

Appended to END of `backlog/BD-167.md` body. Tokenless H2 (zero `BD-167b` token):

```
## Sub-entry b — Per-entry split PM-only edits (trinity Key files + PACK-AGENTS.md PM-only directories list + CLAUDE.md pack-memory bullet + pack-* agent prompts × 15)
Folded from a former standalone sub-entry per BD-211 (no-letter-suffix canonicalization; a sub-part is a section, not a suffixed entry).
```

Followed by BD-167b's fields VERBATIM (Type / Status / Blockers / Unblocks /
File-Symbol / Description / Resolved). Dropped: BD-167b line-1 back-pointer +
line-2 suffix header (title preserved in H2 label). `Blockers: BD-167` (parent
ref) STAYS.

**Self-ref token scrub (1):** File/Symbol final bullet
`(STATUS.md disclaimer surface — … NOT in BD-167b)` → `… NOT in this sub-entry)`.

## Task 2 — Fold BD-169b → BD-169 (tokenless)

Appended to END of `backlog/BD-169.md` body. Tokenless H2 (zero `BD-169b` token):

```
## Sub-entry b — Per-entry split PM-only wording updates (PACK-CHAT.md row + README.md Repository Layout entries)
Folded from a former standalone sub-entry per BD-211 (no-letter-suffix canonicalization; a sub-part is a section, not a suffixed entry).
```

Followed by BD-169b's fields VERBATIM. Dropped: line-1 back-pointer + line-2
suffix header. `Blockers: BD-169` (parent ref) STAYS.

**Self-ref token scrub (1):** Description ending
`… §5.9 + §6.1 BD-169b sample text.` → `… §5.9 + §6.1 sample text.`.

## Task 3 — Repoint BD-169 line-14 cross-ref (tokenless)

`backlog/BD-169.md` Description (orig line 14):
`… those land in BD-169b).` → `… those land in the sub-entry b section below).`
(tokenless — no `BD-NNN`-shaped token, so Check 34 sees no reference).

## Task 4 — Normalize BD-195 header (line 2 only)

```
FROM: **BD-195 (Code Red 3) — v11.0 pristine-state recovery before BD-185 restart (full-repo)**
TO:   **BD-195 — v11.0 pristine-state recovery before BD-185 restart (full-repo) (Code Red 3)**
```

`(Code Red 3)` moved to END of title, inside bold span, after `(full-repo)`.
`Alias:` line (line 6) UNCHANGED. No other line in BD-195.md changed.

---

## Safe-before-delete — field-coverage proof (the deletion gate)

Both parents now carry EVERY live field of their former sub-entry — no content
lost (the dropped line-1 back-pointer + line-2 suffix header carry no live field
content; the title survives in the H2 label).

**BD-167.md `## Sub-entry b` carries every BD-167b.md field:**

| BD-167b field | Present in BD-167 fold | Note |
|---|---|---|
| Type: | YES | verbatim |
| Status: Resolved | YES | verbatim |
| Blockers: BD-167 | YES | parent ref, legitimately kept |
| Unblocks: none | YES | verbatim |
| File/Symbol (PM-only…) + 7 bullets | YES | verbatim; last bullet token scrubbed (`NOT in this sub-entry`) |
| Description: | YES | verbatim |
| Resolved: 2026-05-16 … 8ba0164 … 8fac7d0 | YES | verbatim |

**BD-169.md `## Sub-entry b` carries every BD-169b.md field:**

| BD-169b field | Present in BD-169 fold | Note |
|---|---|---|
| Type: | YES | verbatim |
| Status: Resolved | YES | verbatim |
| Blockers: BD-169 | YES | parent ref, legitimately kept |
| Unblocks: none | YES | verbatim |
| File/Symbol (PM-only…) + 2 bullets | YES | verbatim |
| Description: | YES | verbatim; token scrubbed (`§6.1 sample text`) |
| Resolved: 2026-05-16 … 27374b4 | YES | verbatim |

CONCLUSION: parents are content-complete → safe to delete the orphan files.

---

## Tokenless grep (zero `BD-167b`/`BD-169b` in folded parents)

```
$ grep -n 'BD-167b\|BD-169b' backlog/BD-167.md backlog/BD-169.md
(no output; rc=1)
```

ZERO matches. Parent `Blockers:` refs verified present + legitimate:
```
backlog/BD-167.md:21:Blockers: BD-167
backlog/BD-169.md:5:Blockers: BD-167
backlog/BD-169.md:21:Blockers: BD-169
```

BD-195 normalization + Alias verified:
```
$ sed -n '2p' backlog/BD-195.md
**BD-195 — v11.0 pristine-state recovery before BD-185 restart (full-repo) (Code Red 3)**
$ grep -n '^Alias:' backlog/BD-195.md
6:Alias: "Code Red 3" and "BD-195" refer to the same item (interchangeable).
```

---

## validate-pack.py (transient tree — orphans present, `_toc.md` NOT yet regenerated)

```
$ python3 scripts/validate-pack.py
…
── Check 32 (filename conformance) — OK (suffix grammar unchanged until C2)
── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
FAIL: backlog/_toc.md is out of sync — re-run … per_entry_regenerate_toc pack-backlog … before committing
── Check 34 (cross-ref) — OK (no dangling BD-167b/BD-169b reference reported)
…
FAILED — 1 issue(s) found
```

**EXACTLY 1 FAIL** (`grep -c '^FAIL:'` → 1), and it is **Check 33 (`_toc.md`
out of sync)** — the EXPECTED, by-design transient state:

- The BD-195 `_toc.md` row title still reads the pre-normalization form (the
  regenerator would now emit `(Code Red 3)` at row-title end).
- The `BD-167b` / `BD-169b` rows are still present in `_toc.md` (they vanish only
  after the orphan files are deleted).

Both are resolved by Pack Chat's deletion + `per_entry_regenerate_toc` step
(PLAN §3 C1 items 5–6) — explicitly OUT of this coder's scope (TOC regen
forbidden by the prompt; the coder runs no state-changing verb). The grammar
checks the prompt asked to verify (Check 32 filename-conformance + Check 34
cross-ref) are GREEN — `validate-pack` reports NO dangling `BD-167b`/`BD-169b`
reference and NO non-conforming filename for the still-present orphans (suffix
grammar is unchanged until C2). The Check-33 FAIL is the deferred-to-Pack-Chat
regen, not a coder defect.

`backlog/_toc.md` rows confirming the deferred drift:
```
197:- [BD-167b](./BD-167b.md) — Per-entry split PM-only edits (…)   ← removed on delete+regen
200:- [BD-169b](./BD-169b.md) — Per-entry split PM-only wording updates (…)   ← removed on delete+regen
218:- [BD-195](./BD-195.md) — v11.0 pristine-state recovery before BD-185 restart (full-repo)   ← row title updates on regen
```

---

## Plan deviations

ZERO. C1 items 1–4 implemented exactly per PLAN §3 C1 (tokenless fold form).
Items 5 (`git rm`) + 6 (`_toc.md` regen) are Pack-Chat's per the PLAN + the
prompt — surfaced below, not performed.

## New POQs introduced

None.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| BD-167b folded into BD-167 as tokenless `## Sub-entry b` (all fields verbatim) | PASS |
| BD-169b folded into BD-169 as tokenless `## Sub-entry b` (all fields verbatim) | PASS |
| BD-167 self-ref token scrubbed (`NOT in this sub-entry`) | PASS |
| BD-169 self-ref token scrubbed (`§6.1 sample text`) | PASS |
| BD-169 line-14 cross-ref repointed tokenless (`the sub-entry b section below`) | PASS |
| BD-195 line-2 header normalized; Alias line unchanged; no other line changed | PASS |
| Tokenless grep zero matches in both folded parents | PASS |
| Parent `Blockers:` refs preserved (legitimate) | PASS |
| Safe-before-delete: every sub-entry field present in parent | PASS |
| Scope: only the 3 named `backlog/` files modified | PASS |
| No file deleted / no `_toc.md` regen / no git verb by coder | PASS |
| validate-pack grammar checks (32/34) green; sole FAIL is the deferred Check-33 TOC regen | PASS (deferred to Pack Chat) |

---

## DELETION-READY

DELETION-READY: BD-167b.md + BD-169b.md fully folded + verified complete
(safe-before-delete — both parents carry every former-sub-entry field, verbatim,
with the 2 self-ref tokens scrubbed); Pack Chat to `git rm backlog/BD-167b.md
backlog/BD-169b.md` + regen `_toc.md` (`per_entry_regenerate_toc pack-backlog
backlog`). After deletion + regen, Check 33 goes green (orphan rows removed +
BD-195 row title updated) and the tree is fully canonical for C2's fold-then-guard.

---

## Rules-Applied Verification Block

### Per-rule

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **Safe-before-delete (fail-loud / delete-old-source)** | Field-coverage tables above: every BD-167b field present in BD-167 fold; every BD-169b field present in BD-169 fold; 2 self-ref tokens scrubbed, no live content lost; deletion surfaced (DELETION-READY) NOT performed. | COMPLIANT |
| **Per-action approval / agents-never-commit** | `git status --short` shows only 3 `M` files; coder ran NO `git rm`/`rm`/`git add`/`git commit`/TOC-regen; HEAD unchanged at `7bdb33f`; deletion + regen surfaced to Pack Chat. | COMPLIANT |
| **Tokenless (no-letter-suffix)** | `grep -n 'BD-167b\|BD-169b' backlog/BD-167.md backlog/BD-169.md` → empty (rc=1). Both folds use `## Sub-entry b` form; 2 self-ref tokens scrubbed; parent `Blockers:` refs (legit) kept. | COMPLIANT |
| **Edit in place (no full rewrite)** | 4 targeted `Edit` ops (2 appends, 1 repoint, 1 header replace); no file rewritten; folded sections re-dumped via `awk` to confirm section map post-edit. | COMPLIANT |
| **Pack-only / backlog-only scope** | Only `backlog/BD-167.md`, `BD-169.md`, `BD-195.md` modified (`git status --short`); `_rules.md`/`scripts/`/`project-template/`/`supporting-docs/` untouched. | COMPLIANT |
| **Rules-Applied Verification Block** | This block (per-rule + per-read-doc, evidence quoted, terminal conclusions). | COMPLIANT |
| **Boundary discipline (P-missed-7)** | No project-side file edited; all edits are pack-side `backlog/` data. No project-side SSOT investigation required (no `project-template/`/`supporting-docs/` edit). | N/A: no project-side edit |

### Per-read-doc (READ IN FULL / directly)

| Document | Read evidence | Conclusion |
|---|---|---|
| `PLAN-BD-211.md` § C1 (items 1–4) | Read tool, 827 lines (full); §3 C1 recipe drives all 4 tasks + the deferred items 5/6. | COMPLIANT |
| `ARCHITECTURE-BD-211.md` §2.1/§2.2/§2.2.1/§2.3 | Read tool, L1–120 (covers §1 DPs + §2.1 + §2.2 + §2.2.1 fold shape + scrub targets). | COMPLIANT |
| `backlog/BD-167.md` | Read tool, full (16 lines); fold target + parent header/fields. | COMPLIANT |
| `backlog/BD-167b.md` | Read tool, full (16 lines); fields copied verbatim; scrub target line 14. | COMPLIANT |
| `backlog/BD-169.md` | Read tool, full (15 lines); fold target + line-14 cross-ref repoint. | COMPLIANT |
| `backlog/BD-169b.md` | Read tool, full (11 lines); fields copied verbatim; scrub target line 10. | COMPLIANT |
| `backlog/BD-195.md` | Read tool, full (44 lines); line-2 normalize; Alias line 6 confirmed unchanged. | COMPLIANT |
| `CLAUDE.md ## Pack memory` | Provided in full in system context; agents-never-commit + safe-before-delete + edit-in-place + no-bd-letter-suffix + RAVB rules applied. | COMPLIANT |
| `feedback_fail_loud_delete_old_source.md` | Provided via memory index + applied (safe-before-delete gate; coder surfaces deletion, does not delete; reconcile-in-place for BD-195 active Resolved doc). | COMPLIANT |
| `feedback_edit_in_place_not_full_rewrite.md` | Provided via memory index + applied (targeted edits; re-dumped section map post-edit). | COMPLIANT |
| `feedback_no_bd_letter_suffix.md` | Provided via memory index + applied (tokenless fold; zero suffix token in parents; sub-part = in-body section). | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` | Provided via memory index + applied (this RAVB). | COMPLIANT |

**No named document was derived rather than read.** Every backlog entry + both
design docs (the relevant sections) were Read directly; every claim was measured
live via Bash at HEAD `7bdb33f`.
