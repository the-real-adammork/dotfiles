---
name: secrets
description: "Use when Codex needs to classify, generate, store, encrypt, ignore, reveal, hide, commit, review, or verify secrets and credentials, including .env files, app keys, JWT/session secrets, database passwords, API tokens, cloud credentials, git-secret usage, project posture decisions, and checks that plaintext secrets are not staged."
---

# Secrets

Handle secrets through one canonical policy. Use this skill before generating, writing, revealing, hiding, staging, committing, or reviewing credentials or secret-bearing config.

## Start

Announce: "I'm using the secrets skill to classify and handle secret material safely."

First classify:

1. Project posture.
2. Secret type.
3. Whether the agent may generate it.
4. Storage handling: safe plaintext, ignored plaintext, `git-secret`, environment-only, or human-provided.

## Project Posture

- `side-project/greenfield` - personal, demo, prototype, or new app with no existing users/customer data and no irreversible external side effects.
- `internal/demo` - shared internal or demo environment where generated secrets are acceptable only for isolated non-production resources.
- `production/customer` - existing users, customer data, billing, regulated data, production infrastructure, or real external account access.

If the user says side project, demo, prototype, or greenfield app without existing users, default to `side-project/greenfield` unless requirements contradict it.

## Generation Policy

| Secret Type | side-project/greenfield | internal/demo | production/customer |
| --- | --- | --- | --- |
| App/JWT/session/encryption secrets for new app environments | Agent may generate | Agent may generate for isolated demo envs | Escalate unless explicitly approved |
| Database usernames/passwords for newly created environments | Agent may generate | Agent may generate for isolated demo envs | Escalate for shared/prod DBs |
| Staging/production app secrets for new side-project infra | Agent may generate when infra is newly created and not tied to existing sensitive data | Escalate if shared | Escalate |
| Local/dev/test secrets, salts, seeded admin passwords | Agent may generate | Agent may generate | Agent may generate only for local/test |
| Cloud provider account keys or credentials | Escalate | Escalate | Escalate |
| Third-party API tokens tied to real accounts, billing, quotas, customer data, or account takeover risk | Escalate | Escalate | Escalate |
| Crypto wallets, private keys controlling funds, signing keys for real releases/domains | Escalate | Escalate | Escalate |

Escalate for any credential that grants access to an existing external account, customer data, deployment authority, billing/funds movement, production infrastructure, or identity authority.

## Storage Policy

- Safe demo values may be committed only when explicitly non-secret and harmless.
- Unsafe plaintext must be ignored immediately before or when materialized.
- Unsafe generated secrets that need to be versioned must be stored through repo secret tooling such as `git-secret`.
- Do not print secrets in logs.
- Do not stage plaintext secrets.
- Do not open or print suspected existing secret files just to inspect them.

## git-secret Workflow

Use when unsafe secret material must be committed encrypted:

1. Add a narrow `.gitignore` rule for the plaintext path.
2. Generate or update the plaintext secret file.
3. Run `git secret add <path>`.
4. Run `git secret hide -d`.
5. Stage only `.gitsecret/...`, `<path>.secret`, and the `.gitignore` rule.
6. Verify the plaintext path is not staged and preferably absent after `hide -d`.

If `git-secret` is unavailable, add the plaintext path to `.gitignore`, do not commit plaintext, and record an escalation or setup task.

## Verification

Before committing or reporting completion:

- run `/usr/bin/git status --short`;
- verify no plaintext secret path is staged;
- verify expected `.secret` files are staged when using `git-secret`;
- verify `.gitignore` protects plaintext paths;
- run available secret scan tooling if present, such as `gitleaks`;
- report any unresolved secret handling gaps.

## Worker Result Fields

When implementation workers touch secret material, their result must include:

```yaml
secret_material_changed: true
secret_posture: "side-project/greenfield"
secrets:
  - name: "JWT_SECRET"
    generated_by: "agent"
    storage: "git-secret"
    plaintext_ignored: true
    committed_plaintext: false
    verification:
      - command: "/usr/bin/git status --short"
        result: "no plaintext secret staged"
```
