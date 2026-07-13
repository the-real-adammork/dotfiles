---
title: Portable Dotfiles with Chezmoi - Plan
type: refactor
date: 2026-07-13
deepened: 2026-07-13
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
---

# Portable Dotfiles with Chezmoi - Plan

## Goal Capsule

Migrate this repository from GNU Stow to chezmoi so the same tracked decisions can be reproduced on a fresh macOS machine with a different username, while machine facts, credentials, trust records, caches, and other explicitly local state can differ safely. Preserve `./install.sh` as the single bootstrap entry point. During the migration, Stow and chezmoi may coexist only when tracked desired ownership plus machine-local adoption state prove that they do not manage the same target.

The completed system must detect portable changes made directly to live, app-mutated files before a commit. A commit is allowed when the staged chezmoi source captures the portable live change; declared machine-local drift remains allowed. Unknown fields inside declared portable namespaces block until classified, while unknown fields outside those namespaces are preserved as local state and reported for review.

## Product Contract

### Problem

The repository currently symlinks tracked files directly into `$HOME`. This is simple, but it also means application-generated changes, absolute home paths, trust entries, marketplace metadata, Git identity, and portable preferences can become mixed in the same committed file. Moving the repository to a machine with a different username can therefore produce broken paths or unintentionally transfer account- and machine-specific state.

### Users and outcomes

- The repository owner can bootstrap a new Mac under any home directory with `./install.sh`.
- Key tool choices and portable preferences remain consistent across machines through tracked chezmoi source.
- Machine-specific facts are rendered from built-in facts or local chezmoi data rather than committed usernames and paths.
- Credentials and runtime/account state remain outside version control and survive configuration updates.
- Direct portable edits made by Codex, Claude, or another app are surfaced before committing instead of silently drifting between machines.

### Scope

In scope:

- Incremental classification of every current Stow target as chezmoi-managed or intentionally unmanaged, with every retained managed target moved to a dedicated chezmoi source directory.
- A temporary, explicit non-overlap boundary between Stow and chezmoi.
- Portable templates for home paths, operating system, architecture, and package-manager locations.
- Semantic partial ownership for app-mutated Codex and Claude configuration.
- Machine-local Git identity and signing configuration.
- Transactional adoption, backup, rollback, resume, drift checking, and synthetic-home tests.
- Retirement of Stow after the last target is migrated.
- macOS-first behavior with explicit, graceful Linux skips or alternatives.

Out of scope:

- Syncing credentials, OAuth sessions, API tokens, keychain items, browser state, caches, histories, or application databases.
- Making every application setting identical across machines.
- Supporting branch-specific or worktree-specific dotfiles state.
- Replacing Homebrew as the package bootstrap mechanism.
- Rebuilding application-specific authentication as part of bootstrap.

### Authority and prerequisites

This plan supersedes the no-templating and Stow-only constraints in `docs/plans/2026-03-06-dotfiles-management-design.md` and `docs/plans/2026-03-06-dotfiles-implementation.md`. It preserves their useful constraints: `install.sh` remains the public bootstrap interface, package installation remains declared in Brewfiles, and behavior is verified in isolated synthetic home directories.

Before the mixed Codex and Claude files are migrated, the accepted `origin/main` configuration changes must be integrated. The target state includes the tmux agent sidebar, Codex `gpt-5.6-sol` with medium reasoning, Claude `opus[1m]`, the accepted plugin/runtime additions, and the accepted enabled/disabled MCP choices. Existing uncommitted application changes in `codex/.codex/config.toml` must be classified and reconciled rather than overwritten or bundled accidentally with this plan.

## Requirements

