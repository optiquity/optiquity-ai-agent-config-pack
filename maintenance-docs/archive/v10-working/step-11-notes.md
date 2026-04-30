# Step 11 Assembly Notes

*Corrections and refinements identified during G4-G7 review that the
Step 11 assembly must incorporate into V10-DESIGN.md.*

---

## Note 1 — Rename prompts/README.md to PROMPT-AUTHORING.md

Step 4 §2.4 proposed `docs/pack/prompts/README.md` as a pointer file
to METHODOLOGY.md's Prompt Authoring Principles section. Two problems:

1. `README.md` is non-descriptive and conventionally for human
   orientation, not machine instructions. The PM chat scanning the
   prompts directory cannot distinguish it from a generic readme.
2. A pointer-only stub wastes a file. The "How to use these templates"
   guidance (PROMPT-TEMPLATES.md lines 7-17) and the per-agent
   exceptions table (lines 48-58) are practical quick-reference content
   that the PM chat reads right before generating a prompt.

**Resolution:** Rename to `PROMPT-AUTHORING.md`. Content: the "How to
use" guidance, per-agent exceptions table, and self-check rule from
the current PROMPT-TEMPLATES.md, plus a pointer to METHODOLOGY.md for
the full Prompt Authoring Principles. Small, direct-readable, not a
pointer-only stub. Uppercase name distinguishes it from the per-agent
lowercase files.

**Affects:** Step 4 §2.4, Step 8 rows 22 and 67, Step 10 V-PROMPT-04,
Step 6 §8.6 (S4 copies the prompts directory — new filename applies),
Step 7 §4.1 S6 and §6.2 verification (file count: now 10 per-agent
files + PROMPT-AUTHORING.md = 11 files in the directory).

---

## Note 2 — No orphaned templates after redistribution

Verified: all 14 templates in PROMPT-TEMPLATES.md have destinations in
the Step 4 §1.2 mapping (agent templates → per-agent files; PM chat
operational templates → pm-chat.md). Templates 10-12 are superseded
(already noted in the monolith). The "Prompt Authoring Principles"
section (lines 21-76) is already a documented duplicate of
METHODOLOGY.md content. After redistribution, zero content remains in
the monolith — deletion is correct.

---

## Note 3 — Agent report file convention (Part 12 of V10-PREDESIGN.md)

V10-PREDESIGN.md Part 12 documents a convention validated during the
v10 design process: agent sessions write deliverables to a designated
report file on disk. V10-DESIGN.md must incorporate this into the
prompt template format and PM-CHAT.md behavioral rules. See Part 12
for the full specification including read-only vs. write-capable
framing, the REPORT FILE field, closing instruction, and chunking
instruction.
