# Outstanding Items

## Shell

- [x] **Replace Powerlevel10k prompt** — replaced with oh-my-posh using a custom bubblesextra theme with Catppuccin Latte colors.
- [ ] **Test new shell config** — zsh files were significantly rewritten (320 lines down to 95). Open a fresh terminal to verify: mise, SCM Breeze, mcfly, vi mode cursor, eza aliases, edit-command-line all work.
- [ ] **Remove `.p10k.zsh`** — oh-my-posh is now active; delete this file once confirmed working in a fresh terminal.

## Git

- [ ] **Audit `.gitconfig`** — contains stale entries: Lottie iOS URL override (`url.insteadOf`) from a previous job/project, and `credential.helper = store` which saves passwords in plaintext (macOS Keychain via `osxkeychain` is safer).
- [ ] **Add `diff-so-fancy` to Brewfile** — `.gitconfig` references it as the pager but it's not tracked as a dependency. Will break git diff on a fresh machine.
- [ ] **Audit `.gitignore_global`** — tracked in `dots/git/` but contents haven't been reviewed for completeness or stale entries.

## Neovim

- [ ] **Investigate debugging plugins** — nvim-dap, nvim-dap-ui for in-editor debugging.
- [ ] **Investigate testing plugins** — neotest for running tests from within Neovim.
- [ ] **Learn tabs, windows, and splits** — use these more efficiently for multi-file workflows.
- [ ] **Learn built-in terminal** — run commands without leaving Neovim.
- [ ] **Run project-wide commands from Neovim** — build, test, lint like an IDE.
- [ ] **Navigate project-wide diagnostics** — quickfix list, LSP diagnostics across files.
