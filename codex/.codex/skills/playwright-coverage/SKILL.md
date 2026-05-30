---
name: playwright-coverage
description: "Use when Codex needs to audit Playwright or browser E2E coverage for a web app and report which user-facing flows are covered, partially covered, or missing without writing new tests by default."
---

# Playwright Coverage

Audit Playwright coverage for a web app. Tell the user what flows are covered and what feature flows are not covered.

## Workflow

1. Find the app routes and feature surfaces from the repo's source, docs, specs, navigation, route config, stories, or existing smoke-test notes.
2. Find Playwright tests and config, commonly `playwright.config.*`, `tests/e2e/`, `e2e/`, `playwright/`, or `*.spec.ts`.
3. Map tests to normal user flows, not just files or selectors.
4. Classify each important flow as:
   - `covered`: Playwright exercises the flow through the UI and asserts the user-visible result.
   - `partial`: Playwright reaches part of the flow but misses a key step, state, role, data assertion, or failure path.
   - `missing`: No Playwright test covers the flow.
   - `unknown`: The app surface or test intent is unclear from the repo.
5. Report gaps before suggesting new tests.

## What Counts As A Flow

Use product-facing flows such as:

- unauthenticated landing, signup, login, logout, and password/account paths;
- primary navigation and access to every important page;
- create, read, update, delete, submit, import, export, upload, search, filter, and invite paths;
- role- or permission-specific behavior;
- empty, loading, success, validation-error, and service-error states;
- persistence, background job, notification, email, payment, LLM, or external-service results when visible to the user.

## Report Shape

Return a concise report:

```markdown
## Playwright Coverage

**App Surfaces Reviewed:** <paths or docs>
**Playwright Tests Reviewed:** <paths>

| Flow | Status | Evidence | Gap |
| --- | --- | --- | --- |
| <user flow> | covered/partial/missing/unknown | <test or source path> | <missing assertion or "None"> |

## Highest Priority Missing Flows

1. <flow and why it matters>
2. <flow and why it matters>
3. <flow and why it matters>

## Notes

- <assumptions, unknowns, or test-quality concerns>
```

## Rules

- Do not write new tests unless the user explicitly asks.
- Do not treat unit, API, or component tests as Playwright coverage unless they drive a browser like a user.
- Prefer semantic evidence: routes, page names, user actions, accessible labels, and assertions.
- Flag tests that only check page load or screenshots without asserting product behavior as `partial`.
- If durable accounts or seeded data are required but missing, report the affected flows as blocked or partial and reference the `account-seeding` skill.
- If the repo has no Playwright setup, report the expected critical flows as `missing` and say that no Playwright suite was found.
