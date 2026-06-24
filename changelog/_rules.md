# Stream contract — pack-changelog

> **Audience:** agents + Pack Chat.
> **Purpose:** the SOLE contract for this directory's per-entry files —
> the single source for the per-stream rules; no rule is duplicated or
> fragmented across `_intro.md` / `_toc.md` / any other doc. `_intro.md`
> is human-only orientation and carries zero rules.

Per-stream contract. Pointer-heavy by design. Updated only when the pack
changes the per-entry contract.

## Stream identity

- Stream name: `pack-changelog`
- Pack version that minted this contract: v11.0
- Directory: `/changelog/`

## Source of truth — no mirror

The per-entry tree at `/changelog/` (plus its generated
`/changelog/_toc.md` index) is the **SOLE source of truth and readable
form** for the pack changelog. **There is no monolithic mirror;** do not
recreate one.

**Mode invariance.** The pack-changelog stream is FLAT-FILE
unconditionally; the § "Write authority" procedure below is the sole
write procedure.

## Filename convention

Per-entry files match `^v\d+\.md$` (e.g., `v11.md`, `v7.md`) — one file
per major release. Granularity is per-RELEASE (one `vN.md` per
`## vN — <date>` H2): any nested `### vN.M` / `### vMAJOR.MINOR (X)` (a
going-forward H3 MAY carry a release-state qualifier label) /
`### New/Updated` subsections live INSIDE their major `vN.md` file,
preserved verbatim. The filename regex `^v\d+\.md$` and the ID-extraction
rule below are UNCHANGED — per-major granularity stays; a qualifier appears
only in an H3 subsection label, never in a filename.

## ID-extraction rule

The per-entry **filename is the ID**: the release `## v11 — May 2026`
becomes `v11.md`; the ID is the captured `vN` group. Each entry file's
body is the entire H2 release block.

## Entry contract

One release per file. The first line is an HTML-comment back-pointer
ABOVE the `## vN — <date>` H2; the content span begins at that H2 and
runs through the last line before the next release.

## Lifecycle states admitted

Append-by-release — no lifecycle states. Releases are chronological and
appended, not edited after the fact.

## Supporting files

- `_rules.md`
- `_intro.md`
- `_toc.md`

Files not matching the entry regex AND not in this list are SKIP.

## Write authority

Writes are Pack-Chat authority (the pack-changelog tree is a
pack-chat-only directory per `pack-ops/PACK-AGENTS.md` §
"pack-chat-only files and directories"; agents edit it only when a
caller scopes it in for an explicit version boundary). After any
release edit, regenerate `_toc.md` via
`per_entry_regenerate_toc pack-changelog /changelog` before staging.
