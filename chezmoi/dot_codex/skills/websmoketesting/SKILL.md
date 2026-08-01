---
name: websmoketesting
description: "Manually invoked workflow for writing, running, debugging, or reporting Playwright smoke tests and browser E2E checks for real user journeys. Use only when the user explicitly invokes $websmoketesting."
---

# Web Smoke Testing

Verify explicitly requested web behavior with Playwright. Test the product the way a normal user would use it, not as isolated units.

## Authorization Boundary

- Perform only the requested operations: report, run existing tests, write or update tests, or debug failures.
- Running tests may start required local services and browsers. It does not authorize changing product code, test infrastructure, accounts, credentials, or external resources.
- Write or update tests only when the user explicitly asks. If Playwright is not configured, report the missing setup unless the request authorizes adding it.
- Do not create or seed accounts, change credential material, fix product code, or record proof videos unless the user explicitly requests that action.
- Classify and report failures before proposing the next action. Apply a fix only when the user asks for implementation.

## Core Rule

Use Playwright to prove the integrated system works end to end:

- navigate through real pages and user flows;
- use the UI a human would use;
- expect real data and real service responses;
- verify all important pages are reachable;
- verify key functionality works together across frontend, backend, persistence, jobs, and external/local services;
- treat unexpected UI/API/data results as a coding or integration failure first, not as a reason to weaken the test.

If stable credentials or seed data are missing, report the smoke test as blocked and recommend explicit use of `$account-seeding`. Do not create accounts as part of this skill unless the user separately authorizes that work.

## Durable Accounts

Smoke tests should use durable local/test accounts, not one-off manual signup unless the signup flow itself is under test.

Expected credential source:

```text
account.env
```

The plaintext `account.env` must be ignored and encrypted with `git-secret` as `account.env.secret`. Do not print secrets. If the account file is absent or cannot be revealed, report the smoke test as blocked.

## Writing Tests

When the user asks to write or update tests, prefer the repo's existing Playwright setup and scripts. Add a new setup only when the request explicitly includes it.

Write tests around human-visible outcomes:

- use semantic locators such as roles, labels, and accessible names;
- avoid brittle CSS selectors unless no user-facing selector exists;
- avoid arbitrary sleeps;
- assert page content, navigation, persisted data, API-backed state, and error-free user paths;
- include login, navigation, create/read/update flows, and critical empty/error/success states when relevant;
- preserve failure artifacts produced by the existing Playwright configuration; do not enable new screenshot, trace, or video capture unless the user asks.

Do not add smoke-test instructions, reviewer notes, local setup guidance, or handoff text to product UI or seeded user-facing content. Those belong in docs/artifacts, not in the app.

## Failure Classification

Classify failures this way:

- `product_failure`: user-visible behavior is broken or data is wrong.
- `integration_failure`: services are not wired together, real data does not flow, or persistence/jobs/API behavior is missing.
- `test_setup_failure`: server, port, browser, env, seed account, or fixture setup is missing.
- `test_bug`: assertion is stale, brittle, or does not match the product requirement.

Default to `product_failure` or `integration_failure` when Playwright reaches the app but gets the wrong real response. Report the failure without changing product code or seed data. Rewrite a test only after confirming its expectation is wrong and only when the request authorizes test changes.

## Reporting

Report concisely:

- command run and result;
- URL, browser, viewport/device;
- account source used, without secret values;
- pages and user flows covered;
- real services/data verified;
- artifacts such as screenshots, traces, videos, and logs;
- failure classification and next fix.
