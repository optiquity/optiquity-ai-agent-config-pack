 # V10 Design Process Plan                                                                                
                                                                           
  *Plan type: Phase 1 of the four-phase progression (V10-PREDESIGN.md Part 7).*                            
  *Goal of this phase: produce an approved V10-DESIGN.md.*                                                 
  *Scope of this plan: the workflow between "V10-PREDESIGN.md exists" and "V10-DESIGN.md is approved and   
  V10-PREDESIGN.md is superseded."*                                                                        
  *This plan itself also resolves OQ-6 (design approval process) by defining the process, the actors, the  
  checkpoint gates, and the approval artifact.*                                                            
                                                                  
  ---                                                                                                      
                                                                  
  ## 0. Goal and BD items addressed                                                                        
   
  **Goal.** Convert V10-PREDESIGN.md (discussion capture: 13 candidate decisions, 14 open questions, 9     
  design requirements) into a fully approved V10-DESIGN.md that is detailed enough to drive a downstream
  implementation planning session. At exit:                                                                
                                                                  
  - Every CD-N in V10-PREDESIGN.md has been explicitly confirmed, changed, or superseded in V10-DESIGN.md. 
  - Every OQ-N has been resolved in V10-DESIGN.md or explicitly deferred with a documented rationale and
  fallback.                                                                                                
  - Every Design Requirement from Part 7 has a named section in V10-DESIGN.md that addresses it.
  - V9 lessons (Part 8) have been applied as concrete checkpoints, not generic guidance.                   
  - The token budget analysis (Part 9), migration testing matrix (Part 10), and verification plan (OQ-14)  
  are present in V10-DESIGN.md.                                                                            
  - A written approval record exists.                                                                      
                                                                                                           
  **BD items in scope of V10 and therefore of V10-DESIGN.md.**                                             
                                                                                                           
  | BD | Title | Source |                                                                                  
  |---|---|---|                                                   
  | BD-044 | Project setup paths: init-project.sh, QUICKSTART router, existing-project onboarding |        
  V10-PREDESIGN CD-10, BACKLOG |                                                                           
  | BD-045 | Champion capabilities design pattern alongside LSP | V10-PREDESIGN CD-11, BACKLOG |
  | BD-046 | Custom agent/skill support and prompt template reorganization | V10-PREDESIGN core, BACKLOG | 
                                                                                                           
  **BD items explicitly out of scope of this phase** (to be confirmed at Step 1 below): none. No BD beyond 
  044/045/046 is in v10.                                                                                   
                                                                                                           
  ---                                                             

  ## 1. Actors, session formats, and roles

  The plan uses four actor types drawn from PACK-AGENTS.md and PACK-CHAT.md. Every step names its actor.   
   
  | Actor | Session format | Used for |                                                                    
  |---|---|---|                                                   
  | **Pack chat** (this chat, direct) | Current CLI session | PM-level scope and version decisions,        
  BACKLOG/README/CHANGELOG edits, writing the V10-DESIGN.md file itself, requesting developer approvals |  
  | **pack-architect** | Separate terminal session (`claude --agent pack-architect` or equivalent) | Each
  major design block (BD-045 content, prompt reorg, custom agent mechanism, migration strategy,            
  init-project.sh design). Separate session preferred per PACK-AGENTS.md "major design work" guidance |
  | **pack-docs-researcher** | Sub-agent (Task tool) or separate session | CLI tool documentation          
  verification — Codex config.toml rules, Claude Code skill loading, Gemini CLI subagent/skill mechanisms, 
  filesystem access patterns |
  | **pack-planner** | Sub-agent (Task tool) | Sequencing analysis, migration testing matrix construction, 
  verification plan scaffolding. Not implementation planning — that is Phase 3 |                           
  | **pack-reviewer** | Separate session at end, sub-agent for mid-phase spot checks | Final V10-DESIGN.md
  audit: trinity rule, stale references, doc consistency, Part 8 lesson compliance |                       
  | **Developer** | Human in the pack chat loop | All checkpoint-gate approvals, final V10-DESIGN.md
  sign-off, tie-breaking on open questions, tag/commit approval |                                          
                                                                  
  **Why separate sessions for pack-architect.** Each major design block benefits from clean context and    
  extended reasoning, consistent with PACK-AGENTS.md "Separate terminal session" guidance. Pack chat
  context becomes dense fast when carrying all 14 OQs and 13 CDs plus multiple cross-doc reads.            
                                                                  
  **Why pack-docs-researcher runs early and in parallel.** V9 Lesson 2 (Gemini CLI `--agent` flag and Plan 
  Mode errors) shipped because CLI-specific behavior was not verified before design decisions were
  committed. This plan runs pack-docs-researcher as Step 2, before any binding decision that depends on CLI
   behavior.                                                      

  **Why pack-reviewer runs at the end in a separate session.** V9 Lesson 5 (maintenance-docs stale         
  references missed in initial audits) calls for a review pass whose scope explicitly includes
  maintenance-docs. PACK-AGENTS.md "Independent review that should not be influenced by the pack chat's    
  prior context" applies.                                         

  ---

  ## 2. Inputs every step can assume

  Unless a step names additional inputs, every step may assume the actor has read:                         
   
  - `maintenance-docs/V10-PREDESIGN.md` (all 11 parts, in full)                                            
  - `BACKLOG.md` (BD-044, BD-045, BD-046 entries)                 
  - `README.md` (repo layout section)                                                                      
  - `CLAUDE.md` (pack repo rules)                                 
  - `PACK-CHAT.md` (pack chat operating rules)                                                             
  - `PACK-AGENTS.md` (agent routing table)                        
  - `maintenance-docs/V9-DESIGN.md` (as a format and quality reference for a completed design doc)         
                                                                                                           
  Each step below lists incremental inputs on top of that baseline.                                        
                                                                                                           
  ---                                                                                                      
                                                                  
  ## 3. Workflow — ordered steps

  The numbering is execution order. Dependencies are explicit. Steps within the same "Block" may be        
  executed in the same session; steps in different blocks should generally use separate actors or separate
  sessions.                                                                                                
                                                                  
  ### Block A — Scope confirmation and tool verification                                                   
   
  #### Step 1 — Scope and sequencing confirmation                                                          
                                                                  
  **Actor.** Pack chat + developer.                                                                        
  **Session format.** Pack chat (this session or its successor).
  **Incremental inputs.** None.                                                                            
  **Work.**                                                                                                
  - Confirm or change the four scope/version candidate decisions:                                          
    - **CD-10** (BD-044 in v10)                                                                            
    - **CD-11** (BD-045 in v10)                                                                            
    - **CD-12** (v10.0 is the target version)                                                              
    - **CD-13** (latest v9.x is the only migration baseline)                                               
  - Resolve **OQ-10** (BD item sequencing). The predesign proposes BD-045 → BD-046 → BD-044. This ordering 
  cascades into the design doc section order (Step 5, Step 7, Step 9) and into Phase 3 implementation plan 
  sequencing. Confirm or change.                                                                           
  - Resolve **OQ-6** (design approval process itself). This is resolved by the developer approving the     
  present plan as the design approval process. Record in V10-PREDESIGN.md a note: "Design approval process 
  defined by V10-DESIGN-PROCESS-PLAN.md [or this plan's chosen name/location], approved YYYY-MM-DD."
                                                                                                           
  **OQs resolved.** OQ-6, OQ-10.                                                                           
  **CDs confirmed/changed.** CD-10, CD-11, CD-12, CD-13.
                                                                                                           
  **Checkpoint gate.** **Yes — cascading.** If scope or sequencing is wrong here, every subsequent step is 
  wrong. Developer must explicitly approve before Step 2.                                                  
                                                                                                           
  **Output.** A scope-and-sequencing memo (can be a section in this plan or a brief appended to            
  V10-PREDESIGN.md as "Scope confirmed, YYYY-MM-DD") listing which CDs are confirmed, which are changed
  (with rationale), and the agreed BD order.                                                               
                                                                  
  ---

  #### Step 2 — CLI tool documentation verification

  **Actor.** pack-docs-researcher.                                                                         
  **Session format.** Separate session (Gemini CLI docs research can be web-search-heavy and benefits from
  its own context).                                                                                        
  **Incremental inputs.**                                         
  - `maintenance-docs/TOOL-COMPARISON.md`                                                                  
  - Official CLI docs: Claude Code (https://docs.anthropic.com/claude-code), Codex (OpenAI Codex CLI),     
  Gemini CLI (https://geminicli.com/docs/).                                                                
                                                                                                           
  **Work.** Verify, with a direct citation to the current official doc, each of the following facts the    
  design pass will depend on:                                     
                                                                                                           
  1. **Codex `config.toml` agent registration.** Does Codex require an explicit `[agents.<name>]` entry in 
  addition to the `.toml` file in `.codex/agents/`? What are the naming rules (is `x_name` or `x-name`
  canonical)? What is the failure mode if the `.toml` file exists without the entry, and vice versa? (Input
   for OQ-2.)                                                     
  2. **Claude Code skill loading.** When and how does Claude Code pick up a new skill in
  `.claude/skills/<name>/SKILL.md` — session-start only, or continuously? Any naming rules that would block
   an `x-` prefix? (Input for CD-6, CD-7.)
  3. **Gemini CLI subagent and skill loading.** How are subagents in `.gemini/agents/*.md` picked up and   
  invoked? How are skills in `.gemini/skills/<name>/SKILL.md` loaded? Any filename rules that block `x-`?  
  (Input for CD-1, CD-6.)
  4. **Claude Desktop app project knowledge / MCP.** What file access patterns are available to a Desktop  
  PM chat for reading per-agent prompt files (CD-8)? Does it read a file on demand or must the file be in  
  project knowledge? (Input for Design Requirement "Document access patterns" and "PM chat tool
  flexibility".)                                                                                           
  5. **File size heuristics.** What is a reasonable upper bound for "direct read" vs. "RAG/search" on each
  tool for routinely-read files? (Input for Step 4 token budget analysis and Step 6 migration design.)     
  6. **Codex `post_edit_command` and hook mechanisms relevant to custom agent file creation.** (Input for
  CD-3, CD-4 PM-chat-driven creation.)                                                                     
                                                                  
  **V9 lesson applied.** Lesson 2. This step exists specifically to prevent the Gemini `--agent`/Plan Mode 
  class of error.                                                 
                                                                                                           
  **Output.** A findings memo with each claim tied to a source URL and retrieval date. This memo is an     
  input to Steps 4, 5, 6, and 7. It is not committed as its own file — its conclusions feed into
  V10-DESIGN.md.                                                                                           
                                                                  
  **Checkpoint gate.** **Yes** — developer reviews the findings memo before any downstream design step     
  relies on it. If a finding contradicts V10-PREDESIGN.md (e.g., the x- prefix collides with a CLI naming
  rule), flag it immediately.                                                                              
                                                                  
  ---

  ### Block B — BD-045 (capabilities pattern) — independent, drafted first                                 
   
  BD-045 is the most independent of the three BDs. It adds content to existing files and does not          
  restructure anything. Per OQ-10 it is drafted first.            
                                                                                                           
  #### Step 3 — BD-045 design: the capabilities pattern across nine locations                              
   
  **Actor.** pack-architect.                                                                               
  **Session format.** Separate session. This is substantive writing — ~nine location-specific drafts — and
  benefits from clean context.                                                                             
  **Incremental inputs.**                                         
  - BACKLOG.md BD-045 (full text, especially the "What to add — all nine locations" list).                 
  - `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` (current LSP  
  section and anti-patterns list).                                                                         
  - `project-template/skills/apple-architecture-core/SKILL.md`,                                            
  `project-template/skills/python-best-practices/SKILL.md`,                                                
  `project-template/skills/architecture-review/SKILL.md`.         
  - `project-template/.claude/agents/auditor-architecture.md`, `.codex/agents/auditor-architecture.toml`,  
  `.gemini/agents/auditor-architecture.md`.                                                                
   
  **Work.**                                                                                                
  - Resolve **OQ-13** (capabilities pattern content). Produce concrete drafts — or spec precise enough that
   an implementer needs no design-level decisions — for each of the nine locations listed in BD-045:       
  trinity files × 3, language skills × 2 (plus placeholder for future language skills), architecture-review
   skill extension, auditor-architecture agents × 3.                                                       
  - Explicitly cover both value-based and interface-based capability forms with language-agnostic wording
  in trinity files and language-appropriate wording in language skills.                                    
  - Add the "Branching on concrete types to discover what an abstraction supports" anti-pattern to all
  three trinity files in identical wording (trinity rule).                                                 
                                                                  
  **V9 lesson applied.** Lesson 3 (trinity rule validated per tool). The drafts must be identical in       
  semantics across CLAUDE.md / AGENTS.md / GEMINI.md, with only tool-specific framing differing where
  justified.                                                                                               
                                                                  
  **Design requirement applied.** Seamless BD integration — BD-045's content must not collide with or      
  contradict BD-046's x-prefix content additions to the same trinity files.
                                                                                                           
  **CDs confirmed.** CD-11 (already confirmed Step 1).                                                     
  **OQs resolved.** OQ-13.
                                                                                                           
  **Deliverable.** A section of V10-DESIGN.md titled "Design — BD-045 Capabilities Pattern" containing:    
  - Pattern definition (value-based and interface-based) with wording approved for copy-paste into trinity
  files.                                                                                                   
  - Per-language skill framing for apple-architecture-core, python-best-practices, and the rule for future
  language skills.                                                                                         
  - Architecture-review skill rule extensions (exact bullets).    
  - Auditor-architecture bullet extensions.                                                                
  - An explicit statement of the LSP-vs-capabilities relationship (per BACKLOG BD-045 language).           
                                                                                                           
  **Checkpoint gate.** **No** for the wording itself (review compounds at Step 11), **yes** for the pattern
   definition because downstream review skills (architecture-review, auditor-architecture) depend on stable
   wording. Developer approves the definition; the exact wording rolls forward.                            
                                                                  
  ---

  ### Block C — BD-046 structural decisions (prompt reorg first, then custom agents)                       
  
  The custom agent/skill mechanism (CD-1 through CD-7, CD-9) is structurally dependent on the prompt       
  template reorganization (CD-8), because CD-9 places custom agent prompts in the new `docs/pack/prompts/`
  directory. CD-8 also drives the largest migration complexity. Therefore CD-8 is settled first.           
                                                                  
  #### Step 4 — Token budget analysis and prompt template reorg design                                     
  
  **Actor.** pack-architect, assisted by pack-docs-researcher sub-agent for file-size checks.              
  **Session format.** Separate pack-architect session.            
  **Incremental inputs.**                                                                                  
  - `supporting-docs/PROMPT-TEMPLATES.md` (current 741-line monolith).
  - `project-template/docs/pack/PM-CHAT.md` (current file access strategy table).                          
  - `project-template/skills/pm-startup/SKILL.md` (what pm-startup currently reads).                       
  - Step 2 findings memo (file-size heuristics for each tool).                                             
                                                                                                           
  **Work.**                                                                                                
                                                                                                           
  1. **Token budget analysis (Part 9 procedure — concrete).**                                              
     - Measure the current `supporting-docs/PROMPT-TEMPLATES.md` token footprint. Method: use `wc -w` × 1.3
   as a rough proxy, or a local tokenizer if available. Record exact numbers.                              
     - Segment the file by agent and by PM chat internal use. Measure each segment. The segmentation
  corresponds to the directory proposed in CD-8 (coder.md, reviewer.md, …, pm-chat.md).                    
     - Compute: (a) current tokens read per PM chat startup (full file), (b) tokens per single prompt
  generation under the new directory model (one file), (c) net savings per prompt generation × estimated   
  generations per session, (d) one-time migration complexity cost (script, migration guide, per-project
  migration).                                                                                              
     - **Decision rule.** If per-session savings are ≥ ~30% of pm-startup's total file reads, the reorg is
  justified on efficiency grounds alone. If savings are ~10–30%, the reorg is justified only if it also    
  enables something structural (custom agent prompts under CD-9, which it does). If <10%, the reorg is
  justified only on structural grounds and the design doc must explicitly defend the complexity trade-off. 
     - Feed the conclusion into the CD-8 confirmation below.      
                                                                                                           
  2. **Confirm/change CD-8 (prompt reorganization).** Based on the token analysis and Step 2 access-pattern
   findings, confirm or revise the directory layout in CD-8.                                               
                                                                                                           
  3. **Resolve OQ-9 (directory naming and non-prompt content).** Decide between `docs/pack/prompts/`,      
  `docs/pack/templates/`, or a split (e.g., `docs/pack/prompts/` for agent-facing and retain PM chat
  operational templates elsewhere). Feed the decision into V10-DESIGN.md. Weigh: (a) naming clarity, (b)   
  migration churn, (c) CD-9 (custom prompt placement), (d) whether the PM chat operational templates —
  Templates 1, 8, 13, 14 — belong in the same tree at all.

  4. **Resolve OQ-11 (per-agent prompt file format).** Specify the concrete format:                        
     - Frontmatter presence and schema (if any): `name`, `description`, `agent`, `variants` list.
     - Heading structure for variants (e.g., `## Standard`, `## Fix Cycle`).                               
     - How the PM chat locates a variant: heading name, structured marker, or section anchor.              
     - Machine-parseable vs. free-form markdown.                                                           
     - The decision must be detailed enough that the migration script and the PM chat workflow can be      
  specified without re-opening the format question.                                                        
                                                                  
  5. **Resolve OQ-4 (pm-startup after reorg).** Decide whether pm-startup reads a manifest listing         
  available prompt files, derives the list by directory scan, or treats the directory as opaque and reads
  individual files only on demand. Record the decision and its impact on pm-startup's SKILL.md.            
                                                                  
  **V9 lessons applied.**                                                                                  
  - Lesson 1 (skills distribution design changed twice). Justify explicitly where each setup operation
  belongs (pm-startup reads manifest vs. scans directory; where the per-project prompt directory is        
  populated — at pack copy, at init-project.sh, at first PM chat run). Write the rationale, not just the
  choice.                                                                                                  
  - Lesson 4 (stale prescriptive guidance in design records). The reorg deprecates the monolithic
  PROMPT-TEMPLATES.md; the design doc must explicitly note which historical documents (including           
  V9-DESIGN.md Part 4 references to PROMPT-TEMPLATES.md) need updating.
                                                                                                           
  **Design requirements applied.**                                
  - Resource considerations (token budget is the direct proof).
  - Document access patterns (per-agent files are read on demand; pm-chat.md is read at startup).          
  - Best use of RAG (a small per-agent file can be direct-read; the current monolith's RAG justification is
   invalidated).                                                                                           
  - Maintenance considerations (per-agent files localize changes to one file per agent).                   
                                                                                                           
  **CDs confirmed/changed.** CD-8.                                                                         
  **OQs resolved.** OQ-4, OQ-9, OQ-11.                                                                     
                                                                                                           
  **Deliverable.** A section of V10-DESIGN.md titled "Design — Prompt Template Reorganization" containing: 
  the token analysis result, the confirmed/changed CD-8 layout, resolved OQ-9 (directory name), resolved
  OQ-11 (file format spec), resolved OQ-4 (pm-startup behavior).                                           
                                                                  
  **Checkpoint gate.** **Yes — cascading.** CD-8 directory and OQ-11 format feed Step 5 (custom prompts use
   the same format) and Step 6 (migration script must split the monolith by the same format). Developer
  explicitly approves before Step 5.                                                                       
                                                                  
  ---

  #### Step 5 — Custom agent and skill support design

  **Actor.** pack-architect.                                                                               
  **Session format.** Separate pack-architect session (new session, not a continuation of Step 4 — clean
  context).                                                                                                
  **Incremental inputs.**                                         
  - Step 2 findings (Codex config.toml, CLI skill loading, filename rules).                                
  - Step 4 approved deliverables (CD-8 directory, OQ-11 format).                                           
  - `project-template/docs/pack/PLATFORM-SKILLS.md` (current structure; where the `## Custom skills`       
  section will land).                                                                                      
  - `project-template/docs/pack/PM-CHAT.md` (current PM chat behavior; where custom-agent/skill workflow   
  will be added).                                                                                          
  - `supporting-docs/METHODOLOGY.md` (where Procedure 5 will be added).
  - `.github/workflows/validate-pack.yml` and any `validate-pack.py` script (to understand the pack roster 
  check).                                                                                                  
                                                                                                           
  **Work.**                                                                                                
                                                                  
  1. **Confirm/change CD-1 (x- prefix).** Verified against Step 2 findings that no CLI rejects an `x-` (or 
  `x_` for Codex) filename. Document any tool-specific deviation (e.g., Codex may need `x_<name>` in
  config.toml due to TOML key rules — Step 2 resolves this).                                               
  2. **Confirm/change CD-2 (custom files follow identical structure to pack files).**
  3. **Confirm/change CD-3 (PM chat as only creation mechanism) and resolve OQ-7 (manual creation escape   
  hatch).** Decide one of: (a) strict PM-chat-only with detect-and-offer-to-register as the de facto escape
   hatch; (b) documented manual path in METHODOLOGY.md with unsupported label; (c) both, with clear        
  precedence. Record the decision with rationale.                                                          
  4. **Confirm/change CD-4 (three creation paths — describe / one-tool-format / existing-file).** Write the
   PM chat workflow draft that feeds METHODOLOGY.md Procedure 5 at implementation time.                    
  5. **Confirm/change CD-6 (custom skills load same way) and CD-7 (PLATFORM-SKILLS.md `## Custom skills` 
  section).** Specify the exact header, column structure, and example row.                                 
  6. **Confirm/change CD-9 (custom agent prompts in prompts/ directory).** Verify compatibility with the
  Step 4 format decision — same frontmatter, same heading structure.                                       
  7. **Resolve OQ-1 (authoritative pack roster).** Decide among the three options listed in OQ-1:
     - Hardcoded list in PM-CHAT.md.                                                                       
     - Derived from PLATFORM-SKILLS.md agent rows.                                                         
     - New lightweight registry file (e.g., `project-template/docs/pack/AGENT-ROSTER.md` or equivalent).   
     - Document the drift/maintenance characteristics of the chosen option and which file is updated when a
   new pack agent is added.                                                                                
  8. **Resolve OQ-2 (Codex config.toml registration).** Using Step 2 facts, specify: how the PM chat       
  detects inconsistency between `.codex/agents/x-<name>.toml` presence and the `[agents.x_name]` entry in  
  `config.toml`; the repair procedure; whether this is part of the startup detection scan or a separate
  check.                                                                                                   
  9. **Resolve OQ-8 (x- prefix future collision).** Document the rule: "A future pack agent name must not
  collide with any extant x- prefixed customization pattern observed in shipped projects. The trinity rule 
  variant of this check is a pack-repo CI rule." Decide whether to actively reserve a namespace or just
  document the handling procedure if a collision ever occurs. Record the decision.                         
  10. **Detection workflow.** Specify the pm-startup and phase-gate detection scan precisely: which
  directories are scanned, how unknown files are classified (pack vs. x-custom vs. illegal), what actions  
  the PM chat takes for each class.
                                                                                                           
  **V9 lesson applied.** Lesson 3 (trinity rule validated per tool). Each of the three tool-native         
  mechanisms (Claude `.md` agents, Codex `.toml` + config.toml, Gemini `.md` with YAML frontmatter) must be
   specified on its own terms, not by analogy. Lesson 5 — ensure maintenance-docs references aren't        
  overlooked in the workflow specification.                       

  **Design requirements applied.**                                                                         
  - Automated and manual workflows (CD-3 + OQ-7 together define automation vs. manual boundary).
  - Maintenance considerations (single source of truth for pack roster per OQ-1).                          
  - PM chat tool flexibility (custom agent creation must work from Claude Desktop / Claude Code / Codex /  
  Gemini — verified against Step 2).                                                                       
  - Seamless BD integration (the CD-8 directory from Step 4 must house CD-9 custom prompt files cleanly).  
                                                                                                           
  **CDs confirmed/changed.** CD-1, CD-2, CD-3, CD-4, CD-6, CD-7, CD-9.                                     
  **OQs resolved.** OQ-1, OQ-2, OQ-7, OQ-8.                                                                
                                                                                                           
  **Deliverable.** A section of V10-DESIGN.md titled "Design — Custom Agent and Skill Support" containing: 
  x-prefix rule and collision policy; PM chat workflow (creation, detection, registration); pack roster
  mechanism; Codex config.toml consistency rule; PLATFORM-SKILLS.md `## Custom skills` section spec;       
  Procedure 5 outline for METHODOLOGY.md.                         

  **Checkpoint gate.** **Yes — cascading.** The custom-file mechanism feeds Step 6 migration preservation  
  and Step 7 init-project.sh behavior.
                                                                                                           
  ---                                                             

  ### Block D — Migration and initialization                                                               
   
  #### Step 6 — Migration design (v9.x → v10.0)                                                            
                                                                  
  **Actor.** pack-architect.                                                                               
  **Session format.** Separate session.                           
  **Incremental inputs.**
  - Step 4 and Step 5 approved deliverables.
  - `supporting-docs/MIGRATION-v8-to-v9.md` (as format reference for the new MIGRATION-v9-to-v10.md).      
  - V9.x post-release patch history (CHANGELOG.md entries for v9.1, v9.2, v9.3) — needed to understand what
   has shipped on top of v9.0 and must be preserved.                                                       
  - Current `supporting-docs/PROMPT-TEMPLATES.md` (specifically the BD-044 Step 8 phase-title linking      
  addition referenced in OQ-3, and any other v9.x-only content).                                           
                                                                  
  **Work.**                                                                                                
                                                                  
  1. **Confirm/change CD-5 (migration preserves x- prefixed files).** Specify preservation mechanism       
  precisely: temp-move-and-restore, in-place skip, or manifest-based. Name the directories scanned; name
  the failure modes (file exists on disk but is neither pack nor x-prefixed).                              
  2. **Confirm CD-13 (v9.x-only baseline).** Document the exact baseline (latest v9.x as of design approval
   date).                                                                                                  
  3. **Resolve OQ-3 (prompt template migration for existing projects).** Specify:
     - How the migration script detects that PROMPT-TEMPLATES.md has been customized (diff against pack    
  v9.x baseline at the version the project claims).                                                        
     - How v9.x incremental additions (e.g., Template 8 STATUS.md phase-title linking rule) are carried    
  forward into the new per-agent files. Either the split script understands the v9.x additions, or the     
  migration preserves a backup and the PM chat reconciles post-upgrade.
     - The backup-and-reconcile path is the default fallback — document it explicitly.                     
  4. **Rollback plan.** Design Requirement: every destructive operation creates a backup. Specify:         
  PROMPT-TEMPLATES.md → backup file; any file replaced by the prompt directory layout → backup. Document   
  the rollback procedure in the MIGRATION guide (what to copy back, what to remove, how to re-pin v9.x pack
   version).                                                                                               
  5. **Incremental testability.** Design Requirement: the migration must leave the pack in a working state
  at each stage. If the migration has multiple commits inside the project (prompt split, custom-file scan, 
  BD-045 content add), each commit must pass validate-pack.py's downstream analog (a project-level
  validation) and the project must still build.                                                            
                                                                  
  **V9 lesson applied.**
  - Lesson 1 — justify where each migration operation lives (in the script, in the guide-driven manual
  steps, or in the PM chat post-upgrade reconciliation). Avoid the "skills distribution changed twice"     
  pattern.
  - Lesson 4 — the MIGRATION guide is prescriptive and must be kept current if later v10.x work reverses   
  any decision.                                                                                            
   
  **Design requirements applied.** Rollback plan, incremental testability, seamless BD integration,        
  automated and manual workflows.                                 
                                                                                                           
  **CDs confirmed/changed.** CD-5, CD-13.                         
  **OQs resolved.** OQ-3.
                                                                                                           
  **Deliverable.** A section of V10-DESIGN.md titled "Design — Migration (v9.x → v10.0)" containing:       
  preservation mechanism spec; customization detection and preservation rules; rollback spec;              
  incremental-testability contract; outline of MIGRATION-v9-to-v10.md to be written in Phase 4.            
                                                                  
  **Checkpoint gate.** **Yes.** Migration design is a common source of failure — review before Step 7      
  depends on its shared detection logic.
                                                                                                           
  ---                                                             

  #### Step 7 — BD-044 init-project.sh and QUICKSTART router design                                        
   
  **Actor.** pack-architect. Runs **after** Step 6 because OQ-5 requires the migration script's detection  
  logic to be settled.                                            
  **Session format.** Separate session.                                                                    
  **Incremental inputs.**                                         
  - Step 6 approved deliverables.
  - `QUICKSTART.md` (current structure — will become the three-path router).
  - `supporting-docs/SETUP_TEMPLATE.md` (referenced from BD-044).                                          
  - `README.md` layout section (will be affected by new `scripts/init-project.sh`, new `SETUP-NEW.md`, new 
  `SETUP-EXISTING.md`).                                                                                    
  - Step 2 findings (for filesystem detection and language marker certainty).                              
                                                                                                           
  **Work.**                                                       
                                                                                                           
  1. **Confirm CD-10.**                                                                                    
  2. **Resolve OQ-5 (init-project.sh vs. migration script relationship).** Decide:
     - One script with mode flags, or two scripts with a shared detection library.                         
     - Where the shared detection lives (e.g., `scripts/lib/detect.sh` sourced by both).                   
     - Name placement and pack-repo path of each script.                                                   
  3. **Resolve OQ-12 (detection heuristics).** Specify precisely:                                          
     - What counts as "source files present" (language marker files, source-extension files, both;         
  recursion depth).                                                                                        
     - Handling of README-only / near-empty repos.                                                         
     - Monorepo detection (multiple language roots).                                                       
     - Platform-marker precedence when multiple are present.                                               
     - The detection output (a structured report the developer confirms before any write).                 
  4. **Preview-and-confirm flow.** Specify the exact report format and the confirmation prompt. Specify the
   stop condition when existing AI config (`.claude/`, `.codex/`, `.gemini/`, `CLAUDE.md`, `AGENTS.md`,    
  `GEMINI.md`) is detected.                                                                                
  5. **Existing-project path.** Selective copy rules; `.gitignore` merge; skip-list; end-of-run PM chat    
  prompt with existing-docs pointer (per BD-044 entry); the explicit "pack file names and locations are the
   new standard" message.
  6. **QUICKSTART.md as a three-path router.** Specify the new QUICKSTART.md structure: one short paragraph
   per path (new → SETUP-NEW.md, existing → SETUP-EXISTING.md, upgrade → MIGRATION-v9-to-v10.md), no       
  procedural content.
  7. **Migration guide naming convention.** Document `MIGRATION-vN-to-vM.md` + `supporting-docs/`          
  convention in a central location (to be chosen in the design doc: SETUP-NEW.md, SETUP-EXISTING.md, or    
  README.md).
                                                                                                           
  **V9 lesson applied.**                                          
  - Lesson 2 — any CLI-behavior assumption in init-project.sh (e.g., "Claude Code auto-loads skills after
  git clone") must be a Step 2 citation, not extrapolation. Re-invoke pack-docs-researcher (sub-agent) for 
  any gap.
  - Lesson 1 — explicitly justify why each operation runs in init-project.sh (once per project) vs.        
  bootstrap.sh (per-machine) vs. PM chat (one-time per project).                                           
   
  **Design requirements applied.** Automated and manual workflows; document access patterns (QUICKSTART.md 
  becomes a routing doc, not a procedural doc); PM chat tool flexibility (the end-of-run prompt must work
  on all four PM chat surfaces).                                                                           
                                                                  
  **CDs confirmed.** CD-10.                                                                                
  **OQs resolved.** OQ-5, OQ-12.
                                                                                                           
  **Deliverable.** A section of V10-DESIGN.md titled "Design — Project Initialization (BD-044)" containing:
   init-project.sh scope and shared-detection architecture; detection heuristic spec; preview-and-confirm
  flow; existing-project selective-copy rules; QUICKSTART.md three-path router spec;                       
  migration-guide-naming-convention location.                     

  **Checkpoint gate.** **Yes.**

  ---

  ### Block E — Cross-cutting consolidation

  #### Step 8 — Touch point inventory consolidation                                                        
   
  **Actor.** pack-planner.                                                                                 
  **Session format.** Sub-agent (Task tool) within the pack chat, because this is a mechanical audit over
  already-decided design content.                                                                          
  **Incremental inputs.**
  - All approved Step 3–7 deliverables.                                                                    
  - V10-PREDESIGN.md Part 4 (starting checklist).                 
  - `README.md` (layout section).                                                                          
  - `QUICKSTART.md`.
  - `maintenance-docs/V9-DESIGN.md` Parts 4 and 6 (lesson: maintenance-docs contain stale references that  
  must be updated).                                                                                        
                                                                                                           
  **Work.**                                                                                                
  - Rebuild the Part 4 "Touch point inventory" table from scratch. Every file mentioned in Steps 3–7 must
  appear. Cross-reference additions in docs (trinity rule: edits to `project-template/CLAUDE.md` must      
  appear in `AGENTS.md` and `GEMINI.md`; a change to pack-level `CLAUDE.md` rules must appear in pack-level
   `AGENTS.md` and `GEMINI.md` and in `PACK-AGENTS.md`).                                                   
  - Include stale-reference sweep targets: V9-DESIGN.md, V9-AUDIT-REPORT.md (if present), any
  maintenance-docs that reference PROMPT-TEMPLATES.md as a monolith.                                       
  - Include validate-pack.py / CI workflow updates required by the new file structure (roster check,
  x-prefix skip, per-agent prompt file frontmatter validation if chosen in OQ-11).                         
  - Tag each entry by BD (BD-044 / BD-045 / BD-046) and by actor (pack chat / init-project.sh / migration
  script / PM chat / developer). This tagging feeds the Phase 3 implementation planning session.           
                                                                  
  **V9 lessons applied.** Lesson 3 (trinity rule), Lesson 5 (maintenance-docs in audits).                  
                                                                  
  **Deliverable.** A section of V10-DESIGN.md titled "Touch Point Inventory" that supersedes               
  V10-PREDESIGN.md Part 4. Every row has: file path, change description, BD attribution, actor, and
  trinity-rule note if applicable.                                                                         
                                                                  
  **Checkpoint gate.** **No** (the Step 11 structural review and Step 12 pack-reviewer audit catch misses  
  here).
                                                                                                           
  ---                                                             

  #### Step 9 — Migration testing matrix                                                                   
   
  **Actor.** pack-planner.                                                                                 
  **Session format.** Sub-agent.                                  
  **Incremental inputs.**
  - All approved Step 3–7 deliverables.
  - V10-PREDESIGN.md Part 10 (dimensions).                                                                 
   
  **Work.**                                                                                                
  - Enumerate the Cartesian product of the four dimensions (project type × migration path × PM chat tool ×
  custom file state). Mark each cell as: **critical path** (must be tested in Phase 4), **spot check** (one
   representative case tested), **deferred** (documented but not tested), or **out of scope** (documented
  with rationale).                                                                                         
  - Critical-path defaults per Design Requirement "PM chat tool flexibility": at least one cell per PM chat
   tool (Claude Code, Claude Desktop, Codex, Gemini) is critical-path. At least one cell per BD scope      
  (custom agent created, custom skill created, init-project.sh new, init-project.sh existing, migration
  v9.x→v10) is critical-path.                                                                              
  - Cross-reference each critical-path cell to a specific verification test in Step 10.
                                                                                                           
  **Design requirement applied.** PM chat tool flexibility.
                                                                                                           
  **Deliverable.** A section of V10-DESIGN.md titled "Migration Testing Matrix" with the fully labeled     
  matrix.
                                                                                                           
  **Checkpoint gate.** **No.**                                    

  ---

  #### Step 10 — Verification plan (OQ-14)                                                                 
   
  **Actor.** pack-planner.                                                                                 
  **Session format.** Sub-agent.                                  
  **Incremental inputs.**
  - Step 8 touch point inventory (what changed).                                                           
  - Step 9 testing matrix (which combinations).                                                            
  - `maintenance-docs/V9-AUDIT-REPORT.md` if it exists (format reference).                                 
  - `.github/workflows/validate-pack.yml`.                                                                 
                                                                  
  **Work.**                                                                                                
                                                                  
  1. **CI validation.** Specify every validate-pack.py / workflow update required:                         
     - Skip x-prefixed files in roster checks.
     - Validate per-agent prompt file frontmatter (if OQ-11 chose a schema).                               
     - Verify PLATFORM-SKILLS.md `## Custom skills` section exists in pack template.                       
     - Cross-tool parity for new files (trinity rule on CLAUDE.md/AGENTS.md/GEMINI.md additions).          
  2. **Manual testing scripts.** One item per critical-path cell from Step 9.                              
  3. **PM chat workflow testing.** Scripted scenarios for: custom agent creation (each of CD-4's three     
  paths), custom skill creation, manual-add detection, registration repair, Codex config.toml consistency. 
  4. **Prompt template migration correctness.** Before/after token count match; every Template 1–14        
  accounted for in the new files; no lost content; v9.x additions carried forward.                         
  5. **x- file preservation.** Simulated upgrade on a test project containing x- agents and skills; verify
  all survive.                                                                                             
  6. **BD-045 content review.** Trinity-rule diff on CLAUDE.md/AGENTS.md/GEMINI.md; language-agnostic
  review of anti-pattern wording.                                                                          
  7. **Rollback rehearsal.** Execute the MIGRATION rollback on a real v9.x→v10→rollback round trip.
                                                                                                           
  **V9 lessons applied.**                                         
  - Lesson 4 — the verification plan is prescriptive and must be kept current. Include a rule: "If any V10 
  design decision is reversed in a v10.x patch, update this verification plan, not only the operational    
  docs."
  - Lesson 5 — audits explicitly include maintenance-docs.                                                 
                                                                                                           
  **Design requirement applied.** Incremental testability.
                                                                                                           
  **OQs resolved.** OQ-14.                                        

  **Deliverable.** A section of V10-DESIGN.md titled "Verification Plan" containing CI updates, manual     
  tests, PM chat workflow tests, prompt-migration tests, preservation tests, content reviews, and rollback
  rehearsal.                                                                                               
                                                                  
  **Checkpoint gate.** **No.**                                                                             
   
  ---                                                                                                      
                                                                  
  ### Block F — Consolidation, review, approval                                                            
   
  #### Step 11 — V10-DESIGN.md assembly and structural review                                              
                                                                  
  **Actor.** pack-architect (assembly) + pack-chat (writing the file).                                     
  **Session format.** Pack chat session, with pack-architect sub-agent for coherence questions.
  **Incremental inputs.** All prior deliverables.                                                          
                                                                                                           
  **Work.**                                                                                                
  1. Assemble V10-DESIGN.md using V9-DESIGN.md as the structural reference. The recommended structure:     
     - Part 0 — Status header (approved, date, author, approval record).                                   
     - Part 1 — Why v10 exists (lift from V10-PREDESIGN Part 1, edit for current tense).                   
     - Part 2 — Approved Decisions (the former CDs, now AD-1 through AD-13 or renumbered; each with        
  rationale and rejected alternatives as in V9-DESIGN Decisions 1–9).                                      
     - Part 3 — Design — BD-045 Capabilities Pattern (Step 3 deliverable).                                 
     - Part 4 — Design — Prompt Template Reorganization (Step 4 deliverable, including token budget        
  analysis).                                                                                               
     - Part 5 — Design — Custom Agent and Skill Support (Step 5 deliverable).                              
     - Part 6 — Design — Migration (v9.x → v10.0) (Step 6 deliverable).                                    
     - Part 7 — Design — Project Initialization / BD-044 (Step 7 deliverable).                             
     - Part 8 — Touch Point Inventory (Step 8 deliverable).                                                
     - Part 9 — Migration Testing Matrix (Step 9 deliverable).                                             
     - Part 10 — Verification Plan (Step 10 deliverable).                                                  
     - Part 11 — V9 Lessons Carried Forward (explicit map of Lessons 1–5 to V10 design sections — closes
  Part 8 of the predesign).                                                                                
     - Part 12 — Implementation Sequence Outline (intentionally thin — Phase 3 produces the detailed plan;
  this part lists the top-level ordering implied by OQ-10 and this design pass).                           
     - Part 13 — Open Items Deferred (any OQ that the design pass could not fully resolve, with rationale
  and fallback).                                                                                           
                                                                  
  2. **Structural review (pack-architect).** Confirm:                                                      
     - Every CD from V10-PREDESIGN.md Part 2 is present in Part 2 of V10-DESIGN.md.
     - Every OQ from V10-PREDESIGN.md Part 3 is either resolved somewhere in Parts 3–10 or listed in Part  
  13 with rationale.                                                                                       
     - Every Design Requirement from V10-PREDESIGN.md Part 7 is explicitly addressed — produce a           
  requirement-to-section cross-reference as an appendix.                                                   
     - BD-044, BD-045, BD-046 each have a dedicated design section and the integration points between them
  are explicit (seamless BD integration requirement).                                                      
     - Trinity rule compliance on every location that touches trinity files.
                                                                                                           
  **V9 lessons applied.** All five, in the cross-reference appendix.                                       
                                                                                                           
  **Deliverable.** Draft V10-DESIGN.md on disk at `maintenance-docs/V10-DESIGN.md` (status header: **DRAFT 
  — PENDING REVIEW**). V10-PREDESIGN.md is not yet modified.      
                                                                                                           
  **Checkpoint gate.** **Yes.** Developer reads the assembled draft.                                       
  
  ---                                                                                                      
                                                                  
  #### Step 12 — pack-reviewer independent audit                                                           
   
  **Actor.** pack-reviewer.                                                                                
  **Session format.** Separate session (explicitly independent — "review that should not be influenced by
  the pack chat's prior context," per PACK-AGENTS.md).                                                     
  **Incremental inputs.**
  - The Step 11 draft V10-DESIGN.md.                                                                       
  - V10-PREDESIGN.md (for completeness check).                                                             
  - `maintenance-docs/V9-DESIGN.md` and `V9-AUDIT-REPORT.md` if it exists (for format and stale-reference
  patterns).                                                                                               
  - Files referenced in Step 8 touch point inventory (for stale-reference sweeps).
                                                                                                           
  **Work.** Audit checklist:                                                                               
  - **Trinity rule.** Every trinity-file edit is symmetric.                                                
  - **Stale references.** V9-DESIGN.md, PROMPT-TEMPLATES.md references anywhere in the pack, QUICKSTART.md 
  references in shipped docs — every one is either accurate under v10 or flagged for update.               
  - **CI alignment.** Every design decision that changes file structure has a corresponding                
  validate-pack.py change listed in Part 10.                                                               
  - **Doc consistency.** BD-044 / BD-045 / BD-046 descriptions are consistent between V10-DESIGN.md and
  BACKLOG.md.                                                                                              
  - **Lesson compliance.** Each V9 lesson is applied, not just listed.
  - **Completeness.** Every CD confirmed or changed; every OQ resolved or deferred with rationale.         
                                                                                                           
  **V9 lessons applied.** All five, most notably Lesson 5 (maintenance-docs included in audit scope).      
                                                                                                           
  **Deliverable.** A review report listing findings by severity (Critical / Functional / Polish, matching  
  the audit-methodology skill's scale). Findings feed a fix pass back through Step 11 if needed.
                                                                                                           
  **Checkpoint gate.** **Yes — final review gate.** Any Critical finding goes back to pack-architect       
  (re-enter the relevant Block B–D step). Functional findings are fixed inline. Polish findings can roll to
   v10.x.                                                                                                  
                                                                  
  ---

  #### Step 13 — Final approval and V10-PREDESIGN.md supersession                                          
   
  **Actor.** Pack chat + developer.                                                                        
  **Session format.** Pack chat.                                  
  **Incremental inputs.** Reviewed V10-DESIGN.md, V10-PREDESIGN.md.                                        
                                                                                                           
  **Work.**                                                                                                
  1. Apply any fix-pass outcomes from Step 12.                                                             
  2. Update the Step 11 status header from **DRAFT — PENDING REVIEW** to **APPROVED**, with date and       
  developer-name approval record.                                                                          
  3. Update V10-PREDESIGN.md:                                                                              
     - Replace the top-of-file banner with a supersession notice pointing to V10-DESIGN.md.                
     - Leave the body as a historical record (per Lesson 4 — do not mutate historical records silently, but
   do annotate).                                                                                           
  4. Update `BACKLOG.md`: BD-046 blocker "Design approval pass required" is resolved; BD-045 blocker       
  referencing the design approval pass is resolved; BD-044, BD-045, BD-046 become ready for Phase 3        
  implementation planning.                                        
  5. Update the top of `BACKLOG.md` or the V10-DESIGN.md status header with the approval date (no version  
  table change yet — v10.0 ships at Phase 4).                                                              
  6. Commit the approved V10-DESIGN.md and updated V10-PREDESIGN.md + BACKLOG.md in a single commit
  following pack commit format: `docs: v9 — V10-DESIGN.md approved; supersedes V10-PREDESIGN.md`. (Version 
  prefix remains v9 since v10 has not shipped.)                   
                                                                                                           
  **Checkpoint gate.** **Yes — commit approval, per CLAUDE.md and PACK-CHAT.md rules.** Developer reviews  
  `git status` and explicitly approves before commit.
                                                                                                           
  **Exit condition.** Phase 1 is complete. Phase 3 (implementation planning) can start in a new session.   
   
  ---                                                                                                      
                                                                  
  ## 4. Commit plan (for this design phase)                                                                
   
  This plan produces documentation only. No code changes. Commit sequence, in order:                       
                                                                  
  1. *(optional)* At end of Step 1 — a scope-confirmation note appended to V10-PREDESIGN.md (or committed  
  as a brief): `docs: v9 — V10 scope confirmed (CD-10/11/12/13, OQ-10)`.
  2. At end of Step 13 — `docs: v9 — V10-DESIGN.md approved; supersedes V10-PREDESIGN.md` containing:      
     - `maintenance-docs/V10-DESIGN.md` (new, status APPROVED).                                            
     - `maintenance-docs/V10-PREDESIGN.md` (banner updated to supersession notice).                        
     - `BACKLOG.md` (BD-044, BD-045, BD-046 blockers cleared).                                             
                                                                                                           
  No intermediate commits are required by the plan. Intermediate working drafts can be committed at        
  developer discretion; each must leave the pack in a state where `Validate Pack` passes (CLAUDE.md rule). 
                                                                                                           
  ---                                                             

  ## 5. Checkpoint gates summary                                                                           
   
  Points where the developer explicitly approves before the workflow continues:                            
                                                                  
  | Gate | After step | Why — what cascades if wrong |                                                     
  |---|---|---|                                                   
  | G1 | Step 1 | Scope and BD sequencing; everything downstream reorders or scopes differently |          
  | G2 | Step 2 | CLI facts; Lesson 2 prevention — design decisions built on wrong facts |                 
  | G3 | Step 3 | BD-045 pattern definition (not wording); architecture-review and auditor-architecture    
  depend on stable definition |                                                                            
  | G4 | Step 4 | CD-8 directory + OQ-11 format; Steps 5 and 6 build on them |                             
  | G5 | Step 5 | Custom-file mechanism; Step 6 migration and Step 7 init both consume it |                
  | G6 | Step 6 | Migration design; Step 7 shares detection logic |                                        
  | G7 | Step 7 | BD-044 design |                                                                          
  | G8 | Step 11 | Assembled V10-DESIGN.md draft |                                                         
  | G9 | Step 12 | pack-reviewer report resolution |                                                       
  | G10 | Step 13 | Commit approval |                                                                      
                                                                                                           
  ---                                                                                                      
                                                                  
  ## 6. Cross-reference matrix — every V10-PREDESIGN artifact to its resolution step                       
   
  ### Candidate Decisions (Part 2)                                                                         
                                                                  
  | CD | Step resolving |                                                                                  
  |---|---|                                                       
  | CD-1 (x- prefix) | Step 5 (after Step 2 verifies no CLI filename collision) |
  | CD-2 (identical structure) | Step 5 |                                                                  
  | CD-3 (PM chat as only creation) | Step 5 (paired with OQ-7) |                                          
  | CD-4 (three creation paths) | Step 5 |                                                                 
  | CD-5 (migration preserves x- files) | Step 6 |                                                         
  | CD-6 (custom skills load same way) | Step 5 (after Step 2 verifies skill loading per tool) |           
  | CD-7 (PLATFORM-SKILLS.md `## Custom skills` section) | Step 5 |                                        
  | CD-8 (prompt reorg) | Step 4 (after token budget analysis) |                                           
  | CD-9 (custom prompts in prompts/ dir) | Step 5 (uses Step 4 format) |                                  
  | CD-10 (BD-044 in v10) | Step 1 |                                                                       
  | CD-11 (BD-045 in v10) | Step 1 |                                                                       
  | CD-12 (v10.0 target) | Step 1 |                                                                        
  | CD-13 (v9.x baseline only) | Step 1 / Step 6 |                                                         
                                                                                                           
  ### Open Questions (Part 3)                                                                              
                                                                                                           
  | OQ | Step resolving | Depends on |                            
  |---|---|---|
  | OQ-1 (authoritative pack roster) | Step 5 | CD-1, CD-3 |
  | OQ-2 (Codex config.toml) | Step 5 | Step 2 findings, CD-1 |                                            
  | OQ-3 (prompt template migration) | Step 6 | CD-8 (Step 4), CD-13 |                                     
  | OQ-4 (pm-startup after reorg) | Step 4 | CD-8, OQ-11 |                                                 
  | OQ-5 (init-project.sh vs migration script) | Step 7 | CD-5 (Step 6), CD-10 |                           
  | OQ-6 (design approval process) | Step 1 | This plan itself |                                           
  | OQ-7 (manual escape hatch) | Step 5 | CD-3 |                                                           
  | OQ-8 (x- prefix collision) | Step 5 | CD-1, CD-5 |                                                     
  | OQ-9 (prompts/ directory naming) | Step 4 | CD-8 |                                                     
  | OQ-10 (BD sequencing) | Step 1 | CD-10, CD-11 |                                                        
  | OQ-11 (per-agent prompt file format) | Step 4 | CD-8, OQ-9 |                                           
  | OQ-12 (init-project.sh detection heuristics) | Step 7 | CD-10, Step 2 findings |                       
  | OQ-13 (capabilities pattern content) | Step 3 | CD-11 |                                                
  | OQ-14 (verification plan) | Step 10 | All Block B–D steps |                                            
                                                                                                           
  ### Design Requirements (Part 7)                                                                         
                                                                                                           
  | Requirement | Steps addressing it |                                                                    
  |---|---|
  | Automated and manual workflows | Step 5 (PM chat workflow + manual escape hatch); Step 7               
  (init-project.sh + developer preview/confirm) |                                                          
  | Resource considerations | Step 4 (token budget analysis); Step 5 (pack roster file sizing) |
  | Maintenance considerations | Step 5 (single source of truth for pack roster); Step 6 (migration of v9.x
   customizations) |                                                                                       
  | Document access patterns | Step 4 (per-agent on-demand reads); Step 5 (PLATFORM-SKILLS.md at startup); 
  Step 7 (QUICKSTART.md as router vs. procedure) |                                                         
  | Best use of RAG | Step 4 (directly informed by the analysis) |
  | PM Chat tool flexibility | Step 2 (per-tool verification); Step 5 (four-surface CD-4 workflow); Step 9 
  (test matrix per tool) |                                                                                 
  | Seamless BD integration | Step 11 (structural review); Steps 4/5/6/7 each explicitly reference the     
  others' outputs |                                                                                        
  | Rollback plan | Step 6 |                                      
  | Incremental testability | Step 6; Step 10 |                                                            
                                                                                                           
  ### V9 Lessons (Part 8)
                                                                                                           
  | Lesson | Steps applying it |                                                                           
  |---|---|
  | L1 — skills distribution changed twice | Step 4 (justify pm-startup behavior); Step 6 (justify each    
  migration operation's location); Step 7 (justify init-project.sh vs bootstrap vs PM chat) |              
  | L2 — Gemini CLI misunderstanding | Step 2 (mandatory verification pass before design-level decisions
  depend on CLI behavior); re-invoked sub-agent calls throughout if a gap surfaces |                       
  | L3 — GEMINI.md trinity violation from incomplete spec | Step 3 (BD-045 content trinity check); Step 5
  (three tool-native custom-agent mechanisms spec'd independently); Step 11 (trinity-rule check in         
  structural review) |                                            
  | L4 — V9-DESIGN.md verification checklist became stale | Step 10 (rule about keeping the verification   
  plan current on v10.x reversals); Step 13 (V10-PREDESIGN.md supersession banner, not silent deletion) |  
  | L5 — maintenance-docs stale refs missed in audits | Step 8 (inventory includes maintenance-docs); Step
  12 (pack-reviewer audit scope explicitly includes maintenance-docs) |                                    
                                                                  
  ### Part 9 (token budget) and Part 10 (testing matrix)                                                   
                                                                  
  - **Token budget analysis (Part 9).** Procedure defined in Step 4. Measurement method, decision rule, and
   feed into CD-8 confirmation all specified.                     
  - **Migration testing matrix (Part 10).** Defined in Step 9. Produced after all structural decisions     
  (Steps 3–7) are approved; referenced by Step 10 verification plan.                                       
   
  ### Part 11 (pack development agents and skills)                                                         
                                                                  
  The pack-architect, pack-planner, pack-reviewer, and pack-docs-researcher agents created pre-v10 are     
  consumed by this plan, one per step (see actor column). Their existence is the enabling condition for the
   separated-session design — without them, the whole plan would collapse back into pack chat.             
                                                                  
  ---

  ## 7. Risks and open items for this plan itself                                                          
   
  - **Risk — Step 2 findings contradict CD-1 or CD-6.** If any CLI rejects an `x-` filename or cannot      
  locate a skill with that prefix, CD-1 must change. Mitigation: Step 2 is explicitly a checkpoint gate.
  - **Risk — token budget analysis in Step 4 shows CD-8 savings are marginal.** Per the decision rule, the 
  reorg then stands only on structural grounds (CD-9 custom prompt placement). The design doc must defend  
  the complexity trade-off. Mitigation: rule is explicit in Step 4; this is a decision point, not a
  blocker.                                                                                                 
  - **Risk — OQ-1 pack roster decision drifts.** Whatever mechanism is chosen (hardcoded list / derived /
  registry file), Phase 4 must include the CI check that prevents drift. Mitigation: Step 10 verification  
  plan requires it.
  - **Risk — Phase 3 implementation planning reveals missing design detail.** The phase boundary (Phase 2  
  ends here) is deliberate, but some gaps surface only at planning time. Mitigation: V10-DESIGN.md Part 13 
  ("Open Items Deferred") is the recognized channel; if Phase 3 requires reopening, re-enter this plan at
  the appropriate step.                                                                                    
  - **Risk — BD-044 scope creep.** BD-044 describes "selective copy" and "existing-project onboarding" with
   many edge cases (monorepos, Kotlin / Android detection, existing PM docs). Mitigation: Step 7 resolves  
  OQ-12 with explicit heuristic rules and scope cutoffs; edges not covered are documented in V10-DESIGN.md
  Part 13 with a v10.x or v11 deferral.                                                                    
  - **Unknown — number of v9.x incremental PROMPT-TEMPLATES.md additions that must be carried forward in 
  OQ-3.** The predesign names one concrete example (Template 8 phase-title linking). There may be more.    
  Mitigation: Step 6 input list includes v9.1/v9.2/v9.3 CHANGELOG entries; the pack-architect produces an
  exhaustive list.                                                                                         
  - **Risk — trinity-file collision.** Both BD-045 (capabilities section) and BD-046 (custom agent /
  x-prefix rule) add content to trinity files. Ordering in the files and commit sequencing must not leave  
  one BD's edits half-present. Mitigation: Step 11 structural review; Step 8 touch point inventory tags
  each row by BD.                                                                                          
                                                                  
  ---

  ## 8. Exit criteria recap                                                                                
   
  Phase 1 is complete when all of the following are true:                                                  
                                                                  
  1. `maintenance-docs/V10-DESIGN.md` exists with status **APPROVED** and a dated approval record.         
  2. `maintenance-docs/V10-PREDESIGN.md` has a supersession banner pointing to V10-DESIGN.md.
  3. Every CD from V10-PREDESIGN Part 2 is explicitly confirmed or changed in V10-DESIGN.md Part 2.        
  4. Every OQ from V10-PREDESIGN Part 3 is either resolved in V10-DESIGN.md or listed in V10-DESIGN.md Part
   13 with rationale.                                                                                      
  5. Every Design Requirement from V10-PREDESIGN Part 7 has a named home in V10-DESIGN.md.                 
  6. The Part 8 lessons are mapped to V10-DESIGN.md sections via an explicit appendix.                     
  7. `BACKLOG.md` reflects the cleared blockers on BD-044, BD-045, BD-046.                                 
  8. The approval commit has passed the `Validate Pack` CI workflow.                                       
  9. Phase 3 (implementation planning) can be started in a new session with V10-DESIGN.md as the sole input
   — the plan does not require reconstructing any context from this or prior conversations.                
                                                                                                           
  ---                                                                                                      
                                                                  
  *End of V10 Design Process Plan.*
