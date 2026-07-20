---
name: dashboard-render
description: Dispatch the pack frontier dashboard render to the committed renderer scripts/dashboard-render.py (build mode). The renderer reads the build spec, collects fresh state (committed sources + a live git working-tree read + the complete session-state layer), authors or reuses the spec-fingerprinted shell, injects the complete #state, atomically writes dashboard.html (temp then verify then rename on PASS), and runs the complete-floor verify before the board is accepted; a shortfall exits non-zero and leaves no board on disk.
allowed-tools: Read, Bash
---

Render one self-contained HTML dashboard page for the pack frontier by invoking the
committed renderer. Do not restate the spec's substance here — the renderer executes
the spec's §2 recipe in full; this skill names the invocation only.

## Run the renderer

Run the committed renderer in `build` mode against the repo root:

```
python3 scripts/dashboard-render.py build --repo-root <repo-root>
```

`--repo-root` defaults to the script's git toplevel; `--spec` defaults to
`pack-ops/DASHBOARD-SPEC-PACK.md` and overrides which build spec is rendered.

The renderer executes the spec's §2 recipe: it collects fresh state (the `/backlog/`
and `/changelog/` trees, `README.md`, `CLAUDE.md` § Pack memory, `PACK-AGENTS.md`, a
live `git status` / `git worktree list` read, and `pack-ops/session-state.json` for the
complete session-state layer), selects each `bds{}` record's full-or-minimal tier,
authors or reuses the spec-fingerprinted shell
`pack-ops/dashboard-approvals/dashboard-shell.html` (reused when its `spec-sha` matches
the live spec, regenerated otherwise), injects the complete `#state`, and writes
`pack-ops/dashboard-approvals/dashboard.html`.

The write is ATOMIC: the renderer renders into a temp path, runs the complete-floor
`verify` against it, and renames it into `dashboard.html` ONLY on a PASS. On any
shortfall the renderer exits non-zero and leaves no board on disk. The completeness
floor lives in the committed `verify` and the spec's §3 floor coverage — a single
SSOT, not restated in this skill.
