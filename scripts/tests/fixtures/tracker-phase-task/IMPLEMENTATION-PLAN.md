## Phase 3 — Foundations

### Tasks
#### 3.1 — Schema bootstrap
- **Problem / Goal / Success**: define the initial schema; success is a
  passing schema-validate run with the v11 grammar accepted.
- **Files created/modified**: schemas/v11.json
- **Definition of done**: `bash scripts/tests/schema-validate.sh` PASS.
- **Dependencies**:
  - phase-2.4 (must complete migration scaffold first)
  - TD-029

#### 3.2 — Reverse emitter
- **Problem / Goal / Success**: emit canonical text from parsed JSON.
- **Files created/modified**: scripts/lib/tracker-phase-task.sh
- **Definition of done**: round-trip identity test PASS.
- **Dependencies**:
  - phase-3.1

#### 3.3 — Cross-phase wiring
- **Problem / Goal / Success**: phase-7 task may name phase-3.4 as a dependency.
- **Files created/modified**: scripts/lib/tracker-links.sh
- **Definition of done**: link round-trip PASS.
- **Dependencies**:
  - phase-7.4
  - BD-108
  - TD-030 see TD-029: blocking on schema-bootstrap
  - TD-031 #issue-tracker-link

### Verification
`bash scripts/tests/test-tracker-phase-task.sh` PASS.

### Agent
pack-coder.

### Risks
| Risk | Severity | Mitigation |
| --- | --- | --- |
| parser regex drift | medium | golden fixture |

## Phase 4 — Sparse phase

### Tasks

### Verification
manual.

## Phase 7 — Cross-phase consumer

### Tasks
#### 7.1 — Consume phase-3 outputs
- **Problem / Goal / Success**: depends on phase-3 schema.
- **Files created/modified**: scripts/lib/tracker-links.sh
- **Definition of done**: chain test PASS.
- **Dependencies**:
  - phase-3.4
