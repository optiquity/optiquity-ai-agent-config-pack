#!/usr/bin/env python3
# pack-internal: true  (CI helper; not a user-facing verb)
"""
compare-agent-trinity.py — verify trinity-rule symmetry across the three
tool variants of a pack-roster agent file.

Per BD-059 success criterion #7 (trinity rule compliance), every
pack-roster agent ships in three formats parallel across the three tools:

  .claude/agents/<name>.md                          (Markdown with YAML frontmatter)
  .codex/agents/<name>.toml                         (TOML; body in `developer_instructions`)
  .agents-plugin/optiquity-agents/agents/<name>.md  (Antigravity plugin-bundle agent; Markdown with YAML frontmatter)

(BD-221: the third tool is Antigravity, which ships agents as a plugin
BUNDLE rather than a loose per-CLI dir, so the third tool's variant lives
in the client bundle roster `project-template/.agents-plugin/
optiquity-agents/agents/`. The comparison LOGIC is unchanged.)

The trinity rule says: when one tool's variant is edited, the parallel
edits must land in the other two unless the change is provably
tool-specific. The three formats differ enough that direct text diff is
useless (TOML vs Markdown). This script normalizes each variant into
comparable form and reports semantic divergence.

What is compared:
  - The `name` field (must match exactly across the three).
  - The body prose: extracted from each format, then whitespace-normalized
    (all runs of whitespace collapsed to a single space, leading/trailing
    stripped). Bodies must match across the three after normalization.
    Whitespace-only differences (line wrapping, paragraph spacing) are
    tolerated; substantive content divergence is reported.

What is NOT compared:
  - Tool-specific frontmatter fields (model, approval_policy, sandbox_mode,
    temperature, max_turns, allowed-tools format, etc.) — these are
    intentionally per-tool. The trinity rule does not apply to them.
  - The `description` field — Claude descriptions often include phase
    routing notes ("Default for:", "Also handles:") that the other two
    tools don't carry. The script reports each tool's description
    verbatim but does not enforce equality.

Usage:
    compare-agent-trinity.py <name> [--pack PATH]
    compare-agent-trinity.py --all [--pack PATH] [--summary-only]

Exit codes:
    0  trinity-symmetric (or all agents in --all mode are symmetric)
    1  argument or read error
    2  one or more agents have body divergence (output to stdout)

The script reads `<pack>/project-template/.claude/agents/`,
`<pack>/project-template/.codex/agents/`, and the Antigravity client
plugin bundle `<pack>/project-template/.agents-plugin/optiquity-agents/agents/`.
"""

import argparse
import difflib
import re
import sys
import tomllib
from pathlib import Path

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n?(.*)$", re.DOTALL)


