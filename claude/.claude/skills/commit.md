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
   - Summarize the nature of the changes (new feature, bug fix, refactoring, etc.)
   - Focus on the "why" rather than the "what"
   - Do not commit files that may contain secrets (.env, credentials.json, etc.)
5. Stage relevant files with `/usr/bin/git add`
6. Create the commit using a HEREDOC for proper formatting:

```bash
/usr/bin/git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

7. Run `/usr/bin/git status` to verify success

## Important

- Always use `/usr/bin/git` instead of `git` to avoid SCM Breeze conflicts
- If the commit fails due to pre-commit hooks, fix the issue and create a NEW commit (do not amend)
- Do not push unless explicitly requested
