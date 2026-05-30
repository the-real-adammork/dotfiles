# Blocker Resolver

The blocker-resolver is a bounded agent type owned by the phase orchestrator. Its job is to turn ambiguous "blocked" reports into either a resolved setup path or a precise true blocker that only the human can resolve.

Use it when a worker, reviewer, fix-worker, acceptance command, or the orchestrator hits a blocker that may be caused by local setup, missing dependencies, runtime tooling, environment wiring, dev service availability, generated files, stale install state, ports, containers, emulators, or verification harness configuration.

Do not use it for ordinary product bugs; dispatch an implementation or fix worker instead.

## Blocker Classification

Classify the issue before dispatch:

- `setup_dependency`: missing local tools, packages, browsers, containers, emulators, generated files, migrations, or repo setup.
- `runtime_dependency`: local service, cluster, Docker, database, queue, cache, device simulator, or dev runtime is unavailable or misconfigured.
- `env_config`: missing non-secret environment variables, `.env.example` gaps, local path variables, or safe placeholder config.
- `secret_or_account`: credential, token, account, paid/vendor access, or private secret is needed.
- `external_service`: network, vendor service, rate limit, outage, external allowlist, or unavailable real integration.
- `product_decision`: unresolved product, legal, privacy, security, compliance, or destructive-action decision.
- `workflow_state`: invalid pane, bad heartbeat, malformed YAML, missing artifact, branch/worktree conflict, or broken workflow control plane.

The blocker-resolver may attempt `setup_dependency`, `runtime_dependency`, `env_config`, and most `workflow_state` blockers. It must not invent credentials, bypass paid/vendor setup, use real customer data, perform destructive production actions, or decide product/legal/security policy.

## Allowed Actions

The blocker-resolver may:

- install or refresh development dependencies required for this task using the repo's package manager or system package manager;
- run setup commands such as `make setup`, `pnpm install`, `npm install`, `uv sync`, `pip install -e`, `bundle install`, `cargo fetch`, `playwright install`, migrations, seed scripts, local container setup, or code generation;
- install local development tools such as `kind`, `minikube`, browser runtimes, CLIs, emulators, linters, test runners, or SDKs when the task reasonably requires them;
- create or update safe local non-secret config from examples;
- use `$secrets` before touching secret-bearing files or credentials;
- choose alternate localhost ports under the repo's port-isolation rules;
- update repo docs, setup scripts, lockfiles, `.env.example`, devcontainer files, Make targets, or test harness config when that is the durable fix;
- rerun the blocked command and save evidence.

Prefer repeatable repo fixes over one-off shell state. In dotfiles or bootstrap-managed repos, update the appropriate install/bootstrap file when a newly required tool is durable.

## Dispatch Prompt

The orchestrator dispatches one blocker-resolver per blocker or tightly related blocker set.

```text
Goal: Resolve blocker <blocker-id> for <phase/task/lane> or prove it is a true human blocker.
Agent type: blocker-resolver.
Use blocker result path: <docs/implementation-runs/<run-id>/blockers/<blocker-id>.yaml>.
Use phase state: <phase.yaml>.
Use worker/reviewer/acceptance artifact: <path>.
Allowed scope: local development setup, dependency install, dev runtime setup, safe env wiring, workflow-state repair, and verification rerun needed for this phase.
Do not implement product behavior except small setup/test-harness fixes directly required to unblock verification.
Do not update run.yaml. Do not edit unrelated code. Do not print secrets.
Return commands run, changes made, retry evidence, resolved/unresolved status, and whether human action is required.
```

## Result Contract

Write compact YAML to:

```text
docs/implementation-runs/<run-id>/blockers/<blocker-id>.yaml
```

```yaml
blocker_id: "blocker-001"
status: resolved # resolved | true_blocker | needs_orchestrator_decision | failed
phase: "phase-2"
task: "Task N or acceptance"
reported_by: "worker|reviewer|fix-worker|orchestrator|acceptance"
classification: "setup_dependency"
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
notes:
  - "short note"
```

## True Blocker Report

If the resolver cannot fix it, the result must say exactly why. A true blocker report must include:

- what was attempted;
- why the blocker is outside agent-owned setup;
- the exact human action needed;
- whether work can continue on other lanes;
- the smallest retry command after the human resolves it;
- all evidence artifact paths.

Examples of true blockers:

- a required paid account, vendor approval, license, private token, or allowlist is missing;
- a real external service is down or rate-limited after bounded retry;
- the task requires production/customer data access;
- a destructive production action is required;
- the requirement depends on unresolved product/legal/privacy/security direction;
- a local dependency cannot be installed because the OS, hardware, permissions, or package availability blocks it after reasonable attempts.

## Orchestrator Handling

After a resolver result:

- `resolved`: rerun the blocked worker/checkpoint/acceptance command and continue if it passes.
- `needs_orchestrator_decision`: decide whether this is a product bug, test bug, workflow-state repair, or human escalation; dispatch the right next agent.
- `true_blocker`: stop the phase only when no other safe work can continue or the blocker invalidates acceptance. Write a compact supervisor inbox escalation with the resolver artifact.
- `failed`: retry once with a narrower prompt if the failure was process-related; otherwise classify as `true_blocker` or `restart_needed`.

Do not mark phase acceptance as passed with an allowed dependency blocker unless the blocker-resolver result proves the dependency is outside agent-owned setup or the approved phase plan explicitly permits completion with that unresolved boundary.
