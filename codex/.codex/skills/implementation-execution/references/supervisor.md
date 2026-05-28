# Supervisor

The supervisor is a durable run/process manager, not a chatty project manager. It owns the run, phase order, phase transitions, orchestrator processes, escalations, and final handoff.

## Responsibilities

- Load or create `run.yaml`.
- Discover the SLICES document at `docs/plans/SLICES.md` when no path is provided, then select the current phase from ordered phase plans.
- Track execution scope: `run` by default for a phases document or multiple phase plans; `single-phase` only when the user explicitly asks to run one phase only.
- Create or refresh the compact execution manifest for the active phase before launching the orchestrator.
- Spawn or resume one top-level Codex CLI phase orchestrator for the active phase in a new pane in the current tmux window; record an inline fallback only when tmux/Codex process spawning is unavailable.
- Verify any recorded orchestrator pane before trusting it; state files are hints, not proof that a valid orchestrator is running.
- Start a detached deterministic watchdog for the active phase after orchestrator startup is validated.
- End the supervisor Codex turn after launch/watchdog setup; resume only as a transition handler when the watchdog triggers an actionable lifecycle event.
- Append compact supervisor events to `docs/implementation-runs/<run-id>/events/supervisor.jsonl`.
- Store discovered raw Codex session id/path when available, but do not parse raw session logs as workflow state during normal execution.
- Keep supervisor, phase orchestrator, and worker responsibilities distinct.
- Ensure each active phase has a phase branch/worktree recorded in `phase.yaml`, or a recorded fallback reason when worktrees are unavailable.
- Let the watchdog poll only the compact supervisor inbox for the active phase during normal work, using `sleep 120` between checks by default; do not keep an interactive supervisor LLM turn alive just to wait.
- Keep phase execution sequential unless phases are explicitly independent.
- Ensure only allowed escalations stop autonomous work.
- Ensure phase completion requires the phase acceptance gate and packet.
- Merge each accepted phase branch/worktree back into the run base branch before advancing `run.yaml` to the next phase.
- After each successful phase merge-back, prepare and launch the project locally from the updated base branch/worktree for human verification, unless an allowed escalation prevents it.
- Batch plan consistency updates after phase or lane integration, not after every tiny edit.

## Execution Flow

1. Load `run.yaml`, or create it from `docs/plans/SLICES.md` when no run exists and no slices path was provided.
2. Load the current phase plan, `phases/<phase-slug>.yaml`, and existing manifest if present.
3. If `phase.yaml` does not exist, initialize it from the phase plan.
4. Create or refresh `docs/implementation-runs/<run-id>/manifests/<phase-slug>.yaml` from the phase plan, store its path in `phase.yaml`, and append a compact manifest event.
5. Ensure the phase branch/worktree exists or instruct the phase orchestrator to create it before implementation starts.
6. Ensure `docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml` exists with `orchestrator_status: starting`.
7. If `run.yaml` or the inbox records an existing orchestrator pane, validate it before resuming. If validation fails, restart the orchestrator unless doing so would risk losing unrecorded state.
8. Start or resume the phase orchestrator in a new pane in the current tmux window and record its pane/process identity in `run.yaml` and the inbox.
9. Require startup acknowledgement in the inbox. It must name the expected manifest path and pane id before the supervisor treats the orchestrator as running.
10. Start a detached watchdog script for the compact inbox. Record `supervisor_watchdog` in `run.yaml`, append a `watchdog_started` event, and return a running status to the user. Do not keep the supervisor Codex turn alive as a polling loop.
11. The watchdog polls the inbox using `sleep 120` between checks, validates basic pane/heartbeat health, and writes a trigger file only when it sees escalation, restart, graceful exit, phase completion, heartbeat expiry, or pane death.
12. When resumed by a watchdog trigger, act as a short supervisor transition handler. Load only `run.yaml`, the trigger YAML, the compact inbox, and the narrow transition files required by the trigger.
13. If the trigger reports `blocked`, update `run.yaml`, preserve the orchestrator pane, and write a handoff only when needed.
14. If the trigger reports `graceful_exit`, heartbeat expiry, pane death, or restart needed, validate current state and either restart the orchestrator/watchdog or mark the run blocked if restart would risk losing unrecorded state.
15. If the trigger reports `phase_completion`, verify only the transition gate: acceptance packet exists, `phase.yaml` says complete/acceptance passed, required commit/artifact paths exist, and the phase worktree is clean or has expected state.
16. Fast-forward the accepted phase branch/worktree back into the run base branch. Do this before advancing `run.yaml` to the next phase. If the base branch has diverged from the phase branch, stop with a supervisor escalation/handoff instead of silently chaining or creating an unplanned merge.
17. If phase completion verification and base-branch merge pass, run the lightweight post-merge verification needed to catch integration drift.
18. Immediately record the phase completion in `run.yaml`: completed phase entry, accepted phase commit, base commit after merge, acceptance packet, stopped completed watchdog, completed/closing orchestrator state, handled trigger, and the next `current_phase` when another phase remains. Do this before local verification setup so a long-running dev server launch cannot leave the run state stale.
19. From the updated base branch/worktree, perform post-merge local verification setup: inspect repo docs/scripts for the normal local run path, install or refresh dependencies, apply local setup steps, start required local services, run the app or service locally, capture the process identity, determine the reachable `localhost` URL/port, and write concise smoke-test instructions for the human. If a real allowed escalation blocks local launch, record the blocker and any partial setup completed.
20. Update the completed phase entry in `run.yaml` with local verification status, URL, process identity, artifacts, smoke-test checklist, or blocker.
21. If execution scope is `run` and another phase remains, immediately start the next phase orchestrator and watchdog from the updated base branch while the local verification run remains available when feasible, then end the supervisor turn with running status that includes the localhost URL and smoke-test instructions.
22. Stop only when all phases in scope are complete, an allowed escalation blocks progress, context handoff is required, or the user explicitly stops.

