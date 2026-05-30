# State Files

YAML is the durable machine state. Markdown is the narrative checkpoint. Artifacts are the proof.

## File Layout

```text
docs/implementation-runs/<run-id>/
  run.yaml
  supervisor-inbox/
    <phase-slug>.yaml
  phases/
    <phase-slug>.yaml
  transitions/
    <phase-slug>.yaml
  manifests/
    <phase-slug>.yaml
  watchdogs/
    <phase-slug>.sh
    <phase-slug>-trigger.yaml
  workers/
    <lane>-<timestamp>.yaml
  blockers/
    <blocker-id>.yaml
  events/
    supervisor.jsonl
    orchestrator-<phase-slug>.jsonl
    worker-<lane>-<timestamp>.jsonl
  handoffs/
    <phase-slug>-transition.md
    <timestamp>.md

docs/qa/
  phase-acceptance/
    <phase-slug>.md
  artifacts/
    <phase-slug>/
      <test-output-files>
```

## run.yaml

Tracks only run-level pointers and supervisor-owned lifecycle state. Keep this file small because it lives on the run base branch and is the most likely file to conflict during phase merge-back. Do not embed completed phase details, local verification details, merge reconciliation details, worker state, or copied plan data here; store those in `phases/<phase>.yaml`, `transitions/<phase>.yaml`, handoffs, events, and QA artifacts.

```yaml
run_id: "YYYY-MM-DD-feature"
status: running # running | blocked | complete
execution_scope: run # run | single-phase
slices_document: "docs/plans/SLICES.md"
phases_document: "docs/plans/SLICES.md"
current_phase: "phase-2"
phase_order:
  - phase-1
  - phase-2
phase_plans:
  phase-1: "docs/plans/YYYY-MM-DD-feature-phase-1.md"
  phase-2: "docs/plans/YYYY-MM-DD-feature-phase-2.md"
phase_state:
  phase-1: "docs/implementation-runs/YYYY-MM-DD-feature/phases/phase-1.yaml"
  phase-2: "docs/implementation-runs/YYYY-MM-DD-feature/phases/phase-2.yaml"
transition_state:
  phase-1: "docs/implementation-runs/YYYY-MM-DD-feature/transitions/phase-1.yaml"
active:
  phase: "phase-2"
  phase_state: "docs/implementation-runs/YYYY-MM-DD-feature/phases/phase-2.yaml"
  manifest: "docs/implementation-runs/YYYY-MM-DD-feature/manifests/phase-2.yaml"
  supervisor_inbox: "docs/implementation-runs/YYYY-MM-DD-feature/supervisor-inbox/phase-2.yaml"
  transition_state: null
completed:
  phase-1:
    status: complete
    transition_state: "docs/implementation-runs/YYYY-MM-DD-feature/transitions/phase-1.yaml"
    base_commit_after_merge: "def456def456def456def456def456def456def456def4"
branches:
  base: "main"
  active_phase: "impl/phase-2"
supervisor:
  codex_thread_id: "019e..."
  tmux_session: "project"
  tmux_pane: "%10"
  tmux_window: "project:1"
  workflow_window: "project:workflow"
  cwd: "/absolute/path/to/repo"
  codex_session:
    id: "019e..."
    path: "/Users/example/.codex/sessions/YYYY/MM/DD/session.jsonl"
    role: "supervisor"
    discovered_at: "YYYY-MM-DDTHH:MM:SSZ"
  validation:
    checked_at: "YYYY-MM-DDTHH:MM:SSZ"
    status: valid # valid | invalid | unknown
    reason: null
active_orchestrator:
  phase: "phase-2"
  status: running # starting | running | blocked | acceptance_ready | complete | failed | exiting | invalid
  spawn_method: tmux-pane
  tmux_pane: "%12"
  inbox: "docs/implementation-runs/YYYY-MM-DD-feature/supervisor-inbox/phase-2.yaml"
  launch_command: "codex --dangerously-bypass-approvals-and-sandbox ..."
  codex_session:
    id: "019e..."
    path: "/Users/example/.codex/sessions/YYYY/MM/DD/session.jsonl"
    role: "phase-orchestrator"
    discovered_at: "YYYY-MM-DDTHH:MM:SSZ"
  validation:
    checked_at: "YYYY-MM-DDTHH:MM:SSZ"
    status: valid # valid | invalid | unknown
    reason: null
active_watchdog:
  status: running # starting | running | stopped | failed | disabled
  pid: 12345
  script: "docs/implementation-runs/YYYY-MM-DD-feature/watchdogs/phase-2.sh"
  trigger: "docs/implementation-runs/YYYY-MM-DD-feature/watchdogs/phase-2-trigger.yaml"
  interval_seconds: 120
  tmux_session: "project"
  tmux_window: "project:workflow"
  tmux_pane: "%35"
  wake_method: codex-app-server-turn-start # codex-app-server-turn-start | blocked | disabled
  wake_target:
    supervisor_thread_id: "019e..."
    supervisor_rollout_path: "/Users/example/.codex/sessions/YYYY/MM/DD/rollout-...jsonl"
    supervisor_pane: "%10"
    supervisor_window: "project:1"
    supervisor_session: "project"
  codex_control:
    protocol: codex-app-server
    server_command: "codex app-server"
    smoke_test_status: pass
  wake_blocker: null
  last_checked_at: "YYYY-MM-DDTHH:MM:SSZ"
paths:
  run_dir: "docs/implementation-runs/YYYY-MM-DD-feature"
  events: "docs/implementation-runs/YYYY-MM-DD-feature/events"
  qa_artifacts: "docs/qa/artifacts"
  acceptance_packets: "docs/qa/phase-acceptance"
escalations: []
updated_at: "YYYY-MM-DDTHH:MM:SSZ"
```

