# Local Verification

Use this after the accepted phase branch has been merged or reconciled into the run base branch/worktree and the resulting base commit is recorded. The supervisor owns a best-effort local verification launch for the human. This is separate from phase acceptance automation: acceptance proves the phase can complete, while the local verification run gives the human a live app or service to inspect while the next phase proceeds. The orchestrator's phase-transition handoff/report is the primary setup and smoke-test source.

The supervisor must:

1. Work from the updated run base branch/worktree, not from the completed phase worktree.
2. Read the phase-transition handoff/report from `phase_completion.transition_handoff` first. Use its setup instructions, expected ports, demo data, caveats, and smoke-test checklist as the primary local verification plan.
3. Inspect project docs and standard files only to validate or fill gaps in the handoff/report: `README*`, `AGENTS.md`, `package.json`, lockfiles, `Makefile`, `justfile`, `Taskfile`, `docker-compose*.yml`, `.env.example`, framework config, and existing scripts.
4. Install or refresh dependencies using the handoff's command when present, otherwise the repo's package manager and lockfile. Prefer existing scripts such as `./install.sh`, `make setup`, `just setup`, `pnpm install`, `npm install`, `bundle install`, `uv sync`, `cargo fetch`, or equivalent local conventions.
5. Prepare local runtime prerequisites from the handoff that are safe and reproducible: copy example env files when they contain placeholders, run local migrations or seed scripts, start containers/emulators, build generated assets, and run any documented bootstrap commands.
6. Use `$secrets` before creating, editing, revealing, or reviewing secret-bearing files. Do not invent real external credentials. If the app has login-gated smoke tests, verify the handoff includes seeded local admin access: either harmless local/demo credentials classified safe to print, or an exact ignored plaintext file path plus account/variable names where the credentials can be found. If required external secrets are missing and no safe local placeholder path exists, record an allowed escalation with the exact missing variable or provider name, without printing secret values.
7. Start the project locally with the handoff's dev command when present. Prefer a command that binds to localhost and stays running in a tmux pane in the original supervisor session, ideally in the shared workflow window used by the watchdog, so its PID and pane can be recorded without cluttering the primary supervisor/orchestrator window. Do not create a new tmux session for local verification.
8. Determine the reachable URL/port from command output, config, health checks, or probing the handoff's expected ports. If a port conflict occurs, choose a safe alternate local port when the handoff or repo config permits it, and record the alternate.
9. Write a smoke-test report artifact under `docs/qa/artifacts/<phase-slug>/local-verification-smoke-report.md` containing the URL, setup result, seeded local admin access summary or credential-file path, checklist from the handoff, expected outcomes, which checks the supervisor could verify automatically, which checks remain for the human, and blockers/caveats.
10. Record the command, PID/pane/process identity, URL, setup status, blockers, smoke-test checklist, transition handoff path, and smoke-test report artifact in `run.yaml`; append a compact supervisor event.
11. Print the localhost URL and smoke-test report to the human before starting the next phase orchestrator.

## Watchable Service Panes

Local verification services may write persistent runtime logs, but the tmux panes must still be watchable and controllable. Do not start a service in a pane with stdout/stderr redirected to a file and no visible output. Do not use `tail -f` as the visible pane process for the service; killing or restarting from the pane would affect tail instead of the service. Use `tee` so stdout/stderr goes to both the pane and a log file while the service remains the foreground workload.

Preferred no-tail pattern:

```sh
mkdir -p .tmp/local-verification/<phase-slug>/logs
log_file=".tmp/local-verification/<phase-slug>/logs/<service>.log"
: > "$log_file"
set -o pipefail
<dev-command> 2>&1 | tee -a "$log_file"
```

With this pattern, `Ctrl-C` in the pane interrupts the service pipeline. If the pane was launched by an interactive shell, the human can rerun the same command to restart the service.

If the shell supports process substitution and preserving the service as the exact foreground command matters more than restarting from the same shell, redirect the pane shell through `tee` before running the service:

```sh
mkdir -p .tmp/local-verification/<phase-slug>/logs
log_file=".tmp/local-verification/<phase-slug>/logs/<service>.log"
: > "$log_file"
exec > >(tee -a "$log_file") 2>&1
exec <dev-command>
```

Do not use the process-substitution `exec` form when the human is expected to stop and restart the service repeatedly in the same pane; use the foreground `tee` pipeline from an interactive shell instead.

Record the tmux pane id, URL, service process identity when discoverable, and log artifact path in the local verification smoke report. Do not store full logs in `run.yaml` or the smoke report. Store paths and short summaries only.

Allowed local verification blockers are the same as normal escalations: missing credentials/secrets, paid/vendor setup, external allowlists, unavailable physical devices, destructive production actions, real customer data requirements, or unavailable real dependencies after an agent-owned setup attempt. Dependency installs, local build failures, missing generated files, database migrations, container startup, and port conflicts are not blockers by themselves; diagnose and fix or choose a safe alternate local port before escalating.

If another phase remains and execution scope is `run`, local verification does not pause the run. Once the local launch has either succeeded or recorded an allowed blocker and the smoke-test report has been printed, start the next phase orchestrator and watchdog automatically from the updated base branch. Keep the launched local process running when it is safe to do so, so the human can verify the completed phase while the next phase is in progress.

Do not exit a supervisor transition handler after local verification launch unless `run.yaml` has been updated with the completed phase, the trigger has been marked handled, the completed phase orchestrator pane/session has been stopped or a teardown failure has been recorded, the smoke-test report has been printed, and the next phase orchestrator/watchdog has been started or a valid reason for not starting it has been recorded.