## Escalation Policy

Escalate only for:

- credentials, secrets, private keys, or account access unavailable through approved local setup;
- paid account setup, billing, quota purchase, vendor approval, or external allowlist;
- product, legal, privacy, security, or compliance decisions not answered by source docs;
- destructive production actions, real customer data access, or irreversible external side effects;
- unavailable physical devices, entitlements, or external services after an agent-owned attempt.

Everything else is agent-owned setup or implementation work.

## Role Separation

Treat the workflow as three roles:

- Supervisor: run-level state machine, phase ordering, escalation policy, final handoff.
- Phase orchestrator: active frontier, worker dispatch, integration checkpoints, `phase.yaml`, acceptance packet, plan consistency.
- Worker: bounded implementation, test proposal, implementation result, evidence, no scheduling.

The supervisor does not implement phase tasks, choose implementation lanes, spawn workers, or inspect detailed phase state during normal work. It maintains durable run state, enforces the phase branch/worktree topology, starts/stops orchestrator tmux panes, starts/stops deterministic watchdogs, verifies phase transition gates, records escalations or handoffs, and starts the next phase orchestrator after completion when the run scope continues.

## Detached Watchdog

The supervisor should not sit in an open Codex turn waiting on `sleep`. After launch validation, create a small watchdog script under `docs/implementation-runs/<run-id>/watchdogs/<phase-slug>.sh`, start it with `nohup`, record its PID in `run.yaml`, and end the supervisor turn.

The watchdog is deterministic shell, not an LLM. It may:

- read the compact supervisor inbox;
- check whether the recorded tmux pane still exists;
- compare `heartbeat_expires_at` to current UTC time;
- append compact JSONL events;
- write `watchdogs/<phase-slug>-trigger.yaml`;
- launch a new Codex transition-handler pane or process with a short prompt pointing to the trigger file.

The watchdog must not read `phase.yaml`, worker result YAML, raw Codex session logs, full plans, diffs, or artifacts.

Use absolute paths in the watchdog script, trigger file, and transition-handler prompt. The watchdog may run from a phase worktree, but the supervisor transition handler must receive both the phase worktree path and the run base worktree path. On `phase_completion`, launch or immediately switch the transition handler to the run base worktree before merge-back, post-merge local verification setup, run-state updates, and next-phase orchestrator startup.

Watchdog script shape:

