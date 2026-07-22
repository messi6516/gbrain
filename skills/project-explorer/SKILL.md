---
name: project-explorer
version: 1.0.0
description: |
  Ingest and analyze any open-source project into gbrain as a structured knowledge base:
  domain model extraction, architecture mapping, workflow tracing, and refactoring guidance.
  Supports two entry modes: batch analysis sweep (full pass) and interactive query-driven
  enrichment (continuous learning on user questions). Designed for first-principles codebase
  comprehension: structure, semantics, dynamics, constraints, and evolution.
triggers:
  - "explore this project"
  - "analyze codebase"
  - "understand architecture"
  - "what does this project do"
  - "domain model extraction"
  - "business logic analysis"
  - "refactoring guidance"
  - "migration plan"
  - "project onboarding"
  - "codebase exploration"
  - "open source analysis"
tools:
  - search
  - query
  - get_page
  - put_page
  - add_link
  - add_timeline_entry
  - get_links
  - get_backlinks
  - traverse_graph
  - resolve_slugs
  - sync_brain
mutating: true
writes_pages: true
writes_to:
  - _gbrain/
---

# Project Explorer — First-Principles Codebase Analysis for Refactoring

> **Convention:** Read `skills/conventions/brain-first.md` before starting any lookup.
> **Convention:** See `skills/conventions/quality.md` for citation and back-link rules.
> **Convention:** See `skills/conventions/brain-routing.md` for source isolation rules.
>
> External static analysis tools (dependency-cruiser, cloc, AST parsers) feed data INTO
> this skill. They are not a replacement for it. gbrain provides the persistent knowledge
> graph + multi-dimensional retrieval that makes their output queryable and cumulative.
>
> **Source strategy:** This skill creates a dedicated gbrain source per project
> (`--source <project-slug>`). All analysis pages live inside that source. Cross-project
> queries use `--source` switching or cross-source federation. The user's personal brain
> (`host`) stays untouched.
>
> **Prerequisites:** `gbrain init` completed, gbrain CLI installed and on `$PATH`,
> project source code available locally.
>
> **Companion setup script:** `skills/project-explorer/setup-project.sh` automates Phase 1.

## Contract

This skill guarantees:

- **Completeness by coverage.** Every identified domain entity, module, and workflow
  has a corresponding gbrain page with typed links to related pages. The knowledge graph
  is traversable: `gbrain graph <any-entity> --depth 2` returns a connected view.
- **First-principles decomposition.** Analysis proceeds through five irreducible
  dimensions of codebase comprehension: structure (directory/package layout), semantics
  (domain entities and their meaning), dynamics (data/control flow), constraints
  (invariants, business rules, contracts), and evolution (change history).
- **Traceable refactoring path.** Every refactoring invariant is documented as a page
  in `_gbrain/invariants/`, cross-linked to the modules it constrains. Migration steps are
  timeline entries on the project overview page. Correctness is auditable by checking
  invariant pages against the refactored code.
- **Continuous accumulation.** Each user question triggers a brain-first check, then
  enriches pages with new findings. The knowledge base deepens with use rather than
  being a one-shot analysis artifact.
- **Source isolation.** All project analysis lives under its own `--source <slug>`.
  No cross-contamination with the user's personal brain.

## Phases

### Phase 0: Trigger Detection

This skill activates when the user either:

1. **Explicitly requests onboarding** -- "analyze this project", "explore this codebase",
   "understand this architecture", "onboard this project into gbrain"
2. **Asks a project-specific question** -- "how does the payment module work in
   acme-project", "what are the domain entities in foo-bar", "show me the data flow in
   widget-lib"
3. **Requests refactoring guidance** -- "I want to refactor this project", "migration
   plan for baz-service", "what are the invariants I must preserve"

For case (1), run the full sweep (Phases 1-4), then enter Phase 5 (continuous).
For cases (2) and (3), run Phase 5 directly (query-driven enrichment), which will
backfill specific gaps as they arise.

### Phase 1: Project Onboarding (Setup)

