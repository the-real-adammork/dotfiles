# Oh-My-Posh Migration (Catppuccin Latte Bubbles) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace Powerlevel10k with oh-my-posh using a custom bubblesextra theme remapped to Catppuccin Latte colors.

**Architecture:** Create an oh-my-posh config directory in dots, add a custom theme JSON based on bubblesextra, update .zshrc to swap p10k for oh-my-posh init, and add oh-my-posh to the Brewfile. Stow handles symlinking.

**Tech Stack:** oh-my-posh, zsh, GNU Stow, Homebrew

---

### Task 1: Add oh-my-posh to Brewfile

**Files:**
- Modify: `Brewfile`

**Step 1: Add oh-my-posh formula**

Add `brew "oh-my-posh"` to the Brewfile after `mcfly`:

```
brew "oh-my-posh"
```

**Step 2: Commit**

```bash
git add Brewfile
git commit -m "feat: add oh-my-posh to Brewfile"
```

---

### Task 2: Create oh-my-posh theme config

**Files:**
- Create: `oh-my-posh/.config/oh-my-posh/catppuccin-bubbles.omp.json`

This uses the stow convention — stow will symlink `.config/oh-my-posh/` into `$HOME/.config/oh-my-posh/`.

**Step 1: Create the theme file**

The theme is based on bubblesextra.omp.json with these changes:
- All `#29315A` backgrounds → `#ccd0da` (Catppuccin Latte Surface 0)
- Foreground colors remapped to Catppuccin Latte palette
- Removed: ruby, java, julia, php segments
- Added: swift segment
- Kept: path, git, python, go, node, battery, execution time, username

```json
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "right",
      "segments": [
        {
          "background": "#ccd0da",
          "foreground": "#40a02b",
          "leading_diamond": "\ue0b6",
          "properties": {
            "style": "folder"
          },
          "style": "diamond",
          "template": "\ue5ff {{ .Path }}",
          "trailing_diamond": "\ue0b4",
          "type": "path"
        },
        {
          "background": "#ccd0da",
          "foreground": "#209fb5",
          "foreground_templates": [
            "{{ if or (.Working.Changed) (.Staging.Changed) }}#fe640b{{ end }}",
            "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#d20f39{{ end }}",
            "{{ if gt .Ahead 0 }}#8839ef{{ end }}",
            "{{ if gt .Behind 0 }}#8839ef{{ end }}"
          ],
          "leading_diamond": " \ue0b6",
          "properties": {
            "branch_max_length": 25,
            "fetch_status": true,
            "fetch_upstream_icon": true
          },
          "style": "diamond",
          "template": " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} ",
          "trailing_diamond": "\ue0b4",
          "type": "git"
        },
        {
          "background": "#ccd0da",
          "foreground": "#df8e1d",
          "leading_diamond": " \ue0b6",
          "properties": {
            "fetch_version": false
          },
          "style": "diamond",
          "template": "\ue235 {{ if .Error }}{{ .Error }}{{ else }}{{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }}{{ end }}",
          "trailing_diamond": "\ue0b4",
          "type": "python"
        },
        {
          "background": "#ccd0da",
          "foreground": "#04a5e5",
          "leading_diamond": " \ue0b6",
          "properties": {
            "fetch_version": false
          },
          "style": "diamond",
          "template": "\ue626{{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}",
          "trailing_diamond": "\ue0b4",
          "type": "go"
        },
        {
          "background": "#ccd0da",
          "foreground": "#179299",
          "leading_diamond": " \ue0b6",
          "properties": {
            "fetch_version": false
          },
          "style": "diamond",
          "template": "\ue718{{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }}",
          "trailing_diamond": "\ue0b4",
          "type": "node"
        },
        {
          "background": "#ccd0da",
          "foreground": "#dd7878",
          "leading_diamond": " \ue0b6",
          "properties": {
            "fetch_version": false
          },
          "style": "diamond",
          "template": "\uf179 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}",
          "trailing_diamond": "\ue0b4",
          "type": "swift"
        },
        {
          "background": "#ccd0da",
          "foreground": "#7287fd",
          "foreground_templates": [
            "{{if eq \"Charging\" .State.String}}#04a5e5{{end}}",
            "{{if eq \"Discharging\" .State.String}}#fe640b{{end}}",
            "{{if eq \"Full\" .State.String}}#40a02b{{end}}"
          ],
          "leading_diamond": " \ue0b6",
          "style": "diamond",
          "template": "{{ if not .Error }}{{ .Icon }}{{ .Percentage }}{{ end }}{{ .Error }}",
          "trailing_diamond": "\ue0b4",
          "type": "battery",
          "properties": {
            "charged_icon": " ",
            "charging_icon": "\u21e1 ",
            "discharging_icon": "\u21e3 "
          }
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "background": "#ccd0da",
          "foreground": "#6c6f85",
          "leading_diamond": "\ue0b6",
          "properties": {
            "style": "austin",
            "threshold": 150
          },
          "style": "diamond",
          "template": "{{ .FormattedMs }}",
          "trailing_diamond": "\ue0b4 ",
          "type": "executiontime"
        },
        {
          "background": "#ccd0da",
          "foreground": "#ea76cb",
          "leading_diamond": "\ue0b6",
          "style": "diamond",
          "template": "{{ .UserName }} \u276f",
          "trailing_diamond": "\ue0b4",
          "type": "text"
        }
      ],
      "type": "prompt"
    }
  ],
  "final_space": true,
  "version": 3
}
```