```sh
inbox='<absolute-supervisor-inbox-yaml>'
run_yaml='<absolute-run-yaml>'
phase_yaml='<absolute-phase-yaml>'
trigger='<absolute-watchdog-trigger-yaml>'
event_log='<absolute-events/supervisor.jsonl>'
pane='<orchestrator-pane-id>'
base_worktree='<absolute-run-base-worktree>'
phase_worktree='<absolute-phase-worktree>'
transition_prompt='Use the implementation-execution skill as supervisor transition handler. Load run state: <absolute-run.yaml>. Load watchdog trigger: <absolute-trigger-yaml>. Base worktree: <absolute-run-base-worktree>. Phase worktree: <absolute-phase-worktree>. Handle only that transition event. For phase_completion, perform merge-back, post-merge local verification, run-state updates, and next-phase startup from the base worktree.'

while true; do
  if rg --quiet 'type: (escalation|phase_completion|graceful_exit|restart_needed)|orchestrator_status: (blocked|failed|complete|acceptance_ready)' "$inbox"; then
    request_type="$(sed -n 's/^  type: //p' "$inbox" | head -1)"
    status_type="$(sed -n 's/^orchestrator_status: //p' "$inbox" | head -1)"
    case "$request_type" in
      escalation|phase_completion|graceful_exit|restart_needed) reason="$request_type" ;;
      *) reason="$status_type" ;;
    esac
    [ -n "$reason" ] || reason='lifecycle_request'
    break
  fi
  if ! tmux display-message -p -t "$pane" '#{pane_id}' >/dev/null 2>&1; then
    reason='pane_dead'
    break
  fi
  if python3 - "$inbox" <<'PY'
import sys, datetime, re
text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'^heartbeat_expires_at:\s*"?([^"\n]+)"?', text, re.M)
if not m:
    sys.exit(1)
expiry = datetime.datetime.fromisoformat(m.group(1).replace("Z", "+00:00"))
sys.exit(0 if datetime.datetime.now(datetime.timezone.utc) > expiry else 1)
PY
  then
    reason='heartbeat_expired'
    break
  fi
  sleep 120
done

ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
cat > "$trigger" <<EOF
phase: "<phase>"
triggered_at: "$ts"
reason: "$reason"
inbox: "$inbox"
run_yaml: "$run_yaml"
phase_yaml: "$phase_yaml"
base_worktree: "$base_worktree"
phase_worktree: "$phase_worktree"
tmux_pane: "$pane"
event_log: "$event_log"
handled: false
EOF
printf '{"ts":"%s","role":"supervisor-watchdog","event":"triggered","reason":"%s","trigger":"%s"}\n' "$ts" "$reason" "$trigger" >> "$event_log"
tmux split-window -h -c "$base_worktree" -- codex --dangerously-bypass-approvals-and-sandbox "$transition_prompt"
```

If `tmux` is unavailable, the watchdog may launch `codex --dangerously-bypass-approvals-and-sandbox "$transition_prompt"` directly, or it may stop with a blocked trigger when launching Codex is unavailable. Record the chosen wake method in `run.yaml`.

The transition-handler Codex session must not continue polling after handling the trigger. It either completes the transition, starts the next orchestrator/watchdog, or records the blocker and exits. If the trigger reason is `acceptance_ready` but the inbox contains `request.type: phase_completion`, treat it as a phase-completion transition and repair future watchdog behavior to prioritize `request.type`.

Supervisor must not:

- select the next implementation task/lane;
- spawn workers;
- rewrite worker goals;
- load task-specific implementation modules to move the phase forward;
- poll detailed worker/orchestrator state beyond the compact inbox during normal execution.
- keep an interactive supervisor Codex turn alive only to wait for the orchestrator.
- approve, reject, or answer Codex edit/command prompts in the orchestrator pane with `tmux send-keys`.
- approve worker edits on behalf of the orchestrator.
- run broad log reads, full-plan dumps, full diffs, or raw Codex session-log parsing during the normal polling loop.

If the orchestrator pane shows a Codex approval prompt, treat it as a process launch/configuration failure. Do not press `y`, `a`, or otherwise answer the prompt. Capture a short pane excerpt if useful, then restart the orchestrator with `--dangerously-bypass-approvals-and-sandbox` or mark the run blocked if restart would risk losing unrecorded state.

## Tmux Orchestrator Pane

Start each phase orchestrator in a new pane in the current tmux window so the human can see both supervisor and orchestrator.

Recommended pattern:

```sh
orchestrator_prompt='Use the implementation-execution skill as the phase orchestrator for <phase>. Run state: <run.yaml>. Phase state: <phase.yaml>. Execution manifest: <manifest.yaml>. Phase plan: <phase-plan>. Write supervisor inbox: <inbox-yaml>. On startup, write startup.acknowledged=true and codex_session if discoverable.'
tmux split-window -h -P -F '#{pane_id}' -c "$PWD" -- codex --dangerously-bypass-approvals-and-sandbox "$orchestrator_prompt"
```