**Goal:** Register the project in gbrain and import its source code.

1. **Determine project slug.** Normalize the project name to a gbrain-safe slug
   (`<org>-<project>` format, lowercase, hyphens only).

2. **Create the gbrain source:**

   ```bash
   gbrain sources add <project-slug> --path <project-dir>
   ```

   Verify: `gbrain sources current --source <project-slug>`

3. **Import code files into gbrain:**

   ```bash
   # Import source code (prioritized: src/ > lib/ > root *.py/js/ts/go/rs files)
   gbrain import <project-dir> --source <project-slug> --no-embed

   # Import documentation
   gbrain import <project-dir>/docs --source <project-slug> --no-embed 2>/dev/null

   # Import top-level config files (package.json, Cargo.toml, pyproject.toml, etc.)
   gbrain import <project-dir> --source <project-slug> --no-embed \
     --include '*.{json,toml,yaml,yml}'

   # Embed all chunks
   gbrain embed --stale --source <project-slug>
   ```

   The companion script `setup-project.sh` runs the above automatically.

4. **Create the project overview page:**

   Put a page at `_gbrain/overview` in the project source:

   ```bash
   gbrain put _gbrain/overview --source <project-slug> \
     --content "..."
   ```

   Frontmatter: `type: project`, `language`, `framework`, `build_system`.
   Body: project description from README, detected language, build system,
   package manager, dependency count, file count, entry points found.

5. **Create the architecture overview page:**

   ```bash
   gbrain put _gbrain/architecture --source <project-slug> \
     --content "..."
   ```

   Body: high-level module map as ASCII diagram or structured list.
   Each module entry includes the directory path and a one-line responsibility.

6. **Link the overview pages:**

   ```bash
   gbrain link _gbrain/overview _gbrain/architecture \
     --link-type contains --source <project-slug>
   ```

**Deliverable:** A functional gbrain source containing the project code, searchable
via `query`, plus two anchor pages (`_gbrain/overview`, `_gbrain/architecture`)
that serve as the entry points for all subsequent phases.

### Phase 2: Architecture Discovery

**Goal:** Map the project's structural skeleton -- entry points, module boundaries,
inter-module dependencies, external interfaces.

This phase operates on the **structure** and **dynamics** dimensions of first-principles
decomposition.

1. **Identify entry points.** Search for common entry-point patterns:

   ```
   gbrain query "entry point main function or CLI definition" --source <project-slug>
   gbrain query "server startup HTTP handler route registration" --source <project-slug>
   gbrain query "dependency injection container configuration" --source <project-slug>
   ```

   For each entry point found, create a page at `_gbrain/architecture/entry-<name>` with:
   - File location (absolute path + line number)
   - What it initializes (modules, connections, middleware)
   - Link to architecture overview via `gbrain link ... --link-type called_by`

2. **Map module boundaries.** For each top-level package/directory:

   - Search for its exported API surface: `gbrain query "public API surface of <module-name>" --source <project-slug>`
   - Determine responsibility: what business concern does this module own?
   - Identify cross-module imports: what other modules does it depend on?
   - Create a page at `_gbrain/architecture/<module-slug>` with:
     ```
     ## Responsibility
     {one-paragraph description}
     ## Public API
     {key functions/classes exported}
     ## Dependencies
     {list of other modules it imports}
     ## Used By
     {list of modules that depend on it}
     ## External Dependencies
     {third-party packages used, if notable}
     ```
   - Link each module page to the overview and to its dependents.

3. **Identify external system boundaries.** Search for:
   - HTTP client calls, database connections, message queue producers/consumers
   - File system reads/writes, environment variable access
   - Third-party API integrations
   - Create `_gbrain/architecture/external-<system>` pages for each integration point.

4. **Create the module-dependency index page:**

   ```
   gbrain put _gbrain/module-map --source <project-slug> --content "..."
   ```

   Body: a dependency matrix or directed-graph description showing which modules
   depend on which, plus external boundaries. Cross-link to every module page.

**Deliverable:** One page per architectural module + external system, all linked in
a dependency graph. The module map page serves as the queryable dependency matrix.

