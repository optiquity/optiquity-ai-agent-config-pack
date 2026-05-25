# Implementation Report — Research: Product Specialist Landscape

**Date:** 2026-05-24
**Pair doc:** `maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md`
**Agent:** pack-docs-researcher (sidecar session, BD-186 follow-up)
**HEAD at start of work:** `553ab886c8482f0cbb13511806d623dccab17237` (v11-dev branch)
**Output line count:** 985 (research doc) + this report.

---

## 1 — Research methodology

### 1.1 — Search patterns

Searches were structured per the seven SC categories, with a cast-wide-net-first / filter-second approach:

1. **Tool surveys (SC1, SC2, SC6):** Started with broad searches naming several tools per query (e.g., "Productboard ProductPlan Aha Roadmunk comparison"), then drilled into specific tools where signal was high. Cross-validated pricing and feature claims with 2026 third-party comparison articles to avoid relying solely on vendor self-description.

2. **Methodology/framework canon (SC3, SC4, SC5):** Searched by methodology name paired with author name to surface primary sources (book + publisher + year). Where two schools exist (notably JTBD: Christensen vs. Ulwick), searched explicitly for the distinction to surface the orthodoxy split.

3. **Integration patterns (SC7):** Started with technical patterns ("webhook polling two-way sync conflict resolution"), then validated with vendor-documentation searches for specific PM-to-tracker integrations (Productboard ↔ Jira; Linear ↔ GitHub; Aha! ↔ GitHub).

4. **AI/LLM tooling (SC6):** Searched for specific tool names (ChatPRD, ProdPad CoPilot, Linear Agent) and for the broader category trend ("AI changing product management 2026 wave"). Applied explicit vapor-vs-real-value filter; flagged Wave 3 claims as outpacing adoption evidence.

5. **Cross-CLI agent context (§6.13):** Brief search to characterize the multi-CLI coding-agent landscape adjacent to the pack's existing posture (Claude Code, Codex CLI, Gemini CLI). Not core to PM research but contextually relevant.

### 1.2 — Filtering criteria

Quality gates applied throughout per SC8:

- **Mainstream** — multiple primary sources (book + vendor + third-party), taught/cited in established curricula or industry publications.
- **Established** — author-attributed primary source (book, original blog/article), real practitioner adoption.
- **Niche** — real but small community; mentioned for completeness.
- **Controversial** — established but contested; surfaced explicitly.
- **Vapor risk** — claims outpace track record; flagged.

Entries that failed quality gates were either rejected outright (Trac, Redmine in §1.6) or noted-and-flagged (the open-source AI-PRD-generator cluster in §1.5, the "agentic PM" Wave 3 cluster in §6.8).

### 1.3 — What I cast a wide net for and rejected

