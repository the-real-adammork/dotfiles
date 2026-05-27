# State Files

YAML is the durable machine state. Markdown is the narrative checkpoint. Artifacts are the proof.

## File Layout

```text
docs/implementation-runs/<run-id>/
  run.yaml
  phases/
    <phase-slug>.yaml
  workers/
    <lane>-<timestamp>.yaml
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
phases_document: "docs/plans/YYYY-MM-DD-feature-implementation-phases.md"
current_phase: "phase-2"
phase_order:
  - phase-1
  - phase-2
branches:
  base: "main"
  current: "impl/phase-2"
paths:
  run_dir: "docs/implementation-runs/YYYY-MM-DD-feature"
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
active_lanes:
  - lane: "write-path"
    status: agentic_review
    worker: "worker-write-path-1"
    branch: "impl/phase-2/write-path"
    worktree: ".worktrees/impl-phase-2-write-path"
tasks:
  "4":
    status: done
    lane: "write-path"
    commit: "abc123"
    verification:
      - command: "pnpm test:e2e -- user-write-flow"
        result: pass
        artifact: "docs/qa/artifacts/phase-2/write-flow.txt"
service_wiring:
  create-record:
    status: covered
    evidence: "docs/qa/artifacts/phase-2/create-record-trace.zip"
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

## State Ownership

Only the supervisor or phase owner edits `run.yaml` and `phase.yaml`.

Workers write worker result YAML and code/test changes only. They must not edit canonical state files unless explicitly assigned a narrow state-repair task.

State updates must happen immediately after these transitions:

- run created or resumed;
- phase started, blocked, accepted, or completed;
- worker lane dispatched;
- worker result integrated;
- task status changed;
- branch/worktree merged;
- acceptance command run;
- escalation opened or cleared.

Do not let multiple agents edit the same YAML state file concurrently. When parallel workers run, each worker writes a separate result YAML; the phase owner serially merges those results into `phase.yaml`.

## Worker Result YAML

Workers write or return compact result YAML. The phase owner merges relevant fields into `phase.yaml`.

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
  - name: "seed user fixture"
    acceptable_because: "seed data only; production path still uses real database"
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

## Do Not Store

Do not put these in YAML or markdown:

- full stdout;
- full review text;
- full PR bodies;
- large logs;
- copied plan sections;
- repeated task instructions;
- screenshots, videos, or traces inline;
- chat-style event streams.

Store artifact paths and short summaries instead.