`run.yaml` must be edited only by the supervisor on the run base branch. The phase orchestrator, workers, phase-merge sub-agent, phase-transition sub-agent, and phase branches must not edit it. Sub-agents write phase-specific transition state and return a compact result; the supervisor copies only the minimum pointer/status fields into `run.yaml`.

## transition.yaml

Tracks one completed phase's merge, teardown, and post-advance local verification state. It is append-oriented and scoped to a single phase, so phase transitions do not repeatedly conflict in `run.yaml`.

Default path:

```text
docs/implementation-runs/<run-id>/transitions/<phase-slug>.yaml
```

Example:

```yaml
phase: "phase-1"
status: local_verification_running # merge_pending | merge_running | merged | next_started | local_verification_running | complete | blocked | failed
phase_branch: "impl/phase-1"
accepted_phase_commit: "abc123abc123abc123abc123abc123abc123abc123abc1"
base_commit_after_merge: "def456def456def456def456def456def456def456def4"
acceptance_packet: "docs/qa/phase-acceptance/phase-1.md"
transition_handoff: "docs/implementation-runs/YYYY-MM-DD-feature/handoffs/phase-1-transition.md"
trigger:
  path: "docs/implementation-runs/YYYY-MM-DD-feature/watchdogs/phase-1-trigger.yaml"
  handled: true
  handled_at: "YYYY-MM-DDTHH:MM:SSZ"
merge_worker:
  status: complete # not_started | running | ready_for_supervisor | blocked | complete | failed
  agent_id: "agent_abc123"
  started_at: "YYYY-MM-DDTHH:MM:SSZ"
  completed_at: "YYYY-MM-DDTHH:MM:SSZ"
merge_reconciliation:
  status: none # none | preserved | reconciled | blocked_critical | failed
  strategy: "git merge --ff-only"
  safety_branch: null
  decision_log: null
  verification_artifact: "docs/qa/artifacts/phase-1/post-merge-verification.md"
  base_worktree_status_before: "docs/qa/artifacts/phase-1/base-worktree-status-before.z"
  base_worktree_status_after: "docs/qa/artifacts/phase-1/base-worktree-status-after.z"
orchestrator_teardown:
  status: stopped # stopped | failed | skipped
  command: "tmux kill-pane -t %12"
  tmux_pane: "%12"
  stopped_at: "YYYY-MM-DDTHH:MM:SSZ"
next_phase:
  phase: "phase-2"
  started: true
  orchestrator_pane: "%18"
  watchdog_pane: "%19"
transition_worker:
  status: ready_for_report # not_started | running | ready_for_report | blocked | complete | failed
  agent_id: "agent_def456"
  launched_after_next_phase: true
  started_at: "YYYY-MM-DDTHH:MM:SSZ"
  completed_at: "YYYY-MM-DDTHH:MM:SSZ"
local_verification:
  status: running # running | blocked | stopped | failed | not_applicable
  run_command: "pnpm dev --host 127.0.0.1 --port 3000"
  url: "http://localhost:3000"
  tmux_session: "project"
  tmux_window: "project:workflow"
  tmux_pane: "%34"
  pid: 12345
  smoke_report: "docs/qa/artifacts/phase-1/local-verification-smoke-report.md"
  blocker: null
updated_at: "YYYY-MM-DDTHH:MM:SSZ"
```

