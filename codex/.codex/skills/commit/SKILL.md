---
name: commit
description: Use when the user asks Codex to create a git commit, prepare a commit message, or commit the current work while following repository conventions and avoiding unrelated changes.
---

# Commit Skill

Create a git commit following project conventions.

## Commit Message Format

Use Conventional Commits: `<type>(<scope>): <description>`

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`

**Examples:**
- `feat(character-generator): add ImageKit remote persistence support`
- `fix(scene-compositor): correct alpha channel handling`
- `refactor(persistence): separate image generation from I/O`

## Branch Naming

Use type prefix matching commit convention: `<type>/<description>`

**Examples:** `feat/storybook-db-persistence`, `fix/character-scale`, `refactor/persistence-protocols`

## Workflow

1. Run `/usr/bin/git status` to see untracked and modified files
2. Run `/usr/bin/git diff` to review staged and unstaged changes
3. Run `/usr/bin/git log --oneline -3` to see recent commit message style
4. Analyze the changes and draft a commit message:
   - Summarize the nature of the changes
   - Focus on the why rather than the what
   - Do not commit files that may contain secrets, such as `.env` or `credentials.json`
   - Do not stage unrelated user changes
5. Stage only relevant files with `/usr/bin/git add`
6. Create the commit using a heredoc for proper formatting:

```bash
/usr/bin/git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

Co-Authored-By: OpenAI Codex <codex@openai.com>
EOF
)"
```

7. Run `/usr/bin/git status` to verify success

## Important

- Always use `/usr/bin/git` instead of `git` to avoid SCM Breeze conflicts
- If the commit fails due to pre-commit hooks, fix the issue and create a new commit
- Do not amend or push unless explicitly requested