- **Generic "best PM tools 2026" listicles** — too marketing-noisy; used only for triangulating pricing data, never as primary citation.
- **Single-blog-post claims** — required cross-reference to a primary source (book, vendor doc, author's own published work) before inclusion.
- **Trac, Redmine, Phabricator, MantisBT** — legacy open-source PM tools; effectively in maintenance mode for product-discovery purposes (§1.6).
- **Trello, Basecamp** — light PM usage but not a serious PM platform (§2.16).
- **Wrike, Smartsheet, Workfront** — project-management generalists with thin PM-specific layers (§2.16).
- **"AI product manager" SaaS clusters with strong marketing but unverifiable adoption** — flagged under §6.8 as a category rather than detailed per-vendor.

### 1.4 — Source prioritization

Per the documentation skill methodology:

1. Primary source first (vendor docs, author publications, book references with publisher+year).
2. Original publications over secondary summaries (e.g., Intercom blog for RICE; Ulwick / Strategyn for ODI-JTBD; Torres' Product Talk for OST).
3. 2026-dated third-party comparisons for pricing and current-feature claims (pricing changes annually; older data is stale).
4. Wikipedia used only where consistent with primary sources, as a starting-point for tracking citations back to originals.

---

## 2 — Sources consulted (with dates where available)

### 2.1 — Books cited (primary sources)

- Blank, S. *The Four Steps to the Epiphany.* K&S Ranch (2005, 2nd ed 2013).
- Blank, S. & Dorf, B. *The Startup Owner's Manual.* K&S Ranch (2012).
- Cagan, M. *Inspired: How to Create Tech Products Customers Love.* Wiley (2008, 2nd ed 2017).
- Cagan, M. & Jones, C. *Empowered: Ordinary People, Extraordinary Products.* Wiley (2020).
- Cagan, M. *Transformed.* Wiley (2024).
- Christensen, C., Hall, T., Dillon, K., Duncan, D. *Competing Against Luck.* HarperBusiness (2016).
- Christensen, C. & Raynor, M. *The Innovator's Solution.* Harvard Business Review Press (2003).
- Cooper, A. *The Inmates Are Running the Asylum.* Sams (1999).
- Cooper, A., Reimann, R., Cronin, D., Noessel, C. *About Face: The Essentials of Interaction Design.* Wiley (4th ed 2014).
- Doerr, J. *Measure What Matters.* Portfolio (2018).
- Fitzpatrick, R. *The Mom Test.* Self-published (2013).
- Grove, A. *High Output Management.* Random House (1983).
- Maurya, A. *Running Lean.* O'Reilly (2010, 2nd ed 2012, 3rd ed 2022).
- Osterwalder, A. & Pigneur, Y. *Business Model Generation.* Wiley (2010).
- Patton, J. *User Story Mapping: Discover the Whole Story, Build the Right Product.* O'Reilly (1st ed 2014, 2nd ed 2024).
- Adzic, G. *Impact Mapping.* Provoking Thoughts (2012).
- Ries, E. *The Lean Startup.* Crown Business (2011).
- Torres, T. *Continuous Discovery Habits.* Product Talk LLC (2021).
- Wodtke, C. *Radical Focus.* (2016).
- Alvarez, C. *Lean Customer Development.* O'Reilly (2014, 2nd ed 2017).

### 2.2 — Vendor sites consulted (live 2026-05-21 through 2026-05-24)

See §10.2 of the research doc for the full URL list. Categories:
- §1: OpenProject, Taiga, Plane, Quackback (6 OSS AI-PRD repos).
- §2: Productboard, Aha!, ProductPlan, Roadmunk, Linear, Atlassian (Jira/Confluence), Notion, Coda, ClickUp, monday.com, Asana, Figma, Craft.io, Airfocus.
- §3-§5: Strategyn, Product Talk (Torres), SVPG (Cagan), TheLeanStartup.com, Steve Blank's blog, Cindy Alvarez's site, Mom Test Book, NNG.com, Dubberly.com.
- §6: ChatPRD, ProdPad, Chisel, Linear changelog, Notion AI, Amplitude.
- §7: Productboard Jira-integration docs, Aha! Jira-integration docs, Linear GitHub-integration docs, integration-pattern explainers (Unified.to, freeCodeCamp).

### 2.3 — 2026-dated comparison / trade-press sources

These were used for pricing data and current-feature snapshots (pricing changes annually):
- https://www.featurebase.app/blog/aha-vs-productboard (2026)
- https://www.spotsaas.com/compare/roadmunk-vs-productplan-vs-productboard
- https://userjot.com/blog/top-5-roadmunk-alternatives (2026)
- https://www.techno-pulse.com/2026/04/best-ai-product-management-tools-in.html (2026)
- https://aipmtools.org/articles/ai-changing-product-management (wave taxonomy framing)

### 2.4 — Articles with notable interpretation/framing referenced

- Alan Klement's "Two Very Different Interpretations of JTBD" (https://jtbd.info/know-the-two-very-different-interpretations-of-jobs-to-be-done-5a18b748bd89) — for the JTBD-orthodoxy split.
- Lenny Rachitsky's Newsletter (https://www.lennysnewsletter.com/p/my-favorite-templates-issue-37, /p/how-linear-builds-product) — for the modern PRD-template canon and Linear's product-building approach.
- Linear Method handbook (https://linear.app/method) — for the "write issues not user stories" position that exemplifies a defensible-but-non-default opinion.

---

## 3 — Verification steps performed

1. **Author attribution check.** For each methodology entry, verified that the named author appears in their primary source (book or vendor blog) and that the framework name is not mis-attributed (e.g., confirmed Grove originated OKRs via *High Output Management*; Doerr named and popularized them).
2. **Pricing cross-reference.** Tool pricing was cross-referenced against 2026-dated comparison articles where possible, since vendor pricing pages may be lightly stale.
3. **Tool-grade calibration.** Grades (Mainstream / Established / Niche / Controversial / Vapor risk) were chosen by triangulating (a) primary-source presence, (b) third-party adoption evidence, (c) practitioner-community recognition.
4. **JTBD orthodoxy split.** Verified that both Ulwick (Strategyn) and the Christensen/Moesta camp claim authorship of overlapping-but-distinct frameworks; cited Klement's primary-source explanation for the distinction.
5. **PRD common-denominator section list.** Validated against ≥6 surveyed templates (Atlassian, Lenny's, Yien's, Figma's, ChatPRD output structure, Product School's "only PRD template").
6. **2026 cutoff sanity.** All cited URLs were searched in 2026-05-21 through 2026-05-24 window and were live; publication dates of cited articles are referenced inline where the source provides them.
7. **Wave-taxonomy claim.** The "Wave 1/2/3" framing in §6.11 is paraphrased from multiple trade-press sources; the specific phrasing ("autonomous agents capable of running multi-step workflows autonomously") is taken from the cited trade-press article. Honest framing: this is a popular framing, not a peer-reviewed taxonomy.

---

## 4 — SC mapping (which SC each section satisfies)

| SC | Requirement | Satisfied by |
|----|-------------|--------------|
| SC1 | Open-source PM/discovery tools (≥5 substantive entries) | §1 — 5 named tools (OpenProject, Taiga, Plane, Quackback) + 6 AI-PRD-generator cluster entries with rejection rationale. Each entry: strengths/limitations/popularity signals. |
| SC2 | Professional products (12+ named) | §2 — 15 named tools (Productboard, Aha!, ProductPlan, Roadmunk, Linear, Jira, Notion, Coda, ClickUp, monday.com, Asana, Figma, Craft.io, Airfocus, Jira Product Discovery), each with pricing/features/integrations/target-segment. |
| SC3 | Methodologies + frameworks (12+ named with origin/use/consensus) | §3 — 17 named methodologies + 8 noted-briefly entries. Each with origin/author/primary source/when-to-apply/consensus level. |
| SC4 | PRD templates (5+ canonical) | §4 — 7 named templates (Atlassian, Lenny's, Amazon PR/FAQ, Yien's, Figma's, Productboard/ProductPlan, Notion/Coda community) + common-denominator section list + universal vs. controversial breakdown. |
| SC5 | Interview/discovery frameworks | §5 — 9 frameworks (Mom Test, Customer Development, Lean Customer Dev, JTBD Christensen-school, JTBD Ulwick-school, Continuous Discovery, Cagan's discovery techniques, Generative/Evaluative, Persona/Cooper) + common-pitfalls cross-cut + persona controversy. |
| SC6 | AI/LLM PM tooling (state of the art 2025-2026) | §6 — 9 named tool entries + Wave 1/2/3 taxonomy + integration patterns + cross-CLI agent context (§6.13). Explicit vapor-vs-real framing applied. |
| SC7 | Dev-tool integration patterns (3-5 patterns) | §7 — 7 patterns documented (two-way sync, one-way push, linked-reference, tracker-as-PM, embedded feedback intake, webhook+polling hybrid, GitHub-Issues-specific patterns) + 5 recurring design considerations. |
| SC8 | Quality filter applied throughout | Applied in every section; grades attached to every entry; niche/controversial/vapor flagged explicitly. |
| SC9 | Primary-source URLs cited for every factual claim | Inline citations throughout; §10.2 consolidated URL list by category. |
| SC10 | Cross-category synthesis | §8 — convergence patterns, divergence patterns, gaps, 2025-2026 trends. |
| SC11 | Pack-relevance observations (last section before sources) | §9 — hard-to-do-well caveats, underserved gaps, standard patterns to adopt, LLM-PM-tooling cautious notes, methodology-position recommendations. Descriptive only; no pack design proposed. |
| SC12 | Source-of-truth snapshot (date, URL access pattern) | §10.1 + §10.3 (date and source-quality notes). |

---

## 5 — Open questions I could not resolve from public sources

These items could not be authoritatively resolved within the time/scope of this research pass and are flagged for downstream architect/planner awareness:

1. **Actual adoption numbers for AI PRD tools.** ChatPRD claims "100,000+ PMs" (vendor self-report). I could not find independent third-party adoption verification for any AI-PRD tool. The category is too young and adoption data too marketing-driven.
2. **Open-source AI-PRD-generator cluster trajectory.** The six repos listed in §1.5 have varying star counts (low to modest) and varying activity. Whether any will mature into a canonical option is unknowable in mid-2026.
3. **Productboard AI / Aha! AI / Linear Agent feature parity.** These are evolving fast (2025-2026 quarterly releases). The general comparison in §2/§6 should be revalidated before any design decisions; specific feature claims may already be stale by the next major release cycle.
4. **JTBD orthodoxy split current state.** Both Ulwick and the Christensen-school continue to publish; whether the field is converging or further bifurcating in 2026 is hard to read from public materials. Klement's 2017 article (cited) is the canonical "two schools" reference but pre-dates the LLM-PM wave.
5. **Persona-vs-JTBD debate current state.** Both camps continue to publish. Cagan's vocabulary leans away from personas (problems-to-solve); Cooper-school continues to defend personas-with-goals. No clean industry resolution.
6. **Linear Method adoption beyond Linear users.** Linear's "write issues, not user stories" position is opinionated; whether it's adopted broadly or remains a Linear-internal position is unclear. Anecdotally cited by some PM blogs; not measured.
7. **Pack-side question explicitly out of scope.** What shape (agent / skill / hybrid) the PS feature should take, and what its specific integrations to existing pack primitives (backlog phases groupings) should be, is downstream architect work, not research.

---

## 6 — Honest "harder than expected" notes

- **§6 (AI/LLM PM tooling) was the hardest category to research with rigor.** The space is full of vendor marketing, listicle articles, and Wave 3 / agentic-PM claims with thin track-record backing. I had to apply repeated quality filters and explicitly call out vapor-vs-real. Some Wave-3 vendor claims would have warranted entries on a less-strict bar but were rejected here.
- **§1 (Open-source) is genuinely thin.** Most serious PM tooling is commercial SaaS. The OSS coverage is patchy. The honest answer is that the OSS landscape doesn't have a Productboard-grade peer; entries below that bar are filed at appropriate grades (Established / Niche).
- **§3 (Methodologies) has more entries than typical surveys.** I included 17 named entries because the methodology canon is broad and PMs reach for different frameworks at different stages. Cutting it shorter would distort the landscape.
- **§5 (Interview frameworks) overlaps §3.** Some frameworks (Customer Development, Continuous Discovery, JTBD) appear in both. I retained the overlap to keep each section self-readable rather than forcing the reader to bounce.
- **JTBD's orthodoxy split** required care to surface without taking sides. The text in §3.1 and §5.4/§5.5 treats the split as a fact, with citations on both sides, and flags it for downstream design awareness.
- **The Wave 1/2/3 framing** is paraphrased from trade-press; it's a useful explanatory shorthand but is NOT a peer-reviewed taxonomy. Flagged as such in §6.11.
- **The "pack-relevance observations" section (§9)** required discipline to stay descriptive. The landscape repeatedly surfaces tensions where the pack's existing posture (multi-CLI, project-scoped, opinion-taking, integration-rich) might offer real value. The section flags those without advocating any specific design — that's downstream architect work.

---

## 7 — Files written by this agent

- `maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (985 lines, primary deliverable).
- `maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md` (this file).

No other files were created or modified. Pack source is unchanged (read-only research per the agent contract).

---

## 8 — Recommended next steps (for Pack Chat / downstream)

These are LOGICAL successors, not pack design recommendations:

1. **User review of the landscape doc.** Pack Chat and the user can scan §8 (synthesis) and §9 (pack-relevance) for items to lift into requirements-gathering scope.
2. **Architect-pass for BD-191 (or future PS-feature BD)** would consume this research as input alongside any user-specified scope constraints.
3. **Methodology position decision** is a likely early-design fork (per §9.5 considerations).
4. **Re-validation of fast-moving claims** (§5 open questions) before architect-pass commits to specific positions.


---

End of IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md.
