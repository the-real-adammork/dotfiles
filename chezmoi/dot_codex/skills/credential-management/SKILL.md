---
name: credential-management
description: "Manually invoked workflow for classifying project posture and credential risk, generating approved local/test credentials, rotating credentials, and choosing between environment-only, ignored plaintext, safe placeholder, human-provided, or encrypted storage. Use only when the user explicitly invokes $credential-management."
---

# Credential Management

Classify and manage credentials without exposing their values.

## Classify

Determine:

1. Project posture.
2. Credential type and authority.
3. Whether Codex may generate it.
4. Required storage.

Use these project postures:

- `side-project/greenfield`: personal, prototype, or new app without existing users, customer data, or irreversible external effects.
- `internal/demo`: shared internal or demo environment; generated credentials are acceptable only for isolated non-production resources.
- `production/customer`: existing users, customer data, billing, regulated data, production infrastructure, or real external account access.

## Generation Policy

Codex may generate:

- app, JWT, session, and encryption secrets for local or new side-project environments;
- database credentials for newly created local or isolated demo environments;
- local development and test secrets, salts, and seeded test-account passwords;
- isolated demo credentials that do not grant access to existing accounts or sensitive data.

Require explicit user approval for:

- shared, staging, or production credentials;
- cloud-provider account keys;
- third-party tokens tied to real accounts, billing, quotas, customer data, or account takeover risk;
- signing keys for real releases or domains;
- credentials controlling funds, production infrastructure, deployment authority, or identity.

Never invent credentials for an existing external account.

## Storage

Choose the narrowest suitable option:

- safe non-secret placeholder committed to the repository;
- environment-only injection;
- ignored local plaintext;
- human-provided credential stored outside the repository;
- encrypted repository storage.

Before materializing unsafe plaintext, add a narrow `.gitignore` rule. Do not print generated values in logs or responses. Do not stage plaintext.

If encrypted repository storage is required, stop after classifying the credential and ask the user to invoke `$git-secret`. Do not operate `git-secret` from this skill.

## Verification

- Run `/usr/bin/git status --short`.
- Verify plaintext secret paths are ignored and not staged.
- Run `gitleaks` or another available secret scanner.
- Report variable names and file paths, not secret values.