## phase.yaml

Tracks compact state for one phase:

```yaml
phase: "phase-2"
status: running # not_started | running | blocked | acceptance | complete
plan: "docs/plans/YYYY-MM-DD-feature-phase-2.md"
branch: "impl/phase-2"
worktree: ".worktrees/impl-phase-2"
execution_manifest: "docs/implementation-runs/YYYY-MM-DD-feature/manifests/phase-2.yaml"
active_lanes:
  - lane: "write-path"
    status: agentic_review
    worker: "worker-write-path-1"
    worker_agent: "general-purpose worker"
    branch: "impl/phase-2/write-path"
    worktree: ".worktrees/impl-phase-2-write-path"
orchestrator:
  supervisor_inbox: "docs/implementation-runs/YYYY-MM-DD-feature/supervisor-inbox/phase-2.yaml"
  spawn_method: tmux-pane
  tmux_pane: "%12"
  codex_session:
    id: "019e..."
    path: "/Users/example/.codex/sessions/YYYY/MM/DD/session.jsonl"
    role: "phase-orchestrator"
    discovered_at: "YYYY-MM-DDTHH:MM:SSZ"
  validation:
    checked_at: "YYYY-MM-DDTHH:MM:SSZ"
    status: valid # valid | invalid | unknown
    reason: null
tasks:
  "4":
    status: done
    lane: "write-path"
    commit: "abc123abc123abc123abc123abc123abc123abc123abc1"
    verification:
      - command: "pnpm test:e2e -- user-write-flow"
        result: pass
        artifact: "docs/qa/artifacts/phase-2/write-flow.txt"
service_wiring:
  create-record:
    status: covered
    evidence: "docs/qa/artifacts/phase-2/create-record-trace.zip"
mock_fixture_ledger:
  - id: "mf-001"
    name: "seed user fixture"
    kind: fixture # mock | fixture | fake-service | placeholder | generated-test-data
    introduced_by: "Task 4"
    scope: test-only # test-only | runtime | service-wiring | acceptance-evidence
    affected_paths:
      - "tests/fixtures/users.ts"
    service_wiring_rows:
      - "create-record"
    disposition: test-only # test-only | intentional-phase-boundary | converted | deferred-with-conversion-task | blocked
    acceptable_because: "Seed data only; production path still uses real database."
    conversion_task: null
    evidence:
      - "docs/qa/artifacts/phase-2/create-record-trace.zip"
acceptance:
  status: pending
  packet: "docs/qa/phase-acceptance/phase-2.md"
  commands: []
lessons:
  - path: "docs/lessons/YYYY-MM-DD-slug.md"
    source: "Task 4 review loop"
    applied_to_agents_md: true
blockers:
  - id: "blocker-001"
    status: resolving # reported | resolving | resolved | true_blocker | escalated
    classification: "setup_dependency"
    owner: "blocker-resolver"
    source: "worker-write-path-1"
    source_artifact: "docs/qa/artifacts/phase-2/blocked-command.txt"
    resolver_result: "docs/implementation-runs/YYYY-MM-DD-feature/blockers/blocker-001.yaml"
    summary: "local dev runtime missing"
    human_required: false
    cleared_by: null
updated_at: "YYYY-MM-DDTHH:MM:SSZ"
```

## Supervisor Inbox YAML

The same-session watchdog polls one compact inbox file for the active phase. The supervisor reads it only during launch validation or transition handling. This file is lifecycle state only, not worker or task detail.

