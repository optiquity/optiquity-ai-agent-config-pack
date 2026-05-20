# ARCHITECTURE-BD-179 — `validate-pack.py` Check 40: pack-ops/ bare cross-reference scanner

**Status:** strategy doc (architect-pass output)
**Author:** pack-architect (background spawn 2026-05-20)
**Source BD:** BD-179 (5th BD in the BD-175 emergency batch; predecessor BDs 175/176/177/178 closed)
**Audience:** pack-coder (implements this strategy mechanically); pack-reviewer (verifies the implementation against this strategy); Pack Chat (presents this strategy to user before pack-coder spawn)
**Disposition contract:** coder follows the chosen designs in §2–§8 (D1–D8); §9 lists rule interactions to compose against; §10 hands off the concrete file list + commit shape; §11 lists open questions that gate user approval.

---

## §1 Context

### §1.1 BD-179 problem statement

`pack-ops/MERGE-STRATEGY.md` demonstrated three distinct bare-cross-reference defect classes during the BD-175 emergency batch:

1. **Cross-references-list defects (load-bearing).** Pre-F1: 5 of 7 bullets in the `## Cross-references` list (MERGE-STRATEGY.md L466–474) were bare (no subdirectory path, ambiguous resolution). F1 commit `88a0aea` qualified L471 / L473 / L474 (`supporting-docs/MIGRATION-v10-to-v11.md`, `QUICKSTART.md`, `scripts/validate-pack.py`). The cross-references list is the canonical "where to look next" pointer set — bare refs there have the highest reader-impact.

2. **Inline-prose defects (softer).** F1 IMPL-REPORT §6 flagged 8 OTHER bare refs to the same two files scattered through MERGE-STRATEGY.md: 5 bare `MIGRATION-v10-to-v11.md` (L271, L313, L329, L426, L440) + 3 bare `validate-pack.py` (L270, L412, L479) + 1 narrative shorthand `validate-pack` (L226). F1 left these untouched per tight scope. Inline-prose is lower-impact than cross-references list (reader navigates from prose less often) but identical defect class — reader who clicks the prose ref has the same disambiguation burden.

3. **Audience-mismatch defect (intentional vs accidental).** L472 references `docs/pack/OPTIONAL-FEATURES.md` — the POST-install project-side path. MERGE-STRATEGY.md self-identifies "Audience: pack-internal" at L3. F1 commit `88a0aea` Commit 9b chose to keep the client-side path per Override 8 (the surrounding content discusses install-time migration scenarios that resolve at client repos). The reviewer flagged this as a candidate for architect-pass triage: is this intentional audience-bridge or accidental contamination?

### §1.2 Batch position + sequencing constraint

BD-179 is the 5th of 8 BDs in the BD-175 emergency batch. Predecessors (BD-175 + BD-176 + BD-177 + BD-178) closed. Successors (BD-180 / BD-181 / BD-182) all blocked on BD-179. End-of-batch reviewer fires after BD-182. Architect-pass strategy doc → coder mechanical apply → per-BD reviewer pass is the in-batch contract.

### §1.3 Cross-BD constraints picked up since BD-179 was opened

Three batch decisions affect the design space:
- **BD-176** expanded the RC9 manifest-regen trigger to cover `pack-ops/` and `supporting-docs/` (was: just `project-template/` + `scripts/`). Implication for BD-179: any pack-ops/ markdown edit BD-179 makes triggers a manifest regen alongside the scope edits.
- **BD-178** aligned trinity asymmetries across `project-template/{CLAUDE,AGENTS,GEMINI}.md`. Implication for BD-179: trinity baseline is fully symmetric at HEAD; any new trinity rule BD-179 needs to add (none anticipated — Check 40 is a CI gate, not a trinity rule) lands on a clean parity baseline.
- **BD-180 (next)** will extend Check 39's `cmd_update` mapping symmetry coverage to additional surfaces. Implication for BD-179: Check 40 should compose cleanly with Check 39 and its planned BD-180 extensions, not duplicate scope.

### §1.4 The defect class in pack-architectural terms

