# Pack changelog — how to use this tree

> **Audience:** humans.
> **Purpose:** orientation. This file is NOT read by agents and carries
> NO rules. The per-stream contract (filename regex, granularity,
> ID-extraction, write authority) lives entirely in `_rules.md`.

All notable changes to the AI Agent Config Pack are documented here.
Each major version is available as a git tag (`v1`, `v2`, …).

This directory is the **sole source of truth and readable form** for
the pack changelog — one `vN.md` file per major release, plus a
generated `_toc.md` index. There is no monolithic `CHANGELOG.md`
mirror.

## Reading the changelog

- For a release index (newest first), read `_toc.md`.
- For a single release, read its per-entry file directly at
  `/changelog/vN.md`. The first line is an HTML-comment back-pointer
  that names the contract at `/changelog/_rules.md`. Each release file
  carries its full body, including any nested `### vN.M` /
  `### New/Updated` subsections.

## Adding a release

At a version boundary, write a new `/changelog/vN.md` (or extend the
current release file), then regenerate `_toc.md`. Pack Chat writes;
agents edit only when scoped in.