The bypass flag is for the spawned orchestrator process only. It prevents Codex edit/command approval popups from blocking long-running autonomous phase execution, including worker edit prompts owned by the orchestrator. The orchestrator must still follow the workflow escalation policy and write allowed human-only blockers to the supervisor inbox instead of asking ad hoc approval questions.

Capture the printed pane id and store it in `run.yaml` and the initial inbox. If horizontal split is not usable, use a vertical split. If `$TMUX` is not set or `tmux` fails, record `orchestrator.spawn_method: inline_fallback` and the reason in `run.yaml` and the inbox.

## Orchestrator Pane Validation

Never blindly trust `run.yaml`, `phase.yaml`, or the inbox when they claim an orchestrator pane exists. Before resuming or polling an existing orchestrator, validate the recorded pane id against tmux and the expected launch contract.

Validation checks:

1. `tmux display-message -p -t <pane-id> '#{pane_id}'` succeeds and returns the expected pane id.
2. `tmux display-message -p -t <pane-id> '#{pane_current_command} #{pane_current_path} #{pane_pid}'` shows a live pane in the expected repo or phase worktree.
3. The pane command/process tree contains `codex`.
4. The captured pane text or launch record shows the phase-orchestrator prompt for the expected phase, run state, phase plan, and supervisor inbox path.
5. The pane was launched with `--dangerously-bypass-approvals-and-sandbox`, either from the recorded launch command or from visible shell history/process arguments when available.
6. The inbox startup acknowledgement is present after launch and names the expected manifest path.
7. The inbox heartbeat is fresh enough for the configured heartbeat window and points back to the same pane id.

Suggested validation commands:

```sh
tmux display-message -p -t '<pane-id>' '#{pane_id}'
tmux display-message -p -t '<pane-id>' '#{pane_current_command} #{pane_current_path} #{pane_pid}'
tmux capture-pane -p -t '<pane-id>' -S -80 | tail -80
ps -o pid=,ppid=,command= -g "$(tmux display-message -p -t '<pane-id>' '#{pane_pid}')" 2>/dev/null
```

If validation fails, do not keep polling as if the pane is valid. Mark the existing pane as `invalid` in `run.yaml` with a short reason, then either:

- restart the orchestrator with the recommended tmux command when state is safely persisted; or
- mark the run blocked with a compact handoff if restarting could lose unrecorded work.

If the pane exists but shows a Codex approval prompt, use the approval-prompt rule above: treat it as invalid launch/autonomy state rather than approving the prompt.

## Phase Merge Back

The orchestrator merges workers into the phase branch. The supervisor merges the completed phase branch back into the run base branch during phase transition.

Before merging:

1. Confirm the inbox requested `phase_completion`.
2. Confirm `phase.yaml` is `status: complete` and `acceptance.status: passed`.
3. Confirm the acceptance packet exists and references current commits/artifacts.
4. Confirm the phase worktree is clean or only contains explicitly expected state artifacts already committed on the phase branch.
5. Inspect the run base worktree for local/ad-hoc changes and classify them before merge-back. A dirty base worktree is allowed when the supervisor can preserve or reasonably reconcile local changes without overwriting suspected secrets/runtime data or making a critical product/data decision.
6. Confirm whether the base branch is an ancestor of the phase branch. If yes, prefer fast-forward. If no, use the merge reconciliation protocol instead of silently chaining branches or creating an unexplained merge.
7. Resolve and validate the accepted phase commit from the inbox or acceptance packet. It must be a full 40-character commit hash that exists as a commit object.
8. Confirm the phase branch contains the accepted phase commit.

Default merge sequence:

```sh
base_branch='<run.yaml branches.base>'
phase_branch='<phase.yaml branch>'
accepted_commit='<phase completion commit>'
artifact_dir='docs/qa/artifacts/<phase-slug>'
printf '%s\n' "$accepted_commit" | rg --quiet '^[0-9a-f]{40}$'
/usr/bin/git cat-file -e "$accepted_commit^{commit}"
/usr/bin/git switch "$base_branch"
mkdir -p "$artifact_dir"
/usr/bin/git status --porcelain=v1 -z > "$artifact_dir/base-worktree-status-before.z"
/usr/bin/git diff --name-only -z > "$artifact_dir/base-dirty-tracked-before.z"
/usr/bin/git ls-files --others --exclude-standard -z > "$artifact_dir/base-dirty-untracked-before.z"
/usr/bin/git diff --name-only -z "$base_branch..$accepted_commit" > "$artifact_dir/phase-changed-paths.z"
/usr/bin/git merge-base --is-ancestor "$base_branch" "$phase_branch" || echo "base_not_ancestor_reconciliation_required"
/usr/bin/git merge-base --is-ancestor "$accepted_commit" "$phase_branch"
/usr/bin/git merge --ff-only "$phase_branch"
/usr/bin/git rev-parse HEAD
```

If `git switch "$base_branch"` fails because local changes would be overwritten, use the merge reconciliation protocol below from the current base worktree; do not force checkout. Before running `git merge --ff-only`, compare dirty base paths to phase-changed paths. If dirty paths are non-overlapping and the base branch is an ancestor, proceed with the fast-forward; Git will preserve those local files. If paths overlap, the base branch diverged, or `git merge --ff-only` fails, attempt a supervised reconciliation instead of blocking by default.

After merging:

- run the lightweight post-merge verification needed to catch integration drift, at minimum the phase acceptance gate or the repo's standard smoke commands;
- verify the base branch now points at the accepted phase commit, or at a descendant that contains it when the phase branch includes final acceptance/state commits;
- record the merge commit in `run.yaml` under the completed phase entry before launching any local verification process;
- set `branches.current` to the updated base branch before local verification setup or next-phase startup;
- perform post-merge local verification setup from the updated base branch/worktree and record its result before launching the next phase orchestrator;
- start the next phase orchestrator from the updated base branch, not from the previous phase worktree, after the local verification run has either launched or recorded an allowed blocker.

If post-merge verification fails after reconciliation, do not advance `run.yaml`. Stop with a supervisor escalation/handoff or restart a focused fix workflow. Do not silently rebase the phase branch, discard local work, or chain the next phase from the previous phase branch.

### Dirty Base Worktree Protocol

The run base worktree may contain ad-hoc human work, supervisor-owned lifecycle files, local verification artifacts, or runtime files when a phase completes. The supervisor must handle that state deliberately.

1. Capture a names-only status snapshot before merge-back:

```sh
/usr/bin/git status --porcelain=v1 -z > "docs/qa/artifacts/<phase>/base-worktree-status-before.z"
/usr/bin/git diff --name-only -z > "docs/qa/artifacts/<phase>/base-dirty-tracked-before.z"
/usr/bin/git ls-files --others --exclude-standard -z > "docs/qa/artifacts/<phase>/base-dirty-untracked-before.z"
/usr/bin/git diff --name-only -z "<base-commit>..<accepted-commit>" > "docs/qa/artifacts/<phase>/phase-changed-paths.z"
```

Do not dump full diffs by default. If a dirty or untracked path appears secret-bearing (`.env`, key material, credentials, tokens, private keys, runtime databases, uploaded bundles, extracted customer data), use `$secrets` before inspecting content and add a narrow `.gitignore` rule when needed.

2. Classify dirty paths:

- `supervisor-owned`: run state, inbox, watchdog, event, handoff, or QA artifact files created by the supervisor transition.
- `local-verification`: dev-server logs, local smoke reports, generated local runtime data under ignored runtime paths.
- `human-ad-hoc`: anything else.
- `suspected-secret-or-runtime-data`: secret-bearing or customer/runtime data paths; do not open or print contents.

3. Compute path overlap between dirty base paths and paths changed by the accepted phase commit range. Treat exact path matches as potential conflicts. For directories or generated trees, treat a dirty path under a phase-changed directory as a potential conflict unless the repo's ownership rules make it clearly independent.

4. If dirty paths are non-overlapping and the base branch is an ancestor of the phase branch, merge back with `git merge --ff-only`. Do not stash local changes as the default preservation strategy, because stashes can hide secret-bearing files and make the workflow less auditable. Use stash only after explicit human approval and after `$secrets` classification when suspected secrets/runtime data are present.

5. If dirty paths overlap, the base branch diverged, or fast-forward fails, use the merge reconciliation protocol. The supervisor is expected to make reasonable autonomous merge decisions and only escalate critical mismatches.