```yaml
phase: "phase-2"
orchestrator_status: running # starting | running | blocked | acceptance_ready | complete | failed | exiting
updated_at: "YYYY-MM-DDTHH:MM:SSZ"
heartbeat_expires_at: "YYYY-MM-DDTHH:MM:SSZ"
tmux:
  pane_id: "%12"
codex_session:
  id: "019e..."
  path: "/Users/example/.codex/sessions/YYYY/MM/DD/session.jsonl"
startup:
  acknowledged: true
  manifest: "docs/implementation-runs/YYYY-MM-DD-feature/manifests/phase-2.yaml"
request:
  type: none # none | escalation | phase_completion | graceful_exit | restart_needed
  reason: null
  artifact: null # for true blockers, point at docs/implementation-runs/<run-id>/blockers/<blocker-id>.yaml
phase_completion:
  phase_yaml: "docs/implementation-runs/YYYY-MM-DD-feature/phases/phase-2.yaml"
  acceptance_packet: null
  transition_handoff: null
  commit: null # full 40-character commit hash when populated
```

Do not store worker dispatch details, active lane details, review text, full command output, or phase implementation logs in the supervisor inbox.

## Watchdog Trigger YAML

The same-session supervisor watchdog writes a trigger file when the supervisor needs to resume as a transition router. The trigger is compact lifecycle state, not an implementation report.

```yaml
phase: "phase-2"
triggered_at: "YYYY-MM-DDTHH:MM:SSZ"
reason: phase_completion # phase_completion | escalation | restart_needed | heartbeat_expired | pane_dead | orchestrator_failed
inbox: "/absolute/path/to/docs/implementation-runs/YYYY-MM-DD-feature/supervisor-inbox/phase-2.yaml"
run_yaml: "/absolute/path/to/docs/implementation-runs/YYYY-MM-DD-feature/run.yaml"
phase_yaml: "/absolute/path/to/docs/implementation-runs/YYYY-MM-DD-feature/phases/phase-2.yaml"
transition_yaml: "/absolute/path/to/docs/implementation-runs/YYYY-MM-DD-feature/transitions/phase-2.yaml"
base_worktree: "/absolute/path/to/repo"
phase_worktree: "/absolute/path/to/repo/.worktrees/impl-phase-2"
tmux_pane: "%12"
supervisor_pane: "%10"
supervisor_window: "project:1"
supervisor_session: "project"
event_log: "/absolute/path/to/docs/implementation-runs/YYYY-MM-DD-feature/events/supervisor.jsonl"
supervisor_thread_id: "019e..."
wake_method: "codex-app-server-turn-start" # codex-app-server-turn-start | blocked
wake_blocker: null
codex_control:
  supervisor_thread_id: "019e..."
  server_command: "codex app-server"
  turn_id: "019e..."
  status: "turn_started"
delegated_to: null # null | phase-merge-worker | handled
delegated_at: null
handled: false
```

The resumed supervisor transition router must append a compact event and then either delegate `phase_completion` to a native phase-merge sub-agent, handle a completed merge sub-agent result, spawn the post-advance native phase-transition sub-agent, handle a smoke-report result, handle a small non-completion lifecycle trigger, or record the escalation/blocker. For `phase_completion`, the original supervisor marks `delegated_to: phase-merge-worker` in the trigger and records the native sub-agent id in `transitions/<phase>.yaml`. The merge sub-agent leaves `handled: false` and reports `ready_for_supervisor` after merge-back, post-merge verification, and merge-owned transition-state updates. The original supervisor marks `handled: true` after completed-orchestrator teardown, next-phase startup or terminal state, and post-advance transition sub-agent spawn are durably recorded. The phase-transition sub-agent then records local verification and smoke-report state separately; it must not reopen or depend on the original watchdog trigger being unhandled. The merge sub-agent must operate from `base_worktree` for merge work and use `phase_worktree` only to inspect the accepted phase state, inbox, and artifacts. The phase-transition sub-agent also operates from `base_worktree` for local verification.

## Commit Hash Fields

Every commit-like field in `run.yaml`, `phase.yaml`, `transitions/<phase>.yaml`, worker result YAML, the supervisor inbox, trigger YAML, and acceptance packets must use a quoted full 40-character Git commit hash.

Do not write abbreviated hashes, copied terminal text, branch names, or manually typed hashes into commit fields. Resolve commit values from Git immediately before writing state:

```sh
accepted_commit="$(/usr/bin/git rev-parse HEAD^{commit})"
/usr/bin/git cat-file -e "$accepted_commit^{commit}"
```

For a phase completion request, the orchestrator must write the accepted phase commit from the phase branch after acceptance state and packet commits are complete:

```yaml
phase_completion:
  phase_yaml: "docs/implementation-runs/YYYY-MM-DD-feature/phases/phase-2.yaml"
  acceptance_packet: "docs/qa/phase-acceptance/phase-2.md"
  transition_handoff: "docs/implementation-runs/YYYY-MM-DD-feature/handoffs/phase-2-transition.md"
  commit: "abc123abc123abc123abc123abc123abc123abc123abc1"
```

The phase-merge sub-agent must validate commit fields with:

```sh
printf '%s\n' "$accepted_commit" | rg --quiet '^[0-9a-f]{40}$'
/usr/bin/git cat-file -e "$accepted_commit^{commit}"
```

If a legacy or malformed commit field is encountered, the supervisor may resolve it only when it is an unambiguous object on the phase branch:

```sh
resolved_commit="$(/usr/bin/git rev-parse --verify "${malformed_commit}^{commit}")"
/usr/bin/git merge-base --is-ancestor "$resolved_commit" "$phase_branch"
```

After resolving, patch the malformed state field to the full hash and commit that state repair before merging the phase. If the value is ambiguous, missing, or not contained in the phase branch, stop with `restart_needed` or a supervisor escalation instead of treating the typo as valid.

## Execution Manifest

The supervisor creates or regenerates `docs/implementation-runs/<run-id>/manifests/<phase-slug>.yaml` before launching or resuming the phase orchestrator. The manifest is a compact routing index derived from the approved phase plan. It is not canonical state, not the full plan, and not worker evidence.

The orchestrator schedules from the manifest plus `phase.yaml`. Before dispatching a worker, it reads only the selected task section from the full phase plan using the manifest's `plan_section_anchor`. Workers never edit the manifest. Because the manifest is generated and reproducible, it should contain only enough data to avoid repeatedly scanning the full phase plan.

Example:

```yaml
phase: "phase-2"
plan: "docs/plans/YYYY-MM-DD-feature-phase-2.md"
generated_from_commit: "abc123abc123abc123abc123abc123abc123abc123abc1"
generated_by: "supervisor"
tasks:
  "4":
    title: "Implement write path"
    depends_on:
      - "3"
    lane: "write-path"
    owner: "general-purpose worker"
    parallel_group: "none"
    tdd_gate: true
    plan_section_anchor: "### Task 4: Implement write path"
```

The manifest may store only task id, short title, dependencies, execution lane, owner/worker type, parallel group, TDD requirement, and the exact heading/anchor to the full task section. The owner for every task must be an approved worker agent; use `general-purpose worker` when no repo-approved specialist is named. The orchestrator is not a valid task owner. Phase kickoff and state updates are lifecycle operations outside the manifest task list. Acceptance collation and transition handoff writing belong to the delegated acceptance worker/agent.

Do not store copied task bodies, code snippets, full design rationale, full acceptance text, full command output, copied plan sections, full file scopes, service-wiring requirement text, or checkpoint command lists in the manifest. Those remain in the approved phase plan and `phase.yaml`/artifacts as execution progresses.

Regenerate or patch the manifest only when a consistency update changes future inactive task routing. If the manifest can be generated deterministically in the current environment, it may be treated as a transient derived file instead of a committed artifact. Record regeneration in `events/supervisor.jsonl` or `events/orchestrator-<phase>.jsonl`, depending on who made the plan update.

## Event JSONL

Use compact structured events for timing, communication volume, and workflow debugging. Events are observability, not canonical state.

Default paths:

```text
docs/implementation-runs/<run-id>/events/supervisor.jsonl
docs/implementation-runs/<run-id>/events/orchestrator-<phase-slug>.jsonl
docs/implementation-runs/<run-id>/events/worker-<lane>-<timestamp>.jsonl
```

Event shape:

```json
{"ts":"YYYY-MM-DDTHH:MM:SSZ","role":"orchestrator","phase":"phase-2","event":"worker_dispatched","lane":"write-path","artifact":"docs/implementation-runs/<run-id>/workers/write-path-20260527T120000Z.yaml"}
```

Useful events:

- run created or resumed;
- manifest created, patched, regenerated, or intentionally treated as transient;
- orchestrator launched, startup acknowledged, validated, restarted, stopped, or marked invalid;
- worker dispatched, test proposed, tests approved, implementation complete, reviewed, fixed, or integrated;
- blocker reported, blocker-resolver dispatched, blocker resolved, true blocker escalated;
- command started and ended, with duration, result, and artifact path;
- inbox request written or handled;
- phase-transition handoff/report written or consumed;
- phase acceptance started, passed, failed, or merged to base;
- completed phase orchestrator pane/session stopped;
- post-merge local verification setup started, launched, blocked, stopped, or failed;
- local verification smoke-test report written and printed;
- base worktree dirty status captured, preserved, reconciled, or blocked for critical conflict;
- escalation opened or cleared.