### Phase 3: Domain Model Extraction

**Goal:** Identify and document the project's domain objects, their relationships,
and the business rules that constrain them.

This phase operates on the **semantics** and **constraints** dimensions of
first-principles decomposition. It requires LLM reasoning because domain entities
are semantic units, not syntactic ones -- two projects can model "Order" completely
differently even if both use the same class name.

1. **Discover domain entity candidates.** Search the imported code for:

   ```
   gbrain query "class definitions struct or type representing business concept" --source <project-slug>
   gbrain query "entity aggregate root domain model" --source <project-slug>
   gbrain query "value object enum constants defining domain concepts" --source <project-slug>
   ```

   Use `think` for synthesis when the entity pattern is distributed across files
   rather than defined in one place:

   ```
   gbrain think \
     "What are the core domain entities in this project? List each with the file
     where it's defined, what it represents in business terms, and what business
     rules govern it." \
     --source <project-slug>
   ```

2. **For each domain entity, create a domain page:**

   ```
   gbrain put _gbrain/domain/<entity-name> --source <project-slug> --content "..."
   ```

   Body template:
   ```
   ---
   type: domain-entity
   defined_in: <file-path>
   ---
   # <Entity Name>

   ## Business meaning
   {What real-world concept this represents, in business language, not code language}

   ## Structure
   {Key fields/properties with business meaning. Not an exhaustive list -- only
   the ones that carry business semantics.}

   ## Business rules / invariants
   {Rules that must always be true for this entity. These become refactoring invariants.}

   ## Relationships
   - relates to: <other-entity> (via <field or method>) -- {nature of relationship}

   ## Ownership
   {Which module/package owns this entity's definition and lifecycle}

   ## Code reference
   {Back-link to the defining file and key usages: `[Source: <file>:<line>]`}
   ```

3. **Map entity relationships.** For each entity-entity pair found:

   ```
   gbrain link _gbrain/domain/<entity-a> _gbrain/domain/<entity-b> \
     --link-type <aggregates|contains|references|inherits-from|depends-on> \
     --source <project-slug>
   ```

   Create aggregate root pages where applicable. For entities that form a lifecycle
   boundary (aggregate), create an `_gbrain/analysis/bounded-contexts` page that summarizes
   the service boundaries.

4. **Create workflow/process pages.**

   Identify core end-to-end flows (e.g., "user places order", "payment processed",
   "report generated"). For each:

   ```
   gbrain put _gbrain/workflows/<flow-name> --source <project-slug> --content "..."
   ```

   Body:
   ```
   ## Trigger
   {What starts this flow -- user action, event, cron, etc.}
   ## Steps
   {Sequential steps, each referencing the module and domain entity involved}
   ## Data flow
   {What data is transformed, stored, or transmitted at each step}
   ## Error states
   {What can go wrong and how it's handled}
   ## Invariants preserved
   {Business rules that must hold throughout the flow}
   ## Entry points
   {API endpoint, CLI command, event handler that triggers this flow}
   ```

   Link workflows to the domain entities they touch.

**Deliverable:** A complete domain model as gbrain pages, each with typed links
forming a traversable knowledge graph. Business rules are captured as refactoring
invariants. Workflows show how the entities interact at runtime.

### Phase 4: Knowledge Graph Reconciliation

**Goal:** Wire the architecture pages and domain pages into a unified graph that
supports cross-dimensional queries.

1. **Cross-link pages.** For every domain entity page, add links to:
   - The module that owns it (`_gbrain/architecture/<module>` with type `owned_by`)
   - Every workflow where it participates (`_gbrain/workflows/<flow>` with type `used_in`)
   - The project overview (`_gbrain/overview` with type `part_of`)

   For every module page, add links to:
   - Each domain entity it owns (`_gbrain/domain/<entity>` with type `owns`)
   - Its dependency modules (`_gbrain/architecture/<dep>` with type `depends_on`)
   - External system pages (`_gbrain/architecture/external-<sys>` with type `connects_to`)

