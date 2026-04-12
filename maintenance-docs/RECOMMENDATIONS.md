# Recommendations

Practical recommendations for new projects using the AI Agent Config Pack v9.

1. Keep repo-level instructions committed, but keep local overrides and real MCP files out of Git.

2. Start with the provided validation scripts, then replace generic Xcode steps with scheme-specific commands as soon as the first app target stabilizes.

3. After you provide your design and pattern rules, fold them into `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, and the review skills before you let any tool make broad refactors.

4. Install `buf` before writing any `.proto` files. Run `buf lint` and `buf breaking` in the validation script from day one — retrofitting breaking-change detection is much harder.

5. Decide on your Python server framework (FastAPI, gRPC-only, etc.) and fill in the `[PLATFORM_DEFAULTS]` and `[LANGUAGE_RULES]` sections in the context files before significant server work begins. The unified template leaves this intentionally open.

6. The `grpc-schema` agent is intentionally read-only. Use it for review and planning. Never let it write directly to `.proto` files without a human review step.

7. Pin `grpcio` and `grpcio-tools` to the same version in `pyproject.toml`. Version drift between them is a common source of generation failures.

8. The `pyrightconfig.json` is set to `strict` mode by default. If you need to onboard a legacy codebase, temporarily use `standard` mode and track the path to strict in a comment.

9. Add CI/CD once your schema and toolchain stabilize. The most valuable first CI step for gRPC projects is `buf breaking` run against `main` — it catches breaking schema changes before they merge.

10. Keep the `proto/` directory at the repo root (or monorepo root) so both client and server generation scripts can find it by convention.

11. Fill in `PLATFORM-SKILLS.md` during kickoff — the PM chat needs the project's skill profile to generate correct agent prompts from day one.

12. Seed `PACK-FEEDBACK.md` during kickoff. The PM chat will begin logging observations for the Pack Chat at workflow boundaries.
