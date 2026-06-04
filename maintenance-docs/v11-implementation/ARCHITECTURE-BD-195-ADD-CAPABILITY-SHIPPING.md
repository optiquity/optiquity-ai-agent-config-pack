# ARCHITECTURE — BD-195 — `add-capability.sh` shipping verdict

**Role:** pack-architect (read-only). **Branch:** v11-dev.
**HEAD at design:** `60bb2d61f7c986f82446e4c3929c5c06512ac0e1`. **Date:** 2026-06-03.
**Scope:** verdict + per-client-surface-reference disposition + coder fix recipe + ripple list.

---

## 1 — Verdict (one line)

**`add-capability.sh` is a PACK OPERATION (case (b) of the governing rule) — it
must STAY pack-side; DELETE its client-surface verb/usage references and
forward-frame nothing.** The working hypothesis ("ship it to
`project-template/scripts/`") is **REJECTED**: the script cannot run at a client
install because it requires a present, valid pack checkout (`$PACK`) and copies
FROM `$PACK/project-template/` — shipping it would land a verb that is dead at
every client.

This is the dependency-direction case exactly: `add-capability.sh` is one of the
three pack operations that source `scripts/lib/detect.sh` (the canonical pack-op
set named in `ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md` §8.0:
init-project.sh / add-capability.sh / migrator). A pack operation is pack-side
by definition.

---

## 2 — Empirical evidence (state-claims)

> **EEB-1 — The script exists ONLY pack-side; no `project-template/` copy; not in the install manifest.**
> Command: `find . -name "add-capability.sh" -not -path "./.git/*"` →
> `./scripts/add-capability.sh` (single hit, 37916 bytes).
> Command: `grep -n "add-capability" test-fixtures/manifest.txt` → no match.
> Interpretation: the script lives at the pack-level `scripts/` dir only and is
> NOT in the client install manifest.
> Conclusion: **SUPPORTED**.

> **EEB-2 — The script REQUIRES a valid pack checkout; it copies FROM `$PACK/project-template/`.**
> Command: `grep -nE 'detect_pack_path|"\$PACK|PACK environment|\$PACK/project-template' scripts/add-capability.sh`.
> Output (key lines): `377: die "PACK environment variable not set ..." "$EXIT_PACK_INVALID"`;
> `380: pack_status=$(detect_pack_path "$PACK" ...)`; `382: die "PACK ($PACK) is not a valid pack repo ..."`;
> `580: src="$PACK/project-template/$f"`; `603: local pack_gi="$PACK/project-template/.gitignore"`.
> Interpretation: stage A0 hard-exits (`EXIT_PACK_INVALID=10`) when `$PACK` is
> unset or not a valid pack repo; stage A5 copies conditional files from
> `$PACK/project-template/$f` into the target. A client install has no `$PACK`
> pack checkout, so the script is inoperable client-side.
> Conclusion: **SUPPORTED**. (This is the hypothesis-killer — see §4.)

> **EEB-3 — `init-project.sh` does NOT stage `add-capability.sh` (not in the install map).**
> Command: `grep -n "add-capability" scripts/init-project.sh` → no match.
> Conclusion: **SUPPORTED** — the script is not installed into client projects.

> **EEB-4 — No pack operation INVOKES `add-capability.sh` at runtime; it is itself a top-level pack op.**
> Command: `grep -rn "add-capability" scripts/ --include="*.sh" | grep -v "scripts/add-capability.sh:"`.
> Output: only (a) `scripts/lib/detect.sh` header + comments naming it as a
> *sourcer* of detect.sh; (b) `scripts/tests/test-add-capability.sh` (test
> harness sourcing its functions); (c) `scripts/test-detect.sh` comment. No
> pack script calls `add-capability.sh` as a subprocess.
> Interpretation: it is a developer-invoked top-level pack operation, parallel
> to init-project.sh and the migrator — not a dependency of another pack op, and
> not a client deliverable.
> Conclusion: **SUPPORTED**.

> **EEB-5 — It is in the canonical pack-op set that sources `detect.sh`.**
> Evidence: `scripts/lib/detect.sh:3` "Sourced by init-project.sh,
> migrate-v9-to-v10.sh, and add-capability.sh"; `add-capability.sh:89 source
> "$SCRIPT_DIR/lib/detect.sh"`; `ARCHITECTURE-BD-195-DUAL-USE-SHIPPED-LIBS.md`
> §8.0 names "init-project.sh / add-capability.sh / the migrator (all pack
> operations, EEB-D)."
> Conclusion: **SUPPORTED** — add-capability.sh is a pack operation by the
> dependency-direction analysis already ratified in the dual-use doc.

> **EEB-6 — It is NOT in `_CLIENT_INSTALLED_FILES` and NOT in `_SANCTIONED_PACK_SIDE_SHIPPED`.**
> Command: `grep -n "add-capability" scripts/validate-pack.py`.
> Output: two hits, both in comment prose naming it as a detect.sh sourcer
> (`4152`, `7112`). The `_SANCTIONED_PACK_SIDE_SHIPPED` tuple
> (validate-pack.py:4158-4161) contains exactly `scripts/lib/detect.sh` and
> `scripts/pack-help.sh` — add-capability.sh is absent.
> Interpretation: add-capability.sh neither installs nor is sanctioned to ship.
> It does not even qualify for the sanctioned set, because the set's criterion
> (dual-use: pack-op runtime dependency AND a client surface invokes it) fails
> prong 2 — no client surface invokes add-capability.sh (it requires `$PACK`).
> Conclusion: **SUPPORTED**.

> **EEB-7 — The documented usage is "run from the pack."**
> Evidence: `supporting-docs/METHODOLOGY.md:1415` "first instructs them to run
> `add-capability.sh` from the pack"; `project-template/docs/pack/PM-CHAT.md:389`
> "direct them to run `scripts/add-capability.sh` from the pack first";
> `README.md:195` lists it under "scripts/  Pack-level scripts".
> Conclusion: **SUPPORTED** — every authoritative description already treats it
> as a pack-side, run-from-the-pack operation.

---

## 3 — Governing-rule application

**Rule (`client-ref-delete-or-forward-look`):** a client-shipped reference to a
genuinely-pack-only asset → DELETE; a reference to a real project asset by its
pack path → FORWARD-LOOK to the landed client path (which, for a script, means
the script must actually LAND client-side).

**Classification:** `add-capability.sh` is **genuinely pack-only** (case 1 /
verdict (b)). It has no equivalent at a client install, cannot run there (EEB-2),
is not installed (EEB-3), and is a pack operation by dependency direction
(EEB-5). Therefore every CLIENT-shipped reference to it as a runnable client
verb is **dead at the client → DELETE**.

**Why "forward-look" / "ship it" is wrong (hypothesis challenge,
`dependency-direction-placement`):** Forward-looking a script reference only
works if the script lands client-side and runs there. This one cannot: it is a
pack operation whose runtime substrate is the pack checkout it copies FROM. Per
the dependency-direction rule, "location is governed by DEPENDENCY DIRECTION, not
by ship-status… a file that a pack operation depends on at runtime MUST live
pack-side" — and a pack operation ITSELF lives pack-side a fortiori. Shipping it
to `project-template/scripts/` would either (i) ship a verb that dies at every
client (no `$PACK`), or (ii) require inverting the dependency so a client copy
reads its OWN installed `project-template/` — which is a different script, not
this one, and is out of BD-195 scope (a feature, not a reference fix).

**Boundary nuance — `add-capability.sh`'s OWN `$PACK/project-template/` reads are
fine.** The script reading `project-template/` is a pack-op reading a pack source
tree (pack→pack), not a pack-op depending on a client deliverable. No
dependency-direction violation. The fix is purely about the *client-surface
references* to the script, not the script's internals.

---

## 4 — Per-client-surface-reference disposition

Client surfaces = `project-template/**`, `supporting-docs/**`, README. (Pack
surfaces `pack-ops/**` and `maintenance-docs/**` are pack-only by directory and
out of this fix's scope — see §6.) All line numbers are at HEAD `60bb2d6`;
**coder must re-locate by content, not line number.**

| # | Surface (client) | Ref @ HEAD | Nature | Disposition |
|---|---|---|---|---|
| C1 | `project-template/docs/pack/HELP-FRAGMENT.md:15` | `` \| `bash scripts/add-capability.sh` \| Add a pack-supported capability to an existing project. \| `` | Client verb table ("Verb manifest for **this project**") listing a pack-only script as a client verb — the headline dangling verb | **DELETE the table row.** It is dead at every client (no `scripts/add-capability.sh` installs; even if present it needs `$PACK`). |
| C2 | `project-template/docs/pack/PM-CHAT.md:389` | "direct them to run `scripts/add-capability.sh` from the pack first; then run METHODOLOGY.md Procedure 6" (under **Capability addition** behavioral rule) | Client-installed PM-CHAT instructing the client PM chat to run a pack-only script | **DELETE the pack-script instruction.** The "run X from the pack" directive is a pack-workflow leak into client content (a client PM chat has no pack checkout). Remove the `add-capability.sh` clause; if Procedure 6 retains a client-meaningful trigger, keep only the client-side part (the developer-asks-to-add-a-capability path). Escalate to coder-with-care: this is prose inside a behavioral-rule bullet — surgical clause removal, not whole-bullet deletion, unless the whole bullet is solely about the pack script. |
| C3 | `supporting-docs/METHODOLOGY.md:1412` | "`scripts/add-capability.sh` stage A8 (V10-DESIGN §5.14.3)." | Client-installed methodology citing a pack-only script + a pack-only design doc (`V10-DESIGN.md` lives only at `maintenance-docs/archive/`) | **DELETE.** Already flagged independently as BORDER B2 in `ARCHITECTURE-BD-195-V10-CURRENCY-SWEEP.md` §3 (pack-self-ref leak). Two leaks in one cite: the script ref AND the `V10-DESIGN §5.14.3` cite. Remove both. |
| C4 | `supporting-docs/METHODOLOGY.md:1415` | "first instructs them to run `add-capability.sh` from the pack before resuming" | Procedure 6 trigger #2 prose | **DELETE / REWRITE.** Same leak class as C2. The whole of METHODOLOGY Procedure 6 is the PM-chat companion to a pack-only script — see C5/C6/C7. Coder removes the "run from the pack" directive; whether Procedure 6 survives at all is the §5 escalation question. |
| C5 | `supporting-docs/METHODOLOGY.md:1418` | "Procedure 6 is the PM-chat-side companion to `add-capability.sh`." | Procedure 6 framing | **DELETE / part of the §5 Procedure-6 decision.** |
| C6 | `supporting-docs/METHODOLOGY.md:1432` (Procedure 6 step 6.1) | "Read the `add-capability.sh` report … written by stage A8 …" | Procedure 6 step body | **DELETE / part of the §5 Procedure-6 decision.** |
| C7 | `supporting-docs/METHODOLOGY.md:1457,1463` | "discovery itself runs script-side (`add-capability.sh` stage A7)"; "extends three parallel surfaces in `scripts/add-capability.sh`" | Procedure 6 explanatory tail | **DELETE / part of the §5 Procedure-6 decision.** Line 1463 ("extends three parallel surfaces in scripts/add-capability.sh") is pure pack-maintenance guidance — a clear leak regardless of the Procedure-6 decision. |
| C8 | `supporting-docs/INSTALL-PROCEDURES.md:56` | "the pack's scripts (`init-project.sh`, the active `migrate-vN-to-vM.sh` migrator, `add-capability.sh`) that removes files…" | Client-installed doc naming pack scripts in an `x-` prefix-preservation guarantee | **EVALUATE → likely DELETE the `add-capability.sh` token (and possibly the whole pack-script enumeration).** This sentence explains a pack-controlled-deletion guarantee by naming pack scripts BY NAME — a pack-internal enumeration on a client surface. The client reader needs the guarantee ("pack-controlled deletions skip `x-*`"), not the script roster. Coder: strip the parenthetical script list (or at minimum the `add-capability.sh` token); keep the guarantee prose. Necessity test (`bd-pack-only-operational-rule` token-economy): the client does NOT need the pack-script names to understand the `x-` guarantee → REMOVE. |
| C9 | `README.md:195` | `├── add-capability.sh   Add a pack-supported capability to an existing project (v10)` | Repo-layout map, under "scripts/  Pack-level scripts" | **KEEP — now-valid (pack surface).** README's Repository Layout documents the PACK repo's own tree for pack developers; `add-capability.sh` genuinely lives at `scripts/`. This is a correct pack-side description, not a client leak. **BUT fix the stale `(v10)` currency tag → see C10.** |
| C10 | `README.md:195` (currency) + `add-capability.sh:1-3` header | header self-labels "v10.0 project"; README row tags "(v10)" | Stale-currency tag (separate from the dangling-verb finding) | **RETAG to v11 currency** consistent with how `init-project.sh` ("v10; --update mode v11") and the migrator are tagged. This is the separate `v10.0` staleness sub-finding. Coordinate with `ARCHITECTURE-BD-195-V10-CURRENCY-SWEEP.md` so the currency sweep and this fix do not collide on the same lines. |

**Net for the headline finding:** C1 (the HELP-FRAGMENT client verb row) is the
dangling verb — DELETE it. C2–C8 are the same leak propagated across client
surfaces — DELETE/strip. C9 is the one legitimate KEEP (pack-side README layout).
C10 is the orthogonal currency retag.

---

## 5 — Escalation flag: METHODOLOGY Procedure 6 is wholly a pack-script companion

`supporting-docs/METHODOLOGY.md` Procedure 6 ("Adding a pack-supported
capability") exists ENTIRELY as the PM-chat-side companion to the pack-only
`add-capability.sh` (C4–C7). It is client-installed (it lands at
`docs/pack/METHODOLOGY.md`). Deleting only the `add-capability.sh` tokens may
leave a Procedure that instructs the client PM chat to consume a report from a
script the client cannot run.

**This is the `bd-pack-only-operational-rule` remediation-pathway escalation
point:** surgical token removal is the default, BUT if removing the pack-script
references *breaks the coherence of Procedure 6* (a client PM chat left holding a
procedure whose trigger is a non-existent script), that is the "removal breaks
something" signal → **architect redesign of Procedure 6's client-side story
before the coder strips, NOT a coder guess.** The two coherent end-states are:
(a) Procedure 6 is reframed to a purely client-side "add a capability"
methodology that does not reference the pack script at all; or (b) Procedure 6 is
removed from the client METHODOLOGY because capability-addition is intrinsically a
pack operation. **Pack Chat should surface this to the user as a design decision**
— it is larger than a reference strip. (Recommend folding this into the existing
BD-195 remediation plan rather than opening a new BD, per
`PLAN-BD-195-REMEDIATION.md` scope; confirm with user.)

---

## 6 — Full ripple list (coder)

1. **C1–C8 client-surface strips** (HELP-FRAGMENT, PM-CHAT, METHODOLOGY ×5,
   INSTALL-PROCEDURES) — surgical, content-located, not line-numbered.
2. **C9 KEEP / C10 currency retag** — README layout row + script header `v10.0`
   tag. Coordinate with `ARCHITECTURE-BD-195-V10-CURRENCY-SWEEP.md` to avoid a
   double-edit on the same README/header lines.
3. **HELP-FRAGMENT completeness/freshness validator (CI):** the HELP-FRAGMENT
   client verb table is CI-checked for freshness/completeness (validate-pack.py
   help-fragment checks). Deleting the C1 row MUST be reconciled with any check
   that asserts the verb-table contents, AND with the pack-side
   `pack-ops/HELP-FRAGMENT-PACK.md:30` row (which legitimately KEEPS
   `add-capability.sh` as a pack verb — it is pack-only by directory and renders
   via `pack-help.sh` only on the pack side). Per
   `enumerate-encoding-surfaces`: enumerate the validator + its test fixtures and
   update in lock-step if any encode the deleted row.
4. **`pack-ops/HELP-FRAGMENT-PACK.md:30` — NO CHANGE (legitimate pack verb).**
   Confirmed pack-only surface (`pack-ops/`, never installed; `pack-help.sh`
   renders it pack-side). Listed here only to mark it explicitly out of scope so
   a coder does not "symmetrically" strip it.
5. **`_SANCTIONED_PACK_SIDE_SHIPPED` / Check 47 — NO CHANGE.** add-capability.sh
   is not in the set and does not qualify (fails the dual-use prong-2 "a client
   surface invokes it" test — it requires `$PACK`). The frozen 2-tuple
   (`detect.sh`, `pack-help.sh`) is unaffected. No install-map edit. Documented
   here to close the "should it be sanctioned?" question: **no.**
6. **`test-fixtures/manifest.txt` regen** (`regenerate-manifest-v11-surface`):
   the strips touch `project-template/` and `supporting-docs/` (v11-surface), so
   the coder MUST run `bash test-fixtures/build.sh --all --clean` and stage the
   manifest if its diff is non-empty. (add-capability.sh itself is not in the
   manifest, but the edited client docs may be.)
7. **Pack-side leak cross-ref:** C3 (METHODOLOGY:1412 `V10-DESIGN §5.14.3`) is
   already tracked as BORDER B2 in the currency-sweep doc. Reconcile so the two
   fixes don't double-strip; this doc's C3 disposition (DELETE) matches the
   currency-sweep B2 verdict.
8. **§5 escalation (Procedure 6 redesign)** — gated on a user/architect decision;
   not a mechanical coder strip. Sequence this BEFORE the C4–C7 strips if the
   user chooses redesign over surgical removal.

---

## 7 — Justification summary

- **Governing rule (`client-ref-delete-or-forward-look`):** genuinely-pack-only
  asset → DELETE client references (case 1 / verdict (b)). Confirmed by EEB-2/3/6
  (not installed, needs `$PACK`, not sanctioned).
- **`dependency-direction-placement`:** add-capability.sh is a pack operation (it
  sources detect.sh and is named in the canonical pack-op set, EEB-5) — pack-side
  a fortiori; ship-status does not pull it client-side; it fails the sanctioned
  dual-use criterion. No install-map / Check-47 change.
- **Hypothesis CHALLENGED and REJECTED:** "ship to `project-template/scripts/`"
  fails because the script cannot run at a client install (EEB-2) — forward-look
  presupposes a working landed path, which does not exist.

---

## 8 — Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` issued; only read-only `git rev-parse/branch`, `find`, `grep`, `sed -n`, and one heredoc `cat >` writing this doc. | **COMPLIANT** |
| `agents-read-rule-docs-in-full` | Read in full: `CLAUDE.md` (541 lines incl. `## Pack memory`), `pack-ops/PACK-AGENTS.md` (226), `pack-ops/PACK-CHAT.md` (310), and the 8 curated memory files (`agents-read-rule-docs-in-full`, `client-ref-delete-or-forward-look`, `bd-pack-only-operational-rule`, `pack-project-separation-of-concerns`, `architect-planner-empirical-evidence`, `preliminary-triage-architect-challenge`, `scope-deliverables-to-the-ask`, `agent-output-rules-applied-block`) — each read via a single full-file Read call, no offset/limit cropping. | **COMPLIANT** |
| `client-ref-delete-or-forward-look` | Applied explicitly in §3 (classification = genuinely-pack-only → DELETE) and §4 (per-ref disposition table, every client ref classified DELETE/KEEP/retag). | **COMPLIANT** |
| `dependency-direction-placement` | §3 + §7: add-capability.sh is a pack operation sourcing detect.sh (EEB-5), pack-side a fortiori; fails dual-use sanctioned criterion (EEB-6); no `_SANCTIONED_PACK_SIDE_SHIPPED`/Check-47/install-map change (ripple item 5). | **COMPLIANT** |
| `empirical-evidence-blocks` | §2 EEB-1..EEB-7: each state-claim carries command + captured output + HEAD `60bb2d6` + date 2026-06-03 + interpretation + SUPPORTED conclusion. | **COMPLIANT** |
| `preliminary-triage-architect-challenge` | §1 + §3 + §7: working hypothesis ("ship it") stress-tested against the can-it-run-client-side test (EEB-2) and REJECTED, not rubber-stamped; HIGH bar (boundary-with-existing-pack) applied. | **COMPLIANT** |
| `scope-deliverables-to-the-ask` | Output is exactly verdict + per-ref disposition table + coder recipe + ripple list + justification; no coverage-attestation sprawl or unrequested edge-case multi-pass. | **COMPLIANT** |
| `rules-applied-verification-block` | This table — per-rule name + quoted evidence + conclusion; no empty-evidence rows. | **COMPLIANT** |
| `preflight-stop-means-stop` | No fabricated facts (every claim has an EEB); no parent stop directive received; no state-changing git verb. | **COMPLIANT** |