- **R1 — Portable bootstrap:** `./install.sh` must initialize and apply the repository under a different username and home path without a tracked `/Users/<name>` dependency.
- **R2 — Tracked portable decisions:** Models, reasoning levels, feature flags, plugin selections, shell/editor behavior, and other classified portable preferences must be represented in tracked source.
- **R3 — Declared local variation:** Machine facts and classified machine-local or account-local fields must remain outside tracked source or be preserved by a modifier contract.
- **R4 — No secret transfer:** Credential, OAuth, token, private-key, and authentication paths must never be opened, rendered, backed up, or stored by repository tooling. If a sensitive-looking field appears unexpectedly inside an otherwise allowed mixed file, classification must abort before backup, projection, persistence, or value logging.
- **R5 — Semantic drift gate:** Before a commit, fully owned targets must pass native chezmoi target-state checks, and portable projections of mixed live files must match either the last-applied baseline or the staged source candidate. Unknown fields inside portable namespaces and uncaptured portable changes must block with remediation; unknown fields outside portable namespaces must be preserved as local and reported as warnings.
- **R6 — Transactional adoption:** Changing a target's owner from Stow to chezmoi must be backed up, atomic at the target level, resumable, and reversible without losing local data.
- **R7 — Exclusive ownership:** Every inventoried target must be classified as Stow-owned, chezmoi-owned, or intentionally unmanaged in desired state, and every machine must record at most one active owner locally. The installer and tests must reject Stow/chezmoi overlap.
- **R8 — Selective installation:** Existing `./install.sh --only <package>` workflows must continue to select the corresponding logical target group during migration and after Stow is removed.
- **R9 — Idempotency:** Re-running install or apply without source or local-data changes must make no target changes and must preserve declared local state.
- **R10 — Cross-platform boundary:** macOS is the primary supported platform. Linux must either render a supported alternative or report a clear skip; macOS-only paths and packages must not leak into Linux targets.
- **R11 — Concurrent-write safety:** Adoption and modifier updates must detect if an application changed a target after it was read and stop before replacing newer content.
- **R12 — Complete retirement:** Once no desired-state entry remains Stow-owned and every retained managed target is chezmoi-owned, remove Stow installation, migration-only control paths, Stow-specific scripts, and the old package layout. Intentionally unmanaged inventory entries remain documented.
- **R13 — Repository guidance:** Repository documentation and agent instructions must describe the final chezmoi structure, bootstrap path, local-state boundary, and dependency/config synchronization rules.

## Acceptance Examples

- **AE1 — New username:** With a temporary home representing user `alex`, bootstrap renders that home path, passes chezmoi verification, and contains no reference to the source machine's username.
- **AE2 — Preserved local state:** Applying a portable Codex model change preserves project trust entries, hooks state, NUX state, marketplace cache metadata, trusted-client hashes, and authentication files.
- **AE3 — Uncaptured portable drift:** Changing a live portable model or feature flag without staging the corresponding source causes the commit hook to fail and identify the target and portable field.
- **AE4 — Captured portable drift:** After the staged chezmoi source renders the same portable value as the live file, the commit hook passes even though the live state differs from the last-applied baseline.
- **AE5 — Allowed local drift:** A change limited to a classified local field passes the drift gate without requiring a repository change.
- **AE6 — Unknown field:** A new key inside a declared portable namespace blocks until policy and tests classify it. A new key outside portable namespaces is preserved as local, emits a warning/report entry, and does not block an unrelated commit.
- **AE7 — Interrupted adoption:** If adoption stops after backup but before verification, the next run reports the checkpoint and can resume or roll back without losing the original target.
- **AE8 — Concurrent app write:** If a managed app changes a target during adoption or apply, the operation stops and leaves the newer live file intact.
- **AE9 — Selective apply:** `./install.sh --only zsh` changes only the zsh target group and its required dependencies.
- **AE10 — Linux behavior:** A synthetic Linux run excludes macOS casks, `/Applications` references, and Homebrew-on-Apple-Silicon assumptions while explaining unsupported packages.

## Context & Research

### Repository evidence

- `install.sh` is already the single bootstrap and owns Homebrew, Stow, Cargo, and tool setup. It is the correct compatibility boundary for the migration.
- `Brewfile` already contains `jq`, `yq`, and `lefthook`, which are sufficient for semantic JSON/TOML projections and a repository commit gate. `pre-commit` is also declared but has no repository configuration and is redundant for this design.
- `codex/.codex/config.toml` and `claude/.claude/settings.json` are directly stowed, even though their applications update portable and local fields in the same live file.
- Hard-coded source-machine paths exist in zsh, Vim/Neovim, Git, tmux-related configuration, and application command paths. `/opt/homebrew` assumptions also need an architecture-aware boundary.
- There is no root test harness today. Existing design documents already favor isolated temporary homes, so the new suite should exercise the real installer and render flow without touching the operator's home.

### External behavior relied upon

- Chezmoi separates source state, destination state, machine-local configuration data, and computed target state.
- Chezmoi templates expose home, operating-system, hostname, and architecture facts suitable for path portability.
- Chezmoi `modify_` scripts support partial ownership of an application-mutated file while preserving unowned content.
- `chezmoi status`, `chezmoi diff`, and `chezmoi verify` cover target-state differences and invariants, but they do not by themselves classify portable versus allowed-local fields.
- `chezmoi re-add` does not automatically reconcile templates, so the repository needs an explicit semantic drift workflow for mixed files.
- `.chezmoiroot` supports placing the source state in a subdirectory of this existing repository, which enables non-overlapping incremental migration.

### Sources

