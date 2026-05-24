# Research — Product Specialist Landscape

**Date:** 2026-05-24
**Author:** pack-docs-researcher (sidecar session, BD-186 follow-up)
**Repo:** optiquity-ai-agent-config-pack-v11-dev @ HEAD 553ab886
**Status:** Read-only landscape research. Descriptive, not prescriptive.

---

## Purpose

Provide a landscape view of the product-management tool/methodology ecosystem so that downstream requirements-gathering for the pack's Product Specialist (PS) feature is informed rather than speculative. The PS feature is a CLIENT-SIDE addition (project-template/ surface only) intended to help developers think through product strategy, write PRDs, do user-journey mapping, and integrate with existing pack primitives. Shape (agent, skill, hybrid) and design are TBD; this document does NOT propose either.

## Scope boundaries

- IN scope: Existing tools (open-source and commercial), methodologies/frameworks with documented authorship and origin, PRD template canon, customer-discovery interview frameworks, AI/LLM-assisted PM tooling state of the art, dev-tool integration patterns.
- OUT of scope: Pack design decisions. Specific tool recommendations for the pack. Engineering integration design.

## Quality filter

Throughout this document, entries are graded with one of:
- **Mainstream** — widely adopted, multiple primary sources, taught in MBA/PM programs or used by Fortune 500 product orgs.
- **Established** — author-attributed, published book/article, real practitioner adoption (not a single blog post).
- **Niche** — real but small community, useful in narrow contexts.
- **Controversial** — established but contested within the field; see notes.
- **Vapor risk** — entries (especially AI tools) where claims outpace track record; flagged explicitly.

Niche / controversial / vapor entries are listed so the reader can weight them; they are not endorsements.

---

## Section index

- §1 — Open-source PM/product-discovery tools (SC1)
- §2 — Professional products (SC2)
- §3 — Methodologies + frameworks (SC3)
- §4 — PRD templates + structures (SC4)
- §5 — Interview / customer-discovery frameworks (SC5)
- §6 — AI/LLM-assisted product tooling (SC6)
- §7 — Dev-tool integration patterns (SC7)
- §8 — Cross-category synthesis (SC10)
- §9 — Pack-relevance observations (SC11)
- §10 — Sources + dates (SC9, SC12)

---

## §1 — Open-source PM/product-discovery tools

This category is THIN compared to the commercial space — most serious PM tooling is commercial SaaS. Open-source coverage clusters around (a) generic project-management tools with roadmap modules, and (b) recent AI-PRD generators that lean on hosted LLMs.

### §1.1 — OpenProject

- **Repo:** https://github.com/opf/openproject
- **License:** GPLv3 (Community Edition), commercial Enterprise tier available.
- **Grade:** Mainstream (open-source PM space).
- **What it does:** Full project-management suite with a Roadmap module, version boards for backlog prioritization, scrum/kanban boards, Gantt, time tracking, meetings, forums. Self-hostable.
- **Strengths:** Mature (in development since 2012), German company sponsorship, enterprise track record (used by public institutions and Fortune 500). Real PRD-adjacent surfaces (wiki, requirements documentation).
- **Limitations:** Heavyweight for solo developers or small teams. Roadmap UX is dated relative to commercial peers. No native AI-assisted PRD generation.
- **Popularity signals:** ~8.5k GitHub stars (mid-2026), ~250 contributors, active commits.
- **Source:** https://www.openproject.org/roadmap/

### §1.2 — Taiga

- **Repo:** https://github.com/taigaio/taiga-back (backend), https://github.com/taigaio/taiga-front (frontend)
- **License:** AGPLv3.
- **Grade:** Established.
- **What it does:** Open-source agile project management for Scrum/Kanban teams. Backlog, sprint planning, user stories, epics, kanban boards with WIP limits, basic roadmap visualization.
- **Strengths:** Clean UX, faithful agile-methodology implementation, US/EU community.
- **Limitations:** Less strategic-level surface area than OpenProject; better as engineering-execution tool than product-discovery tool. No AI features.
- **Popularity signals:** ~6k GitHub stars on the main repo, multi-year maintenance.
- **Source:** https://taiga.io/

### §1.3 — Plane

- **Repo:** https://github.com/makeplane/plane
- **License:** AGPLv3.
- **Grade:** Established (newer, rising).
- **What it does:** Modern open-source Jira alternative; cycles (sprints), modules (epics), pages (Notion-like docs), views, issues. Self-hostable; cloud version available.
- **Strengths:** Modern UX, growing community, active development (~30k+ GitHub stars as of mid-2026), strong Notion-esque docs primitive that's usable for PRDs.
- **Limitations:** Younger codebase, fewer integrations than OpenProject, AGPLv3 may limit enterprise adoption.
- **Source:** https://plane.so/

### §1.4 — Quackback

- **Repo:** https://github.com/QuackbackIO/quackback
- **License:** Open-source (MIT per repo).
- **Grade:** Niche.
- **What it does:** Open-source alternative to Canny / UserVoice / Productboard. Customer-feedback aggregation, voting, roadmap-publishing.
- **Strengths:** Fills a real gap (the feedback-aggregation space is otherwise commercial-only).
- **Limitations:** Small community, early-stage. Not a substitute for Productboard's analysis depth.

### §1.5 — Open-source AI PRD generators (cluster)

This is an emerging cluster (2024-2026); none have achieved dominant adoption, and the space has high vapor risk. Representative entries:

