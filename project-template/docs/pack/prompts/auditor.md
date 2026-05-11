---
agent: auditor
variants:
  - standard
---

# auditor — prompt templates

## Variant: standard

*For the `auditor` parent agent — runs a full-codebase structural audit.
Spawns up to seven read-only subagents (one per cluster) and consolidates
their reports. See the `audit-methodology` skill for cluster definitions,
file scopes, severity scale, pass/fail thresholds, and report format.*

**Context:** [PM chat fills — e.g., "Codebase has not had a recent
full-codebase structural audit," or "Verifying fixes for prior findings
TD-NNN..TD-MMM."]

**Required reading:** `audit-methodology` skill (loaded by the parent only).
Each spawned subagent loads the platform skills listed under
`**Platform skills to load per subagent**` below from PLATFORM-SKILLS.md.

**Problem:** The codebase has not had a recent full-codebase structural audit
across the seven cluster dimensions (security, architecture, tests, ops, code,
ui, docs), or a fix-verification audit is needed against a known set of prior
findings.

**Goal:** A consolidated report containing the executive summary plus per-cluster
subagent reports, with skipped clusters disclosed and findings deduplicated per
ownership precedence.

**Success criteria:**
- Executive summary present per `audit-methodology` rules 11–13: total findings
  per severity, top 3 issues (highest severity first; tie-break by cluster
  order from rule 38), pass/fail verdict, skipped subagents with reason.
- All non-skipped subagent reports appended in cluster order (rule 53):
  security → architecture → tests → ops → code → ui → docs.
- Duplicate findings resolved per ownership precedence rules 33–39 with
  surviving entries annotated `(also detected by: <other-clusters>)`.
- `## Next steps` section appended listing Critical and Major findings in
  priority order, cross-referencing METHODOLOGY.md Part 6 BACKLOG processing.

**Files in scope:** None (read-only audit). Output is the consolidated report
only.

**Constraints:**
- Read-only audit. Do not write to BACKLOG.md, STATUS.md, or any other project
  file. In tracker mode the BACKLOG/STATUS mirrors are read-only by design
  and the underlying tracker entries are PM-chat exclusive — the read-only
  posture holds in both modes.
- **Skip rules for this project:** [PM CHAT FILLS THIS IN — for example: "Skip
  auditor-ui (server-only project, no UI layer). Run the six remaining
  clusters." Or: "Run all seven clusters." Or: "Skip auditor-tests (first audit
  of a brand-new project) and auditor-ui (server-only). Run the five remaining
  clusters." Note: auditor-ops is never skippable per audit-methodology rule 46.]
- **Platform skills to load per subagent** (the parent loads only
  `audit-methodology`; each subagent loads the platform skills relevant to its
  cluster from the project's PLATFORM-SKILLS.md profile):
  - `auditor-architecture`: [PM CHAT FILLS — e.g., apple-architecture-core, ios-architecture, python-server-architecture, python-data-architecture]
  - `auditor-code`: [e.g., swift-best-practices, python-best-practices, error-handling]
  - `auditor-tests`: [e.g., testing, ui-test-strategy]
  - `auditor-docs`: documentation
  - `auditor-security`: security-patterns, dependency-swift, dependency-python
  - `auditor-ui`: [if not skipped — e.g., apple-architecture-core, ios-architecture, swift-best-practices]
  - `auditor-ops`: [e.g., deployment-apple, deployment-python]
- **File scope guidance.** Compute per-subagent file scopes per
  `audit-methodology` rules 25–32. Apply the always-exclude list (rule 25):
  `**/.git/**`, `**/.build/**`, `**/DerivedData/**`, `**/node_modules/**`,
  `**/.venv/**`, `**/Pods/**`, `**/__pycache__/**`, `**/generated/**`,
  `**/*_pb2.py`, `**/*.pb.swift`, `**/*.pb.go`. Never pass generated code,
  vendored dependencies, or test fixtures to any subagent.
- **Spawn the subagents** per the per-tool mechanism (rules 56–60):
  - Claude Code: parallel `Task` tool calls in a single message
  - Codex CLI: native subagent invocation via `max_depth=2` config
  - Gemini CLI: native subagents in `.gemini/agents/`, but subagents cannot call
    subagents — `agent-run.sh run_gemini_auditor` provides external orchestration

**Completion report:**
REPORT FILE: `[PM chat supplies path; e.g., docs/project/audit-report-YYYY-MM-DD.md]`

Consolidate per rules 48–55:
1. Executive summary: total findings per severity, top 3 issues (highest
   severity first; tie-break by cluster order from rule 38), pass/fail
   verdict per rules 11–13, any skipped subagents with reason.
2. Append all subagent reports in cluster order (rule 53):
   security → architecture → tests → ops → code → ui → docs.
3. Resolve duplicates per ownership precedence rules 33–39. When a finding
   is attributed to one cluster, annotate the surviving entry with
   `(also detected by: <other-clusters>)` and remove the duplicate. Apply
   severity reconciliation per rule 39 — higher severity always wins.
4. Append a `## Next steps` section listing Critical and Major findings
   in priority order, cross-referencing this PM chat's BACKLOG processing
   workflow (METHODOLOGY.md Part 6).

## Templates 10–12 — Superseded

Templates 10 (Documentation Audit), 11 (Architecture / LSP Audit), and 12
(UI Audit) have been consolidated into the `standard` variant above. The
auditor's seven-cluster architecture covers all three audit dimensions
(plus four additional ones) in a single coordinated run with deduplicated
findings and a unified severity scale.

If you need to audit only one dimension — for example, to verify a fix — run
the corresponding subagent directly per `audit-methodology` rule 70:

```
./agent-run.sh <cli> --agent auditor-docs        # documentation drift
./agent-run.sh <cli> --agent auditor-architecture # layer/LSP/coupling
./agent-run.sh <cli> --agent auditor-ui          # view-thickness/accessibility
```

The subagent reports directly to the terminal; the parent is bypassed.