2. **Create analysis synthesis pages** for cross-cutting concerns:

   ```
   _gbrain/analysis/coupling-patterns      -- tight coupling hotspots, circular deps
   _gbrain/analysis/layer-violations        -- cross-layer dependencies that shouldn't exist
   _gbrain/analysis/unused-code             -- orphaned modules, dead code paths
   _gbrain/analysis/testing-strategy        -- test coverage by module, test patterns
   _gbrain/analysis/configuration-surface   -- env vars, config files, feature flags
   _gbrain/analysis/tech-debt               -- known issues, workarounds, TODOs from code
   ```

   These pages are seeded from the code search, then enriched over time via
   user questions and deeper analysis.

3. **Run link extraction.**

   ```bash
   gbrain extract links --source-id <project-slug>
   ```

   This materializes any mention-based links discovered from the page bodies
   into the typed `links` table.

4. **Verify graph connectivity.**

   Run a traversal from the project overview to ensure the graph is connected:

   ```
   gbrain graph _gbrain/overview --source <project-slug> --depth 3
   ```

   Review the output. Any page that has zero incoming links from other project
   pages is a gap -- go back and add the missing links.

**Deliverable:** A fully connected knowledge graph. Every page is reachable from
`_gbrain/overview` via typed edges in 3 or fewer hops. Cross-cutting analyses
are seeded and linked to the relevant modules/entities.

### Phase 5: Continuous Learning (Interactive / Query-Driven)

**Goal:** Every user interaction with this project enriches the knowledge base.
This is the default mode after initial setup.

This skill listens for project-specific questions and follows this protocol:

1. **Brain-first lookup.** Before answering, check what gbrain already knows:

   ```
   gbrain query "<user's question>" --source <project-slug>
   gbrain search "<keywords from question>" --source <project-slug>
   ```

2. **If the knowledge exists and is current:**

   - Answer with citations to the relevant pages.
   - If the user adds new information, update the page via `gbrain put <slug> --source <project-slug> --content "..."`.

3. **If the knowledge is incomplete or missing:**

   a. **Deep-dive into source code.** Use targeted queries to find the relevant
      code sections:

      ```
      gbrain query \
        "<question-specific search, e.g. how is payment authorization handled>" \
        --source <project-slug>
      ```

      Use `think` when the question requires synthesis across multiple files:

      ```
      gbrain think \
        "<user's question, phrased as a research task>" \
        --source <project-slug>
      ```

   b. **Create or enrich pages.** Based on findings:
      - If the answer reveals a new domain entity: create `_gbrain/domain/<entity>` page
      - If it reveals new module relationships: update `_gbrain/architecture/<module>` page
      - If it describes a new flow: create `_gbrain/workflows/<flow>` page
      - If it identifies a new invariant: create `_gbrain/invariants/<name>` page and
        link it to the relevant modules
      - Add a timeline entry documenting what was learned:

        ```
        gbrain call add_timeline_entry \
          '{"slug":"_gbrain/overview","date":"YYYY-MM-DD","summary":"Learned: {what was discovered}"}' \
          --source <project-slug>
        ```

   c. **Propagate links.** Connect the new page to existing ones via `gbrain link <from> <to> --link-type <type> --source <project-slug>`.

   d. **Answer with full context.** Include citations to the new pages.

4. **Document knowledge gaps.** If a question genuinely cannot be answered from
   the code alone (e.g., business rationale for a design decision), create an
   entry at `_gbrain/analysis/knowledge-gaps`:

   ```
   - **YYYY-MM-DD** | {unanswered question} | [Source: user query]
   ```

   These gaps become inputs to the refactoring phase -- they signal places where
   the business intent needs explicit documentation before migration.

**Deliverable:** Every user question either returns an answer from the knowledge
base or enriches it. The graph grows over time. Gaps are tracked explicitly so
the refactoring phase knows where intent recovery is needed.

### Phase 6: Refactoring Guidance

**Goal:** Use the accumulated knowledge base to define a target architecture,
identify migration invariants, and track refactoring progress.