- **prd-creator** (https://github.com/AungMyoKyaw/prd-creator) — Gemini-backed 3-step wizard. Quality grade: Niche; useful as a reference implementation, not a polished product.
- **prd-generator (PRD Master)** (https://github.com/Sikandar-irfan/prd-generator) — Multi-LLM CLI via OpenRouter. Niche.
- **ai-prd-generator** (https://github.com/cdeust/ai-prd-generator) — Claude Code / Cowork plugin, multi-LLM verification. Niche, recent.
- **agentic_prd** (https://github.com/nanagajui/agentic_prd) — Agentic PRD for "agentic coding systems." Niche, experimental.
- **PRD-MCP-Server** (https://github.com/Saml1211/PRD-MCP-Server) — MCP server for PRD generation from codebase context. Niche, MCP-adjacent.
- **agentic-prd-generation** (https://github.com/SeeknnDestroy/agentic-prd-generation) — Alpha-stage MVP. Niche/experimental.

**Honest assessment:** The open-source AI-PRD-generator cluster is mostly side projects and demos. None have substantial enterprise adoption (validated via low-to-modest GitHub stars and limited issue-tracker activity). The collective signal: PRD generation is interesting enough that many developers are trying it; no canonical open-source winner has emerged. Likely because the value of a PRD is more about the conversation/thinking than the generated artifact (a point echoed in the methodologies in §3 and §5).

### §1.6 — Considered and rejected

- **Trac, Redmine** — Legacy open-source PM tools; effectively maintenance mode for product-discovery purposes. Mentioned for completeness; not substantive entries.
- **Various Markdown-based "second brain" tools** (Obsidian-PARA-template style) — File-organization conventions, not PM tools. Out of scope.

---

## §2 — Professional products (paid + free)

The commercial PM-tool space is large, well-documented, and stratified by team size, methodology preference, and integration depth. Sources: vendor sites and 2026 comparison reports.

### §2.1 — Productboard

- **URL:** https://www.productboard.com/
- **Grade:** Mainstream (one of the top three commercial PM tools).
- **Pricing (2026):** Essentials ~$20-25/maker/mo; Pro ~$70/maker/mo; Scale ~$120/maker/mo; Enterprise custom. Top-tier deployments quoted at $70k-$100k/yr per recent comparisons.
- **Core features:** Customer-feedback aggregation (insights inbox), feature prioritization (multiple scoring frameworks including RICE), roadmap views, portal for public roadmaps, deep Jira / GitHub / Linear / Azure DevOps two-way sync.
- **Strengths:** Best-in-class feedback intelligence (the "insights" layer is the differentiator). Strong Jira integration. Productboard AI (2025-2026) added LLM-assisted insight clustering.
- **Limitations:** Expensive at scale. Learning curve. Some workflows opinionated in ways that don't fit all teams.
- **Target user:** Mid-to-large product orgs with mature customer-feedback intake.
- **Sources:** https://www.productboard.com/integrations/jira/, https://www.featurebase.app/blog/aha-vs-productboard

### §2.2 — Aha!

- **URL:** https://www.aha.io/
- **Grade:** Mainstream.
- **Pricing (2026):** Aha! Roadmaps from $59/user/mo; Aha! Ideas separate ($39/user/mo); Aha! Develop separate. Often bundled.
- **Core features:** Strategy (vision, goals, initiatives), roadmaps (multiple types including Gantt, timeline, swimlane), idea management, release management, two-way Jira integration with custom-field sync.
- **Strengths:** Enterprise-grade. Strong strategy-to-execution traceability (vision → initiative → epic → feature → Jira issue). OKR alignment surfaces. Extensive customization.
- **Limitations:** Heavyweight setup, expensive, can feel overwhelming for smaller teams. Multiple SKUs add complexity.
- **Target user:** Enterprise product orgs with strategic-planning rigor.
- **Sources:** https://www.aha.io/product/integrations/github, https://www.aha.io/blog/just-launched-two-way-jira-integration-now-supports-custom-fields

### §2.3 — ProductPlan

- **URL:** https://www.productplan.com/
- **Grade:** Mainstream.
- **Pricing (2026):** Basic ~$39/user/mo (annual); Professional ~$69/user/mo; Enterprise custom.
- **Core features:** Visual roadmap builder (timeline / lanes / list views), drag-and-drop prioritization, RICE and other scoring frameworks, Jira integration (one-way and two-way variants).
- **Strengths:** Best-in-class visual roadmap UX. Approachable for non-PM stakeholders. High user-satisfaction ratings (~4.3/5 across 4000+ reviews).
- **Limitations:** Lighter on discovery/feedback features than Productboard. Less strategy depth than Aha!.
- **Target user:** Mid-size product teams emphasizing roadmap communication.
- **Source:** https://www.productplan.com/glossary/rice-scoring-model

### §2.4 — Roadmunk

- **URL:** https://roadmunk.com/
- **Grade:** Established.
- **Pricing (2026):** From $19/mo (smallest tier); team plans $49+/user/mo; Enterprise custom.
- **Core features:** Visual roadmaps (timeline + swimlane), idea-management voting, RICE scoring, basic Jira integration.
- **Strengths:** Lower price point than the top three. Visually polished roadmaps.
- **Limitations:** Smaller feature set; some users have raised concerns about long-term roadmap (was acquired by Tempo in 2023). Less integration depth.
- **Target user:** Smaller teams wanting roadmap visualization without heavyweight commitment.

### §2.5 — Linear

- **URL:** https://linear.app/
- **Grade:** Mainstream (engineering-issue-tracking primary, product-management secondary).
- **Pricing (2026):** Free tier (up to 250 issues); Standard $8/user/mo; Plus $14/user/mo; Enterprise custom.
- **Core features:** Issue tracking, cycles (sprints), projects, documents (Notion-like), roadmap view, GitHub two-way sync with PR-status auto-updates, Linear Agent (LLM, 2025+) understanding roadmap/issues/code.
- **Strengths:** Best-in-class engineering issue UX. Speed. The "Linear Method" handbook codifies opinionated practices (e.g., "write issues, not user stories"). Documents primitive doubles as PRD surface for many teams. Linear Agent narrows the AI-PM gap.
- **Limitations:** Engineering-first DNA; lighter on customer-feedback intake and strategic roadmapping than Aha!/Productboard. Some PM workflows (e.g., voting, portal-based feedback) absent.
- **Target user:** Engineering-led product teams; startups and scale-ups.
- **Source:** https://linear.app/method, https://linear.app/docs/github-integration

### §2.6 — Jira (Atlassian)

- **URL:** https://www.atlassian.com/software/jira
- **Grade:** Mainstream (dominant engineering tracker; PM-tool by extension).
- **Pricing (2026):** Free tier (up to 10 users); Standard ~$8/user/mo; Premium ~$16/user/mo; Enterprise custom. Jira Product Discovery is a separate SKU.
- **Core features:** Issues, epics, sprints, boards, advanced roadmaps (Premium), Jira Product Discovery (insights, prioritization, ideas), Confluence integration for PRDs.
- **Strengths:** Ubiquity. Deep ecosystem. Confluence PRD templates (Atlassian's own + Lenny Rachitsky's Confluence template). Jira Product Discovery (launched 2022) adds dedicated product-discovery surface.
- **Limitations:** Configuration complexity. UX often criticized vs. Linear. Jira Product Discovery is younger and less mature than Productboard.
- **Target user:** Enterprise teams; mixed product/engineering shops.
- **Source:** https://www.atlassian.com/software/confluence/templates/product-requirements

### §2.7 — Notion

- **URL:** https://www.notion.com/
- **Grade:** Mainstream (general-purpose docs/database; heavily used for PM).
- **Pricing (2026):** Free tier; Plus $10/user/mo; Business $18/user/mo; Enterprise custom. Notion AI separate add-on (~$10/user/mo).
- **Core features:** Pages, databases, templates. Marketplace of PM templates including PRDs, roadmaps, product systems. Notion AI (2024+) for drafting and summarization.
- **Strengths:** Flexibility (PM = whatever you build). Strong template ecosystem. Cheap for small teams. Natural PRD authoring surface.
- **Limitations:** Not opinionated; teams reinvent wheels. Database performance issues at scale. Limited engineering-tracker integration depth.
- **Target user:** Startups, doc-heavy teams, lean PM operations.
- **Source:** https://www.notion.com/templates/category/product-requirements-doc

### §2.8 — Coda

- **URL:** https://coda.io/
- **Grade:** Established.
- **Pricing (2026):** Free tier; Pro $12/user/mo (Doc Maker); Team $36/user/mo; Enterprise custom.
- **Core features:** Docs with embedded tables, formulas, automations, "packs" (integrations). Strong PRD/launch-coordination templates including the canonical Amazon-style Working Backwards PR/FAQ Coda by Colin Bryar.
- **Strengths:** More structured than Notion for repeated coordination workflows. Excellent for stakeholder approvals and launch motions.
- **Limitations:** Heavier than Notion for simple PRDs. Smaller community/template ecosystem.
- **Target user:** Operations-heavy product teams; orgs doing repeated launch coordination.
- **Source:** https://coda.io/@colin-bryar/working-backwards-how-write-an-amazon-pr-faq

### §2.9 — ClickUp

- **URL:** https://clickup.com/
- **Grade:** Established (broad PM-and-project tool; many PMs use it as a unified workspace).
- **Pricing (2026):** Free tier; Unlimited $7/user/mo; Business $12/user/mo; Enterprise custom.
- **Features:** Tasks, docs, whiteboards, goals, dashboards. PRD templates available. ClickUp AI bundled in higher tiers.
- **Strengths:** Breadth (one tool for tasks, docs, goals). Aggressive feature pace.
- **Limitations:** Surface-area bloat — UX criticism. Less PM-specialized depth than Productboard/Aha!.

### §2.10 — monday.com (Work OS)

- **URL:** https://monday.com/
- **Grade:** Established.
- **Features:** Boards-and-views as core primitive. Product/project templates. Integration ecosystem.
- **Strengths:** Polished UX, broad appeal, strong sales/marketing reach.
- **Limitations:** General-purpose; PM-specific features less deep than dedicated PM tools.

### §2.11 — Asana

- **URL:** https://asana.com/
- **Grade:** Mainstream (project management).
- **Features:** Tasks, projects, portfolios, goals. Product roadmap templates. Universal Reporting / AI features (2024+).
- **Strengths:** Mature, large ecosystem, strong enterprise sales.
- **Limitations:** PM-specific (vs. project-management) features are templates layered on a project tracker, not first-class.

### §2.12 — Figma (FigJam)

- **URL:** https://www.figma.com/figjam/
- **Grade:** Mainstream for collaborative whiteboarding (PM-adjacent).
- **Features:** Whiteboard primitives; templates for user-journey mapping, story mapping, brainstorming, retros.
- **Strengths:** The default canvas for many product teams. Templates from the Figma community for story maps, opportunity solution trees, lean canvases, etc.
- **Limitations:** Not a PM system of record; complements PM tools rather than replacing them.

### §2.13 — Craft.io

- **URL:** https://craft.io/
- **Grade:** Established (less ubiquitous than the top three).
- **Features:** Roadmap, prioritization (multiple frameworks), capacity planning, Jira sync.
- **Strengths:** PM-purpose-built; capacity-planning surface uncommon among peers.
- **Limitations:** Smaller community; less brand recognition.

### §2.14 — Airfocus

- **URL:** https://airfocus.com/
- **Grade:** Established.
- **Features:** Prioritization frameworks, modular roadmap views, idea/feedback intake.
- **Strengths:** Strong on prioritization scoring; modular pricing.
- **Limitations:** Less brand recognition; smaller integration ecosystem.

### §2.15 — Jira Product Discovery (mentioned above, but worth calling out)

- **URL:** https://www.atlassian.com/software/jira/product-discovery
- **Grade:** Established (2022+ entrant).
- **Significance:** Atlassian's direct response to Productboard. Tight Jira-tracker integration is the obvious advantage; depth still maturing as of 2026.

### §2.16 — Considered and rejected (or noted briefly)

- **Trello** — Kanban tool; light PM-usage but not a serious PM platform. Skipped.
- **Basecamp** — Project-org tool; minimal PM-discovery surface.
- **Wrike, Smartsheet, Workfront** — Project-management generalists; light PM-specific.
- **Featurebase, Frill** — Feedback-tool-first, lighter on roadmapping. (Honorable mention for the feedback layer.)
- **Productlift, IdeaPlan, Supahub** — Newer feedback/changelog tools, smaller communities; noted but not detailed.

---

## §3 — Methodologies + frameworks

This section catalogs methodologies/frameworks that PMs apply across discovery, prioritization, strategy, and execution. Each entry: origin/author, when to apply, primary sources.

### §3.1 — Jobs-to-be-Done (JTBD)

- **Grade:** Mainstream, but **forked into two interpretations** (see notes).
- **Origin:** Tony Ulwick conceptualized JTBD in 1990 applying Six Sigma to innovation; formalized as Outcome-Driven Innovation (ODI) in 1999. Ulwick introduced the concept to Clayton Christensen, who popularized it in *The Innovator's Solution* (2003) and *Competing Against Luck* (2016, with Karen Dillon, Taddy Hall, David Duncan).
- **What it produces:** "Job statements" describing what a customer is trying to accomplish, independent of the product. Used to identify under-served outcomes and unmet needs.
- **The two interpretations (important):** Alan Klement and others note that "JTBD" today refers to two distinct schools: (a) **ODI / Ulwick** — quantitative, outcome-statement-driven, survey-validated; (b) **Christensen / Moesta** — qualitative, narrative, "switch interview" driven (the milkshake study is the canonical example). They are NOT interchangeable. Pack-relevant note: pick a school explicitly; don't blend the languages.
- **When to apply:** Early-stage product discovery, repositioning, market segmentation by job.
- **Primary sources:** https://strategyn.com/jobs-to-be-done/ (Ulwick/Strategyn), https://jtbd.info/know-the-two-very-different-interpretations-of-jobs-to-be-done-5a18b748bd89 (Klement's distinction), Christensen et al. *Competing Against Luck* (Harper Business 2016).

### §3.2 — RICE prioritization

- **Grade:** Mainstream.
- **Origin:** Intercom (Sean McBride and team), published on the Intercom blog around 2016. Designed to address scoring biases in their own roadmap process.
- **Formula:** RICE score = (Reach × Impact × Confidence) / Effort.
- **What it produces:** Comparable numeric scores across feature candidates. Used to drive backlog ranking and roadmap inclusion.
- **When to apply:** Backlog prioritization where multiple candidates compete; works best when Reach/Impact are estimable.
- **Limitations:** Spurious precision — numeric outputs invite over-confidence in qualitative inputs. Confidence multiplier is a partial corrective.
- **Source:** https://www.intercom.com/blog/rice-simple-prioritization-for-product-managers/

### §3.3 — Kano Model

- **Grade:** Established (academic origin, real practitioner use).
- **Origin:** Professor Noriaki Kano, 1980s (Japan). Originally a quality-management technique.
- **What it produces:** Categorization of features into Must-Have / Performance / Attractive / Indifferent / Reverse, based on satisfaction-vs-dysfunctionality survey questions.
- **When to apply:** When teams need to distinguish baseline expectations from delighters; pre-launch feature triage.
- **Limitations:** Requires survey infrastructure; categories drift over time (today's delighter is tomorrow's must-have).
- **Source:** https://www.productplan.com/glossary/kano-model

### §3.4 — Story Mapping

- **Grade:** Mainstream.
- **Origin:** Jeff Patton; codified in *User Story Mapping: Discover the Whole Story, Build the Right Product* (O'Reilly 2014, second edition 2024).
- **What it produces:** A two-dimensional map: horizontal = user-journey steps (in narrative order); vertical = priority slices for release planning.
- **When to apply:** Translating a product vision into a release-able sequence; preserving the "whole story" so engineering teams don't lose user context.
- **Source:** https://www.amazon.com/User-Story-Mapping-Discover-Product/dp/1491904909

### §3.5 — Impact Mapping

- **Grade:** Established.
- **Origin:** Gojko Adzic; *Impact Mapping: Making a Big Impact with Software Products and Projects* (2012).
- **What it produces:** A mind-map structure: Goal → Actors → Impacts (changes in actor behavior) → Deliverables (what we build to drive the impact). Forces explicit causal reasoning.
- **When to apply:** Strategy-to-delivery alignment; OKR translation to roadmap.
- **Source:** https://www.amazon.com/Impact-Mapping-Software-Products-Projects/dp/0955683645

### §3.6 — Opportunity Solution Tree (OST)

- **Grade:** Established and rising.
- **Origin:** Teresa Torres (2016, refined in *Continuous Discovery Habits*, 2021).
- **What it produces:** Tree rooted in a desired outcome → branches of opportunities (customer needs/pains/desires) → solution candidates per opportunity → assumption tests per solution.
- **When to apply:** Continuous-discovery teams running weekly customer touchpoints; team alignment on which opportunities to pursue.
- **Sources:** https://www.producttalk.org/opportunity-solution-trees/, Torres *Continuous Discovery Habits* (Product Talk LLC 2021).

### §3.7 — Lean Canvas

- **Grade:** Established.
- **Origin:** Ash Maurya, *Running Lean* (O'Reilly 2010, 2nd ed 2012, 3rd ed 2022). Adapted from Osterwalder's Business Model Canvas.
- **What it produces:** One-page canvas: Problem / Customer Segments / Unique Value Proposition / Solution / Channels / Revenue / Cost / Key Metrics / Unfair Advantage. Lean-focused: emphasizes problem and solution over infrastructure.
- **When to apply:** Early-stage idea capture; rapid hypothesis articulation.
- **Source:** https://www.amazon.com/Running-Lean-Iterate-Plan-Works/dp/1492076139

### §3.8 — Business Model Canvas

- **Grade:** Mainstream.
- **Origin:** Alexander Osterwalder + Yves Pigneur, *Business Model Generation* (Wiley 2010), based on Osterwalder's PhD work (2005).
- **What it produces:** Nine-block canvas: Customer Segments / Value Propositions / Channels / Customer Relationships / Revenue Streams / Key Resources / Key Activities / Key Partnerships / Cost Structure.
- **When to apply:** Established-business model articulation; mapping cross-functional dependencies.
- **Source:** https://en.wikipedia.org/wiki/Business_model_canvas (academic background), strategyzer.com (Osterwalder/Pigneur company).

### §3.9 — OKRs (Objectives and Key Results)

- **Grade:** Mainstream.
- **Origin:** Andy Grove at Intel (1970s; documented in *High Output Management*, 1983). Named "OKRs" by John Doerr; introduced to Google in 1999. Doerr's *Measure What Matters* (2018) is the popular reference.
- **What it produces:** Objective (qualitative, ambitious) + 3-5 Key Results (measurable). Quarterly or annual cadence.
- **When to apply:** Org-wide goal alignment; product strategy linking to company strategy.
- **Limitations / controversies:** Misapplication is common — KRs treated as commitments rather than aspiration; output-KRs (ship X) instead of outcome-KRs (move metric Y). Christina Wodtke's *Radical Focus* (2016) is the practitioner-corrective reference.
- **Sources:** https://en.wikipedia.org/wiki/Objectives_and_key_results, https://www.whatmatters.com/

### §3.10 — Continuous Discovery

- **Grade:** Established (rising).
- **Origin:** Teresa Torres, *Continuous Discovery Habits* (2021). Builds on Marty Cagan's discovery work.
- **What it prescribes:** Weekly touchpoints with customers, one team per outcome, OST for visualization, assumption tests for solutions.
- **When to apply:** Mature product orgs ready to commit to ongoing discovery cadence.
- **Source:** https://www.producttalk.org/

### §3.11 — North Star Framework

- **Grade:** Established.
- **Origin:** Term "North Star Metric" coined by Sean Ellis (growth-hacking community, ~2010). Framework formalized by John Cutler (then at Amplitude) into the freely published *North Star Playbook*.
- **What it produces:** One leading-indicator metric expressing core product value; "inputs" feeding into it for team focus.
- **When to apply:** When a product org needs a single rallying metric and clarity on what drives it.
- **Source:** https://amplitude.com/books/north-star

### §3.12 — Design Thinking (IDEO / Stanford d.school)

- **Grade:** Mainstream (in design and discovery contexts).
- **Origin:** Roots in IDEO's Tim Brown and David Kelley; formalized at Stanford d.school in the early 2000s. Five stages: Empathize, Define, Ideate, Prototype, Test.
- **What it produces:** A repeatable process for human-centered problem solving; outputs include empathy maps, problem statements, prototypes.
- **When to apply:** Early discovery; cross-functional ideation; designer-PM-engineer collaboration.
- **Source:** https://dschool.stanford.edu/, https://web.stanford.edu/~mshanks/MichaelShanks/files/509554.pdf (early process guide).

### §3.13 — Lean Startup (Build-Measure-Learn)

- **Grade:** Mainstream.
- **Origin:** Eric Ries, *The Lean Startup* (Crown Business 2011), drawing on Steve Blank's customer-development work.
- **Key concepts:** Minimum Viable Product (MVP), validated learning, Build-Measure-Learn feedback loop, pivot-or-persevere.
- **When to apply:** New-product launches under uncertainty; hypothesis-driven product work.
- **Limitations / controversies:** MVP is misused widely — often interpreted as "minimum product" rather than "minimum experiment to test a hypothesis."
- **Source:** https://theleanstartup.com/principles

### §3.14 — Customer Development (Four Steps)

- **Grade:** Mainstream.
- **Origin:** Steve Blank, *The Four Steps to the Epiphany* (2005, 2nd ed 2013).
- **What it prescribes:** Four iterative steps — Customer Discovery, Customer Validation, Customer Creation, Company Building. Insists startups search for a business model rather than execute one.
- **Source:** https://steveblank.com/tag/customer-development/

### §3.15 — Empathy Map

- **Grade:** Established.
- **Origin:** Dave Gray (XPLANE) ~2009; adopted by IDEO / d.school design-thinking curriculum.
- **What it produces:** A four-quadrant (or six-quadrant updated version) artifact summarizing what a user Says / Does / Thinks / Feels (and Pains / Gains in updated version).
- **When to apply:** Synthesis after user research; sharing user understanding with stakeholders.
- **Source:** https://medium.com/@davegray/updated-empathy-map-canvas-46df22df3c8a, https://www.ideo.com/journal/build-your-creative-confidence-empathy-maps

### §3.16 — Five Whys

- **Grade:** Mainstream (lean/six-sigma origin; widely used in PM/postmortems).
- **Origin:** Sakichi Toyoda (Toyota founder); described by Taiichi Ohno (Toyota Production System).
- **What it produces:** Iterative "why?" questioning to drive past symptom to root cause.
- **When to apply:** Post-mortem analysis; problem-statement refinement.
- **Limitations / criticism:** Teruyuki Minoura (former Toyota global purchasing MD) and others have criticized the "five" as arbitrarily shallow; real root cause may need more iterations or branching.
- **Source:** https://en.wikipedia.org/wiki/Five_whys, https://www.atlassian.com/incident-management/postmortem/5-whys

### §3.17 — Marty Cagan's empowered-product-teams framework

- **Grade:** Mainstream in product-leadership circles.
- **Origin:** Marty Cagan, Silicon Valley Product Group (SVPG, founded 2001). Books: *Inspired* (2008, 2nd ed 2017), *Empowered* (2020, with Chris Jones), *Transformed* (2024).
- **What it prescribes:** Teams "assigned problems to solve rather than features to build"; outcome accountability; product-discovery skills as core competency (valuable / usable / feasible / viable).
- **When to apply:** Org design and product-team operating model.
- **Source:** https://www.svpg.com/

### §3.18 — Considered and noted briefly

- **MoSCoW** (Must / Should / Could / Won't) — Established prioritization shortcut; useful for fixed-deadline work, less useful for ongoing roadmaps. Originated in DSDM (Dynamic Systems Development Method).
- **Value vs. Effort 2x2** — Mainstream as a workshop-tool; lighter than RICE.
- **Cost of Delay / WSJF** (Weighted Shortest Job First) — Mainstream in SAFe; controversial outside SAFe contexts.
- **HEART framework** (Happiness, Engagement, Adoption, Retention, Task success) — Established (Google research). Measurement framework for user experience.
- **Pirate Metrics (AARRR)** — Established (Dave McClure). Acquisition / Activation / Retention / Referral / Revenue. Growth-focused.
- **GIST planning** (Goals / Ideas / Step-Projects / Tasks) — Niche (Itamar Gilad). Lightweight alternative to roadmap planning.
- **HEILMEIER Catechism** — Niche (originated DARPA). Useful as a problem-statement gut-check; nine questions ("What are you trying to do? Articulate your objectives using absolutely no jargon," etc.). Some PMs adopt it; not mainstream.
- **3 Horizons** (McKinsey) — Established in strategy circles. Horizon 1 (core), Horizon 2 (adjacent), Horizon 3 (transformational). Used for portfolio-balancing discussions.

---

## §4 — PRD templates + structures

PRD templates vary widely, but a strong common-denominator set has emerged. This section surveys canonical templates and the universal/optional/controversial section breakdown.

### §4.1 — Atlassian / Confluence PRD template

- **URL:** https://www.atlassian.com/software/confluence/templates/product-requirements
- **Grade:** Mainstream.
- **Sections:** Project Specifics (participants, status) / Objectives & Metrics / Assumptions / User Stories / UX Design / Scope (in/out) / Open Questions.
- **Notes:** Tight Jira integration (link Jira issues, embed designs). Atlassian's "what is a PRD?" reference also published.

### §4.2 — Lenny Rachitsky's Confluence template

- **URL:** https://www.atlassian.com/software/confluence/templates/lennys-product-requirements
- **Grade:** Established (heavily cited in PM circles via Lenny's Newsletter).
- **Sections:** TL;DR / Problem / Goals (and Non-Goals) / Hypotheses / Solution / Launch readiness checklist.
- **Notes:** Lighter than Atlassian's default; opinionated by-PMs-for-PMs.

### §4.3 — Amazon's PR/FAQ (Working Backwards)

- **URLs:** https://workingbackwards.com/resources/working-backwards-pr-faq/, https://coda.io/@colin-bryar/working-backwards-how-write-an-amazon-pr-faq
- **Grade:** Mainstream (one of the most-cited PRD-adjacent templates).
- **Structure:** A fictional press release (headline, subheading, summary paragraph, problem, solution, exec quote, customer quote, call to action), followed by an FAQ (customer FAQ + stakeholder FAQ).
- **Notes:** Forcing function — write the launch announcement before building. Used at Amazon since the early 2000s (S3, EC2, Kindle, Prime Video cited as products born from PR/FAQs). The PR/FAQ format is more about clarity-of-customer-vision than feature-spec; many teams pair it with a follow-on engineering spec.

### §4.4 — Kevin Yien's PRD template (Square)

- **URL:** Featured in Lenny's Newsletter at https://www.lennysnewsletter.com/p/my-favorite-templates-issue-37
- **Grade:** Established (referenced as a popular template).
- **Sections of note:** Strong "Non-Goals" section, step-by-step user-flow narrative.

### §4.5 — Figma's PRD template

- **URL:** Referenced via Lenny's Newsletter (https://www.lennysnewsletter.com/p/my-favorite-templates-issue-37).
- **Grade:** Established.
- **Notes:** "Plug-and-play" — comprehensive default sections. Heavier than Yien's, lighter than enterprise templates.

### §4.6 — Productboard / ProductPlan in-tool PRDs

- Built-in PRD surfaces. ProductPlan and Productboard offer template structures within their tools.
- Generally aligned with the common-denominator section list below.

### §4.7 — Notion / Coda PRD templates (community)

- Notion marketplace has multiple PRD templates (https://www.notion.com/templates/category/product-requirements-doc) ranging from simple to elaborate.
- Coda templates lean toward launch-coordination structure (Working Backwards adaptations are popular).

### §4.8 — Common-denominator PRD sections (universal)

Across the templates surveyed, these sections appear in virtually all canonical PRDs:

1. **Title / Owner / Status / Date** — Metadata header.
2. **Problem / Background** — What customer problem are we solving? Why now?
3. **Goals** — What does success look like? (Often paired with metrics.)
4. **Non-Goals** — Explicit out-of-scope items. Universally cited as the most important guardrail.
5. **User stories or scenarios** — Who uses this, how, in what context.
6. **Solution / Functional requirements** — What we're building (depth varies).
7. **Success metrics** — How we'll measure outcome post-launch.
8. **Open questions** — Known unknowns.

### §4.9 — Frequently-present but non-universal sections

- **TL;DR / Executive summary** — Common in modern templates (Lenny, ChatPRD output). Absent in legacy templates.
- **Assumptions** — Common (Atlassian-style).
- **UX / Design references** — Common when designers are co-authoring.
- **Technical considerations / dependencies** — Common in eng-heavy templates; sometimes split into a separate engineering spec.
- **Launch / go-to-market plan** — Common in Amazon-style PR/FAQs; less common in feature-spec PRDs.
- **Risks** — Common.
- **Hypotheses** — Common in lean / discovery-influenced templates (Torres-school, Cagan-school).
- **Personas** — Common when team has invested in persona work; controversial otherwise (see §3 caveats around persona-as-vapor).

### §4.10 — Controversial / explicitly debated

- **User stories ("As a X, I want Y so that Z") vs. issues.** Linear's Method (https://linear.app/method/write-issues-not-user-stories) argues user stories are anti-pattern noise; write short clear task statements instead. Mainstream agile PM still defaults to user-story format. Pack-relevant: don't take either side as universal.
- **PRD vs. lightweight spec.** Marty Cagan's school argues that thick PRDs are an anti-pattern from waterfall days; outcomes/discovery work should replace feature-spec ceremony. Counter-school: explicit PRDs prevent miscommunication in cross-functional teams.
- **Section depth.** Amazon PR/FAQ argues that prose narrative beats slide-decks and bullet-list specs because narrative forces clear thinking. Counter-school: bullets are faster and clearer for cross-functional consumption.

---

## §5 — Interview / customer-discovery frameworks

This section catalogs methodologies for conducting customer interviews and validating product hypotheses, with primary-source attribution.

### §5.1 — The Mom Test (Rob Fitzpatrick)

- **Grade:** Mainstream in startup / founder communities; the canonical reference for "how to talk to customers without lying to yourself."
- **Source:** Rob Fitzpatrick, *The Mom Test: How to talk to customers & learn if your business is a good idea when everyone is lying to you* (self-published 2013; widely adopted since).
- **Three rules:**
  1. Talk about their life, not your idea.
  2. Ask about specifics in the past, not generics or opinions about the future.
  3. Talk less, listen more.
- **What it produces:** Higher-quality customer-interview data by avoiding three trap types (compliments, hypothetical fluff, wishlists).
- **Sample question structures:** "Walk me through the last time you [did the thing my product would help with]." "What happened just before that?" "What did you try?" "How much time did it take?" "What would you have to give up to use a solution?"
- **Common pitfalls Fitzpatrick names:** Pitching the idea; asking "would you buy it"; treating compliments as validation; asking hypotheticals.
- **Adoption signals:** Used in Harvard / UCL curricula, Seedcamp, Microsoft Ventures, Shopify, Pact Coffee per the book's own collateral.
- **Source:** https://www.momtestbook.com/

### §5.2 — Steve Blank's Customer Development

- **Grade:** Mainstream.
- **Source:** Steve Blank, *The Four Steps to the Epiphany* (2005, 2nd ed 2013); also *The Startup Owner's Manual* (Blank & Dorf 2012).
- **What it prescribes:** Testing business-model hypotheses outside the building — not in planning meetings, but with potential customers. Iterative across the four steps (Discovery → Validation → Creation → Building).
- **Interview style:** Hypothesis-driven; explicit hypothesis articulated before each interview; interview structured to invalidate or strengthen the hypothesis.
- **Source:** https://steveblank.com/tag/customer-development/

### §5.3 — Lean Customer Development (Cindy Alvarez)

- **Grade:** Established.
- **Source:** Cindy Alvarez, *Lean Customer Development: Building Products Your Customers Will Buy* (O'Reilly 2014, 2nd ed 2017).
- **What it prescribes:** A more accessible/applied version of Blank's customer development; focuses on the interview as the core unit of learning; explicit hypothesis-formulation templates.
- **Source:** https://www.cindyalvarez.com/lean-customer-development/

### §5.4 — JTBD Interviews (Christensen school / "Switch Interview")

- **Grade:** Established.
- **Origin:** Christensen / Bob Moesta / Chris Spiek; codified in *Competing Against Luck* (Christensen et al., 2016) and the "Re-Wired Group" / Moesta's work.
- **Interview style:** Narrative-driven. Focus on a recent purchase/adoption decision. Trace the "switch story" through four forces (push of current situation, pull of new solution, anxiety about change, habit of current).
- **What it produces:** Job statements; understanding of forces that drive customer choice.
- **Source:** https://strategyn.com/jobs-to-be-done/history-of-jtbd/, *Competing Against Luck* (HarperBusiness 2016).

### §5.5 — JTBD interviews (Ulwick / ODI school)

- **Grade:** Established (more quantitative-leaning).
- **Origin:** Tony Ulwick / Strategyn.
- **Interview style:** Identify the job-to-be-done; extract "desired outcome statements" (typically structured as "minimize the time it takes to [verb] the [object] when [condition]"); survey-validate outcome importance and current satisfaction.
- **What it produces:** Outcome-importance maps; under-served-outcome identification.
- **Source:** https://strategyn.com/jobs-to-be-done/

### §5.6 — Teresa Torres' Continuous Discovery interview pattern

- **Grade:** Established (rising).
- **Source:** *Continuous Discovery Habits* (2021).
- **What it prescribes:** Weekly customer touchpoints (one team-to-customer interview per week minimum); story-based interviews ("tell me about the last time you ___"); opportunity-extraction from interview transcripts.
- **Strength:** Couples discovery to the Opportunity Solution Tree workflow.
- **Source:** https://www.producttalk.org/

### §5.7 — Marty Cagan's product-discovery techniques

- **Grade:** Mainstream in product-leadership.
- **Sources:** *Inspired* (Cagan 2008/2017), SVPG articles (https://www.svpg.com/articles/).
- **What it prescribes:** A broader catalog: customer-discovery interviews, customer-letter exercises, customer-misbehavior-interviews, demo-script discovery, paper prototyping, narrative writing.
- **Notable:** Cagan distinguishes discovery (testing hypotheses) from delivery (building production code); both happen in parallel in empowered teams.

### §5.8 — Generative vs. evaluative research distinction

- **Grade:** Mainstream in UX research (Nielsen Norman Group is a primary popularizer).
- **What it teaches:** Generative research uncovers unknowns ("what should we build?"); evaluative research tests a known artifact ("is this design good?"). Different methods apply to each. Misapplying evaluative methods (e.g., usability tests) to generative questions is a common pitfall.
- **Source:** https://www.nngroup.com/articles/discovery-phase/

### §5.9 — Common interview pitfalls (cross-cutting)

Across the frameworks, these failure modes recur and are worth flagging:

- **Leading questions** — "Don't you think it would be great if...?"
- **Hypothetical questions** — "Would you use a product that...?" (Fitzpatrick: a major no.)
- **Pitching mid-interview** — Switches the interviewee from informer to evaluator.
- **Treating compliments as data** — Fitzpatrick's bedrock complaint.
- **Skipping note-discipline** — Without a transcript or notetaker, post-hoc memory is unreliable.
- **Selection bias** — Talking only to friends/early-adopters skews data.
- **Premature pattern-matching** — Five interviews are not statistically meaningful; treat findings as hypotheses, not conclusions.

### §5.10 — Persona development (Alan Cooper)

- **Grade:** Mainstream (though contested — see §5.11).
- **Origin:** Alan Cooper, *The Inmates Are Running the Asylum* (1999); refined in *About Face* (1995, 4th ed 2014).
- **What it produces:** Fictitious-but-grounded user archetypes with goals, behaviors, environment. Goal-Directed Design uses personas as the focal lens for design decisions.
- **Cooper's distinction:** Personas have goals (steady end-states), not just tasks (transient intermediate processes). A persona without articulated goals is decoration.
- **Source:** https://www.dubberly.com/articles/alan-cooper-and-the-goal-directed-design-process.html, *About Face: The Essentials of Interaction Design* (Cooper, Reimann, Cronin, Noessel, Wiley 2014).

### §5.11 — Persona controversy

Two contested points worth surfacing:

- **Personas as vapor.** Critics (including Cagan and some lean-startup voices) argue that personas often become decorative deliverables disconnected from product decisions. Counter: when grounded in real research and used as decision lenses, they retain value.
- **JTBD as persona-replacement.** The JTBD-strict camp argues personas are the wrong unit of analysis; jobs/outcomes are. Counter (Cooper-camp): personas with explicit goals encode the same insight differently.
- **Pack-relevance:** Be cautious about prescribing persona-creation as a default PS-feature output without a clear "and-then-what" workflow.

---

## §6 — AI/LLM-assisted product tooling

This category is fast-moving (2024-2026) and high in vapor risk. Entries are graded with explicit attention to "real value vs. demo-ware."

### §6.1 — ChatPRD

- **URL:** https://www.chatprd.ai/
- **Grade:** Established (the most-cited single-purpose AI PRD tool).
- **What it does:** AI-purpose-tuned for PRDs / specs / user stories / launch briefs. Browser-based.
- **Adoption:** Marketing claims "100,000+ PMs" (vendor-cited; not independently verified).
- **Strengths:** Purpose-built tuning vs. generic ChatGPT; PRD-shaped output by default.
- **Limitations:** Still LLM-output; quality depends on prompt; coupling to one model's quirks.
- **Source:** https://www.chatprd.ai/

### §6.2 — Productboard AI

- **URL:** https://www.productboard.com/ (product feature)
- **Grade:** Established.
- **What it does:** LLM-assisted insight clustering, customer-feedback summarization, draft generation inside Productboard.
- **Strengths:** Embedded in an existing PM workflow (vs. standalone tool requiring context-copying).
- **Limitations:** Bundled to Productboard's pricing.
- **Source:** https://www.productboard.com/

### §6.3 — Aha! Notebooks / Aha! AI

- **URL:** https://www.aha.io/ (product features)
- **Grade:** Established.
- **What it does:** AI features for drafting requirements, summarizing feedback, generating release-notes.
- **Strengths:** Embedded; deep Jira / GitHub integration.
- **Limitations:** Bundled to Aha!'s enterprise pricing.

### §6.4 — Linear Agent

- **URL:** https://linear.app/ (product feature, 2025+)
- **Grade:** Established.
- **What it does:** Agent built into Linear; understands the team's roadmap, issues, and connected code. Synthesizes context, makes recommendations, takes actions.
- **Strengths:** Tight tracker/code integration; no copy-paste-to-LLM friction.
- **Source:** https://linear.app/changelog (Linear changelog has launch entries).

### §6.5 — Notion AI

- **URL:** https://www.notion.com/product/ai
- **Grade:** Mainstream.
- **What it does:** Drafting, summarization, Q&A across a Notion workspace; tunable for PRD drafting where templates exist.
- **Strengths:** Embedded in a heavily-used PM surface.

### §6.6 — ProdPad CoPilot

- **URL:** https://www.prodpad.com/
- **Grade:** Established.
- **What it does:** AI assistant within ProdPad — roadmap suggestions, idea-generation, story-generation, acceptance-criteria suggestions from backlog similarity.
- **Strengths:** Purpose-fit to PM workflow.

### §6.7 — Chisel

- **URL:** https://chisellabs.com/
- **Grade:** Established (smaller scale than Productboard / Aha!).
- **What it does:** Feedback analysis + roadmap prioritization with AI assistance. Jira / Slack integrations.

### §6.8 — Buildbetter / Maven AGI / "AI for PMs" cluster

- **Grade:** Niche to vapor-risk.
- **What they claim:** Various combinations of: customer-interview summarization, PRD generation, roadmap auto-prioritization, "autonomous PM agent."
- **Honest assessment:** Many entries in this cluster (across 2024-2026) make broad agentic claims that outpace demonstrated track record. Real adoption is harder to verify than vendor marketing suggests. Treat agentic-PM claims skeptically.

### §6.9 — Generic LLMs (ChatGPT, Claude, Gemini) used for PM work

- **Grade:** Mainstream by usage.
- **What's happening:** A large fraction of PMs use generic LLMs for PRD drafting, user-story generation, persona summarization, interview-transcript summarization. (Practitioner surveys 2024-2026 consistently report this.)
- **Strengths:** No tool-buy decision needed; works on any data the PM is willing to paste in.
- **Limitations:** No PM-workflow integration; no SSOT; security/compliance concerns with pasting customer data; quality depends on prompt engineering.

### §6.10 — Open-source AI PRD generators (cluster, repeated from §1)

- Multiple small repos exist (see §1.5).
- Collective grade: vapor-risk individual; the cluster itself signals genuine interest.

### §6.11 — Wave taxonomy (2024-2026)

A recurring framing (per multiple 2025-2026 trade-press articles, e.g., https://aipmtools.org/articles/ai-changing-product-management):

- **Wave 1 (~2022-2023):** "AI in PM" = use ChatGPT to draft emails. Light value-add.
- **Wave 2 (~2023-2025):** Content generation in PM workflows — PRDs, user stories, interview summaries, release notes. Real value, well-bounded.
- **Wave 3 (~2025-2026):** "Agentic" PM — autonomous workflows monitoring signals, triaging feedback, suggesting roadmap moves. CLAIMS exceed adoption.

Honest assessment: Wave 2 is real and reproducible. Wave 3 has demonstrable demos but limited durable production deployments as of mid-2026.

### §6.12 — Integration patterns AI tools use

- **Embedded** (Productboard AI, Aha! AI, Linear Agent, ProdPad CoPilot) — AI inside the PM tool; access to context by default.
- **Standalone** (ChatPRD, generic LLMs) — Copy-paste workflow; lower-friction setup, higher-friction usage.
- **MCP / agent-protocol** (PRD-MCP-Server, AI-PRD-Generator plugins) — Newer pattern; LLM-agent toolchain rather than UI.
- **CLI/agent-based** (the pack's CLAUDE / Codex / Gemini integration target) — Emerging; the pack itself is an example of this pattern, though scoped to engineering work today.

### §6.13 — Cross-CLI coding-agent landscape (pack-adjacent reference)

The major CLI coding agents (Claude Code, OpenAI Codex CLI, Gemini CLI) are NOT primarily product-management tools — they target software-engineering workflows. However, they're relevant context for the pack because:

- The pack's existing posture is multi-CLI (CLAUDE.md / AGENTS.md / GEMINI.md trinity).
- LLM-based PM tooling and LLM-based engineering tooling share architecture (skills, sub-agents, MCP servers).
- A PS feature shipped via the pack would inherit the same multi-CLI shape.

Mainstream comparisons (mid-2026): Claude Code positioned for thoughtful production-quality multi-file work; Codex CLI for CI/CD integration and standard tasks; Gemini CLI for large-codebase exploration and best-free-tier access.

- **Sources:** https://www.deployhq.com/blog/comparing-claude-code-openai-codex-and-google-gemini-cli-which-ai-coding-assistant-is-right-for-your-deployment-workflow, https://intuitionlabs.ai/articles/claude-code-vs-codex-vs-gemini-cli-comparison

---

## §7 — Dev-tool integration patterns

How professional PM tools integrate with engineering trackers, and the technical patterns underlying those integrations.

### §7.1 — Two-way sync (Productboard, Aha!, ProductPlan)

- **Pattern:** Bi-directional updates between a PM tool and an engineering tracker (typically Jira, sometimes Linear / GitHub Issues / Azure DevOps).
- **Mechanism:** Field mapping (PM feature ↔ Jira issue with mapped custom fields); status updates flow both directions; assignee/owner sync.
- **Example:** Productboard's Jira integration allows mapping custom fields, pushing features and sub-features into Jira, and reflecting Jira status changes back into Productboard roadmaps.
- **Strengths:** Single-edit-multi-update model; PM and engineering see the same data.
- **Limitations:** Conflict resolution is hard; field-mapping setup is a multi-hour project; schema drift between tools breaks sync.
- **Sources:** https://support.productboard.com/hc/en-us/articles/11535151728275, https://www.aha.io/blog/just-launched-two-way-jira-integration-now-supports-custom-fields

### §7.2 — One-way push (PM → engineering tracker)

- **Pattern:** PM tool is the authoring surface; engineering tracker receives created issues but doesn't push state back.
- **Mechanism:** API call from PM tool to tracker; one-time create or scheduled batch.
- **Strengths:** Simpler than two-way; clear ownership of source-of-truth.
- **Limitations:** Engineering changes don't reflect in PM tool; status drift inevitable.

### §7.3 — Linked-reference (no sync)

- **Pattern:** PM tool stores a reference (URL / ID) to an engineering item; no data sync.
- **Mechanism:** Manual or copy-paste; URL embedding.
- **Strengths:** Trivial setup; no field-mapping concerns.
- **Limitations:** Status info requires clicking through; no aggregate views; drift inevitable.

### §7.4 — Tracker as PM tool (no separate PM surface)

- **Pattern:** Engineering tracker doubles as PM tool. Linear, Jira Premium with Advanced Roadmaps, Jira Product Discovery, ClickUp, Plane.
- **Strengths:** No integration; one SSOT.
- **Limitations:** Trackers optimize for engineering execution; PM-specific needs (customer feedback intake, public portal, prioritization scoring) are bolted on or absent.

### §7.5 — Embedded customer-feedback intake

- **Pattern:** A feedback-intake widget / portal feeds into the PM tool; PM tool aggregates, scores, and routes to engineering.
- **Example:** Productboard's insights inbox, Canny's public board, UserVoice's enterprise portal.
- **Mechanism:** Webhook or API ingestion from intake surface; LLM-clustering (newer); manual triage; promotion-to-feature workflow.

### §7.6 — Webhook + polling hybrid (technical pattern)

- **Pattern:** Webhooks for real-time updates; periodic polling as fallback for missed events.
- **Why both:** Webhooks are push-driven and efficient but can be missed (network failures, downtime, mis-configuration). Polling catches the drift but is rate-limited and laggy. Hybrid is industry-standard.
- **Conflict resolution patterns:** Idempotency keys (dedup retried events), event ordering by timestamp or version, last-write-wins (simple but lossy), field-level merge (complex but lossless), conflict-flagging (defer to human).
- **Source:** https://unified.to/blog/polling_vs_webhooks_when_to_use_one_over_the_other, https://www.freecodecamp.org/news/api-integration-patterns/

### §7.7 — GitHub Issues sync patterns (specific to GitHub-centric teams)

- **Linear ↔ GitHub:** Two-way sync; PR-status auto-updates Linear issue status (in-progress → done); branch-name parsing for issue identifiers; webhooks + Agent session events.
- **Productboard → GitHub Issues:** Native integration; less mature than Jira sync.
- **Aha! ↔ GitHub:** Strategic items (initiatives, features) map to GitHub epics/issues.
- **Common pitfall:** OAuth scope misconfiguration; webhook events not enabled at install time; identifier-format mismatches.
- **Source:** https://linear.app/docs/github-integration

### §7.8 — Five recurring integration design considerations

Across the patterns above, these recur:

1. **Source of truth.** Which system owns which fields? Disagreement here causes most integration failures.
2. **Field mapping.** Custom fields are the integration knife-edge; default-mapped fields rarely match.
3. **Conflict resolution.** What happens when both sides edit the same record? Last-write-wins is the default but loses data.
4. **Permissions / visibility.** A PM-tool item visible to "all stakeholders" may map to an engineering ticket visible only to the eng team. Cross-system permission drift is a real issue.
5. **Schema evolution.** When the PM tool or tracker adds fields, integrations need updating. Schema migration is rarely automated.

---

## §8 — Cross-category synthesis

Where the seven categories converge, where they diverge, and where the field is heading (2025-2026).

### §8.1 — Convergence: the modern PM workflow stack

Despite tool variety, a converged workflow has emerged across the mainstream commercial tools:

1. **Customer-feedback aggregation** (PM tool intake) → 2. **Insight clustering / theming** (manual + LLM-assist) → 3. **Opportunity identification** (OST-ish or feature-list) → 4. **Prioritization scoring** (RICE / Kano / Value-Effort) → 5. **Roadmap visualization** (multiple view types) → 6. **PRD authoring** (in-tool or external doc) → 7. **Two-way sync to engineering tracker** (Jira / Linear / GitHub) → 8. **Outcome measurement** (North Star + supporting metrics).

Every mainstream commercial tool (Productboard, Aha!, ProductPlan, Productboard, Jira Product Discovery) implements some subset of this stack. Differentiation is depth-per-stage, not stage-presence.

### §8.2 — Convergence: a common PRD section set

The cross-template analysis (§4.8) shows strong convergence on eight common-denominator sections (problem / goals / non-goals / user stories / solution / metrics / open questions / metadata). Templates beyond that diverge on optional sections (TL;DR, assumptions, risks, hypotheses, personas), but the core set is stable enough that a "common PRD" is a defensible artifact.

### §8.3 — Convergence: hypothesis-driven discovery

Across methodologies (Lean Startup, Customer Development, Continuous Discovery, JTBD), the practitioner-canon now reflects hypothesis-driven product work. Even teams that don't formalize the hypothesis articulate problems and solutions in hypothesis-shaped language. This is a substantive shift from feature-driven roadmap thinking of the 2000s.

### §8.4 — Divergence: methodology orthodoxies

Several methodologies have ideological camps that don't blend cleanly:

- **JTBD: Christensen vs. Ulwick schools** (§3.1). Don't mix vocabularies.
- **User stories vs. issues** (§4.10, Linear Method vs. agile orthodoxy).
- **PRD vs. lightweight spec** (§4.10, Cagan-school vs. Atlassian-school).
- **Persona-driven vs. JTBD-driven discovery** (§5.11).

A PS feature that doesn't take a position will produce muddled outputs; one that takes a strong position will alienate practitioners of the other schools. This is a fundamental design tension.

### §8.5 — Divergence: tracker integration depth

The integration-depth axis ranges from "trivially linked URLs" (Notion) to "deep two-way custom-field sync with conflict resolution" (Productboard ↔ Jira). Where on this axis to land is a real choice with cost / value implications.

### §8.6 — What's missing across the landscape

Several gaps recur across the surveyed tools and frameworks:

- **Integration between PM thinking and code reality.** PRDs and roadmaps live in PM tools; code lives in repos. Productboard / Aha! / Linear-Agent partially close this, but most teams still copy-paste between worlds. The LLM-agent layer (Wave 3) promises to close it but hasn't yet at scale.
- **Lightweight discovery for solo / micro-team contexts.** Most tooling assumes a multi-person product team. Solo developers and 2-person startups are under-served by Productboard-scale tools (price + complexity) and over-served by sticky-note + spreadsheet workflows. Notion / Coda templates partially fill this; nothing is opinionated for this audience.
- **Methodology-aware tooling.** Most PM tools are methodology-agnostic templates. Few embed an opinion about WHICH framework to use WHEN. The fact that this requires a human "PM" to decide is the gap that AI/LLM tools might close.
- **PRD-to-code traceability.** Linking a PRD requirement to a code change is mostly manual. Jira-Confluence has rudimentary linking; nothing surveyed provides "this code commit fulfills this PRD requirement" semantic linking.
- **Discovery-output durability.** Interview notes, opportunity trees, persona docs decay rapidly. Tools rarely encode incentives to re-validate or archive stale findings.

### §8.7 — 2025-2026 directional trends

Three trends visible in the survey:

1. **Agentic AI in PM** (Wave 3). Heavy claims, modest adoption-evidence. Watch but don't over-index.
2. **Tracker-side PM features.** Jira Product Discovery (2022) and Linear Agent (2025) show engineering trackers moving up into PM space. Productboard / Aha! are responding by deepening tracker sync. The line between "PM tool" and "engineering tracker" is blurring.
3. **Methodology codification in software.** Tools increasingly embed methodology (Productboard's prioritization frameworks, Linear's Method handbook). Pure-template tools (Notion / Coda) maintain agnostic stance.

---

## §9 — Pack-relevance observations

This section describes what the landscape suggests for the pack's Product Specialist feature design, WITHOUT proposing specific designs. Surfacing landscape implications only.

### §9.1 — Hard things to do well (be careful here)

Patterns where the landscape's experience says "this is hard; the obvious approach will disappoint":

- **Generating PRDs that aren't generic.** The crowd of open-source AI-PRD generators (§1.5) demonstrates that the technique is accessible — and that most outputs are mediocre. PRDs derive value from team conversation, not from artifact quality. A PS feature that produces PRDs without facilitating conversation will likely produce decorative artifacts.
- **Generating personas without grounding.** The persona-controversy (§5.11) is real. Personas without genuine research backing become decorative. An LLM-generated persona is doubly suspect — it's not grounded in research AT ALL.
- **Methodology selection by AI.** The orthodoxy splits (§8.4) mean that "pick a framework for me" requires substantive context. Tools that paper over the splits produce muddled output (e.g., a "PRD" that's part-Working-Backwards, part-Atlassian, part-JTBD).
- **Customer-interview replacement.** Multiple frameworks (Mom Test, Customer Development, Continuous Discovery) emphasize that interview value comes from human-listening and follow-up questions. AI can scaffold interviews; it can't replace them. Any PS feature pitching "let AI talk to your users" is in vapor territory.
- **Two-way tracker sync from a CLI tool.** The integration-depth bar set by Productboard et al. is high (custom-field mapping, conflict resolution, schema evolution). Matching that depth from CLI-shipped tooling is non-trivial.

### §9.2 — Underserved gaps (possible pack-specific value)

Areas where the landscape's coverage is thin and where tight pack-integration might offer real value:

- **Solo / micro-team product thinking.** The PM-tool landscape under-serves 1-3-person product efforts. The pack already targets solo and small-team developers — the audience overlap is real.
- **PRD-to-code traceability.** The pack already has primitives for tracking BDs (backlog), phases, groupings, IMPL-REPORTs. Tying PRD requirements to BD entries, then to commits/PRs, is a thread the existing pack ecosystem could pull.
- **Methodology-as-explicit-position.** Existing tools are methodology-neutral templates. The pack has shown willingness to take opinionated positions (Linear Method-style "we recommend X"). A PS feature can take a position on, say, "use Lean Canvas for initial idea capture; use Story Mapping for release planning" — an opinion that's rare in commercial tools.
- **Conversation scaffolding rather than artifact generation.** The pack's CLI-agent shape (interactive, conversational, scoped to a project's context) is well-suited to FACILITATING the thinking (asking clarifying questions, surfacing missing sections, challenging assumptions) rather than generating decorative artifacts.
- **Discovery-output integration with existing pack primitives.** The pack has phases, groupings, backlog entries — natural homes for opportunities and solutions (OST mappable to backlog phases; assumption tests mappable to BD entries). The integration is unique to the pack.

### §9.3 — Patterns the pack should adopt to be familiar to product professionals

Standard patterns that PM practitioners will expect and that the pack would do well not to invent:

- **The eight common-denominator PRD sections** (§4.8). Whatever shape the PS feature takes, the output(s) should be navigable in these terms.
- **Goals + Non-Goals as a paired construct.** Universally cited as the most-important guardrail; should be a first-class output.
- **Hypothesis-driven framing.** Practitioners expect to see explicit hypotheses and tests, not feature wishlists.
- **Outcomes-over-outputs vocabulary.** Cagan / Torres / OKR-correctness all converge here. PRD sections that ask "what feature?" should also ask "what outcome metric moves?"
- **Customer-interview discipline.** Even a lightweight tool should respect Mom Test rules — avoid leading questions, focus on past behavior, listen-don't-pitch.
- **Roadmap as multiple views.** No single roadmap visualization works for all audiences. (Linear / Aha! / Productboard all offer multiple views.)
- **Integration with existing backlog/tracker rather than parallel-universe.** PM artifacts that don't link to engineering work decay rapidly.

### §9.4 — Cautious notes about LLM-PM tooling

Echoing the §6 Wave taxonomy:

- Wave 2 (content generation in PM workflows) is genuinely useful and the pack can credibly operate here.
- Wave 3 (autonomous agentic PM) is largely vapor; making strong agentic claims would be high-cost / low-credibility.
- Generic-LLM-as-PM-helper is what most PMs are doing today; a CLI-pack PS feature competes against "I'll just paste this into Claude." The pack's value-add must be visible above that baseline (context-awareness, project integration, opinion-taking).

### §9.5 — Methodology-position recommendations to consider during requirements gathering

Without prescribing, the cleanest set of methodological positions that the landscape supports as defensible defaults:

- **Discovery framework:** Continuous Discovery (Torres) / OST as the visual primitive.
- **Hypothesis articulation:** Lean Canvas (one-page) or PR/FAQ (narrative-driven). Both are mainstream-defensible.
- **Prioritization:** RICE or Value/Effort as default; Kano for delight/baseline triage.
- **Interview style:** Mom Test rules + past-behavior focus.
- **PRD shape:** Common-denominator sections (§4.8).
- **Outcome framework:** North Star + supporting metrics; OKRs for org-level alignment.
- **Persona vs. JTBD:** Pick one, don't blend. JTBD (Christensen-school for qualitative, narrative work) is the trend-direction.
- **Empowered-team vocabulary:** Cagan (problems-to-solve, outcomes-over-outputs).

These are coherent, mainstream-defensible, internally compatible. Other position-sets are also defensible — this is a starting reference point, not a prescription.

---

## §10 — Sources + dates

### §10.1 — Research date

This research pass was conducted 2026-05-21 through 2026-05-24. URLs cited were live at that time; publication dates of cited materials are referenced inline where the source provides them.

### §10.2 — Primary sources by category

**§1 (Open-source PM tools):**
- https://github.com/opf/openproject — OpenProject repo
- https://www.openproject.org/roadmap/ — vendor roadmap (live 2026-05-24)
- https://taiga.io/ — Taiga vendor site
- https://plane.so/ — Plane vendor site
- https://github.com/QuackbackIO/quackback — Quackback OSS feedback tool
- https://github.com/AungMyoKyaw/prd-creator, https://github.com/Sikandar-irfan/prd-generator, https://github.com/cdeust/ai-prd-generator, https://github.com/nanagajui/agentic_prd, https://github.com/Saml1211/PRD-MCP-Server, https://github.com/SeeknnDestroy/agentic-prd-generation — OSS AI-PRD-generator cluster

**§2 (Professional products):**
- https://www.productboard.com/ + https://www.productboard.com/integrations/jira/
- https://www.aha.io/ + https://www.aha.io/product/integrations/github + https://www.aha.io/blog/just-launched-two-way-jira-integration-now-supports-custom-fields
- https://www.productplan.com/ + https://www.productplan.com/glossary/rice-scoring-model
- https://roadmunk.com/
- https://linear.app/ + https://linear.app/method + https://linear.app/docs/github-integration + https://linear.app/changelog
- https://www.atlassian.com/software/jira + https://www.atlassian.com/software/confluence/templates/product-requirements + https://www.atlassian.com/agile/product-management/requirements
- https://www.notion.com/ + https://www.notion.com/templates/category/product-requirements-doc
- https://coda.io/ + https://coda.io/@colin-bryar/working-backwards-how-write-an-amazon-pr-faq
- https://clickup.com/, https://monday.com/, https://asana.com/, https://www.figma.com/figjam/, https://craft.io/, https://airfocus.com/
- 2026 comparison: https://www.featurebase.app/blog/aha-vs-productboard, https://www.spotsaas.com/compare/roadmunk-vs-productplan-vs-productboard

**§3 (Methodologies):**
- JTBD: https://strategyn.com/jobs-to-be-done/, https://strategyn.com/jobs-to-be-done/history-of-jtbd/, https://jtbd.info/know-the-two-very-different-interpretations-of-jobs-to-be-done-5a18b748bd89; Christensen et al. *Competing Against Luck* (HarperBusiness 2016)
- RICE: https://www.intercom.com/blog/rice-simple-prioritization-for-product-managers/
- Kano: https://www.productplan.com/glossary/kano-model
- Story Mapping: Patton *User Story Mapping* (O'Reilly 2014/2024), https://www.amazon.com/User-Story-Mapping-Discover-Product/dp/1491904909
- Impact Mapping: Adzic *Impact Mapping* (2012), https://www.amazon.com/Impact-Mapping-Software-Products-Projects/dp/0955683645
- OST: Torres *Continuous Discovery Habits* (2021), https://www.producttalk.org/opportunity-solution-trees/
- Lean Canvas / BMC: Maurya *Running Lean* (O'Reilly 2010/2022), Osterwalder & Pigneur *Business Model Generation* (Wiley 2010), https://en.wikipedia.org/wiki/Business_model_canvas
- OKRs: Grove *High Output Management* (1983), Doerr *Measure What Matters* (Portfolio 2018), Wodtke *Radical Focus* (2016), https://en.wikipedia.org/wiki/Objectives_and_key_results, https://www.whatmatters.com/
- North Star: https://amplitude.com/books/north-star
- Design Thinking: https://dschool.stanford.edu/, https://web.stanford.edu/~mshanks/MichaelShanks/files/509554.pdf, https://www.ideo.com/journal/build-your-creative-confidence-empathy-maps
- Lean Startup: Ries *The Lean Startup* (Crown 2011), https://theleanstartup.com/principles
- Customer Development: Blank *The Four Steps to the Epiphany* (2005/2013), https://steveblank.com/tag/customer-development/
- Empathy Map: https://medium.com/@davegray/updated-empathy-map-canvas-46df22df3c8a
- Five Whys: https://en.wikipedia.org/wiki/Five_whys, https://www.atlassian.com/incident-management/postmortem/5-whys
- Cagan: https://www.svpg.com/, *Inspired* (Wiley 2017), *Empowered* (Wiley 2020), *Transformed* (Wiley 2024)

**§4 (PRD templates):**
- https://www.atlassian.com/software/confluence/templates/product-requirements
- https://www.atlassian.com/software/confluence/templates/lennys-product-requirements
- https://workingbackwards.com/resources/working-backwards-pr-faq/
- https://www.lennysnewsletter.com/p/my-favorite-templates-issue-37
- https://www.notion.com/templates/category/product-requirements-doc
- https://linear.app/method/write-issues-not-user-stories
- https://www.reforge.com/blog/product-requirement-document-prd-templates
- https://productschool.com/blog/product-strategy/product-template-requirements-document-prd

**§5 (Interview frameworks):**
- Fitzpatrick *The Mom Test* (2013), https://www.momtestbook.com/
- Blank *Four Steps to the Epiphany* (2005), https://steveblank.com/tag/customer-development/
- Alvarez *Lean Customer Development* (O'Reilly 2014/2017), https://www.cindyalvarez.com/lean-customer-development/
- Christensen et al. *Competing Against Luck* (2016), https://strategyn.com/jobs-to-be-done/history-of-jtbd/
- Torres *Continuous Discovery Habits* (2021), https://www.producttalk.org/
- Cooper *The Inmates Are Running the Asylum* (Sams 1999) / *About Face* (Wiley 2014), https://www.dubberly.com/articles/alan-cooper-and-the-goal-directed-design-process.html
- NNG: https://www.nngroup.com/articles/discovery-phase/

**§6 (AI/LLM PM tools):**
- https://www.chatprd.ai/
- https://www.productboard.com/ (Productboard AI)
- https://www.aha.io/ (Aha! AI)
- https://linear.app/changelog (Linear Agent)
- https://www.notion.com/product/ai
- https://www.prodpad.com/blog/ai-tools-for-product-managers/
- https://chisellabs.com/blog/how-to-write-prd-using-ai/
- https://aipmtools.org/articles/ai-changing-product-management (wave taxonomy reference)
- https://learnprompting.org/blog/ai-tools-for-product-managers, https://blog.productmanagementsociety.com/7-essential-ai-tools-for-product-managers-in-2025-3/
- CLI agent comparisons: https://www.deployhq.com/blog/comparing-claude-code-openai-codex-and-google-gemini-cli-which-ai-coding-assistant-is-right-for-your-deployment-workflow, https://intuitionlabs.ai/articles/claude-code-vs-codex-vs-gemini-cli-comparison

**§7 (Integration patterns):**
- https://support.productboard.com/hc/en-us/articles/11535151728275-Getting-started-with-Productboard-s-Jira-Integration
- https://www.aha.io/blog/just-launched-two-way-jira-integration-now-supports-custom-fields
- https://linear.app/docs/github-integration
- https://unified.to/blog/polling_vs_webhooks_when_to_use_one_over_the_other
- https://www.freecodecamp.org/news/api-integration-patterns/
- https://workmanagementhub.com/linear-github-sync-troubleshooting-2026/ (Linear sync troubleshooting, 2026)

### §10.3 — Source-quality notes

- Vendor sites are authoritative for vendor capabilities but biased toward favorable framing. Cross-referenced with 2026 third-party comparisons (Featurebase, ProductFolio, NocoBase) where possible.
- Book references include publisher and year for traceability.
- 2026-dated comparison articles were used for pricing because pricing changes annually; older pricing data may be stale.
- Where AI-tool vendor claims are uncorroborated (e.g., "100,000 PMs"), the claim is attributed but not independently verified.
