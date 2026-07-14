# Plan to Tasks Skill

Transform an approved plan into detailed, implementable task documents. Uses the avant-garde-designer agent to ensure aesthetic decisions are explicit and verifiable.

## Purpose

Plans describe **what** to build. Tasks describe **how** to build it, with enough detail that an agent without deep design experience can implement and verify each step correctly.

## When to Use

- After a plan is approved (status: Draft → In Progress)
- Before starting implementation
- When the plan involves visual/aesthetic decisions that need explicit guidance

## Arguments

```
/plan-to-tasks <plan-name>
```

**Examples:**
```
/plan-to-tasks breathing-progress-slats
/plan-to-tasks navigation-redesign
```

If no argument provided, prompt for plan selection from `design/plans/`.

---

## Output Structure

Creates a tasks folder alongside the plan:

```
design/plans/
├── plan-breathing-progress-slats.md          # The plan
└── plan-breathing-progress-slats-tasks/      # NEW: Tasks folder
    ├── README.md                             # Task index and overview
    ├── task-01-foundation.md                 # First task
    ├── task-02-breathing-animation.md        # Second task
    └── ...
```

---

## Task Document Template

Each task document follows this structure:

```markdown
# Task NN: [Task Title]

**Plan:** plan-<name>.md
**Prerequisites:** task-01, task-02 (or "None" for first task)
**Estimated complexity:** Low | Medium | High

## Objective

One sentence describing what this task accomplishes.

## Context

Why this task matters in the overall plan. What visual/UX goal it serves.

## Design Rationale

Explain the aesthetic decisions behind this task:
- Why these specific values (colors, spacing, timing)?
- What visual effect are we creating?
- How does this connect to the brand language?

This section should read like guidance from a senior designer.

## Prerequisites Check

Before starting, verify:
- [ ] Previous task(s) complete and verified
- [ ] Required files exist: `path/to/file.css`
- [ ] Required tokens available in colors.json

## Step-by-Step Implementation

### Step 1: [Action]

**File:** `path/to/file.css`
**Location:** After line N / Inside selector X

```css
/* Exact code to add */
.selector {
  property: value;
}
```

**Why this code:** Brief explanation of what this achieves visually.

### Step 2: [Action]

(repeat pattern)

## What NOT to Do

Common mistakes to avoid:
- ❌ Don't use `property: X` — it causes [problem]
- ❌ Don't add this to [wrong location] — it belongs in [right location]
- ❌ Don't skip the dark mode variant

## Verification Criteria

All must pass before this task is complete:

### Visual Checks
- [ ] Element appears at correct position (screenshot reference if needed)
- [ ] Colors match tokens: `--token-name` should render as `#hexvalue`
- [ ] Animation timing feels [descriptor]: approximately Xs

### Code Checks
```bash
# Command to verify (e.g., grep for expected code)
grep -n "expected-selector" design/brand-guide/shared/styles.css
```

### Browser Checks
- [ ] Chrome: [specific behavior]
- [ ] Safari: [specific behavior]
- [ ] Firefox: [specific behavior or fallback note]

### Responsive Checks
- [ ] Desktop (1200px+): [expected state]
- [ ] Tablet (768-1199px): [expected state]
- [ ] Mobile (<768px): [expected state]

## Commit Checkpoint

After verification passes:
```bash
/usr/bin/git add [files]
/usr/bin/git commit -m "feat(brand-guide): [task description]"
```

## Next Task

Proceed to: `task-NN+1-[name].md`
```

---

## Workflow

### 1. Read the Plan

```bash
# Read the source plan
cat design/plans/plan-<name>.md
```

Identify:
- Implementation steps (from plan)
- Visual requirements
- Technical dependencies
- Open questions (must be resolved before creating tasks)

### 2. Launch Avant-Garde Designer Agent

Use the Task tool to spawn the avant-garde-designer agent:

```
Analyze the plan at design/plans/plan-<name>.md and create detailed implementation tasks.

