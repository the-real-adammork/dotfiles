---
name: secrets
description: "Use when Codex encounters suspected secrets, credentials, tokens, private keys, .env files, or secret-bearing configuration and must prevent unsafe inspection, disclosure, logging, staging, or commits. This automatic safety policy does not authorize generating credentials, choosing storage, or operating git-secret."
---

# Secrets

Apply these safeguards whenever secret material may be present:

- Do not open, copy, print, or log suspected existing secret values merely to inspect them.
- Do not expose secret values in responses, documentation, comments, test output, or command output.
- Add a narrow `.gitignore` rule immediately when an untracked path appears secret-bearing.
- Never stage or commit unsafe plaintext secrets.
- Escalate before using credentials that grant access to existing accounts, customer data, production infrastructure, billing, funds, deployment authority, or identity authority.
- Preserve suspected secret files in place unless the user explicitly authorizes a safe operation.

Before committing or reporting completion:

1. Run `/usr/bin/git status --short`.
2. Verify no plaintext secret path is staged.
3. Verify narrow ignore rules protect any local plaintext secret files.
4. Run available secret scanning tools, such as `gitleaks`, when present.
5. Report unresolved handling risks without revealing secret values.

This skill supplies guardrails only. Require explicit invocation of `$credential-management` to classify, generate, rotate, or choose storage for credentials. Require explicit invocation of `$git-secret` to encrypt or decrypt repository secret files.
