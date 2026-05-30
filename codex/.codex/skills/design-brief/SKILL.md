---
name: design-brief
description: "Use when Codex needs to create a design-facing brief for an existing app, summarizing every current page, the functionality each page supports, and backend data schemas/fields available for future UI designs beyond what the API currently exposes."
---

# Design Brief

Create a design-facing overview of the current app. The brief should help a designer understand what pages exist, what each page does today, and what data is available behind the scenes for richer UI ideas.

## Workflow

1. Inspect the app's routes, navigation, page components, layouts, and existing screenshots or design docs.
2. Inspect API routes, handlers, view models, client data fetching, and state stores to understand what the UI currently uses.
3. Inspect backend data schemas, ORM models, migrations, SQL, fixtures, seeds, serializers, generated types, and domain models to identify fields and relationships the system has access to even when they are not currently exposed in the UI or API.
4. Map each page to supported user-facing functionality and data dependencies.
5. Save the brief under `docs/designs/`.

Prefer repo source of truth over guesses. If the repo has multiple apps, produce one section per app or clearly state the scoped app.

## Data Sources To Check

Look for relevant files such as:

- frontend routes, page files, layouts, navigation config, menus, route manifests;
- Playwright tests, smoke-test notes, story files, screenshots, or product docs;
- API routes, controllers, RPC handlers, serializers, schemas, OpenAPI specs, GraphQL schemas, generated clients;
- database migrations, ORM models, SQL schemas, Prisma/Drizzle/SQLAlchemy/Rails/ActiveRecord/Django models;
- seed data, fixtures, factories, ETL outputs, cached sample payloads, and domain model definitions.

Do not inspect or print secret files. If database access requires credentials that are not already available through safe local commands, rely on schema files and mark live database inspection as unavailable.

## Output Location

Write the brief to:

```text
docs/designs/YYYY-MM-DD-<app-or-feature>-design-brief.md
```

Create `docs/designs/` if missing.

## Brief Shape

Use this Markdown shape:

```markdown
# Design Brief: <App Or Feature>

## Summary

- <what the app currently supports>
- <highest-value design opportunity>
- <major data or UX constraint>

## Sources Reviewed

- `<path>` - <what it showed>

## Page Inventory

| Page | Route | Current Functionality | Current Data Used | Notes |
| --- | --- | --- | --- | --- |
| <page> | `<route>` | <what users can do> | <API/store/model data> | <state, role, empty/error behavior, gaps> |

## Functionality By Flow

| Flow | Pages Involved | Supported Today | Gaps Or Constraints |
| --- | --- | --- | --- |
| <flow> | <pages> | <yes/partial/no> | <notes> |

## Data Available Behind The Scenes

| Data Object | Available Fields | Relationships | Currently Exposed In UI/API | Design Opportunities |
| --- | --- | --- | --- | --- |
| <model/table/type> | <fields> | <relations> | <yes/partial/no and where> | <fields or relationships designers can use> |

## Suggested Design Opportunities

- <page or flow> - <specific UI opportunity backed by available data>

## Unknowns And Follow-Ups

- <schema, behavior, route, or data question that could not be verified>
```

## Rules

- Save the brief in `docs/designs/`; do not leave it only in chat.
- Be comprehensive about pages, but concise about implementation details.
- Distinguish `currently exposed` from `available in schema`.
- Do not claim a field is available unless it appears in code, schema, migrations, fixtures, generated types, or safe inspected data.
- Do not recommend UI fields that would expose secrets, private tokens, internal credentials, or unsafe personal data.
- If a field may be sensitive, flag it and explain the design/privacy concern.
- If the app has no clear route map, infer pages from components and navigation, then mark inferred routes as `unknown`.
- In chat, return the artifact path, major page groups covered, and the most important design opportunities or unknowns.