For each implementation step in the plan:
1. Break it into atomic, verifiable tasks
2. Specify exact code with file locations
3. Explain the design rationale — why these specific values?
4. Define visual verification criteria
5. Note browser/responsive considerations

The tasks should be detailed enough that an agent without design experience
can implement them correctly by following instructions literally.

Focus on making aesthetic choices EXPLICIT:
- Don't say "use appropriate spacing" — say "use 16px (--spacing-4)"
- Don't say "animate smoothly" — say "8s ease-in-out, amplitude 3%"
- Don't say "match the brand" — say "use saturated-lavender-550 (#575886)"

Output format: Create individual task markdown files following the template.
```

### 3. Create Tasks Folder

```bash
mkdir -p design/plans/plan-<name>-tasks
```

### 4. Generate Task Index (README.md)

Create `design/plans/plan-<name>-tasks/README.md`:

```markdown
# Tasks: [Plan Title]

**Source Plan:** [plan-<name>.md](../plan-<name>.md)
**Generated:** YYYY-MM-DD
**Total Tasks:** N

## Overview

Brief description of what these tasks accomplish together.

## Task Sequence

| # | Task | Description | Complexity |
|---|------|-------------|------------|
| 01 | [Foundation](./task-01-foundation.md) | Set up CSS custom properties | Low |
| 02 | [Breathing Animation](./task-02-breathing.md) | Implement idle animation | Medium |
| ... | ... | ... | ... |
| NN | [Final Testing](./task-NN-testing.md) | Cross-browser verification | Low |

## Dependencies Graph

```
task-01 ──► task-02 ──► task-03
                  └──► task-04 ──► task-05
```

## Verification Summary

Final checks after all tasks complete:
- [ ] All individual task verifications pass
- [ ] Full page renders without errors
- [ ] Animations perform smoothly (60fps)
- [ ] Reduced motion preference respected
- [ ] Dark mode fully functional
```

### 5. Write Individual Task Files

For each task, create `task-NN-<name>.md` following the template above.

### 6. Update Plan Status

Note in the plan that tasks have been generated:

```markdown
## Implementation

Tasks generated: See [plan-<name>-tasks/](./plan-<name>-tasks/)
```

---

## Quality Criteria for Tasks

Good tasks are:

1. **Atomic** — One clear objective, completable in a focused session
2. **Explicit** — No ambiguity about values, locations, or expected outcomes
3. **Verifiable** — Clear pass/fail criteria, not subjective assessments
4. **Sequential** — Dependencies are clear, order is logical
5. **Self-contained** — All needed context is in the task (no hunting through the plan)

Bad tasks:
- ❌ "Style the component appropriately"
- ❌ "Make it look good"
- ❌ "Add animation" (what kind? what timing? what triggers?)

Good tasks:
- ✅ "Add breathing animation: scaleY transform, 8s duration, 3% amplitude, ease-in-out"
- ✅ "Set primary slat color to --saturated-lavender-550 (#575886)"

---

## Example: Breaking Down a Plan Step

**Plan says:**
> "Implement breathing animation — Create `@keyframes slat-breathe`, apply to both slats with offset"

**Tasks created:**

**Task 02: Breathing Animation Keyframes**
- Add `@keyframes slat-breathe` to styles.css
- Values: scaleY(1) → scaleY(1.03) → scaleY(1)
- Duration reference: 8s (set via `--slat-breathe-duration`)

**Task 03: Apply Breathing to Primary Slat**
- Add animation property to `.slat--primary`
- Use: `slat-breathe var(--slat-breathe-duration) ease-in-out infinite`
- Verify: slat height oscillates ~3% over 8 seconds

**Task 04: Apply Breathing to Secondary Slat with Offset**
- Add same animation to `.slat--secondary`
- Add `animation-delay: -1.5s` for organic offset
- Verify: secondary trails primary by ~1.5s

---

## Integration with Plan-Start

After running `/plan-to-tasks`, the `/plan-start` skill will detect the tasks folder and guide implementation through the task sequence rather than the raw plan steps.