6. After merge-back or reconciliation, rerun `git status --porcelain=v1 -z`, verify preserved/reconciled local changes are accounted for, and record compact events such as `base_worktree_local_changes_preserved` or `base_worktree_conflicts_resolved` with status artifact paths, path counts, and decision artifact paths. Start the next phase from the updated base commit, with a note when preserved ad-hoc changes remain in the base worktree.

### Merge Reconciliation Protocol

Use this when a clean fast-forward is not available because the base worktree has overlapping ad-hoc changes, local base commits, or Git reports merge conflicts.

1. Create an auditable safety point before changing the base worktree:

```sh
base_head="$(/usr/bin/git rev-parse HEAD^{commit})"
safety_branch="supervisor/<run-id>/<phase-slug>-base-before-reconcile-$(date -u +%Y%m%dT%H%M%SZ)"
/usr/bin/git branch "$safety_branch" "$base_head"
/usr/bin/git status --porcelain=v1 -z > "$artifact_dir/base-worktree-status-before-reconcile.z"
/usr/bin/git diff --binary > "$artifact_dir/base-worktree-tracked-before-reconcile.patch"
/usr/bin/git diff --binary --cached > "$artifact_dir/base-worktree-index-before-reconcile.patch"
```

For untracked non-secret files, record names and preserve them in place when possible. Do not copy, print, or commit suspected secrets, runtime databases, uploaded bundles, or extracted customer data. Use `$secrets` for any suspected secret/runtime path before deciding how to preserve it.

2. Attempt the least surprising Git operation:

- If the base branch is an ancestor of the phase branch and the only issue is dirty working-tree overlap, attempt `git merge --ff-only "$phase_branch"` first after confirming Git can preserve local edits.
- If the base branch has local commits or fast-forward is impossible, run `git merge --no-ff "$phase_branch"` from the base branch so both histories are represented.
- Do not rebase the accepted phase branch during transition handling.

3. Resolve conflicts using reasonableness:

- Prefer the accepted phase branch for completed phase behavior, tests, generated contracts, migrations, and acceptance-backed service wiring.
- Preserve base-worktree ad-hoc changes when they are additive, local verification/reporting artifacts, documentation clarifications, developer-only config, or do not contradict acceptance evidence.
- Combine both sides when changes are compatible, such as adjacent docs, additive config keys, expanded tests, or non-conflicting UI copy.
- For lockfiles and generated artifacts, regenerate with the repo's standard command instead of hand-editing conflict markers when practical.
- For formatting-only conflicts, choose the version consistent with repo tooling and run the formatter/test command.

4. Escalate only critical mismatches. Critical mismatches include:

- a required product, privacy, security, legal, or data retention decision with no clear source-of-truth;
- suspected secret/customer/runtime data that would need to be opened, copied, deleted, or committed to continue;
- destructive data migration or irreversible external side effect;
- conflict between two incompatible schema/migration histories where automated tests cannot establish the correct state;
- conflict that would invalidate phase acceptance evidence and cannot be repaired with a focused fix;
- merge result cannot pass required post-merge verification after one focused fix attempt.

5. Record autonomous decisions. For every medium/high-confidence conflict resolved without human input, write a compact decision log under:

```text
docs/qa/artifacts/<phase>/merge-reconciliation-decisions.md
```

Include:

- accepted phase commit;
- current base commit;
- safety branch;
- conflicted paths;
- decision per path;
- reason/source-of-truth, such as phase acceptance evidence, repo convention, generated-file command, or additive preservation;
- verification command proving the decision.

Low-risk mechanical decisions may be summarized by category. Critical escalations must list path names and the decision needed, but not file contents when secrets or private data might be involved.

6. Commit or preserve the reconciliation result according to the shape of the merge:

- If the merge created a merge commit, use a message such as `merge: integrate <phase-slug>`.
- If the merge was a fast-forward with preserved uncommitted local changes, leave those local changes uncommitted and record them in `run.yaml`.
- If conflict resolution required edits after a fast-forward or merge, commit those edits on the base branch as supervisor reconciliation work, unless they are local verification artifacts that should remain uncommitted.

7. Run post-merge verification. If it fails, make one focused repair attempt when the failure is clearly caused by the reconciliation. Escalate if the fix would require a critical decision or broad reimplementation.