Do not put full prompts, full stdout, full diffs, full review text, screenshots, traces, videos, or copied plan sections in JSONL events. Store artifact paths and short summaries only.

## State Ownership

Only the supervisor edits `run.yaml`, and it should do so from the run base branch/worktree. Phase branches, phase orchestrators, implementation workers, phase-merge sub-agents, and phase-transition sub-agents must not edit `run.yaml`. The phase-merge sub-agent and phase-transition sub-agent write only the completed phase's `transitions/<phase>.yaml` plus referenced artifacts, then return a compact result to the supervisor. Only the orchestrator edits `phase.yaml` during normal phase execution. The supervisor owns initial manifest creation before launch. The orchestrator may patch or regenerate the manifest only as part of a batched consistency update for future inactive task routing.

The supervisor may initialize `supervisor-inbox/<phase-slug>.yaml` before spawning the orchestrator and may write the tmux pane id immediately after spawn. After that, the orchestrator writes compact lifecycle requests there. The watchdog polls that inbox and wakes the recorded original supervisor thread through the Codex app-server control plane for phase transitions, escalations, restarts, and completion. If the recorded supervisor thread cannot be resumed, the watchdog writes a blocked trigger, records the wake blocker, appends a compact event, and stops. It must not create a fresh Codex transition-handler pane/process. The supervisor transition router reads the inbox and trigger, records delegation for `phase_completion` in `transitions/<phase>.yaml`, and starts native sub-agents. After the merge sub-agent records merge-owned transition state, the supervisor updates only minimal `run.yaml` pointers/status on the base branch. After the supervisor starts the next phase from the merged base branch, the phase-transition sub-agent updates only local verification and smoke-report fields in `transitions/<completed-phase>.yaml`.

Workers write worker result YAML, compact worker event JSONL, and code/test changes only. They must not edit canonical state files unless explicitly assigned a narrow state-repair task.

Blocker-resolvers write blocker result YAML under `blockers/<blocker-id>.yaml`, compact evidence artifacts, and narrowly scoped setup/config/tooling changes needed to unblock the phase. They must not edit `run.yaml`; the orchestrator serially merges their result into `phase.yaml`.

State updates must happen immediately after these transitions:

- run created or resumed;
- phase started, blocked, accepted, or completed;
- execution manifest created, patched, regenerated, or intentionally skipped as derived;
- supervisor watchdog started, triggered, stopped, or failed;
- worker lane dispatched;
- worker result integrated;
- task status changed;
- branch/worktree merged;
- base worktree dirty status classified, preserved, reconciled, or blocked;
- acceptance command run;
- blocker status changed;
- post-merge local verification setup or run status changed;
- escalation opened or cleared.

Do not let multiple agents edit the same YAML state file concurrently. When parallel workers run, each worker writes a separate result YAML; the orchestrator serially merges those results into `phase.yaml`. When a phase completes, transition sub-agents write only that phase's transition YAML; the supervisor serially updates `run.yaml` after each sub-agent result.

## Worker Result YAML

Workers write or return compact result YAML. The orchestrator merges relevant fields into `phase.yaml`.