- [Chezmoi concepts](https://www.chezmoi.io/reference/concepts/)
- [Manage machine-to-machine differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Manage different file types and modify scripts](https://www.chezmoi.io/user-guide/manage-different-types-of-file/)
- [Chezmoi status](https://www.chezmoi.io/reference/commands/status/), [diff](https://www.chezmoi.io/reference/commands/diff/), and [verify](https://www.chezmoi.io/reference/commands/verify/)
- [Chezmoi re-add](https://www.chezmoi.io/reference/commands/re-add/)
- [Chezmoi setup](https://www.chezmoi.io/user-guide/setup/) and [custom source directories](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/)
- [GNU Stow manual](https://www.gnu.org/software/stow/manual/stow.html)

## Key Technical Decisions

### KTD1 — Use chezmoi's native source-state model, not generated untracked mirrors

Tracked files under `chezmoi/` are the canonical portable source. `.chezmoiroot` points chezmoi at that directory. Machine-local data stays in chezmoi's local configuration or is discovered at runtime; generated targets live only in the destination home. This avoids making an untracked generated tree a second source of truth.

Tradeoff: application edits to a rendered file cannot be committed by simply staging that file. The semantic drift gate and an explicit capture workflow add friction, but they make the portable/local boundary reviewable.

### KTD2 — Migrate incrementally, but end with one manager

Use a tracked manifest for desired ownership, migration version, logical groups, policies, and platform constraints. Store each machine's actual owner and completed adoption version in private runtime state. A machine remains Stow-owned until its verified adoption transaction advances local state; pulling a newer desired manifest must detect and adopt a legacy Stow symlink before invoking chezmoi. Keep legacy Stow sources available until the final rollout explicitly confirms active machines have crossed the migration version. The terminal state is zero desired Stow ownership and removal of Stow.

Tradeoff: a temporary dual-manager period is operationally more complex than a one-shot conversion, but it makes rollback and verification practical. Permanent hybrid ownership is rejected because future contributors would need to remember two mental models indefinitely.

### KTD3 — Classify fields with fail-closed semantic policies

For app-mutated JSON and TOML, use a versioned policy schema that defines exact portable paths, enumerated portable map keys, local dynamic-map ownership, array semantics, normalization, and projection output. Maintain these boundaries:

1. declared portable namespaces produced from tracked source;
2. declared local fields plus unknown fields outside portable namespaces, passed through from the live target with unknown-field warnings; and
3. forbidden secret/authentication target paths that repository tooling never opens, copies, backs up, or logs.

An unknown field inside a portable namespace blocks modify, adoption, and commit checks. An unknown field outside portable namespaces is preserved as local and added to a review report so policies can be tightened later without interrupting unrelated work. A sensitive-looking field discovered inside an allowed mixed file aborts in memory before any backup, projection, persistence, or value logging. Policies operate on parsed structures, not line diffs, so formatting and key-order changes do not create false portable drift.

Tradeoff: application upgrades can still block when they alter a namespace containing key portable decisions, but incidental metadata elsewhere produces reviewable warnings instead of stopping unrelated work.

### KTD4 — Compare live state, a local baseline, and the staged candidate

Use native chezmoi status/diff behavior for fully owned targets. Reserve the custom three-way portable baseline for modifier-managed mixed files, where chezmoi cannot distinguish portable intent from allowed local content. After every successful mixed-file apply, store a mode-restricted machine-local baseline containing only the portable projection and source identity. Before commit:

1. render a candidate from the Git index in a sandboxed synthetic HOME/XDG tree, using an allowlisted environment, explicit non-secret facts, no real authentication-path access, no network, and no candidate hook or arbitrary script execution;
2. project the portable portion of the live target;
3. allow the target when live equals the baseline (no direct portable edit), or when live equals the staged candidate (the direct edit is captured);
4. otherwise block and explain how to inspect or capture the difference.

The baseline is runtime state under the user's state directory, not a committed or ignored repository file. Declared local fields are omitted from projections. Git's unavoidable `--no-verify` escape remains available for emergencies and is documented as bypassing the guarantee.

### KTD5 — Use Lefthook as the single repository hook runner

Add a tracked `lefthook.yml`, but keep the drift command manually runnable until Codex and Claude policies are reconciled and their initial baselines exist. Install and activate the commit hook from `install.sh` only at that U3 gate. Remove the unused `pre-commit` package when the hook is active. This retains one existing Brew dependency and avoids adding a Python hook runtime solely for the drift gate.

Tradeoff: the protection applies only after bootstrap installs hooks, and Git permits bypass. CI or a manual verification command must run the same check to keep the policy independently executable.

### KTD6 — Derive facts automatically; prompt only for genuine choices

Use chezmoi built-ins or runtime discovery for home directory, username, OS, architecture, hostname, Homebrew prefix, and application availability. Store genuine per-machine choices such as Git name, email, signing key, and signing enablement in local chezmoi data or an included untracked Git config.

Tradeoff: Git identity may need one-time entry per machine instead of being copied automatically. That is preferable to committing account identity or enabling a signing key that is unavailable on the destination machine.

### KTD7 — Treat adoption as a transaction with optimistic concurrency

For each target, record a content hash, validate that the path and parsed structure contain no forbidden material, create a private backup, render to a temporary destination, re-check the live hash, replace the target, verify, then record the new machine-local owner and applicable baseline. On sensitive-field discovery, mismatch, or verification failure, do not create a backup or replace newer content. Checkpoints allow explicit resume or rollback.

Backups and checkpoints live outside the repository with user-only permissions and a bounded retention policy. This protects private local fields without creating untracked secret-bearing files in the repository.

### KTD8 — Keep bootstrap credential-independent

The installer may install applications and portable config, but it must not require Codex, Claude, GitHub, or plugin authentication. It reports deferred authentication steps without inspecting or printing credentials. Existing authentication files remain unmanaged.

## High-Level Technical Design

The diagrams describe boundaries and state flow, not exact command syntax.

```text
tracked repository                 machine-local state                 live home
┌─────────────────────┐           ┌──────────────────────┐           ┌─────────────────────┐
│ chezmoi/ source     │           │ chezmoi local data   │           │ rendered targets    │
│ portable policies   │──render──▶│ detected facts       │──────────▶│ app-mutated configs │
│ desired ownership   │           │ actual owner/version │           │ unmanaged auth/state│
│ + migration version │           │ portable baselines   │           │                     │
└──────────┬──────────┘           └──────────┬───────────┘           └──────────┬──────────┘
           │                                 │                                  │
           └──────────────── staged candidate│live portable projection ─────────┘
                                             ▼
                                  semantic drift/adoption gate
```

For mixed files, a modifier reads only an explicitly allowed non-secret target, parses it in memory, preserves declared and out-of-namespace local fields, overlays tracked portable values, rejects unknown portable-namespace or sensitive-looking fields, and emits a complete replacement. Authentication files and secret-bearing paths never enter this flow.

```text
inventoried → rendered-to-temp → privately-backed-up → ownership-released
      ▲                                                        │
      │                                                        ▼
rolled-back ← verification-failed ← target-replaced ← verified/complete
                                      │
                         live hash changed: stop, preserve newer file
```

The tracked manifest is the durable desired-state and policy contract. Machine-local runtime state records actual ownership, completed migration version, transaction status, hashes, baselines, and backup locations. Shared desired state never claims that another machine has completed adoption.

## Implementation Units

### U1 — Establish the chezmoi source and ownership boundary

**Requirements:** R1, R7, R8, R9, R10

**Files:**

- `.chezmoiroot`
- `chezmoi/`
- `config/managed-targets.toml`
- `Brewfile`
- `install.sh`
- `AGENTS.md`
- `tests/portability/helpers/`
- `tests/portability/test-bootstrap.sh`
- `tests/portability/test-ownership.sh`

**Approach:**

Add chezmoi as a cross-platform Brew dependency and create a dedicated source-state directory. Define a manifest entry for every current Stow package and target, including logical package name, desired owner, migration version, platform constraint, and local/portable policy reference. Store actual owner/adoption version outside the repository. Extend `install.sh` so `--only` resolves desired state plus detected/local actual state, invokes only the safe active owner, adopts legacy symlinks before chezmoi apply, and rejects duplicate or missing ownership. Keep Stow installed during this unit.

Update `AGENTS.md` in this unit with the transitional manifest-controlled Stow/chezmoi boundary so implementation guidance permits the new source layout without weakening repeatability rules. U6 replaces the transitional language with the final chezmoi-only contract.

Build synthetic-home helpers that isolate home, XDG paths, chezmoi config/state, Git config, and Homebrew command discovery. The tests must never dereference or mutate the operator's live home.

**Test scenarios:**

- Bootstrap an empty synthetic macOS home with a different username using a test-only manifest whose exact foundation targets are `.fixture-static` and `.config/fixture/machine.toml`; chezmoi initializes, renders exactly those fixtures, and leaves every other inventoried target untouched.
- Run the same bootstrap twice; the second run reports no target changes.
- Insert duplicate ownership for a fixture target; validation fails before either manager runs.
- Select one logical package with `--only`; unrelated target fixtures remain byte-identical.
- Exercise the Linux fixture; macOS-only entries are skipped with a reason rather than rendered.

**Verification outcome:** The repository has a valid chezmoi source boundary, every target is inventoried exactly once, and install selection behaves consistently across both managers.

### U2 — Add transactional adoption and semantic drift protection

**Requirements:** R3, R4, R5, R6, R9, R11

**Files:**

- `scripts/dotfiles-state`
- `config/managed-targets.toml`
- `config/policies/`
- `lefthook.yml`
- `install.sh`
- `tests/portability/test-adoption.sh`
- `tests/portability/test-drift-gate.sh`
- `tests/portability/test-concurrent-write.sh`

**Approach:**

Implement one repository command surface for manifest validation, adoption, apply, capture guidance, drift check, resume, and rollback. Use chezmoi's native status/diff behavior for fully owned targets; keep custom baseline/projection logic limited to ownership transactions and mixed modifier-managed files.

Before generalizing the control surface, pass an explicit pilot gate using one static fixture and one representative mixed Codex fixture. The pilot must prove indexed-source rendering, modifier preservation, portable-namespace rejection, out-of-namespace preservation/warning, concurrent-write detection, rollback, and idempotent re-apply.

Store actual ownership, backups, checkpoints, and mixed-file portable baselines in a user-only runtime state directory outside the repository. The drift command exports the Git index to a sandboxed synthetic HOME/XDG candidate with an allowlisted environment, no network or real authentication-path access, and candidate hooks/scripts disabled. It reports target names and classified paths but never secret or forbidden values.

Expose the drift check as a standalone verification entry point in this unit. Defer Lefthook activation until U3 has installed Codex and Claude policies, reconciled their live structures, and recorded initial baselines.

**Test scenarios:**

- Interrupt after backup and before replacement; resume completes and rollback restores the original fixture.
- Change the target after its initial hash is recorded; adoption stops without overwriting the newer fixture.
- Change a portable live value without staging source; drift check fails.
- Stage source that renders the same portable value; drift check passes.
- Change only a declared local value; drift check passes and apply preserves it.
- Add an unknown field inside a portable namespace; adoption, apply, and drift check fail closed. Add one outside portable namespaces; it is preserved, warned, and reported without blocking.
- Add a sensitive-looking field inside an allowed mixed fixture; classification aborts before backup/output creation and does not log the value.
- Place a staged candidate that tries to read the real home, environment, network, authentication paths, or invoke a candidate hook/script; the drift sandbox denies it.
- Place a sentinel credential file beside a fixture; no tool opens, copies, logs, or backs it up.
- Run without a baseline; the check fails with instructions to initialize state rather than assuming cleanliness.

**Verification outcome:** Ownership can change without data loss, and portable live drift cannot pass the repository gate unless it is unchanged or represented by staged source.

### U3 — Migrate Codex and Claude mixed-ownership configuration

**Requirements:** R2, R3, R4, R5, R6, R11

**Depends on:** U1, U2, and integration of the accepted remote configuration baseline.

**Files:**

- `chezmoi/` sources and modifiers for `.codex/config.toml`, `.codex/hooks.json`, and `.claude/settings.json`
- `config/policies/codex.toml`
- `config/policies/claude.toml`
- `config/managed-targets.toml`
- `codex/.codex/config.toml` (removed after verified adoption)
- `claude/.claude/settings.json` (removed after verified adoption)
- `tests/portability/test-codex-policy.sh`
- `tests/portability/test-claude-policy.sh`

**Approach:**

Encode the accepted portable decisions in tracked source: the selected models and reasoning settings, tmux agent sidebar, hooks file, plugins, runtimes, MCP definitions, and accepted enablement choices. Template home-relative command paths and application locations where possible.

For Codex, preserve as local at minimum project trust, hook runtime state, NUX state, marketplace timestamps/revisions/cache sources, trusted-client hashes, and app metadata. For Claude, keep authentication and trust state outside `settings.json` unmanaged, and preserve any policy-classified application metadata in the mixed file. Explicitly exclude Codex authentication files, Claude account files, and keychain material from target inventory.

Adopt the two live mixed files one at a time only after policy projections pass against the real reconciled structure. After the first mixed config is adopted, run a guarded canary: launch and cleanly exit its application once, then verify local preservation, warning/classification behavior, drift status, and idempotent re-apply before adopting the second config or starting U5. Keep legacy Stow source paths until rollout confirms active machines have completed the relevant migration version.

After both policies are installed and initial baselines are recorded, activate Lefthook from `install.sh`; until then the drift command remains manual so transitional unknown state cannot block unrelated commits.

**Test scenarios:**

- Render under two usernames; all home-relative commands follow the destination home.
- Apply a portable model, MCP, plugin, or sidebar change; the live fixture updates.
- Seed every declared local field; apply and re-apply preserve it exactly.
- Add an unknown key inside each portable namespace; modifiers stop without replacing the file. Add an unknown key outside those namespaces; modifiers preserve it and emit a review warning.
- Complete one application launch/exit round trip after the first adoption; the rewritten file remains classified, passes drift checks, and is idempotent on the next apply.
- Include representative auth files adjacent to each config; adoption leaves them untouched and uninspected.
- Simulate an application write between read and replacement; the newer configuration remains intact.

**Verification outcome:** Codex and Claude share portable decisions across machines without committing or destroying their account-, trust-, cache-, or machine-specific state.

### U4 — Remove username and architecture assumptions from shell, editor, tmux, and Git configuration

**Requirements:** R1, R2, R3, R8, R10

**Depends on:** U1, U2

**Files:**

- `chezmoi/` sources for zsh, Vim/Neovim, tmux, Git, and related shell tools
- `config/managed-targets.toml`
- current `zsh/`, `vim/`, `nvim/`, `tmux/`, and `git/` package sources (removed after verified adoption)
- `tests/portability/test-path-portability.sh`
- `tests/portability/test-git-local-config.sh`

**Approach:**

Replace source-user paths with home-relative configuration or chezmoi facts. Discover the Homebrew prefix and executable locations instead of committing `/opt/homebrew` or a source-machine binary path. Use application lookup and guarded platform conditions for optional tools.

Move Git identity, signing key, and signing enablement to a machine-local include or local chezmoi data. Keep portable Git behavior tracked. Bootstrap may prompt for missing identity only when installing the Git group interactively; non-interactive runs must explain the missing local choice and leave signing disabled rather than inventing values.

**Test scenarios:**

- Render all targets under two distinct home paths; no source username or source home survives.
- Render macOS Apple Silicon, macOS Intel, and Linux fixtures; package-manager and executable paths match their declared platform behavior.
- Omit optional tools; shell/editor startup fixtures avoid unconditional missing-binary paths.
- Provide local Git identity with no signing key; identity renders and signing remains disabled.
- Provide an available signing key; the local include enables signing without placing the key identifier in tracked output.
- Apply `--only zsh` and `--only git`; each operation remains isolated to its logical group.

**Verification outcome:** Core interactive configuration renders under a new account and architecture without transferring machine identity or creating broken absolute paths.

### U5 — Migrate the remaining stable Stow packages in bounded cohorts

**Requirements:** R1, R2, R6, R7, R8, R9, R10

**Depends on:** U1, U2

**Files:**

- `chezmoi/`
- `config/managed-targets.toml`
- remaining top-level Stow package directories
- `tests/portability/test-package-inventory.sh`
- `tests/portability/test-package-cohorts.sh`

**Approach:**

Migrate remaining packages in cohorts based on behavior: simple static CLI config, templated path/platform config, and application-managed config. Each machine follows the U2 adoption transaction and advances local actual ownership only after verification; tracked desired ownership advances by migration version without claiming other machines have adopted. Any newly discovered app-mutated file must receive a semantic policy before migration; it must not be treated as a static overwrite merely to finish the cohort.

Keep package names as logical manifest groups so existing `--only` usage remains stable even though physical Stow directories disappear. Platform-specific application bundles remain conditional and authentication/runtime directories remain unmanaged.

**Test scenarios:**

- Compare the manifest with the pre-migration Stow inventory; every intended target is migrated or explicitly classified unmanaged.
- Adopt and re-apply each cohort in a synthetic populated home; portable values update and local fixtures survive.
- Fail a target in the middle of a cohort; completed targets remain verified, the failing target remains recoverable, and pending targets are not silently marked complete.
- Run every logical `--only` group and confirm it touches only its manifest closure.
- Render the full inventory for macOS and Linux fixtures; unsupported entries produce explicit skips.

**Verification outcome:** Every retained dotfile has an intentional chezmoi or unmanaged classification, with no residual target depending on a Stow symlink.

### U6 — Retire Stow and finalize the portable bootstrap contract

**Requirements:** R8, R9, R12, R13

**Depends on:** U3, U4, U5

**Files:**

- `Brewfile`
- `install.sh`
- `stow-conflicts.sh` (removed)
- obsolete Stow package directories and ignore files (removed after inventory verification)
- `README.md`
- `AGENTS.md`
- `chezmoi/` source for `.claude/CLAUDE.md`
- `docs/plans/2026-03-06-dotfiles-management-design.md`
- `docs/plans/2026-03-06-dotfiles-implementation.md`
- `tests/portability/run.sh`
- `tests/portability/test-final-state.sh`

**Approach:**

Make desired state prove that no target remains Stow-owned and require an explicit rollout confirmation that every active machine has completed the terminal migration version, or that a dormant machine is intentionally retired. Then remove Stow and the redundant `pre-commit` formula, Stow-specific installer paths, conflict tooling, and old source layout. Keep chezmoi, Lefthook, jq, and yq declared because final configuration and validation depend on them.

After final inventory verification, remove migration-only adoption, resume, rollback, ownership-transition, and checkpoint behavior. Preserve steady-state apply, capture, drift checking, verification, and logical `--only` group selection; retain only the manifest fields needed for final grouping, platform conditions, and policies.

Update documentation and instructions to describe the chezmoi source layout, local config/state locations, secret boundary, capture/drift workflow, backup recovery, selective install behavior, and the rule that adding a configured binary requires a matching Brewfile or installer declaration. Mark the older Stow design documents as superseded while retaining them as historical context.

Create a single root portability suite that runs all synthetic-home scenarios and final-state assertions.

**Test scenarios:**

- Validate that the manifest contains no Stow owner and no old package source is reachable through a live target.
- Bootstrap an empty macOS synthetic home, run the full suite, apply twice, and observe a clean second status/diff.
- Bootstrap a populated synthetic home containing allowed local Codex, Claude, and Git state; verify preservation and idempotency.
- Run the repository drift gate against clean, captured-drift, uncaptured-drift, local-only, and unknown-field fixtures.
- Run the Linux fixture and verify graceful skips with no macOS path leakage.
- Search tracked source and rendered portable fixtures for the source username, absolute source home, credential fixtures, and Stow commands; find none.

**Verification outcome:** `./install.sh` is a complete, idempotent chezmoi bootstrap; the test suite proves portability and drift behavior; documentation matches the executable system; and Stow is no longer a dependency.

## System-Wide Impact

### Entry points and interfaces

- `./install.sh` remains the human-facing entry point. Its package vocabulary stays stable through logical manifest groups.
- Chezmoi becomes the rendering/apply engine and source-state contract.
- During migration, `scripts/dotfiles-state` is the explicit interface for validation, adoption, recovery, and drift checks. U6 reduces it to steady-state validation, apply/capture, drift checking, and logical group selection.
- Lefthook invokes the standalone drift check; CI or manual verification can invoke the same interface without Git hook state.

### State lifecycle and data integrity

- Tracked source holds portable intent, desired ownership/migration versions, and classification policies.
- Chezmoi local configuration holds non-secret machine choices and detected facts.
- During migration, runtime state holds actual ownership/version, private backups, transaction checkpoints, and mixed-file portable baselines with user-only permissions; U6 removes obsolete transition state after rollout confirmation.
- Live targets may contain tracked portable values plus declared local values. Secret/auth targets are outside inventory entirely.
- Baselines update only after verified apply or adoption. A failed or concurrent operation cannot advance ownership or baseline state.

### Failure propagation

- Manifest or policy validation fails before target mutation.
- Unknown portable-namespace or sensitive-looking fields fail the affected target and prevent ownership/baseline advancement; unknown out-of-namespace fields are preserved and warned.
- A live hash mismatch stops replacement and preserves the newer file.
- A failed target leaves an actionable checkpoint; it does not mark later cohort targets complete.
- Missing credentials never fail portable bootstrap because authentication is deferred and unmanaged.
- Missing local Git identity affects only the Git group and does not invent or commit identity.

### Security and privacy

- Secret-bearing paths are denylisted from inventory, backup, projection, logging, and fixtures.
- Backups may contain private non-secret local metadata and therefore require user-only permissions and bounded retention.
- Error output names files and field paths but redacts values for mixed application configuration.
- Local config and runtime state are outside the repository; no broad ignore rule is used as a substitute for correct placement.

### Compatibility and rollout

- Migration proceeds by target group from tracked desired ownership and per-machine actual ownership with a reversible checkpoint.
- The temporary dual-manager period is tested for non-overlap on every install.
- Existing machines adopt populated files; fresh machines render without adoption.
- macOS behavior is release-blocking. Linux behavior is limited to supported alternatives and explicit skips, but it must not render broken macOS assumptions.

## Verification Contract

Implementation is accepted only when all of these gates pass in isolated test homes:

- Syntax and manifest validation for `install.sh`, state tooling, policy files, and hook configuration.
- The complete `tests/portability/run.sh` suite, including every AE1–AE10 scenario.
- A clean second full bootstrap/apply with no target diff.
- A full logical-package `--only` matrix with no unrelated target mutation.
- Semantic policy fixtures for every mixed JSON/TOML file, covering portable, local, forbidden, and unknown fields.
- A policy-schema fixture covering exact paths, enumerated portable map keys, local dynamic maps, arrays, normalization, projections, out-of-namespace warnings, and sensitive-field aborts.
- Transaction fixtures for backup, resume, rollback, verification failure, and concurrent writes.
- Final inventory proof that no target is multiply owned, no target remains Stow-owned, and every old Stow target is now chezmoi-managed or explicitly unmanaged.
- A repository scan proving no source-machine home path, fixture credential, or active Stow invocation remains.
- Manual review of one real-machine dry run, diff, and adoption preview before the first live ownership change; the operator explicitly approves mutation after inspecting the backup location and rendered diff.
- A guarded real-application canary after the first mixed-config adoption: launch/exit once, then require classified output, preserved local state, a clean drift check, and idempotent re-apply before broader adoption.

No verification step may use the operator's live home as a test fixture or print authentication material.

## Risks & Dependencies

- **Remote reconciliation dependency:** Codex and Claude policies must be built from the accepted merged configuration, not the currently divergent branches or incidental app drift. Mitigation: block U3 until the remote baseline and live local changes are reconciled and semantically classified.
- **Application schema churn:** Codex or Claude may add fields. Mitigation: fail closed inside portable namespaces, preserve and warn outside them, abort on sensitive-looking fields, and require policy regression fixtures when a warning should become a portable or explicitly local rule.
- **Concurrent application writes:** A running app can update configuration during adoption. Mitigation: optimistic content hashes, temporary rendering, and no baseline/owner advancement on mismatch.
- **Private backup exposure:** Mixed configs can contain sensitive local metadata. Mitigation: exclude known credential files entirely, restrict backup permissions, redact output, retain backups for a bounded period, and document secure deletion.
- **Hook bypass or absence:** Hooks can be bypassed or not installed. Mitigation: installer-managed Lefthook setup plus the same standalone verification gate for CI/manual use; document `--no-verify` as an explicit emergency bypass.
- **Temporary manager complexity:** Stow and chezmoi coexist during rollout. Mitigation: manifest-enforced exact ownership, pre-mutation overlap checks, and a time-bounded terminal unit that removes Stow.
- **Chezmoi/modifier behavior changes:** The design depends on supported source-root, template, modify, status, diff, and verify behavior. Mitigation: pin behavior through integration fixtures and keep custom policy tooling behind one repository interface.
- **Package-manager variance:** Homebrew prefixes differ by architecture and Linux installations vary. Mitigation: runtime discovery and platform fixtures rather than committed absolute paths.
- **Local identity availability:** Git signing keys may not exist on a destination machine. Mitigation: local data, explicit availability checks, and signing disabled by default until configured.

## Documentation Plan

- Rewrite `README.md` around install, update, preview, capture, drift resolution, selective install, backup recovery, and new-machine setup.
- Update `AGENTS.md` first with the transitional ownership boundary in U1, then with final chezmoi-only repeatability and config/dependency synchronization guidance in U6.
- Update global Claude guidance only where it documents dotfiles bootstrap behavior; keep unrelated global instructions unchanged.
- Mark the 2026-03-06 Stow design and implementation documents superseded by this plan, with links forward.
- Document the portable/local/forbidden classification table for every mixed config and the process for adding a newly observed app field.
- Document that authentication is a post-bootstrap user action and identify only the unmanaged file categories, never credential values.

## Open Questions

### Resolved during planning

- **Manager:** chezmoi replaces Stow; the migration is incremental but the final state is not hybrid.
- **Canonical state:** tracked chezmoi source is canonical; generated live files are not committed mirrors.
- **Drift policy:** portable drift blocks commits unless captured by staged source; declared local drift is allowed; unknown fields inside portable namespaces block, while unknown fields outside them are preserved as local with a warning/report entry.
- **Repository workflow:** the dotfiles repository is maintained directly on `main`; branch/worktree-specific dotfiles state is not required.
- **Hook runner:** Lefthook is the sole hook framework; the unused `pre-commit` dependency is removed at finalization.
- **Git identity:** identity and signing are machine-local choices, not tracked portable defaults.
- **Authentication:** account login and credentials remain unmanaged and are not prerequisites for install.
- **Unknown fields:** use scoped fail-closed behavior rather than blocking every new application metadata field.

### Deferred to implementation

- The exact bounded backup retention count or age, chosen after measuring typical mixed-config sizes. The required behavior is private, bounded retention with explicit cleanup.
- The exact grouping of remaining simple packages into U5 cohorts, derived mechanically from the completed ownership inventory. This may affect execution batching but not ownership or verification behavior.

## Definition of Done

- All R1–R13 requirements and AE1–AE10 examples are covered by passing verification evidence.
- A fresh macOS synthetic home under a different username bootstraps from `./install.sh` and is idempotent.
- A populated-home adoption preserves classified and out-of-namespace local state, refuses unknown portable-namespace, sensitive-looking, or concurrently changed data, and reports preserved unknown local fields.
- Portable live drift is detected before commit and passes only when unchanged or represented by staged source.
- Credentials and authentication state remain outside repository source, runtime projections, backups, and logs.
- Every target is exactly once classified as chezmoi-managed or intentionally unmanaged; none remains Stow-owned.
- Stow and redundant hook dependencies and tooling are removed.
- `README.md`, `AGENTS.md`, global tool guidance where relevant, and historical design docs accurately describe the final system.
- A reviewed real-machine dry run shows the expected diff and backup destination before any live target is adopted.