This phase creates a **sibling source** (`<project-slug>-target`) to isolate
the target architecture from the current-state analysis:

```bash
gbrain sources add <project-slug>-target --path <project-dir>
```

#### Step 6a: Define Target Architecture

1. **Create the target architecture overview:**

   ```
   gbrain put _gbrain/architecture --source <project-slug>-target --content "..."
   ```

   Body: the target architecture in the chosen style (hexagonal, clean architecture,
   DDD tactical layers, event-driven, etc.). Include:
   - Boundary definitions (bounded contexts)
   - Module responsibilities (what stays, what moves, what is new)
   - Interface contracts between modules (ports)
   - Data ownership schema (which module owns which entities)
   - Technology decisions (framework updates, language features)

2. **Create future-state domain pages:**

   For each domain entity that needs to change:
   ```
   gbrain put _gbrain/domain/<entity> --source <project-slug>-target --content "..."
   ```
   Document what changes, what stays the same, and why.

3. **Link target back to current state:**

   ```
   gbrain link _gbrain/domain/<entity> _gbrain/domain/<entity> \
     --link-type evolves-from --source <project-slug>-target
   ```

   (The `--source` points to the target source; the `--to` slug references a page
   in the current source. The agent resolves this cross-source reference.)

#### Step 6b: Document Migration Invariants

Every refactoring has things that must NOT change. These are invariants.
Create a page per invariant at `_gbrain/invariants/<name>` (in the **current** source):

```
---
type: invariant
source_of_truth: <file path or external contract>
---
# <Invariant Name>

## Business rule
{What must always be true, in business language}

## Technical constraint
{How this manifests in code -- function signature, data format, response contract}

## Module boundary
{Which module(s) this invariant constrains}

## Test coverage
{Link to relevant test file(s)}

## Risk in refactoring
{What goes wrong if this invariant is violated}

## Cross-references
- Link to: _gbrain/domain/<entity> (type: constrains)
- Link to: _gbrain/workflows/<flow> (type: guards)
```

**Types of invariants to identify (first-principles breakdown):**

| Dimension | Invariant type | Example |
|-----------|---------------|---------|
| Structure | Module boundary | "Payment module never imports from UI module" |
| Semantics | Domain rule | "Order total must equal sum of line items" |
| Dynamics | Data contract | "API response always includes id and created_at" |
| Constraints | Business policy | "Free tier users cannot exceed 1000 requests/day" |
| Evolution | Migration contract | "Database migration must be backward-compatible for one release" |

After creating all invariants, verify connectivity:

```
gbrain graph _gbrain/overview --source <project-slug> --depth 3
```

Every invariant page should be reachable from the modules/entities it constrains.

#### Step 6c: Plan Incremental Migration

1. **Read the current knowledge base:**

   ```
   gbrain query "module boundaries and dependencies" --source <project-slug>
   gbrain graph _gbrain/overview --source <project-slug> --depth 3
   ```

2. **Define migration phases.** Each phase is a timeline entry on the project
   overview in the target source:

   ```
   gbrain call add_timeline_entry \
     '{"slug":"_gbrain/architecture","date":"YYYY-MM-DD","summary":"Phase N: {brief description}","detail":"{what modules move, what changes, what invariants to check}"}' \
     --source <project-slug>-target
   ```

3. **For each phase, identify:**
   - What code moves (specific files, modules)
   - Which invariants are at risk (link to `_gbrain/invariants/<name>`)
   - Verification step (test command, audit query)
   - Rollback criteria

4. **Track progress.** As the refactoring proceeds, update the current-state
   pages to reflect the new reality. Mark migrated modules with a tag or
   timestamped note:

   ```
   gbrain put _gbrain/architecture/<module> --source <project-slug> \
     --content "(existing content)

   ## Refactoring Status
   - Status: migrated to target
   - Migrated: YYYY-MM-DD
   - Target page: --source <project-slug>-target _gbrain/architecture/<module>"
   ```

#### Step 6d: Verify Completeness Before/After Each Phase

For each migration step, run a completeness check:

1. **Load all invariants** that constrain the module being refactored:

   ```
   gbrain search "type:invariant" --source <project-slug>
   gbrain call get_links '{"slug":"_gbrain/architecture/<module>"}' --source <project-slug>
   ```

2. **For each invariant**, read its page and verify the refactored code satisfies it.
   This is a human-AI collaboration: the agent surfaces the invariants with their
   original code locations; the user (or test suite) confirms they still hold.

3. **Check cross-source consistency.** Query both sources for the same domain
   concept and compare:

   ```
   # Query current state
   gbrain query "order domain rules" --source <project-slug>
   # Query target state
   gbrain query "order domain rules" --source <project-slug>-target
   ```

   Look for contradictions between current-state invariants and target-state design.
   Any contradiction means the migration plan needs adjustment.

4. **Update the timeline.** Record what was verified and what passed/failed:

   ```
   gbrain call add_timeline_entry \
     '{"slug":"_gbrain/overview","date":"YYYY-MM-DD","summary":"Verification: Phase N {passed/failed} -- {findings}"}' \
     --source <project-slug>
   ```

**Deliverable:** A target architecture source, a complete set of migration invariants
linked to the current-state pages, a phased migration plan as timeline entries, and
a repeatable verification protocol for each phase.

## Output Format

All analysis is stored as gbrain pages within the project's source. There is no
separate output artifact -- the knowledge base IS the output.

For interactive questions (Phase 5), the agent responds in the conversation with:
- Direct answer to the user's question
- Citations to the relevant gbrain pages: `[Source: <project>:_gbrain/domain/<entity>]`
- A brief note on what was learned and enriched (if new pages were created)

For refactoring guidance (Phase 6), the agent presents:
- A summary of the target architecture
- The invariant list with risk levels
- The phased migration plan
- The verification protocol

## Anti-Patterns

- **Flat analysis.** Creating a single "analysis dump" page instead of a linked graph
  of entity pages, module pages, and workflow pages. The graph IS the analysis.
  Never collapse it into a monolith.
- **Source confusion.** Writing project analysis into the default (host) source instead
  of a project-specific source. Cross-contamination makes future retrieval ambiguous.
- **Skipping brain-first.** Answering a project question from general LLM knowledge
  without first checking what the analysis graph contains. The graph is authoritative
  for this project.
- **One-shot analysis.** Running the full sweep once and never enriching. The value
  compounds with every interaction. Phase 5 (continuous learning) is the default mode,
  not an afterthought.
- **Silent graph breaks.** Removing a module or entity page without updating the links
  from dependent pages. Use `gbrain graph <slug> --depth 2` regularly to detect
  orphaned references.
- **Undocumented invariants.** Assuming "everyone knows this can't change" without
  creating an invariant page. If it's not in the graph, it can be violated during
  refactoring without detection.
- **Target architecture as spec.** Writing the target architecture as a fixed spec
  rather than a living set of pages that evolve as refactoring reveals new constraints.

## Related skills

- `skills/query/SKILL.md` -- for the retrieval primitives used throughout
- `skills/enrich/SKILL.md` -- for entity page enrichment patterns
- `skills/schema-author/SKILL.md` -- if you need custom page types for domain analysis
- `skills/maintain/SKILL.md` -- for ongoing graph health after the initial analysis
- `skills/repo-architecture/SKILL.md` -- for filing conventions

## Error recovery

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `gbrain sources add` fails | Source slug conflicts with existing source | Choose a more specific slug (`<org>-<project>` rather than bare `<project>`) |
| `gbrain query` returns nothing | Source not specified, or embed incomplete | Verify `gbrain sources current --source <slug>`, re-run `gbrain embed --stale --source <slug>` |
| `gbrain graph` returns zero edges | Links not created or extract not run | Run `gbrain extract links --source-id <slug>`, check link count with `gbrain stats` |
| Knowledge gaps page is growing | Questions about business intent, not code structure | This is expected. Flag these gaps as refactoring prerequisites -- don't try to infer business intent from code alone. |
