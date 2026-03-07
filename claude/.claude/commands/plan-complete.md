# Plan Complete Skill

Guide for completing a plan implementation and merging to main.

## Before Completing

1. **Review all changes** made on the branch that were not part of the original plan

2. **Update the plan document** to reflect any additional changes, scope adjustments, or discoveries

3. **Add "Implementation Notes" section** if significant deviations occurred:
   ```markdown
   ## Implementation Notes

   Changes made during implementation that differed from the original plan:
   - Added X because...
   - Modified approach to Y due to...
   ```

---

## Step 1: Push Feature Branch

From your feature branch:
```bash
/usr/bin/git push -u origin <branch-name>
```

---

## Step 2: Switch to Main

**Worktree workflow:**
```bash
cd ../spare-parts
```

**Traditional workflow:**
```bash
/usr/bin/git checkout main
```

---

## Step 3: Squash Merge

```bash
/usr/bin/git pull
/usr/bin/git merge --squash <branch-name>
/usr/bin/git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

Implements Plan: <plan title>

<summary of key changes>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Step 4: Update Plan Status

1. **Update the plan file:**
   ```markdown
   **Status:** Completed
   **Completed:** YYYY-MM-DD
   **Implementation Commit:** <squashed-commit-hash>
   ```

2. **Update `design/plans/README.md` index** (if exists):
   - Change status to Completed
   - Add completion date
   - Add squashed commit hash

3. **Commit the status update:**
   ```bash
   /usr/bin/git add design/plans/
   /usr/bin/git commit -m "docs(plans): mark plan as completed"
   ```

4. **Push main:**
   ```bash
   /usr/bin/git push origin main
   ```

---

## Step 5: Cleanup

**Worktree workflow:**
```bash
# Remove the worktree
/usr/bin/git worktree remove ../spare-parts-plan-<short-name>

# Verify
/usr/bin/git worktree list
```

**Traditional workflow:**
No cleanup needed. Branch remains for historical reference.

---

## Plan Status Lifecycle

| Status | Meaning |
|--------|---------|
| Draft | Created, awaiting approval |
| In Progress | Implementation started |
| Completed | Squash-merged to main |
| On Hold | Temporarily stopped |
| Abandoned | No longer pursuing |
