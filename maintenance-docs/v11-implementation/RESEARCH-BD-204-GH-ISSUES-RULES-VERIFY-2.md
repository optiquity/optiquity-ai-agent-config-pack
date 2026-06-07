# RESEARCH-BD-204 — VERIFICATION-2 (focused: the two SECOND-fold-in rows only)

> **Role:** pack-docs-researcher (ADVERSARIAL VERIFIER). **Mode:** read-only repo + ONLINE research;
> one report write. No design.
> **Under verification:** the SECOND fold-in to `maintenance-docs/v11-implementation/RESEARCH-BD-204-GH-ISSUES-RULES.md`
> — exactly two NEW rule rows (**R-OPS-7** repo-creation limits; **R-ACCT-5** account repo quota) plus
> the consistency of that fold-in (rule-count 30; §3 rows; DS-6).
> **Scope discipline (per mandate):** I did NOT re-verify the 28 previously-verified rows. ONLY the 2
> new rows + the consistency spot-check.
> **HEAD (verified):** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`). **Date:** 2026-06-07.
> Platform claims: URL + quoted text (independently fetched this session). Repo claims: CMD + verbatim OUT.

---

## §0 — Bottom line

**Verdict: VERIFIED** (with two NON-blocking framing NITs noted, neither of which changes the rows'
load-bearing conclusions).

Both new rows are correct on every load-bearing claim:
- **R-OPS-7** — the load-bearing NEGATIVE ("GitHub documents NO repository-creation-specific rate
  limit; repo create rides the general secondary caps") is CONFIRMED. I hunted for any official
  repo-create-only threshold and found NONE — the negative holds. The general-secondary quotes
  (80/min, 500/hr, 100 concurrent, 900 points/min, 90s CPU/60s) are verbatim-accurate. The implication
  (1 repo/rehearsal ≪ 500/hr; the binding constraint is the 211 issue-creates) is sound.
- **R-ACCT-5** — every leg verifies against official sources: personal accounts own UNLIMITED
  public+private repos; the 100,000 hard cap + 50,000 banner + email/audit-log-every-5,000 quotes are
  verbatim-accurate; the 10 GB on-disk figure IS the `.git` folder and IS framed as a recommendation;
  and ISSUES ARE DATABASE-STORED, NOT in `.git` (independently confirmed) — so ~211 archived-scratch
  issues consume ≈0 of both quota axes. Net "no quota wall" conclusion is robust.

Consistency spot-check PASSES: rule count is **30** everywhere it is stated; the §3 compliance rows for
both new rules map FACTUALLY to real design anchors (§3.3d pacing, §5.c disposal — both confirmed
present in `ARCHITECTURE-BD-204-LOSSLESS-FIX.md`) without proposing design; **DS-6** (gh-version) is
recorded as DOCUMENTED-SILENT, not fabricated — independently confirmed no official line pins it.

Two NITs (framing only, not corrections to the verdict):
- **NIT-1 (R-ACCT-5):** "archived repos COUNT toward the cap (no documented exception)" — the official
  docs are SILENT on an archived-repo exemption; they do not affirmatively state archived repos count.
  The report states it as positive fact. This is a conservative inference (treating them as counting is
  the SAFE direction) and the safety conclusion holds either way, so it is immaterial — but the row
  asserts slightly more certainty than the source carries.
- **NIT-2 (R-ACCT-5):** the 10 GB on-disk figure — the report (correctly) quotes the official
  "we recommend staying within" framing as a RECOMMENDATION; some third-party sources call it a "hard
  limit." The report's official-doc framing is the right one; just flagging the divergence exists.

---

## §1 — THE TWO NEW ROWS: correctness table

| Row | Claim under verification | Independent source + quoted text | Verdict |
|---|---|---|---|
| **R-OPS-7** (no repo-create-specific rate limit) | Repo create has NO documented repo-only threshold; it is a content-generating mutation under the GENERAL secondary caps (80/min, 500/hr, 100 concurrent, 900 pts/min, 90s CPU/60s); DOCUMENTED-SILENT on a repo-only limit; binding constraint = each rehearsal's 211 issue-creates, not the repo create | docs Rate-limits, "About secondary rate limits": *"In general, no more than 80 content-generating requests per minute and no more than 500 content-generating requests per hour are allowed."*; *"No more than 100 concurrent requests are allowed."*; *"No more than 900 points per minute are allowed for REST API endpoints…"*; *"No more than 90 seconds of CPU time per 60 seconds of real time is allowed."* <https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api> — and **I searched specifically for an official repository-creation-only rate limit (REST `POST /user/repos`, `gh repo create`); NONE is documented** (the rate-limits doc has no repo-create section; the negative is confirmed) | **VERIFIED** — the load-bearing negative holds; quotes verbatim; implication sound |
| **R-ACCT-5** (account repo quota + on-disk) | (a) personal accounts own UNLIMITED public+private repos; (b) hard cap 100,000 (banner 50,000; email + audit-log every 5,000); (c) archived repos COUNT (no exception); (d) 10 GB on-disk = `.git` folder, a recommendation; (e) issues are DB-stored not `.git`, so ~211 archived-scratch issues ≈0 of both axes | (a) docs Types-of-accounts: *"All personal accounts can own an unlimited number of public and private repositories, with an unlimited number of collaborators…"* <https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts> · (b) docs Repository-limits: *"Organizations and accounts may not exceed 100,000 repositories. When an account surpasses 50,000 repositories, a banner will appear… administrators will receive email notifications, and the audit log will update every additional 5,000 repositories created."* <https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits>; corroborated by changelog 2025-03-27 (effective Apr 28 2025) <https://github.blog/changelog/2025-03-27-repository-ownership-limits/> · (d) same Repository-limits doc: *"On-disk size: 10 GB. On-disk size refers to the size of the .git folder (the compressed form of the repository)."* under *"we recommend staying within the following maximum limits"* · (e) independently confirmed: *"issues … are stored separately by the platform … not stored in the .git folder that you clone"* (git-clone-not-backup; rewind.com + cloning docs) | **VERIFIED** on legs (a)(b)(d)(e); leg (c) = **VERIFIED-by-conservative-inference** (docs SILENT on an archived exemption — see NIT-1); net "no quota wall" conclusion ROBUST |

### Negative-claim hunt detail (R-OPS-7 — the load-bearing assertion)

> The mandate flags the "no repo-specific limit" NEGATIVE as load-bearing. I ran a dedicated search
> ("GitHub repository creation rate limit per hour API documented limit"). The official rate-limits doc
> returns ONLY the general primary (5,000/hr) + secondary (80/min, 500/hr, 100-concurrent, 900-points,
> 90s-CPU) limits; there is NO repository-creation-specific section or threshold anywhere in it. A
> practitioner result even phrases it directly: *"For repository creation specifically, in general, no
> more than 80 content-generating requests per minute and no more than 500 … per hour are allowed"* —
> i.e. repo create is folded into the SAME general content-creation regime. `INTERP`: the report's
> negative ("NO documented repo-specific limit") is correct, and its DOCUMENTED-SILENT label for a
> repo-only threshold is the honest characterization. `CONCL`: SUPPORTED.

### Sanity-check of the implications

- **R-OPS-7 implication** ("1 repo/rehearsal ≪ 500/hr; the binding gate is the 211 issue-creates"):
  SOUND. One repo create is a single content-generating mutation; even dozens of rehearsals/day stay
  far under 500/hr on the repo-create axis. The real pressure is the per-rehearsal 211 issue burst —
  exactly the R-OPS-2/3 pacing gate the report already flags. The row's "no separate repo-create gate
  needed" is correct.
- **R-ACCT-5 implication** ("accumulating archived ~211-issue scratch repos approach neither cap"):
  SOUND. Repo-count: even a multi-year daily campaign is orders of magnitude below 100,000 (and the
  50,000 banner). On-disk: a scratch repo carries ~no code → ~0 of the 10 GB `.git` budget; the 211
  issues live in GitHub's DB, not `.git` (leg (e), independently confirmed). Both axes clear with vast
  headroom. The "archive-not-delete disposal is benign" conclusion holds regardless of NIT-1.

---

## §2 — CONSISTENCY SPOT-CHECK (the fold-in's internal integrity)

### 2.1 Rule count = 30 everywhere

> `CMD`: `grep -nE '\b30 rule|30 rule rows|R-OPS-1\.\.7|R-ACCT-1\.\.5' RESEARCH-BD-204-GH-ISSUES-RULES.md`
> `OUT` (verbatim, reconciled): §0 line 39 *"**30 rule rows** across 8 categories"*; §1 reconciliation
> lines 454-457 *"30 rule rows: A (R-BODY-1..7 = 7) + … + F (R-OPS-1..7 = 7) + … + H (R-ACCT-1..5 = 5)
> = 30 rule rows"* with the audit trail *"25 … first fold-in … -> 28; second fold-in +R-OPS-7 GAP-1 /
> +R-ACCT-5 GAP-2 -> 30"*; §6 Rules-Applied line 785 *"30 rule rows"*; §9 second-fold-in line 854
> *"Rule count: 28 -> 30 rule rows"*. `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: the category arithmetic sums to 30 (7+2+4+2+2+7+1+5 = 30) and every stated count is 30; the
> 25→28→30 provenance is internally consistent. `CONCL`: SUPPORTED — **no count drift**.