The bare-cross-reference defect is a special case of the design-best-practice principle "single source of truth for content / rules / config" (`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Design best practices" principle #1) when applied to file-pointer references. A bare ref like `MIGRATION-v10-to-v11.md` could resolve to: pack root, `supporting-docs/MIGRATION-v10-to-v11.md`, `pack-ops/MIGRATION-v10-to-v11.md` (none of these is the actual ref, but a reader does not know that a priori), `project-template/docs/pack/MIGRATION-v10-to-v11.md`, etc. The bareness is the defect — the reader cannot uniquely resolve the target without out-of-band knowledge. Qualified refs (`supporting-docs/MIGRATION-v10-to-v11.md`) resolve unambiguously.

This frames the design problem: Check 40 enforces unambiguous resolvability for file-pointer refs in `pack-ops/` markdown.

---

## §2 D1 — Scope of pack-ops/ files Check 40 walks

### §2.1 D1a — File coverage (chosen: ALL `pack-ops/*.md` files except the regenerated mirrors)

**Decision:** Check 40 walks ALL `pack-ops/*.md` files EXCEPT `pack-ops/BACKLOG.md` and `pack-ops/CHANGELOG.md`.

**Rationale:**

- **Inclusion (default):** `pack-ops/` is the canonical home for PACK × OPERATIONS docs (per `pack-ops/BOUNDARY-DEFINITION.md` §2 C2 examples). The bare-cross-reference defect class is uniform across these docs — MERGE-STRATEGY.md just happened to be the first one where the defect surfaced empirically. Inclusion is the simplest-correct-design heuristic; per-file allowlisting would re-create the deny-list-by-omission pattern that drove BD-175 audit findings.

- **Exclusion: `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md`** are regenerated mirrors (per pack-memory "Per-entry trees vs mirrors — mode-dependent source of truth" rule). They aggregate per-entry source content from `/backlog/<ID>.md` and `/changelog/<ID>.md`. Per-entry source content is authoritative; the mirror is regenerated. If Check 40 walked the mirrors, it would FAIL on every bare ref in any per-entry source — turning Check 40 into a per-entry-source linter by accident, scope-creeping into the per-entry tree. The per-entry tree has its own discipline (cross-reference integrity per Check 34) and is not the surface this BD addresses.

  The mirrors carry their bare refs by-construction (regenerated from per-entry source) and are read-stable. Bare refs in per-entry source ARE a legitimate concern but belong to a separate BD scope (touches `/backlog/` and `/changelog/` per-entry trees, not `pack-ops/` operating docs).

- **Survey confirms scope:** 11 pack-ops/*.md files at HEAD. Excluding BACKLOG.md (4205 lines) and CHANGELOG.md (734 lines), the in-scope set is 9 files totaling ~2098 lines:
  - `pack-ops/BOUNDARY-DEFINITION.md` (255 lines)
  - `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (297 lines)
  - `pack-ops/DRY-RUN-MIGRATION.md` (199 lines)
  - `pack-ops/HELP-FRAGMENT-PACK.md` (42 lines)
  - `pack-ops/HELP-FRAGMENT-TRACKER.md` (49 lines)
  - `pack-ops/MERGE-STRATEGY.md` (482 lines)
  - `pack-ops/OPTIONAL-FEATURES.md` (235 lines)
  - `pack-ops/PACK-AGENTS.md` (248 lines)
  - `pack-ops/PACK-CHAT.md` (291 lines)

### §2.2 D1b — File-type extension (chosen: `.md` only)

**Decision:** Check 40 scans only `.md` files under `pack-ops/`.

**Rationale:**

- **Bare-cross-reference defect is a prose concern.** TOML / shell / Python / YAML files use language-native import or path mechanisms (Python `from`, shell `source`, TOML keys). When TOML / shell / Python refs ARE bare (e.g., `source customization-preserve.sh` in a shell script), the shell interpreter's `PATH` resolution governs — not a doc-ref-ambiguity problem.
- **Markdown is the surface where bare refs cause reader friction.** The defect cataloged in §1 (MERGE-STRATEGY.md F1/F1-fix work) is uniformly markdown.
- **Future-proofing:** if a TOML or shell file in `pack-ops/` ever embeds prose path refs (e.g., a block comment with bare doc names), the heuristic above breaks — but the current pack-ops/ directory has only one non-`.md` file at HEAD (`.boundary-exempt-root.txt`, machine-readable allowlist) and the `.md`-only restriction is structurally adequate today.

### §2.3 What "pack-ops/*.md" includes (clarification)

The glob is non-recursive: `pack-ops/*.md`. No subdirectories under `pack-ops/` carry markdown today; if a subdirectory is added in a future BD (e.g., `pack-ops/architecture/`), that BD must extend the glob in the same commit or scope its content separately.

---

## §3 D2 — Bare-reference pattern detection

### §3.1 Chosen patterns (P1 + P2 + P3 + P5 in scope; P4 out of scope)

**Decision:** Check 40 detects bare refs in:
- **P1 — Markdown bullet items** with inline filename refs: `- \`FILENAME.md\` — description` or `- \`FILENAME.md\``
- **P2 — Prose inline mentions**: `... see \`FILENAME.md\` ...`, `... per \`FILENAME.md\` ...`, `... in \`FILENAME.md\` ...`, etc.
- **P3 — Table cell refs**: `| \`FILENAME.md\` |`
- **P5 — Hyperlink refs**: `[link](FILENAME.md)` or `[link text](FILENAME.md)` (the `(target)` half of a markdown link)

**Out of scope:**
- **P4 — Code-block embedded refs.** Code blocks (` ```bash ... ``` `, indented 4-space blocks, single-backtick spans inside other code) are excluded. Rationale: code blocks demonstrate example commands or file paths the user types into a shell; the path semantics are governed by the user's shell working directory at execution time, not by the surrounding markdown. A code block like `python3 scripts/validate-pack.py` is already qualified by the user's CWD; rewriting to `python3 /path/to/scripts/validate-pack.py` would be wrong (it's a script invocation, not a doc reference).

### §3.2 Detection mechanism (chosen: regex over a code-block-stripped representation)

**Decision:** Regex-based detection over a markdown representation that has been preprocessed to strip code-block content. AST-based markdown parsing is out of scope.

**Rationale:**

- **Regex matches the existing Check 36–39 implementation pattern.** All five existing boundary-/symmetry-prevention checks (36, 37, 38, 39) use regex (see `_DENY_LIST_FILENAMES`, `_DENY_LIST_AGENT_NAMES`, `_subject_has_keyword`, `_parse_cmd_update_entries`). Introducing an AST dependency (`markdown` Python package, `mistune`, etc.) adds a runtime dependency to `validate-pack.py` that today is dependency-free (stdlib only). Per `pack-ops/PACK-CHAT.md` rule "simplest-correct-design heuristic," stdlib regex wins.

- **Code-block stripping is a well-bounded preprocess.** Markdown fenced code blocks delimited by ` ``` ` (with optional language identifier) are easy to identify by line-prefix regex; indented 4-space blocks are recognizable by line-prefix indentation (after an empty line); single-backtick spans inside non-code-block text are NOT code blocks (they ARE the filename markers Check 40 looks for — see §3.3 for the marker discipline). The preprocessing function returns the markdown with code-block content REPLACED by empty lines (preserving line numbers so Check 40 can still cite `file:line` accurately per the existing Check 37 convention).

- **Trade-off (acknowledged):** edge cases where a single-backtick span LOOKS like a filename ref but is actually inline code (e.g., `` `cp` is the shell command ``) are theoretically possible. The current proposal accepts this small false-positive risk because (a) the filename-vs-shell-command disambiguation is mechanically possible (filenames have a `.ext` extension; shell commands typically don't), (b) the allowlist (§6) handles the residual edge cases by inline marker.

### §3.3 Pattern recognition (the "what is a filename ref" decision)

**Decision:** A bare cross-reference is a backtick-delimited span containing an alphanumeric token (no `/`) ending in a known file extension. The bareness check is enforced by the absence of `/` in the regex character class — any `/` inside the backticks means the span is already a qualified path and Check 40 correctly does not match it.

**Initial-draft regex (Python re syntax — superseded by §3.5):**

```python
_CHECK_40_BARE_REF_PATTERN = re.compile(
    r"`([A-Z][A-Z0-9_.-]*\.(?:md|sh|py|toml|yml|yaml|json|txt))`"
)
```

A backtick span like `` `supporting-docs/MIGRATION-v10-to-v11.md` `` has `/` inside; the character class `[A-Z0-9_.-]` does not include `/`, so the regex does not match. A bare span like `` `MIGRATION-v10-to-v11.md` `` matches cleanly within the character class.

The first-character class `[A-Z]` rejects lowercase-starting filenames; §3.5 widens this to `[A-Za-z]` after verification surfaces lowercase-starting script names like `merge-json.py` in the in-scope set. The final regex is the §3.5 form (`[A-Za-z][A-Za-z0-9_.-]*\.(?:md|sh|py|toml|yml|yaml|json|txt)`); §3.3 here shows the initial-draft form for derivation clarity.

**Markdown-hyperlink variant (for P5):**

```python
_CHECK_40_HYPERLINK_PATTERN = re.compile(
    r"\]\(([A-Z][A-Z0-9_.-]*\.(?:md|sh|py|toml|yml|yaml|json|txt))\)"
)
```

The `](FILENAME.md)` portion of `[link text](FILENAME.md)`. Same character-class discipline: a `/` in the path means it's qualified and the regex misses it.

### §3.4 Patterns explicitly NOT detected

- **Wildcard refs:** `` `HELP-FRAGMENT*.md` `` (DRY-RUN-MIGRATION.md L94). The wildcard `*` is not a valid filename character in the regex (not in `[A-Z0-9_.-]`); these refs are skipped by construction. They are bare-ref-shaped but represent a class of files (glob), not a single file — qualification would change their meaning.

- **Generic family refs:** `` `ARCHITECTURE-V*.md` `` (CONCEPTUAL-REVIEW-METHODOLOGY.md L38). Same reasoning as wildcards. The `*` excludes them.

- **Narrative shorthand without extension:** `` `validate-pack` `` (MERGE-STRATEGY.md L226, "the pack never ships `x-`-prefixed scripts (validate-pack Check 8 enforces)"). The regex requires a `.ext` suffix; bare-without-extension narrative shorthand is not detected by Check 40. This is intentional: validate-pack-the-CI-script (`scripts/validate-pack.py`) is distinct from validate-pack-the-concept ("the validate-pack gate"); the latter is the concept noun, not a file-pointer ref. Per §1.4 framing, only file-pointer refs are in scope.

- **Lowercase-starting filenames:** the regex requires `[A-Z]` as the first character. Files like `_rules.md`, `_format.md`, `_intro.md` (per-entry tree supporting files, lowercase-underscored) are not detected. These per-entry tree filenames are scoped to per-entry trees and don't appear as bare refs in pack-ops/*.md content surveyed in §1.

- **Filenames embedded in URLs or filesystem paths:** by definition these are NOT bare (the URL or path qualifier resolves them).

### §3.5 What gets flagged in MERGE-STRATEGY.md by the §3.3 regex (verification)

Applying §3.3's regex against the post-F1 HEAD MERGE-STRATEGY.md identifies (approximately, line numbers may have drifted post-F1):

- **Cross-references list (L470–474):** `` `scripts/lib/customization-preserve.sh` `` qualified — no match. `` `scripts/lib/customization-report.sh` `` qualified — no match. `` `scripts/tests/test-customization-preserve.sh` `` qualified — no match. `` `supporting-docs/MIGRATION-v10-to-v11.md` `` qualified — no match. `` `docs/pack/OPTIONAL-FEATURES.md` `` qualified — no match (BUT see §7 D6 for the audience-mismatch concern this triggers). `` `QUICKSTART.md` `` BARE — MATCH (regex flags it; D5 allowlist below admits it as pack-root-resolvable). `` `scripts/validate-pack.py` `` qualified — no match.

- **Inline prose:** `MIGRATION-v10-to-v11.md` BARE at L271, L313, L329, L426, L440 — 5 MATCHES. `validate-pack.py` BARE at L270, L412, L479 — 3 MATCHES. `validate-pack` narrative shorthand at L226 — NO MATCH (no `.ext` suffix per §3.4). `HELP-FRAGMENT-PACK.md` BARE at L479 — MATCH. `merge-json.py` BARE at L100, L108, L119 — 3 MATCHES (downcased start; the regex requires `[A-Z]` first char, so `merge-json.py` is NOT matched).

  Wait — `merge-json.py` starts lowercase. The regex `[A-Z]` first-char excludes it. So bare `merge-json.py` is NOT detected. This is a design gap: the F1-fix candidate refs DO include lowercase-starting script names like `merge-json.py`. Resolution: relax the regex first-character class to `[A-Za-z]` to admit lowercase-starting filenames. The `[A-Z]` constraint was intuitive but unnecessarily restrictive.

**Revised regex (§3.3 final):**

```python
_CHECK_40_BARE_REF_PATTERN = re.compile(
    r"`([A-Za-z][A-Za-z0-9_.-]*\.(?:md|sh|py|toml|yml|yaml|json|txt))`"
)
_CHECK_40_HYPERLINK_PATTERN = re.compile(
    r"\]\(([A-Za-z][A-Za-z0-9_.-]*\.(?:md|sh|py|toml|yml|yaml|json|txt))\)"
)
```

This change widens detection to include `merge-json.py`, `merge-toml.py`, `customization-preserve.sh`, etc. when they appear bare. Re-applying to MERGE-STRATEGY.md with the revised regex:

- L100, L108, L119: 3 bare `merge-json.py` MATCHES (each could resolve to `scripts/merge-json.py`).
- The narrative-shorthand `validate-pack` at L226 still doesn't match (no `.ext`).

The revised regex is the correct shape. Total MERGE-STRATEGY.md detection set: ~12–14 matches (5 inline `MIGRATION-v10-to-v11.md` + 3 inline `validate-pack.py` + 1 `HELP-FRAGMENT-PACK.md` + 3 `merge-json.py` + 1 `QUICKSTART.md` cross-references list bare; the qualified refs from F1 don't match).

---

## §4 D3 — Per-pattern triage heuristic

### §4.1 Chosen: T1 (always FAIL with allowlist) — uniform severity, allowlist-mediated exemptions

**Decision:** Check 40 treats every bare ref match as a FAIL unless the ref is on the allowlist (§6) OR the surrounding context carries a deliberate anchor-phrase exemption (§6.4). No T2 warning-only mode. No T3 per-location severity variation. No T4 context-driven heuristic policy.

**Rationale:**

- **T2 (warn-only) noise risk.** A warn-only Check 40 would emit ~12–14 warnings on the current MERGE-STRATEGY.md at HEAD plus an additional ~8–15 across the remaining 8 in-scope files. CI logs become noisy; developers learn to scroll past warnings; the next bare-ref class introduction is masked under existing noise. Per `pack-ops/PACK-CHAT.md` "no green-the-test band-aids" principle, "warn but don't fail" is the doc-level equivalent.

- **T3 (hybrid per-location severity) complexity.** Distinguishing "load-bearing" location (cross-references list) from "softer" location (prose) requires the check to identify markdown section structure — heading level, list nesting, table-vs-prose context. Section-structure identification re-introduces the AST dependency rejected in §3.2. Worse, the load-bearing-vs-softer distinction is not stable across the 9 in-scope files (a cross-references list in DRY-RUN-MIGRATION.md is just as load-bearing as in MERGE-STRATEGY.md, but a methodology-section bullet citing rule sources in CONCEPTUAL-REVIEW-METHODOLOGY.md is ALSO load-bearing — these are not "softer"). T3's premise of a clean load-bearing-vs-softer dichotomy does not hold across the in-scope set.

- **T4 (context-driven per-purpose policy) is T3 with more dimensions.** Same complexity tax. Same brittleness.

- **T1 (uniform FAIL with allowlist) matches Check 37's design pattern.** Check 37 uses FAIL + per-file legitimate-context allowlist (`_is_legitimate_deny_list_doc`) + per-pattern anchor-phrase exemption (`_DENY_LIST_ANCHOR_PHRASES`). This is the proven CI-gate shape for prose-content scanning. Check 40 inherits the pattern.

### §4.2 Single severity = FAIL (no NIT / SHOULD / WARN tier)

**Decision:** Check 40 emits FAIL on bare-ref hits not covered by allowlist or anchor-phrase. No tiered severity within Check 40 itself.

**Rationale:** validate-pack.py's existing checks emit binary PASS/FAIL via the `ok()` and `fail()` helpers; there is no NIT/SHOULD tier in the validator. Tiering within Check 40 would break the existing helper contract. The pack-reviewer agent (not validate-pack) is the surface that emits BLOCKER/MUST/SHOULD/NIT severity per `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Severity scheme"; the validator is a binary gate.

### §4.3 Failure-message format (chosen: matches Check 37 conventions)

**Decision:** Each failure emits a message of the form:

```
pack-ops/<file>.md:<lineno> — bare cross-reference `<FILENAME>` (no
directory qualifier). Resolves ambiguously: <candidate paths or "could
resolve to multiple paths">. Remediation: qualify the path (e.g.,
`supporting-docs/<FILENAME>` or `scripts/<FILENAME>`) OR add to
_CHECK_40_ALLOWLIST with one-line rationale OR wrap in code-block
context if it is a shell/code example.
```

**Rationale:**

- **Cite file:line per Check 37's `fail()` convention.** Existing CI gate log shape.
- **Name the bare ref by content.** Reader can grep for it directly.
- **Name candidate paths if known.** The check can do a coarse filesystem walk to suggest qualified paths (e.g., for `MIGRATION-v10-to-v11.md`, the suggestion is "lives at `supporting-docs/MIGRATION-v10-to-v11.md`"). See §5 D4 for the file-exists verification design that this leverages.
- **Three remediation paths (qualify / allowlist / code-block).** Lets the coder pick the right resolution per-case without re-reading the Check 40 design doc.

### §4.4 Implication: BD-179 commit must clean all current FAILs (BOOTSTRAP)

A T1 + uniform-FAIL Check 40 will FAIL at HEAD on the current ~12–14 MERGE-STRATEGY.md hits plus ~8–15 hits across the other 8 in-scope files (full count established by §8 D7 bootstrap survey). The BD-179 commit must address every flagged ref in the SAME commit Check 40 lands, OR add explicit allowlist entries per §6 — otherwise CI fails on the BD-179 commit itself. This is the same bootstrap discipline Check 37 followed (per `scripts/validate-pack.py` lines 4359–4364 comment: "Check 37 lands LAST in the boundary trio per C §13 bootstrap-incompatibility note — the 17 §D-9 contamination refs from audit must be resolved by Commits 4-9 before Check 37 is enabled, otherwise Check 37 FAILs at HEAD.").

§8 D7 spells out the bootstrap commit shape.


---

## §5 D4 — File-exists verification

### §5.1 Chosen: exists-check ENABLED (bareness + resolvability validated together)

**Decision:** Check 40 performs a coarse filesystem walk to discover whether the bare-ref filename has an unambiguous resolved path. Specifically, for each bare-ref hit, Check 40 searches the pack repo (excluding `.git/`, `maintenance-docs/archive/`, `test-fixtures/`, `scripts/tests/fixtures/`, and `node_modules`-like dirs) for files whose basename matches the bare ref. The walk produces a `candidate-paths` set per bare-ref.

**§5.1 EXCLUDE addendum (Phase 2, OQ-S1 ratification 2026-05-20).** The original §5.1 text named `test-fixtures/` but did NOT name `scripts/tests/fixtures/`. The Phase 1 survey applied both exclusions (synthetic test content; not real candidates). User-approved OQ-S1 resolution: ratify the dual EXCLUDE in the architect doc. Without `scripts/tests/fixtures/` excluded, candidate-suggestion messages would frequently point at fixture paths (wrong target for coder guidance). Phase 2 implementation MUST exclude BOTH `test-fixtures/` (top-level) AND `scripts/tests/fixtures/` (per-script synthetic fixture trees).

**Triage per candidate set size:**

| Candidate count | Disposition | Failure message addendum |
|---|---|---|
| 0 | FAIL with "broken ref — no file with that basename exists in the pack repo" | hardest signal; reader knows the ref is stale or typo |
| 1 | FAIL with "qualify to `<the-one-path>`" | check suggests the exact qualified replacement |
| 2+ | FAIL with "qualify to one of: `<path1>` `<path2>` ..."; reader picks | the original ambiguity Check 40 is designed to surface |

**Rationale:**

- **Stronger guarantee than bareness-only.** Bareness-only would flag every backtick-delimited filename — the check would emit no actionable suggestion when there's exactly one candidate path. The exists-check converts "you have a bare ref" into "you have a bare ref AND the target lives at PATH; qualify it" — directly actionable.

- **Walks the pack repo, not just `pack-ops/`.** Bare refs in pack-ops/*.md commonly point at `scripts/`, `supporting-docs/`, `project-template/`, etc. The walk must be repo-wide to find candidates.

- **Excludes regenerated and stale surfaces.** `maintenance-docs/archive/` carries historical content with stale refs by construction; `test-fixtures/` carries synthetic fixture content. Excluding these prevents false candidates from drowning out real ones.

- **`.git/` is always excluded.** Standard discipline; the pack-internal git index doesn't carry pack content.

### §5.2 Coupling to filesystem layout (acknowledged)

The exists-check couples Check 40 to the pack repo's current directory layout. If a future BD relocates `MIGRATION-v10-to-v11.md` from `supporting-docs/` to (say) `migration-docs/`, Check 40's candidate-suggestion for a bare `MIGRATION-v10-to-v11.md` ref correctly updates to the new path (the walk is filesystem-truth at runtime).

Coupling concern: if a future BD DELETES a referenced file without updating its refs, Check 40's "0 candidates" FAIL surfaces the broken ref cleanly — this is feature, not coupling tax.

### §5.3 Implementation cost

The walk runs once per Check 40 invocation, not once per bare ref. Build an in-memory `basename → [paths]` index at the start of `check_bare_pack_ops_refs()` (Check 40's function), then look up each bare-ref hit in O(1) against the index. Walk cost is bounded by the file count of the pack repo (~few thousand at HEAD). The performance is acceptable per the existing Check 37 / Check 38 patterns (which also walk many files).

### §5.4 Per-file allowlist entries skip the exists-check

For allowlist-exempt refs (§6), Check 40 emits a PASS notice and skips the exists-check entirely. Rationale: the allowlist is the "we know this ref is intentional" assertion; re-validating it via filesystem walk is redundant and risks false failures (e.g., an intentionally external ref to a future file the pack doesn't yet ship).

---

## §6 D5 — Allowlist design

### §6.1 Two-tier exemption model: per-pattern allowlist + anchor-phrase exemption

**Decision:** Check 40 uses two complementary exemption mechanisms:

1. **`_CHECK_40_ALLOWLIST` (per-pattern global allowlist)** — a Python dict at module-level mapping a bare basename to a one-line rationale string. Refs in the allowlist PASS unconditionally with a notice.
2. **Anchor-phrase exemption** — like Check 37's `_DENY_LIST_ANCHOR_PHRASES`, a list of contextual phrases that, when present in the ±N-line window around the bare ref, mark the ref as legitimate.

**Rationale:**

- **Per-pattern global allowlist handles the universal cases.** "Pack root markdown filenames" (`README.md`, `QUICKSTART.md`, `LICENSE.md`) are always pack-root-resolvable; bare ref to them in a pack-ops/ doc is unambiguous by repo convention. These belong on the global allowlist.

- **Anchor-phrase handles contextual cases.** A pack-ops/ doc that discusses the project-side voice of a file (e.g., "the client's `MIGRATION-v10-to-v11.md` reference" in a discussion of post-install client procedures) may legitimately use the bare form because the surrounding sentence anchors the audience. Per Check 37's existing pattern, anchor-phrase exemption is the proven shape for this.

- **Per-file allowlist NOT chosen.** A per-file allowlist (where each pack-ops/ file gets its own allowlist of permitted bare refs) would re-create the deny-list-by-omission pattern that drove BD-175 audit findings — and would multiply maintenance burden (every new bare ref needs review for which file allowlist it belongs to). Per-pattern global allowlist scales by ref-class, not file-count.

- **Inline `<!-- check40:skip -->` markers NOT chosen.** Inline HTML-comment markers add markdown-source noise and rely on the markdown renderer ignoring them (true for GitHub render but adds visual clutter when viewing source). The two-tier exemption (allowlist + anchor-phrase) provides sufficient coverage without inline markers.

### §6.2 `_CHECK_40_ALLOWLIST` initial entries (justified set)

```python
_CHECK_40_ALLOWLIST: dict[str, str] = {
    # Pack-root landing-page files — always resolvable at pack root per
    # `pack-ops/BOUNDARY-DEFINITION.md` §2 C1 (PACK × PRODUCT) classification.
    "README.md": "Pack-root landing-page doc (BOUNDARY-DEFINITION.md C1)",
    "QUICKSTART.md": "Pack-root installer doc (BOUNDARY-DEFINITION.md C1 + Override 7)",
    "LICENSE.md": "Pack-root deliverable; standard repo convention",
    "LICENSE": "Pack-root deliverable; extension-less licence file",
    # Pack-root trinity — always at pack root by Claude/Codex/Gemini contract
    # (BOUNDARY-DEFINITION.md §2 C3). Bare ref in pack-ops/ disambiguates
    # via the doc's own audience qualifier (pack-internal) per discipline.
    "CLAUDE.md": "Pack-root trinity (C3); see also project-template/CLAUDE.md",
    "AGENTS.md": "Pack-root trinity (C3); see also project-template/AGENTS.md",
    "GEMINI.md": "Pack-root trinity (C3); see also project-template/GEMINI.md",
    # Pack-memory `MEMORY.md` — the Claude-Code memory cache; bare ref
    # legitimate from any pack-side doc (the file lives in `~/.claude/...`,
    # not in the pack repo; bare ref is the actual reference shape).
    "MEMORY.md": "Claude-Code memory cache (external to pack repo)",
    # Concept-noun / generated-file / placeholder additions (Phase 2,
    # OQ-S2 approved 2026-05-20). These are filename-shaped references
    # to (a) files generated at user opt-in (not in pack repo at HEAD),
    # (b) generated reports / metadata produced by pack scripts at
    # runtime, or (c) per-entry filename PATTERN placeholders (templates,
    # not real files). Bare ref in pack-ops/ prose is legitimate by
    # construction — there is no qualified path to point at.
    "tracker.toml": "Generated by `pack tracker init` (not in pack repo; pack ships tracker.toml.pack-example)",
    "id-map.json": "Generated tracker-mode metadata (not in pack repo)",
    "report.md": "Generated by scripts/lib/customization-report.sh (not in pack repo)",
    "manifest.txt": "RC9 manifest at test-fixtures/manifest.txt (per RC9 trigger rule)",
    "BD-NNN.md": "Per-entry backlog filename pattern (template; see /backlog/_format.md)",
    "TD-NNN.md": "Per-entry tech-debt filename pattern (template)",
    "phase-N.md": "Per-entry implementation-plan filename pattern (template)",
    # Claude-Code memory-cache feedback file (Phase 2, OQ-S3 Option A
    # approved 2026-05-20). Same class as MEMORY.md — lives external
    # to pack repo at ~/.claude/projects/.../memory/.
    "feedback_review_fix_one_cycle.md": "Claude-Code memory cache feedback file (external to pack repo)",
    # Byte-identical mirror exception (Phase 2, surfaced during
    # apply 2026-05-20). HELP-FRAGMENT.md is referenced from
    # pack-ops/HELP-FRAGMENT-TRACKER.md, which is byte-identical to
    # project-template/docs/pack/HELP-FRAGMENT-TRACKER.md per Check 24.
    # The bare ref is correct at the client-installed location
    # (same-dir sibling); qualifying it pack-side would break the
    # Check 24 byte-identity contract.
    "HELP-FRAGMENT.md": "Byte-identical mirror exception (Check 24); bare ref correct at client-installed location",
}
```

Each entry MUST carry a one-line rationale comment. The entry without rationale is a regression signal — Check 40's loader (see §6.3) enforces non-empty rationale strings.

### §6.3 Allowlist enforcement contract

The `_CHECK_40_ALLOWLIST` dict is parsed at module load time. Check 40's per-hit logic is:

```python
for hit in bare_ref_hits:
    if hit.basename in _CHECK_40_ALLOWLIST:
        ok(f"{hit.path}:{hit.lineno} — bare ref `{hit.basename}` "
           f"exempt: {_CHECK_40_ALLOWLIST[hit.basename]}")
        continue
    if _context_has_anchor(hit.lines, hit.lineno):
        ok(f"{hit.path}:{hit.lineno} — bare ref `{hit.basename}` "
           f"anchor-phrase-exempt")
        continue
    # ... emit FAIL with candidate paths per §5.1
```

PASS notices for allowlist-exempt and anchor-phrase-exempt hits are surfaced in the validate-pack.py log so reviewers can see what was admitted. This matches Check 37's `hits_clean` counter convention.

### §6.4 Anchor-phrase exemption (chosen phrases)

**Decision:** Check 40's anchor-phrase set is a SUBSET of Check 37's `_DENY_LIST_ANCHOR_PHRASES`, plus one new phrase:

```python
_CHECK_40_ANCHOR_PHRASES = (
    # Inherit pack-vs-project disambiguation context from Check 37
    # (BOUNDARY-DEFINITION.md §6 cross-reference network).
    "in the pack repo",
    "at the pack repo",
    "pack-repo",
    "in the project",
    "at the client",
    "post-install",       # OQ-3 confirmed — covers the L472 audience-bridge
                          # pattern discussed in §7 D6 (M2 disposition).
                          # Phase 1 survey §6 confirmed already load-bearing
                          # at HEAD (4 hits in BOUNDARY-DEFINITION.md).
    "does not exist",     # OQ-S4 — covers self-flagging non-existence prose
                          # (e.g., CONCEPTUAL-REVIEW-METHODOLOGY.md:L247
                          # "...cited `IMPLEMENTATION-PLAN-V11.0.md` (does
                          # not exist); canonical filename..."). The phrase
                          # IS the disambiguation; the bare ref is part of
                          # a prose flag that the name was wrong.
    "archived",           # OQ-S4 forward-compat — covers prose that
                          # explicitly qualifies bare-ref historical docs
                          # as archived (e.g., "from the now-archived
                          # `ARCHITECTURE-V1.md`..."). Forward-compat per
                          # user direction 2026-05-20: future ship-time
                          # archive shuffles will produce similar prose.
)
_CHECK_40_ANCHOR_WINDOW = 2  # lines before/after; matches Check 37 default
```

**Rationale:**

- **Inherit Check 37 phrases for pack-vs-project disambiguation.** A pack-ops/ doc that calls out the project-side counterpart of a file (e.g., "the client's `OPTIONAL-FEATURES.md`, at `docs/pack/OPTIONAL-FEATURES.md`") often uses these anchors; Check 40 reuses them for consistency.

- **NEW phrase: `post-install`.** The L472 audience-bridge pattern (§7 D6 M2 disposition below) needs a way to flag intentional client-path references in pack-internal docs. `post-install` is the canonical signal that the prose discusses what happens AFTER `init-project.sh` runs — the moment when client-side paths become resolvable. This anchor admits L472's `docs/pack/OPTIONAL-FEATURES.md` reference IF the surrounding ±2 lines mention "post-install" or related context. (See §7.3 for the L472 disposition that closes the loop.) Phase 1 survey §6 confirmed the anchor was load-bearing at HEAD (4 hits in BOUNDARY-DEFINITION.md), supporting the original §6.4 forward-compat hypothesis.

- **NEW phrase (OQ-S4): `does not exist`.** Covers prose patterns where the surrounding sentence explicitly self-flags a bare ref as non-existent — typically a historical-error citation. Phase 1 survey §4 surfaced CONCEPTUAL-REVIEW-METHODOLOGY.md:L247 ("...cited `IMPLEMENTATION-PLAN-V11.0.md` (does not exist); canonical filename...") as the load-bearing case. The phrase IS the disambiguation; the reader is informed inline that the bare ref is intentional historical citation, not a current pointer. Rewriting these prose patterns (e.g., escaping the backticks) loses the historical-citation signal.

- **NEW phrase (OQ-S4 forward-compat): `archived`.** Covers prose patterns where bare-ref historical docs are explicitly qualified as archived (e.g., "from the now-archived `ARCHITECTURE-V1.md` and `V3.3-DELTA.md`"). Phase 1 survey §4 identified CONCEPTUAL-REVIEW-METHODOLOGY.md:L195 as the immediate use case (Phase 2 prose rewrite at L195 introduces the `archived` qualifier — see Edit 4). User direction 2026-05-20: add this anchor for forward-compatibility against future ship-time archive shuffles that produce similar prose patterns. Anchor-window=2 keeps the prose-anchor coupling tight.

- **Drop Check 37's `feedback` / `report back` / `escalation` / `stop and surface` phrases.** Those phrases are scoped to project→pack feedback flow disambiguation (discussed in audit §D-4 LEGITIMATE designation), not to file-pointer-ref ambiguity. They're orthogonal to Check 40's defect class.

### §6.5 Allowlist evolution discipline

Adding an entry to `_CHECK_40_ALLOWLIST` is a single-line dict edit + rationale comment. The discipline: every addition lands in a BD's IMPL-REPORT with a one-line justification for why the bare ref is legitimately resolvable without qualifier. Pack Chat reviewer of any future BD that adds an entry checks the rationale before approving the commit.

Anchor-phrase additions are higher-stakes (each new phrase widens Check 40's exemption surface). Anchor-phrase changes require user-discussion-and-approval per the OQ-1 EXECUTION-PLAN §B step 5 rule (= adding a phrase is "new BD" surface).

### §6.6 Self-documenting allowlist comment (added per user-approved Q-B 2026-05-20)

The `_CHECK_40_ALLOWLIST` dict in `scripts/validate-pack.py` must include a comment block above the dict definition that documents the extension contract. Coder applies the following (or equivalent that matches the surrounding Check 36/37/38/39 code style):

```python
# Check 40 — pack-ops/ bare-cross-reference scanner — hardcoded allowlist.
# Extend this list when new bare references in pack-ops/ markdown are
# explicitly authorized (e.g., new pack-root files, new trinity members,
# new tool-specific exempt patterns). Adding an entry here is the
# intentional escape hatch for legitimate bareness; prefer qualifying
# the ref over allowlisting it unless the ref's bareness is load-bearing.
# Each addition lands in a BD's IMPL-REPORT with rationale per §6.5.
_CHECK_40_ALLOWLIST = {
    # ... entries per §6.2 initial set ...
}
```

Rationale: the allowlist IS hardcoded (per §6.1 design — global per-pattern dict), and the hardcoded shape is hard to avoid without complicating the check's read-cost. But the comment block makes the extension contract self-documenting for future readers/maintainers — answers "can I add an entry?" and "what's the bar?" inline, rather than requiring readers to navigate to §6.5 of this architect doc.

---

## §7 D6 — L472 audience-mismatch disposition

### §7.1 The three options recap

The L472 line at HEAD reads:

```markdown
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
```

This is part of MERGE-STRATEGY.md's cross-references list (L466–474). It points at the POST-install client-side path (`docs/pack/OPTIONAL-FEATURES.md`, the file that `scripts/init-project.sh` installs to client repos at v11). MERGE-STRATEGY.md self-identifies "Audience: pack-internal" at L3.

The three options framed in the BD-179 prompt:
- **M1.** Qualify to pack-repo path (`pack-ops/OPTIONAL-FEATURES.md`) — consistency wins; overrides Override 8.
- **M2.** Keep client-side path — Override 8 stays; Check 40 has anchor-phrase exemption that recognizes the audience-bridge.
- **M3.** Add explicit documentation in the line near L472 that explains the audience-bridge; Check 40 detects the explicit-rationale marker.

### §7.2 Chosen: M2 with §6.4 anchor-phrase exemption

**Decision:** Keep the client-side path (Override 8 stays). Check 40 admits the L472 ref via the `post-install` anchor-phrase in `_CHECK_40_ANCHOR_PHRASES`. The surrounding content at L466–482 is edited minimally to include the anchor phrase in the ±2-line window of L472.

**Rationale:**

- **Override 8 is the authoritative disposition.** Per `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Override 8 ("OQ-3 OPTIONAL-FEATURES.md SPLIT is CONFIRMED"): the pack-side file moves to `pack-ops/OPTIONAL-FEATURES.md` (pack-internal) AND a NEW project-side file is created at `project-template/docs/pack/OPTIONAL-FEATURES.md` (project-side, post-install path `docs/pack/OPTIONAL-FEATURES.md` at the client repo). The two files are independently curated. The content at MERGE-STRATEGY.md L472 explicitly discusses install-time migration scenarios that resolve at client repos post-install (per the surrounding cross-references list's framing). The CLIENT-SIDE path is the architecturally-correct target here. M1 would override an authoritative user-curation decision; architects do not override user-curation by default.

- **M3 is heavier than M2 for the same outcome.** M3 (add explicit documentation) requires per-occurrence prose edits + a marker convention for Check 40 to detect. M2 leverages the already-designed anchor-phrase mechanism (§6.4) and requires only ONE editorial touch: ensure the `post-install` anchor lives in the ±2-line window of L472. Worked example below shows the touch is minor.

- **M2 generalizes cleanly to future audience-bridge cases.** Any pack-internal doc that legitimately points at a client-side path can adopt the same anchor-phrase pattern. M1 (qualify to pack-repo path) treats each case as a one-off override.

### §7.3 The minimal MERGE-STRATEGY.md edit at L466–474

**Current (post-F1) text** (per §1 survey, L466–482 area):

```markdown
## Cross-references

- `scripts/lib/customization-preserve.sh` — the BD-088 implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `supporting-docs/MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
- `QUICKSTART.md` — where to start
- `scripts/validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

**Proposed edit (one-line addendum + anchor-phrase placement):**

```markdown
## Cross-references

These are the pack-internal touch points for the customization-preservation contract; the `docs/pack/OPTIONAL-FEATURES.md` entry below intentionally points at the post-install project-side path because the surrounding install-time migration content resolves at client repos post-install.

- `scripts/lib/customization-preserve.sh` — the BD-088 implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `supporting-docs/MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough (post-install client path; see preamble above)
- `QUICKSTART.md` — where to start
- `scripts/validate-pack.py` Check 25 — CI regression guard for the truthful-report contract
```

This (a) inserts a 1-sentence preamble that includes the `post-install` anchor inside the ±2-line window of L472, (b) appends an inline parenthetical to the L472 bullet that reinforces the audience-bridge to a reader and ALSO contains the `post-install` anchor.

### §7.4 Compatibility with the M2 anchor-phrase design

After the edit, Check 40 walks L472, finds the bare-ref hit `docs/pack/OPTIONAL-FEATURES.md` (BUT — wait — that ref is NOT bare; it carries the `docs/pack/` qualifier and the regex (§3.3) does NOT match it because `/` is not in the character class). The L472 line is ALREADY non-matching by the regex contract.

Re-evaluating §7.2/§7.3: **L472 is not a Check 40 hit per the §3.3 regex.** It's qualified (`docs/pack/...`); the issue is audience-mismatch (pack-internal doc points at post-install client-side path), not bareness.

**Revised D6 disposition:** L472 is OUT OF SCOPE for Check 40 because Check 40 only detects bare refs. The audience-mismatch concern is a separate defect class — call it the "audience-bridge" defect — that bare-ref-scanning does not address. Two paths:

- **Option D6.1 (chosen):** Document the L472 audience-bridge in the prose itself (the §7.3 edit), making the intent self-documenting to future readers. Check 40 stays out of audience-bridge detection scope; that's a separate problem class better addressed by a hypothetical future "Check N: pack-internal doc references client-side path" scanner that walks qualified-but-cross-audience refs. Not in BD-179 scope; could be a future BD if the defect class re-surfaces.

- **Option D6.2 (declined):** Try to detect audience-mismatch in Check 40 by walking qualified refs in addition to bare refs and cross-checking against the audience-axis classification (pack-ops/ = pack-internal; refs into `docs/pack/`, `.claude/`, `.codex/`, `.gemini/`, `tracker.toml.example`-style client-side paths = client-side audience). Rejected: scope-creeps Check 40 from "bareness scanner" to "audience-classification scanner" and re-introduces the BOUNDARY-DEFINITION.md complexity that Architect C already addressed in Checks 36–38. The compose-cleanly principle (§9) says don't duplicate.

### §7.5 Final D6 disposition

**Decision:**

1. Check 40's scope is bareness-only. L472 (and any other audience-bridge but qualified ref) is OUT OF SCOPE for Check 40 by construction.

2. The L472 line gets the §7.3 prose edit (1-sentence preamble + inline parenthetical) regardless of Check 40 detection. This is editorial best-practice per `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` § "Design best practices" principle #1 ("single source of truth for content / rules / config"): the audience-bridge is documented in the cross-references list itself, eliminating the disambiguation burden on the reader.

3. The `post-install` anchor-phrase in `_CHECK_40_ANCHOR_PHRASES` is retained per §6.4 for FUTURE bare-ref hits that legitimately reference client-side paths in post-install context. The anchor mechanism is forward-compatible; the L472 prose edit is corrective.

### §7.6 Override 8 + audit reference for the reviewer

The L472 edit does NOT change the architectural disposition; it ONLY adds reader-facing prose that documents the existing disposition. Per `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` Override 8, the SPLIT is confirmed; the client-side path on L472 is correct. The §7.3 edit is editorial-quality work that surfaces the audience-bridge to readers.

---

## §8 D7 — Bootstrap order

### §8.1 The bootstrap problem

A T1-uniform-FAIL Check 40 (§4.1) will FAIL at HEAD on all unfixed bare-ref hits in pack-ops/*.md. The BD-179 commit must either (a) qualify every flagged ref in the same commit Check 40 lands, OR (b) add explicit allowlist entries that admit them. Anything else means CI fails on the BD-179 commit.

### §8.2 Pre-commit bare-ref survey (in-scope files)

Per §2.1 + §3.5, the 9 in-scope files carry the following anticipated bare-ref hits (manual survey; coder runs Check 40 with `--dry-run`-equivalent print-only mode during implementation to ground the count):

| File | Estimated bare-ref hits | Notes |
|---|---|---|
| pack-ops/MERGE-STRATEGY.md | 12–14 | 5 inline `MIGRATION-v10-to-v11.md` + 3 inline `validate-pack.py` + 3 inline `merge-json.py` + 1 inline `HELP-FRAGMENT-PACK.md` + 1 cross-ref-list `QUICKSTART.md` (latter allowlist-exempt per §6.2) |
| pack-ops/DRY-RUN-MIGRATION.md | 5–7 | 5 inline `MIGRATION-v10-to-v11.md` + 1 cross-ref-list `MIGRATION-v10-to-v11.md` + 1 cross-ref-list `MERGE-STRATEGY.md`; `BACKLOG.md` cross-ref-list entry is allowlist-non-eligible (it lives at `pack-ops/`, not pack root) |
| pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md | 2–4 | Bullet refs to `CLAUDE.md`, `PACK-CHAT.md`, `MEMORY.md`, `ARCHITECTURE-V*.md` family (latter not matched per §3.4 wildcard) |
| pack-ops/PACK-CHAT.md | 0–2 | Mostly already-qualified or anchor-phrase-friendly; survey expected to be near-zero |
| pack-ops/PACK-AGENTS.md | 0–3 | Bullet refs to PM-only files list; most are anchor-phrase-friendly via §6.4 patterns |
| pack-ops/BOUNDARY-DEFINITION.md | 0 | The doc carries qualified refs by discipline (every example names full path); pre-survey indicates zero hits |
| pack-ops/OPTIONAL-FEATURES.md | 1 | L184 `MERGE-STRATEGY.md` bare ref (same-pack-ops/ dir; needs qualification to `pack-ops/MERGE-STRATEGY.md` for unambiguous resolution from pack root) |
| pack-ops/HELP-FRAGMENT-PACK.md | 0–1 | L4 `QUICKSTART.md` / `README.md` allowlist-exempt per §6.2 |
| pack-ops/HELP-FRAGMENT-TRACKER.md | 0–1 | L49 `OPTIONAL-FEATURES.md` bare ref (needs qualification or anchor-phrase) |

**Total anticipated hits to address in the BD-179 commit:** approximately 20–32 bare-ref qualifications, mostly in MERGE-STRATEGY.md and DRY-RUN-MIGRATION.md.

### §8.3 The BD-179 commit shape (single commit)

The BD-179 commit MUST contain, atomically:

1. **NEW `scripts/validate-pack.py` Check 40 implementation** — `check_bare_pack_ops_refs()` + helpers (`_CHECK_40_ALLOWLIST`, `_CHECK_40_BARE_REF_PATTERN`, `_CHECK_40_HYPERLINK_PATTERN`, `_CHECK_40_ANCHOR_PHRASES`, `_CHECK_40_ANCHOR_WINDOW`, code-block stripper, candidate-path index builder). Add `check_bare_pack_ops_refs()` call to `main()` after the Check 39 call (per `scripts/validate-pack.py:4371` insertion point convention).

2. **NEW test fixture for Check 40** — `scripts/tests/test-validate-pack-check-40.sh` + `scripts/tests/fixtures/bare-cross-reference/` directory. Test groups follow the Check 39 test pattern (Group 0 module import + symbol registration; Group 1 _CHECK_40_BARE_REF_PATTERN unit tests; Group 2 code-block-stripper unit tests; Group 3 candidate-path-index unit tests; Group 4 allowlist + anchor-phrase exemption tests; Group 5 end-to-end check_bare_pack_ops_refs() per-fixture tests).

3. **Qualify all bare refs in the 9 in-scope `pack-ops/*.md` files** per the §8.2 survey. Most are mechanical (replace `` `FILENAME.md` `` with `` `<dir>/FILENAME.md` `` per the §5.1 D4 candidate-path lookup).

4. **L472 prose edit per §7.3** — preamble + parenthetical addendum (not a bareness fix; editorial-quality work that closes the D6 audience-bridge concern in the same commit).

5. **Regenerate `test-fixtures/manifest.txt`** per RC9 (BD-176-extended trigger: pack-ops/ + scripts/ are both v11-surface). Run `bash test-fixtures/build.sh --all --clean`, then `git add test-fixtures/manifest.txt` if non-empty diff.

6. **`.github/workflows/validate-pack.yml`** add a new step that invokes `bash scripts/tests/test-validate-pack-check-40.sh` (the new test fixture file), per the Check 39 CI-wiring pattern at `.github/workflows/validate-pack.yml` (coder verifies the exact step shape against the existing Check 39 step).

### §8.4 Land Check 40's call site in main() at the right point

Per the existing main() comment block at `scripts/validate-pack.py:4359–4364`:

```python
# ── BD-175 Commit 12 (Architect C M5a/b/c): pack/project boundary
# prevention. Order: 36 (commit-scope honesty) → 37 (project-side
# deny-list) → 38 (pack-only-file siting). Check 37 lands LAST in
# the boundary trio per C §13 bootstrap-incompatibility note ...
```

BD-179 inserts Check 40 AFTER Check 39 with a parallel comment block:

```python
# ── BD-179: pack-ops/ bare cross-reference scanner. Lands AFTER
# the M5a/b/c boundary trio + Check 39 cmd_update symmetry so the
# directory-boundary + install-coverage gates run before Check 40's
# prose-cross-reference gate. Per ARCHITECTURE-BD-179.md §8.3, the
# BD-179 commit qualifies all current bare-ref hits in pack-ops/*.md
# so Check 40 PASSes at HEAD.
check_bare_pack_ops_refs()
```

### §8.5 Verification recipe (coder runs before PREFLIGHT)

```sh
# 1. Run Check 40 directly:
python3 scripts/validate-pack.py 2>&1 | grep -A 5 "Check 40"
# Expect: "Check 40 — N pack-ops/*.md file(s) walked; zero bare ..."

# 2. Run the full validator:
python3 scripts/validate-pack.py
# Expect: "PASSED — all checks clean"

# 3. Run the new Check 40 test fixture:
bash scripts/tests/test-validate-pack-check-40.sh
# Expect: all PASS lines, no FAIL

# 4. Confirm manifest fresh:
bash test-fixtures/build.sh --all --clean
git diff test-fixtures/manifest.txt  # MUST be empty after rebuild + stage
```

All four must pass before the coder emits the PREFLIGHT line.

### §8.6 OQ-S4 final resolution — historical/archived-doc refs (added Phase 2 2026-05-20)

Phase 1 survey §4 surfaced 3 historical-doc bare refs in CONCEPTUAL-REVIEW-METHODOLOGY.md (L195 `ARCHITECTURE-V1.md` + `V3.3-DELTA.md`; L247 `IMPLEMENTATION-PLAN-V11.0.md`). Survey §8.4 proposed Option A (rewrite L195) + Option D (anchor phrase for L247). User-approved 2026-05-20: **Option A+D combination**, with the additional decision to add the `archived` anchor phrase forward-compat per `feedback-no-deferral-without-user-direction` discipline (catch future archive-shuffle patterns without re-litigating BD-179).

**Applied resolution (executed in Phase 2 Edit 4):**

- **L195 (Option A — prose rewrite):** REWRITE prose to add `archived` qualifier. Example proposed form: "from the now-archived `ARCHITECTURE-V1.md` and `V3.3-DELTA.md`". The new `archived` anchor phrase (§6.4) exempts the bare refs at L195 once the rewrite places `archived` in the ±2-line window.
- **L247 (Option D — anchor-phrase exemption):** KEEP AS-IS. The prose already says "(does not exist); canonical filename..." which the new `does not exist` anchor (§6.4) admits.
- **Both anchor phrases added (forward-compat):** `does not exist` + `archived` land in `_CHECK_40_ANCHOR_PHRASES` per §6.4. Future bare-ref-in-historical-context patterns are admitted by the anchor mechanism without further BD work.

**Why not Option B (allowlist) or Option C (restructure):** Option B (add historical refs to allowlist) loses the architectural distinction — these are NOT generally-resolvable refs (like README.md); they're contextual historical citations. Option C (restructure to remove bare refs) destroys the historical-citation surface (the reader can no longer see what was originally cited). Option A+D preserves the prose intent AND surfaces the historical context to readers.

### §8.7 OQ-S resolution summary (Phase 2 2026-05-20)

Eight OQ-S items raised by Phase 1 survey. User-approved dispositions applied in Phase 2:

| OQ-S | Subject | Resolution | Architect-doc landing point |
|---|---|---|---|
| OQ-S1 | EXCLUDE expansion (`scripts/tests/fixtures/`) | Ratified — added to §5.1 EXCLUDE list | §5.1 addendum |
| OQ-S2 | Concept-noun allowlist additions | 7 entries added to `_CHECK_40_ALLOWLIST` | §6.2 |
| OQ-S3 | Feedback memory cache | Option A — single entry (`feedback_review_fix_one_cycle.md`) | §6.2 |
| OQ-S4 | Historical/archived doc refs | Option A (L195 rewrite) + Option D (L247 anchor) + forward-compat `archived` anchor | §6.4 + §8.6 (this section) + Edit 4 |
| OQ-S5 | Agent-file sibling-list refs (L179 / L196) | Option B — compositional prose rewrite | §10.2 mapping + Edit 4 |
| OQ-S6 | Anchor window=2 false positives (L5) | Option (b) — manual re-qualify outside anchor mechanism | §10.2 mapping + Edit 4 |
| OQ-S7 | settings.json 4-candidate (L101) | Compositional rewrite ("any CLI's `settings.json` ...") | §10.2 mapping + Edit 4 |
| OQ-S8 | BOUNDARY-DEFINITION.md 24-hit hot-spot | Option (a) — mechanical qualification per §10.2 mapping | §10.2 mapping |

Q-A (L472 audience-bridge preamble) + Q-B (self-documenting allowlist comment) — both applied verbatim per architect §7.3 (Q-A) + §6.6 (Q-B).

**Apply-time discovery (Phase 2 2026-05-20):** one additional allowlist entry surfaced during apply that wasn't anticipated in Phase 1 survey §8 — `HELP-FRAGMENT.md` at pack-ops/HELP-FRAGMENT-TRACKER.md:L21. The byte-identity mirror contract (Check 24) requires pack-ops and project-template copies to be byte-identical; qualifying the bare ref pack-side would diverge from the client-side surface where the bare ref is correctly same-dir-resolvable. Added to allowlist as the byte-identical mirror exception. This is the architecturally-justified pattern for ALL future byte-identical mirror pairs (none currently exist for pack-ops/*.md beyond HELP-FRAGMENT-TRACKER.md; precedent recorded here for future BDs).

---

## §9 D8 — Trinity / rule-interactions

Check 40 must compose cleanly with five other surfaces; this section catalogs the interactions.

### §9.1 Trinity rule (CLAUDE/AGENTS/GEMINI parity) — NO INTERACTION

Check 40 is a CI gate, not a trinity rule. It adds a function to `scripts/validate-pack.py` (pack-only, non-trinity surface) and an allowlist dict at module level. No edit lands in pack-root trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) or project-template trinity files. No trinity-parity edit needed.

**Exception:** if a future architect-doc-vs-reality reconciliation surfaces a need to document the bare-cross-reference discipline in pack-memory (as a rule, not just a CI gate), that addition WOULD require trinity-parity edits. BD-179 does not require this; the CI gate IS the enforcement. If post-BD-179 the discipline needs human-readable documentation in pack-memory, that is a separate BD that handles trinity per the BD-179 IMPL-REPORT carry-forward signal — not a same-commit obligation.

### §9.2 Check 18 H2 (trinity H2 parity) — NO INTERACTION

Check 18 validates that pack-root and project-template trinity files share the same H2 section structure. Check 40 walks pack-ops/*.md (none of which is a trinity file). No overlap.

### §9.3 BD-176 RC9 expansion — DIRECT INTERACTION (handled by §8.3 step 5)

BD-176 expanded the RC9 manifest-regen trigger to include `pack-ops/` as v11-surface. The BD-179 commit edits multiple pack-ops/*.md files (per §8.3 step 3) AND adds `scripts/validate-pack.py` + `scripts/tests/test-validate-pack-check-40.sh` edits (per §8.3 steps 1–2). Both `pack-ops/` and `scripts/` are v11-surface; the commit triggers the manifest-regen rule per RC9. Step 5 of §8.3 handles the regen explicitly.

**Composition check:** No conflict. RC9 is an obligation on the commit author; Check 40 is a separate CI gate. Both fire on the BD-179 commit; both must pass independently.

### §9.4 BD-178 trinity-alignment work — NO INTERACTION

BD-178 closed pre-existing trinity asymmetries in `project-template/{CLAUDE,AGENTS,GEMINI}.md`. Check 40 walks pack-ops/*.md (not project-template/). No overlap.

### §9.5 Override 8 (OPTIONAL-FEATURES.md SPLIT) — DIRECT INTERACTION (handled by §7 D6 disposition)

Override 8 chose SPLIT for OPTIONAL-FEATURES.md. The L472 ref in MERGE-STRATEGY.md points at the post-install client-side path per Override 8's authorized disposition. §7 D6 chose M2 (keep client-side path; anchor-phrase exemption for future bare-ref hits) + §7.3 prose edit (document the audience-bridge in the cross-references list itself). Override 8 is preserved.

**Composition check:** No conflict. The §7 D6 disposition respects Override 8's user-curation decision and adds editorial documentation, not architectural override.

### §9.6 Check 37 anchor-phrase mechanism — REUSED (not duplicated)

Check 40's `_CHECK_40_ANCHOR_PHRASES` and `_context_has_anchor()` follow the exact pattern Check 37 introduced. The implementation should reuse the existing `_context_has_anchor` helper if its signature accepts a configurable anchor-phrase set, or factor out a shared `_context_has_anchor_against(lines, lineno, anchor_phrases, window)` helper that both Check 37 and Check 40 call. The latter is cleaner; coder's discretion to pick the refactor shape based on the existing `_context_has_anchor` implementation.

**Acknowledged:** the refactor (if chosen) lands in the BD-179 commit. Adding a `_context_has_anchor_against` helper + adapting `_context_has_anchor` to call it (passing Check 37's anchor set) is a non-breaking refactor. If the coder finds the refactor introduces non-trivial code-churn, they may instead leave Check 37's `_context_has_anchor` untouched and define a parallel `_check_40_context_has_anchor` for Check 40 specifically (small duplication; no behavior change). The coder picks per simplest-correct-design at implementation time.

### §9.7 BD-180 Check 39 extension — COMPOSITION NEUTRAL (no overlap)

BD-180 will extend Check 39's `cmd_update` mapping symmetry coverage to additional surfaces (.gemini/commands/, .claude/skills/, per-entry templates, etc.). Check 40's scope is bare cross-references in `pack-ops/*.md` markdown — disjoint from Check 39's `cmd_update` mapping symmetry concern.

**Composition check:** No overlap. BD-179 lands first per the batch chain; BD-180 builds on Check 39 (not Check 40). Sequential, non-interacting.

### §9.8 BD-181 + BD-182 — COMPOSITION NEUTRAL (no overlap)

Per the batch chain (`pack-ops/BACKLOG.md` BD-181 + BD-182 entries), neither touches pack-ops/*.md content nor adds validate-pack.py checks that overlap with Check 40's scope. BD-179 closes its own surface; subsequent BDs extend other surfaces.

### §9.9 Pack memory rule: "no green-the-test band-aids" — DIRECT INTERACTION

Per `pack-ops/PACK-CHAT.md` "Real fixes only — no green-the-test band-aids" rule. Check 40's T1-uniform-FAIL design (§4.1) is the strict-gate option. The allowlist (§6) is NOT a band-aid mechanism — every allowlist entry MUST carry a one-line rationale comment per §6.2, and the entries admitted in §6.2's initial set are architecturally-justified (pack-root files always resolve at pack root by repo convention).

**Composition check:** No conflict. The allowlist documents intentional exemptions with rationale; it does not suppress legitimate Check 40 failures.

### §9.10 Pack memory rule: "Architect-doc-vs-reality reconciliation" — POTENTIAL FUTURE INTERACTION

Per pack-memory: when a BD realizes a design anticipated in an architect doc, ship the reconciliation chain (in-code docstring + architect-doc addendum + IMPL-REPORT cross-reference).

**This BD's status:** BD-179 IS itself an architect doc; it does not realize a design pre-existing in another architect doc. No reconciliation chain owed at landing.

**Future consideration:** if a later BD adds a new pack-ops/*.md file that would have benefited from Check 40 being designed differently, that BD's IMPL-REPORT should cross-reference back to this strategy doc. This is a forward-pointing concern, not a same-commit obligation for BD-179.

---

## §10 Implementation handoff

### §10.1 File list for the coder (concrete surface to edit)

The BD-179 commit edits or creates the following files:

| File | Action | Reason |
|---|---|---|
| `scripts/validate-pack.py` | EDIT | Add Check 40 function + helpers per §3, §5, §6, §8; add call-site in `main()` per §8.4 |
| `scripts/tests/test-validate-pack-check-40.sh` | NEW | Test fixture for Check 40 per §8.3 step 2; pattern matches test-validate-pack-check-39.sh |
| `scripts/tests/fixtures/bare-cross-reference/` | NEW (directory) | Synthetic fixture inputs for Check 40 unit tests; pattern matches `scripts/tests/fixtures/cmd-update-symmetry/` |
| `.github/workflows/validate-pack.yml` | EDIT | Add step invoking `bash scripts/tests/test-validate-pack-check-40.sh` per §8.3 step 6; pattern matches Check 39's CI step |
| `pack-ops/MERGE-STRATEGY.md` | EDIT | Qualify ~12–14 bare refs per §8.2; apply §7.3 prose edit at L466–474 (preamble + L472 parenthetical) |
| `pack-ops/DRY-RUN-MIGRATION.md` | EDIT | Qualify ~5–7 bare refs per §8.2 |
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | EDIT | Qualify ~2–4 bare refs per §8.2 |
| `pack-ops/PACK-CHAT.md` | EDIT (if any hits) | Qualify ~0–2 bare refs per §8.2 |
| `pack-ops/PACK-AGENTS.md` | EDIT (if any hits) | Qualify ~0–3 bare refs per §8.2 |
| `pack-ops/OPTIONAL-FEATURES.md` | EDIT | Qualify ~1 bare ref per §8.2 (L184 `MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md`) |
| `pack-ops/HELP-FRAGMENT-PACK.md` | EDIT (if any hits beyond allowlist) | Qualify ~0–1 bare refs per §8.2 |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | EDIT | Qualify ~0–1 bare refs per §8.2 (L49 `OPTIONAL-FEATURES.md`) |
| `pack-ops/BOUNDARY-DEFINITION.md` | NO EDIT (per §8.2 zero-hits survey) | Doc already follows qualified-ref discipline |
| `test-fixtures/manifest.txt` | EDIT (regen) | Per RC9 expanded trigger for pack-ops/ + scripts/ v11-surface |

**Files explicitly OUT of scope:**
- `pack-ops/BACKLOG.md` — regenerated mirror; per §2.1 D1a exclusion
- `pack-ops/CHANGELOG.md` — regenerated mirror; per §2.1 D1a exclusion
- All trinity files (pack-root + project-template) — per §9.1
- All `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` files — Check 40 scope is pack-ops/*.md only
- All `supporting-docs/` files — Check 40 scope is pack-ops/*.md only

### §10.2 Per-file qualification mapping (coder reference)

For each bare ref the coder finds during implementation, apply the following qualification rules (derived from the §5.1 D4 candidate-path lookup):

| Bare ref basename | Qualified replacement | Notes |
|---|---|---|
| `MIGRATION-v10-to-v11.md` | `supporting-docs/MIGRATION-v10-to-v11.md` | Single candidate per pack repo |
| `MIGRATION-v9-to-v10.md` | `supporting-docs/MIGRATION-v9-to-v10.md` | Frozen historical doc, same dir |
| `MERGE-STRATEGY.md` | `pack-ops/MERGE-STRATEGY.md` | Single candidate post-BD-175 reorg |
| `OPTIONAL-FEATURES.md` (in pack-ops/ context) | `pack-ops/OPTIONAL-FEATURES.md` | When referring to pack-internal file. Use `docs/pack/OPTIONAL-FEATURES.md` ONLY when content discusses post-install client-side (anchor-phrase contextualized per §6.4) |
| `HELP-FRAGMENT-PACK.md` | `pack-ops/HELP-FRAGMENT-PACK.md` | Post-BD-175 location |
| `HELP-FRAGMENT-TRACKER.md` (in pack-ops/) | `pack-ops/HELP-FRAGMENT-TRACKER.md` | Pack-internal canonical source |
| `HELP-FRAGMENT.md` | `project-template/docs/pack/HELP-FRAGMENT.md` | Project-side companion (no pack-ops/ version exists) |
| `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` | Post-BD-175 location |
| `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` | Post-BD-175 location |
| `BOUNDARY-DEFINITION.md` | `pack-ops/BOUNDARY-DEFINITION.md` | Post-BD-175 location |
| `CONCEPTUAL-REVIEW-METHODOLOGY.md` | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | Post-BD-175 location |
| `DRY-RUN-MIGRATION.md` | `pack-ops/DRY-RUN-MIGRATION.md` | Post-BD-175 location |
| `validate-pack.py` | `scripts/validate-pack.py` | Single candidate |
| `init-project.sh` | `scripts/init-project.sh` | Single candidate |
| `migrate-v10-to-v11.sh` | `scripts/migrate-v10-to-v11.sh` | Single candidate |
| `merge-json.py` | `scripts/merge-json.py` | Single candidate |
| `merge-toml.py` | `scripts/merge-toml.py` | Single candidate |
| `customization-preserve.sh` | `scripts/lib/customization-preserve.sh` | Single candidate |
| `pack-help.sh` | `scripts/pack-help.sh` | Single candidate |
| `pack-tracker.sh` | `scripts/pack-tracker.sh` | Single candidate |
| `dry-run-migration.sh` | `scripts/dry-run-migration.sh` | Single candidate |
| `tracker-migrate.sh` | `scripts/tracker-migrate.sh` | Single candidate |
| `BACKLOG.md` (in pack-ops/ context) | `pack-ops/BACKLOG.md` | Post-BD-175 location; pack-internal ref |
| `CHANGELOG.md` (in pack-ops/ context) | `pack-ops/CHANGELOG.md` | Post-BD-175 location; pack-internal ref |
| `README.md` | allowlist (no qualification) | Pack-root landing-page per §6.2 |
| `QUICKSTART.md` | allowlist (no qualification) | Pack-root installer per §6.2 |
| `LICENSE`, `LICENSE.md` | allowlist (no qualification) | Pack-root deliverable per §6.2 |
| `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (bare) | allowlist (no qualification) | Pack-root trinity per §6.2; project-template parallels disambiguated by full path when referenced |
| `MEMORY.md` | allowlist (no qualification) | Claude-Code memory cache per §6.2 |
| `AUDIT-USER-CURATION.md` | `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` | Single candidate (per Phase 1 survey §3) |
| `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` | `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` | Single candidate (per Phase 1 survey §3) |
| `AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` | `maintenance-docs/v11-implementation/AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` | Single candidate (per Phase 1 survey §3) |
| `EXECUTION-PLAN-V11.0.md` | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` | Single candidate (per Phase 1 survey §3) |
| `INSTALL-PROCEDURES.md` | `supporting-docs/INSTALL-PROCEDURES.md` | Single candidate (per Phase 1 survey §3) |
| `settings.json` | OQ-S7 compositional rewrite | 4 candidates; rewrite as "any CLI's `settings.json` (e.g., `project-template/.claude/settings.json`)" per §8.7 OQ-S7 |
| `pack-architect.md` / `pack-coder.md` / `pack-planner.md` / `pack-reviewer.md` / `pack-docs-researcher.md` (bare, sibling-list pattern) | OQ-S5 compositional rewrite | 2 candidates each (.claude/.gemini); rewrite to "[the pack-architect / ... / pack-docs-researcher set of agents at `.claude/agents/`]" per §8.7 OQ-S5 |

The coder MUST verify each replacement against the live filesystem (per §5.1 D4 candidate-path discipline) before applying; the table is a starting reference, not a substitute for verification.

**§10.2 BOUNDARY mapping addendum (Phase 2, OQ-S8 + survey §3 ratification 2026-05-20).** Phase 1 survey §3 enumerated 51 qualify-needed bare-ref hits empirically; survey §2 surfaced BOUNDARY-DEFINITION.md as a 24-hit hot-spot (vs §8.2 estimate "0 hits"). Per OQ-S8 Option (a) — mechanical qualification per this §10.2 table mapping. Coder applies all 51 qualifications uniformly using the survey §3 table as the row-by-row authority + this table as the basename→qualified-path lookup. The 24 BOUNDARY-DEFINITION.md hits use the same table rows — no new BOUNDARY-DEFINITION.md-specific exception. OQ-S5 (agent-file sibling-list) + OQ-S6 (L5 manual re-qualify) + OQ-S7 (settings.json) are the three non-mechanical applications; everything else is row-lookup.

### §10.3 Estimated commit shape

Single commit with subject `feat: v11 — BD-179 validate-pack.py Check 40 pack-ops/ bare cross-reference scanner`. Body lines per the pack convention (one-paragraph summary + bullet list of touched files). Per `pack-ops/PACK-CHAT.md` § "Batch close commit shapes" — single-BD batches combine implementation + status flip; BUT BD-179 is mid-batch (multi-BD batch chain BD-175 → BD-182), so it follows the multi-BD-batch convention: implementation commit lands first; status flip lands in the end-of-batch fix/flip commit per the batch lead (not in this BD's commit).

### §10.4 Pre-commit verification (extends §8.5)

The coder runs §8.5's 4-step recipe BEFORE emitting PREFLIGHT. The PREFLIGHT line takes the form:

```
PREFLIGHT: N/N in-scope file edits complete; Check 40 PASS at HEAD; full validate-pack.py PASS; Check 40 test fixture PASS; manifest fresh; HEAD <SHA>; about to Write IMPL-REPORT to <path>
```

The coder may abbreviate to the standard form if all four verification steps passed; the form above is the verbose acknowledgment of the §8.5 recipe completion.

### §10.5 IMPL-REPORT cross-references (coder writes)

The IMPL-REPORT MUST cross-reference:

1. This strategy doc (`maintenance-docs/v11-implementation/ARCHITECTURE-BD-179.md`) by full path with §-anchors for each decision realized.

2. The bare-ref count per in-scope file (final tally from §8.2 survey vs actual implementation).

3. Any divergence from this strategy (none anticipated; if the coder finds an unanticipated decision point, surface to Pack Chat for triage before implementing — the strategy is the authority).

4. The `_CHECK_40_ALLOWLIST` initial state at commit time (i.e., the §6.2 set as-implemented).

5. The L472 prose edit per §7.3 (line-number citation post-edit).

6. The manifest regen confirmation (commit SHA of manifest delta if any; per RC9 expanded trigger).


---

## §11 Open questions / blockers requiring user input

This section flags decisions where the strategy doc made a default call but the user may want to override before pack-coder spawns. Each item names the choice made + what user override looks like.

### §11.1 OQ-1 — Scope of BACKLOG.md / CHANGELOG.md exclusion (§2.1 D1a)

**Strategy decision:** Check 40 EXCLUDES `pack-ops/BACKLOG.md` and `pack-ops/CHANGELOG.md` (the regenerated mirrors).

**Why this is OQ-worthy:** the exclusion is justified by the "per-entry source-of-truth in flat-file mode" rule from pack-memory, but the user may want Check 40 to ALSO scan the per-entry source trees (`/backlog/*.md` + `/changelog/*.md`) to catch bare refs at the source layer. Per pack-memory, the per-entry trees ARE source-of-truth; bare refs there propagate to the mirrors via regeneration.

**If user override = include per-entry trees:** Check 40's scope expands to `pack-ops/*.md` + `/backlog/*.md` + `/changelog/*.md`. The bootstrap-survey count grows substantially (per-entry trees have many more files; the F2-fixture survey would need running before any commit lands). This is potentially a multi-batch scope-expansion, not a same-commit add.

**Strategy default:** stay with pack-ops/*.md only (excluding mirrors). The per-entry tree concern is a separate BD if needed. Coder follows §2.1 unless user redirects before spawn.

### §11.2 OQ-2 — `_CHECK_40_ALLOWLIST` initial set (§6.2)

**Strategy decision:** The initial allowlist contains 8 entries: `README.md`, `QUICKSTART.md`, `LICENSE.md`, `LICENSE`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `MEMORY.md`.

**Why this is OQ-worthy:** the user may want a tighter or looser initial set. Tighter (e.g., drop trinity bare-allowlist entries on grounds that they're ambiguous between pack-root and project-template variants) → coder qualifies bare trinity refs to `pack-root CLAUDE.md` (prose convention) or full path in pack-ops/ docs. Looser (e.g., add `MERGE-STRATEGY.md`, `OPTIONAL-FEATURES.md` etc. that live in pack-ops/) → would defeat Check 40's purpose by exempting the very files that prompted the BD.

**Strategy default:** the §6.2 set is the minimum architecturally-justified allowlist (pack-root files + memory cache). Coder applies §6.2 unless user redirects before spawn.

### §11.3 OQ-3 — Anchor-phrase `post-install` addition (§6.4)

**Strategy decision:** Add the `post-install` anchor phrase to admit future legitimate client-side path refs in pack-internal docs.

**Why this is OQ-worthy:** the §7 D6 disposition concluded L472 is OUT OF SCOPE for Check 40 (qualified ref, not bare) — so the immediate justification for the `post-install` anchor is forward-pointing (future bare-ref hits in audience-bridge context). The user may prefer to drop `post-install` from the initial anchor set and add it later when an actual bare-ref-in-audience-bridge case arises. This would tighten Check 40's exemption surface; cost is some coder-flexibility loss if a legitimate audience-bridge bare ref appears in this commit's qualification work.

**Strategy default:** add `post-install` per §6.4 (forward-compatible; no surface cost). Coder applies §6.4 unless user redirects before spawn.

### §11.4 OQ-4 — Refactor `_context_has_anchor` to support per-check phrase sets (§9.6)

**Strategy decision:** Coder picks per simplest-correct-design — either refactor `_context_has_anchor` to `_context_has_anchor_against(lines, lineno, phrases, window)` (shared by Check 37 and Check 40), OR define a parallel `_check_40_context_has_anchor` (small duplication).

**Why this is OQ-worthy:** the refactor option lands in the BD-179 commit and touches Check 37 code paths. The parallel-helper option keeps Check 37 untouched but introduces ~10 lines of duplication. Both are defensible; the coder's pick affects diff size and review surface.

**Strategy default:** coder's discretion at implementation time. Pack Chat may prefer one over the other for review-surface reasons; user input optional but welcome before spawn.

### §11.5 OQ-5 — L472 prose edit prose-quality review (§7.3)

**Strategy decision:** The §7.3 prose edit adds a 1-sentence preamble + inline parenthetical to MERGE-STRATEGY.md L466–474. The exact wording is the strategy's first draft.

**Why this is OQ-worthy:** the prose edit changes a user-facing pack-ops/ doc; the user may want a different wording or different placement (e.g., a footnote rather than parenthetical; a separate prose paragraph after the list rather than a preamble before).

**Strategy default:** §7.3 wording is the coder's starting point. Coder may apply as-written; user input on wording welcome before spawn or as part of triage at the pack-reviewer pass.

### §11.6 OQ-6 — Bootstrap-survey full count grounding (§8.2)

**Strategy decision:** §8.2 estimates 20–32 bare-ref hits across the 9 in-scope files but acknowledges the count is manual-survey-derived and may differ from Check 40's actual report.

**Why this is OQ-worthy:** if the actual count substantially exceeds 32 (e.g., 60+), the BD-179 commit's footprint grows correspondingly; Pack Chat may want to know the empirical count BEFORE approving the strategy. The coder runs Check 40 in print-only mode against HEAD as the first implementation step — this is "fast investigative work" not the BD-179 commit itself.

**Strategy default:** coder runs Check 40 against HEAD as the first implementation step, reports the actual count to Pack Chat via SendMessage (Claude-Code-only enforcement; on other CLIs the coder reports via natural-language pause), waits for Pack Chat's go-ahead before applying the qualification edits. This is BLOCKED-PROCEED, not a strategy override — the strategy stands; only the empirical-count grounding gates execution.

### §11.7 Items NOT requiring user input

The following decisions stand without user override unless the user volunteers a redirect:

- Regex pattern (§3.3) — well-defined per `[A-Za-z][A-Za-z0-9_.-]*\.(?:md|sh|py|toml|yml|yaml|json|txt)` with code-block stripping
- Exists-check + candidate-path lookup (§5.1) — implementation detail; behavior is deterministic
- Single-FAIL severity (§4.1, §4.2) — uniform with Check 37 pattern; no override expected
- BD-179 commit shape (§8.3) — single commit per pack-memory single-BD batch convention applied mid-batch
- CI workflow step addition (§8.3 step 6) — mechanical per Check 39 template
- Manifest regen (§8.3 step 5) — RC9 trigger; mandatory

---

## §12 Summary table — decisions at-a-glance

| Decision | Chosen | Defaulted from |
|---|---|---|
| D1a file coverage | All `pack-ops/*.md` except BACKLOG.md / CHANGELOG.md (regenerated mirrors) | Per-entry source-of-truth rule + minimal-noise |
| D1b file types | `.md` only | Prose-concern restriction |
| D2 patterns in scope | P1 (bullet) + P2 (prose) + P3 (table) + P5 (hyperlink) | Markdown surface coverage |
| D2 patterns out of scope | P4 (code block) | Code-block content is shell-CWD-resolved, not doc-ref-ambiguous |
| D2 detection mechanism | Regex over code-block-stripped representation | Stdlib-only; matches Check 36–39 pattern |
| D2 regex first-char class | `[A-Za-z]` (admits lowercase script names) | Empirical: `merge-json.py` would be missed by `[A-Z]`-only |
| D3 triage heuristic | T1 (uniform FAIL with allowlist) | Matches Check 37 pattern; avoids noise + complexity |
| D3 severity | Single FAIL (no NIT/SHOULD tier) | Binary CI-gate contract |
| D4 file-exists verification | ENABLED (candidate-path lookup) | Stronger guarantee + actionable error messages |
| D5 allowlist mechanism | Two-tier: per-pattern global dict + anchor-phrase | Matches Check 37; covers contextual cases |
| D5 initial allowlist | 8 entries (pack-root files + trinity + memory cache) | Architecturally-justified minimum |
| D5 anchor phrases | Subset of Check 37 + new `post-install` | Forward-compat for audience-bridge |
| D6 L472 disposition | M2-equivalent (L472 is QUALIFIED, so out of Check 40 scope) + §7.3 editorial prose edit | Respects Override 8; documents audience-bridge to readers |
| D7 bootstrap order | Land Check 40 + all qualification fixes + manifest regen in ONE commit | Matches Check 37 bootstrap pattern; CI green at commit |
| D8 trinity / rule interactions | No trinity edit; RC9 manifest-regen mandatory; Override 8 respected | All interactions composable |

---

## §13 Appendix — pre-survey data for the coder

### §13.1 In-scope file inventory (verified 2026-05-20 against HEAD `18880b4`)

```
pack-ops/BOUNDARY-DEFINITION.md         (255 lines)
pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md (297 lines)
pack-ops/DRY-RUN-MIGRATION.md           (199 lines)
pack-ops/HELP-FRAGMENT-PACK.md           (42 lines)
pack-ops/HELP-FRAGMENT-TRACKER.md        (49 lines)
pack-ops/MERGE-STRATEGY.md              (482 lines)
pack-ops/OPTIONAL-FEATURES.md           (235 lines)
pack-ops/PACK-AGENTS.md                 (248 lines)
pack-ops/PACK-CHAT.md                   (291 lines)
```

Excluded per §2.1 D1a:
```
pack-ops/BACKLOG.md                    (4205 lines; regenerated mirror)
pack-ops/CHANGELOG.md                   (734 lines; regenerated mirror)
```

### §13.2 Bare-ref hit estimate vs verification path

The §8.2 table's hit counts are manual-survey estimates. Coder runs Check 40 in print-only mode against HEAD as the first implementation step to ground the actual count. Per §11.6 OQ-6, the coder reports the actual count to Pack Chat before applying qualification edits.

### §13.3 Cross-reference: ARCHITECTURE-BD-176.md interaction

This strategy doc references BD-176 only in §1.3 (cross-BD context) and §9.3 (composition check). The BD-176 architect doc has a §5.3 sketch for a "self-documenting files-copied-to-clients list" — that sketch is BD-180's surface, not BD-179's. No content carry-forward from BD-176 to BD-179 beyond the v11-surface trigger expansion.

### §13.4 Cross-reference: ARCHITECTURE-BD-119.md §9.2 reconciliation pattern

Per the BD-179 prompt, ARCHITECTURE-BD-119.md §9.2 demonstrates the architect-doc-vs-reality reconciliation pattern (Pattern A → realized consumer chain). BD-179 is itself an architect doc; it does not realize a design pre-existing in ARCHITECTURE-BD-119.md or any other architect doc. The reconciliation pattern does not apply to BD-179's landing commit (see §9.10 for forward-pointing note on future BDs that might trigger reconciliation back to this doc).

### §13.5 The qualified-vs-bare regex test (verification snippet for the coder)

```python
import re

# §3.3 final regex
_CHECK_40_BARE_REF_PATTERN = re.compile(
    r"`([A-Za-z][A-Za-z0-9_.-]*\.(?:md|sh|py|toml|yml|yaml|json|txt))`"
)

# Verification:
# Bare (matches):
assert _CHECK_40_BARE_REF_PATTERN.search("see `MIGRATION-v10-to-v11.md` for ...")
assert _CHECK_40_BARE_REF_PATTERN.search("the `merge-json.py` script")
assert _CHECK_40_BARE_REF_PATTERN.search("- `QUICKSTART.md` — where to start")
# Qualified (no match):
assert not _CHECK_40_BARE_REF_PATTERN.search("see `supporting-docs/MIGRATION-v10-to-v11.md`")
assert not _CHECK_40_BARE_REF_PATTERN.search("the `scripts/merge-json.py` script")
assert not _CHECK_40_BARE_REF_PATTERN.search("- `pack-ops/MERGE-STRATEGY.md` — ...")
# Wildcards (no match by §3.4):
assert not _CHECK_40_BARE_REF_PATTERN.search("the `HELP-FRAGMENT*.md` family")
# Narrative shorthand without extension (no match by §3.4):
assert not _CHECK_40_BARE_REF_PATTERN.search("the (validate-pack Check 8 enforces)")
```

Coder uses this snippet as the first unit test (Group 1) per §8.3 step 2.

---

**End of ARCHITECTURE-BD-179.md.**

When this strategy doc changes after pack-coder spawns (rare), re-spawn pack-architect for the second pass rather than amending mid-implementation. Pack Chat surfaces strategy-doc deltas to the user before approving the second-pass spawn per the planner-output-→-user-review-→-coder-spawn rule.

