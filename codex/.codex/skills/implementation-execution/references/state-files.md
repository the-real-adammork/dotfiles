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
  manifests/
    <phase-slug>.yaml
  watchdogs/
    <phase-slug>.sh
    <phase-slug>.pid
    <phase-slug>-trigger.yaml
  workers/
    <lane>-<timestamp>.yaml
  events/
    supervisor.jsonl
    orchestrator-<phase-slug>.jsonl
    worker-<lane>-<timestamp>.jsonl
  handoffs/
    <timestamp>.md

docs/qa/
  phase-acceptance/
    <phase-slug>.md
  artifacts/
    <phase-slug>/
      <test-output-files>
```

## run.yaml

Tracks run-level state only:

```yaml
run_id: "YYYY-MM-DD-feature"
status: running # running | blocked | complete
slices_document: "docs/plans/SLICES.md"
phases_document: "docs/plans/SLICES.md"
current_phase: "phase-2"
phase_order:
  - phase-1
  - phase-2
completed_phases:
  phase-1:
    phase_branch: "impl/phase-1"
    base_commit_after_merge: "def456def456def456def456def456def456def456def4"
    accepted_phase_commit: "abc123abc123abc123abc123abc123abc123abc123abc1"
    acceptance_packet: "docs/qa/phase-acceptance/phase-1.md"
branches:
  base: "main"
  current: "impl/phase-2"
orchestrator:
  phase: "phase-2"
  status: running # starting | running | blocked | acceptance_ready | complete | failed | exiting | invalid
  spawn_method: tmux-pane # tmux-pane | inline_fallback
  tmux_pane: "%12"
  inbox: "docs/implementation-runs/YYYY-MM-DD-feature/supervisor-inbox/phase-2.yaml"
  fallback_reason: null
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
supervisor_watchdog:
  status: running # starting | running | stopped | failed | disabled
  pid: 12345
  script: "docs/implementation-runs/YYYY-MM-DD-feature/watchdogs/phase-2.sh"
  trigger: "docs/implementation-runs/YYYY-MM-DD-feature/watchdogs/phase-2-trigger.yaml"
  interval_seconds: 120
  wake_method: tmux-pane # tmux-pane | codex-cli | disabled
  last_checked_at: "YYYY-MM-DDTHH:MM:SSZ"
paths:
  run_dir: "docs/implementation-runs/YYYY-MM-DD-feature"
  events: "docs/implementation-runs/YYYY-MM-DD-feature/events"
  qa_artifacts: "docs/qa/artifacts"
  acceptance_packets: "docs/qa/phase-acceptance"
escalations: []
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
    branch: "impl/phase-2/write-path"
    worktree: ".worktrees/impl-phase-2-write-path"
orchestrator:
  supervisor_inbox: "docs/implementation-runs/YYYY-MM-DD-feature/supervisor-inbox/phase-2.yaml"
  spawn_method: tmux-pane # tmux-pane | inline_fallback
  tmux_pane: "%12"
  fallback_reason: null
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
blockers: []
updated_at: "YYYY-MM-DDTHH:MM:SSZ"
```

## Supervisor Inbox YAML

The detached watchdog polls one compact inbox file for the active phase. The supervisor reads it only during launch validation or transition handling. This file is lifecycle state only, not worker or task detail.

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
  artifact: null
phase_completion:
  phase_yaml: "docs/implementation-runs/YYYY-MM-DD-feature/phases/phase-2.yaml"
  acceptance_packet: null
  commit: null # full 40-character commit hash when populated
```

Do not store worker dispatch details, active lane details, review text, full command output, or phase implementation logs in the supervisor inbox.

## Watchdog Trigger YAML

The detached supervisor watchdog writes a trigger file when the supervisor needs to resume as a transition handler. The trigger is compact lifecycle state, not an implementation report.

```yaml
phase: "phase-2"
triggered_at: "YYYY-MM-DDTHH:MM:SSZ"
reason: phase_completion # phase_completion | escalation | restart_needed | heartbeat_expired | pane_dead | orchestrator_failed
inbox: "docs/implementation-runs/YYYY-MM-DD-feature/supervisor-inbox/phase-2.yaml"
run_yaml: "docs/implementation-runs/YYYY-MM-DD-feature/run.yaml"
phase_yaml: "docs/implementation-runs/YYYY-MM-DD-feature/phases/phase-2.yaml"
tmux_pane: "%12"
event_log: "docs/implementation-runs/YYYY-MM-DD-feature/events/supervisor.jsonl"
handled: false
```

The resumed supervisor transition handler must mark the trigger handled, append a compact event, and then either complete the phase transition, restart the orchestrator, or record the escalation/blocker.

## Commit Hash Fields

Every commit-like field in `run.yaml`, `phase.yaml`, worker result YAML, the supervisor inbox, trigger YAML, and acceptance packets must use a quoted full 40-character Git commit hash.

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
  commit: "abc123abc123abc123abc123abc123abc123abc123abc1"
