# Plan Start Skill

Guide for starting implementation of an approved plan.

## Choose a Workflow

| Workflow | Pros | Cons |
|----------|------|------|
| **Worktree** (recommended) | Keeps main clean, parallel work possible | More directories to manage |
| **Traditional branch** | Simpler, single directory | Must stash/commit to switch branches |

---

## Option A: Worktree Workflow (Recommended)

### Directory Structure
```
Projects/
├── spare-parts/                     # main worktree (always exists)
├── spare-parts-plan-nav-redesign/   # plan worktree (temporary)
└── spare-parts-plan-dark-mode/      # another plan worktree (temporary)
```

### Steps

1. **Create branch and worktree together:**
   ```bash
   # From main worktree (spare-parts/)
   /usr/bin/git worktree add -b <type>/plan-<short-description> ../spare-parts-plan-<short-name>

   # Example:
   /usr/bin/git worktree add -b feat/plan-nav-redesign ../spare-parts-plan-nav-redesign
   ```

2. **Change to worktree directory:**
   ```bash
   cd ../spare-parts-plan-<short-name>
   ```

3. **Update plan status** (see Common Steps below)

### Useful Worktree Commands
```bash
/usr/bin/git worktree list    # List all worktrees
/usr/bin/git branch -a        # See all branches
```

### Working in a Worktree

**IMPORTANT:** Always run commands from the worktree directory, not main.

```bash
# Correct - from plan worktree
cd ../spare-parts-plan-nav-redesign
python3 -m http.server 8080   # Serves brand guide with plan changes

# Wrong - from main worktree
cd ../spare-parts
python3 -m http.server 8080   # Serves WITHOUT plan changes!
```

---

## Option B: Traditional Branch Workflow

### Steps

1. **Create and switch to branch:**
   ```bash
   /usr/bin/git checkout -b <type>/plan-<short-description>

   # Example:
   /usr/bin/git checkout -b feat/plan-nav-redesign
   ```

2. **Update plan status** (see Common Steps below)

---

## Common Steps (Both Workflows)

After creating your branch:

1. **Update plan status to In Progress:**
   ```markdown
   **Status:** In Progress
   ```

2. **Update `design/plans/README.md` index** (if it exists) to reflect In Progress status

3. **Commit the status update:**
   ```bash
   /usr/bin/git add design/plans/
   /usr/bin/git commit -m "docs(plans): update plan status to in progress"
   ```

---

## Task-Based Plans

Some plans have a companion tasks folder with detailed implementation guides. Check for one:

```bash
ls design/plans/plan-<name>-tasks/
```

### If a tasks folder exists:

1. **Read the task index** to understand the work breakdown:
   ```bash
   cat design/plans/plan-<name>-tasks/README.md
   ```

2. **Work through tasks sequentially** — Each task document contains:
   - **Prerequisites** — Previous tasks that must be complete
   - **Step-by-step instructions** — Exact code and file locations
   - **Verification criteria** — Tests that must pass before moving on
   - **What NOT to do** — Common mistakes to avoid

3. **Populate your todo list** from the task index to track progress

4. **Complete verification criteria** before moving to the next task — Tasks build on each other, so skipping verification may cause issues later

5. **Update the main plan** — Check off items in the Implementation Steps section as you complete tasks

### Task Execution Flow

```
Read task-01 → Implement → Verify → Mark complete
     ↓
Read task-02 → Implement → Verify → Mark complete
     ↓
   (repeat)
     ↓
Final testing task (task-08 or similar)
```

### Tips for Task-Based Implementation

- **Don't skip ahead** — Later tasks assume earlier ones are complete
- **Run verification commands** — They catch issues early
- **Commit after each task** — Creates clean history and safe restore points
- **If stuck, re-read prerequisites** — You may have missed something

## Branch Naming Convention

Use type prefix: `<type>/plan-<short-description>`

**Types:** `feat`, `fix`, `refactor`, `docs`, `style`, `chore`, `perf`

**Examples:**
- `feat/plan-nav-redesign`
- `refactor/plan-color-tokens`
- `docs/plan-visual-language`
