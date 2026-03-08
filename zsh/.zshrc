# Oh My Zsh
export ZSH=$HOME/.oh-my-zsh
export ZSH_THEME=""
export CASE_SENSITIVE="true"
export DISABLE_LS_COLORS="true"
export DISABLE_AUTO_TITLE="true"
DISABLE_UPDATE_PROMPT=true

plugins=(z history zsh-autosuggestions history-substring-search zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Shell options
unsetopt correct

# History
HISTFILESIZE=10000000

# Vi mode
bindkey -v
export KEYTIMEOUT=1
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd "^V" edit-command-line
bindkey -v '^?' backward-delete-char

function zle-keymap-select zle-line-init {
    case $KEYMAP in
        vicmd)      print -n -- "\e[2 q";;  # block cursor
        viins|main) print -n -- "\e[6 q";;  # line cursor
    esac
    zle reset-prompt
    zle -R
}

function zle-line-finish {
    print -n -- "\e[2 q"  # block cursor
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

function vi_mode_prompt_info() {
  echo "${${KEYMAP/vicmd/% NORMAL }/(main|viins)/% INSERT %}"
}

# Word navigation with Alt+arrow
bindkey '^[[1;9C' forward-word
bindkey '^[[1;9D' backward-word
[ -z "${TMUX}" ] && bindkey '^[[1;3C' forward-word
[ -z "${TMUX}" ] && bindkey '^[[1;3D' backward-word

# PATH
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="$PATH:/Users/adam/.local/bin"
export PATH="$PATH:/Users/adam/Projects/xcode-build-server"
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"

# Custom PAGER (man pages in nvim)
export PAGER="/bin/sh -c \"unset PAGER;col -b -x | \
    nvim -R -c 'set ft=man nomod nolist' -c 'map q :q<CR>' \
    -c 'map <SPACE> <C-D>' -c 'map b <C-U>' \
    -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""

# GPG
export GPG_TTY=$(tty)

# Aliases
alias l='eza --long -a'
alias ll='eza --long -a --git'
alias lt='eza --long -a --tree --level=2'
alias gcm='git commit -m '
alias gpoh='git push origin HEAD '

# Tools
eval "$(mise activate zsh)"

# SCM Breeze (keep short aliases like gs/ga/gco, but unwrap raw git for agents)
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"
unfunction git 2>/dev/null

# mcfly
export MCFLY_LIGHT=TRUE
export MCFLY_KEY_SCHEME=vim
export MCFLY_FUZZY=2
export MCFLY_INTERFACE_VIEW=BOTTOM
source <(mcfly init zsh)

# Prompt
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/catppuccin-bubbles.omp.json)"
