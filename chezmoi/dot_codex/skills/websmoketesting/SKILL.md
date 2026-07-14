---
name: websmoketesting
description: "Use when Codex needs to write, run, debug, or report web smoke tests and E2E checks for a product website or web app, especially with Playwright, real user journeys, durable login accounts, page coverage, service integration proof, and real-data validation."
---

# Web Smoke Testing

For any product with a website or web app, verify important behavior with Playwright. Test the product the way a normal user would use it, not as isolated units.

## Core Rule

Use Playwright to prove the integrated system works end to end:

- navigate through real pages and user flows;
- use the UI a human would use;
- expect real data and real service responses;
- verify all important pages are reachable;
- verify key functionality works together across frontend, backend, persistence, jobs, and external/local services;
- treat unexpected UI/API/data results as a coding or integration failure first, not as a reason to weaken the test.

If the app cannot be tested like a normal user because stable credentials or seed data are missing, flag that as an implementation issue. Fix it by adding durable local/test accounts and seed data. Use the `account-seeding` skill for credential handling.

## Durable Accounts

Smoke tests should use durable local/test accounts, not one-off manual signup unless the signup flow itself is under test.

Expected credential source:

```text
account.env
```

The plaintext `account.env` must be ignored and encrypted with `git-secret` as `account.env.secret`. Do not print secrets. If the account file is absent or cannot be revealed, the smoke test is blocked on account seeding, not complete.

## Writing Tests

Prefer the repo's existing Playwright setup and scripts. If none exists, add the smallest conventional setup that fits the repo.

Write tests around human-visible outcomes:

- use semantic locators such as roles, labels, and accessible names;
- avoid brittle CSS selectors unless no user-facing selector exists;
- avoid arbitrary sleeps;
- assert page content, navigation, persisted data, API-backed state, and error-free user paths;
- include login, navigation, create/read/update flows, and critical empty/error/success states when relevant;
- capture screenshots/traces/videos on failure when the repo supports it.

Do not add smoke-test instructions, reviewer notes, local setup guidance, or handoff text to product UI or seeded user-facing content. Those belong in docs/artifacts, not in the app.

## Failure Classification

Classify failures this way:

- `product_failure`: user-visible behavior is broken or data is wrong.
- `integration_failure`: services are not wired together, real data does not flow, or persistence/jobs/API behavior is missing.
- `test_setup_failure`: server, port, browser, env, seed account, or fixture setup is missing.
- `test_bug`: assertion is stale, brittle, or does not match the product requirement.

Default to `product_failure` or `integration_failure` when Playwright reaches the app but gets the wrong real response. Fix the code or seed path first. Rewrite the test only after confirming the test expectation is wrong.

## Reporting

Report concisely:

- command run and result;
- URL, browser, viewport/device;
- account source used, without secret values;
- pages and user flows covered;
- real services/data verified;
- artifacts such as screenshots, traces, videos, and logs;
- failure classification and next fix.