If the inbox or acceptance packet contains an abbreviated, malformed, or manually typed commit value, do not use it directly. Resolve it only when Git can unambiguously expand it and the resolved commit is contained in the phase branch:

```sh
resolved_commit="$(/usr/bin/git rev-parse --verify "${accepted_commit}^{commit}")"
/usr/bin/git merge-base --is-ancestor "$resolved_commit" "$phase_branch"
```

Patch the state file that had the malformed value to the full 40-character hash, commit that state repair on the phase branch, and then continue transition validation from the repaired state. If resolution fails, is ambiguous, or points outside the phase branch, stop with `restart_needed` or a supervisor escalation.

## Post-Merge Local Verification Run

After the accepted phase branch has been fast-forwarded into the run base branch/worktree and the resulting base commit is recorded, the supervisor owns a best-effort local verification launch for the human. This is separate from phase acceptance automation: acceptance proves the phase can complete, while the local verification run gives the human a live app or service to inspect while the next phase proceeds.

The supervisor must:

1. Work from the updated run base branch/worktree, not from the completed phase worktree.
2. Inspect project docs and standard files for the local setup path: `README*`, `AGENTS.md`, `package.json`, lockfiles, `Makefile`, `justfile`, `Taskfile`, `docker-compose*.yml`, `.env.example`, framework config, and existing scripts.
3. Install or refresh dependencies using the repo's package manager and lockfile. Prefer existing scripts such as `./install.sh`, `make setup`, `just setup`, `pnpm install`, `npm install`, `bundle install`, `uv sync`, `cargo fetch`, or equivalent local conventions.
4. Prepare local runtime prerequisites that are safe and reproducible: copy example env files when they contain placeholders, run local migrations or seed scripts, start containers/emulators, build generated assets, and run any documented bootstrap commands.
5. Use `$secrets` before creating, editing, revealing, or reviewing secret-bearing files. Do not invent real credentials. If required secrets are missing and no safe local placeholder path exists, record an allowed escalation with the exact missing variable or provider name, without printing secret values.
6. Start the project locally with the repo's normal dev command. Prefer a command that binds to localhost and stays running under a supervised process, tmux pane, or documented background process whose PID can be recorded.
7. Determine the reachable URL/port from command output, config, health checks, or probing common documented ports. Verify reachability with a lightweight request or browser check when possible.
8. Record the command, PID/pane/process identity, URL, setup status, blockers, and smoke-test instructions in `run.yaml` and append a compact supervisor event. Store longer output under `docs/qa/artifacts/<phase-slug>/local-verification-*` instead of YAML.
9. Print the localhost URL and a concise smoke-test checklist to the human in the supervisor transition status.

Allowed local verification blockers are the same as normal escalations: missing credentials/secrets, paid/vendor setup, external allowlists, unavailable physical devices, destructive production actions, real customer data requirements, or unavailable real dependencies after an agent-owned setup attempt. Dependency installs, local build failures, missing generated files, database migrations, container startup, and port conflicts are not blockers by themselves; diagnose and fix or choose a safe alternate local port before escalating.

If another phase remains and execution scope is `run`, local verification does not pause the run. Once the local launch has either succeeded or recorded an allowed blocker, start the next phase orchestrator and watchdog automatically from the updated base branch. Keep the launched local process running when it is safe to do so, so the human can verify the completed phase while the next phase is in progress.

Do not exit a supervisor transition handler after local verification launch unless `run.yaml` has been updated with the completed phase, the trigger has been marked handled, and the next phase orchestrator/watchdog has been started or a valid reason for not starting it has been recorded.

## Compact Inbox Contract

The watchdog polls only:

```text
docs/implementation-runs/<run-id>/supervisor-inbox/<phase-slug>.yaml
```

Example:

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
  manifest: "docs/implementation-runs/<run-id>/manifests/<phase>.yaml"
request:
  type: none # none | escalation | phase_completion | graceful_exit | restart_needed
  reason: null
  artifact: null
phase_completion:
  phase_yaml: "docs/implementation-runs/<run-id>/phases/<phase>.yaml"
  acceptance_packet: null
  commit: null # full 40-character commit hash when populated
```

The supervisor should not poll detailed phase internals. On `phase_completion`, it may run the narrow transition verification listed in the execution flow.

## Linear And SQLite

Do not use Linear or SQLite as workflow state. If Linear is present, treat it as an optional compact mirror only. The canonical execution state is the YAML run directory.
