# Implementation Plan

## Phase 3 — Foundations

### Tasks
#### 3.1 — Schema bootstrap
- **Problem / Goal / Success**: define the initial schema; success is a
  passing schema-validate run with the v11 grammar accepted.
- **Files created/modified**: schemas/v11.json
- **Definition of done**: `bash scripts/tests/schema-validate.sh` PASS.
- **Dependencies**:
  - (none)

#### 3.2 — Reverse emitter
- **Problem / Goal / Success**: emit canonical text from parsed JSON.
- **Files created/modified**: scripts/lib/tracker-phase-task.sh
- **Definition of done**: round-trip identity test PASS.
- **Dependencies**:
  - phase-3.1

### Verification
`bash scripts/tests/test-tracker-phase-task.sh` PASS.

### Agent
pack-coder.

### Risks
| Risk | Severity | Mitigation |
| --- | --- | --- |
| parser regex drift | medium | golden fixture |