### 2.2 §3 compliance rows map FACTUALLY to real design anchors, no design proposed

> `CMD`: `grep -nE '3\.3d|§5\.c|provider_min_write_interval_s|provider_writes_per_hour_max|archive-not-delete' maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md`
> `OUT` (verbatim, abridged): `:529 ### 3.3d OPERATIONAL RULES for the C-8 bulk create (R-OPS-2/3
> pacing + R-OPS-6 mention/autolink)`; `:550-551 provider_min_write_interval_s (GitHub: 1 …) and
> provider_writes_per_hour_max (GitHub: 500 …)`; `:414 the C-7 live oracle (§5.c)`; `:844 SCRATCH
> DISPOSAL REWORK (§5.c …): replace gh repo delete … with gh repo archive`. `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: the report's R-OPS-7 row cites **§3.3d** (`provider_min_write_interval_s`=1 /
> `provider_writes_per_hour_max`=500, the pacing gate) and its R-ACCT-5 row cites **§5.c** (archive-not-
> delete disposal) — BOTH design anchors EXIST in the architecture doc with exactly those contents. The
> rows describe what the design ALREADY does ("DESIGN's §3.3d pacing MUST honor…"; "DESIGN's §5.c
> archive-not-delete disposal is SAFE…") and explicitly tag themselves *"factual mapping; no design"*.
> `CONCL`: SUPPORTED — the two new §3 rows are FACTUAL mappings to real anchors, propose no design, and
> do not fabricate a design section.

### 2.3 DS-6 recorded as DOCUMENTED-SILENT, not fabricated

> The report's DS-6 row (line 740) states the `gh` version that introduced `gh repo archive` /
> `gh repo view --json isArchived` is NOT pinned by any single official line, and explicitly asserts
> NO version ("per the mandate … NO version is asserted here … Recorded as the absorbed flag, not a
> fabricated pin"). I independently checked: the `gh` releases page carries per-version notes but no
> official "introduced in vX.Y" line for `gh repo archive`; the command is GA in modern `gh`. `INTERP`:
> DS-6 is a faithful DOCUMENTED-SILENT entry — it asserts a gap, not a fact. `CONCL`: SUPPORTED — not
> fabricated; correctly deferred to the §5.f tooling preflight (which checks the runtime `gh` supports
> the commands, rather than pinning a version).

---

## §3 — VERDICT

**VERIFIED.** Both second-fold-in rows (R-OPS-7, R-ACCT-5) are correct on every load-bearing claim,
independently sourced this session; the R-OPS-7 negative ("no documented repo-create-specific limit")
holds under a dedicated hunt; R-ACCT-5's archived-scratch ≈0-quota conclusion is robust on both axes.
The fold-in is internally consistent: rule count 30 everywhere; the two new §3 rows map factually to
real design anchors (§3.3d / §5.c) without proposing design; DS-6 is a faithful DOCUMENTED-SILENT
record, not a fabrication.

Two NON-blocking NITs (framing, not factual errors; do NOT change the verdict):
1. **NIT-1:** R-ACCT-5's "archived repos COUNT toward the cap (no documented exception)" overstates
   source certainty — the docs are SILENT on an archived-repo exemption rather than affirmatively
   stating they count. The inference is conservative (safe direction) and the safety conclusion holds
   either way; optionally soften the wording to "the docs document no archived-repo exemption, so —
   conservatively — they are assumed to count."
2. **NIT-2:** the 10 GB on-disk figure is correctly quoted as a RECOMMENDATION from the official doc;
   third-party sources sometimes call it a "hard limit." The report's official framing is right;
   noting the divergence for completeness only.

No CORRECTIONS-NEEDED: nothing in the two rows is WRONG or UNVERIFIABLE; the consistency checks pass.

---

## §4 — Rules-Applied Verification Block

| Rule | Verification evidence (actual) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` or state-changing verb; `git rev-parse HEAD` (read-only) only; sole write is this ONE report; WebSearch for online research. | COMPLIANT |
| `external-rules-census-before-design` | Both new rows re-sourced from official docs this session (rate-limits secondary, repository-limits, types-of-accounts, changelog 2025-03-27) + a dedicated NEGATIVE hunt for a repo-create-specific limit (found none) + independent confirmation that issues are DB-stored not in `.git`. | COMPLIANT |
| `verify-availability-not-just-existence` | Both rows re-checked on GA + personal-account-FREE axes (R-OPS-7 GA personal; R-ACCT-5 unlimited-repos GA personal/Free; 100,000 cap applies to all accounts incl. personal). | COMPLIANT |
| `researcher-maps-blast-radius` | Scoped exactly to the 2 new rows + consistency (the 28 prior rows NOT re-verified per mandate); verified the §3 rows' design anchors exist in the architecture doc (grep, verbatim); rule-count reconciled across all 4 statement sites. | COMPLIANT |
| `empirical-evidence-blocks` | Every repo claim: CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL (§2.1/§2.2/§2.3 + R-OPS-7 negative hunt); every platform claim: URL + quoted text (§1 table). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered EXACTLY the 2-row correctness table + consistency spot-check + verdict; explicitly did NOT re-verify the 28 prior rows; NITs fenced as non-blocking; no design, no fix authoring. | COMPLIANT |
| `filename-uniqueness-heuristic` | `find . -name "RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY-2.md" -not -path "./.git/*"` returned EMPTY before write (Bash, this session). | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence; no AMBIGUOUS state. | COMPLIANT |

