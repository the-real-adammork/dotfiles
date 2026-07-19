---
name: commit
description: Use when the user asks to commit changes, create a git commit, generate a commit message, or invokes "/commit". Guides Codex through safe diff inspection, intentional staging, and Conventional Commit message generation.
---

# Commit

Create a safe, focused git commit with a concise Conventional Commit message.

## Core Rules

- Honor repo instructions first, including a required git binary such as `/usr/bin/git`.
- Never commit suspected secrets, credentials, tokens, private keys, or untracked files that appear sensitive.
- Never run destructive git commands such as `reset --hard`, `checkout --`, `clean`, or force push unless the user explicitly requests that exact operation.
- Never change git config.
- Never skip hooks with `--no-verify` unless the user explicitly asks.
- Prefer one logical change per commit. If unrelated changes are present, stage only the files that belong together and explain what was left unstaged.
- Keep the workflow fast: inspect status and relevant diffs, produce a message, commit, and report the result. Avoid broad repo exploration unless needed to understand the commit.
- If the user asks for a commit subagent or fast commit-message generation, use the deterministic subagent flow below.

## Deterministic Fast Subagent Flow

Use this flow only when the user explicitly asks for a subagent, commit subagent, or fastest Codex model for commit-message generation.

- The parent agent always owns file staging and the actual `/usr/bin/git commit` in the real workspace.
- The subagent must never stage files, commit, amend, reset, clean, push, or change repository state.
- Spawn exactly one subagent with model `gpt-5.6-terra` and reasoning effort `low`.
- Give the subagent only the relevant status and diff text needed to write the message.
- Ask the subagent to return exactly this format:

  ```text
  subject: <type>[optional scope]: <description>
  body:
  <optional body, or empty>
  rationale: <one short sentence>
  ```

- If the requested model is unavailable or the subagent fails, fall back to local commit-message generation rather than choosing a different model.
- The parent agent must review the returned message against the staged diff before committing.

## Workflow

1. Check status:

   ```bash
   /usr/bin/git status --porcelain
   ```

2. Inspect the diff:

   ```bash
   /usr/bin/git diff --staged
   /usr/bin/git diff
   ```

   If staged changes exist, treat them as the intended commit by default. If nothing is staged, inspect the working tree and stage the smallest coherent set of files.

3. Check untracked files by name only. If an untracked path looks like it may contain secrets, add a narrowly scoped `.gitignore` rule for that path before continuing, and do not open or print it.

4. Stage intentionally:

   ```bash
   /usr/bin/git add path/to/file
   ```

   Avoid `git add -A` unless every changed file clearly belongs to the same commit.

5. Generate the commit message:

   ```text
   <type>[optional scope]: <description>
   ```

   Use present tense, imperative mood, and keep the first line under 72 characters.

6. Commit:

   ```bash
   /usr/bin/git commit -m "<type>[scope]: <description>"
   ```

   For meaningful context, use a body:

   ```bash
   /usr/bin/git commit -m "$(cat <<'EOF'
   <type>[scope]: <description>

   <body>
   EOF
   )"
   ```

7. Report the resulting commit hash and subject:

   ```bash
   /usr/bin/git log -1 --oneline
   ```

## Commit Types

- `feat`: new user-facing capability
- `fix`: bug fix
- `docs`: documentation-only change
- `style`: formatting or presentation change without behavior change
- `refactor`: code restructuring without feature or bug fix
- `perf`: performance improvement
- `test`: add or update tests
- `build`: dependencies, packaging, build tooling
- `ci`: CI configuration or workflows
- `chore`: maintenance that does not fit another type
- `revert`: revert a previous commit

## Scope Guidance

Use a short scope when it clarifies the affected area, such as `zsh`, `nvim`, `brew`, `install`, `auth`, `ui`, or a package/module name. Omit the scope when it would be vague.

## Breaking Changes

Use `!` after the type or scope, and include a `BREAKING CHANGE:` footer when helpful:

```text
feat!: remove deprecated endpoint

BREAKING CHANGE: the old endpoint path is no longer supported.
```

## Hook Failures

If commit hooks fail, read the hook output, fix the problem when it is in scope, rerun relevant checks, and create a new commit attempt. Do not bypass hooks unless the user explicitly asks.