```yaml
worker_id: "worker-write-path-1"
worker_agent: "general-purpose worker"
lane: "write-path"
task: "Task 4"
status: complete # test_proposed | complete | blocked | needs_fix
started_at: "YYYY-MM-DDTHH:MM:SSZ"
completed_at: "YYYY-MM-DDTHH:MM:SSZ"
base_commit: "abc000"
head_commit: "abc123"
branch: "impl/phase-2/write-path"
worktree: ".worktrees/impl-phase-2-write-path"
changed_files:
  - "src/path/file.ts"
commands:
  - command: "pnpm test user-flow"
    result: pass
    artifact: "docs/qa/artifacts/phase-2/task-4-test.txt"
service_wiring_rows:
  - "create-record"
real_dependencies:
  - "postgres local container"
mocks_or_fixtures:
  - id: "mf-001"
    name: "seed user fixture"
    kind: fixture # mock | fixture | fake-service | placeholder | generated-test-data
    scope: test-only # test-only | runtime | service-wiring | acceptance-evidence
    affected_paths:
      - "tests/fixtures/users.ts"
    service_wiring_rows:
      - "create-record"
    disposition: test-only # test-only | intentional-phase-boundary | converted | deferred-with-conversion-task | blocked | unresolved
    acceptable_because: "Seed data only; production path still uses real database."
    conversion_task: null
    evidence:
      - "docs/qa/artifacts/phase-2/create-record-trace.zip"
residual_risks: []
review_status: approved # not_reviewed | approved | needs_fix | blocked
lesson_candidate:
  problem: "short recurring failure mode, or null"
  proven_fix: "short proven fix, or null"
  applies_when:
    - "situation where future agents should apply it"
  evidence:
    - "docs/qa/artifacts/phase-2/evidence.txt"
plan_updates_recommended:
  - task: "Task 5"
    reason: "Endpoint path changed"
    change: "Use /api/v2/records"
blockers: []
```

## Blocker Result YAML

Blocker-resolvers write compact result YAML. The orchestrator merges the status into `phase.yaml` and either reruns the blocked command or escalates through the supervisor inbox.

```yaml
blocker_id: "blocker-001"
status: resolved # resolved | true_blocker | needs_orchestrator_decision | failed
phase: "phase-2"
task: "Task N or acceptance"
reported_by: "worker|reviewer|fix-worker|orchestrator|acceptance"
classification: "setup_dependency" # setup_dependency | runtime_dependency | env_config | secret_or_account | external_service | product_decision | workflow_state
summary: "short blocker summary"
source_artifacts:
  - "docs/qa/artifacts/<phase>/blocked-command.txt"
actions_taken:
  - command: "make setup"
    result: pass
    artifact: "docs/qa/artifacts/<phase>/blocker-001-setup.txt"
changes_made:
  - "Makefile"
retry:
  command: "make eval-factory-once ..."
  result: pass # pass | still_blocked | fail_product | fail_test
  artifact: "docs/qa/artifacts/<phase>/blocker-001-retry.txt"
human_required: false
human_blocker_reason: null
safe_to_continue: true
notes: []
```

For `true_blocker`, `human_required` must be true and `human_blocker_reason` must state the exact external action required, why it is outside agent-owned setup, and the retry command after the human resolves it.

## Mock/Fixture Ledger

Mocks, fixtures, fake services, placeholder handlers, generated test data, and temporary runtime stand-ins are allowed during implementation when they make the work faster or safer. They must not silently become completion evidence.

The orchestrator maintains `mock_fixture_ledger` in `phase.yaml` by merging every worker's `mocks_or_fixtures` entries. Track any fake that touches runtime behavior, service wiring, acceptance evidence, or test data used to prove a phase. Pure unit-test-only fixtures may be tracked compactly when they matter for service-wiring interpretation.

Every ledger entry must have one disposition before phase completion:

- `test-only`: used only in tests or deterministic seed data; production/dev runtime path still uses the real implementation.
- `intentional-phase-boundary`: fixture-backed runtime behavior is explicitly the phase deliverable, such as an approved fixture shell phase.
- `converted`: temporary fake was replaced by real integration and verified through the real runtime boundary.
- `deferred-with-conversion-task`: fake remains by design and a named later phase/task owns conversion to real integration.
- `blocked`: real dependency is unavailable under allowed escalation rules, blocker-resolver evidence proves it is outside agent-owned setup, and the phase cannot honestly complete unless the phase scope allows this blocker.

These statuses fail phase acceptance:

- missing ledger entry for a discovered runtime fake;
- `unresolved`;
- runtime fake with no disposition;
- `mock-only-evidence` for a service-wiring row that requires real integration proof;
- `deferred-with-conversion-task` without a concrete plan/task path;
- `blocked` without an allowed escalation, blocker-resolver result, and blocking state.

The ledger is state, not evidence storage. Store short summaries and artifact paths only.

## Do Not Store

Do not put these in YAML or markdown:

- full stdout;
- full review text;
- full PR bodies;
- large logs;
- copied plan sections;
- repeated task instructions;
- screenshots, videos, or traces inline;
- raw Codex logs or chat-style event streams.

Store artifact paths and short summaries instead.