```

The supervisor transition handler must validate commit fields with:

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

The supervisor creates `docs/implementation-runs/<run-id>/manifests/<phase-slug>.yaml` before launching or resuming the phase orchestrator. The manifest is a compact routing index derived from the approved phase plan. It is not the full plan and is not worker evidence.

The orchestrator schedules from the manifest plus `phase.yaml`. Before dispatching a worker, it reads only the selected task section from the full phase plan using the manifest's `plan_section_anchor`. Workers never edit the manifest.

Example:

```yaml
phase: "phase-2"
plan: "docs/plans/YYYY-MM-DD-feature-phase-2.md"
generated_from_commit: "abc123"
generated_by: "supervisor"
tasks:
  "4":
    title: "Implement write path"
    depends_on:
      - "Task 3"
    execution: "worker lane: write-path; parallel with none"
    files:
      modify:
        - "src/path/file.ts"
      test:
        - "tests/path/file.test.ts"
    service_wiring_rows:
      - "create-record"
    checkpoint: "pnpm test user-flow"
    tdd_gate: required
    plan_section_anchor: "### Task 4: Implement write path"
acceptance:
  packet: "docs/qa/phase-acceptance/phase-2.md"
  commands:
    - "pnpm test:e2e -- user-write-flow"
```

The manifest may store task title, dependencies, execution lane, declared file scope, service-wiring rows, checkpoint commands, TDD requirement, and the exact heading/anchor to the full task section.

Do not store copied task bodies, code snippets, full design rationale, full acceptance text, full command output, or copied plan sections in the manifest.

Regenerate or patch the manifest only when a consistency update changes future inactive tasks. Record the regeneration in `events/supervisor.jsonl` or `events/orchestrator-<phase>.jsonl`, depending on who made the plan update.

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
- manifest created, patched, or regenerated;
- orchestrator launched, startup acknowledged, validated, restarted, stopped, or marked invalid;
- worker dispatched, test proposed, tests approved, implementation complete, reviewed, fixed, or integrated;
- command started and ended, with duration, result, and artifact path;
- inbox request written or handled;
- phase acceptance started, passed, failed, or merged to base;
- escalation opened or cleared.

Do not put full prompts, full stdout, full diffs, full review text, screenshots, traces, videos, or copied plan sections in JSONL events. Store artifact paths and short summaries only.

## State Ownership

Only the supervisor edits `run.yaml`. Only the orchestrator edits `phase.yaml` during normal phase execution. The supervisor owns initial manifest creation before launch. The orchestrator may patch or regenerate the manifest only as part of a batched consistency update for future inactive tasks.

The supervisor may initialize `supervisor-inbox/<phase-slug>.yaml` before spawning the orchestrator and may write the tmux pane id immediately after spawn. After that, the orchestrator writes compact lifecycle requests there. The watchdog polls that inbox and wakes a short supervisor transition handler for phase transitions, escalations, restarts, and completion. The supervisor transition handler reads the inbox and updates `run.yaml`.

Workers write worker result YAML, compact worker event JSONL, and code/test changes only. They must not edit canonical state files unless explicitly assigned a narrow state-repair task.

State updates must happen immediately after these transitions:

- run created or resumed;
- phase started, blocked, accepted, or completed;
- execution manifest created, patched, or regenerated;
- supervisor watchdog started, triggered, stopped, or failed;
- worker lane dispatched;
- worker result integrated;
- task status changed;
- branch/worktree merged;
- acceptance command run;
- escalation opened or cleared.

Do not let multiple agents edit the same YAML state file concurrently. When parallel workers run, each worker writes a separate result YAML; the orchestrator serially merges those results into `phase.yaml`.

## Worker Result YAML

Workers write or return compact result YAML. The orchestrator merges relevant fields into `phase.yaml`.

```yaml
worker_id: "worker-write-path-1"
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

## Mock/Fixture Ledger

Mocks, fixtures, fake services, placeholder handlers, generated test data, and temporary runtime stand-ins are allowed during implementation when they make the work faster or safer. They must not silently become completion evidence.

The orchestrator maintains `mock_fixture_ledger` in `phase.yaml` by merging every worker's `mocks_or_fixtures` entries. Track any fake that touches runtime behavior, service wiring, acceptance evidence, or test data used to prove a phase. Pure unit-test-only fixtures may be tracked compactly when they matter for service-wiring interpretation.

Every ledger entry must have one disposition before phase completion:

- `test-only`: used only in tests or deterministic seed data; production/dev runtime path still uses the real implementation.
- `intentional-phase-boundary`: fixture-backed runtime behavior is explicitly the phase deliverable, such as an approved fixture shell phase.
- `converted`: temporary fake was replaced by real integration and verified through the real runtime boundary.
- `deferred-with-conversion-task`: fake remains by design and a named later phase/task owns conversion to real integration.
- `blocked`: real dependency is unavailable under allowed escalation rules and the phase cannot honestly complete unless the phase scope allows this blocker.

These statuses fail phase acceptance:

- missing ledger entry for a discovered runtime fake;
- `unresolved`;
- runtime fake with no disposition;
- `mock-only-evidence` for a service-wiring row that requires real integration proof;
- `deferred-with-conversion-task` without a concrete plan/task path;
- `blocked` without an allowed escalation and blocking state.

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