**Step 2: Commit**

```bash
git add oh-my-posh/
git commit -m "feat: add oh-my-posh catppuccin-latte bubbles theme"
```

---

### Task 3: Update .zshrc to use oh-my-posh

**Files:**
- Modify: `zsh/.zshrc`

**Step 1: Remove Powerlevel10k instant prompt block (lines 1-4)**

Remove:
```zsh
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```

**Step 2: Remove ZSH_THEME line (line 8)**

Remove:
```zsh
export ZSH_THEME="powerlevel10k/powerlevel10k"
```

**Step 3: Remove p10k source line (line 95)**

Remove:
```zsh
# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

**Step 4: Add oh-my-posh init at the end of the file**

Add after the mcfly block:
```zsh
# Prompt
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/catppuccin-bubbles.omp.json)"
```

**Step 5: Commit**

```bash
git add zsh/.zshrc
git commit -m "feat(zsh): switch from Powerlevel10k to oh-my-posh"
```

---

### Task 4: Stow and verify

**Step 1: Stow the new oh-my-posh package**

```bash
cd ~/dots && stow -t "$HOME" --restow oh-my-posh
```

Verify the symlink exists:
```bash
ls -la ~/.config/oh-my-posh/catppuccin-bubbles.omp.json
```

**Step 2: Re-stow zsh to pick up .zshrc changes**

```bash
cd ~/dots && stow -t "$HOME" --restow zsh
```

**Step 3: Verify oh-my-posh is installed**

```bash
which oh-my-posh
oh-my-posh version
```

If not installed yet:
```bash
brew install oh-my-posh
```

**Step 4: Test the prompt**

Open a new terminal window (or `exec zsh`) and verify:
- Prompt renders with Catppuccin Latte colors (light backgrounds, colored text)
- Directory bubble shows current path in green
- Git bubble shows branch info in sapphire (clean) / peach (dirty)
- Username bubble shows on second line in pink
- No p10k errors in output

---

### Task 5: Update ITEMS.md

**Files:**
- Modify: `ITEMS.md`

**Step 1: Update the shell items**

Mark "Replace Powerlevel10k prompt" as done. Update "Remove `.p10k.zsh`" to note it can now be removed once the new prompt is confirmed working.

**Step 2: Commit**

```bash
git add ITEMS.md
git commit -m "docs: update ITEMS.md after oh-my-posh migration"
```
