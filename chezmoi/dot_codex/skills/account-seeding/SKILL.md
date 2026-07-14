---
name: account-seeding
description: "Use when Codex needs to add or verify durable local/test accounts for an app or service, seed databases for repeatable login, create account.env credentials, encrypt credentials with git-secret, and support smoke tests or E2E tests that require stable authentication."
---

# Account Seeding

Use durable local/test accounts so smoke tests and E2E tests can log in repeatably.

Use the `secrets` skill before generating, writing, revealing, encrypting, staging, committing, or reviewing credentials.

## Policy

- Seed durable local/test accounts for apps that require login.
- Store local/test account credentials in `account.env`.
- Add an exact `.gitignore` rule for `account.env`.
- Encrypt `account.env` with `git-secret`, producing `account.env.secret`.
- Commit the encrypted secret file and git-secret metadata, never the plaintext `account.env`.
- Do not print passwords, tokens, or secret values in logs, docs, comments, or final responses.

## Expected Workflow

1. Classify the project and secret type with the `secrets` skill.
2. Add or update a seed script/migration/factory that creates durable local/test accounts.
3. Create or update `account.env` with the account identifiers and generated local/test credentials.
4. Add `account.env` to `.gitignore` with a narrow path rule.
5. Run `git secret add account.env`.
6. Run `git secret hide -d`.
7. Verify plaintext `account.env` is not staged and `account.env.secret` is present.
8. Document only the account names/emails and the credential file path. Do not document secret values.

If `git-secret` is unavailable, ignore `account.env`, do not commit plaintext credentials, and report a setup blocker.

## Account File Shape

Prefer simple env vars:

```sh
E2E_ADMIN_EMAIL=admin@example.test
E2E_ADMIN_PASSWORD=<secret>
E2E_USER_EMAIL=user@example.test
E2E_USER_PASSWORD=<secret>
```

Use project-specific names when the existing test harness already expects them.

## Verification

Before completion:

- run the seed/setup command;
- verify the accounts can authenticate locally;
- run the relevant smoke/E2E login path;
- run `/usr/bin/git status --short`;
- verify plaintext `account.env` is not staged;
- verify encrypted `account.env.secret` and git-secret metadata are staged when committing.