---

## §5 — READ-IN-FULL attestation (this session, at HEAD `feaa45d`)

| Document / source | Direct-read proof |
|---|---|
| `RESEARCH-BD-204-GH-ISSUES-RULES.md` — the two new rows + consistency surfaces | Read R-OPS-7 (lines 348-372), R-COMMENT/R-ACCT block incl. R-ACCT-5 (374-450), §1 rule-count reconciliation (452-459), §3 rows R-OPS-7/R-ACCT-4/R-ACCT-5 (683-689) + §3 summary (691-722), DS-6 (740), §6 source/attestation lines (785, 817), §9 second-fold-in section (850-854). |
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` — cited design anchors | Verified §3.3d (line 529 + `provider_min_write_interval_s`/`provider_writes_per_hour_max` 550-553) and §5.c (414, 844 scratch-disposal archive-not-delete) EXIST with the cited contents (grep, verbatim). |
| `backlog/BD-204.md` | The `:20` "scratch-repo proof -> archive -> real flip" scope line (basis the new rows reference) — read in the prior verification pass; re-confirmed in scope here. |
| Official GitHub docs + sources (fetched via WebSearch this session) | Rate-limits (secondary caps + the repo-create negative); Repository-limits (100,000 / 50,000 / 5,000 audit; 10 GB on-disk = `.git`, recommendation framing); Types-of-accounts (unlimited public+private repos); changelog 2025-03-27 (ownership limits, effective Apr 28 2025); git-clone-not-backup / cloning docs (issues DB-stored, not in `.git`); `gh` releases (no official version pin for `gh repo archive` → DS-6 silent). NOT relied on from training data. |

**No named document was derived rather than read.** All repo measurements are this session's own
command output at HEAD `feaa45d` (2026-06-07); all platform claims carry a source URL + quoted text.

**End of RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY-2.md**
