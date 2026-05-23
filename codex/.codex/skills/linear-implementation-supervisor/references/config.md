# Config

Expected non-secret `.codex/linear.toml` fields include:

```toml
state_backend = "sqlite"
state_db = ".codex/workflows/state.sqlite"
legacy_state_mode = "archived"

team_key = "ENG"
admin_user_email = "adam@example.com"
project_naming_prefix = "My Feature"
default_labels = ["codex", "implementation-plan"]
create_missing_labels = true

handoff_dir = "docs/handoffs"
run_log_dir = "docs/linear/runs"
smoke_test_dir = "docs/linear/smoke-tests"
human_review_dir = "docs/linear/reviews"

status_todo = "Todo"
status_in_progress = "In Progress"
status_blocked = "Blocked"
status_agentic_review = "Agentic Review"
status_human_review = "In Review"
status_done = "Completed"

worktree_dir = ".worktrees"
branch_template = "codex/{feature}/{plan_slug}"
task_branch_template = "codex/{feature}/{plan_slug}/{issue_id}-{task_slug}"
merge_completed_plan_branches = true
merge_target_branch = ""
merge_target_worktree = ""
remote_name = "origin"
pr_provider = "gitlab"
pr_create_command = ""
pr_link_required_for_human_review = true

poll_interval_minutes = 5
human_review_timeout_minutes = 60
human_review_mode = "event_driven" # event_driven | polling

assign_blocked_to_admin = true
assign_human_review_to_admin = true
block_on_existing_test_failures = true
context_handoff_threshold_percent = 70

worker_dispatch = "supervisor"
worker_model = ""
reviewer_model = ""
worker_reasoning_effort = "medium"
reviewer_reasoning_effort = "medium"
fix_worker_reasoning_effort = "medium"
merge_worker_reasoning_effort = "low"
```

Never store Linear credentials in this config.

If `state_db` is missing, default to `.codex/workflows/state.sqlite`. If `state_backend` is not `sqlite`, stop and ask the user to migrate or update config.
