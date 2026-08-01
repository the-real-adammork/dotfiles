---
name: git-secret
description: "Manually invoked workflow for encrypting, decrypting, adding, removing, and verifying repository secret files with git-secret and GPG. Use only when the user explicitly invokes $git-secret."
---

# Git Secret

Operate `git-secret` only for a repository that intentionally versions encrypted secret material.

## Preconditions

1. Confirm `git-secret` is installed.
2. Confirm the repository already uses `git-secret`, or obtain explicit user approval to initialize it.
3. Confirm the required GPG recipient configuration exists on this machine.
4. Identify exact plaintext and encrypted paths without printing secret values.

If this machine lacks the required GPG identity, stop. Keep plaintext ignored and do not initialize recipients, import keys, or copy credentials from another machine without explicit approval.

## Encrypt

1. Add a narrow `.gitignore` rule for the plaintext path.
2. Create or update plaintext only when authorized.
3. Run `git secret add <path>` when the path is not already tracked by `git-secret`.
4. Run `git secret hide -d`.
5. Stage only `.gitsecret/...`, `<path>.secret`, and the narrow `.gitignore` change.
6. Verify the plaintext path is absent from the index and preferably removed after encryption.

## Decrypt

1. Confirm the destination is ignored.
2. Run the repository-approved `git secret reveal` command.
3. Do not print or inspect revealed values.
4. Keep revealed plaintext unstaged.

## Verify

- Run `/usr/bin/git status --short`.
- Verify no plaintext secret path is staged.
- Verify expected `.secret` files and `.gitsecret` metadata are present.
- Run `gitleaks` or another available scanner.
- Report paths and outcomes without reporting values.
