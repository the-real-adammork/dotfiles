---
name: simslim
description: Manage local iOS Simulator devices with SimSlim on macOS. Use when an agent boots, shuts down, clones, renames, erases, deletes, diagnoses, or reduces resource use for local simulators, especially during parallel iOS development or testing. Do not use for physical devices or remote simulators.
---

# SimSlim

Use `simslim` as the preferred lifecycle and resource-management layer for local
iOS simulators. SimSlim complements `xcrun simctl` and simulator interaction
tools. It does not replace them.

## Choose the right tool

Prefer SimSlim for:

- Listing local simulators and checking their slim state.
- Booting, shutting down, cloning, repairing clones, renaming, erasing, or
  deleting a simulator.
- Reducing simulator memory use for parallel development, tests, or agents.
- Applying, checking, or removing a slimming profile.
- Measuring simulator memory or disk use and planning allowlisted cleanup.

Use `xcrun simctl` or the available iOS Simulator interaction tool for:

- Building, installing, launching, or terminating an app.
- UI gestures, accessibility inspection, and text input.
- Push payloads, deep links, location, privacy permissions, and status bars.
- Screenshots, video, app logs, and app-container access.

## Workflow

1. Confirm that the target is a local iOS simulator on macOS and that
   `command -v simslim` succeeds. Do not use SimSlim for physical devices or
   cloud simulators. If it is unavailable, report that fact and use `simctl`
   only when the task can still proceed. Do not install tools unless the task
   authorizes installation.
2. Run `simslim list --json` and resolve the exact simulator UDID. Use explicit
   UDIDs when more than one simulator exists. Do not apply a command to every
   simulator unless the user requested that scope.
3. Before slimming, identify the app features that the task needs. Reuse a
   repository profile when one exists. Inspect `simslim profiles` and
   `simslim doctor --list` instead of guessing category IDs or daemon labels.
4. For a compatible simulator that needs lower resource use, run
   `simslim on <udid>` with the required `--profile`, `--except`, or `--keep`
   options. This changes persistent per-simulator service state and reboots the
   simulator.
5. Verify the result with `simslim status <udid>`. When a profile or required
   app capability is known, also use `simslim verify` or `simslim doctor` with
   the same requirements. Use `simslim measure <udid>` when resource reduction
   is part of the task.
6. Shut down only the simulators that the task started. Keep the slim state for
   later runs unless the user asks for stock behavior; `simslim off <udid>`
   restores managed services and reboots the simulator.

Use `simslim --help` or the relevant subcommand help as the source of truth for
the installed version's flags.

## Safety

- Slimming can disable behavior that a test needs. Preserve required features
  in the selected profile and run `doctor` before claiming that the environment
  is ready.
- Treat `disk-clean`, `erase`, and `delete` as destructive. Run `disk-plan`
  before cleanup and obtain the authorization required by the active task
  before using a destructive command or its confirmation flag.
- Prefer `simslim clone` when an isolated copy is useful. Do not erase or alter
  an existing simulator merely to create a clean test target.
- Do not hardcode UDIDs in repository files. Discover them at runtime.
