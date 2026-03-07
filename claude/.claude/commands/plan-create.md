# Plan Create Skill

Guide for creating implementation plans.

## Plan Location and Naming

Save plans in `design/plans/` directory:
- Use kebab-case for filenames: `plan-<short-description>.md`
- Check existing plans to determine appropriate naming

**Examples:**
- `design/plans/plan-navigation-redesign.md`
- `design/plans/plan-dark-mode-improvements.md`

## Plan Structure

```markdown
# Plan: Plan Title

**Status:** Draft
**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD

## Overview
Brief description of the design feature and its purpose.

## Goals
- Goal 1
- Goal 2

## Non-Goals
What this plan explicitly does not cover.

## Design Specifications

### Visual Requirements
- Colors, typography, spacing, etc.

### Components
- List of components or assets needed

### Responsive Behavior
- How the design adapts across breakpoints

## Implementation Steps
1. Step one
2. Step two

## Dependencies
- Any existing tokens, assets, or external resources needed

## Open Questions
- [ ] Question 1
- [ ] Question 2

## References
- Links to inspiration, related plans, or external resources
```

## Status Icons

Use these status indicators:
- `Draft` - Plan being written/reviewed
- `In Progress` - Currently implementing
- `Completed` - Fully implemented and merged
- `On Hold` - Implementation paused/blocked
- `Abandoned` - No longer pursuing this approach

## After Creating a Plan

1. Add status header with Draft status
2. Update `design/plans/README.md` index (if it exists)
3. Present plan summary to user
4. **Wait for approval before implementation**
5. Plans may be iterated based on feedback