def parse_md_frontmatter(text: str) -> tuple[dict, str]:
    """Return (frontmatter_dict, body) from a Markdown file with YAML frontmatter."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, text
    fm_text, body = m.group(1), m.group(2)
    fm: dict[str, str] = {}
    for line in fm_text.splitlines():
        line = line.rstrip()
        if not line or line.startswith("#"):
            continue
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip().strip('"\'')
    return fm, body


def parse_codex_toml(text: str) -> tuple[dict, str]:
    """Return (top_level_dict, body) from a Codex TOML agent file.

    Body is `developer_instructions`, falling back to `system_prompt`. Both
    are removed from the metadata dict before returning.
    """
    data = tomllib.loads(text)
    body = ""
    if "developer_instructions" in data:
        body = data.pop("developer_instructions")
    elif "system_prompt" in data:
        body = data.pop("system_prompt")
    return data, body


def normalize_body(body: str, strict: bool = False) -> str:
    """Normalize body for comparison.

    Default (lenient) mode strips Markdown inline-formatting chars
    (backticks, single-char asterisks/underscores around words) before
    whitespace collapse. The pack's Codex agent files frequently drop
    backticks around inline code/skill names; this is stylistic noise
    that the trinity rule does not enforce.

    Strict mode keeps the formatting chars, so any divergence — including
    stylistic — is reported. Useful for pack-quality audits.

    All modes collapse whitespace runs (including newlines) to single
    spaces and strip leading/trailing whitespace.
    """
    if not strict:
        body = body.replace("`", "")
    return re.sub(r"\s+", " ", body).strip()


def read_agent(pack: Path, tool: str, ext: str, name: str, strict: bool = False) -> dict | None:
    """Read one tool's agent file. Return None if missing.

    The Claude/Codex legs read the loose per-CLI dir `.{tool}/agents/`. The
    Antigravity leg (`tool == "agents"`, BD-221) reads the client plugin
    bundle roster `.agents-plugin/optiquity-agents/agents/` — Antigravity
    agents ship as a plugin BUNDLE, not a loose per-CLI dir.
    """
    if tool == "agents":
        path = (pack / "project-template" / ".agents-plugin"
                / "optiquity-agents" / "agents" / f"{name}.{ext}")
    else:
        path = pack / "project-template" / f".{tool}" / "agents" / f"{name}.{ext}"
    if not path.is_file():
        return None
    text = path.read_text()
    if ext == "toml":
        meta, body = parse_codex_toml(text)
    else:
        meta, body = parse_md_frontmatter(text)
    return {
        "tool": tool,
        "path": path,
        "meta": meta,
        "body": body,
        "norm": normalize_body(body, strict=strict),
        "name_field": meta.get("name", ""),
    }


def show_body_diff(label_a: str, body_a: str, label_b: str, body_b: str, max_lines: int = 30) -> None:
    """Print a unified diff of two normalized bodies, segmented on sentence breaks."""
    seg_a = re.split(r"(?<=[.!?])\s+", body_a)
    seg_b = re.split(r"(?<=[.!?])\s+", body_b)
    diff = list(difflib.unified_diff(
        seg_a, seg_b, lineterm="", fromfile=label_a, tofile=label_b, n=2
    ))
    if not diff:
        return
    print(f"  --- {label_a} vs {label_b} ---")
    shown = 0
    for line in diff:
        if shown >= max_lines:
            print(f"    ... ({len(diff) - shown} more diff lines suppressed)")
            break
        print(f"    {line}")
        shown += 1


def compare_one(pack: Path, name: str, verbose: bool = True, strict: bool = False) -> int:
    """Compare the three tool variants of agent <name>. Return 0 / 2.

    The third leg ("agents", BD-221) is the Antigravity plugin-bundle agent
    `.agents-plugin/optiquity-agents/agents/<name>.md`. Comparison logic is
    unchanged.
    """
    claude = read_agent(pack, "claude", "md", name, strict=strict)
    codex = read_agent(pack, "codex", "toml", name, strict=strict)
    agents = read_agent(pack, "agents", "md", name, strict=strict)

    missing = [t for t, v in (("claude", claude), ("codex", codex), ("agents", agents)) if v is None]
    if missing:
        print(f"error: agent '{name}' missing in: {', '.join(missing)}", file=sys.stderr)
        return 1

    name_values = [claude["name_field"], codex["name_field"], agents["name_field"]]
    name_field_match = all(v == name for v in name_values)
    bodies_match = claude["norm"] == codex["norm"] == agents["norm"]

    symmetric = name_field_match and bodies_match

    if verbose:
        status = "PASS" if symmetric else "DIVERGENT"
        print(f"=== {name}: {status} ===")
        print(f"  name field:       claude={claude['name_field']!r} codex={codex['name_field']!r} agents={agents['name_field']!r}")
        if not name_field_match:
            print(f"  WARNING: name field mismatch (expected {name!r} in all three)")
        print(f"  body length norm: claude={len(claude['norm'])} codex={len(codex['norm'])} agents={len(agents['norm'])}")
        print(f"  body match:       {'YES' if bodies_match else 'NO'}")
        if not bodies_match:
            if claude["norm"] != codex["norm"]:
                show_body_diff("claude", claude["norm"], "codex", codex["norm"])
            if claude["norm"] != agents["norm"]:
                show_body_diff("claude", claude["norm"], "agents", agents["norm"])
            if codex["norm"] != agents["norm"] and claude["norm"] == codex["norm"]:
                # claude/codex agree but the Antigravity bundle agent differs
                show_body_diff("codex", codex["norm"], "agents", agents["norm"])
        # Description (informational; not enforced)
        print(f"  descriptions (informational, not enforced for equality):")
        for v, lbl in ((claude, "claude"), (codex, "codex"), (agents, "agents")):
            d = v["meta"].get("description", "<no description>")
            d_short = d[:100] + ("..." if len(d) > 100 else "")
            print(f"    {lbl}: {d_short}")

    return 0 if symmetric else 2


def list_pack_agents(pack: Path) -> list[str]:
    """Return sorted list of agent names from .claude/agents/, excluding x-*."""
    agent_dir = pack / "project-template" / ".claude" / "agents"
    if not agent_dir.is_dir():
        return []
    return sorted(
        p.stem for p in agent_dir.glob("*.md")
        if not p.stem.startswith("x-")
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0], formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("name", nargs="?", help="Agent name (e.g., 'coder')")
    ap.add_argument("--pack", default=".", help="Pack repo path (default: cwd)")
    ap.add_argument("--all", action="store_true", help="Compare every agent in the pack roster")
    ap.add_argument("--summary-only", action="store_true", help="In --all mode, suppress per-agent details on PASS")
    ap.add_argument("--strict", action="store_true",
                    help="Strict comparison: keep Markdown formatting chars (backticks etc.) in body diff. "
                         "Default is lenient (formatting normalized away) since the trinity rule enforces "
                         "substantive content equivalence, not stylistic identity.")
    args = ap.parse_args()

    pack = Path(args.pack).resolve()
    if not (pack / "project-template").is_dir():
        print(f"error: {pack} does not look like a pack repo (no project-template/)", file=sys.stderr)
        return 1

    if args.all:
        names = list_pack_agents(pack)
        if not names:
            print("error: no pack agents found in project-template/.claude/agents/", file=sys.stderr)
            return 1
        any_diverged = False
        diverged_names: list[str] = []
        for name in names:
            verbose = not args.summary_only
            rc = compare_one(pack, name, verbose=verbose, strict=args.strict)
            if rc != 0:
                any_diverged = True
                diverged_names.append(name)
                if args.summary_only:
                    # Re-run verbose to show the divergence detail.
                    compare_one(pack, name, verbose=True, strict=args.strict)
        print()
        print(f"summary: {len(names)} agents checked; {len(diverged_names)} divergent")
        if diverged_names:
            print(f"divergent: {', '.join(diverged_names)}")
        return 2 if any_diverged else 0

    if not args.name:
        ap.print_usage(sys.stderr)
        print("error: agent name required (or use --all)", file=sys.stderr)
        return 1

    return compare_one(pack, args.name, verbose=True, strict=args.strict)


if __name__ == "__main__":
    sys.exit(main())
